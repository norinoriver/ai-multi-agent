#!/bin/bash

# AI Multi-Agent Development System - 統合管理スクリプト
# エージェントの起動とダッシュボード表示を統合

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 設定
AGENTS_DIR="$WORKSPACE_DIR/agents"
TASKS_DIR="$WORKSPACE_DIR/tasks"
REPORTS_DIR="$WORKSPACE_DIR/reports"
LOGS_DIR="$WORKSPACE_DIR/logs"
TMUX_PREFIX="ai-agent"
DASHBOARD_SESSION="ai-agent-dashboard"

# エージェントタイプの配列
AGENT_TYPES=("boss" "engineer" "designer" "marketer")

# ファイルディスクリプタ上限の設定
ulimit -n 4096

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 色付き出力用の関数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 最大セッション数を取得する関数
get_max_sessions() {
    local agent_type=$1
    case "$agent_type" in
        engineer) echo "10" ;;
        designer) echo "2" ;;
        marketer) echo "2" ;;
        boss) echo "1" ;;
        *) echo "1" ;;
    esac
}

# tmuxセッションの起動関数
start_agent_session() {
    local agent_type=$1
    local session_number=$2
    local session_name="${TMUX_PREFIX}-${agent_type}-${session_number}"
    local work_dir="$AGENTS_DIR/$agent_type"
    local claude_md="$work_dir/CLAUDE.md"
    
    # 作業ディレクトリの確認
    if [ ! -d "$work_dir" ]; then
        mkdir -p "$work_dir"
    fi
    
    # 既存のセッションがある場合は削除して再作成
    if tmux has-session -t "$session_name" 2>/dev/null; then
        print_info "既存のセッション $session_name を削除して再作成します"
        tmux kill-session -t "$session_name"
    fi
    
    # 新しいtmuxセッションを作成
    tmux new-session -d -s "$session_name" -c "$work_dir"
    
    # 基本情報の表示
    tmux send-keys -t "$session_name" "cd $work_dir" Enter
    tmux send-keys -t "$session_name" "echo '==================================='" Enter
    tmux send-keys -t "$session_name" "echo 'AI Multi-Agent Development System'" Enter
    tmux send-keys -t "$session_name" "echo 'エージェント: $agent_type-$session_number'" Enter
    tmux send-keys -t "$session_name" "echo '作業ディレクトリ: $work_dir'" Enter
    tmux send-keys -t "$session_name" "echo '==================================='" Enter
    tmux send-keys -t "$session_name" "echo ''" Enter
    
    # CLAUDE.mdファイルが存在する場合は表示
    if [ -f "$claude_md" ]; then
        tmux send-keys -t "$session_name" "echo '指示書を確認しています...'" Enter
        tmux send-keys -t "$session_name" "cat CLAUDE.md | head -20" Enter
        tmux send-keys -t "$session_name" "echo ''" Enter
        tmux send-keys -t "$session_name" "echo '※ 完全な指示書は CLAUDE.md を参照してください'" Enter
        tmux send-keys -t "$session_name" "echo ''" Enter
    fi
    
    # 環境変数の設定
    tmux send-keys -t "$session_name" "export AGENT_TYPE=$agent_type" Enter
    tmux send-keys -t "$session_name" "export AGENT_NUMBER=$session_number" Enter
    tmux send-keys -t "$session_name" "export WORKSPACE_DIR='$WORKSPACE_DIR'" Enter
    
    # Claude Codeを自動起動
    tmux send-keys -t "$session_name" "echo 'Claude Codeを起動しています...'" Enter
    tmux send-keys -t "$session_name" "echo ''" Enter
    tmux send-keys -t "$session_name" "claude" Enter
    
    print_success "セッション $session_name を起動しました"
}

# エージェントセッションを停止
stop_session() {
    local session_name=$1
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${YELLOW}停止中: $session_name${NC}"
        tmux kill-session -t "$session_name"
        echo -e "${GREEN}✓ 停止完了: $session_name${NC}"
    else
        echo -e "${RED}✗ セッションが見つかりません: $session_name${NC}"
    fi
}

