## 概要
AI Multi-Agentシステムを他のプロジェクトのサブディレクトリとして配置できるように改善しました。

## 変更内容

### 1. 🆕 setup-as-subdirectory.sh スクリプトの追加
- プロジェクトルートにCLAUDE.mdを自動作成
- .gitignoreへのai-multi-agent除外設定を自動追加
- 必要なディレクトリの自動作成
- スクリプトファイルの実行権限設定

### 2. 📝 各エージェント指示書の更新
- AI_MULTI_AGENT_DIRの動的検出機能を追加
- すべてのスクリプトパスを相対パスから動的パスに変更
- boss/engineer/designer/marketerすべてに対応

### 3. 🔧 通知システムv2への完全移行
- notification-watcher-v2.shとsend-notification-v2.shを実装
- ディレクトリベース通知システム（notifications/pending/）に移行
- デザイナーの完了通知を特に強化（スクリプト実行必須として明記）

## 使用方法

### サブディレクトリとして配置する場合
```bash
# 1. ai-multi-agentをproject/ai-multi-agentに配置
# 2. setupスクリプトを実行
cd project/ai-multi-agent
./setup-as-subdirectory.sh

# 3. プロジェクトルートでClaude Codeを起動
cd ../
claude --dangerously-skip-permissions
```

### 動的パス検出の仕組み
```bash
# 各エージェントの指示書で以下のコードが自動的にAI Multi-Agentのパスを検出
AI_MULTI_AGENT_DIR=$(find $(pwd) -name "ai-multi-agent-dashboard.sh" 2>/dev/null | head -1 | xargs dirname | xargs dirname)
```

## テスト項目
- [x] setup-as-subdirectory.shの動作確認
- [x] 各エージェントからの通知送信
- [x] ボスからの指示送信
- [x] 通知システムv2の動作確認

## 関連Issue
なし

🤖 Generated with [Claude Code](https://claude.ai/code)