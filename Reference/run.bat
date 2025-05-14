@CALL "%~dp0micromamba.exe" shell init --shell cmd.exe --prefix "%~dp0\"
@CALL condabin\micromamba.bat activate StableDiffusion_001
@CALL set GDOWN_CACHE=cache\gdown
@CALL set TORCH_HOME=cache\torch
@CALL set HF_HOME=cache\huggingface
@CALL set PYTHONDONTWRITEBYTECODE=1
@CALL set CUDA_HOME=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.1
@CALL set COMMANDLINE_ARGS=--listen --port 7860 --autolaunch --theme dark --xformers --opt-sdp-attention --api --skip-install --skip-torch-cuda-test --skip-version-check --enable-insecure-extension-access
@CALL cd stable-diffusion-webui
@CALL python -B webui.py %COMMANDLINE_ARGS%
@CALL PAUSE
