/* =====================================================================
   Module 4 - Script 06: a view and a stored procedure
   View      = a saved SELECT that you can query like a table.
   Procedure = saved, parameterised SQL code that you run with EXEC.
   Safe to re-run (CREATE OR ALTER).
   ===================================================================== */

USE BankingDB;
GO

/* ---------------------------------------------------------------------
   View: one row per branch (duplicates removed with ROW_NUMBER)
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW src.vw_branches_current
AS
WITH ranked AS (
    SELECT branch_id, branch_name, city, state, ifsc_code, opened_date, manager_name, modified_at,
           ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY modified_at DESC, row_id DESC) AS rn
    FROM src.branches
    WHERE branch_id IS NOT NULL
)
SELECT branch_id, branch_name, city, state, ifsc_code, opened_date, manager_name, modified_at
FROM ranked
WHERE rn = 1;
GO

/* ---------------------------------------------------------------------
   Procedure: customer summary per branch, optionally for one state
   @state = NULL (the default) means "all states".
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE src.usp_branch_customer_summary
    @state NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT b.branch_id,
           b.branch_name,
           b.state,
           COUNT(c.customer_id)                                        AS customers,
           SUM(CASE WHEN c.customer_segment = 'PREMIUM' THEN 1 ELSE 0 END) AS premium_customers
    FROM src.vw_branches_current b
    LEFT JOIN src.customers c ON c.home_branch_id = b.branch_id
    WHERE (@state IS NULL OR b.state = @state)
    GROUP BY b.branch_id, b.branch_name, b.state
    ORDER BY customers DESC, b.branch_id;
END;
GO

-- Try them
SELECT COUNT(*) AS branches FROM src.vw_branches_current;
-- Expected: 15

EXEC src.usp_branch_customer_summary @state = N'Maharashtra';
-- Expected (6 rows):
--   BR011 Mumbai East Branch  Maharashtra 30 8
--   BR002 Pune Main Branch    Maharashtra 24 7
--   BR003 Nagpur Main Branch  Maharashtra 22 3
--   BR012 Pune East Branch    Maharashtra 22 8
--   BR001 Mumbai Main Branch  Maharashtra 18 7
--   BR013 Nagpur East Branch  Maharashtra 17 7

EXEC src.usp_branch_customer_summary;   -- all 15 branches
