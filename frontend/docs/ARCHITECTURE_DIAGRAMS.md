# news-lab: Architecture Diagrams
**Companion to:** `ARCHITECTURE_EXPANSION.md`  
**Notation:** C4 Model (L1 Context → L2 Container) + UML Sequence

---

## Diagram 1 — System Context (C4 Level 1)

> Who uses the system and what external systems does it depend on.

```mermaid
C4Context
    title System Context — news-lab

    Person(reader, "Reader", "Reads curated news,<br/>votes on fact-checks")
    Person(journalist, "Journalist", "Publishes articles,<br/>requests analysis on demand")

    System(newslab, "news-lab", "Cross-platform news application<br/>with AI-assisted analysis layer")

    System_Ext(firebase, "Firebase Platform", "Authentication, Firestore,<br/>Cloud Storage")
    System_Ext(vertexai, "Vertex AI", "Gemini LLM · text-embedding-004<br/>Google Cloud AI platform")
    System_Ext(newsapi, "NewsAPI.org", "External headline feed")
    System_Ext(gdelt, "GDELT / RSS", "Multi-source news corpus<br/>for semantic indexing")

    Rel(reader, newslab, "Reads news, votes", "Mobile · Desktop · Web")
    Rel(journalist, newslab, "Publishes, triggers analysis", "Mobile · Desktop · Web")

    Rel(newslab, firebase, "Auth · database · storage", "Firebase SDK / gRPC")
    Rel(newslab, vertexai, "LLM inference · embeddings", "gRPC / REST")
    Rel(newslab, newsapi, "Headline ingestion", "HTTPS / REST")
    Rel(newslab, gdelt, "Multi-source ingestion", "HTTPS / BigQuery API")
```

---

## Diagram 2 — Container Architecture (C4 Level 2)

> Every deployable unit, its technology, and how they communicate.

```mermaid
C4Container
    title Container Diagram — news-lab Microservices Expansion

    Person(user, "User", "Reader or Journalist")

    System_Boundary(client, "Client Layer") {
        Container(flutter, "Flutter App", "Dart · Flutter 3", "Cross-platform UI.<br/>BLoC state management.<br/>Clean Architecture feature modules.")
    }

    System_Boundary(gateway_layer, "Edge Layer — GCP") {
        Container(gateway, "API Gateway", "GCP API Gateway", "Single ingress point.<br/>Firebase JWT validation.<br/>Rate limiting · routing.")
    }

    System_Boundary(services, "Service Layer — GCP Cloud Run") {
        Container(factchecker, "fact-checker", "Node.js · NestJS · Cloud Run", "Extracts factual claims.<br/>Evaluates against corpus.<br/>Writes botCheck to Firestore.")
        Container(polarizer, "polarizer", "Node.js · NestJS · Cloud Run", "Scores political lean,<br/>emotional language, framing.<br/>Writes biasReport to Firestore.")
        Container(sensemaker, "sensemaker", "Node.js · NestJS · Cloud Run", "Ingests multi-source news.<br/>Generates vector embeddings.<br/>Serves semantic similarity queries.")
    }

    System_Boundary(data, "Data Layer — GCP") {
        ContainerDb(firestore, "Firestore", "Google Cloud Firestore", "articles · fact_checks<br/>sensemaker_articles · categories<br/>Real-time listeners to client.")
        ContainerDb(vertexai, "Vertex AI", "Gemini 1.5 Flash · Pro<br/>text-embedding-004", "LLM inference for all services.<br/>Vector embedding generation.")
        ContainerDb(secretmgr, "Secret Manager", "GCP Secret Manager", "NewsAPI key · service<br/>account credentials.")
    }

    System_Boundary(ops, "Ops Layer — GCP") {
        Container(scheduler, "Cloud Scheduler", "GCP Cloud Scheduler", "Triggers sensemaker<br/>/ingest daily at 03:00 UTC.")
        Container(registry, "Artifact Registry", "GCP Artifact Registry", "Versioned Docker images<br/>for all Cloud Run services.")
        Container(cloudbuild, "Cloud Build", "GCP Cloud Build", "CI/CD pipeline.<br/>Build → push → deploy<br/>on push to main.")
    }

    System_Ext(firebase_auth, "Firebase Auth", "JWT issuance · user identity")
    System_Ext(newsapi_ext, "NewsAPI.org", "Top headlines feed")
    System_Ext(gdelt_ext, "GDELT · RSS Feeds", "BBC · Reuters · AP · Al Jazeera")

    %% Client ↔ Firebase Auth
    Rel(user, flutter, "Uses", "HTTPS")
    Rel(flutter, firebase_auth, "Sign in · get JWT", "Firebase SDK")

    %% Client ↔ Data (real-time reads)
    Rel(flutter, firestore, "Real-time listeners<br/>(articles · fact_checks · bias)", "Firebase SDK · WebSocket")

    %% Client → Edge → Services (on-demand triggers)
    Rel(flutter, gateway, "POST /fact-check<br/>POST /polarize<br/>POST /similar", "HTTPS · Bearer JWT")
    Rel(gateway, factchecker, "Routes validated request", "HTTPS")
    Rel(gateway, polarizer, "Routes validated request", "HTTPS")
    Rel(gateway, sensemaker, "Routes validated request", "HTTPS")

    %% Services → AI
    Rel(factchecker, vertexai, "Claim extraction · evaluation", "gRPC")
    Rel(polarizer, vertexai, "Bias scoring", "gRPC")
    Rel(sensemaker, vertexai, "Embedding generation", "gRPC")

    %% Services → Firestore (async writes)
    Rel(factchecker, firestore, "Writes fact_checks/{id}.botCheck", "gRPC")
    Rel(polarizer, firestore, "Writes articles/{id}.biasReport", "gRPC")
    Rel(sensemaker, firestore, "Writes sensemaker_articles", "gRPC")

    %% Services → Secrets
    Rel(factchecker, secretmgr, "Reads credentials at boot", "gRPC")
    Rel(polarizer, secretmgr, "Reads credentials at boot", "gRPC")
    Rel(sensemaker, secretmgr, "Reads credentials at boot", "gRPC")

    %% Ops → Services
    Rel(scheduler, sensemaker, "POST /ingest (daily 03:00 UTC)", "HTTPS · SA token")
    Rel(cloudbuild, registry, "Pushes Docker image", "")
    Rel(registry, factchecker, "Pulls image on deploy", "")
    Rel(registry, polarizer, "Pulls image on deploy", "")
    Rel(registry, sensemaker, "Pulls image on deploy", "")

    %% Sensemaker → External sources
    Rel(sensemaker, newsapi_ext, "Fetches headlines", "HTTPS · REST")
    Rel(sensemaker, gdelt_ext, "Fetches multi-source corpus", "HTTPS · BigQuery API")
```

