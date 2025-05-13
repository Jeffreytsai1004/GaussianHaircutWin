@echo off
setlocal enabledelayedexpansion

echo ===================================
echo GaussianHaircut Windows 运行程序
echo ===================================

REM 设置环境变量
set GPU=0
set CAMERA=PINHOLE
set EXP_NAME_1=stage1
set EXP_NAME_2=stage2
set EXP_NAME_3=stage3

REM 获取项目目录
set "PROJECT_DIR=%CD%"
set "DATA_PATH=%PROJECT_DIR%\data"
set "ENV_PATH=%PROJECT_DIR%\envs"
set "MAMBA=%PROJECT_DIR%\micromamba.exe"
set "CUDA_DIR=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"
set "BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6"
set "COLMAP_DIR=C:\Colmap\bin"
set "CMAKE_DIR=C:\Program Files\CMake\bin"
set "GIT_DIR=C:\Program Files\Git\bin"
set "VCVARS_DIR=D:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build"
set PATH=%PROJECT_DIR%;%PATH%;%CUDA_DIR%\bin;%BLENDER_DIR%;%COLMAP_DIR%;%CMAKE_DIR%;%GIT_DIR%

REM 设置模型路径
set SAM_MODEL=%PROJECT_DIR%\ext\Matte-Anything\pretrained\sam_vit_h_4b8939.pth
set FACE_ALIGN_MODEL=%PROJECT_DIR%\ext\face-alignment\pretrained\3DFAN4-4a694010b.pth.tar
set PIXIE_MODEL=%PROJECT_DIR%\ext\PIXIE\pixie_model
set FLAME_MODEL=%PROJECT_DIR%\ext\FLAME\flame_model
set OPENPOSE_MODEL=%PROJECT_DIR%\ext\openpose\models

REM 确保设置DATA_PATH环境变量
if "%DATA_PATH%"=="" (
    echo 错误: 未设置DATA_PATH环境变量! 
    echo 请设置DATA_PATH指向包含raw.mp4的场景文件夹。
    echo 例如: set DATA_PATH=E:\data\my_scene
    pause
    exit /b 1
)

REM 确保BLENDER_DIR环境变量已设置
if "%BLENDER_DIR%"=="" (
    echo 错误: 未设置BLENDER_DIR环境变量! 
    echo 请设置BLENDER_DIR指向Blender的安装目录。
    echo 例如: set BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6
    pause
    exit /b 1
)

REM 确保micromamba可用
if not exist "%MAMBA%" (
    echo 错误: micromamba.exe不存在于项目目录! 
    echo 请确保安装脚本已正确运行。
    pause
    exit /b 1
)

REM 检查环境是否存在
if not exist "%ENV_PATH%\gaussianhaircut" (
    echo 环境未安装，请先运行 install.bat
    pause
    exit /b 1
)

REM 检查模型文件是否存在
if not exist "%SAM_MODEL%" (
    echo 警告: SAM模型文件不存在于 %SAM_MODEL%
    echo 请确保已下载SAM模型文件，或在install.bat中修改下载位置。
)

if not exist "%FACE_ALIGN_MODEL%" (
    echo 警告: Face-Alignment模型文件不存在于 %FACE_ALIGN_MODEL%
    echo 请确保已下载Face-Alignment模型文件，或在install.bat中修改下载位置。
)

if not exist "%PIXIE_MODEL%" (
    echo 警告: PIXIE模型文件不存在于 %PIXIE_MODEL%
    echo 请确保已下载PIXIE模型文件，或在install.bat中修改下载位置。
)

if not exist "%FLAME_MODEL%" (
    echo 警告: FLAME模型文件不存在于 %FLAME_MODEL%
    echo 请确保已下载FLAME模型文件，或在install.bat中修改下载位置。
)

