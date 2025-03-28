#!/bin/sh
function create_gce_instance() {
  local FUNC_NAME="create_gce_instance"
  send_discord_notification "VMを構築するよ！"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE] [MACHINE_TYPE]"
      echo "  INSTANCE_NAME : 作成するインスタンスの名前"
      echo "  ZONE          : インスタンスを作成するゾーン (デフォルト: us-central1-a)"
      echo "  MACHINE_TYPE  : マシンタイプ (デフォルト: e2-medium)"
      return 0
    fi
  done

  # 引数チェック：最低1つはインスタンス名を指定する必要があります
  if [ $# -lt 1 ]; then
    echo "[ERROR] Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE] [MACHINE_TYPE]" >&2
    return 1
  fi

  # パラメータの初期化（デフォルト値付き）
  local instance_name="$1"
  local zone="${2:-us-central1-a}"
  local machine_type="${3:-e2-medium}"
  local address_flag="--no-address"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] Error: gcloud コマンドが見つかりません。Google Cloud SDKがインストールされているか確認してください。" >&2
    return 1
  fi

  # インスタンス作成処理
  if ! gcloud compute instances create "$instance_name" \
    --zone="$zone" \
    --machine-type="$machine_type" \
    "$address_flag"; then
    echo "[ERROR] Error: インスタンス '$instance_name' の作成に失敗しました。" >&2
    send_discord_notification_about_gce "失敗…" "VMが構築できなかったよ…" "red"
    return 1
  fi

  send_discord_notification_about_gce "VMを構築するよ！" "VMが起動したよ！" "green"
  echo "インスタンス '$instance_name' が正常に作成されました。"
}

function create_gce_instance_and_configure() {
  local FUNC_NAME="create_gce_instance_and_configure"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE] [MACHINE_TYPE] [YAML_FILE] [STARTUP_SCRIPT_FILE]"
      echo "  INSTANCE_NAME       : 作成するインスタンスの名前"
      echo "  ZONE                : インスタンスを作成するゾーン (デフォルト: us-central1-a)"
      echo "  MACHINE_TYPE        : マシンタイプ (デフォルト: e2-medium)"
      echo "  STARTUP_SCRIPT_FILE : スタートアップスクリプトのファイルパス (デフォルト: ./iac/gcloud/setup_scripts/startup-script.sh)"
      echo "  YAML_FILE           : metadata設定用のYAMLファイル (デフォルト: env.yml)"
      return 0
    fi
  done

  # 引数チェック：最低1つは INSTANCE_NAME を指定する必要があります
  if [ "$#" -lt 1 ]; then
    echo "[ERROR] ${FUNC_NAME}: Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE] [MACHINE_TYPE] [STARTUP_SCRIPT_FILE] [YAML_FILE]" >&2
    return 1
  fi

  # パラメータの初期化（デフォルト値付き）
  local INSTANCE_NAME="$1"
  local ZONE="${2:-us-central1-a}"
  local MACHINE_TYPE="${3:-e2-medium}"
  local YAML_FILE="${4:-env.yml}"
  local STARTUP_FILE="${5:-./iac/gcloud/setup_scripts/startup-script.sh}"

  # 1. インスタンス作成
  if ! create_gce_instance "$INSTANCE_NAME" "$ZONE" "$MACHINE_TYPE"; then
    echo "[ERROR] ${funcName}: Failed to create instance '$INSTANCE_NAME'." >&2
    return 1
  fi

  # 2. YAMLファイルからmetadataの設定
  if ! set_gce_instance_metadata_from_yaml "$INSTANCE_NAME" "$ZONE" "$YAML_FILE"; then
    echo "[ERROR] ${FUNC_NAME}: インスタンス '$INSTANCE_NAME' のmetadata設定に失敗しました。" >&2
    return 1
  fi

  # 3. とスタートアップスクリプトの登録
  if ! add_startup_script_to_gce_instance "$INSTANCE_NAME" "$ZONE" "$FILE_PATH"; then
    echo "[ERROR] ${funcName}: Failed to add startup script to instance '$INSTANCE_NAME'." >&2
    return 1
  fi

  echo "[INFO] ${FUNC_NAME}: インスタンス '$INSTANCE_NAME' の作成、スタートアップスクリプト登録、metadata設定が正常に完了しました。"
  return 0
}