---

## Diagram 3 — On-Demand Analysis Flow (UML Sequence)

> What happens end-to-end when a journalist taps "Check this article."  
> The same flow applies to `polarizer` — only the endpoint and Firestore field change.

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant FS as Firestore
    participant GW as API Gateway
    participant FC as fact-checker<br/>(Cloud Run)
    participant VAI as Vertex AI<br/>(Gemini)

    User->>App: Taps "Fact-check article"
    activate App

    App->>GW: POST /fact-check<br/>{ articleId, text }<br/>Bearer: <firebase-jwt>
    activate GW

    GW->>GW: Validate Firebase JWT
    GW->>FC: Forward request (identity verified)
    activate FC

    FC-->>GW: 202 Accepted<br/>{ status: "processing" }
    GW-->>App: 202 Accepted
    deactivate GW

    App->>App: Emit ServiceRequested state
    App->>FS: Open real-time listener<br/>fact_checks/{articleId}
    deactivate App

    Note over FC,VAI: Async processing begins

    FC->>VAI: Extract factual claims<br/>from article text
    activate VAI
    VAI-->>FC: Structured claim list
    deactivate VAI

    FC->>VAI: Evaluate each claim<br/>(plausibility · sources)
    activate VAI
    VAI-->>FC: Evaluation results
    deactivate VAI

    FC->>FC: Compute flaggedSentencesPercent<br/>+ confidenceScore

    FC->>FS: Write fact_checks/{articleId}.botCheck<br/>{ flaggedSentencesPercent, confidenceScore, checkedAt }
    deactivate FC

    FS-->>App: Real-time push (listener fires)
    activate App
    App->>App: Emit ServiceLoaded state<br/>with BotCheckEntity
    App-->>User: Renders BotCheckBadge
    deactivate App
```

---

## Diagram 4 — Sensemaker Ingestion Flow (UML Sequence)

> Background pipeline. Runs daily via Cloud Scheduler. No user interaction.

```mermaid
sequenceDiagram
    participant SCH as Cloud Scheduler
    participant SM as sensemaker<br/>(Cloud Run)
    participant NAPI as NewsAPI.org
    participant GDELT as GDELT · RSS
    participant VAI as Vertex AI<br/>(text-embedding-004)
    participant FS as Firestore<br/>sensemaker_articles

    SCH->>SM: POST /ingest<br/>03:00 UTC daily<br/>SA token auth
    activate SM

    SM->>NAPI: GET /top-headlines<br/>(all categories)
    NAPI-->>SM: Article batch

    SM->>GDELT: Fetch RSS feeds<br/>+ BigQuery export
    GDELT-->>SM: Article batch

    SM->>SM: Deduplicate by URL<br/>Normalise schema

    loop For each article batch (max 100/call)
        SM->>VAI: Generate embeddings<br/>text-embedding-004
        VAI-->>SM: vector<768> per article
    end

    SM->>FS: Batch write<br/>sensemaker_articles<br/>{ title, source, url, snippet,<br/>publishedAt, embedding }
    FS-->>SM: ACK

    SM-->>SCH: 200 OK<br/>{ ingested: N, deduplicated: M }
    deactivate SM
