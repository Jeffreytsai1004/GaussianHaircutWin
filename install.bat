@echo off
setlocal EnableDelayedExpansion

echo ===== GaussianHaircut Windows Installation =====
echo Setting up environment...

REM 检查微型Mamba
if not exist "%~dp0micromamba.exe" (
    echo ERROR: Missing micromamba.exe in project directory
    echo Please download from: https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-win-64.exe
    echo Rename it to micromamba.exe and place it in this directory
    pause
    exit /b 1
)

REM 创建基础目录
echo Creating directories...
mkdir "%~dp0cache" 2>nul
mkdir "%~dp0cache\gdown" 2>nul
mkdir "%~dp0cache\torch" 2>nul
mkdir "%~dp0cache\huggingface" 2>nul
mkdir "%~dp0data" 2>nul
mkdir "%~dp0ext" 2>nul
mkdir "%~dp0ext\diff_gaussian_rasterization_hair" 2>nul
mkdir "%~dp0ext\diff_gaussian_rasterization_hair\third_party" 2>nul

REM 设置环境变量
set "PROJECT_DIR=%~dp0"
set "DATA_PATH=%PROJECT_DIR%data"
set "MAMBA_ROOT_PREFIX=%PROJECT_DIR%"
set "MAMBA_EXE=%PROJECT_DIR%micromamba.exe"
set "GDOWN_CACHE=%PROJECT_DIR%cache\gdown"
set "TORCH_HOME=%PROJECT_DIR%cache\torch"
set "HF_HOME=%PROJECT_DIR%cache\huggingface"
set "PYTHONDONTWRITEBYTECODE=1"

REM 检测CUDA路径
echo Detecting CUDA path...
set "CUDA_DIR=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"
if exist "%CUDA_DIR%\bin\nvcc.exe" (
    echo Found CUDA at %CUDA_DIR%
) else (
    echo WARNING: CUDA 11.8 not found at default location
    echo Please ensure CUDA is installed
    echo Continuing with default path: %CUDA_DIR%
)

REM 检测Blender路径
set "BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6"
if exist "%BLENDER_DIR%\blender.exe" (
    echo Found Blender at %BLENDER_DIR%
) else (
    echo WARNING: Blender 3.6 not found at default location
    echo Continuing with default path: %BLENDER_DIR%
)

REM 检测COLMAP路径
set "COLMAP_DIR=C:\Colmap\bin"
if exist "%COLMAP_DIR%\colmap.exe" (
    echo Found COLMAP at %COLMAP_DIR%
) else (
    echo WARNING: COLMAP not found at default location
    echo Continuing with default path: %COLMAP_DIR%
)

REM 检测Visual Studio路径
set "VCVARS_DIR=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build"
if exist "%VCVARS_DIR%\vcvarsall.bat" (
    echo Found Visual Studio at %VCVARS_DIR%
) else (
    echo WARNING: Visual Studio not found at default location
    echo OpenPose compilation may fail
)

REM 更新PATH
set "PATH=%CUDA_DIR%\bin;%BLENDER_DIR%;%COLMAP_DIR%;%PATH%"

echo.
echo ===== Creating Main Environment =====
echo.

REM 创建主环境
echo Creating gaussian_splatting_hair environment...
"%MAMBA_EXE%" create -n gaussian_splatting_hair python=3.9 pip=23.3.1 git=2.41.0 -c pytorch -c conda-forge -r "%PROJECT_DIR%" -y
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create main environment
    echo Trying alternative method...
    "%MAMBA_EXE%" create -n gaussian_splatting_hair python=3.9 -y -c conda-forge -r "%PROJECT_DIR%"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Environment creation failed
        pause
        exit /b 1
    )
)

REM 设置shell hook
echo Setting up shell hook...
"%MAMBA_EXE%" shell init --shell cmd.exe --prefix "%PROJECT_DIR%"

REM 激活环境
echo Activating environment...
call "%PROJECT_DIR%condabin\micromamba.bat" activate gaussian_splatting_hair
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Failed to activate environment using standard method
    echo Trying alternative activation...
    "%MAMBA_EXE%" run -n gaussian_splatting_hair -p "%PROJECT_DIR%" echo Environment active
)

REM 安装PyTorch
echo Installing PyTorch...
pip install torch==2.1.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install PyTorch
    pause
    exit /b 1
)

REM 安装其他依赖
echo Installing requirements...
pip install -r requirements.txt

echo.
echo ===== Creating Additional Environments =====
echo.

REM 创建Matte-Anything环境
echo Creating matte_anything environment...
"%MAMBA_EXE%" create -n matte_anything python=3.9 pytorch=2.0.0 pytorch-cuda=11.8 torchvision tensorboard opencv -c pytorch -c nvidia -c conda-forge -r "%PROJECT_DIR%" -y
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create matte_anything environment
    pause
)

REM 创建OpenPose环境
echo Creating openpose environment...
"%MAMBA_EXE%" create -n openpose cmake=3.20 -c conda-forge -r "%PROJECT_DIR%" -y
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create openpose environment
    pause
)

REM 创建PIXIE环境
echo Creating pixie environment...
"%MAMBA_EXE%" create -n pixie python=3.8 pytorch=2.0.0 pytorch-cuda=11.8 -c pytorch -c nvidia -c conda-forge -r "%PROJECT_DIR%" -y
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create pixie environment
    pause
)

echo.
echo ===== Cloning Repositories =====
echo.

