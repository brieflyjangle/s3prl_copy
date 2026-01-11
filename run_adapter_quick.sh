#!/bin/bash
################################################################################
# Quick Adapter Experiments - Test Best Configurations Only
# Based on ADAPTER_RECOMMENDATIONS.md
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/s3prl/upstream/distiller/config_model.yaml"
BACKUP_CONFIG="$SCRIPT_DIR/s3prl/upstream/distiller/config_model.yaml.backup"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Quick Adapter Experiments - Recommended Configurations Only ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

update_config() {
    if [ ! -f "$BACKUP_CONFIG" ]; then
        cp "$CONFIG_FILE" "$BACKUP_CONFIG"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/adapter_dim: [0-9]*/adapter_dim: $1/" "$CONFIG_FILE"
        sed -i '' "s/adapter_scale: [0-9.]*/adapter_scale: $2/" "$CONFIG_FILE"
    else
        sed -i "s/adapter_dim: [0-9]*/adapter_dim: $1/" "$CONFIG_FILE"
        sed -i "s/adapter_scale: [0-9.]*/adapter_scale: $2/" "$CONFIG_FILE"
    fi
    echo -e "${YELLOW}[Config] adapter_dim=$1, adapter_scale=$2${NC}"
}

restore_config() {
    if [ -f "$BACKUP_CONFIG" ]; then
        cp "$BACKUP_CONFIG" "$CONFIG_FILE"
        echo -e "${GREEN}[Config] Restored${NC}"
    fi
}

run_training() {
    echo -e "${GREEN}[Training] $3${NC}"
    cd "$SCRIPT_DIR"
    python s3prl/run_downstream.py -m train -u "$1" -d "$2" -n "$3" -f --verbose
}

# Intent Classification - Recommended
echo -e "${BLUE}[1/3] Intent Classification (dim=32, scale=0.05)${NC}"
update_config 32 0.05
run_training "distiller" "fluent_commands" "ic_adapter_recommended"

# Speaker ID - Recommended
echo -e "${BLUE}[2/3] Speaker ID (dim=64, scale=0.1)${NC}"
update_config 64 0.1
run_training "distiller" "voxceleb1" "sid_adapter_recommended"

# ASR - Recommended
echo -e "${BLUE}[3/3] ASR (dim=128, scale=0.1)${NC}"
update_config 128 0.1
run_training "distiller" "asr" "asr_adapter_recommended"

restore_config

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  All experiments completed!                                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Results: $SCRIPT_DIR/s3prl/result/downstream/"
echo ""
