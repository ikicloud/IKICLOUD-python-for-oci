# Case 3 — Insurance Policies Semantic Search on Oracle 23ai (server-side embeddings via PL/SQL)


## License & Copyright

**Copyright (c) 2025 IKI CLOUD**

This repository is provided by IKI CLOUD for demonstration and proof-of-concept (POC) purposes.  
It is released under the **MIT License**, see LICENSE.

**Important notice (production use)**  
You are free to use, modify, and redistribute the code under the MIT License.  
However, if you plan to adapt or deploy any part of this project in **production environments**,  
please **contact the IKI CLOUD team first**: info@iki-cloud.com.

**Third-party components**  
This project uses third-party libraries, including Oracle Python SDKs (e.g., `oci`, `oracledb`)  
that are distributed under their own licenses (e.g., UPL). Using OCI Generative AI and Cohere  
models is subject to the respective service terms. Make sure you review and comply with all  
third-party license terms and acceptable-use policies.

**No affiliation / trademarks**  
Oracle, OCI, Cohere, and other names may be trademarks of their respective owners.  
IKI CLOUD is not affiliated with those vendors beyond publicly available services/libraries.

**No warranty**  
The software is provided “AS IS”, without warranties of any kind, express or implied, including  
merchantability, fitness for a particular purpose, and non-infringement.

**Security & data**  
Samples are fictional and for testing only. Do not store sensitive or personal data unless you  
have implemented appropriate security, compliance, retention, and governance controls.

---

## What it is
An end-to-end proof of concept that converts PDF insurance policies into a searchable
semantic knowledge base on Oracle 23ai. Text is extracted with **OCI Document Understanding**, ingested as raw
content into Oracle, and then **chunking & embeddings are performed server-side in PL/SQL**
using `DBMS_VECTOR` with **Cohere `embed-multilingual-v3.0` via OCI Generative AI**.  
Semantic search runs in-DB with cosine similarity.

## Who it’s for
Teams that prefer keeping the entire embedding pipeline **inside Oracle** (data stays in DB),
with simple Python for ingestion and querying.

## What it demonstrates
- PDF text extraction with OCI Document Understanding (DU).
- Ingestion of raw text rows into `GENAI_USER.DOCUMENT_RAW` (CLOB).
- **Server-side** chunking (`DBMS_VECTOR.UTL_TO_CHUNKS`) and **1024-dim embeddings**
  (`DBMS_VECTOR.UTL_TO_EMBEDDING` using Cohere Multilingual v3).
- Python search client (`DatabaseSearch.py`) that issues semantic queries.

## Flow
```
File System (PDF/JPG/PNG)
      │
      ▼
IngestPdfText.py  ──► TextExtraction.py (OCI DU) ──► raw text
      │
      ▼
Oracle 23ai: insert rows into DOCUMENT_RAW
      │
      ▼
PL_SQL.sql: CHUNK_AND_EMBED_ALL
  - dbms_vector.utl_to_chunks
  - dbms_vector.utl_to_embedding (Cohere v3 via OCI GenAI)
      │
      ▼
INSURANCE_POLICY_AI (TEXT_CHUNK, EMBEDDING)
      │
      └─► DatabaseSearch.py (semantic input → DB results)
```

## Notes & limits
- DU language: use ISO-639-2 codes (e.g., `ITA`) or omit for auto-detect.
- Ensure IAM policies and the correct OCI region (e.g., `eu-frankfurt-1`).
- Keep chunk size consistent between **ingest** and **query** paths.
- For larger datasets, add a **vector index** (e.g., HNSW) on the embedding column.
- Consider deduplication (SHA-256) and PII governance before loading real policies.

---

## Files

| File                  | Description                                                                                                              |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------|
| **CASE3.jpg**         | Overview image for **Case 3** (end-to-end diagram).                                                                      |
| **CASE3.pdf**         | PDF version of the **Case 3** overview/guide.                                                                            |
| **DDL.sql**           | DDL for tables (e.g., `DOCUMENT_RAW`, `INSURANCE_POLICY_AI` with `VECTOR(1024,FLOAT32)`).                                |
| **PL_SQL.sql**        | PL/SQL to create `OCI_CRED` (if used) and procedure **`CHUNK_AND_EMBED_ALL`** (server-side chunking + embeddings).       |
| **TextExtraction.py** | Uses **OCI Document Understanding** to extract text from input PDFs.                                                     |
| **IngestPdfText.py**  | Sends files to DU, receives text, and inserts rows into `DOCUMENT_RAW`.                                                  |
| **DatabaseSearch.py** | Python script to submit a semantic prompt and return ranked DB results.                                                  |
| **USAGE.sh**          | Example command list for reference (not an executable script).                                                           |
| **polizza_auto.pdf**  | **Sample** insurance PDF (auto).                                                                                          |
| **polizza_casa.pdf**  | **Sample** insurance PDF (home).                                                                                          |
| **polizza_vita.pdf**  | **Sample** insurance PDF (life).                                                                                          |
| **LICENSE**           | MIT License.                                                                                                             |
