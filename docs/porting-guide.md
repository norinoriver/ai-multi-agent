# AI Multi-Agent システム移植ガイド

## 他のリポジトリへの移植手順

### 1. ファイルのコピー
```bash
# AI Multi-Agentディレクトリを対象リポジトリにコピー
cp -r /path/to/ai-multi-agent /path/to/your-project/ai-multi-agent
```

### 2. .gitignoreの更新
プロジェクトの`.gitignore`に以下を追加：
```
# AI Multi-Agent generated files
ai-multi-agent/agent_instructions/
ai-multi-agent/brainstorm/
ai-multi-agent/commands/
ai-multi-agent/tasks/
ai-multi-agent/notifications/
ai-multi-agent/queues/
```

### 3. CLAUDE.mdの配置
**重要**: プロジェクトルートにCLAUDE.mdを配置するか、既存のCLAUDE.mdに内容を追加

```bash
# オプション1: プロジェクトルートに配置
cp ai-multi-agent/CLAUDE.md ./CLAUDE.md

# オプション2: 既存のCLAUDE.mdに追加
cat ai-multi-agent/CLAUDE.md >> ./CLAUDE.md
```

### 4. パスの確認
- CLAUDE.md内のパスが `@/agents/` で始まることを確認
- プロジェクト名を含むパスがないことを確認

### 5. スクリプトの実行権限
```bash
chmod +x ai-multi-agent/scripts/*.sh
```

## トラブルシューティング

### Q: エージェントが指示書を読み込めない
A: CLAUDE.md内のパスが相対パス（`@/agents/`）になっているか確認

### Q: tmuxセッションが起動しない
A: tmuxがインストールされているか確認: `brew install tmux`

### Q: スクリプトが動作しない
A: 実行権限があるか確認: `ls -la scripts/`