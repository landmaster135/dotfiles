# memos-postgres-staging バックアップ方針と別PC移行計画

基準変数: `VOLUME_DATA_DIR` (`.env`内にて定義)

## 1. この構成でバックアップすべきデータ

- Memosアプリデータ（添付ファイル等）
  - `${VOLUME_DATA_DIR}/memos-postgres-staging/data`
- PostgreSQLデータディレクトリ
  - `${VOLUME_DATA_DIR}/memos-postgres-staging/db`
- スタック定義
  - `${VOLUME_DATA_DIR}/memos-postgres-staging/stack/`

移行先のDBユーザー名、パスワードもしくはDB名を変える場合、論理バックアップを取る必要があります。いずれも変えない場合、tarボールのみで移行可能です。

## 2. 旧PC: バックアップ取得手順

### 2-1. 論理バックアップ（保険経路。移行先のユーザー名を変える場合も。）

```bash
ROOT_DIR="${VOLUME_DATA_DIR}/memos-postgres-staging"
BACKUP_DIR="$ROOT_DIR/backup"
DUMP_FILE="$BACKUP_DIR/memos_$(date +%F_%H%M%S).dump"
docker exec -i memos-db \
  sh -lc 'pg_dump -U "$POSTGRES_USER" -d memos -Fc' \
  > "$DUMP_FILE"
sudo sha256sum "$DUMP_FILE" | sudo tee "${DUMP_FILE}.sha256" > /dev/null
```

### 2-2. サービス停止（整合性確保）

```bash
STACK_DIR="${VOLUME_DATA_DIR}/memos-postgres-staging/stack"
docker compose --project-directory "$STACK_DIR" --env-file "$STACK_DIR/.env" down
```

### 2-3. 実データ + 設定をアーカイブ（移行先のユーザー名を変えない場合）

```bash
ROOT_DIR="${VOLUME_DATA_DIR}/memos-postgres-staging"
BACKUP_TS=$(date +%F_%H%M%S)
BACKUP_FILE="$ROOT_DIR/memos-postgres-staging-migration-${BACKUP_TS}.tar.gz"

sudo tar czf "$BACKUP_FILE" \
  -C "$ROOT_DIR" \
  data \
  db \
  stack
ls "$ROOT_DIR"

sudo sha256sum "$BACKUP_FILE" | sudo tee "${BACKUP_FILE}.sha256" > /dev/null
```

### 2-4. 旧PCを一旦復帰（必要なら）

```bash
STACK_DIR="${VOLUME_DATA_DIR}/memos-postgres-staging/stack"
docker compose --project-directory "$STACK_DIR" --env-file "$STACK_DIR/.env" up -d
```

## 3. 新PC: 復元・起動手順（移行先のユーザー名を変えない場合）

### 3-1. バックアップ転送

例:

```bash
rsync --archive --verbose --human-readable --partial --progress $ROOT_DIR/memos-postgres-staging-migration-*.tar.gz* <new-pc>:/tmp/
rsync --archive --verbose --human-readable --partial --progress $ROOT_DIR/memos_*.dump* <new-pc>:/tmp/   # 取得した場合
```

### 3-2. チェックサム検証

```bash
sha256sum --check /tmp/memos-postgres-staging-migration-*.tar.gz.sha256
sha256sum --check /tmp/memos_*.dump.sha256   # 取得した場合
```

### 3-3. 展開

```bash
TARGET_ROOT="${VOLUME_DATA_DIR}/memos-postgres-staging"
sudo tar xzf /tmp/memos-postgres-staging-migration-*.tar.gz -C "$TARGET_ROOT"
```

### 3-4. 起動

```bash
STACK_DIR="${VOLUME_DATA_DIR}/memos-postgres-staging/stack"
docker compose --project-directory "$STACK_DIR" --env-file "$STACK_DIR/.env" pull
docker compose --project-directory "$STACK_DIR" --env-file "$STACK_DIR/.env" up -d
```

## 4. 新PC: 復元・起動手順（保険経路。移行先のユーザー名を変える場合も。）

### 4-1. 論理バックアップ(.dump)からのリストア

```bash
STACK_DIR="${VOLUME_DATA_DIR}/memos-postgres-staging/stack"
set -a; source "$STACK_DIR/.env"; set +a

# DBコンテナのみ起動
docker compose --project-directory "$STACK_DIR" --env-file "$STACK_DIR/.env" up -d db

# DBをリストア
cat "/tmp/${DUMP_FILE}" | sudo docker exec -i "$POSTGRES_DB_CONTAINER" pg_restore --clean --if-exists --no-owner --no-privileges \
  -U "$POSTGRES_USER" -d "$POSTGRES_DB"

# Appコンテナを起動
docker compose --project-directory "$STACK_DIR" --env-file "$STACK_DIR/.env" up -d memos-staging
```

## 5. 動作確認チェックリスト

```bash
cd "${VOLUME_DATA_DIR}/memos-postgres-staging/stack"
docker compose --env-file .env ps
docker compose --env-file .env logs --tail=100 db
docker compose --env-file .env logs --tail=100 memos-staging
```

確認観点:

- `db` が `healthy`
- `memos-staging` が再起動ループしていない
- ブラウザで `http://<新PCIP>:5241` にアクセスできる
- 既存メモ・添付ファイルが参照できる

## 5. 失敗時ロールバック

- 移行完了判定まで旧PCを削除しない
- DNS/接続先を旧PCへ戻せる状態で切替する
- 新PC不具合時は旧PCの `stack` で `docker compose --env-file .env up -d` を実行して即時復旧

## 6. 移行後の定期バックアップ運用（推奨）

最低限、次を自動化する。

- 日次: `pg_dump -Fc`（直近14〜30世代を一時保持、各月の初日を永久保持）
- すべてのバックアップに `sha256sum` を作成
- 別ストレージ（別ディスク/別PC/NAS）へ複製

例（crontabイメージ）:

```cron
# 毎日 03:00 論理バックアップ
0 3 * * * /usr/local/bin/memos_pg_dump.sh

# 毎週日曜 04:00 コールドバックアップ
0 4 * * 0 /usr/local/bin/memos_cold_backup.sh
```

---

補足:

- `postgres:18` を利用しているため、将来的にメジャーバージョンを変える際は `pg_upgrade` か dump/restore 手順を別途設計する。
- 今回の「別PCへ同一バージョンで移行」では、上記手順（停止アーカイブ + 論理バックアップ保険）が最も実務的で安全。