function add_startup_script_to_gce_instance() {
  local funcName="add_startup_script_to_gce_instance"
  local DEFAULT_ZONE="us-central1-a"
  local DEFAULT_FILE_PATH="./shell/setup_scripts/startup-script.sh"
  send_discord_notification "VMのスタートアップスクリプトを反映するよ！"

  # --help が指定された場合は利用方法を表示
  if [ "$1" = "--help" ]; then
    echo "[INFO] ${funcName}: Usage: ${funcName} VM_NAME ZONE [FILE_PATH]"
    echo "[INFO] ${funcName}: Example: ${funcName} my-vm ${DEFAULT_ZONE} ${DEFAULT_FILE_PATH}"
    echo "[INFO] ${funcName}: If ZONE is not provided, default value '${DEFAULT_ZONE}' is used."
    echo "[INFO] ${funcName}: If FILE_PATH is not provided, default value '${DEFAULT_FILE_PATH}' is used."
    return 0
  fi

  # 必須パラメータの数チェック (1～3個)
  if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo "[ERROR] ${funcName}: Invalid number of parameters." >&2
    echo "[INFO] ${funcName}: Usage: ${funcName} VM_NAME [ZONE] [FILE_PATH]" >&2
    return 1
  fi

  local VM_NAME="$1"
  local ZONE="${2:-$DEFAULT_ZONE}"
  # 3番目の引数が未指定の場合はデフォルト値を使用
  local FILE_PATH="${3:-$DEFAULT_FILE_PATH}"

  # gcloud コマンドの実行
  if ! gcloud compute instances add-metadata "${VM_NAME}" --zone="${ZONE}" --metadata-from-file startup-script="${FILE_PATH}"; then
    echo "[ERROR] ${funcName}: Failed to add metadata from file '${FILE_PATH}' to instance '${VM_NAME}' in zone '${ZONE}'." >&2
    send_discord_notification_about_gce "失敗…" "VMのスタートアップスクリプトを反映できなかったよ…" "red"
    return 1
  fi

  send_discord_notification "VMのスタートアップスクリプトを反映したよ！"
  echo "[INFO] ${funcName}: Successfully added metadata from file '${FILE_PATH}' to instance '${VM_NAME}' in zone '${ZONE}'."
  return 0
}

function create_gce_instance_with_startup_script() {
  local funcName="create_gce_instance_with_startup_script"
  local DEFAULT_ZONE="us-central1-a"
  local DEFAULT_MACHINE_TYPE="e2-medium"
  local DEFAULT_FILE_PATH="./shell/setup_scripts/startup-script.sh"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] ${funcName}: Usage: ${funcName} INSTANCE_NAME [ZONE] [MACHINE_TYPE] [FILE_PATH]"
      echo "[INFO] ${funcName}:   INSTANCE_NAME  : 作成するインスタンスの名前"
      echo "[INFO] ${funcName}:   ZONE           : インスタンスを作成するゾーン (デフォルト: ${DEFAULT_ZONE})"
      echo "[INFO] ${funcName}:   MACHINE_TYPE   : マシンタイプ (デフォルト: ${DEFAULT_MACHINE_TYPE})"
      echo "[INFO] ${funcName}:   FILE_PATH      : スタートアップスクリプトのファイルパス (デフォルト: ${DEFAULT_FILE_PATH})"
      return 0
    fi
  done

  # 引数チェック：最低1つは INSTANCE_NAME を指定する必要があります
  if [ "$#" -lt 1 ]; then
    echo "[ERROR] ${funcName}: Invalid number of parameters." >&2
    echo "[INFO] ${funcName}: Usage: ${funcName} INSTANCE_NAME [ZONE] [MACHINE_TYPE] [FILE_PATH]" >&2
    return 1
  fi

  local INSTANCE_NAME="$1"
  local ZONE="${2:-$DEFAULT_ZONE}"
  local MACHINE_TYPE="${3:-$DEFAULT_MACHINE_TYPE}"
  local FILE_PATH="${4:-$DEFAULT_FILE_PATH}"

  # インスタンス作成
  if ! create_gce_instance "$INSTANCE_NAME" "$ZONE" "$MACHINE_TYPE"; then
    echo "[ERROR] ${funcName}: Failed to create instance '$INSTANCE_NAME'." >&2
    return 1
  fi

  # スタートアップスクリプトの登録
  if ! add_startup_script_to_gce_instance "$INSTANCE_NAME" "$ZONE" "$FILE_PATH"; then
    echo "[ERROR] ${funcName}: Failed to add startup script to instance '$INSTANCE_NAME'." >&2
    return 1
  fi

  echo "[INFO] ${funcName}: Instance '$INSTANCE_NAME' created with startup script successfully."
  return 0
}

