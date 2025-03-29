#!/bin/sh
function create_gcloud_scheduler_job_for_cloud_run_function() {
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "ジョブを作成するよ！"
  local USAGE="[INFO] Usage: ${FUNC_NAME} -j <JOB_NAME> -p <PROJECT_ID> [-l <LOCATION>] -t <PUBSUB_TOPIC> -d <DB_INSTANCE_ID> [-w <DISCORD_WEBHOOK_URL>] [-c <ICON_URL>] [-S <SCHEDULE>] [-D <DESCRIPTION>] [-z <TIME_ZONE>] [-m <MESSAGE_BODY>]

Options (short / long):
  -j, --job-name            The instance name used in job name (job name will be 'exec-cloud-run')
  -p, --project-id              The GCP project ID. This is used for the gcloud command and as the 'Project' in the message body.
  -l, --location                The location for the scheduler job. (default: \"us-central1\")
  -t, --pubsub-topic            The Pub/Sub topic to trigger.
  -w, --discord-webhook-url     Discord webhook URL (for message body). If not specified, the environment variable DISCORD_WEBHOOK_URL is used.
  -i, --icon-url      Cloud SQL icon URL (for message body). If not specified, the environment variable ICON_URL is used.
  -A, --action                  The action to perform. This is used in the message body as the 'Action' field. (default: \"start\")
  -S, --schedule                The cron schedule for the job. (default: \"0 4 * * 0-6\")
  -D, --description             The description for the job. (default: \"Trigger Cloud Functions to start Cloud SQL instance.\")
  -z, --time-zone               The time zone for the schedule. (default: \"Asia/Tokyo\")
  -m, --message-body            Request body for RESTful API.
  -h, --help                    Show this help message.

Example:
  # Full parameter example:
  \$ ${FUNC_NAME} \\
    --job-name exec-cloud-run \\
    --project-id My_PROJECT_ID \\
    --location MY_LOCATION \\
    --pubsub-topic MY_PUBSUB_TOPIC_ID \\
    --discord-webhook-url https://my.discord/webhook \\
    --icon-url https://my.icon/url \\
    --schedule \"0 4 * * 0-6\" \\
    --description \"Trigger Cloud Functions to start Cloud SQL instance.\" \\
    --time-zone \"Asia/Tokyo\"

  # If -w and -i are omitted, the values of the environment variables DISCORD_WEBHOOK_URL and ICON_URL are used.
  # Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/create/pubsub
"

  # GNU getopt を利用してオプション解析
  local OPTIONS
  OPTIONS=$(getopt -o j:p:l:t:w:i:S:D:z:m:h --long job-name:,project-id:,location:,pubsub-topic:,discord-webhook-url:,icon-url:,schedule:,description:,time-zone:,message-body:,help -n "$FUNC_NAME" -- "$@")
  if [ $? -ne 0 ]; then
    echo "[ERROR] $FUNC_NAME: Error parsing arguments." >&2
    echo "$USAGE" >&2
    return 1
  fi

  # 解析結果で位置パラメータを再設定
  eval set -- "$OPTIONS"

  # パラメータ初期化
  local job_name=""
  local project_id=""
  local LOCATION=""
  local PUBSUB_TOPIC=""
  local DB_INSTANCE_ID=""
  local SCHEDULE=""
  local DESCRIPTION=""
  local TIME_ZONE=""
  local MESSAGE_BODY=""
  local discord_webhook_url=""
  local ICON_URL=""
  # local discord_webhook_url="${discord_webhook_url:-}"
  # local ICON_URL="${ICON_URL:-}"

  while true; do
    echo "[DEBUG] $FUNC_NAME: 1st argument: $1"
    case "$1" in
      -j|--job-name)
        job_name="$2"
        shift 2
        ;;
      -p|--project-id)
        project_id="$2"
        shift 2
        ;;
      -l|--location)
        LOCATION="$2"
        shift 2
        ;;
      -t|--pubsub-topic)
        PUBSUB_TOPIC="$2"
        shift 2
        ;;
      -S|--schedule)
        SCHEDULE="$2"
        shift 2
        ;;
      -D|--description)
        DESCRIPTION="$2"
        shift 2
        ;;
      -z|--time-zone)
        TIME_ZONE="$2"
        shift 2
        ;;
      -w|--discord-webhook-url)
        discord_webhook_url="$2"
        shift 2
        ;;
      -i|--icon-url)
        ICON_URL="$2"
        shift 2
        ;;
      -m|--message-body)
        MESSAGE_BODY="$2"
        shift 2
        ;;
      -h|--help)
        echo "$USAGE"
        return 0
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "[ERROR] $FUNC_NAME: Invalid option: $1" >&2
        echo "$USAGE"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック（-w, -c は環境変数をデフォルトとするため必須ではない）
  if [ -z "$job_name" ] || [ -z "$project_id" ] || [ -z "$PUBSUB_TOPIC" ]; then
    echo "[ERROR] $FUNC_NAME: Missing required parameters." >&2
    echo "$USAGE"
    return 1
  fi

  # デフォルト値の設定
  if [ -z "$LOCATION" ]; then
    LOCATION="us-central1"
    echo "[INFO] $FUNC_NAME: --location not specified. Using default: ${LOCATION}"
  fi
  if [ -z "$SCHEDULE" ]; then
    SCHEDULE="0 4 * * 0-6"
    echo "[INFO] $FUNC_NAME: --schedule not specified. Using default: ${SCHEDULE}"
  fi
  if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="Trigger Cloud Functions to start Cloud SQL instance."
    echo "[INFO] $FUNC_NAME: --description not specified. Using default: ${DESCRIPTION}"
  fi
  if [ -z "$TIME_ZONE" ]; then
    TIME_ZONE="Asia/Tokyo"
    echo "[INFO] $FUNC_NAME: --time-zone not specified. Using default: ${TIME_ZONE}"
  fi
  if [ -z "$discord_webhook_url" ]; then
    discord_webhook_url="${DISCORD_WEBHOOK_URL:-}"
    echo "[INFO] $FUNC_NAME: --time-zone not specified. Using env variable."
  fi
  if [ -z "$ICON_URL" ]; then
    ICON_URL="${ICON_URL:-}"
    echo "[INFO] $FUNC_NAME: --time-zone not specified. Using env variable."
  fi

  # 1行にまとめる
  MESSAGE_BODY=$(echo "$MESSAGE_BODY" | tr -d '\n')

  echo "[INFO] $FUNC_NAME: Creating scheduler job '${job_name}'..."

  # gcloud コマンド実行
  if [ -n "$MESSAGE_BODY" ]; then
    gcloud scheduler jobs create pubsub "${job_name}" \
      --schedule="${SCHEDULE}" \
      --description="${DESCRIPTION}" \
      --project="${project_id}" \
      --location="${LOCATION}" \
      --time-zone="${TIME_ZONE}" \
      --topic="${PUBSUB_TOPIC}" \
      --message-body="${MESSAGE_BODY}"
  else
    gcloud scheduler jobs create pubsub "${job_name}" \
      --schedule="${SCHEDULE}" \
      --description="${DESCRIPTION}" \
      --project="${project_id}" \
      --location="${LOCATION}" \
      --time-zone="${TIME_ZONE}" \
      --topic="${PUBSUB_TOPIC}";
  fi

  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "ジョブを作成できなかったよ…" "red"
    echo "[ERROR] $FUNC_NAME: Scheduler job creation failed." >&2
    return 1
  fi

  send_discord_notification_about_gcscheduler "作成したよ！" "ジョブを作成したよ！" "green"
  echo "[INFO] $FUNC_NAME: Scheduler job '${job_name}' created successfully."
  return 0
}

