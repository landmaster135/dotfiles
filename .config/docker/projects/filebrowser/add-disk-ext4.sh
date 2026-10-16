#!/bin/bash

# ディスクを確認
sudo fdisk -l

# UUIDを確認
sudo blkid /dev/sdb2

# 必要に応じてフォーマット
sudo mkfs.ext4 /dev/sdb2

# HDDをマウント
mkdir /mnt/hdd01
# sudo mount -t ext4 -o uid=1000,gid=1000,umask=000 /dev/sdb2 /mnt/hdd01

# 自動マウント対象に追加
sudo nano /etc/fstab
# 内容としては下記となる（UUIDは実際の値に置き換える）
cat <<EOF >> /etc/fstab
UUID=1234-5678  /mnt/hdd01  ext4  defaults  0  2
EOF
# ディスクをフォーマットし直した場合は、保存前にデーモンを再起動
sudo systemctl daemon-reload
# 保存
sudo mount -a
# 設定を確認
df -h | grep hdd01

# 権限設定
sudo chown -R 1000:1000 /mnt/hdd01 /mnt/hdd02 /mnt/hdd03 /mnt/hdd04
sudo mkdir -p /mnt/hdd01/nas_volume
sudo chmod 755 /mnt/hdd01/nas_volume
sudo mkdir -p /mnt/hdd02/nas_volume
sudo chmod 755 /mnt/hdd02/nas_volume
sudo mkdir -p /mnt/hdd03/nas_volume
sudo chmod 755 /mnt/hdd03/nas_volume
sudo mkdir -p /mnt/hdd04/nas_volume
sudo chmod 755 /mnt/hdd04/nas_volume

sudo mkdir -p /mnt/hdd01/nas_volume/999_app_for_nas
sudo chmod 755 /mnt/hdd01/nas_volume/999_app_for_nas

echo "Setup complete."