function create_gce_router_and_nat() {
  local FUNC_NAME="create_gce_router_and_nat"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] Usage: ${FUNC_NAME} ROUTER_NAME [REGION] [NETWORK] [NAT_NAME]"
      echo "  ROUTER_NAME : 作成するルーターの名前"
      echo "  REGION      : ルーターとNATを作成するリージョン (デフォルト: us-central1)"
      echo "  NETWORK     : ルーターを作成するネットワーク (デフォルト: default)"
      echo "  NAT_NAME    : 作成するNATの名前 (デフォルト: nat1)"
      return 0
    fi
  done

  # 引数チェック：最低1つはルーター名を指定する必要があります
  if [ $# -lt 1 ]; then
    echo "[ERROR] Usage: ${FUNC_NAME} ROUTER_NAME [REGION] [NETWORK] [NAT_NAME]" >&2
    return 1
  fi

  # パラメータの初期化（デフォルト値付き）
  local router_name="$1"
  local region="${2:-us-central1}"
  local network="${3:-default}"
  local nat_name="${4:-nat1}"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] Error: gcloud コマンドが見つかりません。Google Cloud SDKがインストールされているか確認してください。" >&2
    return 1
  fi

  # ルーター作成処理
  if ! gcloud compute routers create "$router_name" \
    --region="$region" \
    --network="$network"; then
    echo "[ERROR] Error: ルーター '$router_name' の作成に失敗しました。" >&2
    return 1
  fi

  # NAT作成処理
  if ! gcloud compute routers nats create "$nat_name" \
    --router="$router_name" \
    --region="$region" \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges; then
    echo "[ERROR] Error: NAT '$nat_name' の作成に失敗しました。" >&2
    return 1
  fi

  echo "ルーター '$router_name' と NAT '$nat_name' が正常に作成されました。"
}

function create_gce_iap_ssh_firewall_rule() {
  local FUNC_NAME="create_gce_iap_ssh_firewall_rule"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] Usage: ${FUNC_NAME} [RULE_NAME] [DIRECTION] [ACTION] [RULES] [SOURCE_RANGES]"
      echo "  RULE_NAME     : ファイアウォールルールの名前 (デフォルト: allow-ssh-ingress-from-iap)"
      echo "  DIRECTION     : ルールの方向 (デフォルト: INGRESS)"
      echo "  ACTION        : アクション (デフォルト: allow)"
      echo "  RULES         : 許可するルール (デフォルト: tcp:22)"
      echo "  SOURCE_RANGES : 送信元 IP 範囲 (デフォルト: 35.235.240.0/20)"
      return 0
    fi
  done

  # パラメータの初期化（デフォルト値付き）
  local rule_name="${1:-allow-ssh-ingress-from-iap}"
  local direction="${2:-INGRESS}"
  local action="${3:-allow}"
  local rules="${4:-tcp:22}"
  local source_ranges="${5:-35.235.240.0/20}"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] Error: gcloud コマンドが見つかりません。Google Cloud SDK がインストールされているか確認してください。" >&2
    return 1
  fi

  # ファイアウォールルール作成処理
  if ! gcloud compute firewall-rules create "$rule_name" \
      --direction="$direction" \
      --action="$action" \
      --rules="$rules" \
      --source-ranges="$source_ranges"; then
    echo "[ERROR] Error: ファイアウォールルール '$rule_name' の作成に失敗しました。" >&2
    return 1
  fi

  echo "ファイアウォールルール '$rule_name' が正常に作成されました。"
}

