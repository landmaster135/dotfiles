# Codex settings
## Instructions
```bash
ln -s ${HOME}/dotfiles/.config/agents/codex/rules/instructions.md ${HOME}/.codex
```

## Default Rules
```bash
mkdir -p ${HOME}/.codex/rules
ln -s ${HOME}/dotfiles/.config/agents/codex/rules/default.rules ${HOME}/.codex/rules
```

## Hooks
```bash
ln -s ${HOME}/dotfiles/.config/agents/codex/hooks/hooks.json ${HOME}/.codex
```

## MCP tools
dotfils にある必要な設定内容のみをホームの設定 TOML に貼り付ける。設定値内のユーザー名も適宜変更する。
```bash
ls ${HOME}/dotfiles/.config/agents/codex/mcp_linux/config.toml
ls ${HOME}/.codex/config.toml
```

## Skills
`./skills/` を参照。
