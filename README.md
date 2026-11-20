# Banking Data Engineering on Azure

**An end-to-end, hands-on banking data platform built with Azure Data Factory, ADLS Gen2, Azure Databricks (PySpark, Spark SQL, Delta Lake), SQL Server and Azure Key Vault, using the Medallion (Bronze → Silver → Gold) architecture.**

![Azure Data Factory](https://img.shields.io/badge/Azure%20Data%20Factory-0078D4?logo=microsoftazure&logoColor=white)
![ADLS Gen2](https://img.shields.io/badge/ADLS%20Gen2-0078D4?logo=microsoftazure&logoColor=white)
![Azure Databricks](https://img.shields.io/badge/Azure%20Databricks-FF3621?logo=databricks&logoColor=white)
![PySpark](https://img.shields.io/badge/PySpark-E25A1C?logo=apachespark&logoColor=white)
![Delta Lake](https://img.shields.io/badge/Delta%20Lake-003366)
![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?logo=microsoftsqlserver&logoColor=white)
![Key Vault](https://img.shields.io/badge/Azure%20Key%20Vault-0078D4?logo=microsoftazure&logoColor=white)

> 🚧 **Work in progress.** This repository is built module by module as a learning project. The progress tracker below shows what is complete.

## What this project does

A fictional bank, **FinTrust Bank**, receives customer, account, transaction, loan, credit card and payment data from a SQL Server database and from daily CSV and JSON files. The data contains duplicates, invalid values and orphan keys. This project builds an automated platform that:

1. **Ingests** all sources into Azure Data Lake Storage with Azure Data Factory (full, incremental and metadata-driven loads).
2. **Cleans and validates** the data in Azure Databricks with PySpark, sending bad rows to a `rejected` area with the reason.
3. **Publishes** business-ready Gold tables (customer 360, daily and monthly transactions, branch performance, loans, credit cards).
4. **Serves** the Gold data back to SQL Server for reporting.

```mermaid
flowchart LR
    SQL[("SQL Server")] --> ADF["Azure Data Factory"]
    FILES["CSV / JSON files"] --> ADF
    ADF --> BR["Bronze (raw)"]
    BR --> DBX["Azure Databricks<br/>PySpark + Delta Lake"]
    DBX --> SV["Silver (clean)"]
    DBX --> RJ["Rejected"]
    SV --> GD["Gold (business)"]
    GD --> RPT[("SQL Server reporting / Power BI")]
    KV["Azure Key Vault"] -. secrets .-> ADF
    KV -. secrets .-> DBX
```

The full architecture is described in [Module 1](docs/01-project-overview.md#4-architecture).

## Learning modules

| # | Module | Status |
|---|---|---|
| 1 | [Project introduction, architecture, prerequisites](docs/01-project-overview.md) | ✅ Available |
| 2 | Azure Resource Group | ⬜ Next |
| 3 | Storage Account and ADLS Gen2 | ⬜ |
| 4 | SQL Server fundamentals and BankingDB | ⬜ |
| 5 | Azure Data Factory setup | ⬜ |
| 6 | ADF activities | ⬜ |
| 7 | ADF pipelines | ⬜ |
| 8 | Azure Databricks setup | ⬜ |
| 9 | PySpark fundamentals | ⬜ |
| 10 | Bronze layer | ⬜ |
| 11 | Silver layer and data quality | ⬜ |
| 12 | Gold layer | ⬜ |
| 13 | Incremental loading | ⬜ |
| 14 | Logging, auditing and error handling | ⬜ |
| 15 | End-to-end testing | ⬜ |
| 16 | GitHub publishing and interview preparation | ⬜ |

Each module follows the same format: **What is it → Why → Real-world example → Azure portal steps → Implementation → Explanation → Expected output → Common errors → Assignment → Interview questions.**

## Repository structure (current)

```text
banking-data-engineering/
├── README.md
├── LICENSE
├── .gitignore
├── datasets/                         Fictional sample data (with planted data quality problems)
│   ├── README.md                     Data dictionary
│   ├── branches.csv                  16 rows
│   ├── customers.csv                 303 rows
│   ├── accounts.csv                  451 rows
│   ├── transactions.csv              3,006 rows
│   ├── loans.csv                     121 rows
│   ├── credit_card_transactions.csv  1,503 rows
│   └── payments.json                 601 records (JSON Lines)
├── docs/
│   └── 01-project-overview.md        Module 1
└── scripts/
    └── generate_datasets.py          Reproducible data generator (seeded)
```

Folders for `sql-server/`, `adf/`, `databricks/`, `architecture/` and `exercises/` are added as each module is completed.

## Data and security

- All data is **fictional**. No real customer or banking information is used.
- No passwords, keys or connection strings are stored in this repository. Secrets are kept in Azure Key Vault (Module 14). `.gitignore` blocks common secret files.

## License

[MIT](LICENSE)
