#!/bin/bash

# Script to download datasets for ASR, SID, and IC downstream tasks
# ASR: LibriSpeech (train-clean-100, dev-clean, test-clean)
# SID: VoxCeleb1 (dev and test)
# IC: Fluent Speech Commands

set -e  # Exit on error

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default dataset directory
DATASET_DIR=${1:-"./datasets"}

echo -e "${GREEN}Dataset download script for S3PRL downstream tasks${NC}"
echo -e "${GREEN}=================================================${NC}"
echo "Datasets will be saved to: ${DATASET_DIR}"
echo ""

# Create dataset directory
mkdir -p ${DATASET_DIR}
cd ${DATASET_DIR}

# ============================================================================
# ASR: LibriSpeech Dataset
# ============================================================================
echo -e "${GREEN}[1/3] Downloading LibriSpeech for ASR task...${NC}"
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

# ============================================================================
# SID: VoxCeleb1 Dataset
# ============================================================================
echo -e "${GREEN}[2/3] Downloading VoxCeleb1 for SID task...${NC}"
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

# ============================================================================
# IC: Fluent Speech Commands Dataset
# ============================================================================
echo -e "${GREEN}[3/3] Downloading Fluent Speech Commands for IC task...${NC}"
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

# ============================================================================
# Summary and Next Steps
# ============================================================================
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}All datasets downloaded successfully!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo "Dataset locations:"
echo "  - LibriSpeech (ASR): ${LIBRISPEECH_DIR}"
echo "  - VoxCeleb1 (SID):   ${VOXCELEB1_DIR}"
echo "  - Fluent Commands (IC): ${FLUENT_DIR}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. For ASR task, update the path in downstream/asr/config.yaml:"
echo "   libri_root: \"${LIBRISPEECH_DIR}\""
echo ""
echo "   Then generate length files:"
echo "   python3 preprocess/generate_len_for_bucket.py -i \"${LIBRISPEECH_DIR}\" -o data/librispeech -a .flac --n_jobs 12"
echo ""
echo "2. For SID task, update the path in downstream/voxceleb1/config.yaml:"
echo "   file_path: \"${VOXCELEB1_DIR}\""
echo ""
echo "3. For IC task, update the path in downstream/fluent_commands/config.yaml:"
echo "   file_path: \"${FLUENT_DIR}\""
echo ""
echo -e "${GREEN}You can now run training with:${NC}"
echo "  python3 run_downstream.py -m train -n ExpName -u fbank -d asr"
echo "  python3 run_downstream.py -m train -n ExpName -u fbank -d voxceleb1"
echo "  python3 run_downstream.py -m train -n ExpName -u fbank -d fluent_commands"
echo ""
