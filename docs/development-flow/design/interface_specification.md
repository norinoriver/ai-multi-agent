# インターフェース仕様書 (Interface Specification)
## Multi-Agent Claude Code Development System (MACCDS)

## 1. 概要

### 1.1 目的
本文書は、MACCDSにおける外部システム連携および内部モジュール間のインターフェース仕様を定義する。

### 1.2 適用範囲
- 外部システムインターフェース（GitHub、Git、OS等）
- 内部モジュール間インターフェース（エージェント間通信等）
- データ交換フォーマットと通信プロトコル

### 1.3 参照文書
- [Software Design Document](./software_design_document.md)
- [アーキテクチャ・データフロー図](./architecture_dataflow_diagrams.md)

## 2. 外部インターフェース仕様

### 2.1 Claude Code CLI インターフェース

#### 2.1.1 エージェント起動インターフェース
```bash
# 基本起動コマンド
claude --profile <persona_file_path>

# 例
claude --profile agents/boss/CLAUDE.md
claude --profile agents/pm/CLAUDE.md
claude --profile agents/engineer/CLAUDE.md
```

**入力パラメータ:**
- `persona_file_path`: エージェントペルソナファイルのパス

**出力:**
- Claude Codeインスタンスの起動
- 指定ペルソナでの動作開始

**エラーハンドリング:**
- ファイル不存在: エラーメッセージと終了
- 権限不足: 権限エラーと終了

#### 2.1.2 エージェント間コマンド送信
```bash
# tmux経由でのコマンド送信
tmux send-keys -t <session>:<window>.<pane> "<command>" C-m

# 例
tmux send-keys -t ai-multi-agent:0.1 "start task-001" C-m
```

### 2.2 GitHub MCP インターフェース

#### 2.2.1 Pull Request 作成
```json
{
  "action": "create_pull_request",
  "parameters": {
    "owner": "string",
    "repo": "string", 
    "title": "string",
    "head": "string",
    "base": "string", 
    "body": "string",
    "draft": "boolean"
  }
}
```

**レスポンス:**
```json
{
  "status": "success|error",
  "data": {
    "pull_request_id": "number",
    "html_url": "string",
    "number": "number"
  },
  "error": "string"
}
```

#### 2.2.2 Pull Request レビュー
```json
{
  "action": "create_pull_request_review",
  "parameters": {
    "owner": "string",
    "repo": "string",
    "pull_number": "number",
    "body": "string",
    "event": "APPROVE|REQUEST_CHANGES|COMMENT",
    "comments": [
      {
        "path": "string",
        "line": "number",
        "body": "string"
      }
    ]
  }
}
```

### 2.3 Git インターフェース

#### 2.3.1 エージェントによるGit Worktree 操作
```bash
# エージェントが直接実行するworktree作成コマンド
git worktree add <path> <branch>

# 例
git worktree add ../worktrees/feature-task-001 feature/task-001
```

**パラメータ:**
- `path`: worktreeを作成するパス
- `branch`: 作成または切り替えるブランチ名

#### 2.3.2 エージェントによるGit Worktree 削除
```bash
# エージェントが直接実行するworktree削除コマンド
git worktree remove <path>

# 例
git worktree remove ../worktrees/feature-task-001
```

**注意:**
- 各エージェントが必要に応じて直接gitコマンドを実行
- Git Worktree Managerのような中間レイヤーは不要

## 3. 内部インターフェース仕様

### 3.1 エージェント間メッセージングインターフェース

#### 3.1.1 メッセージ形式
```json
{
  "messageId": "uuid",
  "timestamp": "ISO8601",
  "from": "agent_id",
  "to": "agent_id|broadcast",
  "type": "request|response|notification|command",
  "priority": "high|medium|low",
  "content": {
    "action": "string", 
    "data": "object",
    "context": "object"
  },
  "correlation_id": "uuid",
  "ttl": "number"
}
```

#### 3.1.2 メッセージタイプ定義

**Request Message:**
```json
{
  "type": "request",
  "content": {
    "action": "decompose_task|assign_task|review_code|run_test",
    "data": {
      "task_id": "string",
      "description": "string",
      "requirements": "object"
    }
  }
}
```

**Response Message:**
```json
{
  "type": "response", 
  "content": {
    "action": "task_decomposed|task_assigned|review_completed",
    "data": {
      "result": "object",
      "status": "success|failure|partial",
      "errors": ["string"]
    }
  }
}
```

**Notification Message:**
```json
{
  "type": "notification",
  "content": {
    "action": "progress_update|error_occurred|task_completed",
    "data": {
      "progress": "number",
      "message": "string",
      "details": "object"
    }
  }
}
```

### 3.2 タスク管理インターフェース