function create_gcloud_scheduler_job_for_cloud_run_container() {
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "ジョブを作成するよ！"
  local USAGE="[INFO] Usage: ${FUNC_NAME} -j <JOB_NAME> -p <PROJECT_ID> [-l <LOCATION>] -H <HTTP_METHOD> -u <SERVICE_URL> [-w <DISCORD_WEBHOOK_URL>] [-c <ICON_URL>] [-a <OIDC_SERVICE_ACCOUNT_EMAIL>] [-S <SCHEDULE>] [-D <DESCRIPTION>] [-z <TIME_ZONE>] [-m <MESSAGE_BODY>]

Options (short / long):
  -j, --job-name                    The instance name used in job name (job name will be 'exec-cloud-run')
  -p, --project-id                  The GCP project ID. This is used for the gcloud command and as the 'Project' in the message body.
  -l, --location                    The location for the scheduler job. (default: \"us-central1\")
  -H, --http-method                 HTTP method with [ GET | POST | PUT | DELETE | HEAD ].
  -s, --service-url                 URL of service on Cloud Run resource.
  -a, --oidc-service-account-email  The service account email to be used for generating an OpenId Connect token to be included in the request sent to the target when executing the job. The service account must be within the same project as the job. The caller must have **iam.serviceAccounts.actAs** permission for the service account.
  -S, --schedule                    The cron schedule for the job. (default: \"0 4 * * 0-6\")
  -D, --description                 The description for the job. (default: \"Trigger Cloud Functions to start Cloud SQL instance.\")
  -z, --time-zone                   The time zone for the schedule. (default: \"Asia/Tokyo\")
  -w, --discord-webhook-url         Discord webhook URL (for message body). If not specified, the environment variable DISCORD_WEBHOOK_URL is used.
  -i, --icon-url           Cloud SQL icon URL (for message body). If not specified, the environment variable ICON_URL is used.
  -m, --message-body                Request body for RESTful API.
  -h, --help                        Show this help message.

Example:
  # Full parameter example:
  \$ ${FUNC_NAME} \\
    --job-name exec-cloud-run \\
    --project-id My_PROJECT_ID \\
    --location MY_LOCATION \\
    --http-method \"POST\" \\
    --service-url \"https://asia-example.12345.run.app\" \\
    --oidc-service-account-email \\
    --schedule \"0 4 * * 0-6\" \\
    --description \"Trigger Cloud Functions to start Cloud SQL instance.\" \\
    --time-zone \"Asia/Tokyo\"
    --discord-webhook-url https://my.discord/webhook \\
    --icon-url https://my.icon/url sample@example.gserviceaccount.com \\

  # If -w and -i are omitted, the values of the environment variables DISCORD_WEBHOOK_URL and ICON_URL are used.
  # Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/create/http
"

  # GNU getopt を利用してオプション解析
  local OPTIONS
  OPTIONS=$(getopt -o j:p:a:S:D:l:z:w:i:H:s:m:h --long job-name:,project-id:,location:,http-method:,service-url:,oidc-service-account-email:,schedule:,description:,time-zone:,discord-webhook-url:,icon-url:,message-body:,help -n "$FUNC_NAME" -- "$@")
  # OPTIONS=$(getopt -o j:p:a:S:D:l:z:w:i:H:s:m:h --long job-name:,project-id:,location:,http-method:,service-url:,oidc-service-account-email:,schedule:,description:,time-zone:,discord-webhook-url:,icon-url:,message-body:,help -n "$FUNC_NAME" -- "$@")
  if [ $? -ne 0 ]; then
    echo "[ERROR] $FUNC_NAME: Error parsing arguments." >&2
    echo "$USAGE" >&2
    return 1
  fi

  # 解析結果で位置パラメータを再設定
  eval set -- "$OPTIONS"

  # パラメータ初期化
  local JOB_NAME=""
  local PROJECT_ID=""
  local LOCATION=""
  local HTTP_METHOD=""
  local SERVICE_URL=""
  local OIDC_SERVICE_ACCOUNT_EMAIL=""
  local SCHEDULE=""
  local DESCRIPTION=""
  local TIME_ZONE=""
  local MESSAGE_BODY=""
  local discord_webhook_url=""
  local ICON_URL=""
  # local discord_webhook_url="${DISCORD_WEBHOOK_URL:-}"
  # local ICON_URL="${ICON_URL:-}"

  while true; do
    echo "[DEBUG] $FUNC_NAME: 1st argument: $1"
    case "$1" in
      -j|--job-name)
        JOB_NAME="$2"
        shift 2
        ;;
      -p|--project-id)
        PROJECT_ID="$2"
        shift 2
        ;;
      -l|--location)
        LOCATION="$2"
        shift 2
        ;;
      -H|--http-method)
        HTTP_METHOD="$2"
        shift 2
        ;;
      -s|--service-url)
        SERVICE_URL="$2"
        shift 2
        ;;
      -a|--oidc-service-account-email)
        OIDC_SERVICE_ACCOUNT_EMAIL="$2"
        shift 2
        ;;
      -S|--schedule)
        SCHEDULE="$2"
        shift 2
        ;;
      -D|--description)
        DESCRIPTION="$2"
        shift 2
        ;;
      -z|--time-zone)
        TIME_ZONE="$2"
        shift 2
        ;;
      -w|--discord-webhook-url)
        discord_webhook_url="$2"
        shift 2
        ;;
      -i|--icon-url)
        ICON_URL="$2"
        shift 2
        ;;
      -m|--message-body)
        MESSAGE_BODY="$2"
        shift 2
        ;;
      -h|--help)
        echo "$USAGE"
        return 0
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "[ERROR] $FUNC_NAME: Invalid option: $1" >&2
        echo "$USAGE"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック（-w, -c は環境変数をデフォルトとするため必須ではない）
  if [ -z "$JOB_NAME" ] || [ -z "$PROJECT_ID" ] || [ -z "$HTTP_METHOD" ] || [ -z "$SERVICE_URL" ]; then
    echo "[ERROR] $FUNC_NAME: Missing required parameters." >&2
    echo "$USAGE"
    return 1
  fi

  # デフォルト値の設定
  if [ -z "$LOCATION" ]; then
    LOCATION="us-central1"
    echo "[INFO] $FUNC_NAME: --location not specified. Using default: ${LOCATION}"
  fi
  if [ -z "$SCHEDULE" ]; then
    SCHEDULE="0 4 * * 0-6"
    echo "[INFO] $FUNC_NAME: --schedule not specified. Using default: ${SCHEDULE}"
  fi
  if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="Trigger Cloud Run Container."
    echo "[INFO] $FUNC_NAME: --description not specified. Using default: ${DESCRIPTION}"
  fi
  if [ -z "$TIME_ZONE" ]; then
    TIME_ZONE="Asia/Tokyo"
    echo "[INFO] $FUNC_NAME: --time-zone not specified. Using default: ${TIME_ZONE}"
  fi
  if [ -z "$discord_webhook_url" ]; then
    discord_webhook_url="${DISCORD_WEBHOOK_URL:-}"
    echo "[INFO] $FUNC_NAME: --time-zone not specified. Using env variable."
  fi
  if [ -z "$ICON_URL" ]; then
    ICON_URL="${ICON_URL:-}"
    echo "[INFO] $FUNC_NAME: --time-zone not specified. Using env variable."
  fi

  # 1行にまとめる
  MESSAGE_BODY=$(echo "$MESSAGE_BODY" | tr -d '\n')

  echo "[INFO] $FUNC_NAME: Creating scheduler job '${JOB_NAME}'..."

  # gcloud コマンド実行
  if [ -n "$MESSAGE_BODY" ]; then
    gcloud scheduler jobs create http "${JOB_NAME}" \
      --schedule="${SCHEDULE}" \
      --description="${DESCRIPTION}" \
      --project="${PROJECT_ID}" \
      --location="${LOCATION}" \
      --time-zone="${TIME_ZONE}" \
      --http-method="${HTTP_METHOD}" \
      --uri="${SERVICE_URL}" \
      --message-body="${MESSAGE_BODY}";
      # --uri="${SERVICE_URL}" \
      # --oidc-service-account-email="${OIDC_SERVICE_ACCOUNT_EMAIL}" \
      # --oidc-token-audience="${SERVICE_URL}" \
  else
    gcloud scheduler jobs create http "${JOB_NAME}" \
      --schedule="${SCHEDULE}" \
      --description="${DESCRIPTION}" \
      --project="${PROJECT_ID}" \
      --location="${LOCATION}" \
      --time-zone="${TIME_ZONE}" \
      --http-method="${HTTP_METHOD}" \
      --uri="${SERVICE_URL}" \
      # --oidc-service-account-email="${OIDC_SERVICE_ACCOUNT_EMAIL}" \
      # --oidc-token-audience="${SERVICE_URL}";
  fi

  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "ジョブを作成できなかったよ…" "red"
    echo "[ERROR] $FUNC_NAME: Scheduler job creation failed." >&2
    return 1
  fi

  send_discord_notification_about_gcscheduler "作成したよ！" "ジョブを作成したよ！" "green"
  echo "[INFO] $FUNC_NAME: Scheduler job '${JOB_NAME}' created successfully."
  return 0
}

