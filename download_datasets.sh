#!/bin/bash

# Script to download datasets for ASR, SID, and IC downstream tasks
# ASR: LibriSpeech (train-clean-100, dev-clean, test-clean)
# SID: VoxCeleb1 (dev and test)
# IC: Fluent Speech Commands
#
# Usage: ./download_datasets.sh <dataset_dir> <task_name>
# Example: ./download_datasets.sh /data/datasets asr
# Example: ./download_datasets.sh /data/datasets sid
# Example: ./download_datasets.sh /data/datasets ic
# Example: ./download_datasets.sh /data/datasets all

set -e  # Exit on error

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Two arguments required${NC}"
    echo "Usage: $0 <dataset_dir> <task_name>"
    echo ""
    echo "Arguments:"
    echo "  dataset_dir  - Absolute or relative path to save datasets"
    echo "  task_name    - Task to download: 'asr', 'sid', 'ic', or 'all'"
    echo ""
    echo "Examples:"
    echo "  $0 /data/datasets asr"
    echo "  $0 ./datasets ic"
    echo "  $0 /data/datasets all"
    exit 1
fi

# Get arguments
DATASET_DIR=$1
TASK_NAME=$2

# Validate task name
if [[ ! "$TASK_NAME" =~ ^(asr|sid|ic|all)$ ]]; then
    echo -e "${RED}Error: Invalid task name '${TASK_NAME}'${NC}"
    echo "Valid options: asr, sid, ic, all"
    exit 1
fi

# Convert to absolute path
DATASET_DIR=$(cd "$(dirname "${DATASET_DIR}")" && pwd)/$(basename "${DATASET_DIR}")
# Create if it doesn't exist for the realpath conversion
mkdir -p ${DATASET_DIR}
DATASET_DIR=$(cd "${DATASET_DIR}" && pwd)

echo -e "${GREEN}Dataset download script for S3PRL downstream tasks${NC}"
echo -e "${GREEN}=================================================${NC}"
echo "Datasets will be saved to: ${DATASET_DIR}"
echo "Task: ${TASK_NAME}"
echo ""

# Change to dataset directory
cd ${DATASET_DIR}

# ============================================================================
# ASR: LibriSpeech Dataset
# ============================================================================
if [[ "$TASK_NAME" == "asr" || "$TASK_NAME" == "all" ]]; then
    echo -e "${GREEN}Downloading LibriSpeech for ASR task...${NC}"
    LIBRISPEECH_DIR="${DATASET_DIR}/LibriSpeech"

    if [ -d "${LIBRISPEECH_DIR}" ]; then
        echo -e "${YELLOW}LibriSpeech directory already exists. Skipping download.${NC}"
    else
        mkdir -p ${LIBRISPEECH_DIR}

        echo "Downloading train-clean-100..."
        wget -c https://www.openslr.org/resources/12/train-clean-100.tar.gz
        tar -xzf train-clean-100.tar.gz

        echo "Downloading dev-clean..."
        wget -c https://www.openslr.org/resources/12/dev-clean.tar.gz
        tar -xzf dev-clean.tar.gz

        echo "Downloading test-clean..."
        wget -c https://www.openslr.org/resources/12/test-clean.tar.gz
        tar -xzf test-clean.tar.gz

        echo -e "${GREEN}LibriSpeech downloaded successfully!${NC}"
        echo "Location: ${LIBRISPEECH_DIR}"
        echo ""
    fi
fi

