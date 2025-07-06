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
  pm:
    count: 1
    persona: "project_manager"
    skills: ["project_management", "communication"]
  
  engineers:
    count: 5
    persona: "fullstack_engineer"
    skills: ["frontend", "backend", "infrastructure"]
    
  # プロジェクトに応じて追加
  data_scientist:
    count: 2
    persona: "data_analyst"
    skills: ["python", "machine_learning", "statistics"]
```

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
  - 初期開発：ウォーターフォール型（要件定義→設計→実装→テスト）
  - MVP達成後：アジャイル型（スプリント単位での改善）
  - 設定で切り替え可能

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

#### 5.3 ワークフロー定義
**明確化：プロジェクト固有のワークフローとは**
- タスクの承認フロー
- レビュープロセスのカスタマイズ
- デプロイメント手順

例：
```yaml
workflow:
  review_process:
    min_reviewers: 2
    auto_merge: false
    require_tests_pass: true
  
  deployment:
    stages: ["dev", "staging", "production"]
    approval_required: ["staging", "production"]
```

### 6. 初期化とセットアップ

#### 6.1 CLIツール
```bash
# インストール
git clone https://github.com/[user]/maccds.git
cd maccds
./install.sh

# 新規プロジェクト作成
maccds init my-project

# エージェント起動
maccds start

# ステータス確認
maccds status

# エージェント追加
maccds add-agent --type engineer --count 2
```

#### 6.2 設定ファイル構造
```
my-project/
├── .maccds/
│   ├── config.yaml      # 基本設定
│   ├── agents.yaml      # エージェント構成
│   ├── workflow.yaml    # ワークフロー定義
│   └── personas/        # カスタムペルソナ定義
├── src/
└── README.md
```

### 7. 配布とメンテナンス

#### 7.1 配布方法
- GitHubでオープンソース公開
- MITライセンス（または選択可能）
- `git clone`で即座に利用開始可能

#### 7.2 アップデート
```bash
maccds update  # フレームワーク本体の更新
```

### 8. P2P分散開発への拡張性

将来的な拡張として、ローカルtmuxベースから以下への発展を考慮：
- 複数マシン間でのエージェント分散
- セキュアな通信プロトコル
- 分散タスクキュー

ただし、現バージョンはローカル環境での動作に焦点を当てる。