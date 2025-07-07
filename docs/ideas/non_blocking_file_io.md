# 非ブロックファイルI/O実装アイデア

## 概要

複数エージェントが同時にファイル書き込みを行う際のI/Oブロックを回避する実装パターン。

## 基本方針

「一時ファイルに書き込み → 完了後に移動/結合」により、読み込み中のファイルへの書き込みを避ける。

## 実装パターン

### 1. メッセージ送信時
```bash
# 一時ファイル作成
message_file="boss_agent_$(date +%Y%m%d%H%M%S)_$(uuidgen).tmp"
echo '{"message": "task assignment"}' > "shared/messages/outbox/$message_file"

# 完成後に正式な場所へ移動
final_name="$(date +%Y%m%d%H%M%S)_boss_pm_msg-12345.json"
mv "shared/messages/outbox/$message_file" "shared/messages/inbox/$final_name"
```

### 2. ログ書き込み時
```bash
# 各エージェントが個別の一時ファイルに書き込み
log_file="se_agent_1_$(date +%Y%m%d%H%M%S)_$(uuidgen).tmp"
echo "2025-01-07 12:00:00 [INFO] Task started" >> "shared/logs/temp/$log_file"

# 定期的にログ統合スクリプトが実行
# 全ての.tmpファイルを日付別の統合ログファイルに結合
for tmp in shared/logs/temp/*.tmp; do
    cat "$tmp" >> "shared/logs/20250107_consolidated.log"
    rm "$tmp"
done
```

### 3. 進捗レポート更新時
```bash
# 新しい進捗を一時ファイルに書き込み
progress_file="pm_agent_$(date +%Y%m%d%H%M%S)_$(uuidgen).tmp"
cat > "shared/progress/temp/$progress_file" << EOF
{
  "task_id": "task-001",
  "progress": 75,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# アトミックに最新進捗として反映
mv "shared/progress/temp/$progress_file" "shared/progress/latest/task-001.json"
```

## 利点

### 1. 並列性の向上
- 複数エージェントが同時書き込み可能
- 読み込み操作をブロックしない
- ファイルロック不要

### 2. データ整合性
- 部分的な書き込み状態を他が読まない
- アトミックな操作で一貫性保証
- 破損ファイルのリスク低減

### 3. シンプルな実装
- 特別なライブラリ不要
- OSレベルの基本操作のみ
- デバッグが容易

## 注意点

### 1. 一時ファイルのクリーンアップ
```bash
# 定期的に古い一時ファイルを削除
find shared/*/temp -name "*.tmp" -mtime +1 -delete
```

### 2. ディスク容量管理
- 一時ファイルが蓄積しないよう監視
- ログローテーション戦略の実装

### 3. ファイル名の一意性
- UUIDやタイムスタンプで衝突回避
- エージェントIDを含めて識別性向上

## 実装例

### メッセージ送信関数
```bash
send_message() {
    local from=$1
    local to=$2
    local content=$3
    
    # 一時ファイル作成
    local tmp_file="${from}_$(date +%Y%m%d%H%M%S%N)_$(uuidgen).tmp"
    local tmp_path="shared/messages/temp/$tmp_file"
    
    # 内容書き込み
    echo "$content" > "$tmp_path"
    
    # 最終ファイル名決定
    local msg_id=$(uuidgen | cut -d'-' -f1)
    local final_name="$(date +%Y%m%d%H%M%S)_${from}_${to}_msg-${msg_id}.json"
    
    # アトミックな移動
    mv "$tmp_path" "shared/messages/inbox/$final_name"
}
```

---

**作成日**: 2025-01-07  
**フェーズ**: 詳細設計時の実装パターン