function create_gcloud_scheduler_job_for_cloud_sql_instance() {
  local FUNC_NAME="${FUNCNAME[0]}"
  send_discord_notification "ジョブを作成するよ！"
  local USAGE="[INFO] Usage: \$${FUNC_NAME} -j <JOB_NAME> -p <PROJECT_ID> [-l <LOCATION>] -t <PUBSUB_TOPIC> -d <DB_INSTANCE_ID> [-w <DISCORD_WEBHOOK_URL>] [-c <ICON_URL>] [-A <ACTION>] [-S <SCHEDULE>] [-D <DESCRIPTION>] [-z <TIME_ZONE>]

Options (short / long):
  -j, --job-name            The instance name used in job name (job name will be 'start-my-db-instance')
  -p, --project-id              The GCP project ID. This is used for the gcloud command and as the 'Project' in the message body.
  -l, --location                The location for the scheduler job. (default: \"us-central1\")
  -t, --pubsub-topic            The Pub/Sub topic to trigger.
  -d, --db-instance-id          The Cloud SQL instance ID (for message body).
  -w, --discord-webhook-url     Discord webhook URL (for message body). If not specified, the environment variable DISCORD_WEBHOOK_URL is used.
  -i, --icon-url      Service icon URL (for message body). If not specified, the environment variable ICON_URL is used.
  -A, --action                  The action to perform. This is used in the message body as the 'Action' field. (default: \"start\")
  -S, --schedule                The cron schedule for the job. (default: \"0 4 * * 0-6\")
  -D, --description             The description for the job. (default: \"Trigger Cloud Functions to start Cloud SQL instance.\")
  -z, --time-zone               The time zone for the schedule. (default: \"Asia/Tokyo\")
  -h, --help                    Show this help message.

Example:
  # Full parameter example:
  \$ ${FUNC_NAME} \\
    --job-name my-db \\
    --project-id My_PROJECT_ID \\
    --location MY_LOCATION \\
    --pubsub-topic MY_PUBSUB_TOPIC_ID \\
    --db-instance-id MY_DB_INSTANCE_ID \\
    --discord-webhook-url https://my.discord/webhook \\
    --icon-url https://my.icon/url \\
    --action start \\
    --schedule \"0 4 * * 0-6\" \\
    --description \"Trigger Cloud Functions to start Cloud SQL instance.\" \\
    --time-zone \"Asia/Tokyo\"

  # If -w and -c are omitted, the values of the environment variables DISCORD_WEBHOOK_URL and ICON_URL are used.
"

  # GNU getopt を利用してオプション解析
  local OPTIONS
  OPTIONS=$(getopt -o j:p:l:t:d:w:c:A:S:D:z:h --long job-instance:,project-id:,location:,pubsub-topic:,db-instance-id:,discord-webhook-url:,cloud-sql-icon-url:,action:,schedule:,description:,time-zone:,help -n "$FUNC_NAME" -- "$@")
  if [ $? -ne 0 ]; then
    echo "[ERROR] $FUNC_NAME: Error parsing arguments." >&2
    echo "$USAGE" >&2
    return 1
  fi

  eval set -- "$OPTIONS"

  # パラメータ初期化
  local JOB_NAME="" PROJECT_ID="" LOCATION=""
  local PUBSUB_TOPIC="" DB_INSTANCE_ID=""
  local discord_webhook_url="${DISCORD_WEBHOOK_URL:-}"
  local ICON_URL="${ICON_URL:-}"
  local ACTION="" SCHEDULE="" DESCRIPTION="" TIME_ZONE=""

  while true; do
    case "$1" in
      -j|--job-name)
        JOB_NAME="$2"
        shift 2
        ;;
      -p|--project-id)
        PROJECT_ID="$2"
        shift 2
        ;;
      -l|--location)
        LOCATION="$2"
        shift 2
        ;;
      -t|--pubsub-topic)
        PUBSUB_TOPIC="$2"
        shift 2
        ;;
      -d|--db-instance-id)
        DB_INSTANCE_ID="$2"
        shift 2
        ;;
      -w|--discord-webhook-url)
        discord_webhook_url="$2"
        shift 2
        ;;
      -i|--icon-url)
        ICON_URL="$2"
        shift 2
        ;;
      -A|--action)
        ACTION="$2"
        shift 2
        ;;
      -S|--schedule)
        SCHEDULE="$2"
        shift 2
        ;;
      -D|--description)
        DESCRIPTION="$2"
        shift 2
        ;;
      -z|--time-zone)
        TIME_ZONE="$2"
        shift 2
        ;;
      -h|--help)
        echo "$USAGE"
        return 0
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "[ERROR] $FUNC_NAME: Invalid option: $1" >&2
        echo "$USAGE"
        return 1
        ;;
    esac
  done

  # 必須パラメータのチェック（-w, -c は環境変数をデフォルトとするため必須ではない）
  if [ -z "$JOB_NAME" ] || [ -z "$PROJECT_ID" ] || [ -z "$PUBSUB_TOPIC" ] || [ -z "$DB_INSTANCE_ID" ]; then
    echo "[ERROR] $FUNC_NAME: Missing required parameters." >&2
    echo "$USAGE"
    return 1
  fi

  # デフォルト値の設定
  if [ -z "$LOCATION" ]; then
    LOCATION="us-central1"
    echo "[INFO] $FUNC_NAME: --location not specified. Using default: ${LOCATION}"
  fi
  if [ -z "$SCHEDULE" ]; then
    SCHEDULE="0 4 * * 0-6"
    echo "[INFO] $FUNC_NAME: --schedule not specified. Using default: ${SCHEDULE}"
  fi
  if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="Trigger Cloud Functions to start Cloud SQL instance."
    echo "[INFO] $FUNC_NAME: --description not specified. Using default: ${DESCRIPTION}"
  fi
  if [ -z "$TIME_ZONE" ]; then
    TIME_ZONE="Asia/Tokyo"
    echo "[INFO] $FUNC_NAME: --time-zone not specified. Using default: ${TIME_ZONE}"
  fi
  if [ -z "$ACTION" ]; then
    ACTION="start"
    echo "[INFO] $FUNC_NAME: --action not specified. Using default: ${ACTION}"
  fi

  # message-body の JSON を作成
  local MESSAGE_BODY
  MESSAGE_BODY=$(cat <<EOF
{
  "Instance": "${DB_INSTANCE_ID}",
  "Project": "${PROJECT_ID}",
  "Action": "${ACTION}",
  "DiscordWebhookUrl": "${discord_webhook_url}",
  "CloudSqlIconUrl": "${ICON_URL}"
}
EOF
)
  # 1行にまとめる
  MESSAGE_BODY=$(echo "$MESSAGE_BODY" | tr -d '\n')

  create_gcloud_scheduler_job_for_cloud_run_function \
    -j "${JOB_NAME}" \
    -p "${PROJECT_ID}" \
    -S "${SCHEDULE}" \
    -D "${DESCRIPTION}" \
    -l "${LOCATION}" \
    -z "${TIME_ZONE}" \
    -t "${PUBSUB_TOPIC}" \
    -m "${MESSAGE_BODY}";

  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "ジョブを作成できなかったよ…" "red"
    echo "[ERROR] $FUNC_NAME: Scheduler job creation for Cloud SQL instance failed." >&2
    return 1
  fi

  send_discord_notification_about_gcscheduler "作成したよ！" "ジョブを作成したよ！" "green"
  echo "[INFO] $FUNC_NAME: Scheduler job '${JOB_NAME}' for Cloud SQL created successfully."
  return 0
}

