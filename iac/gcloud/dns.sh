#!/bin/sh
function list_dns_zones_on_gcloud() {
  local func_name="${FUNCNAME[0]}"
  local project=""
  local format=""  # デフォルト値を空に変更
  local filter=""
  local limit=""
  local page_size=""
  local sort_by=""
  local uri=""
  local verbosity=""  # verbosity も空に変更

  # ヘルプ表示
  if [[ "$1" == "--help" ]]; then
    echo "${func_name} - Google Cloud DNSのマネージドゾーン一覧を表示します"
    echo ""
    echo "使用方法:"
    echo "  ${func_name} [オプション]"
    echo ""
    echo "オプション:"
    echo "  --project=PROJECT_ID     対象のGCPプロジェクトID"
    echo "  --format=FORMAT          出力フォーマット (yaml, json, csv等)"
    echo "  --filter=FILTER          出力結果をフィルタリング"
    echo "  --limit=LIMIT            表示する結果の最大数"
    echo "  --page-size=PAGE_SIZE    1ページあたりの結果数"
    echo "  --sort-by=SORT_BY        結果のソート基準"
    echo "  --uri                    URI形式で出力"
    echo "  --verbosity=LEVEL        詳細レベル (debug, info, warning, error, critical, none)"
    echo "  --help                   このヘルプを表示"
    echo ""
    echo "使用例:"
    echo "  ${func_name}"
    echo "  ${func_name} --project=my-project"
    echo "  ${func_name} --format=json"
    return 0
  fi

  # パラメータの処理
  for param in "$@"; do
    case "$param" in
      --project=*)
        project="${param#*=}"
        ;;
      --format=*)
        format="${param#*=}"
        ;;
      --filter=*)
        filter="${param#*=}"
        ;;
      --limit=*)
        limit="${param#*=}"
        ;;
      --page-size=*)
        page_size="${param#*=}"
        ;;
      --sort-by=*)
        sort_by="${param#*=}"
        ;;
      --verbosity=*)
        verbosity="${param#*=}"
        ;;
      --uri)
        uri="--uri"
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ: $param"
        echo "ヘルプを表示するには ${func_name} --help を実行してください"
        return 1
        ;;
    esac
  done

  # コマンド構築
  local cmd="gcloud dns managed-zones list"

  if [[ -n "$project" ]]; then
    cmd="$cmd --project=$project"
  fi

  if [[ -n "$format" ]]; then
    # set double quotations
    cmd="$cmd --format='$format'"
  fi

  if [[ -n "$filter" ]]; then
    cmd="$cmd --filter=$filter"
  fi

  if [[ -n "$limit" ]]; then
    cmd="$cmd --limit=$limit"
  fi

  if [[ -n "$page_size" ]]; then
    cmd="$cmd --page-size=$page_size"
  fi

  if [[ -n "$sort_by" ]]; then
    cmd="$cmd --sort-by=$sort_by"
  fi

  if [[ -n "$verbosity" ]]; then
    cmd="$cmd --verbosity=$verbosity"
  fi

  if [[ -n "$uri" ]]; then
    cmd="$cmd $uri"
  fi

  # 実行するコマンドを表示
  echo "[INFO] ${func_name}: 実行コマンド: $cmd"

  # コマンド実行前のメッセージ
  echo "[INFO] ${func_name}: DNSマネージドゾーン一覧を取得中..."

  # コマンド実行
  eval $cmd
  local status=$?

  # エラーハンドリング
  if [[ $status -ne 0 ]]; then
    echo "[ERROR] ${func_name}: DNSマネージドゾーン一覧の取得に失敗しました (終了コード: $status)"
    return 1
  fi

  echo "[INFO] ${func_name}: DNSマネージドゾーンの一覧を正常に取得しました"
  return 0
}
