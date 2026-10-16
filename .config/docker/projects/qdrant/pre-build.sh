#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/qdrant/storage
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/qdrant/storage
sudo chmod -R 755 ${VOLUME_DATA_DIR}/qdrant/storage

sudo mkdir -p ${VOLUME_DATA_DIR}/qdrant/snapshots
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/qdrant/snapshots
sudo chmod -R 755 ${VOLUME_DATA_DIR}/qdrant/snapshots

sudo mkdir -p ${VOLUME_DATA_DIR}/qdrant/config
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/qdrant/config
sudo chmod -R 755 ${VOLUME_DATA_DIR}/qdrant/config

# For docker-compose stack
sudo mkdir -p ${VOLUME_DATA_DIR}/qdrant/stack
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/qdrant/stack
sudo chmod -R 755 ${VOLUME_DATA_DIR}/qdrant/stack

echo "Setup complete."
