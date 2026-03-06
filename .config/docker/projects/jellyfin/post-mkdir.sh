#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

# 所有者をuid:1000, gid:1000に変更
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/config
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/cache
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/media
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/media2
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/fonts

sudo chmod -R 755 ${VOLUME_DATA_DIR}/config
sudo chmod -R 755 ${VOLUME_DATA_DIR}/cache
sudo chmod -R 755 ${VOLUME_DATA_DIR}/media
sudo chmod -R 755 ${VOLUME_DATA_DIR}/media2
sudo chmod -R 755 ${VOLUME_DATA_DIR}/fonts

echo "Setup complete."
