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

  while [ $# -gt 0 ]; do
    docker_array=("aliases" "build-options" "options" "run-options" "subcommands")
    case ${1} in
      --help | -h)
        docker_array=($(add_prefix "--" "${docker_array[@]}"))
        echo -e ""
        echo -e "Usage: ${BASH_SOURCE[0]:-$0} [docker | git | psql | tmux] [--help | -h]" 0>&2
        echo "  docker: show snippets for docker with the following options. [$(echo "${docker_array[*]}" | tr ' ' '|' | sed 's/|/ | /g')]"
        echo -e "  git: show snippets for git with the following options. [--diff-options | --options | --subcommands]"
        echo -e "  psql: show snippets for psql with the following options. [--commands]"
        echo -e "  tmux: show snippets for tmux with the following options. [--options | --subcommands]"
        echo -e ""
        exit 1
				;;
      docker)
        snippet_file=$(remove_substring_sed $2 "--")
        if contains_element $(remove_substring_sed $2 "--") "${docker_array[@]}"; then
          cat $ZHOMEDIR/snippets/docker/$snippet_file.txt
        fi
        ;;
      # --help | -h)
			# 	;;
      *)
				echo "[ERROR] Invalid arguments '${1}'"
				usage
				exit 1
				;;
    esac
		shift
	done
}
