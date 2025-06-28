#!/bin/bash

# AI Multi-Agent Brainstorming System
# ふんわりした要望から仕様を固めるためのブレインストーミングシステム

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 設定
TMUX_PREFIX="ai-agent"
BOSS_SESSION="ai-agent-boss-1"
BRAINSTORM_DIR="$WORKSPACE_DIR/brainstorm"
SPECS_DIR="$WORKSPACE_DIR/specs"
REPORTS_DIR="$WORKSPACE_DIR/reports"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ディレクトリ作成
mkdir -p "$BRAINSTORM_DIR" "$SPECS_DIR"

# 使用方法を表示
show_usage() {
    echo -e "${CYAN}AI Multi-Agent Brainstorming System${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 start \"<要望>\"              # ブレインストーミング開始"
    echo "  $0 collect <session_id>         # 意見収集と整理"
    echo "  $0 draft <session_id>           # 仕様書案作成"
    echo "  $0 review <session_id>          # レビュー要求"
    echo "  $0 finalize <session_id>        # 仕様確定"
    echo "  $0 status [session_id]          # 進行状況確認"
    echo ""
    echo "フロー:"
    echo "  1. start   - 要望を各エージェントに送信"
    echo "  2. collect - 各エージェントの意見を収集"
    echo "  3. draft   - 仕様書案を作成"
    echo "  4. review  - 全員でレビュー"
    echo "  5. finalize - 最終仕様書作成"
}

# ブレインストーミングセッション開始
start_brainstorm() {
    local request="$1"
    local session_id="brainstorm_$(date +%Y%m%d%H%M%S)"
    local session_file="$BRAINSTORM_DIR/${session_id}/session.info"
    
    # セッションディレクトリ作成
    mkdir -p "$BRAINSTORM_DIR/$session_id"
    
    # セッション情報保存
    cat > "$session_file" << EOF
SESSION_ID: $session_id
REQUEST: $request
STATUS: brainstorming
STARTED_AT: $(date +"%Y-%m-%d %H:%M:%S")
PARTICIPANTS: boss, engineer, designer, marketer
EOF
    
    echo -e "${GREEN}ブレインストーミングセッションを開始しました${NC}"
    echo -e "${BLUE}セッションID: $session_id${NC}"
    echo ""
    
    # 各エージェントタイプへブレスト要求を送信
    echo -e "${YELLOW}各エージェントへ意見募集を送信中...${NC}"
    
    # ボスへの指示
    "$SCRIPT_DIR/boss-command.sh" send boss 1 "【ブレスト開始】要望: $request - プロジェクト全体の観点から意見をまとめてください"
    
    # エンジニアへの指示（代表者のみ）
    "$SCRIPT_DIR/boss-command.sh" send engineer 1 "【ブレスト】要望: $request - 技術的な実現性、必要な技術スタック、開発工数の観点から意見をまとめてください"
    "$SCRIPT_DIR/boss-command.sh" send engineer 2 "【ブレスト】要望: $request - セキュリティ、パフォーマンス、スケーラビリティの観点から意見をまとめてください"
    
    # デザイナーへの指示
    "$SCRIPT_DIR/boss-command.sh" send designer 1 "【ブレスト】要望: $request - UI/UX、ユーザビリティ、デザインシステムの観点から意見をまとめてください"
    
    # マーケターへの指示
    "$SCRIPT_DIR/boss-command.sh" send marketer 1 "【ブレスト】要望: $request - ターゲットユーザー、市場性、競合分析の観点から意見をまとめてください"
    
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo -e "  意見がまとまったら: ${WHITE}$0 collect $session_id${NC}"
    
    # 意見テンプレートを作成
    for agent in boss engineer designer marketer; do
        cat > "$BRAINSTORM_DIR/$session_id/${agent}_opinion.md" << EOF
# ${agent}の意見

## 要望
$request

## 意見・提案
（ここに意見を記載）

## 懸念事項
（ここに懸念事項を記載）

## 必要リソース
（ここに必要なリソースを記載）
EOF
    done
}

# 意見収集と整理
collect_opinions() {
    local session_id=$1
    local session_dir="$BRAINSTORM_DIR/$session_id"
    local summary_file="$session_dir/summary.md"
    
    if [ ! -d "$session_dir" ]; then
        echo -e "${RED}エラー: セッションが見つかりません: $session_id${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}意見を収集・整理中...${NC}"
    
    # サマリーファイル作成
    cat > "$summary_file" << EOF
# ブレインストーミングサマリー
セッションID: $session_id
日時: $(date +"%Y-%m-%d %H:%M:%S")

## 元の要望
$(grep "^REQUEST:" "$session_dir/session.info" | cut -d' ' -f2-)

## 各エージェントの意見まとめ

### ボス（プロダクトオーナー）の観点
$(cat "$session_dir/boss_opinion.md" 2>/dev/null | grep -A 100 "## 意見・提案" | tail -n +2 || echo "意見未提出")

### エンジニアの観点
$(cat "$session_dir/engineer_opinion.md" 2>/dev/null | grep -A 100 "## 意見・提案" | tail -n +2 || echo "意見未提出")

### デザイナーの観点
$(cat "$session_dir/designer_opinion.md" 2>/dev/null | grep -A 100 "## 意見・提案" | tail -n +2 || echo "意見未提出")

### マーケターの観点
$(cat "$session_dir/marketer_opinion.md" 2>/dev/null | grep -A 100 "## 意見・提案" | tail -n +2 || echo "意見未提出")

## 統合された提案
（ボスがここに統合案を記載）

## 次のアクション
1. 仕様書案の作成
2. 各エージェントによるレビュー
3. 最終仕様の確定
EOF
    
    # ステータス更新
    sed -i.bak "s/^STATUS: .*/STATUS: collected/" "$session_dir/session.info"
    
    echo -e "${GREEN}意見の収集・整理が完了しました${NC}"
    echo -e "${BLUE}サマリー: $summary_file${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo -e "  仕様書案作成: ${WHITE}$0 draft $session_id${NC}"
}

