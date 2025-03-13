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
  local new_url="https://$username:$pat@github.com/$username/$repository.git"
  git remote set-url origin $new_url
}

function git-nb() {
  # 'git-nb' means 'git-new-branch'
  # e.g. git-nb initialCommit
  local branch_name="$1"
  git branch $branch_name
  git checkout $branch_name
}

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
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      common)
          here_are_the_available_snippets "common on $snippet_file"
        cat $ZHOMEDIR/snippets/$1/common.txt
        ;;
      docker)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${docker_array[@]}"; then
          here_are_the_available_snippets "Docker on $snippet_file"
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      git)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${git_array[@]}"; then
          here_are_the_available_snippets "Git on $snippet_file"
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      go)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${go_array[@]}"; then
          here_are_the_available_snippets "Go on $snippet_file"
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      psql)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${psql_array[@]}"; then
          here_are_the_available_snippets "PostgreSQL on $snippet_file"
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      tmux)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${tmux_array[@]}"; then
          here_are_the_available_snippets "Tmux on $snippet_file"
          echo "Here are the available snippets for Tmux."
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
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
