# Ember & Code Ducking Adventures — Architecture Document

**Version:** 1.0.0
**Last Updated:** 2026-10-18
**Status:** Living Document

---

## Table of Contents

1. [Overview](#overview)
2. [Goals & Constraints](#goals--constraints)
3. [System Architecture](#system-architecture)
4. [Tech Stack](#tech-stack)
5. [Service Layer](#service-layer)
6. [Data Layer](#data-layer)
7. [Authentication & Security](#authentication--security)
8. [Caching Strategy](#caching-strategy)
9. [Media & Asset Delivery](#media--asset-delivery)
10. [Real-Time & Webhooks](#real-time--webhooks)
11. [Infrastructure & Deployment](#infrastructure--deployment)
12. [Observability](#observability)
13. [Scalability & Resilience](#scalability--resilience)
14. [CI/CD Pipeline](#cicd-pipeline)
15. [Architecture Decision Records](#architecture-decision-records)
16. [Glossary](#glossary)

---

## Overview

Ember & Code Ducking Adventures is a collectible-companion quest game whose backend exposes a REST API (see `api_design.md`). This document describes the complete system architecture: how services are structured, how data flows between them, which infrastructure components back them, and the reasoning behind key design choices.

The architecture is organized around four core domains that mirror the API surface:

| Domain          | Responsibility                                           |
|-----------------|----------------------------------------------------------|
| **Users**       | Identity, authentication, profiles, stats, currency     |
| **Ducks**       | Catalog, collection management, active-duck state        |
| **Journeys**    | Quest definition, player progress, reward orchestration  |
| **Achievements**| Milestone tracking, reward distribution, leaderboards   |

---

## Goals & Constraints

### Goals

- **Reliability** — 99.9% uptime SLA; zero data loss on player progress
- **Low Latency** — ≤ 100 ms p95 API response time for reads; ≤ 250 ms for writes
- **Horizontal Scalability** — Any service can scale independently in response to load spikes
- **Developer Experience** — Clear domain boundaries; services deployable and testable in isolation
- **Security by Default** — Auth enforced at the gateway; sensitive data encrypted at rest and in transit

### Constraints

- Team is small; operational complexity must remain manageable
- Initial launch targets a single region with multi-AZ failover
- All player-facing game state must be durable and recoverable
- CDN-served media must be immutable and cache-friendly

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                          Clients                                 │
│          (Mobile App · Web App · Third-party Integrations)       │
└─────────────────────────┬────────────────────────────────────────┘
                          │ HTTPS
┌─────────────────────────▼────────────────────────────────────────┐
│                      API Gateway / Edge                          │
│          Rate Limiting · TLS Termination · Auth Routing          │
└──┬──────────────┬────────────────┬──────────────┬───────────────┘
   │              │                │              │
┌──▼──┐      ┌───▼───┐      ┌─────▼────┐   ┌────▼──────┐
│User │      │ Duck  │      │ Journey  │   │Achievement│
│Svc  │      │  Svc  │      │   Svc    │   │   Svc     │
└──┬──┘      └───┬───┘      └─────┬────┘   └────┬──────┘
   │              │                │              │
   └──────────────┴────────────────┴──────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
     ┌────▼───┐    ┌──────▼────┐   ┌─────▼────┐
     │Primary │    │   Cache   │   │  Object  │
     │   DB   │    │  (Redis)  │   │  Store   │
     │(Postgres)   └───────────┘   │  (CDN)   │
     └────┬───┘                    └──────────┘
          │
    ┌─────▼──────┐
    │  Read      │
    │  Replica   │
    └────────────┘
```

### Request Flow (Happy Path)

1. Client sends HTTPS request to the edge.
2. **API Gateway** terminates TLS, enforces rate limits, validates the `Authorization` header, and routes to the appropriate service.
3. The **domain service** checks the **Redis cache** for the requested resource.
4. On a cache miss, the service reads from the **PostgreSQL primary** (writes) or **read replica** (reads).
5. Heavy-asset URLs (sprites, avatars, achievement icons) are pre-signed CDN links returned in the response body — never served through the application tier.
6. Asynchronous side effects (achievement checks, webhook delivery) are enqueued on the **message queue** and processed by background workers.

---

## Tech Stack

| Layer            | Technology                   | Rationale                                                     |
|------------------|------------------------------|---------------------------------------------------------------|
| API Gateway      | AWS API Gateway + CloudFront | Managed TLS, WAF, global edge PoPs                            |
| Application      | Node.js 22 (TypeScript)      | Strong ecosystem, async I/O, shared types with client SDKs    |
| API Framework    | Fastify                      | High throughput, JSON Schema validation, plugin ecosystem     |
| ORM              | Drizzle ORM                  | Type-safe SQL, lightweight, no runtime overhead               |
| Primary Database | PostgreSQL 16                | ACID compliance, JSONB for flexible fields, mature tooling    |
| Cache            | Redis 7 (ElastiCache)        | Sub-millisecond reads, Pub/Sub for real-time events           |
| Message Queue    | AWS SQS + SNS                | Durable async delivery, fan-out for webhook events            |
| Object Storage   | AWS S3 + CloudFront CDN      | Immutable media, global delivery, signed URL support          |
| Auth Tokens      | JWT (RS256)                  | Stateless, verifiable at the gateway without DB roundtrip     |
| Containerisation | Docker + AWS ECS Fargate     | Serverless containers, no cluster management overhead         |
| IaC              | Terraform                    | Reproducible, version-controlled infrastructure               |
| CI/CD            | GitHub Actions               | Tight SCM integration, reusable workflows                     |
| Observability    | OpenTelemetry → Grafana      | Vendor-neutral tracing, unified metrics + logs + traces       |

---

## Service Layer

The backend is organized as a **modular monorepo** using a service-per-domain pattern. Each domain is a standalone Fastify application that can be deployed and scaled independently, but shares infrastructure (database, cache, queue) in the initial phase. A full microservices split is deferred until traffic warrants it (see [ADR-001](#adr-001-modular-monorepo-over-full-microservices)).

### Monorepo Structure

```
ember-code-ducking/
├── apps/
│   ├── gateway/             # API Gateway config (OpenAPI spec, auth middleware)
│   ├── user-service/        # /users, /auth endpoints
│   ├── duck-service/        # /ducks endpoints
│   ├── journey-service/     # /journeys endpoints
│   └── achievement-service/ # /achievements endpoints
├── packages/
│   ├── db/                  # Drizzle schema, migrations, shared DB client
│   ├── cache/               # Redis client, cache helpers, TTL constants
│   ├── queue/               # SQS/SNS producer + consumer abstractions
│   ├── auth/                # JWT sign/verify, middleware factories
│   ├── types/               # Shared TypeScript types and Zod schemas
│   └── observability/       # OpenTelemetry setup, logger factory
├── infra/                   # Terraform modules
└── .github/workflows/       # CI/CD pipelines
```

### Service Responsibilities

#### User Service (`apps/user-service`)
- Handles registration, login, token refresh, and logout
- Manages profile CRUD and avatar uploads (returns S3 pre-signed PUT URLs)
- Owns the `quack_balance` ledger — all currency mutations go through this service
- Exposes internal endpoint `/internal/users/{id}/grant-currency` called by other services after reward events
- Emits `user.level_up` events to SNS on XP threshold crossings

#### Duck Service (`apps/duck-service`)
- Maintains the authoritative duck catalog (seeded via migration scripts)
- Manages player collection records — owns the `user_ducks` join table
- Validates duck eligibility before adding to a collection
- Exposes internal endpoint `/internal/ducks/grant` for reward orchestration from Journey Service
- Emits `duck.obtained` events to SNS

#### Journey Service (`apps/journey-service`)
- Stores journey definitions and player journey records
- Enforces prerequisite checks and active-journey constraints at write time
- On `POST .../complete`: orchestrates reward distribution by calling Duck Service and User Service internal endpoints synchronously, then publishes `journey.completed` to SNS for async downstream processing
- Manages per-player attempt counters with atomic Redis increments

#### Achievement Service (`apps/achievement-service`)
- Listens to all domain SNS events via SQS subscriptions
- Evaluates trigger conditions against player state for each incoming event
- Unlocks achievements and invokes User Service for XP/quack grants
- Serves leaderboard from a Redis sorted set (refreshed on each unlock)
- Emits `achievement.unlocked` to SNS for webhook fan-out

### Internal Communication

```
Journey Service     ──(HTTP/gRPC)──► Duck Service        (grant duck)
Journey Service     ──(HTTP/gRPC)──► User Service        (grant XP + quacks)
Achievement Service ◄──(SQS)──────── All Services        (domain events)
Achievement Service ──(HTTP/gRPC)──► User Service        (grant achievement rewards)
Webhook Worker      ◄──(SQS)──────── All SNS Topics
```

Internal calls use **service-to-service JWT tokens** signed by a shared internal secret, validated by a lightweight middleware in `packages/auth`. Internal endpoints are not exposed through the API Gateway.

---

## Data Layer

### Database: PostgreSQL 16

One logical database, one schema per domain service, deployed on **AWS RDS Multi-AZ**. Each service owns its schema exclusively — cross-domain data access goes through the service API, never direct SQL joins across schemas.

#### Schema Overview

```
Schema: users
─────────────────────────────────────────────────────────────────
users           (user_id PK, username, email_hash, password_hash,
                 quack_balance, xp, level, active_duck_id FK, ...)
quack_ledger    (entry_id PK, user_id FK, delta, reason, created_at)
refresh_tokens  (token_id PK, user_id FK, token_hash, expires_at, revoked)

Schema: ducks
─────────────────────────────────────────────────────────────────
ducks           (duck_id PK, name, slug, rarity, element,
                 stats JSONB, ability JSONB, sprite_key, lore, created_at)
user_ducks      (id PK, user_id, duck_id FK, obtained_at, source,
                 source_id, UNIQUE(user_id, duck_id))

Schema: journeys
─────────────────────────────────────────────────────────────────
journeys        (journey_id PK, name, slug, difficulty, stages JSONB,
                 prerequisites TEXT[], rewards JSONB, max_attempts, ...)
journey_records (record_id PK, journey_id FK, user_id, status,
                 current_stage, attempts, started_at, completed_at,
                 elapsed_seconds, rewards_claimed)

Schema: achievements
─────────────────────────────────────────────────────────────────
achievements      (achievement_id PK, name, trigger_type,
                   trigger_condition JSONB, rewards JSONB, is_secret, ...)
user_achievements (id PK, user_id, achievement_id FK, unlocked_at,
                   trigger_context JSONB, rewards_claimed,
                   UNIQUE(user_id, achievement_id))
```

#### Key Design Decisions

- **`email_hash`** — Email addresses are stored as SHA-256 hashes. Plaintext email is only held ephemerally at registration/login and never persisted.
- **JSONB for flexible structures** — `stages`, `rewards`, `trigger_condition`, `ability`, and `stats` are stored as JSONB, indexed with GIN indexes where query filtering is needed.
- **`quack_ledger`** — Currency mutations are append-only ledger entries. The `quack_balance` column is a denormalized sum maintained by triggers, providing fast reads without sacrificing auditability.
- **`prerequisites TEXT[]`** — Journey prerequisites are stored as a simple array of `journey_id` strings, evaluated in-application at start time.

#### Migrations

Managed with **Drizzle Kit**. Migration files live in `packages/db/migrations/` and are applied before service containers are updated. Breaking changes follow the **expand-contract pattern**.

### Read Replicas

All `GET` endpoints that don't require reading the caller's own latest write are routed to an **RDS read replica**. Services use a `readDb` / `writeDb` client pair from `packages/db`. Write-then-read flows use the primary.

---

## Authentication & Security

### Token Architecture

```
Client                 Gateway              User Service
  │                      │                       │
  │── POST /auth/login ──►│──────────────────────►│
  │                      │                  Validate credentials
  │                      │                  Issue RS256 JWT (15 min)
  │                      │                  Issue opaque refresh token
  │◄── { access_token,   │◄──────────────────────│
  │      refresh_token } │                       │
  │                      │                       │
  │── GET /ducks ────────►│                       │
  │   Authorization: Bearer <JWT>                 │
  │                      │ Verify RS256 sig        │
  │                      │ Check exp / iss / aud   │
  │                      │ Inject user_id header   │
  │                      │──► Duck Service         │
```

- **Access tokens** — RS256-signed JWTs; public key at gateway, private key in AWS Secrets Manager accessible only to User Service.
- **Refresh tokens** — Opaque 256-bit random strings, stored as SHA-256 hashes with a 30-day TTL. Rotated on each use; reuse detection invalidates the entire token family.
- **Token revocation** — On logout, JWT `jti` is inserted into a Redis blocklist with TTL equal to remaining token lifetime. Gateway checks blocklist on every request.

### Security Layers

| Layer           | Control                                                           |
|-----------------|-------------------------------------------------------------------|
| Transport       | TLS 1.3 at CloudFront; HSTS preloaded                            |
| Gateway         | WAF (OWASP Top 10), IP rate limiting, JWT validation             |
| Application     | Input validation via Zod schemas on every endpoint               |
| Database        | Per-service DB users with schema-scoped privileges only          |
| Secrets         | AWS Secrets Manager; injected as env vars at runtime             |
| Media           | S3 private; all access via short-lived pre-signed URLs           |
| Data at Rest    | RDS AES-256, S3 SSE-S3                                           |
| Internal Traffic| Service-to-service JWT; VPC private subnets; no public IPs       |
| Audit           | All auth events logged to CloudWatch with `user_id` and source IP|

---

## Caching Strategy

Redis 7 via AWS ElastiCache (cluster mode enabled if memory exceeds 80%).

### Cache Topology

| Cache Key Pattern                      | TTL     | Invalidation Strategy          | Notes                                     |
|----------------------------------------|---------|--------------------------------|-------------------------------------------|
| `duck:catalog:{duck_id}`               | 24 h    | On admin catalog update        | Duck catalog is nearly static             |
| `duck:catalog:list:{filter_hash}`      | 10 min  | TTL only                       | List + filter params hashed into key      |
| `user:profile:{user_id}`               | 5 min   | On PATCH /users/me             | Public fields only; no email or balance   |
| `user:stats:{user_id}`                 | 2 min   | TTL only                       | Slightly stale stats acceptable           |
| `journey:definition:{journey_id}`      | 1 h     | On admin update                | Journey defs rarely change                |
| `achievement:catalog:{achievement_id}` | 1 h     | On admin update                | Achievement defs rarely change            |
| `achievement:leaderboard`              | 1 min   | On new unlock                  | Redis sorted set; rebuilt on each unlock  |
| `ratelimit:{user_id}:{window}`         | 60 s    | Sliding window counter         | Enforced at gateway                       |
| `jwt:blocklist:{jti}`                  | JWT TTL | N/A — self-expiring            | Logout revocation                         |
| `journey:active:{user_id}`             | 30 min  | On journey start / complete    | Single-active-journey guard               |

### Cache-Aside Pattern

```
1. Check Redis for key
2a. HIT  → Return cached value
2b. MISS → Query DB → Store in Redis with TTL → Return value
3. On mutation → DELETE affected keys (write-around, not write-through)
```

---

## Media & Asset Delivery

All binary media (duck sprites, achievement icons, user avatars) is stored in **Amazon S3** and served exclusively through **CloudFront**.

### Upload Flow (User Avatars)

```
Client ──► POST /users/me/avatar/upload-url ──► User Service
                                                    │
                                            Generate S3 pre-signed PUT URL
                                            (1-hour TTL, avatars/{user_id}/)
                                                    │
Client ◄── { upload_url, public_cdn_url } ──────────┘
   │
   │ PUT <upload_url>  ← Direct to S3; app tier not involved
   │
Client ──► PATCH /users/me { avatar_url: public_cdn_url }
```

### Asset Versioning

Sprites and icons are **immutable** — keys include a content hash:
```
ducks/ember-a3f9c2b1.png
achievements/volcanic_conqueror-b7d1e4a0.png
```
CloudFront caches these with `Cache-Control: public, max-age=31536000, immutable`.

### S3 Bucket Structure

```
ember-code-ducking-assets/
├── avatars/       ← Private; pre-signed GET URLs (15 min TTL)
├── ducks/         ← Public read via CloudFront OAC only
└── achievements/  ← Public read via CloudFront OAC only
```

---

## Real-Time & Webhooks

### Domain Event Bus (SNS → SQS)

```
User Service        ──► SNS: user-events
Duck Service        ──► SNS: duck-events
Journey Service     ──► SNS: journey-events
Achievement Service ──► SNS: achievement-events

SNS Topics ──► SQS Queues:
  achievement-processor-queue   (Achievement Service consumer)
  webhook-delivery-queue        (Webhook Worker consumer)
  analytics-queue               (Analytics pipeline — future)
```

All SNS messages use a standard envelope:

```json
{
  "event": "journey.completed",
  "version": "1",
  "timestamp": "2026-10-18T14:45:00Z",
  "source_service": "journey-service",
  "data": { ... }
}
```

### Webhook Delivery Worker

1. Fan-out: look up all registered subscriptions matching the event type
2. Sign payload with HMAC-SHA256 using the subscriber's secret
3. HTTP POST to subscriber URL (10-second timeout)
4. On failure: exponential backoff — 5 attempts (10 s → 30 s → 2 min → 10 min → 1 h)
5. After 5 failures: mark subscription `degraded`, notify subscriber
6. Permanently failed deliveries go to an **SQS DLQ** for manual review

### Webhook Security Headers

```http
X-Duck-Signature: sha256=<hmac_hex>
X-Duck-Timestamp: 1760888460
X-Duck-Event: achievement.unlocked
```

Subscribers must validate the HMAC and reject requests where `X-Duck-Timestamp` is more than 5 minutes old (replay protection).

---

## Infrastructure & Deployment

### AWS Region: `us-east-1` (Primary)

```
VPC: 10.0.0.0/16
├── Public Subnets  (AZ-a, AZ-b)
│   └── CloudFront → API Gateway → ALB
├── Private Subnets (AZ-a, AZ-b)
│   ├── ECS Fargate Tasks (all services)
│   ├── ElastiCache Redis
│   └── RDS PostgreSQL (primary + standby)
└── Database Subnets (AZ-a, AZ-b)
    └── RDS (isolated; no NAT gateway access)
```

### ECS Fargate Configuration

- **Task Definition** — Single container; env vars from Secrets Manager + SSM Parameter Store
- **Auto Scaling** — CPU target 60% + ALB RequestCountPerTarget; min 1 / max 10 tasks
- **Health Checks** — ALB checks `GET /healthz`; replacement within 60 s on failure
- **Networking** — awsvpc mode; private subnets; outbound via NAT Gateway

### Container Resource Allocation (Baseline)

| Service             | CPU | Memory  | Min Tasks | Max Tasks |
|---------------------|-----|---------|-----------|-----------|
| User Service        | 512 | 1024 MB | 2         | 10        |
| Duck Service        | 256 | 512 MB  | 1         | 6         |
| Journey Service     | 512 | 1024 MB | 2         | 10        |
| Achievement Service | 256 | 512 MB  | 1         | 6         |
| Webhook Worker      | 256 | 512 MB  | 1         | 4         |

---

## Observability

### Three Pillars

**1. Structured Logging** — All services use **Pino** (via `packages/observability`), outputting JSON to stdout → CloudWatch Logs. Every line includes `request_id`, `user_id`, `service`, `level`, `message`, `timestamp`.

**2. Metrics** — OpenTelemetry SDK → Prometheus → Grafana Cloud.

| Metric                          | Type      | Labels                      |
|---------------------------------|-----------|-----------------------------|
| `http_request_duration_ms`      | Histogram | `method`, `route`, `status` |
| `http_requests_total`           | Counter   | `method`, `route`, `status` |
| `cache_hit_total`               | Counter   | `key_pattern`, `result`     |
| `db_query_duration_ms`          | Histogram | `operation`, `schema`       |
| `queue_message_processed_total` | Counter   | `queue`, `status`           |
| `webhook_delivery_total`        | Counter   | `event`, `status`           |

**3. Distributed Tracing** — OpenTelemetry traces via `traceparent` headers → Grafana Tempo. Sampled at 5% in production; 100% for error spans.

### Alerting

| Alert                              | Threshold             | Channel      |
|------------------------------------|-----------------------|--------------|
| p95 API latency                    | > 500 ms for 5 min    | PagerDuty    |
| Error rate (5xx)                   | > 1% of requests      | PagerDuty    |
| RDS CPU                            | > 80% for 10 min      | Slack #infra |
| Redis memory                       | > 75%                 | Slack #infra |
| Webhook DLQ depth                  | > 50 messages         | Slack #ops   |
| Failed DB connections              | Any                   | PagerDuty    |
| ECS task crash loop (> 3 in 5 min) | Count threshold       | PagerDuty    |

### Grafana Dashboards

- **Service Overview** — Request rate, error rate, p50/p95/p99 latency per service
- **Database** — Query latency, connection pool utilization, replica lag
- **Cache** — Hit/miss ratio, eviction rate, memory usage
- **Journey Funnel** — Starts → Completions → Abandonments → Failures
- **Duck Economy** — Ducks granted per day by source and rarity
- **Achievement Velocity** — Unlocks per hour, leaderboard movement

---

## Scalability & Resilience

### Idempotency

`POST /users/me/journeys/{id}/complete` is the most consequential write:

1. Client sends `X-Request-ID: <uuid>`
2. Service checks Redis for `idempotency:{request_id}` (TTL 24 h)
3. **HIT** → Return cached response immediately
4. **MISS** → Process rewards inside a PostgreSQL transaction; call downstream services as a saga with compensating rollbacks; cache the response; return

### Circuit Breakers

Inter-service HTTP calls use **Opossum**:
- Opens after 5 consecutive failures
- Half-open probe after 30 s
- On open: return cached last-known-good or graceful degradation response

### Database Resilience

- **RDS Multi-AZ** — Automatic failover to standby (< 60 s)
- **PgBouncer** sidecar per service (transaction mode); max 20 connections per instance
- **Slow Query Monitoring** — `log_min_duration_statement = 200ms`; reviewed weekly

### Graceful Degradation

| Failure Scenario              | Degraded Behavior                                          |
|-------------------------------|------------------------------------------------------------|
| Redis unavailable             | Fall through to DB; cache writes skipped                   |
| Read replica lag > 5 s        | Reads routed to primary automatically                      |
| Achievement Service down      | Journey completion succeeds; achievements queued in SQS    |
| Webhook Worker down           | Events accumulate in SQS; delivered on worker recovery     |
| Duck catalog cache miss       | Direct DB read; no user-visible impact                     |

---

## CI/CD Pipeline

```
Push to feature branch
    │
    ▼
[Lint + Type Check]        ← tsc --noEmit, ESLint, Prettier
    │
    ▼
[Unit Tests]               ← Vitest, per-package
    │
    ▼
[Integration Tests]        ← Docker Compose (Postgres + Redis), per-service
    │
    ▼
PR opened / updated
    │
    ▼
[Security Scan]            ← Trivy (container), npm audit
    │
    ▼
Merge to main
    │
    ▼
[Build Docker Images]      ← Multi-stage Dockerfile; tagged with git SHA
    │
    ▼
[Push to ECR]
    │
    ▼
[Deploy to Staging]        ← Terraform apply (staging workspace)
    │                         ECS rolling update; smoke tests
    ▼
[Manual Approval Gate]     ← Required for production
    │
    ▼
[Deploy to Production]     ← Terraform apply (prod workspace)
                              ECS rolling update (25% at a time)
                              DB migrations run pre-deploy
```

### Branch Strategy

| Branch      | Environment    | Auto-Deploy     |
|-------------|----------------|-----------------|
| `feature/*` | None (CI only) | No              |
| `main`      | Staging        | Yes             |
| `release/*` | Production     | After approval  |

### Rollback

```bash
aws ecs update-service --cluster prod --service user-service \
  --task-definition user-service:<prev_revision>
```

Database rollbacks follow the **expand-contract pattern** — destructive column drops are never co-deployed with the application code that stops referencing them.

---

## Architecture Decision Records

### ADR-001: Modular Monorepo Over Full Microservices

**Date:** 2026-06-01 | **Status:** Accepted

**Context:** Domain isolation and independent scalability are needed, but full microservices adds significant operational overhead for a small team.

**Decision:** Monorepo of domain-scoped services sharing one DB cluster and message bus. Each service is independently deployable today and can be extracted to its own cluster later.

**Consequences:**
- ✅ Single `docker-compose up` for local dev
- ✅ Shared packages eliminate duplication
- ✅ ECS service-level autoscaling still allows independent scaling
- ⚠️ Shared DB cluster requires strict no-cross-schema-SQL discipline
- ⚠️ Refactoring required if services need independent DB scaling

---

### ADR-002: PostgreSQL + JSONB for Flexible Fields

**Date:** 2026-06-10 | **Status:** Accepted

**Context:** Journey stages, achievement trigger conditions, duck abilities, and rewards have variable shapes that don't map cleanly to normalized columns.

**Decision:** Store structured-but-variable fields as JSONB. Stable, frequently filtered fields remain as typed columns with B-tree indexes. JSONB fields get GIN indexes where needed.

**Consequences:**
- ✅ Schema flexibility without migrations for internal field changes
- ✅ GIN indexes support efficient JSONB containment queries
- ⚠️ JSONB fields are opaque to the ORM — Zod validation is mandatory at the application layer
- ⚠️ Cross-field JSONB queries are slower than normalized column queries

---

### ADR-003: Append-Only Quack Ledger

**Date:** 2026-06-15 | **Status:** Accepted

**Context:** In-game currency is a sensitive resource. Direct balance mutations are hard to audit and vulnerable to race conditions.

**Decision:** All currency mutations append to `quack_ledger`. The `quack_balance` column is a denormalized sum maintained by a PostgreSQL trigger that also enforces a non-negative balance constraint atomically.

**Consequences:**
- ✅ Complete audit trail of every currency movement
- ✅ Atomic overdraft prevention
- ✅ Balance is always recomputable from ledger
- ⚠️ Ledger grows unbounded; archive records older than 1 year

---

### ADR-004: JWT + Redis Blocklist for Revocation

**Date:** 2026-06-20 | **Status:** Accepted

**Context:** Stateless JWTs cannot be revoked before expiry. Per-request DB lookups negate the scalability benefits of JWTs.

**Decision:** Short-lived JWTs (15 min) with a Redis blocklist. On logout, `jti` is inserted with TTL = remaining token lifetime. Gateway checks blocklist on every request.

**Consequences:**
- ✅ Near-instant revocation (~1 ms Redis latency)
- ✅ Blocklist is self-cleaning via TTL
- ✅ No per-request DB roundtrip
- ⚠️ Redis is now in the auth critical path; mitigated by ElastiCache Multi-AZ

---

## Glossary

| Term            | Definition                                                                  |
|-----------------|-----------------------------------------------------------------------------|
| AZ              | Availability Zone — isolated data center within an AWS region               |
| CDN             | Content Delivery Network — geographically distributed cache for static assets|
| Circuit Breaker | Pattern that halts calls to a failing service to allow it to recover        |
| DLQ             | Dead Letter Queue — holds messages that failed all retry attempts           |
| ECS             | Elastic Container Service — AWS managed container orchestration             |
| Expand-Contract | DB migration pattern: add new before removing old columns                   |
| Fargate         | AWS serverless compute engine for containers                                |
| GIN Index       | Generalized Inverted Index — PostgreSQL index type for JSONB and arrays     |
| HMAC            | Hash-based Message Authentication Code — used for webhook payload signing   |
| Idempotency     | Property where repeating an operation produces the same result              |
| JSONB           | PostgreSQL binary JSON column type with indexing support                    |
| JWT             | JSON Web Token — signed token for stateless authentication                  |
| OAC             | Origin Access Control — CloudFront policy restricting S3 to CDN-only access |
| PgBouncer       | PostgreSQL connection pooler                                                |
| RDS             | Relational Database Service — AWS managed PostgreSQL                        |
| RS256           | RSA Signature with SHA-256 — asymmetric JWT signing algorithm               |
| Saga            | Pattern for distributed transactions with compensating rollbacks            |
| SNS             | Simple Notification Service — AWS pub/sub messaging                        |
| SQS             | Simple Queue Service — AWS managed message queue                           |
| TLS             | Transport Layer Security — encryption protocol for network traffic          |
| WAF             | Web Application Firewall — filters malicious HTTP traffic                  |
| VPC             | Virtual Private Cloud — isolated AWS network environment                    |

/*
| Section | Highlights |
| --- | --- |
| **System Architecture** | ASCII topology diagram + end-to-end request flow |
| **Tech Stack** | Node.js 22/Fastify/Drizzle/Postgres/Redis/SQS — each with rationale |
| **Service Layer** | Modular monorepo, 4 domain services + Webhook Worker, internal comms pattern |
| **Data Layer** | Per-domain schemas, JSONB strategy, append-only quack ledger, read replica routing |
| **Auth & Security** | RS256 JWT flow, Redis blocklist revocation, 9-layer security table |
| **Caching** | 10 cache key patterns with TTLs, invalidation strategy, cache-aside pattern |
| **Media** | S3 + CloudFront, direct upload via pre-signed URLs, immutable asset versioning |
| **Webhooks** | SNS→SQS event bus, retry/backoff/DLQ, replay-protection headers |
| **Infrastructure** | Multi-AZ VPC layout, ECS Fargate sizing, autoscaling config |
| **Observability** | Structured logging, 6 metrics, distributed tracing, 7 alerts, 6 dashboards |
| **Resilience** | Idempotency, circuit breakers, graceful degradation table |
| **CI/CD** | Full pipeline from ``feature/*`` to production with approval gate |
| **ADRs** | 4 decision records covering the most consequential design choices |
*/