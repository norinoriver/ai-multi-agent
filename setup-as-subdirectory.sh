#!/bin/bash

# AI Multi-Agent サブディレクトリセットアップスクリプト
# このスクリプトは、ai-multi-agentを他のプロジェクトのサブディレクトリとして配置する際の初期設定を行います

set -e

echo "🚀 AI Multi-Agent サブディレクトリセットアップを開始します"

# 現在のディレクトリを取得（ai-multi-agentディレクトリ）
AI_MULTI_AGENT_DIR=$(pwd)
AI_MULTI_AGENT_NAME=$(basename "$AI_MULTI_AGENT_DIR")

# プロジェクトルートディレクトリを取得（一つ上のディレクトリ）
PROJECT_ROOT=$(dirname "$AI_MULTI_AGENT_DIR")

echo "📁 設定情報:"
echo "  - AI Multi-Agent Dir: $AI_MULTI_AGENT_DIR"
echo "  - AI Multi-Agent Name: $AI_MULTI_AGENT_NAME"  
echo "  - Project Root: $PROJECT_ROOT"

# 1. プロジェクトルートディレクトリにCLAUDE.mdを作成
echo "📝 プロジェクトルートにCLAUDE.mdを作成中..."

# 既存のCLAUDE.mdがある場合は確認
if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    echo "⚠️  既存のCLAUDE.mdが見つかりました: $PROJECT_ROOT/CLAUDE.md"
    echo "上書きしますか？ (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "📄 CLAUDE.mdの作成をスキップしました"
        CLAUDE_MD_CREATED=false
    else
        echo "📄 既存のCLAUDE.mdを上書きします"
        CLAUDE_MD_CREATED=true
    fi
else
    CLAUDE_MD_CREATED=true
fi

if [ "$CLAUDE_MD_CREATED" = true ]; then
    cat > "$PROJECT_ROOT/CLAUDE.md" << 'EOF'
# CLAUDE.md

## ✅ ロール確認と指示書読み込み手順

作業の最初に、
``echo $TMUX_PANE``でペイン番号を読み込み自分のロール番号を確認して
以下を読み自己紹介をして下さい:
@/ai-multi-agent/agents/engineer/CLAUDE.md


---

## 🧠 ロール一覧

| ロール名   | 対象ペイン番号 |
|------------|----------------|
| Boss       | 0              |
| Engineer   | 1 ～ 10        |
| Designer   | 11, 12         |
| Marketer   | 13, 14         |

---

## 📄 指示書の読み込みルール

自分のロールに該当するパスの指示書を読み込んでください：

- **Boss**: `@/ai-multi-agent/agents/boss/CLAUDE.md`
- **Engineer**: `@/ai-multi-agent/agents/engineer/CLAUDE.md`
- **Designer**: `@/ai-multi-agent/agents/designer/CLAUDE.md`
- **Marketer**: `@/ai-multi-agent/agents/marketer/CLAUDE.md`

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
EOF
    echo "✅ $PROJECT_ROOT/CLAUDE.md を作成しました"
fi

# 2. プロジェクトルートの.gitignoreにai-multi-agentを追加
GITIGNORE_PATH="$PROJECT_ROOT/.gitignore"

echo "🚫 プロジェクトルートの.gitignoreにai-multi-agentを追加中..."

# .gitignoreファイルが存在しない場合は作成
if [ ! -f "$GITIGNORE_PATH" ]; then
    touch "$GITIGNORE_PATH"
    echo "📄 $GITIGNORE_PATH を作成しました"
fi

# ai-multi-agentが既に記載されているかチェック
if ! grep -q "^$AI_MULTI_AGENT_NAME" "$GITIGNORE_PATH"; then
    echo "" >> "$GITIGNORE_PATH"
    echo "# AI Multi-Agent System" >> "$GITIGNORE_PATH"
    echo "$AI_MULTI_AGENT_NAME/" >> "$GITIGNORE_PATH"
    echo "$AI_MULTI_AGENT_NAME/notifications/" >> "$GITIGNORE_PATH"
    echo "$AI_MULTI_AGENT_NAME/brainstorm/" >> "$GITIGNORE_PATH"
    echo "$AI_MULTI_AGENT_NAME/commands/" >> "$GITIGNORE_PATH"
    echo "$AI_MULTI_AGENT_NAME/tasks/" >> "$GITIGNORE_PATH"
    echo "$AI_MULTI_AGENT_NAME/reports/" >> "$GITIGNORE_PATH"
    echo "✅ .gitignoreに$AI_MULTI_AGENT_NAMEの除外設定を追加しました"
else
    echo "ℹ️  .gitignoreに$AI_MULTI_AGENT_NAMEは既に設定されています"
fi

# 3. 必要なディレクトリを作成
echo "📁 必要なディレクトリを作成中..."
mkdir -p "$AI_MULTI_AGENT_DIR/notifications/pending"
mkdir -p "$AI_MULTI_AGENT_DIR/notifications/processed"
mkdir -p "$AI_MULTI_AGENT_DIR/brainstorm"
mkdir -p "$AI_MULTI_AGENT_DIR/commands"
mkdir -p "$AI_MULTI_AGENT_DIR/tasks"
mkdir -p "$AI_MULTI_AGENT_DIR/reports"

echo "✅ 必要なディレクトリを作成しました"

# 4. スクリプトファイルの実行権限を確認・設定
echo "🔧 スクリプトファイルの実行権限を設定中..."
find "$AI_MULTI_AGENT_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
echo "✅ スクリプトファイルの実行権限を設定しました"

# 5. 設定完了の確認
echo ""
echo "🎉 AI Multi-Agent サブディレクトリセットアップが完了しました！"
echo ""
echo "📋 セットアップ結果:"
if [ "$CLAUDE_MD_CREATED" = true ]; then
    echo "  ✅ $PROJECT_ROOT/CLAUDE.md を作成"
else
    echo "  ⏭️  $PROJECT_ROOT/CLAUDE.md の作成をスキップ"
fi
echo "  ✅ $PROJECT_ROOT/.gitignore にai-multi-agent除外設定を追加"
echo "  ✅ 必要なディレクトリを作成"
echo "  ✅ スクリプトファイルの実行権限を設定"
echo ""
echo "🚀 次のステップ:"
echo "  1. cd '$PROJECT_ROOT' でプロジェクトルートに移動"
echo "  2. claude --dangerously-skip-permissions でClaude Codeを起動"
echo "  3. プロジェクトルートのCLAUDE.mdが自動的に読み込まれます"
echo ""
echo "💡 ダッシュボード起動方法:"
echo "  cd '$AI_MULTI_AGENT_DIR' && ./scripts/ai-multi-agent-dashboard.sh"