# 仕様書案作成
create_draft_spec() {
    local session_id=$1
    local session_dir="$BRAINSTORM_DIR/$session_id"
    local draft_file="$SPECS_DIR/${session_id}_draft.md"
    
    if [ ! -f "$session_dir/summary.md" ]; then
        echo -e "${RED}エラー: 意見収集が完了していません${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}仕様書案を作成中...${NC}"
    
    # 仕様書テンプレート作成
    cat > "$draft_file" << EOF
# 仕様書（案）
ドキュメントID: ${session_id}_spec
作成日: $(date +"%Y-%m-%d")
ステータス: ドラフト

## 1. 概要
### 1.1 背景
$(grep "^REQUEST:" "$session_dir/session.info" | cut -d' ' -f2-)

### 1.2 目的
（ここに目的を記載）

### 1.3 スコープ
（ここにスコープを記載）

## 2. 機能要件
### 2.1 必須機能
- [ ] 機能1
- [ ] 機能2

### 2.2 オプション機能
- [ ] 機能A
- [ ] 機能B

## 3. 非機能要件
### 3.1 パフォーマンス
（ここに要件を記載）

### 3.2 セキュリティ
（ここに要件を記載）

### 3.3 ユーザビリティ
（ここに要件を記載）

## 4. 技術仕様
### 4.1 アーキテクチャ
（ここにアーキテクチャを記載）

### 4.2 技術スタック
- フロントエンド:
- バックエンド:
- データベース:

## 5. UI/UXデザイン
### 5.1 デザインコンセプト
（ここにコンセプトを記載）

### 5.2 画面構成
（ここに画面構成を記載）

## 6. 開発計画
### 6.1 フェーズ分け
- Phase 1: 基本機能（2週間）
- Phase 2: 追加機能（1週間）
- Phase 3: テスト・調整（1週間）

### 6.2 担当割り当て
- エンジニア: 
- デザイナー:
- マーケター:

## 7. リスクと対策
（ここにリスクと対策を記載）

## 8. 承認
- [ ] ボス承認
- [ ] エンジニア承認
- [ ] デザイナー承認
- [ ] マーケター承認

---
*このドキュメントはブレインストーミングセッション ${session_id} の結果に基づいて作成されました*
EOF
    
    # ボスへ仕様書案作成を依頼
    "$SCRIPT_DIR/boss-command.sh" send boss 1 "【仕様書案作成】$draft_file を確認し、ブレスト結果を基に具体的な仕様を記入してください"
    
    # ステータス更新
    sed -i.bak "s/^STATUS: .*/STATUS: drafting/" "$session_dir/session.info"
    
    echo -e "${GREEN}仕様書案を作成しました${NC}"
    echo -e "${BLUE}ドラフト: $draft_file${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo -e "  レビュー要求: ${WHITE}$0 review $session_id${NC}"
}

# レビュー要求
request_review() {
    local session_id=$1
    local draft_file="$SPECS_DIR/${session_id}_draft.md"
    
    if [ ! -f "$draft_file" ]; then
        echo -e "${RED}エラー: 仕様書案が見つかりません${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}レビューを要求中...${NC}"
    
    # 各エージェントへレビュー要求
    "$SCRIPT_DIR/boss-command.sh" all "【レビュー要求】仕様書案 $draft_file をレビューし、フィードバックをお願いします"
    
    # レビューコメント用ファイル作成
    local review_file="$SPECS_DIR/${session_id}_reviews.md"
    cat > "$review_file" << EOF
# 仕様書レビューコメント
セッションID: $session_id
レビュー開始: $(date +"%Y-%m-%d %H:%M:%S")

## ボスのレビュー
（コメントをここに記載）

## エンジニアのレビュー
（コメントをここに記載）

## デザイナーのレビュー
（コメントをここに記載）

## マーケターのレビュー
（コメントをここに記載）

## 修正が必要な項目
- [ ] 項目1
- [ ] 項目2
EOF
    
    # ステータス更新
    sed -i.bak "s/^STATUS: .*/STATUS: reviewing/" "$BRAINSTORM_DIR/$session_id/session.info"
    
    echo -e "${GREEN}レビュー要求を送信しました${NC}"
    echo -e "${BLUE}レビューファイル: $review_file${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo -e "  仕様確定: ${WHITE}$0 finalize $session_id${NC}"
}

