@echo off
setlocal enabledelayedexpansion

echo.
echo ========= 环境变量设置 =========

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

REM 添加必要的路径到 PATH
set PATH=%CUDA_DIR%\bin;%BLENDER_DIR%;%COLMAP_DIR%;%CMAKE_DIR%;%GIT_DIR%;%PATH%

echo.
echo ========== 环境初始化 ==========

REM 检查micromamba是否存在
if not exist "%MAMBA%" (
    echo 错误：找不到micromamba.exe！
    echo 请从https://github.com/mamba-org/micromamba-releases/releases下载
    echo 并将其重命名为micromamba.exe放在项目根目录
    pause
    exit /b 1
)

REM 设置 micromamba 环境变量
echo 正在初始化micromamba环境...
set "MAMBA_ROOT_PREFIX=%ENV_PATH%"
set "MAMBA_NO_PROMPT=1"
echo micromamba环境初始化成功！

REM 创建主环境
call %MAMBA% create -p "%ENV_PATH%\gaussian_splatting_hair" -f environment.yml -y
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install --upgrade pip
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install gdown
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install -r requirements.txt

REM 检查colmap是否可用，如果不可用给出提示
where colmap >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo COLMAP未找到！请确保已安装COLMAP并添加到PATH
    echo 您可以从https://github.com/colmap/colmap/releases下载预编译的Windows版本
    echo 请下载COLMAP并将其安装在%COLMAP_DIR%目录，或更新PATH环境变量
    pause
)

REM 创建Matte-Anything环境
call %MAMBA% create -p "%ENV_PATH%\matte_anything" -c pytorch -c nvidia -c conda-forge ^
    pytorch=2.0.0 pytorch-cuda=11.8 torchvision tensorboard timm=0.5.4 opencv=4.5.3 ^
    mkl=2024.0 setuptools=58.2.0 easydict wget scikit-image gradio=3.46.1 fairscale -y
call %MAMBA% run -p "%ENV_PATH%\matte_anything" pip install --upgrade pip
call %MAMBA% run -p "%ENV_PATH%\matte_anything" pip install gdown

REM 创建OpenPose环境
call %MAMBA% create -p "%ENV_PATH%\openpose" -c conda-forge cmake=3.20 -y
call %MAMBA% run -p "%ENV_PATH%\openpose" pip install --upgrade pip
call %MAMBA% run -p "%ENV_PATH%\openpose" pip install gdown

REM 创建PIXIE环境
call %MAMBA% create -p "%ENV_PATH%\pixie" -c pytorch -c nvidia -c fvcore -c conda-forge -c pytorch3d ^
    python=3.8 pytorch=2.0.0 torchvision=0.15.0 torchaudio=2.0.0 pytorch-cuda=11.8 fvcore pytorch3d=0.7.5 kornia matplotlib pyyaml==5.4.1 -y
call %MAMBA% run -p "%ENV_PATH%\pixie" pip install --upgrade pip
call %MAMBA% run -p "%ENV_PATH%\pixie" pip install gdown
call %MAMBA% run -p "%ENV_PATH%\pixie" pip install face-alignment

echo.
echo ==== 克隆代码库和第三方依赖 ====

if not exist "%PROJECT_DIR%\ext" mkdir "%PROJECT_DIR%\ext"
cd /d "%PROJECT_DIR%\ext"

REM 克隆 openpose 并更新子模块
git clone --depth 1 https://github.com/CMU-Perceptual-Computing-Lab/openpose
cd openpose
git submodule update --init --recursive --remote
cd ..

REM 克隆 Matte-Anything 和 SegmentAnything, Detectron2, GroundingDINO
git clone https://github.com/hustvl/Matte-Anything
cd Matte-Anything
git clone https://github.com/facebookresearch/segment-anything
git clone https://github.com/facebookresearch/detectron2
git clone https://github.com/IDEA-Research/GroundingDINO.git
cd ..

REM 克隆 NeuralHaircut
git clone --recursive https://github.com/egorzakharov/NeuralHaircut

REM 克隆 pytorch3d 并切换至指定 commit
git clone https://github.com/facebookresearch/pytorch3d
cd pytorch3d
git checkout 2f11ddc5ee7d6bd56f2fb6744a16776fab6536f7
cd ..

REM 克隆 simple-knn
git clone https://github.com/camenduru/simple-knn

REM 确保目录存在
if not exist "diff_gaussian_rasterization_hair\third_party" mkdir "diff_gaussian_rasterization_hair\third_party"

REM 克隆 diff_gaussian_rasterization_hair 的 glm 子模块
git clone https://github.com/g-truc/glm diff_gaussian_rasterization_hair\third_party\glm
cd diff_gaussian_rasterization_hair\third_party\glm
git checkout 5c46b9c07008ae65cb81ab79cd677ecc1934b903
cd "%PROJECT_DIR%\ext"

