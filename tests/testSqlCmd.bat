REM This batch script runs SQLCMD.exe to output files in the desired format for ingestion into other systems.

REM HEADERLESS

sqlcmd -S localhost -d test -E -W -h-1 -s"," -Q "SET NOCOUNT ON; SELECT LOWER(CONVERT(VARCHAR(500), customer_name, 2)),LOWER(CONVERT(VARCHAR(500), customer_sex, 2)),LOWER(CONVERT(VARCHAR(500), customer_dob, 2)) FROM customers" -o test.csv -w 1024

REM WITH HEADERS

sqlcmd -S localhost -d test -E -W -s"," -Q "SET NOCOUNT ON; SELECT TOP 0 * FROM customers union SELECT LOWER(CONVERT(VARCHAR(500), customer_name, 2)),LOWER(CONVERT(VARCHAR(500), customer_sex, 2)),LOWER(CONVERT(VARCHAR(500), customer_dob, 2)) FROM customers" -o test.csv -w 1024



