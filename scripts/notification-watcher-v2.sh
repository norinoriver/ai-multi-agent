#!/bin/bash

# ディレクトリベースの通知監視スクリプト
# 各通知を個別ファイルとして作成し、ls -ltrで更新順に処理

# スクリプト自身のディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFICATION_DIR="$SCRIPT_DIR/../notifications"
PENDING_DIR="$NOTIFICATION_DIR/pending"
PROCESSED_DIR="$NOTIFICATION_DIR/processed"
BOSS_PANE="ai-multi-agent:0.0"
CHECK_INTERVAL=10

# 必要なディレクトリの作成
mkdir -p "$PENDING_DIR" "$PROCESSED_DIR"

# Bossペインの存在確認
check_boss_pane() {
    if ! tmux has-session -t "ai-multi-agent" 2>/dev/null; then
        echo "エラー: ai-multi-agentセッションが存在しません"
        return 1
    fi
    
    if ! tmux list-panes -t "ai-multi-agent:0" 2>/dev/null | grep -q "^0:"; then
        echo "エラー: Bossペイン(0.0)が存在しません"
        return 1
    fi
    
    return 0
}

# 通知をBossに送信
send_notification_to_boss() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Bossペインに通知表示
    tmux send-keys -t "$BOSS_PANE" "echo '【🔔通知 $timestamp】$message'" C-m && sleep 0.1 && tmux send-keys -t "$BOSS_PANE" "Enter"
    
    echo "[$timestamp] Bossに通知送信: $message"
}

# 通知ディレクトリの処理
process_notifications() {
    # pending ディレクトリ内のファイルを更新順に取得
    local files=($(ls -ltr "$PENDING_DIR" 2>/dev/null | awk 'NR>1 {print $NF}'))
    
    if [ ${#files[@]} -eq 0 ]; then
        return 0
    fi
    
    echo "新しい通知を ${#files[@]} 件検出しました"
    
    # 各通知ファイルを処理
    for file in "${files[@]}"; do
        local notification_file="$PENDING_DIR/$file"
        
        if [[ -f "$notification_file" ]]; then
            # 通知内容を読み取り
            local message=$(cat "$notification_file")
            
            # Bossに通知送信
            send_notification_to_boss "$message"
            
            # 処理済みディレクトリに移動
            mv "$notification_file" "$PROCESSED_DIR/"
            
            echo "処理完了: $file → processed/"
        fi
    done
}

# メイン監視ループ
main() {
    echo "ディレクトリベース通知監視開始: $CHECK_INTERVAL秒間隔でチェック"
    echo "監視ディレクトリ: $PENDING_DIR"
    echo "処理済みディレクトリ: $PROCESSED_DIR"
    echo "Bossペイン: $BOSS_PANE"
    
    # 初期チェック
    if ! check_boss_pane; then
        echo "監視を開始できません"
        exit 1
    fi
    
    # 監視ループ
    while true; do
        process_notifications
        sleep "$CHECK_INTERVAL"
    done
}

# シグナルハンドラ
cleanup() {
    echo "通知監視を停止します..."
    exit 0
}

trap cleanup SIGINT SIGTERM

# スクリプト実行
main "$@"