#!/usr/bin/env bash
# Task 5: Grant DLP User Role to Discovery Engine Service Agent & Attach SDP Policy to Google Drive Connector
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
SERVICE_AGENT="service-${PROJECT_NUMBER}@gcp-sa-discoveryengine.iam.gserviceaccount.com"
POLICY_NAME="projects/${PROJECT_ID}/locations/global/contentPolicies/cepf-drive-policy"
TOKEN="$(gcloud auth print-access-token)"

echo "[1/2] Granting roles/dlp.user to Discovery Engine Service Agent (${SERVICE_AGENT})..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_AGENT}" \
  --role="roles/dlp.user" \
  --condition=None \
  --quiet

echo "[2/2] Attaching cepf-drive-policy directly to Google Drive Connector (cymbal-gdrive-connector)..."
curl -s -X PATCH \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/cymbal-gdrive-connector/dataConnector?updateMask=dataProtectionPolicy" \
  -d "{
    \"dataProtectionPolicy\": {
      \"sensitiveDataProtectionPolicy\": {
        \"policy\": \"${POLICY_NAME}\"
      }
    }
  }" | jq '{name, state, dataProtectionPolicy}'
