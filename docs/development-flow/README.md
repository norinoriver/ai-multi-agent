# 開発フロードキュメント

このディレクトリには、MIL-STD-498準拠の開発フローに基づくドキュメントを管理します。

## ディレクトリ構造

- `requirements/` - 要求定義・要件定義書
  - [OCD (Operational Concept Description)](./requirements/OCD_multi_claude_code_system.md) ✅
  - [SSS (System/Subsystem Specification)](./requirements/SSS_multi_claude_code_system.md) ✅
  - [汎用フレームワーク化要求仕様](./requirements/framework_requirements.md) ✅
  - [要求定義書サマリー](./requirements/requirements_summary.md) ✅
  - [SRS (Software Requirements Specification)](./requirements/SRS_multi_claude_code_system.md) ✅
  - [ユースケース・ユーザーストーリー](./requirements/use_cases_user_stories.md) ✅
  - [受入条件](./requirements/acceptance_criteria.md) ✅
  - [トレーサビリティマトリクス](./requirements/traceability_matrix.md) ✅

- `design/` - 設計書
  - [Software Design Document (高レベル設計書)](./design/software_design_document.md) ✅
  - [アーキテクチャ・データフロー図](./design/architecture_dataflow_diagrams.md) ✅
  - [インターフェース仕様書](./design/interface_specification.md) ✅

- `detailed-design/` - 詳細設計書
  - [Software Design Description (SDD)](./detailed-design/SDD_software_design_description.md) ✅
  - [Technical Design Document (TDD)](./detailed-design/TDD_technical_design_document.md) ✅
  - [データベース詳細設計](./detailed-design/DB_detailed_design.md) ✅

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
2. **要件定義** ✅ - システムが満たすべき機能・非機能要件を定義
   - [SRS, ユースケース, 受入条件, トレーサビリティ](./requirements/) 完了
3. **概要設計** ✅ - システムアーキテクチャと主要コンポーネントを設計
   - [Software Design Document, アーキテクチャ図, インターフェース仕様](./design/) 完了
4. **詳細設計** - 各コンポーネントの内部構造を設計
5. **テスト設計** - テスト戦略とテストケースを設計
6. **TDD実装** - テスト駆動開発による実装

## 現在の進捗

**完了済み:**
- 要求定義フェーズ（[4つのドキュメント](./requirements/)）
- 要件定義フェーズ（[4つのドキュメント](./requirements/)）
- 概要設計フェーズ（[3つのドキュメント](./design/)）
- 詳細設計フェーズ（[3つのドキュメント](./detailed-design/)）

**次のステップ:**
- テスト設計フェーズの開始

各フェーズのドキュメントは対応するディレクトリに保存してください。