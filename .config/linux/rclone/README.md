# Rclone

## 初期設定 (非推奨)

**`/home/nov/dotfiles/.config/rclone/rclone.conf`を使った設定は意味がありません。**

`[rclone]` セクション自体がグローバルフラグには効かず、`rclone config show` はファイルの内容を表示するだけで、実際には読み込まれていません。下記のようにシンボリックリンクで設定を配布しても意味がありません。

### Sudo実行用の準備
シンボリックリンクを作成して、root実行でも初期設定が反映されるようにする。
```bash
sudo ln -s ~/.config/rclone/rclone.conf /root/.config/rclone/rclone.conf
```

## 初期設定 (推奨)
環境変数で設定するのが唯一の確実な方法です。 (本来はconfファイルで設定した方が設定値を管理しやすいですが、ちゃんと動かないので仕方ありません・・・。)
root権限で実行する場合には`/etc/profile.d/rclone.sh`で設定しておく必要があります。しかし、設定の管理が面倒なので、root権限が不要であれば`~/.bashrc`に設定を書いておいた方が便利かもしれません。 (結局のところ、この設定が最善ですが使いづらいですね。)

```bash
sudo tee /etc/profile.d/rclone.sh << 'EOF'
export RCLONE_CHECKERS=1
export RCLONE_TRANSFERS=1
export RCLONE_MULTI_THREAD_STREAMS=1
export RCLONE_BUFFER_SIZE=16M
export RCLONE_RETRIES=3
export RCLONE_CHECKSUM=true
export RCLONE_LOG_LEVEL=INFO
EOF
```
