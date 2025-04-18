#!/bin/sh
function deploy_cloud_run_container() {
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "コンテナをデプロイするよ！"

  # --help オプションのチェック
  for arg in "$@"; do
    if [ "$arg" = "--help" ]; then
      echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} IMAGE_NAME PROJECT_ID [REGION]"
      echo "  IMAGE_NAME : デプロイする Cloud Run サービスの名前"
      echo "  PROJECT_ID : 対象の GCP プロジェクトID"
      echo "  REGION     : リージョンのサフィックス (例: 'central1' → us-central1, デフォルト: central1)"
      echo "  TIMEOUT    : value for timeout (例: '40m', '1m32s' and so on. '40m' as a default.)"
      echo "  SERVICE_ACCOUNT: サービスアカウントのメールアドレス (例: my-service-account@my-project.iam.gserviceaccount.com)"
      echo "[INFO] ${FUNC_NAME}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/run/deploy"
      return 0
    fi
  done

  # 引数チェック: IMAGE_NAME と PROJECT_ID は必須
  if [ $# -lt 2 ]; then
    echo "[ERROR] ${FUNC_NAME}: Usage: ${FUNC_NAME} IMAGE_NAME PROJECT_ID [REGION]" >&2
    return 1
  fi

  # 引数チェック: IMAGE_NAME と PROJECT_ID は必須。最大5個の引数を許容。
  if [ "$#" -lt 2 ] || [ "$#" -gt 5 ]; then
    echo "[ERROR] ${FUNC_NAME}: Usage: ${FUNC_NAME} IMAGE_NAME PROJECT_ID [REGION] [TIMEOUT] [SERVICE_ACCOUNT]" >&2
    return 1
  fi

  # パラメータの設定
  local image_name="$1"
  local project_id="$2"
  local full_region="${3:us-central1}"
  local timeout="${4:-40m}"
  local service_account="${5:-}"

  # gcloud コマンドの存在確認
  if ! command -v gcloud >/dev/null 2>&1; then
    echo "[ERROR] ${FUNC_NAME}: gcloud コマンドが見つかりません。Google Cloud SDK のインストールを確認してください。" >&2
    return 1
  fi

  # Dockerfile の存在チェック
  if [ ! -f "./Dockerfile" ]; then
    echo "[ERROR] ${FUNC_NAME}: 現在のディレクトリに Dockerfile が見つかりません。" >&2
    return 1
  fi

  # Cloud Run サービスのデプロイ処理
  local cmd=( "gcloud" "run" "deploy" "$image_name" "--source" "." "--project=${project_id}" "--region=${full_region}" "--allow-unauthenticated" "--timeout=${timeout}" )
  if [ -n "${service_account}" ]; then
    cmd+=( "--service-account=${service_account}" )
  fi
  echo "cmd is here: ${cmd[*]}"

  echo "[INFO] ${FUNC_NAME}: Running command: ${cmd[*]}"
  echo ""
  echo "======= Deployments on Google Cloud ========================================================================"
  if ! "${cmd[@]}"; then
    send_discord_notification_about_gcloud_run "失敗…" "コンテナをデプロイできなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Cloud Run サービス '$image_name' のデプロイに失敗しました。" >&2
    return 1
  fi
  echo "============================================================================================================"
  echo ""

  send_discord_notification_about_gcloud_run "デプロイしたよ！" "コンテナをデプロイしたよ！" "green"
}

