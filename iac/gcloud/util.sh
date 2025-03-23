#!/bin/sh
function send_discord_notification() {
  local func_name=${FUNCNAME[0]}

  # --helpオプションの確認
  if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    cat <<EOF
[INFO] ${func_name}: Usage: ${FUNCNAME[0]} <通知テキスト> <Embedのテキスト> <Embedのフッターテキスト> <EmbedのアイコンのURL> <Embedの色> [DISCORD_WEBHOOK_URL]

Parameters:
  通知テキスト           : 通知内容のテキスト
  Embedのテキスト        : Embedメッセージの内容
  Embedのフッターテキスト : Embedフッターに表示するテキスト
  EmbedのアイコンのURL   : Embedフッターに表示するアイコンのURL
  Embedの色             : Embedの色（10進数の数値または以下の文字列指定が可能）
  DISCORD_WEBHOOK_URL    : (任意) DiscordのWebhook URL。省略した場合は環境変数DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUDを使用します。

Color Samples:
  green     : 4569935   (0x45BB4F)
  red       : 16711680  (0xFF0000)
  sky_blue  : 52479     (0x00CCFF)
  orange    : 14177041  (0xD85311)
  white     : 16777215  (0xFFFFFF)
  blue      : 39423     (0x0099FF)
  yellow    : 16770560  (0xFFE600)
  pink      : 16711833  (0xFF0099)
  purple    : 10494192  (0xA020F0)
  gray_blue : 9212588   (0x8C92AC)
  black     : 3355443   (0x333333)

Examples:
  # Using environment variable DISCORD_WEBHOOK_URL (5 arguments)
  ${FUNCNAME[0]} "通知テキスト" "Embedのテキスト" "Embedのフッターテキスト" "https://example.com/footer_icon.png" green

  # Explicitly specifying DISCORD_WEBHOOK_URL as the last argument (6 arguments)
  ${FUNCNAME[0]} "通知テキスト" "Embedのテキスト" "Embedのフッターテキスト" "https://example.com/footer_icon.png" red "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token"
EOF
    return 0
  fi

  local message embed_text embed_footer_text embed_icon_url embed_color webhook_url

  echo "[DEBUG] ${func_name}: parameters are following."
  echo "\$1: $1"
  echo "\$2: $2"
  echo "\$3: $3"
  echo "\$4: $4"
  echo "\$5: $5"
  echo "\$6: $6"

  # Embedなし
  # 引数の個数チェック
  if [ "$#" -eq 1 ]; then
    message="$1"
    webhook_url="${DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD}"
    # JSONペイロードの作成
    local payload=$(cat <<EOF
{
  "content": "$message"
}
EOF
    )
    echo "[DEBUG] ${func_name}: message and webhook are following."
    echo "\$message: $message"
    echo "\$webhook_url: $webhook_url"
    # curlでDiscordのWebhookにPOSTリクエストを送信
    curl -H "Content-Type: application/json" \
      -X POST \
      -d "$payload" \
      "$webhook_url"
    return 0
  fi

  # Embedあり
  # 引数の個数チェック
  if [ "$#" -eq 5 ]; then
    message="$1"
    embed_text="$2"
    embed_footer_text="$3"
    embed_icon_url="$4"
    embed_color="$5"
    webhook_url="${DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD}"
  elif [ "$#" -eq 6 ]; then
    message="$1"
    embed_text="$2"
    embed_footer_text="$3"
    embed_icon_url="$4"
    embed_color="$5"
    webhook_url="$6"
  else
    echo "[ERROR] ${func_name}: 引数の数が正しくありません。"
    cat <<EOF
Usage: ${FUNCNAME[0]} <通知テキスト> <Embedのテキスト> <Embedのフッターテキスト> <EmbedのアイコンのURL> <Embedの色> [DISCORD_WEBHOOK_URL];
EOF
    return 1
  fi

  echo "[DEBUG] ${func_name}: translated parameters are following."
  echo "\$message: $message"
  echo "\$embed_text: $embed_text"
  echo "\$embed_footer_text: $embed_footer_text"
  echo "\$embed_icon_url: $embed_icon_url"
  echo "\$embed_color: $embed_color"
  echo "\$webhook_url: $webhook_url"

  # いずれかの引数が空文字だった場合のエラーハンドリング
  if [ -z "$message" ] || [ -z "$embed_text" ] || [ -z "$embed_footer_text" ] || [ -z "$embed_icon_url" ] || [ -z "$embed_color" ] || [ -z "$webhook_url" ]; then
    if [ -z "$message" ]; then
      echo "[ERROR] ${func_name}: 通知テキストが空文字です。"
    fi
    if [ -z "$embed_text" ]; then
      echo "[ERROR] ${func_name}: Embedのテキストが空文字です。"
    fi
    if [ -z "$embed_footer_text" ]; then
      echo "[ERROR] ${func_name}: Embedのフッターテキストが空文字です。"
    fi
    if [ -z "$embed_icon_url" ]; then
      echo "[ERROR] ${func_name}: EmbedのアイコンのURLが空文字です。"
    fi
    if [ -z "$embed_color" ]; then
      echo "[ERROR] ${func_name}: Embedの色が空文字です。"
    fi
    if [ -z "$webhook_url" ]; then
      echo "[ERROR] ${func_name}: DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUDが空文字です。"
    fi
    cat <<EOF
Usage: ${FUNCNAME[0]} <通知テキスト> <Embedのテキスト> <Embedのフッターテキスト> <EmbedのアイコンのURL> <Embedの色> [DISCORD_WEBHOOK_URL];
EOF
    return 1
  fi

  # Embedの色が文字列の場合、対応する10進数の値に変換
  case "$embed_color" in
    green)
      embed_color=4569935
      ;;
    red)
      embed_color=16711680
      ;;
    sky_blue)
      embed_color=52479
      ;;
    orange)
      embed_color=14177041
      ;;
    white)
      embed_color=16777215
      ;;
    blue)
      embed_color=39423
      ;;
    yellow)
      embed_color=16770560
      ;;
    pink)
      embed_color=16711833
      ;;
    purple)
      embed_color=10494192
      ;;
    gray_blue)
      embed_color=9212588
      ;;
    black)
      embed_color=3355443
      ;;
    *)
      # 数値が直接入力されているものとみなす
      ;;
  esac

  # JSONペイロードの作成
  local payload=$(cat <<EOF
{
  "content": "$message",
  "embeds": [
    {
      "description": "$embed_text",
      "color": $embed_color,
      "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "footer": {
          "text": "$embed_footer_text",
          "icon_url": "$embed_icon_url"
      }
    }
  ]
}
EOF
  )

  # curlでDiscordのWebhookにPOSTリクエストを送信
  curl -H "Content-Type: application/json" \
    -X POST \
    -d "$payload" \
    "$webhook_url"
}

