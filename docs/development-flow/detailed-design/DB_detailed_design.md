# ファイルベースデータ設計書
## Multi-Agent Claude Code Development System (MACCDS)
### Version 1.0.0

## 1. 概要

### 1.1 目的
本文書は、MACCDSにおけるファイルベースデータ永続化層の詳細設計を定義する。ファイル構造、データスキーマ、アクセスパターンを記述する。

### 1.2 ファイルベースアプローチの選定理由
- **シンプルさ**: DBサーバー不要で軽量
- **可搬性**: ファイルシステムがあれば動作
- **可視性**: 人間が直接ファイル内容を確認可能
- **デバッグ容易性**: ファイル操作でトラブルシューティング可能

### 1.3 将来の拡張性
必要に応じてRDBMSやNoSQLデータベースへの移行も考慮した設計とする。

## 2. ファイル構造設計

### 2.1 全体ディレクトリ構造

```mermaid
graph TD
    A[shared/] --> B[agents/]
    A --> C[tasks/]
    A --> D[messages/]
    A --> E[metrics/]
    A --> F[logs/]
    A --> G[indexes/]
    
    B --> B1[metadata/]
    B --> B2[status/]
    B --> B3[history/]
    
    C --> C1[active/]
    C --> C2[completed/]
    C --> C3[dependencies/]
    C --> C4[history/]
    
    D --> D1[inbox/]
    D --> D2[sent/]
    D --> D3[temp/]
    
    E --> E1[YYYYMMDD/]
    F --> F2[YYYYMMDD/]
    
    B1 --> B1A[agent_id.json]
    B2 --> B2A[agent_id_status]
    C1 --> C1A[task_uuid.json]
    D1 --> D1A[agent_id/]
```

### 2.2 データエンティティ関係図

```mermaid
graph LR
    A[Agent Metadata] -->|assigns| B[Task Data]
    A -->|sends| C[Message Data]
    A -->|has| D[Status History]
    B -->|has| E[Task History]
    B -->|depends_on| F[Task Dependencies]
    
    A -.->|file ref| A1[agents/metadata/]
    B -.->|file ref| B1[tasks/active/]
    C -.->|file ref| C1[messages/inbox/]
    D -.->|file ref| D1[agents/history/]
    E -.->|file ref| E1[tasks/history/]
    F -.->|file ref| F1[tasks/dependencies/]
```

## 3. JSONスキーマ設計

