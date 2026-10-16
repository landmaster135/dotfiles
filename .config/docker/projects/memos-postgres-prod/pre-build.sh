#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/memos-postgres-prod/data
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/memos-postgres-prod/data
sudo chmod -R 755 ${VOLUME_DATA_DIR}/memos-postgres-prod/data

sudo mkdir -p ${VOLUME_DATA_DIR}/memos-postgres-prod/db
sudo chown -R 999:999 ${VOLUME_DATA_DIR}/memos-postgres-prod/db
sudo chmod -R 700 ${VOLUME_DATA_DIR}/memos-postgres-prod/db

# For docker-compose stack
sudo mkdir -p ${VOLUME_DATA_DIR}/memos-postgres-prod/stack
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/memos-postgres-prod/stack
sudo chmod -R 755 ${VOLUME_DATA_DIR}/memos-postgres-prod/stack

echo "Setup complete."
