# Software Design Description (SDD)
## Multi-Agent Claude Code Development System (MACCDS)
### Version 1.0.0

## 1. 概要

### 1.1 目的
本文書は、MACCDSの詳細設計を記述し、各コンポーネントの内部構造、インターフェース、および実装方法を定義する。

### 1.2 適用範囲
- クラス設計とメソッド仕様
- シーケンス図による詳細な処理フロー
- データ構造とアルゴリズム
- エラーハンドリング詳細

### 1.3 参照文書
- [Software Design Document](../design/software_design_document.md)
- [Interface Specification](../design/interface_specification.md)

## 2. スクリプト構成とデータフロー設計

### 2.1 Boss/PO Agent スクリプト構成

#### 2.1.1 スクリプトファイル構成

```
boss_po/
├── init_agent.sh              # エージェント初期化
├── receive_request.sh         # 人間からの要求受信
├── analyze_requirement.sh     # 要求分析
├── negotiate_with_human.sh    # 人間との交渉・確認
├── delegate_to_team.sh        # チームへのタスク委譲
├── report_progress.sh         # 進捗レポート生成
├── validate_requirement.sh    # 要求検証
├── prioritize_tasks.sh        # タスク優先順位付け
└── lib/
    ├── common_functions.sh    # 共通関数
    └── constants.sh           # 定数定義
```

#### 2.1.2 データフロー図

```mermaid
flowchart TB
    subgraph "Boss/PO Agent"
        H[Human Input] -->|request.txt| RR[receive_request.sh]
        RR -->|raw_request.json| AR[analyze_requirement.sh]
        AR -->|analysis.json| NH[negotiate_with_human.sh]
        NH -->|agreement.json| DT[delegate_to_team.sh]
        
        VR[validate_requirement.sh] -.->|validation.json| AR
        PT[prioritize_tasks.sh] -.->|priorities.json| DT
        
        DT -->|task_messages/| MQ[(Message Queue)]
        RP[report_progress.sh] -->|progress_report.md| H
    end
```

#### 2.1.3 スクリプト仕様

**init_agent.sh**
- 説明: エージェントの初期化とディレクトリ構造作成
- 入力: `$1: agent_id`
- 出力: エージェントディレクトリ構造の作成
- ファイル生成: `agents/boss_po/$agent_id/metadata.json`

**receive_request.sh**
- 説明: 人間からの要求を受信し、構造化データに変換
- 入力: `stdin または $1: request_file`
- 出力: `stdout: JSON形式の要求データ`
- ファイル生成: `requests/${timestamp}_request.json`

### 2.2 PM Agent スクリプト構成

#### 2.2.1 スクリプトファイル構成

```
pm/
├── init_agent.sh                  # エージェント初期化
├── receive_requirement.sh         # 要件受信
├── decompose_task.sh             # タスク分解
├── assign_task.sh                # タスク割り当て
├── monitor_progress.sh           # 進捗監視
├── handle_blocker.sh             # ブロッカー対応
├── calculate_dependencies.sh      # 依存関係計算
├── optimize_assignment.sh        # 割り当て最適化
└── lib/
    ├── task_functions.sh         # タスク操作関数
    └── agent_status_manager.sh   # エージェント状態管理
```

#### 2.2.2 データフロー図

```mermaid
flowchart TB
    subgraph "PM Agent"
        MQ[(Message Queue)] -->|requirement.json| RR[receive_requirement.sh]
        RR -->|requirement.json| DT[decompose_task.sh]
        DT -->|tasks.json| CD[calculate_dependencies.sh]
        CD -->|dependency_graph.json| OA[optimize_assignment.sh]
        
        ASM[agent_status_manager.sh] -->|available_agents.json| OA
        OA -->|assignment_plan.json| AT[assign_task.sh]
        AT -->|task_messages/| SE[(SE Agents)]
        
        MP[monitor_progress.sh] <-->|status_updates/| ASM
        HB[handle_blocker.sh] <-.->|blocker_info.json| MP
    end
```

### 2.3 SE Agent スクリプト構成

#### 2.3.1 スクリプトファイル構成

