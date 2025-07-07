# エージェント状態管理ファイル実装アイデア

## 概要

エージェントの状態をファイル名で表現し、Task Managerが定期的にチェックしてタスク割り振りを行う詳細実装案。

## ファイル名による状態管理

### ディレクトリ構造
```
shared/agents/status/
├── boss_agent_busy
├── pm_agent_busy
├── se_agent_1_free
├── se_agent_2_work
├── se_agent_3_work  
├── qa_agent_free
├── review_agent_free
└── architect_agent_work
```

### 状態種別
- `_free`: 空き状態（新しいタスクを受け取り可能）
- `_work`: 作業中（タスク実行中）
- `_busy`: 忙しい（会議、レビュー、分析中など）
- `_error`: エラー状態（復旧が必要）
- `_offline`: オフライン（停止中）

## 状態変更操作

### エージェント側の操作
```bash
# タスク開始時
rm shared/agents/status/se_agent_1_free
touch shared/agents/status/se_agent_1_work

# タスク完了時  
rm shared/agents/status/se_agent_1_work
touch shared/agents/status/se_agent_1_free

# エラー発生時
rm shared/agents/status/se_agent_1_work
touch shared/agents/status/se_agent_1_error
```

### Task Manager側の監視
```bash
# 5秒間隔で空きエージェントをチェック
watch -n 5 'ls shared/agents/status/*_free'

# 結果例：
# se_agent_1_free
# qa_agent_free  
# review_agent_free

# 特定タイプの空きエージェント検索
ls shared/agents/status/se_agent_*_free
ls shared/agents/status/qa_agent_*_free
```

## タスク割り振りロジック

### 基本フロー
1. Task Managerが5秒間隔で状態ディレクトリをスキャン
2. `*_free`ファイルからタスクに適したエージェントを選択
3. タスクを割り当て
4. エージェントの状態ファイルを`_work`に変更
5. エージェントがタスク完了後、状態を`_free`に戻す

### 優先順位付け
```bash
# 負荷分散: 現在の作業中エージェント数をチェック
work_count=$(ls shared/agents/status/*_work | wc -l)
free_count=$(ls shared/agents/status/*_free | wc -l)

# 最も空いているタイプのエージェントを優先
```

## メリット

### シンプルさ
- ファイルI/O最小限
- JSONパースなどの複雑な処理不要
- シェルコマンドだけで完結

### 高速性
- `ls`コマンドは非常に高速
- ファイル内容読み込み不要
- リアルタイム状態反映

### 可視性
- `ls shared/agents/status/`で一目で全状態確認
- デバッグが容易
- 人間にも分かりやすい

## 拡張可能性

### 詳細情報の追加
```bash
# タスクIDを含む状態表現
se_agent_1_work_task-001
qa_agent_free_idle

# 開始時刻を含む
se_agent_2_work_20250107120000
```

### 統計情報
```bash
# 日次統計
echo "$(date): $(ls shared/agents/status/*_free | wc -l) agents free" >> daily_stats.log
```

## 実装時の注意点

### 原子性確保
```bash
# 一時ファイルを使用して原子的な状態変更
touch shared/agents/status/se_agent_1_work.tmp
rm shared/agents/status/se_agent_1_free
mv shared/agents/status/se_agent_1_work.tmp shared/agents/status/se_agent_1_work
```

### エラーハンドリング
- ファイル操作失敗時の復旧手順
- 孤立状態ファイルのクリーンアップ
- システム再起動時の状態初期化

---

**作成日**: 2025-01-07  
**フェーズ**: 詳細設計時に参考とする実装アイデア