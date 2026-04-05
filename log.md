# Architectural Pattern Analysis — Active Changes
_Date: 2026-04-05 — verified against project guidelines_

Findings below are validated against `APP_ARCHITECTURE.md`, `ARCHITECTURE_VIOLATIONS.md`, `CODING_GUIDELINES.md`, and `FACT_CHECK_FEATURE.md`.

---

## Pattern Family A — Model / Entity separation

### Canonical rule (guideline 1.3)
> 1.3.1 ALWAYS EXTEND AN ENTITY from the `domain/entities` folder.
> 1.3.2 Contain a `toEntity()` function for conversion to entities.
> 1.3.3 Contain a `fromRawData` factory for conversion from external API data to model.

### What the codebase does

| Model | Extends entity? | Has `toEntity()`? | Has factory ctor? |
|---|---|---|---|
| `ArticleModel` | No (separate class) | ✅ Yes | ✅ `fromJson` / `fromEntity` |
| `UserModel` | ✅ Yes | ❌ No | ✅ `fromFirebaseUser` |
| `ArticleCategoryModel` | ✅ Yes | ❌ No | ✅ `fromFirestore` |
| `BotCheckModel` | ✅ Yes | ❌ No | ✅ `fromMap` |
| `CommunityCheckModel` | ✅ Yes | ❌ No | ✅ `fromMap` |
| `FactCheckModel` | ✅ Yes | ❌ No | ✅ `fromFirestore` |

### Verdict

`ArticleModel` **violates 1.3.1** — it is a separate class, not an extension of the entity. It was built this way because Floor ORM requires an `@Entity` annotation with different field names, but the guideline has no exceptions. It should still extend `ArticleEntity`. (Pre-existing violation, not introduced in this diff.)

All other models correctly extend their entity (1.3.1 ✅). However, **none of them implement `toEntity()`** (1.3.2 ❌). The new fact_check models introduced this gap and the existing `UserModel` / `ArticleCategoryModel` already had it. The `FactCheckRepositoryImpl` returns `Success(model)` passing a data-layer object through the domain boundary — while the declared type `Result<FactCheckEntity>` is satisfied via inheritance, the intent of 1.3.2 is that the repository calls `model.toEntity()` to return a clean entity.

### Fixes required

Add `toEntity()` to all models that extend entities. For the new fact_check models:

**`BotCheckModel`**
```dart
BotCheckEntity toEntity() => BotCheckEntity(
  flaggedSentencesPercent: flaggedSentencesPercent,
  confidenceScore: confidenceScore,
  checkedAt: checkedAt,
);
```

**`CommunityCheckModel`**
```dart
CommunityCheckEntity toEntity() => CommunityCheckEntity(
  accurateVotes: accurateVotes,
  inaccurateVotes: inaccurateVotes,
  unsureVotes: unsureVotes,
  userVote: userVote,
);
```

**`FactCheckModel`**
```dart
FactCheckEntity toEntity() => FactCheckEntity(
  articleId: articleId,
  botCheck: (botCheck as BotCheckModel?)?.toEntity(),
  communityCheck: (communityCheck as CommunityCheckModel?)?.toEntity(),
);
```

Then the repository impl uses the converter:
```dart
return Success(model.toEntity());
```

`UserModel` and `ArticleCategoryModel` have the same gap — apply the same fix as a Boy Scout cleanup (CG1).

---

## Pattern Family B — UseCase interface contract

### Canonical rule (APP_ARCHITECTURE.md Business Layer)
> Use Cases: implements an abstract class with a `call` method, utilizing Repository Interfaces to execute specific functions.

The abstract classes are `UseCase<T, P>` and `NoParamsUseCase<T>` in `lib/core/usecase/usecase.dart`.

### What the codebase does

| Use case | Implements interface? |
|---|---|
| `GetArticleUseCase` | ✅ `UseCase<Result<List<ArticleEntity>>, GetArticlesParams>` |
| `SaveArticleUseCase` | ✅ `UseCase<Result<void>, ArticleEntity>` |
| `RemoveArticleUseCase` | ✅ `UseCase<Result<void>, ArticleEntity>` |
| `GetSavedArticleUseCase` | ✅ `NoParamsUseCase<Result<List<ArticleEntity>>>` |
| `UpdateArticleUseCase` | ✅ `UseCase<Result<void>, UpdateArticleParams>` |
| `DeleteArticleUseCase` | ✅ `UseCase<Result<void>, String>` |
| `GetJournalistArticlesUseCase` | ✅ `UseCase<Result<List<ArticleEntity>>, String>` |
| `SignInUseCase` | ❌ plain class |
| `SignOutUseCase` | ❌ plain class |
| `GetCurrentUserUseCase` | ❌ synchronous — cannot implement either interface |
| `GetFactCheckUseCase` | ❌ plain class (NEW) |
| `SubmitCommunityVoteUseCase` | ❌ plain class (NEW) |

