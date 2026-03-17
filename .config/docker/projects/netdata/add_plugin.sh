#!/bin/bash

# Example env-vars:
SRC_DIR=.
DEST_DIR=../netdata/config
FILE_NAME_PREFIX=disk_io_guard

# Move files:
sudo mv ${SRC_DIR}/${FILE_NAME_PREFIX}.conf ${DEST_DIR}/health.d/${FILE_NAME_PREFIX}.conf
sudo mv ${SRC_DIR}/${FILE_NAME_PREFIX}.plugin ${DEST_DIR}/custom-plugins.d/${FILE_NAME_PREFIX}.plugin

# Confirm results:
ls ${DEST_DIR}/health.d
ls ${DEST_DIR}/custom-plugins.d
