

(venv-oci) [oracle@tirocinio-2025 CASO1]$ ls -ltr
total 28
-rw-r--r--. 1 oracle oinstall 2683 Aug 22 11:29 polizza_vita.pdf
-rw-r--r--. 1 oracle oinstall 2672 Aug 22 11:29 polizza_casa.pdf
-rw-r--r--. 1 oracle oinstall 2711 Aug 22 11:29 polizza_auto.pdf
-rw-r--r--. 1 oracle oinstall 4827 Aug 22 11:30 IngestPdfText.py
-rw-r--r--. 1 oracle oinstall 5638 Aug 22 11:36 TextExtraction.py

(venv-oci) [oracle@tirocinio-2025 CASO1]$ python IngestPdfText.py polizza_vita.pdf 
[OK] Inserted 'polizza_vita.pdf' as ID=1 (SHA256=3648614e8249...)

(venv-oci) [oracle@tirocinio-2025 CASO1]$ python IngestPdfText.py polizza_auto.pdf 
[OK] Inserted 'polizza_auto.pdf' as ID=2 (SHA256=b26a305f0d20...)

(venv-oci) [oracle@tirocinio-2025 CASO1]$ python IngestPdfText.py polizza_casa.pdf 
[OK] Inserted 'polizza_casa.pdf' as ID=3 (SHA256=38b6e02fc76e...)

(venv-oci) [oracle@tirocinio-2025 CASO1]$ sqlplus / as sysdba

SQL*Plus: Release 23.0.0.0.0 - Production on Fri Aug 22 11:37:34 2025
Version 23.6.0.24.10

Copyright (c) 1982, 2024, Oracle.  All rights reserved.


Connected to:
Oracle Database 23ai Free Release 23.0.0.0.0 - Develop, Learn, and Run for Free
Version 23.6.0.24.10

SQL> show pdbs

    CON_ID CON_NAME			  OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
	 2 PDB$SEED			  READ ONLY  NO
	 3 FREEPDB1			  READ WRITE NO
SQL> alter session set container=FREEPDB1; 

Session altered.

