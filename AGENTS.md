# AGENTS.md

## Prerequisites

- 回答は日本語で行うこと。
- 詳細ルールをこのファイルへ増やさないこと。詳細は `docs/` 側へ追記すること。

## Summary

このファイルは、エージェント向けの入口です。  
実装・設計・運用の詳細ルールは `docs/` 側を正本とします。

- `docs/project_overview/project_overview.md`
  - 全体アーキテクチャとディレクトリ構成の確認

## Quick Decision Trees

### 「タスクに着手したい」

```text
タスクに着手したい
└─ タスクの指示書を確認したい → `.agents/tmp/instructions.md`
```

### 「プロジェクトの状況を確認したい」
```text
プロジェクトの状況を確認したい
├─ 全体のアーキテクチャ/構成を確認したい → docs/project_overview/project_overview.md
└─ 計画（active/completed）を確認したい → docs/exec_plans/index.md
```
