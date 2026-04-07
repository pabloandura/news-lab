# Project Report — News Lab

## 1. Introduction

I came into this project with prior experience in full-stack development but not with Flutter, Firebase, or the BLoC pattern specifically.
My familiarity was in clean architecture principles and state management in general, so the learning curve was around the ecosystem and tooling rather than the underlying ideas. The assignment is well scoped — a realistic feature you'd build in any news or publishing product — which made it easier to stay motivated and treat it as production work rather than a coding exercise.

---

## 2. Learning Journey

*See [`docs/LEARNING_JOURNEY.md`](LEARNING_JOURNEY.md) for a detailed, running log of checkpoints.*

The short version: I worked through Flutter and BLoC fundamentals first, then Firebase integration, then clean architecture layering.

I wrote an `ACCEPTANCE_CRITERIA.md` at the repo root to sequence work and avoid building ahead of what was actually needed — it kept the minimum delivery tightly scoped while leaving room to overdeliver once the core was solid.

---

## 3. Challenges Faced

**New ecosystem from scratch.** Flutter, Firebase, and BLoC were all new to me. The biggest friction was not the concepts (clean architecture and reactive state management are language-agnostic) but the tooling: FlutterFire CLI setup, CocoaPods dependency resolution on macOS, and the macOS sandbox entitlements needed to allow network calls on desktop. The entitlements issue silently blocked all Firebase calls on macOS until I traced it to a missing `com.apple.security.network.client` entitlement.

**Firestore security rules as a first-class concern.** Writing rules that enforced schema ownership (`request.auth.uid == resource.data.authorId`) while still allowing the merged home feed to read both authenticated and unauthenticated articles required careful scoping. Rules are easy to over-restrict and hard to debug — I ended up iterating on them in the Firebase emulator before deploying.

**BLoC subscription lifecycle.** Understanding when to `close` a BLoC, how to avoid duplicate stream subscriptions when a widget rebuilds, and the right granularity for events vs. states took several iterations. The fact-check feature surfaced this most clearly: a `FactCheckBloc` created per article tile caused an explosion of Firestore reads that I caught in the profiler and refactored out.

**Designing for extension from day one.** Keeping the data layer split into separate `ArticleFirestoreDataSource` and `ArticleStorageDataSource` — and later adding parallel service-backed data sources for fact-check and bias without touching the domain layer — validated the clean architecture constraint. The friction of the strict import boundaries paid off each time a new data source was wired in without touching existing code.

**Denormalized badge fields as a feed performance trade-off.** Storing `badgeFactCheck` and `badgeBias` directly on each `articles` document (written by the backend services) means the home feed can display all badges in a single Firestore read, with no join to `fact_checks`. The downside is that if the badge classification logic ever changes the stored values need backfilling. For a read-heavy, append-mostly feed this is the right trade-off: reads are vastly more frequent than classification rule updates.

---

## 4. Reflection and Future Directions

The clean architecture constraint — no Firebase imports in `domain/`, no business logic in `build()` methods — adds upfront friction but pays off quickly when you need to swap or extend a data source. Every new feature (fact-check, bias report, similar articles) followed the same domain → data → presentation path, which made each one faster to ship than the last.

**Future directions I'd pursue with more time:**

- **Article editing flow:** The journalist profile page lists a user's articles and links to an edit page, but the optimistic UI and offline draft support are not there yet.
- **Pagination:** Both the News API feed and the Firestore articles query are unpaginated. A cursor-based pagination strategy on the repository layer would fix this cleanly.
- **Push notifications:** Firestore + FCM could notify journalists when their article receives a community fact-check vote — closing the feedback loop for the community notes feature.
- **Ollama model selection UI:** The sensemaker and fact-checker services call a locally running Ollama instance. Exposing model selection in the app settings would let users switch between models without a service restart.
- **Deployed backend:** Currently the three microservices (fact-checker, polarizer, sensemaker) run locally with `adb reverse` for device access. The Cloud Run + API Gateway infrastructure is already written in `infra/` and `justfile`; it just needs secrets provisioned and a CI trigger enabled.

---

## 5. Proof of the Project

*Screenshots and screen recordings to be added here.*

Screens to document:
- Login page
- Home feed (merged News API + Firestore articles, category filter bar)
- Publish article form (title, description, content, thumbnail picker)
- Article detail page (fact-check badges, bias badge, similar articles section)
- Journalist profile page (article list, edit and delete actions)
- Explore page (category grid)

---

## 6. Overdelivery

### 6.1 New Features Implemented

