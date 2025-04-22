#!/bin/bash

#==============================================================#
##         New Commands                                       ##
#==============================================================#
function getpids() {
  local func_name="${FUNCNAME[0]}"
  local process_pattern=""
  local pids=""
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <process_pattern>"
    echo "[INFO] ${func_name}: This function returns the PIDs of processes matching the given pattern."
    echo "[INFO] ${func_name}: Example: ${func_name} firefox"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Process pattern is required."
    return 1
  fi

  process_pattern="$1"

  echo "[INFO] ${func_name}: Finding processes matching pattern '${process_pattern}'..."

  # Execute ps command
  echo "[INFO] ${func_name}: Executing: ps x | grep ${process_pattern} | awk '{print \$1}'"
  pids=$(ps x | grep "${process_pattern}" | grep -v "grep ${process_pattern}" | awk '{print $1}')
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to get process IDs."
    return ${exit_code}
  fi

  # Check if any PIDs were found
  if [[ -z "${pids}" ]]; then
    echo "[INFO] ${func_name}: No processes found matching pattern '${process_pattern}'."
    return 0
  fi

  # Output the PIDs
  echo "[INFO] ${func_name}: Found the following PIDs:"
  echo "${pids}"

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
  echo "[INFO] ${func_name}: Executing: git push HEAD ${branch_name}"
  git push HEAD "${branch_name}"
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to push HEAD to remote branch '${branch_name}'."
    return ${exit_code}
  fi

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

#==============================================================#
##          Docker Functions                                  ##
#==============================================================#

function docker-cp() {
  local func_name="${FUNCNAME[0]}"
  local container_id=""
  local executing_file_path=""
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <container_id> <file_path_in_container>"
    echo "[INFO] ${func_name}: This function copies a file from a Docker container to the current directory."
    echo "[INFO] ${func_name}: Example: ${func_name} abc123def456 /app/config.json"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Container ID is required."
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: File path in container is required."
    return 2
  fi

  container_id="$1"
  executing_file_path="$2"

  # Check if container exists
  echo "[INFO] ${func_name}: Checking if container '${container_id}' exists..."
  if ! docker ps -a | grep -q "${container_id}"; then
    echo "[ERROR] ${func_name}: Container '${container_id}' does not exist."
    return 3
  fi

  # Execute docker cp
  echo "[INFO] ${func_name}: Executing: docker cp ${container_id}:${executing_file_path} ."
  docker cp "${container_id}:${executing_file_path}" .
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to copy '${executing_file_path}' from container '${container_id}'."
    return ${exit_code}
  fi

  # Get filename from path
  local filename=$(basename "${executing_file_path}")

  # Check if file was copied successfully
  if [[ -e "${filename}" ]]; then
    echo "[INFO] ${func_name}: Successfully copied '${filename}' to current directory."
  else
    echo "[ERROR] ${func_name}: File was not copied. It may not exist in the container."
    return 4
  fi

  return 0
}

function docker-build() {
  local func_name="${FUNCNAME[0]}"
  local path=""
  local tag=""
  local exit_code=0

  # Help parameter handling
  if [[ "$1" == "--help" ]]; then
    echo "[INFO] ${func_name}: Usage: ${func_name} <path> <tag>"
    echo "[INFO] ${func_name}: This function builds a Docker image from a Dockerfile."
    echo "[INFO] ${func_name}: Example: ${func_name} ./app my-image:latest"
    return 0
  fi

  # Parameter validation
  if [[ -z "$1" ]]; then
    echo "[ERROR] ${func_name}: Path to Dockerfile directory is required."
    return 1
  fi

  if [[ -z "$2" ]]; then
    echo "[ERROR] ${func_name}: Image tag is required."
    return 2
  fi

  path="$1"
  tag="$2"

  # Check if path exists
  echo "[INFO] ${func_name}: Checking if path '${path}' exists..."
  if [[ ! -d "${path}" ]]; then
    echo "[ERROR] ${func_name}: Directory '${path}' does not exist."
    return 3
  fi

  # Check if Dockerfile exists in the path
  echo "[INFO] ${func_name}: Checking if Dockerfile exists in '${path}'..."
  if [[ ! -f "${path}/Dockerfile" ]]; then
    echo "[ERROR] ${func_name}: Dockerfile not found in '${path}'."
    return 4
  fi

  # Execute docker build
  echo "[INFO] ${func_name}: Executing: docker build -t ${tag} ${path}"
  docker build -t "${tag}" "${path}"
  exit_code=$?
  if [[ ${exit_code} -ne 0 ]]; then
    echo "[ERROR] ${func_name}: Failed to build Docker image '${tag}' from '${path}'."
    return ${exit_code}
  fi

  echo "[INFO] ${func_name}: Successfully built Docker image '${tag}' from '${path}'."
  return 0
}

function run_docker_container() {
  local func_name="${FUNCNAME[0]}"
  local container_name=""
  local env_vars=()
  local image_name=""
  local help_flag=false
  local env_file="env.yml"

  # ヘルプメッセージ表示関数
  function show_help() {
    echo "[INFO] ${func_name}: 使用方法:"
    echo "  ${func_name} --name <コンテナ名> --image <イメージ名> [--env-file <YAMLファイル>] [--env KEY=VALUE] [--help]"
    echo ""
    echo "オプション:"
    echo "  --name     コンテナ名を指定 (必須)"
    echo "  --image    実行するDockerイメージ名を指定 (必須)"
    echo "  --env-file 環境変数が記述されたYAMLファイルを指定 (デフォルト: カレントディレクトリのenv.yml)"
    echo "  --env      追加の環境変数を指定 (複数指定可能)"
    echo "  --help     このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${func_name} --name my-container --image nginx"
    echo "  ${func_name} --name db-server --image mysql --env-file db-env.yml"
    echo "  ${func_name} --name app --image my-app:latest --env-file app-env.yml --env DEBUG=true"
  }

  # パラメータが無い場合はヘルプを表示
  if [ $# -eq 0 ]; then
    show_help
    return 1
  fi

  # パラメータの解析
  while [ $# -gt 0 ]; do
    case "$1" in
      --name)
        if [ -z "$2" ] || [[ "$2" == --* ]]; then
          echo "[ERROR] ${func_name}: --nameの後にコンテナ名を指定してください"
          return 1
        fi
        container_name="$2"
        shift 2
        ;;
      --image)
        if [ -z "$2" ] || [[ "$2" == --* ]]; then
          echo "[ERROR] ${func_name}: --imageの後にイメージ名を指定してください"
          return 1
        fi
        image_name="$2"
        shift 2
        ;;
      --env-file)
        if [ -z "$2" ] || [[ "$2" == --* ]]; then
          echo "[ERROR] ${func_name}: --env-fileの後にYAMLファイルパスを指定してください"
          return 1
        fi
        env_file="$2"
        shift 2
        ;;
      --env)
        if [ -z "$2" ] || [[ "$2" == --* ]]; then
          echo "[ERROR] ${func_name}: --envの後に環境変数を KEY=VALUE 形式で指定してください"
          return 1
        fi
        if [[ ! "$2" =~ ^[A-Za-z0-9_]+=.* ]]; then
          echo "[ERROR] ${func_name}: 環境変数は KEY=VALUE 形式で指定してください"
          return 1
        fi
        env_vars+=("$2")
        shift 2
        ;;
      --help)
        help_flag=true
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1"
        show_help
        return 1
        ;;
    esac
  done

  # ヘルプフラグが指定されていたらヘルプを表示して終了
  if $help_flag; then
    show_help
    return 0
  fi

  # 必須パラメータのチェック
  if [ -z "$container_name" ]; then
    echo "[ERROR] ${func_name}: コンテナ名(--name)は必須です"
    return 1
  fi

  if [ -z "$image_name" ]; then
    echo "[ERROR] ${func_name}: イメージ名(--image)は必須です"
    return 1
  fi

  # YAMLファイルの存在チェック
  if [ ! -f "$env_file" ]; then
    echo "[ERROR] ${func_name}: 環境変数ファイル '$env_file' が見つかりません"
    return 1
  fi

  # YAMLファイルから環境変数を読み込む
  echo "[INFO] ${func_name}: 環境変数ファイル '$env_file' から変数を読み込みます"

  # YAMLファイルを解析して環境変数を設定
  while IFS=: read -r key value; do
    # 空行や#で始まる行はスキップ
    if [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    # キーと値からスペースを削除
    key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # 引用符を削除（シングルクォートとダブルクォート両方）
    value=$(echo "$value" | sed -e "s/^[\"']*//" -e "s/[\"']*$//")

    # 環境変数を追加
    if [ -n "$key" ] && [ -n "$value" ]; then
      echo "[INFO] ${func_name}: 環境変数を追加: $key=$value"
      env_vars+=("${key}=${value}")
    fi
  done < "$env_file"

  # コマンドの組み立て
  local cmd="docker run --rm -d --name $container_name"

  # 環境変数があれば追加
  for env_var in "${env_vars[@]}"; do
    cmd="$cmd -e $env_var"
  done

  # イメージ名を追加
  cmd="$cmd $image_name"

  # 実行コマンドの表示
  echo "[INFO] ${func_name}: 実行コマンド: $cmd"

  # コマンドの実行
  eval $cmd
  local exit_code=$?

  # 実行結果の確認
  if [ $exit_code -ne 0 ]; then
    echo "[ERROR] ${func_name}: Dockerコンテナの起動に失敗しました (終了コード: $exit_code)"
    return $exit_code
  fi

  echo "[INFO] ${func_name}: コンテナ '$container_name' を正常に起動しました"
  return 0
}

