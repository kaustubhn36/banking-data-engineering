/* =====================================================================
   Module 4 - Script 05: SQL fundamentals on BankingDB
   Each exercise has: the question, the query, and the expected result.
   Try writing each query yourself FIRST, then compare with the solution.
   ===================================================================== */

USE BankingDB;
GO

/* ---------------------------------------------------------------------
   E1. SELECT, WHERE, ORDER BY
   Question: list customers who live in Pune, sorted by last name.
   --------------------------------------------------------------------- */
SELECT customer_id, first_name, last_name, city
FROM src.customers
WHERE city = 'Pune'
ORDER BY last_name, first_name;
-- Expected: 33 rows. First three: C00160 Ishaan Bhat, C00009 Meera Bhat, C00174 Aditi Bose

/* ---------------------------------------------------------------------
   E2. INNER JOIN vs LEFT JOIN, and the "duplicate key fan-out" trap
   Question: show each customer with their branch name.
   --------------------------------------------------------------------- */
SELECT c.customer_id, c.first_name, b.branch_id, b.branch_name
FROM src.customers c
INNER JOIN src.branches b ON b.branch_id = c.home_branch_id;
-- Expected: 324 rows (not 303!)
--   -1  : C00050 has branch BR999, which doesn't exist (INNER JOIN drops it)
--   +22 : BR003 appears twice in branches, so each of its 22 customers is returned twice

SELECT COUNT(*) AS left_join_rows
FROM src.customers c
LEFT JOIN src.branches b ON b.branch_id = c.home_branch_id;
-- Expected: 325 (LEFT JOIN keeps C00050 with branch_name = NULL, BR003 still doubled)

/* ---------------------------------------------------------------------
   E3. GROUP BY and aggregate functions
   Question: which 3 states have the most customers?
   --------------------------------------------------------------------- */
SELECT TOP (3) state, COUNT(*) AS customers
FROM src.customers
GROUP BY state
ORDER BY customers DESC;
-- Expected: Maharashtra 92, Gujarat 35, Karnataka 33

/* ---------------------------------------------------------------------
   E4. CTE + ROW_NUMBER() to remove duplicates
   A CTE (WITH ... AS) is a named sub-query you can use like a table.
   ROW_NUMBER() numbers the rows inside each PARTITION (group); keeping
   rn = 1 keeps exactly one row per branch_id.
   This is THE standard de-duplication pattern. You will use it again in
   PySpark in the Silver layer (Module 11).
   --------------------------------------------------------------------- */
WITH branches_dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY modified_at DESC, row_id DESC) AS rn
    FROM src.branches
)
SELECT COUNT(*) AS customers_with_valid_branch
FROM src.customers c
INNER JOIN branches_dedup b ON b.branch_id = c.home_branch_id AND b.rn = 1;
-- Expected: 302 (303 customers minus C00050 with the unknown branch)

/* ---------------------------------------------------------------------
   E5. Window function: DENSE_RANK
   Question: rank branches by number of customers (1 = most customers).
   --------------------------------------------------------------------- */
WITH per_branch AS (
    SELECT home_branch_id, COUNT(*) AS customers
    FROM src.customers
    GROUP BY home_branch_id
)
SELECT home_branch_id,
       customers,
       DENSE_RANK() OVER (ORDER BY customers DESC) AS branch_rank
FROM per_branch
ORDER BY branch_rank, home_branch_id;
-- Expected (top 5 rows): BR011 30 1 | BR008 25 2 | BR002 24 3 | BR006 24 3 | BR003 22 4
-- RANK() would give BR003 rank 5 (it skips a number after a tie); DENSE_RANK() gives 4.

/* ---------------------------------------------------------------------
   E6. Window function: running total
   Question: how many customers did the bank have at the end of each year?
   --------------------------------------------------------------------- */
SELECT LEFT(created_date, 4)                                   AS created_year,
       COUNT(*)                                                AS new_customers,
       SUM(COUNT(*)) OVER (ORDER BY LEFT(created_date, 4)
                           ROWS UNBOUNDED PRECEDING)           AS total_customers
FROM src.customers
GROUP BY LEFT(created_date, 4)
ORDER BY created_year;
-- Expected: 2015: 31 / 31 ... 2021: 35 / 202 ... 2025: 28 / 303

/* ---------------------------------------------------------------------
   E7. Percentage of total with SUM() OVER ()
   Question: what share of customers is in each segment?
   --------------------------------------------------------------------- */
SELECT customer_segment,
       COUNT(*) AS customers,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS pct_of_total
FROM src.customers
GROUP BY customer_segment
ORDER BY customers DESC;
-- Expected: RETAIL 210 69.3 | PREMIUM 66 21.8 | CORPORATE 27 8.9

/* ---------------------------------------------------------------------
   E8. CASE to standardise values (a preview of Silver-layer cleaning)
   Question: map gender to M, F or U (unknown).
   --------------------------------------------------------------------- */
SELECT CASE
           WHEN UPPER(LTRIM(RTRIM(gender))) IN ('M', 'MALE')   THEN 'M'
           WHEN UPPER(LTRIM(RTRIM(gender))) IN ('F', 'FEMALE') THEN 'F'
           ELSE 'U'
       END AS gender_clean,
       COUNT(*) AS customers
FROM src.customers
GROUP BY CASE
             WHEN UPPER(LTRIM(RTRIM(gender))) IN ('M', 'MALE')   THEN 'M'
             WHEN UPPER(LTRIM(RTRIM(gender))) IN ('F', 'FEMALE') THEN 'F'
             ELSE 'U'
         END
ORDER BY gender_clean;
-- Expected: F 170 | M 132 | U 1   ('Male' became M, NULL became U)

/* ---------------------------------------------------------------------
   E9. Spot the difference between two "duplicate" rows
   Question: C00060 and C00065 both appear twice. Are the copies identical?
   --------------------------------------------------------------------- */
SELECT row_id, customer_id, first_name, last_name, phone, email
FROM src.customers
WHERE customer_id IN ('C00060', 'C00065')
ORDER BY customer_id, row_id;
-- Expected: C00060's two rows are identical (exact duplicate).
--           C00065's rows differ in phone: +91-9954942461 vs +91-9000000001.
--           Which one is correct? The source can't tell us, so Silver will keep
--           the most recently modified row and log the conflict.

/* ---------------------------------------------------------------------
   E10. Try to add a PRIMARY KEY on the business key (it will FAIL)
   Run it and read the error message, then continue.
   --------------------------------------------------------------------- */
-- ALTER TABLE src.branches ADD CONSTRAINT UQ_src_branches_branch_id UNIQUE (branch_id);
-- Expected error: Msg 1505 "The CREATE UNIQUE INDEX statement terminated because a
-- duplicate key was found ... The duplicate key value is (BR003)."
-- Lesson: constraints stop bad data from entering a table. This legacy source
-- has none, so the data platform must detect and handle duplicates itself.
