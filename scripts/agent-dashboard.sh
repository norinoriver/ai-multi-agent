#!/bin/bash

# エージェント管理ダッシュボード
# tmuxを使用してエージェントの状態を監視・管理する統合インターフェース

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 設定
AGENTS_DIR="$WORKSPACE_DIR/agents"
TASKS_DIR="$WORKSPACE_DIR/tasks"
REPORTS_DIR="$WORKSPACE_DIR/reports"
LOGS_DIR="$WORKSPACE_DIR/logs"

# エージェントタイプと最大セッション数
declare -A MAX_SESSIONS=(
    ["engineer"]=10
    ["designer"]=2
    ["marketer"]=2
    ["boss"]=1
)

# 最大セッション数を取得する関数
get_max_sessions() {
    local agent_type=$1
    echo "${MAX_SESSIONS[$agent_type]:-1}"
}

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ダッシュボードのセッション名
DASHBOARD_SESSION="ai-agent-dashboard"

# ダッシュボードを作成
create_dashboard() {
    # 既存のダッシュボードセッションがあれば削除
    if tmux has-session -t "$DASHBOARD_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}既存のダッシュボードセッションを削除しています...${NC}"
        tmux kill-session -t "$DASHBOARD_SESSION"
    fi
    
    echo -e "${GREEN}ダッシュボードを作成しています...${NC}"
    
    # 新しいダッシュボードセッションを作成
    tmux new-session -d -s "$DASHBOARD_SESSION" -n "overview"
    
    # Window 1: Overview (概要とステータス)
    # 一時的なスクリプトファイルを作成
    cat > "/tmp/show-agent-status-temp.sh" << EOF
#!/bin/bash
cd "$WORKSPACE_DIR"
source "$SCRIPT_DIR/agent-dashboard.sh"
show_agent_status
EOF
    chmod +x "/tmp/show-agent-status-temp.sh"
    tmux send-keys -t "$DASHBOARD_SESSION:overview" "watch -n 2 '/tmp/show-agent-status-temp.sh'" Enter
    
    # Window 2: Logs (ログ監視)
    tmux new-window -t "$DASHBOARD_SESSION" -n "logs"
    tmux send-keys -t "$DASHBOARD_SESSION:logs" "tail -f $WORKSPACE_DIR/logs/agent-*.log 2>/dev/null || echo 'ログファイルが見つかりません'" Enter
    
    # Window 3: Tasks (タスク管理)
    tmux new-window -t "$DASHBOARD_SESSION" -n "tasks"
    if [[ -f "$SCRIPT_DIR/agent-task.sh" ]]; then
        tmux send-keys -t "$DASHBOARD_SESSION:tasks" "watch -n 5 '$SCRIPT_DIR/agent-task.sh list'" Enter
    else
        tmux send-keys -t "$DASHBOARD_SESSION:tasks" "echo 'タスク管理スクリプトが見つかりません'; echo '$SCRIPT_DIR/agent-task.sh が必要です'" Enter
    fi
    
    # Window 4: Control (エージェント制御)
    tmux new-window -t "$DASHBOARD_SESSION" -n "control"
    tmux send-keys -t "$DASHBOARD_SESSION:control" "echo 'エージェント制御コンソール'; echo ''; echo '使用可能なコマンド:'; echo '  ./scripts/start-agents.sh    - エージェント起動'; echo '  ./scripts/stop-agents.sh     - エージェント停止'; echo '  ./scripts/agent-task.sh      - タスク管理'; echo ''; bash" Enter
    
    # Overview windowのレイアウト設定（4分割）
    tmux select-window -t "$DASHBOARD_SESSION:overview"
    tmux split-window -t "$DASHBOARD_SESSION:overview" -h -p 50
    tmux split-window -t "$DASHBOARD_SESSION:overview.0" -v -p 50
    tmux split-window -t "$DASHBOARD_SESSION:overview.2" -v -p 50
    
    # 各ペインにコマンドを送信
    # Pane 0: 全体ステータス
    tmux select-pane -t "$DASHBOARD_SESSION:overview.0"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" C-c Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "watch -n 2 '/tmp/show-agent-status-temp.sh'" Enter
    
    # Pane 1: システムリソース
    tmux select-pane -t "$DASHBOARD_SESSION:overview.1"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "htop || top" Enter
    
    # Pane 2: Git状態
    tmux select-pane -t "$DASHBOARD_SESSION:overview.2"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "watch -n 5 'cd $WORKSPACE_DIR && git status -s && echo \"\" && git branch -a | grep -E \"(\\*|ai-agent)\"'" Enter
    
    # Pane 3: 最近のレポート
    tmux select-pane -t "$DASHBOARD_SESSION:overview.3"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "watch -n 10 'ls -la $REPORTS_DIR/*.txt 2>/dev/null | tail -10 || echo \"レポートがありません\"'" Enter
    
    echo -e "${GREEN}ダッシュボードの作成が完了しました！${NC}"
    echo ""
    echo -e "${CYAN}ダッシュボードに接続するには:${NC}"
    echo -e "${WHITE}  tmux attach -t $DASHBOARD_SESSION${NC}"
    echo ""
    echo -e "${CYAN}ウィンドウの切り替え:${NC}"
    echo -e "${WHITE}  Ctrl+B, 0-4  : ウィンドウ番号で切り替え${NC}"
    echo -e "${WHITE}  Ctrl+B, n    : 次のウィンドウ${NC}"
    echo -e "${WHITE}  Ctrl+B, p    : 前のウィンドウ${NC}"
    echo ""
    echo -e "${CYAN}ペイン間の移動 (overview window):${NC}"
    echo -e "${WHITE}  Ctrl+B, 矢印キー : ペイン間を移動${NC}"
    echo ""
    echo -e "${CYAN}デタッチ:${NC}"
    echo -e "${WHITE}  Ctrl+B, d    : セッションから切断（バックグラウンドで継続）${NC}"
}

