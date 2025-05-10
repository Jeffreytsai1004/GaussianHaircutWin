@echo off
setlocal enabledelayedexpansion

REM 环境变量设置（去掉引号，全部为目录，不带可执行文件名）
set PROJECT_DIR=%CD%
set DATA_PATH=%PROJECT_DIR%\data
set MAMBA=%PROJECT_DIR%\micromamba.exe
set CUDA_DIR=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8
set BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6
set COLMAP_DIR=C:\Colmap\bin
set CMAKE_DIR=C:\Program Files\CMake\bin
set GIT_DIR=C:\Program Files\Git\bin

REM 添加所有依赖到PATH
set PATH=%PATH%;%CUDA_DIR%\bin;%BLENDER_DIR%;%COLMAP_DIR%;%CMAKE_DIR%;%GIT_DIR%;%PROJECT_DIR%

REM 确保gdown可用
pip install -U gdown

REM 检查必要的软件是否安装
echo 检查必要软件中...

REM 检查CUDA
where nvcc >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo CUDA未安装或未添加到PATH！
    echo 请从https://developer.nvidia.com/cuda-11-8-0-download-archive安装CUDA 11.8
    echo 请确保将CUDA的bin目录添加到PATH环境变量
    echo 例如: C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8\bin
    pause
    exit /b 1
)

REM 检查CUDA版本
for /f "tokens=*" %%i in ('nvcc --version') do (
    echo %%i | findstr "11.8" >nul 2>nul
    if !ERRORLEVEL! equ 0 (
        echo 已检测到CUDA 11.8
        goto cuda_ok
    )
)
echo 警告: 未检测到CUDA 11.8，项目需要CUDA 11.8版本
echo 是否继续？(Y/N)
set /p CONTINUE=
if /i "!CONTINUE!" neq "Y" (
    exit /b 1
)
:cuda_ok

REM 检查Blender
where blender >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Blender未安装或未添加到PATH！
    echo 请从https://www.blender.org/download/lts/3-6下载并安装Blender 3.6
    echo 然后将Blender的安装目录添加到PATH环境变量
    echo 例如: %BLENDER_DIR%
    pause
    exit /b 1
)

REM 检查CMake
where cmake >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo CMake未安装或未添加到PATH！
    echo 请安装CMake并将其添加到PATH环境变量
    echo 下载地址: https://cmake.org/download/
    echo 例如: %CMAKE_DIR%
    pause
    exit /b 1
)

REM 检查COLMAP
where colmap >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo COLMAP未安装或未添加到PATH！
    echo 请从https://github.com/colmap/colmap/releases下载并安装COLMAP
    echo 然后将COLMAP的安装目录添加到PATH环境变量
    echo 例如: %COLMAP_DIR%
    pause
    exit /b 1
)

REM 检查Git
where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Git未安装或未添加到PATH！
    echo 请安装Git并将其添加到PATH环境变量
    echo 下载地址: https://git-scm.com/download/win
    echo 例如: %GIT_DIR%
    pause
    exit /b 1
)

:skip_checks

REM 保存项目目录
set PROJECT_DIR=%CD%

REM 创建ext目录
if not exist ext mkdir ext

REM 克隆所需的仓库
echo 正在克隆外部库...
if "%1"=="TEST" (
    echo 测试模式：模拟克隆外部库...
    if not exist %PROJECT_DIR%\ext\diff_gaussian_rasterization_hair\third_party mkdir %PROJECT_DIR%\ext\diff_gaussian_rasterization_hair\third_party
    echo 模拟完成：外部库克隆
) else (
    cd %PROJECT_DIR%\ext && git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose --depth 1
    cd %PROJECT_DIR%\ext\openpose && git submodule update --init --recursive --remote
    cd %PROJECT_DIR%\ext && git clone https://github.com/hustvl/Matte-Anything
    cd %PROJECT_DIR%\ext\Matte-Anything && git clone https://github.com/IDEA-Research/GroundingDINO.git
    cd %PROJECT_DIR%\ext && git clone https://github.com/egorzakharov/NeuralHaircut.git --recursive
    cd %PROJECT_DIR%\ext && git clone https://github.com/facebookresearch/pytorch3d
    cd %PROJECT_DIR%\ext\pytorch3d && git checkout 2f11ddc5ee7d6bd56f2fb6744a16776fab6536f7
    cd %PROJECT_DIR%\ext && git clone https://github.com/camenduru/simple-knn
    if not exist %PROJECT_DIR%\ext\diff_gaussian_rasterization_hair\third_party mkdir %PROJECT_DIR%\ext\diff_gaussian_rasterization_hair\third_party
    cd %PROJECT_DIR%\ext\diff_gaussian_rasterization_hair\third_party && git clone https://github.com/g-truc/glm
    cd %PROJECT_DIR%\ext\diff_gaussian_rasterization_hair\third_party\glm && git checkout 5c46b9c07008ae65cb81ab79cd677ecc1934b903
    cd %PROJECT_DIR%\ext && git clone --recursive https://github.com/NVIDIAGameWorks/kaolin
    cd %PROJECT_DIR%\ext\kaolin && git checkout v0.15.0
    cd %PROJECT_DIR%\ext && git clone https://github.com/SSL92/hyperIQA
)