function create_gcloud_scheduler_job_to_start_cloud_sql_instance() {
  local MY_DB_INSTANCE="$1"
  local MY_PROJECT_ID="$2"
  local MY_PUBSUB_TOPIC_ID="$3"
  local MY_DB_INSTANCE_ID="$4"
  local SCHEDULE="$5"

  if [ -z "$SCHEDULE" ]; then
    LOCATION="0 4 * * 0-6"
    echo "[INFO] $FUNC_NAME: argument for schedule not specified. Using default: ${SCHEDULE}"
  fi

  local JOB_INSTANCE="start-${MY_DB_INSTANCE}-instance"
  create_gcloud_scheduler_job_for_cloud_sql_instance -j "$JOB_INSTANCE" -p "$MY_PROJECT_ID" -t "$MY_PUBSUB_TOPIC_ID" -d "$MY_DB_INSTANCE_ID" -A "start" -S "$SCHEDULE"
}

function create_gcloud_scheduler_job_to_stop_cloud_sql_instance() {
  local MY_DB_INSTANCE="$1"
  local MY_PROJECT_ID="$2"
  local MY_PUBSUB_TOPIC_ID="$3"
  local MY_DB_INSTANCE_ID="$4"
  local SCHEDULE="$5"

  if [ -z "$SCHEDULE" ]; then
    LOCATION="0 7 * * 0-6"
    echo "[INFO] $FUNC_NAME: argument for schedule not specified. Using default: ${SCHEDULE}"
  fi

  local JOB_NAME="stop-${MY_DB_INSTANCE}-instance"
  create_gcloud_scheduler_job_for_cloud_sql_instance -j "$JOB_NAME" -p "$MY_PROJECT_ID" -t "$MY_PUBSUB_TOPIC_ID" -d "$MY_DB_INSTANCE_ID" -A "stop" -S "$SCHEDULE"
}

