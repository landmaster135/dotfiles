#!/bin/sh

function list_dashboards_on_gcloud_monitoring() {
  local func_name="${FUNCNAME[0]}"
  local project=""
  local filter=""
  local format=""
  local page_size=""
  local sort_by=""
  local limit=""

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "使用方法: ${func_name} [オプション]"
    echo ""
    echo "オプション:"
    echo "  --project=PROJECT_ID    Google Cloud プロジェクトID"
    echo "  --filter=FILTER         結果をフィルタリングする式"
    echo "  --format=FORMAT         出力形式 (table, json, yaml, etc.)"
    echo "  --page-size=SIZE        1ページあたりの結果数"
    echo "  --sort-by=FIELD         指定したフィールドでソート"
    echo "  --limit=LIMIT           表示する結果の最大数"
    echo "  --help                  このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${func_name} --project=my-project"
    echo "  ${func_name} --format=json --limit=10"
    echo "  ${func_name} --filter=\"displayName:test\""
    echo "More detail: https://cloud.google.com/sdk/gcloud/reference/monitoring/dashboards/list"
    return 0
  fi

  # パラメータ解析
  for param in "$@"; do
    case $param in
      --project=*)
        project="${param#*=}"
        ;;
      --filter=*)
        filter="${param#*=}"
        ;;
      --format=*)
        format="${param#*=}"
        ;;
      --page-size=*)
        page_size="${param#*=}"
        ;;
      --sort-by=*)
        sort_by="${param#*=}"
        ;;
      --limit=*)
        limit="${param#*=}"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ: $param"
        echo "[INFO] ${func_name}: 使用方法を表示するには --help を使用してください"
        return 1
        ;;
    esac
  done

  # コマンド構築
  local cmd="gcloud monitoring dashboards list"

  # オプション追加
  if [[ -n "$project" ]]; then
    cmd="$cmd --project=$project"
  fi

  if [[ -n "$filter" ]]; then
    cmd="$cmd --filter=$filter"
  fi

  if [[ -n "$format" ]]; then
    # 引用符で囲んで特殊文字を保護
    cmd="$cmd --format='$format'"
  fi

  if [[ -n "$page_size" ]]; then
    cmd="$cmd --page-size=$page_size"
  fi

  if [[ -n "$sort_by" ]]; then
    cmd="$cmd --sort-by=$sort_by"
  fi

  if [[ -n "$limit" ]]; then
    cmd="$cmd --limit=$limit"
  fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行コマンド: $cmd"

  # コマンド実行
  if ! eval "$cmd"; then
    echo "[ERROR] ${func_name}: ダッシュボード一覧の取得に失敗しました"
    return 1
  fi

  echo "[INFO] ${func_name}: ダッシュボード一覧の取得が完了しました"
  return 0
}

function describe_dashboard_on_gcloud_monitoring() {
  local func_name="${FUNCNAME[0]}"
  local dashboard_id=""
  local project=""
  local format=""

  # ダッシュボードIDの必須チェック
  if [[ $# -eq 0 || "$1" == "--help" ]]; then
    echo "使用方法: ${func_name} DASHBOARD_ID [オプション]"
    echo ""
    echo "引数:"
    echo "  DASHBOARD_ID            ダッシュボードID (必須)"
    echo ""
    echo "オプション:"
    echo "  --project=PROJECT_ID    Google Cloud プロジェクトID"
    echo "  --format=FORMAT         出力形式 (json, yaml, etc.)"
    echo "  --help                  このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${func_name} my-dashboard"
    echo "  ${func_name} my-dashboard --project=my-project"
    echo "  ${func_name} my-dashboard --format=json"
    echo "More detail: https://cloud.google.com/sdk/gcloud/reference/monitoring/dashboards/describe"
    return 0
  fi

  # 第一引数をダッシュボードIDとして取得
  dashboard_id="$1"
  shift

  # パラメータ解析
  for param in "$@"; do
    case $param in
      --project=*)
        project="${param#*=}"
        ;;
      --format=*)
        format="${param#*=}"
        ;;
      --help)
        # ヘルプは最初のif文で処理済み
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ: $param"
        echo "[INFO] ${func_name}: 使用方法を表示するには --help を使用してください"
        return 1
        ;;
    esac
  done

  # コマンド構築
  local cmd="gcloud monitoring dashboards describe ${dashboard_id}"

  # オプション追加
  if [[ -n "$project" ]]; then
    cmd="$cmd --project=$project"
  fi

  if [[ -n "$format" ]]; then
  # 引用符で囲んで特殊文字を保護
    cmd="$cmd --format='$format'"
  fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行コマンド: $cmd"

  # コマンド実行
  if ! eval "$cmd"; then
    echo "[ERROR] ${func_name}: ダッシュボード '${dashboard_id}' の詳細取得に失敗しました"
    return 1
  fi

  echo "[INFO] ${func_name}: ダッシュボード '${dashboard_id}' の詳細取得が完了しました"
  return 0
}

