@echo off
setlocal enabledelayedexpansion

REM 设置环境变量
set GPU=0
set CAMERA=PINHOLE
set EXP_NAME_1=stage1
set EXP_NAME_2=stage2
set EXP_NAME_3=stage3



REM 获取项目目录
set PROJECT_DIR=%CD%
set DATA_PATH=%PROJECT_DIR%\data
set ENV_PATH=%PROJECT_DIR%\envs
set MAMBA=%PROJECT_DIR%\micromamba.exe
set CUDA_DIR="C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"
set BLENDER_DIR="C:\Program Files\Blender Foundation\Blender 3.6"
set COLMAP_DIR="C:\Colmap\bin"
set CMAKE_DIR="C:\Program Files\CMake\bin"
set GIT_DIR="C:\Program Files\Git\bin"
set PATH=%PATH%;%CUDA_DIR%\bin;%BLENDER_DIR%\blender.exe;%COLMAP_DIR%;%CMAKE_DIR%;%GIT_DIR%;%MAMBA%

REM 确保设置DATA_PATH环境变量
if "%DATA_PATH%"=="" (
    echo 错误：未设置DATA_PATH环境变量！
    echo 请设置DATA_PATH指向包含raw.mp4的场景文件夹。
    echo 例如: set DATA_PATH=E:\data\my_scene
    pause
    exit /b 1
)

REM 确保BLENDER_DIR环境变量已设置
if "%BLENDER_DIR%"=="" (
    echo 错误：未设置BLENDER_DIR环境变量！
    echo 请设置BLENDER_DIR指向Blender的安装目录。
    echo 例如: set BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6
    pause
    exit /b 1
)

REM 确保micromamba可用
if not exist "%MAMBA%" (
    echo 错误：micromamba.exe不存在于项目目录！
    echo 请确保安装脚本已正确运行。
    pause
    exit /b 1
)

REM 初始化micromamba
call %USERPROFILE%\.micromamba\micromambarc.cmd

echo 开始预处理...

REM 预处理：将原始图像整理为3D Gaussian Splatting格式
%MAMBA% activate gaussian_splatting_hair
cd %PROJECT_DIR%\src\preprocessing
set CUDA_VISIBLE_DEVICES=%GPU%
python preprocess_raw_images.py --data_path %DATA_PATH%

REM 运行COLMAP重建并校正图像和相机
cd %PROJECT_DIR%\src
python convert.py -s %DATA_PATH% --camera %CAMERA% --max_size 1024

REM 运行Matte-Anything
%MAMBA% activate matte_anything
cd %PROJECT_DIR%\src\preprocessing
python calc_masks.py --data_path %DATA_PATH% --image_format png --max_size 2048

REM 使用IQA分数过滤图像
%MAMBA% activate gaussian_splatting_hair
cd %PROJECT_DIR%\src\preprocessing
python filter_extra_images.py --data_path %DATA_PATH% --max_imgs 128

REM 调整图像大小
cd %PROJECT_DIR%\src\preprocessing
python resize_images.py --data_path %DATA_PATH%

REM 计算方向图
cd %PROJECT_DIR%\src\preprocessing
python calc_orientation_maps.py --img_path %DATA_PATH%\images_2 --mask_path %DATA_PATH%\masks_2\hair --orient_dir %DATA_PATH%\orientations_2\angles --conf_dir %DATA_PATH%\orientations_2\vars --filtered_img_dir %DATA_PATH%\orientations_2\filtered_imgs --vis_img_dir %DATA_PATH%\orientations_2\vis_imgs

REM 运行OpenPose
%MAMBA% activate openpose
cd %PROJECT_DIR%\ext\openpose
mkdir %DATA_PATH%\openpose
cd %PROJECT_DIR%\ext\openpose\build\bin\Release
OpenPoseDemo.exe --image_dir %DATA_PATH%\images_4 --scale_number 4 --scale_gap 0.25 --face --hand --display 0 --write_json %DATA_PATH%\openpose\json --write_images %DATA_PATH%\openpose\images --write_images_format jpg

