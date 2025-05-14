#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import cv2
import argparse
import numpy as np
from tqdm import tqdm
import subprocess

def extract_frames_cv2(video_path, output_dir, fps=None):
    """
    Extract frames from a video using OpenCV
    
    Args:
        video_path: Path to the video file
        output_dir: Directory to save frames
        fps: Frames per second to extract (None for all frames)
    """
    # Check if video exists
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"视频文件未找到: {video_path}")
        
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Open video file
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise ValueError(f"无法打开视频文件: {video_path}")
    
    # Get video properties
    video_fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # Calculate frame interval if fps is specified
    if fps is not None and fps < video_fps:
        frame_interval = round(video_fps / fps)
    else:
        frame_interval = 1
    
    print(f"视频FPS: {video_fps}")
    print(f"总帧数: {total_frames}")
    print(f"每{frame_interval}帧提取一帧")
    
    # Extract frames
    frame_count = 0
    saved_count = 0
    
    with tqdm(total=total_frames//frame_interval) as pbar:
        while True:
            ret, frame = cap.read()
            if not ret:
                break
                
            if frame_count % frame_interval == 0:
                # Save frame
                frame_path = os.path.join(output_dir, f"{saved_count:04d}.jpg")
                cv2.imwrite(frame_path, frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
                saved_count += 1
                pbar.update(1)
                
            frame_count += 1
    
    cap.release()
    print(f"已提取{saved_count}帧到{output_dir}")

def extract_frames_ffmpeg(video_path, output_dir, fps=None):
    """
    Extract frames from a video using ffmpeg (as backup method)
    
    Args:
        video_path: Path to the video file
        output_dir: Directory to save frames
        fps: Frames per second to extract (None for all frames)
    """
    # Check if video exists
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"视频文件未找到: {video_path}")
        
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Construct ffmpeg command
    output_pattern = os.path.join(output_dir, "%04d.jpg")
    
    if fps is not None:
        cmd = ["ffmpeg", "-i", video_path, "-qscale:v", "1", "-vf", f"fps={fps}", output_pattern]
    else:
        cmd = ["ffmpeg", "-i", video_path, "-qscale:v", "1", output_pattern]
    
    # Run ffmpeg
    print(f"运行命令: {' '.join(cmd)}")
    try:
        subprocess.run(cmd, check=True)
        print(f"已提取帧到{output_dir}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"运行ffmpeg时出错: {e}")
        return False
    except FileNotFoundError:
        print("未找到ffmpeg。请安装ffmpeg或者使用OpenCV方法。")
        return False
        
    return True

def main():
    parser = argparse.ArgumentParser(description="从视频中提取帧")
    parser.add_argument("--input_path", type=str, required=True, help="视频文件路径")
    parser.add_argument("--output_path", type=str, required=True, help="保存帧的目录")
    parser.add_argument("--fps", type=float, default=5, help="要提取的每秒帧数（默认5）")
    parser.add_argument("--use_ffmpeg", action="store_true", help="使用ffmpeg而非OpenCV")
    
    args = parser.parse_args()
    
    try:
        print(f"开始从视频提取帧: {args.input_path}")
        print(f"输出目录: {args.output_path}")
        print(f"目标FPS: {args.fps}")
        
        if args.use_ffmpeg:
            print("使用ffmpeg方法")
            success = extract_frames_ffmpeg(args.input_path, args.output_path, args.fps)
            if not success:
                print("ffmpeg方法失败，尝试使用OpenCV...")
                extract_frames_cv2(args.input_path, args.output_path, args.fps)
        else:
            try:
                print("使用OpenCV方法")
                extract_frames_cv2(args.input_path, args.output_path, args.fps)
            except Exception as e:
                print(f"OpenCV方法出错: {e}")
                print("尝试使用ffmpeg作为备用方法...")
                extract_frames_ffmpeg(args.input_path, args.output_path, args.fps)
    except Exception as e:
        print(f"提取帧时出错: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main()) 