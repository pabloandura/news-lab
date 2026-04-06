# news-lab: Microservices Expansion
**Document type:** Architecture Design Record  
**Status:** Approved for implementation  
**Audience:** Senior Tech Lead / Implementing Developer  
**Date:** 2026-04-05

---

## 1. Context and Motivation

news-lab is a Flutter cross-platform news application backed entirely by Firebase. Users can read curated headlines from NewsAPI, publish their own articles, and vote on fact-check accuracy via a community system already live in Firestore.

The current architecture handles everything through direct Firestore reads/writes from the Flutter client. This works well for what exists today, but it cannot support the next layer of product capabilities:

- **Automated fact-checking** — running NLP analysis against a published article
- **Bias detection** — scoring an article for political framing and emotional language
- **Semantic news clustering** — finding related coverage of the same event across sources

These are compute-heavy, AI-driven operations that do not belong in the client and cannot be expressed as Firestore rules. They require server-side processing. This document defines the three microservices that deliver those capabilities and how they integrate with the existing app.

---

## 2. Design Principles

These principles govern every decision in this document. When you encounter a trade-off during implementation, resolve it by returning here.

**Write to Firestore, not to the client.**  
Microservices never respond directly with processed results. They write to Firestore, and the Flutter app's existing real-time listeners pick up the update. This decouples processing time from UX and requires no polling logic on the client.

**On-demand over scheduled for user-facing features.**  
The user triggers analysis explicitly ("Check this article"). Do not run analysis on every article automatically — that burns budget and creates noise. Background ingestion (sensemaker) is the only scheduled job.

**Clean Architecture parity.**  
Every new service integration in Flutter follows the same `domain → data → presentation` pattern already established in `features/fact_check/`. No shortcuts. New developers should not be able to tell which features came first.

**Scale to zero.**  
All three services run on Cloud Run with minimum instances set to 0 unless load testing proves otherwise. These are not latency-critical enough to justify warm instances at this stage.

**One auth system.**  
Firebase Authentication tokens are the only credential. API Gateway validates Firebase JWTs before any request reaches a Cloud Run service. No separate service accounts exposed to the client.

---

## 3. System Overview

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                         │
│                                                         │
│  reads (real-time) ◄──────────────── Firestore         │
│                                           ▲             │
│  on-demand calls ──► API Gateway          │ writes      │
│                           │               │             │
│               ┌───────────┼───────────┐   │             │
│               │           │           │   │             │
│         fact-checker  polarizer  sensemaker             │
│               │           │           │                 │
│           Vertex AI   Vertex AI   Vertex AI             │
│           (Gemini)    (Gemini)   (Embeddings)           │
│                                       │                 │
│                               Cloud Scheduler           │
│                           (daily ingestion job)         │
└─────────────────────────────────────────────────────────┘

Supporting infrastructure (all GCP):
  API Gateway · Cloud Run · Cloud Pub/Sub
  Secret Manager · Artifact Registry · Cloud Build
```

The Flutter app has two integration modes with the microservices layer:

| Mode | Trigger | Pattern |
|---|---|---|
| On-demand | User action in app | HTTP POST to API Gateway → Cloud Run → write to Firestore → real-time listener fires |
| Background | Cloud Scheduler (sensemaker only) | Scheduler → Cloud Run → write to Firestore |

---

## 4. The Three Services

### 4.1 `fact-checker`

**Purpose:** Accepts article text, extracts factual claims, evaluates them against a reference corpus, and writes a structured bot-check result to Firestore.

**Why this scope:** The Flutter app already contains `BotCheckEntity` with `flaggedSentencesPercent` and `confidenceScore` fields. The `dev/fact_check_seeder.dart` generates fake data for these fields. This service replaces the seeder with real analysis — the UI requires zero changes.

#### API contract

```
POST /fact-check
Authorization: Bearer <firebase-jwt>

{
  "articleId": "string",
  "text": "string"
}

