#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/seaweedfs/data

# For docker-compose stack
sudo mkdir -p ${VOLUME_DATA_DIR}/seaweedfs/stack

sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/seaweedfs
sudo chmod -R 755 ${VOLUME_DATA_DIR}/seaweedfs

echo "Setup complete."
