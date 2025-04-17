#!/bin/bash

#==============================================================#
##         New Commands                                      ##
#==============================================================#
function getpids() {
  echo `ps x | grep $1 | awk '{print $1}'`
}

function du-ah() {
  # e.g. du-ah / 20
  du -ah $1 | sort -rh | head -n $2
}

function count_lines_in_dir() {
  local FUNC_NAME="${FUNCNAME[0]}"
  local DIR=""

  # ヘルプメッセージの表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNC_NAME}: 指定されたディレクトリ内のすべてのファイルの行数を合計して表示します"
    echo "使用法: ${FUNC_NAME} [ディレクトリパス]"
    echo "例: ${FUNC_NAME} /path/to/directory"
    echo "パラメータが指定されない場合は、カレントディレクトリが使用されます"
    return 0
  fi

  # パラメータの処理
  if [[ $# -eq 0 ]]; then
    DIR="$(pwd)"
    echo "[INFO] ${FUNC_NAME}: パラメータが指定されていないため、カレントディレクトリを使用します: ${DIR}"
  else
    DIR="$1"
  fi

  # ディレクトリの存在確認
  if [[ ! -d "${DIR}" ]]; then
    echo "[ERROR] ${FUNC_NAME}: 指定されたディレクトリが存在しません: ${DIR}"
    return 1
  fi

  # 実行コマンドの表示と行数の合計計算
  echo "[INFO] ${FUNC_NAME}: 実行コマンド: find \"${DIR}\" -type f -exec wc -l {} \; | awk '{sum += \$1} END {print sum}'"

  local TOTAL_LINES=$(find "${DIR}" -type f -exec wc -l {} \; | awk '{sum += $1} END {print sum}')

  # 結果の表示
  if [[ $? -eq 0 ]]; then
    echo "[INFO] ${FUNC_NAME}: ディレクトリ ${DIR} 内のファイルの合計行数: ${TOTAL_LINES}"
    return 0
  else
    echo "[ERROR] ${FUNC_NAME}: 行数のカウント中にエラーが発生しました"
    return 1
  fi
}

#==============================================================#
##          Git Functions                                     ##
#==============================================================#

function git-erase() {
  # e.g. git-erase credential.json
  git filter-branch --force --index-filter "git rm --cached --ignore-unmatch $1" -- --all
}

function git-repat() {
  local pat="$1"
  local current_url=$(git remote -v | awk '/origin/ {print $2; exit}')
  if [[ "$current_url" =~ github\.com[:/]([^/]+)/([^/]+)$ ]]; then
    local username="${BASH_REMATCH[1]}"
    local repository="${BASH_REMATCH[2]}"
  else
    echo "URL extraction failed"
  fi
  local new_url="https://$username:$pat@github.com/$username/$repository"
  git remote set-url origin $new_url
}

function git-chup-main() {
  # 'git-chup-main' means 'git checkout and update local main branch'
  # e.g. git-chup
  git checkout main
  git pull origin main
}

function git-nb() {
  # 'git-nb' means 'git-new-branch'
  # e.g. git-nb initialCommit
  local branch_name="$1"
  git branch $branch_name
  git checkout $branch_name
}

function git-publish() {
  local BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
  git push HEAD "$BRANCH_NAME"
  git push --set-upstream origin "$BRANCH_NAME"
}

function docker-cp() {
  local container_id=$1
  local executing_file_path=$2
  docker cp $container_id:$executing_file_path .
}

function docker-build() {
  local tag=$2
  local path=$1
  docker build -t $2 $1
}

function configure_git_user() {
  local func_name="${FUNCNAME[0]}"
  local email="${GITHUB_ACCOUNT_EMAIL:-}"
  local name="${GITHUB_ACCOUNT_NAME:-}"
  local show_help=false

  # パラメータの解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --email=*)
        email="${1#*=}"
        shift
        ;;
      --name=*)
        name="${1#*=}"
        shift
        ;;
      --help)
        show_help=true
        shift
        ;;
      *)
        echo "[ERROR] $func_name: 不明なパラメータ: $1"
        return 1
        ;;
    esac
  done

  # ヘルプ表示
  if [[ "$show_help" = true ]]; then
    echo "使用方法: $func_name --email=メールアドレス --name=ユーザー名"
    echo ""
    echo "オプション:"
    echo "  --email=EMAIL    Gitに設定するメールアドレス (デフォルト: 環境変数 GITHUB_ACCOUNT_EMAIL)"
    echo "  --name=NAME      Gitに設定するユーザー名 (デフォルト: 環境変数 GITHUB_ACCOUNT_NAME)"
    echo "  --help           このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  $func_name --email=user@example.com --name=\"John Doe\""
    return 0
  fi

  # パラメータ検証
  if [[ -z "$email" ]]; then
    echo "[ERROR] $func_name: メールアドレスが指定されていません。--email=パラメータか環境変数GITHUB_ACCOUNT_EMAILを設定してください。"
    return 1
  fi

  if [[ -z "$name" ]]; then
    echo "[ERROR] $func_name: ユーザー名が指定されていません。--name=パラメータか環境変数GITHUB_ACCOUNT_NAMEを設定してください。"
    return 1
  fi

  # .gitディレクトリの存在を確認
  if [[ ! -d ".git" ]]; then
    echo "[ERROR] $func_name: カレントディレクトリにGitリポジトリが見つかりません。"
    return 1
  fi

  # コマンド実行
  echo "[INFO] $func_name: 実行コマンド: git config --local user.email \"$email\""
  if ! git config --local user.email "$email"; then
    echo "[ERROR] $func_name: メールアドレスの設定に失敗しました。"
    return 1
  fi

  echo "[INFO] $func_name: 実行コマンド: git config --local user.name \"$name\""
  if ! git config --local user.name "$name"; then
    echo "[ERROR] $func_name: ユーザー名の設定に失敗しました。"
    return 1
  fi

  echo "[INFO] $func_name: Gitユーザー設定が完了しました。(email: $email, name: $name)"
  return 0
}

