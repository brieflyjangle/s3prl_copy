# Using Adapters with Distiller Model for Downstream Tasks

This guide explains how to use adapter modules for parameter-efficient fine-tuning of the Distiller model on downstream tasks.

## Overview

Adapters are small neural network modules inserted into the transformer layers that allow you to fine-tune a pretrained model while keeping the original pretrained weights frozen. This approach:

- **Reduces trainable parameters**: Only ~1-5% of parameters need training
- **Prevents catastrophic forgetting**: Pretrained weights remain unchanged
- **Enables task-specific adaptation**: Each downstream task gets its own adapters
- **Speeds up training**: Fewer parameters to update

## Architecture

The adapter implementation adds two adapter modules per transformer layer:
1. **After attention**: Applied after the self-attention mechanism
2. **After FFN**: Applied after the feed-forward network

Each adapter uses a bottleneck architecture:
```
Input → Down-projection (dim → adapter_dim) → GELU → Up-projection (adapter_dim → dim) → Scale → Residual
```

## Configuration

### 1. Model Configuration File

Create or modify your model config YAML (e.g., `distiller_adapter_config.yaml`):

```yaml
distiller:
  # ... (other config parameters)

  # Adapter configuration
  use_adapter: true         # Enable adapter modules
  adapter_dim: 64           # Bottleneck dimension (default: 64)
  adapter_scale: 0.1        # Scaling factor for adapter output (default: 0.1)
```

**Parameters:**
- `use_adapter`: Set to `true` to enable adapters
- `adapter_dim`: Bottleneck dimension (smaller = fewer parameters, typical: 32-128)
- `adapter_scale`: Output scaling factor (typical: 0.1-1.0)

### 2. Upstream Expert Options

When using the distiller model with adapters in downstream tasks, you need to set the `freeze_pretrained` option:

```python
options = {
    "ckpt_file": "/path/to/pretrained/checkpoint.ckpt",
    "load_pretrain": "True",
    "no_grad": "False",
    "permute_input": "False",
    "freeze_pretrained": "True"  # This freezes all weights except adapters
}
```

## Usage with run_downstream.py

### Command Example

```bash
python run_downstream.py \
  -m train \
  -u distiller_local \
  -k /path/to/pretrained_distiller.ckpt \
  -g /path/to/distiller_adapter_config.yaml \
  -d phoneme_recognition \
  -n distiller_adapter_phoneme \
  --upstream_trainable \
  --override "upstream_model_config=/path/to/distiller_adapter_config.yaml,freeze_pretrained=True"
```

**Important flags:**
- `-g`: Path to your adapter config file
- `--upstream_trainable`: Enable training of upstream model (adapters only)
- `--override`: Override with `freeze_pretrained=True` to freeze pretrained weights

### Alternative: Modify Downstream Config

In your downstream task config file (e.g., `downstream/phoneme_recognition/config.yaml`), ensure the upstream is trainable:

```yaml
runner:
  total_steps: 200000
  gradient_clipping: 1.0
  gradient_accumulate_steps: 1
  log_step: 100
  eval_step: 5000
  save_step: 5000

upstream:
  trainable: true  # Allow upstream training (only adapters will be trained)
```

## Implementation Details

### Code Structure

The adapter implementation consists of:

1. **Adapter Class** ([model.py](../s3prl/upstream/distiller/model.py:324-340))
   - Bottleneck architecture with residual connection
   - Located at the end of `model.py`

2. **TransformerSentenceEncoderLayer** ([module.py](../s3prl/upstream/distiller/module.py:93-269))
   - Modified to include adapter modules
   - Applies adapters after attention and FFN

3. **DistillerConfig** ([model.py](../s3prl/upstream/distiller/model.py:17-83))
   - Added `use_adapter`, `adapter_dim`, `adapter_scale` config options

4. **freeze_pretrained_weights()** ([model.py](../s3prl/upstream/distiller/model.py:295-321))
   - Freezes all pretrained parameters
   - Unfreezes only adapter parameters
   - Prints parameter statistics

## Example Workflow

### 1. Prepare Your Pretrained Model

Ensure you have a pretrained Distiller checkpoint:
```bash
ls /path/to/pretrained_distiller.ckpt
```

### 2. Create Adapter Config

Copy and modify the example config:
```bash
cp example/distiller_adapter_config.yaml my_adapter_config.yaml
# Edit my_adapter_config.yaml to set use_adapter: true
```

### 3. Train on Downstream Task

```bash
python run_downstream.py \
  -m train \
  -u distiller_local \
  -k /path/to/pretrained_distiller.ckpt \
  -g my_adapter_config.yaml \
  -d speaker_recognition \
  -n my_experiment \
  --upstream_trainable \
  --override "freeze_pretrained=True"
```

### 4. Monitor Training

The training will print adapter statistics:
```
[DistillerModel] - Freezing all pretrained weights except adapters
[DistillerModel] - Unfroze 98,304 adapter parameters
[DistillerModel] - Trainable parameters: 98,304 / 10,234,567 (0.96%)
```

### 5. Evaluate

```bash
python run_downstream.py \
  -m evaluate \
  -e /path/to/experiment/dir
```

## Hyperparameter Tuning

### Adapter Dimension
- **Smaller (16-32)**: Fewer parameters, faster training, may underfit
- **Medium (64-128)**: Good balance (recommended starting point)
- **Larger (256-512)**: More capacity, slower training, may overfit

### Adapter Scale
- **Smaller (0.01-0.1)**: More stable, slower adaptation
- **Medium (0.1-0.5)**: Balanced (recommended)
- **Larger (0.5-1.0)**: Faster adaptation, may be unstable

## Troubleshooting

### Issue: All parameters are being trained
**Solution**: Ensure you're using `--override "freeze_pretrained=True"` in your command

### Issue: No improvement during training
**Solution**: Try increasing `adapter_dim` or `adapter_scale`

### Issue: Model overfitting quickly
**Solution**: Try decreasing `adapter_dim` or adding regularization to downstream model

### Issue: Config not loading properly
**Solution**: Verify the path to your config file with `-g` flag is correct

## References

- Original Distiller Paper: [DistilHuBERT](https://arxiv.org/abs/2110.01900)
- Adapter Paper: [Parameter-Efficient Transfer Learning for NLP](https://arxiv.org/abs/1902.00751)
