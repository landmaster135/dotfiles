#!/usr/bin/env bash
# Usage: rclone_ops.sh [options] <operation> [target-dir | date-prefix]
#   operation:  init | dryrun | run | check | grep | tail | ls
#   -t <n>  --transfers の値 (デフォルト: 4)
#   -m <n>  --multi-thread-streams の値 (デフォルト: 4)
#   -c <n>  --checkers の値 (デフォルト: 8)
set -euo pipefail

# ── デフォルト値 ─────────────────────────────────────────
TRANSFERS=4
MULTI_THREAD_STREAMS=4
CHECKERS=8

# ── オプション解析 ────────────────────────────────────────
while getopts ":t:m:c:" opt; do
  case "${opt}" in
    t) TRANSFERS="${OPTARG}" ;;
    m) MULTI_THREAD_STREAMS="${OPTARG}" ;;
    c) CHECKERS="${OPTARG}" ;;
    :) echo "Error: -${OPTARG} には値が必要です" >&2; exit 1 ;;
    \?) echo "Error: 不明なオプション: -${OPTARG}" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

# ── 設定 ────────────────────────────────────────────────
OPERATION="${1:-}"
TARGET_DIR="${2:-}"
SRC_BASE="/mnt/hdd11/nas_volume"
DST_BASE="/mnt/hdd01/nas_volume"
SRC="${SRC_BASE}/${TARGET_DIR}"
DST="${DST_BASE}/${TARGET_DIR}"
LOG_FILE="rclone.log"
RCLONE_COMMON_OPTS=(
  --progress
  --checksum
  --log-file="${LOG_FILE}"
  -v
  --transfers="${TRANSFERS}"
  --multi-thread-streams="${MULTI_THREAD_STREAMS}"
)
# ────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $0 [options] <operation> [target-dir | date-prefix]

Options:
  -t <n>  --transfers の値 (デフォルト: 4)
  -m <n>  --multi-thread-streams の値 (デフォルト: 4)
  -c <n>  --checkers の値 (デフォルト: 8)

Operations:
  init    コピー先ディレクトリの作成・権限設定
  dryrun  ドライラン (rclone copy --dry-run)
  run     本番コピー (rclone copy) + chown/chmod
  check   整合性確認 (rclone check --one-way)
  grep    ログから ERROR/NOTICE を抽出
  tail    ログ末尾 10 行を表示
  ls      SRC_BASE と DST_BASE の内容を表示

target-dir: 対象ディレクトリ名 ※ init/dryrun/run/check は必須
           ※ grep/tail/ls には不要

grep の date-prefix:
  ログ行の先頭タイムスタンプに対する絞り込み文字列
  例: "2026/03/10 07:"  → 特定の時刻帯
      "2026/03/10"      → その日すべて
  省略すると日時フィルタなしで全件抽出

Example:
  $0 init 841_VIDEO
  $0 dryrun 841_VIDEO
  $0 -t 8 -m 8 dryrun 841_VIDEO
  $0 -t 8 -c 16 run 841_VIDEO
  $0 -t 8 -m 8 -c 16 check 841_VIDEO
  $0 check 841_VIDEO
  $0 grep "2026/03/10 07:"
  $0 grep "2026/03/10"
  $0 grep
  $0 tail
  $0 ls
EOF
  exit 1
}

op_init() {
  echo "==> [init] ディレクトリ作成・権限設定: ${DST}"
  sudo mkdir -p "${DST}"
  sudo chown -R 1000:1000 "${DST}"
  sudo find "${DST}" -type d -exec chmod 755 {} +
  echo "Done: init"
}

op_dryrun() {
  echo "==> [dryrun] ドライラン: ${SRC} → ${DST}"
  echo "    transfers=${TRANSFERS}, checkers=${CHECKERS}, multi-thread-streams=${MULTI_THREAD_STREAMS}"
  rclone copy "${SRC}" "${DST}" \
    "${RCLONE_COMMON_OPTS[@]}" \
    --dry-run
  echo "Done: dryrun"
}

op_run() {
  echo "==> [run] 本番コピー: ${SRC} → ${DST}"
  echo "    transfers=${TRANSFERS}, checkers=${CHECKERS}, multi-thread-streams=${MULTI_THREAD_STREAMS}"
  rclone copy "${SRC}" "${DST}" \
    "${RCLONE_COMMON_OPTS[@]}"
  echo ""
  echo "==> [run] chown -R 1000:1000 ${DST}"
  sudo chown -R 1000:1000 "${DST}"
  echo ""
  echo "==> [run] chmod 755 (ディレクトリ): ${DST}"
  sudo find "${DST}" -type d -exec chmod 755 {} +
  echo "Done: run"
}

op_check() {
  echo "==> [check] 整合性確認: ${SRC} → ${DST}"
  echo "    transfers=${TRANSFERS}, checkers=${CHECKERS}, multi-thread-streams=${MULTI_THREAD_STREAMS}"
  rclone check "${SRC}" "${DST}" \
    --one-way \
    --transfers "${TRANSFERS}" \
    --checkers "${CHECKERS}" \
    --multi-thread-streams "${MULTI_THREAD_STREAMS}" \
    --progress
  echo "Done: check"
}

op_grep() {
  local date_prefix="${1:-}"
  if [[ -n "${date_prefix}" ]]; then
    echo "==> [grep] ERROR/NOTICE 抽出 (${LOG_FILE}, フィルタ: \"${date_prefix}\")"
    grep -E "ERROR|NOTICE" "${LOG_FILE}" \
      | grep -v "dry-run is set" \
      | grep "${date_prefix}" \
      || echo "(該当行なし)"
  else
    echo "==> [grep] ERROR/NOTICE 抽出 (${LOG_FILE}, 日時フィルタなし)"
    grep -E "ERROR|NOTICE" "${LOG_FILE}" \
      | grep -v "dry-run is set" \
      || echo "(該当行なし)"
  fi
}

op_tail() {
  echo "==> [tail] ログ末尾 10 行 (${LOG_FILE})"
  tail -n 10 "${LOG_FILE}"
}

op_ls() {
  echo "==> [ls] SRC_BASE: ${SRC_BASE}"
  ls -a "${SRC_BASE}" --color=auto
  echo ""
  echo "==> [ls] DST_BASE: ${DST_BASE}"
  ls -a "${DST_BASE}" --color=auto
}

# ── エントリポイント ──────────────────────────────────────
if [[ -z "${OPERATION}" ]]; then
  usage
fi

# target-dir が必要な operation では第2引数を必須チェック
case "${OPERATION}" in
  init|dryrun|run|check)
    if [[ -z "${TARGET_DIR}" ]]; then
      echo "Error: target-dir が指定されていません" >&2
      usage
    fi
    ;;
esac

case "${OPERATION}" in
  init)   op_init              ;;
  dryrun) op_dryrun            ;;
  run)    op_run               ;;
  check)  op_check             ;;
  grep)   op_grep "${2:-}"     ;;
  tail)   op_tail              ;;
  ls)     op_ls                ;;
  *)
    echo "Error: 不明な operation: '${OPERATION}'" >&2
    usage
    ;;
esac