function update_env_for_cloud_run_container() {
  # ローカル変数に関数名を設定
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "コンテナの環境変数を更新するよ！"

  # --help オプションが指定された場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -i IMAGE_NAME -p PROJECT_ID -r REGION -e ENV_FILE"
    echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -p my-project -i my-image -r my-region -e ENV_FILE"
    echo "[INFO] ${FUNC_NAME}:"
    echo "[INFO] ${FUNC_NAME}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/run/deploy"
    return 0
  fi

  # 必要な変数の初期化
  local project_id=""
  local image_name=""
  local region=""
  local env_file="env.yml"
  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--project)
        project_id="$2"
        shift 2
        ;;
      -i|--image)
        image_name="$2"
        shift 2
        ;;
      -r|--region)
        region="$2"
        shift 2
        ;;
      -e|--env-file)
        env_file="$2"
        shift 2
        ;;
      --help)
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -p PROJECT_ID -i IMAGE_NAME -r REGION [-e ENV_FILE]"
        echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -p my-project -i my-image -r my-region [-e env.yml]"
        return 0
        ;;
      *)
        echo "[ERROR] ${FUNC_NAME}: Unknown parameter: $1"
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -p PROJECT_ID -i IMAGE_NAME -r REGION [-e ENV_FILE]"
        return 1
        ;;
    esac
  done

  # 必須パラメータ IMAGE_NAME のチェック
  if [[ -z "$image_name" ]]; then
    echo "[ERROR] ${FUNC_NAME}: IMAGE_NAME is required."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -p PROJECT_ID -i IMAGE_NAME -r REGION [-e ENV_FILE]"
    return 1
  fi

  # 必須パラメータ IMAGE_NAME のチェック
  if [[ -z "$project_id" ]]; then
    echo "[ERROR] ${FUNC_NAME}: PROJECT_ID is required."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -p PROJECT_ID -i IMAGE_NAME -r REGION [-e ENV_FILE]"
    return 1
  fi

  # 必須パラメータ REGION のチェック
  if [[ -z "$region" ]]; then
    echo "[ERROR] ${FUNC_NAME}: REGION is required."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -p PROJECT_ID -i IMAGE_NAME -r REGION [-e ENV_FILE]"
    return 1
  fi

  # gcloud コマンドの実行
  echo "[INFO] ${FUNC_NAME}: Deploying service with image '${image_name}'..."
  echo ""
  echo "======= Deployments on Google Cloud ========================================================================"
  gcloud run deploy "$image_name" \
    --image="gcr.io/${project_id}/${image_name}" \
    --region="$region" \
    --env-vars-file="$env_file";
  echo "============================================================================================================"
  echo ""

  local ret_code=$?
  if [[ $ret_code -eq 0 ]]; then
    send_discord_notification_about_gcloud_run "更新したよ！" "コンテナの環境変数を更新したよ！" "green"
    echo "[INFO] ${FUNC_NAME}: Service deployed successfully."
  else
    send_discord_notification_about_gcloud_run "失敗…" "コンテナの環境変数を更新できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to deploy service."
    return $ret_code
  fi
}

function deploy_cloud_run_function() {
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "関数をデプロイするよ！"

  # --help が最初の引数の場合、使い方を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -r REGION -n FUNCTION_NAME -e ENTRY_POINT"
    echo ""
    echo "[INFO] ${FUNC_NAME}: Example:"
    echo "  ${FUNC_NAME} -r us-central1 -n my-function -e MyFunction"
    return 0
  fi

  # 必要な変数の初期化
  local region=""
  local name=""
  local entry_point=""

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--region)
        region="$2"
        shift 2
        ;;
      -n|--name)
        name="$2"
        shift 2
        ;;
      -e|--entry-point)
        entry_point="$2"
        shift 2
        ;;
      --help)
        echo "[INFO] ${FUNC_NAME}: Usage: deploy_function -r REGION -n FUNCTION_NAME -e ENTRY_POINT"
        echo "[INFO] ${FUNC_NAME}:"
        echo "[INFO] ${FUNC_NAME}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/functions/deploy"
        return 0
        ;;
      *)
        echo "[ERROR] ${FUNC_NAME}: Error: Unknown parameter: $1"
        echo "[INFO] ${FUNC_NAME}: Usage: deploy_function -r REGION -n FUNCTION_NAME -e ENTRY_POINT"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [ -z "$region" ] || [ -z "$name" ] || [ -z "$entry_point" ]; then
    echo "[ERROR] ${FUNC_NAME}: Error: Missing required parameter(s)."
    echo "[INFO] ${FUNC_NAME}: Usage: deploy_function -r REGION -n FUNCTION_NAME -e ENTRY_POINT"
    return 1
  fi

  # gcloud コマンドの実行
  echo ""
  echo "======= Deployments on Google Cloud ========================================================================"
  gcloud functions deploy "$name" \
    --gen2 \
    --runtime=go122 \
    --region="$region" \
    --source=. \
    --entry-point="$entry_point" \
    --trigger-http \
    --allow-unauthenticated \
    --timeout=180s
  echo "============================================================================================================"
  echo ""

  # コマンド実行結果のチェック
  if [ $? -eq 0 ]; then
    send_discord_notification_about_gcloud_run_function "デプロイしたよ！" "関数をデプロイしたよ！" "green"
    echo "[INFO] ${FUNC_NAME}: Deployment succeeded."
  else
    send_discord_notification_about_gcloud_run_function "失敗…" "関数をデプロイできなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Deployment failed." >&2
    return 1
  fi
}

