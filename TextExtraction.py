#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# -----------------------------------------------------------------------------
# Copyright (c) 2025 IKI CLOUD
#
# This software is provided by IKI CLOUD for demonstration and proof-of-concept (POC) purposes.
# You are free to use, modify, and distribute this code under the MIT License.
#
# IMPORTANT:
# These scripts are intended for evaluation and educational use.
# If you plan to adapt or deploy them in production environments,
# please contact the IKI CLOUD team first at info@iki-cloud.com.
#
# This project uses third-party libraries including Oracle Python SDKs
# (e.g., `oci`, `oracledb`), which are distributed under their own licenses.
# Please refer to their respective license terms for details.
# -----------------------------------------------------------------------------

"""
TextExtraction.py
-----------------
Extract text from a PDF using OCI Document Understanding (Text Extraction)
and (when run as a script) save the output to a .txt file next to the PDF.

This module exposes:
  - main(pdf_path: str) -> str
    Returns the full extracted text as a single string. This is used by your
    ingestion/embedding pipeline (e.g., IngestPdfText.py).

CLI usage:
  python TextExtraction.py /path/to/file.pdf

Prerequisites:
  pip install oci
  A valid OCI config file (by default we use /home/oracle/POC_GENAI_NODELETE/.oci/config)
"""

import os
import base64
import oci

from oci.ai_document import AIServiceDocumentClient
from oci.ai_document.models import (
    AnalyzeDocumentDetails,
    InlineDocumentDetails,
    DocumentTextExtractionFeature,
    DocumentKeyValueExtractionFeature,
    DocumentTableExtractionFeature,
)

# === Configuration ===
# You can override these with environment variables if you prefer:
#   export OCI_CONFIG_FILE=/path/to/config
#   export OCI_CONFIG_PROFILE=DEFAULT
CONFIG_PATH   = os.getenv("OCI_CONFIG_FILE", "/home/oracle/POC_GENAI_NODELETE/.oci/config")
CONFIG_PROFILE = os.getenv("OCI_CONFIG_PROFILE", "DEFAULT")

# Optional: set the language hint sent to Document Understanding.
# Use "it" for Italian policies, "en" for English, or leave None to let the service auto-detect.
LANGUAGE_HINT = "it"   # change to "en" or None if needed

def pdf_to_base64(path: str) -> str:
    """
    Read the PDF bytes and return a base64-encoded string,
    as required by InlineDocumentDetails.data.
    """
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def main(pdf_path: str) -> str:
    """
    Extract full text from the given PDF path using OCI Document Understanding.
    Returns:
      A single string with one line per OCR/line detected by the service.

    Notes:
      - We request Text, KeyValue, and Table features. In this simple example
        we only concatenate the line-level text, but enabling KV/Table may
        improve text detection quality and future extensibility.
      - If you need a structured output (keys/tables), you can extend this
        function to parse result.key_value_pairs / result.tables as well.
    """
    # --- 1) Validate input path ---
    if not os.path.exists(pdf_path):
        raise FileNotFoundError(f"PDF not found: {pdf_path}")

    # --- 2) Build OCI client from config file/profile ---
    # The profile must match a region where the AI Document service is available.
    config = oci.config.from_file(CONFIG_PATH, CONFIG_PROFILE)
    doc_client = AIServiceDocumentClient(config)

    # --- 3) Prepare the inline document payload (base64-encoded PDF) ---
    inline_doc = InlineDocumentDetails(data=pdf_to_base64(pdf_path))

    # --- 4) Select features to run: text, key-value, and table extraction ---
    # Even if we only return plain lines, enabling these features can help
    # the service produce more complete OCR results in some documents.
    features = [
        DocumentTextExtractionFeature(),
        DocumentKeyValueExtractionFeature(),
        DocumentTableExtractionFeature(),
    ]

    # --- 5) Build the analyze request ---
    details = AnalyzeDocumentDetails(
        document=inline_doc,
        features=features,
        # LANGUAGE_HINT can be "it", "en", etc. Set to None to let the service auto-detect.
        language=LANGUAGE_HINT if LANGUAGE_HINT else None,
    )

    # --- 6) Call the service and get the result payload ---
    response = doc_client.analyze_document(details)
    result = response.data  # AnalyzeDocumentResult

    # --- 7) Collect line-level text page by page ---
    lines_out = []
    for page in (result.pages or []):
        for line in (page.lines or []):
            if line and getattr(line, "text", None):
                lines_out.append(line.text)

    full_text = "\n".join(lines_out).strip()
    if not full_text:
        # Fallback: keep a clear marker so downstream steps can detect “no text”
        full_text = "(No text detected)"

    return full_text

# === CLI helper ===
if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python TextExtraction.py <path_to_pdf>")
        raise SystemExit(1)

    pdf_path = sys.argv[1]
    try:
        text = main(pdf_path)

        # When invoked as a script, also write a .txt next to the PDF (handy for manual inspection).
        txt_path = os.path.splitext(pdf_path)[0] + ".txt"
        with open(txt_path, "w", encoding="utf-8") as f:
            f.write(text)

        print(f"[OK] Extracted text written to: {txt_path}")
    except Exception as e:
        # Keep the message concise but clear; re-raise for calling shells if needed.
        print(f"[ERROR] {e}")
        raise
