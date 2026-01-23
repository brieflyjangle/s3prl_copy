#!/bin/bash
################################################################################
# Adapter Training Experiments Script (PAPER FEATURE SELECTION)
# Based on ADAPTER_RECOMMENDATIONS.md
#
# This script runs adapter fine-tuning experiments with different configurations
# for Intent Classification, Speaker ID, and ASR tasks.
# Using 'paper' feature selection (last encoder layer only)
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/s3prl/upstream/distiller/config_model.yaml"
BACKUP_CONFIG="$SCRIPT_DIR/s3prl/upstream/distiller/config_model.yaml.backup"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ADAPTER FINE-TUNING EXPERIMENTS (PAPER FEATURE)                 ║${NC}"
echo -e "${BLUE}║           Using 'paper' feature selection (last encoder layer)            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to update config_model.yaml
update_config() {
    local adapter_dim=$1
    local adapter_scale=$2

    echo -e "${YELLOW}[Config] Updating adapter_dim=$adapter_dim, adapter_scale=$adapter_scale${NC}"

    # Backup original config if not exists
    if [ ! -f "$BACKUP_CONFIG" ]; then
        cp "$CONFIG_FILE" "$BACKUP_CONFIG"
        echo -e "${GREEN}[Config] Backed up original config${NC}"
    fi

    # Update adapter_dim and adapter_scale using sed
    # For macOS compatibility, use -i '' instead of -i
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/adapter_dim: [0-9]*/adapter_dim: $adapter_dim/" "$CONFIG_FILE"
        sed -i '' "s/adapter_scale: [0-9.]*/adapter_scale: $adapter_scale/" "$CONFIG_FILE"
    else
        sed -i "s/adapter_dim: [0-9]*/adapter_dim: $adapter_dim/" "$CONFIG_FILE"
        sed -i "s/adapter_scale: [0-9.]*/adapter_scale: $adapter_scale/" "$CONFIG_FILE"
    fi

    echo -e "${GREEN}[Config] Updated successfully${NC}"
}

# Function to restore original config
restore_config() {
    if [ -f "$BACKUP_CONFIG" ]; then
        cp "$BACKUP_CONFIG" "$CONFIG_FILE"
        echo -e "${GREEN}[Config] Restored original config${NC}"
    fi
}

# Function to run training
run_training() {
    local upstream=$1
    local downstream=$2
    local exp_name=$3

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}[Training] Starting: $exp_name${NC}"
    echo -e "${GREEN}[Training] Using feature selection: paper${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"

    cd "$SCRIPT_DIR"

    python s3prl/run_downstream.py \
        -m train \
        -u "$upstream" \
        -d "$downstream" \
        -n "$exp_name" \
        -s paper \
        -f \
        --verbose

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[Training] ✓ Completed: $exp_name${NC}"
    else
        echo -e "${RED}[Training] ✗ Failed: $exp_name${NC}"
        return 1
    fi
}

################################################################################
# PHASE 1: INTENT CLASSIFICATION (QUICK VALIDATION)
################################################################################

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ PHASE 1: Intent Classification - Adapter Validation                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Task: Intent Classification (Fluent Commands)"
echo "Purpose: Quick validation that adapters work"
echo "Expected: ~1-3% accuracy improvement vs feature extraction"
echo ""

# IC Experiment 1: Conservative (Recommended)
echo -e "${YELLOW}[1/3] Testing dim=32, scale=0.05 (Recommended for IC)${NC}"
update_config 32 0.05
run_training "distiller" "fluent_commands" "ic_adapter_dim32_scale0.05_paper"

# IC Experiment 2: Standard
echo -e "${YELLOW}[2/3] Testing dim=64, scale=0.1 (Standard)${NC}"
update_config 64 0.1
run_training "distiller" "fluent_commands" "ic_adapter_dim64_scale0.1_paper"

# IC Experiment 3: Conservative with larger dim
echo -e "${YELLOW}[3/3] Testing dim=64, scale=0.05 (Larger dim, conservative)${NC}"
update_config 64 0.05
run_training "distiller" "fluent_commands" "ic_adapter_dim64_scale0.05_paper"

echo ""
echo -e "${GREEN}[Phase 1] Intent Classification experiments completed! ✓${NC}"
echo ""

################################################################################
# PHASE 2: SPEAKER IDENTIFICATION (MEDIUM COMPLEXITY)
################################################################################

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ PHASE 2: Speaker Identification                                          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Task: Speaker Identification (VoxCeleb1)"
echo "Purpose: Medium complexity task"
echo "Expected: ~2-5% accuracy improvement vs feature extraction"
echo ""