SQL> CREATE OR REPLACE PROCEDURE GENAI_USER.CHUNK_AND_EMBED_ALL AUTHID DEFINER IS
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
      JSON_VALU  2  E(c.column_value, '$.chunk_data') AS TEXT_CHUNK,  -- try '$.chunk' if needed
      DBM  3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29  S_VECTOR.UTL_TO_EMBEDDING(
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
 30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45  
Procedure created.

SQL> BEGIN
  GENAI_USER.CHUNK_AND_EMBED_ALL;
END;
/
  2    3    4  

PL/SQL procedure successfully completed.




-- check with sql:

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
set lines 400
set pages 400

-- Top-k nearest chunks using cosine distance.
-- Replace 'Find Policy in Milan' with any natural language query.
SELECT
  FILENAME,
  SUBSTR(TEXT_CHUNK, 1, 300) AS PREVIEW,
  VECTOR_DISTANCE(
    EMBEDDING,
    DBMS_VECTOR.UTL_TO_EMBEDDING('find policy in Lodon', JSON(:params)),
    COSINE
  ) AS DIST
FROM GENAI_USER.INSURANCE_POLICY_AI
ORDER BY DIST ASC
FETCH FIRST 10 ROWS ONLY;

FILENAME		       PREVIEW										      DIST
------------------------------ -------------------------------------------------------------------------------- ----------
polizza_vita.pdf	       3. Recesso: il contraente pu recedere entro 14 giorni dalla stipula.		 6.14E-001
			       4. Foro com


  1* select * from GENAI_USER.DOCUMENT_RAW

	ID FILENAME			  FILETEXT									   DOC_SHA256							    LOADED_AT
---------- ------------------------------ -------------------------------------------------------------------------------- ---------------------------------------------------------------- ---------------------------------------------------------------------------
	 1 polizza_vita.pdf		  Compagnia Assicurativa Fittizia S.p.A.					   3648614e8249240724496787fca81098f5b1a53d3d7775f0c66db951c1c19574 22-AUG-25 11.36.56.742073 AM
					  Tipo di polizza: Polizza Vita
					  Numero di polizza: LIFE-2025-045
					  Contraente: J ohn Doe
					  Indirizzo: 221B Baker Street, London, UK                      <================== Returned document
					  Decorrenza: 15/03/2025 - Scadenza: 14/03/2045
					  Dettagli copertura
					  Descrizione
					  Copertura
					  Capitale in caso di decesso, invalidita permanente
					  Esclusioni principali
					  Suicidio nei primi 2 anni, atti di guerra
					  Massimale
					  ? 200.000
					  Premio annuo
					  ? 1,200.00
					  Condizioni generali: La presente polizza regolata dalle leggi vigenti in materia
					   assicurativa.
					  Eventuali controversie saranno gestite presso il foro competente di Milano.
					  Firma digitale della Compagnia Assicurativa
					  Condizioni generali aggiuntive
					  1. Obblighi del contraente: mantenere veridicita nelle dichiarazioni.
					  2. Modalit di pagamento: tramite bonifico bancario annuale.
					  3. Recesso: il contraente pu recedere entro 14 giorni dalla stipula.
					  4. Foro competente: Milano.

	 2 polizza_auto.pdf		  Compagnia Assicurativa Fittizia S.p.A.					   b26a305f0d2065fe6359e24dc0f575a78f8833c07f748332fba9dd8bb6c5c32e 22-AUG-25 11.39.55.342094 AM
					  Tipo di polizza: Polizza RCA Auto
					  Numero di polizza: AUTO-2025-001
					  Contraente: Mario Rossi
					  Indirizzo: Via Garibaldi 45, 20121 Milano (MI), Italia
					  Decorrenza: 01/02/2025 - Scadenza: 31/01/2026
					  Dettagli copertura
					  Descrizione
					  Copertura
					  Responsabilita civile verso terzi, tutela legale
					  Esclusioni principali
					  Guida in stato di ebbrezza, gare sportive
					  Massimale
					  ? 5.000.000
					  Premio annuo
					  ? 620.00
					  Condizioni generali: La presente polizza regolata dalle leggi vigenti in materia
					   assicurativa.
					  Eventuali controversie saranno gestite presso il foro competente di Milano.
					  Firma digitale della Compagnia Assicurativa
					  Condizioni generali aggiuntive
					  1. Obblighi del contraente: mantenere veridicita nelle dichiarazioni.
					  2. Modalit di pagamento: tramite bonifico bancario annuale.
					  3. Recesso: il contraente pu recedere entro 14 giorni dalla stipula.
					  4. Foro competente: Milano.

	 3 polizza_casa.pdf		  Compagnia Assicurativa Fittizia S.p.A.					   38b6e02fc76e102a02b1122492fccb5a0f5313c63565f88b5d7c66256c9af076 22-AUG-25 11.40.09.091441 AM
					  Tipo di polizza: Polizza Casa
					  Numero di polizza: HOME-2025-089
					  Contraente: Anna Mller
					  Indirizzo: Mnchner Str. 12, 80331 Mnchen, DE
					  Decorrenza: 10/04/2025 - Scadenza: 09/04/2026
					  Dettagli copertura
					  Descrizione
					  Copertura
					  Incendio, furto, danni da acqua
					  Esclusioni principali
					  Eventi catastrofali naturali non coperti
					  Massimale
					  ? 100.000
					  Premio annuo
					  ? 450.00
					  Condizioni generali: La presente polizza regolata dalle leggi vigenti in materia
					   assicurativa.
					  Eventuali controversie saranno gestite presso il foro competente di Milano.
					  Firma digitale della Compagnia Assicurativa
					  Condizioni generali aggiuntive
					  1. Obblighi del contraente: mantenere veridicita nelle dichiarazioni.
					  2. Modalit di pagamento: tramite bonifico bancario annuale.
					  3. Recesso: il contraente pu recedere entro 14 giorni dalla stipula.
					  4. Foro competente: Milano.