REM 克隆 kaolin 并切换至v0.15.0
git clone --recursive https://github.com/NVIDIAGameWorks/kaolin
cd kaolin
git checkout v0.15.0
cd ..

REM 克隆 hyperIQA
git clone https://github.com/SSL92/hyperIQA

REM 克隆 PIXIE
git clone https://github.com/Jeffreytsai1004/PIXIE


cd "%PROJECT_DIR%"
echo 代码和依赖库克隆完成

echo.
echo ====== 下载预训练模型 ======

cd "%PROJECT_DIR%\ext\NeuralHaircut"
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install gdown
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" gdown --folder https://drive.google.com/drive/folders/1TCdJ0CKR3Q6LviovndOkJaKm8S1T9F_8
cd "%PROJECT_DIR%\ext\NeuralHaircut\pretrained_models\diffusion_prior"
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" gdown 1_9EOUXHayKiGH5nkrayncln3d6m1uV7f
cd "%PROJECT_DIR%\ext\NeuralHaircut\PIXIE"
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" gdown 1mPcGu62YPc4MdkT8FFiOCP629xsENHZf
tar -xvzf pixie_data.tar.gz
del pixie_data.tar.gz
cd "%PROJECT_DIR%\ext\hyperIQA"
if not exist pretrained mkdir pretrained
cd "%PROJECT_DIR%\ext\hyperIQA\pretrained"
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" gdown 1OOUmnbvpGea0LIGpIWEbOyxfWx6UCiiE
cd "%PROJECT_DIR%"

echo.
echo ===== Matte-Anything =====

REM 安装 segment-anything, detectron2 和 GroundingDINO
cd "%PROJECT_DIR%\ext\Matte-Anything\segment-anything"
call %MAMBA% run -p "%ENV_PATH%\matte_anything" pip install -e .
cd "%PROJECT_DIR%\ext\Matte-Anything\detectron2"
call %MAMBA% run -p "%ENV_PATH%\matte_anything" pip install -e .
cd "%PROJECT_DIR%\ext\Matte-Anything\GroundingDINO"
call %MAMBA% run -p "%ENV_PATH%\matte_anything" pip install -e .
cd "%PROJECT_DIR%\ext\Matte-Anything"
call %MAMBA% run -p "%ENV_PATH%\matte_anything" pip install supervision==0.22.0

REM 下载模型文件
if not exist pretrained mkdir pretrained
cd pretrained
powershell -Command "Invoke-WebRequest -Uri 'https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth' -OutFile 'sam_vit_h_4b8939.pth'"
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth' -OutFile 'groundingdino_swint_ogc.pth'"
call %MAMBA% run -p "%ENV_PATH%\matte_anything" gdown 1d97oKuITCeWgai2Tf3iNilt6rMSSYzkW

REM 下载openpose模型
cd "%PROJECT_DIR%\ext\openpose"
call %MAMBA% run -p "%ENV_PATH%\openpose" powershell -Command "Invoke-WebRequest -Uri 'https://drive.google.com/uc?export=download&id=1Yn03cKKfVOq4qXmgBMQD20UMRRRkd_tV' -OutFile 'models.tar.gz'"
tar -xvzf models.tar.gz
del models.tar.gz

REM 编译 openpose（需先使用 VS vcvarsall.bat）
cd "%PROJECT_DIR%\ext\openpose"
call "%VCVARS_DIR%\vcvarsall.bat" x64
REM 编译Openpose
mkdir build
cd build
cmake .. -DBUILD_PYTHON=true -DUSE_CUDNN=OFF -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release

REM PIXIE
REM 下载PIXIE模型
cd "%PROJECT_DIR%\ext\PIXIE"
if exist fetch_model.bat (
    call fetch_model.bat
) else (
    echo PIXIE模型下载脚本不存在，创建下载脚本...
    (
        echo @echo off
        echo powershell -Command "Invoke-WebRequest -Uri 'https://pixie.is.tue.mpg.de/media/uploads/pixie/pixie_model.tar' -OutFile 'pixie_model.tar'"
        echo powershell -Command "Invoke-WebRequest -Uri 'https://pixie.is.tue.mpg.de/media/uploads/pixie/pixie_data.tar' -OutFile 'pixie_data.tar'"
        echo tar -xf pixie_model.tar
        echo tar -xf pixie_data.tar
        echo del pixie_model.tar
        echo del pixie_data.tar
    ) > fetch_model.bat
    call fetch_model.bat
)

REM 切换回主环境，安装本地依赖
echo.
echo ========= 安装本地依赖 =========

cd "%PROJECT_DIR%"
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install -e ext/pytorch3d
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install -e ext/NeuralHaircut/npbgpp
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install -e ext/simple-knn
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install -e ext/diff_gaussian_rasterization_hair
call %MAMBA% run -p "%ENV_PATH%\gaussian_splatting_hair" pip install -e ext/kaolin

echo.
echo ==== 安装完成，请确认所有步骤无误 ====

pause
