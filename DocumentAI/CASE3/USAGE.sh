
(venv-oci) [oracle@tirocinio-2025 CASO3]$ 
(venv-oci) [oracle@tirocinio-2025 CASO3]$ python IngestPdfText.py polizza_auto.pdf 
[OK] Inserted 'polizza_auto.pdf' as ID=4 (SHA256=b26a305f0d20...)
(venv-oci) [oracle@tirocinio-2025 CASO3]$ python IngestPdfText.py polizza_casa.pdf 
[OK] Inserted 'polizza_casa.pdf' as ID=5 (SHA256=38b6e02fc76e...)
(venv-oci) [oracle@tirocinio-2025 CASO3]$ python IngestPdfText.py polizza_vita.pdf 
[OK] Inserted 'polizza_vita.pdf' as ID=6 (SHA256=3648614e8249...)
(venv-oci) [oracle@tirocinio-2025 CASO3]$ sqlplus / as sysdba

SQL*Plus: Release 23.0.0.0.0 - Production on Fri Aug 22 12:54:20 2025
Version 23.6.0.24.10

Copyright (c) 1982, 2024, Oracle.  All rights reserved.


Connected to:
Oracle Database 23ai Free Release 23.0.0.0.0 - Develop, Learn, and Run for Free
Version 23.6.0.24.10

SQL> alter session set container=FREEPDB1; 

Session altered.

-- check CASE1 for PLSQL of CHUNK_AND_EMBED_ALL procedure
SQL> BEGIN
  GENAI_USER.CHUNK_AND_EMBED_ALL;
END;
/
  2    3    4  

PL/SQL procedure successfully completed.


SQL> exit
Disconnected from Oracle Database 23ai Free Release 23.0.0.0.0 - Develop, Learn, and Run for Free
Version 23.6.0.24.10


(venv-oci) [oracle@tirocinio-2025 CASO3]$ python DatabaseSearch.py "find London Policies"

Top 10 results for: 'find London Policies'

 # FILENAME                       TEXT_CHUNK                                                                                    DIST
------------------------------------------------------------------------------------------------------------------------------------
 1 polizza_vita.pdf               Compagnia Assicurativa Fittizia S.p.A. Tipo di polizza: Polizza Vita Numero di polizza:...   0.605
...
...
...
