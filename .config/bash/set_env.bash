#!/bin/bash

# YAMLファイルから環境変数を設定する関数
function set_env_from_yaml() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"

  # ヘルプメッセージの表示
  if [[ "$1" == "--help" ]]; then
    echo "使用方法: source scripts/set_env.sh [env_file]"
    echo ""
    echo "YAMLファイルから環境変数を設定します。"
    echo "パラメータ:"
    echo "  env_file  - 環境変数を読み込むYAMLファイルのパス（デフォルト: env.yml）"
    echo "  --help    - このヘルプメッセージを表示"
    echo "  --unset   - YAMLファイルから設定した環境変数を削除"
    echo ""
    echo "使用例:"
    echo "  source scripts/set_env.sh"
    echo "  source scripts/set_env.sh config/dev.yml"
    echo "  source scripts/set_env.sh --unset env.yml"
    echo "  source scripts/set_env.sh --help"
    return 0
  fi

  # 環境変数を削除するモード
  if [[ "$1" == "--unset" ]]; then
    unset_env_from_yaml "${2:-env.yml}"
    return $?
  fi

  # デフォルトのYAMLファイル
  local env_file=${1:-env.yml}

  # YAMLファイルが存在するか確認
  if [ ! -f "$env_file" ]; then
    echo "[ERROR] ${func_name}: ファイルが見つかりません: $env_file"
    return 1
  fi

  echo "[INFO] ${func_name}: YAMLファイル '$env_file' から環境変数を読み込みます"

  # YAMLファイルを解析して環境変数を設定
  while IFS=: read -r key value; do
    # 空行や#で始まる行はスキップ
    if [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    # キーと値からスペースを削除
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    # 環境変数を設定
    if [ -n "$key" ] && [ -n "$value" ]; then
      echo "[INFO] ${func_name}: 実行コマンド: export $key=$value"
      export "$key"="$value"
      echo "[INFO] ${func_name}: 環境変数を設定しました: $key=$value"
    fi
  done < "$env_file"

  echo "[INFO] ${func_name}: 環境変数を正常に読み込みました: $env_file"
  return 0
}

# YAMLファイルから設定した環境変数を削除する関数
function unset_env_from_yaml() {
  # 関数名を取得
  local func_name="${FUNCNAME[0]}"

  # デフォルトのYAMLファイル
  local env_file=${1:-env.yml}

  # YAMLファイルが存在するか確認
  if [ ! -f "$env_file" ]; then
    echo "[ERROR] ${func_name}: ファイルが見つかりません: $env_file"
    return 1
  fi

  echo "[INFO] ${func_name}: YAMLファイル '$env_file' から設定した環境変数を削除します"

  # YAMLファイルを解析して環境変数を削除
  while IFS=: read -r key value; do
    # 空行や#で始まる行はスキップ
    if [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    # キーからスペースを削除
    key=$(echo "$key" | xargs)

    # 環境変数を削除
    if [ -n "$key" ]; then
      echo "[INFO] ${func_name}: 実行コマンド: unset $key"
      unset "$key"
      echo "[INFO] ${func_name}: 環境変数を削除しました: $key"
    fi
  done < "$env_file"

  echo "[INFO] ${func_name}: 環境変数を正常に削除しました: $env_file"
  return 0
}

# コマンドライン引数に基づいて関数を実行
set_env_from_yaml "$@"
