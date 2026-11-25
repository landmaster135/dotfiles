# ComfyUI

## Setup
NVIDIA Container Toolkitが未設定である場合、CachyOSでセットアップする必要がある:
```bash
# インストール
sudo pacman -S nvidia-container-toolkit

# Dockerランタイムに登録
sudo nvidia-ctk runtime configure --runtime=docker

# Docker再起動
sudo systemctl restart docker
```