```
se/
├── init_agent.sh              # エージェント初期化
├── receive_task.sh            # タスク受信
├── execute_task.sh            # タスク実行メイン
├── tdd/
│   ├── write_test.sh         # テスト作成 (Red)
│   ├── implement_code.sh     # コード実装 (Green)
│   ├── refactor_code.sh      # リファクタリング (Refactor)
│   └── run_tests.sh          # テスト実行
├── git/
│   ├── setup_worktree.sh     # worktree設定
│   ├── commit_changes.sh     # 変更コミット
│   └── create_pr.sh          # PR作成
└── lib/
    ├── test_helpers.sh       # テスト支援関数
    └── code_analyzer.sh      # コード解析関数
```

#### 2.3.2 データフロー図

```mermaid
flowchart TB
    subgraph "SE Agent - TDD Cycle"
        RT[receive_task.sh] -->|task.json| ET[execute_task.sh]
        ET -->|test_spec.json| WT[write_test.sh]
        WT -->|test_file.sh| RUN1[run_tests.sh]
        RUN1 -->|failed.json| IC[implement_code.sh]
        IC -->|code_file.sh| RUN2[run_tests.sh]
        RUN2 -->|passed.json| RC[refactor_code.sh]
        RC -->|refactored_code.sh| RUN3[run_tests.sh]
        RUN3 -->|passed.json| CC[commit_changes.sh]
        CC -->|commit_sha| CPR[create_pr.sh]
        CPR -->|pr_info.json| REV[(Review Agent)]
    end
```

### 2.4 Review Agent スクリプト構成

#### 2.4.1 スクリプトファイル構成

```
review/
├── init_agent.sh                 # エージェント初期化
├── review_pr.sh                  # PR レビューメイン
├── tests/
│   ├── setup_test_branch.sh     # テストブランチ設定
│   ├── run_e2e_tests.sh         # E2Eテスト実行
│   ├── run_integration_tests.sh # 統合テスト実行
│   └── cleanup_test_env.sh      # テスト環境クリーンアップ
├── review/
│   ├── code_review.sh           # コードレビュー
│   ├── wait_external_review.sh  # 外部レビュー待機
│   └── consolidate_reviews.sh   # レビュー結果統合
└── lib/
    ├── github_client.sh         # GitHub API操作
    └── test_runner.sh           # テスト実行支援
```

#### 2.4.2 データフロー図

```mermaid
flowchart TB
    subgraph "Review Agent"
        PR[(Pull Request)] -->|pr_info.json| RP[review_pr.sh]
        RP -->|pr_data.json| STB[setup_test_branch.sh]
        STB -->|test_branch_ready| E2E[run_e2e_tests.sh]
        STB -->|test_branch_ready| INT[run_integration_tests.sh]
        
        E2E -->|e2e_results.json| CR[code_review.sh]
        INT -->|integration_results.json| CR
        
        CR -->|internal_review.json| WER[wait_external_review.sh]
        WER -->|external_review.json| CON[consolidate_reviews.sh]
        CON -->|final_review.json| GH[(GitHub)]
        
        cleanup[cleanup_test_env.sh] -.->|cleanup| STB
    end
```

## 2.5 エージェント間のメッセージフロー全体図

```mermaid
flowchart LR
    H[Human] -->|request.txt| BP[Boss/PO Agent]
    BP -->|requirement.json| PM[PM Agent]
    PM -->|task_assignment.json| SE[SE Agent]
    SE -->|pr_info.json| RA[Review Agent]
    RA -->|review_result.json| PM
    PM -->|progress_update.json| BP
    BP -->|status_report.md| H
    
    subgraph "File System"
        MQ[(Message Queue)]
        TR[(Task Repository)]
        AS[(Agent Status)]
    end
    
    PM <-->|task_data| TR
    PM <-->|agent_status| AS
    BP <-->|messages| MQ
    PM <-->|messages| MQ
    SE <-->|messages| MQ
    RA <-->|messages| MQ
```

```mermaid
classDiagram
    class ReviewAgent {
        -String agentId
        -String status
        -String testBranchPath
        -GitHubClient githubClient
        +initialize()
        +reviewPullRequest(pr: PRInfo): ReviewResult
        +runE2ETests(pr: PRInfo): TestResult
        +runIntegrationTests(pr: PRInfo): TestResult
        +waitForExternalReview(pr: PRInfo): ExternalReview
        +consolidateReviews(reviews: List): FinalReview
        -setupTestBranch(pr: PRInfo): void
        -cleanupTestEnvironment(): void
    }
```

