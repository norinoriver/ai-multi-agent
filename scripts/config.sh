#!/bin/bash

# AI Multi-Agent 設定ファイル

# 基本設定
export AI_AGENT_WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export AI_AGENT_MAX_SESSIONS=25
export AI_AGENT_MEMORY_RESERVE_GB=6

# セッション制限設定
export AI_AGENT_ENGINEER_MAX=10
export AI_AGENT_DESIGNER_MAX=2
export AI_AGENT_MARKETER_MAX=2
export AI_AGENT_BOSS_MAX=1

# Git設定
export AI_AGENT_GIT_WORKTREE_BASE="$AI_AGENT_WORKSPACE/worktrees"
export AI_AGENT_BRANCH_PREFIX="feat"

# Claude Code設定
export AI_AGENT_CLAUDE_CMD="claude"  # または ccmanager

# レポート設定
export AI_AGENT_REPORT_FORMAT="summary.txt"
export AI_AGENT_PATCH_FORMAT="*.patch"

# tmux設定
export AI_AGENT_TMUX_PREFIX="ai-agent"
export AI_AGENT_TMUX_SOCKET_DIR="/tmp"

# カラー設定
export COLOR_INFO="\033[0;34m"
export COLOR_SUCCESS="\033[0;32m"
export COLOR_WARNING="\033[0;33m"
export COLOR_ERROR="\033[0;31m"
export COLOR_RESET="\033[0m"

# 関数: 現在のセッション数を取得
get_session_count() {
    local agent_type=$1
    tmux list-sessions 2>/dev/null | grep -c "${AI_AGENT_TMUX_PREFIX}-${agent_type}" || echo 0
}

# 関数: セッション制限チェック
check_session_limit() {
    local agent_type=$1
    local current_count=$(get_session_count "$agent_type")
    local max_var="AI_AGENT_${agent_type^^}_MAX"
    local max_limit=${!max_var:-1}
    
    if [ "$current_count" -ge "$max_limit" ]; then
        echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} ${agent_type}のセッション上限に達しています (現在: $current_count/$max_limit)"
        return 1
    fi
    return 0
}

# 関数: メモリ使用状況チェック
check_memory_usage() {
    # macOS用のメモリチェック
    local total_memory=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024}')
    local used_memory=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//' | awk '{print $1*4096/1024/1024/1024}')
    local available_memory=$(echo "$total_memory - $used_memory" | bc)
    
    if (( $(echo "$available_memory < $AI_AGENT_MEMORY_RESERVE_GB" | bc -l) )); then
        echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} 利用可能メモリが少なくなっています (${available_memory}GB < ${AI_AGENT_MEMORY_RESERVE_GB}GB)"
        return 1
    fi
    return 0
}