→ 202 Accepted
{ "status": "processing", "articleId": "string" }
```

The service returns `202` immediately. The result is written asynchronously to Firestore. The client does not wait.

#### Firestore write (existing schema, no migration needed)

```
fact_checks/{articleId}
  botCheck:
    flaggedSentencesPercent: float   // 0.0–1.0
    confidenceScore: float           // 0.0–1.0
    checkedAt: timestamp
```

#### Processing pipeline

```
1. Receive article text
2. Call Vertex AI (Gemini): extract discrete factual claims as structured list
3. For each claim: evaluate plausibility, flag if contested
4. Compute flaggedSentencesPercent and confidenceScore
5. Write to Firestore fact_checks/{articleId}.botCheck
```

#### Technology

- **Runtime:** Node.js 20 + NestJS
- **AI:** Vertex AI Gemini 1.5 Flash (cost-efficient for structured extraction)
- **Firestore SDK:** `firebase-admin` (server-side, uses Application Default Credentials)
- **Container:** Cloud Run, region `us-central1`, min instances 0, max 5

---

### 4.2 `polarizer`

**Purpose:** Accepts article text, scores it across a bias taxonomy (political lean, emotional language, framing), and writes a `BiasReport` to Firestore.

**Why this scope:** Ground News' core differentiator is showing the same story from left/center/right outlets. Polarizer is the engine that produces that signal for user-generated articles in news-lab.

#### API contract

```
POST /polarize
Authorization: Bearer <firebase-jwt>

{
  "articleId": "string",
  "text": "string"
}

→ 202 Accepted
{ "status": "processing", "articleId": "string" }
```

#### Firestore write (new schema)

```
articles/{articleId}
  biasReport:
    politicalLean: float          // -1.0 (left) to +1.0 (right)
    emotionalLanguageScore: float // 0.0 (neutral) to 1.0 (highly charged)
    framingNotes: string[]        // short labels, e.g. ["passive voice", "loaded adjectives"]
    analyzedAt: timestamp
```

> **Implementation note:** Write to the `articles` document directly rather than a separate collection. Bias is a property of the article, not a separate entity. This avoids an extra Firestore read when displaying an article.

#### Processing pipeline

```
1. Receive article text
2. Call Vertex AI (Gemini) with a structured bias taxonomy prompt
3. Parse structured JSON response into BiasReport fields
4. Write to Firestore articles/{articleId}.biasReport
```

#### Flutter integration

New feature folder: `features/bias_report/`  
Follow the `features/fact_check/` structure exactly:
- `domain/entities/bias_report_entity.dart`
- `domain/usecases/run_bias_check_use_case.dart`
- `data/data_sources/bias_report_remote_data_source.dart` (calls Cloud Run)
- `presentation/bloc/bias_report_bloc.dart`
- `presentation/widgets/bias_badge.dart` (mirrors `bot_check_badge.dart`)

#### Technology

- **Runtime:** Node.js 20 + NestJS (shares base image with `fact-checker`)
- **AI:** Vertex AI Gemini 1.5 Pro (more nuanced reasoning needed for bias)
- **Container:** Cloud Run, region `us-central1`, min instances 0, max 5

---

### 4.3 `sensemaker`

**Purpose:** Ingests multiple news sources daily, generates semantic embeddings for each article, and exposes a query endpoint that returns ranked similar articles for a given input. This is the "related perspectives" feature.

**Why this scope:** news-lab currently has one source: NewsAPI. Sensemaker is what turns news-lab into a multi-perspective platform — it is the core Ground News analogue. It is also the most complex service and should be built last.

#### Two modes of operation

**Mode 1: Ingestion (background, scheduled)**  
Cloud Scheduler triggers sensemaker daily. The service fetches from all configured sources, deduplicates by URL, generates embeddings, and stores articles with their vector representations.

**Mode 2: Query (on-demand, user-triggered)**  
Flutter app sends an article's text or ID. Sensemaker returns the top N semantically similar articles from its index with source attribution.

#### API contracts

```
// Triggered by Cloud Scheduler, not the client
POST /ingest
Authorization: Bearer <gcp-service-account>

→ 200 OK
{ "ingested": 847, "deduplicated": 23, "timestamp": "..." }
```

```
// Triggered by user action in Flutter
POST /similar
Authorization: Bearer <firebase-jwt>

