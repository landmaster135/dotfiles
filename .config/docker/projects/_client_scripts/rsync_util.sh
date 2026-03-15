#!/usr/bin/env bash
set -euo pipefail

function rsync_to_nas() {
  local file="$1"
  local nas_host="$2"
  local volume_data_dir="$3"
  local project_dir="$4"
  local dest="${nas_host}:${volume_data_dir}/${project_dir}"

  if [[ ! -e "$file" ]]; then
    echo "Error: 転送元が見つかりません: ${file}" >&2
    return 1
  fi

  rsync --archive --verbose --human-readable --partial --progress "$file" "$dest"
}

if [[ $# -ne 4 ]]; then
  echo "Usage: $(basename "$0") <file> <nas_host> <volume_data_dir> <project_dir>" >&2
  exit 1
fi

rsync_to_nas "$1" "$2" "$3" "$4"
