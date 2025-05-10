# Gaussian Haircut: 使用链条对齐的3D高斯体进行人物头发重建

[**论文**](https://arxiv.org/abs/2409.14778) | [**项目主页**](https://eth-ait.github.io/GaussianHaircut/)

本仓库包含Gaussian Haircut的Windows实现，这是一种基于链条的头发重建方法，适用于单目视频。

## 必要软件

在开始之前，请确保您的系统已安装以下软件：

1. **CUDA 11.8**

   从 [NVIDIA官方网站](https://developer.nvidia.com/cuda-11-8-0-download-archive) 下载并安装CUDA 11.8。

   请确保：
   - PATH环境变量包含`<CUDA安装目录>\bin`
   - 环境变量中CUDA可以被正确访问

   本项目仅使用此CUDA版本进行过测试。

2. **Blender 3.6**（用于创建发丝可视化）

   从 [Blender官方网站](https://www.blender.org/download/lts/3-6) 下载并安装Blender 3.6。
   
   安装后请将Blender的安装目录添加到PATH环境变量中，以便能够在命令行中直接调用`blender`命令。

3. **CMake**

   从 [CMake官方网站](https://cmake.org/download/) 下载并安装CMake。
   
   安装时请选择"将CMake添加到系统PATH"选项。

4. **COLMAP**

   从 [COLMAP的GitHub发布页](https://github.com/colmap/colmap/releases) 下载并安装COLMAP。

   colmap-x64-windows-cuda.zip/colmap-x64-windows-nocuda.zip 解压放到"C:\Colmap", 并将"C:\Colmap\bin"添加到环境变量
   
   安装后请将COLMAP的安装目录添加到PATH环境变量中。

5. **Git**

   从 [Git官方网站](https://git-scm.com/download/win) 下载并安装Git。

## 安装步骤

1. **克隆仓库**

   ```bash
   git clone https://github.com/eth-ait/GaussianHaircut.git
   cd GaussianHaircut
   ```

2. **运行安装脚本**

   ```bash
   install.bat
   ```

   此脚本将：
   - 检查必要软件是否已安装
   - 克隆所需的外部库
   - 使用micromamba创建和配置所需的环境
   - 下载预训练模型和其他必要文件

## 重建步骤

1. **录制单目视频**

   请参考项目页面上的示例，并尽量减少运动模糊。

2. **设置场景目录**

   创建一个新目录用于存储重建场景，并将视频文件放入其中，命名为`raw.mp4`。

3. **运行重建脚本**

   打开命令提示符，设置环境变量并运行脚本：

   ```bash
   set PROJECT_DIR=E:\path\to\GaussianHaircut
   set BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6
   set DATA_PATH=E:\path\to\scene\folder
   run.bat
   ```

   脚本将执行数据预处理、重建和使用Blender进行最终可视化。使用Tensorboard可以查看中间可视化结果。

## 技术细节

该项目使用以下关键技术：

- **3D高斯体溅射**：用于场景的初始3D重建
- **FLAME面部拟合**：用于准确重建头部形状
- **基于链条的头发建模**：将头发表示为3D曲线，实现逼真的头发重建
- **多视图优化**：从多个角度优化头发重建

## 注意事项

- 环境设置可能需要几个小时，因为需要下载和编译多个大型库
- 重建过程在单个GPU上可能需要几个小时
- 请确保您有足够的磁盘空间（至少需要10GB用于环境和临时文件）
- 建议使用NVIDIA RTX系列GPU以获得最佳性能

## 环境变量设置

在Windows系统中，您可以按照以下步骤设置环境变量：

1. 右键点击"此电脑"或"我的电脑"，选择"属性"
2. 点击"高级系统设置"
3. 点击"环境变量"按钮
4. 在"系统变量"区域，找到并双击"Path"变量
5. 点击"新建"按钮，添加软件的安装路径
6. 点击"确定"保存更改

## 故障排除

- 如果遇到CUDA错误，请确认CUDA 11.8已正确安装且环境变量设置正确
- 如果安装过程中遇到Python包安装错误，请尝试手动安装有问题的包
- 对于OpenPose构建错误，请确保您安装了正确版本的Visual Studio和C++构建工具

## 许可证

本代码基于3D Gaussian Splatting项目。有关条款和条件，请参阅LICENSE_3DGS。其余代码根据CC BY-NC-SA 4.0分发。

如果本代码对您的项目有帮助，请引用以下论文。

## 引用

```
@inproceedings{zakharov2024gh,
   title = {Human Hair Reconstruction with Strand-Aligned 3D Gaussians},
   author = {Zakharov, Egor and Sklyarova, Vanessa and Black, Michael J and Nam, Giljoo and Thies, Justus and Hilliges, Otmar},
   booktitle = {European Conference of Computer Vision (ECCV)},
   year = {2024}
} 
```

## 链接

- [3D Gaussian Splatting](https://github.com/graphdeco-inria/gaussian-splatting)
- [Neural Haircut](https://github.com/SamsungLabs/NeuralHaircut)：FLAME拟合管道、链条先验和发型扩散先验
- [HAAR](https://github.com/Vanessik/HAAR)：头发上采样
- [Matte-Anything](https://github.com/hustvl/Matte-Anything)：头发和身体分割
- [PIXIE](https://github.com/yfeng95/PIXIE)：FLAME拟合的初始化
- [Face-Alignment](https://github.com/1adrianb/face-alignment)、[OpenPose](https://github.com/CMU-Perceptual-Computing-Lab/openpose)：用于FLAME拟合的关键点检测
