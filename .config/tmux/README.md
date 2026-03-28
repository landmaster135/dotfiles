## Small install
**Check** whether the configuration file uses LF break codes.
Execute the following processes if you haven't set up.

### 1. Backup
```zsh
mkdir -p $HOME/.config/tmux
mv $HOME/.config/tmux/tmux.conf $HOME/.config/tmux/tmux.conf.bak
```

### 2. Set symbolic link
```zsh
ln -s $HOME/dotfiles/.config/tmux/tmux.conf $HOME/.config/tmux/tmux.conf
```

### 3. Restart tmux

### 4. Enjoy!
