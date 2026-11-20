/* =====================================================================
   Module 5 - Script 07: give the ADF login read-only access to BankingDB
   BEFORE RUNNING:
     1. Switch SQL Server to "SQL Server and Windows Authentication mode"
        and restart the service (Module 5 lab, Step 2).
     2. Create the login adf_reader in SSMS: Security > Logins > New Login
        (Module 5 lab, Step 3). The password is typed ONLY in that dialog
        and in Azure Key Vault. It is never written in this file or in Git.
   Safe to re-run.
   ===================================================================== */

USE BankingDB;
GO

-- 1. Stop with a clear message if the login hasn't been created yet
IF SUSER_ID(N'adf_reader') IS NULL
BEGIN
    RAISERROR(N'Login adf_reader does not exist. Create it first (Module 5 lab, Step 3).', 16, 1);
    RETURN;
END;

-- 2. A database user for the login (a login lets you into the SERVER,
--    a user lets you into one DATABASE)
IF USER_ID(N'adf_reader') IS NULL
    CREATE USER adf_reader FOR LOGIN adf_reader WITH DEFAULT_SCHEMA = src;

-- 3. Read-only: db_datareader can SELECT from every table and view,
--    but cannot INSERT, UPDATE, DELETE or change anything (least privilege)
IF IS_ROLEMEMBER(N'db_datareader', N'adf_reader') = 0
    ALTER ROLE db_datareader ADD MEMBER adf_reader;
GO

-- 4. Check
SELECT u.name AS user_name, r.name AS role_name
FROM sys.database_role_members m
JOIN sys.database_principals r ON r.principal_id = m.role_principal_id
JOIN sys.database_principals u ON u.principal_id = m.member_principal_id
WHERE u.name = N'adf_reader';
-- Expected: adf_reader | db_datareader