REM 显示菜单
:menu
cls
echo GaussianHaircut 运行菜单
echo =======================
echo 1. 运行完整处理流程
echo 2. 仅运行数据预处理
echo 3. 仅运行重建
echo 4. 仅运行可视化
echo 5. 选择数据目录
echo 6. 设置GPU和相机参数
echo 7. 设置实验名称
echo 8. 退出
echo.
echo 当前数据目录: %DATA_PATH%
echo 当前GPU: %GPU%
echo 当前相机模型: %CAMERA%
echo 当前实验名称: %EXP_NAME_1%, %EXP_NAME_2%, %EXP_NAME_3%
echo.
set /p choice=请选择操作 (1-8): 

if "%choice%"=="1" goto full_pipeline
if "%choice%"=="2" goto preprocessing
if "%choice%"=="3" goto reconstruction
if "%choice%"=="4" goto visualization
if "%choice%"=="5" goto select_data_dir
if "%choice%"=="6" goto set_params
if "%choice%"=="7" goto set_exp_names
if "%choice%"=="8" goto end

echo 无效选择，请重试
timeout /t 2 >nul
goto menu

:select_data_dir
cls
echo 选择数据目录
echo ============
echo 当前数据目录: %DATA_PATH%
echo.
echo 请输入新的数据目录路径 (留空则保持不变):
set /p new_data_path=
if not "%new_data_path%"=="" (
    if exist "%new_data_path%" (
        set DATA_PATH=%new_data_path%
        echo 数据目录已更新为: %DATA_PATH%
    ) else (
        echo 错误: 目录不存在!
        pause
    )
)
goto menu

:set_params
cls
echo 设置GPU和相机参数
echo ================
echo 当前GPU: %GPU%
echo 当前相机模型: %CAMERA%
echo.
set /p new_gpu=请输入GPU编号 (0, 1, 2, ...) (留空则保持不变): 
if not "%new_gpu%"=="" set GPU=%new_gpu%

echo.
echo 相机模型选项:
echo 1. PINHOLE (默认)
echo 2. OPENCV
echo 3. OPENCV_FISHEYE
echo 4. SIMPLE_PINHOLE
echo 5. SIMPLE_RADIAL
echo 6. RADIAL
echo 7. SIMPLE_RADIAL_FISHEYE
echo 8. RADIAL_FISHEYE
echo.
set /p cam_choice=请选择相机模型 (1-8) (留空则保持不变): 

if "%cam_choice%"=="1" set CAMERA=PINHOLE
if "%cam_choice%"=="2" set CAMERA=OPENCV
if "%cam_choice%"=="3" set CAMERA=OPENCV_FISHEYE
if "%cam_choice%"=="4" set CAMERA=SIMPLE_PINHOLE
if "%cam_choice%"=="5" set CAMERA=SIMPLE_RADIAL
if "%cam_choice%"=="6" set CAMERA=RADIAL
if "%cam_choice%"=="7" set CAMERA=SIMPLE_RADIAL_FISHEYE
if "%cam_choice%"=="8" set CAMERA=RADIAL_FISHEYE

echo.
echo GPU和相机参数已更新!
echo GPU: %GPU%
echo 相机模型: %CAMERA%
pause
goto menu

:set_exp_names
cls
echo 设置实验名称
echo ============
echo 当前实验名称: %EXP_NAME_1%, %EXP_NAME_2%, %EXP_NAME_3%
echo.
set /p new_exp_1=请输入实验名称1 (留空则保持不变 [%EXP_NAME_1%]): 
if not "%new_exp_1%"=="" set EXP_NAME_1=%new_exp_1%

set /p new_exp_2=请输入实验名称2 (留空则保持不变 [%EXP_NAME_2%]): 
if not "%new_exp_2%"=="" set EXP_NAME_2=%new_exp_2%

set /p new_exp_3=请输入实验名称3 (留空则保持不变 [%EXP_NAME_3%]): 
if not "%new_exp_3%"=="" set EXP_NAME_3=%new_exp_3%

echo.
echo 实验名称已更新为: %EXP_NAME_1%, %EXP_NAME_2%, %EXP_NAME_3%
pause
goto menu

:full_pipeline
echo 开始完整处理流程...

REM 运行预处理
call :preprocessing
if %ERRORLEVEL% neq 0 exit /b 1

