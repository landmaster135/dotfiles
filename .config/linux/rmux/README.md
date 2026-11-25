# RMUX
rmux に反映される設定ファイルのパスは、 `/etc/rmux.conf`, `~/.rmux.conf`, `$XDG_CONFIG_HOME/rmux/rmux.conf`, `~/.config/rmux/rmux.conf` である。
それらのパスで設定ファイルが見つからない場合、 tmux 用の設定ファイル (`/etc/tmux.conf`, `~/.tmux.conf`, `$XDG_CONFIG_HOME/tmux/tmux.conf`, `/.config/tmux/tmux.conf`) がフォールバックとして適用される。
