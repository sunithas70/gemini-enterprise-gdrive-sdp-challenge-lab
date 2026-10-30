# Architecture & Security Design: Gemini Enterprise with Google Drive & Sensitive Data Protection (SDP)

## 1. Architectural Overview

Cymbal Group's enterprise knowledge architecture integrates **Gemini Enterprise (Google Cloud Discovery Engine)** with **Google Workspace (Google Drive)** via a **Federated Search and Actions Data Connector**, secured end-to-end by **Cloud Data Loss Prevention (Sensitive Data Protection / SDP)** content policies.

```mermaid
flowchart TB
    subgraph Identity["Identity & Access Control Layer"]
        GID["Google Identity (GSUITE IdP)<br/>Global ACL Config"]
        OAUTH["OAuth 2.0 Delegated Scopes<br/>drive / docs / spreadsheets / presentations"]
        SA["Discovery Engine Service Agent<br/>service-280090500177@gcp-sa-discoveryengine.iam.gserviceaccount.com<br/>Role: roles/dlp.user"]
    end

    subgraph Gemini["Gemini Enterprise (Discovery Engine - global)"]
        ENGINE["Gemini Enterprise App<br/>Engine ID: cymbal-ge-app<br/>Company: Cymbal Group"]
        ASSIST["Default Assistant<br/>assistants/default_assistant"]
        NBLM["Gemini Notebook (NotebookLM)<br/>Project customerProvidedConfig"]
        CONN["Google Drive Data Connector<br/>Collection: cymbal-gdrive-connector<br/>Modes: FEDERATED + ACTIONS (19 tools)"]
        DS["Federated Data Store<br/>cymbal-gdrive-connector_google_drive"]
    end

    subgraph Security["Sensitive Data Protection (Cloud DLP - global)"]
        POLICY["SDP Content Policy: cepf-drive-policy<br/>Action: BLOCK on anyInfoType"]
        IT_LABEL["Custom File Label InfoType: confidential<br/>Label ID: OiQWm4osiQYvIPl6oW6sZqALpOoNtv8zCP7RNNEbbFcb<br/>Likelihood: VERY_LIKELY"]
        IT_CC["Built-in InfoTypes:<br/>CREDIT_CARD_NUMBER, CREDIT_CARD_DATA"]
    end

    subgraph Workspace["Google Workspace (Google Drive)"]
        DOC1["Cymbal_QuantumLedger<br/>Label: Cymbal Confidential<br/>Status: BLOCKED by SDP"]
        DOC2["Cymbal_Public_Overview<br/>Label: None<br/>Status: ALLOWED"]
        DOC3["Cymbal_Brand_Guidelines<br/>Label: None<br/>Status: ALLOWED"]
    end

    GID --> ENGINE
    OAUTH --> CONN
    ENGINE --> ASSIST
    ENGINE --> DS
    CONN --> DS
    CONN -->|Federated Search & 19 Actions| Workspace

    POLICY --> IT_LABEL
    POLICY --> IT_CC
    SA -->|Evaluates inline SDP rules| POLICY

    POLICY -.->|1. Connector-level SDP| CONN
    POLICY -.->|2. Assistant-level SDP| ASSIST
    POLICY -.->|3. Project NotebookLM SDP| NBLM
```

---

## 2. Defense-in-Depth Sensitive Data Protection (SDP) Layers

The architecture enforces `cepf-drive-policy` at three independent points in Gemini Enterprise:

| Enforcement Point | Resource Path | API Field | Purpose |
| :--- | :--- | :--- | :--- |
| **Layer 1: Data Connector** | `projects/{PROJECT_NUMBER}/locations/global/collections/cymbal-gdrive-connector/dataConnector` | `dataProtectionPolicy.sensitiveDataProtectionPolicy.policy` | Inspects and blocks sensitive/labeled Google Drive files (`Cymbal Confidential`) or credit card numbers during federated retrieval before content enters the LLM context. |
| **Layer 2: Gemini Assistant** | `projects/{PROJECT_NUMBER}/locations/global/collections/default_collection/engines/cymbal-ge-app/assistants/default_assistant` | `customerPolicy.dataProtectionPolicy.sensitiveDataProtectionPolicy.policy` | Inspects user prompts, grounding chunks, and assistant generation paths across all connected tools and data stores. |
| **Layer 3: Gemini Notebook** | `projects/{PROJECT_ID}` | `customerProvidedConfig.notebooklmConfig.dataProtectionPolicy.sensitiveDataProtectionPolicy.policy` | Enforces the same SDP policy in NotebookLM Enterprise when users attempt to import Drive documents or query sources containing `Cymbal Confidential` labels or credit card data. |

