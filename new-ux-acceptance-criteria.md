# NewsLab UX Improvements — Acceptance Criteria

> **Source:** `new-ux-improvements.md` (38 items from React prototype comparison)
> **Target:** `frontend/` (Flutter) + Firestore schema + existing NestJS microservices
> **Date:** 2026-04-06

---

## Architecture & Code Quality Requirements

> Reference: `starter-project/docs/APP_ARCHITECTURE.md`, `ARCHITECTURE_VIOLATIONS.md`, `CODING_GUIDELINES.md`

Every feature in this document **must** comply with the following rules. PRs that violate them will be rejected.

### Clean Folder Structure (mandatory for every new feature)

Every new feature module must follow this exact structure under `lib/features/{feature}/` or `lib/shared/{feature}/`:

```
{feature}/
├── data/
│   ├── data_sources/    # ONLY place to import Firebase, Dio, etc.
│   ├── models/          # MUST extend a domain entity, include toEntity() + fromRawData()
│   └── repository/      # Named {RepositoryName}Impl, ALWAYS returns DataState<Type>
├── domain/
│   ├── entities/        # Pure Dart, no Flutter/Firebase imports
│   ├── repository/      # Abstract classes only — no implementation details
│   └── use_cases/       # One class = one operation, uses repository interfaces only
└── presentation/
    ├── bloc/            # ONLY place to call use cases — no repos, no data sources
    ├── screens/         # Delegates all logic to BLoCs
    └── widgets/         # Reusable, receives data via constructors
```

Cross-cutting data sources (e.g., `ViewTrackingRemoteDataSource`) that serve multiple features go under `lib/core/data/data_sources/`.

### Layer Isolation Rules (from ARCHITECTURE_VIOLATIONS.md)

| Rule | What it means |
|------|---------------|
| **Domain imports nothing** | The `domain/` layer is pure Dart. Zero imports from `data/`, `presentation/`, Flutter, Firebase, or any external package (violation 2.1.1) |
| **Presentation → Domain only** | Screens and BLoCs import from `domain/` (use cases, entities). Never from `data/` (violation 3.1.1) |
| **Data → Domain only** | Data sources, models, and repo impls import from `domain/` (entities, repo interfaces). Never from `presentation/` (violation 1.1.1) |
| **BLoCs own use case calls** | BLoCs are the ONLY place that call use cases (violation 3.2.2, 3.2.3). Screens/widgets never call use cases directly |
| **Data sources own external calls** | Firestore, Dio, Storage, and any external SDK are imported ONLY in data sources (violation 1.2.3, 1.2.4) |
| **Models extend entities** | Every model in `data/models/` must `extends` the corresponding entity and include `toEntity()` + `factory fromRawData()` (violations 1.3.1–1.3.3) |
| **Repo impls named {Name}Impl** | Repository implementation classes follow the `{InterfaceName}Impl` convention (violation 1.4.1) |

### Coding Guidelines (from CODING_GUIDELINES.md)

| Guideline | Application to this work |
|-----------|--------------------------|
| **Meaningful names** (CG2) | New BLoCs, use cases, entities, and widgets use intention-revealing names. Follow existing naming conventions (e.g., `GetTrendingArticlesUseCase`, `ViewTrackingRemoteDataSource`, `BiasSpectrumWidget`) |
| **Small functions** (CG3) | Max nesting depth of 2. Functions do one thing. Prefer many small functions over few large ones |
| **Low arguments** (CG3.5) | Use Params classes for use cases with 2+ parameters (e.g., `TrackViewParams(articleId, userId)`) |
| **Command-Query Separation** (CG3.6) | Functions either mutate state OR return data, not both |
| **Small classes, single responsibility** (CG5) | One BLoC per concern (e.g., `TrendingArticlesBloc` is separate from `BiasLandscapeBloc`) |
| **Abstract classes for isolation** (CG6) | All repository interfaces are abstract. New data sources should also have abstract interfaces in the domain layer |
| **Boy Scout Rule** (CG1) | If you touch existing code, leave it cleaner. If existing code near your changes lacks tests or has poor naming, improve it |

