#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/filebrowser/config
sudo mkdir -p ${VOLUME_DATA_DIR}/filebrowser/srv
sudo mkdir -p ${VOLUME_DATA_DIR}/filebrowser/database

sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/filebrowser
sudo chmod -R 755 ${VOLUME_DATA_DIR}/filebrowser

echo "Setup complete."
