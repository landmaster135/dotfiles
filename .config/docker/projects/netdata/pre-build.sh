#!/bin/bash

# VOLUME_DATA_DIRの値を確認
echo ${VOLUME_DATA_DIR}

sudo mkdir -p ${VOLUME_DATA_DIR}/netdata/config
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/netdata/config
sudo chmod -R 755 ${VOLUME_DATA_DIR}/netdata/config

sudo mkdir -p ${VOLUME_DATA_DIR}/netdata/lib
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/netdata/lib
sudo chmod -R 755 ${VOLUME_DATA_DIR}/netdata/lib

sudo mkdir -p ${VOLUME_DATA_DIR}/netdata/cache
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/netdata/cache
sudo chmod -R 755 ${VOLUME_DATA_DIR}/netdata/cache

# For docker-compose stack
sudo mkdir -p ${VOLUME_DATA_DIR}/netdata/stack
sudo chown -R 1000:1000 ${VOLUME_DATA_DIR}/netdata/stack
sudo chmod -R 755 ${VOLUME_DATA_DIR}/netdata/stack

echo "Setup complete."