### Dependency Injection

- All new data sources, repositories, use cases, and BLoCs **must** be registered in `injection_container.dart`
- Data sources and repositories: register as **singletons** (`registerSingleton` or `registerLazySingleton`)
- BLoCs: register as **factories** (`registerFactory`) so each route gets a fresh instance
- Follow the existing registration order: data sources → repositories → use cases → BLoCs

### What This Work Does NOT Require

- **TDD is not required** for this project
- No pixel-perfect match to the React prototype — adapt to Flutter/Material patterns

---

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| **No new microservice** | New data needs (views, trending, stats) are aggregation concerns handled by Firestore directly. Two minor changes to existing services (denormalized badge writes + bias landscape counter) |
| **Firestore-first** | View tracking, trending queries, profile stats, and bias landscape use Firestore writes + security rules + AggregateQuery |
| **Denormalize for feed performance** | Badge data (bias lean, fact-check status) is written onto `articles/{id}` by existing services — feed cards read badges for free, zero extra queries |
| **Materialized counters over scans** | Bias landscape stats and author daily views use pre-aggregated counters, not runtime collection scans |
| **On-demand analysis only** | AI analysis (fact-check, bias) is triggered manually in the article detail screen. News API articles never show badges in feed cards — analysis data only exists for articles a user has explicitly checked |
| **New libraries allowed (necessary only)** | `share_plus` (native share sheet), `url_launcher` (external links) |
| **Reuse emotionalLanguageScore as confidence** | The polarizer's existing `emotionalLanguageScore` (0–1) maps directly to the "confidence %" concept — no service change needed |
| **Breaking news = most recent News API article** | No new Firestore collection; resolved client-side from existing News API feed |
| **Discard #31 (mobile viewport shell)** | App targets mobile only — web frame simulation not needed |
| **Adapt, don't copy** | Recycle existing Flutter components and Material patterns; match the React prototype's UX intent, not its pixel layout |

---

## Firestore Schema Additions

These collections/fields must exist before feature work begins.

### New collection: `article_views`

```
article_views/{articleId}
├── authorId: string            // denormalized — enables aggregate queries by author
├── viewCount: number           // incremented via FieldValue.increment(1)
├── lastViewedAt: timestamp
└── daily_views/{YYYY-MM-DD}    // subcollection
    └── count: number           // incremented per unique view that day
```

**Security rules:**
```
match /article_views/{articleId} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update: if request.auth != null
                && request.resource.data.viewCount == resource.data.viewCount + 1
                && request.resource.data.authorId == resource.data.authorId;  // authorId immutable

  match /daily_views/{day} {
    allow read: if true;
    allow write: if request.auth != null;
  }
}
```

### New collection: `author_daily_views`

Materialized view that aggregates daily views across all articles for a given author. Eliminates fan-out reads when rendering the 7-day chart on the Profile Analytics tab.

```
author_daily_views/{authorId}/days/{YYYY-MM-DD}
└── count: number               // incremented alongside article_views daily_views
```

**Security rules:**
```
match /author_daily_views/{authorId} {
  allow read: if true;

  match /days/{day} {
    allow read: if true;
    allow write: if request.auth != null;
  }
}
```

### New document: `stats/bias_landscape`

Materialized counters that track the global Left/Center/Right distribution. Updated by the `polarizer` service when it writes a bias report — avoids scanning all bias reports on every Explore screen load.

```
stats/bias_landscape
├── leftCount: number           // politicalLean < -0.33
├── centerCount: number         // politicalLean between -0.33 and 0.33
├── rightCount: number          // politicalLean > 0.33
└── totalCount: number
```

