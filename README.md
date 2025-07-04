# AI Multi-Agent Development System

## 概要
このプロジェクトは、Claude Codeを複数のエージェントとして活用し、並列的にソフトウェア開発を進めるシステムです。

## プロジェクト構造
```
.
├── agents/             # 各エージェントの作業ディレクトリ
│   ├── engineer/       # エンジニアエージェント用
│   ├── designer/       # デザイナーエージェント用
│   ├── marketer/       # マーケターエージェント用
│   └── boss/          # ボス（マネージャー）用
├── scripts/           # エージェント管理スクリプト
├── docs/              # プロジェクトドキュメント
├── worktrees/         # Git worktree用ディレクトリ
├── reports/           # 各エージェントからのレポート
└── templates/         # 各役割用のテンプレート
```

## 役割定義

### ボス（プロダクトオーナー/ディレクター）
- プロジェクト全体の管理
- 仕様作成と承認
- マージ判断とレビュー
- 進行管理

### エンジニア
- フロントエンド/バックエンド実装
- テスト駆動開発（TDD）
- 技術スタック:
  - Frontend: React, Next.js, Tailwind CSS
  - Backend: FastAPI, Node.js
  - Testing: Jest, Playwright, Power Assert

### デザイナー
- UI/UX設計
- プロトタイプ制作
- HTML/CSSテンプレート作成

### マーケター
- ランディングページコンテンツ作成
- SEO対策
- ユーザー導線設計

## 開発フロー

1. **要件定義**: ボスがプロジェクト要件とタスクを定義
2. **設計フェーズ**: チームで詳細設計・テスト設計を作成
3. **承認**: ボスが設計を承認
4. **実装**: TDDによる実装
5. **レビュー**: テスト結果とコードレビュー
6. **マージ**: ボスによる最終承認とマージ

## 運用ルール

- **ブランチ戦略**: Git worktreeを使用し、1タスク1ブランチ
- **セッション管理**: 各エージェントは独立したClaude Codeセッションで動作
- **成果物**: 
  - `summary.txt`: 作業サマリとテスト結果
  - `*.patch`: 変更内容のパッチファイル

## 制限事項

- 最大セッション数: 20-25
- メモリ使用量: OS用に6GBを確保
- ファイルディスクリプタ上限: 4096

## セットアップ

```bash
# ファイルディスクリプタ上限の設定
ulimit -n 4096

# エージェント起動スクリプトの実行
./scripts/start-agents.sh
```

## 使用方法

1. ボスセッションでタスクを定義
2. 各エージェントにタスクを割り当て
3. エージェントが作業を実行
4. レポートを確認してマージ判定