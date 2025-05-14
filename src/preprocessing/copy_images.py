#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import argparse
import shutil
from glob import glob
from tqdm import tqdm

def copy_images(data_path):
    """
    Create copies of images for different processing stages
    
    Args:
        data_path: Path to data directory
    """
    src_dir = os.path.join(data_path, 'images')
    if not os.path.exists(src_dir):
        raise FileNotFoundError(f"Source image directory not found: {src_dir}")
    
    # Create destination directories if they don't exist
    for i in range(2, 5):
        dst_dir = os.path.join(data_path, f'images_{i}')
        os.makedirs(dst_dir, exist_ok=True)
    
    # Get all images in source directory
    image_files = glob(os.path.join(src_dir, '*.jpg')) + glob(os.path.join(src_dir, '*.png'))
    
    if not image_files:
        raise ValueError(f"No image files found in {src_dir}")
    
    # Copy images to each destination directory
    for i in range(2, 5):
        dst_dir = os.path.join(data_path, f'images_{i}')
        print(f"Copying images to {dst_dir}...")
        
        for src_file in tqdm(image_files):
            filename = os.path.basename(src_file)
            dst_file = os.path.join(dst_dir, filename)
            shutil.copy2(src_file, dst_file)
    
    print(f"Created image copies for all processing stages")

def main():
    parser = argparse.ArgumentParser(description="Create copies of images for different processing stages")
    parser.add_argument("--data_path", type=str, required=True, help="Path to data directory")
    
    args = parser.parse_args()
    
    try:
        copy_images(args.data_path)
    except Exception as e:
        print(f"Error copying images: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main()) 