function deploy_cloud_run_function_triggered_by_pubsub() {
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "関数をデプロイするよ！"
  local USAGE="[INFO] Usage: $FUNC_NAME -f <FUNCTION_NAME> -p <PROJECT> -s <SERVICE_ACCOUNT> -t <TOPIC_ID> [-r <REGION>] [-E <ENTRY_POINT>] [-c <API_CLIENT_ID>] [-k <API_CLIENT_SECRET>] [-e <API_ENDPOINT>]
(defaults: --region=us-central1, --entry-point=ProcessPubSub)
Long options:
  --function-name, --project, --region, --service-account, --topic, --entry-point, --api-client-id, --api-client-secret, --api-endpoint, --help

Examples:
  # API パラメータを指定する場合:
  $FUNC_NAME --function-name my-function \
    --project My_PROJECT \
    --service-account MY_APP_ENGINE_SERVICE_ACCOUNT \
    --topic MY_PUBSUB_TOPIC_ID \
    --region MY_REGION \
    --entry-point CustomEntryPoint \
    --api-client-id AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \
    --api-client-secret BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB \
    --api-endpoint https://CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

  # --region および --entry-point を省略する場合（デフォルト値が使用されます）:
  $FUNC_NAME -f my-function \
    -p My_PROJECT \
    -s MY_APP_ENGINE_SERVICE_ACCOUNT \
    -t MY_PUBSUB_TOPIC_ID
"

  # GNU getopt を使用してオプションを解析
  local OPTIONS
  OPTIONS=$(getopt -o f:p:r:s:t:E:c:k:e:h --long function-name:,project:,region:,service-account:,topic:,entry-point:,api-client-id:,api-client-secret:,api-endpoint:,help -n "$FUNC_NAME" -- "$@")
  if [ $? -ne 0 ]; then
    echo "[ERROR] ${FUNC_NAME}: Error parsing arguments." >&2
    echo "$USAGE" >&2
    return 1
  fi

  eval set -- "$OPTIONS"

  # オプション解析
  while true; do
    case "$1" in
      -f|--function-name)
        FUNCTION_NAME="$2"
        shift 2
        ;;
      -p|--project)
        PROJECT="$2"
        shift 2
        ;;
      -r|--region)
        REGION="$2"
        shift 2
        ;;
      -s|--service-account)
        SERVICE_ACCOUNT="$2"
        shift 2
        ;;
      -t|--topic)
        TOPIC_ID="$2"
        shift 2
        ;;
      -E|--entry-point)
        ENTRY_POINT="$2"
        shift 2
        ;;
      -c|--api-client-id)
        API_CLIENT_ID="$2"
        shift 2
        ;;
      -k|--api-client-secret)
        API_CLIENT_SECRET="$2"
        shift 2
        ;;
      -e|--api-endpoint)
        API_ENDPOINT="$2"
        shift 2
        ;;
      -h|--help)
        echo "$USAGE"
        echo "[INFO] ${FUNC_NAME}:"
        echo "[INFO] ${FUNC_NAME}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/functions/deploy"
        return 0
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "[ERROR] Invalid option: $1"
        echo "$USAGE"
        return 1
        ;;
    esac
  done

  # デフォルト値の設定
  if [ -z "$REGION" ]; then
    REGION="us-central1"
    echo "[INFO] --region not specified. Using default: ${REGION}"
  fi
  if [ -z "$ENTRY_POINT" ]; then
    ENTRY_POINT="ProcessPubSub"
    echo "[INFO] --entry-point not specified. Using default: ${ENTRY_POINT}"
  fi

  # 必須パラメータのチェック
  if [ -z "$FUNCTION_NAME" ] || [ -z "$PROJECT" ] || [ -z "$SERVICE_ACCOUNT" ] || [ -z "$TOPIC_ID" ]; then
    echo "[ERROR] Missing required parameters."
    echo "$USAGE"
    return 1
  fi

  # 任意のAPIパラメータが指定された場合、環境変数用の文字列を作成
  local ENV_VARS=""
  if [ -n "$API_CLIENT_ID" ]; then
    ENV_VARS="SCRIPT_MANAGER_API_CLIENT_ID=${API_CLIENT_ID}"
  fi
  if [ -n "$API_CLIENT_SECRET" ]; then
    if [ -n "$ENV_VARS" ]; then
      ENV_VARS="${ENV_VARS},SCRIPT_MANAGER_API_CLIENT_SECRET=${API_CLIENT_SECRET}"
    else
      ENV_VARS="SCRIPT_MANAGER_API_CLIENT_SECRET=${API_CLIENT_SECRET}"
    fi
  fi
  if [ -n "$API_ENDPOINT" ]; then
    if [ -n "$ENV_VARS" ]; then
      ENV_VARS="${ENV_VARS},SCRIPT_MANAGER_API_ENDPOINT=${API_ENDPOINT}"
    else
      ENV_VARS="SCRIPT_MANAGER_API_ENDPOINT=${API_ENDPOINT}"
    fi
  fi

  echo "[INFO] Deploying ${FUNCTION_NAME} function..."

  # コマンド実行（--set-env-vars は ENV_VARS が空でなければ追加）
  echo ""
  echo "======= Deployments on Google Cloud ========================================================================"
  if [ -n "$ENV_VARS" ]; then
    gcloud functions deploy "${FUNCTION_NAME}" \
      --gen2 \
      --runtime=go123 \
      --project="${PROJECT}" \
      --region="${REGION}" \
      --source=. \
      --entry-point="${ENTRY_POINT}" \
      --trigger-service-account="${SERVICE_ACCOUNT}" \
      --trigger-topic="${TOPIC_ID}" \
      --allow-unauthenticated \
      --timeout=180s \
      --set-env-vars="${ENV_VARS}"
  else
    gcloud functions deploy "${FUNCTION_NAME}" \
      --gen2 \
      --runtime=go123 \
      --project="${PROJECT}" \
      --region="${REGION}" \
      --source=. \
      --entry-point="${ENTRY_POINT}" \
      --trigger-service-account="${SERVICE_ACCOUNT}" \
      --trigger-topic="${TOPIC_ID}" \
      --allow-unauthenticated \
      --timeout=180s
  fi
  echo "============================================================================================================"
  echo ""

  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcloud_run_function "失敗…" "関数をデプロイできなかったよ…" "red"
    echo "[ERROR] Deployment failed."
    return 1
  fi

  send_discord_notification_about_gcloud_run_function "デプロイしたよ！" "関数をデプロイしたよ！" "green"
  echo "[INFO] Deployment succeeded."
  return 0
}