---

## 3. Data Flow & Policy Enforcement Sequence

```mermaid
sequenceDiagram
    autonumber
    actor User as Employee (Google Identity)
    participant WebApp as Gemini Enterprise Web App / Assistant
    participant Conn as Google Drive Connector (cymbal-gdrive-connector)
    participant SA as Discovery Engine Service Agent
    participant DLP as Cloud SDP (cepf-drive-policy)
    participant Drive as Google Drive API v3

    User->>WebApp: Query: "Retrieve the summary for Cymbal_QuantumLedger"
    WebApp->>Conn: Invoke google_drive_agent (Federated Search / Read Document)
    Conn->>Drive: Fetch file metadata, Drive Labels & content (OAuth delegated token)
    Drive-->>Conn: Return Cymbal_QuantumLedger + Label ID OiQWm4osiQYvIPl6oW6sZqALpOoNtv8zCP7RNNEbbFcb
    Conn->>SA: Request inline SDP inspection against cepf-drive-policy
    SA->>DLP: Evaluate custom FileLabelInfoType (confidential) & Credit Card InfoTypes
    DLP-->>SA: Match: customInfoType "confidential" (VERY_LIKELY) -> Action: BLOCK
    SA-->>Conn: Enforce BLOCK action
    Conn-->>WebApp: Return policy access restriction / content blocked alert
    WebApp-->>User: Explicit refusal (confidential contents withheld)

    User->>WebApp: Query: "Summarize Cymbal_Public_Overview"
    WebApp->>Conn: Invoke google_drive_agent
    Conn->>Drive: Fetch Cymbal_Public_Overview (No confidential label, no PII/CC)
    Drive-->>Conn: Return document content
    Conn->>SA: Request inline SDP inspection
    SA->>DLP: Evaluate cepf-drive-policy
    DLP-->>SA: No InfoType match -> Allowed
    Conn-->>WebApp: Return grounded content
    WebApp-->>User: Present synthesized summary of Cymbal_Public_Overview
```

---

## 4. Key Component Specifications

### 4.1 Identity & Access Management
- **Identity Provider**: Google Identity (`idpType: GSUITE`) configured on `projects/{PROJECT_ID}/locations/global/aclConfig`.
- **Service Agent**: `service-{PROJECT_NUMBER}@gcp-sa-discoveryengine.iam.gserviceaccount.com` granted `roles/dlp.user` so Discovery Engine can call Cloud DLP (`projects/{PROJECT_ID}/locations/global/contentPolicies/cepf-drive-policy`) at query time.

### 4.2 Google Drive Federated Connector (`cymbal-gdrive-connector`)
- **Mode**: `FEDERATED` + `ACTIONS` (no ingestion index storage latency; live search via Google Drive API).
- **Supported Actions Enabled (19 Actions)**:
  - `copy_file`, `create_file`, `download_file_content`, `get_cell_values`, `get_file_metadata`, `get_file_permissions`, `get_spreadsheet`, `insert_dimension`, `list_recent_files`, `list_shared_drives`, `read_document`, `read_file_content`, `read_presentation`, `search_files`, `share_file`, `trash_file`, `update_cell_values`, `update_file`, `update_formulas`.

### 4.3 Sensitive Data Protection Content Policy (`cepf-drive-policy`)
- **Custom File Label InfoType**:
  - Name: `confidential`
  - Likelihood: `VERY_LIKELY`
  - Sensitivity Score: `SENSITIVITY_UNSPECIFIED`
  - Google Drive Label ID: `OiQWm4osiQYvIPl6oW6sZqALpOoNtv8zCP7RNNEbbFcb` (`Cymbal Confidential`)
- **Built-in InfoTypes**:
  - `CREDIT_CARD_NUMBER`
  - `CREDIT_CARD_DATA`
- **Rule Action**:
  - Condition: `anyInfoType: {}`
  - Action: `BLOCK` (all `ALLOW` rules removed)
