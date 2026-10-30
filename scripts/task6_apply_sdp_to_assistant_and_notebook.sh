#!/usr/bin/env bash
# Task 6: Apply Sensitive Data Protection (cepf-drive-policy) to Assistant and Gemini Notebook
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
POLICY_NAME="projects/${PROJECT_ID}/locations/global/contentPolicies/cepf-drive-policy"
TOKEN="$(gcloud auth print-access-token)"

echo "[1/2] Applying cepf-drive-policy to Gemini Enterprise Assistant (default_assistant)..."
curl -s -X PATCH \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/engines/cymbal-ge-app/assistants/default_assistant?updateMask=customerPolicy" \
  -d "{
    \"customerPolicy\": {
      \"dataProtectionPolicy\": {
        \"sensitiveDataProtectionPolicy\": {
          \"policy\": \"${POLICY_NAME}\"
        }
      }
    }
  }" | jq '{name, customerPolicy}'

echo "[2/2] Applying cepf-drive-policy to Gemini Notebook (project notebooklmConfig)..."
curl -s -X PATCH \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}?updateMask=customerProvidedConfig" \
  -d "{
    \"customerProvidedConfig\": {
      \"notebooklmConfig\": {
        \"dataProtectionPolicy\": {
          \"sensitiveDataProtectionPolicy\": {
            \"policy\": \"${POLICY_NAME}\"
          }
        }
      }
    }
  }" | jq '{name, customerProvidedConfig}'