{
  "articleId": "string",   // if article is already indexed
  "text": "string"         // OR raw text for user-authored articles
}

→ 200 OK
{
  "results": [
    {
      "title": "string",
      "source": "string",
      "url": "string",
      "publishedAt": "string",
      "similarityScore": float,
      "snippet": "string"
    }
  ]
}
```

> **Note:** Sensemaker is the only service that responds synchronously with data. The result set is small (top 10–20 articles), latency is acceptable (~2–4s), and there is no Firestore collection to write a "similar articles" result to. Optionally cache results in `articles/{articleId}/similarArticles` if you find users repeatedly querying the same article.

#### Data sources (start with these, add more incrementally)

| Source | Method | Notes |
|---|---|---|
| NewsAPI.org | REST API (existing key) | Same key already in the app |
| GDELT Project | Public BigQuery dataset | Free, massive coverage |
| RSS feeds | HTTP fetch + XML parse | BBC, Reuters, AP, Al Jazeera |
| Hacker News | Algolia API | Tech/startup lens |

#### Storage architecture

Firestore alone is not appropriate for vector similarity search. Use one of:

| Option | Recommended if |
|---|---|
| **Firestore Vector Search** (native, preview) | You want to stay 100% in Firebase ecosystem, lower operational overhead |
| **Vertex AI Matching Engine** | You need sub-100ms query latency at scale (>1M vectors) |

**Start with Firestore Vector Search.** Migrate to Matching Engine only if you outgrow it.

```
Firestore collection: sensemaker_articles
  {docId}:
    title: string
    source: string
    url: string
    publishedAt: timestamp
    snippet: string
    embedding: vector<768>   // Firestore native vector field
```

#### Technology

- **Runtime:** Node.js 20 + NestJS
- **Embeddings:** Vertex AI `text-embedding-004` model (768 dimensions)
- **Scheduler:** Cloud Scheduler → HTTP POST to sensemaker `/ingest`
- **Container:** Cloud Run, min instances 0, max 10 (ingestion can spike)

---

## 5. Infrastructure

### 5.1 API Gateway

A single API Gateway sits in front of all three Cloud Run services. This is where Firebase JWT validation happens — once, for all services.

```
api.news-lab.com
  /fact-check  → fact-checker Cloud Run service
  /polarize    → polarizer Cloud Run service
  /similar     → sensemaker Cloud Run service
  /ingest      → sensemaker Cloud Run service (internal only, Scheduler SA)
```

**Why API Gateway instead of calling Cloud Run directly:**
- JWT validation in one place — services receive pre-validated requests
- Single URL for the Flutter client — no per-service URL management
- Rate limiting and quota enforcement without code changes
- Dead simple to add a new route when a fourth service appears

### 5.2 Cloud Pub/Sub (optional trigger path)

For the on-demand services, a direct HTTP call from Flutter → API Gateway → Cloud Run is sufficient. Pub/Sub becomes useful only if you want to fan-out a single event to multiple services simultaneously.

Example: user publishes an article → single Pub/Sub message → fact-checker and polarizer both process it in parallel, without Flutter needing to fire two separate API calls.

Implement this only when you find yourself writing sequential API calls in the Flutter BLoC. Until then, direct HTTP is simpler.

### 5.3 Secret Manager

All credentials go here. No environment variables with secrets in Cloud Run config.

| Secret | Consumers |
|---|---|
| `newsapi-key` | sensemaker |
| `vertex-ai-project` | all three services |
| `firebase-service-account` | all three services (Firestore writes) |

Cloud Run services access secrets via the `@google-cloud/secret-manager` SDK with the Cloud Run service account granted `Secret Manager Secret Accessor` role.

### 5.4 Monorepo Structure

All services live in a single git repository alongside the Flutter app. No submodules. No external tooling required — Cloud Build path filters handle affected-only builds in CI.

```
news-lab/
├── frontend/                   ← Flutter application
├── backend/                    ← Firebase CLI config (intentionally kept — matches assignment spec)
│   └── docs/
│       └── DB_SCHEMA.md
├── services/                   ← NestJS microservices
│   ├── fact-checker/           ← NestJS · Cloud Run
│   ├── polarizer/              ← NestJS · Cloud Run
│   └── sensemaker/             ← NestJS · Cloud Run
├── types/                      ← shared TypeScript API contracts
│   ├── fact-checker.types.ts
│   ├── polarizer.types.ts
│   ├── sensemaker.types.ts
│   ├── tsconfig.json
│   └── package.json            ← name: "@news-lab/types"
├── infra/
│   ├── firebase/               ← Firebase rules, indexes, firebase.json
│   └── cloudbuild/
│       ├── fact-checker.yaml
│       ├── polarizer.yaml
│       └── sensemaker.yaml
├── justfile                    ← unified task runner
└── news-lab.code-workspace     ← VS Code multi-root workspace
```

**Why `just` over a plain Makefile:** cleaner syntax, no tab-indentation pitfalls, cross-platform (macOS and Cloud Build Linux run identically). Install with `brew install just`.

#### Shared TypeScript types (`types/`)

NestJS services are TypeScript — which means request/response shapes can be defined once and imported by every service. This is the primary structural advantage of NestJS over Python for this monorepo: a single source of truth for the API contract enforced at compile time, not at runtime.

```typescript
// types/fact-checker.types.ts
export interface FactCheckRequest {
  articleId: string;
  text: string;
}