## 3. シーケンス図

### 3.1 タスク割り当てシーケンス

```mermaid
sequenceDiagram
    participant H as Human
    participant B as Boss/PO Agent
    participant P as PM Agent
    participant S as SE Agent
    participant A as Agent Status Manager
    participant T as Task Repository
    
    H->>B: 要求入力
    B->>B: 要求分析
    B->>H: 確認・提案
    H->>B: 承認
    
    B->>P: 要求委譲
    P->>T: タスク分解・保存
    
    P->>A: 空きエージェント確認
    A->>A: status/*_freeスキャン
    A->>P: 空きエージェントリスト
    
    P->>P: タスク最適割り当て計算
    P->>S: タスク割り当て
    
    S->>A: ステータス更新（free→work）
    S->>P: 割り当て確認
```

### 3.2 TDDサイクル詳細シーケンス

```mermaid
sequenceDiagram
    participant S as SE Agent
    participant W as Worktree
    participant T as Test Runner
    participant G as Git
    
    S->>W: テストファイル作成（Red）
    S->>T: テスト実行
    T->>S: 失敗結果（期待通り）
    
    S->>W: 最小限のコード実装（Green）
    S->>T: テスト実行
    T->>S: テスト結果
    
    alt テスト失敗
        S->>W: コード修正
        S->>T: 再テスト
    else テスト成功
        S->>W: リファクタリング（Refactor）
        S->>T: 回帰テスト
        S->>G: git commit
    end
    
    S->>S: 次のテスト必要？
    
    alt 追加テスト必要
        S->>W: 次のテスト作成
    else 完了
        S->>G: git push
        S->>G: PR作成
    end
```

### 3.3 レビュー処理詳細シーケンス

```mermaid
sequenceDiagram
    participant P as PR
    participant R as Review Agent
    participant T as Test Branch
    participant E as E2E Test Env
    participant G as GitHub API
    participant C as CodeRabbit
    
    P->>R: レビュー要求
    
    par 内部レビュー
        R->>R: コード解析
        R->>R: 品質チェック
    and 外部レビュー開始
        P->>C: レビュー自動起動
    end
    
    R->>T: PR内容を専用ブランチに反映
    T->>T: git reset --hard main
    T->>T: git merge PR
    
    R->>E: E2E/統合テスト環境構築
    E->>E: 専用ポート設定
    
    R->>E: テスト実行
    E->>R: テスト結果
    
    alt テスト失敗
        R->>P: レビュー却下
    else テスト成功
        loop CodeRabbit完了待ち
            R->>G: レビュー状態確認
            G->>R: ステータス返却
        end
        R->>P: 統合レビュー結果
    end
    
    R->>E: 環境クリーンアップ
```

## 4. データ構造詳細

### 4.1 Task データ構造

```typescript
interface Task {
    taskId: string;           // UUID v4
    title: string;            // 最大200文字
    description: string;      // Markdown形式
    type: TaskType;          // enum
    assignee?: string;       // agent_id
    status: TaskStatus;      // enum
    priority: Priority;      // high|medium|low
    storyPoints: number;     // 1-13
    dependencies: string[];  // taskId配列
    metadata: {
        createdAt: Date;
        updatedAt: Date;
        createdBy: string;
        tags: string[];
        branch?: string;     // feature/task-xxx
        pullRequestId?: number;
    };
    acceptanceCriteria: AcceptanceCriterion[];
}

interface AcceptanceCriterion {
    id: string;
    description: string;
    testable: boolean;
    completed: boolean;
}

enum TaskType {
    IMPLEMENTATION = "implementation",
    TESTING = "testing",
    REVIEW = "review",
    ARCHITECTURE = "architecture",
    INFRASTRUCTURE = "infrastructure",
    DOCUMENTATION = "documentation"
}

enum TaskStatus {
    CREATED = "created",
    ASSIGNED = "assigned",
    IN_PROGRESS = "in_progress",
    REVIEW = "review",
    TESTING = "testing",
    COMPLETED = "completed",
    BLOCKED = "blocked",
    CANCELLED = "cancelled"
}
```

### 4.2 Agent Message データ構造