The auth feature established the precedent of skipping the interface. The new fact_check feature copied it.

### Fixes

**`sign_in.dart`**: `class SignInUseCase implements UseCase<UserEntity, SignInParams>`

**`sign_out.dart`**: `class SignOutUseCase implements NoParamsUseCase<void>`

**`get_fact_check_usecase.dart`**: `class GetFactCheckUseCase implements UseCase<Result<FactCheckEntity>, GetFactCheckParams>`

**`submit_community_vote_usecase.dart`**: `class SubmitCommunityVoteUseCase implements UseCase<Result<void>, SubmitVoteParams>`

`GetCurrentUserUseCase` is synchronous and cannot implement either existing interface. It is an accepted exception; document with a comment.

---

## Pattern Family C — Params object placement + dependency direction

### Canonical rule (APP_ARCHITECTURE.md Business Layer section 2)
> **Params** — classes that represent the parameters of the use_cases.

Params belong in the business layer, co-located with the use case that owns them.

### What the codebase does

| Params class | Where it lives | Data source imports it? |
|---|---|---|
| `GetArticlesParams` | Use case file ✅ | No |
| `SignInParams` | Use case file ✅ | No |
| `UploadArticleParams` | Use case file ✅ | No |
| `GetFactCheckParams` | Use case file ✅ | No |
| `UpdateArticleParams` | Repository file ⚠️ | No — data source accepts primitives |
| `SubmitVoteParams` | Repository file ⚠️ | **Yes** ← violation |

`UpdateArticleParams` in the repository is a pre-existing deviation. It does not cause a dependency violation because the data source accepts individual primitives. Lower priority to move.

`SubmitVoteParams` in the repository causes `FactCheckRemoteDataSource` to import a domain-layer type — reversing the data→domain dependency direction. Data sources must only import from the domain layer for entity types used as return values, not for input params (ARCHITECTURE_VIOLATIONS 1.1 spirit).

### Fix

Move `SubmitVoteParams` to `submit_community_vote_usecase.dart`. Change the data source interface and impl to accept primitives:

**`fact_check_remote_data_source.dart`**
```dart
abstract class FactCheckRemoteDataSource {
  Future<FactCheckModel> getFactCheck({required String articleId, required String userId});
  Future<void> submitVote({required String articleId, required String userId, required CommunityVote vote});
}
```

**`fact_check_repository_impl.dart`** (translates from domain params to primitives)
```dart
@override
Future<Result<void>> submitVote(SubmitVoteParams params) async {
  try {
    await _dataSource.submitVote(
      articleId: params.articleId,
      userId: params.userId,
      vote: params.vote,
    );
    return const Success(null);
  } on Exception catch (e) {
    return Failure(e);
  }
}
```

---

## Pattern Family D — `copyWith` for nullable fields

### Canonical rule
Standard `copyWith` contract: `field: newValue ?? this.field`. When a field may need to be explicitly cleared to null, add a boolean flag but keep the fallback:
```dart
field: clearField ? null : (newValue ?? this.field),
```

### What the codebase does

`CommunityCheckEntity.copyWith` — **correct**:
```dart
userVote: clearUserVote ? null : (userVote ?? this.userVote),
```

`ArticleCategoryLoaded.copyWith` — **broken** (regression introduced in this diff):
```dart
selected: clearSelected ? null : selected,  // missing ?? this.selected
```

Any caller of `state.copyWith(categories: newList)` without passing `selected` will silently lose the selection.

### Fix

**`article_category_state.dart`**
```dart
selected: clearSelected ? null : (selected ?? this.selected),
```

---

## Bugs (guideline-confirmed, must fix)

### B1 — Firestore rules block all vote writes [HIGH]

**File:** `backend/firestore.rules`

The `submitVote` transaction writes to the parent `fact_checks/{articleId}` document to update counters. No `allow write` exists on that path. Every vote submission fails silently. AC-5 cannot be satisfied.

```javascript
match /fact_checks/{articleId} {
  allow read: if true;
  allow write: if request.auth != null;  // ADD THIS

  match /votes/{userId} {
    allow read:  if request.auth != null && request.auth.uid == userId;
    allow write: if request.auth != null && request.auth.uid == userId;
  }
}
```

