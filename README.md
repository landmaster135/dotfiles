# dotfiles
dotfiles

[![total lines](https://tokei.rs/b1/github/landmaster135/dotfiles)](https://github.com/XAMPPRocky/tokei)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/landmaster135/dotfiles)
![GitHub repo size](https://img.shields.io/github/repo-size/landmaster135/dotfiles)

## Install

1. Download

```bash
git clone https://github.com/landmaster135/dotfiles.git
cd dotfiles
```

2. Install

```bash
./install.sh
```

or with GUI(Hyprland/i3/sway setup)

```bash
./install.sh --gui
```

3. zsh plugin install

```bash
exec zsh
```

4. Enjoy!

## Small install
Only aliases and functions. (LF break code)
```bash
export ZHOMEDIR=$HOME/dotfiles/.config/zsh
export ZRCDIR=$ZHOMEDIR/rc
source "$ZRCDIR/alias.zsh"
source "$ZRCDIR/function.zsh"

export PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '
export MY_PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '

HISTCONTROL=erasedups

```

## WSL
Only aliases and functions. (LF break code)
```bash
export ZHOMEDIR=$HOME/dotfiles/.config/zsh
export ZRCDIR=$ZHOMEDIR
export WSLHOMEDIR=$HOME/dotfiles/.config/wsl
source "$WSLHOMEDIR/alias.bash"
source "$WSLHOMEDIR/function.bash"

export PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '
export MY_PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '

HISTCONTROL=erasedups

```

## Snippet
Show snippets with the following shell command.
```bash
# snippet
snippet --help
# alias
alias

```

## License
MIT License
