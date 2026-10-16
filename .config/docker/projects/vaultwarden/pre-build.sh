#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/vaultwarden/data
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/vaultwarden/data
sudo chmod -R 755 ${VOLUME_DATA_DIR}/vaultwarden/data

echo "Setup complete."