REM 运行重建
call :reconstruction
if %ERRORLEVEL% neq 0 exit /b 1

REM 运行可视化
call :visualization
if %ERRORLEVEL% neq 0 exit /b 1

echo 完整处理流程已完成!
pause
goto menu

:preprocessing
echo 开始数据预处理...

REM 设置实验路径
set EXP_PATH_1=%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%

REM 提取视频帧
echo [1/13] 提取视频帧...
if not exist "%DATA_PATH%\images" mkdir "%DATA_PATH%\images"
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\extract_frames.py ^
    --input_path "%DATA_PATH%\raw.mp4" ^
    --output_path "%DATA_PATH%\images" ^
    --fps 5
if %ERRORLEVEL% neq 0 (
    echo 提取视频帧失败! 
    echo 可能原因: 视频文件不存在或格式不支持
    echo 解决方案: 确保raw.mp4存在于数据目录中，并且是有效的视频文件
    pause
    exit /b 1
)

REM 运行COLMAP
echo [2/13] 运行COLMAP...
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\run_colmap.py ^
    --data_path %DATA_PATH% ^
    --colmap_path %COLMAP_DIR% ^
    --camera_model %CAMERA%
if %ERRORLEVEL% neq 0 (
    echo COLMAP处理失败! 
    echo 可能原因: COLMAP未正确安装或图像质量问题
    echo 解决方案: 确保COLMAP已正确安装，并且图像质量足够好
    pause
    exit /b 1
)

REM 运行 Matte-Anything
echo [3/13] 运行 Matte-Anything...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\matte_anything" python %PROJECT_DIR%\ext\Matte-Anything\inference.py ^
    --input_dir %DATA_PATH%\images ^
    --output_dir %DATA_PATH%\masks ^
    --sam_checkpoint "%SAM_MODEL%" ^
    --text_prompt "hair" ^
    --model_type "vit_h" ^
    --device cuda:%GPU%
if %ERRORLEVEL% neq 0 (
    echo 运行 Matte-Anything 失败! 
    echo 可能原因: SAM模型文件不存在或CUDA内存不足
    echo 解决方案: 确保SAM模型文件已下载，或尝试使用更大内存的GPU
    pause
    exit /b 1
)

REM 创建图像副本
echo [4/13] 创建图像副本...
if not exist "%DATA_PATH%\images_2" mkdir "%DATA_PATH%\images_2"
if not exist "%DATA_PATH%\images_3" mkdir "%DATA_PATH%\images_3"
if not exist "%DATA_PATH%\images_4" mkdir "%DATA_PATH%\images_4"
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\copy_images.py ^
    --data_path %DATA_PATH%
if %ERRORLEVEL% neq 0 (
    echo 创建图像副本失败! 
    echo 可能原因: 源图像不存在或权限问题
    echo 解决方案: 确保源图像存在，并且有足够的权限
    pause
    exit /b 1
)

REM 运行图像裁剪
echo [5/13] 运行图像裁剪...
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\crop_images.py ^
    --data_path %DATA_PATH%
if %ERRORLEVEL% neq 0 (
    echo 图像裁剪失败! 
    echo 可能原因: 源图像不存在或格式不支持
    echo 解决方案: 确保源图像存在，并且是有效的图像文件
    pause
    exit /b 1
)

REM 运行图像缩放
echo [6/13] 运行图像缩放...
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\resize_images.py ^
    --data_path %DATA_PATH% ^
    --max_size 512
if %ERRORLEVEL% neq 0 (
    echo 图像缩放失败! 
    echo 可能原因: 源图像不存在或格式不支持
    echo 解决方案: 确保源图像存在，并且是有效的图像文件
    pause
    exit /b 1
)

REM 运行 OpenPose
echo [7/13] 运行 OpenPose...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\openpose" python %PROJECT_DIR%\src\preprocessing\run_openpose.py ^
    --openpose_dir %EXT_PATH%\openpose ^
    --data_dir %DATA_PATH% ^
    --model_dir "%OPENPOSE_MODEL%"
