#!/bin/bash

# ディスクを確認
sudo fdisk -l

# UUIDを確認
sudo blkid /dev/sdb2

# 必要に応じてフォーマット
sudo mkfs.exfat /dev/sdb2

# HDDをマウント
mkdir /mnt/hdd01
sudo mount -t exfat -o uid=1000,gid=1000,umask=000 /dev/sdb2 /mnt/hdd01
# 保存して設定を確認
sudo mount -a

echo "Setup complete."