#### Multiple news sources — merged home feed
The home feed combines articles from the [News API](https://newsapi.org/) (existing) with journalist-published articles from Firestore (new). Both sources are merged and sorted by publish date inside the repository layer, keeping the presentation layer oblivious to the source split. A category filter bar (driven by a `articleCategories` Firestore collection) applies across both sources.

#### Journalist profile page
A dedicated screen lets signed-in journalists view all articles they have published. From there they can open an edit form to update any field, or delete an article (with confirmation). This closes the publishing lifecycle — create, read, update, delete — that the core assignment only required the "create" side of.

#### Explore page
A full-screen category grid lets users browse articles by category. Categories are fetched from the `articleCategories` Firestore collection (same data that drives the home feed filter), so adding a new category in Firestore propagates to both surfaces without a code change.

#### AI-powered fact-checking (`fact_check` feature + `fact-checker` service)
Each article detail page shows a fact-check panel with two components:

- **Bot check:** a NestJS microservice (`services/fact-checker`) that calls a locally running [Ollama](https://ollama.com/) LLM to rate the article's factual reliability and return a structured verdict. The result is cached in Firestore under `fact_checks/{articleId}` so the LLM is only called once per article.
- **Community check:** readers can cast an `accurate` / `inaccurate` / `unsure` vote. Votes are stored in Firestore (`fact_checks/{articleId}/votes/{userId}`) and aggregated into `fact_checks/{articleId}.communityCheck` counters, displayed as a badge on both the article detail page and the home feed tile.

Home feed badges for every article: once the fact-checker pipeline writes its result, `RemoteArticlesBloc` derives the `badgeFactCheck` badge from `botCheck.flaggedSentencesPercent` (≥ 0.3 → "disputed", otherwise "verified") and patches it onto the article entity so the badge appears on the tile immediately — no reload required. The `_TileBadges` widget in `article_tile.dart` renders the fact-check chip, bias chip, and community vote chip for all articles on the home feed, regardless of whether the article came from Firestore or the News API.

The `fact_check` feature is fully layered: domain entities and use cases are Firebase/HTTP agnostic; the data layer has two separate data sources — `FactCheckRemoteDataSource` (Firestore) and `BotCheckApiDataSource` (HTTP).

#### Bias detection (`bias_report` feature + `polarizer` service)
A `polarizer` NestJS microservice accepts an article and returns a bias report (left/center/right lean with a confidence score) by calling Ollama. The bias report is embedded directly inside the `articles/{articleId}` document (`biasReport` sub-map) so that a single Firestore read retrieves both article and analysis. `badgeBias` is also written to the same document as a denormalized string (`"left"` / `"center"` / `"right"`) so the home feed can render the badge without a second read. The article detail page shows the bias badge, and the polarizer also increments the `stats/bias_landscape` singleton document to power a global bias distribution dashboard.

#### Similar articles (`similar_articles` feature + `sensemaker` service)
A `sensemaker` NestJS microservice finds thematically related articles using Ollama embeddings. The article detail page shows a "Similar Articles" section with links to related stories. The feature is fully layered with its own domain entity, repository, and BLoC.

#### Shared TypeScript types package (`types/`)
A local `types` npm package (`@news-lab/types`) defines the shared request/response contracts used by all three microservices. This prevents schema drift between services without a full gRPC or GraphQL setup.

#### Unified task runner (`justfile`)
A `justfile` at the repo root provides a single interface for all development and deployment tasks across the monorepo: `just dev-all` starts all three services and Flutter concurrently with log prefixing; `just deploy-rules` deploys Firestore and Storage security rules; `just gateway-create` / `just gateway-update` manage the GCP API Gateway. See the [README](../../README.md) for the full command reference.

#### GCP cloud infrastructure (`infra/`)
The `infra/` directory contains everything needed to run the backend in production:
- Cloud Run service definitions for each microservice
- A GCP API Gateway with an OpenAPI spec that proxies authenticated requests to the correct Cloud Run service
- A Cloud Build pipeline (`infra/cloudbuild/`) for CI/CD
- Secret Manager integration for API keys

### 6.2 Prototypes Created

#### Microservice architecture diagram
The three microservices (fact-checker, polarizer, sensemaker) sit behind a single GCP API Gateway. The Flutter app talks only to the gateway, which routes requests and handles service-account authentication to Cloud Run. A UML-style sequence diagram for this flow:

```
Flutter → API Gateway → [fact-checker | polarizer | sensemaker] → Ollama (local / Cloud Run)
                    ↓
              Firestore (cache layer)
```

#### Shared types package as a lightweight contract layer
Rather than duplicating request/response interfaces across services, `types/` acts as a compile-time contract. Any breaking change in a service's interface is caught by `just check-types` before it reaches the gateway.

### 6.3 How Can You Improve This

- **Deploy Ollama to Cloud Run** (GPU instance) so the fact-checker, polarizer, and sensemaker work without a local machine running. The Cloud Run configs are already in `infra/` but Ollama hosting needs a GPU-backed service.
- **Stream LLM responses** to the Flutter client using Server-Sent Events instead of waiting for the full response — this would make the fact-check UX feel much faster for long articles.
- **Add a confidence threshold UI** so editors can configure at what bias score an article gets flagged for review before it appears in the home feed.
- **Community notes moderation:** add an admin role in Firestore rules and a simple moderation screen so abusive votes can be removed without touching production data.
- **Offline-first publishing:** buffer unpublished articles in the local Floor database and sync when connectivity is restored — the Floor ORM is already in the codebase for saved articles.
