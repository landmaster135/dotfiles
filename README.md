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
Check whether the configuration file uses LF break codes.
```bash
# Only aliases and functions.
export ZHOMEDIR=$HOME/dotfiles/.config/zsh
export ZRCDIR=$ZHOMEDIR
export BASHHOMEDIR=$HOME/dotfiles/.config/bash
source "$BASHHOMEDIR/alias.bash"
source "$BASHHOMEDIR/function.bash"
source "$BASHHOMEDIR/extract_blog_articles.bash"
export DOTFILE_HOMEDIR=$HOME/dotfiles
source "$BASHHOMEDIR/set_env.bash" "$DOTFILE_HOMEDIR/env.yml"

export PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '
export MY_PS1='$(_append_history_line)\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(_current_branch)\[\033[00m\]\[\033[01;35m\]\$\[\033[00m\] '

HISTCONTROL=erasedups

# Install IaC functions
export IACHOMEDIR=$HOME/dotfiles/iac
source "$IACHOMEDIR/gcloud/init.sh"
source "$IACHOMEDIR/gcloud/bigquery.sh"
source "$IACHOMEDIR/gcloud/billing.sh"
source "$IACHOMEDIR/gcloud/compute.sh"
source "$IACHOMEDIR/gcloud/container.sh"
source "$IACHOMEDIR/gcloud/db.sh"
source "$IACHOMEDIR/gcloud/deployment.sh"
source "$IACHOMEDIR/gcloud/dns.sh"
source "$IACHOMEDIR/gcloud/iam.sh"
source "$IACHOMEDIR/gcloud/logging.sh"
source "$IACHOMEDIR/gcloud/monitoring.sh"
source "$IACHOMEDIR/gcloud/scheduler.sh"
source "$IACHOMEDIR/gcloud/secret.sh"
source "$IACHOMEDIR/gcloud/storage.sh"
source "$IACHOMEDIR/gcloud/task.sh"
source "$IACHOMEDIR/gcloud/util.sh"
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