REM 克隆代码库
call "%PROJECT_DIR%condabin\micromamba.bat" activate gaussian_splatting_hair
cd /d "%PROJECT_DIR%ext"

echo Cloning OpenPose...
if not exist "openpose" (
    git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose --depth 1
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to clone OpenPose
        echo Trying alternative mirror...
        git clone https://github.com.cnpmjs.org/CMU-Perceptual-Computing-Lab/openpose --depth 1
    )
    cd openpose
    git submodule update --init --recursive --remote
    cd ..
) else (
    echo OpenPose already exists, skipping...
)

echo Cloning Matte-Anything...
if not exist "Matte-Anything" (
    git clone https://github.com/hustvl/Matte-Anything
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to clone Matte-Anything
    ) else (
        cd Matte-Anything
        git clone https://github.com/IDEA-Research/GroundingDINO.git
        git clone https://github.com/facebookresearch/segment-anything.git
        git clone https://github.com/facebookresearch/detectron2.git
        cd ..
    )
) else (
    echo Matte-Anything already exists, skipping...
)

echo Cloning NeuralHaircut...
if not exist "NeuralHaircut" (
    git clone https://github.com/egorzakharov/NeuralHaircut.git --recursive
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to clone NeuralHaircut
    )
) else (
    echo NeuralHaircut already exists, skipping...
)

echo Cloning pytorch3d...
if not exist "pytorch3d" (
    git clone https://github.com/facebookresearch/pytorch3d
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to clone pytorch3d
    ) else (
        cd pytorch3d
        git checkout 2f11ddc5ee7d6bd56f2fb6744a16776fab6536f7
        cd ..
    )
) else (
    echo pytorch3d already exists, skipping...
)

echo Cloning additional repositories...
if not exist "simple-knn" (
    git clone https://github.com/camenduru/simple-knn
)

if not exist "diff_gaussian_rasterization_hair\third_party\glm" (
    git clone https://github.com/g-truc/glm diff_gaussian_rasterization_hair\third_party\glm
    cd diff_gaussian_rasterization_hair\third_party\glm
    git checkout 5c46b9c07008ae65cb81ab79cd677ecc1934b903
    cd ..\..\..\
)

if not exist "kaolin" (
    git clone --recursive https://github.com/NVIDIAGameWorks/kaolin
    cd kaolin
    git checkout v0.15.0
    cd ..
)

if not exist "hyperIQA" (
    git clone https://github.com/SSL92/hyperIQA
)

if not exist "PIXIE" (
    git clone https://github.com/yfeng95/PIXIE
)

echo.
echo ===== Installing pip in each environment =====
echo.

REM 为每个环境安装pip包
echo Installing packages in matte_anything environment...
call "%PROJECT_DIR%condabin\micromamba.bat" activate matte_anything
cd "%PROJECT_DIR%ext\Matte-Anything\segment-anything"
if exist "%PROJECT_DIR%ext\Matte-Anything\segment-anything" (
    pip install -e .
)

cd "%PROJECT_DIR%ext\Matte-Anything\detectron2"
if exist "%PROJECT_DIR%ext\Matte-Anything\detectron2" (
    pip install -e .
)

cd "%PROJECT_DIR%ext\Matte-Anything\GroundingDINO"
if exist "%PROJECT_DIR%ext\Matte-Anything\GroundingDINO" (
    pip install -e .
)

pip install supervision==0.22.0

echo Installing packages in pixie environment...
call "%PROJECT_DIR%condabin\micromamba.bat" activate pixie
pip install face-alignment pyyaml==5.4.1 kornia matplotlib

echo Installing gdown in openpose environment...
call "%PROJECT_DIR%condabin\micromamba.bat" activate openpose
pip install gdown

echo.
echo ===== Installing local dependencies =====
echo.

call "%PROJECT_DIR%condabin\micromamba.bat" activate gaussian_splatting_hair
cd "%PROJECT_DIR%"

echo Installing pytorch3d...
if exist "ext\pytorch3d" (
    pip install -e ext/pytorch3d
)

echo Installing NeuralHaircut/npbgpp...
if exist "ext\NeuralHaircut\npbgpp" (
    pip install -e ext/NeuralHaircut/npbgpp
)

echo Installing simple-knn...
if exist "ext\simple-knn" (
    pip install -e ext/simple-knn
)

echo Installing diff_gaussian_rasterization_hair...
if exist "ext\diff_gaussian_rasterization_hair" (
    pip install -e ext/diff_gaussian_rasterization_hair
)

echo Installing kaolin...
if exist "ext\kaolin" (
    pip install -e ext/kaolin
)

echo.
echo ===== Creating activation script =====
echo.

echo Creating start_gaussian_hair.bat...
(
    echo @echo off
    echo call "%PROJECT_DIR%micromamba.exe" shell init --shell cmd.exe --prefix "%PROJECT_DIR%"
    echo call "%PROJECT_DIR%condabin\micromamba.bat" activate gaussian_splatting_hair
    echo echo Environment activated, you can now run: run.bat
    echo pause
) > start_gaussian_hair.bat

echo.
echo ===== Installation complete =====
echo The basic environment has been set up.
echo.
echo NOTE: Model downloads will be performed during first run
echo NOTE: Some components may require additional setup
echo.
echo To start using GaussianHaircut:
echo 1. Run start_gaussian_hair.bat to activate the environment
echo 2. Then run run.bat to start the program
echo.
pause 