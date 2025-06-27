#!/bin/bash

# エージェント停止スクリプト
# 使用方法:
#   ./scripts/stop-agents.sh            # 全エージェントを停止
#   ./scripts/stop-agents.sh engineer   # エンジニアエージェントのみ停止
#   ./scripts/stop-agents.sh boss 1     # ボスエージェントの1番を停止

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/config.sh"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 使用方法を表示
show_usage() {
    echo "使用方法:"
    echo "  $0                    # 全エージェントを停止"
    echo "  $0 <agent_type>       # 特定タイプの全エージェントを停止"
    echo "  $0 <agent_type> <id>  # 特定のエージェントを停止"
    echo ""
    echo "agent_type: engineer, designer, marketer, boss"
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

# メイン処理
main() {
    if [[ $# -eq 0 ]]; then
        # 全エージェントを停止
        echo -e "${YELLOW}全エージェントを停止しています...${NC}"
        echo ""
        
        # 現在起動中のエージェントセッションを確認
        local sessions=$(tmux list-sessions 2>/dev/null | grep "ai-agent" | cut -d: -f1 || true)
        
        if [[ -z "$sessions" ]]; then
            echo -e "${RED}起動中のエージェントセッションが見つかりません。${NC}"
            exit 0
        fi
        
        # 各セッションを停止
        while IFS= read -r session; do
            stop_session "$session"
        done <<< "$sessions"
        
        echo ""
        echo -e "${GREEN}全エージェントの停止が完了しました。${NC}"
        
    elif [[ $# -eq 1 ]]; then
        # 特定タイプの全エージェントを停止
        local agent_type=$1
        
        # agent_typeの検証
        if [[ ! " engineer designer marketer boss " =~ " $agent_type " ]]; then
            echo -e "${RED}エラー: 無効なエージェントタイプ '$agent_type'${NC}"
            show_usage
            exit 1
        fi
        
        echo -e "${YELLOW}${agent_type}エージェントを停止しています...${NC}"
        echo ""
        
        # 該当するセッションを検索して停止
        local sessions=$(tmux list-sessions 2>/dev/null | grep "ai-agent-${agent_type}" | cut -d: -f1 || true)
        
        if [[ -z "$sessions" ]]; then
            echo -e "${RED}起動中の${agent_type}エージェントが見つかりません。${NC}"
            exit 0
        fi
        
        while IFS= read -r session; do
            stop_session "$session"
        done <<< "$sessions"
        
        echo ""
        echo -e "${GREEN}${agent_type}エージェントの停止が完了しました。${NC}"
        
    elif [[ $# -eq 2 ]]; then
        # 特定のエージェントを停止
        local agent_type=$1
        local agent_id=$2
        local session_name="ai-agent-${agent_type}-${agent_id}"
        
        # agent_typeの検証
        if [[ ! " engineer designer marketer boss " =~ " $agent_type " ]]; then
            echo -e "${RED}エラー: 無効なエージェントタイプ '$agent_type'${NC}"
            show_usage
            exit 1
        fi
        
        # agent_idが数字かチェック
        if ! [[ "$agent_id" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}エラー: エージェントIDは数字である必要があります。${NC}"
            show_usage
            exit 1
        fi
        
        stop_session "$session_name"
        
    else
        echo -e "${RED}エラー: 引数が多すぎます。${NC}"
        show_usage
        exit 1
    fi
}

# 現在のセッション状態を表示
echo -e "${YELLOW}=== 現在のエージェントセッション ===${NC}"
tmux list-sessions 2>/dev/null | grep "ai-agent" || echo "起動中のエージェントはありません。"
echo ""

# メイン処理を実行
main "$@"

# 終了後の状態を表示
echo ""
echo -e "${YELLOW}=== 停止後のエージェントセッション ===${NC}"
tmux list-sessions 2>/dev/null | grep "ai-agent" || echo "起動中のエージェントはありません。"