if %ERRORLEVEL% neq 0 (
    echo 运行 OpenPose 失败! 
    echo 可能原因: OpenPose模型文件不存在或编译问题
    echo 解决方案: 确保OpenPose模型文件已下载，并且OpenPose已正确编译
    pause
    exit /b 1
)

REM 运行 Face-Alignment
echo [8/13] 运行 Face-Alignment...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\run_face_alignment.py ^
    --data_dir %DATA_PATH% ^
    --model_path "%FACE_ALIGN_MODEL%"
if %ERRORLEVEL% neq 0 (
    echo 运行 Face-Alignment 失败! 
    echo 可能原因: Face-Alignment模型文件不存在或CUDA内存不足
    echo 解决方案: 确保Face-Alignment模型文件已下载，或尝试使用更大内存的GPU
    pause
    exit /b 1
)

REM 运行 PIXIE
echo [9/13] 运行 PIXIE...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\pixie" python %PROJECT_DIR%\src\preprocessing\run_pixie.py ^
    --pixie_dir %EXT_PATH%\PIXIE ^
    --data_dir %DATA_PATH% ^
    --model_path "%PIXIE_MODEL%"
if %ERRORLEVEL% neq 0 (
    echo 运行 PIXIE 失败! 
    echo 可能原因: PIXIE模型文件不存在或CUDA内存不足
    echo 解决方案: 确保PIXIE模型文件已下载，或尝试使用更大内存的GPU
    pause
    exit /b 1
)

REM 将所有PIXIE预测合并到单个文件中
echo [10/13] 合并PIXIE预测...
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\merge_pixie_predictions.py ^
    --data_path %DATA_PATH%
if %ERRORLEVEL% neq 0 (
    echo 合并PIXIE预测失败! 
    echo 可能原因: PIXIE预测文件不存在或格式不正确
    echo 解决方案: 确保PIXIE预测文件存在，并且格式正确
    pause
    exit /b 1
)

REM 运行FLAME拟合
echo [11/13] 运行FLAME拟合...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\run_flame_fitting.py ^
    --data_path %DATA_PATH% ^
    --flame_model_path "%FLAME_MODEL%" ^
    --exp_name %EXP_NAME_1%
if %ERRORLEVEL% neq 0 (
    echo FLAME拟合失败! 
    echo 可能原因: FLAME模型文件不存在或CUDA内存不足
    echo 解决方案: 确保FLAME模型文件已下载，或尝试使用更大内存的GPU
    pause
    exit /b 1
)

REM 准备3D高斯Splatting数据
echo [12/13] 准备3D高斯Splatting数据...
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\prepare_gaussian_splatting_data.py ^
    --data_path %DATA_PATH% ^
    --exp_name %EXP_NAME_1%
if %ERRORLEVEL% neq 0 (
    echo 准备3D高斯Splatting数据失败! 
    echo 可能原因: COLMAP结果不存在或格式不正确
    echo 解决方案: 确保COLMAP已成功运行，并且结果格式正确
    pause
    exit /b 1
)

REM 准备头发分割
echo [13/13] 准备头发分割...
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\prepare_hair_segmentation.py ^
    --data_path %DATA_PATH%
if %ERRORLEVEL% neq 0 (
    echo 准备头发分割失败! 
    echo 可能原因: 头发分割文件不存在或格式不正确
    echo 解决方案: 确保头发分割文件存在，并且格式正确
    pause
    exit /b 1
)

echo 数据预处理完成!
pause
exit /b 0

:reconstruction
echo 开始重建...
set EXP_PATH_1=%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%

REM 运行3D高斯Splatting重建
echo [1/10] 运行3D高斯Splatting重建...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\train.py ^
    -s %DATA_PATH% ^
    -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" ^
    --eval ^
    --save_iterations 30000 ^
    --iterations 30000 ^
    --port "800%GPU%"
if %ERRORLEVEL% neq 0 (
    echo 3D高斯Splatting重建失败! 
    echo 可能原因: CUDA内存不足或数据集问题
    echo 解决方案: 尝试减小图像大小或使用更大内存的GPU，检查数据集完整性
    pause
    exit /b 1
)

