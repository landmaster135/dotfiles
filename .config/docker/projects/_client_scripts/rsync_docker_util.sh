#!/usr/bin/env bash
set -euo pipefail

function rsync_to_stack_dir() {
  local file="$1"
  local nas_host="$2"
  local volume_data_dir="$3"
  local project_dir="$4"
  local dest="${nas_host}:${volume_data_dir}/${project_dir}"

  if [[ ! -e "$file" ]]; then
    echo "Error: File not found: ${file}" >&2
    return 1
  fi

  rsync --archive --verbose --human-readable --partial --progress "$file" "$dest"
}

if [[ $# -ne 3 ]]; then
  echo "Usage: $(basename "$0") <nas_host> <volume_data_dir> <project_dir>" >&2
  exit 1
fi

NAS_HOST="$1"
VOLUME_DATA_DIR="$2"
PROJECT_DIR="$3"
SRC_DIR="$HOME/dotfiles/.config/docker/projects/$PROJECT_DIR"

echo "[Rsync: 1/2]"
rsync_to_stack_dir "$SRC_DIR/docker-compose.yml" "$NAS_HOST" "$VOLUME_DATA_DIR" "$PROJECT_DIR/stack"
echo "[Rsync: 2/2]"
rsync_to_stack_dir "$SRC_DIR/.env"               "$NAS_HOST" "$VOLUME_DATA_DIR" "$PROJECT_DIR/stack"
