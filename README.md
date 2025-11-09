# Dataset_preparation_pipeline.sh

For this Script I have used CIFAR-10 / CIFAR-100 dataset
Image (32*32) of animal or vehicle
Downloaded from https://www.cs.toronto.edu/~kriz/cifar.html

After Downloading 
Unpack the folder "tar -xzvf cifar-10-python.tar.gz"


A **simple, reproducible dataset preparation pipeline** for ML projects.  
Ideal for image classification or segmentation tasks where we need fast, clean, and automated preprocessing before training.


## Features
- Random **train/val/test split** with custom ratios  
- **Resize** (requires [ImageMagick](https://imagemagick.org))  
- **Copy** or **move** mode for flexibility  
- Automatic **filename normalization** e.g.(removes spaces & brackets)  
- Generates `dataset_summary.txt` with:
  - Image counts per subset  
  - Average width/height  
- Detailed **logging** for reproducibility


## Requirements
- Linux or MacOS terminal  
- `bash` ≥ 4  
- Utilities: `find`, `awk`, `shuf`, `mogrify`, `identify` (from ImageMagick)

Install "ImageMagick" & "shuf" if missing:
`For Ubuntu
sudo apt install imagemagick & sudo apt install coreutils
`For MacOs 
brew install imagemagick & brew install coreutils

# To Run
Navigate to the folder and type "bash file_name.sh --input /Path Name/cifar-10-batches-py --output ./data --split "70 15 15" --copy
