# T-WADAスタイルTDD開発プロセス

## 開発手順（改定版）

### 1. 要求定義書作成
**担当**: ボス + 関連ステークホルダー

- ビジネス要件の明確化
- ユーザーストーリーの作成
- 受け入れ基準の定義

### 2. 要件定義書作成
**担当**: ボス

- 機能要件の詳細化
- 非機能要件の定義（性能、セキュリティ、可用性等）
- 制約条件の明確化

### 3. 技術選定
**担当**: エンジニア（リードエンジニア）

- 技術スタックの決定
- フレームワーク・ライブラリの選定
- 開発ツールの決定

### 4. アーキテクチャ設計
**担当**: エンジニア（シニアエンジニア） + ボス（承認）

- システム全体の構成設計
- レイヤー構造の設計
- コンポーネント間の依存関係
- データフローの設計
- セキュリティアーキテクチャ
- スケーラビリティ考慮

### 5. 概要設計（API仕様書）
**担当**: エンジニア

- API エンドポイント設計
- データスキーマ設計
- 外部システム連携仕様
- 認証・認可方式

### 6. 詳細設計（フローチャート）
**担当**: エンジニア

- 業務フローの詳細化
- 例外処理の設計
- エラーハンドリング戦略
- パフォーマンス要件の詳細

### 7. テスト設計（T-WADAスタイル）
**担当**: エンジニア + ボス（承認）

- **重要**: このフェーズでテスト仕様を確定し、実装中の修正を禁止
- 単体テスト・統合テスト・E2Eテストの設計

### 8. TDD開発実装
**担当**: エンジニア

- **テスト修正禁止**: 実装中はテストコードを一切変更しない

## テスト修正禁止の仕組み

### 1. テスト仕様書の作成と承認

```yaml
test_specification:
  id: TEST-001
  feature: ユーザー認証
  approved_by: ボス
  approved_date: 2024-01-15
  locked: true  # 承認後はロック
  
  test_cases:
    - name: 正常なログイン
      input:
        email: "user@example.com"
        password: "validPassword123"
      expected_output:
        success: true
        token: "JWT形式のトークン"
        user_id: 123
        
    - name: 無効なパスワード
      input:
        email: "user@example.com"
        password: "wrongPassword"
      expected_output:
        success: false
        error: "Invalid credentials"
        
    - name: 存在しないユーザー
      input:
        email: "nonexistent@example.com"
        password: "anyPassword"
      expected_output:
        success: false
        error: "User not found"
```

### 2. テストコードの事前作成と保護

```typescript
// tests/auth.test.ts - 実装前に作成し、変更禁止
import { authenticate } from '../src/auth';
import assert from 'power-assert';

describe('Authentication', () => {
  // TEST-001-1: 正常なログイン
  test('should authenticate valid user', async () => {
    const result = await authenticate('user@example.com', 'validPassword123');
    
    assert(result.success === true);
    assert(typeof result.token === 'string');
    assert(result.token.length > 0);
    assert(result.user_id === 123);
  });
  
  // TEST-001-2: 無効なパスワード  
  test('should reject invalid password', async () => {
    const result = await authenticate('user@example.com', 'wrongPassword');
    
    assert(result.success === false);
    assert(result.error === 'Invalid credentials');
    assert(result.token === undefined);
  });
  
  // TEST-001-3: 存在しないユーザー
  test('should reject non-existent user', async () => {
    const result = await authenticate('nonexistent@example.com', 'anyPassword');
    
    assert(result.success === false);
    assert(result.error === 'User not found');
    assert(result.token === undefined);
  });
});
```

### 3. テスト保護スクリプト

```bash
#!/bin/bash
# scripts/protect-tests.sh

# テストファイルのハッシュを記録
find tests/ -name "*.test.ts" -o -name "*.test.js" | while read file; do
  hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
  echo "$hash  $file" >> .test-hashes
done

echo "テストファイルが保護されました。実装中は変更できません。"
```

```bash
#!/bin/bash
# scripts/verify-tests.sh

# テストファイルが変更されていないかチェック
if [ -f .test-hashes ]; then
  shasum -a 256 -c .test-hashes
  if [ $? -ne 0 ]; then
    echo "❌ エラー: テストファイルが変更されています！"
    echo "実装中のテスト修正は禁止されています。"
    exit 1
  fi
  echo "✅ テストファイルの整合性が確認されました。"
else
  echo "⚠️  警告: テストハッシュファイルが見つかりません。"
fi
```

