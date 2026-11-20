/* =====================================================================
   Module 4 - Script 03: load branches.csv and customers.csv
   1. BULK INSERT the CSV files into the staging tables (all text)
   2. Copy staging -> source tables
   Safe to re-run: tables are emptied first, so you always end up with
   exactly the rows in the CSV files.

   BEFORE RUNNING: copy the project's datasets folder to
       C:\BankingData\datasets\
   If you use a different folder, change the two FROM '...' paths below.
   ===================================================================== */

USE BankingDB;
GO

SET NOCOUNT ON;

-- 1. Empty the tables (full reload)
TRUNCATE TABLE stg.branches_raw;
TRUNCATE TABLE stg.customers_raw;
TRUNCATE TABLE src.branches;
TRUNCATE TABLE src.customers;

-- 2. Load the CSV files into staging
BULK INSERT stg.branches_raw
FROM 'C:\BankingData\datasets\branches.csv'
WITH (
    FORMAT          = 'CSV',    -- understands "quoted, values"
    FIRSTROW        = 2,        -- skip the header line
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',   -- line feed: works for Linux (LF) and Windows (CRLF) files
    CODEPAGE        = '65001',  -- UTF-8
    TABLOCK
);

BULK INSERT stg.customers_raw
FROM 'C:\BankingData\datasets\customers.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '65001',
    TABLOCK
);

-- 3. Copy staging -> source.
--    Values are copied AS-IS (spaces, wrong case and bad dates are kept),
--    because the lake must receive what the source system really holds.
--    Only two technical fixes:
--      REPLACE(..., CHAR(13), '') removes a Windows carriage return that
--                                 can stick to the last column
--      NULLIF(..., '')            turns an empty string into NULL
INSERT INTO src.branches
    (branch_id, branch_name, city, state, ifsc_code, opened_date, manager_name)
SELECT
    NULLIF(branch_id, ''),
    NULLIF(branch_name, ''),
    NULLIF(city, ''),
    NULLIF(state, ''),
    NULLIF(ifsc_code, ''),
    NULLIF(opened_date, ''),
    NULLIF(REPLACE(manager_name, CHAR(13), ''), '')
FROM stg.branches_raw;

INSERT INTO src.customers
    (customer_id, first_name, last_name, date_of_birth, gender, email, phone,
     city, state, customer_segment, kyc_status, home_branch_id, created_date)
SELECT
    NULLIF(customer_id, ''),
    NULLIF(first_name, ''),
    NULLIF(last_name, ''),
    NULLIF(date_of_birth, ''),
    NULLIF(gender, ''),
    NULLIF(email, ''),
    NULLIF(phone, ''),
    NULLIF(city, ''),
    NULLIF(state, ''),
    NULLIF(customer_segment, ''),
    NULLIF(kyc_status, ''),
    NULLIF(home_branch_id, ''),
    NULLIF(REPLACE(created_date, CHAR(13), ''), '')
FROM stg.customers_raw;
GO

-- 4. Check row counts
SELECT 'stg.branches_raw'  AS table_name, COUNT(*) AS row_count FROM stg.branches_raw
UNION ALL SELECT 'src.branches',      COUNT(*) FROM src.branches
UNION ALL SELECT 'stg.customers_raw', COUNT(*) FROM stg.customers_raw
UNION ALL SELECT 'src.customers',     COUNT(*) FROM src.customers;
-- Expected:
--   stg.branches_raw   16
--   src.branches       16
--   stg.customers_raw 303
--   src.customers     303
