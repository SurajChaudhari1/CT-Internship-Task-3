# CT-Internship-Task-3

## Task 3 — Database Migration (MySQL to PostgreSQL)

**File:** `task3_migration.sql`  
**Schema:** `task3_migration`

### What it does

Simulates a **MySQL to PostgreSQL migration** using the same sales dataset.

Since only **pgAdmin/PostgreSQL** is available, the MySQL source database is simulated within PostgreSQL before migrating the data to PostgreSQL target tables.

### Migration Steps

1. Load CSV into `mysql_staging` table (MySQL source simulation)
2. Create `mysql_products` and `mysql_orders` tables
3. Migrate data into PostgreSQL `products` table
4. Migrate data into PostgreSQL `orders` table
5. Verify data integrity after migration

---

## Key Differences Demonstrated

| MySQL | PostgreSQL |
|---------|------------|
| AUTO_INCREMENT | SERIAL |
| DECIMAL | NUMERIC |
| No `created_at` by default | `created_at TIMESTAMP` added |

---

## Verification Queries

The script validates migration success using:

- Row count comparison (MySQL vs PostgreSQL)
- Total revenue match check
- NULL value check
- Duplicate record check
- Category-wise summary

---

## How to Run

1. Open `task3_migration.sql` in pgAdmin Query Tool
2. Update the CSV file path in the `COPY` command
3. Press **F5**