function create_gce_ingress_ssh_firewall_rule() {
  local FUNC_NAME="create_gce_ingress_ssh_firewall_rule"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] Usage: ${FUNC_NAME} [RULE_NAME] [ALLOW_RULE] [SOURCE_RANGES]"
      echo "  RULE_NAME     : ファイアウォールルールの名前 (デフォルト: allow-ingress-ssh)"
      echo "  ALLOW_RULE    : 許可するプロトコルとポート (デフォルト: tcp:22)"
      echo "  SOURCE_RANGES : 送信元 IP 範囲 (デフォルト: 10.0.0.0/8)"
      return 0
    fi
  done

  # パラメータの初期化（デフォルト値付き）
  local rule_name="${1:-allow-ingress-ssh}"
  local allow_rule="${2:-tcp:22}"
  local source_ranges="${3:-10.0.0.0/8}"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] Error: gcloud コマンドが見つかりません。Google Cloud SDK がインストールされているか確認してください。" >&2
    return 1
  fi

  # ファイアウォールルール作成処理
  if ! gcloud compute firewall-rules create "$rule_name" \
      --allow="$allow_rule" \
      --source-ranges="$source_ranges"; then
    echo "[ERROR] Error: ファイアウォールルール '$rule_name' の作成に失敗しました。" >&2
    return 1
  fi

  echo "ファイアウォールルール '$rule_name' が正常に作成されました。"
}

function copy_gce_ssh_key() {
  local FUNC_NAME="copy_gce_ssh_key"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE] [SSH_KEY_PATH]"
      echo "  INSTANCE_NAME : SSH 秘密鍵をコピーする対象のインスタンス名"
      echo "  ZONE         : インスタンスのゾーン (デフォルト: us-central1-a)"
      echo "  SSH_KEY_PATH : SSH 秘密鍵ファイルのパス (デフォルト: \$HOME/.ssh/google_compute_engine)"
      return 0
    fi
  done

  # 引数チェック: インスタンス名は必須
  if [ $# -lt 1 ]; then
    echo "[ERROR]  Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE] [SSH_KEY_PATH]" >&2
    return 1
  fi

  local instance_name="$1"
  local zone="${2:-us-central1-a}"
  local ssh_key_path="${3:-$HOME/.ssh/google_compute_engine}"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] Error: gcloud コマンドが見つかりません。Google Cloud SDK がインストールされているか確認してください。" >&2
    return 1
  fi

  # SSH 秘密鍵のコピー処理
  if ! gcloud compute scp "$ssh_key_path" "${instance_name}:/tmp" \
      --zone="$zone" \
      --tunnel-through-iap; then
    echo "Error: インスタンス '$instance_name' への SSH 秘密鍵のコピーに失敗しました。" >&2
    return 1
  fi

  echo "[INFO] SSH 秘密鍵 '$ssh_key_path' がインスタンス '$instance_name' の /tmp に正常にコピーされました。"
}

function connect_gce_instance() {
  local FUNC_NAME="connect_gce_instance"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE]"
      echo "  INSTANCE_NAME : SSH 接続するインスタンスの名前"
      echo "  ZONE         : インスタンスが存在するゾーン (デフォルト: us-central1-a)"
      return 0
    fi
  done

  # 引数チェック: 少なくともインスタンス名は必須
  if [ $# -lt 1 ]; then
    echo "[ERROR] Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE]" >&2
    return 1
  fi

  local instance_name="$1"
  local zone="${2:-us-central1-a}"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] Error: gcloud コマンドが見つかりません。Google Cloud SDK がインストールされているか確認してください。" >&2
    return 1
  fi

  echo ""
  echo "[INFO] **Notice**: Setup Chrome Remote Desktop on your ssh connection and [Remote Desktop Service](https://remotedesktop.google.com/headless) if you want."
  echo ""

  # インスタンスへの SSH 接続処理
  if ! gcloud compute ssh "$instance_name" \
      --zone="$zone" \
      --tunnel-through-iap; then
    echo "[ERROR] Error: インスタンス '$instance_name' への SSH 接続に失敗しました。" >&2
    return 1
  fi

  echo "[INFO] インスタンス '$instance_name' への SSH 接続が正常に完了しました。"
}

