#!/bin/bash

function initialize() {
  apt update
  apt upgrade -y
  apt autoremove -y
}

initialize

function setup_japanese_timezone() {
  echo "[INFO] Setting up Japanese timezone..."
  timedatectl set-timezone Asia/Tokyo
  echo "[INFO] Timezone setup completed."
  timedatectl status | grep "Time zone"
}

setup_japanese_timezone

function install_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "[INFO] Docker is already installed. Skip installation."
    docker --version
    return 0
  fi

  echo "[INFO] Installing Docker..."

  # Ubuntu Serverでは基本的にubuntuリポジトリを使用
  local docker_repo_os="ubuntu"

  DEBIAN_FRONTEND=noninteractive apt-get update
  DEBIAN_FRONTEND=noninteractive \
    apt-get install --assume-yes ca-certificates curl gnupg lsb-release

  install -m 0755 -d /etc/apt/keyrings
  rm -f /etc/apt/keyrings/docker.gpg
  curl -fsSL "https://download.docker.com/linux/${docker_repo_os}/gpg" \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${docker_repo_os} \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

  DEBIAN_FRONTEND=noninteractive apt-get update
  DEBIAN_FRONTEND=noninteractive \
    apt-get install --assume-yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Docker service start
  systemctl enable docker
  systemctl start docker

  # 動作確認
  docker --version
  docker compose version
  echo "[INFO] Docker installation completed successfully."
}

function install_packages() {
  install_docker
}

install_packages