### 3.1 Agent Metadata スキーマ

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "agent_id": {"type": "string", "pattern": "^[a-z_]+$"},
    "type": {"enum": ["boss", "pm", "engineer", "qa", "review", "architect"]},
    "capabilities": {"type": "array", "items": {"type": "string"}},
    "configuration": {
      "type": "object",
      "properties": {
        "max_concurrent_tasks": {"type": "integer", "minimum": 1},
        "preferred_languages": {"type": "array", "items": {"type": "string"}},
        "tmux_session": {"type": "string"},
        "tmux_window": {"type": "integer"},
        "tmux_pane": {"type": "integer"}
      }
    },
    "performance_stats": {
      "type": "object",
      "properties": {
        "total_tasks_completed": {"type": "integer", "minimum": 0},
        "average_completion_time_hours": {"type": "number", "minimum": 0},
        "success_rate": {"type": "number", "minimum": 0, "maximum": 1}
      }
    },
    "created_at": {"type": "string", "format": "date-time"},
    "updated_at": {"type": "string", "format": "date-time"}
  },
  "required": ["agent_id", "type", "capabilities", "created_at", "updated_at"]
}
```

### 3.2 Task Data スキーマ

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "task_id": {"type": "string", "pattern": "^task_[a-f0-9-]+$"},
    "title": {"type": "string", "maxLength": 200},
    "description": {"type": "string"},
    "type": {"enum": ["implementation", "testing", "review", "architecture", "infrastructure", "documentation"]},
    "status": {"enum": ["created", "assigned", "in_progress", "review", "testing", "completed", "blocked", "cancelled"]},
    "priority": {"enum": ["high", "medium", "low"]},
    "story_points": {"type": "integer", "minimum": 1, "maximum": 13},
    "assignee": {"type": "string", "pattern": "^[a-z_]+$"},
    "branch": {"type": "string", "pattern": "^feature/task-[a-f0-9-]+$"},
    "pull_request_id": {"type": ["integer", "null"]},
    "metadata": {
      "type": "object",
      "properties": {
        "created_by": {"type": "string"},
        "created_at": {"type": "string", "format": "date-time"},
        "updated_at": {"type": "string", "format": "date-time"},
        "started_at": {"type": ["string", "null"], "format": "date-time"},
        "estimated_completion": {"type": ["string", "null"], "format": "date-time"}
      }
    },
    "acceptance_criteria": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "description": {"type": "string"},
          "testable": {"type": "boolean"},
          "completed": {"type": "boolean"}
        },
        "required": ["id", "description", "testable", "completed"]
      }
    },
    "tags": {"type": "array", "items": {"type": "string"}}
  },
  "required": ["task_id", "title", "type", "status", "priority", "story_points", "metadata"]
}
```

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "message_id": {"type": "string", "pattern": "^msg_[a-f0-9-]+$"},
    "timestamp": {"type": "string", "format": "date-time"},
    "from": {"type": "string", "pattern": "^[a-z_]+$"},
    "to": {"type": "string", "pattern": "^[a-z_]+|broadcast$"},
    "type": {"enum": ["task_assignment", "progress_update", "blocker_notification", "review_request", "command"]},
    "priority": {"enum": ["high", "medium", "low"]},
    "content": {"type": "object"},
    "metadata": {
      "type": "object",
      "properties": {
        "correlation_id": {"type": "string"},
        "reply_to": {"type": "string"},
        "ttl": {"type": "integer", "minimum": 0},
        "retry_count": {"type": "integer", "minimum": 0}
      }
    }
  },
  "required": ["message_id", "timestamp", "from", "to", "type", "content"]
}
```

## 4. ファイル配置詳細

### 4.1 ディレクトリレイアウト

```
shared/
├── agents/
│   ├── metadata/           # エージェントメタデータ
│   │   ├── boss_agent.json
│   │   ├── pm_agent.json
│   │   └── ...
│   ├── status/            # 現在のステータス（ファイル名で表現）
│   │   ├── boss_agent_busy
│   │   ├── pm_agent_busy
│   │   ├── se_agent_1_free
│   │   └── ...
│   └── history/           # ステータス履歴
│       └── YYYYMMDD/
│           └── agent_status_changes.jsonl
├── tasks/
│   ├── active/           # アクティブなタスク
│   │   └── task_{uuid}.json
│   ├── completed/        # 完了タスク（アーカイブ）
│   │   └── YYYYMM/
│   │       └── task_{uuid}.json
│   ├── dependencies/     # タスク依存関係
│   │   └── dependencies.json
│   └── history/          # タスク変更履歴
│       └── YYYYMMDD/
│           └── task_changes.jsonl
├── messages/
│   ├── inbox/           # 受信メッセージ
│   │   └── {agent_id}/
│   │       └── {timestamp}_{from}_{message_id}.json
│   ├── sent/            # 送信済みメッセージ（監査用）
│   │   └── YYYYMMDD/
│   │       └── {timestamp}_{from}_{to}_{message_id}.json
│   └── temp/            # 一時ファイル（非ブロック書き込み用）
├── metrics/
│   └── YYYYMMDD/
│       ├── performance.jsonl
│       ├── errors.jsonl
│       └── usage.jsonl
└── logs/
    └── YYYYMMDD/
        ├── system.log
        └── {agent_id}.log
```

### 4.2 サンプルデータファイル

詳細なサンプルデータについては、各JSONスキーマに基づいて生成される。

## 5. インデックス設計

### 5.1 ファイル名ベースインデックス

ファイル名に重要な属性を含めることで、高速な検索を実現：

```bash
# タスク検索の例
# status別
ls shared/tasks/active/task_*.json | grep -E "task_[^_]+_in_progress"

