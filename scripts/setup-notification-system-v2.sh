#!/bin/bash

# ディレクトリベース通知システムのセットアップスクリプト

echo "=== AI Multi-Agent ディレクトリベース通知システムセットアップ ==="

# 必要なディレクトリの作成
echo "1. 通知ディレクトリの作成..."
mkdir -p notifications/pending
mkdir -p notifications/processed

# スクリプトに実行権限を付与
echo "2. スクリプトの実行権限を設定..."
chmod +x scripts/notification-watcher-v2.sh
chmod +x scripts/send-notification-v2.sh

# 通知監視用のtmuxウィンドウを作成
echo "3. 通知監視ウィンドウの作成..."
if tmux has-session -t "ai-multi-agent" 2>/dev/null; then
    # 既存のnotificationウィンドウがあれば削除
    tmux kill-window -t "ai-multi-agent:notification" 2>/dev/null || true
    
    # 新しいnotificationウィンドウを作成
    tmux new-window -t "ai-multi-agent" -n "notification"
    tmux send-keys -t "ai-multi-agent:notification" "./scripts/notification-watcher-v2.sh" C-m
    
    echo "通知監視ウィンドウが作成されました"
    echo "確認: tmux list-windows -t ai-multi-agent"
else
    echo "警告: ai-multi-agentセッションが存在しません"
    echo "まず ai-multi-agent-dashboard.sh を実行してください"
fi

# 使用方法の表示
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "【ディレクトリ構造】"
echo "notifications/"
echo "├── pending/     # 未処理通知"
echo "└── processed/   # 処理済み通知"
echo ""
echo "【使用方法】"
echo "1. エージェントから通知送信:"
echo "   ./scripts/send-notification-v2.sh engineer-1 'ログイン機能完了'"
echo ""
echo "2. 通知監視状況確認:"
echo "   tmux attach -t ai-multi-agent:notification"
echo ""
echo "3. 通知確認:"
echo "   ls -ltr notifications/pending/    # 未処理通知"
echo "   ls -ltr notifications/processed/  # 処理済み通知"
echo ""
echo "【テスト実行】"
echo "./scripts/send-notification-v2.sh test-agent 'テスト通知です'"
echo ""
echo "【メリット】"
echo "- IOブロックなし"
echo "- 競合回避不要"
echo "- ls -ltr で更新順に処理"
echo "- ファイル単位での確実な処理"