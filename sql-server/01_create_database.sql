/* =====================================================================
   Module 4 - Script 01: create the BankingDB database and its schemas
   Run on: local SQL Server (Express or Developer), connected as yourself
           (Windows Authentication).
   Safe to re-run: every object is created only if it does not exist.
   ===================================================================== */

-- 1. The database
IF DB_ID(N'BankingDB') IS NULL
BEGIN
    CREATE DATABASE BankingDB;
    PRINT 'Database BankingDB created.';
END
ELSE
    PRINT 'Database BankingDB already exists.';
GO

USE BankingDB;
GO

-- 2. Schemas (a schema is a named folder for tables inside a database)
--    stg = staging: raw text exactly as it came from the CSV file
--    src = source:  the "core banking system" tables that ADF will read
IF SCHEMA_ID(N'stg') IS NULL EXEC (N'CREATE SCHEMA stg AUTHORIZATION dbo;');
IF SCHEMA_ID(N'src') IS NULL EXEC (N'CREATE SCHEMA src AUTHORIZATION dbo;');
GO

-- 3. Check
SELECT name AS schema_name
FROM sys.schemas
WHERE name IN (N'stg', N'src')
ORDER BY name;
-- Expected: 2 rows -> src, stg
