#!/bin/sh
function create_secret() {
  local func_name=${FUNCNAME[0]}
  send_discord_notification "シークレットを作るよ！"

  # --help パラメータの場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> [replication_policy] [locations]"
    echo "[INFO] ${func_name}: replication_policy を省略した場合、デフォルトは \"automatic\" です。"
    echo "[INFO] ${func_name}: replication_policy が \"user-managed\" の場合は locations を必須とします。"
    echo "[INFO] ${func_name}: Example (automatic): ${func_name} test-secret"
    echo "[INFO] ${func_name}: Example (user-managed): ${func_name} test-secret user-managed us-central1,us-east1"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/secrets/versions/add"
    return 0
  fi

  # 引数は1～3個を許容。replication_policy が user-managed の場合は locations が必須
  if [[ $# -lt 1 || $# -gt 3 ]]; then
    echo "[ERROR] ${func_name}: 引数の数が正しくありません。"
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> [replication_policy] [locations]"
    return 1
  fi

  local secret_name="$1"
  local replication_policy="${2:-automatic}"

  # replication_policy が user-managed の場合、locations の指定を確認
  if [[ "${replication_policy}" == "user-managed" ]]; then
    if [[ $# -lt 3 ]]; then
      echo "[ERROR] ${func_name}: replication_policy が \"user-managed\" の場合、locations を指定する必要があります。"
      echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> user-managed <locations>"
      return 1
    fi
    local locations="$3"
    echo "[INFO] ${func_name}: シークレット「${secret_name}」をレプリケーションポリシー「user-managed」、ロケーション「${locations}」で作成中..."
    if ! gcloud secrets create "${secret_name}" --replication-policy="user-managed" --locations="${locations}"; then
      echo "[ERROR] ${func_name}: シークレット「${secret_name}」の作成に失敗しました。"
      return 1
    fi
  else
    send_discord_notification_about_gsm "失敗…" "シークレットが作れなかったよ…" "red"
    echo "[INFO] ${func_name}: シークレット「${secret_name}」をレプリケーションポリシー「${replication_policy}」で作成中..."
    if ! gcloud secrets create "${secret_name}" --replication-policy="${replication_policy}"; then
      echo "[ERROR] ${func_name}: シークレット「${secret_name}」の作成に失敗しました。"
      return 1
    fi
  fi

  send_discord_notification_about_gsm "作ったよ！" "シークレットを作ったよ！" "green"
  echo "[INFO] ${func_name}: シークレット「${secret_name}」が正常に作成されました。"
  return 0
}

function add_secret_version() {
  local func_name=${FUNCNAME[0]}
  send_discord_notification "シークレットのバージョンを作るよ！"

  # --help パラメータの場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <secret_value>"
    echo "[INFO] ${func_name}: Example: ${func_name} test-secret 'your secret value'"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/secrets/versions/add"
    return 0
  fi

  # 必須パラメータの確認
  if [[ $# -ne 2 ]]; then
    echo "[ERROR] ${func_name}: 引数の数が正しくありません。"
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <secret_value>"
    return 1
  fi

  local secret_name=${1}
  local secret_value=${2}

  echo "[INFO] ${func_name}: シークレット「${secret_name}」に新しいバージョンを追加中..."

  # gcloudコマンドの実行とエラーチェック
  if ! echo -n "${secret_value}" | gcloud secrets versions add "${secret_name}" --data-file=-; then
    send_discord_notification_about_gsm "失敗…" "シークレットにバージョンを作れなかったよ…" "red"
    echo "[ERROR] ${func_name}: シークレット「${secret_name}」の新しいバージョンの追加に失敗しました。"
    return 1
  fi

  send_discord_notification_about_gsm "作ったよ！" "シークレットにバージョンを追加したよ！" "green"
  echo "[INFO] ${func_name}: シークレット「${secret_name}」に新しいバージョンを正常に追加しました。"
  return 0
}

function create_and_add_secret_version() {
  local func_name=${FUNCNAME[0]}
  send_discord_notification "シークレットとバージョンを作るよ！"

  # --help パラメータの場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <secret_value> [replication_policy] [locations]"
    echo "[INFO] ${func_name}: replication_policy を省略した場合、デフォルトは \"automatic\" です。"
    echo "[INFO] ${func_name}: replication_policy が \"user-managed\" の場合は locations を必須とします。"
    echo "[INFO] ${func_name}: Example: (automatic): ${func_name} test-secret 'your secret value'"
    echo "[INFO] ${func_name}: Example: (user-managed): ${func_name} test-secret 'your secret value' user-managed us-central1,us-east1"
    return 0
  fi

  # 引数は2～4個を許容。replication_policy が user-managed の場合は locations が必須
  if [[ $# -lt 2 || $# -gt 4 ]]; then
    echo "[ERROR] ${func_name}: 引数の数が正しくありません。"
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <secret_value> [replication_policy] [locations]"
    return 1
  fi

  local secret_name="$1"
  local secret_value="$2"
  local replication_policy="${3:-automatic}"

  if [[ "${replication_policy}" == "user-managed" ]]; then
    if [[ $# -lt 4 ]]; then
      echo "[ERROR] ${func_name}: replication_policy が \"user-managed\" の場合、locations を指定する必要があります。"
      echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <secret_value> user-managed <locations>"
      return 1
    fi
    local locations="$4"
  fi

  echo "[INFO] ${func_name}: シークレット「${secret_name}」の作成を開始します。"
  if [[ "${replication_policy}" == "user-managed" ]]; then
    create_secret "${secret_name}" "${replication_policy}" "${locations}"
  else
    create_secret "${secret_name}" "${replication_policy}"
  fi

  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${func_name}: create_secret の実行中にエラーが発生しました。"
    return 1
  fi

  echo "[INFO] ${func_name}: シークレット「${secret_name}」の新しいバージョンを追加します。"
  add_secret_version "${secret_name}" "${secret_value}"
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${func_name}: add_secret_version の実行中にエラーが発生しました。"
    return 1
  fi

  send_discord_notification_about_gsm "作ったよ！" "シークレットと新しいバージョンを追加したよ！" "green"
  echo "[INFO] ${func_name}: シークレット「${secret_name}」の作成とバージョン追加が完了しました。"
  return 0
}

function access_secret_version() {
  local func_name=${FUNCNAME[0]}
  send_discord_notification "シークレットの値を取得するよ！"

  # --help パラメータの場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> [version]"
    echo "[INFO] ${func_name}: version を省略した場合、デフォルトは \"latest\" です。"
    echo "[INFO] ${func_name}: Example (latest version): ${func_name} test-secret"
    echo "[INFO] ${func_name}: Example (specified version): ${func_name} test-secret 3"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/secrets/versions/access"
    return 0
  fi

  # 必須パラメータの確認（1～2個の引数を許容）
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "[ERROR] ${func_name}: 引数の数が正しくありません。"
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> [version]"
    return 1
  fi

  local secret_name="$1"
  # バージョンが指定されなかった場合は "latest" を使用
  local version="${2:-latest}"

  echo "[INFO] ${func_name}: シークレット「${secret_name}」のバージョン \"${version}\" の値を取得中..."

  # gcloud コマンドの実行とエラーチェック
  local result
  result=$(gcloud secrets versions access "${version}" --secret="${secret_name}" 2>&1)
  if [[ $? -ne 0 ]]; then
    send_discord_notification_about_gsm "失敗…" "シークレットを取れなかったよ…" "red"
    echo "[ERROR] ${func_name}: シークレット「${secret_name}」のバージョン \"${version}\" の値の取得に失敗しました。"
    echo "[ERROR] ${func_name}: ${result}"
    return 1
  fi

  send_discord_notification_about_gsm "取れた！" "シークレットを取得したよ！" "green"
  echo "[INFO] ${func_name}: シークレット「${secret_name}」のバージョン \"${version}\" の値は以下の通りです:"
  echo "${result}"
  return 0
}

function update_secret_labels() {
  local func_name=${FUNCNAME[0]}
  send_discord_notification "シークレットのラベルを更新するよ！"

  # --help パラメータの場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <labels>"
    echo "[INFO] ${func_name}: labels は KEY=VALUE,... の形式で指定します。"
    echo "[INFO] ${func_name}: Example: ${func_name} test-secret env=prod,team=devops"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/secrets/update"
    return 0
  fi

  # 必須パラメータの確認（引数は2個必要）
  if [[ $# -ne 2 ]]; then
    echo "[ERROR] ${func_name}: 引数の数が正しくありません。"
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <labels>"
    return 1
  fi

  local secret_name="$1"
  local labels="$2"

  echo "[INFO] ${func_name}: シークレット「${secret_name}」のラベルを「${labels}」に更新中..."

  # gcloud コマンドの実行とエラーチェック
  if ! gcloud secrets update "${secret_name}" --update-labels="${labels}"; then
    send_discord_notification_about_gsm "失敗…" "シークレットのラベル更新に失敗したよ…" "red"
    echo "[ERROR] ${func_name}: シークレット「${secret_name}」のラベル更新に失敗しました。"
    return 1
  fi

  send_discord_notification_about_gsm "更新したよ！" "シークレットのラベルを更新したよ！" "green"
  echo "[INFO] ${func_name}: シークレット「${secret_name}」のラベルが正常に更新されました。"
  return 0
}

# NOT applicable...
function update_secret_version_aliases() {
  local func_name=${FUNCNAME[0]}
  send_discord_notification "シークレットのエイリアスを更新するよ！"

  # --help パラメータの場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <alias_option>"
    echo "[INFO] ${func_name}: <alias_option> は以下のいずれかの形式で指定してください:"
    echo "  --clear-version-aliases"
    echo "  --remove-version-aliases=KEY1,KEY2,..."
    echo "  --update-version-aliases=KEY1=VALUE1,KEY2=VALUE2,..."
    echo "[INFO] ${func_name}: Example: ${func_name} test-secret --clear-version-aliases"
    echo "[INFO] ${func_name}: Example: ${func_name} test-secret --remove-version-aliases=prod,dev"
    echo "[INFO] ${func_name}: Example: ${func_name} test-secret --update-version-aliases=env=prod,team=devops"
    echo "[INFO] ${func_name}: Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/secrets/update"
    return 0
  fi

  # 必須パラメータの確認（引数は2個必要）
  if [[ $# -ne 2 ]]; then
    echo "[ERROR] ${func_name}: 引数の数が正しくありません。"
    echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <alias_option>"
    return 1
  fi

  local secret_name="$1"
  local alias_option="$2"

  # alias_option の形式チェック
  case "$alias_option" in
    --clear-version-aliases)
      ;;  # OK
    --remove-version-aliases=*)
      ;;  # OK
    --update-version-aliases=*)
      ;;  # OK
    *)
      echo "[ERROR] ${func_name}: 無効な alias_option です。"
      echo "[INFO] ${func_name}: Usage: ${func_name} <secret_name> <alias_option>"
      return 1
      ;;
  esac

  echo "[INFO] ${func_name}: シークレット「${secret_name}」のバージョンエイリアスを更新中 (option: ${alias_option})..."

  # gcloud コマンドの実行とエラーチェック
  if ! gcloud secrets update "${secret_name}" ${alias_option}; then
    send_discord_notification_about_gsm "失敗…" "シークレットのエイリアス更新に失敗したよ…" "red"
    echo "[ERROR] ${func_name}: シークレット「${secret_name}」のバージョンエイリアス更新に失敗しました。"
    return 1
  fi

  send_discord_notification_about_gsm "更新したよ！" "シークレットのエイリアスを更新したよ！" "green"
  echo "[INFO] ${func_name}: シークレット「${secret_name}」のバージョンエイリアスが正常に更新されました。"
  return 0
}