**Security rules:**
```
match /stats/{statId} {
  allow read: if true;
  allow write: if false;        // only writable by backend services (admin SDK)
}
```

### Denormalized badge fields on `articles`

When the `fact-checker` and `polarizer` services write analysis results, they also write a lightweight summary directly onto the source article document. This eliminates batch-fetching badges for feed cards.

```
articles/{articleId}
├── ... (existing fields)
├── badgeBias: string | null      // "left", "center", "right" — written by polarizer
└── badgeFactCheck: string | null  // "verified", "disputed", "unverified" — written by fact-checker
```

> **Service change required:** Both `fact-checker` and `polarizer` NestJS services must add a single Firestore write to `articles/{articleId}` when they persist their analysis results. This is a ~5-line change per service — update the existing Firestore write handler to also set the badge field on the article doc.

**Security rules:** The existing `articles` rules allow public read. Badge fields are written by backend services using the Firebase Admin SDK (bypasses rules), so no rule change is needed.

### Existing collection changes (display-only, no schema modification)

| Collection | Change | Purpose |
|------------|--------|---------|
| `fact_checks/{articleId}` | Read `communityCheck.accurateVotes` as "upvotes" and `inaccurateVotes` as "downvotes" | Profile stats (#24) — no schema change |
| Bias reports | Map existing `emotionalLanguageScore` field as "confidence %" in the UI | #11 — no schema change, display-only rename |

---

## Phases

Ordered by dependency: backend/infrastructure first, foundational UI second, feature screens third, polish last.

---

### Phase 1 — Data Infrastructure & Firestore

> Goal: all backend data contracts are in place so feature phases can build against real data.

#### 1.1 Article View Tracking

| ID | Criteria |
|----|----------|
| 1.1.1 | Create `article_views/{articleId}` collection with `authorId` (string), `viewCount` (number), and `lastViewedAt` (timestamp) fields. The `authorId` field is denormalized from the article document and set on first create — it must be immutable thereafter |
| 1.1.2 | Create `article_views/{articleId}/daily_views/{YYYY-MM-DD}` subcollection with `count` field |
| 1.1.3 | Create `author_daily_views/{authorId}/days/{YYYY-MM-DD}` collection — incremented alongside the article-level daily view in the same write operation |
| 1.1.4 | Deploy Firestore security rules per the schema section above: public read, authenticated increment-only write on `viewCount`, immutable `authorId` |
| 1.1.5 | In the Flutter app, create `ViewTrackingRemoteDataSource` under `core/data/data_sources/` that performs a Firestore **batched write**: (a) increment `article_views/{articleId}.viewCount`, (b) upsert today's `daily_views` doc, (c) upsert today's `author_daily_views/{authorId}/days` doc. All three writes in a single Firestore batch |
| 1.1.6 | Trigger view tracking when `ArticleDetailsView` is opened — **only for journalist-published articles** (those with a `remoteId`). News API articles do not generate view tracking data |
| 1.1.7 | Deduplicate: max 1 count per user per article per app session (in-memory `Set<String>` of tracked article IDs, cleared on app restart) |
| 1.1.8 | Register the data source, repository, and use case in `injection_container.dart` |
| 1.1.9 | **Smoke test:** After deploying Firestore security rules, manually verify that (a) an authenticated user can trigger a view, (b) all three documents are written atomically (article_views, daily_views, author_daily_views), (c) an unauthenticated user cannot write. This validates the batched write + security rules integration before building features on top |

#### 1.2 Denormalized Badge Writes (service changes)

| ID | Criteria |
|----|----------|
| 1.2.1 | **fact-checker service:** After writing to `fact_checks/{articleId}`, also set `articles/{articleId}.badgeFactCheck` to `"verified"` (if `flaggedSentencesPercent < 30`), `"disputed"` (if `>= 30`), or `"unverified"` (if analysis inconclusive). This is a single additional `firestore.doc().update()` call |
| 1.2.2 | **polarizer service:** After writing the bias report, also set `articles/{articleId}.badgeBias` to `"left"`, `"center"`, or `"right"` based on `politicalLean` thresholds (-0.33, +0.33). Single additional Firestore update |
| 1.2.3 | **polarizer service:** After writing the bias report, increment the appropriate counter on `stats/bias_landscape` (`leftCount`, `centerCount`, or `rightCount`) and `totalCount` using `FieldValue.increment(1)` |

#### 1.3 Aggregation Use Cases

| ID | Criteria |
|----|----------|
| 1.3.1 | Create `GetTrendingArticlesUseCase` — queries `article_views` ordered by `viewCount` descending, limit 10, then fetches corresponding article data. Requires composite Firestore index on `article_views(viewCount DESC)` |
| 1.3.2 | Create `GetAuthorStatsUseCase` — for a given `authorId`: (a) count of articles via Firestore `count()` on `articles` where `authorId`, (b) sum of views via Firestore `sum('viewCount')` on `article_views` where `authorId` — single aggregate query, no fan-out, (c) aggregate community votes from `fact_checks` for the author's article IDs — this is O(n) on article count (fan-out: fetch article IDs, then query each `fact_checks/{id}`). Acceptable for MVP scale. Add `// TODO: denormalize authorId onto fact_checks for O(1) aggregation when author article counts grow large` |
| 1.3.3 | Create `GetBiasLandscapeUseCase` — reads the single `stats/bias_landscape` document and computes percentages from the counters. **Does NOT scan individual bias reports** |
| 1.3.4 | Create `GetWeeklyViewsUseCase` — for a given `authorId`, reads the last 7 documents from `author_daily_views/{authorId}/days/` ordered by document ID descending. **Single collection read, no fan-out across articles** |

---

### Phase 2 — Navigation & App Shell Restructure

> Goal: the app's skeleton supports 4 top-level destinations before screens are built out.

| ID | Criteria |
|----|----------|
| 2.1 | Refactor `AppShell` bottom navigation from 2 tabs (Home, Explore) to 4 tabs: **Feed**, **Explore**, **Publish**, **Profile** |
| 2.2 | The Publish tab icon is visually elevated (larger, accented background) as a primary call-to-action — implemented using a custom `FloatingActionButton`-style widget embedded in the `BottomNavigationBar` |
| 2.3 | Tapping Publish when not authenticated redirects to the Login screen |
| 2.4 | Tapping Profile when not authenticated redirects to the Login screen |
| 2.5 | `IndexedStack` continues to preserve state across all 4 tabs. **Implement lazy-loading:** tabs that haven't been visited yet should not build their widget tree. Use a `List<bool> _hasVisited` flag array — on first tab selection, set the flag to `true` and build the child. Before first visit, render an empty `SizedBox`. This avoids holding Publish (image picker, controllers) and Profile (stats, charts, article list) in memory when the user has only visited the Feed |
| 2.6 | Remove the existing FAB for publishing from `DailyNews` screen since Publish now lives in the bottom nav |
| 2.7 | Remove the profile avatar / login button from the `DailyNews` AppBar since Profile is now a tab |
| 2.8 | Update `routes.dart` — remove standalone `/UploadArticle` and `/JournalistProfile` routes; these are now tab destinations. Keep `/ArticleDetails`, `/SavedArticles`, and `/Login` as push routes |

---

### Phase 3 — Authentication Improvements

> Items: #1, #3, #4

| ID | Criteria |
|----|----------|
| 3.1 | **Dual-mode toggle (#1):** `LoginPage` displays both Sign In and Create Account modes on the same screen. A toggle (segmented button or tab) switches between modes. In Create Account mode the form includes email, password, and confirm password fields. `AuthBloc` gains a `SignUpRequested` event that calls `FirebaseAuth.createUserWithEmailAndPassword` |
| 3.2 | **Forgot password (#3):** In Sign In mode, a "Forgot password?" text button appears below the password field. Tapping it shows a dialog/bottom sheet requesting the user's email, then calls `FirebaseAuth.sendPasswordResetEmail`. Display a confirmation message on success or an error on failure |
| 3.3 | **Terms & Privacy links (#4):** Below the form, display tappable "Terms of Service" and "Privacy Policy" text links. Tapping opens the respective URL via `url_launcher`. Add `url_launcher` to `pubspec.yaml` |
| 3.4 | All auth actions (sign in, sign up, forgot password) show an inline loading spinner on the action button while processing (ties into #38) |

---

### Phase 4 — Home Feed Enhancements

> Items: #5, #6, #7, #8

| ID | Criteria |
|----|----------|
| 4.1 | **Sticky blurred header (#8):** Convert the `DailyNews` AppBar into a `SliverAppBar` with `pinned: true` and a `BackdropFilter` (sigma ~10) for frosted-glass effect. The category filter bar scrolls with content but the header remains fixed |
| 4.2 | **Real-time search (#5):** Add a search icon in the header that expands into a `TextField` with `onChanged` callback. Filtering is applied client-side on the already-loaded article list (by title, case-insensitive). When the search field is cleared or collapsed, the full list is restored. Implement via a `SearchCubit` or local state in the widget |
| 4.3 | **Breaking news ticker (#6):** Below the category bar, display a horizontal ticker banner showing the title of the most recent article from the News API feed. The ticker auto-scrolls horizontally if the title overflows. Tapping it navigates to that article's detail view |
| 4.4 | **Featured article spotlight (#7):** The first article in the feed (after any search/category filter) renders as a larger hero card: full-width image with a bottom-to-top gradient overlay, category pill badge, title, and author overlaid on the image. Subsequent articles use the standard `ArticleTile` |

---

### Phase 5 — Article Detail Improvements

> Items: #9, #10, #11, #12, #13, #14

| ID | Criteria |
|----|----------|
| 5.1 | **Hero image with gradient (#14):** Article detail opens with a full-width image (if available) at the top. A linear gradient (transparent to background color) overlays the bottom third for text readability. Title and author are positioned over the gradient. If no image exists, fall back to the current layout |
| 5.2 | **Share button (#9):** Add a share icon button in the article header bar alongside the existing bookmark button. Tapping invokes `Share.share()` from `share_plus` with the article title and URL. Add `share_plus` to `pubspec.yaml` |
| 5.3 | **Bias spectrum visualization (#10):** Replace the current `BiasBadge` text label with a horizontal gradient bar widget (red-left to blue-right, with a neutral center). A positioned marker (circle/triangle) indicates the exact `politicalLean` value (-1 to +1). Labels "Left", "Center", "Right" appear below the bar |
| 5.4 | **Bias confidence percentage (#11):** Next to the bias spectrum bar, display the `emotionalLanguageScore` value formatted as a percentage (e.g., "73% confidence"). No backend change — this is a UI mapping of the existing field |
| 5.5 | **Collapsible analysis panels (#12):** Wrap the AI Fact-Check section, Bias Analysis section, and Similar Articles section each in an `ExpansionTile`. Default state: Fact-Check expanded, Bias and Similar collapsed. Each panel has a chevron icon that rotates on expand/collapse |
| 5.6 | **Vote styling (#13):** When a user selects "Credible" (accurate), the button background changes to green with white text and shows "You voted Credible". When "Disputed" (inaccurate) is selected, the button background changes to red. "Unsure" uses a neutral gray. The selected state persists (already backed by Firestore vote doc) |
| 5.7 | View tracking fires on screen open per Phase 1 spec (1.1.5) |

---

### Phase 6 — Article Cards

> Items: #32, #33, #34

| ID | Criteria |
|----|----------|
| 6.1 | **Featured card variant (#32):** Create a `FeaturedArticleCard` widget: full-width hero image, bottom gradient overlay, category pill, title, author, and timestamp overlaid. Used for the first article in feeds and in spotlight positions |
| 6.2 | **Compact card variant (#33):** Create a `CompactArticleCard` widget: small thumbnail on the left, title, author, and time on the right. Used in Similar Articles lists, trending lists, and search results |
| 6.3 | **Inline AI badges on cards (#34):** Both card variants display small badge chips for bias lean (e.g., "Left", "Center") and fact-check status (e.g., "Verified", "Disputed") **only for journalist-published articles** that have been analyzed. Badge data comes from the denormalized `badgeBias` and `badgeFactCheck` fields already present on the `articles/{id}` document (written by the services in Phase 1.2) — **no extra Firestore queries are needed**. News API articles never display badges (analysis is on-demand only via the detail screen). No new BLoC required; the existing `ArticleEntity` gains two optional nullable fields (`String? badgeBias`, `String? badgeFactCheck`) that the card widgets read directly |
| 6.4 | **Null-safe badge handling:** Badge fields will be `null` for articles that haven't been analyzed yet and for all News API articles. The `ArticleModel.fromRawData()` must handle missing fields gracefully (nullable, no crash). Card widgets check `article.badgeBias != null` before rendering the badge chip. When a field is unexpectedly null on a journalist article that should have been analyzed, log a warning via `debugPrint` for development visibility — do not throw or show an error to the user |

---

### Phase 7 — Explore Screen Improvements

> Items: #15, #16, #17, #18

| ID | Criteria |
|----|----------|
| 7.1 | **Color-coded category buttons (#18):** Category cards in the grid use warm-tone backgrounds (reds/oranges) for Politics and Business, and cool-tone backgrounds (blues/teals) for Tech and Science. Define a `categoryColorMap` in the theme or constants |
| 7.2 | **Trending articles list (#15):** Below the category grid, display a "Trending" section with a numbered list (1–10) of articles ranked by `viewCount` descending using `GetTrendingArticlesUseCase` from Phase 1. Each item uses the `CompactArticleCard` from Phase 6. Create a `TrendingArticlesBloc` |
| 7.3 | **Explore search (#17):** Add a search `TextField` at the top of the Explore screen that filters the trending articles list by title in real-time (client-side) |
| 7.4 | **Bias breakdown stats (#16):** Display three horizontal progress bars labeled Left / Center / Right with percentage values. Data sourced from `GetBiasLandscapeUseCase` (Phase 1.3.3) which reads the single `stats/bias_landscape` document — **1 Firestore read, not a collection scan**. Create a `BiasLandscapeCubit` |

---

### Phase 8 — Publish Flow Improvements

> Items: #19, #20, #21, #22, #23

| ID | Criteria |
|----|----------|
| 8.1 | **Two-step publish flow (#19):** Refactor `UploadArticlePage` into two steps using a `PageView` or `Stepper`. **Step 1:** headline, description, category selector, thumbnail picker. **Step 2:** article body (full content). A "Next" button advances from Step 1 to Step 2; a "Back" button returns. "Publish" button only appears on Step 2 |
| 8.2 | **Step indicator dots (#20):** Between the header and the form, display two animated dots indicating the current step (1 of 2). The active dot is larger/accented; the inactive dot is smaller/muted. Animate the transition |
| 8.3 | **Character counters (#21):** The headline field shows a live character counter (e.g., "42/120"). The description field shows "128/280". Exceeding the limit changes the counter to red and disables the "Next" button. Enforce via `TextEditingController` listeners |
| 8.4 | **AI analysis info callout (#22):** On Step 2, below the content field, display an informational `Card` with an info icon and text: "After publishing, AI will automatically analyze your article for bias and fact-check accuracy. Badges will appear on your article once analysis is complete." |
| 8.5 | **Success screen with auto-redirect (#23):** After successful publish, navigate to a confirmation screen showing a large check-circle icon, the article title, and two info lines ("Your article is now live" and "AI analysis will appear shortly"). After a 2-second delay, auto-navigate to the Feed tab. Include a "Go to Feed" button for immediate navigation |

---

### Phase 9 — Profile & Analytics

> Items: #24, #25, #26, #27, #28

| ID | Criteria |
|----|----------|
| 9.1 | **Stats overview grid (#24):** At the top of the Profile tab, display a 3-column grid showing: **Articles** (count of published articles), **Total Views** (sum from `article_views` where `authorId` — single aggregate query, no fan-out), **Upvotes** (sum of `accurateVotes` from `fact_checks` across the user's articles). Data from `GetAuthorStatsUseCase` (Phase 1.3.2). Create a `ProfileStatsBloc` |
| 9.2 | **Two-tab layout:** The Profile screen has two tabs: "My Articles" (existing article list) and "Analytics" (new). Use a `TabBar` + `TabBarView` |
| 9.3 | **Average credibility score (#26):** In the Analytics tab, display a large numeric score (0–100) representing the average `communityCheck.accurateVotes / totalVotes * 100` across the user's articles. Show "N/A" if no votes exist |
| 9.4 | **Bias profile badge (#25 partial):** In the Analytics tab, show the user's predominant bias lean (computed from the average `politicalLean` across their articles' bias reports) as a spectrum bar similar to #10 |
| 9.5 | **7-day views bar chart (#27):** In the Analytics tab, display a simple vertical bar chart showing daily views for the last 7 days. Data from `GetWeeklyViewsUseCase` (Phase 1.3.4) — reads 7 docs from `author_daily_views/{authorId}/days/`, **not** a fan-out across individual articles. Implement using a custom `CustomPainter` — no charting library needed for 7 static bars |
| 9.6 | **Inline edit modal (#28):** In "My Articles" tab, tapping "Edit" on an article opens a modal bottom sheet (not a new route) with pre-filled title and description fields. Saving updates the Firestore document and refreshes the list. Replace the current navigation to `EditArticlePage` |

---

### Phase 10 — General UX Polish

> Items: #35, #36, #37, #38

| ID | Criteria |
|----|----------|
| 10.1 | **Empty states (#35):** Every screen that can be empty (Feed with no results, Saved Articles with no bookmarks, Profile with no articles, Explore with no trending, search with no matches) shows a centered column: icon, primary message (e.g., "No articles yet"), secondary hint (e.g., "Articles you publish will appear here"). Create a reusable `EmptyStateWidget` |
| 10.2 | **Delete scale-down animation (#36):** When an article is deleted (from Profile) or a bookmark is removed (from Saved Articles), the item animates out with a scale-down (1.0 to 0.0) and opacity fade (1.0 to 0.0) over 300ms before being removed from the list. Use `AnimatedList` with a custom `SizeTransition` + `FadeTransition` |
| 10.3 | **Input focus rings (#37):** Update `app_themes.dart` to set `InputDecorationTheme.focusedBorder` with a 2px primary-color `OutlineInputBorder`. This applies globally to all `TextField` and `TextFormField` widgets |
| 10.4 | **Loading spinners on actions (#38):** All async action buttons (Sign In, Sign Up, Publish, Check Article, Polarize, Edit, Delete, Vote) display an inline `SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))` replacing the button label while the action is in progress. The button is disabled during loading. Each relevant BLoC must emit a `loading` state that the button widget observes |

---

## Cross-Cutting Concerns

| Concern | Guidance |
|---------|----------|
| **Clean architecture** | Every new feature follows the existing `data/domain/presentation` layer pattern. New use cases, repositories, and data sources must be registered in `injection_container.dart` |
| **No new microservices** | All new data needs (views, trending, stats, landscape) are served by Firestore. Two minor additions to existing `fact-checker` and `polarizer` services: denormalized badge writes + bias landscape counter increment |
| **New packages** | Only `share_plus` and `url_launcher` are added. The 7-day bar chart uses `CustomPainter`, not a charting library |
| **Existing component reuse** | Extend `ArticleTile`, `BiasBadge`, `FactCheckBadges`, and other existing widgets rather than building from scratch. Create new variants (Featured, Compact) as sibling widgets in the same directory |
| **Performance** | AI badges on feed cards use denormalized fields on the `articles` document — zero extra queries. Bias landscape reads 1 materialized document. Author stats use `authorId` on `article_views` for single aggregate queries. 7-day chart reads from `author_daily_views` (7 docs). View tracking deduplicates per session. Trending query is limited to 10 results |
| **On-demand only** | Fact-check and bias analysis is triggered manually per article in the detail screen. News API articles never show badges in feed — they have no analysis data unless a user explicitly triggers it |
| **Firestore indexes** | Composite indexes needed: `article_views(viewCount DESC)` for trending; `article_views(authorId, viewCount)` for author stats; `articles(authorId, publishedAt DESC)` for profile. Deploy via `firestore.indexes.json` |
| **Security rules** | All new collections (`article_views`, `daily_views`, `author_daily_views`) require security rules deployed before feature work. `stats/*` is read-only from client, writable only via Admin SDK. Rules must enforce authentication and prevent arbitrary writes |

---

## Dependency Graph (Phase Order)

```
Phase 1 (Data Infrastructure)
  └── Phase 2 (Navigation Shell)
        ├── Phase 3 (Auth) ─────────────────────────┐
        ├── Phase 4 (Home Feed) ────────────────────┤
        ├── Phase 5 (Article Detail) ───────────────┤
        │     └── Phase 6 (Article Cards) ──────────┤
        ├── Phase 7 (Explore) ── needs Phase 1, 6 ──┤
        ├── Phase 8 (Publish Flow) ─────────────────┤
        ├── Phase 9 (Profile) ── needs Phase 1 ─────┤
        └── Phase 10 (UX Polish) ── last, all screens must exist
```

**Parallelizable:** Phases 3, 4, 5, and 8 have no inter-dependencies and can be worked on concurrently after Phase 2 is complete. Phase 6 should land before Phase 7 (Explore uses CompactArticleCard). Phase 9 depends on Phase 1 aggregation use cases. Phase 10 is the final sweep.

---

## Deployment Note

This is an MVP in local development. All phases are developed as a single body of work. When complete, deployment order is:

```
1. Deploy Firestore security rules + indexes       (infra/firebase/)
2. Deploy updated fact-checker + polarizer services (services/)
3. Ship Flutter app                                 (frontend/)
```

Rules and indexes must be live before the app writes to new collections. Services must be updated before the app expects denormalized badge fields.

---

## Out of Scope

| Item | Reason |
|------|--------|
| #31 Mobile viewport shell | App targets mobile only — confirmed out of scope |
| New NestJS microservice | Firestore handles all new data needs; existing services get minor additions only |
| Polarizer LLM prompt changes | `emotionalLanguageScore` is reused as confidence — no LLM change needed |
| Batch-fetching badges from `fact_checks`/bias collections | Replaced by denormalized fields on `articles` documents — zero extra reads |
| Scanning all bias reports for landscape stats | Replaced by materialized `stats/bias_landscape` counter document |
| Fan-out reads for author view stats | Replaced by `authorId` on `article_views` (single aggregate query) and `author_daily_views` collection |
| Badges on News API article cards | News API articles are not analyzed unless a user triggers it on-demand — no badges shown in feed |
| Materializing `authorId` on `fact_checks` | Fan-out for upvote aggregation is acceptable at MVP scale; marked as future optimization |
| Data migration script | Existing Firestore data is already compatible; new fields are nullable and handled gracefully |
| Pixel-perfect React match | Flutter/Material adaptation is preferred |