# ステータス表示関数
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

    # 各エージェントタイプをチェック (新しい構成)
    # Boss: 1人
    boss_count=0
    if tmux has-session -t "ai-agent-boss-1" 2>/dev/null; then
        boss_count=1
    fi
    status_boss="${RED}○ 停止中${NC}"
    if [[ $boss_count -gt 0 ]]; then
        status_boss="${GREEN}● 稼働中${NC}"
    fi
    printf "%-20s %-25s %-10s\n" "boss" "$status_boss" "($boss_count/1)"
    
    # Engineer: 10人
    engineer_count=0
    for i in {1..10}; do
        if tmux has-session -t "ai-agent-engineer-$i" 2>/dev/null; then
            ((engineer_count++))
        fi
    done
    status_engineer="${RED}○ 停止中${NC}"
    if [[ $engineer_count -gt 0 ]]; then
        status_engineer="${GREEN}● 稼働中${NC}"
    fi
    printf "%-20s %-25s %-10s\n" "engineer" "$status_engineer" "($engineer_count/10)"
    
    # Designer: 2人
    designer_count=0
    for i in {1..2}; do
        if tmux has-session -t "ai-agent-designer-$i" 2>/dev/null; then
            ((designer_count++))
        fi
    done
    status_designer="${RED}○ 停止中${NC}"
    if [[ $designer_count -gt 0 ]]; then
        status_designer="${GREEN}● 稼働中${NC}"
    fi
    printf "%-20s %-25s %-10s\n" "designer" "$status_designer" "($designer_count/2)"
    
    # Marketer: 2人
    marketer_count=0
    for i in {1..2}; do
        if tmux has-session -t "ai-agent-marketer-$i" 2>/dev/null; then
            ((marketer_count++))
        fi
    done
    status_marketer="${RED}○ 停止中${NC}"
    if [[ $marketer_count -gt 0 ]]; then
        status_marketer="${GREEN}● 稼働中${NC}"
    fi
    printf "%-20s %-25s %-10s\n" "marketer" "$status_marketer" "($marketer_count/2)"

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

    # 実行中のtmuxセッション詳細
    echo -e "${YELLOW}[実行中のセッション]${NC}"
    echo -e "-----------------------------------"
    tmux list-sessions 2>/dev/null | grep "ai-agent" | while IFS= read -r line; do
        echo -e "${GREEN}$line${NC}"
    done || echo -e "${MAGENTA}実行中のセッションはありません${NC}"
}

