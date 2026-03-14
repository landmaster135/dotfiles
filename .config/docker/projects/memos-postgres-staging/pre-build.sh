#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/memos_staging/data
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/memos_staging/data
sudo chmod -R 755 ${VOLUME_DATA_DIR}/memos_staging/data

sudo mkdir -p ${VOLUME_DATA_DIR}/memos_staging/db
sudo chown -R 999:999 ${VOLUME_DATA_DIR}/memos_staging/db
sudo chmod -R 700 ${VOLUME_DATA_DIR}/memos_staging/db

# For backup
sudo mkdir -p ${VOLUME_DATA_DIR}/memos_staging/backup
# For docker-compose stack
sudo mkdir -p ${VOLUME_DATA_DIR}/memos_staging/stack

echo "Setup complete."