### B2 — Server counter double-increments on re-vote [HIGH]

**File:** `fact_check_remote_data_source.dart`

The transaction always calls `FieldValue.increment(1)` even when `previousVote == params.vote`. Client-side `_applyOptimisticVote` correctly no-ops, masking the corruption in the UI. Violates AC-6 ("the user cannot have more than one active vote").

```dart
if (voteSnap.exists) {
  final previousVote = (voteSnap.data()?['vote'] as String?).toCommunityVote();
  if (previousVote == params.vote) return; // same vote — no-op
  // ... decrement old vote, then fall through to increment new vote
}
```

### B3 — `FactCheckBloc` in list tiles violates AC-8 [HIGH]

**File:** `article_tile.dart`

AC-8 explicitly states: "`FactCheckBloc` is scoped to the article detail screen — it is not registered globally in the DI container." The current code creates one `FactCheckBloc` per tile, firing 2 Firestore reads per visible article on every page load with `userId: ''` (always unauthenticated).

Fix: remove `BlocProvider` and `FactCheckBadges` from `ArticleTile` entirely. Badges are shown on the detail screen, which is the designed scope.

### B4 — Empty `articleId` dispatched to Firestore [MEDIUM]

**File:** `article_detail.dart`

When `article?.remoteId` is null, `articleId = ''` and `LoadFactCheck` fires anyway, hitting an invalid Firestore path. AC-7 says dispatch with `article's remoteId` — guard when absent.

```dart
if (articleId.isNotEmpty) {
  ..add(LoadFactCheck(articleId: articleId, userId: userId))
}
```

---

## Smells (clean code guidelines)

### S1 — Use case invoked synchronously inside `build()` [CG 3.6 — Command Query Separation]

**File:** `article_detail.dart`

```dart
final userId = sl<GetCurrentUserUseCase>()()?.uid ?? '';
```

Bypasses the reactive auth model. Use `context.read<AuthBloc>().state` instead — consistent with the rest of the presentation layer and reactive to sign-out.

### S2 — Silent exception swallow without logging [CG 3.3 — SRP]

**File:** `article_repository_impl.dart`

```dart
} on Exception catch (e) {
  debugPrint('[ArticleRepository] NewsAPI unavailable: $e');
}
```

### S3 — `FactCheckSeeder` has no debug-mode guard [Risk]

**File:** `dev/fact_check_seeder.dart`

```dart
assert(kDebugMode, 'FactCheckSeeder must not run in production');
```

### S4 — `_formatDate` copy-pasted four times [CG 1 — Boy Scout Rule]

`article_detail.dart`, `article_tile.dart`, `journalist_profile_page.dart`, `bot_check_badge.dart`. Extract to `lib/core/utils/date_formatter.dart`.

---

## Fix priority order

| Priority | Item | Guideline | File(s) |
|---|---|---|---|
| 1 | **B1** Firestore rules `allow write` | AC-5 blocked | `firestore.rules` |
| 2 | **B2** Re-vote double-increment | AC-6 violated | `fact_check_remote_data_source.dart` |
| 3 | **B3** Remove `FactCheckBloc` from tiles | AC-8 violated | `article_tile.dart` |
| 4 | **D** `copyWith` fallback regression | correctness | `article_category_state.dart` |
| 5 | **A** Add `toEntity()` to fact_check models | 1.3.2 | `fact_check_model.dart` + repository impl |
| 6 | **C** Data source accepts primitives, not domain params | layer separation | `fact_check_remote_data_source.dart`, `fact_check_repository_impl.dart` |
| 7 | **B** `UseCase` interface on new use cases | architecture | `get_fact_check_usecase.dart`, `submit_community_vote_usecase.dart` |
| 8 | **B** `UseCase` interface on auth use cases | CG 2.1 conventions | `sign_in.dart`, `sign_out.dart` |
| 9 | **B4** Empty `articleId` guard | AC-7 | `article_detail.dart` |
| 10 | **S1** Use case in `build()` | CG 3.6 | `article_detail.dart` |
| 11 | **S2** Silent exception logging | maintainability | `article_repository_impl.dart` |
| 12 | **S3** Seeder debug guard | risk | `fact_check_seeder.dart` |
| 13 | **S4** Shared date formatter | CG 1 | `bot_check_badge.dart` + 3 others |
| — | **Pre-existing** `UserModel` / `ArticleCategoryModel` missing `toEntity()` | 1.3.2 | Boy Scout fix |
| — | **Pre-existing** `ArticleModel` does not extend entity | 1.3.1 | separate refactor, Floor constraints complicate it |