# ダッシュボードを作成
create_dashboard() {
    # 既存のダッシュボードセッションがあれば削除
    if tmux has-session -t "$DASHBOARD_SESSION" 2>/dev/null; then
        print_warning "既存のダッシュボードセッションを削除しています..."
        tmux kill-session -t "$DASHBOARD_SESSION"
    fi
    
    print_info "ダッシュボードを作成しています..."
    
    # 新しいダッシュボードセッションを作成
    tmux new-session -d -s "$DASHBOARD_SESSION" -n "overview"
    
    # Window 1: Overview (概要とステータス)
    # 一時的なスクリプトファイルを作成
    cat > "/tmp/show-agent-status-temp.sh" << EOF
#!/bin/bash
cd "$WORKSPACE_DIR"
source "$SCRIPT_DIR/ai-multi-agent.sh"
show_agent_status
EOF
    chmod +x "/tmp/show-agent-status-temp.sh"
    tmux send-keys -t "$DASHBOARD_SESSION:overview" "watch -n 2 '/tmp/show-agent-status-temp.sh'" Enter
    
    # Window 2: Logs (ログ監視)
    tmux new-window -t "$DASHBOARD_SESSION" -n "logs"
    if [[ -d "$LOGS_DIR" ]]; then
        tmux send-keys -t "$DASHBOARD_SESSION:logs" "tail -f $LOGS_DIR/agent-*.log 2>/dev/null || echo 'ログファイルが見つかりません'" Enter
    else
        tmux send-keys -t "$DASHBOARD_SESSION:logs" "echo 'ログディレクトリが見つかりません: $LOGS_DIR'" Enter
    fi
    
    # Window 3: Tasks (タスク管理)
    tmux new-window -t "$DASHBOARD_SESSION" -n "tasks"
    if [[ -f "$SCRIPT_DIR/agent-task.sh" ]]; then
        tmux send-keys -t "$DASHBOARD_SESSION:tasks" "watch -n 5 '$SCRIPT_DIR/agent-task.sh list'" Enter
    else
        tmux send-keys -t "$DASHBOARD_SESSION:tasks" "echo 'タスク管理機能はまだ実装されていません'" Enter
    fi
    
    # Window 4: Engineers (Engineer専用 - 4分割表示)
    tmux new-window -t "$DASHBOARD_SESSION" -n "engineers"
    
    # 4分割レイアウト (Engineer 1-4を表示)
    tmux split-window -t "$DASHBOARD_SESSION:engineers" -h -p 50
    tmux split-window -t "$DASHBOARD_SESSION:engineers.0" -v -p 50
    tmux split-window -t "$DASHBOARD_SESSION:engineers.2" -v -p 50
    
    # Engineer 1-4を各ペインに配置
    for i in {0..3}; do
        engineer_num=$((i + 1))
        tmux select-pane -t "$DASHBOARD_SESSION:engineers.$i"
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "clear" Enter
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "echo '┌─────────────────────────────┐'" Enter
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "echo '│       ⚡ ENGINEER-$engineer_num         │'" Enter
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "echo '│      フルスタック開発        │'" Enter
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "echo '│  (残り6人は個別接続可能)     │'" Enter
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "echo '└─────────────────────────────┘'" Enter
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "cd $AGENTS_DIR/engineer" Enter
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "export AGENT_TYPE=engineer AGENT_NUMBER=$engineer_num WORKSPACE_DIR='$WORKSPACE_DIR'" Enter
        tmux send-keys -t "$DASHBOARD_SESSION:engineers.$i" "claude --dangerously-skip-permissions" Enter
    done
    
    # Window 5: Control (エージェント制御)
    tmux new-window -t "$DASHBOARD_SESSION" -n "control"
    tmux send-keys -t "$DASHBOARD_SESSION:control" "echo 'エージェント制御コンソール'; echo ''; echo '使用可能なコマンド:'; echo '  $SCRIPT_DIR/ai-multi-agent.sh start     - エージェント起動'; echo '  $SCRIPT_DIR/ai-multi-agent.sh stop      - エージェント停止'; echo '  $SCRIPT_DIR/ai-multi-agent.sh status    - ステータス確認'; echo ''; bash" Enter
    
    # マウス操作を有効化
    tmux set-option -t "$DASHBOARD_SESSION" mouse on
    
    # Overview windowで6分割レイアウト（画面サイズに配慮）
    tmux select-window -t "$DASHBOARD_SESSION:overview"
    
    # 6ペインを作成（2行3列）
    tmux split-window -t "$DASHBOARD_SESSION:overview" -h  # ペイン1
    tmux split-window -t "$DASHBOARD_SESSION:overview.0" -v  # ペイン2 
    tmux split-window -t "$DASHBOARD_SESSION:overview.1" -v  # ペイン3
    tmux split-window -t "$DASHBOARD_SESSION:overview.2" -h  # ペイン4
    tmux split-window -t "$DASHBOARD_SESSION:overview.3" -h  # ペイン5
    
    # レイアウトを調整
    tmux select-layout -t "$DASHBOARD_SESSION:overview" tiled
    
    # 全15エージェントを配置
    declare -a all_agents=(
        "boss:1:🎯:ボス"
        "engineer:1:⚡:エンジニア1"
        "engineer:2:⚡:エンジニア2"  
        "engineer:3:⚡:エンジニア3"
        "engineer:4:⚡:エンジニア4"
        "engineer:5:⚡:エンジニア5"
        "engineer:6:⚡:エンジニア6"
        "engineer:7:⚡:エンジニア7"
        "engineer:8:⚡:エンジニア8"
        "engineer:9:⚡:エンジニア9"
        "engineer:10:⚡:エンジニア10"
        "designer:1:🎨:デザイナー1"
        "designer:2:🎨:デザイナー2"
        "marketer:1:📈:マーケター1"
        "marketer:2:📈:マーケター2"
    )
    
    # 6ペインに主要エージェントとリストを配置
    # ペイン0: Boss
    tmux select-pane -t "$DASHBOARD_SESSION:overview.0"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "clear" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "echo '┌─────────────────┐'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "echo '│  🎯 BOSS (ボス)  │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "echo '│   プロジェクト   │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "echo '│     管理者       │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "echo '└─────────────────┘'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "cd $AGENTS_DIR/boss" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "export AGENT_TYPE=boss AGENT_NUMBER=1 WORKSPACE_DIR='$WORKSPACE_DIR'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.0" "claude --dangerously-skip-permissions" Enter
    
    # ペイン1: Engineer 1
    tmux select-pane -t "$DASHBOARD_SESSION:overview.1"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "clear" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "echo '┌──────────────────┐'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "echo '│ ⚡ ENGINEER-1    │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "echo '│  フルスタック開発 │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "echo '└──────────────────┘'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "cd $AGENTS_DIR/engineer" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "export AGENT_TYPE=engineer AGENT_NUMBER=1 WORKSPACE_DIR='$WORKSPACE_DIR'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.1" "claude --dangerously-skip-permissions" Enter
    
    # ペイン2: Engineer 2
    tmux select-pane -t "$DASHBOARD_SESSION:overview.2"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "clear" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "echo '┌──────────────────┐'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "echo '│ ⚡ ENGINEER-2    │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "echo '│  バックエンド開発 │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "echo '└──────────────────┘'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "cd $AGENTS_DIR/engineer" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "export AGENT_TYPE=engineer AGENT_NUMBER=2 WORKSPACE_DIR='$WORKSPACE_DIR'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.2" "claude --dangerously-skip-permissions" Enter
    
    # ペイン3: Designer 1
    tmux select-pane -t "$DASHBOARD_SESSION:overview.3"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "clear" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "echo '┌──────────────────┐'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "echo '│ 🎨 DESIGNER-1    │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "echo '│   UI/UX設計      │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "echo '└──────────────────┘'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "cd $AGENTS_DIR/designer" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "export AGENT_TYPE=designer AGENT_NUMBER=1 WORKSPACE_DIR='$WORKSPACE_DIR'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.3" "claude --dangerously-skip-permissions" Enter
    
    # ペイン4: Marketer 1
    tmux select-pane -t "$DASHBOARD_SESSION:overview.4"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.4" "clear" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.4" "echo '┌──────────────────┐'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.4" "echo '│ 📈 MARKETER-1    │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.4" "echo '│  コンテンツ作成   │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.4" "echo '└──────────────────┘'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.4" "cd $AGENTS_DIR/marketer" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.4" "export AGENT_TYPE=marketer AGENT_NUMBER=1 WORKSPACE_DIR='$WORKSPACE_DIR'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.4" "claude --dangerously-skip-permissions" Enter
    
    # ペイン5: 全エージェント一覧
    tmux select-pane -t "$DASHBOARD_SESSION:overview.5"
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "clear" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo '┌──────────────────┐'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo '│ 🔄 全エージェント │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo '│     一覧表示     │'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo '└──────────────────┘'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo 'Engineer: 1-10人'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo 'Designer: 1-2人'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo 'Marketer: 1-2人'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo 'Boss: 1人'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo ''" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo '個別接続:'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo 'tmux attach -t ai-agent-engineer-[1-10]'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo 'tmux attach -t ai-agent-designer-[1-2]'" Enter
    tmux send-keys -t "$DASHBOARD_SESSION:overview.5" "echo 'tmux attach -t ai-agent-marketer-[1-2]'" Enter
    
    print_success "ダッシュボードの作成が完了しました！"
    echo ""
    echo -e "${CYAN}=== AI Multi-Agent Dashboard ====${NC}"
    echo -e "${WHITE}総エージェント数: 15人 (Boss1人、Engineer10人、Designer2人、Marketer2人)${NC}"
    echo ""
    echo -e "${CYAN}ダッシュボードに接続するには:${NC}"
    echo -e "${WHITE}  tmux attach -t $DASHBOARD_SESSION${NC}"
    echo ""
    echo -e "${CYAN}ウィンドウ構成:${NC}"
    echo -e "${WHITE}  0: overview   - 主要エージェント表示 (6分割: Boss+主要メンバー+リスト)${NC}"
    echo -e "${WHITE}  1: logs      - ログ監視${NC}"
    echo -e "${WHITE}  2: tasks     - タスク管理${NC}"
    echo -e "${WHITE}  3: engineers - Engineer専用 (4分割: Engineer 1-4)${NC}"
    echo -e "${WHITE}  4: control   - エージェント制御${NC}"
    echo ""
    echo -e "${CYAN}6分割メインダッシュボード (overview画面):${NC}"
    echo -e "${WHITE}  ┌─────────────┬─────────────┬─────────────┐${NC}"
    echo -e "${WHITE}  │ 🎯 Boss     │ ⚡ Engineer-1│ ⚡ Engineer-2│${NC}"
    echo -e "${WHITE}  │ (管理者)     │ (フルスタック) │ (バックエンド) │${NC}"
    echo -e "${WHITE}  ├─────────────┼─────────────┼─────────────┤${NC}"
    echo -e "${WHITE}  │ 🎨 Designer-1│ 📈 Marketer-1│ 🔄 全一覧    │${NC}"
    echo -e "${WHITE}  │ (UI/UX設計)  │ (コンテンツ)  │ (接続情報)   │${NC}"
    echo -e "${WHITE}  └─────────────┴─────────────┴─────────────┘${NC}"
    echo -e "${WHITE}  🎯 Boss${NC}"
    echo -e "${WHITE}  ⚡ Engineer 1-10${NC}"
    echo -e "${WHITE}  🎨 Designer 1-2${NC}"
    echo -e "${WHITE}  📈 Marketer 1-2${NC}"
    echo ""
    echo -e "${CYAN}操作方法:${NC}"
    echo -e "${WHITE}  Ctrl+B, 0-4     : ウィンドウ切り替え${NC}"
    echo -e "${WHITE}  Ctrl+B, 矢印キー : ペイン間移動${NC}"
    echo -e "${WHITE}  Ctrl+B, n/p     : 次/前のウィンドウ${NC}"
    echo -e "${WHITE}  Ctrl+B, d       : デタッチ${NC}"
}

