#!/usr/bin/env bash

set -ue

#--------------------------------------------------------------#
##          Functions                                         ##
#--------------------------------------------------------------#

function helpmsg() {
	print_default "Usage: ${BASH_SOURCE[0]:-$0} [install | update | link] [--with-gui] [--help | -h]" 0>&2
	print_default "  install: add require package install and symbolic link to $HOME from dotfiles [default]"
	print_default "  update: add require package install or update."
	print_default "  link: only symbolic link to $HOME from dotfiles."
	print_default ""
}

function print_success_info(){
  print_info ""
  print_info "#####################################################"
  print_info "$(basename "${BASH_SOURCE[0]:-$1}") $2 $3"
  print_info "#####################################################"
  print_info ""
}

#--------------------------------------------------------------#
##          main                                              ##
#--------------------------------------------------------------#

function main() {
	local current_dir
	current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")
	source $current_dir/lib/dotsinstaller/utilfuncs.sh

	local is_install="false"
	local is_link="false"
	local is_update="false"
	local with_gui="false"

	while [ $# -gt 0 ]; do
		case ${1} in
			--help | -h)
				helpmsg
				exit 1
				;;
			install)
				is_install="true"
				is_update="true"
				is_link="true"
				;;
			update)
				is_install="true"
				is_link="false"
				is_update="true"
				;;
			link)
				is_install="false"
				is_link="true"
				is_update="false"
				;;
			--with-gui)
				with_gui="true"
				;;
			--all) ;;

			--verbose | --debug)
				set -x
				shift
				;;
			*)
				echo "[ERROR] Invalid arguments '${1}'"
				usage
				exit 1
				;;
		esac
		shift
	done

	# default behaviour
	if [[ "$is_install" == false && "$is_link" == false && "$is_update" == false ]]; then
		is_install="true"
		is_link="true"
		is_update="true"
	fi

	if [[ "$is_install" = true ]]; then
		source $current_dir/lib/dotsinstaller/install-required-packages.sh
    print_success_info $0 "" "install finish!!!"
	fi

	if [[ "$is_link" = true ]]; then
		source $current_dir/lib/dotsinstaller/link-to-homedir.sh
		source $current_dir/lib/dotsinstaller/gitconfig.sh
    print_success_info $0 "" "link success!!!"
	fi

	if [[ "$is_update" = true ]]; then
		source $current_dir/lib/dotsinstaller/install-basic-packages.sh
    print_success_info $0 "install-basic-packages.sh" "updated."
		# source $current_dir/lib/dotsinstaller/install-neovim.sh
    if [[ ! -d ~/.local/bin ]]; then
      mkdir -p ~/.local/bin || {
        local fallback_bin="$HOME/bin"  # Define a fallback directory
        mkdir -p "$fallback_bin" || {
          print_error "Failed to create both ~/.local/bin and $fallback_bin. Exiting."
          exit 1
        }
        print_warning "Failed to create ~/.local/bin. Using $fallback_bin instead."
        ln -snf "$current_dir/lib/dotsinstaller/bin/*" "$fallback_bin/" # Use fallback
      }
    else
      ln -snf "$current_dir/lib/dotsinstaller/bin/*" "~/.local/bin/" # Original behavior
    fi

		if [[ "$with_gui" = true ]]; then
			source $current_dir/lib/dotsinstaller/install-extra.sh
      print_success_info $0 "install-extra.sh" "updated."
			source $current_dir/lib/dotsinstaller/setup-terminal.sh
      print_success_info $0 "setup-terminal.sh" "updated."
			# source $current_dir/lib/dotsinstaller/install-i3.sh
			# source $current_dir/lib/dotsinstaller/install-sway.sh
			source $current_dir/lib/dotsinstaller/install-hyprland.sh
      print_success_info $0 "install-hyprland.sh" "updated."
			source $current_dir/lib/dotsinstaller/setup-default-app.sh
      print_success_info $0 "setup-default-app.sh" "updated."
			source $current_dir/lib/dotsinstaller/install-font.sh
      print_success_info $0 "install-font.sh" "updated."
		fi

    print_success_info $0 "" "update finish!!!"
	fi
}

main "$@"
