#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/memos/data
sudo mkdir -p ${VOLUME_DATA_DIR}/memos/db

sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/memos/data
sudo chmod -R 755 ${VOLUME_DATA_DIR}/memos/data

sudo chown -R 999:999 ${VOLUME_DATA_DIR}/memos/db
sudo chmod -R 700 ${VOLUME_DATA_DIR}/memos/db

echo "Setup complete."
