# E2E/統合テスト実行戦略

## 概要

複数ブランチでのE2E/統合テスト実行時のリソース競合を回避するため、Review Agent専用のテスト環境を用意する。

## 問題と解決策

### 問題点
- **ポート競合**: 複数ブランチで同じポートを使用
- **DB競合**: テストDBの同時アクセス
- **リソース競合**: ファイル、メモリ、プロセス等
- **環境汚染**: テスト実行による他ブランチへの影響

### 解決策
- **専用テストブランチ**: `review-test-branch` でのみE2E/統合テスト実行
- **完全環境分離**: 他のworktreeと独立したテスト環境
- **上書き実行**: PR内容を専用ブランチに反映してテスト

## 実装詳細

### 1. 専用テストブランチの準備
```bash
# Review Agent専用のworktree作成
git worktree add ../worktrees/review-test review-test-branch

# テスト環境用の設定ファイル
cp config/test.env ../worktrees/review-test/.env
```

### 2. PR内容の反映プロセス
```bash
# PR内容を専用ブランチに反映
cd ../worktrees/review-test

# メインブランチから最新を取得
git fetch origin main
git reset --hard origin/main

# PR変更を適用
git fetch origin pull/{PR_NUMBER}/head:pr-{PR_NUMBER}
git merge pr-{PR_NUMBER}
```

### 3. E2E/統合テスト実行
```bash
# 専用ポート設定（競合回避）
export TEST_PORT=9000
export TEST_DB_PORT=5433
export TEST_REDIS_PORT=6380

# テスト実行
npm run test:e2e
npm run test:integration

# 結果の記録
echo "E2E Test Result: $?" > test_results.txt
```

### 4. 環境クリーンアップ
```bash
# テスト後の環境リセット
docker-compose -f docker-compose.test.yml down --volumes
rm -rf temp_test_files/
pkill -f "test_server"

# 次のテスト用に準備完了状態に戻す
git reset --hard origin/main
```

## 設定例

### テスト環境設定ファイル (.env.test)
```bash
# 専用ポート設定
SERVER_PORT=9000
DB_HOST=localhost
DB_PORT=5433
REDIS_PORT=6380

# テスト専用DB
DATABASE_URL="postgresql://test:test@localhost:5433/test_db"

# テスト用ログレベル
LOG_LEVEL=debug
```

### Docker Compose設定 (docker-compose.test.yml)
```yaml
version: '3.8'
services:
  test_db:
    image: postgres:15
    ports:
      - "5433:5432"  # 専用ポート
    environment:
      POSTGRES_DB: test_db
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
  
  test_redis:
    image: redis:7
    ports:
      - "6380:6379"  # 専用ポート
```

## テスト種別の判定

### E2Eテスト対象の判定
```bash
# パッケージ内容からE2Eテストが必要かを判定
has_e2e_tests() {
    if [[ -d "cypress" ]] || [[ -d "e2e" ]] || [[ -f "playwright.config.js" ]]; then
        return 0  # E2Eテストあり
    fi
    return 1  # E2Eテストなし
}

# 統合テスト対象の判定
has_integration_tests() {
    if [[ -d "tests/integration" ]] || grep -q "test:integration" package.json; then
        return 0  # 統合テストあり
    fi
    return 1  # 統合テストなし
}
```

## Review Agentの処理フロー

### 1. PR受信時
```bash
review_pr() {
    local pr_number=$1
    
    # 1. 内部レビュー実施
    claude_code_review "$pr_number"
    
    # 2. E2E/統合テスト判定
    if has_e2e_tests || has_integration_tests; then
        run_e2e_integration_tests "$pr_number"
    fi
    
    # 3. 外部レビュー待機
    wait_for_coderabbit "$pr_number"
}
```

### 2. E2E/統合テスト実行
```bash
run_e2e_integration_tests() {
    local pr_number=$1
    
    # 専用ブランチにPR内容を反映
    setup_test_branch "$pr_number"
    
    # テスト実行
    cd ../worktrees/review-test
    
    if has_e2e_tests; then
        npm run test:e2e || return 1
    fi
    
    if has_integration_tests; then
        npm run test:integration || return 1
    fi
    
    # クリーンアップ
    cleanup_test_environment
    
    return 0
}
```

## メリット

### 1. リソース競合回避
- ポート、DB、ファイルの競合なし
- 安全な並列開発環境

### 2. 環境分離
- テスト実行が他の開発作業に影響しない
- クリーンな環境での毎回のテスト

### 3. 効率的なリソース使用
- 必要な時のみテスト環境を構築
- 使用後は即座にクリーンアップ

### 4. 一貫性のあるテスト
- 同一環境での統一されたテスト実行
- 再現性の高いテスト結果

---

**作成日**: 2025-01-07  
**フェーズ**: 詳細設計・実装時の戦略