function list_gcloud_scheduler_jobs() {
  # 関数名をローカル変数に格納
  local func_name=${FUNCNAME[0]}
  send_discord_notification "ジョブを一覧表示するよ！"

  # 初期値
  local location=""
  local limit=""

  # パラメータ解析
  if [ $# -eq 0 ]; then
    echo "[INFO] ${func_name}: パラメータが指定されなかったため、デフォルト設定で実行します。"
  fi

  local usage="[INFO] Usage: ${func_name} --location <LOCATION> --limit <LIMIT>
  --location    gcloud scheduler のロケーションを指定します。
  --limit       結果の上限数を指定します。
[INFO] Example: ${func_name} --location us-central1 --limit 10
[INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/list
"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help)
        echo "$usage"
        return 0
        ;;
      --location)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --location の引数が指定されていません。"
          return 1
        fi
        location="$1"
        ;;
      --limit)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --limit の引数が指定されていません。"
          return 1
        fi
        limit="$1"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ '$1' です。"
        return 1
        ;;
    esac
    shift
  done

  # コマンド組み立て
  local cmd="gcloud scheduler jobs list"
  if [ -n "$location" ]; then
    cmd+=" --location=${location}"
  fi
  if [ -n "$limit" ]; then
    cmd+=" --limit=${limit}"
  fi

  echo "[INFO] ${func_name}: 実行するコマンド: ${cmd}"

  # コマンド実行とエラーハンドリング
  eval "${cmd}"
  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "ジョブを一覧表示できなかったよ…" "red"
    echo "[ERROR] ${func_name}: コマンド実行中にエラーが発生しました。"
    return 1
  fi
  send_discord_notification_about_gcscheduler "一覧表示したよ！" "ジョブを一覧表示したよ！" "green"
}

