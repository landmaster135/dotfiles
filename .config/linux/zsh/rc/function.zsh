#!/bin/zsh

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
  # Get function name
  local func_name="${FUNCNAME[0]}"
  local target_dir=""
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <directory>"
    echo "[INFO] ${func_name}: This function changes line endings from CRLF to LF for all files in a directory."
    echo "[INFO] ${func_name}: Example: ${func_name} dir_1"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Directory path is required."
    return 1
  fi

  target_dir="$1"

  # Check if directory exists
  echo "[INFO] ${func_name}: Checking if directory '${target_dir}' exists..."
  if [[ ! -d "${target_dir}" ]]; then
    echo "[ERROR] ${func_name}: Directory '${target_dir}' does not exist."
    return 2
  fi

  # Check if dos2unix is installed
  echo "[INFO] ${func_name}: Checking if dos2unix is installed..."
  if ! command -v dos2unix &> /dev/null; then
    echo "[ERROR] ${func_name}: dos2unix command not found. Please install it first."
    return 3
  fi

  # Count number of files to be processed
  echo "[INFO] ${func_name}: Counting files in '${target_dir}'..."
  local file_count=$(find "${target_dir}" -type f | wc -l)
  echo "[INFO] ${func_name}: Found ${file_count} files to process."

  # Execute find and dos2unix
  echo "[INFO] ${func_name}: Executing: find ${target_dir} -type f -exec dos2unix {} \;"
  find "${target_dir}" -type f -exec dos2unix {} \;
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to convert line endings."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Successfully converted line endings from CRLF to LF for all files in '${target_dir}'."
  return 0
}

function find_and_sort() {
  # ローカル変数の宣言
  local func_name="${FUNCNAME[0]}"
  local directory=""
  local condition=""
  local show_help=false

  # パラメータの処理
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help)
        show_help=true
        shift
        ;;
      --dir=*)
        directory="${1#*=}"
        shift
        ;;
      --pattern=*)
        condition="${1#*=}"
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なパラメータ: $1" >&2
        return 1
        ;;
    esac
  done

  # ヘルプの表示
  if $show_help; then
    echo "[INFO] ${func_name}: 使用方法"
    echo "  ${func_name} --dir=<ディレクトリ> --pattern=<検索パターン>"
    echo ""
    echo "  パラメータ:"
    echo "    --dir=<ディレクトリ>    : 検索するディレクトリのパス"
    echo "    --pattern=<検索パターン>: 検索するファイル名のパターン（例: \"*.txt\"）"
    echo "    --help                 : このヘルプメッセージを表示"
    echo ""
    echo "  使用例:"
    echo "    ${func_name} --dir=/home/user/documents --pattern=\"*.pdf\""
    echo "    ${func_name} --dir=/var/log --pattern=\"*.log\""
    return 0
  fi

  # 必須パラメータのチェック
  if [[ -z "$directory" ]]; then
    echo "[ERROR] ${func_name}: ディレクトリが指定されていません。--dir=<ディレクトリ> を指定してください。" >&2
    return 1
  fi

  if [[ -z "$condition" ]]; then
    echo "[ERROR] ${func_name}: 検索パターンが指定されていません。--pattern=<検索パターン> を指定してください。" >&2
    return 1
  fi

  # ディレクトリの存在チェック
  if [[ ! -d "$directory" ]]; then
    echo "[ERROR] ${func_name}: ディレクトリ '$directory' が存在しません。" >&2
    return 1
  fi

  # コマンドの実行
  echo "[INFO] ${func_name}: 実行コマンド: find \"$directory\" -type f -name \"$condition\" | sort"

  # コマンドの実行と結果のキャプチャ
  local result=$(find "$directory" -type f -name "$condition" 2>&1 | sort)

  # コマンドのエラーチェック
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] ${func_name}: コマンド実行中にエラーが発生しました: $result" >&2
    return 1
  fi

  # 結果が空かどうかチェック
  if [[ -z "$result" ]]; then
    echo "[INFO] ${func_name}: 条件に一致するファイルが見つかりませんでした。"
    return 0
  fi

  # 結果の表示
  echo "$result"

  # 成功
  return 0
}

