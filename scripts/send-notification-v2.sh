#!/bin/bash

# ディレクトリベースの通知送信スクリプト
# 各通知を個別ファイルとして作成

NOTIFICATION_DIR="notifications"
PENDING_DIR="$NOTIFICATION_DIR/pending"

# 使用方法
usage() {
    echo "使用方法: $0 <from_agent> <message>"
    echo "例: $0 engineer-1 'ログイン機能の実装が完了しました'"
    echo "例: $0 designer-1 'UI設計が完了しました'"
    exit 1
}

# 引数チェック
if [ $# -lt 2 ]; then
    usage
fi

FROM_AGENT="$1"
MESSAGE="${@:2}"

# 必要なディレクトリの作成
mkdir -p "$PENDING_DIR"

# 通知ファイル名の作成（タイムスタンプ + エージェント名）
TIMESTAMP=$(date +%Y%m%d_%H%M%S_%N)
NOTIFICATION_FILE="$PENDING_DIR/${TIMESTAMP}_${FROM_AGENT}.txt"

# 通知内容の作成
NOTIFICATION_TIME=$(date -Iseconds)
NOTIFICATION_MESSAGE="[$FROM_AGENT] $MESSAGE (完了時刻: $NOTIFICATION_TIME)"

# 通知ファイルの作成（アトミック操作）
echo "$NOTIFICATION_MESSAGE" > "$NOTIFICATION_FILE"

echo "通知送信完了: $NOTIFICATION_FILE"
echo "内容: $NOTIFICATION_MESSAGE"