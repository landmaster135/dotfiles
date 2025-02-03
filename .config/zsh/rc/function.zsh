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
    echo -e ""
    echo "####################################################################"
    echo "######   Here are the available snippets for $1.   ######"
    echo "####################################################################"
    echo -e ""
  }

  while [ $# -gt 0 ]; do
    apt_array=("commands-for-disk")
    docker_array=("aliases" "build-options" "options" "run-options" "subcommands")
    git_array=("diff-options" "options" "subcommands")
    psql_array=("commands")
    tmux_array=("options" "subcommands")
    case ${1} in
      --help | -h)
        apt_array=($(add_prefix "--" "${apt_array[@]}"))
        docker_array=($(add_prefix "--" "${docker_array[@]}"))
        git_array=($(add_prefix "--" "${git_array[@]}"))
        psql_array=($(add_prefix "--" "${psql_array[@]}"))
        tmux_array=($(add_prefix "--" "${tmux_array[@]}"))
        echo -e "Usage: ${BASH_SOURCE[0]:-$0} [common | apt | docker | git | psql | tmux] [--help | -h]" 0>&2
        echo -e "  common: show common snippets."
        echo -e "  apt: show snippets for Debian/Ubuntu terminals with the following options. [$(echo "${apt_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  docker: show snippets for docker with the following options. [$(echo "${docker_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  git: show snippets for git with the following options. [$(echo "${git_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  psql: show snippets for psql with the following options. [$(echo "${psql_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  tmux: show snippets for tmux with the following options. [$(echo "${tmux_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
				# exit 1
				;;
      apt)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${apt_array[@]}"; then
          here_are_the_available_snippets "Debian/Ubuntu"
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      common)
          here_are_the_available_snippets "common"
        cat $ZHOMEDIR/snippets/$1/common.txt
        ;;
      docker)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${docker_array[@]}"; then
          here_are_the_available_snippets "Docker"
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      git)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${git_array[@]}"; then
          here_are_the_available_snippets "Git"
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      psql)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${psql_array[@]}"; then
          here_are_the_available_snippets "PostgreSQL"
          cat $ZHOMEDIR/snippets/$1/$snippet_file.txt
        fi
        return 0
        ;;
      tmux)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${tmux_array[@]}"; then
          here_are_the_available_snippets "Docker"
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
