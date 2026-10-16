#!/usr/bin/env bash

# Git pre-commit hook用のGo製シークレット検知ツールセットアップスクリプト
# ビルド済みバイナリを使用してGitフックを設定

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

function check_requirements() {
  local tool_dir="$1"
  command -v git >/dev/null 2>&1 || {
    echo "❌ Git is required" >&2
    return 1
  }
  if [[ ! -d "$tool_dir" ]] ||
     [[ "$(git -C "$tool_dir" rev-parse --is-inside-work-tree 2>/dev/null)" != true ]]; then
    echo "❌ Not a Git working tree: $tool_dir" >&2
    return 1
  fi
}

function process_for_pre_commit_hook() {
  # local tool_dir="."
  local tool_dir="$1"
  local dir_for_common_hooks
  dir_for_common_hooks=$(git -C "$tool_dir" rev-parse --path-format=absolute --git-path hooks)
  local dir_for_common_pre_commit_hooks="$dir_for_common_hooks/pre-commit"
  local dir_for_git_pre_commit_hooks="$dir_for_common_hooks/git-pre-commit-hooks"
  local file_for_git_pre_commit_hooks="$dir_for_git_pre_commit_hooks/git-pre-commit-hooks"

  # 色付きの出力用
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local BLUE='\033[0;34m'
  local NC='\033[0m'

  echo -e "${BLUE}🔧 Setting up Go-based secret detector for Git hooks...${NC}"

  # ビルド済みバイナリのパス
  local BINARY_PATH="$ROOT_DIR/pkg/bin/cli/linux_amd64/git-pre-commit-hooks"

  # バイナリが存在するかチェック
  if [[ ! -f "$BINARY_PATH" ]]; then
    echo -e "${RED}❌ Binary not found at $BINARY_PATH${NC}" >&2
    echo -e "${YELLOW}Please run '$ROOT_DIR/scripts/build/build_git_pre_commit_hooks.sh' from '$ROOT_DIR' first${NC}" >&2
    exit 1
  fi

  echo -e "${GREEN}✅ Binary found: $BINARY_PATH${NC}"

  # バイナリが実行可能かチェック
  if [[ ! -x "$BINARY_PATH" ]]; then
    echo -e "${YELLOW}⚠️  Making binary executable...${NC}"
    chmod +x "$BINARY_PATH"
  fi

  # ツールディレクトリを作成
  mkdir -p "$dir_for_git_pre_commit_hooks"

  # バイナリをコピー
  echo -e "${YELLOW}📦 Copying binary to Git hooks directory...${NC}"
  cp "$BINARY_PATH" "$file_for_git_pre_commit_hooks"
  chmod +x "$file_for_git_pre_commit_hooks"

  # Pre-commitフックを作成
  if [[ -e "$dir_for_common_pre_commit_hooks" || -L "$dir_for_common_pre_commit_hooks" ]]; then
    local backup_path
    backup_path=$(mktemp "$dir_for_common_pre_commit_hooks.backup.XXXXXXXX")
    cp -p -- "$dir_for_common_pre_commit_hooks" "$backup_path"
    echo "Existing hook backed up to: $backup_path"
  fi
  echo -e "${YELLOW}🔗 Creating pre-commit hook...${NC}"

  cat > "$dir_for_common_pre_commit_hooks" << 'EOF'
#!/bin/bash

# Execute the secret detector tool implemented with Go
TOOL_PATH="$(dirname "$0")/git-pre-commit-hooks/git-pre-commit-hooks"

if [ -x "$TOOL_PATH" ]; then
  "$TOOL_PATH"
else
  echo "❌ Secret detector tool not found at $TOOL_PATH"
  echo "Please run the setup script again."
  exit 1
fi
EOF

  # 実行権限を付与
  chmod +x "$dir_for_common_pre_commit_hooks"

  echo -e "${GREEN}✅ Setup completed successfully!${NC}"
  echo ""
  echo -e "${BLUE}📝 Usage:${NC}"
  echo "  • The pre-commit hook will automatically run on 'git commit'"
  echo "  • To bypass the check: git commit --no-verify"
  echo "  • To test manually: $file_for_git_pre_commit_hooks"
  echo ""

  # テスト実行
  echo -e "${YELLOW}🧪 Testing the tool...${NC}"
  if "$file_for_git_pre_commit_hooks" --version; then
    echo -e "${GREEN}✅ Tool is working correctly${NC}"
  else
    echo -e "${YELLOW}⚠️  Tool test completed (may show 'no staged files' message)${NC}"
  fi

  echo ""
  echo -e "${GREEN}🎉 Secret detector is now active for this repository!${NC}"
  echo ""
  echo -e "${BLUE}📋 What was installed:${NC}"
  echo "  • Binary: $file_for_git_pre_commit_hooks"
  echo "  • Hook: $dir_for_common_pre_commit_hooks"
  echo ""
  echo -e "${BLUE}🔧 To update the tool:${NC}"
  echo "  1. Run from $ROOT_DIR: ./scripts/build/build_git_pre_commit_hooks.sh"
  echo "  2. Run: $SCRIPT_DIR/setup-git-pre-commit-hooks.sh \"$tool_dir\""
  echo ""
  echo -e "${BLUE}🗑️  To remove the hook:${NC}"
  echo "  • Delete: $dir_for_common_pre_commit_hooks"
  echo "  • Delete: $dir_for_git_pre_commit_hooks/"
}


function show_help() {
  local FUNC="${FUNCNAME[0]}"
  cat <<EOF
[INFO] [$FUNC] Git pre-commit hook用の処理を行います。

使用方法:
  $SCRIPT_DIR/setup-git-pre-commit-hooks.sh <TARGET_REPOSITORY>

例:
  ./scripts/initialize/setup-git-pre-commit-hooks.sh '/home/user/my_project'

--help を指定するとこのメッセージを表示します。
実行ディレクトリに依存せず、指定先の Git hooks ディレクトリに設定します。
既存の pre-commit はバックアップしてから置き換えます。
EOF
}

# === 実行部 ===
function main() {
  local FUNC="${FUNCNAME[0]}"

  if [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
  fi

  if [[ $# -ne 1 || -z "$1" ]]; then
    show_help >&2
    return 1
  fi
  local tool_dir="$1"

  check_requirements "$tool_dir"
  process_for_pre_commit_hook "$tool_dir"
}

main "$@"