#==============================================================#
##          Common Functions                                  ##
#==============================================================#

function cron_help() {
  # 'cron_help' shows how to describe cron.
  cat << 'EOF'
cronの書き方:

形式:
  * * * * * command
  | | | | |
  | | | | ----- 曜日 (0-7, 0または7は日曜日)
  | | | ------- 月 (1-12)
  | | --------- 日 (1-31)
  | ----------- 時間 (0-23)
  ------------- 分 (0-59)

例:
1. 毎日午前5時に実行:
   0 5 * * * command

2. 毎時15分ごとに実行:
   */15 * * * * command

3. 毎週月曜日の午後2時に実行:
   0 14 * * 1 command

※ 各フィールドで「*」は任意の値を意味します。
EOF
}

function change_carriage_return() {
  # 'change_carriage_return' changes the line feed code to the carriage return code.
  # e.g. change_carriage_return dir_1
  find $1 -type f -exec dos2unix {} \;
}

function list_available_commands() {
  echo "==== 利用可能なコマンド一覧 ===="
  echo "システムパスにあるコマンド:"
  compgen -c | sort | uniq

  echo ""
  echo "ビルトイン Bash コマンド:"
  compgen -b | sort | uniq

  echo ""
  echo "エイリアス:"
  alias | sed 's/alias \([^=]*\)=.*/\1/'

  echo ""
  echo "キーワード:"
  compgen -k | sort | uniq

  echo ""
  echo "関数:"
  compgen -A function | sort | uniq
}

#==============================================================#
##          Configuration Functions                           ##
#==============================================================#
function _append_history_line() {
  _date="[$(date '+%Y-%m-%d %H:%M:%S %Z')]"
  _width=$(tput cols)

  printf "%$(( $_width - ${#_date} - 1 ))s" | tr ' ' '-'
  echo " $_date"
}

function _current_branch() {
  _git_branch=$(git branch --show-current 2>/dev/null) && echo "[branch: $_git_branch] "
}

function edit-ps1-env() {
  case ${1} in
    --activate | -a)
      echo 'Activate venv now......'
      export _OLD_VIRTUAL_PS1="$MY_PS1"
      _my_venv_dir='.venv'
      PS1=${MY_PS1/'$(_append_history_line)'/'$(_append_history_line)'"\[\033[01;31m\]($_my_venv_dir)\[\033[00m\] "}
      return 0
      ;;
    --deactivate | -d)
      # nothing to do
      echo 'Deactivate venv now......'
      return 0
      ;;
    *)
      echo "[ERROR] invalid options: '${1}'"
      return 1
      ;;
  esac
}

