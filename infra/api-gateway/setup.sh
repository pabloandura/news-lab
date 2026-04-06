#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# news-lab GCP Infrastructure Setup
# Run once to provision all shared infrastructure before the first Cloud Run
# deployment. Safe to re-run — most commands are idempotent.
#
# Prerequisites:
#   gcloud auth login
#   gcloud config set project news-lab-2ba2d
#
# Usage:
#   bash infra/api-gateway/setup.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

PROJECT_ID="news-lab-2ba2d"
REGION="us-central1"
REGISTRY_REPO="news-lab"

echo "▶ Using project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# ── Step 1: Enable required GCP APIs ─────────────────────────────────────────

echo "▶ Enabling GCP APIs..."
gcloud services enable \
  apigateway.googleapis.com \
  servicecontrol.googleapis.com \
  servicemanagement.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  cloudscheduler.googleapis.com \
  vertexai.googleapis.com \
  firestore.googleapis.com \
  --project="$PROJECT_ID"

# ── Step 2: Artifact Registry ─────────────────────────────────────────────────

echo "▶ Creating Artifact Registry repository..."
gcloud artifacts repositories create "$REGISTRY_REPO" \
  --repository-format=docker \
  --location="$REGION" \
  --description="news-lab Docker images" \
  --project="$PROJECT_ID" 2>/dev/null || echo "  (already exists)"

# Authenticate Docker to push to Artifact Registry
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

# ── Step 3: Service Accounts ──────────────────────────────────────────────────
#
# One SA per Cloud Run service. Each SA is granted only the permissions it needs.

for SERVICE in fact-checker polarizer sensemaker; do
  SA_NAME="${SERVICE}-sa"
  SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

  echo "▶ Creating service account: $SA_NAME"
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="${SERVICE} Cloud Run SA" \
    --project="$PROJECT_ID" 2>/dev/null || echo "  (already exists)"

  # Firestore read/write
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/datastore.user" --quiet

  # Vertex AI user (generate content)
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/aiplatform.user" --quiet

  # Secret Manager accessor
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/secretmanager.secretAccessor" --quiet
done

# API Gateway backend auth SA (used to invoke Cloud Run with a signed JWT)
gcloud iam service-accounts create api-gateway-sa \
  --display-name="API Gateway backend auth SA" \
  --project="$PROJECT_ID" 2>/dev/null || echo "  (already exists)"

GW_SA="api-gateway-sa@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${GW_SA}" \
  --role="roles/run.invoker" --quiet

# Cloud Scheduler SA (invokes sensemaker /ingest daily)
gcloud iam service-accounts create scheduler-sa \
  --display-name="Cloud Scheduler SA (sensemaker ingestion)" \
  --project="$PROJECT_ID" 2>/dev/null || echo "  (already exists)"

SENSEMAKER_SA="sensemaker-sa@${PROJECT_ID}.iam.gserviceaccount.com"
SCHEDULER_SA="scheduler-sa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud run services add-iam-policy-binding sensemaker \
  --region="$REGION" \
  --member="serviceAccount:${SCHEDULER_SA}" \
  --role="roles/run.invoker" 2>/dev/null || echo "  (sensemaker not yet deployed — run this again after deploy)"

# ── Step 4: Secret Manager ────────────────────────────────────────────────────
#
# Create secrets (empty). Fill values with the commands printed below.

echo "▶ Creating secrets in Secret Manager..."

for SECRET in claimbuster-api-key newsapi-key; do
  gcloud secrets create "$SECRET" \
    --replication-policy="automatic" \
    --project="$PROJECT_ID" 2>/dev/null || echo "  ($SECRET already exists)"
done

# vertex-ai-project is non-sensitive but stored here for consistency
gcloud secrets create vertex-ai-project \
  --replication-policy="automatic" \
  --project="$PROJECT_ID" 2>/dev/null || echo "  (already exists)"

# Pre-fill vertex-ai-project (not sensitive)
echo -n "$PROJECT_ID" | gcloud secrets versions add vertex-ai-project \
  --data-file=- --project="$PROJECT_ID" 2>/dev/null || echo "  (version already exists)"

echo ""
echo "┌─ ACTION REQUIRED ──────────────────────────────────────────────────────"
echo "│  Fill in your secret values:"
echo "│"
echo "│  # NewsAPI key (same one in your .env / flutter app)"
echo "│  echo -n 'YOUR_NEWSAPI_KEY' | gcloud secrets versions add newsapi-key --data-file=-"
echo "│"
echo "│  # ClaimBuster API key (optional — register at idir.uta.edu/claimbuster)"
echo "│  echo -n 'YOUR_CLAIMBUSTER_KEY' | gcloud secrets versions add claimbuster-api-key --data-file=-"
echo "└────────────────────────────────────────────────────────────────────────"

# ── Step 5: API Gateway ───────────────────────────────────────────────────────
#
# Creates the gateway API entity. The actual API config (with Cloud Run URLs)
# is deployed after Cloud Run services are live — use `just gateway-deploy`.

echo "▶ Creating API Gateway API..."
gcloud api-gateway apis create news-lab-api \
  --project="$PROJECT_ID" 2>/dev/null || echo "  (already exists)"

echo ""
echo "┌─ NEXT STEPS ───────────────────────────────────────────────────────────"
echo "│"
echo "│  1. Fill in secret values (see above)"
echo "│"
echo "│  2. Deploy Cloud Run services:"
echo "│     just deploy fact-checker"
echo "│     just deploy polarizer"
echo "│     just deploy sensemaker"
echo "│"
echo "│  3. Deploy the API Gateway (resolves Cloud Run URLs automatically):"
echo "│     just gateway-deploy"
echo "│"
echo "│  4. Get the gateway URL and set it in Flutter:"
echo "│     gcloud api-gateway gateways describe news-lab-gateway \\"
echo "│       --location=$REGION --format='value(defaultHostname)'"
echo "│     # Then update MICROSERVICES_BASE_URL in constants.dart"
echo "│"
echo "└────────────────────────────────────────────────────────────────────────"
