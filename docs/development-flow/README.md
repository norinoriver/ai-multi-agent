# 開発フロードキュメント

このディレクトリには、MIL-STD-498準拠の開発フローに基づくドキュメントを管理します。

## ディレクトリ構造

- `requirements/` - 要求定義・要件定義書
  - [OCD (Operational Concept Description)](./requirements/OCD_multi_claude_code_system.md) ✅
  - [SSS (System/Subsystem Specification)](./requirements/SSS_multi_claude_code_system.md) ✅
  - [汎用フレームワーク化要求仕様](./requirements/framework_requirements.md) ✅
  - [要求定義書サマリー](./requirements/requirements_summary.md) ✅
  - SRS (Software Requirements Specification)
  - ユースケース・ユーザーストーリー
  - 受入条件

- `design/` - 設計書
  - 概要設計書 (High-level Design)
  - 詳細設計書 (SDD: Software Design Description)
  - インターフェース仕様書
  - データベース設計書

- `test/` - テスト関連ドキュメント
  - テスト計画書
  - テスト設計仕様書
  - テストケース仕様書
  - トレーサビリティマトリクス

- `implementation/` - 実装関連ドキュメント
  - TDD実装記録
  - コーディング規約
  - CI/CDパイプライン設定

## 開発フロー

1. **要求定義** ✅ - ステークホルダーのニーズを明確化
   - [OCD, SSS, 汎用フレームワーク要求](./requirements/) 完了
2. **要件定義** - システムが満たすべき機能・非機能要件を定義
3. **概要設計** - システムアーキテクチャと主要コンポーネントを設計
4. **詳細設計** - 各コンポーネントの内部構造を設計
5. **テスト設計** - テスト戦略とテストケースを設計
6. **TDD実装** - テスト駆動開発による実装

## 現在の進捗

**完了済み:**
- 要求定義フェーズ（[4つのドキュメント](./requirements/)）

**次のステップ:**
- 要件定義フェーズの開始

各フェーズのドキュメントは対応するディレクトリに保存してください。