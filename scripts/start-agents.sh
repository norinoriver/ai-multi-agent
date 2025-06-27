#!/bin/bash

# AI Multi-Agent Development System - エージェント起動スクリプト

# 設定
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="$WORKSPACE_DIR/agents"
WORKTREES_DIR="$WORKSPACE_DIR/worktrees"
TMUX_PREFIX="ai-agent"

# ファイルディスクリプタ上限の設定
ulimit -n 4096

# 色付き出力用の関数
print_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# エージェントタイプの配列
AGENT_TYPES=("boss" "engineer" "designer" "marketer")

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
    
    # セッションが既に存在するか確認
    if tmux has-session -t "$session_name" 2>/dev/null; then
        print_info "セッション $session_name は既に存在します"
    else
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
            tmux send-keys -t "$session_name" "cat CLAUDE.md | head -50" Enter
            tmux send-keys -t "$session_name" "echo ''" Enter
            tmux send-keys -t "$session_name" "echo '※ 完全な指示書は CLAUDE.md を参照してください'" Enter
            tmux send-keys -t "$session_name" "echo ''" Enter
        fi
        
        # 環境変数の設定
        tmux send-keys -t "$session_name" "export AGENT_TYPE=$agent_type" Enter
        tmux send-keys -t "$session_name" "export AGENT_NUMBER=$session_number" Enter
        tmux send-keys -t "$session_name" "export WORKSPACE_DIR='$WORKSPACE_DIR'" Enter
        
        # Claude Codeの起動準備メッセージ
        tmux send-keys -t "$session_name" "echo 'Claude Codeを起動する準備ができました。'" Enter
        tmux send-keys -t "$session_name" "echo '以下のコマンドでClaude Codeを起動してください:'" Enter
        tmux send-keys -t "$session_name" "echo '  claude'" Enter
        tmux send-keys -t "$session_name" "echo ''" Enter
        tmux send-keys -t "$session_name" "echo 'タスクを確認するには:'" Enter
        tmux send-keys -t "$session_name" "echo '  $WORKSPACE_DIR/scripts/agent-task.sh list $agent_type'" Enter
        
        print_success "セッション $session_name を起動しました"
    fi
}

# メイン処理
main() {
    print_info "AI Multi-Agent Development System を起動します..."
    
    # 引数の処理
    if [ $# -eq 0 ]; then
        # デフォルト起動（各エージェント1つずつ）
        for agent_type in "${AGENT_TYPES[@]}"; do
            start_agent_session "$agent_type" 1
        done
    elif [ $# -eq 2 ]; then
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
        echo "使用方法:"
        echo "  $0                    # 各エージェントを1つずつ起動"
        echo "  $0 <agent_type> <count>  # 特定のエージェントを指定数起動"
        echo ""
        echo "エージェントタイプ: ${AGENT_TYPES[@]}"
        exit 1
    fi
    
    print_info "起動完了！"
    echo ""
    echo "セッション一覧:"
    tmux list-sessions | grep "$TMUX_PREFIX"
    echo ""
    echo "セッションに接続するには:"
    echo "  tmux attach -t <session_name>"
    echo ""
    echo "ダッシュボードを起動するには:"
    echo "  $WORKSPACE_DIR/scripts/agent-dashboard.sh"
    echo ""
    echo "エージェントを停止するには:"
    echo "  $WORKSPACE_DIR/scripts/stop-agents.sh"
}

# スクリプトの実行
main "$@"