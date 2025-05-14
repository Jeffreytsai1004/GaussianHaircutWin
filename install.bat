@echo off
@REM 初始化安装过程
@echo ==== GaussianHaircut Windows 安装脚本 ====
@echo 正在准备环境...

@REM 清理可能存在的旧环境（防止文件占用问题）
@echo 清理可能存在的旧环境...
@CALL taskkill /f /im micromamba.exe 2>nul

@REM 设置必要的环境变量
@CALL set PROJECT_DIR=%~dp0
@CALL set MAMBA_ROOT_PREFIX=%~dp0
@CALL set MAMBA_EXE=%~dp0micromamba.exe
@CALL set PATH=%MAMBA_ROOT_PREFIX%\Library\bin;%MAMBA_ROOT_PREFIX%\Scripts;%MAMBA_ROOT_PREFIX%\condabin;%PATH%
@CALL set GDOWN_CACHE=cache\gdown
@CALL set TORCH_HOME=cache\torch
@CALL set HF_HOME=cache\huggingface
@CALL set PYTHONDONTWRITEBYTECODE=1
@REM 设置其他环境变量
@CALL set DATA_PATH=%PROJECT_DIR%data
@CALL set ENV_PATH=%PROJECT_DIR%envs
@CALL set MAMBA=%PROJECT_DIR%micromamba.exe
@CALL set CUDA_DIR=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8
@CALL set BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6
@CALL set COLMAP_DIR=C:\Colmap\bin
@CALL set CMAKE_DIR=C:\Program Files\CMake\bin
@CALL set GIT_DIR=C:\Program Files\Git\bin
@CALL set VCVARS_DIR=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build
@CALL set PATH=%CUDA_DIR%\bin;%BLENDER_DIR%;%COLMAP_DIR%;%CMAKE_DIR%;%GIT_DIR%;%PATH%

@REM 清理旧目录
@CALL rd /s /q "%MAMBA_ROOT_PREFIX%envs" 2>nul
@CALL rd /s /q "%MAMBA_ROOT_PREFIX%Library\bin" 2>nul
@CALL rd /s /q "%MAMBA_ROOT_PREFIX%Scripts" 2>nul
@CALL rd /s /q "%MAMBA_ROOT_PREFIX%condabin" 2>nul
@CALL rd /s /q "%PROJECT_DIR%cache" 2>nul

@REM 创建必要的目录结构
@CALL mkdir "%MAMBA_ROOT_PREFIX%envs" 2>nul
@CALL mkdir "%MAMBA_ROOT_PREFIX%Library\bin" 2>nul
@CALL mkdir "%MAMBA_ROOT_PREFIX%Scripts" 2>nul
@CALL mkdir "%MAMBA_ROOT_PREFIX%condabin" 2>nul
@CALL mkdir "%PROJECT_DIR%\data" 2>nul

@echo.
@echo ==== 创建主环境 ====

@REM 使用绝对路径引用，确保脚本在任何位置运行都能找到micromamba
@CALL "%~dp0micromamba.exe" create -n gaussian_splatting_hair -f environment.yml -r "%~dp0\" -y
@CALL IF %ERRORLEVEL% NEQ 0 (
    @echo 创建环境失败，请检查错误信息
    @CALL pause
    @exit /b 1
)

@REM 直接激活环境而不使用shell hook
@CALL "%~dp0micromamba.exe" shell hook --shell cmd.exe --prefix "%~dp0\" >nul 2>&1
@CALL "%~dp0condabin\micromamba.bat" activate gaussian_splatting_hair
@CALL IF %ERRORLEVEL% NEQ 0 (
    @echo 激活环境失败，尝试替代方案...
    @CALL "%~dp0micromamba.exe" run -n gaussian_splatting_hair -r "%~dp0\" echo 环境测试
    @CALL IF %ERRORLEVEL% NEQ 0 (
        @echo 环境激活替代方案也失败，请检查安装
        @CALL pause
        @exit /b 1
    )
)

@echo.
@echo ==== 创建附加环境 ====

@REM 创建 Matte-Anything 环境
@CALL "%~dp0micromamba.exe" create -n matte_anything -c pytorch -c nvidia -c conda-forge ^
    pytorch=2.0.0 pytorch-cuda=11.8 torchvision tensorboard timm=0.5.4 opencv=4.5.3 ^
    mkl=2024.0 setuptools=58.2.0 easydict wget scikit-image gradio=3.46.1 fairscale -r "%~dp0\" -y
@CALL IF %ERRORLEVEL% NEQ 0 (
    @echo 创建matte_anything环境失败，请检查错误信息
    @CALL pause
    @exit /b 1
)

@REM 创建 OpenPose 环境
@CALL "%~dp0micromamba.exe" create -n openpose cmake=3.20 -c conda-forge -r "%~dp0\" -y
@CALL "%~dp0condabin\micromamba.bat" activate openpose
@CALL pip install gdown