function setup_gce_firewall_and_ssh() {
  local FUNC_NAME="setup_gce_firewall_and_ssh"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE] [SSH_KEY_PATH]"
      echo "  INSTANCE_NAME : SSH 接続対象のインスタンス名 (例: crd1)"
      echo "  ZONE         : インスタンスのゾーン (デフォルト: us-central1-a)"
      echo "  SSH_KEY_PATH : SSH 秘密鍵ファイルのパス (デフォルト: \$HOME/.ssh/google_compute_engine)"
      return 0
    fi
  done

  # 引数チェック：最低1つはインスタンス名を指定する必要があります
  if [ $# -lt 1 ]; then
    echo "[ERROR] Usage: ${FUNC_NAME} INSTANCE_NAME [ZONE] [SSH_KEY_PATH]" >&2
    return 1
  fi

  # パラメータの初期化（デフォルト値付き）
  local instance_name="$1"
  local zone="${2:-us-central1-a}"
  local ssh_key_path="${3:-$HOME/.ssh/google_compute_engine}"

  # 現在の日付 (YYYYMMDD) をサフィックスとして生成
  local today
  today=$(date +%Y%m%d)

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] Error: gcloud コマンドが見つかりません。Google Cloud SDK がインストールされているか確認してください。" >&2
    return 1
  fi

  echo "【STEP 1】 IAP TCP 転送用の SSH ファイアウォールルールを作成中..."
  # 第一引数にルール名＋実行日付を渡す
  if ! create_gce_iap_ssh_firewall_rule "allow-ssh-ingress-from-iap-${today}"; then
    echo "[ERROR] Error: IAP 用ファイアウォールルールの作成に失敗しました。" >&2
    return 1
  fi

  echo "【STEP 2】 VPC 内 SSH 用のファイアウォールルールを作成中..."
  if ! create_gce_ingress_ssh_firewall_rule "allow-ingress-ssh-${today}"; then
    echo "[ERROR] Error: VPC 内 SSH 用ファイアウォールルールの作成に失敗しました。" >&2
    return 1
  fi

  echo "【STEP 3】 SSH 秘密鍵のコピーを実行中..."
  if ! copy_gce_ssh_key "$instance_name" "$zone"; then
    echo "[ERROR] Error: インスタンス '$instance_name' への SSH 秘密鍵のコピーに失敗しました。" >&2
    return 1
  fi

  echo "【STEP 4】 インスタンスへの SSH 接続を実行中..."
  if ! connect_gce_instance "$instance_name" "$zone"; then
    echo "[ERROR] Error: インスタンス '$instance_name' への SSH 接続に失敗しました。" >&2
    return 1
  fi

  echo "[INFO] ファイアウォール設定、SSH 秘密鍵のコピー、SSH 接続が正常に完了しました。"
}

