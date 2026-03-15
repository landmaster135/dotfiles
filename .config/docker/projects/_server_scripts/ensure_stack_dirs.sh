#!/usr/bin/env bash
# ensure_stack_dirs.sh v0.1
set -euo pipefail

function ensure_stack_dirs() {
  local target_dir="$1"

  if [[ ! -d "$target_dir" ]]; then
    echo "Error: 対象ディレクトリが見つかりません: ${target_dir}" >&2
    return 1
  fi

  local created=0
  local skipped=0

  while IFS= read -r sub_dir; do
    local basename
    basename="$(basename "$sub_dir")"
    if [[ "$basename" == _* ]]; then
      continue
    fi

    local stack_dir="${sub_dir}/stack"

    if [[ ! -d "$stack_dir" ]]; then
      echo "作成: ${stack_dir}"
      sudo mkdir -p "$stack_dir"
      sudo chown -R 1000:1000 "$stack_dir"
      sudo chmod -R 755 "$stack_dir"
      created=$(( created + 1 ))
    else
      echo "スキップ（既存）: ${stack_dir}"
      skipped=$(( skipped + 1 ))
    fi
  done < <(find "$target_dir" -mindepth 1 -maxdepth 1 -type d)

  echo ""
  echo "完了: ${created} 件作成, ${skipped} 件スキップ"
}

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <target_dir>" >&2
  exit 1
fi

ensure_stack_dirs "$1"
