# Learning Journey

A running log of checkpoints as the project progresses. Each checkpoint captures what was learned, what was built, and what came next.

---

## Checkpoint 1 — Minimum Delivery Complete

**State of the project:** All acceptance criteria in `ACCEPTANCE_CRITERIA.md` are met. The app compiles and runs on Android and macOS.

**What was built:**
- Firebase project configured (Firestore, Storage, Auth — email/password)
- Firestore schema designed and documented (`backend/docs/DB_SCHEMA.md`)
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

**What we may follow up with:**
- Article editing and deletion UI for news that have not been published yet.
- Pagination for both the API and Firestore queries
- Optimistic UI on publish

---

## Checkpoint 2 — *(to be filled)*

---

## Checkpoint 3 — *(to be filled)*

