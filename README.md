# AI Multi-Agent Claude Code Development System (MACCDS)

複数のClaude Codeインスタンスを協調させて並列的にソフトウェア開発を行うシステム

## 概要

MACCDSは、複数のAIエージェント（Claude Code）が協調して効率的にソフトウェア開発を行うフレームワークです。人間は企画・要求定義に集中し、実装はAIエージェントチームが並列で実行します。

## ドキュメント

### 要求定義フェーズ
- [運用コンセプト記述書 (OCD)](./docs/development-flow/requirements/OCD_multi_claude_code_system.md)
- [システム/サブシステム仕様書 (SSS)](./docs/development-flow/requirements/SSS_multi_claude_code_system.md)
- [汎用フレームワーク化要求仕様](./docs/development-flow/requirements/framework_requirements.md)
- [要求定義まとめ](./docs/development-flow/requirements/requirements_summary.md)

### 要件定義フェーズ
- [ソフトウェア要件仕様書 (SRS)](./docs/development-flow/requirements/SRS_multi_claude_code_system.md)
- [ユースケース・ユーザーストーリー](./docs/development-flow/requirements/use_cases_user_stories.md)
- [受入条件](./docs/development-flow/requirements/acceptance_criteria.md)
- [トレーサビリティマトリクス](./docs/development-flow/requirements/traceability_matrix.md)

### 概要設計フェーズ
- [Software Design Document (高レベル設計書)](./docs/development-flow/design/software_design_document.md)
- [アーキテクチャ・データフロー図](./docs/development-flow/design/architecture_dataflow_diagrams.md)
- [インターフェース仕様書](./docs/development-flow/design/interface_specification.md)

### 詳細設計フェーズ
- 作成予定

### テスト設計フェーズ
- 作成予定

## クイックスタート

```bash
# リポジトリのクローン
git clone https://github.com/[user]/ai-multi-agent.git
cd ai-multi-agent

# エージェント起動
bash start-agents.sh

# エージェント停止
bash stop-agents.sh
```

## システム構成

- **Boss/POエージェント**: 人間との対話窓口
- **PMエージェント**: プロジェクト管理
- **エンジニアエージェント**: 実装作業
- **QAエージェント**: テスト・品質保証
- **レビューエージェント**: コードレビュー
- その他、プロジェクトに応じて追加可能

## 必要環境

- macOS または Linux
- Claude Code CLI
- tmux
- Git
- 16GB RAM以上、マルチコアCPU推奨

## ライセンス

MIT License（予定）