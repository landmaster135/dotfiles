#!/bin/bash

function install_qemu_guest_agent() {
  sudo apt update
  sudo apt install qemu-guest-agent -y
  sudo systemctl enable qemu-guest-agent
  sudo systemctl start qemu-guest-agent
}

install_qemu_guest_agent