function send_discord_notification_about_gce() {
  # 第一引数以降のパラメータは send_discord_notification と同じ順序
  local message="$1"
  local embed_text="$2"
  local embed_color="$3"
  local embed_footer_text="GoogleComputeEngine"
  local embed_icon_url=$GCE_ICON_URL
  local webhook_url=$DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD

  # webhook_url が空でないかチェックし、あれば最後の引数として渡す
  if [ -n "$webhook_url" ]; then
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color" "$webhook_url"
  else
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color"
  fi
}

function send_discord_notification_about_gsm() {
  # 第一引数以降のパラメータは send_discord_notification と同じ順序
  local message="$1"
  local embed_text="$2"
  local embed_color="$3"
  local embed_footer_text="GoogleSecretManager"
  local embed_icon_url=$GSM_ICON_URL
  local webhook_url=$DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD

  # webhook_url が空でないかチェックし、あれば最後の引数として渡す
  if [ -n "$webhook_url" ]; then
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color" "$webhook_url"
  else
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color"
  fi
}

function send_discord_notification_about_gcs() {
  # 第一引数以降のパラメータは send_discord_notification と同じ順序
  local message="$1"
  local embed_text="$2"
  local embed_color="$3"
  local embed_footer_text="GoogleCloudStorage"
  local embed_icon_url=$GCS_ICON_URL
  local webhook_url=$DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD

  # webhook_url が空でないかチェックし、あれば最後の引数として渡す
  if [ -n "$webhook_url" ]; then
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color" "$webhook_url"
  else
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color"
  fi
}

