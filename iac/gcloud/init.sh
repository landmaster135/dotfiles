#!/bin/sh
function auth_gcloud() {
  local FUNC_NAME=${FUNCNAME[0]}

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} PROJECT_ID"
      echo "  PROJECT_ID : 設定するプロジェクトのID"
      return 0
    fi
  done

  # 引数チェック：プロジェクトIDが必要
  if [ $# -lt 1 ]; then
    echo "[ERROR] ${FUNC_NAME}: Usage: ${FUNC_NAME} PROJECT_ID" >&2
    return 1
  fi

  local project_id="$1"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] ${FUNC_NAME}: Error: gcloud コマンドが見つかりません。Google Cloud SDKがインストールされているか確認してください。" >&2
    return 1
  fi

  # プロジェクト設定処理
  if ! gcloud auth login "$project_id"; then
    echo "[ERROR] ${FUNC_NAME}: Error: プロジェクト '$project_id' の認証に失敗しました。" >&2
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: プロジェクト '$project_id' が正常に認証されました。"
}

function set_gcloud_project_config() {
  local FUNC_NAME=${FUNCNAME[0]}

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} PROJECT_ID"
      echo "  PROJECT_ID : 設定するプロジェクトのID"
      return 0
    fi
  done

  # 引数チェック：プロジェクトIDが必要
  if [ $# -lt 1 ]; then
    echo "[ERROR] ${FUNC_NAME}: Usage: ${FUNC_NAME} PROJECT_ID" >&2
    return 1
  fi

  local project_id="$1"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] ${FUNC_NAME}: Error: gcloud コマンドが見つかりません。Google Cloud SDKがインストールされているか確認してください。" >&2
    return 1
  fi

  # プロジェクト設定処理
  if ! gcloud config set project "$project_id"; then
    echo "[ERROR] ${FUNC_NAME}: Error: プロジェクト '$project_id' の設定に失敗しました。" >&2
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: プロジェクト '$project_id' が正常に設定されました。"
}

function list_shell_functions_for_cdk() {
  local FUNC_NAME=${FUNCNAME[0]}

  if [ $# -lt 1 ]; then
    echo "[ERROR] ${FUNC_NAME}: Usage: ${FUNC_NAME} DIRECTORY_PATH" >&2
    return 1
  fi

  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo "[ERROR] ${FUNC_NAME}: 指定されたパスはディレクトリではありません: $dir" >&2
    return 1
  fi

  for file in "$dir"/*.sh; do
    if [[ -f "$file" ]]; then
      echo "[INFO] ${FUNC_NAME}: Functions in $file:"
      grep -oP '^\s*function\s+\K\w+' "$file"
    fi
  done
}
