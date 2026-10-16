## Small install
**Check** whether the configuration file uses LF break codes.
Execute the following processes if you haven't set up.

### 1. Backup
```zsh
mkdir $HOME/backup
mv $HOME/.p10k.zsh $HOME/.p10k.zsh.bak
mv $HOME/.zshrc $HOME/.zshrc.bak
```

### 2. Set symbolic link
```zsh
ln -s $HOME/dotfiles/.config/zsh/rc/.p10k.zsh $HOME
ln -s $HOME/dotfiles/.config/zsh/.zshrc $HOME
```

### 3. Restart zsh
or change shell to zsh
```zsh
chsh -s $(which zsh)
```

### 4. Enjoy!
