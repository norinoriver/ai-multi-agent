#!/bin/bash

# Git Worktree Manager for AI Multi-Agent System

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# 使用方法
usage() {
    echo "Git Worktree Manager"
    echo ""
    echo "使用方法:"
    echo "  $0 create <branch_name> <agent_type>  # 新しいworktreeを作成"
    echo "  $0 list                               # worktree一覧を表示"
    echo "  $0 remove <branch_name>               # worktreeを削除"
    echo "  $0 sync                               # 全worktreeを最新状態に同期"
    exit 1
}

# worktreeの作成
create_worktree() {
    local branch_name=$1
    local agent_type=$2
    local worktree_path="$AI_AGENT_GIT_WORKTREE_BASE/${agent_type}/${branch_name}"
    
    # ブランチ名の検証
    if [[ ! "$branch_name" =~ ^${AI_AGENT_BRANCH_PREFIX}/.+ ]]; then
        echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} ブランチ名は '${AI_AGENT_BRANCH_PREFIX}/' で始まる必要があります"
        exit 1
    fi
    
    # worktreeディレクトリの作成
    mkdir -p "$(dirname "$worktree_path")"
    
    # ブランチが存在するか確認
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} 既存のブランチからworktreeを作成: $branch_name"
        git worktree add "$worktree_path" "$branch_name"
    else
        echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} 新しいブランチとworktreeを作成: $branch_name"
        git worktree add -b "$branch_name" "$worktree_path" origin/main
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} Worktreeを作成しました:"
        echo "  パス: $worktree_path"
        echo "  ブランチ: $branch_name"
        echo "  担当: $agent_type"
        
        # エージェント用の初期設定ファイルを作成
        cat > "$worktree_path/.agent-config" << EOF
AGENT_TYPE=$agent_type
BRANCH_NAME=$branch_name
CREATED_AT=$(date +"%Y-%m-%d %H:%M:%S")
EOF
    else
        echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} Worktreeの作成に失敗しました"
        exit 1
    fi
}

# worktree一覧の表示
list_worktrees() {
    echo "=== Git Worktree 一覧 ==="
    echo ""
    
    git worktree list --porcelain | while read -r line; do
        if [[ "$line" =~ ^worktree ]]; then
            path="${line#worktree }"
            # 次の行でブランチ名を取得
            read -r branch_line
            branch="${branch_line#branch refs/heads/}"
            
            # エージェント情報を取得
            if [ -f "$path/.agent-config" ]; then
                agent_type=$(grep "^AGENT_TYPE=" "$path/.agent-config" | cut -d'=' -f2)
                created_at=$(grep "^CREATED_AT=" "$path/.agent-config" | cut -d'=' -f2)
                echo "Branch: $branch"
                echo "  Path: $path"
                echo "  Agent: $agent_type"
                echo "  Created: $created_at"
            else
                echo "Branch: $branch"
                echo "  Path: $path"
            fi
            echo ""
        fi
    done
}

# worktreeの削除
remove_worktree() {
    local branch_name=$1
    
    # worktreeのパスを取得
    local worktree_path=$(git worktree list --porcelain | grep -B1 "branch refs/heads/$branch_name" | grep "^worktree" | cut -d' ' -f2)
    
    if [ -z "$worktree_path" ]; then
        echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} Worktreeが見つかりません: $branch_name"
        exit 1
    fi
    
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} Worktreeを削除します: $worktree_path"
    git worktree remove "$worktree_path"
    
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} Worktreeを削除しました"
        
        # ブランチも削除するか確認
        read -p "ブランチ '$branch_name' も削除しますか？ (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git branch -D "$branch_name"
            echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} ブランチを削除しました"
        fi
    fi
}

# 全worktreeの同期
sync_worktrees() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} 全worktreeを同期します..."
    
    # 現在のディレクトリを保存
    local current_dir=$(pwd)
    
    git worktree list --porcelain | while read -r line; do
        if [[ "$line" =~ ^worktree ]]; then
            path="${line#worktree }"
            
            if [ "$path" != "$AI_AGENT_WORKSPACE" ]; then
                echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} 同期中: $path"
                cd "$path"
                git pull origin main --rebase
                cd "$current_dir"
            fi
        fi
    done
    
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} 同期が完了しました"
}

# メイン処理
case "$1" in
    create)
        if [ $# -ne 3 ]; then
            usage
        fi
        create_worktree "$2" "$3"
        ;;
    list)
        list_worktrees
        ;;
    remove)
        if [ $# -ne 2 ]; then
            usage
        fi
        remove_worktree "$2"
        ;;
    sync)
        sync_worktrees
        ;;
    *)
        usage
        ;;
esac