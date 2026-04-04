# Acceptance Criteria — News Lab (Journalist Upload Feature)

## Context
A Flutter + Firebase + BLoC news app. The existing codebase (`features/daily_news`) already fetches articles from a remote news API and lets users bookmark them locally (Floor SQLite). The new feature adds the ability for a **journalist** to upload their own articles to Firebase Firestore, with thumbnail images stored in Firebase Cloud Storage — all wired through Clean Architecture.

---

## Feature 1: Backend — Firestore Schema & Rules

### AC-B1: Article Schema documented
- `backend/docs/DB_SCHEMA.md` exists and describes the `articles` Firestore collection
- Schema fields match those of the existing `ArticleEntity` plus Firebase-specific additions:
  | Field | Type | Notes |
  |---|---|---|
  | `id` | string (auto doc id) | Firestore document ID |
  | `author` | string | journalist's display name |
  | `authorId` | string | Firebase Auth UID |
  | `title` | string | required, non-empty |
  | `description` | string | subtitle / summary |
  | `content` | string | full article body |
  | `thumbnailUrl` | string | path in Cloud Storage (`media/articles/<filename>`) |
  | `sourceUrl` | string | optional external reference |
  | `publishedAt` | timestamp | Firestore server timestamp |
  | `category` | string | optional tag (e.g. "technology") |

### AC-B2: Firebase project configured
- Firebase project has Firestore, Cloud Storage, and Auth enabled
- `.firebaserc` contains the correct project ID
- `firebase emulators:start` launches without errors

### AC-B3: Firestore security rules enforced
- Unauthenticated users can **read** published articles (`get` / `list`)
- Only authenticated users can **create** an article document
- An authenticated user can only **update / delete** their own documents (`authorId == request.auth.uid`)
- The `thumbnailUrl` must point to the `media/articles/` path
- Rules are deployed via `firebase deploy` with no errors

### AC-B4: Cloud Storage rules enforced
- Anyone can read files under `media/articles/`
- Only authenticated users can write to `media/articles/`

---

## Feature 2: Frontend — Journalist Upload Flow

### AC-F1: Firebase connected to Flutter
- `google-services.json` / `GoogleService-Info.plist` are in place (not committed, added to `.gitignore`)
- `firebase_core` initialised in `main.dart` before `runApp`
- App compiles and runs without Firebase errors

### AC-F2: Auth (Journalist Identity)
- A journalist can sign in with **Email + Password** via Firebase Authentication
- A journalist can sign out
- Navigation guards prevent unauthenticated users from reaching the upload screen
- Auth state is managed by a dedicated BLoC (`AuthBloc` / `AuthCubit`) inside `features/auth/presentation/bloc`

### AC-F3: Domain layer — `publish_article` feature
- `ArticleEntity` in the domain layer contains all fields from AC-B1 (pure Dart, no Firebase imports)
- `UploadArticleParams` class holds: title, description, content, author, authorId, localImagePath, category
- `UploadArticleUseCase` implements the abstract `UseCase<void, UploadArticleParams>` interface from `core/usecase`
- `ArticleRepository` (abstract, domain layer) declares `uploadArticle(UploadArticleParams)`
- No Firebase / Flutter package imports exist in `domain/`

### AC-F4: Data layer — `publish_article` feature
- `ArticleFirestoreDataSource` uploads document to the `articles` Firestore collection
- `ArticleStorageDataSource` uploads a local image file to `media/articles/<uuid>` and returns the download URL
- `ArticleModel` extends `ArticleEntity` with `fromFirestore` and `toFirestore` factory/methods
- `ArticleRepositoryImpl` implements `ArticleRepository`; orchestrates storage upload then Firestore write
- All Firebase-specific code lives exclusively in the data layer

### AC-F5: Presentation layer — Upload screen
- An "Upload Article" screen exists, accessible from the home screen for authenticated users only
- Form contains: Title (required), Description (required), Content (required), Category (optional), Thumbnail picker (required)
- Image picker opens device gallery; selected thumbnail previewed before submission
- A "Publish" button triggers `UploadArticleBloc`
- Loading state: button shows a spinner, form inputs are disabled
- Success state: user navigated back / shown a success message
- Error state: user shown an inline error message without leaving the screen
- Validation: empty required fields show inline error text before any network call

### AC-F6: Published articles appear in the app
- After successful upload, the home feed includes the newly published article on next fetch
- The existing `daily_news` feed is not broken

---

## Feature 3: Clean Architecture Compliance

### AC-A1: Layer isolation
- `domain/` has zero imports from `data/`, `presentation/`, or any Firebase/Flutter package
- `presentation/` imports only from `domain/` (use cases, entities) and `core/`
- `data/` imports only from `domain/` and Firebase packages

### AC-A2: Folder structure matches spec
```
features/
  auth/
    data/  domain/  presentation/
  publish_article/
    data/  domain/  presentation/
```
The existing `daily_news` feature is untouched structurally.

### AC-A3: BLoC pattern followed
- Each BLoC has a corresponding `State`, `Event` (or Cubit with state) file
- No business logic lives inside Widget `build` methods

---

## Out of Scope (Day 1)
- Article editing / deletion UI (backend rules support it, UI is Extra)
- Journalist profile page
- Comments, likes, or social features
- Push notifications
- Full test coverage (unit tests for use cases recommended but not blocking)

---

## Day 1 Sequence (suggested order to be fully operational by EOD)

| # | Task | Layer |
|---|---|---|
| 1 | Design & write `DB_SCHEMA.md` | Backend |
| 2 | Set up Firebase project + emulator | Backend |
| 3 | Write & deploy Firestore + Storage rules | Backend |
| 4 | Connect Firebase to Flutter app | Frontend setup |
| 5 | Implement `auth` feature (domain → data → presentation) | Frontend |
| 6 | Implement `publish_article` domain layer with mock data | Frontend |
| 7 | Wire `UploadArticleBloc` + Upload screen UI | Frontend |
| 8 | Implement data layer (Firestore + Storage data sources) | Frontend |
| 9 | Replace mock with real data sources in DI (`injection_container.dart`) | Frontend |
| 10 | Smoke test full upload flow end-to-end | QA |
