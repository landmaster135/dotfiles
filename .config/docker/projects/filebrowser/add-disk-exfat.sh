#!/bin/bash

# ディスクを確認
sudo fdisk -l

# UUIDを確認
sudo blkid /dev/sdb2

# 必要に応じてフォーマット
sudo mkfs.exfat /dev/sdb2

# HDDをマウント
mkdir /mnt/hdd01
# sudo mount -t exfat -o uid=1000,gid=1000,umask=000 /dev/sdf2 /mnt/hdd11
# sudo mount /dev/sdf2 /mnt/hdd11

# 自動マウント対象に追加
sudo nano /etc/fstab
# 内容としては下記となる（UUIDは実際の値に置き換える）
cat <<EOF >> /etc/fstab
UUID=1234-5678  /mnt/hdd01  exfat  uid=1000,gid=1000,umask=000  0  0
EOF
# 保存
sudo mount -a
# 設定を確認
df -h | grep hdd01

echo "Setup complete."