function list_snoozes_on_gcloud_monitoring() {
  local func_name="${FUNCNAME[0]}"
  local project=""
  local filter=""
  local format=""
  local page_size=""
  local sort_by=""
  local limit=""
  local uri=""

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "使用方法: ${func_name} [オプション]"
    echo ""
    echo "オプション:"
    echo "  --project=PROJECT_ID    Google Cloud プロジェクトID"
    echo "  --filter=FILTER         結果をフィルタリングする式"
    echo "  --format=FORMAT         出力形式 (table, json, yaml, etc.)"
    echo "  --page-size=SIZE        1ページあたりの結果数"
    echo "  --sort-by=FIELD         指定したフィールドでソート"
    echo "  --limit=LIMIT           表示する結果の最大数"
    echo "  --uri                   リソースの URI を表示"
    echo "  --help                  このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${func_name} --project=my-project"
    echo "  ${func_name} --format=json --limit=10"
    echo "  ${func_name} --filter=\"displayName:maintenance\""
    echo "More detail: https://cloud.google.com/sdk/gcloud/reference/monitoring/snoozes/list"
    return 0
  fi

  # パラメータ解析
  for param in "$@"; do
    case $param in
      --project=*)
        project="${param#*=}"
        ;;
      --filter=*)
        filter="${param#*=}"
        ;;
      --format=*)
        format="${param#*=}"
        ;;
      --page-size=*)
        page_size="${param#*=}"
        ;;
      --sort-by=*)
        sort_by="${param#*=}"
        ;;
      --limit=*)
        limit="${param#*=}"
        ;;
      --uri)
        uri="true"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ: $param"
        echo "[INFO] ${func_name}: 使用方法を表示するには --help を使用してください"
        return 1
        ;;
    esac
  done

  # コマンド構築
  local cmd="gcloud monitoring snoozes list"

  # オプション追加
  if [[ -n "$project" ]]; then
    cmd="$cmd --project=$project"
  fi

  if [[ -n "$filter" ]]; then
    cmd="$cmd --filter=$filter"
  fi

  if [[ -n "$format" ]]; then
    # 引用符で囲んで特殊文字を保護
    cmd="$cmd --format='$format'"
  fi

  if [[ -n "$page_size" ]]; then
    cmd="$cmd --page-size=$page_size"
  fi

  if [[ -n "$sort_by" ]]; then
    cmd="$cmd --sort-by=$sort_by"
  fi

  if [[ -n "$limit" ]]; then
    cmd="$cmd --limit=$limit"
  fi

  if [[ -n "$uri" ]]; then
    cmd="$cmd --uri"
  fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行コマンド: $cmd"

  # コマンド実行
  if ! eval "$cmd"; then
    echo "[ERROR] ${func_name}: Snoozes 一覧の取得に失敗しました"
    return 1
  fi

  echo "[INFO] ${func_name}: Snoozes 一覧の取得が完了しました"
  return 0
}

function list_uptime_configs_on_gcloud_monitoring() {
  local func_name="${FUNCNAME[0]}"
  local project=""
  local filter=""
  local format=""
  local page_size=""
  local sort_by=""
  local limit=""
  local uri=""

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "使用方法: ${func_name} [オプション]"
    echo ""
    echo "オプション:"
    echo "  --project=PROJECT_ID    Google Cloud プロジェクトID"
    echo "  --filter=FILTER         結果をフィルタリングする式"
    echo "  --format=FORMAT         出力形式 (table, json, yaml, etc.)"
    echo "  --page-size=SIZE        1ページあたりの結果数"
    echo "  --sort-by=FIELD         指定したフィールドでソート"
    echo "  --limit=LIMIT           表示する結果の最大数"
    echo "  --uri                   リソースの URI を表示"
    echo "  --help                  このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${func_name} --project=my-project"
    echo "  ${func_name} --format=json --limit=10"
    echo "  ${func_name} --filter=\"displayName:api\""
    echo "More detail: https://cloud.google.com/sdk/gcloud/reference/monitoring/uptime/list-configs"
    return 0
  fi

  # パラメータ解析
  for param in "$@"; do
    case $param in
      --project=*)
        project="${param#*=}"
        ;;
      --filter=*)
        filter="${param#*=}"
        ;;
      --format=*)
        format="${param#*=}"
        ;;
      --page-size=*)
        page_size="${param#*=}"
        ;;
      --sort-by=*)
        sort_by="${param#*=}"
        ;;
      --limit=*)
        limit="${param#*=}"
        ;;
      --uri)
        uri="true"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ: $param"
        echo "[INFO] ${func_name}: 使用方法を表示するには --help を使用してください"
        return 1
        ;;
    esac
  done

  # コマンド構築
  local cmd="gcloud monitoring uptime list-configs"

  # オプション追加
  if [[ -n "$project" ]]; then
    cmd="$cmd --project=$project"
  fi

  if [[ -n "$filter" ]]; then
    cmd="$cmd --filter=$filter"
  fi

  if [[ -n "$format" ]]; then
    cmd="$cmd --format=$format"
  fi

  if [[ -n "$page_size" ]]; then
    cmd="$cmd --page-size=$page_size"
  fi

  if [[ -n "$sort_by" ]]; then
    cmd="$cmd --sort-by=$sort_by"
  fi

  if [[ -n "$limit" ]]; then
    cmd="$cmd --limit=$limit"
  fi

  if [[ -n "$uri" ]]; then
    cmd="$cmd --uri"
  fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行コマンド: $cmd"

  # コマンド実行
  if ! eval "$cmd"; then
    echo "[ERROR] ${func_name}: Uptime チェック設定の一覧取得に失敗しました"
    return 1
  fi

  echo "[INFO] ${func_name}: Uptime チェック設定の一覧取得が完了しました"
  return 0
}