function stop_docker_container() {
  local func_name="${FUNCNAME[0]}"
  local container_name=""
  local help_flag=false
  local force_flag=false
  local time_wait=10

  # ヘルプメッセージ表示関数
  function show_help() {
    echo "[INFO] ${func_name}: 使用方法:"
    echo "  ${func_name} --name <コンテナ名> [--force] [--time <秒数>] [--help]"
    echo ""
    echo "オプション:"
    echo "  --name    停止するコンテナ名を指定 (必須)"
    echo "  --force   コンテナを強制的に停止する (SIGKILL を送信)"
    echo "  --time    コンテナが正常に停止するまでの待機時間 (デフォルト: 10秒)"
    echo "  --help    このヘルプメッセージを表示"
    echo ""
    echo "使用例:"
    echo "  ${func_name} --name my-container"
    echo "  ${func_name} --name db-server --force"
    echo "  ${func_name} --name app --time 30"
  }

  # パラメータが無い場合はヘルプを表示
  if [ $# -eq 0 ]; then
    show_help
    return 1
  fi

  # パラメータの解析
  while [ $# -gt 0 ]; do
    case "$1" in
      --name)
        if [ -z "$2" ] || [[ "$2" == --* ]]; then
          echo "[ERROR] ${func_name}: --nameの後にコンテナ名を指定してください"
          return 1
        fi
        container_name="$2"
        shift 2
        ;;
      --force)
        force_flag=true
        shift
        ;;
      --time)
        if [ -z "$2" ] || [[ "$2" == --* ]]; then
          echo "[ERROR] ${func_name}: --timeの後に秒数を指定してください"
          return 1
        fi
        if ! [[ "$2" =~ ^[0-9]+$ ]]; then
          echo "[ERROR] ${func_name}: 待機時間は数値で指定してください"
          return 1
        fi
        time_wait="$2"
        shift 2
        ;;
      --help)
        help_flag=true
        shift
        ;;
      *)
        echo "[ERROR] ${func_name}: 不明なオプション: $1"
        show_help
        return 1
        ;;
    esac
  done

  # ヘルプフラグが指定されていたらヘルプを表示して終了
  if $help_flag; then
    show_help
    return 0
  fi

  # 必須パラメータのチェック
  if [ -z "$container_name" ]; then
    echo "[ERROR] ${func_name}: コンテナ名(--name)は必須です"
    return 1
  fi

  # コンテナの存在確認
  if ! docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
    echo "[ERROR] ${func_name}: コンテナ '$container_name' が見つかりません"
    return 1
  fi

  # コンテナが既に停止しているか確認
  if ! docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
    echo "[INFO] ${func_name}: コンテナ '$container_name' は既に停止しています"
    return 0
  fi

  # コマンドの組み立て
  local cmd="docker stop"

  # 強制停止フラグが設定されていれば
  if $force_flag; then
    cmd="docker kill"
    echo "[INFO] ${func_name}: コンテナを強制停止します"
  else
    # 待機時間を指定
    cmd="$cmd --time=$time_wait"
  fi

  # コンテナ名を追加
  cmd="$cmd $container_name"

  # 実行コマンドの表示
  echo "[INFO] ${func_name}: 実行コマンド: $cmd"

  # コマンドの実行
  eval $cmd
  local exit_code=$?

  # 実行結果の確認
  if [ $exit_code -ne 0 ]; then
    echo "[ERROR] ${func_name}: コンテナの停止に失敗しました (終了コード: $exit_code)"
    return $exit_code
  fi

  echo "[INFO] ${func_name}: コンテナ '$container_name' を正常に停止しました"
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
