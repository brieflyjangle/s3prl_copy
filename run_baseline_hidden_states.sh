#!/bin/bash
# Baseline experiments: IC and SID with hidden_states feature, NO adapter module

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/s3prl/upstream/distiller/config_model.yaml"
BACKUP_CONFIG="$CONFIG_FILE.backup"

# Backup config and disable adapter
if [ ! -f "$BACKUP_CONFIG" ]; then
    cp "$CONFIG_FILE" "$BACKUP_CONFIG"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/use_adapter: true/use_adapter: false/" "$CONFIG_FILE"
else
    sed -i "s/use_adapter: true/use_adapter: false/" "$CONFIG_FILE"
fi

echo "=== Config: use_adapter set to false ==="

cd "$SCRIPT_DIR/s3prl"

# IC: Intent Classification (Fluent Commands) - hidden_states, no adapter
echo "=== Running IC baseline (hidden_states, no adapter) ==="
python run_downstream.py \
    -m train \
    -u distilhubert \
    -d fluent_commands \
    -n distilhubert_ic_hidden_states_no_adapter \
    -s hidden_states \
    -f

# SID: Speaker Identification (VoxCeleb1) - hidden_states, no adapter
echo "=== Running SID baseline (hidden_states, no adapter) ==="
python run_downstream.py \
    -m train \
    -u distilhubert \
    -d voxceleb1 \
    -n distilhubert_sid_hidden_states_no_adapter \
    -s hidden_states \
    -f

# Restore original config
cp "$BACKUP_CONFIG" "$CONFIG_FILE"
echo "=== Config restored ==="
echo "=== Done. Results in s3prl/result/downstream/ ==="