export interface FactCheckResponse {
  status: 'processing';
  articleId: string;
}

export interface BotCheckResult {
  flaggedSentencesPercent: number; // 0.0–1.0
  confidenceScore: number;         // 0.0–1.0
  checkedAt: FirebaseFirestore.Timestamp;
}
```

Each NestJS service installs `@news-lab/types` as a local workspace dependency:

```json
// services/fact-checker/package.json
{
  "dependencies": {
    "@news-lab/types": "file:../../types"
  }
}
```

**What this buys you:** if you rename a field (e.g. `flaggedSentencesPercent` → `flaggedPercent`), TypeScript will fail to compile in every service that uses it — catching the drift before it reaches Cloud Run. No integration tests required to catch contract mismatches between services.

#### justfile

```just
# ── Dev ────────────────────────────────────────────────────────────────────
dev-fact-checker:
    cd services/fact-checker && npm run start:dev

dev-polarizer:
    cd services/polarizer && npm run start:dev

dev-sensemaker:
    cd services/sensemaker && npm run start:dev

dev-app:
    cd app && flutter run

# ── Test ───────────────────────────────────────────────────────────────────
test-all:
    cd app && flutter test
    cd services/fact-checker && npm test
    cd services/polarizer && npm test
    cd services/sensemaker && npm test

test service:
    cd services/{{service}} && npm test

# ── Types (shared contract validation) ────────────────────────────────────
check-types:
    cd types && npx tsc --noEmit
    cd services/fact-checker && npx tsc --noEmit
    cd services/polarizer && npx tsc --noEmit
    cd services/sensemaker && npx tsc --noEmit

# ── Lint ───────────────────────────────────────────────────────────────────
lint-all:
    cd app && dart analyze
    cd services && npx eslint .

# ── Build ──────────────────────────────────────────────────────────────────
build service:
    docker build -t {{service}} services/{{service}}

# ── Deploy (manual, for hotfixes outside CI) ───────────────────────────────
deploy service:
    gcloud run deploy {{service}} \
      --image gcr.io/$PROJECT_ID/{{service}}:latest \
      --region us-central1 \
      --platform managed
