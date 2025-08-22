(venv-oci) [oracle@tirocinio-2025 CASO2]$ python Oracle23aiEmbedding.py polizza_vita.pdf 
[OK] Inserted 24 rows from polizza_vita.pdf into GENAI_USER.INSURANCE_POLICY_AI
(venv-oci) [oracle@tirocinio-2025 CASO2]$ python Oracle23aiEmbedding.py polizza_auto.pdf 
[OK] Inserted 24 rows from polizza_auto.pdf into GENAI_USER.INSURANCE_POLICY_AI
(venv-oci) [oracle@tirocinio-2025 CASO2]$ python Oracle23aiEmbedding.py polizza_casa.pdf 
[OK] Inserted 24 rows from polizza_casa.pdf into GENAI_USER.INSURANCE_POLICY_AI
(venv-oci) [oracle@tirocinio-2025 CASO2]$ 

(venv-oci) [oracle@tirocinio-2025 CASO2]$ sqlplus / as sysdba

SQL*Plus: Release 23.0.0.0.0 - Production on Fri Aug 22 12:34:04 2025
Version 23.6.0.24.10

Copyright (c) 1982, 2024, Oracle.  All rights reserved.


Connected to:
Oracle Database 23ai Free Release 23.0.0.0.0 - Develop, Learn, and Run for Free
Version 23.6.0.24.10

SQL> alter session set container=FREEPDB1; 

Session altered.

SQL> 
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
/SQL> SQL> SQL>   2    3    4    5    6    7    8    9  

PL/SQL procedure successfully completed.


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
    DBMS_VECTOR.UTL_TO_EMBEDDING('Find Policy in London', JSON(:params)),
    COSINE
  ) AS DIST
FROM GENAI_USER.INSURANCE_POLICY_AI
ORDER BY DIST ASC
FETCH FIRST 10 ROWS ONLY;SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11  

FILENAME		       PREVIEW										      DIST
------------------------------ -------------------------------------------------------------------------------- ----------
polizza_vita.pdf	       Indirizzo: 221B Baker Street, London, UK 					4.516E-001
polizza_auto.pdf	       4. Foro competente: Milano.							4.728E-001
polizza_vita.pdf	       4. Foro competente: Milano.							4.733E-001
polizza_casa.pdf	       4. Foro competente: Milano.							4.733E-001
polizza_auto.pdf	       Compagnia Assicurativa Fittizia S.p.A.						4.797E-001
polizza_casa.pdf	       Compagnia Assicurativa Fittizia S.p.A.						4.797E-001
polizza_vita.pdf	       Compagnia Assicurativa Fittizia S.p.A.						4.801E-001
polizza_auto.pdf	       Responsabilita civile verso terzi, tutela legale 				4.853E-001
polizza_auto.pdf	       Contraente: Mario Rossi								4.919E-001
polizza_vita.pdf	       Copertura									4.943E-001

10 rows selected.
