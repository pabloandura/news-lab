# Services Code Review

Architecture and code quality review of `fact-checker`, `polarizer`, and `sensemaker`.

---

## Critical Bugs

### `sensemaker` — `articleId` lookup against `sensemaker_articles` will never match

`ingest.service.ts` stores documents with `md5(url)` as the doc ID and never writes an `articleId` field. The query below always returns empty and silently falls through:

```typescript
// similar.service.ts
.where('articleId', '==', dto.articleId) // field never stored → always empty
```

The fallback to the `articles` collection only works for internally published articles, not for sensemaker-ingested ones.

### `sensemaker` — `similarityScore` is a fabricated rank-based approximation

Firestore's `findNearest` returns actual distance metadata per document, but the service ignores it and invents a score from ranking position:

```typescript
// similar.service.ts
const similarityScore = Math.max(0, 1 - index * (1 / TOP_N)); // position-derived, not real cosine distance
```

The real distance is available on `VectorQueryDocumentSnapshot` and should be used directly.

### `fact-checker` + `polarizer` — Test specs import a non-existent `VertexService`

Both spec files mock `from '../vertex/vertex.service.js'`, which does not exist. The real injectable is `LlmService`. These specs fail to compile and never run.

```typescript
// fact-check.service.spec.ts, polarize.service.spec.ts
{ provide: VertexService, useValue: mockVertexService } // VertexService does not exist
```

---

## Design Issues

### All services — `LlmService` / `EmbeddingService` violate SRP with inline `NODE_ENV` branching

Dev/prod switching lives inside the service body via a direct `process.env.NODE_ENV` read, bypassing the `ConfigService` used everywhere else. The correct NestJS pattern is two implementations behind an interface, selected at the module level:

```
LlmModule → providers: [isDev ? OllamaLlmService : VertexLlmService]
            exports: [LlmService] (abstract / injection token)
```

### `sensemaker` — GCP auth client recreated on every `embed()` call

The dynamic import, `GoogleAuth` construction, and `getClient()` call happen on every single vector embedding request in the production path:

```typescript
// embedding.service.ts — runs per request
const { GoogleAuth } = await import('google-auth-library');
const auth = new GoogleAuth({ scopes: '...' });
const client = await auth.getClient();
```

The auth client should be initialised once in `onApplicationBootstrap()` and stored as an instance field.

### All services — dead NestJS scaffold files

`app.controller.ts` and `app.service.ts` exist in all three services but are not registered in any `AppModule`. They are pure boilerplate left over from `nest new` and should be deleted.

### `fact-checker` — `ClaimBusterService` API URL hardcoded

```typescript
const CLAIMBUSTER_API_URL = 'https://idir.uta.edu/api/v1/factcheck/claims/';
```

Should be part of `AppConfig` so it can be overridden via environment variable without a code change.

### `sensemaker` — NewsAPI key sent in URL query string

```typescript
const url = `https://newsapi.org/v2/top-headlines?...&apiKey=${key}`;
```

API keys in URLs appear in server access logs and HTTP referer headers. Should be sent as an `X-Api-Key` header instead.

### `polarizer` — raw LLM response logged at `log` level

```typescript
this.logger.log(`Raw LLM response: ${raw}`); // can be thousands of characters in production
```

Should be `this.logger.debug(...)`.

---

## Summary

| Service | Severity | Issue | Status |
|---|---|---|---|
| `sensemaker` | **Bug** | `articleId` field query on `sensemaker_articles` never matches | ✅ Fixed |
| `sensemaker` | **Bug** | `similarityScore` uses rank index, not real cosine distance | ✅ Fixed |
| `fact-checker`, `polarizer` | **Bug** | Specs reference non-existent `VertexService` — never compile | ✅ Fixed |
| all 3 | Design | `LlmService`/`EmbeddingService` mix SRP with inline `NODE_ENV` branching | ✅ Fixed |
| `sensemaker` | Design | GCP auth client recreated on every `embed()` call | ✅ Fixed |
| all 3 | Minor | Dead `AppController`/`AppService` scaffold files | ✅ Fixed |
| `fact-checker` | Minor | `ClaimBusterService` API URL hardcoded | ✅ Fixed |
| `sensemaker` | Minor | NewsAPI key sent in URL query string | ✅ Fixed |
| `polarizer` | Minor | Raw LLM response logged at `log` level instead of `debug` | ✅ Fixed |