# ステータス表示関数（統合版）
show_agent_status() {
    # ヘッダー表示
    echo -e "${CYAN}======================================${NC}"
    echo -e "${WHITE}   AI Multi-Agent System Dashboard${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo -e "更新時刻: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # エージェントステータス
    echo -e "${YELLOW}[エージェントステータス]${NC}"
    echo -e "-----------------------------------"
    printf "%-20s %-15s %-10s\n" "エージェント" "状態" "セッション名"
    echo -e "-----------------------------------"

    # 各エージェントタイプをチェック
    for agent_type in engineer designer marketer boss; do
        # 最大セッション数を取得
        max_sessions=$(get_max_sessions "$agent_type")
        running_count=0
        
        # 各セッションをチェック
        for i in $(seq 1 "$max_sessions"); do
            session_name="ai-agent-${agent_type}-${i}"
            if tmux has-session -t "$session_name" 2>/dev/null; then
                ((running_count++))
            fi
        done
        
        if [[ $running_count -gt 0 ]]; then
            status="${GREEN}● 稼働中${NC}"
            printf "%-20s %-25s %-10s\n" "$agent_type" "$status" "($running_count/$max_sessions)"
        else
            status="${RED}○ 停止中${NC}"
            printf "%-20s %-25s %-10s\n" "$agent_type" "$status" "(0/$max_sessions)"
        fi
    done

    echo ""

    # タスク統計
    echo -e "${YELLOW}[タスク統計]${NC}"
    echo -e "-----------------------------------"

    # タスクファイルが存在する場合のみ統計を表示
    if [[ -d "$TASKS_DIR" ]] && ls "$TASKS_DIR"/*.task &>/dev/null; then
        pending_count=$(grep -l "STATUS: pending" "$TASKS_DIR"/*.task 2>/dev/null | wc -l || echo "0")
        in_progress_count=$(grep -l "STATUS: in_progress" "$TASKS_DIR"/*.task 2>/dev/null | wc -l || echo "0")
        completed_count=$(grep -l "STATUS: completed" "$TASKS_DIR"/*.task 2>/dev/null | wc -l || echo "0")
        blocked_count=$(grep -l "STATUS: blocked" "$TASKS_DIR"/*.task 2>/dev/null | wc -l || echo "0")
        
        echo -e "保留中:     ${YELLOW}$pending_count${NC}"
        echo -e "進行中:     ${BLUE}$in_progress_count${NC}"
        echo -e "完了:       ${GREEN}$completed_count${NC}"
        echo -e "ブロック:   ${RED}$blocked_count${NC}"
    else
        echo -e "${MAGENTA}タスクがありません${NC}"
    fi

    echo ""

    # システムリソース
    echo -e "${YELLOW}[システムリソース]${NC}"
    echo -e "-----------------------------------"

    # メモリ使用量（macOS対応）
    if command -v vm_stat &>/dev/null; then
        # macOS
        mem_info=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-20s %12.2f MB\n", "$1:", $2 * $size / 1048576);')
        echo "$mem_info" | grep -E "(free:|active:|inactive:|wired:)" | head -4
    else
        # Linux
        free -h | grep -E "^(Mem|Swap)" | awk '{printf "%-15s %10s / %10s\n", $1, $3, $2}'
    fi

    echo ""

    # 実行中のtmuxセッション詳細
    echo -e "${YELLOW}[実行中のセッション]${NC}"
    echo -e "-----------------------------------"
    tmux list-sessions 2>/dev/null | grep "ai-agent" | while IFS= read -r line; do
        echo -e "${GREEN}$line${NC}"
    done || echo -e "${MAGENTA}実行中のセッションはありません${NC}"
}

# メイン処理
main() {
    # ダッシュボードを作成
    create_dashboard
    
    # 自動的にダッシュボードに接続するか確認
    echo ""
    echo -e "${YELLOW}ダッシュボードに接続しますか？ (y/n)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        tmux attach -t "$DASHBOARD_SESSION"
    fi
}

# 引数処理
case "${1:-}" in
    attach)
        # 既存のダッシュボードに接続
        if tmux has-session -t "$DASHBOARD_SESSION" 2>/dev/null; then
            tmux attach -t "$DASHBOARD_SESSION"
        else
            echo -e "${RED}ダッシュボードセッションが見つかりません。${NC}"
            echo -e "${YELLOW}'$0' を実行してダッシュボードを作成してください。${NC}"
            exit 1
        fi
        ;;
    stop)
        # ダッシュボードを停止
        if tmux has-session -t "$DASHBOARD_SESSION" 2>/dev/null; then
            tmux kill-session -t "$DASHBOARD_SESSION"
            echo -e "${GREEN}ダッシュボードを停止しました。${NC}"
        else
            echo -e "${YELLOW}ダッシュボードは起動していません。${NC}"
        fi
        ;;
    *)
        # ダッシュボードを作成
        main
        ;;
esac