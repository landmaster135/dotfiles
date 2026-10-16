# SeaweedFS stack

## Troubleshooting: WebUI ではあるけど、ls で出ない
**この問題は解決できませんでした。もしかしたら、未知の解決方法があるかもしれません。**

`ls` で見えない原因は、`mount` コンテナ内でマウントされているだけでホストには反映されていないからです。`propagation: shared` が効いていない可能性があります。

ホスト側で確認してください。
```bash
mount | grep seaweed
```

マウントが見えない場合は、ホスト側の `/etc/fuse.conf` に `user_allow_other` が必要です。
```bash
echo "user_allow_other" | sudo tee -a /etc/fuse.conf
```

そして compose の mount コマンドに `-allowOthers` を追加します。
```yaml
    command: 'mount -filer="filer:8888" -dir=/mnt/seaweed -filer.path=/ -volumeServerAccess=filerProxy -allowOthers'
```

その後コンテナを再起動して確認してください。
```bash
docker compose restart mount
ls ${VOLUME_DATA_DIR}/seaweedfs/data/mount/
```

### それでも出ない場合: その1
`propagation: shared` がホスト側で効くには、ホスト側のマウントポイント自体が `shared` である必要があります。

ホスト側で確認してください。
```bash
findmnt ${VOLUME_DATA_DIR}/seaweedfs/data/mount
```

もしくは親ディレクトリが `shared` かどうか確認します。
```bash
findmnt -o TARGET,PROPAGATION ${VOLUME_DATA_DIR}
```

`private` と出ている場合は以下で `shared` に変更してください。
```bash
sudo mount --make-shared ${VOLUME_DATA_DIR}
```

その後コンテナを再起動して確認してください。
```bash
docker compose restart mount
mount | grep seaweed
```

`findmnt` で何も出ていないということは、`/mnt/hdd02` 自体が独立したマウントポイントとして認識されていない可能性があります。
下記の 1 および 2 の結果を教えてください。
```bash
# 1
findmnt /mnt/hdd02

# 2
findmnt -o TARGET,PROPAGATION /mnt
```

`/mnt/hdd02` は `private` マウントになっています（`PROPAGATION` が表示されていないのは `private` のためです）。
以下を実行してください。
```bash
sudo mount --make-shared /mnt/hdd02
```

確認します。
```bash
findmnt -o TARGET,PROPAGATION /mnt/hdd02
```

`shared` と出たらコンテナを再起動してください。
```bash
docker compose restart mount
mount | grep seaweed
```

### それでも出ない場合: その2
`shared` になっています。ではコンテナを再作成してください。`restart` ではなく `up` で再作成が必要です。
```bash
docker compose up -d --force-recreate mount
```

その後確認してください。
```bash
mount | grep seaweed
ls ${VOLUME_DATA_DIR}/seaweedfs/data/mount/
```

### 結局実装できなかった
はぁ・・・