REM 运行FLAME网格拟合 (阶段1)
echo [2/10] 运行FLAME网格拟合 (阶段1)...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\fit.py ^
    --conf %PROJECT_DIR%\confs\train_person_1.conf ^
    --batch_size 32 ^
    --train_rotation False ^
    --train_shape False ^
    --save_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_1 ^
    --data_path %DATA_PATH% ^
    --fitted_camera_path %EXP_PATH_1%\cameras\30000_matrices.pkl ^
    --model_path "%FLAME_MODEL%"
if %ERRORLEVEL% neq 0 (
    echo FLAME网格拟合 (阶段1) 失败! 
    echo 可能原因: CUDA内存不足或FLAME模型问题
    echo 解决方案: 尝试减小batch_size或使用更大内存的GPU，检查FLAME模型完整性
    pause
    exit /b 1
)

REM 运行FLAME网格拟合 (阶段2)
echo [3/10] 运行FLAME网格拟合 (阶段2)...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\fit.py ^
    --conf %PROJECT_DIR%\confs\train_person_1.conf ^
    --batch_size 32 ^
    --train_rotation True ^
    --train_shape False ^
    --save_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_2 ^
    --checkpoint_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_1\opt_params_final ^
    --data_path %DATA_PATH% ^
    --fitted_camera_path %EXP_PATH_1%\cameras\30000_matrices.pkl ^
    --model_path %FLAME_MODEL%
if %ERRORLEVEL% neq 0 (
    echo FLAME网格拟合 (阶段2) 失败! 
    echo 可能原因: CUDA内存不足或阶段1结果问题
    echo 解决方案: 尝试减小batch_size或使用更大内存的GPU，检查阶段1结果完整性
    pause
    exit /b 1
)

REM 运行FLAME网格拟合 (阶段3)
echo [4/10] 运行FLAME网格拟合 (阶段3)...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\fit.py ^
    --conf %PROJECT_DIR%\confs\train_person_1.conf ^
    --batch_size 32 ^
    --train_rotation True ^
    --train_shape True ^
    --save_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_3 ^
    --checkpoint_path %DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_2\opt_params_final ^
    --data_path %DATA_PATH% ^
    --fitted_camera_path %EXP_PATH_1%\cameras\30000_matrices.pkl ^
    --model_path %FLAME_MODEL%
if %ERRORLEVEL% neq 0 (
    echo FLAME网格拟合 (阶段3) 失败! 
    echo 可能原因: CUDA内存不足或阶段2结果问题
    echo 解决方案: 尝试减小batch_size或使用更大内存的GPU，检查阶段2结果完整性
    pause
    exit /b 1
)

REM 裁剪重建场景
echo [5/10] 裁剪重建场景...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\scale_scene_into_sphere.py ^
    --path_to_data %DATA_PATH% ^
    -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" ^
    --iter 30000
if %ERRORLEVEL% neq 0 (
    echo 裁剪重建场景失败! 
    echo 可能原因: 3D高斯Splatting结果问题
    echo 解决方案: 检查3D高斯Splatting结果完整性
    pause
    exit /b 1
)

REM 删除与FLAME头部网格相交的头发高斯分布
echo [6/10] 过滤FLAME交叉点...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\filter_gaussians_by_flame.py ^
    --data_path %DATA_PATH% ^
    --model_path "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" ^
    --flame_mesh_path "%DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_3\mesh_final.obj" ^
    --iteration 30000
if %ERRORLEVEL% neq 0 (
    echo 过滤FLAME交叉点失败! 
    echo 可能原因: FLAME网格或3D高斯Splatting结果问题
    echo 解决方案: 检查FLAME网格和3D高斯Splatting结果完整性
    pause
    exit /b 1
)

REM 运行训练视图渲染
echo [7/10] 运行训练视图渲染...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\render.py ^
    -s %DATA_PATH% ^
    -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" ^
    --iteration 30000 ^
    --skip_test ^
    --skip_train ^
    --skip_video ^
    --output_path "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%\train_cropped" ^
    --flame_mesh_path "%DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_3\mesh_final.obj" ^
    --pointcloud_path_head "%EXP_PATH_1%\point_cloud_filtered\iteration_30000\raw_point_cloud.ply"