# ============================================================================
# SID: VoxCeleb1 Dataset
# ============================================================================
if [[ "$TASK_NAME" == "sid" || "$TASK_NAME" == "all" ]]; then
    echo -e "${GREEN}Downloading VoxCeleb1 for SID task...${NC}"
    VOXCELEB1_DIR="${DATASET_DIR}/VoxCeleb1"

    if [ -d "${VOXCELEB1_DIR}" ]; then
        echo -e "${YELLOW}VoxCeleb1 directory already exists. Skipping download.${NC}"
    else
        mkdir -p ${VOXCELEB1_DIR}/dev
        mkdir -p ${VOXCELEB1_DIR}/test

        echo "Downloading VoxCeleb1 dev set (split into 4 parts)..."
        cd ${VOXCELEB1_DIR}/dev/

        wget -c "https://huggingface.co/datasets/ProgramComputer/voxceleb/resolve/main/vox1/vox1_dev_wav_partaa?download=true" -O vox1_dev_wav_partaa
        wget -c "https://huggingface.co/datasets/ProgramComputer/voxceleb/resolve/main/vox1/vox1_dev_wav_partab?download=true" -O vox1_dev_wav_partab
        wget -c "https://huggingface.co/datasets/ProgramComputer/voxceleb/resolve/main/vox1/vox1_dev_wav_partac?download=true" -O vox1_dev_wav_partac
        wget -c "https://huggingface.co/datasets/ProgramComputer/voxceleb/resolve/main/vox1/vox1_dev_wav_partad?download=true" -O vox1_dev_wav_partad

        echo "Combining and extracting dev set..."
        cat vox1_dev_wav_part* > vox1_dev_wav.zip
        unzip -q vox1_dev_wav.zip
        rm vox1_dev_wav_part* vox1_dev_wav.zip

        echo "Downloading VoxCeleb1 test set..."
        cd ${VOXCELEB1_DIR}/test/
        wget -c "https://huggingface.co/datasets/ProgramComputer/voxceleb/resolve/main/vox1/vox1_test_wav.zip?download=true" -O vox1_test_wav.zip

        echo "Extracting test set..."
        unzip -q vox1_test_wav.zip
        rm vox1_test_wav.zip

        cd ${DATASET_DIR}
        echo -e "${GREEN}VoxCeleb1 downloaded successfully!${NC}"
        echo "Location: ${VOXCELEB1_DIR}"
        echo ""
    fi
fi

# ============================================================================
# IC: Fluent Speech Commands Dataset
# ============================================================================
if [[ "$TASK_NAME" == "ic" || "$TASK_NAME" == "all" ]]; then
    echo -e "${GREEN}Downloading Fluent Speech Commands for IC task...${NC}"
    FLUENT_DIR="${DATASET_DIR}/fluent_speech_commands_dataset"

    if [ -d "${FLUENT_DIR}" ]; then
        echo -e "${YELLOW}Fluent Speech Commands directory already exists. Skipping download.${NC}"
    else
        echo "Downloading Fluent Speech Commands..."
        wget -c "https://huggingface.co/datasets/leo19941227/fluent_speech_commands/resolve/main/fluent.tar.gz?download=true" -O fluent.tar.gz

        echo "Extracting Fluent Speech Commands..."
        tar -xzf fluent.tar.gz
        rm fluent.tar.gz

        echo -e "${GREEN}Fluent Speech Commands downloaded successfully!${NC}"
        echo "Location: ${FLUENT_DIR}"
        echo ""
    fi
fi

# ============================================================================
# Summary and Next Steps
# ============================================================================
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}Dataset download completed successfully!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""

if [[ "$TASK_NAME" == "asr" || "$TASK_NAME" == "all" ]]; then
    echo -e "${YELLOW}ASR Dataset (LibriSpeech):${NC}"
    echo "  Location: ${LIBRISPEECH_DIR}"
    echo ""
    echo "  Next steps:"
    echo "  1. Update the path in downstream/asr/config.yaml:"
    echo "     libri_root: \"${LIBRISPEECH_DIR}\""
    echo ""
    echo "  2. Generate length files:"
    echo "     python3 preprocess/generate_len_for_bucket.py -i \"${LIBRISPEECH_DIR}\" -o data/librispeech -a .flac --n_jobs 12"
    echo ""
    echo "  3. Run training:"
    echo "     python3 run_downstream.py -m train -n ExpName -u fbank -d asr"
    echo ""
fi

if [[ "$TASK_NAME" == "sid" || "$TASK_NAME" == "all" ]]; then
    echo -e "${YELLOW}SID Dataset (VoxCeleb1):${NC}"
    echo "  Location: ${VOXCELEB1_DIR}"
    echo ""
    echo "  Next steps:"
    echo "  1. Update the path in downstream/voxceleb1/config.yaml:"
    echo "     file_path: \"${VOXCELEB1_DIR}\""
    echo ""
    echo "  2. Run training:"
    echo "     python3 run_downstream.py -m train -n ExpName -u fbank -d voxceleb1"
    echo ""
fi

if [[ "$TASK_NAME" == "ic" || "$TASK_NAME" == "all" ]]; then
    echo -e "${YELLOW}IC Dataset (Fluent Speech Commands):${NC}"
    echo "  Location: ${FLUENT_DIR}"
    echo ""
    echo "  Next steps:"
    echo "  1. Update the path in downstream/fluent_commands/config.yaml:"
    echo "     file_path: \"${FLUENT_DIR}\""
    echo ""
    echo "  2. Run training:"
    echo "     python3 run_downstream.py -m train -n ExpName -u fbank -d fluent_commands"
    echo ""
fi

echo -e "${GREEN}Done!${NC}"
echo ""