function update_env_for_cloud_run_function() {
  # ローカル変数に関数名を設定
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "関数の環境変数を更新するよ！"

  # --help オプションが指定された場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -n SERVICE_NAME -r REGION -e ENV_VARS"
    echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -n my-service -r us-central1 -e KEY1=VALUE1,KEY2=VALUE2"
    echo "[INFO] ${FUNC_NAME}:"
    echo "[INFO] ${FUNC_NAME}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/run/services/update"
    return 0
  fi

  # 必要な変数の初期化
  local service=""
  local env_vars=""

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--name)
        service="$2"
        shift 2
        ;;
      -r|--region)
        region="$2"
        shift 2
        ;;
      -e|--env-vars)
        env_vars="$2"
        shift 2
        ;;
      --help)
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -n SERVICE_NAME -r REGION -e ENV_VARS"
        echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -n my-service -r us-central1 -e KEY1=VALUE1,KEY2=VALUE2"
        return 0
        ;;
      *)
        echo "[ERROR] ${FUNC_NAME}: Unknown parameter: $1"
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -n SERVICE_NAME -r REGION -e ENV_VARS"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [[ -z "$service" || -z "$env_vars" ]]; then
    echo "[ERROR] ${FUNC_NAME}: Missing required parameter(s)."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -n SERVICE_NAME -r REGION -e ENV_VARS"
    return 1
  fi

  # gcloud コマンドの実行
  echo "[INFO] ${FUNC_NAME}: Updating service '${service}' with environment variables '${env_vars}'..."
  echo ""
  echo "======= Deployments on Google Cloud ========================================================================"
  gcloud run services update "$service" --region "$region" --update-env-vars "$env_vars"
  echo "============================================================================================================"
  echo ""

  local ret_code=$?
  if [[ $ret_code -eq 0 ]]; then
    send_discord_notification_about_gcloud_run_function "更新したよ！" "関数の環境変数を更新したよ！" "green"
    echo "[INFO] ${FUNC_NAME}: Service '${service}' updated successfully."
  else
    send_discord_notification_about_gcloud_run_function "失敗…" "関数の環境変数を更新できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to update service '${service}'."
    return $ret_code
  fi
}

