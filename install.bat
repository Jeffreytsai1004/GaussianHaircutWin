CALL "%~dp0micromamba.exe" create -n gaussian_splatting_hair python==3.9 pip==23.3.1 git==2.41.0 -c pytorch -c conda-forge -r "%~dp0\" -y
@CALL "%~dp0micromamba.exe" shell init --shell cmd.exe --prefix "%~dp0\"
@CALL "%~dp0condabin\micromamba.bat" activate gaussian_splatting_hair
@CALL set GDOWN_CACHE=cache\gdown
@CALL set TORCH_HOME=cache\torch
@CALL set HF_HOME=cache\huggingface
@CALL set PYTHONDONTWRITEBYTECODE=1
@CALL set "PROJECT_DIR=%CD%"
@CALL set "DATA_PATH=%PROJECT_DIR%\data"
@CALL set "ENV_PATH=%PROJECT_DIR%\envs"
@CALL set "MAMBA=%PROJECT_DIR%\micromamba.exe"
@CALL set "CUDA_DIR=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"
@CALL set "BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6"
@CALL set "COLMAP_DIR=C:\Colmap\bin"
@CALL set "CMAKE_DIR=C:\Program Files\CMake\bin"
@CALL set "GIT_DIR=C:\Program Files\Git\bin"
@CALL set "VCVARS_DIR=D:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build"
@CALL set PATH=%PROJECT_DIR%;%PATH%;%CUDA_DIR%\bin;%CUDA_DIR%\libnvvp;%BLENDER_DIR%;%COLMAP_DIR%;%CMAKE_DIR%;%GIT_DIR%
@CALL python -m pip install --upgrade pip
@CALL python -m pip install torch==2.1.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir
@CALL python -m pip install -r requirements.txt

@echo ===== 创建必要目录 =====
@CALL mkdir ext 2>nul
@CALL mkdir data 2>nul
@CALL mkdir cache 2>nul
@CALL mkdir cache\gdown 2>nul
@CALL mkdir cache\torch 2>nul
@CALL mkdir cache\huggingface 2>nul
@CALL mkdir ext\diff_gaussian_rasterization_hair\third_party 2>nul

@echo ===== 克隆外部依赖库 =====
@CALL cd /d %PROJECT_DIR%\ext
@echo 克隆 openpose...
@CALL git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose --depth 1
@if %ERRORLEVEL% NEQ 0 @echo 克隆 openpose 失败，尝试使用镜像... && @CALL git clone https://github.com.cnpmjs.org/CMU-Perceptual-Computing-Lab/openpose --depth 1
@CALL cd openpose && git submodule update --init --recursive --remote
@CALL cd %PROJECT_DIR%\ext

@echo 克隆 Matte-Anything...
@CALL git clone https://github.com/hustvl/Matte-Anything
@CALL cd Matte-Anything && git clone https://github.com/IDEA-Research/GroundingDINO.git && git clone https://github.com/facebookresearch/segment-anything.git && git clone https://github.com/facebookresearch/detectron2.git
@CALL cd %PROJECT_DIR%\ext

@echo 克隆 NeuralHaircut...
@CALL git clone https://github.com/egorzakharov/NeuralHaircut.git --recursive

@echo 克隆 pytorch3d...
@CALL git clone https://github.com/facebookresearch/pytorch3d
@CALL cd pytorch3d && git checkout 2f11ddc5ee7d6bd56f2fb6744a16776fab6536f7
@CALL cd %PROJECT_DIR%\ext

@echo 克隆 simple-knn...
@CALL git clone https://github.com/camenduru/simple-knn

@echo 克隆 glm...
@CALL git clone https://github.com/g-truc/glm %PROJECT_DIR%\ext\diff_gaussian_rasterization_hair\third_party\glm
@CALL cd %PROJECT_DIR%\ext\diff_gaussian_rasterization_hair\third_party\glm
@CALL git checkout 5c46b9c07008ae65cb81ab79cd677ecc1934b903
@CALL cd %PROJECT_DIR%\ext

@echo 克隆 kaolin...
@CALL git clone --recursive https://github.com/NVIDIAGameWorks/kaolin
@CALL cd kaolin && git checkout v0.15.0
@CALL cd %PROJECT_DIR%\ext

@echo 克隆 hyperIQA...
@CALL git clone https://github.com/SSL92/hyperIQA

@echo 克隆 PIXIE...
@CALL git clone https://github.com/yfeng95/PIXIE

@echo ===== 下载模型文件 =====
@CALL cd %PROJECT_DIR%\ext\NeuralHaircut
@CALL python -m gdown --folder https://drive.google.com/drive/folders/1TCdJ0CKR3Q6LviovndOkJaKm8S1T9F_8

@echo 下载 diffusion prior...
@CALL cd %PROJECT_DIR%\ext\NeuralHaircut\pretrained_models\diffusion_prior
@CALL python -m gdown 1_9EOUXHayKiGH5nkrayncln3d6m1uV7f

@echo 下载 PIXIE 数据...
@CALL cd %PROJECT_DIR%\ext\NeuralHaircut\PIXIE
@CALL python -m gdown 1mPcGu62YPc4MdkT8FFiOCP629xsENHZf
@CALL tar -xzf pixie_data.tar.gz
@CALL del pixie_data.tar.gz

@echo 下载 hyperIQA 模型...
@CALL cd %PROJECT_DIR%\ext\hyperIQA
@CALL mkdir pretrained
@CALL cd pretrained
@CALL python -m gdown 1OOUmnbvpGea0LIGpIWEbOyxfWx6UCiiE

