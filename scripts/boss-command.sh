#!/bin/bash

# AI Multi-Agent Boss Command System
# ボスから各エージェントへの指示送信スクリプト

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 設定
TMUX_PREFIX="ai-agent"
BOSS_SESSION="ai-agent-boss-1"
TASKS_DIR="$WORKSPACE_DIR/tasks"
COMMANDS_DIR="$WORKSPACE_DIR/commands"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ディレクトリ作成
mkdir -p "$COMMANDS_DIR"

# 使用方法を表示
show_usage() {
    echo -e "${CYAN}AI Multi-Agent Boss Command System${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 send <agent_type> <agent_id> \"<command>\"  # 特定エージェントへ指示"
    echo "  $0 broadcast <agent_type> \"<command>\"         # タイプ全員へ指示"
    echo "  $0 all \"<command>\"                            # 全エージェントへ指示"
    echo "  $0 task <agent_type> <agent_id> <task_id>     # タスクを割り当て"
    echo "  $0 status                                      # 指示履歴を表示"
    echo ""
    echo "agent_type: boss, engineer (1-10), designer (1-2), marketer (1-2)"
    echo ""
    echo "例:"
    echo "  $0 send engineer 1 \"ログイン機能を実装してください\""
    echo "  $0 broadcast engineer \"コードレビューを開始してください\""
    echo "  $0 all \"進捗状況を報告してください\""
    echo "  $0 task engineer 1 20240628123456_engineer_login"
}

# 指示の記録
record_command() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local agent_type=$1
    local agent_id=$2
    local command=$3
    local command_file="$COMMANDS_DIR/$(date +%Y%m%d%H%M%S)_${agent_type}_${agent_id}.cmd"
    
    cat > "$command_file" << EOF
TIMESTAMP: $timestamp
FROM: Boss
TO: ${agent_type}-${agent_id}
COMMAND: $command
STATUS: sent
EOF
    
    echo "$command_file"
}

# 特定エージェントへ指示送信
send_to_agent() {
    local agent_type=$1
    local agent_id=$2
    local command=$3
    local session_name="${TMUX_PREFIX}-${agent_type}-${agent_id}"
    
    # セッション存在確認
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${RED}エラー: エージェントセッションが見つかりません: $session_name${NC}"
        return 1
    fi
    
    # 指示を記録
    local cmd_file=$(record_command "$agent_type" "$agent_id" "$command")
    
    # tmuxセッションに指示を送信
    tmux send-keys -t "$session_name" "" C-m
    tmux send-keys -t "$session_name" "# ===== BOSS指示 =====" C-m
    tmux send-keys -t "$session_name" "# 時刻: $(date +"%Y-%m-%d %H:%M:%S")" C-m
    tmux send-keys -t "$session_name" "# 指示: $command" C-m
    tmux send-keys -t "$session_name" "# ===================" C-m
    tmux send-keys -t "$session_name" "" C-m
    
    echo -e "${GREEN}✓ 指示を送信しました: ${agent_type}-${agent_id}${NC}"
    echo -e "${BLUE}  内容: $command${NC}"
    echo -e "${CYAN}  記録: $cmd_file${NC}"
}

# 複数エージェントへ一斉送信
broadcast_to_type() {
    local agent_type=$1
    local command=$2
    local count=0
    
    echo -e "${YELLOW}${agent_type}タイプへ一斉送信中...${NC}"
    
    # エージェント数を取得
    case "$agent_type" in
        boss) local max=1 ;;
        engineer) local max=10 ;;
        designer|marketer) local max=2 ;;
        *) 
            echo -e "${RED}エラー: 無効なエージェントタイプ: $agent_type${NC}"
            return 1
            ;;
    esac
    
    # 各エージェントへ送信
    for i in $(seq 1 $max); do
        if send_to_agent "$agent_type" "$i" "$command" 2>/dev/null; then
            ((count++))
        fi
    done
    
    echo -e "${GREEN}完了: ${count}/${max} エージェントへ送信しました${NC}"
}

# 全エージェントへ送信
broadcast_to_all() {
    local command=$1
    
    echo -e "${YELLOW}全エージェントへ一斉送信中...${NC}"
    echo ""
    
    for agent_type in boss engineer designer marketer; do
        broadcast_to_type "$agent_type" "$command"
        echo ""
    done
}

# タスクを割り当て
assign_task() {
    local agent_type=$1
    local agent_id=$2
    local task_id=$3
    local task_file="$TASKS_DIR/${task_id}.task"
    
    # タスクファイルの確認
    if [ ! -f "$task_file" ]; then
        echo -e "${RED}エラー: タスクが見つかりません: $task_id${NC}"
        return 1
    fi
    
    # タスク内容を取得
    local task_name=$(grep "^TASK_NAME:" "$task_file" | cut -d' ' -f2-)
    local description=$(grep "^DESCRIPTION:" "$task_file" | cut -d' ' -f2-)
    
    # タスク割り当てコマンドを作成
    local command="タスク割り当て: [${task_id}] ${task_name} - ${description}"
    
    # エージェントへ送信
    send_to_agent "$agent_type" "$agent_id" "$command"
    
    # タスクファイルを更新
    echo "ASSIGNED_TO: ${agent_type}-${agent_id}" >> "$task_file"
    echo "ASSIGNED_AT: $(date +"%Y-%m-%d %H:%M:%S")" >> "$task_file"
    
    # agent-task.shを使って状態更新
    "$SCRIPT_DIR/agent-task.sh" update "$task_id" "in_progress"
}

# 指示履歴を表示
show_command_status() {
    echo -e "${CYAN}=== 指示履歴 ===${NC}"
    echo ""
    
    if [ -d "$COMMANDS_DIR" ] && ls "$COMMANDS_DIR"/*.cmd &>/dev/null; then
        for cmd_file in "$COMMANDS_DIR"/*.cmd; do
            echo -e "${YELLOW}--- $(basename "$cmd_file" .cmd) ---${NC}"
            cat "$cmd_file"
            echo ""
        done | tail -50  # 最新50件のみ表示
    else
        echo -e "${MAGENTA}指示履歴がありません${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}=== アクティブなタスク ===${NC}"
    "$SCRIPT_DIR/agent-task.sh" list | grep -E "(pending|in_progress)" || echo -e "${MAGENTA}アクティブなタスクはありません${NC}"
}

# ボスセッションの確認
check_boss_session() {
    if ! tmux has-session -t "$BOSS_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}警告: ボスセッションが起動していません${NC}"
        echo -e "${BLUE}ヒント: ./scripts/ai-multi-agent.sh start を実行してください${NC}"
    fi
}

# メイン処理
main() {
    case "${1:-}" in
        send)
            if [ $# -ne 4 ]; then
                show_usage
                exit 1
            fi
            check_boss_session
            send_to_agent "$2" "$3" "$4"
            ;;
        broadcast)
            if [ $# -ne 3 ]; then
                show_usage
                exit 1
            fi
            check_boss_session
            broadcast_to_type "$2" "$3"
            ;;
        all)
            if [ $# -ne 2 ]; then
                show_usage
                exit 1
            fi
            check_boss_session
            broadcast_to_all "$2"
            ;;
        task)
            if [ $# -ne 4 ]; then
                show_usage
                exit 1
            fi
            check_boss_session
            assign_task "$2" "$3" "$4"
            ;;
        status)
            show_command_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# スクリプトの実行
main "$@"