REM 运行Face-Alignment
%MAMBA% activate gaussian_splatting_hair
cd %PROJECT_DIR%\src\preprocessing
python calc_face_alignment.py --data_path %DATA_PATH% --image_dir "images_4"

REM 运行PIXIE
%MAMBA% activate pixie-env
cd %PROJECT_DIR%\ext\PIXIE
python demos\demo_fit_face.py -i %DATA_PATH%\images_4 -s %DATA_PATH%\pixie --saveParam True --lightTex False --useTex False --rasterizer_type pytorch3d

REM 将所有PIXIE预测合并到单个文件中
%MAMBA% activate gaussian_splatting_hair
cd %PROJECT_DIR%\src\preprocessing
python merge_smplx_predictions.py --data_path %DATA_PATH%

REM 将COLMAP相机转换为txt
mkdir %DATA_PATH%\sparse_txt
colmap model_converter --input_path %DATA_PATH%\sparse\0 --output_path %DATA_PATH%\sparse_txt --output_type TXT

REM 将COLMAP相机转换为H3DS格式
cd %PROJECT_DIR%\src\preprocessing
python colmap_parsing.py --path_to_scene %DATA_PATH%

REM 删除原始文件以节省磁盘空间
if exist %DATA_PATH%\input rd /s /q %DATA_PATH%\input
if exist %DATA_PATH%\images rd /s /q %DATA_PATH%\images
if exist %DATA_PATH%\masks rd /s /q %DATA_PATH%\masks
del /q %DATA_PATH%\iqa*

echo 开始重建...

set EXP_PATH_1=%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%

REM 运行3D Gaussian Splatting重建
%MAMBA% activate gaussian_splatting_hair
cd %PROJECT_DIR%\src
python train_gaussians.py -s %DATA_PATH% -m "%EXP_PATH_1%" -r 1 --port "888%GPU%" --trainable_cameras --trainable_intrinsics --use_barf --lambda_dorient 0.1

REM 运行FLAME网格拟合
cd %PROJECT_DIR%\ext\NeuralHaircut\src\multiview_optimization

python fit.py --conf confs/train_person_1.conf --batch_size 1 --train_rotation True --fixed_images True --save_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_1 --data_path %DATA_PATH% --fitted_camera_path %EXP_PATH_1%\cameras\30000_matrices.pkl

python fit.py --conf confs/train_person_1.conf --batch_size 4 --train_rotation True --fixed_images True --save_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_2 --checkpoint_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_1\opt_params_final --data_path %DATA_PATH% --fitted_camera_path %EXP_PATH_1%\cameras\30000_matrices.pkl

python fit.py --conf confs/train_person_1_.conf --batch_size 32 --train_rotation True --train_shape True --save_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_3 --checkpoint_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_2\opt_params_final --data_path %DATA_PATH% --fitted_camera_path %EXP_PATH_1%\cameras\30000_matrices.pkl

REM 裁剪重建场景
cd %PROJECT_DIR%\src\preprocessing
python scale_scene_into_sphere.py --path_to_data %DATA_PATH% -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" --iter 30000

REM 移除与FLAME头部网格相交的头发高斯体
cd %PROJECT_DIR%\src\preprocessing
python filter_flame_intersections.py --flame_mesh_dir %DATA_PATH%\flame_fitting\%EXP_NAME_1% -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" --iter 30000 --project_dir %PROJECT_DIR%\ext\NeuralHaircut

REM 渲染训练视图
cd %PROJECT_DIR%\src
python render_gaussians.py -s %DATA_PATH% -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" --skip_test --scene_suffix "_cropped" --iteration 30000 --trainable_cameras --trainable_intrinsics --use_barf

REM 获取FLAME网格头皮图
cd %PROJECT_DIR%\src\preprocessing
python extract_non_visible_head_scalp.py --project_dir %PROJECT_DIR%\ext\NeuralHaircut --data_dir %DATA_PATH% --flame_mesh_dir %DATA_PATH%\flame_fitting\%EXP_NAME_1% --cams_path %DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%\cameras\30000_matrices.pkl -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%"

