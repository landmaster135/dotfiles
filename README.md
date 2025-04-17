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
**Check** whether the configuration file uses LF break codes.
Execute the following processes if you haven't set up.

1. Backup.
`mkdir $HOME/backup && mv $HOME/.bashrc $HOME/backup`

2. Set symbolic link
`ln -s $HOME/dotfiles/.config/bash/.bashrc $HOME`

3. Restart bash.

4. Enjoy!

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