function update_env_for_cloud_run_service() {
  # ローカル変数に関数名を設定
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "サービスの環境変数を更新するよ！"

  # --help オプションが指定された場合、利用方法を表示して終了
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -n SERVICE_NAME -p PROJECT -r REGION -f FILE_PATH"
    echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -s my-service -p project_id -r us-central1 -f env.yml"
    echo "[INFO] ${FUNC_NAME}:"
    echo "[INFO] ${FUNC_NAME}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/run/services/update"
    return 0
  fi

  # 必要な変数の初期化
  local service=""
  local project=""
  local region=""
  local file_path="env.yml"

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--service)
        service="$2"
        shift 2
        ;;
      -p|--project)
        project="$2"
        shift 2
        ;;
      -r|--region)
        region="$2"
        shift 2
        ;;
      -f|--file)
        file_path="$2"
        shift 2
        ;;
      --help)
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -n SERVICE_NAME -p PROJECT -r REGION -f FILE_PATH"
        echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -s my-service -p project_id -r us-central1 -f env.yml"
        return 0
        ;;
      *)
        echo "[ERROR] ${FUNC_NAME}: Unknown parameter: $1"
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -n SERVICE_NAME -p PROJECT -r REGION -f FILE_PATH"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [[ -z "$service" || -z "$project" || -z "$region" ]]; then
    echo "[ERROR] ${FUNC_NAME}: Missing required parameter(s)."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -n SERVICE_NAME -p PROJECT -r REGION -f FILE_PATH"
    return 1
  fi

  # file_path の存在チェック
  if [ ! -f "./$file_path" ]; then
    echo "[Error] ${FUNC_NAME}: Error: 現在のディレクトリに ${file_path} が見つかりません。" >&2
    return 1
  fi

  # gcloud コマンドの実行
  echo "[INFO] ${FUNC_NAME}: Updating service '${service}' with environment variables from file '${file_path}'..."
  echo ""
  echo "======= Deployments on Google Cloud ========================================================================"
  gcloud run services update "$service" \
    --project "$project" \
    --region "$region" \
    --env-vars-file="$file_path";
  echo "============================================================================================================"
  echo ""
  local ret_code=$?

  if [[ $ret_code -eq 0 ]]; then
    send_discord_notification_about_gcloud_run "更新したよ！" "サービスの環境変数を更新したよ！" "green"
    echo "[INFO] ${FUNC_NAME}: Service '${service}' updated successfully."
  else
    send_discord_notification_about_gcloud_run "失敗…" "サービスの環境変数を更新できなかったよ…" "red"
    echo "[ERROR] ${FUNC_NAME}: Failed to update service '${service}'."
    return $ret_code
  fi
}

function create_cloud_pubsub_topic() {
  local funcName="${FUNCNAME[0]}"

  # --help オプションが指定された場合、利用方法を表示する
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: Usage:"
    echo "[INFO] ${funcName}:   ${funcName} <TOPIC_NAME> [MESSAGE_RETENTION_DURATION]"
    echo "[INFO] ${funcName}: Example:"
    echo "[INFO] ${funcName}:   ${funcName} my-topic message-retention-duration"
    echo "[INFO] ${funcName}:   - TOPIC_NAME: 必須"
    echo "[INFO] ${funcName}:   - MESSAGE_RETENTION_DURATION: 省略時は '1d'"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/pubsub/topics/create"
    return 0
  fi

  # パラメータが不足している場合はエラーを返す
  if [ "$#" -lt 1 ]; then
    echo "[ERROR] ${funcName}: Missing required parameter TOPIC_NAME. Use --help for usage."
    return 1
  fi

  local topic_name="$1"
  local message_retention_duration="${2:-1d}"
  echo "[INFO] ${funcName}: Creating topic '${topic_name}'..."

  echo ""
  echo "======= Deployments on Google Cloud ========================================================================"
  gcloud pubsub topics create "${topic_name}" --message-retention-duration="${message_retention_duration}"
  echo "============================================================================================================"
  echo ""
  local ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "[ERROR] ${funcName}: Failed to create topic '${topic_name}'."
    return ${ret}
  fi

  echo "[INFO] ${funcName}: Topic '${topic_name}' created successfully."
}

function list_cloud_pubsub_topics() {
  local funcName="${FUNCNAME[0]}"

  # --help オプションが指定された場合、利用方法を表示する
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: Usage: ${funcName} <topic_name>"
    echo "[INFO] ${funcName}: Example: ${funcName} my-topic"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/pubsub/topics/list"
    return 0
  fi

  # トピック名パラメータが不足している場合はエラーを返す
  if [ "$#" -lt 1 ]; then
    echo "[ERROR] ${funcName}: Missing topic name parameter. Use --help for usage."
    return 1
  fi

  local topic_name="$1"
  local filter="name.scope(topic):'${topic_name}'"

  echo "[INFO] ${funcName}: Listing topics with filter: ${filter}"
  echo ""
  echo "======= Cloud Pub/Sub on Google Cloud ======================================================================"
  gcloud pubsub topics list --filter="${filter}"
  echo "============================================================================================================"
  echo ""
  local ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "[ERROR] ${funcName}: Failed to list topics with filter: ${filter}"
    return ${ret}
  fi

  echo "[INFO] ${funcName}: Topics listed successfully."
}

