#!/usr/bin/env bash
# Task 2: Set up a Google Drive Federated Connector with All Supported Actions
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
TOKEN="$(gcloud auth print-access-token)"

echo "[1/3] Setting up Google Drive Data Connector (cymbal-gdrive-connector) in FEDERATED + ACTIONS mode..."
curl -s -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global:setUpDataConnector?collectionId=cymbal-gdrive-connector&collectionDisplayName=cymbal-gdrive-connector" \
  -d '{
    "dataSource": "google_drive",
    "entities": [
      {
        "entityName": "google_drive"
      }
    ],
    "connectorModes": ["FEDERATED", "ACTIONS"]
  }' | jq .

echo "[2/3] Enabling all 19 supported Google Drive Actions on bapConfig..."
curl -s -X PATCH \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/cymbal-gdrive-connector/dataConnector?updateMask=bap_config" \
  -d '{
    "bapConfig": {
      "supportedConnectorModes": ["ACTIONS"],
      "enabledActions": [
        "copy_file",
        "create_file",
        "download_file_content",
        "get_cell_values",
        "get_file_metadata",
        "get_file_permissions",
        "get_spreadsheet",
        "insert_dimension",
        "list_recent_files",
        "list_shared_drives",
        "read_document",
        "read_file_content",
        "read_presentation",
        "search_files",
        "share_file",
        "trash_file",
        "update_cell_values",
        "update_file",
        "update_formulas"
      ]
    }
  }' | jq .

echo "[3/3] Verifying Data Connector state..."
curl -s -H "Authorization: Bearer ${TOKEN}" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/cymbal-gdrive-connector/dataConnector" | jq '{name, state, actionState, connectorModes, bapConfig}'