function custom_tree() {
  # ローカル変数に関数名を格納
  local func_name="${FUNCNAME[0]}"

  # ヘルプパラメータのチェック
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: カスタムツリービューを表示します"
    echo "使用方法: ${func_name} [ディレクトリパス] [除外パターン...]"
    echo "オプション:"
    echo "  --help                このヘルプメッセージを表示します"
    echo "使用例:"
    echo "  ${func_name}          カレントディレクトリのツリーを表示"
    echo "  ${func_name} /path/to/dir    指定したディレクトリのツリーを表示"
    echo "  ${func_name} . node_modules  カレントディレクトリから node_modules を除外して表示"
    return 0
  fi

  # Default to current directory if no argument is provided
  local dir="${1:-.}"

  # Check if directory exists
  if [[ ! -d "$dir" ]]; then
    echo "[ERROR] ${func_name}: 指定されたディレクトリ '$dir' が存在しません"
    return 1
  fi

  # Initialize empty exclusion pattern
  local exclude_pattern=""

  # Process arguments after the first one as exclusions
  shift
  for excl in "$@"; do
    # Build grep exclusion pattern
    if [ -n "$exclude_pattern" ]; then
      exclude_pattern="$exclude_pattern|$excl"
    else
      exclude_pattern="$excl"
    fi
  done

  # Current directory
  echo "[INFO] ${func_name}: 現在のディレクトリ: $(pwd)"

  # コマンド表示
  if [ -n "$exclude_pattern" ]; then
    echo "[INFO] ${func_name}: 実行コマンド: find \"$dir\" | grep -v \"$exclude_pattern\" | sort | sed..."
    # Find command with exclusions
    find "$dir" | grep -v "$exclude_pattern" | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g' | sed -E 's/^\(standard input\):[0-9]+://;s/^\.//' 2>/dev/null || {
      echo "[ERROR] ${func_name}: ツリーの生成中にエラーが発生しました"
      return 1
    }
  else
    echo "[INFO] ${func_name}: 実行コマンド: find \"$dir\" | sort | sed..."
    # Find command without exclusions
    find "$dir" | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g' | sed -E 's/^\(standard input\):[0-9]+://;s/^\.//' 2>/dev/null || {
      echo "[ERROR] ${func_name}: ツリーの生成中にエラーが発生しました"
      return 1
    }
  fi

  return 0
}

function du-ah() {
  local func_name="${FUNCNAME[0]}"
  local directory=""
  local num_entries=20  # Default number of entries to show
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <directory> [num_entries]"
    echo "[INFO] ${func_name}: This function shows the largest files/directories in a given path."
    echo "[INFO] ${func_name}: Parameters:"
    echo "[INFO] ${func_name}:   <directory>   - Directory to analyze (required)"
    echo "[INFO] ${func_name}:   [num_entries] - Number of entries to show (optional, default: 20)"
    echo "[INFO] ${func_name}: Example: ${func_name} /home/user 10"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Directory path is required."
    return 1
  fi

  directory="$1"

  # Check if directory exists
  echo "[INFO] ${func_name}: Checking if directory '${directory}' exists..."
  if [[ ! -d "${directory}" && ! -f "${directory}" ]]; then
    echo "[ERROR] ${func_name}: Path '${directory}' does not exist."
    return 2
  fi

  # Second parameter (optional)
  if [[ -n "$2" ]]; then
    # Check if the second parameter is a number
    if [[ "$2" =~ ^[0-9]+$ ]]; then
      num_entries="$2"
    else
      echo "[ERROR] ${func_name}: Number of entries must be a positive integer."
      return 3
    fi
  fi

  echo "[INFO] ${func_name}: Analyzing disk usage in '${directory}', showing top ${num_entries} entries..."

  # Execute du command
  echo "[INFO] ${func_name}: Executing: du -ah ${directory} | sort -rh | head -n ${num_entries}"
  du -ah "${directory}" | sort -rh | head -n "${num_entries}"
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to analyze disk usage in '${directory}'."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Disk usage analysis completed."
  return 0
}