# エージェント起動
start_agents() {
    print_info "AI Multi-Agent Development System を起動します..."
    
    # 引数の処理
    if [[ ${#@} -eq 0 ]]; then
        # デフォルト起動（engineerは10人、他は1つずつ）
        print_info "デフォルト起動: Engineer10人、Designer2人、Marketer2人、Boss1人"
        
        # Boss: 1人
        print_info "起動中: boss エージェント (1人)"
        start_agent_session "boss" 1
        
        # Engineer: 10人
        print_info "起動中: engineer エージェント (10人)"
        for i in {1..10}; do
            start_agent_session "engineer" "$i"
        done
        
        # Designer: 2人
        print_info "起動中: designer エージェント (2人)"
        for i in {1..2}; do
            start_agent_session "designer" "$i"
        done
        
        # Marketer: 2人
        print_info "起動中: marketer エージェント (2人)"
        for i in {1..2}; do
            start_agent_session "marketer" "$i"
        done
    elif [[ ${#@} -eq 2 ]]; then
        # 特定のエージェントタイプと数を指定
        agent_type=$1
        count=$2
        
        # エージェントタイプの検証
        if [[ ! " ${AGENT_TYPES[@]} " =~ " ${agent_type} " ]]; then
            print_error "無効なエージェントタイプ: $agent_type"
            echo "有効なタイプ: ${AGENT_TYPES[@]}"
            exit 1
        fi
        
        # 指定された数だけセッションを起動
        for ((i=1; i<=count; i++)); do
            start_agent_session "$agent_type" "$i"
        done
    else
        print_error "引数が正しくありません"
        show_usage
        exit 1
    fi
    
    print_success "エージェント起動完了！"
    echo ""
    echo "起動中のセッション:"
    tmux list-sessions | grep "$TMUX_PREFIX" || echo "なし"
}

# エージェント停止
stop_agents() {
    if [[ $# -eq 0 ]]; then
        # 全エージェントを停止
        print_info "全エージェントを停止しています..."
        echo ""
        
        # 現在起動中のエージェントセッションを確認
        local sessions=$(tmux list-sessions 2>/dev/null | grep "ai-agent" | cut -d: -f1 || true)
        
        if [[ -z "$sessions" ]]; then
            print_warning "起動中のエージェントセッションが見つかりません。"
            exit 0
        fi
        
        # 各セッションを停止
        while IFS= read -r session; do
            stop_session "$session"
        done <<< "$sessions"
        
        print_success "全エージェントの停止が完了しました。"
        
    elif [[ $# -eq 1 ]]; then
        # 特定タイプの全エージェントを停止
        local agent_type=$1
        
        # agent_typeの検証
        if [[ ! " ${AGENT_TYPES[@]} " =~ " $agent_type " ]]; then
            print_error "無効なエージェントタイプ '$agent_type'"
            show_usage
            exit 1
        fi
        
        print_info "${agent_type}エージェントを停止しています..."
        echo ""
        
        # 該当するセッションを検索して停止
        local sessions=$(tmux list-sessions 2>/dev/null | grep "ai-agent-${agent_type}" | cut -d: -f1 || true)
        
        if [[ -z "$sessions" ]]; then
            print_warning "起動中の${agent_type}エージェントが見つかりません。"
            exit 0
        fi
        
        while IFS= read -r session; do
            stop_session "$session"
        done <<< "$sessions"
        
        print_success "${agent_type}エージェントの停止が完了しました。"
        
    elif [[ $# -eq 2 ]]; then
        # 特定のエージェントを停止
        local agent_type=$1
        local agent_id=$2
        local session_name="ai-agent-${agent_type}-${agent_id}"
        
        # agent_typeの検証
        if [[ ! " ${AGENT_TYPES[@]} " =~ " $agent_type " ]]; then
            print_error "無効なエージェントタイプ '$agent_type'"
            show_usage
            exit 1
        fi
        
        # agent_idが数字かチェック
        if ! [[ "$agent_id" =~ ^[0-9]+$ ]]; then
            print_error "エージェントIDは数字である必要があります。"
            show_usage
            exit 1
        fi
        
        stop_session "$session_name"
        
    else
        print_error "引数が多すぎます。"
        show_usage
        exit 1
    fi
}

# 使用方法を表示
show_usage() {
    echo "AI Multi-Agent Development System - 統合管理ツール"
    echo ""
    echo "使用方法:"
    echo "  $0 start [agent_type] [count]  # エージェントを起動してダッシュボードを表示"
    echo "  $0 stop [agent_type] [id]      # エージェントを停止"
    echo "  $0 dashboard                   # ダッシュボードのみを表示"
    echo "  $0 status                      # 現在の状態を表示"
    echo ""
    echo "例:"
    echo "  $0 start                       # 全エージェントを起動してダッシュボード表示"
    echo "  $0 start engineer 3            # エンジニアを3つ起動してダッシュボード表示"
    echo "  $0 stop                        # 全エージェントを停止"
    echo "  $0 stop engineer               # エンジニアエージェントのみ停止"
    echo "  $0 stop engineer 1             # エンジニア1番のみ停止"
    echo ""
    echo "エージェントタイプ: ${AGENT_TYPES[@]}"
}

# メイン処理
main() {
    case "${1:-start}" in
        start)
            # エージェント起動
            shift
            start_agents "$@"
            
            # ダッシュボードを作成して接続
            echo ""
            print_info "ダッシュボードを起動します..."
            create_dashboard
            
            echo ""
            echo -e "${YELLOW}ダッシュボードに接続しますか？ (y/n)${NC}"
            read -r response
            
            if [[ "$response" =~ ^[Yy]$ ]]; then
                tmux attach -t "$DASHBOARD_SESSION"
            else
                echo ""
                echo -e "${CYAN}後でダッシュボードに接続するには:${NC}"
                echo -e "${WHITE}  tmux attach -t $DASHBOARD_SESSION${NC}"
            fi
            ;;
        stop)
            shift
            stop_agents "$@"
            ;;
        dashboard)
            create_dashboard
            tmux attach -t "$DASHBOARD_SESSION"
            ;;
        status)
            show_agent_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "無効なコマンド: $1"
            show_usage
            exit 1
            ;;
    esac
}

# スクリプトの実行
main "$@"