REM 使用micromamba创建环境
echo 正在创建环境...
if "%1"=="TEST" (
    echo 测试模式：模拟创建环境...
    echo 模拟完成：环境创建
) else (
    cd %PROJECT_DIR%
    %MAMBA% create -f environment.yml
    %MAMBA% shell init -s cmd.exe
    call %USERPROFILE%\.micromamba\micromambarc.cmd
    %MAMBA% activate gaussian_splatting_hair
)

REM 下载Neural Haircut文件
echo 正在下载Neural Haircut文件...
if "%1"=="TEST" (
    echo 测试模式：模拟下载Neural Haircut文件...
    echo 模拟完成：Neural Haircut文件下载
) else (
    cd %PROJECT_DIR%\ext\NeuralHaircut
    pip install gdown
    gdown --folder https://drive.google.com/drive/folders/1TCdJ0CKR3Q6LviovndOkJaKm8S1T9F_8
    cd %PROJECT_DIR%\ext\NeuralHaircut\pretrained_models\diffusion_prior
    gdown 1_9EOUXHayKiGH5nkrayncln3d6m1uV7f
    cd %PROJECT_DIR%\ext\NeuralHaircut\PIXIE
    gdown 1mPcGu62YPc4MdkT8FFiOCP629xsENHZf
    tar -xvzf pixie_data.tar.gz ./
    del pixie_data.tar.gz
    cd %PROJECT_DIR%\ext\hyperIQA
    mkdir pretrained
    cd pretrained
    gdown 1OOUmnbvpGea0LIGpIWEbOyxfWx6UCiiE
    cd %PROJECT_DIR%
)

REM 创建并配置Matte-Anything环境
echo 正在设置Matte-Anything环境...
if "%1"=="TEST" (
    echo 测试模式：模拟设置Matte-Anything环境...
    echo 模拟完成：Matte-Anything环境设置
) else (
    %MAMBA% create -n matte_anything -c pytorch -c nvidia -c conda-forge pytorch=2.0.0 pytorch-cuda=11.8 torchvision tensorboard timm=0.5.4 opencv=4.5.3 mkl=2024.0 setuptools=58.2.0 easydict wget scikit-image gradio=3.46.1 fairscale
    %MAMBA% activate matte_anything
    pip install git+https://github.com/facebookresearch/segment-anything.git
    python -m pip install git+https://github.com/facebookresearch/detectron2.git
    cd %PROJECT_DIR%\ext\Matte-Anything\GroundingDINO && pip install -e .
    pip install supervision==0.22.0
    cd %PROJECT_DIR%\ext\Matte-Anything && mkdir pretrained
    cd %PROJECT_DIR%\ext\Matte-Anything\pretrained
    curl -LO https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth
    curl -LO https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth
    %MAMBA% activate gaussian_splatting_hair
    pip install gdown
    gdown 1d97oKuITCeWgai2Tf3iNilt6rMSSYzkW
)

REM 设置OpenPose
echo 正在设置OpenPose...
if "%1"=="TEST" (
    echo 测试模式：模拟设置OpenPose...
    echo 模拟完成：OpenPose设置
) else (
    cd %PROJECT_DIR%\ext\openpose
    gdown 1Yn03cKKfVOq4qXmgBMQD20UMRRRkd_tV
    tar -xvzf models.tar.gz
    del models.tar.gz
    git submodule update --init --recursive --remote
    %MAMBA% create -n openpose -c conda-forge cmake=3.20
    %MAMBA% activate openpose
    mkdir build
    cd build
    cmake .. -DBUILD_PYTHON=true -DUSE_CUDNN=off
    cmake --build . --config Release
)

REM 设置PIXIE
echo 正在设置PIXIE...
if "%1"=="TEST" (
    echo 测试模式：模拟设置PIXIE...
    echo 模拟完成：PIXIE设置
) else (
    cd %PROJECT_DIR%\ext && git clone https://github.com/yfeng95/PIXIE
    cd %PROJECT_DIR%\ext\PIXIE
    powershell -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/yfeng95/PIXIE/master/fetch_model.sh' -OutFile 'fetch_model.ps1'; (Get-Content 'fetch_model.ps1') -replace 'wget', 'curl -LO' | Set-Content 'fetch_model.ps1'; ./fetch_model.ps1}"
    %MAMBA% create -n pixie-env -c pytorch -c nvidia -c fvcore -c conda-forge -c pytorch3d python=3.8 pytorch==2.0.0 torchvision==0.15.0 torchaudio==2.0.0 pytorch-cuda=11.8 fvcore pytorch3d==0.7.5 kornia matplotlib
    %MAMBA% activate pixie-env
    pip install pyyaml==5.4.1
    pip install git+https://github.com/1adrianb/face-alignment.git@54623537fd9618ca7c15688fd85aba706ad92b59
)

echo 安装完成！
echo 请运行run.bat来执行重建过程。
pause
