#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import argparse
import cv2
import numpy as np
from glob import glob
from tqdm import tqdm

def crop_center(img, crop_width=None, crop_height=None):
    """
    在图像中心裁剪
    
    Args:
        img: 输入图像
        crop_width: 裁剪宽度 (默认: 图像宽度的3/4)
        crop_height: 裁剪高度 (默认: 图像高度的3/4)
    
    Returns:
        裁剪后的图像
    """
    height, width = img.shape[:2]
    
    if crop_width is None:
        crop_width = int(width * 0.75)
    if crop_height is None:
        crop_height = int(height * 0.75)
    
    startx = width//2 - crop_width//2
    starty = height//2 - crop_height//2
    
    return img[starty:starty+crop_height, startx:startx+crop_width]

def crop_face(img, face_cascade=None):
    """
    在人脸周围裁剪图像
    
    Args:
        img: 输入图像
        face_cascade: 用于人脸检测的Haar级联分类器
    
    Returns:
        聚焦于人脸的裁剪图像，如果没有检测到人脸则使用中心裁剪
    """
    if face_cascade is None:
        # 尝试加载人脸检测器
        cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        if os.path.exists(cascade_path):
            face_cascade = cv2.CascadeClassifier(cascade_path)
        else:
            print("未找到人脸检测器，使用中心裁剪")
            return crop_center(img)
    
    # 转为灰度图进行人脸检测
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # 检测人脸
    faces = face_cascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(30, 30)
    )
    
    if len(faces) == 0:
        # 没检测到人脸，使用中心裁剪
        return crop_center(img)
    
    # 使用最大的人脸
    if len(faces) > 1:
        areas = [w * h for (x, y, w, h) in faces]
        faces = [faces[np.argmax(areas)]]
    
    # 获取带填充的人脸坐标
    x, y, w, h = faces[0]
    padding = max(w, h) // 2
    
    # 计算裁剪区域
    startx = max(0, x - padding)
    starty = max(0, y - padding)
    endx = min(img.shape[1], x + w + padding)
    endy = min(img.shape[0], y + h + padding)
    
    return img[starty:endy, startx:endx]

def crop_images(data_path):
    """
    裁剪数据目录中的图像
    
    Args:
        data_path: 数据目录路径
    """
    # 尝试加载人脸检测器
    cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    face_cascade = None
    if os.path.exists(cascade_path):
        face_cascade = cv2.CascadeClassifier(cascade_path)
        print("使用人脸检测进行裁剪")
    else:
        print("未找到人脸检测器，使用中心裁剪")
    
    # 处理images_2目录中的图像
    src_dir = os.path.join(data_path, 'images_2')
    if not os.path.exists(src_dir):
        raise FileNotFoundError(f"源图像目录未找到: {src_dir}")
    
    # 获取源目录中的所有图像
    image_files = glob(os.path.join(src_dir, '*.jpg')) + glob(os.path.join(src_dir, '*.png'))
    
    if not image_files:
        raise ValueError(f"在{src_dir}中未找到图像文件")
    
    print(f"裁剪{len(image_files)}张图像...")
    for img_path in tqdm(image_files):
        # 读取图像
        img = cv2.imread(img_path)
        if img is None:
            print(f"警告: 无法读取{img_path}")
            continue
        
        # 裁剪图像
        if face_cascade is not None:
            cropped = crop_face(img, face_cascade)
        else:
            cropped = crop_center(img)
        
        # 保存裁剪后的图像
        cv2.imwrite(img_path, cropped)
    
    print(f"已裁剪{src_dir}中的所有图像")

def main():
    parser = argparse.ArgumentParser(description="为预处理裁剪图像")
    parser.add_argument("--data_path", type=str, required=True, help="数据目录路径")
    
    args = parser.parse_args()
    
    try:
        crop_images(args.data_path)
    except Exception as e:
        print(f"裁剪图像时出错: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main()) 