# SID Experiment 1: Standard (Recommended)
echo -e "${YELLOW}[1/3] Testing dim=64, scale=0.1 (Recommended for SID)${NC}"
update_config 64 0.1
run_training "distiller" "voxceleb1" "sid_adapter_dim64_scale0.1_paper"

# SID Experiment 2: Larger capacity
echo -e "${YELLOW}[2/3] Testing dim=96, scale=0.1 (Medium)${NC}"
update_config 96 0.1
run_training "distiller" "voxceleb1" "sid_adapter_dim96_scale0.1_paper"

# SID Experiment 3: Aggressive
echo -e "${YELLOW}[3/3] Testing dim=128, scale=0.15 (Aggressive)${NC}"
update_config 128 0.15
run_training "distiller" "voxceleb1" "sid_adapter_dim128_scale0.15_paper"

echo ""
echo -e "${GREEN}[Phase 2] Speaker ID experiments completed! ✓${NC}"
echo ""

################################################################################
# PHASE 3: ASR (MOST COMPLEX)
################################################################################

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ PHASE 3: Automatic Speech Recognition (ASR)                              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Task: ASR (LibriSpeech)"
echo "Purpose: Most complex task, large downstream head (42.8M params)"
echo "Expected: ~5-15% WER improvement vs feature extraction"
echo "WARNING: This phase takes significantly longer!"
echo ""

# ASR Experiment 1: Conservative (Recommended first)
echo -e "${YELLOW}[1/3] Testing dim=128, scale=0.1 (Conservative for ASR)${NC}"
update_config 128 0.1
run_training "distiller" "asr" "asr_adapter_dim128_scale0.1_paper"

# ASR Experiment 2: Aggressive
echo -e "${YELLOW}[2/3] Testing dim=256, scale=0.15 (Aggressive)${NC}"
update_config 256 0.15
run_training "distiller" "asr" "asr_adapter_dim256_scale0.15_paper"

# ASR Experiment 3: Maximum capacity with conservative scale
echo -e "${YELLOW}[3/3] Testing dim=256, scale=0.1 (Maximum capacity)${NC}"
update_config 256 0.1
run_training "distiller" "asr" "asr_adapter_dim256_scale0.1_paper"

echo ""
echo -e "${GREEN}[Phase 3] ASR experiments completed! ✓${NC}"
echo ""

################################################################################
# CLEANUP AND SUMMARY
################################################################################

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ ALL EXPERIMENTS COMPLETED!                                                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Restore original config
restore_config

echo -e "${GREEN}Summary of experiments (using PAPER feature selection):${NC}"
echo ""
echo "Phase 1: Intent Classification"
echo "  ✓ ic_adapter_dim32_scale0.05_paper  (Recommended - 198K adapter params)"
echo "  ✓ ic_adapter_dim64_scale0.1_paper   (Standard - 396K adapter params)"
echo "  ✓ ic_adapter_dim64_scale0.05_paper  (Conservative - 396K adapter params)"
echo ""
echo "Phase 2: Speaker Identification"
echo "  ✓ sid_adapter_dim64_scale0.1_paper   (Recommended - 396K adapter params)"
echo "  ✓ sid_adapter_dim96_scale0.1_paper   (Medium - 593K adapter params)"
echo "  ✓ sid_adapter_dim128_scale0.15_paper (Aggressive - 789K adapter params)"
echo ""
echo "Phase 3: ASR"
echo "  ✓ asr_adapter_dim128_scale0.1_paper  (Conservative - 789K adapter params)"
echo "  ✓ asr_adapter_dim256_scale0.15_paper (Aggressive - 1.58M adapter params)"
echo "  ✓ asr_adapter_dim256_scale0.1_paper  (Maximum - 1.58M adapter params)"
echo ""
echo -e "${YELLOW}Results location:${NC}"
echo "  $SCRIPT_DIR/s3prl/result/downstream/"
echo ""
echo -e "${GREEN}To view best results:${NC}"
echo "  grep -r \"best\" $SCRIPT_DIR/s3prl/result/downstream/*/log.log"
echo ""
echo -e "${GREEN}To compare experiments:${NC}"
echo "  ls -lh $SCRIPT_DIR/s3prl/result/downstream/"
echo ""
echo "Review the results and choose the best adapter configuration for each task!"
echo ""