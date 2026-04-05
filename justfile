# news-lab unified task runner
# Install: brew install just
# Usage:   just <recipe>

# ── Dev ────────────────────────────────────────────────────────────────────

dev-app:
    cd frontend && flutter run

dev service:
    cd services/{{service}} && npm run start:dev

# ── Test ───────────────────────────────────────────────────────────────────

test-all:
    cd frontend && flutter test
    cd services/fact-checker && npm test
    cd services/polarizer && npm test
    cd services/sensemaker && npm test

test service:
    cd services/{{service}} && npm test

# ── Type checking ──────────────────────────────────────────────────────────

check-types:
    cd types && npx tsc --noEmit
    cd services/fact-checker && npx tsc --noEmit
    cd services/polarizer && npx tsc --noEmit
    cd services/sensemaker && npx tsc --noEmit

# ── Lint ───────────────────────────────────────────────────────────────────

lint-all:
    cd frontend && dart analyze
    cd services/fact-checker && npx eslint src
    cd services/polarizer && npx eslint src
    cd services/sensemaker && npx eslint src

lint service:
    cd services/{{service}} && npx eslint src

# ── Build ──────────────────────────────────────────────────────────────────

build service:
    docker build -t {{service}} services/{{service}}

build-all:
    just build fact-checker
    just build polarizer
    just build sensemaker

# ── Deploy (manual — for hotfixes outside CI) ──────────────────────────────

deploy service:
    gcloud run deploy {{service}} \
      --image gcr.io/$PROJECT_ID/{{service}}:latest \
      --region us-central1 \
      --platform managed \
      --no-allow-unauthenticated

# ── Firebase ───────────────────────────────────────────────────────────────

deploy-rules:
    cd infra/firebase && firebase deploy --only firestore:rules,storage

deploy-indexes:
    cd infra/firebase && firebase deploy --only firestore:indexes

# ── Install ────────────────────────────────────────────────────────────────

install-all:
    cd types && npm install
    cd services/fact-checker && npm install
    cd services/polarizer && npm install
    cd services/sensemaker && npm install
    cd frontend && flutter pub get
