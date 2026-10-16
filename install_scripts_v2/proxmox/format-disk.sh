#!/bin/bash

function process_for_proxmox(){
  ########## CAUTION !! ###########
  ##     1行ずつ実行すること。     ##
  #################################

  # Stop VM
  qm stop 101

  # Remove HDD from VM
  # Preventing mistakes by removing it from the Web UI

  # Wipe partition table and filesystem
  wipefs -a /dev/sda
  # Re-create partition table
  gdisk /dev/sda <<EOF
o
y
n
1


8300
w
y
EOF
  # Format disk
  mkfs.ext4 /dev/sda1 -y

  # Reboot Proxmox and confirm
  reboot
  lsblk /dev/sda

  # Test mounting
  mount /dev/sda1 /mnt/test
  df -h | grep test
  ls /mnt/test

  # Unmount
  umount /mnt/test

  # Boot VM
  qm start 101

  # Attach new disk
  qm set 101 -scsi1 /dev/sda
}

function process_for_ubuntu(){
  ########## CAUTION !! ###########
  ##     1行ずつ実行すること。     ##
  #################################

  # Confirm new disk is recognized
  lsblk
  # If not recognized, reload kernel
  sudo blockdev --rereadpt /dev/sdb

  # Inspect mounting
  sudo blkid /dev/sdb1
  sudo mount /dev/sdb1 /mnt/hdd01
  sudo df -h | grep hdd01

  # Automate mounting
  sudo nano /etc/fstab
  sudo cat /etc/fstab

  # Test auto-mounting
  sudo systemctl daemon-reload
  sudo umount /mnt/hdd01
  sudo mount -a
  sudo df -h | grep hdd01
}