```

Usage examples:
```bash
just dev-fact-checker           # start one service with hot reload
just test service=polarizer     # test a single service
just check-types                # validate shared contract across all services
just build service=sensemaker
just deploy service=fact-checker
```

### 5.5 CI/CD

One Cloud Build trigger per service directory. Each trigger fires only when its own path changes — no unnecessary rebuilds.

```yaml
# infra/cloudbuild/fact-checker.yaml
steps:
  - name: node:20
    dir: services/fact-checker
    args: ['npm', 'ci']
  - name: node:20           # install shared types package
    dir: types
    args: ['npm', 'ci']
  - name: node:20           # validate shared contract
    dir: services/fact-checker
    args: ['npx', 'tsc', '--noEmit']
  - name: node:20
    dir: services/fact-checker
    args: ['npm', 'test']
  - name: gcr.io/cloud-builders/docker
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/fact-checker:$COMMIT_SHA', 'services/fact-checker']
  - name: gcr.io/cloud-builders/docker
    args: ['push', 'gcr.io/$PROJECT_ID/fact-checker:$COMMIT_SHA']
  - name: gcr.io/google.com/cloudsdktool/cloud-sdk
    args:
      - gcloud
      - run
      - deploy
      - fact-checker
      - --image=gcr.io/$PROJECT_ID/fact-checker:$COMMIT_SHA
      - --region=us-central1
      - --platform=managed

