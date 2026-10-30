#!/usr/bin/env bash
# Task 1: Configure the Gemini Enterprise App & Global Authentication
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
TOKEN="$(gcloud auth print-access-token)"

echo "[1/2] Configuring Global Authentication to use Google Identity (GSUITE)..."
curl -s -X PATCH \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/aclConfig" \
  -d '{
    "idpConfig": {
      "idpType": "GSUITE"
    }
  }' | jq .

echo "[2/2] Creating Gemini Enterprise App (cymbal-ge-app)..."
curl -s -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/engines?engineId=cymbal-ge-app" \
  -d '{
    "displayName": "cymbal-ge-app",
    "solutionType": "SOLUTION_TYPE_SEARCH",
    "industryVertical": "GENERIC",
    "appType": "APP_TYPE_INTRANET",
    "searchEngineConfig": {
      "searchTier": "SEARCH_TIER_ENTERPRISE",
      "searchAddOns": ["SEARCH_ADD_ON_LLM"]
    },
    "commonConfig": {
      "companyName": "Cymbal Group"
    }
  }' | jq .
