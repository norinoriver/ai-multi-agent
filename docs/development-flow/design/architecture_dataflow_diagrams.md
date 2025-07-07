# アーキテクチャ・データフロー図
## Multi-Agent Claude Code Development System (MACCDS)

## 1. 概要

本文書は、MACCDSのアーキテクチャとデータフローを視覚的に表現する図表集です。システムの構造理解と実装ガイドとして活用されます。

## 2. システムアーキテクチャ図

### 2.1 レイヤード・アーキテクチャ詳細図

```mermaid
graph TB
    subgraph "UI Layer"
        H[Human User]
        CLI[Claude Code CLI Interface]
    end
    
    subgraph "Presentation Layer"
        B[Boss/PO Agent]
        D[Dashboard View]
        S[Status Display]
    end
    
    subgraph "Business Logic Layer"
        P[PM Agent]
        TM[Task Manager]
        CM[Communication Manager]
        WM[Workflow Manager]
    end
    
    subgraph "Service Layer"
        SE1[SE Agent 1]
        SE2[SE Agent 2] 
        SE3[SE Agent 3]
        QA[QA Agent]
        R[Review Agent]
        A[Architect Agent]
    end
    
    subgraph "Infrastructure Layer"
        TS[tmux Session Manager]
        GIT[Git Repository]
        GM[GitHub MCP]
        FS[File System Storage]
    end
    
    subgraph "External Systems"
        GH[GitHub Repository]
        GIT[Git Repository]
        OS[Operating System]
    end
    
    H --> CLI
    CLI --> B
    B --> D
    B --> P
    D --> S
    P --> TM
    P --> CM
    P --> WM
    TM --> SE1
    TM --> SE2
    TM --> SE3
    TM --> QA
    TM --> R
    TM --> A
    CM --> FS
    WM --> TS
    SE1 --> GIT
    SE2 --> GIT
    SE3 --> GIT
    QA --> GIT
    R --> GM
    A --> GIT
    TS --> OS
    GM --> GH
    FS --> OS
```

### 2.2 コンポーネント間依存関係図

```mermaid
graph LR
    subgraph "Core Components"
        Boss[Boss/PO Agent]
        PM[PM Agent]
        TaskMgr[Task Manager]
        CommMgr[Communication Manager]
    end
    
    subgraph "Worker Components"
        SE[SE Agents]
        QA[QA Agent]
        Review[Review Agent]
        Arch[Architect Agent]
    end
    
    subgraph "Infrastructure Components"
        Tmux[tmux Manager]
        Git[Git Manager]
        GitHub[GitHub MCP]
        Storage[Shared Storage]
    end
    
    Boss -->|delegates| PM
    PM -->|manages| TaskMgr
    PM -->|coordinates| CommMgr
    TaskMgr -->|assigns| SE
    TaskMgr -->|assigns| QA
    TaskMgr -->|assigns| Review
    TaskMgr -->|assigns| Arch
    CommMgr -->|stores| Storage
    SE -->|uses| Git
    QA -->|uses| Git
    Review -->|uses| GitHub
    Arch -->|uses| Git
    Tmux -->|hosts| SE
    Tmux -->|hosts| QA
    Tmux -->|hosts| Review
    Tmux -->|hosts| Arch
    Storage -->|persists| TaskMgr
    Storage -->|persists| CommMgr
```

## 3. データフロー図

### 3.1 主要ワークフロー・データフロー