function count_files() {
	# Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Directory path is required."
    return 1
  fi

	find "$1" -maxdepth 1 -type f | wc -l

	return 0
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
##          Git Functions                                     ##
#==============================================================#

# `precmd` runs on every execution.
function precmd() {
	# Counts File Descriptor
  local fd_count=$(ls /proc/$$/fd | wc -l)
  if (( fd_count > 8000 )); then
    echo "警告: fd使用数が${fd_count}に達しています"
  fi
}

#==============================================================#
##          Git Functions                                     ##
#==============================================================#

function git-erase() {
  local func_name="${FUNCNAME[0]}"
  local file_pattern=""
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <file_pattern>"
    echo "[INFO] ${func_name}: This function removes a file from the entire git history."
    echo "[INFO] ${func_name}: Example: ${func_name} credential.json"
    echo "[INFO] ${func_name}: WARNING: This rewrites git history. Use with caution!"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: File pattern is required."
    return 1
  fi

  file_pattern="$1"

  # Confirm the operation
  echo "[INFO] ${func_name}: This will permanently remove '${file_pattern}' from the entire git history."
  echo "[INFO] ${func_name}: This operation rewrites git history and cannot be undone."
  read -p "[INFO] ${func_name}: Are you sure you want to continue? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "[INFO] ${func_name}: Operation cancelled."
    return 0
  fi

  # Execute git filter-branch
  echo "[INFO] ${func_name}: Executing: git filter-branch --force --index-filter \"git rm --cached --ignore-unmatch ${file_pattern}\" -- --all"
  git filter-branch --force --index-filter "git rm --cached --ignore-unmatch ${file_pattern}" -- --all
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to remove '${file_pattern}' from git history."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Successfully removed '${file_pattern}' from git history."
  echo "[INFO] ${func_name}: You may need to force-push to update the remote repository."
  echo "[INFO] ${func_name}: Example: git push origin --force --all"

  return 0
}

function git-post-erase() {
  local func_name="${FUNCNAME[0]}"
  local exit_code=0

  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name}"
    echo "[INFO] ${func_name}: Creates 'backup/origin-main' from origin/main and force-pushes local main with lease."
    return 0
  fi

  echo "[INFO] ${func_name}: Creating backup branch 'backup/origin-main' from origin/main..."
  git branch backup/origin-main origin/main
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to create backup branch. Aborting."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Force-pushing local main with lease..."
  git push --force-with-lease origin main
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Force push failed."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Completed backup creation and force push."
  return 0
}

