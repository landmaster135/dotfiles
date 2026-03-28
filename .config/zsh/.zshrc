#==============================================================#
##          Base Configuration                                ##
#==============================================================#
source-safe() { if [ -f "$1" ]; then source "$1"; fi }

#==============================================================#
##          Rewrite CachyOS Config                            ##
#==============================================================#
# Default statement
# source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# Oh My Zsh
export ZSH="/usr/share/oh-my-zsh"
DISABLE_MAGIC_FUNCTIONS="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
plugins=(git fzf extract)
source $ZSH/oh-my-zsh.sh

# History settings
HISTSIZE=1000             # Number of histories in memory
SAVEHIST=1000             # Number of histories to be saved
HISTFILE=~/.zsh_history
# KEYTIMEOUT=1 # conflict with zsh-autocomplete

# ignoreboth 相当
setopt HIST_IGNORE_SPACE  # スペース始まりのコマンドを残さない
setopt HIST_IGNORE_DUPS   # 直前と同じコマンドを残さない

setopt HIST_IGNORE_ALL_DUPS  # 過去の重複もまとめて削除（erasedups 相当）
setopt HIST_SAVE_NO_DUPS     # ファイル保存時も重複を除外
setopt INC_APPEND_HISTORY    # PROMPT_COMMAND="history -a" 相当（即時書き込み）

# HISTORY_IGNORE 相当（特定コマンドを履歴に残さない）
zshaddhistory() {
  local line="${1%%$'\n'}"
  [[ ${line} != (bg|fg|c|clear|history|exit|q|pwd|ls|la|ll|head*|tail*|zsh|"cd .."|*--help) ]]
}

# man ページの色付け
export LESS_TERMCAP_md="$(tput bold 2>/dev/null; tput setaf 2 2>/dev/null)"
export LESS_TERMCAP_me="$(tput sgr0 2>/dev/null)"

#==============================================================#
##          Utilities                                         ##
#==============================================================#
export ZSH_HOMEDIR=$HOME/dotfiles-local/.config/zsh
source "$ZSH_HOMEDIR/alias.zsh"
source "$ZSH_HOMEDIR/function.zsh"

#==============================================================#
##        command not found ハンドラ                           ##
#==============================================================#
[[ -f /usr/share/doc/pkgfile/command-not-found.zsh ]] && \
  source /usr/share/doc/pkgfile/command-not-found.zsh

#==============================================================#
##          FZF                                               ##
#==============================================================#
export FZF_BASE=/usr/share/fzf

#==============================================================#
##          Powerlevel10k Instant Prompt                      ##
#==============================================================#
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#==============================================================#
##          Plugin                                            ##
#==============================================================#
# zsh-autocomplete の挙動を調整する設定を先に書く
zstyle ':autocomplete:*' min-input 1        # 1文字入力で候補表示
zstyle ':autocomplete:*' async false         # 非同期を無効化（固まる問題の対策）

source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

#==============================================================#
##          Powerlevel10k Applying                            ##
#==============================================================#
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
