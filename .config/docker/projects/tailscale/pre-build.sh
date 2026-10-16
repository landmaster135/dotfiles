#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/tailscale/tun
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/tailscale/tun
sudo chmod -R 755 ${VOLUME_DATA_DIR}/tailscale/tun

sudo mkdir -p ${VOLUME_DATA_DIR}/tailscale/lib
sudo chown -R 999:999 ${VOLUME_DATA_DIR}/tailscale/lib
sudo chmod -R 700 ${VOLUME_DATA_DIR}/tailscale/lib

# For docker-compose stack
sudo mkdir -p ${VOLUME_DATA_DIR}/tailscale/stack
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/tailscale/stack
sudo chmod -R 755 ${VOLUME_DATA_DIR}/tailscale/stack

echo "Setup complete."
