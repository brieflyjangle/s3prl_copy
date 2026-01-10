#!/bin/bash

# Exit on error
set -e

#echo "Creating conda environment 'pyvenv' with Python 3.10..."
#conda create -n pyvenv python=3.10 -y

#echo "Activating conda environment..."
#source $(conda info --base)/etc/profile.d/conda.sh
#conda activate pyvenv

echo "Installing PyTorch 2.3.1 with CUDA 12.1 support..."
pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 --index-url https://download.pytorch.org/whl/cu121

echo "Installing package with [all] extras..."
pip install -e .[all]

echo "Installing package with [dev] extras..."
pip install -e .[dev]

echo "Installing package with [install] extras..."
pip install -e .[install]

echo "Setup complete! Environment 'pyvenv' is ready."
echo "To activate the environment, run: conda activate pyvenv"
