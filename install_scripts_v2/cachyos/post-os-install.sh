#!bin/bash

sudo pacman -Syu

##########################################
##            Japanese input            ##
##########################################

sudo pacman -S fcitx5 fcitx5-mozc fcitx5-configtool fcitx5-gtk fcitx5-qt

mkdir -p $HOME/.config/environment.d
cat << EOF > $HOME/.config/environment.d/fcitx5.conf
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF

# After rebooting, you must add Mozc from the setting tool
# Fcitx5の設定ファイルを作成
mkdir -p ~/.config/fcitx5

cat << 'EOF' > ~/.config/fcitx5/profile
[Groups/0]
Name=Default
Default Layout=jp
DefaultIM=mozc

[Groups/0/Items/0]
Name=keyboard-jp
Layout=

[Groups/0/Items/1]
Name=mozc
Layout=

[GroupOrder]
0=Default
EOF

# Fcitx5再起動
fcitx5 -r

# Confirm Fcitx5 settings
fcitx5-configtool

##########################################
##      Install packages via pacman     ##
##########################################

# Common packages
sudo pacman -S --noconfirm --needed steam
sudo pacman -S --noconfirm --needed obs-studio
sudo pacman -S --noconfirm --needed tmux
sudo pacman -S --noconfirm --needed go
sudo pacman -S --noconfirm --needed gimp
sudo pacman -S --noconfirm --needed vlc

# For AUR
sudo pacman -S --noconfirm --needed git
sudo pacman -S --noconfirm --needed base-devel

# Install Docker
sudo pacman -S --noconfirm --needed docker
sudo pacman -S --noconfirm --needed docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# Install Tailscale
sudo pacman -S --noconfirm --needed tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up --accept-dns=true

# Install for games
sudo pacman -S --noconfirm --needed mangohud

# Install for coding
sudo pacman -S --noconfirm --needed lazygit

# pended packages...
# sudo pacman -S --noconfirm --needed openbsd-netcat
# sudo pacman -S --noconfirm --needed zed
# sudo pacman -S --noconfirm --needed neovim

##########################################
##       Install packages via AUR       ##
##########################################

# packages via yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Common packages
yay -S --noconfirm --needed brave-bin
yay -S --noconfirm --needed google-cloud-cli
yay -S --noconfirm --needed discord_arch_electron

# For game
yay -S --noconfirm --needed envycontrol

# pended packages...
# yay -S google-chrome
