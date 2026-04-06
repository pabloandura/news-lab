# news-lab Microservices — Acceptance Criteria

**Project:** news-lab microservices expansion  
**Phases covered:** 1 (fact-checker), 2 (API Gateway + infra), 3 (polarizer)  
**Phase 4 (sensemaker):** deferred — see `ARCHITECTURE_EXPANSION.md §8`

---

## Phase 1 — fact-checker

### Service (NestJS)

- [ ] `GET /health` returns `200 { "status": "ok" }`
- [ ] `POST /fact-check` with valid body returns `202 { "status": "processing", "articleId": "..." }`
- [ ] `POST /fact-check` with `text` shorter than 50 characters returns `400`
- [ ] `POST /fact-check` with missing `articleId` returns `400`
- [ ] After a valid request, `fact_checks/{articleId}.botCheck` appears in Firestore within 30 seconds containing:
  - `flaggedSentencesPercent` (float 0.0–1.0)
  - `confidenceScore` (float 0.0–1.0)
  - `checkedAt` (Firestore timestamp)
- [ ] Service logs show extracted claim count and final scores
- [ ] Service recovers gracefully when Vertex AI returns malformed JSON (no crash, writes fallback 0/1.0 scores)
- [ ] All unit tests pass: `just test fact-checker`

### Flutter integration

- [ ] "Check article" button is visible on the article detail page when no `botCheck` exists
- [ ] Tapping the button while unauthenticated does nothing (button is disabled)
- [ ] Tapping the button shows a loading spinner and "Analysing…" label
- [ ] Within ~30 seconds, the spinner disappears and `BotCheckBadge` renders with real scores
- [ ] "Check article" button disappears once `botCheck` data is present
- [ ] If the 30-second timeout elapses without a Firestore update, an error message is shown

---

## Phase 2 — API Gateway + Infrastructure

### GCP provisioning (`just setup`)

- [ ] All required APIs are enabled in project `news-lab-2ba2d`
- [ ] Artifact Registry repository `news-lab` exists in `us-central1`
- [ ] Service accounts exist: `fact-checker-sa`, `polarizer-sa`, `sensemaker-sa`, `api-gateway-sa`, `scheduler-sa`
- [ ] Each service SA has roles: `datastore.user`, `aiplatform.user`, `secretmanager.secretAccessor`
- [ ] `api-gateway-sa` has `roles/run.invoker`
- [ ] Secrets exist in Secret Manager: `newsapi-key`, `claimbuster-api-key`, `vertex-ai-project`

### API Gateway (`just gateway-create`)

- [ ] Gateway `news-lab-gateway` is live and returns a hostname
- [ ] `POST /fact-check` through the gateway with a valid Firebase JWT returns `202`
- [ ] `POST /fact-check` through the gateway without a JWT returns `401`
- [ ] `POST /polarize` through the gateway with a valid Firebase JWT returns `202`
- [ ] `GET /health` through the gateway returns `200` with no auth required

### CI/CD (Cloud Build)

- [ ] Pushing to `main` with changes under `services/fact-checker/**` triggers the fact-checker pipeline
- [ ] Pushing to `main` with changes under `services/polarizer/**` triggers the polarizer pipeline
- [ ] Each pipeline: installs deps → type-checks → runs tests → builds Docker image → deploys to Cloud Run
- [ ] A failed test blocks deployment

---

## Phase 3 — polarizer

### Service (NestJS)

- [ ] `GET /health` returns `200 { "status": "ok" }`
- [ ] `POST /polarize` with valid body returns `202 { "status": "processing", "articleId": "..." }`
- [ ] `POST /polarize` with `text` shorter than 50 characters returns `400`
- [ ] After a valid request, `articles/{articleId}.biasReport` appears in Firestore within 30 seconds containing:
  - `politicalLean` (float −1.0 to +1.0)
  - `emotionalLanguageScore` (float 0.0–1.0)
  - `framingNotes` (array of strings, may be empty)
  - `analyzedAt` (Firestore timestamp)
- [ ] `politicalLean` is clamped to [−1.0, +1.0] even if Gemini returns out-of-range values
- [ ] `emotionalLanguageScore` is clamped to [0.0, 1.0]
- [ ] Service recovers gracefully when Vertex AI returns malformed JSON (writes neutral fallback: 0, 0, [])
- [ ] All unit tests pass: `just test polarizer`

### Flutter integration

- [ ] "Analyse bias" button is visible on the article detail page when no `biasReport` exists
- [ ] Tapping the button shows a loading spinner and "Analysing…" label
- [ ] Within ~30 seconds, the spinner disappears and `BiasBadge` renders with:
  - Political lean chip (blue = left, green = neutral, red = right)
  - Emotional tone chip (green → red scale)
- [ ] "Analyse bias" button disappears once `biasReport` data is present
- [ ] If the 30-second timeout elapses, an error message is shown
- [ ] "Related coverage — coming soon" placeholder is visible below the bias controls

---

## Cross-cutting

- [ ] `just test-all` passes with no failures across all services
- [ ] `just check-types` passes with no TypeScript errors across `types/`, `fact-checker/`, `polarizer/`
- [ ] `git status` is clean after running `just install-all` and `just build-all`
- [ ] No secrets or credentials appear in git history (`services/credentials/` is gitignored)
- [ ] Both services start successfully locally with `just dev fact-checker` and `just dev polarizer`
- [ ] Flutter app compiles without errors: `flutter analyze`

---

## Out of scope (Phase 4 — deferred)

The following are explicitly **not** acceptance criteria for this release:

- Similar articles / "Find related coverage" feature
- `POST /similar` and `POST /ingest` gateway routes being functional
- sensemaker Cloud Run service deployed
- Multi-source news ingestion pipeline
- Firestore Vector Search index
