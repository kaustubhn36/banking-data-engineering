/* =====================================================================
   Module 4 - Script 04: data profiling
   "Profiling" = measuring the quality of data before you use it.
   Run each query on its own (select it, press Ctrl+Enter) and compare
   with the expected result in the comment below it.
   ===================================================================== */

USE BankingDB;
GO

/* P1. Duplicate business keys in branches
   GROUP BY puts equal branch_ids together; HAVING keeps groups with more than 1 row. */
SELECT branch_id, COUNT(*) AS times
FROM src.branches
GROUP BY branch_id
HAVING COUNT(*) > 1;
-- Expected: BR003 | 2

/* P2. Duplicate and missing customer_ids */
SELECT customer_id, COUNT(*) AS times
FROM src.customers
GROUP BY customer_id
HAVING COUNT(*) > 1 OR customer_id IS NULL;
-- Expected: 3 rows -> NULL | 1, C00060 | 2, C00065 | 2

/* P3. NULL count per column (one row, one number per column) */
SELECT
    COUNT(*)                                              AS total_rows,
    SUM(CASE WHEN customer_id    IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN email          IS NULL THEN 1 ELSE 0 END) AS null_email,
    SUM(CASE WHEN gender         IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN home_branch_id IS NULL THEN 1 ELSE 0 END) AS null_home_branch
FROM src.customers;
-- Expected: 303 | 1 | 1 | 1 | 0

/* P4. Orphan foreign keys: customers whose home branch does not exist.
   LEFT JOIN keeps every customer; b.branch_id is NULL when no branch matched. */
SELECT c.customer_id, c.home_branch_id
FROM src.customers c
LEFT JOIN src.branches b ON b.branch_id = c.home_branch_id
WHERE b.branch_id IS NULL;
-- Expected: C00050 | BR999

/* P5. Dates that are not real dates.
   TRY_CONVERT returns NULL instead of an error when the value can't be converted.
   Style 23 = yyyy-mm-dd. */
SELECT customer_id, date_of_birth
FROM src.customers
WHERE date_of_birth IS NOT NULL
  AND TRY_CONVERT(date, date_of_birth, 23) IS NULL;
-- Expected: C00020 | 1990-02-30   (30 February does not exist)
--           C00055 | 15/08/1985   (wrong format)

/* P6. Dates in the future (a customer can't be born in 2030) */
SELECT customer_id, date_of_birth
FROM src.customers
WHERE TRY_CONVERT(date, date_of_birth, 23) > CAST(SYSDATETIME() AS date);
-- Expected: C00025 | 2030-05-01

/* P7. Values outside the allowed list */
SELECT 'gender' AS column_name, gender AS value, COUNT(*) AS cnt
FROM src.customers
WHERE gender IS NULL OR gender NOT IN ('M', 'F')
GROUP BY gender
UNION ALL
SELECT 'kyc_status', kyc_status, COUNT(*)
FROM src.customers
WHERE kyc_status COLLATE Latin1_General_CS_AS NOT IN ('VERIFIED', 'PENDING', 'REJECTED')
GROUP BY kyc_status;
-- Expected: gender | NULL | 1
--           gender | Male | 1
--           kyc_status | verified | 1
-- Note: COLLATE ..._CS_AS makes the comparison Case-Sensitive. SQL Server's
-- default collation is case-INsensitive, so without it 'verified' = 'VERIFIED'.

/* P8. Text with extra spaces or wrong case */
SELECT customer_id,
       '[' + first_name + ']' AS first_name_with_brackets,
       '[' + last_name  + ']' AS last_name_with_brackets
FROM src.customers
WHERE first_name <> LTRIM(RTRIM(first_name))
   OR DATALENGTH(last_name) <> DATALENGTH(RTRIM(last_name))
   OR first_name COLLATE Latin1_General_CS_AS = LOWER(first_name);
-- Expected: C00030 | [  rahul ] | [SHARMA ]
-- Note: SQL Server ignores trailing spaces when comparing with '=' or '<>',
-- so DATALENGTH (number of bytes) is used to detect them.

/* P9. Missing values in branches */
SELECT branch_id, branch_name, manager_name
FROM src.branches
WHERE manager_name IS NULL;
-- Expected: BR014 | Bengaluru East Branch | NULL

/* P10. One-page quality summary */
SELECT 'Duplicate branch_id'           AS check_name, COUNT(*) AS issues FROM (SELECT branch_id FROM src.branches GROUP BY branch_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'Duplicate customer_id',      COUNT(*) FROM (SELECT customer_id FROM src.customers WHERE customer_id IS NOT NULL GROUP BY customer_id HAVING COUNT(*) > 1) d
UNION ALL SELECT 'Missing customer_id',        COUNT(*) FROM src.customers WHERE customer_id IS NULL
UNION ALL SELECT 'Orphan home_branch_id',      COUNT(*) FROM src.customers c WHERE NOT EXISTS (SELECT 1 FROM src.branches b WHERE b.branch_id = c.home_branch_id)
UNION ALL SELECT 'Invalid date_of_birth',      COUNT(*) FROM src.customers WHERE date_of_birth IS NOT NULL AND TRY_CONVERT(date, date_of_birth, 23) IS NULL
UNION ALL SELECT 'Future date_of_birth',       COUNT(*) FROM src.customers WHERE TRY_CONVERT(date, date_of_birth, 23) > CAST(SYSDATETIME() AS date)
UNION ALL SELECT 'Missing branch manager',     COUNT(*) FROM src.branches WHERE manager_name IS NULL;
-- Expected: 1, 2, 1, 1, 2, 1, 1