if %ERRORLEVEL% neq 0 (
    echo 运行训练视图渲染失败! 
    echo 可能原因: 3D高斯Splatting结果或FLAME网格问题
    echo 解决方案: 检查3D高斯Splatting结果和FLAME网格完整性
    pause
    exit /b 1
)

REM 获取FLAME网格头皮图
echo [8/10] 获取FLAME网格头皮图...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\extract_non_visible_head_scalp.py ^
    --project_dir %PROJECT_DIR%\ext\NeuralHaircut ^
    --data_dir %DATA_PATH% ^
    --flame_mesh_dir %DATA_PATH%\flame_fitting\%EXP_NAME_1% ^
    --cams_path %DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%\cameras\30000_matrices.pkl
if %ERRORLEVEL% neq 0 (
    echo 获取FLAME网格头皮图失败! 
    echo 可能原因: FLAME网格或相机矩阵问题
    echo 解决方案: 检查FLAME网格和相机矩阵完整性
    pause
    exit /b 1
)

REM 运行潜在头发链条重建
echo [9/10] 运行潜在头发链条重建...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\train_latent_strands.py ^
    -s %DATA_PATH% ^
    -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" ^
    -r 1 ^
    --model_path_hair "%DATA_PATH%\strands_reconstruction\%EXP_NAME_2%" ^
    --flame_mesh_dir "%DATA_PATH%\flame_fitting\%EXP_NAME_1%" ^
    --pointcloud_path_head "%EXP_PATH_1%\point_cloud_filtered\iteration_30000\raw_point_cloud.ply" ^
    --hair_conf_path "%PROJECT_DIR%\src\arguments\hair_strands_textured.yaml" ^
    --lambda_dmask 0.1 ^
    --lambda_dorient 0.1 ^
    --lambda_dsds 0.01 ^
    --load_synthetic_rgba ^
    --load_synthetic_geom ^
    --binarize_masks ^
    --iteration_data 30000 ^
    --trainable_cameras ^
    --trainable_intrinsics ^
    --use_barf ^
    --iterations 20000 ^
    --port "800%GPU%"
if %ERRORLEVEL% neq 0 (
    echo 运行潜在头发链条重建失败! 
    echo 可能原因: CUDA内存不足或前序步骤结果问题
    echo 解决方案: 尝试使用更大内存的GPU，检查前序步骤结果完整性
    pause
    exit /b 1
)

REM 运行头发链条重建
echo [10/10] 运行头发链条重建...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\train_strands.py ^
    -s %DATA_PATH% ^
    -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" ^
    -r 1 ^
    --model_path_curves "%DATA_PATH%\curves_reconstruction\%EXP_NAME_3%" ^
    --flame_mesh_dir "%DATA_PATH%\flame_fitting\%EXP_NAME_1%" ^
    --pointcloud_path_head "%EXP_PATH_1%\point_cloud_filtered\iteration_30000\raw_point_cloud.ply" ^
    --start_checkpoint_hair "%DATA_PATH%\strands_reconstruction\%EXP_NAME_2%\checkpoints\20000.pth" ^
    --hair_conf_path "%PROJECT_DIR%\src\arguments\hair_strands_textured.yaml" ^
    --lambda_dmask 0.1 ^
    --lambda_dorient 0.1 ^
    --lambda_dsds 0.01 ^
    --load_synthetic_rgba ^
    --load_synthetic_geom ^
    --binarize_masks ^
    --iteration_data 30000 ^
    --position_lr_init 0.0000016 ^
    --position_lr_max_steps 10000 ^
    --trainable_cameras ^
    --trainable_intrinsics ^
    --use_barf ^
    --iterations 10000 ^
    --port "800%GPU%"