```mermaid
flowchart TD
    Start([システム起動]) --> Init[エージェント初期化]
    Init --> Ready[待機状態]
    Ready --> ReqInput[要求入力]
    
    ReqInput --> ReqAnalysis[要求分析]
    ReqAnalysis --> ReqConfirm[要求確認]
    ReqConfirm --> Approved{承認?}
    Approved -->|No| ReqAnalysis
    Approved -->|Yes| TaskDecomp[タスク分解]
    
    TaskDecomp --> TaskAssign[タスク割り当て]
    TaskAssign --> ParallelDev[並列開発]
    
    ParallelDev --> CodeImpl[コード実装]
    ParallelDev --> TestImpl[テスト実装]
    ParallelDev --> ArchWork[アーキテクチャ作業]
    
    CodeImpl --> PRCreate[PR作成]
    TestImpl --> TestExec[テスト実行]
    ArchWork --> ArchReview[アーキテクチャレビュー]
    
    PRCreate --> CodeReview[コードレビュー]
    CodeReview --> ReviewOK{レビューOK?}
    ReviewOK -->|No| CodeImpl
    ReviewOK -->|Yes| Merge[マージ]
    
    TestExec --> TestOK{テストOK?}
    TestOK -->|No| CodeImpl
    TestOK -->|Yes| QualityReport[品質レポート]
    
    ArchReview --> ArchOK{アーキテクチャOK?}
    ArchOK -->|No| ArchWork
    ArchOK -->|Yes| ArchApprove[アーキテクチャ承認]
    
    Merge --> Progress[進捗更新]
    QualityReport --> Progress
    ArchApprove --> Progress
    
    Progress --> Complete{完了?}
    Complete -->|No| TaskAssign
    Complete -->|Yes| Report[結果報告]
    
    Report --> Ready
```

### 3.2 タスク管理データフロー

```mermaid
sequenceDiagram
    participant H as Human
    participant B as Boss/PO
    participant P as PM
    participant T as TaskManager
    participant S as SharedStorage
    participant W as Workers
    
    H->>B: 要求入力
    B->>B: 要求分析
    B->>H: 確認・提案
    H->>B: 承認
    
    B->>P: 開発指示
    P->>T: タスク分解要求
    
    T->>S: タスク定義保存
    S-->>T: 保存確認
    
    T->>W: タスク分解依頼
    W->>T: 分解結果
    
    T->>S: 分解済みタスク保存
    S-->>T: 保存確認
    
    T->>W: タスク割り当て
    W->>T: 割り当て確認
    
    loop 作業実行
        W->>T: 進捗更新
        T->>S: 進捗保存
        T->>P: 進捗報告
    end
    
    W->>T: 完了報告
    T->>S: 完了状態保存
    T->>P: 完了通知
    P->>B: 全体進捗報告
    B->>H: 結果報告
```

### 3.3 エージェント間通信フロー

```mermaid
sequenceDiagram
    participant A1 as Agent 1
    participant CM as Communication Manager
    participant S as Shared Storage
    participant A2 as Agent 2
    
    A1->>CM: メッセージ送信要求
    CM->>S: メッセージ保存
    S-->>CM: 保存完了
    CM-->>A1: 送信確認
    
    CM->>A2: メッセージ通知
    A2->>S: メッセージ取得
    S-->>A2: メッセージ内容
    A2->>CM: 受信確認
    CM->>S: 受信ステータス更新
    
    A2->>CM: 応答メッセージ送信
    CM->>S: 応答保存
    CM->>A1: 応答通知
    A1->>S: 応答取得
```

## 4. Git Worktree データフロー

### 4.1 並列開発環境構築フロー

```mermaid
flowchart TD
    TaskAssigned[タスク割り当て] --> BranchReq[ブランチ作成要求]
    BranchReq --> GitCmd[git worktree add コマンド実行]
    
    GitCmd --> CheckMain[メインブランチ確認]
    CheckMain --> CreateBranch[feature ブランチ作成]
    CreateBranch --> CreateWorktree[worktree 作成]
    CreateWorktree --> SetupEnv[開発環境セットアップ]
    
    SetupEnv --> WorkspaceReady[ワークスペース準備完了]
    WorkspaceReady --> AgentWork[エージェント作業開始]
    
    AgentWork --> CodeChange[コード変更]
    CodeChange --> LocalCommit[ローカルコミット]
    LocalCommit --> PRCreate[PR作成]
    
    PRCreate --> Review[レビュー]
    Review --> ReviewOK{レビューOK?}
    ReviewOK -->|No| CodeChange
    ReviewOK -->|Yes| Merge[メインブランチマージ]
    
    Merge --> Cleanup[worktree クリーンアップ]
    Cleanup --> BranchDelete[git worktree remove コマンド実行]
    BranchDelete --> Complete[完了]
```

### 4.2 Git Worktree 管理構造

