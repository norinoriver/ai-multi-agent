#!/bin/bash

# AI Multi-Agent Task Management Script
# エージェントへのタスク割り当てと状態管理

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="$WORKSPACE_DIR/reports"
TASKS_DIR="$WORKSPACE_DIR/tasks"

# タスクディレクトリの作成
mkdir -p "$TASKS_DIR"

# 使用方法の表示
usage() {
    echo "使用方法:"
    echo "  $0 create <agent_type> <task_name> <description>  # タスクの作成"
    echo "  $0 list [agent_type]                              # タスクの一覧表示"
    echo "  $0 update <task_id> <status>                      # タスク状態の更新"
    echo "  $0 report <task_id>                               # タスクレポートの確認"
    echo ""
    echo "タスク状態: pending, in_progress, completed, blocked"
    exit 1
}

# タスクの作成
create_task() {
    local agent_type=$1
    local task_name=$2
    local description=$3
    local task_id=$(date +%Y%m%d%H%M%S)_${agent_type}_${task_name//[^a-zA-Z0-9]/_}
    local task_file="$TASKS_DIR/${task_id}.task"
    
    cat > "$task_file" << EOF
TASK_ID: $task_id
AGENT_TYPE: $agent_type
TASK_NAME: $task_name
DESCRIPTION: $description
STATUS: pending
CREATED_AT: $(date +"%Y-%m-%d %H:%M:%S")
BRANCH: feat/$task_name
EOF
    
    echo "タスクを作成しました: $task_id"
    echo "タスクファイル: $task_file"
}

# タスクの一覧表示
list_tasks() {
    local agent_filter=$1
    
    echo "=== タスク一覧 ==="
    echo ""
    
    for task_file in "$TASKS_DIR"/*.task 2>/dev/null; do
        if [ -f "$task_file" ]; then
            local agent_type=$(grep "^AGENT_TYPE:" "$task_file" | cut -d' ' -f2)
            
            # フィルタリング
            if [ -n "$agent_filter" ] && [ "$agent_type" != "$agent_filter" ]; then
                continue
            fi
            
            echo "--- $(basename "$task_file" .task) ---"
            cat "$task_file"
            echo ""
        fi
    done
}

# タスク状態の更新
update_task_status() {
    local task_id=$1
    local new_status=$2
    local task_file="$TASKS_DIR/${task_id}.task"
    
    if [ ! -f "$task_file" ]; then
        echo "エラー: タスクが見つかりません: $task_id"
        exit 1
    fi
    
    # 状態を更新
    sed -i.bak "s/^STATUS: .*/STATUS: $new_status/" "$task_file"
    echo "UPDATED_AT: $(date +"%Y-%m-%d %H:%M:%S")" >> "$task_file"
    
    echo "タスク状態を更新しました: $task_id -> $new_status"
}

# タスクレポートの確認
view_report() {
    local task_id=$1
    local report_file="$REPORTS_DIR/${task_id}_summary.txt"
    
    if [ -f "$report_file" ]; then
        echo "=== タスクレポート: $task_id ==="
        cat "$report_file"
    else
        echo "レポートが見つかりません: $report_file"
    fi
}

# メイン処理
case "$1" in
    create)
        if [ $# -ne 4 ]; then
            usage
        fi
        create_task "$2" "$3" "$4"
        ;;
    list)
        list_tasks "$2"
        ;;
    update)
        if [ $# -ne 3 ]; then
            usage
        fi
        update_task_status "$2" "$3"
        ;;
    report)
        if [ $# -ne 2 ]; then
            usage
        fi
        view_report "$2"
        ;;
    *)
        usage
        ;;
esac