```typescript
interface AgentMessage {
    messageId: string;        // UUID v4
    timestamp: Date;         // ISO 8601
    from: string;           // agent_id
    to: string | "broadcast"; // agent_id or broadcast
    type: MessageType;
    priority: Priority;
    content: MessageContent;
    metadata: {
        correlationId?: string;  // 関連メッセージID
        replyTo?: string;       // 返信先メッセージID
        ttl?: number;          // Time to Live (秒)
        retryCount?: number;   // 再送回数
    };
}

type MessageContent = 
    | TaskAssignmentMessage
    | ProgressUpdateMessage
    | BlockerNotificationMessage
    | ReviewRequestMessage
    | CommandMessage;

interface TaskAssignmentMessage {
    action: "ASSIGN_TASK";
    taskId: string;
    deadline?: Date;
    notes?: string;
}

interface ProgressUpdateMessage {
    action: "UPDATE_PROGRESS";
    taskId: string;
    progress: number;      // 0-100
    message: string;
    blockers?: string[];
}
```

### 4.3 Agent Status データ構造

```typescript
interface AgentStatus {
    agentId: string;
    type: AgentType;
    status: AgentState;
    currentTask?: string;
    workload: number;       // 0-10
    lastHeartbeat: Date;
    capabilities: string[];
    metadata: {
        worktreePath?: string;
        sessionInfo?: {
            tmuxSession: string;
            tmuxWindow: number;
            tmuxPane: number;
        };
        performance?: {
            tasksCompleted: number;
            averageTime: number;
            successRate: number;
        };
    };
}

enum AgentState {
    INITIALIZING = "initializing",
    FREE = "free",
    BUSY = "busy",
    WORKING = "working",
    ERROR = "error",
    OFFLINE = "offline"
}
```

## 5. アルゴリズム詳細

### 5.1 タスク割り当てアルゴリズム

```typescript
class TaskAssignmentOptimizer {
    /**
     * タスクを最適なエージェントに割り当て
     */
    optimizeAssignment(
        tasks: Task[], 
        agents: AgentStatus[]
    ): Map<string, string> {
        const assignments = new Map<string, string>();
        
        // 1. タスクを優先度とストーリーポイントでソート
        const sortedTasks = tasks.sort((a, b) => {
            if (a.priority !== b.priority) {
                return this.priorityValue(a.priority) - 
                       this.priorityValue(b.priority);
            }
            return b.storyPoints - a.storyPoints;
        });
        
        // 2. 各タスクに対して最適なエージェントを選択
        for (const task of sortedTasks) {
            const availableAgents = agents.filter(agent => 
                agent.status === AgentState.FREE &&
                this.hasCapability(agent, task.type) &&
                agent.workload + task.storyPoints <= 10
            );
            
            if (availableAgents.length === 0) {
                continue; // 後で再割り当て
            }
            
            // 3. 負荷分散を考慮して選択
            const selectedAgent = availableAgents.reduce((best, current) => 
                current.workload < best.workload ? current : best
            );
            
            assignments.set(task.taskId, selectedAgent.agentId);
            selectedAgent.workload += task.storyPoints;
        }
        
        return assignments;
    }
    
    private priorityValue(priority: Priority): number {
        switch (priority) {
            case Priority.HIGH: return 1;
            case Priority.MEDIUM: return 2;
            case Priority.LOW: return 3;
        }
    }
}
```

### 5.2 非ブロックファイル書き込みアルゴリズム

```typescript
class NonBlockingFileWriter {
    /**
     * 非ブロックでファイルに書き込み
     */
    async writeFile(
        filePath: string, 
        content: string,
        agentId: string
    ): Promise<void> {
        // 1. 一時ファイル名生成
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const uuid = crypto.randomUUID();
        const tempFile = `${agentId}_${timestamp}_${uuid}.tmp`;
        const tempPath = path.join(path.dirname(filePath), 'temp', tempFile);
        
        try {
            // 2. 一時ファイルに書き込み
            await fs.writeFile(tempPath, content, 'utf8');
            
            // 3. アトミックに移動
            await fs.rename(tempPath, filePath);
            
        } catch (error) {
            // 4. エラー時は一時ファイルを削除
            await fs.unlink(tempPath).catch(() => {});
            throw error;
        }
    }
    
    /**
     * 複数の一時ファイルを結合
     */
    async consolidateFiles(
        pattern: string,
        outputPath: string
    ): Promise<void> {
        const files = await glob(pattern);
        const sortedFiles = files.sort(); // タイムスタンプ順
        
        const writeStream = createWriteStream(outputPath);
        
        for (const file of sortedFiles) {
            const content = await fs.readFile(file, 'utf8');
            writeStream.write(content);
            writeStream.write('\n');
            
            // 処理済みファイルを削除
            await fs.unlink(file);
        }
        
        writeStream.end();
    }
}
```

