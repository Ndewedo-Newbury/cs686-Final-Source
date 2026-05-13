# CI/CD Pipeline

Rendered with [Mermaid](https://mermaid.js.org/) — visible natively on GitHub and in VS Code with the Mermaid Preview extension.

```mermaid
flowchart TD

    %% ── Triggers ─────────────────────────────────────────────────────────────
    T1(["Push to main or develop"])
    T2(["2 AM UTC Cron - nightly.yml"])
    T3(["Push to release branch - promote.yml"])
    T4(["Push semver tag v*.*.* - promote.yml"])

    %% ── ci.yml ───────────────────────────────────────────────────────────────
    subgraph CI ["ci.yml — Every Push to main / develop"]
        direction TB
        UT["Unit Tests - matrix: auth, workouts, analytics"]
        MT["Migration Tests - spin up Postgres, run Alembic"]
        BP["Build and Push to ECR - tagged sha-commit"]
        MIG["Run DB Migrations - dev Lambda"]
        IT["Integration Tests - dev Lambda per service"]
        DD["Deploy to Dev - bump Helm values, git push"]
        WR["Wait for Rollout - kubectl rollout status 600s"]

        UT --> BP
        MT --> BP
        BP --> MIG --> IT --> DD --> WR
    end

    %% ── nightly.yml ──────────────────────────────────────────────────────────
    subgraph NIGHTLY ["nightly.yml — 2 AM UTC Daily"]
        direction TB
        PQA["Promote dev to QA - retag dev-latest as qa-latest, update qa Helm values"]
        E2E["E2E Tests - QA Lambda per service - full user journey"]

        PQA --> E2E
    end

    %% ── promote.yml QA to UAT ────────────────────────────────────────────────
    subgraph PUAT_WF ["promote.yml — release/* branch push"]
        direction TB
        PUAT["Promote QA to UAT - retag qa-latest as uat-latest, update uat Helm values"]
        SMOKE["Smoke Tests - UAT Lambda per service - happy path only"]

        PUAT --> SMOKE
    end

    %% ── promote.yml UAT to Prod ──────────────────────────────────────────────
    subgraph PPROD_WF ["promote.yml — v*.*.* tag or workflow_dispatch"]
        direction TB
        PPROD["Promote UAT to Prod - retag uat-latest as version tag"]
        PMIG["Prod Migrations - fitness-tracker-prod-migrate Lambda"]
        PHELM["Update Prod Helm Values - git push version tag"]
        GHR["Create GitHub Release - auto-generated notes"]

        PPROD --> PMIG --> PHELM --> GHR
    end

    %% ── Environments ─────────────────────────────────────────────────────────
    DEV[("Dev - EKS dev namespace - ArgoCD selfHeal + prune")]
    QA[("QA - EKS qa namespace")]
    UAT[("UAT - EKS uat namespace")]
    PROD[("Prod - EKS prod namespace - Blue/Green via ArgoCD Rollouts")]

    %% ── Flow ─────────────────────────────────────────────────────────────────
    T1 --> CI
    WR --> DEV

    T2 --> NIGHTLY
    DEV -.->|"image built by last CI run"| PQA
    PQA --> QA
    E2E -.->|"tests run against live QA"| QA

    T3 --> PUAT_WF
    QA -.->|"image promoted by last nightly"| PUAT
    PUAT --> UAT
    SMOKE -.->|"tests run against live UAT"| UAT

    T4 --> PPROD_WF
    UAT -.->|"image promoted from release branch"| PPROD
    PPROD --> PROD

    %% ── Style ────────────────────────────────────────────────────────────────
    classDef trigger fill:#1f2937,color:#f9fafb,stroke:#4b5563
    classDef env    fill:#065f46,color:#f0fdf4,stroke:#047857

    class T1,T2,T3,T4 trigger
    class DEV,QA,UAT,PROD env
```

## How to promote between environments

| From → To | Trigger |
|---|---|
| Dev (every push) | Automatic — any push to `main` or `develop` |
| Dev → QA (nightly) | Automatic — cron at 2 AM UTC; or run `nightly.yml` manually via `workflow_dispatch` |
| QA → UAT | Push or merge to a `release/*` branch: `git checkout -b release/v1.1.0 && git push origin release/v1.1.0` |
| UAT → Prod | Push a semver tag: `git tag v1.1.0 && git push origin v1.1.0` — or trigger `promote.yml` manually with a version input |

## Test tier responsibilities

| Tier | Workflow | Runs on | What it checks |
|---|---|---|---|
| Unit | `ci.yml` | GitHub Actions runner | Pure logic, no I/O |
| Migration | `ci.yml` | GitHub Actions runner + Postgres container | Alembic up/down against a real schema |
| Integration | `ci.yml` | Dev Lambda + Dev RDS/SQS | Each service against its own infrastructure |
| E2E | `nightly.yml` | QA Lambda | Full user journey across all services |
| Smoke | `promote.yml` | UAT Lambda | Happy path only — confirm deploy succeeded |