# 日付別メッセージ
ls shared/messages/sent/20250107/*.json

# エージェント状態
ls shared/agents/status/*_free
```

### 5.2 メタデータインデックス

定期的に生成される集約ファイルでクエリ性能を向上：

```json
// shared/indexes/task_index.json
{
  "last_updated": "2025-01-07T12:00:00Z",
  "total_tasks": 156,
  "by_status": {
    "created": 10,
    "assigned": 5,
    "in_progress": 8,
    "review": 3,
    "completed": 130
  },
  "by_assignee": {
    "se_agent_1": 3,
    "se_agent_2": 5,
    "se_agent_3": 2,
    "qa_agent": 1
  },
  "by_priority": {
    "high": 5,
    "medium": 8,
    "low": 3
  }
}
```

### 5.3 インデックス更新スクリプト

```bash
#!/bin/bash
# scripts/update_indexes.sh

update_task_index() {
    local index_file="shared/indexes/task_index.json"
    local temp_file="${index_file}.tmp"
    
    # タスク統計を集計
    local total=$(find shared/tasks/active -name "*.json" | wc -l)
    local by_status=$(find shared/tasks/active -name "*.json" -exec jq -r '.status' {} \; | sort | uniq -c)
    
    # インデックスファイル生成
    jq -n \
        --arg updated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg total "$total" \
        --argjson by_status "$(echo "$by_status" | jq -Rs 'split("\n") | map(select(length > 0) | split(" ") | {(.[2]): (.[1] | tonumber)}) | add')" \
        '{
            last_updated: $updated,
            total_tasks: ($total | tonumber),
            by_status: $by_status
        }' > "$temp_file"
    
    # アトミックに更新
    mv "$temp_file" "$index_file"
}
```

## 6. データアクセスパターン

### 6.1 読み取りパターン

```bash
# 単一エンティティ読み取り
read_task() {
    local task_id=$1
    cat "shared/tasks/active/task_${task_id}.json" 2>/dev/null || \
    cat "shared/tasks/completed/*/task_${task_id}.json" 2>/dev/null
}

# 条件付き検索
find_tasks_by_status() {
    local status=$1
    find shared/tasks/active -name "*.json" -exec jq -r \
        'select(.status == "'$status'") | {id: .task_id, title: .title}' {} \;
}

# 集約クエリ
count_agent_tasks() {
    local agent_id=$1
    find shared/tasks/active -name "*.json" -exec jq -r \
        'select(.assignee == "'$agent_id'") | .task_id' {} \; | wc -l
}
```

### 6.2 書き込みパターン

```bash
# トランザクション的書き込み
update_task_status() {
    local task_id=$1
    local new_status=$2
    local task_file="shared/tasks/active/task_${task_id}.json"
    local temp_file="${task_file}.tmp"
    local backup_file="${task_file}.bak"
    
    # 1. 現在の状態をバックアップ
    cp "$task_file" "$backup_file"
    
    # 2. 更新を一時ファイルに書き込み
    jq --arg status "$new_status" \
       --arg updated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.status = $status | .metadata.updated_at = $updated' \
       "$task_file" > "$temp_file"
    
    # 3. 履歴を記録
    record_task_change "$task_id" "status" "$(jq -r .status "$task_file")" "$new_status"
    
    # 4. アトミックに更新
    mv "$temp_file" "$task_file"
    
    # 5. バックアップ削除
    rm "$backup_file"
}
```

## 7. データ整合性とトランザクション

### 7.1 楽観的ロック

```bash
# バージョン番号による楽観的ロック
update_with_version_check() {
    local file=$1
    local expected_version=$2
    local update_function=$3
    
    # 現在のバージョンを確認
    local current_version=$(jq -r '.version // 0' "$file")
    
    if [[ "$current_version" != "$expected_version" ]]; then
        echo "Error: Version mismatch. Expected $expected_version, got $current_version"
        return 1
    fi
    
    # 更新実行（バージョンインクリメント含む）
    local new_version=$((current_version + 1))
    $update_function "$file" "$new_version"
}
```

### 7.2 ジャーナリング

```bash
# 変更ジャーナル
journal_operation() {
    local operation=$1
    local entity_type=$2
    local entity_id=$3
    local data=$4
    
    local journal_entry=$(jq -n \
        --arg op "$operation" \
        --arg type "$entity_type" \
        --arg id "$entity_id" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson data "$data" \
        '{
            operation: $op,
            entity_type: $type,
            entity_id: $id,
            timestamp: $ts,
            data: $data
        }'
    )
    
    echo "$journal_entry" >> "shared/journal/$(date +%Y%m%d).jsonl"
}
```

## 8. バックアップとリカバリー

### 8.1 バックアップ戦略

```bash
#!/bin/bash
# scripts/backup.sh

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

