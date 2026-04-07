# News Lab

A Flutter news app where journalists publish articles, AI services fact-check them, and readers vote on credibility. 

**Report and learning journey:** [`frontend/docs/REPORT.md`](frontend/docs/REPORT.md) · [`frontend/docs/LEARNING_JOURNEY.md`](frontend/docs/LEARNING_JOURNEY.md)

---

## Features (journalist perspective)

- **Sign in / sign out** — email/password auth via Firebase
- **Publish an article** — fill in title, description, body, category, and pick a thumbnail; the article goes live in the home feed immediately
- **Journalist profile** — see all your published articles, edit any field, or delete an article
- **Home feed** — your articles appear alongside News API stories, filterable by category
- **Fact-check panel** — on any article detail page, trigger an AI bot check (Ollama LLM) or see the community credibility score from reader votes
- **Bias badge** — an AI bias analysis (left / center / right lean) shown on each article
- **Similar articles** — AI-recommended related stories shown below the article body
- **Explore page** — browse articles by category

---

## Monorepo layout

```
frontend/          Flutter app
services/
  fact-checker/    NestJS — LLM-based fact-check + Firestore cache
  polarizer/       NestJS — bias detection
  sensemaker/      NestJS — similar articles via embeddings
types/             Shared TypeScript interfaces (@news-lab/types)
backend/docs/      Firestore schema documentation
infra/             GCP API Gateway, Cloud Run, Cloud Build, Firebase rules
justfile           Unified task runner (install just via brew)
```

---

## justfile quick reference

> Install: `brew install just` · Run: `just <recipe>`

| Recipe | What it does |
|---|---|
| `just dev-app` | Run the Flutter app (loads `frontend/.env` for the News API key) |
| `just dev service` | Start one service in watch mode (`fact-checker`, `polarizer`, `sensemaker`) |
| `just dev-all` | Start all 3 services + Flutter concurrently with prefixed logs |
| `just adb-forward` | Forward device localhost ports to Mac (run once per USB session) |
| `just test-all` | Run Flutter tests + all service tests |
| `just lint-all` | `dart analyze` + ESLint across all services |
| `just check-types` | TypeScript type-check all services and the types package |
| `just build service` | Build a service Docker image |
| `just deploy service` | Deploy a service to Cloud Run (manual hotfix path) |
| `just deploy-rules` | Deploy Firestore + Storage security rules |
| `just gateway-create` | Provision the GCP API Gateway (one-time) |
| `just gateway-update` | Push a new OpenAPI config to the gateway |
| `just install-all` | `npm install` all services + `flutter pub get` |

The services expect a locally running [Ollama](https://ollama.com/) instance (`ollama serve`). `just dev-all` checks for it and aborts with a clear message if it's not running.