# 仕様確定
finalize_spec() {
    local session_id=$1
    local draft_file="$SPECS_DIR/${session_id}_draft.md"
    local final_file="$SPECS_DIR/${session_id}_final.md"
    local presentation_file="$REPORTS_DIR/${session_id}_presentation.md"
    
    echo -e "${YELLOW}仕様を確定中...${NC}"
    
    # 最終仕様書作成
    cp "$draft_file" "$final_file"
    sed -i.bak "s/ステータス: ドラフト/ステータス: 確定/" "$final_file"
    echo "" >> "$final_file"
    echo "確定日: $(date +"%Y-%m-%d %H:%M:%S")" >> "$final_file"
    
    # ユーザー向けプレゼンテーション資料作成
    cat > "$presentation_file" << EOF
# 仕様提案書

## エグゼクティブサマリー
お客様からいただいた要望「$(grep "^REQUEST:" "$BRAINSTORM_DIR/$session_id/session.info" | cut -d' ' -f2-)」について、
弊社のAIエージェントチームで検討した結果、以下の仕様を提案いたします。

## 提案内容

### 1. 実現する機能
$(grep -A 10 "## 2. 機能要件" "$final_file" | tail -n +2)

### 2. 期待される効果
- ビジネス面での効果
- ユーザー体験の向上
- 技術的な優位性

### 3. 開発スケジュール
$(grep -A 10 "## 6. 開発計画" "$final_file" | grep "Phase" || echo "詳細は仕様書をご確認ください")

### 4. 必要な投資
- 開発リソース: エンジニア10名、デザイナー2名、マーケター2名
- 開発期間: 約4週間
- その他必要なリソース

## 次のステップ
1. この提案内容のレビュー
2. 詳細な要件の確認
3. 開発着手

## 添付資料
- 詳細仕様書: ${session_id}_final.md
- ブレインストーミング記録: ${session_id}/summary.md

---
*この提案書はAI Multi-Agent Development Systemによって作成されました*
*作成日: $(date +"%Y-%m-%d %H:%M:%S")*
EOF
    
    # ステータス更新
    sed -i.bak "s/^STATUS: .*/STATUS: finalized/" "$BRAINSTORM_DIR/$session_id/session.info"
    
    echo -e "${GREEN}仕様が確定しました！${NC}"
    echo ""
    echo -e "${CYAN}=== 成果物 ===${NC}"
    echo -e "${BLUE}最終仕様書: $final_file${NC}"
    echo -e "${BLUE}プレゼン資料: $presentation_file${NC}"
    echo ""
    echo -e "${YELLOW}ユーザーへの提出準備が完了しました${NC}"
}

# 進行状況確認
show_status() {
    local session_id=$1
    
    if [ -n "$session_id" ]; then
        # 特定セッションの詳細
        local session_dir="$BRAINSTORM_DIR/$session_id"
        if [ ! -d "$session_dir" ]; then
            echo -e "${RED}エラー: セッションが見つかりません: $session_id${NC}"
            return 1
        fi
        
        echo -e "${CYAN}=== セッション詳細 ===${NC}"
        cat "$session_dir/session.info"
        echo ""
        
        # 関連ファイル
        echo -e "${YELLOW}関連ファイル:${NC}"
        find "$session_dir" -type f -name "*.md" | sort
        find "$SPECS_DIR" -name "${session_id}*" | sort
        find "$REPORTS_DIR" -name "${session_id}*" | sort
    else
        # 全セッション一覧
        echo -e "${CYAN}=== アクティブなブレインストーミングセッション ===${NC}"
        echo ""
        
        for session_dir in "$BRAINSTORM_DIR"/brainstorm_*; do
            if [ -d "$session_dir" ]; then
                local sid=$(basename "$session_dir")
                local status=$(grep "^STATUS:" "$session_dir/session.info" | cut -d' ' -f2)
                local request=$(grep "^REQUEST:" "$session_dir/session.info" | cut -d' ' -f2-)
                
                echo -e "${YELLOW}$sid${NC} [$status]"
                echo "  要望: $request"
                echo ""
            fi
        done
    fi
}

# メイン処理
main() {
    case "${1:-}" in
        start)
            if [ $# -ne 2 ]; then
                show_usage
                exit 1
            fi
            start_brainstorm "$2"
            ;;
        collect)
            if [ $# -ne 2 ]; then
                show_usage
                exit 1
            fi
            collect_opinions "$2"
            ;;
        draft)
            if [ $# -ne 2 ]; then
                show_usage
                exit 1
            fi
            create_draft_spec "$2"
            ;;
        review)
            if [ $# -ne 2 ]; then
                show_usage
                exit 1
            fi
            request_review "$2"
            ;;
        finalize)
            if [ $# -ne 2 ]; then
                show_usage
                exit 1
            fi
            finalize_spec "$2"
            ;;
        status)
            show_status "${2:-}"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# スクリプトの実行
main "$@"