function set_gce_instance_metadata_from_yaml() {
  local vm_name="$1"
  local zone="$2"
  local yaml_file="${3:-env.yml}"
  local fn_name="set_gce_instance_metadata_from_yaml"
  send_discord_notification "VMの環境変数をYAMLから設定するよ！"

  # ヘルプオプション
  if [[ "$1" == "--help" ]]; then
    echo "Usage: set_instance_metadata_from_yaml <VM_NAME> <ZONE> [YAML_FILE]"
    echo "Example: set_instance_metadata_from_yaml my-vm us-central1-a env.yml"
    echo "If YAML_FILE is not specified, 'env.yml' will be used by default."
    return 0
  fi

  # YAMLファイルの存在チェック
  if [[ ! -f "$yaml_file" ]]; then
    echo "Error: YAML file '$yaml_file' not found!"
    return 1
  fi

  # YAMLを key=value 形式に変換
  local metadata_args=""
  while IFS=":" read -r key value; do
    # 空白を除去
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    # 空行やコメント行を無視
    if [[ -n "$key" && -n "$value" && "$key" != \#* ]]; then
      metadata_args+="$key=$value,"
    fi
  done < "$yaml_file"

  # 最後のカンマを削除
  metadata_args="${metadata_args%,}"

  if [[ -z "$metadata_args" ]]; then
    echo "[INFO] No valid metadata found in '$yaml_file'"
    return 0
  fi

  # gcloud compute instances add-metadata を実行
  gcloud compute instances add-metadata "$vm_name" --zone "$zone" --metadata "$metadata_args"

  local ret_code=$?

  if [ $ret_code -eq 0 ]; then
    send_discord_notification "VMの環境変数を設定したよ！"
    echo "[INFO] ${fn_name}: Env variables of instance '${vm_name}' have set successfully."
  else
    send_discord_notification_about_gce "失敗…" "VMの環境変数を設定できなかったよ…" "red"
    echo "[ERROR] ${fn_name}: Failed to set env variables for instance '${vm_name}'."
    return $ret_code
  fi
}

function list_gcloud_instances() {
  # ヘルプオプション
  if [[ "$1" == "--help" ]]; then
    echo "Usage: list_gcloud_instances [FILTER] [FORMAT]"
    echo "Example: list_gcloud_instances"
    echo "Example: list_gcloud_instances 'zone:us-central1-a'"
    echo "Example: list_gcloud_instances '' 'json'"
    echo ""
    echo "FILTER: Optional. Apply a filter to the instance list (e.g., 'zone:us-central1-a')."
    echo "FORMAT: Optional. Output format (default is table). Options: table, json, yaml, csv."
    return 0
  fi

  local default_format="table(name, zone.basename(), scheduling.preemptible.yesno(yes=true, no=''), networkInterfaces.internal_ip():label=INTERNAL_IP, external_ip():label=EXTERNAL_IP, status)"
  local filter="${1:-}"   # フィルタ条件 (デフォルトなし)
  local format="${2:-}"  # 表示フォーマット (デフォルトは table)

  if [[ -n "$format" ]]; then
    format="$default_format"
  fi

  if [[ -n "$filter" ]]; then
    gcloud compute instances list --filter="$filter" --format="$format"
  else
    gcloud compute instances list --format="$format"
  fi
}

function start_gce_instance() {
  local fn_name="start_gce_instance"
  send_discord_notification "VMを起動するよ！"
  # --help が指定された場合、使い方を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "Usage: ${fn_name} -i INSTANCE_NAME -z ZONE"
    echo ""
    echo "Example:"
    echo "  ${fn_name} -i my-instance -z us-central1-a"
    return 0
  fi

  local instance_name=""
  local zone=""

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--instance)
        instance_name="$2"
        shift 2
        ;;
      -z|--zone)
        zone="$2"
        shift 2
        ;;
      --help)
        echo "Usage: ${fn_name} -i INSTANCE_NAME -z ZONE"
        return 0
        ;;
      *)
        echo "Error: Unknown parameter: $1"
        echo "Usage: ${fn_name} -i INSTANCE_NAME -z ZONE"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [ -z "$instance_name" ] || [ -z "$zone" ]; then
    echo "Error: Missing required parameter(s)."
    echo "Usage: ${fn_name} -i INSTANCE_NAME -z ZONE"
    return 1
  fi

  # gcloud コマンドの実行
  gcloud compute instances start "$instance_name" --zone="$zone"

  # コマンド実行結果のチェック
  if [ $? -eq 0 ]; then
    echo "Instance '$instance_name' started successfully."
    send_discord_notification_about_gce "VMを起動するよ！" "VMが起動したよ！" "green"
  else
    echo "Error: Failed to start instance '$instance_name'." >&2
    send_discord_notification_about_gce "失敗…" "VMが起動できなかったよ…" "red"
    return 1
  fi
}

