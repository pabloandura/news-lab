# Learning Journey

A running log of checkpoints as the project progresses. Each checkpoint captures what was learned, what was built, and what came next.

---

## Checkpoint 1 — Minimum Delivery Complete

**State of the project:** All acceptance criteria in `ACCEPTANCE_CRITERIA.md` are met. The app compiles and runs on all potential environments.

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

**What I quickly followed up with:**
- Article editing and deletion UI for articles the journalist has already published
- Optimistic UI on publish

---

## Checkpoint 2 — Overdelivery Features Complete

**A moment to think**:** I thought of the initial proposition: "You are a journalist and **as a journalist, you would love to upload your own articles to the app so that society can benefit from your genius**.". And then I though, "What else would a journalist love to have in an app like this? What would make their life easier, their work more impactful, or their experience more enjoyable?".
Therefore I decided to build some AI-powered features that would enhance the value of the app for journalists and readers alike, such as fact-checking, bias detection, and similar article recommendations. I also wanted to create a journalist profile page where they could manage their articles and see their impact on the audience.

**State of the project:** Three NestJS microservices built and running locally. 
Flutter features built to consume the microservices and deployed to production. GCP API Gateway routing requests to the microservices with authentication. CI/CD pipeline set up for automated deployments on push to main.

**What was built:**

*Microservices (Node.js / NestJS):*
1. `fact-checker`: receives an article, calls a Vertex AI model in production (Mistral in local development), returns a structured fact-check verdict; caches the result in Firestore.
2. `polarizer`: same pattern for bias detection (left / center / right lean + confidence score)
3. `sensemaker`: uses Vertex AI embeddings to find thematically similar articles from the feed. Shared TypeScript interfaces package (`@news-lab/types`) consumed by all three services to prevent schema drift.
4. `Journalist profile` feature with list of the signed-in user's articles, edit article page, delete with confirmation.

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
- I'd already knew NestJS well and that is why it was selected.
- To prevent running a bill while developing locally against Vertex AI, I set up a local Ollama instance with the Mistral 7B model and implemented an adapter pattern in the microservices to switch between the local and production LLMs based on environment. This allowed me to develop and test the AI features without incurring GCP costs.
- GCP API Gateway: OpenAPI spec authoring, service-account-based backend auth to Cloud Run
- `adb reverse` for forwarding device localhost ports to the Mac during development
- Shared npm packages with local `file:` references across a monorepo
- Learned about `just` files a whole lot more than initially. Since I was used to Docker Compose but we are working with Flutter. I needed a way to unify all the different commands for running the app, the microservices, the tests, the linters, and the deployments. `just` files turned out to be a great solution for that, allowing me to define simple aliases for complex commands and keep everything organized in one place.

**What to follow up with:**
- Will improve the UX/UI to loose this generic setup that I learned from the docs/videos.
- Pagination on the home feed and journalist profile article list (an easy one).
- Consider additional alternatives that I may be missing in hindsight of these huge triple services. Will probably run it through v0 from Vercel to see what it comes up with (besides the UI improvements that gets two birds with one stone).

---

## Checkpoint 3 — Bug Fixes, Badge UX, and Production Hardening

**State of the project:** All AI badges (fact-check, bias, community votes) are now visible on the home feed for every article — not just on the article detail page — and the fact-checker pipeline runs reliably end-to-end in production.

**What was fixed:**

*Fact-checker pipeline not completing*

The pipeline would start, call the LLM, and then silently crash before writing the result to Firestore. The root cause was subtle: the `fact-checker` service called `articles.update({ badgeFactCheck })`, but `Firestore.update()` throws `NOT_FOUND` when the document does not exist. External (News API) articles have no Firestore document, so every external article caused the service to crash at the last step. The fix was a one-line change: `set({ badgeFactCheck }, { merge: true })`. `set+merge` is a true upsert — it creates the document if absent and patches if present — which is the semantically correct operation here.

*Badge latency in the home feed*