REM 运行潜在头发丝重建
cd %PROJECT_DIR%\src
python train_latent_strands.py -s %DATA_PATH% -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" -r 1 --model_path_hair "%DATA_PATH%\strands_reconstruction\%EXP_NAME_2%" --flame_mesh_dir "%DATA_PATH%\flame_fitting\%EXP_NAME_1%" --pointcloud_path_head "%EXP_PATH_1%\point_cloud_filtered\iteration_30000\raw_point_cloud.ply" --hair_conf_path "%PROJECT_DIR%\src\arguments\hair_strands_textured.yaml" --lambda_dmask 0.1 --lambda_dorient 0.1 --lambda_dsds 0.01 --load_synthetic_rgba --load_synthetic_geom --binarize_masks --iteration_data 30000 --trainable_cameras --trainable_intrinsics --use_barf --iterations 20000 --port "800%GPU%"

REM 运行头发丝重建
cd %PROJECT_DIR%\src
python train_strands.py -s %DATA_PATH% -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" -r 1 --model_path_curves "%DATA_PATH%\curves_reconstruction\%EXP_NAME_3%" --flame_mesh_dir "%DATA_PATH%\flame_fitting\%EXP_NAME_1%" --pointcloud_path_head "%EXP_PATH_1%\point_cloud_filtered\iteration_30000\raw_point_cloud.ply" --start_checkpoint_hair "%DATA_PATH%\strands_reconstruction\%EXP_NAME_2%\checkpoints\20000.pth" --hair_conf_path "%PROJECT_DIR%\src\arguments\hair_strands_textured.yaml" --lambda_dmask 0.1 --lambda_dorient 0.1 --lambda_dsds 0.01 --load_synthetic_rgba --load_synthetic_geom --binarize_masks --iteration_data 30000 --position_lr_init 0.0000016 --position_lr_max_steps 10000 --trainable_cameras --trainable_intrinsics --use_barf --iterations 10000 --port "800%GPU%"

if exist "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%\train_cropped" rd /s /q "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%\train_cropped"

echo 创建可视化...

REM 导出结果头发丝为pkl和ply
cd %PROJECT_DIR%\src\preprocessing
python export_curves.py --data_dir %DATA_PATH% --model_name %EXP_NAME_3% --iter 10000 --flame_mesh_path "%DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_3\mesh_final.obj" --scalp_mesh_path "%DATA_PATH%\flame_fitting\%EXP_NAME_1%\scalp_data\scalp.obj" --hair_conf_path "%PROJECT_DIR%\src\arguments\hair_strands_textured.yaml"

REM 渲染可视化
cd %PROJECT_DIR%\src\postprocessing
python render_video.py --blender_path "%BLENDER_DIR%" --input_path "%DATA_PATH%" --exp_name_1 "%EXP_NAME_1%" --exp_name_3 "%EXP_NAME_3%"

REM 渲染头发丝
cd %PROJECT_DIR%\src
python render_strands.py -s %DATA_PATH% --data_dir "%DATA_PATH%" --data_device 'cpu' --skip_test -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" --iteration 30000 --flame_mesh_dir "%DATA_PATH%\flame_fitting\%EXP_NAME_1%" --model_hair_path "%DATA_PATH%\curves_reconstruction\%EXP_NAME_3%" --hair_conf_path "%PROJECT_DIR%\src\arguments\hair_strands_textured.yaml" --checkpoint_hair "%DATA_PATH%\strands_reconstruction\%EXP_NAME_2%\checkpoints\20000.pth" --checkpoint_curves "%DATA_PATH%\curves_reconstruction\%EXP_NAME_3%\checkpoints\10000.pth" --pointcloud_path_head "%EXP_PATH_1%\point_cloud\iteration_30000\raw_point_cloud.ply" --interpolate_cameras

REM 创建视频
cd %PROJECT_DIR%\src\postprocessing
python concat_video.py --input_path "%DATA_PATH%" --exp_name_3 "%EXP_NAME_3%"

echo 重建完成！
echo 结果保存在 %DATA_PATH% 目录中。
pause
