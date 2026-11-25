#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

# Set user ownership, not root
mkdir -p ${VOLUME_DATA_DIR}/comfyui/ComfyUI
chmod -R 755 ${VOLUME_DATA_DIR}/comfyui/ComfyUI

mkdir -p ${VOLUME_DATA_DIR}/comfyui/cache
chmod -R 755 ${VOLUME_DATA_DIR}/comfyui/cache

# For docker-compose stack
mkdir -p ${VOLUME_DATA_DIR}/comfyui/stack
chmod -R 755 ${VOLUME_DATA_DIR}/comfyui/stack

echo "Setup complete."
