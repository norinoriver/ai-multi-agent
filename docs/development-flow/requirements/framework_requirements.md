# 汎用フレームワーク化要求仕様
## Multi-Agent Claude Code Development System (MACCDS)

### 1. フレームワーク概要

MACCDSは、複数のClaude Codeインスタンスを協調させてソフトウェア開発を行う汎用フレームワークである。
**「課題解決のための手段としてのソフトウェア開発」**を効率化することを目的とする。

### 2. 設計原則

#### 2.1 汎用性
- あらゆる種類のソフトウェア開発プロジェクトに適用可能
  - Webアプリケーション
  - モバイルアプリ
  - データ分析
  - インフラ構築
  - その他、必要に応じて拡張

#### 2.2 シンプルな設定
- プロジェクトごとの設定は最小限に
- デフォルト設定で即座に開始可能
- 必要に応じて詳細なカスタマイズが可能

### 3. カスタマイズ要件

#### 3.1 エージェント構成
```yaml
# config/agents.yaml の例
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
    
  # プロジェクトに応じて追加
  data_scientist:
    count: 2
    persona_file: "@/agents/data_scientist/CLAUDE.md"
    skills: ["python", "machine_learning", "statistics"]
```

各エージェントのCLAUDE.mdファイルには以下を記載：
- 作業手順
- ペルソナ（性格・判断基準）
- スキルセット
- コミュニケーションスタイル
- その他、エージェント固有の振る舞い

#### 3.2 技術スタック対応
- **動的ペルソナ生成機能**
  1. プロジェクトで使用する技術スタックを分析
  2. 必要なスキルセットを自動抽出
  3. 適切なペルソナを自動生成または提案
  
例：
- React + Node.js → フロントエンドとバックエンドに特化したペルソナを生成
- Python + TensorFlow → データサイエンス特化のペルソナを生成

#### 3.3 開発プロセス
- **ハイブリッドアプローチ**
  - 機能単位：ウォーターフォール型（要件定義→設計→実装→テスト→リリース）
  - 全体プロセス：アジャイル型（小さな機能を短期間で繰り返しリリース）
  - 「小さく出す」ことでリスクを最小化し、早期フィードバックを獲得
  - 各機能の完成度を保ちながら、全体として反復的に価値を提供

### 4. 品質管理

#### 4.1 コーディング規約
- CI/CDパイプラインに統合
- プロジェクトごとの`.eslintrc`、`.prettierrc`等を自動認識
- テスト実行時に自動的にリント・フォーマットチェック

#### 4.2 テスト戦略
**明確化：テストポリシーとは**
- カバレッジ目標（例：80%以上）
- テストレベル（単体/統合/E2E）の実行基準
- テスト失敗時の対応方針

プロジェクトごとに以下を設定可能：
```yaml
test_policy:
  coverage_threshold: 80
  required_tests:
    - unit
    - integration
  fail_strategy: "block_merge"  # or "warning_only"
```

#### 4.3 タスク管理とエラー処理
- タスク状態の自動保存（定期的なスナップショット）
- エラー発生時の自動バックアップ
- 未完了タスクの永続化
- エージェント再起動時のタスク復旧機能

### 5. 拡張機能

#### 5.1 エージェントタイプ拡張
**明確化：カスタムエージェントとは**
- デフォルトで提供される役割（PM、エンジニア等）以外に、プロジェクト固有の役割を追加できる機能

例：
- ゲーム開発：「ゲームデザイナー」エージェント
- 医療系：「医療規制コンプライアンス」エージェント
- 金融系：「金融規制対応」エージェント

#### 5.2 外部連携
- MCP server設定済みのツールは全て利用可能
- 追加の連携は設定ファイルで指定


### 6. 初期化とセットアップ

#### 6.1 セットアップと起動
```bash
# 既存プロジェクトでの使用
cd /path/to/your/project
git clone https://github.com/[user]/ai-multi-agent.git
echo "ai-multi-agent/" >> .gitignore

# エージェント起動
cd ai-multi-agent
bash start-agents.sh

# エージェント停止
bash stop-agents.sh
```

#### 6.2 ディレクトリ構造（シンプル版）
```
your-project/
├── ai-multi-agent/              
│   ├── agents/          # エージェントペルソナ定義
│   │   ├── boss/
│   │   │   └── CLAUDE.md
│   │   ├── pm/
│   │   │   └── CLAUDE.md
│   │   └── engineer/
│   │       └── CLAUDE.md
│   ├── start-agents.sh  # tmux起動スクリプト
│   └── stop-agents.sh   # tmux停止スクリプト
├── src/                 # あなたのプロジェクトコード
└── .gitignore          # ai-multi-agent/を除外
```

#### 6.3 起動スクリプト例（start-agents.sh）
```bash
#!/bin/bash
# tmuxセッションを作成
tmux new-session -d -s ai-multi-agent

# Boss/POエージェント起動
tmux send-keys -t ai-multi-agent:0 "claude --profile agents/boss/CLAUDE.md" C-m

# 新しいペインでPMエージェント
tmux split-window -h -t ai-multi-agent:0
tmux send-keys -t ai-multi-agent:0.1 "claude --profile agents/pm/CLAUDE.md" C-m

# エンジニアエージェント（複数）
for i in {1..5}; do
  tmux new-window -t ai-multi-agent:$i
  tmux send-keys -t ai-multi-agent:$i "claude --profile agents/engineer/CLAUDE.md" C-m
done

# セッションにアタッチ
tmux attach-session -t ai-multi-agent
```

#### 6.4 停止スクリプト例（stop-agents.sh）
```bash
#!/bin/bash
# tmuxセッションを停止
tmux kill-session -t ai-multi-agent

echo "AI Multi-Agent system stopped."
```

### 7. 配布とメンテナンス

#### 7.1 配布方法
- GitHubでオープンソース公開（ai-multi-agent）
- MITライセンス（または選択可能）
- `git clone`で即座に利用開始可能

#### 7.2 アップデート
フレームワークの更新は`git pull`で実行

