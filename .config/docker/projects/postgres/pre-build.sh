#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/postgres/db
sudo chown -R 999:999 ${VOLUME_DATA_DIR}/postgres/db
sudo chmod -R 700 ${VOLUME_DATA_DIR}/postgres/db

# For docker-compose stack
sudo mkdir -p ${VOLUME_DATA_DIR}/postgres/stack
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/postgres/stack
sudo chmod -R 755 ${VOLUME_DATA_DIR}/postgres/stack

echo "Setup complete."
