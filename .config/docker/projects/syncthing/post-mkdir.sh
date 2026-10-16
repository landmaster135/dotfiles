#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

# 所有者をuid:1000, gid:1000に変更
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/syncthing/config
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/syncthing/data

sudo chmod -R 755 ${VOLUME_DATA_DIR}/syncthing/config
sudo chmod -R 755 ${VOLUME_DATA_DIR}/syncthing/data

echo "Setup complete."