#### 3.2.1 タスク定義インターフェース
```json
{
  "taskId": "task-{uuid}",
  "title": "string",
  "description": "string", 
  "type": "implementation|testing|review|architecture|infrastructure|documentation",
  "priority": "high|medium|low",
  "status": "created|assigned|in_progress|review|testing|completed|cancelled",
  "assignee": "agent_id",
  "storyPoints": "number",
  "estimatedHours": "number",
  "dependencies": ["task_id"],
  "blockers": ["string"],
  "branch": "string",
  "created": "ISO8601",
  "updated": "ISO8601",
  "deadline": "ISO8601",
  "tags": ["string"],
  "metadata": {
    "requirements": "object",
    "acceptance_criteria": ["string"],
    "test_cases": ["object"]
  }
}
```

#### 3.2.2 タスク操作インターフェース

**タスク作成:**
```bash
POST /tasks
Content-Type: application/json

{
  "title": "string",
  "description": "string",
  "type": "string",
  "priority": "string",
  "assignee": "string",
  "storyPoints": "number"
}
```

**タスク更新:**
```bash
PUT /tasks/{task_id}
Content-Type: application/json

{
  "status": "string",
  "progress": "number", 
  "assignee": "string",
  "blockers": ["string"]
}
```

**タスク検索:**
```bash
GET /tasks?status=in_progress&assignee=se-agent-1&type=implementation
```

### 3.3 進捗管理インターフェース

#### 3.3.1 進捗レポート形式
```json
{
  "reportId": "report-{uuid}",
  "timestamp": "ISO8601",
  "type": "realtime|daily|weekly",
  "overallProgress": {
    "completed": "number",
    "in_progress": "number", 
    "pending": "number",
    "blocked": "number",
    "percentage": "number"
  },
  "agentStatus": {
    "boss": {
      "status": "online|busy|error|offline",
      "current_task": "string",
      "last_activity": "ISO8601"
    },
    "pm": {
      "status": "online|busy|error|offline", 
      "current_task": "string",
      "last_activity": "ISO8601"
    }
  },
  "tasks": [
    {
      "taskId": "string",
      "status": "string",
      "progress": "number",
      "assignee": "string",
      "estimated_completion": "ISO8601",
      "blockers": ["string"]
    }
  ],
  "metrics": {
    "velocity": "number",
    "throughput": "number",
    "lead_time": "number",
    "cycle_time": "number"
  }
}
```

## 4. ファイルシステムインターフェース

### 4.1 共有ディレクトリ構造
```
shared/
├── messages/           # エージェント間メッセージ
│   ├── inbox/         # 受信メッセージ
│   ├── outbox/        # 送信メッセージ 
│   └── archive/       # アーカイブ
├── tasks/             # タスク定義ファイル
│   ├── pending/       # 未着手タスク
│   ├── active/        # 進行中タスク
│   └── completed/     # 完了タスク
├── progress/          # 進捗情報
│   ├── realtime/      # リアルタイム進捗
│   ├── reports/       # 進捗レポート
│   └── metrics/       # 性能メトリクス
├── config/            # 設定ファイル
│   ├── agents.yaml    # エージェント設定
│   └── system.yaml    # システム設定
└── logs/              # ログファイル
    ├── agents/        # エージェント別ログ
    ├── system/        # システムログ
    └── audit/         # 監査ログ
```

### 4.2 ファイル命名規則

#### 4.2.1 メッセージファイル
```
{timestamp}_{from}_{to}_{message_id}.json

例:
20250107120000_boss_pm_msg-12345.json
20250107120001_pm_se1_msg-12346.json
```

#### 4.2.2 タスクファイル
```
task_{task_id}_{status}.json

例:
task_001_pending.json
task_001_in_progress.json
task_001_completed.json
```

#### 4.2.3 進捗ファイル
```
progress_{type}_{timestamp}.json

例:
progress_realtime_20250107120000.json
progress_daily_20250107.json
```

## 5. 設定ファイルインターフェース

### 5.1 エージェント設定 (agents.yaml)
```yaml
agents:
  boss:
    count: 1
    persona_file: "agents/boss/CLAUDE.md"
    skills: ["leadership", "requirement_analysis", "communication"]
    resources:
      memory: "2GB"
      cpu_priority: "high"
    
  pm: 
    count: 1
    persona_file: "agents/pm/CLAUDE.md"
    skills: ["project_management", "task_decomposition", "coordination"]
    resources:
      memory: "1GB"
      cpu_priority: "high"
      
  engineers:
    count: 3
    persona_file: "agents/engineer/CLAUDE.md"
    skills: ["frontend", "backend", "infrastructure"] 
    resources:
      memory: "2GB"
      cpu_priority: "medium"
      
  qa:
    count: 1
    persona_file: "agents/qa/CLAUDE.md"
    skills: ["testing", "quality_assurance", "automation"]
    resources:
      memory: "1GB"
      cpu_priority: "medium"
      
  review:
    count: 1
    persona_file: "agents/review/CLAUDE.md"
    skills: ["code_review", "security_analysis", "performance_analysis"]
    resources:
      memory: "1GB"
      cpu_priority: "medium"
      
  architect:
    count: 1
    persona_file: "agents/architect/CLAUDE.md"
    skills: ["system_design", "infrastructure", "documentation", "mcp_integration"]
    resources:
      memory: "2GB"
      cpu_priority: "medium"
```

