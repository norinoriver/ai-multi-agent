# 要求定義書サマリー
## Multi-Agent Claude Code Development System (MACCDS)

### 1. システム要求概要

本システムは、複数のClaude Codeインスタンスを協調させることで、人間が企画・課題解決に集中できるよう、ソフトウェア開発の実装作業を自動化する汎用フレームワークである。

### 2. 主要要求事項

#### 2.1 チーム構成
- **最小構成**: 10名のClaude Codeインスタンス
- **役割**: Boss/PO（人間との窓口）、PM、エンジニア（フルスタック）、デザイナー、QA、DevOps、アーキテクト、セキュリティ、ビジネスアナリスト
- **共通能力**: 全エンジニアはフロントエンド・バックエンド・インフラの基本実装が可能

#### 2.2 開発方式
- **ブランチ戦略**: git worktreeによる並列開発（競合回避）
- **レビュープロセス**: GitHub MCP経由でPR作成・相互レビュー
- **タスク管理**: 中央管理型、13ポイント以上は自動分割

#### 2.3 通信・協調
- **基盤**: tmuxペイン + send-keys
- **可視化**: tmux複数ペインでのリアルタイムログ監視
- **通知**: 共有ディレクトリベース

#### 2.4 汎用フレームワーク要件
- **初期化**: 設定ファイルベース（デフォルト構成を編集可能）
- **人間とのインターフェース**: Boss/POエージェント経由で一元化
- **開発フロー**: CLAUDE.mdの開発フロー（要求定義→要件定義→概要設計→詳細設計→テスト設計→TDD実装）を組み込み
- **適用範囲**: Web、モバイル、データ分析、インフラ等、あらゆるソフトウェア開発

### 3. 設定ファイル構造

```yaml
# .maccds/agents.yaml
agents:
  boss:
    count: 1
    persona_file: "@/agents/boss/CLAUDE.md"
    skills: ["leadership", "requirement_analysis", "communication"]
    
  pm:
    count: 1
    persona_file: "@/agents/pm/CLAUDE.md"
    skills: ["project_management", "communication"]
  
  engineers:
    count: 5
    persona_file: "@/agents/engineer/CLAUDE.md"
    skills: ["frontend", "backend", "infrastructure"]
    
  # プロジェクトに応じて追加・編集・削除可能
```

### 4. 初期セットアップフロー

```bash
# 1. 既存プロジェクトへの導入
cd /path/to/your/project
git clone https://github.com/[user]/ai-multi-agent.git
echo "ai-multi-agent/" >> .gitignore

# 2. エージェント起動
cd ai-multi-agent
bash start-agents.sh
# → Boss/POエージェントが起動し、人間との対話を開始
```

### 5. 運用シナリオ

1. **人間** → **Boss/POエージェント**: 要求を伝える
2. **Boss/POエージェント**: 要求を整理・分析
3. **Boss** → **人間**: 要求内容の確認・合意形成
4. **Boss** → **PM**: 合意済み要求で開発指示
5. **PM** → **各専門エージェント**: タスク分解依頼
6. **各エージェント**: 専門領域のタスクを詳細分解＋見積もり
7. **各エージェント** → **PM**: タスク詳細と見積もりを回答
8. **PM**: タスク依存関係整理・実行優先順位決定
9. **PM**: 各エージェントへ詳細タスク割り振り
10. **エージェント群**: git worktreeで並列開発
11. **レビュー**: PR経由で相互レビュー
12. **Boss** → **人間**: 進捗報告・成果確認
13. **人間**: 最終確認・マージ

### 6. 期待効果

- **開発速度**: 並列処理により6倍以上の生産性向上
- **品質**: AI同士のレビューによる品質向上
- **人的リソース**: 実装から解放され、より創造的な業務に集中

### 7. 制約事項

- tmuxベースのローカル実行環境
- 最終的なマージは人間が承認
- Claude Code CLIの制限に準拠


---

## 承認

本要求定義書は、複数Claude Codeによる非同期協調開発システムの基本要求を定義したものである。

作成日: 2025-01-06
バージョン: 1.0.0