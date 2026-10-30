#!/usr/bin/env python3
"""
Task 3: Connect Google Drive Data Store to Gemini Enterprise App and Create Sample Google Docs
"""
import json
import os
import subprocess
import urllib.request

PROJECT_ID = os.environ.get(
    "PROJECT_ID",
    subprocess.check_output(["gcloud", "config", "get-value", "project"], text=True).strip(),
)

DOCUMENTS = {
    "Cymbal_QuantumLedger": """Financial Overview - Cymbal Group

Executive Summary:

Q4 2023 showed strong revenue growth driven by strategic acquisitions and increased market share in the security consulting division.

Financial Details:

Revenue Breakdown:

- Professional Services: $4.2M (up 15% YoY)
- Technology Solutions: $2.8M (up 12% YoY)
- Managed Services: $1.5M (up 8% YoY)

Key Highlights:

- Successfully integrated acquired assets, achieving cost synergies ahead of schedule
- Expanded market presence in APAC region, capturing 5% market share
- Improved operational efficiency through automation initiatives

Strategic Outlook:

- Continued investment in AI-powered solutions to enhance service offerings
- Focus on expanding managed services portfolio for recurring revenue
- Explore strategic partnerships to accelerate growth in emerging markets

Risk Factors:

- Global economic uncertainties may impact client spending
- Increased competition in technology solutions segment
- Regulatory changes in data privacy could affect operations""",
    "Cymbal_Public_Overview": """Cymbal Group - Public Overview

Cymbal Group is a premier technology services and consulting organization. We work with enterprises worldwide to deliver state-of-the-art cloud architecture, data platform development, and managed infrastructure services.

Our team focuses on open standard technologies, security-first patterns, and reliable cloud operations.""",
    "Cymbal_Brand_Guidelines": """Cymbal Group - Brand Guidelines

Our Brand Tone and Voice:
- Professional: We use clear, direct, and helpful language.
- Collaborative: We emphasize teamwork, partnership, and working together to solve problems.
- Innovative: We look forward and think about modern cloud-native capabilities.

Please follow these guidelines for all public-facing communication materials.""",
}


def get_token(adc: bool = True) -> str:
    cmd = ["gcloud", "auth", "application-default", "print-access-token"] if adc else ["gcloud", "auth", "print-access-token"]
    return subprocess.check_output(cmd, text=True).strip()


def create_google_doc(title: str, content: str, token: str) -> dict:
    boundary = "===CYMBAL_DOC_BOUNDARY==="
    metadata = json.dumps({
        "name": title,
        "mimeType": "application/vnd.google-apps.document",
    })
    body = (
        f"--{boundary}\r\n"
        f"Content-Type: application/json; charset=UTF-8\r\n\r\n"
        f"{metadata}\r\n"
        f"--{boundary}\r\n"
        f"Content-Type: text/plain; charset=UTF-8\r\n\r\n"
        f"{content}\r\n"
        f"--{boundary}--"
    ).encode("utf-8")

    req = urllib.request.Request(
        "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,mimeType,webViewLink",
        data=body,
        headers={
            "Authorization": f"Bearer {token}",
            "X-Goog-User-Project": PROJECT_ID,
            "Content-Type": f"multipart/related; boundary={boundary}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main() -> None:
    drive_token = get_token(adc=True)
    for title, body in DOCUMENTS.items():
        created = create_google_doc(title, body, drive_token)
        print(f"Created Google Doc: {created['name']} (ID: {created['id']})")


if __name__ == "__main__":
    main()