After fixing the pipeline, badges were written to Firestore correctly but did not appear in the home feed until the user force-reloaded the app. The problem was architectural: `RemoteArticlesBloc` loads article entities once on startup via a single Firestore `.get()`, long before the fact-check and bias-report results arrive. Those results are fetched separately and stored in `RemoteArticlesDone.factChecks` and `.biasReports`, but the bloc was never patching the badge strings back onto the article entities before emitting state. The fix was to extend `_fetchAndEmitResults` so that after fetching results it derives `badgeFactCheck` (from `botCheck.flaggedSentencesPercent >= 0.3`) and `badgeBias` (from `biasReport.politicalLean` with ±0.33 thresholds) and copies them onto the article entities in the state — so the feed renders badges immediately when results arrive, with no reload required.

*Badges hidden behind a journalist-only gate*

Both `ArticleWidget` (the standard list tile) and `FeaturedArticleCard` (the hero card) had an `isJournalistArticle &&` guard that prevented any badge row from rendering for external News API articles. Since external articles are precisely the ones most likely to be fact-checked by the AI pipeline, this gate was removed from both widgets so all articles show badges when data is available.

**What was built:**

*UI overhaul:*

The generic starter UI that shipped with the initial implementation was replaced with a custom design more appropriate for a news product:
- **App bar** — branded "NewsLab" wordmark with an orange (`#E8621A`) accent that carries through the entire theme (selected chips, active states, action buttons).
- **Featured card** — the first article in the home feed is now a large hero card with a full-bleed thumbnail, gradient overlay, category label, and a reading-time estimate, replacing the plain list tile it shared with every other article.
- **Article tile** — redesigned with a compact thumbnail on the right, bold title, source line, and date; the generic `ListTile` was removed entirely.
- **Journalist profile page** — rebuilt to show an avatar, article count, a 7-day views sparkline chart, a bias-distribution spectrum bar, and a credibility score alongside the article list; the old flat stats grid was removed.
- **Article detail page** — redesigned community vote section with three clearly labelled vote buttons, live vote counts, and a loading skeleton while the fact-check result loads; the bias report section was replaced with a visual spectrum slider widget.
- **Empty states** — a shared `EmptyStateWidget` with a contextual icon and hint message was added across the home feed, saved articles, explore page, and journalist profile list, replacing the bare "no results" text.
- **Animated list deletions** — article deletions on the journalist profile page now animate out with a slide + fade transition using `AnimatedList`.
- **Breaking news ticker** — a scrolling horizontal ticker above the feed shows the latest headline.

*Badge infrastructure on top of the UI overhaul:*

- `_TileBadges` and `_SmallChip` widgets added to `article_tile.dart`, rendering the bias chip, fact-check chip (with icon), and community vote chip below the article date for any article that has at least one badge or community vote.
- `static String _biasLabel(BiasReportEntity)` helper added to `RemoteArticlesBloc` to centralise the ±0.33 threshold logic so it matches the backend exactly.
- `RefreshFactChecks` event dispatched via `.then()` on each `Navigator.pushNamed()` call that opens the article detail page, so the feed re-checks for new badge results as soon as the user returns.

**What I learned at this checkpoint:**

- **Firestore `update` vs `set+merge`:** `update` is a strict patch on an existing document; `set+merge` is a safe upsert. For services that may run before the client has created the document, `set+merge` is almost always the right choice.
- **Two-system badge problem:** When two separate data fetches need to be reconciled into one UI state (article entities vs. fact-check results), the reconciliation must happen explicitly in the BLoC before emitting state — waiting for the user to reload is not acceptable UX.
- **Denormalized badge fields as a trade-off:** Writing `badgeFactCheck` and `badgeBias` directly onto `articles` documents means the home feed can display badges in a single Firestore read. The trade-off is that if the badge logic ever changes, a migration script is needed to backfill the stored values. For a read-heavy feed this is the right trade-off.
- **Widget gate audits:** Feature flags and conditional rendering guards (`isJournalistArticle &&`) need regular review to ensure they reflect current requirements. It is easy to add a guard during initial development that becomes a silent blocker as the feature expands.