# Cloud Build trigger configuration (set in GCP Console or via gcloud):
#   includedFiles: services/fact-checker/**
#   branch: ^main$
```

The same structure repeats for `polarizer` and `sensemaker` with their respective paths. The Flutter app uses a separate trigger scoped to `app/**` that runs `flutter test` and produces a build artifact.

```
push to main
  path: services/fact-checker/**  → fact-checker.yaml  → Cloud Run
  path: services/polarizer/**     → polarizer.yaml     → Cloud Run
  path: services/sensemaker/**    → sensemaker.yaml    → Cloud Run
  path: app/**                    → app.yaml           → build artifact
```

Each service has a `GET /health` endpoint returning `200 OK` — Cloud Run uses this for the automatic rollback signal on a failed deployment.

---

## 6. Flutter Integration Guide

This section is the implementation checklist for the Flutter side.

### 6.1 New dependency

Add to `pubspec.yaml` — no new packages required. Dio and Retrofit are already present. Create a new Retrofit service for the API Gateway, similar to the existing `NewsApiService`.

### 6.2 Adding a new service integration (pattern)

Every new microservice integration follows this exact sequence. Do not deviate.

```
features/{service_name}/
  domain/
    entities/{service_name}_entity.dart        # pure Dart, no framework imports
    repository/{service_name}_repository.dart  # abstract interface
    usecases/
      run_{service_name}_use_case.dart          # triggers processing
      get_{service_name}_result_use_case.dart   # reads Firestore result
  data/
    data_sources/
      {service_name}_remote_data_source.dart   # calls API Gateway via Dio
      {service_name}_firestore_data_source.dart # reads result from Firestore
    models/{service_name}_model.dart            # fromFirestore() + toEntity()
    repository/{service_name}_repository_impl.dart
  presentation/
    bloc/{service_name}_bloc.dart              # Loading → Processing → Result → Error
    widgets/{service_name}_badge.dart
```

### 6.3 BLoC state machine (standard pattern for all three)

```dart
// States
sealed class ServiceState {}
class ServiceInitial extends ServiceState {}
class ServiceRequested extends ServiceState {}   // call sent, waiting for Firestore
class ServiceLoaded extends ServiceState { final Entity result; }
class ServiceError extends ServiceState { final String message; }

// Event flow
// 1. User taps → dispatch RunServiceEvent
// 2. BLoC calls run use case → HTTP POST to API Gateway → returns 202
// 3. BLoC starts listening to Firestore document
// 4. When Firestore document updates → dispatch ResultReceivedEvent → emit Loaded
```

The Firestore listener is opened after the `202 Accepted` response and closed when the result arrives or after a timeout (suggest 30 seconds — show a "try again" message if exceeded).

### 6.4 Injection container

Register all new repositories and use cases in `injection_container.dart` following the existing pattern. Each service adds approximately 4–6 registrations (data source, repository, 2 use cases, BLoC).

---

## 7. Firestore Schema Changes

Summary of all Firestore changes required. Existing documents are unaffected unless noted.

| Collection | Field | Type | Added by | Notes |
|---|---|---|---|---|
| `fact_checks/{id}` | `botCheck` | map | `fact-checker` | Already in schema, currently seeded |
| `articles/{id}` | `biasReport` | map | `polarizer` | New field, optional |
| `sensemaker_articles` | entire collection | — | `sensemaker` | New collection |

No migrations required. Firestore is schemaless — new fields appear when the service first writes them.

Update `firestore.rules` to allow the microservice service account to write to `fact_checks` and `articles`. Use `request.auth.token.firebase.identities` or a custom claim to identify service account writes vs. user writes.

---

## 8. Build Order

Build in this sequence. Each phase is independently shippable.

### Phase 1: fact-checker backend
The Flutter UI is already built. Wire up the real service, remove the seeder from production builds. This is the fastest path to an end-to-end demo of the microservices pattern.

**Deliverable:** User can tap "Check article" → real bot analysis appears in the UI.

### Phase 2: API Gateway + shared infra
Establish the gateway, Secret Manager setup, Artifact Registry, and Cloud Build pipeline once. All subsequent services reuse this without modification.

**Deliverable:** fact-checker is behind the gateway. Infrastructure pattern is documented and repeatable.

### Phase 3: polarizer
Straightforward structured prompt → Firestore write. Reuses the Cloud Run + Gemini pattern from Phase 1. Add the `bias_report` Flutter feature.

**Deliverable:** User can tap "Check bias" on any article and see a bias breakdown.

### Phase 4: sensemaker ⏳ Coming Soon

> **Status: Deferred.** The service scaffold, Cloud Build pipeline, API Gateway routes, and shared TypeScript contracts are all in place. Implementation is blocked pending decisions on source licensing (see Open Questions §10.2) and rate-limiting policy (§10.4). The Flutter UI shows a placeholder.

Most complex — requires multi-source ingestion, embedding pipeline, and vector search. Build last when the infrastructure and Flutter integration patterns are well-established.

**Deliverable:** User can tap "Find related coverage" and see the same event from different sources and perspectives.

---

## 9. Decision Log

Decisions made during design that you should not revisit without a concrete reason.

| Decision | Rationale | Revisit if |
|---|---|---|
| Cloud Run over Cloud Functions | Services need >9min execution time for ingestion; Cloud Run has no timeout limit | Sensemaker ingestion stays under 9 minutes consistently |
| Write-to-Firestore pattern | Decouples processing time from client UX; no polling; reuses existing listeners | Latency becomes unacceptable for a specific use case |
| Sensemaker responds synchronously | Result set is small; caching in Firestore adds complexity without benefit | Users query the same article repeatedly and latency is noticeable |
| Firestore Vector Search over Matching Engine | Lower ops overhead; sufficient for <1M articles; stays in Firebase ecosystem | Article index exceeds 500K documents or query latency exceeds 3s |
| peoples-court stays in Firestore | Atomic transactions already handle vote counting correctly; no feature gap | Weighted voting, moderation queues, or cross-article analytics are required |
| Single API Gateway | One JWT validation point; one URL to manage in Flutter; trivial to extend | Services need different auth models (e.g. B2B API keys) |

---

## 10. Open Questions

These are unresolved at architecture time and need a decision before implementation of the relevant phase.

1. **fact-checker reference corpus:** Gemini alone can evaluate claim plausibility but has a knowledge cutoff. Do we need to integrate a live fact-check database (PolitiFact API, ClaimBuster)? If yes, this adds a data licensing consideration.

2. **sensemaker source licensing:** GDELT is public domain. RSS feeds are publicly accessible but redistribution may require attribution. Confirm legal posture before ingesting and storing article content at scale — storing snippets only (not full text) is the safer default.

3. **polarizer ground truth:** The bias scores will be subjective without a labeled validation set. Consider a feedback mechanism where users can flag a bias score as inaccurate — this doubles as training data for future model fine-tuning.

4. **Rate limiting per user:** Should users be able to trigger fact-checker and polarizer unlimited times? Cloud Run costs scale with invocations. API Gateway supports quota policies per Firebase UID — decide on a limit before launch.

5. **Regional deployment:** `us-central1` is assumed throughout. If the user base is primarily in another region, adjust Cloud Run and Vertex AI regions together (Vertex AI model availability varies by region).
