#!/usr/bin/env bash
# Task 4: Apply 'Cymbal Confidential' Drive Label and Create Custom SDP Policy (cepf-drive-policy)
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
QUANTUM_LEDGER_FILE_ID="${QUANTUM_LEDGER_FILE_ID:-1fxzz5V2PpobNqcHA5ytEpC0KEioSfM8T39lD5nSi_gI}"
CONFIDENTIAL_LABEL_ID="OiQWm4osiQYvIPl6oW6sZqALpOoNtv8zCP7RNNEbbFcb"

ADC_TOKEN="$(gcloud auth application-default print-access-token)"
GCP_TOKEN="$(gcloud auth print-access-token)"

echo "[1/2] Applying Google Drive Label (${CONFIDENTIAL_LABEL_ID}) to Cymbal_QuantumLedger (${QUANTUM_LEDGER_FILE_ID})..."
curl -s -X POST \
  -H "Authorization: Bearer ${ADC_TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  -H "Content-Type: application/json" \
  "https://www.googleapis.com/drive/v3/files/${QUANTUM_LEDGER_FILE_ID}/modifyLabels" \
  -d "{
    \"labelModifications\": [
      {
        \"labelId\": \"${CONFIDENTIAL_LABEL_ID}\"
      }
    ]
  }" | jq .

echo "[2/2] Creating Sensitive Data Protection Content Policy (cepf-drive-policy) in global..."
curl -s -X POST \
  -H "Authorization: Bearer ${GCP_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/global/contentPolicies?contentPolicyId=cepf-drive-policy" \
  -d "{
    \"contentPolicy\": {
      \"inspectPolicy\": {
        \"infoTypes\": [
          {
            \"name\": \"CREDIT_CARD_NUMBER\",
            \"sensitivityScore\": {\"score\": \"SENSITIVITY_HIGH\"},
            \"specificInfoType\": {\"defaultLikelihood\": \"LIKELY\"}
          },
          {
            \"name\": \"CREDIT_CARD_DATA\",
            \"sensitivityScore\": {\"score\": \"SENSITIVITY_HIGH\"},
            \"specificInfoType\": {\"defaultLikelihood\": \"LIKELY\"}
          }
        ],
        \"customInfoTypes\": [
          {
            \"infoType\": {
              \"name\": \"confidential\",
              \"sensitivityScore\": {\"score\": \"SENSITIVITY_UNSPECIFIED\"}
            },
            \"likelihood\": \"VERY_LIKELY\",
            \"fileLabelInfoType\": {
              \"googleDriveLabel\": {
                \"labelId\": \"${CONFIDENTIAL_LABEL_ID}\"
              }
            }
          }
        ]
      },
      \"rules\": [
        {
          \"conditions\": {
            \"anyInfoType\": {}
          },
          \"action\": \"BLOCK\"
        }
      ]
    }
  }" | jq .
