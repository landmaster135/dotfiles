#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/jellyfin/config
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/jellyfin/config
sudo chmod -R 755 ${VOLUME_DATA_DIR}/jellyfin/config

sudo mkdir -p ${VOLUME_DATA_DIR}/jellyfin/cache
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/jellyfin/cache
sudo chmod -R 755 ${VOLUME_DATA_DIR}/jellyfin/cache

sudo mkdir -p ${VOLUME_DATA_DIR}/jellyfin/media
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/jellyfin/media
sudo chmod -R 755 ${VOLUME_DATA_DIR}/jellyfin/media

sudo mkdir -p ${VOLUME_DATA_DIR}/jellyfin/media2
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/jellyfin/media2
sudo chmod -R 755 ${VOLUME_DATA_DIR}/jellyfin/media2

sudo mkdir -p ${VOLUME_DATA_DIR}/jellyfin/fonts
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/jellyfin/fonts
sudo chmod -R 755 ${VOLUME_DATA_DIR}/jellyfin/fonts

echo "Setup complete."
