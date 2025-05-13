# GaussianHaircut

[English](README_EN.md) | 中文

## 项目简介

GaussianHaircut 是一个用于高质量头发建模和渲染的项目，基于 3D 高斯点云技术。该项目由 ETH Zurich 的 AIT 实验室开发。

- 项目官方网站: [GaussianHaircut](https://eth-ait.github.io/GaussianHaircut/)
- GitHub 仓库: [GaussianHaircut](https://github.com/eth-ait/GaussianHaircut)
- 白皮书: [GaussianHaircut](https://arxiv.org/abs/2409.00437)
- 项目主页: [GaussianHaircut](https://haiminluo.github.io/gaussianhair/)

## 系统要求

- Windows 10 或 Windows 11
- NVIDIA GPU (支持 CUDA 11.8)，推荐至少8GB显存
- 至少 16GB RAM
- 至少 10GB 磁盘空间
- 稳定的网络连接，用于下载模型和依赖

## 必要软件

在运行 GaussianHaircut 之前，请确保安装以下软件:

1. **CUDA 11.8**
   - 下载链接: [https://developer.nvidia.com/cuda-11-8-0-download-archive](https://developer.nvidia.com/cuda-11-8-0-download-archive)
   - 默认安装路径: `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8`
   - 注意: 安装时确保选择"自定义安装"并确认安装CUDA工具包和开发库

2. **Blender 3.6**
   - 下载链接: [https://www.blender.org/download/](https://www.blender.org/download/)
   - 默认安装路径: `C:\Program Files\Blender Foundation\Blender 3.6`
   - 注意: 确保记住安装路径，需要在配置文件中设置

3. **COLMAP**
   - 下载链接: [https://github.com/colmap/colmap/releases](https://github.com/colmap/colmap/releases)
   - 建议安装路径: `C:\Colmap`
   - 注意: 下载Windows预编译版本，不需要从源码编译
   - 安装步骤:
     1. 下载最新的Windows版本zip文件
     2. 解压到`C:\Colmap`目录
     3. 确保添加到环境变量PATH或在配置中指定路径

4. **CMake**
   - 下载链接: [https://cmake.org/download/](https://cmake.org/download/)
   - 默认安装路径: `C:\Program Files\CMake`
   - 注意: 安装时勾选"添加CMake到系统PATH"选项

5. **Git**
   - 下载链接: [https://git-scm.com/download/win](https://git-scm.com/download/win)
   - 默认安装路径: `C:\Program Files\Git`
   - 注意: 安装时选择"Git从Windows命令提示符使用"选项

6. **Visual Studio 2022**
   - 下载链接: [https://visualstudio.microsoft.com/downloads/](https://visualstudio.microsoft.com/downloads/)
   - 注意: 确保安装以下组件:
     - "使用C++的桌面开发"工作负载
     - Windows 10/11 SDK
     - MSVC v143 生成工具
     - C++/CLI支持

## 安装步骤

1. 克隆仓库:
   ```
   git clone https://github.com/用户名/GaussianHaircutWin.git
   cd GaussianHaircutWin
   ```

2. 下载micromamba:
   - 从 [https://github.com/mamba-org/micromamba-releases/releases](https://github.com/mamba-org/micromamba-releases/releases) 下载Windows版本
   - 重命名为`micromamba.exe`并放置在项目根目录

3. 运行安装脚本 `install.bat`:
   ```
   install.bat
   ```
   
   此脚本将完成以下工作:
   - 初始化micromamba环境
   - 创建所有必要的虚拟环境(gaussian_splatting_hair, matte_anything, openpose, pixie)
   - 克隆所有依赖代码库
   - 下载预训练模型
   - 编译CUDA扩展和OpenPose
   - 安装本地依赖

   **注意**: 安装过程可能需要1-2小时，取决于网络速度和计算机性能。建议使用稳定的网络连接。

4. 安装过程中可能需要的手动干预:
   - 如果COLMAP未找到，将提示您安装
   - 某些模型下载可能较慢，可以手动下载并放入指定目录

## 使用方法

1. 准备数据:
   - 创建 `data` 目录(如果不存在)
   - 在 `data` 目录下创建一个场景文件夹(如`my_scene`)
   - 将您的原始视频文件命名为`raw.mp4`并放入场景文件夹中

2. 运行脚本:
   ```
   run.bat
   ```
   
   此脚本将显示一个菜单，让您选择:
   - 运行完整处理流程
   - 仅运行数据预处理
   - 仅运行重建
   - 仅运行可视化
   - 设置数据目录和其他参数

3. 查看结果:
   - 渲染结果将保存在`data/[场景名称]/videos`目录下
   - 3D模型将保存在`data/[场景名称]/curves_reconstruction`目录下

## 详细处理流程

### 预处理 (约30-60分钟)
1. 提取视频帧
2. 运行COLMAP重建，生成相机参数
3. 使用Matte-Anything提取头发区域
4. 裁剪和缩放图像
5. 运行OpenPose检测人体姿态
6. 运行Face-Alignment检测面部特征
7. 运行PIXIE生成初始3D头部模型
8. 准备FLAME拟合和3D高斯Splatting数据

### 重建 (约1-3小时，取决于GPU性能)
1. 运行3D高斯Splatting生成点云
2. 运行FLAME网格拟合优化头部模型
3. 裁剪重建场景并过滤
4. 移除与头部相交的头发点
5. 运行头发链条重建
6. 优化头发链条

### 可视化 (约10-20分钟)
1. 导出结果模型
2. 渲染可视化结果
3. 生成结果视频

## 环境变量

默认环境变量设置如下:
```
PROJECT_DIR=%CD%
DATA_PATH=%PROJECT_DIR%\data
ENV_PATH=%PROJECT_DIR%\envs
MAMBA=%PROJECT_DIR%\micromamba.exe
CUDA_DIR=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8
BLENDER_DIR=C:\Program Files\Blender Foundation\Blender 3.6
COLMAP_DIR=C:\Colmap\bin
CMAKE_DIR=C:\Program Files\CMake\bin
GIT_DIR=C:\Program Files\Git\bin
VCVARS_DIR=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build
```

如果您的软件安装在不同位置，请在`install.bat`和`run.bat`文件的开头修改相应的路径设置。

## 常见问题和故障排除

### 安装问题

1. **micromamba下载失败**
   - 问题: 无法自动下载micromamba
   - 解决方案: 手动下载并放置在项目根目录

2. **依赖下载失败**
   - 问题: 某些Python包或模型下载失败
   - 解决方案: 检查网络连接，可能需要设置代理或手动下载

3. **编译失败**
   - 问题: OpenPose或CUDA扩展编译错误
   - 解决方案:
     - 确保Visual Studio正确安装且包含C++组件
     - 确保CUDA路径正确
     - 检查是否有足够的磁盘空间

4. **COLMAP未安装或检测不到**
   - 问题: 安装脚本提示找不到COLMAP
   - 解决方案: 手动下载COLMAP预编译版本并解压到`C:\Colmap`

### 运行问题

1. **GPU内存不足**
   - 问题: 处理过程中提示CUDA out of memory
   - 解决方案:
     - 尝试降低图像分辨率(在run.bat选项中修改)
     - 使用更少的迭代次数
     - 使用更大显存的GPU

2. **视频帧提取失败**
   - 问题: 无法从raw.mp4提取帧
   - 解决方案: 确保视频格式正确，可能需要使用其他工具转换格式

3. **重建质量不佳**
   - 问题: 最终生成的头发模型不准确或有缺陷
   - 解决方案:
     - 确保输入视频质量高，稳定且清晰
     - 尝试增加迭代次数
     - 确保视频中头发部分足够清晰可见

## 参考资料

- [3D Gaussian Splatting](https://github.com/graphdeco-inria/gaussian-splatting)
- [NeuralHaircut](https://github.com/egorzakharov/NeuralHaircut)
- [FLAME](https://flame.is.tue.mpg.de/)
- [Matte-Anything](https://github.com/hustvl/Matte-Anything)
- [OpenPose](https://github.com/CMU-Perceptual-Computing-Lab/openpose)

## 许可证

请参阅原始项目的许可证信息: [https://github.com/eth-ait/GaussianHaircut](https://github.com/eth-ait/GaussianHaircut)

## 致谢

感谢ETH Zurich的AIT实验室开发的原始项目。本Windows版本适配仅用于方便Windows用户使用，并非官方发布。
