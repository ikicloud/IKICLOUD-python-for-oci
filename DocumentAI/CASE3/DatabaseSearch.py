#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# -----------------------------------------------------------------------------
# Copyright (c) 2025 IKI CLOUD
# License: MIT (see LICENSE)
#
# POC code provided for evaluation and educational use.
# If you plan to adapt or deploy this in production, please contact IKI CLOUD first: info@iki-cloud.com.
#
# This project uses third-party libraries (e.g., Oracle Python SDKs) under their own licenses.
# Review and comply with all third-party license terms.
# -----------------------------------------------------------------------------

import sys
import array
import oracledb
import oci
from textwrap import shorten
from oci.generative_ai_inference import GenerativeAiInferenceClient
from oci.generative_ai_inference.models import EmbedTextDetails, OnDemandServingMode

# ======== CONFIG ========
# Oracle DB connection parameters.
# - DB_DSN format: "host:port/SERVICE_NAME" (e.g., "hostname:1521/FREEPDB1")
# - DB_USER/DB_PASS are the credentials of the schema that holds the vectors table.
DB_DSN  = "tirocinio-2025:1521/FREEPDB1"
DB_USER = "GENAI_USER"
DB_PASS = "GENAI_USER"

# OCI configuration for Generative AI Inference.
# - CONFIG_FILE/CONFIG_PROFILE: point to your OCI CLI config (tenancy, user, fingerprint, key_file, region)
# - COMPARTMENT_ID: compartment where the request will be executed/billed
# - ENDPOINT: regional endpoint for Generative AI Inference; must match your config region
# - MODEL_ID: embedding model identifier (Cohere Multilingual v3, 1024-dim)
CONFIG_FILE    = "/home/oracle/POC_GENAI_NODELETE/.oci/config"
CONFIG_PROFILE = "DEFAULT"
COMPARTMENT_ID = "ocid1.tenancy.oc1..xxx"
ENDPOINT       = "https://inference.generativeai.eu-frankfurt-1.oci.oraclecloud.com"
MODEL_ID       = "cohere.embed-multilingual-v3.0"

# Max results to return from the vector search and preview width for console output.
TOPK  = 10
WIDTH = 90

# Vector similarity query (COSINE) against the new schema:
# - Table: GENAI_USER.INSURANCE_POLICY_AI
# - Columns: FILENAME (VARCHAR2), TEXT_CHUNK (CLOB), EMBEDDING (VECTOR(1024, FLOAT32))
# - We pass the query vector from Python via bind variable :query_vector
SQL = """
SELECT filename,
       text_chunk,
       VECTOR_DISTANCE(embedding, :query_vector, COSINE) AS dist
FROM   genai_user.insurance_policy_ai
ORDER  BY dist ASC
FETCH  FIRST :topk ROWS ONLY
"""

# ======== FUNCTIONS ========

def embed_query(text: str) -> array.array:
    """
    Compute the query embedding **client-side** using the OCI SDK.

    Steps:
      1) Load OCI config (keys, tenancy, user, fingerprint, key_file, region).
      2) Create GenerativeAiInference client pointing to the regional ENDPOINT.
      3) Build the request (EmbedTextDetails) with model, compartment, and the query text.
      4) Call embed_text and extract the embedding from the response.
      5) Convert to array('f') [float32] for binding into Oracle VECTOR.

    IMPORTANT:
      - ENDPOINT must match the region in your OCI profile.
      - Your principal must have IAM policy to use the "generative-ai-family".
      - The model must be available on-demand in your tenancy/region.
    """
    # 1) Load config (profile DEFAULT).
    cfg = oci.config.from_file(CONFIG_FILE, CONFIG_PROFILE)

    # 2) Create the client (explicit service_endpoint to avoid region mismatch).
    client = GenerativeAiInferenceClient(config=cfg, service_endpoint=ENDPOINT)

    # 3) Prepare the embedding request for a single input (the user's query).
    details = EmbedTextDetails(
        serving_mode=OnDemandServingMode(model_id=MODEL_ID),
        compartment_id=COMPARTMENT_ID,
        inputs=[text],
    )

    # 4) Call the embedding API. If you hit 404/401, it's usually region/endpoint/IAM issues.
    resp = client.embed_text(details)

    # 5) Extract the vector. SDKs may expose .values, .embedding, or just a list.
    emb = resp.data.embeddings[0]
    if hasattr(emb, "values"):
        emb = emb.values
    elif hasattr(emb, "embedding"):
        emb = emb.embedding
    elif isinstance(emb, list):
        pass  # already a list of floats
    else:
        raise RuntimeError("Unknown embedding format in OCI response")

    # Convert to float32 array for Oracle binding (VECTOR(…, FLOAT32)).
    return array.array("f", [float(x) for x in emb])

def main():
    """
    Minimal flow:
      - Accept a single CLI argument (the natural language query).
      - Compute the embedding client-side with OCI.
      - Run a COSINE similarity search in Oracle 23ai against stored vectors.
      - Read CLOBs while the cursor is open, then print a neat table.
    """
    if len(sys.argv) != 2:
        print('Usage: python simple_vector_search.py "find policy in Milan"')
        sys.exit(1)

    query_text = sys.argv[1]

    # 1) Compute the query embedding outside the DB.
    query_vec = embed_query(query_text)

    # 2) Connect to the database and execute the similarity query.
    rows = []
    with oracledb.connect(user=DB_USER, password=DB_PASS, dsn=DB_DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(SQL, {"query_vector": query_vec, "topk": TOPK})

            # Read rows while the cursor is open (so CLOBs can be .read()).
            for filename, chunk, dist in cur:
                if hasattr(chunk, "read"):  # TEXT_CHUNK is a CLOB → LOB with .read()
                    chunk = chunk.read()
                rows.append((filename, chunk, dist))

    # 3) Pretty-print results with a single-line preview of TEXT_CHUNK.
    print(f"\nTop {TOPK} results for: {query_text!r}\n")
    print(f"{'#':>2} {'FILENAME':30} {'TEXT_CHUNK':{WIDTH}} {'DIST':>7}")
    print("-" * (2 + 1 + 30 + 1 + WIDTH + 1 + 7))

    for i, (filename, chunk, dist) in enumerate(rows, 1):
        # Normalize whitespace to a single line and shorten to WIDTH characters.
        txt = " ".join((chunk or "").split())
        preview = shorten(txt, width=WIDTH, placeholder="...")
        print(f"{i:>2} { (filename or ''):30} {preview:{WIDTH}} {dist:7.3f}")

# Script entrypoint.
if __name__ == "__main__":
    main()