@echo ===== 创建 Matte-Anything 环境 =====
@CALL cd %PROJECT_DIR%
@CALL "%~dp0micromamba.exe" create -n matte_anything -c pytorch -c nvidia -c conda-forge ^
    pytorch=2.0.0 pytorch-cuda=11.8 torchvision tensorboard timm=0.5.4 opencv=4.5.3 ^
    mkl=2024.0 setuptools=58.2.0 easydict wget scikit-image gradio=3.46.1 fairscale -r "%~dp0\" -y

@echo 激活 matte_anything 环境...
@CALL "%~dp0condabin\micromamba.bat" activate matte_anything
@CALL cd %PROJECT_DIR%\ext\Matte-Anything\segment-anything
@CALL pip install -e .
@CALL cd %PROJECT_DIR%\ext\Matte-Anything\detectron2
@CALL pip install -e .
@CALL cd %PROJECT_DIR%\ext\Matte-Anything\GroundingDINO
@CALL pip install -e .
@CALL pip install supervision==0.22.0

@echo 下载 Matte-Anything 模型...
@CALL cd %PROJECT_DIR%\ext\Matte-Anything
@CALL mkdir pretrained
@CALL cd pretrained
@CALL powershell -Command "Invoke-WebRequest -Uri 'https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth' -OutFile 'sam_vit_h_4b8939.pth'"
@CALL powershell -Command "Invoke-WebRequest -Uri 'https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth' -OutFile 'groundingdino_swint_ogc.pth'"
@CALL python -m gdown 1d97oKuITCeWgai2Tf3iNilt6rMSSYzkW

@echo ===== 设置 OpenPose 环境 =====
@CALL "%~dp0condabin\micromamba.bat" activate gaussian_splatting_hair
@CALL cd %PROJECT_DIR%\ext\openpose
@CALL python -m gdown 1Yn03cKKfVOq4qXmgBMQD20UMRRRkd_tV
@CALL tar -xzf models.tar.gz
@CALL del models.tar.gz

@echo 创建 OpenPose 环境...
@CALL "%~dp0micromamba.exe" create -n openpose cmake=3.20 -c conda-forge -r "%~dp0\" -y
@CALL "%~dp0condabin\micromamba.bat" activate openpose

@echo 编译 OpenPose (可能需要较长时间)...
@CALL cd %PROJECT_DIR%\ext\openpose
@CALL if not exist build mkdir build
@CALL cd build

@echo 配置 OpenPose CMake...
@if exist "%VCVARS_DIR%\vcvarsall.bat" (
    @CALL "%VCVARS_DIR%\vcvarsall.bat" x64
    @CALL cmake .. -DBUILD_PYTHON=true -DUSE_CUDNN=OFF -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release
    @if %ERRORLEVEL% NEQ 0 (
        @CALL cmake .. -DBUILD_PYTHON=true -DUSE_CUDNN=OFF -G "Visual Studio 16 2019" -A x64 -DCMAKE_BUILD_TYPE=Release
    )
    @echo 编译 OpenPose...
    @CALL cmake --build . --config Release
) else (
    @echo 警告: 未找到Visual Studio的vcvarsall.bat，跳过编译OpenPose
)

@echo ===== 创建 PIXIE 环境 =====
@CALL cd %PROJECT_DIR%
@CALL "%~dp0micromamba.exe" create -n pixie -c pytorch -c nvidia -c fvcore -c conda-forge -c pytorch3d ^
    python=3.8 pytorch=2.0.0 torchvision=0.15.0 torchaudio=2.0.0 pytorch-cuda=11.8 fvcore pytorch3d=0.7.5 kornia matplotlib pyyaml==5.4.1 -r "%~dp0\" -y

@echo 激活 PIXIE 环境...
@CALL "%~dp0condabin\micromamba.bat" activate pixie
@CALL pip install gdown face-alignment
@CALL cd %PROJECT_DIR%\ext\PIXIE
@CALL powershell -Command "Invoke-WebRequest -Uri 'https://pixie.is.tue.mpg.de/media/uploads/pixie/pixie_model.tar' -OutFile 'pixie_model.tar'"
@CALL powershell -Command "Invoke-WebRequest -Uri 'https://pixie.is.tue.mpg.de/media/uploads/pixie/pixie_data.tar' -OutFile 'pixie_data.tar'"
@CALL tar -xf pixie_model.tar
@CALL tar -xf pixie_data.tar
@CALL del pixie_model.tar
@CALL del pixie_data.tar

@echo ===== 安装本地依赖 =====
@CALL "%~dp0condabin\micromamba.bat" activate gaussian_splatting_hair
@CALL cd %PROJECT_DIR%

@echo 安装 pytorch3d...
@CALL pip install -e ext/pytorch3d

@echo 安装 NeuralHaircut/npbgpp...
@CALL pip install -e ext/NeuralHaircut/npbgpp

@echo 安装 simple-knn...
@CALL pip install -e ext/simple-knn

@echo 安装 diff_gaussian_rasterization_hair...
@CALL pip install -e ext/diff_gaussian_rasterization_hair

@echo 安装 kaolin...
@CALL pip install -e ext/kaolin

@echo ===== 创建启动脚本 =====
@echo @CALL "%%~dp0micromamba.exe" shell init --shell cmd.exe --prefix "%%~dp0\" > start_gaussian_hair.bat
@echo @CALL "%%~dp0condabin\micromamba.bat" activate gaussian_splatting_hair >> start_gaussian_hair.bat
@echo @CALL "%%~dp0run.bat" >> start_gaussian_hair.bat
@echo @CALL pause >> start_gaussian_hair.bat

@echo.
@echo ===== 安装完成 =====
@echo 要运行项目，请双击 start_gaussian_hair.bat
@CALL pause





