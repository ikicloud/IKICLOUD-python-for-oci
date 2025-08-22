-- =============================================================================
-- TEST: Ad-hoc similarity search (embedding the query in-DB on the fly)
-- =============================================================================

-- Recreate the credential if needed (example)
DECLARE
  jo JSON_OBJECT_T := JSON_OBJECT_T();
BEGIN
  jo.put('user_ocid',        'ocid1.user.oc1..xxx');
  jo.put('tenancy_ocid',     'ocid1.tenancy.oc1..xxx');
  jo.put('compartment_ocid', 'ocid1.tenancy.oc1..xxx');
  jo.put('private_key',      '...xxxxxxcA==');
  jo.put('fingerprint',      'xx:xx:xx:xx:xx:xx:xx:xx');

  DBMS_VECTOR.CREATE_CREDENTIAL(
    credential_name => 'OCI_CRED',
    params          => JSON(jo.to_string)
  );
END;
/

-- Parameters for in-DB embedding of the user query
VAR params CLOB
BEGIN
  :params := '{
    "provider": "ocigenai",
    "credential_name": "OCI_CRED",
    "url":"https://inference.generativeai.eu-frankfurt-1.oci.oraclecloud.com/20231130/actions/embedText",
    "model":"cohere.embed-multilingual-v3.0"
  }';
END;
/

-- Optional SQL*Plus formatting for readability
COL FILENAME   FOR A30
COL TEXT_CHUNK FOR A60

-- Top-k nearest chunks using cosine distance.
-- Replace 'Find Policy in Milan' with any natural language query.
SELECT
  FILENAME,
  SUBSTR(TEXT_CHUNK, 1, 300) AS PREVIEW,
  VECTOR_DISTANCE(
    EMBEDDING,
    DBMS_VECTOR.UTL_TO_EMBEDDING('Find Policy in Milan', JSON(:params)),
    COSINE
  ) AS DIST
FROM GENAI_USER.INSURANCE_POLICY_AI
ORDER BY DIST ASC
FETCH FIRST 10 ROWS ONLY;
