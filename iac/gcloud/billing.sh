#!/bin/sh
function list_billing_budgets() {
  local function_name=${FUNCNAME[0]}
  local limit=10
  local billing_id=""

  # ヘルプメッセージ表示
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "[INFO] ${function_name}: 利用方法"
    echo "  ${function_name} [--limit N]"
    echo ""
    echo "概要:"
    echo "  gcloud billing accounts listから請求アカウントIDを取得し、"
    echo "  gcloud billing budgets listコマンドを実行して予算情報を表示します。"
    echo ""
    echo "オプション:"
    echo "  --limit N    表示する予算の最大数を指定します（デフォルト: 10）"
    echo "  --help, -h   このヘルプメッセージを表示します"
    echo ""
    echo "使用例:"
    echo "  ${function_name}"
    echo "  ${function_name} --limit 5"
    return 0
  fi

  # 引数処理
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit)
        if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
          limit="$2"
          shift 2
        else
          echo "[ERROR] ${function_name}: --limitオプションには数値を指定してください" >&2
          return 1
        fi
        ;;
      *)
        echo "[ERROR] ${function_name}: 不明なオプション: $1" >&2
        echo "ヘルプを表示するには: ${function_name} --help" >&2
        return 1
        ;;
    esac
  done

  echo "[INFO] ${function_name}: 請求アカウントリストを取得しています..."

  # gcloudコマンドの存在確認
  if ! command -v gcloud &> /dev/null; then
    echo "[ERROR] ${function_name}: gcloudコマンドが見つかりません" >&2
    return 1
  fi

  # 請求アカウントリストの取得
  local accounts_output
  accounts_output=$(gcloud billing accounts list 2>&1)

  # gcloudコマンドのエラーチェック
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${function_name}: 請求アカウントの取得に失敗しました" >&2
    echo "[ERROR] ${function_name}: $accounts_output" >&2
    return 1
  fi

  # 出力が空かどうかをチェック
  if [[ -z "$accounts_output" || "$accounts_output" == "Listed 0 items." ]]; then
    echo "[ERROR] ${function_name}: 利用可能な請求アカウントが見つかりません" >&2
    return 1
  fi

  # my-idの抽出（最初に見つかった請求アカウントIDを使用）
  billing_id=$(echo "$accounts_output" | awk 'NR>1 {print $1; exit}')

  # billing_idが取得できたかチェック
  if [[ -z "$billing_id" ]]; then
    echo "[ERROR] ${function_name}: 請求アカウントIDを抽出できませんでした" >&2
    return 1
  fi

  echo "[INFO] ${function_name}: 請求アカウントID「${billing_id}」を使用します"
  echo "[INFO] ${function_name}: 予算リストを取得しています（最大${limit}件）..."

  # 予算リストの取得
  local budgets_output
  budgets_output=$(gcloud billing budgets list --billing-account "$billing_id" --limit "$limit" 2>&1)

  # gcloudコマンドのエラーチェック
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${function_name}: 予算リストの取得に失敗しました" >&2
    echo "[ERROR] ${function_name}: $budgets_output" >&2
    return 1
  fi

  # 出力表示
  if [[ -z "$budgets_output" || "$budgets_output" == "Listed 0 items." ]]; then
    echo "[INFO] ${function_name}: 予算情報が見つかりませんでした"
  else
    echo "$budgets_output"
  fi

  return 0
}