function list_cloud_pubsub_subscriptions() {
  local funcName="${FUNCNAME[0]}"

  # --help オプションが指定された場合、利用方法を表示する
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: Usage:"
    echo "[INFO] ${funcName}:   ${funcName} [SUBSCRIPTION_NAME] [--uri]"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}:   - SUBSCRIPTION_NAME: オプション。指定した場合、名前でフィルターをかけます。"
    echo "[INFO] ${funcName}:   - --uri            : オプション。指定すると、出力に URI を付加します。"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Example:"
    echo "[INFO] ${funcName}:   ${funcName} my-subscription --uri"
    echo "[INFO] ${funcName}:   ${funcName} my-subscription"
    echo "[INFO] ${funcName}:   ${funcName} --uri"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/pubsub/subscriptions/list"
    return 0
  fi

  local subscription=""
  local uri_option=""

  # パラメータ解析
  if [ "$#" -ge 1 ]; then
    if [[ "$1" == "--uri" ]]; then
      uri_option="--uri"
    else
      subscription="$1"
      shift
      if [ "$#" -ge 1 ] && [[ "$1" == "--uri" ]]; then
        uri_option="--uri"
      fi
    fi
  fi

  local cmd="gcloud pubsub subscriptions list"
  if [ -n "${subscription}" ]; then
    local filter="name.scope(subscription):'${subscription}'"
    cmd="${cmd} --filter=\"${filter}\""
    echo "[INFO] ${funcName}: Listing subscriptions with filter: ${filter}"
  else
    echo "[INFO] ${funcName}: Listing all subscriptions."
  fi

  if [ -n "${uri_option}" ]; then
    cmd="${cmd} ${uri_option}"
  fi

  # コマンド実行
  echo ""
  echo "======= Cloud Pub/Sub on Google Cloud ======================================================================"
  eval ${cmd}
  echo "============================================================================================================"
  echo ""
  local ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "[ERROR] ${funcName}: Failed to list subscriptions."
    return ${ret}
  fi

  echo "[INFO] ${funcName}: Subscriptions listed successfully."
}

function create_cloud_pubsub_subscription() {
  local funcName="${FUNCNAME[0]}"

  # --help オプションが指定された場合、利用方法を表示する
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: Usage:"
    echo "[INFO] ${funcName}:   ${funcName} <SUBSCRIPTION> <TOPIC> <TOPIC_PROJECT> <PUSH_ENDPOINT> <SERVICE_ACCOUNT_EMAIL> [MESSAGE_RETENTION_DURATION] [EXPIRATION_PERIOD] [MAX_RETRY_DELAY] [MIN_RETRY_DELAY] [ACK_DEADLINE]"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}:   - SUBSCRIPTION: 必須"
    echo "[INFO] ${funcName}:   - TOPIC: 必須"
    echo "[INFO] ${funcName}:   - TOPIC_PROJECT: 必須"
    echo "[INFO] ${funcName}:   - SERVICE_ACCOUNT_EMAIL: 必須"
    echo "[INFO] ${funcName}:   - PUSH_ENDPOINT: 省略時は 'https://<TOPIC_PROJECT>.appspot.com/<SUBSCRIPTION>'"
    echo "[INFO] ${funcName}:   - MESSAGE_RETENTION_DURATION: 省略時は '1d'"
    echo "[INFO] ${funcName}:   - EXPIRATION_PERIOD: 省略時は 'never'"
    echo "[INFO] ${funcName}:   - MAX_RETRY_DELAY: 省略時は '600s'"
    echo "[INFO] ${funcName}:   - MIN_RETRY_DELAY: 省略時は '10s'"
    echo "[INFO] ${funcName}:   - ACK_DEADLINE: 秒単位で入力。省略時は '600'"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Example (全パラメータ指定):"
    echo "[INFO] ${funcName}:   ${funcName} my-subscription my-topic my-project service-account@example.com https://test.com 86400s 600s 600s 10s"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Example (オプションはデフォルト値を利用):"
    echo "[INFO] ${funcName}:   ${funcName} my-subscription my-topic my-project service-account@example.com"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/pubsub/subscriptions/create"
    return 0
  fi

  # 必須パラメータが不足している場合はエラーを返す
  if [ "$#" -lt 4 ]; then
    echo "[ERROR] ${funcName}: Missing required parameters. Use --help for usage."
    return 1
  fi

  local subscription="$1"
  local topic="$2"
  local topic_project="$3"
  local service_account_email="$4"

  # オプションパラメータ（指定がなければデフォルト値を設定）
  local default_endpoint="https://${topic_project}.appspot.com/${subscription}"
  local push_endpoint="${5:-$default_endpoint}"
  local message_retention_duration="${6:-1d}"
  local expiration_period="${7:-never}"
  local max_retry_delay="${8:-600s}"
  local min_retry_delay="${9:-10s}"
  local ack_deadline="${10:-600}"

  echo "[INFO] ${funcName}: Creating subscription '${subscription}' for topic '${topic}' (project: '${topic_project}')..."
  echo "[INFO] ${funcName}: Using parameters:"
  echo "        MESSAGE_RETENTION_DURATION=${message_retention_duration}"
  echo "        SERVICE_ACCOUNT_EMAIL=${service_account_email}"
  echo "        PUSH_ENDPOINT=${push_endpoint}"
  echo "        EXPIRATION_PERIOD=${expiration_period}"
  echo "        MAX_RETRY_DELAY=${max_retry_delay}"
  echo "        MIN_RETRY_DELAY=${min_retry_delay}"
  echo "        ACK_DEADLINE=${ack_deadline}"

  echo ""
  echo "======= Cloud Pub/Sub on Google Cloud ======================================================================"
  gcloud pubsub subscriptions create "${subscription}" \
    --topic="${topic}" \
    --topic-project="${topic_project}" \
    --message-retention-duration="${message_retention_duration}" \
    --push-auth-service-account="${service_account_email}" \
    --push-endpoint="${push_endpoint}" \
    --expiration-period="${expiration_period}" \
    --max-retry-delay="${max_retry_delay}" \
    --min-retry-delay="${min_retry_delay}" \
    --ack-deadline="${ack_deadline}"
  echo "============================================================================================================"
  echo ""

  local ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "[ERROR] ${funcName}: Failed to create subscription '${subscription}'."
    return ${ret}
  fi

  echo "[INFO] ${funcName}: Subscription '${subscription}' created successfully."
}

