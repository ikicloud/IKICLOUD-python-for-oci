# Case 2 — Insurance Policies Semantic Search on Oracle 23ai (client-side embeddings)

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
An end-to-end proof of concept that turns PDF insurance policies into a searchable
semantic knowledge base on Oracle 23ai. Text is extracted with **OCI Document Understanding**,
then **chunked and embedded on the client (Python)** using **Cohere `embed-multilingual-v3.0` via OCI Generative AI**.  
Both chunks and 1024-dim vectors are written directly to Oracle, enabling semantic search with cosine similarity.

## Who it’s for
Teams who want a simple pipeline where embeddings are computed outside the database
(client-side) and stored in Oracle for fast, meaning-aware retrieval across
insurance documents (life, auto, home).

## What it demonstrates
- PDF text extraction with OCI Document Understanding (DU).
- **Client-side** chunking in Python and generation of **1024-dim embeddings** with Cohere Multilingual v3.
- Direct insert of chunks + vectors into an Oracle table (e.g., `INSURANCE_POLICY_AI` with `VECTOR(1024,FLOAT32)`).
- Semantic search with `VECTOR_DISTANCE(..., COSINE)` and optional top-k filtering.

## Flow
```
PDFs → TextExtraction.py (OCI DU)
↓
Oracle23aiEmbedding.py (client-side chunk + embed with Cohere v3 via OCI GenAI)
↓
INSURANCE_POLICY_AI (TEXT_CHUNK, EMBEDDING)
↓
SemanticSQL.sql (cosine top-k queries)
```

## Notes & limits
- DU language: use ISO-639-2 codes (e.g., `ITA`), or omit to auto-detect.
- Configure IAM policies and region (e.g., `eu-frankfurt-1`) for your tenancy.
- Keep chunk sizes within model limits; ensure consistent preprocessing between ingest and query.
- For larger datasets, create a **vector index (e.g., HNSW)** in Oracle to speed up similarity search.
- Consider deduplication (e.g., hashing) and PII governance if adding real documents.

---

## Files

| File                | Description                                                                                                   |
|---------------------|---------------------------------------------------------------------------------------------------------------|
| **CASE2.jpg**       | Overview image for **Case 2** (end-to-end diagram).                                                           |
| **CASE2.pdf**       | PDF version of the **Case 2** overview/guide.                                                                 |
| **DDL.sql**         | SQL to create the database structure (e.g., `INSURANCE_POLICY_AI` with `TEXT_CHUNK` and `EMBEDDING` vector). |
| **SemanticSQL.sql** | Sample SQL for semantic search using `VECTOR_DISTANCE(..., COSINE)` (expects 1024-dim vectors).               |
| **TextExtraction.py** | Uses **OCI Document Understanding** to extract text from PDFs (can also persist a `.txt` if needed).        |
| **Oracle23aiEmbedding.py** | Reads extracted text, **chunks it**, calls OCI Generative AI (Cohere v3) to get embeddings, then inserts chunks + vectors into Oracle. |
| **USAGE.sh**        | Example command list for reference (not an executable script).                                                |
| **polizza_auto.pdf**| **Sample** insurance PDF (auto) for testing.                                                                  |
| **polizza_casa.pdf**| **Sample** insurance PDF (home) for testing.                                                                  |
| **polizza_vita.pdf**| **Sample** insurance PDF (life) for testing.                                                                  |
| **LICENSE**         | MIT License.                                                                                                  |