function git-repat() {
  local func_name="${FUNCNAME[0]}"
  local pat=""
  local current_url=""
  local username=""
  local repository=""
  local new_url=""
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <personal_access_token>"
    echo "[INFO] ${func_name}: This function updates the git remote URL with a personal access token."
    echo "[INFO] ${func_name}: Example: ${func_name} ghp_1234abcd5678efgh"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Personal Access Token (PAT) is required."
    return 1
  fi

  pat="$1"

  # Get current remote URL
  echo "[INFO] ${func_name}: Getting current remote URL..."
  current_url=$(git remote -v | awk '/origin/ && /fetch/ {print $2; exit}')
  exit_code=$?
  if [[ ${exit_code} -ne 0 || -z "${current_url}" ]]; then
    echo "[ERROR] ${func_name}: Failed to get current remote URL."
    return 2
  fi

  echo "[INFO] ${func_name}: Current remote URL found."

  # Extract username and repository from URL
  echo "[INFO] ${func_name}: Extracting username and repository..."
  if [[ "${current_url}" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    username="${BASH_REMATCH[1]}"
    # Remove .git extension if present
    repository="${BASH_REMATCH[2]}"
    repository="${repository%.git}"
  else
    echo "[ERROR] ${func_name}: Failed to extract username and repository from URL: ${current_url}"
    return 3
  fi

  echo "[INFO] ${func_name}: Username: ${username}, Repository: ${repository}"

  # Create new URL with PAT
  new_url="https://${username}:${pat}@github.com/${username}/${repository}.git"

  # Update remote URL
  echo "[INFO] ${func_name}: Executing: git remote set-url origin <URL with PAT>"
  # Not showing the actual URL with PAT for security reasons
  git remote set-url origin "${new_url}"
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to update remote URL."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Successfully updated remote URL with Personal Access Token."
  return 0
}

function git-chup-main() {
  local func_name="${FUNCNAME[0]}"
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name}"
    echo "[INFO] ${func_name}: This function checks out the main branch and pulls the latest changes."
    echo "[INFO] ${func_name}: Example: ${func_name}"
    return 0
  fi

  # No parameters expected for this function
  if [[ -n "$1" ]]; then
    echo "[INFO] ${func_name}: Note - this function does not require parameters."
  fi

  # Checkout main
  echo "[INFO] ${func_name}: Executing: git checkout main"
  git checkout main
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to checkout main branch."
    return ${exit_code}
  fi

  # Pull from main
  echo "[INFO] ${func_name}: Executing: git pull origin main"
  git pull origin main
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to pull changes from main."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Successfully updated main branch."
  return 0
}

function git-renew() {
  local func_name="${FUNCNAME[0]}"
  local working_branch=""
  local exit_code=0
  local branch_exists=false

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <branch_name>"
    echo "[INFO] ${func_name}: This function checks out main branch, pulls latest changes,"
    echo "[INFO] ${func_name}: then checks out your working branch (creates it if not exists)"
    echo "[INFO] ${func_name}: and merges main into it."
    echo "[INFO] ${func_name}: Example: ${func_name} feature_branch"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Working branch name is required."
    return 1
  fi

  working_branch="$1"

  # Check if branch exists
  echo "[INFO] ${func_name}: Checking if branch '${working_branch}' exists..."
  if git show-ref --verify --quiet refs/heads/"${working_branch}"; then
    branch_exists=true
    echo "[INFO] ${func_name}: Branch '${working_branch}' exists."
  else
    echo "[INFO] ${func_name}: Branch '${working_branch}' does not exist. Will create it later."
  fi

  # Checkout main
  echo "[INFO] ${func_name}: Executing: git checkout main"
  git checkout main
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to checkout main branch."
    return ${exit_code}
  fi

  # Pull from main
  echo "[INFO] ${func_name}: Executing: git pull origin main"
  git pull origin main
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to pull changes from main."
    return ${exit_code}
  fi

  # Checkout working branch (create if doesn't exist)
  if [[ "${branch_exists}" == true ]]; then
    echo "[INFO] ${func_name}: Executing: git checkout ${working_branch}"
    git checkout "${working_branch}"
  else
    echo "[INFO] ${func_name}: Executing: git checkout -b ${working_branch}"
    git checkout -b "${working_branch}"
  fi

  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to checkout/create branch '${working_branch}'."
    return ${exit_code}
  fi

  # Only merge if the branch already existed (new branch is already based on latest main)
  if [[ "${branch_exists}" == true ]]; then
    echo "[INFO] ${func_name}: Executing: git merge main"
    git merge main
    exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
      echo "[ERROR] ${func_name}: Failed to merge main into '${working_branch}'."
      return ${exit_code}
    fi
    echo "[INFO] ${func_name}: Successfully updated branch '${working_branch}' with changes from main."
  else
    echo "[INFO] ${func_name}: Branch '${working_branch}' was newly created from main, no merge needed."
  fi

  return 0
}

function git-nb() {
  # Get function name
  local func_name="${FUNCNAME[0]}"
  local branch_name=""
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <branch_name>"
    echo "[INFO] ${func_name}: This function creates a new git branch and checks it out."
    echo "[INFO] ${func_name}: Example: ${func_name} feature_branch"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Branch name is required."
    return 1
  fi

  branch_name="$1"

  # Check if branch already exists
  echo "[INFO] ${func_name}: Checking if branch '${branch_name}' exists..."
  if git show-ref --verify --quiet refs/heads/"${branch_name}"; then
    echo "[ERROR] ${func_name}: Branch '${branch_name}' already exists."
    return 2
  fi

  # Create new branch
  echo "[INFO] ${func_name}: Executing: git branch ${branch_name}"
  git branch "${branch_name}"
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to create branch '${branch_name}'."
    return ${exit_code}
  fi

  # Checkout the new branch
  echo "[INFO] ${func_name}: Executing: git checkout ${branch_name}"
  git checkout "${branch_name}"
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to checkout branch '${branch_name}'."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Successfully created and checked out branch '${branch_name}'."
  return 0
}

function git-publish() {
  local func_name="${FUNCNAME[0]}"
  local branch_name=""
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name}"
    echo "[INFO] ${func_name}: This function pushes the current branch to remote and sets up tracking."
    echo "[INFO] ${func_name}: Example: ${func_name}"
    return 0
  fi

  # No parameters expected for this function
  if [[ -n "$1" ]]; then
    echo "[INFO] ${func_name}: Note - this function does not require parameters."
  fi

  # Get current branch name
  echo "[INFO] ${func_name}: Getting current branch name..."
  branch_name=$(git rev-parse --abbrev-ref HEAD)
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to get the current branch name."
    return ${exit_code}
  fi

  # Check if we're on a branch (not in a detached HEAD state)
  if [[ "${branch_name}" == "HEAD" ]]; then
    echo "[ERROR] ${func_name}: You are in a detached HEAD state, not on a branch."
    return 1
  fi

  echo "[INFO] ${func_name}: Current branch is '${branch_name}'."

  # Push HEAD to remote branch
  # echo "[INFO] ${func_name}: Executing: git push HEAD ${branch_name}"
  # git push HEAD "${branch_name}"
  # exit_code=$?
  # if [[ ${exit_code} -ne 0 ]]; then
  #   echo "[ERROR] ${func_name}: Failed to push HEAD to remote branch '${branch_name}'."
  #   return ${exit_code}
  # fi

  # Set upstream tracking
  echo "[INFO] ${func_name}: Executing: git push --set-upstream origin ${branch_name}"
  git push --set-upstream origin "${branch_name}"
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to set upstream tracking for branch '${branch_name}'."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Successfully published branch '${branch_name}' to remote."
  return 0
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

function git-resync() {
  local func_name="${FUNCNAME[0]}"
  local my_branch=$1

  # --helpパラメータのチェック
  if [ "$1" = "--help" ]; then
    echo "${func_name}: ブランチとmainブランチを同期するコマンド"
    echo
    echo "Usage: ${func_name} <branch_name>"
    echo
    echo "Example:"
    echo "  ${func_name} feature/my-feature"
    echo
    echo "Description:"
    echo "  1. mainブランチに移動"
    echo "  2. mainブランチをpull"
    echo "  3. 指定したブランチに移動"
    echo "  4. 指定したブランチをfetch"
    return 0
  fi

  # 引数チェック
  if [ -z "$my_branch" ]; then
    echo "[ERROR] ${func_name}: ブランチ名を指定してください。"
    echo "[INFO] ${func_name}: ${func_name} --help で使用方法を確認してください。"
    return 1
  fi

  # mainブランチへ移動
  echo "[INFO] ${func_name}: mainブランチへ移動します。"
  echo "[INFO] ${func_name}: 実行コマンド: git checkout main"
  if ! git checkout main; then
    echo "[ERROR] ${func_name}: mainブランチへの移動に失敗しました。"
    return 1
  fi

  # mainブランチをpull
  echo "[INFO] ${func_name}: mainブランチをpullします。"
  echo "[INFO] ${func_name}: 実行コマンド: git pull"
  if ! git pull; then
    echo "[ERROR] ${func_name}: mainブランチのpullに失敗しました。"
    return 1
  fi

  # 指定したブランチへ移動
  echo "[INFO] ${func_name}: ${my_branch}ブランチへ移動します。"
  echo "[INFO] ${func_name}: 実行コマンド: git checkout ${my_branch}"
  if ! git checkout "$my_branch"; then
    echo "[ERROR] ${func_name}: ${my_branch}ブランチへの移動に失敗しました。"
    return 1
  fi

  # 指定したブランチをfetch
  echo "[INFO] ${func_name}: ${my_branch}ブランチをfetchします。"
  echo "[INFO] ${func_name}: 実行コマンド: git fetch"
  if ! git fetch; then
    echo "[ERROR] ${func_name}: ${my_branch}ブランチのfetchに失敗しました。"
    return 1
  fi

  echo "[INFO] ${func_name}: 同期処理が正常に完了しました。"
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

#==============================================================#
##          Taskfile functions                                ##
#==============================================================#

function list_root_taskfiles(){
  echo $HOME/chrome-forge/Taskfile.yml
  echo $HOME/dathub/Taskfile.yml
  echo $HOME/db-server-brewery/Taskfile.yml
  echo $HOME/devbox/Taskfile.yml
  # echo $HOME/dotfiles/Taskfile.yml
  echo $HOME/notion-synchronizer/Taskfile.yml
}

function fill_fields_in_root_taskfiles(){
  local repos=('chrome-forge' 'dathub' 'db-server-brewery' 'devbox' 'notion-synchronizer')

  for repo_name in "${repos[@]}"; do
    echo "Processing repository: $repo_name"
    go run ./cmd/cli/taskfile --operation fill --task-type root --taskfile-path "$HOME/$repo_name/Taskfile.yml"
  done
}
