#==============================================================#
##          WSL Default Configuration                         ##
#==============================================================#
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

#==============================================================#
##          Base Configuration                                ##
#==============================================================#
# Set prompts
export PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '
export MY_PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '

HOSTNAME="$HOST"
HISTFILE="${ZDATADIR}/zsh_history"
HISTSIZE=10000                    # Number of histories in memory
HISTFILESIZE=100000
SAVEHIST=100000                   # Number of histories to be saved
HISTORY_IGNORE="(ls|cd|pwd|zsh|exit|cd ..)"
HISTCONTROL=erasedups
LISTMAX=1000                      # number of completion listings to ask for (1=shut up, 0=ask when window overflows)
# KEYTIMEOUT=1 # conflict with zsh-autocomplete
TZ_ORG="$TZ"
TZ="Asia/Tokyo"

#==============================================================#
##         Utilities                                          ##
#==============================================================#
# Aliases and functions.
export ZHOMEDIR=$HOME/dotfiles/.config/zsh
export ZRCDIR=$ZHOMEDIR
export BASH_HOMEDIR=$HOME/dotfiles/.config/bash
source "$BASH_HOMEDIR/alias.bash"
source "$BASH_HOMEDIR/function.bash"
source "$BASH_HOMEDIR/extract_blog_articles.bash"

# Environment variables
export DOTFILE_HOMEDIR=$HOME/dotfiles
source "$BASH_HOMEDIR/set_env.bash" "$DOTFILE_HOMEDIR/env.yml"

#==============================================================#
##          IaC Functions                                     ##
#==============================================================#
# Install IaC functions
export IAC_HOMEDIR=$HOME/dotfiles/iac
source "$IAC_HOMEDIR/gcloud/init.sh"
source "$IAC_HOMEDIR/gcloud/ai.sh"
source "$IAC_HOMEDIR/gcloud/bigquery.sh"
source "$IAC_HOMEDIR/gcloud/billing.sh"
source "$IAC_HOMEDIR/gcloud/compute.sh"
source "$IAC_HOMEDIR/gcloud/container.sh"
source "$IAC_HOMEDIR/gcloud/db.sh"
source "$IAC_HOMEDIR/gcloud/deployment.sh"
source "$IAC_HOMEDIR/gcloud/dns.sh"
source "$IAC_HOMEDIR/gcloud/iam.sh"
source "$IAC_HOMEDIR/gcloud/logging.sh"
source "$IAC_HOMEDIR/gcloud/monitoring.sh"
source "$IAC_HOMEDIR/gcloud/scheduler.sh"
source "$IAC_HOMEDIR/gcloud/secret.sh"
source "$IAC_HOMEDIR/gcloud/storage.sh"
source "$IAC_HOMEDIR/gcloud/task.sh"
source "$IAC_HOMEDIR/gcloud/util.sh"

#==============================================================#
##          Options                                           ##
#==============================================================#
shopt -s autocd
shopt -s histappend
shopt -s globstar

# setopt extended_history      # Record start time and elapsed time in history file
# setopt append_history        # Add history (instead of creating .zhistory every time)
# setopt hist_ignore_all_dups  # Delete older command lines if they overlap
# setopt hist_ignore_dups      # Do not add the same command line to history as the previous one
# setopt hist_ignore_space     # Remove command lines beginning with a space from history
# unsetopt hist_verify         # Stop editability once between history invocation and execution
# setopt hist_reduce_blanks    # Extra white space is stuffed and recorded <-teraterm makes history or crazy
# setopt hist_save_no_dups     # Ignore old commands that are the same as old commands when writing to history file.
# setopt hist_no_store         # history commands are not registered in history
# setopt hist_expand           # automatically expand history on completion


# setopt list_packed           # Compactly display completion list
# setopt auto_remove_slash     # Automatically remove trailing / in completions
# setopt auto_param_slash      # Automatically append trailing / in directory name completion to prepare for next completion
# setopt mark_dirs             # Append trailing / to filename expansions when they match a directory
# setopt list_types            # Display file type identifier in list of possible completions (ls -F)
# unsetopt menu_complete       # When completing, instead of displaying a list of possible completions and beeping. Don't insert the first match suddenly.
# setopt auto_list             # Display a list of possible completions with ^I (when there are multiple candidates for completion, display a list)
# setopt auto_menu             # Automatic completion of completion candidates in order by hitting completion key repeatedly
# setopt auto_param_keys       # Automatically completes bracket correspondence, etc.
# setopt auto_resume           # Resume when executing the same command name as a suspended process


# setopt rm_star_wait          # confirm before rm * is executed
# # setopt rm_star_silent        # Don't confirm before executing rm *
# setopt notify                # Notify as soon as background job finishes (don't wait for prompt)

echo ""
echo "[INFO] .bashrc process terminated !!"
echo ""

#==============================================================#
##          Flutter                                           ##
#==============================================================#

# Flutter SDK
export FLUTTER_ROOT=$HOME/flutter
export PATH=$PATH:$FLUTTER_ROOT/bin

# FVM (Flutter Version Management)
export PATH="$PATH:$HOME/.pub-cache/bin"
export FLUTTER_ROOT="$HOME/fvm/default/"
export PATH="$PATH:$FLUTTER_ROOT/bin"
# export FLUTTER_ROOT="$HOME/fvm/versions/3.29.3"
# export PATH="$PATH:$FLUTTER_ROOT/bin"

#==============================================================#
##          Claude Code                                       ##
#==============================================================#

# alias claude="$HOME/.claude/local/claude"
alias claude="/home/nov/.claude/local/claude"

#==============================================================#
##          Docker                                            ##
#==============================================================#

# sudo を .bashrc で実行すると、Cline がシェルを使えなくなるのでコメントアウトしておく。

# dockerグループに現在のユーザーを追加
# sudo usermod -aG docker $USER

# # 変更を反映させるために、以下のコマンドを実行。.bashrcで実行すると無限ループしてしまう
# echo ""
# echo "**Notice** Copy and Paste into Shell the following command: 'newgrp docker'"
# echo ""