function send_discord_notification_about_gcscheduler() {
  # 第一引数以降のパラメータは send_discord_notification と同じ順序
  local func_name=${FUNCNAME[0]}
  local message="$1"
  local embed_text="$2"
  local embed_color="$3"
  local embed_footer_text="GoogleCloudScheduler"
  local embed_icon_url=$GCSCHEDULER_ICON_URL
  local webhook_url=$DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD

  echo "[DEBUG] ${func_name}: parameters are following."
  echo "\$message: $message"
  echo "\$embed_text: $embed_text"
  echo "\$embed_color: $embed_color"
  echo "\$embed_footer_text: $embed_footer_text"
  echo "\$embed_icon_url: $embed_icon_url"
  echo "\$webhook_url: $webhook_url"

  # webhook_url が空でないかチェックし、あれば最後の引数として渡す
  if [ -n "$webhook_url" ]; then
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color" "$webhook_url"
  else
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color"
  fi
}

function send_discord_notification_about_gciam() {
  # 第一引数以降のパラメータは send_discord_notification と同じ順序
  local func_name=${FUNCNAME[0]}
  local message="$1"
  local embed_text="$2"
  local embed_color="$3"
  local embed_footer_text="GoogleCloudIAM"
  local embed_icon_url=$GCIAM_ICON_URL
  local webhook_url=$DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD

  echo "[DEBUG] ${func_name}: parameters are following."
  echo "\$message: $message"
  echo "\$embed_text: $embed_text"
  echo "\$embed_color: $embed_color"
  echo "\$embed_footer_text: $embed_footer_text"
  echo "\$embed_icon_url: $embed_icon_url"
  echo "\$webhook_url: $webhook_url"

  # webhook_url が空でないかチェックし、あれば最後の引数として渡す
  if [ -n "$webhook_url" ]; then
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color" "$webhook_url"
  else
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color"
  fi
}

function send_discord_notification_about_gcloud_run() {
  # 第一引数以降のパラメータは send_discord_notification と同じ順序
  local message="$1"
  local embed_text="$2"
  local embed_color="$3"
  local embed_footer_text="GoogleCloudRun"
  local embed_icon_url=$GCLOUD_RUN_ICON_URL
  local webhook_url=$DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD

  # webhook_url が空でないかチェックし、あれば最後の引数として渡す
  if [ -n "$webhook_url" ]; then
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color" "$webhook_url"
  else
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color"
  fi
}

function send_discord_notification_about_gcloud_run_function() {
  # 第一引数以降のパラメータは send_discord_notification と同じ順序
  local message="$1"
  local embed_text="$2"
  local embed_color="$3"
  local embed_footer_text="GoogleCloudRunFunction"
  local embed_icon_url=$GCLOUD_RUN_FUNCTION_ICON_URL
  local webhook_url=$DISCORD_WEBHOOK_URL_FOR_IAC_ON_GCLOUD

  # webhook_url が空でないかチェックし、あれば最後の引数として渡す
  if [ -n "$webhook_url" ]; then
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color" "$webhook_url"
  else
    send_discord_notification "$message" "$embed_text" "$embed_footer_text" "$embed_icon_url" "$embed_color"
  fi
}
