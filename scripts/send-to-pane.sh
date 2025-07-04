#!/bin/bash

# Claude Code対応のペイン送信コマンド

# 使用方法を表示
usage() {
    echo "使用方法: $0 <agent_type> <agent_number> <message> [--with-role-reminder]"
    echo "例: $0 engineer 1 'ログイン機能を実装してください'"
    echo "例: $0 engineer 1 'ログイン機能を実装してください' --with-role-reminder"
    echo ""
    echo "エージェントタイプ:"
    echo "  - boss"
    echo "  - engineer (1-10)"
    echo "  - designer (1-2)"
    echo "  - marketer (1-2)"
    echo "  - notification"
    echo ""
    echo "オプション:"
    echo "  --with-role-reminder : メッセージ送信前に役割を思い出させる"
    exit 1
}

# 引数チェック
if [ $# -lt 3 ]; then
    usage
fi

AGENT_TYPE="$1"
AGENT_NUM="$2"

# 役割リマインダーオプションをチェック
WITH_ROLE_REMINDER=false
if [[ "${@: -1}" == "--with-role-reminder" ]]; then
    WITH_ROLE_REMINDER=true
    MESSAGE="${@:3:$(($#-3))}"  # 最後の引数を除いてメッセージとして結合
else
    MESSAGE="${@:3}"  # 3番目以降の引数を全てメッセージとして結合
fi

SESSION_NAME="ai-multi-agent"

# エージェントタイプとナンバーからペイン番号を決定
get_pane_number() {
    local type="$1"
    local num="$2"
    
    case "$type" in
        boss)
            echo 0
            ;;
        engineer)
            if [ "$num" -ge 1 ] && [ "$num" -le 10 ]; then
                echo "$num"
            else
                echo -1
            fi
            ;;
        designer)
            if [ "$num" -eq 1 ]; then
                echo 11
            elif [ "$num" -eq 2 ]; then
                echo 12
            else
                echo -1
            fi
            ;;
        marketer)
            if [ "$num" -eq 1 ]; then
                echo 13
            elif [ "$num" -eq 2 ]; then
                echo 14
            else
                echo -1
            fi
            ;;
        notification)
            echo 15
            ;;
        *)
            echo -1
            ;;
    esac
}

# ペイン番号を取得
PANE_NUM=$(get_pane_number "$AGENT_TYPE" "$AGENT_NUM")

if [ "$PANE_NUM" -eq -1 ]; then
    echo "エラー: 無効なエージェントタイプまたは番号です"
    usage
fi

# セッションが存在するか確認
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "エラー: セッション '$SESSION_NAME' が存在しません"
    echo "まず './scripts/ai-multi-agent-dashboard.sh' を実行してセッションを作成してください"
    exit 1
fi

# ペインにメッセージを送信（Claude Code対応）
TARGET_PANE="$SESSION_NAME:0.$PANE_NUM"

# 役割リマインダーを送信（必要に応じて）
if [ "$WITH_ROLE_REMINDER" = true ]; then
    case "$AGENT_TYPE" in
        boss)
            ROLE_MESSAGE="【役割リマインダー】agents/boss/CLAUDE.md を再度確認して、ボスとしての役割を思い出してください。"
            ;;
        engineer)
            ROLE_MESSAGE="【役割リマインダー】agents/engineer/CLAUDE.md を再度確認して、エンジニアとしての役割を思い出してください。"
            ;;
        designer)
            ROLE_MESSAGE="【役割リマインダー】agents/designer/CLAUDE.md を再度確認して、デザイナーとしての役割を思い出してください。"
            ;;
        marketer)
            ROLE_MESSAGE="【役割リマインダー】agents/marketer/CLAUDE.md を再度確認して、マーケターとしての役割を思い出してください。"
            ;;
        notification)
            ROLE_MESSAGE="【システム情報】通知監視専用ペインです。"
            ;;
    esac
    
    tmux send-keys -t "$TARGET_PANE" "$ROLE_MESSAGE"
    tmux send-keys -t "$TARGET_PANE" Enter
    sleep 1
    echo "役割リマインダーを送信しました"
fi

# メッセージを送信（テキストとEnterを別々に送信）
tmux send-keys -t "$TARGET_PANE" "$MESSAGE"
tmux send-keys -t "$TARGET_PANE" Enter

echo "メッセージを $AGENT_TYPE-$AGENT_NUM (ペイン$PANE_NUM) に送信しました:"
echo "$MESSAGE"