function update_gcloud_scheduler_job_http() {
  # 関数名をローカル変数に格納
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "HTTPジョブを更新するよ！"

  # 初期値
  local job_name=""
  local schedule=""
  local message_body=""

  # パラメータ解析
  if [ $# -eq 0 ]; then
    echo "[INFO] ${func_name}: パラメータが指定されなかったため、デフォルト設定で実行します。"
  fi

  local usage="[INFO] Usage: ${func_name} --job-name <JOB_NAME> --schedule <SCHEDULE> --message-body <MESSAGE_BODY>
  --job-name      更新対象のジョブ名を指定します。
  --schedule      更新するスケジュールの値を指定します。
  --message-body  更新するHTTPリクエストの本文を指定します。

[INFO] Example:
  ${func_name} --schedule '*/5 * * * *' --message-body '{\"key\":\"value\"}'
[INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/update/http
"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help)
        echo "$usage"
        return 0
        ;;
      --job-name)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --job-name の引数が指定されていません。"
          return 1
        fi
        job_name="$1"
        ;;
      --schedule)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --schedule の引数が指定されていません。"
          return 1
        fi
        schedule="$1"
        ;;
      --message-body)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --message-body の引数が指定されていません。"
          return 1
        fi
        message_body="$1"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ '$1' です。"
        return 1
        ;;
    esac
    shift
  done

  # 必須パラメータのチェック
  if [ -z "${job_name}" ]; then
    echo "[ERROR] ${func_name}: --job-name は必須パラメータです。"
    return 1
  fi

  # コマンド組み立て
  local cmd="gcloud scheduler jobs update http ${job_name}"
  if [ -n "$schedule" ]; then
    cmd+=" --schedule=${schedule}"
  fi
  if [ -n "$message_body" ]; then
    cmd+=" --message-body=${message_body}"
  fi

  echo "[INFO] ${func_name}: 実行するコマンド: ${cmd}"

  # コマンド実行とエラーハンドリング
  eval "${cmd}"
  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "HTTPジョブを更新できなかったよ…" "red"
    echo "[ERROR] ${func_name}: コマンド実行中にエラーが発生しました。"
    return 1
  fi
  send_discord_notification_about_gcscheduler "更新したよ！" "HTTPジョブを更新したよ！" "green"
  echo "[INFO] ${func_name}: Scheduler job '${job_name}' updated successfully."
}

