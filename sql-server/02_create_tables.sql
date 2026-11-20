/* =====================================================================
   Module 4 - Script 02: create the staging and source tables
   Re-running this script DROPS and recreates the tables (all rows are lost).
   Run 03_load_data.sql afterwards to load the data again.
   ===================================================================== */

USE BankingDB;
GO

/* ---------------------------------------------------------------------
   STAGING tables: every column is text (NVARCHAR).
   Why? BULK INSERT fails on the first value that doesn't fit the data
   type (for example the date '15/08/1985' into a DATE column). Loading
   as text first means the load never fails, and we decide later what to
   do with bad values.
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS stg.branches_raw;
CREATE TABLE stg.branches_raw (
    branch_id     NVARCHAR(50)  NULL,
    branch_name   NVARCHAR(200) NULL,
    city          NVARCHAR(100) NULL,
    state         NVARCHAR(100) NULL,
    ifsc_code     NVARCHAR(50)  NULL,
    opened_date   NVARCHAR(50)  NULL,
    manager_name  NVARCHAR(200) NULL
);

DROP TABLE IF EXISTS stg.customers_raw;
CREATE TABLE stg.customers_raw (
    customer_id       NVARCHAR(50)  NULL,
    first_name        NVARCHAR(100) NULL,
    last_name         NVARCHAR(100) NULL,
    date_of_birth     NVARCHAR(50)  NULL,
    gender            NVARCHAR(20)  NULL,
    email             NVARCHAR(200) NULL,
    phone             NVARCHAR(50)  NULL,
    city              NVARCHAR(100) NULL,
    state             NVARCHAR(100) NULL,
    customer_segment  NVARCHAR(50)  NULL,
    kyc_status        NVARCHAR(50)  NULL,
    home_branch_id    NVARCHAR(50)  NULL,
    created_date      NVARCHAR(50)  NULL
);
GO

/* ---------------------------------------------------------------------
   SOURCE tables: our pretend "core banking system".
   - row_id      : surrogate key (a number the database generates). It is
                   the PRIMARY KEY because the business keys (branch_id,
                   customer_id) contain duplicates in this legacy system.
   - modified_at : when the row was last inserted or changed. ADF uses it
                   for incremental (watermark) loads in Module 13.
   - date columns stay as text on purpose: this legacy system accepted
     dates in more than one format. Cleaning them is the job of the
     Silver layer (Module 11), not of the source system.
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS src.customers;
DROP TABLE IF EXISTS src.branches;

CREATE TABLE src.branches (
    row_id        INT IDENTITY(1,1) NOT NULL,
    branch_id     VARCHAR(10)   NULL,
    branch_name   NVARCHAR(100) NULL,
    city          NVARCHAR(50)  NULL,
    state         NVARCHAR(50)  NULL,
    ifsc_code     VARCHAR(11)   NULL,
    opened_date   VARCHAR(20)   NULL,
    manager_name  NVARCHAR(100) NULL,
    modified_at   DATETIME2(3)  NOT NULL CONSTRAINT DF_branches_modified_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_src_branches PRIMARY KEY CLUSTERED (row_id)
);

CREATE TABLE src.customers (
    row_id            INT IDENTITY(1,1) NOT NULL,
    customer_id       VARCHAR(10)   NULL,
    first_name        NVARCHAR(50)  NULL,
    last_name         NVARCHAR(50)  NULL,
    date_of_birth     VARCHAR(20)   NULL,
    gender            VARCHAR(10)   NULL,
    email             NVARCHAR(100) NULL,
    phone             VARCHAR(20)   NULL,
    city              NVARCHAR(50)  NULL,
    state             NVARCHAR(50)  NULL,
    customer_segment  VARCHAR(20)   NULL,
    kyc_status        VARCHAR(20)   NULL,
    home_branch_id    VARCHAR(10)   NULL,
    created_date      VARCHAR(20)   NULL,
    modified_at       DATETIME2(3)  NOT NULL CONSTRAINT DF_customers_modified_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_src_customers PRIMARY KEY CLUSTERED (row_id)
);

-- Index on modified_at: incremental loads filter on this column
CREATE INDEX IX_src_customers_modified_at ON src.customers (modified_at);
CREATE INDEX IX_src_branches_modified_at  ON src.branches  (modified_at);
GO

-- Check: 4 tables
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ('stg', 'src')
ORDER BY s.name, t.name;
-- Expected: src.branches, src.customers, stg.branches_raw, stg.customers_raw