```

---

## Diagram 5 — On-Demand Similarity Query (UML Sequence)

> sensemaker's query path is synchronous — the only service that responds with data directly.

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant GW as API Gateway
    participant SM as sensemaker<br/>(Cloud Run)
    participant VAI as Vertex AI<br/>(text-embedding-004)
    participant FS as Firestore<br/>sensemaker_articles

    User->>App: Taps "Find related coverage"
    activate App

    App->>GW: POST /similar<br/>{ articleId, text }<br/>Bearer: <firebase-jwt>
    activate GW

    GW->>GW: Validate Firebase JWT
    GW->>SM: Forward request
    activate SM

    SM->>VAI: Embed query article text
    VAI-->>SM: query vector<768>

    SM->>FS: Vector similarity search<br/>ORDER BY distance(embedding, queryVec)<br/>LIMIT 15
    FS-->>SM: Top-15 similar articles

    SM-->>GW: 200 OK<br/>{ results: [...] }
    deactivate SM

    GW-->>App: 200 OK · results
    deactivate GW

    App->>App: Emit SensemakerLoaded state
    App-->>User: Renders "Related Coverage" panel
    deactivate App
```

---

## Diagram 6 — Flutter BLoC State Machine

> Canonical state machine implemented by every microservice BLoC in the Flutter app.  
> Applies identically to `FactCheckBloc`, `BiasReportBloc`, and `SensemakerBloc`.

```mermaid
stateDiagram-v2
    direction LR

    [*] --> Initial

    Initial --> Requesting : User triggers analysis
    Requesting --> Requested : 202 Accepted from API Gateway\nFirestore listener opened

    Requested --> Loaded : Firestore real-time push\n(service wrote result)
    Requested --> Error : Timeout (30s) or\nFirestore read failure

    Loaded --> Requesting : User re-triggers analysis

    Error --> Requesting : User retries

    note right of Requesting
        HTTP POST to API Gateway.
        Emits loading indicator in UI.
    end note

    note right of Requested
        Listener open on Firestore doc.
        UI shows "processing" state.
    end note

    note right of Loaded
        BotCheckEntity / BiasEntity /
        SensemakerResults materialised.
        Badge rendered in UI.
    end note
```

---

## Diagram 7 — Deployment & Build Pipeline

> How code moves from a developer's machine to a running Cloud Run service.

```mermaid
flowchart TD
    DEV([Developer\npushes to main]) --> CB

    subgraph CICD ["CI/CD — Cloud Build"]
        CB[Cloud Build\ntrigger fires]
        CB --> TEST[Run unit tests]
        TEST --> BUILD[docker build]
        BUILD --> PUSH[Push image to\nArtifact Registry]
        PUSH --> DEPLOY[gcloud run deploy\n--image :latest\n--region us-central1]
        DEPLOY --> HEALTH{Health check\nGET /health\n→ 200?}
        HEALTH -- pass --> LIVE[Traffic migrated\nto new revision]
        HEALTH -- fail --> ROLLBACK[Automatic rollback\nto previous revision]
    end

    subgraph GCR ["Cloud Run — Production"]
        FC_SVC["fact-checker\nmin 0 · max 5"]
        POL_SVC["polarizer\nmin 0 · max 5"]
        SM_SVC["sensemaker\nmin 0 · max 10"]
    end

    LIVE --> FC_SVC
    LIVE --> POL_SVC
    LIVE --> SM_SVC

    subgraph SECRETS ["Secret Manager"]
        S1[newsapi-key]
        S2[vertex-ai-project]
        S3[firebase-service-account]
    end

    FC_SVC -. reads at boot .-> SECRETS
    POL_SVC -. reads at boot .-> SECRETS
    SM_SVC -. reads at boot .-> SECRETS
```

---

## Diagram 8 — Implementation Phases

> Build order and dependencies between phases.

```mermaid
gantt
    title Implementation Phases — news-lab Microservices
    dateFormat  YYYY-MM-DD
    axisFormat  Phase %s

    section Phase 1 · fact-checker
    Cloud Run service (Node.js + NestJS)     :p1a, 2026-04-06, 7d
    Vertex AI claim extraction prompt        :p1b, after p1a, 4d
    Wire Flutter FactCheckBloc to real API   :p1c, after p1b, 3d
    Remove dev seeder from prod builds       :p1d, after p1c, 1d

    section Phase 2 · Shared Infrastructure
    API Gateway setup + JWT validation       :p2a, after p1d, 3d
    Secret Manager + IAM roles               :p2b, after p2a, 2d
    Artifact Registry + Cloud Build pipeline :p2c, after p2b, 3d
    Migrate fact-checker behind gateway      :p2d, after p2c, 1d

    section Phase 3 · polarizer
    Cloud Run service (shared Node.js base)  :p3a, after p2d, 5d
    Bias scoring Gemini prompt + schema      :p3b, after p3a, 4d
    Flutter bias_report feature module       :p3c, after p3b, 5d

    section Phase 4 · sensemaker
    Multi-source ingestion pipeline          :p4a, after p3c, 7d
    Vertex AI embeddings + Firestore vectors :p4b, after p4a, 5d
    Cloud Scheduler daily trigger            :p4c, after p4b, 2d
    Flutter sensemaker feature module        :p4d, after p4c, 7d
```