### 4. Git Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "テスト整合性チェック中..."
./scripts/verify-tests.sh

if [ $? -ne 0 ]; then
  echo "❌ コミットが拒否されました: テストファイルが不正に変更されています"
  exit 1
fi

echo "✅ テスト整合性チェック完了"
```

## エンジニアエージェント向けTDD指示

### Red-Green-Refactor サイクルの徹底

```typescript
// 1. RED: テストを実行（必ず失敗することを確認）
npm test -- auth.test.ts
// ❌ テストが失敗することを確認

// 2. GREEN: 最小限の実装でテストを通す
export async function authenticate(email: string, password: string) {
  // 最初は簡単な実装から始める
  if (email === 'user@example.com' && password === 'validPassword123') {
    return {
      success: true,
      token: 'temporary-token',
      user_id: 123
    };
  }
  
  if (email === 'nonexistent@example.com') {
    return {
      success: false,
      error: 'User not found'
    };
  }
  
  return {
    success: false,
    error: 'Invalid credentials'
  };
}

// 3. REFACTOR: テストを通したまま、コードを改善
export async function authenticate(email: string, password: string) {
  const user = await findUserByEmail(email);
  
  if (!user) {
    return {
      success: false,
      error: 'User not found'
    };
  }
  
  const isValidPassword = await verifyPassword(password, user.hashedPassword);
  
  if (!isValidPassword) {
    return {
      success: false,
      error: 'Invalid credentials'
    };
  }
  
  return {
    success: true,
    token: generateJWT(user),
    user_id: user.id
  };
}
```

## ワークフロー管理

### 1. テスト設計フェーズ
```bash
# 1. テスト仕様書の作成
./scripts/agent-task.sh create engineer "auth-test-design" "認証機能のテスト設計"

# 2. テストコードの実装
# 3. ボスによるテスト設計の承認
# 4. テストファイルの保護
./scripts/protect-tests.sh
```

### 2. 実装フェーズ
```bash
# 1. 実装タスクの開始
./scripts/agent-task.sh create engineer "auth-implementation" "認証機能の実装"

# 2. TDDサイクルの実行
npm test -- --watch  # テストを監視モードで実行

# 3. 実装完了時のチェック
./scripts/verify-tests.sh  # テスト整合性確認
npm test  # 全テスト実行
```

## エンジニアエージェント用チェックリスト

### テスト設計フェーズ
- [ ] 要件定義書の理解
- [ ] API仕様書の確認  
- [ ] テストケースの網羅性確認
- [ ] 境界値テストの追加
- [ ] 例外ケースの考慮
- [ ] ボスによる承認取得
- [ ] テストファイルの保護実行

### 実装フェーズ  
- [ ] テスト実行（RED確認）
- [ ] 最小実装（GREEN達成）
- [ ] リファクタリング実行
- [ ] テスト整合性確認
- [ ] コードカバレッジ80%以上
- [ ] 静的解析エラーなし

## 禁止事項の明確化

### 絶対禁止
1. **実装中のテスト修正**: テストケースの変更、削除、追加
2. **テスト期待値の変更**: `assert`文の条件変更
3. **テストのスキップ**: `test.skip()`, `describe.skip()`の使用
4. **テストの無効化**: コメントアウト

### 例外的に許可される場合
1. **テスト設計フェーズでのバグ発見**: ボスの承認が必要
2. **要件変更**: 正式な変更管理プロセスを経る
3. **技術的制約の発見**: アーキテクチャ変更を伴う場合

## 違反時の対応

```bash
# 違反検知時のアラート
echo "🚨 重大な違反: テストファイルが不正に変更されました"
echo "担当エージェント: $AGENT_TYPE-$AGENT_NUMBER"
echo "変更されたファイル: $CHANGED_FILES"
echo "即座にボスに報告してください"

# タスクを自動的にブロック状態に
./scripts/agent-task.sh update $TASK_ID blocked
```

この仕組みにより、T-WADAスタイルのTDDを正しく実践し、テストの信頼性を保ちながら実装の振り幅を大幅に削減できます。