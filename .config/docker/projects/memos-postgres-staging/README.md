# Memos Postgres

# Troubleshooting

## DockerをHDDマウント後に起動させる
VM再起動後にDockerが起動しない場合、以下のような手順で対応できます。

```bash
sudo systemctl edit docker
```

以下を追加：

```ini
[Unit]
After=mnt-hdd01.mount
Requires=mnt-hdd01.mount
```

保存後：

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

これでHDDのマウントが完了してからDockerが起動するようになります。`/mnt/hdd02`なども使っている場合は同様に追加してください。

ファイルが作られていない場合、直接ファイルを作成しましょう：

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo nano /etc/systemd/system/docker.service.d/override.conf
```

以下を入力：

```ini
[Unit]
After=mnt-hdd01.mount
Requires=mnt-hdd01.mount
```

保存後：

```bash
sudo systemctl daemon-reload
```

確認：

```bash
cat /etc/systemd/system/docker.service.d/override.conf
```
