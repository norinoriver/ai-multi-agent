#!/bin/bash

# 16ペインのエージェントダッシュボードを作成するスクリプト

SESSION_NAME="ai-multi-agent"

# MCP設定の同期
echo "MCP設定を確認・同期中..."
if command -v claude &> /dev/null; then
    # claude mcp listでエラーが出る場合は設定が不足している
    if ! claude mcp list &> /dev/null; then
        echo "MCP設定が見つかりません。Claude Desktop設定から同期します..."
        CONFIG_FILE="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
        if [[ -f "$CONFIG_FILE" ]]; then
            jq -c '.mcpServers | to_entries[]' "$CONFIG_FILE" 2>/dev/null | \
            while read -r entry; do
                key=$(echo "$entry" | jq -r '.key')
                value=$(echo "$entry" | jq -c '.value')
                echo "MCPサーバー '$key' を追加中..."
                claude mcp add-json "$key" "$value" 2>/dev/null
            done
            echo "MCP設定の同期が完了しました"
        else
            echo "警告: Claude Desktop設定ファイルが見つかりません"
        fi
    else
        echo "MCP設定は既に存在します"
    fi
fi

# 既存セッションがあれば削除
tmux kill-session -t $SESSION_NAME 2>/dev/null

# 新しいセッションを作成
tmux new-session -d -s $SESSION_NAME

# 16ペインを作成する最もシンプルな方法
# まず15個のペインを追加（元の1個と合わせて16個）
for i in {1..15}; do
    tmux split-window -t $SESSION_NAME
    tmux select-layout -t $SESSION_NAME tiled
done

# 各ペインにエージェント名を表示してClaude Codeを起動
tmux send-keys -t $SESSION_NAME:0.0 "sleep 0.1 && echo 'Pane 0: Boss' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo 'Pane 1: Engineer-1' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo 'Pane 2: Engineer-2' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.3 "echo 'Pane 3: Engineer-3' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.4 "echo 'Pane 4: Engineer-4' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.5 "echo 'Pane 5: Engineer-5' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.6 "echo 'Pane 6: Engineer-6' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.7 "echo 'Pane 7: Engineer-7' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.8 "echo 'Pane 8: Engineer-8' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.9 "echo 'Pane 9: Engineer-9' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.10 "echo 'Pane 10: Engineer-10' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.11 "echo 'Pane 11: Designer-1' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.12 "echo 'Pane 12: Designer-2' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.13 "echo 'Pane 13: Marketer-1' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.14 "echo 'Pane 14: Marketer-2' && sleep 0.1 && claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION_NAME:0.15 "echo 'Pane 15: Notification Monitor' && sleep 0.1 && ./scripts/notification-watcher-v2.sh" C-m


echo "セッション '$SESSION_NAME' を作成しました（16ペイン）"

# 自動的にセッションにアタッチ
tmux attach -t $SESSION_NAME