#==============================================================#
##          Functions for each language                       ##
#==============================================================#
# 引数からテキストファイルのパスを受け取り、テスト結果を分析する関数
function analyze_pytest_results() {
  local allowed_failures_file="$1"

  # ファイルが存在するか確認
  if [ ! -f "$allowed_failures_file" ]; then
    echo "エラー: 指定されたファイル '$allowed_failures_file' が見つかりません。"
    return 1
  fi

  # ファイルから許容される失敗テストのリストを読み込む
  # コメント行と空行を除外
  allowed_failures=()
  while IFS= read -r line; do
    # 空行やコメント行をスキップ
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi
    # 行の前後の空白を削除
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    allowed_failures+=("$line")
  done < "$allowed_failures_file"

  # 許容される失敗テストのリストが空かどうかチェック
  if [ ${#allowed_failures[@]} -eq 0 ]; then
    echo "警告: 許容される失敗テストのリストが空です。"
  fi

  # python -m pytest -v を実行してすべての結果を取得
  echo "テストを実行中..."
  pytest_output=$(python -m pytest -v)

  # すべての失敗テストを抽出
  all_failures=()
  while IFS= read -r line; do
    # FAILEDの後に空白があり、その後に::を含むテスト名があるパターンにマッチ
    if [[ "$line" =~ FAILED[[:space:]]([^[:space:]]+::[^[:space:]]+) ]]; then
      test_name="${BASH_REMATCH[1]}"
      all_failures+=("$test_name")
    fi
  done < <(echo "$pytest_output")

  # 本当の失敗（許容されない失敗）を特定
  true_failures=()
  for failure in "${all_failures[@]}"; do
    is_allowed=false

    for allowed in "${allowed_failures[@]}"; do
      if [[ "$failure" == "$allowed" ]]; then
        is_allowed=true
        break
      fi
    done

    if [[ "$is_allowed" == "false" ]]; then
      true_failures+=("$failure")
    fi
  done

  # 結果の表示
  echo
  echo "=== テスト実行結果のサマリー ==="
  echo

  # すべてのテスト結果の要約を表示（pytestの最後の行を抽出）
  summary=$(echo "$pytest_output" | grep -E "= .* tests, .* deselected" | tail -1)
  echo "全体の結果: $summary"
  echo

  echo "許容される失敗テスト:"
  for allowed in "${allowed_failures[@]}"; do
    # 実際に失敗したかチェック
    is_failed=false
    for failure in "${all_failures[@]}"; do
      if [[ "$failure" == "$allowed" ]]; then
        is_failed=true
        break
      fi
    done

    if [[ "$is_failed" == "true" ]]; then
      echo "  ✓ $allowed (予期された失敗)"
    else
      echo "  - $allowed (失敗しませんでした)"
    fi
  done
  echo

  if [ ${#true_failures[@]} -eq 0 ]; then
    echo "✅ 重要なテストはすべて成功しました！"
    return 0
  else
    echo "❌ 対応が必要な失敗テスト:"
    for failure in "${true_failures[@]}"; do
      echo "  - $failure"
    done
    return 1
  fi
}

function find_single_quotes() {
  local FUNCNAME="find_single_quotes"

  # ヘルプメッセージの表示
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${FUNCNAME}: このツールはファイル内の二重引用符の外側にある一重引用符が2つ以上ある行を検出します"
    echo "使用法: ${FUNCNAME} <ファイルパス>"
    echo "例: ${FUNCNAME} ./my_file.txt"
    return 0
  fi

  # パラメータのチェック
  if [[ $# -eq 0 ]]; then
    echo "[ERROR] ${FUNCNAME}: ファイルパスが指定されていません"
    echo "[INFO] ${FUNCNAME}: 使用法を確認するには '${FUNCNAME} --help' を実行してください"
    return 1
  fi

  local file_path="$1"

  # ファイルの存在チェック
  if [[ ! -f "$file_path" ]]; then
    echo "[ERROR] ${FUNCNAME}: ファイル '$file_path' が見つかりません"
    return 1
  fi

  # ファイルの読み取り権限チェック
  if [[ ! -r "$file_path" ]]; then
    echo "[ERROR] ${FUNCNAME}: ファイル '$file_path' の読み取り権限がありません"
    return 1
  fi

  # 一重引用符が2つ以上あり、二重引用符の外側にある行を検出
  echo "[INFO] ${FUNCNAME}: ファイル '$file_path' を処理しています..."

  # AWKスクリプトで処理
  awk '
  {
    in_double_quote = 0
    single_quote_count = 0

    for (i = 1; i <= length($0); i++) {
      char = substr($0, i, 1)

      if (char == "\"" && substr($0, i-1, 1) != "\\") {
        in_double_quote = !in_double_quote
      } else if (char == "\x27" && !in_double_quote && substr($0, i-1, 1) != "\\") {
        single_quote_count++
      }
    }

    if (single_quote_count >= 2) {
      printf "行番号 %d: %s\n", NR, $0
    }
  }
  ' "$file_path"

  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${FUNCNAME}: ファイルの処理中にエラーが発生しました"
    return 1
  fi

  echo "[INFO] ${FUNCNAME}: 処理が完了しました"
  return 0
}

function clean_go_pkg() {
  # --help が指定された場合は使い方とサンプルのドライランを表示
  if [ "$1" = "--help" ]; then
    cat <<EOF
Usage: clean_pkg <package_path>

This function does the following:
  1. Removes the package directory at: \${go_path}/pkg/mod/*
EOF
    return 0
  fi

  # パッケージパスが指定されていない場合はエラーを表示
  if [ -z "$1" ]; then
    echo "Error: package path is required."
    echo "Usage: clean_pkg <package_path>"
    return 1
  fi

  local go_path="~/gopath"

  echo "Removing directory: ${target_dir}"
  rm -rf "${go_path}/pkg/mod/*"
}

#==============================================================#
##          JSON Functions                                    ##
#==============================================================#
# JSONCファイルのコメントを削除する（単純な実装）
function strip_jsonc() {
  # 行コメント（//）を削除
  sed -E 's://.*$::g' "$1" | \
  # ブロックコメント（/* ... */）を削除（複数行にまたがる場合に対応）
  sed -E ':a;N;$!ba;s:/\*([^*]|\*+[^*/])*\*+/::g'
}

# ファイルの内容をロード。コメント除去を実施
function load_json() {
  local file="$1"
  if [[ "$file" == *.json ]] || [[ "$file" == *.jsonc ]]; then
    strip_jsonc "$file"
  else
    cat "$file"
  fi
}

# not applicable...
# TEST: compare_json $HOME/Dev/dotfiles/.config/zsh/test/compare_json_01.json $HOME/Dev/dotfiles/.config/zsh/test/compare_json_02.json
function compare_json() {
  local FUNC_NAME="compare_json"
  local USAGE="Usage: ${FUNC_NAME}

このスクリプトは、2つのJSONまたはJSONCファイルのトップレベルのキーと値を比較し、
・片方のみに存在するフィールド
・もう片方のみに存在するフィールド
・両方に存在するが値が異なるフィールド
を列挙します。

使用例:
  ./compare_json.sh file1.json[.jsonc] file2.json[.jsonc]

--help パラメータを渡すと、使用方法を表示します。
"

  # --helpパラメータの処理
  if [ "$1" == "--help" ]; then
    echo "[INFO] $USAGE"
    return 0
  fi

  if [ "$#" -ne 2 ]; then
    echo "[ERROR] Usage: compare_json file1.json[.jsonc] file2.json[.jsonc]"
    return 1
  fi

  local file1="$1"
  local file2="$2"

  # 入力ファイルの存在チェック
  if [ ! -f "$file1" ]; then
    echo "[ERROR] File not found: $file1"
    return 1
  fi
  if [ ! -f "$file2" ]; then
    echo "[ERROR] File not found: $file2"
    return 1
  fi

  # ファイル内容のロード（JSONCならコメント除去）
  local data1 data2
  data1=$(load_json "$file1")
  data2=$(load_json "$file2")

  # JSONとしてフラット化: 各行 "keypath<TAB>value" を出力
  local flat1 flat2
  flat1=$(echo "$data1" | jq -r 'paths(scalars) as $p | "\($p | map(tostring) | join("::"))\t\(getpath($p))"')
  if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to parse JSON from file: $file1"
    return 1
  fi
  flat2=$(echo "$data2" | jq -r 'paths(scalars) as $p | "\($p | map(tostring) | join("::"))\t\(getpath($p))"')
  if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to parse JSON from file: $file2"
    return 1
  fi

  # 連想配列に格納（bash4以降が必要）
  declare -A dict1
  declare -A dict2

  local line key value
  while IFS=$'\t' read -r key value; do
    dict1["$key"]="$value"
  done <<< "$flat1"

  while IFS=$'\t' read -r key value; do
    dict2["$key"]="$value"
  done <<< "$flat2"

  # 片方のみ存在するフィールド（file1のみ）
  echo "[INFO] ${file1} のみ存在するフィールド:"
  for key in "${!dict1[@]}"; do
    if [[ -z "${dict2[$key]+x}" ]]; then
      echo "$key -> ${dict1[$key]}"
    fi
  done

  echo ""
  # もう片方のみ存在するフィールド（file2のみ）
  echo "[INFO] ${file2} のみ存在するフィールド:"
  for key in "${!dict2[@]}"; do
    if [[ -z "${dict1[$key]+x}" ]]; then
      echo "$key -> ${dict2[$key]}"
    fi
  done

  echo ""
  # 両方に存在するが、値が異なるフィールド
  echo "両方に存在するが、値が異なるフィールド"
  for key in "${!dict1[@]}"; do
    if [[ -n "${dict2[$key]+x}" ]]; then
      if [ "${dict1[$key]}" != "${dict2[$key]}" ]; then
        echo "$key -> $file1: ${dict1[$key]} | $file2: ${dict2[$key]}"
      fi
    fi
  done
}

function convert_json_log_timestamps() {
  local funcname="${FUNCNAME[0]}"
  local directory=""
  local tool_dir="."
  local verbose=false

  # ヘルプ表示
  function show_help() {
    echo "使用方法: ${funcname} [オプション] <ディレクトリ>"
    echo ""
    echo "オプション:"
    echo "  --help          このヘルプメッセージを表示"
    echo "  --verbose       詳細な処理情報を表示"
    echo "  --tool-dir DIR  json-timestamp-modifier が存在するディレクトリを指定（デフォルト: カレントディレクトリ）"
    echo ""
    echo "説明:"
    echo "  指定されたディレクトリ内のすべての log_yyyyMMdd-hhmmss.json 形式のファイルに対して、"
    echo "  ファイル名からUNIXタイムスタンプを抽出し、json-timestamp-modifier を使用して"
    echo "  JSONファイルのoutput_atフィールドを更新します。"
    echo ""
    echo "使用例:"
    echo "  ${funcname} ./logs"
    echo "  ${funcname} --verbose --tool-dir /path/to/tools /path/to/logs"
    echo ""
    echo "注意:"
    echo "  'json-timestamp-modifier'の実行ファイルが必要です。"
    return 0
  }

  # 引数解析
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help)
        show_help
        return 0
        ;;
      --verbose)
        verbose=true
        shift
        ;;
      --tool-dir)
        if [[ -n "$2" ]]; then
          tool_dir="$2"
          shift 2
        else
          echo "[ERROR] ${funcname}: --tool-dir オプションには引数が必要です。"
          return 1
        fi
        ;;
      *)
        if [[ -z "$directory" ]]; then
          directory="$1"
        else
          echo "[ERROR] ${funcname}: 複数のディレクトリが指定されています。一度に処理できるのは1ディレクトリのみです。"
          return 1
        fi
        shift
        ;;
    esac
  done

  # ディレクトリ名チェック
  if [[ -z "$directory" ]]; then
    echo "[ERROR] ${funcname}: ディレクトリが指定されていません。"
    echo "[INFO] ${funcname}: ヘルプを表示するには --help オプションを使用してください。"
    return 1
  fi

  # ディレクトリの存在チェック
  if [[ ! -d "$directory" ]]; then
    echo "[ERROR] ${funcname}: ディレクトリ '$directory' が見つかりません。"
    return 1
  fi

  # tool_dir の存在チェック
  if [[ ! -d "$tool_dir" ]]; then
    echo "[ERROR] ${funcname}: ツールディレクトリ '$tool_dir' が見つかりません。"
    return 1
  fi

  # json-modifier の存在確認
  local tool_path="${tool_dir}/json-modifier"
  if [[ ! -f "$tool_path" ]]; then
    echo "[ERROR] ${funcname}: '$tool_path' が見つかりません。"
    return 1
  fi

  if [[ ! -x "$tool_path" ]]; then
    echo "[ERROR] ${funcname}: '$tool_path' に実行権限がありません。"
    return 1
  fi

  # 対象ファイルを検索
  local files=()
  while IFS= read -r -d $'\0' file; do
    files+=("$file")
  done < <(find "$directory" -type f -name "log_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9].json" -print0)

  # ファイルが見つからない場合
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "[ERROR] ${funcname}: ディレクトリ '$directory' 内に対象となるログファイルが見つかりません。"
    return 1
  fi

  echo "[INFO] ${funcname}: ${#files[@]} 件のファイルを処理します。"

  # 各ファイルを処理
  local success_count=0
  local error_count=0

  for filename in "${files[@]}"; do
    local basename=$(basename "$filename")

    if $verbose; then
      echo "[INFO] ${funcname}: ファイル '$basename' を処理中..."
    fi

    # ファイル名から日付と時間の部分を抽出
    local datepart=${basename:4:8}
    local timepart=${basename:13:6}

    # 年、月、日、時、分、秒を分解
    local year=${datepart:0:4}
    local month=${datepart:4:2}
    local day=${datepart:6:2}
    local hour=${timepart:0:2}
    local minute=${timepart:2:2}
    local second=${timepart:4:2}

    # システムに応じた date コマンドの使用
    local timestamp
    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS
      if $verbose; then
        echo "[INFO] ${funcname}: macOS システムが検出されました。"
        echo "[INFO] ${funcname}: コマンド実行: date -u -j -f \"%Y-%m-%d %H:%M:%S\" \"${year}-${month}-${day} ${hour}:${minute}:${second}\" +%s"
      fi
      timestamp=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "${year}-${month}-${day} ${hour}:${minute}:${second}" +%s 2>/dev/null)
    else
      # Linux/その他
      if $verbose; then
        echo "[INFO] ${funcname}: Linux/その他のシステムが検出されました。"
        echo "[INFO] ${funcname}: コマンド実行: date -u -d \"${year}-${month}-${day} ${hour}:${minute}:${second}\" +%s"
      fi
      timestamp=$(date -u -d "${year}-${month}-${day} ${hour}:${minute}:${second}" +%s 2>/dev/null)
    fi

    # timestamp の取得確認
    if [[ -z "$timestamp" || "$timestamp" == *"illegal"* || "$timestamp" == *"invalid"* ]]; then
      echo "[ERROR] ${funcname}: ファイル '$basename' の日付からタイムスタンプへの変換に失敗しました。"
      ((error_count++))
      continue
    fi

    # 実行するコマンドを表示
    echo "[INFO] ${funcname}: 以下のコマンドを実行します:"
    echo "[INFO] ${funcname}: \"$tool_path\" -file \"$filename\" -key \"output_at\" -set $timestamp"

    # コマンド実行
    if "$tool_path" -file "$filename" -key output_at -set "$timestamp"; then
      echo "[INFO] ${funcname}: ファイル '$basename' のoutput_atフィールドを正常に更新しました。タイムスタンプ: $timestamp"
      ((success_count++))
    else
      echo "[ERROR] ${funcname}: ファイル '$basename' の更新に失敗しました。"
      ((error_count++))
    fi
  done

  # 処理結果の表示
  echo "[INFO] ${funcname}: 処理完了。成功: $success_count 件、失敗: $error_count 件"

  if [[ $error_count -gt 0 ]]; then
    return 1
  else
    return 0
  fi
}

#==============================================================#
##          Diff Functions                                    ##
#==============================================================#
function diff_files() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: diff_files file1 file2"
    return 1
  fi

  if [ ! -f "$1" ]; then
    echo "Error: '$1' は存在しないか、ファイルではありません。"
    return 1
  fi

  if [ ! -f "$2" ]; then
    echo "Error: '$2' は存在しないか、ファイルではありません。"
    return 1
  fi

  diff -u "$1" "$2"
}

