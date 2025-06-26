# Git ブランチ戦略

## 概要
このプロジェクトでは、Git worktreeを活用して複数のエージェントが並列で作業できる環境を提供します。

## ブランチ命名規則

### フィーチャーブランチ
```
feat/<機能名>
```
- 例: `feat/user-authentication`, `feat/payment-integration`

### バグ修正ブランチ
```
fix/<バグ説明>
```
- 例: `fix/login-error`, `fix/memory-leak`

### リファクタリングブランチ
```
refactor/<対象>
```
- 例: `refactor/database-layer`, `refactor/api-structure`

### ドキュメントブランチ
```
docs/<ドキュメント名>
```
- 例: `docs/api-reference`, `docs/setup-guide`

## Worktree運用ルール

### 1. Worktree作成
```bash
# エンジニア用のフィーチャーブランチを作成
./scripts/worktree-manager.sh create feat/new-feature engineer

# デザイナー用のUIブランチを作成
./scripts/worktree-manager.sh create feat/ui-redesign designer
```

### 2. ディレクトリ構造
```
worktrees/
├── engineer/
│   ├── feat/user-auth/
│   └── feat/api-endpoints/
├── designer/
│   └── feat/ui-redesign/
└── marketer/
    └── feat/landing-page/
```

### 3. エージェント割り当て
- 各エージェントは自分の役割に対応するworktreeディレクトリで作業
- 他のエージェントのworktreeには干渉しない
- 作業完了後はPull Requestを作成

## マージ戦略

### 1. Pull Request作成
- 各フィーチャーブランチからmainブランチへPRを作成
- PRには以下を含める：
  - 実装内容の説明
  - テスト結果（summary.txt）
  - 変更内容のパッチ（*.patch）

### 2. レビュープロセス
1. 自動テストの実行
2. ボスによるコードレビュー
3. 必要に応じて他のエージェントからのフィードバック
4. 承認後にマージ

### 3. マージ後の処理
```bash
# 使用済みworktreeの削除
./scripts/worktree-manager.sh remove feat/completed-feature

# 全worktreeの同期
./scripts/worktree-manager.sh sync
```

## コンフリクト解決

### 予防策
- 機能ごとに明確に分離されたブランチを作成
- 定期的な同期（1日1回以上）
- 小さく頻繁なコミット

### 解決手順
1. mainブランチの最新状態を取得
2. 各worktreeで `git pull origin main --rebase`
3. コンフリクトが発生した場合はボスが調整
4. 必要に応じてエージェント間で協議

## ベストプラクティス

1. **1タスク1ブランチ**: 各タスクは独立したブランチで作業
2. **早期マージ**: 完成した機能は速やかにマージ
3. **定期同期**: 毎日作業開始時に最新のmainブランチを同期
4. **明確なコミットメッセージ**: 変更内容が分かりやすいメッセージを記載
5. **テスト必須**: 全ての変更にはテストを含める