function list_billing_projects() {
  local function_name=${FUNCNAME[0]}
  local limit=10
  local billing_id=""
  local filter=""

  # ヘルプメッセージ表示
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "[INFO] ${function_name}: 利用方法"
    echo "  ${function_name} [--limit N] [--filter FILTER]"
    echo ""
    echo "概要:"
    echo "  gcloud billing accounts listから請求アカウントIDを取得し、"
    echo "  gcloud billing projects listコマンドを実行してプロジェクト情報を表示します。"
    echo ""
    echo "オプション:"
    echo "  --limit N        表示するプロジェクトの最大数を指定します（デフォルト: 10）"
    echo "  --filter FILTER  gcloudのフィルター式を指定します"
    echo "  --help, -h       このヘルプメッセージを表示します"
    echo ""
    echo "使用例:"
    echo "  ${function_name}"
    echo "  ${function_name} --limit 5"
    echo "  ${function_name} --filter \"project_id ~ ^test-\""
    return 0
  fi

  # 引数処理
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit)
        if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
          limit="$2"
          shift 2
        else
          echo "[ERROR] ${function_name}: --limitオプションには数値を指定してください" >&2
          return 1
        fi
        ;;
      --filter)
        if [[ -n "$2" ]]; then
          filter="$2"
          shift 2
        else
          echo "[ERROR] ${function_name}: --filterオプションには値を指定してください" >&2
          return 1
        fi
        ;;
      *)
        echo "[ERROR] ${function_name}: 不明なオプション: $1" >&2
        echo "ヘルプを表示するには: ${function_name} --help" >&2
        return 1
        ;;
    esac
  done

  echo "[INFO] ${function_name}: 請求アカウントリストを取得しています..."

  # gcloudコマンドの存在確認
  if ! command -v gcloud &> /dev/null; then
    echo "[ERROR] ${function_name}: gcloudコマンドが見つかりません" >&2
    return 1
  fi

  # 請求アカウントリストの取得
  local accounts_output
  accounts_output=$(gcloud billing accounts list 2>&1)

  # gcloudコマンドのエラーチェック
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${function_name}: 請求アカウントの取得に失敗しました" >&2
    echo "[ERROR] ${function_name}: $accounts_output" >&2
    return 1
  fi

  # 出力が空かどうかをチェック
  if [[ -z "$accounts_output" || "$accounts_output" == "Listed 0 items." ]]; then
    echo "[ERROR] ${function_name}: 利用可能な請求アカウントが見つかりません" >&2
    return 1
  fi

  # my-idの抽出（最初に見つかった請求アカウントIDを使用）
  billing_id=$(echo "$accounts_output" | awk 'NR>1 {print $1; exit}')

  # billing_idが取得できたかチェック
  if [[ -z "$billing_id" ]]; then
    echo "[ERROR] ${function_name}: 請求アカウントIDを抽出できませんでした" >&2
    return 1
  fi

  echo "[INFO] ${function_name}: 請求アカウントID「${billing_id}」を使用します"
  echo "[INFO] ${function_name}: プロジェクトリストを取得しています（最大${limit}件）..."

  # プロジェクトリストの取得
  local projects_output
  local command="gcloud billing projects list --billing-account \"$billing_id\" --limit \"$limit\""

  # フィルターが指定されている場合は追加
  if [[ -n "$filter" ]]; then
    command+=" --filter \"$filter\""
    echo "[INFO] ${function_name}: フィルター「${filter}」を適用します"
  fi

  # コマンド実行
  projects_output=$(eval "$command" 2>&1)

  # gcloudコマンドのエラーチェック
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${function_name}: プロジェクトリストの取得に失敗しました" >&2
    echo "[ERROR] ${function_name}: $projects_output" >&2
    return 1
  fi

  # 出力表示
  if [[ -z "$projects_output" || "$projects_output" == "Listed 0 items." ]]; then
    echo "[INFO] ${function_name}: プロジェクト情報が見つかりませんでした"
  else
    echo "$projects_output"
  fi

  return 0
}

