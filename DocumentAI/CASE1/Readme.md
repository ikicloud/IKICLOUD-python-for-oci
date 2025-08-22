## License & Copyright

**Copyright (c) 2025 IKI CLOUD**

This repository is provided by IKI CLOUD for demonstration and proof-of-concept (POC) purposes.  
It is released under the **MIT License** (see `LICENSE`).

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

## Case 1 — Insurance Policies Semantic Search on Oracle 23ai (OCI)

**What it is**  
An end-to-end proof of concept that turns PDF insurance policies into a searchable
semantic knowledge base on Oracle 23ai. The pipeline extracts text (OCI Document
Understanding), ingests it into Oracle, chunks the text and generates 1024-dim
embeddings with Cohere `embed-multilingual-v3.0` (via OCI Generative AI), and
enables semantic search with cosine similarity.

**Who it’s for**  
Teams who need fast, multilingual, meaning-aware retrieval across insurance
documents (life, auto, home), with all data stored and queried in Oracle.

**What it demonstrates**
- PDF text extraction with OCI Document Understanding.
- Raw text ingestion into `GENAI_USER.DOCUMENT_RAW` (CLOB).
- Server-side chunking (`DBMS_VECTOR.UTL_TO_CHUNKS`) and embeddings
  (`DBMS_VECTOR.UTL_TO_EMBEDDING`) using Cohere Multilingual v3.
- Semantic search with `VECTOR_DISTANCE(..., COSINE)` against `VECTOR(1024,FLOAT32)`.

**Flow**
PDFs → TextExtraction.py → DOCUMENT_RAW
↓ (PL/SQL: CHUNK_AND_EMBED_ALL)
INSURANCE_POLICY_AI (TEXT_CHUNK, EMBEDDING)
↓
Semantic SQL (cosine top-k)

markdown
Copia
Modifica

**Key files**
- `TextExtraction.py` — calls OCI Document Understanding to extract text from PDFs.
- `IngestPdfText.py` — inserts full text into `DOCUMENT_RAW` and hashes for dedupe.
- `PL_SQL.sql` — creates OCI credential and `CHUNK_AND_EMBED_ALL` (chunk + embed).
- `SemanticSQL.sql` — example of in-DB query embedding and cosine search.
- `DDL.sql` — table creation for `DOCUMENT_RAW` and `INSURANCE_POLICY_AI`.
- `USAGE.sh` — example command list (reference only, not executable).

**Notes & limits**
- Use ISO-639-2 language codes for DU (e.g., `ITA`) or omit for auto-detect.
- Ensure IAM policies and region (`eu-frankfurt-1`) match your OCI tenancy.
- For larger datasets, add a vector index (HNSW) and enforce data governance (PII).
If you want, I can also add a short “Credits & Third-party Licenses” section listing oci and oracledb (UPL) and a one-liner about Cohere model usage via OCI.


| File              | Description                                                                                                   |
|-------------------|---------------------------------------------------------------------------------------------------------------|
| CASE1.jpg         | Overview image for **Case 1** (diagram/summary).                                                              |
| CASE1.pdf         | PDF version of the **Case 1** overview/guide.                                                                 |
| DDL.sql           | SQL to create the database structure (tables: `DOCUMENT_RAW`, `INSURANCE_POLICY_AI`, etc.).                   |
| PL_SQL.sql        | PL/SQL to create `OCI_CRED` and the `CHUNK_AND_EMBED_ALL` procedure (server-side chunking + embeddings).      |
| SemanticSQL.sql   | Sample SQL for semantic search (in-DB query embedding + `VECTOR_DISTANCE(..., COSINE)`).                      |
| IngestPdfText.py  | Python script that ingests extracted text into `DOCUMENT_RAW` (computes SHA-256 for deduplication).           |
| TextExtraction.py | Python script using **OCI Document Understanding** to extract text from PDFs (CLI can also write a `.txt`).   |
| USAGE.sh          | **Example** command list for reference only (not an executable script).                                       |
| polizza_auto.pdf  | **Sample** insurance PDF (auto) used for testing.                                                             |
| polizza_casa.pdf  | **Sample** insurance PDF (home) used for testing.                                                             |
| polizza_vita.pdf  | **Sample** insurance PDF (life) used for testing.                                                             |