### 5.2 システム設定 (system.yaml)
```yaml
system:
  name: "ai-multi-agent"
  version: "1.0.0"
  
tmux:
  session_name: "ai-multi-agent"
  windows:
    management: 0
    development: 1
    quality: 2
    
communication:
  protocol: "file_based"
  check_interval: 1  # seconds
  message_ttl: 3600  # seconds
  max_retries: 3
  
storage:
  base_path: "./shared"
  cleanup_interval: 86400  # seconds
  max_log_size: "10MB"
  retention_days: 30
  
git:
  worktree_base: "./worktrees"
  branch_prefix: "feature/"
  auto_cleanup: true
  
github:
  auto_create_pr: true
  auto_request_review: true
  merge_strategy: "squash"
  
monitoring:
  enabled: true
  metrics_interval: 30  # seconds
  health_check_interval: 60  # seconds
  alert_thresholds:
    error_rate: 0.05
    response_time: 5000  # milliseconds
```

## 6. ログインターフェース

### 6.1 ログ形式
```json
{
  "timestamp": "ISO8601",
  "level": "DEBUG|INFO|WARN|ERROR|FATAL",
  "logger": "agent_id|system",
  "message": "string",
  "context": {
    "task_id": "string",
    "session_id": "string",
    "correlation_id": "string"
  },
  "details": "object",
  "stack_trace": "string"
}
```

### 6.2 ログレベル定義
- **DEBUG**: 詳細なデバッグ情報
- **INFO**: 一般的な情報メッセージ
- **WARN**: 警告（処理は継続）
- **ERROR**: エラー（処理に影響）
- **FATAL**: 致命的エラー（システム停止）

## 7. エラーハンドリングインターフェース

### 7.1 エラー形式
```json
{
  "error_id": "uuid",
  "timestamp": "ISO8601",
  "type": "system|agent|communication|external",
  "severity": "low|medium|high|critical",
  "code": "string",
  "message": "string",
  "details": {
    "agent_id": "string",
    "task_id": "string",
    "operation": "string",
    "parameters": "object"
  },
  "stack_trace": "string",
  "recovery_action": "retry|escalate|ignore|restart",
  "resolved": "boolean",
  "resolution_time": "ISO8601"
}
```

### 7.2 エラーコード定義
- **SYS_001**: システム初期化エラー
- **AGT_001**: エージェント起動エラー
- **AGT_002**: エージェント通信エラー
- **TSK_001**: タスク作成エラー
- **TSK_002**: タスク割り当てエラー
- **GIT_001**: Git操作エラー
- **GH_001**: GitHub API エラー
- **FS_001**: ファイルシステムエラー

## 8. 性能インターフェース

### 8.1 メトリクス収集インターフェース
```json
{
  "metric_id": "uuid",
  "timestamp": "ISO8601",
  "type": "performance|resource|business",
  "name": "string",
  "value": "number",
  "unit": "string",
  "tags": {
    "agent_id": "string",
    "task_type": "string",
    "operation": "string"
  },
  "context": "object"
}
```

### 8.2 性能基準
- **タスク割り当て**: 5秒以内
- **エージェント間通信**: 1秒以内
- **Git操作**: 10秒以内
- **GitHub API**: 3秒以内
- **ファイルI/O**: 100ms以内

## 9. セキュリティインターフェース

### 9.1 認証インターフェース
```json
{
  "auth_type": "claude_cli|github_mcp|os_user",
  "credentials": {
    "type": "token|key|password",
    "value": "string",
    "expires": "ISO8601"
  },
  "permissions": ["read", "write", "execute", "admin"],
  "scope": "string"
}
```

### 9.2 監査ログインターフェース
```json
{
  "audit_id": "uuid",
  "timestamp": "ISO8601",
  "actor": "string",
  "action": "string",
  "resource": "string",
  "result": "success|failure",
  "details": "object",
  "ip_address": "string",
  "session_id": "string"
}
```

## 10. テストインターフェース

### 10.1 テスト実行インターフェース
```bash
# 単体テスト実行
POST /test/unit
{
  "test_suite": "string",
  "test_cases": ["string"],
  "environment": "local|ci"
}

# 統合テスト実行  
POST /test/integration
{
  "components": ["string"],
  "scenarios": ["string"]
}
```

### 10.2 テスト結果インターフェース
```json
{
  "test_run_id": "uuid",
  "timestamp": "ISO8601",
  "type": "unit|integration|e2e",
  "status": "passed|failed|skipped",
  "summary": {
    "total": "number",
    "passed": "number", 
    "failed": "number",
    "skipped": "number"
  },
  "results": [
    {
      "test_case": "string",
      "status": "passed|failed|skipped",
      "duration": "number",
      "error_message": "string",
      "stack_trace": "string"
    }
  ],
  "coverage": {
    "lines": "number",
    "functions": "number", 
    "branches": "number",
    "percentage": "number"
  }
}
```

---

**承認**  
本インターフェース仕様書は、MACCDSの内外連携における標準仕様として使用される。

作成日: 2025-01-07  
バージョン: 1.0.0