@REM 创建 PIXIE 环境
@CALL "%~dp0micromamba.exe" create -n pixie -c pytorch -c nvidia -c fvcore -c conda-forge -c pytorch3d ^
    python=3.8 pytorch=2.0.0 torchvision=0.15.0 torchaudio=2.0.0 pytorch-cuda=11.8 fvcore pytorch3d=0.7.5 kornia matplotlib pyyaml==5.4.1 -r "%~dp0\" -y
@CALL "%~dp0condabin\micromamba.bat" activate pixie
@CALL pip install gdown face-alignment -i https://pypi.tuna.tsinghua.edu.cn/simple

@REM 回到主环境
@CALL "%~dp0condabin\micromamba.bat" activate gaussian_splatting_hair

@echo.
@echo ==== 克隆代码库和第三方依赖 ====

@CALL cd /d "%PROJECT_DIR%\ext"

@REM 克隆 openpose 并更新子模块
@CALL git clone --depth 1 https://github.com/CMU-Perceptual-Computing-Lab/openpose
@CALL IF %ERRORLEVEL% NEQ 0 (
    @echo 克隆openpose失败，请检查网络连接
    @CALL pause
    @exit /b 1
)
@CALL cd openpose
@CALL git submodule update --init --recursive --remote
@CALL cd ..

@REM 克隆 Matte-Anything 和 SegmentAnything, Detectron2, GroundingDINO
@CALL git clone https://github.com/hustvl/Matte-Anything
@CALL cd Matte-Anything
@CALL git clone https://github.com/facebookresearch/segment-anything
@CALL git clone https://github.com/facebookresearch/detectron2
@CALL git clone https://github.com/IDEA-Research/GroundingDINO.git
@CALL cd ..

@REM 克隆 NeuralHaircut
@CALL git clone --recursive https://github.com/egorzakharov/NeuralHaircut

@REM 克隆 pytorch3d 并切换至指定 commit
@CALL git clone https://github.com/facebookresearch/pytorch3d
@CALL cd pytorch3d
@CALL git checkout 2f11ddc5ee7d6bd56f2fb6744a16776fab6536f7
@CALL cd ..

@REM 克隆 simple-knn
@CALL git clone https://github.com/camenduru/simple-knn

@REM 确保目录存在
@CALL if not exist "diff_gaussian_rasterization_hair\third_party" mkdir "diff_gaussian_rasterization_hair\third_party"

@REM 克隆 diff_gaussian_rasterization_hair 的 glm 子模块
@CALL git clone https://github.com/g-truc/glm diff_gaussian_rasterization_hair\third_party\glm
@CALL cd diff_gaussian_rasterization_hair\third_party\glm
@CALL git checkout 5c46b9c07008ae65cb81ab79cd677ecc1934b903
@CALL cd "%PROJECT_DIR%\ext"

@REM 克隆 kaolin 并切换至v0.15.0
@CALL git clone --recursive https://github.com/NVIDIAGameWorks/kaolin
@CALL cd kaolin
@CALL git checkout v0.15.0
@CALL cd ..

@REM 克隆 hyperIQA
@CALL git clone https://github.com/SSL92/hyperIQA

@REM 克隆 PIXIE
@CALL git clone https://github.com/Jeffreytsai1004/PIXIE

@CALL cd "%PROJECT_DIR%"
@echo 代码和依赖库克隆完成

@echo.
@echo ====== 下载预训练模型 ======

@CALL cd "%PROJECT_DIR%\ext\NeuralHaircut"
@CALL "%~dp0micromamba.exe" run -n openpose -r "%~dp0\" gdown --folder https://drive.google.com/drive/folders/1TCdJ0CKR3Q6LviovndOkJaKm8S1T9F_8
@CALL cd "%PROJECT_DIR%\ext\NeuralHaircut\pretrained_models\diffusion_prior"
@CALL "%~dp0micromamba.exe" run -n openpose -r "%~dp0\" gdown 1_9EOUXHayKiGH5nkrayncln3d6m1uV7f
@CALL cd "%PROJECT_DIR%\ext\NeuralHaircut\PIXIE"
@CALL "%~dp0micromamba.exe" run -n openpose -r "%~dp0\" gdown 1mPcGu62YPc4MdkT8FFiOCP629xsENHZf
@CALL tar -xvzf pixie_data.tar.gz
@CALL del pixie_data.tar.gz
@CALL cd "%PROJECT_DIR%\ext\hyperIQA"
@CALL if not exist pretrained mkdir pretrained
@CALL cd "%PROJECT_DIR%\ext\hyperIQA\pretrained"
@CALL "%~dp0micromamba.exe" run -n openpose -r "%~dp0\" gdown 1OOUmnbvpGea0LIGpIWEbOyxfWx6UCiiE
@CALL cd "%PROJECT_DIR%"