if %ERRORLEVEL% neq 0 (
    echo 运行头发链条重建失败! 
    echo 可能原因: CUDA内存不足或前序步骤结果问题
    echo 解决方案: 尝试使用更大内存的GPU，检查前序步骤结果完整性
    pause
    exit /b 1
)

if exist "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%\train_cropped" rmdir /s /q "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%\train_cropped"

echo 重建完成! 
pause
exit /b 0

:visualization
echo 开始可视化...

REM 将结果链条导出为pkl和ply
echo [1/4] 导出结果链条...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\preprocessing\export_curves.py ^
    --data_dir %DATA_PATH% ^
    --model_name %EXP_NAME_3% ^
    --iter 10000 ^
    --flame_mesh_path "%DATA_PATH%\flame_fitting\%EXP_NAME_1%\stage_3\mesh_final.obj" ^
    --scalp_mesh_path "%DATA_PATH%\flame_fitting\%EXP_NAME_1%\scalp_data\scalp.obj" ^
    --hair_conf_path "%PROJECT_DIR%\src\arguments\hair_strands_textured.yaml"
if %ERRORLEVEL% neq 0 (
    echo 导出结果链条失败! 
    echo 可能原因: 模型文件损坏或不存在
    echo 解决方案: 确保重建步骤已成功完成，并且所有必要的文件都存在
    pause
    exit /b 1
)

REM 渲染可视化
echo [2/4] 渲染可视化...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\postprocessing\render_video.py ^
    --blender_path "%BLENDER_DIR%" ^
    --input_path "%DATA_PATH%" ^
    --exp_name_1 "%EXP_NAME_1%" ^
    --exp_name_3 "%EXP_NAME_3%"
if %ERRORLEVEL% neq 0 (
    echo 渲染可视化失败! 
    echo 可能原因: Blender路径错误或模型文件问题
    echo 解决方案: 确保Blender已正确安装，并且所有必要的模型文件都存在
    pause
    exit /b 1
)

REM 渲染链条
echo [3/4] 渲染链条...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\render_strands.py ^
    -s %DATA_PATH% ^
    --data_dir "%DATA_PATH%" ^
    --data_device "cpu" ^
    --skip_test ^
    -m "%DATA_PATH%\3d_gaussian_splatting\%EXP_NAME_1%" ^
    --iteration 30000 ^
    --flame_mesh_dir "%DATA_PATH%\flame_fitting\%EXP_NAME_1%" ^
    --model_hair_path "%DATA_PATH%\curves_reconstruction\%EXP_NAME_3%" ^
    --hair_conf_path "%PROJECT_DIR%\src\arguments\hair_strands_textured.yaml" ^
    --checkpoint_hair "%DATA_PATH%\strands_reconstruction\%EXP_NAME_2%\checkpoints\20000.pth" ^
    --checkpoint_curves "%DATA_PATH%\curves_reconstruction\%EXP_NAME_3%\checkpoints\10000.pth" ^
    --pointcloud_path_head "%EXP_PATH_1%\point_cloud_filtered\iteration_30000\raw_point_cloud.ply" ^
    --interpolate_cameras
if %ERRORLEVEL% neq 0 (
    echo 渲染链条失败! 
    echo 可能原因: 模型文件损坏或不存在
    echo 解决方案: 确保重建步骤已成功完成，并且所有必要的文件都存在
    pause
    exit /b 1
)

REM 制作视频
echo [4/4] 制作视频...
set CUDA_VISIBLE_DEVICES=%GPU%
call %MAMBA% run -p "%ENV_PATH%\gaussianhaircut" python %PROJECT_DIR%\src\postprocessing\concat_video.py ^
    --input_path "%DATA_PATH%" ^
    --exp_name_3 "%EXP_NAME_3%"
if %ERRORLEVEL% neq 0 (
    echo 制作视频失败! 
    echo 可能原因: 渲染图像不存在或格式不支持
    echo 解决方案: 确保前面的渲染步骤已成功完成
    pause
    exit /b 1
)

echo 可视化完成! 
echo 结果视频保存在: %DATA_PATH%\videos
pause
exit /b 0

:end
echo 感谢使用 GaussianHaircut! 
exit /b 0