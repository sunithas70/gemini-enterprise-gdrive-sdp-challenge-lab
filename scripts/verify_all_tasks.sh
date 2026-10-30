#!/usr/bin/env bash
# Comprehensive Verification Script for All 6 Challenge Lab Tasks
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
TOKEN="$(gcloud auth print-access-token)"
ADC_TOKEN="$(gcloud auth application-default print-access-token)"

echo "================================================================="
echo " Task 1: Verify Global Auth (Google Identity) & cymbal-ge-app"
echo "================================================================="
curl -s -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/aclConfig" | jq .

curl -s -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/engines/cymbal-ge-app" | jq '{name, displayName, commonConfig, dataStoreIds}'

echo "================================================================="
echo " Task 2 & 5: Verify cymbal-gdrive-connector & Attached SDP Policy"
echo "================================================================="
curl -s -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/cymbal-gdrive-connector/dataConnector" | jq '{name, state, actionState, connectorModes, dataProtectionPolicy, enabledActionsCount: (.bapConfig.enabledActions | length)}'

echo "================================================================="
echo " Task 3 & 4: Verify Google Drive Docs & Cymbal Confidential Label"
echo "================================================================="
curl -s -H "Authorization: Bearer ${ADC_TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://www.googleapis.com/drive/v3/files?q=trashed=false&fields=files(id,name,mimeType)" | jq .

curl -s -H "Authorization: Bearer ${ADC_TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://www.googleapis.com/drive/v3/files/1fxzz5V2PpobNqcHA5ytEpC0KEioSfM8T39lD5nSi_gI/listLabels" | jq .

echo "================================================================="
echo " Task 4: Verify SDP Content Policy (cepf-drive-policy)"
echo "================================================================="
curl -s -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/global/contentPolicies/cepf-drive-policy" | jq .

echo "================================================================="
echo " Task 5: Verify Discovery Engine Service Agent DLP User IAM Role"
echo "================================================================="
gcloud projects get-iam-policy "${PROJECT_ID}" \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/dlp.user AND bindings.members:service-${PROJECT_NUMBER}@gcp-sa-discoveryengine.iam.gserviceaccount.com" \
  --format="table(bindings.role, bindings.members)"

echo "================================================================="
echo " Task 6: Verify Assistant & Gemini Notebook SDP Policies"
echo "================================================================="
curl -s -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/engines/cymbal-ge-app/assistants/default_assistant" | jq '{name, customerPolicy}'

curl -s -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}" | jq '{name, customerProvidedConfig}'
