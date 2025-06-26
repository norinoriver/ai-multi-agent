# AI Multi-Agent Development System 設定ガイド

このドキュメントは、Claude Codeを使って複数のAIエージェントによる並列開発を行うための設定ガイドです。

## システム概要

複数のClaude Codeセッションを異なる役割（エンジニア、デザイナー、マーケター、ボス）として起動し、チーム開発をシミュレートします。

## 初期セットアップ

新しいプロジェクトでこのシステムを使用する場合、以下のコマンドを実行してください：

```bash
# 1. 必要なディレクトリ構造を作成
mkdir -p agents/{engineer,designer,marketer,boss} scripts docs worktrees reports templates tasks

# 2. 管理スクリプトをダウンロード（またはコピー）
# ※ 以下のスクリプトファイルが必要です：
# - scripts/start-agents.sh
# - scripts/agent-task.sh
# - scripts/worktree-manager.sh
# - scripts/config.sh

# 3. スクリプトに実行権限を付与
chmod +x scripts/*.sh

# 4. ファイルディスクリプタ上限を設定
ulimit -n 4096
```

## 役割定義

### ボス（プロダクトオーナー）
- プロジェクト全体の管理
- 要件定義と仕様承認
- コードレビューとマージ判断
- 他エージェントへのタスク割り当て

### エンジニア
- フロントエンド/バックエンド実装
- TDD（テスト駆動開発）の実践
- 技術的な設計と実装

### デザイナー
- UI/UX設計
- ワイヤーフレームとプロトタイプ作成
- デザインシステムの構築

### マーケター
- コンテンツ作成
- SEO最適化
- ユーザー体験の設計

## 基本的な使い方

### 1. エージェントの起動

```bash
# 全エージェントを起動（各1セッション）
./scripts/start-agents.sh

# 特定のエージェントを複数起動
./scripts/start-agents.sh engineer 3
./scripts/start-agents.sh designer 2
```

**エージェント起動時の自動設定**：
- 各エージェントは起動時に専用の`CLAUDE.md`を自動読み込み
- 役割に応じた環境変数を設定
- 必要なコマンドとガイドラインを表示

### 2. 各エージェントの専用指示書

各エージェントディレクトリには専用の`CLAUDE.md`があります：

- `agents/boss/CLAUDE.md` - プロダクトオーナー向け指示
- `agents/engineer/CLAUDE.md` - エンジニア向け指示
- `agents/designer/CLAUDE.md` - デザイナー向け指示
- `agents/marketer/CLAUDE.md` - マーケター向け指示

これらの指示書には、各役割に特化した：
- 具体的な作業手順
- 使用するツールとコマンド
- 品質基準とチェックリスト
- 他エージェントとの連携方法
- レポート作成方法

### 3. タスクの管理

```bash
# タスクの作成
./scripts/agent-task.sh create engineer "feature-name" "機能の詳細説明"

# タスク一覧の確認
./scripts/agent-task.sh list

# タスク状態の更新
./scripts/agent-task.sh update <task_id> in_progress
./scripts/agent-task.sh update <task_id> completed
```

### 4. Git Worktreeの管理

```bash
# 新しいworktreeを作成
./scripts/worktree-manager.sh create feat/new-feature engineer

# worktree一覧
./scripts/worktree-manager.sh list

# worktreeの削除
./scripts/worktree-manager.sh remove feat/completed-feature

# 全worktreeを同期
./scripts/worktree-manager.sh sync
```

## 開発フロー

1. **要件定義** - ボスがタスクを定義
2. **設計** - チームで詳細設計を検討
3. **実装** - 各エージェントが並列で作業
4. **テスト** - TDDによる品質保証
5. **レビュー** - ボスによるコードレビュー
6. **マージ** - 承認後にmainブランチへ統合

## ブランチ戦略

- `feat/` - 新機能開発
- `fix/` - バグ修正
- `refactor/` - リファクタリング
- `docs/` - ドキュメント更新

各エージェントは自分専用のworktreeで作業し、他のエージェントの作業に干渉しません。

## セッション管理のヒント

1. **tmuxセッションの確認**
   ```bash
   tmux list-sessions | grep ai-agent
   ```

2. **セッションへの接続**
   ```bash
   tmux attach -t ai-agent-engineer-1
   ```

3. **セッションの切り替え**
   - `Ctrl+B, D` でデタッチ
   - `tmux attach -t <session-name>` で別セッションへ

## 制限事項と推奨事項

- 最大セッション数: 20-25（メモリに依存）
- エンジニア: 最大10セッション
- デザイナー: 最大2セッション
- マーケター: 最大2セッション
- ボス: 1セッション

## トラブルシューティング

### メモリ不足の場合
```bash
# セッション数を確認
./scripts/config.sh && get_session_count engineer

# 不要なセッションを終了
tmux kill-session -t ai-agent-engineer-3
```

### worktreeのコンフリクト
```bash
# mainブランチの最新を取得
git checkout main && git pull

# 各worktreeで同期
./scripts/worktree-manager.sh sync
```

## カスタマイズ

`scripts/config.sh`を編集して、プロジェクトに合わせた設定が可能：

- セッション数の上限
- ブランチ命名規則
- レポート形式
- その他の環境設定