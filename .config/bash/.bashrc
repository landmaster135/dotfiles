
typeset -U path PATH
path=(
  /opt/homebrew/bin(N-/)
  /opt/homebrew/sbin(N-/)
  /usr/bin
  /usr/sbin
  /bin
  /sbin
  /usr/local/bin(N-/)
  /usr/local/sbin(N-/)
  /Library/Apple/usr/bin
  $HOME/go/bin(N-/)
  $HOME/.go/bin(N-/)
)

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/landmaster/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/landmaster/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/landmaster/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/landmaster/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"


#==============================================================#
##          Base Configuration                                ##
#==============================================================#
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
export PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '
export MY_PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '

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


#--------------------------------------------------------------#
##          Function                                          ##
#--------------------------------------------------------------#
source "$ZRCDIR/function.zsh"

#--------------------------------------------------------------#
##          Aliases                                           ##
#--------------------------------------------------------------#
source "$ZRCDIR/alias.zsh"