```mermaid
graph TB
    MainRepo[Main Repository] --> WT1[Worktree 1<br/>feature/task-001]
    MainRepo --> WT2[Worktree 2<br/>feature/task-002]
    MainRepo --> WT3[Worktree 3<br/>feature/task-003]
    MainRepo --> WT4[Worktree 4<br/>feature/test-001]
    MainRepo --> WT5[Worktree 5<br/>feature/arch-001]
    
    WT1 --> SE1[SE Agent 1]
    WT2 --> SE2[SE Agent 2]
    WT3 --> SE3[SE Agent 3]
    WT4 --> QA[QA Agent]
    WT5 --> Arch[Architect Agent]
    
    SE1 --> PR1[PR #001]
    SE2 --> PR2[PR #002]
    SE3 --> PR3[PR #003]
    QA --> PR4[PR #004]
    Arch --> PR5[PR #005]
    
    PR1 --> Review[Review Agent]
    PR2 --> Review
    PR3 --> Review
    PR4 --> Review
    PR5 --> Review
```

## 5. システム状態遷移図

### 5.1 エージェント状態遷移

```mermaid
stateDiagram-v2
    [*] --> Initializing
    Initializing --> Ready: 初期化完了
    Ready --> Busy: タスク受信
    Busy --> Working: 作業開始
    Working --> Reviewing: 作業完了
    Reviewing --> Ready: レビュー完了
    Working --> Error: エラー発生
    Error --> Recovery: 復旧処理
    Recovery --> Ready: 復旧完了
    Recovery --> Error: 復旧失敗
    Ready --> Shutdown: 停止指示
    Busy --> Shutdown: 停止指示
    Working --> Shutdown: 停止指示
    Error --> Shutdown: 停止指示
    Shutdown --> [*]
```

### 5.2 タスク状態遷移

```mermaid
stateDiagram-v2
    [*] --> Created
    Created --> Analyzed: 要求分析完了
    Analyzed --> Decomposed: タスク分解完了
    Decomposed --> Assigned: 割り当て完了
    Assigned --> InProgress: 作業開始
    InProgress --> Review: 実装完了
    Review --> Testing: レビュー承認
    Testing --> Complete: テスト完了
    Complete --> [*]
    
    Review --> InProgress: レビュー差し戻し
    Testing --> InProgress: テスト失敗
    InProgress --> Blocked: ブロック発生
    Blocked --> InProgress: ブロック解除
    Assigned --> Cancelled: キャンセル
    InProgress --> Cancelled: キャンセル
    Cancelled --> [*]
```

## 6. 通信アーキテクチャ図

### 6.1 tmux ベース通信構造

```mermaid
graph TB
    subgraph "tmux Session: ai-multi-agent"
        subgraph "Window 0: Management"
            P0[Pane 0: Boss/PO Agent]
            P1[Pane 1: PM Agent]
            P2[Pane 2: Dashboard]
        end
        
        subgraph "Window 1: Development"
            P10[Pane 0: SE Agent 1]
            P11[Pane 1: SE Agent 2]
            P12[Pane 2: SE Agent 3]
        end
        
        subgraph "Window 2: Quality"
            P20[Pane 0: QA Agent]
            P21[Pane 1: Review Agent]
            P22[Pane 2: Architect Agent]
        end
    end
    
    subgraph "Shared Communication"
        Messages[/shared/messages/]
        Tasks[/shared/tasks/]
        Progress[/shared/progress/]
    end
    
    P0 --> Messages
    P1 --> Messages
    P10 --> Messages
    P11 --> Messages
    P12 --> Messages
    P20 --> Messages
    P21 --> Messages
    P22 --> Messages
    
    P1 --> Tasks
    P10 --> Tasks
    P11 --> Tasks
    P12 --> Tasks
    P20 --> Tasks
    P21 --> Tasks
    P22 --> Tasks
    
    P2 --> Progress
    Messages --> Progress
    Tasks --> Progress
```

### 6.2 ファイルベース通信プロトコル

```mermaid
sequenceDiagram
    participant S as Sender Agent
    participant FS as File System
    participant R as Receiver Agent
    participant W as Watcher Process
    
    S->>FS: メッセージファイル作成
    FS->>W: ファイル変更通知
    W->>R: 新規メッセージ通知
    R->>FS: メッセージ読み取り
    R->>FS: 受信確認ファイル作成
    FS->>W: 確認ファイル通知
    W->>S: 受信確認通知
    S->>FS: メッセージファイル削除
```

## 7. セキュリティアーキテクチャ図

### 7.1 権限管理構造

