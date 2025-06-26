#!/bin/bash

# テスト保護スクリプト
# T-WADAスタイルTDDでテストファイルを実装中に変更されないよう保護

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HASH_FILE="$WORKSPACE_DIR/.test-hashes"
LOCK_FILE="$WORKSPACE_DIR/.test-lock"

source "$WORKSPACE_DIR/scripts/config.sh"

# 使用方法
usage() {
    echo "テスト保護スクリプト"
    echo ""
    echo "使用方法:"
    echo "  $0 lock [task_id]     # テストファイルをロック（実装フェーズ開始前）"
    echo "  $0 verify             # テストファイルの整合性確認"
    echo "  $0 unlock [task_id]   # テストファイルのロック解除（実装完了後）"
    echo "  $0 status             # 現在の保護状態確認"
    exit 1
}

# テストファイルのロック
lock_tests() {
    local task_id=$1
    
    if [ -f "$LOCK_FILE" ]; then
        echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} テストファイルは既にロックされています"
        cat "$LOCK_FILE"
        return 1
    fi
    
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} テストファイルをロックしています..."
    
    # テストファイルを検索してハッシュ値を計算
    find . -name "*.test.ts" -o -name "*.test.js" -o -name "*.spec.ts" -o -name "*.spec.js" | \
    grep -v node_modules | \
    while read file; do
        if [ -f "$file" ]; then
            hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
            echo "$hash  $file"
        fi
    done > "$HASH_FILE"
    
    # ロック情報を記録
    cat > "$LOCK_FILE" << EOF
LOCKED_AT=$(date +"%Y-%m-%d %H:%M:%S")
TASK_ID=$task_id
LOCKED_BY=$USER
STATUS=LOCKED
REASON=TDD実装フェーズ開始 - テストファイルの変更を禁止
EOF
    
    local test_count=$(wc -l < "$HASH_FILE")
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $test_count 個のテストファイルがロックされました"
    echo "ロック情報: $LOCK_FILE"
    echo "ハッシュファイル: $HASH_FILE"
    
    # Git属性でテストファイルを読み取り専用に設定
    if [ -d .git ]; then
        echo "*.test.ts diff=nodiff" >> .gitattributes
        echo "*.test.js diff=nodiff" >> .gitattributes
        echo "*.spec.ts diff=nodiff" >> .gitattributes
        echo "*.spec.js diff=nodiff" >> .gitattributes
    fi
}

# テストファイルの整合性確認
verify_tests() {
    if [ ! -f "$HASH_FILE" ]; then
        echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} テストハッシュファイルが見つかりません"
        echo "テストがロックされていない可能性があります"
        return 1
    fi
    
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} テストファイルの整合性を確認中..."
    
    # ハッシュ値をチェック
    if shasum -a 256 -c "$HASH_FILE" >/dev/null 2>&1; then
        echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} ✅ テストファイルの整合性が確認されました"
        return 0
    else
        echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} ❌ テストファイルが変更されています！"
        echo ""
        echo "変更されたファイル:"
        shasum -a 256 -c "$HASH_FILE" 2>&1 | grep FAILED
        echo ""
        echo "🚨 重大な違反: 実装中にテストファイルを変更することは禁止されています"
        echo "T-WADAスタイルTDDでは、テストファーストが原則です"
        echo ""
        echo "対処法:"
        echo "1. テストファイルを元の状態に戻す"
        echo "2. 要件に問題がある場合は、ボスに報告して正式な変更管理プロセスを経る"
        echo "3. 実装をテストに合わせて修正する"
        
        # 違反を記録
        echo "VIOLATION_DATE=$(date +"%Y-%m-%d %H:%M:%S")" >> "$LOCK_FILE"
        echo "VIOLATION_USER=$USER" >> "$LOCK_FILE"
        echo "VIOLATION_FILES=$(shasum -a 256 -c "$HASH_FILE" 2>&1 | grep FAILED | cut -d: -f1)" >> "$LOCK_FILE"
        
        return 1
    fi
}

# テストファイルのロック解除
unlock_tests() {
    local task_id=$1
    
    if [ ! -f "$LOCK_FILE" ]; then
        echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} テストファイルはロックされていません"
        return 1
    fi
    
    # 最終整合性チェック
    if ! verify_tests; then
        echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} テストファイルが変更されているため、ロック解除できません"
        return 1
    fi
    
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} テストファイルのロックを解除中..."
    
    # ロック解除情報を記録
    echo "UNLOCKED_AT=$(date +"%Y-%m-%d %H:%M:%S")" >> "$LOCK_FILE"
    echo "UNLOCKED_BY=$USER" >> "$LOCK_FILE"
    echo "COMPLETION_TASK_ID=$task_id" >> "$LOCK_FILE"
    
    # アーカイブとして保存
    local archive_dir="$WORKSPACE_DIR/test-locks/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$archive_dir"
    cp "$LOCK_FILE" "$archive_dir/"
    cp "$HASH_FILE" "$archive_dir/"
    
    # ロックファイルを削除
    rm "$LOCK_FILE" "$HASH_FILE"
    
    # Git属性をクリア
    if [ -f .gitattributes ]; then
        sed -i.bak '/.*\.test\..* diff=nodiff/d' .gitattributes
        sed -i.bak '/.*\.spec\..* diff=nodiff/d' .gitattributes
        rm -f .gitattributes.bak
    fi
    
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} テストファイルのロックが解除されました"
    echo "アーカイブ: $archive_dir"
}

# 保護状態の確認
check_status() {
    echo "=== テスト保護状態 ==="
    echo ""
    
    if [ -f "$LOCK_FILE" ]; then
        echo -e "${COLOR_WARNING}[LOCKED]${COLOR_RESET} テストファイルはロックされています"
        echo ""
        cat "$LOCK_FILE"
        echo ""
        
        if [ -f "$HASH_FILE" ]; then
            local test_count=$(wc -l < "$HASH_FILE")
            echo "保護対象ファイル数: $test_count"
            echo ""
            echo "保護対象ファイル一覧:"
            cat "$HASH_FILE" | cut -d' ' -f3-
        fi
    else
        echo -e "${COLOR_SUCCESS}[UNLOCKED]${COLOR_RESET} テストファイルはロックされていません"
        
        # テストファイルの存在確認
        local test_files=$(find . -name "*.test.ts" -o -name "*.test.js" -o -name "*.spec.ts" -o -name "*.spec.js" | grep -v node_modules | wc -l)
        echo "テストファイル数: $test_files"
    fi
}

# Git pre-commit hook用の関数
precommit_check() {
    if [ -f "$LOCK_FILE" ]; then
        echo "テスト整合性チェック中..."
        if ! verify_tests; then
            echo "❌ コミットが拒否されました: テストファイルが不正に変更されています"
            echo "実装中のテスト修正は禁止されています"
            exit 1
        fi
        echo "✅ テスト整合性チェック完了"
    fi
}

# メイン処理
case "$1" in
    lock)
        if [ $# -ne 2 ]; then
            echo "使用方法: $0 lock <task_id>"
            exit 1
        fi
        lock_tests "$2"
        ;;
    verify)
        verify_tests
        ;;
    unlock)
        if [ $# -ne 2 ]; then
            echo "使用方法: $0 unlock <task_id>"
            exit 1
        fi
        unlock_tests "$2"
        ;;
    status)
        check_status
        ;;
    precommit)
        precommit_check
        ;;
    *)
        usage
        ;;
esac