function diff_dirs() {
  if [ "$#" -lt 2 ]; then
    echo "Usage: diff_dirs dir1 dir2 [exclude_pattern...]"
    echo "Example: diff_dirs dir1 dir2 \"*.log\" \"temp*\""
    return 1
  fi

  local dir1="$1"
  local dir2="$2"
  shift 2

  # 残りの引数を除外パターンとして配列に格納
  local exclude_patterns=("$@")

  if [ ! -d "$dir1" ]; then
    echo "Error: '$dir1' はディレクトリではありません。"
    return 1
  fi

  if [ ! -d "$dir2" ]; then
    echo "Error: '$dir2' はディレクトリではありません。"
    return 1
  fi

  for file in "$dir1"/*; do
    local filename
    filename=$(basename "$file")

    # 除外パターンに一致する場合はスキップ
    local skip=0
    for pattern in "${exclude_patterns[@]}"; do
      if [[ "$filename" == $pattern ]]; then
        skip=1
        break
      fi
    done
    if [ $skip -eq 1 ]; then
      continue
    fi

    # 両ディレクトリに同名の通常ファイルがあれば diff_files を実行
    if [ -f "$file" ] && [ -f "$dir2/$filename" ]; then
      echo "========== $filename の差分 =========="
      echo ""
      diff_files "$file" "$dir2/$filename"
      echo ""
      echo "-----------------------------------------"
      echo ""
      echo ""
    fi
  done
}

# 任意のファイルのcat結果を別ファイルの指定行の特定範囲文字でgrepする関数
function cat_grep_by_line() {
  # 引数のチェック
  if [ $# -ne 5 ]; then
    echo "使用方法: cat_grep_by_line <cat対象ファイル> <grep用ファイル> <行番号> <開始位置> <終了位置>"
    return 1
  fi

  local CAT_FILE="$1"
  local GREP_FILE="$2"
  local LINE_NUM="$3"
  local START_POS="$4"
  local END_POS="$5"

  # ファイルの存在チェック
  if [ ! -f "$CAT_FILE" ]; then
    echo "エラー: cat対象ファイル '$CAT_FILE' が見つかりません"
    return 1
  fi

  if [ ! -f "$GREP_FILE" ]; then
    echo "エラー: grep用ファイル '$GREP_FILE' が見つかりません"
    return 1
  fi

  # 数値チェック
  if ! [[ "$START_POS" =~ ^[0-9]+$ ]] || ! [[ "$END_POS" =~ ^[0-9]+$ ]]; then
    echo "エラー: 開始位置と終了位置は数値である必要があります"
    return 1
  fi

  if [ "$START_POS" -gt "$END_POS" ]; then
    echo "エラー: 開始位置は終了位置以下である必要があります"
    return 1
  fi

  # 指定ファイルの指定行を取得
  local LINE=$(sed -n "${LINE_NUM}p" "$GREP_FILE")

  if [ -z "$LINE" ]; then
    echo "警告: 指定された行 $LINE_NUM は空か存在しません"
    return 1
  fi

  # 行から指定範囲の文字を抽出
  local LINE_LENGTH=${#LINE}

  if [ "$START_POS" -gt "$LINE_LENGTH" ]; then
    echo "エラー: 開始位置が行の長さを超えています"
    return 1
  fi

  local ACTUAL_END=$END_POS
  if [ "$END_POS" -gt "$LINE_LENGTH" ]; then
    ACTUAL_END=$LINE_LENGTH
    echo "警告: 終了位置が行の長さを超えています。行の終わりまでを使用します"
  fi

  # 文字列の切り出し（bash では文字列のインデックスは0から始まる）
  local START_IDX=$((START_POS - 1))
  local LENGTH=$((ACTUAL_END - START_POS + 1))
  local PATTERN=${LINE:$START_IDX:$LENGTH}

  # 特殊文字をエスケープ
  PATTERN=$(echo "$PATTERN" | sed 's/[]\/$*.^[]/\\&/g')

  if [ -z "$PATTERN" ]; then
    echo "警告: 指定された範囲の文字列は空です"
    return 1
  fi

  # catの結果を指定パターンでgrep
  cat "$CAT_FILE" | grep "$PATTERN"
}

#==============================================================#
##          Snippet functions                                 ##
#==============================================================#

function snippet() {
  function contains_element() {
    local target="$1"
    shift
    local array=("$@")

    for item in "${array[@]}"; do
      if [[ "$item" == "$target" ]]; then
        return 0
      fi
    done
    return 1
  }

  function add_prefix() {
    local prefix="$1"
    shift
    local array=("$@")
    local new_array=()

    for element in "${array[@]}"; do
        new_array+=("${prefix}${element}")
    done

    echo "${new_array[@]}"
  }

  function remove_substring_sed() {
    local input_string="$1"
    local remove_str="$2"
    echo "$input_string" | sed "s/$remove_str//g"
  }

  function here_are_the_available_snippets() {
    local len=${#1}
    local hashes=$(printf "%${len}s" "" | tr ' ' '#')
    echo -e ""
    echo "#######################################################$hashes"
    echo "######   Here are the available snippets for $1.   ######"
    echo "#######################################################$hashes"
    echo -e ""
  }

  while [ $# -gt 0 ]; do
    apt_array=("commands-for-disk")
    docker_array=("aliases" "build-options" "options" "run-options" "subcommands")
    git_array=("diff-options" "options" "subcommands")
    go_array=("options" "subcommands")
    psql_array=("commands")
    tmux_array=("options" "subcommands")
    case ${1} in
      --help | -h)
        apt_array=($(add_prefix "--" "${apt_array[@]}"))
        docker_array=($(add_prefix "--" "${docker_array[@]}"))
        git_array=($(add_prefix "--" "${git_array[@]}"))
        go_array=($(add_prefix "--" "${go_array[@]}"))
        psql_array=($(add_prefix "--" "${psql_array[@]}"))
        tmux_array=($(add_prefix "--" "${tmux_array[@]}"))
        echo -e "Usage: ${BASH_SOURCE[0]:-$0} [common | apt | docker | git | go | psql | tmux] [--help | -h]" 0>&2
        echo -e "  common: show common snippets."
        echo -e "  apt: show snippets for Debian/Ubuntu terminals with the following options. [$(echo "${apt_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  docker: show snippets for docker with the following options. [$(echo "${docker_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  git: show snippets for git with the following options. [$(echo "${git_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  go: show snippets for go with the following options. [$(echo "${go_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  psql: show snippets for psql with the following options. [$(echo "${psql_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  tmux: show snippets for tmux with the following options. [$(echo "${tmux_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        return 0
				;;
      apt)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${apt_array[@]}"; then
          here_are_the_available_snippets "Debian/Ubuntu on $snippet_file"
          cat $BASH_HOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      common)
          here_are_the_available_snippets "common on $snippet_file"
        cat $BASH_HOMEDIR/snippets/$1/common.txt
        ;;
      docker)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${docker_array[@]}"; then
          here_are_the_available_snippets "Docker on $snippet_file"
          cat $BASH_HOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      git)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${git_array[@]}"; then
          here_are_the_available_snippets "Git on $snippet_file"
          cat $BASH_HOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      go)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${go_array[@]}"; then
          here_are_the_available_snippets "Go on $snippet_file"
          cat $BASH_HOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      psql)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${psql_array[@]}"; then
          here_are_the_available_snippets "PostgreSQL on $snippet_file"
          cat $BASH_HOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      tmux)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${tmux_array[@]}"; then
          here_are_the_available_snippets "Tmux on $snippet_file"
          echo "Here are the available snippets for Tmux."
          cat $BASH_HOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      --aliases | --build-options | --commands-for-disk | --options | --run-options | --subcommands | --diff-options | --commands)
        return 1
				;;
      *)
				echo "[ERROR] Invalid arguments '${1}'"
				usage
        return 1
				;;
    esac
    echo -e ""
		shift
	done
}

function upload_file_into_gcs() {
  local src_file=$1
  local dest_dir=$2
  gsutil cp $1 $2
}