function update_gcloud_scheduler_job_pubsub() {
  # 関数名をローカル変数に格納
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "PUB/SUBジョブを更新するよ！"

  # 初期値
  local job_name=""
  local schedule=""
  local message_body=""

  # パラメータ解析
  if [ $# -eq 0 ]; then
    echo "[INFO] ${func_name}: パラメータが指定されなかったため、デフォルト設定で実行します。"
  fi

  local usage="[INFO] Usage: ${func_name} --job-name <JOB_NAME> --schedule <SCHEDULE> --message-body <MESSAGE_BODY>
  --job-name      更新対象のジョブ名を指定します。
  --schedule      更新するスケジュールの値を指定します。
  --message-body  更新するPub/Subのメッセージ本文を指定します。

[INFO] Example:
  ${func_name} --job-name my-job --schedule '*/5 * * * *' --message-body '{\"key\":\"value\"}'
[INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/update/pubsub
"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help)
        echo "$usage"
        return 0
        ;;
      --job-name)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --job-name の引数が指定されていません。"
          return 1
        fi
        job_name="$1"
        ;;
      --schedule)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --schedule の引数が指定されていません。"
          return 1
        fi
        schedule="$1"
        ;;
      --message-body)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --message-body の引数が指定されていません。"
          return 1
        fi
        message_body="$1"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ '$1' です。"
        return 1
        ;;
    esac
    shift
  done

  # 必須パラメータのチェック
  if [ -z "${job_name}" ]; then
    echo "[ERROR] ${func_name}: --job-name は必須パラメータです。"
    return 1
  fi

  # コマンド組み立て（ジョブ名は必ず先頭に指定）
  local cmd="gcloud scheduler jobs update pubsub ${job_name}"
  if [ -n "${schedule}" ]; then
    cmd+=" --schedule=${schedule}"
  fi
  if [ -n "${message_body}" ]; then
    cmd+=" --message-body=${message_body}"
  fi

  echo "[INFO] ${func_name}: 実行するコマンド: ${cmd}"

  # コマンド実行とエラーハンドリング
  eval "${cmd}"
  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "PUB/SUBジョブを更新できなかったよ…" "red"
    echo "[ERROR] ${func_name}: コマンド実行中にエラーが発生しました。"
    return 1
  fi
  send_discord_notification_about_gcscheduler "更新したよ！" "PUB/SUBジョブを更新したよ！" "green"
  echo "[INFO] ${func_name}: Scheduler job '${job_name}' updated successfully."
}

function pause_gcloud_scheduler_job() {
  # 関数名をローカル変数に格納
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "ジョブを一時停止するよ！"

  # 初期値
  local job_name=""
  local location=""

  # パラメータ解析
  if [ $# -eq 0 ]; then
    echo "[INFO] ${func_name}: パラメータが指定されなかったため、デフォルト設定で実行します。"
  fi

  local usage="[INFO] Usage: ${func_name} --job-name <JOB_NAME> --location <LOCATION>
  --job-name      対象のジョブ名を指定します。
  --location      対象のロケーションを指定します。

[INFO] Example:
  ${func_name} --job-name my-job --location us-central1
[INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/pause
"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help)
        echo "$usage"
        return 0
        ;;
      --job-name)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --job-name の引数が指定されていません。"
          return 1
        fi
        job_name="$1"
        ;;
      --location)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --location の引数が指定されていません。"
          return 1
        fi
        location="$1"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ '$1' です。"
        return 1
        ;;
    esac
    shift
  done

  # 必須パラメータのチェック
  if [ -z "${job_name}" ]; then
    echo "[ERROR] ${func_name}: --job-name は必須パラメータです。"
    return 1
  fi
  if [ -z "${location}" ]; then
    echo "[ERROR] ${func_name}: --location は必須パラメータです。"
    return 1
  fi

  # コマンド組み立て
  local cmd="gcloud scheduler jobs pause ${job_name} --location=${location}"
  echo "[INFO] ${func_name}: 実行するコマンド: ${cmd}"

  # コマンド実行とエラーハンドリング
  eval "${cmd}"
  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "ジョブを一時停止できなかったよ…" "red"
    echo "[ERROR] ${func_name}: コマンド実行中にエラーが発生しました。"
    return 1
  fi
  send_discord_notification_about_gcscheduler "一時停止したよ！" "ジョブを一時停止したよ！" "green"
  echo "[INFO] ${func_name}: Scheduler job '${job_name}' paused successfully."
}

function resume_gcloud_scheduler_job() {
  # 関数名をローカル変数に格納
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "ジョブを再開するよ！"

  # 初期値
  local job_name=""
  local location=""

  # パラメータ解析
  if [ $# -eq 0 ]; then
    echo "[INFO] ${func_name}: パラメータが指定されなかったため、デフォルト設定で実行します。"
  fi

  local usage="[INFO] Usage: ${func_name} --job-name <JOB_NAME> --location <LOCATION>
  --job-name      対象のジョブ名を指定します。
  --location      対象のロケーションを指定します。

[INFO] Example:
  ${func_name} --job-name my-job --location us-central1
[INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/resume
"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help)
        echo "$usage"
        return 0
        ;;
      --job-name)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --job-name の引数が指定されていません。"
          return 1
        fi
        job_name="$1"
        ;;
      --location)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --location の引数が指定されていません。"
          return 1
        fi
        location="$1"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ '$1' です。"
        return 1
        ;;
    esac
    shift
  done

  # 必須パラメータのチェック
  if [ -z "${job_name}" ]; then
    echo "[ERROR] ${func_name}: --job-name は必須パラメータです。"
    return 1
  fi
  if [ -z "${location}" ]; then
    echo "[ERROR] ${func_name}: --location は必須パラメータです。"
    return 1
  fi

  # コマンド組み立て
  local cmd="gcloud scheduler jobs resume ${job_name} --location=${location}"
  echo "[INFO] ${func_name}: 実行するコマンド: ${cmd}"

  # コマンド実行とエラーハンドリング
  eval "${cmd}"
  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "ジョブを再開できなかったよ…" "red"
    echo "[ERROR] ${func_name}: コマンド実行中にエラーが発生しました。"
    return 1
  fi
  send_discord_notification_about_gcscheduler "再開したよ！" "ジョブを再開したよ！" "green"
  echo "[INFO] ${func_name}: Scheduler job '${job_name}' updated successfully."
}