# プロジェクトの詳細情報を表示する関数
function describe_billing_project() {
  local function_name=${FUNCNAME[0]}
  local project_id=""

  # ヘルプメッセージ表示
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "[INFO] ${function_name}: 利用方法"
    echo "  ${function_name} <PROJECT_ID>"
    echo ""
    echo "概要:"
    echo "  指定されたプロジェクトIDの請求情報の詳細を表示します。"
    echo "  プロジェクトIDが指定されない場合は、現在のgcloudプロジェクトを使用します。"
    echo ""
    echo "引数:"
    echo "  PROJECT_ID  詳細を表示するプロジェクトID（省略可）"
    echo ""
    echo "オプション:"
    echo "  --help, -h  このヘルプメッセージを表示します"
    echo ""
    echo "使用例:"
    echo "  ${function_name} my-project-123"
    echo "  ${function_name}  # 現在のプロジェクトを使用"
    return 0
  fi

  # 引数処理
  if [[ $# -gt 0 && "$1" != "--"* ]]; then
    project_id="$1"
  fi

  # gcloudコマンドの存在確認
  if ! command -v gcloud &> /dev/null; then
    echo "[ERROR] ${function_name}: gcloudコマンドが見つかりません" >&2
    return 1
  fi

  # プロジェクトIDが指定されていなければ現在のプロジェクトを使用
  if [[ -z "$project_id" ]]; then
    echo "[INFO] ${function_name}: プロジェクトIDが指定されていないため、現在のプロジェクトを使用します"

    project_id=$(gcloud config get-value project 2>/dev/null)

    if [[ -z "$project_id" || "$project_id" == "(unset)" ]]; then
      echo "[ERROR] ${function_name}: 現在のプロジェクトが設定されていません" >&2
      echo "[ERROR] ${function_name}: プロジェクトIDを引数として指定するか、gcloud config set projectでデフォルトプロジェクトを設定してください" >&2
      return 1
    fi
  fi

  echo "[INFO] ${function_name}: プロジェクト「${project_id}」の請求情報を取得しています..."

  # プロジェクト詳細の取得
  local project_output
  project_output=$(gcloud billing projects describe "$project_id" 2>&1)

  # gcloudコマンドのエラーチェック
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${function_name}: プロジェクト請求情報の取得に失敗しました" >&2
    echo "[ERROR] ${function_name}: $project_output" >&2
    return 1
  fi

  # 出力表示
  if [[ -z "$project_output" ]]; then
    echo "[INFO] ${function_name}: プロジェクト「${project_id}」の請求情報が見つかりませんでした"
  else
    echo "$project_output"
  fi

  return 0
}

# 予算の詳細情報を表示する関数
function describe_billing_budget() {
  local function_name=${FUNCNAME[0]}
  local billing_id=""
  local budget_id=""

  # ヘルプメッセージ表示
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "[INFO] ${function_name}: 利用方法"
    echo "  ${function_name} <BUDGET_ID> [--account BILLING_ACCOUNT_ID]"
    echo ""
    echo "概要:"
    echo "  指定された予算IDの詳細情報を表示します。"
    echo "  請求アカウントIDが指定されない場合は、最初に見つかった請求アカウントを使用します。"
    echo ""
    echo "引数:"
    echo "  BUDGET_ID  詳細を表示する予算ID"
    echo ""
    echo "オプション:"
    echo "  --account ID  使用する請求アカウントID"
    echo "  --help, -h    このヘルプメッセージを表示します"
    echo ""
    echo "使用例:"
    echo "  ${function_name} 00AA00-000000-000000"
    echo "  ${function_name} 00AA00-000000-000000 --account my-billing-account-id"
    return 0
  fi

  # 引数処理
  if [[ $# -lt 1 ]]; then
    echo "[ERROR] ${function_name}: 予算IDを指定してください" >&2
    echo "使用方法を表示するには: ${function_name} --help" >&2
    return 1
  fi

  # 最初の引数が--helpでなければ、それを予算IDとして扱う
  if [[ "$1" != "--help" && "$1" != "-h" ]]; then
    budget_id="$1"
    shift
  fi

  # 残りの引数を処理
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --account)
        if [[ -n "$2" ]]; then
          billing_id="$2"
          shift 2
        else
          echo "[ERROR] ${function_name}: --accountオプションには値を指定してください" >&2
          return 1
        fi
        ;;
      *)
        echo "[ERROR] ${function_name}: 不明なオプション: $1" >&2
        echo "ヘルプを表示するには: ${function_name} --help" >&2
        return 1
        ;;
    esac
  done

  # gcloudコマンドの存在確認
  if ! command -v gcloud &> /dev/null; then
    echo "[ERROR] ${function_name}: gcloudコマンドが見つかりません" >&2
    return 1
  fi

  # 請求アカウントIDが指定されていなければ取得
  if [[ -z "$billing_id" ]]; then
    echo "[INFO] ${function_name}: 請求アカウントリストを取得しています..."

    # 請求アカウントリストの取得
    local accounts_output
    accounts_output=$(gcloud billing accounts list 2>&1)

    # gcloudコマンドのエラーチェック
    if [[ $? -ne 0 ]]; then
      echo "[ERROR] ${function_name}: 請求アカウントの取得に失敗しました" >&2
      echo "[ERROR] ${function_name}: $accounts_output" >&2
      return 1
    fi

    # 出力が空かどうかをチェック
    if [[ -z "$accounts_output" || "$accounts_output" == "Listed 0 items." ]]; then
      echo "[ERROR] ${function_name}: 利用可能な請求アカウントが見つかりません" >&2
      return 1
    fi

    # my-idの抽出（最初に見つかった請求アカウントIDを使用）
    billing_id=$(echo "$accounts_output" | awk 'NR>1 {print $1; exit}')

    # billing_idが取得できたかチェック
    if [[ -z "$billing_id" ]]; then
      echo "[ERROR] ${function_name}: 請求アカウントIDを抽出できませんでした" >&2
      return 1
    fi

    echo "[INFO] ${function_name}: 請求アカウントID「${billing_id}」を使用します"
  fi

  echo "[INFO] ${function_name}: 予算ID「${budget_id}」の詳細情報を取得しています..."

  # 予算詳細の取得
  local budget_output
  budget_output=$(gcloud billing budgets describe "$budget_id" --billing-account "$billing_id" 2>&1)

  # gcloudコマンドのエラーチェック
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${function_name}: 予算情報の取得に失敗しました" >&2
    echo "[ERROR] ${function_name}: $budget_output" >&2
    return 1
  fi

  # 出力表示
  if [[ -z "$budget_output" ]]; then
    echo "[INFO] ${function_name}: 予算情報が見つかりませんでした"
  else
    echo "$budget_output"
  fi

  return 0
}
