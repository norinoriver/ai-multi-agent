# ボス（プロダクトオーナー）作業テンプレート

## プロジェクト管理

### プロジェクト情報
- **プロジェクト名**: [PROJECT_NAME]
- **フェーズ**: [PHASE]
- **スプリント**: [SPRINT_NUMBER]
- **期間**: [START_DATE] - [END_DATE]

### チーム状況
| エージェント | 稼働数 | 現在のタスク | ステータス |
|-------------|--------|--------------|-----------|
| Engineer | [COUNT] | [TASKS] | [STATUS] |
| Designer | [COUNT] | [TASKS] | [STATUS] |
| Marketer | [COUNT] | [TASKS] | [STATUS] |

## タスク定義

### 新規タスク
```yaml
task_id: [TASK_ID]
title: [TASK_TITLE]
description: |
  [詳細な説明]
acceptance_criteria:
  - [基準1]
  - [基準2]
  - [基準3]
assigned_to: [AGENT_TYPE]
priority: [HIGH/MEDIUM/LOW]
estimated_hours: [HOURS]
dependencies: [TASK_IDS]
```

### 進行中タスク
| タスクID | タイトル | 担当 | 進捗 | 期限 |
|----------|---------|------|------|------|
| [ID] | [TITLE] | [AGENT] | [%] | [DATE] |

## レビュー記録

### コードレビュー
- **PR番号**: #[NUMBER]
- **ブランチ**: [BRANCH_NAME]
- **レビュアー**: Boss
- **日時**: [DATETIME]

#### チェックリスト
- [ ] 要件を満たしている
- [ ] テストが網羅的
- [ ] コード品質が基準を満たす
- [ ] ドキュメントが更新されている
- [ ] セキュリティ考慮がされている

#### フィードバック
[具体的なフィードバック内容]

### テスト結果確認
- **実行日時**: [DATETIME]
- **結果**: [PASS/FAIL]
- **詳細**: [DETAILS]

## 意思決定記録

### 決定事項
| 日付 | 決定内容 | 理由 | 影響範囲 |
|------|---------|------|----------|
| [DATE] | [DECISION] | [RATIONALE] | [IMPACT] |

### リスク管理
| リスク | 可能性 | 影響度 | 対策 |
|--------|--------|--------|------|
| [RISK] | [L/M/H] | [L/M/H] | [MITIGATION] |

## スプリント振り返り

### 成果
- 完了タスク数: [COMPLETED]
- 計画達成率: [PERCENTAGE]%
- 品質指標: [METRICS]

### 良かった点
- [GOOD_POINT_1]
- [GOOD_POINT_2]

### 改善点
- [IMPROVEMENT_1]
- [IMPROVEMENT_2]

### 次スプリントへの申し送り
[HANDOVER_NOTES]

## マージ判定

### マージ基準
- [ ] 全自動テストがパス
- [ ] コードレビュー完了
- [ ] ドキュメント更新完了
- [ ] デプロイ準備完了
- [ ] ステークホルダー承認

### マージ実行記録
```bash
# マージコマンド
git checkout main
git merge --no-ff [BRANCH_NAME]
git tag -a v[VERSION] -m "[RELEASE_NOTES]"
git push origin main --tags
```

## 報告書
- [ ] 週次進捗報告
- [ ] スプリント完了報告
- [ ] リリースノート
- [ ] ステークホルダー向け資料