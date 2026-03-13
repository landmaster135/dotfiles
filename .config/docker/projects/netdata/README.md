# Netdataカスタムプラグイン＆アラート設定手順

## 前提

- Netdata v2.9.0 (Docker)

## 1. カスタムプラグインスクリプトの作成

`${VOLUME_DATA_DIR}/netdata/config/custom-plugins.d/` に **`.plugin`** 拡張子でスクリプトを作成する。
下記は、`filesystem_error_monitor.plugin` というファイル名における具体例である。

```bash
mkdir -p ${VOLUME_DATA_DIR}/netdata/config/custom-plugins.d
vim ${VOLUME_DATA_DIR}/netdata/config/custom-plugins.d/filesystem_error_monitor.plugin
```

スクリプトの基本構造（外部プラグイン API）:

```bash
#!/bin/bash
UPDATE_EVERY="${1:-30}"

# チャート定義（起動時に一度だけ出力）
cat <<EOF
CHART custom.filesystem_errors '' 'Filesystem Errors in Kernel Log' 'errors/s' 'filesystem' '' line 900 ${UPDATE_EVERY} '' '' 'filesystem_error_monitor'
DIMENSION ext4_errors 'EXT4 errors' absolute 1 1
EOF

while true; do
  # メトリクスを収集して出力
  echo "BEGIN custom.filesystem_errors"
  echo "SET ext4_errors = 0"
  echo "END"

  sleep "${UPDATE_EVERY}"
done
```

実行権限を付与:

```bash
chmod +x ${VOLUME_DATA_DIR}/netdata/config/custom-plugins.d/filesystem_error_monitor.plugin
```

## 2. netdata.conf にプラグインディレクトリを追加

`${VOLUME_DATA_DIR}/netdata/config/netdata.conf` に以下を追記する。

```ini
[global]
  plugins directory = /usr/libexec/netdata/plugins.d /etc/netdata/custom-plugins.d
```

## 3. アラート設定ファイルの作成

`${VOLUME_DATA_DIR}/netdata/config/health.d/` にアラート設定ファイルを作成する。

```bash
mkdir -p ${VOLUME_DATA_DIR}/netdata/config/health.d
nano ${VOLUME_DATA_DIR}/netdata/config/health.d/filesystem_errors.conf
```

設定例:

```
alarm: ext4_error_detected
  on: custom.filesystem_errors
  lookup: sum -5m unaligned of ext4_errors
  units: errors
  every: 30s
  warn: $this > 0
    crit: $this > 5
    delay: down 10m multiplier 1.5 max 1h
    summary: EXT4 filesystem error detected
    info: EXT4エラーが直近5分間で検知されました（${this}件）
    to: sysadmin
```

## 4. コンテナを再起動

```bash
sudo docker compose restart netdata
```

## 5. 動作確認

### プラグインが起動しているか確認

```bash
sudo docker exec netdata ps aux | grep filesystem
# netdata  XXXX  ... /bin/bash /etc/netdata/custom-plugins.d/filesystem_error_monitor.plugin 1
# のように表示されればOK
```

### チャートが生成されているか確認

```bash
curl -s http://localhost:19999/api/v1/charts | grep custom
```

### アラートが読み込まれているか確認

```bash
curl -s 'http://localhost:19999/api/v1/alarms?all' | python3 -m json.tool | grep filesystem
```

Web UI では **Alerts → Alert Configurations** で確認できる。

## 今後プラグインを追加するとき

`docker-compose.yml` や `netdata.conf` の変更は不要。

1. `.plugin` 拡張子でスクリプトを `custom-plugins.d/` に置く
2. 実行権限を付与: `chmod +x *.plugin`
3. アラートが必要なら `health.d/` に `.conf` ファイルを追加
4. `sudo docker compose restart netdata`

## ハマりポイントまとめ

| 問題 | 原因 | 解決策 |
|---|---|---|
| プラグインが起動しない | 拡張子が `.sh` | `.plugin` に変更する |
| プラグインが起動しない | `custom-plugins.d` がスキャンされていない | `netdata.conf` の `[global] plugins directory` に追記 |
| `[plugins] custom-plugins.d = yes` が効かない | Netdata v2 では未実装 | `[global] plugins directory` を使う |
| アラートが読み込まれない | 参照先チャートが存在しない | プラグインを先に動かす |

## 参考

- [External plugins | Learn Netdata](https://learn.netdata.cloud/docs/developer-and-contributor-corner/external-plugins)
- [Creating custom plugin in non-orchestrated language - Media Center - Netdata Community Forums](https://community.netdata.cloud/t/creating-custom-plugin-in-non-orchestrated-language/1577)
- [Configure Health Alerts | Learn Netdata](https://learn.netdata.cloud/docs/alerts-&-notifications/alert-configuration-reference)
- [Install Netdata with Docker | Learn Netdata](https://learn.netdata.cloud/docs/netdata-agent/installation/docker)