```mermaid
graph TB
    subgraph "Authentication Layer"
        Claude[Claude Code CLI Auth]
        GitHub[GitHub MCP Auth]
        OS[OS User Auth]
    end
    
    subgraph "Authorization Layer"
        Permissions[Permission Manager]
        Policies[Security Policies]
    end
    
    subgraph "Resource Access"
        FileSystem[File System Access]
        GitRepo[Git Repository Access]
        GitHubAPI[GitHub API Access]
        SystemCmd[System Command Access]
    end
    
    Claude --> Permissions
    GitHub --> Permissions
    OS --> Permissions
    
    Permissions --> Policies
    Policies --> FileSystem
    Policies --> GitRepo
    Policies --> GitHubAPI
    Policies --> SystemCmd
```

## 8. 監視・ログアーキテクチャ

### 8.1 ログ集約構造

```mermaid
graph TB
    subgraph "Log Sources"
        AgentLogs[Agent Logs]
        SystemLogs[System Logs]
        GitLogs[Git Logs]
        GitHubLogs[GitHub API Logs]
    end
    
    subgraph "Log Processing"
        Collector[Log Collector]
        Parser[Log Parser]
        Aggregator[Log Aggregator]
    end
    
    subgraph "Log Storage"
        Files[Log Files]
        Structured[Structured Logs]
        Metrics[Performance Metrics]
    end
    
    subgraph "Monitoring"
        Dashboard[Monitoring Dashboard]
        Alerts[Alert System]
        Reports[Status Reports]
    end
    
    AgentLogs --> Collector
    SystemLogs --> Collector
    GitLogs --> Collector
    GitHubLogs --> Collector
    
    Collector --> Parser
    Parser --> Aggregator
    
    Aggregator --> Files
    Aggregator --> Structured
    Aggregator --> Metrics
    
    Files --> Dashboard
    Structured --> Dashboard
    Metrics --> Dashboard
    
    Dashboard --> Alerts
    Dashboard --> Reports
```

## 9. 配置図詳細

### 9.1 開発マシン内部構造

```mermaid
graph TB
    subgraph "Development Machine"
        subgraph "Process Layer"
            TmuxMain[tmux main process]
            TmuxSession[tmux session: ai-multi-agent]
        end
        
        subgraph "Agent Processes"
            BossProcess[Boss Agent Process]
            PMProcess[PM Agent Process]
            SEProcess1[SE Agent 1 Process]
            SEProcess2[SE Agent 2 Process]
            SEProcess3[SE Agent 3 Process]
            QAProcess[QA Agent Process]
            ReviewProcess[Review Agent Process]
            ArchProcess[Architect Agent Process]
        end
        
        subgraph "File System"
            SharedDir[/shared/]
            WorktreeDir[/worktrees/]
            ConfigDir[/config/]
            LogDir[/logs/]
        end
        
        subgraph "Git Repositories"
            MainRepo[Main Repository]
            Worktree1[Worktree 1]
            Worktree2[Worktree 2]
            Worktree3[Worktree 3]
            WorktreeArch[Worktree Arch]
        end
    end
    
    TmuxMain --> TmuxSession
    TmuxSession --> BossProcess
    TmuxSession --> PMProcess
    TmuxSession --> SEProcess1
    TmuxSession --> SEProcess2
    TmuxSession --> SEProcess3
    TmuxSession --> QAProcess
    TmuxSession --> ReviewProcess
    TmuxSession --> ArchProcess
    
    BossProcess --> SharedDir
    PMProcess --> SharedDir
    SEProcess1 --> SharedDir
    SEProcess2 --> SharedDir
    SEProcess3 --> SharedDir
    QAProcess --> SharedDir
    ReviewProcess --> SharedDir
    ArchProcess --> SharedDir
    
    SEProcess1 --> Worktree1
    SEProcess2 --> Worktree2
    SEProcess3 --> Worktree3
    QAProcess --> MainRepo
    ReviewProcess --> MainRepo
    ArchProcess --> WorktreeArch
    
    MainRepo --> Worktree1
    MainRepo --> Worktree2
    MainRepo --> Worktree3
    MainRepo --> WorktreeArch
```

---

**承認**  
本アーキテクチャ・データフロー図は、MACCDSの構造理解と実装ガイドとして使用される。

作成日: 2025-01-07  
バージョン: 1.0.0