#!/bin/bash

# エージェントに役割を定期的に思い出させるスクリプト

SESSION_NAME="ai-multi-agent"

# 使用方法を表示
usage() {
    echo "使用方法: $0 [all|boss|engineer|designer|marketer|overview]"
    echo "例: $0 all           # 全エージェントに役割を再通知"
    echo "例: $0 engineer      # エンジニアのみに役割を再通知"
    exit 1
}

# セッションが存在するか確認
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "エラー: セッション '$SESSION_NAME' が存在しません"
    exit 1
fi

# 引数が指定されていない場合は使用方法を表示
if [ $# -eq 0 ]; then
    usage
fi

TARGET="$1"

# 役割リマインダーメッセージを送信
remind_agent() {
    local pane_num="$1"
    local role_file="$2"
    local role_name="$3"
    
    local message="【役割リマインダー】$role_file を再度確認して、$role_name としての役割を思い出してください。これまでの作業を継続しつつ、役割に沿った行動をお願いします。"
    
    tmux send-keys -t "$SESSION_NAME:0.$pane_num" "$message"
    tmux send-keys -t "$SESSION_NAME:0.$pane_num" Enter
}

case "$TARGET" in
    all)
        echo "全エージェントに役割を再通知しています..."
        remind_agent 0 "agents/boss/CLAUDE.md" "ボス"
        for i in {1..10}; do
            remind_agent $i "agents/engineer/CLAUDE.md" "エンジニア"
        done
        remind_agent 11 "agents/designer/CLAUDE.md" "デザイナー"
        remind_agent 12 "agents/designer/CLAUDE.md" "デザイナー"
        remind_agent 13 "agents/marketer/CLAUDE.md" "マーケター"
        remind_agent 14 "agents/marketer/CLAUDE.md" "マーケター"
        tmux send-keys -t "$SESSION_NAME:0.15" "【役割リマインダー】あなたは全体の進捗を俯瞰するOverviewエージェントです。各エージェントの状況をまとめて報告してください。"
        tmux send-keys -t "$SESSION_NAME:0.15" Enter
        ;;
    boss)
        echo "ボスに役割を再通知しています..."
        remind_agent 0 "agents/boss/CLAUDE.md" "ボス"
        ;;
    engineer)
        echo "エンジニアに役割を再通知しています..."
        for i in {1..10}; do
            remind_agent $i "agents/engineer/CLAUDE.md" "エンジニア"
        done
        ;;
    designer)
        echo "デザイナーに役割を再通知しています..."
        remind_agent 11 "agents/designer/CLAUDE.md" "デザイナー"
        remind_agent 12 "agents/designer/CLAUDE.md" "デザイナー"
        ;;
    marketer)
        echo "マーケターに役割を再通知しています..."
        remind_agent 13 "agents/marketer/CLAUDE.md" "マーケター"
        remind_agent 14 "agents/marketer/CLAUDE.md" "マーケター"
        ;;
    overview)
        echo "Overviewエージェントに役割を再通知しています..."
        tmux send-keys -t "$SESSION_NAME:0.15" "【役割リマインダー】あなたは全体の進捗を俯瞰するOverviewエージェントです。各エージェントの状況をまとめて報告してください。"
        tmux send-keys -t "$SESSION_NAME:0.15" Enter
        ;;
    *)
        echo "エラー: 無効な対象です"
        usage
        ;;
esac

echo "役割リマインダーを送信しました"