backup_shared_data() {
    mkdir -p "$BACKUP_DIR"
    
    # 重要データのバックアップ
    tar -czf "$BACKUP_DIR/tasks.tar.gz" shared/tasks/
    tar -czf "$BACKUP_DIR/agents.tar.gz" shared/agents/
    tar -czf "$BACKUP_DIR/messages.tar.gz" shared/messages/sent/
    
    # メタデータ記録
    jq -n \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg size "$(du -sh shared/ | cut -f1)" \
        '{
            backup_timestamp: $timestamp,
            data_size: $size,
            backup_location: "'$BACKUP_DIR'"
        }' > "$BACKUP_DIR/metadata.json"
}
```

### 8.2 リカバリー手順

```bash
#!/bin/bash
# scripts/restore.sh

restore_from_backup() {
    local backup_dir=$1
    
    if [[ ! -d "$backup_dir" ]]; then
        echo "Error: Backup directory not found"
        return 1
    fi
    
    # 現在のデータを退避
    mv shared/ shared_old_$(date +%Y%m%d_%H%M%S)/
    
    # バックアップから復元
    mkdir -p shared/
    tar -xzf "$backup_dir/tasks.tar.gz" -C ./
    tar -xzf "$backup_dir/agents.tar.gz" -C ./
    tar -xzf "$backup_dir/messages.tar.gz" -C ./
    
    echo "Restore completed from $backup_dir"
}
```

## 9. パフォーマンス最適化

### 9.1 キャッシュ戦略

```bash
# インメモリキャッシュ（Bash連想配列）
declare -A TASK_CACHE
CACHE_TTL=300  # 5分

get_task_cached() {
    local task_id=$1
    local cache_key="task_${task_id}"
    local cached_value="${TASK_CACHE[$cache_key]}"
    
    if [[ -n "$cached_value" ]]; then
        # キャッシュヒット
        echo "$cached_value"
        return
    fi
    
    # キャッシュミス - ファイルから読み込み
    local task_data=$(read_task "$task_id")
    TASK_CACHE[$cache_key]=$task_data
    
    # TTL後にキャッシュクリア
    (sleep $CACHE_TTL && unset TASK_CACHE[$cache_key]) &
    
    echo "$task_data"
}
```

### 9.2 バッチ処理

```bash
# 複数タスクの一括読み込み
batch_read_tasks() {
    local task_ids=("$@")
    local results=()
    
    for task_id in "${task_ids[@]}"; do
        # 並列読み込み
        {
            read_task "$task_id"
        } &
    done
    
    # 全ての読み込み完了を待つ
    wait
}
```

## 10. データ保守

### 10.1 アーカイブ処理

```bash
# 完了タスクのアーカイブ
archive_completed_tasks() {
    local cutoff_date=$(date -d "30 days ago" +%Y%m%d)
    
    find shared/tasks/active -name "*.json" | while read -r task_file; do
        local completed_at=$(jq -r '.metadata.completed_at // empty' "$task_file")
        
        if [[ -n "$completed_at" ]]; then
            local completed_date=$(date -d "$completed_at" +%Y%m%d)
            
            if [[ "$completed_date" -lt "$cutoff_date" ]]; then
                # アーカイブディレクトリに移動
                local archive_dir="shared/tasks/completed/$(date -d "$completed_at" +%Y%m)"
                mkdir -p "$archive_dir"
                mv "$task_file" "$archive_dir/"
            fi
        fi
    done
}
```

### 10.2 データクリーンアップ

```bash
# 古いログとメトリクスの削除
cleanup_old_data() {
    # 30日以上前のログを削除
    find shared/logs -name "*.log" -mtime +30 -delete
    
    # 90日以上前のメトリクスを圧縮
    find shared/metrics -name "*.jsonl" -mtime +90 -exec gzip {} \;
    
    # 一時ファイルのクリーンアップ
    find shared/messages/temp -name "*.tmp" -mtime +1 -delete
}
```

---

**承認**  
本データベース詳細設計書は、MACCDSのデータ永続化層の実装ガイドラインとして使用される。

作成日: 2025-01-07  
バージョン: 1.0.0