function delete_cloud_pubsub_subscriptions_and_topics() {
  local funcName="${FUNCNAME[0]}"

  # --help オプションが指定された場合、利用方法を表示する
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: Usage:"
    echo "[INFO] ${funcName}:   ${funcName} -s <SUBSCRIPTION> [SUBSCRIPTION …] -t <TOPIC> [TOPIC …]"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}:   -s, --subscriptions : 削除対象のサブスクリプション名を1つ以上指定"
    echo "[INFO] ${funcName}:   -t, --topics        : 削除対象のトピック名を1つ以上指定"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Example:"
    echo "[INFO] ${funcName}:   ${funcName} -s sub1 sub2 -t topic1 topic2"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: ※ サブスクリプションのみ、またはトピックのみの削除も可能です。"
    return 0
  fi

  local subscriptions=()
  local topics=()

  # パラメータ解析
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -s|--subscriptions)
        shift
        while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
          subscriptions+=("$1")
          shift
        done
        ;;
      -t|--topics)
        shift
        while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
          topics+=("$1")
          shift
        done
        ;;
      *)
        echo "[ERROR] ${funcName}: Unknown parameter: $1"
        return 1
        ;;
    esac
  done

  if [ ${#subscriptions[@]} -eq 0 ] && [ ${#topics[@]} -eq 0 ]; then
    echo "[ERROR] ${funcName}: At least one subscription or topic must be specified. Use --help for usage."
    return 1
  fi

  # サブスクリプションの削除（指定があれば）
  echo ""
  echo "======= Cloud Pub/Sub on Google Cloud ======================================================================"
  if [ ${#subscriptions[@]} -gt 0 ]; then
    echo "[INFO] ${funcName}: Deleting subscriptions: ${subscriptions[*]}"
    delete_cloud_pubsub_subscriptions "${subscriptions[@]}"
    local ret=$?
    if [ ${ret} -ne 0 ]; then
      echo "[ERROR] ${funcName}: Failed to delete some subscriptions."
      return ${ret}
    fi
  fi
  echo "============================================================================================================"
  echo ""

  # トピックの削除（指定があれば）
  echo ""
  echo "======= Cloud Pub/Sub on Google Cloud ======================================================================"
  if [ ${#topics[@]} -gt 0 ]; then
    echo "[INFO] ${funcName}: Deleting topics: ${topics[*]}"
    delete_cloud_pubsub_topics "${topics[@]}"
    local ret=$?
    if [ ${ret} -ne 0 ]; then
      echo "[ERROR] ${funcName}: Failed to delete some topics."
      return ${ret}
    fi
  fi
  echo "============================================================================================================"
  echo ""

  echo "[INFO] ${funcName}: All specified subscriptions and topics deleted successfully."
}

function delete_cloud_pubsub_subscriptions() {
  local funcName="${FUNCNAME[0]}"

  # --help オプションが指定された場合、利用方法を表示する
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: Usage:"
    echo "[INFO] ${funcName}:   ${funcName} <SUBSCRIPTION> [SUBSCRIPTION …]"
    echo "[INFO] ${funcName}: Example:"
    echo "[INFO] ${funcName}:   ${funcName} sub1 sub2 sub3"
    echo "[INFO] ${funcName}:"
    echo "[INFO] ${funcName}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/pubsub/subscriptions/delete"
    return 0
  fi

  # パラメータが不足している場合はエラーを返す
  if [ "$#" -lt 1 ]; then
    echo "[ERROR] ${funcName}: Missing required parameter SUBSCRIPTION. Use --help for usage."
    return 1
  fi

  # 複数のサブスクリプションをループで削除する
  echo ""
  echo "======= Cloud Pub/Sub on Google Cloud ======================================================================"
  for subscription in "$@"; do
    echo "[INFO] ${funcName}: Deleting subscription '${subscription}'..."
    gcloud pubsub subscriptions delete "${subscription}"
    local ret=$?
    if [ ${ret} -ne 0 ]; then
      echo "[ERROR] ${funcName}: Failed to delete subscription '${subscription}'."
      return ${ret}
    fi
    echo "[INFO] ${funcName}: Subscription '${subscription}' deleted successfully."
  done
  echo "============================================================================================================"
  echo ""
}

function delete_cloud_pubsub_topics() {
  local funcName="${FUNCNAME[0]}"

  # --help オプションが指定された場合、利用方法を表示する
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${funcName}: Usage:"
    echo "[INFO] ${funcName}:   ${funcName} <TOPIC> [TOPIC …]"
    echo "[INFO] ${funcName}: Example:"
    echo "[INFO] ${funcName}:   ${funcName} topic1 topic2 topic3"
    return 0
  fi

  # パラメータが不足している場合はエラーを返す
  if [ "$#" -lt 1 ]; then
    echo "[ERROR] ${funcName}: Missing required parameter TOPIC. Use --help for usage."
    return 1
  fi

  # 複数のトピックをループで削除する
  echo ""
  echo "======= Cloud Pub/Sub on Google Cloud ======================================================================"
  for topic in "$@"; do
    echo "[INFO] ${funcName}: Deleting topic '${topic}'..."
    gcloud pubsub topics delete "${topic}"
    local ret=$?
    if [ ${ret} -ne 0 ]; then
      echo "[ERROR] ${funcName}: Failed to delete topic '${topic}'."
      return ${ret}
    fi
    echo "[INFO] ${funcName}: Topic '${topic}' deleted successfully."
  done
  echo "============================================================================================================"
  echo ""
}

function delete_cloud_run_function() {
  # ローカル変数に関数名を設定
  local FUNC_NAME="${FUNCNAME[0]}"

  # 必要なパラメータの初期化
  local service_name=""
  local region=""

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--name)
        service_name="$2"
        shift 2
        ;;
      -r|--region)
        region="$2"
        shift 2
        ;;
      --help)
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -s SERVICE_NAME -r REGION"
        echo "[INFO] ${FUNC_NAME}: Example: ${FUNC_NAME} -s my-service -r us-central1"
        echo "[INFO] ${FUNC_NAME}:"
        echo "[INFO] ${FUNC_NAME}: Notice: API reference URL: https://cloud.google.com/sdk/gcloud/reference/run/services/delete"
        return 0
        ;;
      *)
        echo "[ERROR] ${FUNC_NAME}: Unknown parameter: $1"
        echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -s SERVICE_NAME -r REGION"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [[ -z "$service_name" || -z "$region" ]]; then
    echo "[ERROR] ${FUNC_NAME}: Missing required parameter(s)."
    echo "[INFO] ${FUNC_NAME}: Usage: ${FUNC_NAME} -s SERVICE_NAME -r REGION"
    return 1
  fi

  # gcloud コマンドの実行
  echo "[INFO] ${FUNC_NAME}: Deleting service '${service_name}' in region '${region}'..."
  echo ""
  echo "======= Cloud Pub/Sub on Google Cloud ======================================================================"
  gcloud run services delete "$service_name" --region="$region"
  echo "============================================================================================================"
  echo ""

  local ret_code=$?
  if [ $ret_code -eq 0 ]; then
    echo "[INFO] ${FUNC_NAME}: Service '${service_name}' deleted successfully."
  else
    echo "[ERROR] ${FUNC_NAME}: Failed to delete service '${service_name}'."
    return $ret_code
  fi
}
