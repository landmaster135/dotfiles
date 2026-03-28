## Small install
**Check** whether the configuration file uses LF break codes.
Execute the following processes if you haven't set up.

### 1. Backup.
```bash
mkdir $HOME/backup
mv $HOME/.bashrc $HOME/.bashrc.bak
```

### 2. Set symbolic link
```bash
ln -s $HOME/dotfiles/.config/bash/.bashrc $HOME
```

### 3. Restart bash.

### 4. Enjoy!
