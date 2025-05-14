CALL "%~dp0micromamba.exe" create -n StableDiffusion_001 python==3.10.14 git==2.41.0 git-lfs==3.2.0 -c pytorch -c conda-forge -r "%~dp0\" -y
@CALL "%~dp0micromamba.exe" shell init --shell cmd.exe --prefix "%~dp0\"
@CALL condabin\micromamba.bat activate StableDiffusion_001
@CALL set GDOWN_CACHE=cache\gdown
@CALL set TORCH_HOME=cache\torch
@CALL set HF_HOME=cache\huggingface
@CALL set PYTHONDONTWRITEBYTECODE=1
@CALL set CUDA_HOME=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.1
@CALL pip install --force-reinstall torch==2.2.0+cu121 torchvision==0.17.0+cu121 torchaudio==2.2.0+cu121 --index-url https://download.pytorch.org/whl/cu121 --no-cache-dir
@CALL git clone https://github.com/facebookresearch/xformers.git
@CALL cd xformers
@CALL git submodule update --init --recursive
@CALL pip install .
@CALL cd ..
@CALL git clone https://github.com/NVlabs/nvdiffrast .\nvdiffrast
@CALL cd nvdiffrast
@CALL pip install .
@CALL cd ..
@CALL git clone -b v1.9.4 https://github.com/AUTOMATIC1111/stable-diffusion-webui/ .\stable-diffusion-webui\
@CALL mkdir .\stable-diffusion-webui\cache\gdown\
@CALL mkdir .\stable-diffusion-webui\cache\torch\
@CALL mkdir .\stable-diffusion-webui\cache\huggingface\
@CALL mkdir .\stable-diffusion-webui\repositories\
@CALL git clone https://github.com/CompVis/stable-diffusion.git .\stable-diffusion-webui\repositories\stable-diffusion
@CALL git clone https://github.com/CompVis/taming-transformers.git .\stable-diffusion-webui\repositories\taming-transformers
@CALL git clone https://github.com/crowsonkb/k-diffusion.git .\stable-diffusion-webui\repositories\k-diffusion
@CALL git clone https://github.com/sczhou/CodeFormer.git .\stable-diffusion-webui\repositories\CodeFormer
@CALL git clone http://github.com/salesforce/BLIP.git .\stable-diffusion-webui\repositories\BLIP
@CALL cd .\stable-diffusion-webui
@CALL pip install -r .\stable-diffusion-webui\requirements.txt
@CALL python -B launch.py --xformers --opt-sdp-attention --autolaunch --theme dark --listen --port 7860 --enable-insecure-extension-access --skip-torch-cuda-test
@CALL PAUSE