function stop_gce_instance() {
  # ローカル変数に関数名をセット
  local FUNC_NAME="stop_gce_instance"
  send_discord_notification "VMを停止するよ！"

  # --help が指定された場合は利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
    echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -i my-instance -z us-central1-a"
    return 0
  fi

  # 必要な変数の初期化
  local instance_name=""
  local zone=""

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--instance)
        instance_name="$2"
        shift 2
        ;;
      -z|--zone)
        zone="$2"
        shift 2
        ;;
      --help)
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
        echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -i my-instance -z us-central1-a"
        return 0
        ;;
      *)
        echo "[ERROR] ${FUNC_NAME}: Unknown parameter: $1"
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [[ -z "$instance_name" || -z "$zone" ]]; then
    echo "[ERROR] ${FUNC_NAME}: Missing required parameter(s)."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
    return 1
  fi

  # gcloud コマンドの実行
  echo "[INFO] ${FUNC_NAME}: Stopping instance '${instance_name}' in zone '${zone}'..."
  gcloud compute instances stop "$instance_name" --zone="$zone"
  local ret_code=$?

  if [ $ret_code -eq 0 ]; then
    send_discord_notification_about_gce "VMを停止するよ！" "VMを停止したよ！" "green"
    echo "[INFO] ${FUNC_NAME}: Instance '${instance_name}' stopped successfully."
  else
    send_discord_notification_about_gce "失敗…" "VMを停止できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to stop instance '${instance_name}'."
    return $ret_code
  fi
}

function reboot_gce_instance() {
  # ローカル変数に関数名を設定
  local FUNC_NAME="reboot_gce_instance"
  send_discord_notification "VMを再起動するよ！"

  # --help が指定された場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
    echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -i my-instance -z us-central1-a"
    return 0
  fi

  # 必要なパラメータの初期化
  local instance_name=""
  local zone=""

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--instance)
        instance_name="$2"
        shift 2
        ;;
      -z|--zone)
        zone="$2"
        shift 2
        ;;
      --help)
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
        echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -i my-instance -z us-central1-a"
        return 0
        ;;
      *)
        echo "[ERROR] ${FUNC_NAME}: Unknown parameter: $1"
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [[ -z "$instance_name" || -z "$zone" ]]; then
    echo "[ERROR] ${FUNC_NAME}: Missing required parameter(s)."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
    return 1
  fi

  # gcloud コマンドの実行
  echo "[INFO] ${FUNC_NAME}: Resetting instance '${instance_name}' in zone '${zone}'..."
  gcloud compute instances reset "$instance_name" --zone="$zone"
  local ret_code=$?

  if [ $ret_code -eq 0 ]; then
    send_discord_notification_about_gce "VMを再起動したよ！" "VMが起動したよ！" "green"
    echo "[INFO] ${FUNC_NAME}: Instance '${instance_name}' reset successfully."
  else
    send_discord_notification_about_gce "失敗…" "VMが再起動できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to reset instance '${instance_name}'."
    return $ret_code
  fi
}

function delete_gce_instance() {
  # ローカル変数に関数名を設定
  local FUNC_NAME="delete_gce_instance"
  send_discord_notification "VMを削除するよ！"

  # --help オプションが指定された場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
    echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -i my-instance -z us-central1-a"
    return 0
  fi

  # 必要な変数の初期化
  local instance_name=""
  local zone=""

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--instance)
        instance_name="$2"
        shift 2
        ;;
      -z|--zone)
        zone="$2"
        shift 2
        ;;
      --help)
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
        echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -i my-instance -z us-central1-a"
        return 0
        ;;
      *)
        echo "[ERROR] ${FUNC_NAME}: Unknown parameter: $1"
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [[ -z "$instance_name" || -z "$zone" ]]; then
    echo "[ERROR] ${FUNC_NAME}: Missing required parameter(s)."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i INSTANCE_NAME -z ZONE"
    return 1
  fi

  # gcloud コマンドの実行
  echo "[INFO] ${FUNC_NAME}: Deleting instance '${instance_name}' in zone '${zone}'..."
  gcloud compute instances delete "$instance_name" --zone="$zone" --quiet
  local ret_code=$?

  if [ $ret_code -eq 0 ]; then
    send_discord_notification_about_gce "削除したよ！" "VMを削除したよ！" "green"
    echo "[INFO] ${FUNC_NAME}: Instance '${instance_name}' deleted successfully."
  else
    send_discord_notification_about_gce "失敗…" "VMを削除できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to delete instance '${instance_name}'."
    return $ret_code
  fi
}