function delete_gcloud_scheduler_job() {
  # 関数名をローカル変数に格納
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "ジョブを削除するよ！"

  # 初期値
  local job_name=""
  local location=""

  # パラメータ解析
  if [ $# -eq 0 ]; then
    echo "[INFO] ${func_name}: パラメータが指定されなかったため、デフォルト設定で実行します。"
  fi

  local usage="[INFO] Usage: ${func_name} --job-name <JOB_NAME> --location <LOCATION>
  --job-name      削除対象のジョブ名を指定します。
  --location      対象のロケーションを指定します。

[INFO] Example:
  ${func_name} --job-name my-job --location us-central1
[INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/delete
"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help)
        echo "$usage"
        return 0
        ;;
      --job-name)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --job-name の引数が指定されていません。"
          return 1
        fi
        job_name="$1"
        ;;
      --location)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --location の引数が指定されていません。"
          return 1
        fi
        location="$1"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ '$1' です。"
        return 1
        ;;
    esac
    shift
  done

  # 必須パラメータのチェック
  if [ -z "${job_name}" ]; then
    echo "[ERROR] ${func_name}: --job-name は必須パラメータです。"
    return 1
  fi
  if [ -z "${location}" ]; then
    echo "[ERROR] ${func_name}: --location は必須パラメータです。"
    return 1
  fi

  # コマンド組み立て
  local cmd="gcloud scheduler jobs delete ${job_name} --location=${location} --quiet"
  echo "[INFO] ${func_name}: 実行するコマンド: ${cmd}"

  # コマンド実行とエラーハンドリング
  eval "${cmd}"
  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "ジョブを削除できなかったよ…" "red"
    echo "[ERROR] ${func_name}: コマンド実行中にエラーが発生しました。"
    return 1
  fi
  send_discord_notification_about_gcscheduler "削除したよ！" "ジョブを削除したよ！" "green"
  echo "[INFO] ${func_name}: Scheduler job '${job_name}' deleted successfully."
}

function run_gcloud_scheduler_job() {
  # 関数名をローカル変数に格納
  local func_name="${FUNCNAME[0]}"
  send_discord_notification "ジョブを強制実行するよ！"

  # 初期値
  local job_name=""
  local location=""

  # パラメータ解析
  if [ $# -eq 0 ]; then
    echo "[INFO] ${func_name}: パラメータが指定されなかったため、デフォルト設定で実行します。"
  fi

  local usage="[INFO] Usage: ${func_name} --job-name <JOB_NAME> --location <LOCATION>
  --job-name      実行対象のジョブ名を指定します。
  --location      対象のロケーションを指定します。

[INFO] Example:
  ${func_name} --job-name my-job --location us-central1
[INFO] Detail of gcloud is here: https://cloud.google.com/sdk/gcloud/reference/scheduler/jobs/run
"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help)
        echo "$usage"
        return 0
        ;;
      --job-name)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --job-name の引数が指定されていません。"
          return 1
        fi
        job_name="$1"
        ;;
      --location)
        shift
        if [ -z "$1" ]; then
          echo "[ERROR] ${func_name}: --location の引数が指定されていません。"
          return 1
        fi
        location="$1"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ '$1' です。"
        return 1
        ;;
    esac
    shift
  done

  # 必須パラメータのチェック
  if [ -z "${job_name}" ]; then
    echo "[ERROR] ${func_name}: --job-name は必須パラメータです。"
    return 1
  fi
  if [ -z "${location}" ]; then
    echo "[ERROR] ${func_name}: --location は必須パラメータです。"
    return 1
  fi

  # コマンド組み立て
  local cmd="gcloud scheduler jobs run ${job_name} --location=${location}"
  echo "[INFO] ${func_name}: 実行するコマンド: ${cmd}"

  # コマンド実行とエラーハンドリング
  eval "${cmd}"
  if [ $? -ne 0 ]; then
    send_discord_notification_about_gcscheduler "失敗…" "ジョブを強制実行できなかったよ…" "red"
    echo "[ERROR] ${func_name}: コマンド実行中にエラーが発生しました。"
    return 1
  fi
  send_discord_notification_about_gcscheduler "強制実行したよ！" "ジョブを強制実行したよ！" "green"
  echo "[INFO] ${func_name}: Scheduler job '${job_name}' executed successfully."
}
