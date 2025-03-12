#!/usr/bin/env bash
function setup_vscode() {
  mkdir -p ~/.local/
  
  # To automatically install the apt repository and signing key, such as on a non-interactive terminal, run the following command first:
  echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections

  # Run the following script:
  sudo apt-get install wget gpg
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
  rm -f packages.microsoft.gpg

  # Then update the package cache and install the package using:
  sudo apt install apt-transport-https
  sudo apt update
  sudo apt install code
}
