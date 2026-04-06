# Learning Journey

A running log of checkpoints as the project progresses. Each checkpoint captures what was learned, what was built, and what came next.

---

## Checkpoint 1 — Minimum Delivery Complete

**State of the project:** All acceptance criteria in `ACCEPTANCE_CRITERIA.md` are met. The app compiles and runs on Android and macOS.

**What was built:**
- Firebase project configured (Firestore, Storage, Auth — email/password)
- Firestore schema designed and documented (`backend/docs/DB_SCHEMA.md`) — intentionally kept at this path to match the assignment spec
- Firestore and Storage security rules written and deployed
- Flutter connected to Firebase via FlutterFire CLI
- `auth` feature: sign in, sign out, `AuthBloc`, navigation guards
- `publish_article` feature: full clean architecture stack — domain, data (Firestore + Storage data sources), presentation (form UI, `UploadArticleBloc`)
- Firestore-published articles merged into the home feed alongside the existing News API articles
- Category filter bar on home feed (bonus — driven by `articleCategories` Firestore collection)
- Explore screen with category grid (bonus)
- macOS sandbox entitlements configured so network calls work on desktop

**What I learned at this checkpoint:**
- Flutter widget tree and lifecycle basics
- BLoC and Cubit patterns for state management
- Firebase Firestore: collections, documents, security rules, server timestamps
- Firebase Storage: upload flow, download URLs, path conventions
- Flutter Clean Architecture layering: strict import boundaries between domain / data / presentation
- GetIt for dependency injection
- Floor ORM for local SQLite (already in the codebase — learned it by reading the existing `daily_news` feature)
- Platform-specific setup: CocoaPods, macOS sandbox entitlements

**What to follow up with:**
- Article editing and deletion UI for articles the journalist has already published
- Pagination for both the API and Firestore queries
- Optimistic UI on publish

---

## Checkpoint 2 — Overdelivery Features Complete

**State of the project:** Three NestJS microservices built and running locally. AI-powered fact-checking, bias detection, and similar article recommendations integrated into the article detail page. Journalist profile page with edit/delete actions. GCP infrastructure written and ready to deploy.

**What was built:**

*Microservices (Node.js / NestJS):*
- `services/fact-checker` — receives an article, calls a local Ollama LLM, returns a structured fact-check verdict; caches the result in Firestore
- `services/polarizer` — same pattern for bias detection (left / center / right lean + confidence score)
- `services/sensemaker` — uses Ollama embeddings to find thematically similar articles from the feed
- `types/` — shared TypeScript interfaces package (`@news-lab/types`) consumed by all three services to prevent schema drift

*Flutter features:*
- `fact_check` feature — `FactCheckBloc`, `BotCheckApiDataSource`, `FactCheckRemoteDataSource` (Firestore cache), community vote submission, fact-check badges on article detail
- `bias_report` feature — `BiasReportBloc`, `PolarizeApiDataSource`, `BiasReportRemoteDataSource` (Firestore cache), bias badge on article detail
- `similar_articles` feature — `SimilarArticlesBloc`, `SensemakerApiDataSource`, similar articles section on article detail
- `journalist_profile` feature — profile page listing the signed-in user's articles, edit article page, delete with confirmation

*Infrastructure (`infra/`):*
- Cloud Run service definitions for each microservice
- GCP API Gateway with OpenAPI spec routing authenticated requests to each Cloud Run service
- Cloud Build pipeline for CI/CD
- Secret Manager integration for API keys
- `justfile` at repo root unifying all dev, test, lint, build, and deploy commands across the monorepo

**What I learned at this checkpoint:**
- NestJS module/controller/service structure and how it maps to the same clean architecture separation used in Flutter
- Ollama local LLM APIs: model prompting, structured JSON output, embedding endpoints
- GCP API Gateway: OpenAPI spec authoring, service-account-based backend auth to Cloud Run
- `adb reverse` for forwarding device localhost ports to the Mac during development
- Shared npm packages with local `file:` references across a monorepo
- How to split a complex screen (article detail) into independently-scoped BLoCs without coupling their lifecycles

**What to follow up with:**
- Deploy Ollama to a GPU-backed Cloud Run instance so the services work without a local machine
- Enable the Cloud Build trigger so deploys happen automatically on push to main
- Pagination on the home feed and journalist profile article list
- Offline-first publish flow using the Floor ORM already in the codebase

---

## Checkpoint 3 — *(to be filled)*