@echo.
@echo ===== Matte-Anything =====

@CALL "%~dp0condabin\micromamba.bat" activate matte_anything
@REM 安装 segment-anything, detectron2 和 GroundingDINO
@CALL cd "%PROJECT_DIR%\ext\Matte-Anything\segment-anything"
@CALL pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple
@CALL cd "%PROJECT_DIR%\ext\Matte-Anything\detectron2"
@CALL pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple
@CALL cd "%PROJECT_DIR%\ext\Matte-Anything\GroundingDINO"
@CALL pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple
@CALL cd "%PROJECT_DIR%\ext\Matte-Anything"
@CALL pip install supervision==0.22.0 -i https://pypi.tuna.tsinghua.edu.cn/simple

@REM 下载模型文件
@CALL if not exist pretrained mkdir pretrained
@CALL cd pretrained
@CALL powershell -Command "Invoke-WebRequest -Uri 'https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth' -OutFile 'sam_vit_h_4b8939.pth'"
@CALL powershell -Command "Invoke-WebRequest -Uri 'https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth' -OutFile 'groundingdino_swint_ogc.pth'"
@CALL "%~dp0micromamba.exe" run -n openpose -r "%~dp0\" gdown 1d97oKuITCeWgai2Tf3iNilt6rMSSYzkW

@REM 下载openpose模型
@CALL "%~dp0condabin\micromamba.bat" activate openpose
@CALL cd "%PROJECT_DIR%\ext\openpose"
@CALL powershell -Command "Invoke-WebRequest -Uri 'https://drive.google.com/uc?export=download&id=1Yn03cKKfVOq4qXmgBMQD20UMRRRkd_tV' -OutFile 'models.tar.gz'"
@CALL tar -xvzf models.tar.gz
@CALL del models.tar.gz

@REM 编译 openpose（需先使用 VS vcvarsall.bat）
@CALL cd "%PROJECT_DIR%\ext\openpose"
@CALL IF EXIST "%VCVARS_DIR%\vcvarsall.bat" (
    @CALL "%VCVARS_DIR%\vcvarsall.bat" x64
    @REM 编译Openpose
    @CALL mkdir build
    @CALL cd build
    @CALL cmake .. -DBUILD_PYTHON=true -DUSE_CUDNN=OFF -G "Visual Studio 17 2022" -A x64
    @CALL cmake --build . --config Release
    @CALL IF %ERRORLEVEL% NEQ 0 (
        @echo 编译OpenPose失败，但将继续安装其他组件
    )
) ELSE (
    @echo Visual Studio的vcvarsall.bat未找到，跳过编译OpenPose
    @echo 请检查Visual Studio的安装路径，并手动编译OpenPose
)

@REM PIXIE
@CALL "%~dp0condabin\micromamba.bat" activate pixie
@REM 下载PIXIE模型
@CALL cd "%PROJECT_DIR%\ext\PIXIE"
@CALL if exist fetch_model.bat (
    @CALL fetch_model.bat
) else (
    @echo PIXIE模型下载脚本不存在，创建下载脚本...
    (
        @echo @echo off
        @echo powershell -Command "Invoke-WebRequest -Uri 'https://pixie.is.tue.mpg.de/media/uploads/pixie/pixie_model.tar' -OutFile 'pixie_model.tar'"
        @echo powershell -Command "Invoke-WebRequest -Uri 'https://pixie.is.tue.mpg.de/media/uploads/pixie/pixie_data.tar' -OutFile 'pixie_data.tar'"
        @echo tar -xf pixie_model.tar
        @echo tar -xf pixie_data.tar
        @echo del pixie_model.tar
        @echo del pixie_data.tar
    ) > fetch_model.bat
    @CALL fetch_model.bat
)

@REM 切换回主环境，安装本地依赖
@CALL "%~dp0condabin\micromamba.bat" activate gaussian_splatting_hair

@echo.
@echo ========= 安装本地依赖 =========

@CALL cd "%PROJECT_DIR%"
@CALL pip install -e ext/pytorch3d -i https://pypi.tuna.tsinghua.edu.cn/simple
@CALL pip install -e ext/NeuralHaircut/npbgpp -i https://pypi.tuna.tsinghua.edu.cn/simple
@CALL pip install -e ext/simple-knn -i https://pypi.tuna.tsinghua.edu.cn/simple
@CALL pip install -e ext/diff_gaussian_rasterization_hair -i https://pypi.tuna.tsinghua.edu.cn/simple
@CALL pip install -e ext/kaolin -i https://pypi.tuna.tsinghua.edu.cn/simple

@echo.
@echo ==== 安装完成，请确认所有步骤无误 ====

@echo 如遇到问题，请检查error.log和安装输出
@echo 运行模型请使用run.bat脚本

@CALL pause

@REM 添加额外的命令以确保窗口在完成后不会关闭
@CALL cmd /k
