# dotfiles プロジェクト概要

## 1. 目的とスコープ

このリポジトリは、開発端末の初期セットアップと日常運用を再現可能にするための `dotfiles` 集合です。  
主な責務は以下です。

- シェル環境（Bash/Zsh）の共通化
- エディタ・ターミナル・Git など開発ツール設定の配布
- OS ごとのパッケージ導入と追加セットアップ
- Google Cloud 操作用シェル関数の提供
- リモートサーバ向け運用スクリプトの管理

## 2. 全体アーキテクチャ

### 2.1 実行フロー

標準の導入フローは次のとおりです。

1. 入口スクリプト `install.sh` がオプション (`--gui`, `--arch`, `--all`) を解釈
2. `install_scripts/dotsinstaller.sh` を呼び出してインストール処理を実行
3. `install_scripts/lib/dotsinstaller/` 配下の機能別スクリプトで処理を分割
4. `link-to-homedir.sh` が `.config` およびルート dotfiles をバックアップ付きでシンボリックリンク化
5. `.bashrc` / `.zshrc` から alias・function・IaC 関数を読み込み、利用環境を有効化

### 2.2 レイヤー構造

本プロジェクトは大きく 4 レイヤーで構成されます。

- Entry Layer
  - `install.sh`
  - `install_scripts/dotsinstaller.sh`
- Setup Module Layer
  - `install_scripts/lib/dotsinstaller/*.sh`
  - 例: `install-basic-packages.sh`, `install-extra.sh`, `install-hyprland.sh`
- Config Asset Layer
  - `.config/` 配下の実設定ファイル群
  - `.linkignore` によりリンク対象外を制御
- Ops/IaC Layer
  - `iac/gcloud/*.sh`（GCP 操作用関数）
  - `install_scripts_v2/*`（サーバ運用・リモート適用系）

### 2.3 設計上の特徴

- バックアップ優先
  - 既存ファイルを `~/.cache/dotbackup/<timestamp>/` に退避してからリンクを作成
- 機能分割
  - パッケージ導入、GUI 設定、フォント設定などをスクリプト分割し、保守単位を明確化
- マルチ環境対応
  - Debian/RedHat/Arch/Alpine を `whichdistro` で判定して分岐
  - Windows 系は `PowerShell` / `batch` スクリプトで補完
- 実運用寄りのシェル拡張
  - alias・function・snippet を集約し、日常運用コマンドを即利用可能にする

## 3. 主要コンポーネント

### 3.1 シェル設定

- Bash
  - `.config/bash/.bashrc` を中心に alias/function/env ローダーを構成
  - `set_env.bash` で `env.yml` 由来の環境変数を読み込み可能
- Zsh
  - `.config/zsh/.zshrc` + `rc/` + `z_key_bind/` で構成
  - 履歴・補完・キーバインドを明示設定

### 3.2 エディタ・開発ツール設定

- VSCode プロファイル
  - `.config/vscode/{cloudshell,debian_crd,windows}/`
- Tmux
  - `.config/tmux/tmux.conf`
- Git
  - `.config/git/gitconfig_shared`
  - インストール時に `git config --global include.path` を設定

### 3.3 インフラ運用関数

- `iac/gcloud/*.sh`
  - `auth`, `project config`, `compute`, `storage`, `dns` などを関数化
- `.bashrc` から一括 `source` し、CLI 補助関数として利用

### 3.4 リモート運用スクリプト

- `install_scripts_v2/apt/post-os-install.sh`
  - APT 更新、Docker、rclone、監視系ツール導入
- `install_scripts_v2/proxmox/*.sh`
  - VM 初期設定やディスク処理補助

## 4. ディレクトリ構成

| パス | 役割 |
| --- | --- |
| `.config/` | 各種設定ファイル本体（bash, zsh, tmux, vscode, git, docker など） |
| `install.sh` | 標準インストールのエントリーポイント |
| `install_scripts/` | ローカル端末向けセットアップ実装 |
| `install_scripts/lib/dotsinstaller/` | セットアップ処理の機能別モジュール |
| `install_scripts_v2/` | リモートサーバ/運用向けスクリプト群 |
| `iac/gcloud/` | GCP 操作用シェル関数ライブラリ |
| `docs/` | プロジェクト文書の正本 |

## 5. 想定ユースケース

### 5.1 新規端末セットアップ

```bash
git clone <repo>
cd dotfiles
./install.sh
```

GUI を含める場合:

```bash
./install.sh --gui
```

### 5.2 リンクのみ再作成

```bash
./install_scripts/dotsinstaller.sh link
```

### 5.3 既存環境の更新

```bash
./install_scripts/dotsinstaller.sh update
```
