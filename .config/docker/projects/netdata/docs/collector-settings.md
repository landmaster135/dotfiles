# コレクター設定

## コレクターのアクティブ化/非アクティブ化
`../set-collector.sh`にあるようなコマンドを実行することで、コレクターの非アクティブ化を設定可能。

`echo "enabled: yes"`で再びアクティブ化することが可能。
e.g.:
```bash
echo "enabled: yes" > ${VOLUME_DATA_DIR}/netdata/config/go.d/vsphere.conf
```
