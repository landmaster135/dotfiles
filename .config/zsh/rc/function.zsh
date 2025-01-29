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
    echo "#################################################################"
    echo "######   Here are the available snippets for $1.   ######"
    echo "#################################################################"
    echo -e ""
  }

  while [ $# -gt 0 ]; do
    docker_array=("aliases" "build-options" "options" "run-options" "subcommands")
    git_array=("diff-options" "options" "subcommands")
    psql_array=("commands")
    tmux_array=("options" "subcommands")
    case ${1} in
      --help | -h)
        docker_array=($(add_prefix "--" "${docker_array[@]}"))
        git_array=($(add_prefix "--" "${git_array[@]}"))
        psql_array=($(add_prefix "--" "${psql_array[@]}"))
        tmux_array=($(add_prefix "--" "${tmux_array[@]}"))
        echo -e "Usage: ${BASH_SOURCE[0]:-$0} [docker | git | psql | tmux] [--help | -h]" 0>&2
        echo -e "  docker: show snippets for docker with the following options. [$(echo "${docker_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  git: show snippets for git with the following options. [$(echo "${git_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  psql: show snippets for psql with the following options. [$(echo "${psql_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  tmux: show snippets for tmux with the following options. [$(echo "${tmux_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
				# exit 1
				;;
      docker)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${docker_array[@]}"; then
          here_are_the_available_snippets "Docker"
          cat $ZHOMEDIR/snippets/docker/$snippet_file.txt
        fi
        ;;
      git)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${git_array[@]}"; then
          here_are_the_available_snippets "Git"
          cat $ZHOMEDIR/snippets/git/$snippet_file.txt
        fi
        ;;
      psql)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${psql_array[@]}"; then
          here_are_the_available_snippets "PostgreSQL"
          cat $ZHOMEDIR/snippets/postgresql/$snippet_file.txt
        fi
        ;;
      tmux)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${tmux_array[@]}"; then
          here_are_the_available_snippets "Docker"
          echo "Here are the available snippets for Tmux."
          cat $ZHOMEDIR/snippets/tmux/$snippet_file.txt
        fi
        ;;
      --aliases | --build-options | --options | --run-options | --subcommands | --diff-options | --commands)
				;;
      general)
          here_are_the_available_snippets "general"
        cat $ZHOMEDIR/snippets/general/general.txt
        ;;
      --aliases | --build-options | --options | --run-options | --subcommands | --diff-options | --commands)
				;;
      *)
				echo "[ERROR] Invalid arguments '${1}'"
				usage
				# exit 1
				;;
    esac
    echo -e ""
		shift
	done
}