## 6. エラーハンドリング

### 6.1 エラー階層

```typescript
class MACCDSError extends Error {
    constructor(
        message: string,
        public code: string,
        public severity: 'low' | 'medium' | 'high' | 'critical',
        public recoverable: boolean
    ) {
        super(message);
        this.name = 'MACCDSError';
    }
}

class AgentError extends MACCDSError {
    constructor(
        message: string,
        public agentId: string,
        code: string,
        severity: 'low' | 'medium' | 'high' | 'critical',
        recoverable: boolean
    ) {
        super(message, code, severity, recoverable);
        this.name = 'AgentError';
    }
}

class TaskError extends MACCDSError {
    constructor(
        message: string,
        public taskId: string,
        code: string
    ) {
        super(message, code, 'high', true);
        this.name = 'TaskError';
    }
}
```

### 6.2 エラーハンドリング戦略

```typescript
class ErrorHandler {
    async handle(error: Error, context: ExecutionContext): Promise<void> {
        if (error instanceof MACCDSError) {
            await this.logError(error, context);
            
            if (error.recoverable) {
                await this.attemptRecovery(error, context);
            } else {
                await this.escalate(error, context);
            }
            
            if (error.severity === 'critical') {
                await this.notifyHuman(error, context);
            }
        } else {
            // 予期しないエラー
            await this.handleUnexpectedError(error, context);
        }
    }
    
    private async attemptRecovery(
        error: MACCDSError, 
        context: ExecutionContext
    ): Promise<void> {
        const strategies = {
            'AGT_001': () => this.restartAgent(context.agentId),
            'TSK_001': () => this.retryTask(context.taskId),
            'GIT_001': () => this.resetGitState(context.worktreePath),
            // ... 他のリカバリー戦略
        };
        
        const strategy = strategies[error.code];
        if (strategy) {
            await strategy();
        }
    }
}
```

## 7. パフォーマンス考慮事項

### 7.1 並列処理最適化

```typescript
class ParallelExecutor {
    private readonly MAX_CONCURRENT = 10;
    private readonly BATCH_SIZE = 5;
    
    async executeParallel<T>(
        tasks: (() => Promise<T>)[]
    ): Promise<T[]> {
        const results: T[] = [];
        
        // バッチ処理で実行
        for (let i = 0; i < tasks.length; i += this.BATCH_SIZE) {
            const batch = tasks.slice(i, i + this.BATCH_SIZE);
            const batchResults = await Promise.all(
                batch.map(task => this.executeWithTimeout(task))
            );
            results.push(...batchResults);
        }
        
        return results;
    }
    
    private async executeWithTimeout<T>(
        task: () => Promise<T>,
        timeout: number = 30000
    ): Promise<T> {
        return Promise.race([
            task(),
            new Promise<T>((_, reject) => 
                setTimeout(() => reject(new Error('Timeout')), timeout)
            )
        ]);
    }
}
```

### 7.2 キャッシング戦略

```typescript
class CacheManager {
    private cache = new Map<string, CacheEntry>();
    private readonly TTL = 300000; // 5分
    
    async get<T>(
        key: string, 
        factory: () => Promise<T>
    ): Promise<T> {
        const cached = this.cache.get(key);
        
        if (cached && cached.expiry > Date.now()) {
            return cached.value as T;
        }
        
        const value = await factory();
        this.cache.set(key, {
            value,
            expiry: Date.now() + this.TTL
        });
        
        return value;
    }
    
    invalidate(pattern: string): void {
        const regex = new RegExp(pattern);
        for (const key of this.cache.keys()) {
            if (regex.test(key)) {
                this.cache.delete(key);
            }
        }
    }
}
```

---

**承認**  
本詳細設計書は、MACCDSの実装ガイドラインとして使用される。

作成日: 2025-01-07  
バージョン: 1.0.0