-- =============================================================================
-- SAFETY: Drop credential if it exists (ignore error if not present)
-- =============================================================================
BEGIN
  DBMS_VECTOR.DROP_CREDENTIAL('OCI_CRED');
EXCEPTION
  WHEN OTHERS THEN NULL; -- Ignore if the credential doesn't exist yet
END;
/
-- =============================================================================
-- Create the DBMS_VECTOR credential for OCI Generative AI
-- WARNING: Storing a private key inline is sensitive. Prefer OCI Vault / external secrets.
-- =============================================================================
DECLARE
  jo JSON_OBJECT_T := JSON_OBJECT_T();
BEGIN
  -- Replace the values below with your real OCIDs and key/fingerprint.
  jo.put('user_ocid',        'ocid1.user.oc1..xxxxxxx');
  jo.put('tenancy_ocid',     'ocid1.tenancy.oc1..xxxxxxx');
  jo.put('compartment_ocid', 'ocid1.tenancy.oc1..xxxxxxx');
  jo.put('private_key',      '...xxxxxxx=='); -- Base64-encoded private key or PEM (check docs)
  jo.put('fingerprint',      'xx:xx:xx:xx:xx:xx:xx');

  DBMS_VECTOR.CREATE_CREDENTIAL(
    credential_name => 'OCI_CRED',
    params          => JSON(jo.to_string)
  );
END;
/

-- =============================================================================
-- STORED PROCEDURE: chunk server-side + embed server-side
--   - v_chunk_params controls chunking (by words, max length, overlap, etc.)
--   - v_embed_params configures OCI Generative AI (Cohere Multilingual v3)
-- NOTE:
--   DBMS_VECTOR.UTL_TO_CHUNKS returns a JSON array. Depending on your DB version,
--   the JSON key for the chunk content may be '$.chunk' or '$.chunk_data'.
--   Here we use '$.chunk_data'. If you get NULLs, try '$.chunk' instead.
-- =============================================================================
CREATE OR REPLACE PROCEDURE GENAI_USER.CHUNK_AND_EMBED_ALL AUTHID DEFINER IS
  v_chunk_params CLOB := '{
    "by":"words",
    "max":50,
    "overlap":10,
    "split":"sentence",
    "language":"italian",
    "normalize":"all"
  }';

  v_embed_params CLOB := '{
    "provider":"ocigenai",
    "credential_name":"OCI_CRED",
    "url":"https://inference.generativeai.eu-frankfurt-1.oci.oraclecloud.com/20231130/actions/embedText",
    "model":"cohere.embed-multilingual-v3.0"
  }';
BEGIN
  -- Iterate distinct filenames existing in DOCUMENT_RAW
  FOR r IN (SELECT DISTINCT FILENAME FROM GENAI_USER.DOCUMENT_RAW) LOOP

    -- Clear any previous chunks/embeddings for this file
    DELETE FROM GENAI_USER.INSURANCE_POLICY_AI WHERE FILENAME = r.FILENAME;

    -- Chunk the full text and embed each chunk server-side
    INSERT INTO GENAI_USER.INSURANCE_POLICY_AI (FILENAME, TEXT_CHUNK, EMBEDDING)
    SELECT
      r.FILENAME,
      JSON_VALUE(c.column_value, '$.chunk_data') AS TEXT_CHUNK,  -- try '$.chunk' if needed
      DBMS_VECTOR.UTL_TO_EMBEDDING(
        JSON_VALUE(c.column_value, '$.chunk_data'),
        JSON(v_embed_params)
      ) AS EMBEDDING
    FROM GENAI_USER.DOCUMENT_RAW d
    CROSS JOIN TABLE(
      DBMS_VECTOR.UTL_TO_CHUNKS(
        TO_CLOB(d.FILETEXT),       -- source CLOB
        JSON(v_chunk_params)       -- chunking parameters
      )
    ) c
    WHERE d.FILENAME = r.FILENAME;

    COMMIT;
  END LOOP;
END;
/


-- =============================================================================
-- RUN the procedure to populate INSURANCE_POLICY_AI from existing DOCUMENT_RAW
-- =============================================================================
BEGIN
  GENAI_USER.CHUNK_AND_EMBED_ALL;
END;
/


