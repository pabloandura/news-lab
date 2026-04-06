# news-lab unified task runner
# Install: brew install just
# Usage:   just <recipe>

PROJECT_ID := "news-lab-2ba2d"
REGION     := "us-central1"

# ── Dev ────────────────────────────────────────────────────────────────────

dev-app:
    cd frontend && flutter run

dev service:
    cd services/{{service}} && npm run start:dev

# Forward device localhost → Mac for all dev services (run once per USB session)
adb-forward:
    adb reverse tcp:3001 tcp:3001
    adb reverse tcp:3002 tcp:3002
    adb reverse tcp:11434 tcp:11434

# Run a service on a fixed local port (polarizer=3001, fact-checker=3002)
dev-local service:
    #!/usr/bin/env bash
    case "{{service}}" in
      polarizer)    PORT=3001 ;;
      fact-checker) PORT=3002 ;;
      *)            PORT=3000 ;;
    esac
    cd services/{{service}} && PORT=$PORT npm run start:dev

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

# Build a single service Docker image (repo root as context)
build service:
    docker build -f services/{{service}}/Dockerfile -t {{service}} .

build-all:
    just build fact-checker
    just build polarizer
    just build sensemaker

# ── Deploy (manual — for hotfixes outside CI) ──────────────────────────────

deploy service:
    gcloud run deploy {{service}} \
      --image gcr.io/{{PROJECT_ID}}/{{service}}:latest \
      --region {{REGION}} \
      --platform managed \
      --no-allow-unauthenticated \
      --service-account {{service}}-sa@{{PROJECT_ID}}.iam.gserviceaccount.com

# ── Infrastructure setup ───────────────────────────────────────────────────

# One-time provisioning: APIs, service accounts, secrets, Artifact Registry
setup:
    bash infra/api-gateway/setup.sh

# ── API Gateway ────────────────────────────────────────────────────────────

# Create the gateway for the first time (run once, after Cloud Run services are live)
gateway-create:
    #!/usr/bin/env bash
    set -euo pipefail
    export FACT_CHECKER_URL=$(gcloud run services describe fact-checker --region={{REGION}} --format='value(status.url)')
    export POLARIZER_URL=$(gcloud run services describe polarizer --region={{REGION}} --format='value(status.url)')
    export SENSEMAKER_URL=$(gcloud run services describe sensemaker --region={{REGION}} --format='value(status.url)')
    export GATEWAY_HOST="pending"
    export GCP_PROJECT_ID={{PROJECT_ID}}
    CONFIG_ID="news-lab-config-$(date +%Y%m%d%H%M%S)"
    envsubst < infra/api-gateway/openapi.template.yaml > /tmp/openapi.yaml
    gcloud api-gateway api-configs create "$CONFIG_ID" \
      --api=news-lab-api --openapi-spec=/tmp/openapi.yaml \
      --project={{PROJECT_ID}} \
      --backend-auth-service-account=api-gateway-sa@{{PROJECT_ID}}.iam.gserviceaccount.com
    gcloud api-gateway gateways create news-lab-gateway \
      --api=news-lab-api --api-config="$CONFIG_ID" \
      --location={{REGION}} --project={{PROJECT_ID}}
    echo "Gateway URL:"
    just gateway-url

# Update the gateway with the latest spec and current Cloud Run URLs
gateway-update:
    #!/usr/bin/env bash
    set -euo pipefail
    export FACT_CHECKER_URL=$(gcloud run services describe fact-checker --region={{REGION}} --format='value(status.url)')
    export POLARIZER_URL=$(gcloud run services describe polarizer --region={{REGION}} --format='value(status.url)')
    export SENSEMAKER_URL=$(gcloud run services describe sensemaker --region={{REGION}} --format='value(status.url)')
    export GATEWAY_HOST=$(gcloud api-gateway gateways describe news-lab-gateway --location={{REGION}} --format='value(defaultHostname)')
    export GCP_PROJECT_ID={{PROJECT_ID}}
    CONFIG_ID="news-lab-config-$(date +%Y%m%d%H%M%S)"
    envsubst < infra/api-gateway/openapi.template.yaml > /tmp/openapi.yaml
    gcloud api-gateway api-configs create "$CONFIG_ID" \
      --api=news-lab-api --openapi-spec=/tmp/openapi.yaml \
      --project={{PROJECT_ID}} \
      --backend-auth-service-account=api-gateway-sa@{{PROJECT_ID}}.iam.gserviceaccount.com
    gcloud api-gateway gateways update news-lab-gateway \
      --api=news-lab-api --api-config="$CONFIG_ID" \
      --location={{REGION}} --project={{PROJECT_ID}}
    echo "Updated. Gateway URL:"
    just gateway-url

# Show the current gateway hostname
gateway-url:
    gcloud api-gateway gateways describe news-lab-gateway \
      --location={{REGION}} --format='value(defaultHostname)'

# Grant the gateway SA invoker rights on all Cloud Run services (run after gateway-create)
gateway-grant-invoker:
    #!/usr/bin/env bash
    GW_SA="api-gateway-sa@{{PROJECT_ID}}.iam.gserviceaccount.com"
    for SERVICE in fact-checker polarizer sensemaker; do
      gcloud run services add-iam-policy-binding $SERVICE \
        --region={{REGION}} \
        --member="serviceAccount:$GW_SA" \
        --role="roles/run.invoker" \
        --project={{PROJECT_ID}}
    done

# ── Secret Manager ─────────────────────────────────────────────────────────

# Set or update a secret value
# Usage: just set-secret newsapi-key YOUR_VALUE
set-secret name value:
    echo -n "{{value}}" | gcloud secrets versions add {{name}} --data-file=- --project={{PROJECT_ID}}

# Read the current value of a secret
get-secret name:
    gcloud secrets versions access latest --secret={{name}} --project={{PROJECT_ID}}

# List all news-lab secrets
list-secrets:
    gcloud secrets list --project={{PROJECT_ID}}

# ── Firebase ───────────────────────────────────────────────────────────────

deploy-rules:
    cd infra/firebase && firebase deploy --only firestore:rules,storage

deploy-indexes:
    cd infra/firebase && firebase deploy --only firestore:indexes

# ── Install ────────────────────────────────────────────────────────────────

install-all:
    cd types && npm install && npm run build
    cd services/fact-checker && npm install --legacy-peer-deps
    cd services/polarizer && npm install --legacy-peer-deps
    cd services/sensemaker && npm install --legacy-peer-deps
    cd frontend && flutter pub get
