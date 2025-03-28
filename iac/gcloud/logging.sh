#!/bin/sh
function read_gcloud_logging() {
  local FUNCTION_NAME="${FUNCNAME[0]}"
  local severity=""
  local limit=10
  local query=""
  local resource_type=""
  local additional_args=""
  local filter=""

  # ヘルプメッセージの表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNCTION_NAME}: Google Cloud Loggingからログを取得する関数"
    echo ""
    echo "使用方法: ${FUNCTION_NAME} [オプション]"
    echo ""
    echo "オプション:"
    echo "  --severity SEVERITY       ログの重要度 (例: ERROR, WARNING)"
    echo "  --limit NUMBER            取得するログの最大数 (デフォルト: 10)"
    echo "  --query QUERY             追加のクエリフィルター"
    echo "  --resource-type TYPE      リソースタイプ (例: gce_instance, k8s_container)"
    echo "  --filter FILTER           完全なフィルター文字列を直接指定"
    echo "  --help                    このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${FUNCTION_NAME} --severity ERROR                       # エラーログを取得"
    echo "  ${FUNCTION_NAME} --resource-type gce_instance           # GCEインスタンスのログを取得"
    echo "  ${FUNCTION_NAME} --severity WARNING --limit 20          # 最大20件の警告ログを取得"
    echo "  ${FUNCTION_NAME} --query 'textPayload:\"Database\"'     # Databaseを含むログを取得"
    echo "  ${FUNCTION_NAME} --filter 'resource.type=gce_instance'  # フィルターを直接指定"
    echo "More detail: https://cloud.google.com/sdk/gcloud/reference/logging/read"
    return 0
  fi

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --severity)
        severity="$2"
        shift 2
        ;;
      --limit)
        if [[ ! "$2" =~ ^[0-9]+$ ]]; then
          echo "[ERROR] ${FUNCTION_NAME}: limit は数値で指定してください" >&2
          return 1
        fi
        limit="$2"
        shift 2
        ;;
      --query)
        query="$2"
        shift 2
        ;;
      --resource-type)
        resource_type="$2"
        shift 2
        ;;
      --filter)
        filter="$2"
        shift 2
        ;;
      *)
        additional_args="${additional_args} $1"
        shift
        ;;
    esac
  done

  # コマンドの構築
  local cmd="gcloud logging read \""

  # 完全なフィルターが指定されている場合はそれを使用
  if [[ -n "$filter" ]]; then
    cmd="${cmd}${filter}"
  else
    # 各フィルター要素を構築
    local filter_parts=()

    # 重要度が指定されている場合
    if [[ -n "$severity" ]]; then
      filter_parts+=("severity>=${severity}")
    fi

    # リソースタイプが指定されている場合
    if [[ -n "$resource_type" ]]; then
      filter_parts+=("resource.type=${resource_type}")
    fi

    # クエリが指定されている場合
    if [[ -n "$query" ]]; then
      filter_parts+=("${query}")
    fi

    # フィルター部分を組み立て
    local combined_filter=""
    for part in "${filter_parts[@]}"; do
      if [[ -n "$combined_filter" ]]; then
        combined_filter="${combined_filter} AND ${part}"
      else
        combined_filter="${part}"
      fi
    done

    cmd="${cmd}${combined_filter}"
  fi

  cmd="${cmd}\" --limit=${limit} ${additional_args}"

  echo "[INFO] ${FUNCTION_NAME}: 次のコマンドを実行します: ${cmd}"

  # 空のフィルターをチェック
  if [[ "${cmd}" == *"\"\""* ]]; then
    echo "[ERROR] ${FUNCTION_NAME}: フィルターが指定されていません。少なくとも1つのフィルター条件を指定してください" >&2
    return 1
  fi

  # gcloudコマンドの実行
  eval ${cmd}

  # エラーハンドリング
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${FUNCTION_NAME}: gcloud logging コマンドの実行に失敗しました" >&2
    return 1
  fi

  echo "[INFO] ${FUNCTION_NAME}: ログの取得が完了しました"
  return 0
}

function create_sink_of_gcloud_logging() {
  local FUNCTION_NAME="${FUNCNAME[0]}"
  local sink_name=""
  local destination=""
  local log_filter=""
  local additional_args=""

  # ヘルプメッセージの表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNCTION_NAME}: Google Cloud Loggingのシンクを作成する関数"
    echo ""
    echo "使用方法: ${FUNCTION_NAME} --sink-name NAME --destination DESTINATION [オプション]"
    echo ""
    echo "必須オプション:"
    echo "  --sink-name NAME          作成するシンク名"
    echo "  --destination DESTINATION シンクの送信先 (例: storage.googleapis.com/my-bucket)"
    echo ""
    echo "オプション:"
    echo "  --log-filter FILTER       ログフィルター (例: resource.type=gce_instance)"
    echo "  --help                    このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${FUNCTION_NAME} --sink-name my-sink --destination storage.googleapis.com/my-bucket"
    echo "  ${FUNCTION_NAME} --sink-name my-sink --destination storage.googleapis.com/my-bucket --log-filter=\"resource.type=gce_instance\""
    echo "  ${FUNCTION_NAME} --sink-name my-sink --destination pubsub.googleapis.com/projects/my-project/topics/my-topic"
    return 0
  fi

  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --sink-name)
        sink_name="$2"
        shift 2
        ;;
      --destination)
        destination="$2"
        shift 2
        ;;
      --log-filter)
        log_filter="$2"
        shift 2
        ;;
      *)
        additional_args="${additional_args} $1"
        shift
        ;;
    esac
  done

  # 必須パラメータのチェック
  if [[ -z "$sink_name" ]]; then
    echo "[ERROR] ${FUNCTION_NAME}: シンク名を指定してください (--sink-name)" >&2
    return 1
  fi

  if [[ -z "$destination" ]]; then
    echo "[ERROR] ${FUNCTION_NAME}: 送信先を指定してください (--destination)" >&2
    return 1
  fi

  # コマンドの構築
  local cmd="gcloud logging sinks create ${sink_name} ${destination}"

  # ログフィルターが指定されている場合は追加
  if [[ -n "$log_filter" ]]; then
    cmd="${cmd} --log-filter=\"${log_filter}\""
  fi

  # 追加の引数があれば追加
  if [[ -n "$additional_args" ]]; then
    cmd="${cmd} ${additional_args}"
  fi

  echo "[INFO] ${FUNCTION_NAME}: 次のコマンドを実行します: ${cmd}"

  # gcloudコマンドの実行
  eval ${cmd}

  # エラーハンドリング
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${FUNCTION_NAME}: gcloud logging sinks コマンドの実行に失敗しました" >&2
    return 1
  fi

  echo "[INFO] ${FUNCTION_NAME}: ログシンクの作成が完了しました"
  echo "[INFO] ${FUNCTION_NAME}: 作成したシンク: ${sink_name}"
  echo "[INFO] ${FUNCTION_NAME}: 宛先: ${destination}"

  return 0
}
