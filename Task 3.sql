- ============================================================
-- PHASE 1: Source Database (MySQL Simulation)
-- ============================================================
 
CREATE SCHEMA IF NOT EXISTS task3_migration;
 
DROP TABLE IF EXISTS task3_migration.orders          CASCADE;
DROP TABLE IF EXISTS task3_migration.products        CASCADE;
DROP TABLE IF EXISTS task3_migration.mysql_orders    CASCADE;
DROP TABLE IF EXISTS task3_migration.mysql_products  CASCADE;
DROP TABLE IF EXISTS task3_migration.mysql_staging   CASCADE;
 
-- MySQL Source: Staging Table
-- MySQL mein DECIMAL use hota hai, PostgreSQL mein NUMERIC
CREATE TABLE task3_migration.mysql_staging (
    txn_id      INT            NOT NULL,
    txn_date    DATE           NOT NULL,
    category    VARCHAR(50),
    pname       VARCHAR(150),
    qty         INT,
    unit_price  NUMERIC(10,2),
    revenue     NUMERIC(10,2),
    region      VARCHAR(30),
    payment     VARCHAR(20)
);
 
-- CSV Import into MySQL source
COPY task3_migration.mysql_staging (
    txn_id, txn_date, category, pname,
    qty, unit_price, revenue, region, payment
)
FROM 'D:\Codetech It Solution Internship\Online Sales Data.csv'
DELIMITER ','
CSV HEADER;
 
-- MySQL Source: Products Table
-- MySQL mein AUTO_INCREMENT hota hai, PostgreSQL mein SERIAL
CREATE TABLE task3_migration.mysql_products (
    pid       SERIAL         PRIMARY KEY,
    pname     VARCHAR(150)   NOT NULL,
    category  VARCHAR(50)    NOT NULL,
    price     NUMERIC(10,2)  NOT NULL
);
 
INSERT INTO task3_migration.mysql_products (pname, category, price)
SELECT DISTINCT pname, category, unit_price
FROM task3_migration.mysql_staging
ORDER BY pname;
 
-- MySQL Source: Orders Table
CREATE TABLE task3_migration.mysql_orders (
    oid      INT            PRIMARY KEY,
    odate    DATE           NOT NULL,
    pid      INT            REFERENCES task3_migration.mysql_products(pid),
    qty      INT            NOT NULL,
    revenue  NUMERIC(10,2)  NOT NULL,
    region   VARCHAR(30)    NOT NULL,
    payment  VARCHAR(20)    NOT NULL
);
 
INSERT INTO task3_migration.mysql_orders (oid, odate, pid, qty, revenue, region, payment)
SELECT
    ROW_NUMBER() OVER (ORDER BY s.txn_id)  AS oid,
    s.txn_date,
    p.pid,
    s.qty,
    s.revenue,
    s.region,
    s.payment
FROM task3_migration.mysql_staging  AS s
INNER JOIN task3_migration.mysql_products AS p
    ON s.pname = p.pname;
 
-- Verify MySQL source
SELECT 'mysql_products' AS tbl, COUNT(*) AS rows FROM task3_migration.mysql_products
UNION ALL
SELECT 'mysql_orders',           COUNT(*)          FROM task3_migration.mysql_orders;
 
 
-- ============================================================
-- PHASE 2: Target Database (PostgreSQL)
-- mysql tables se postgresql tables mein migrate karo
-- ============================================================
 
-- PostgreSQL Target: Products Table
-- SERIAL = MySQL AUTO_INCREMENT
-- NUMERIC = MySQL DECIMAL
-- created_at = PostgreSQL extra feature 
CREATE TABLE task3_migration.products (
    pid        SERIAL         PRIMARY KEY,
    pname      VARCHAR(150)   NOT NULL,
    category   VARCHAR(50)    NOT NULL,
    price      NUMERIC(10,2)  NOT NULL,
    created_at TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);
 
-- Migrate products: MySQL → PostgreSQL
INSERT INTO task3_migration.products (pname, category, price)
SELECT pname, category, price
FROM task3_migration.mysql_products
ORDER BY pid;
 
-- PostgreSQL Target: Orders Table
CREATE TABLE task3_migration.orders (
    oid        INT            PRIMARY KEY,
    odate      DATE           NOT NULL,
    pid        INT            REFERENCES task3_migration.products(pid),
    qty        INT            NOT NULL,
    revenue    NUMERIC(10,2)  NOT NULL,
    region     VARCHAR(30)    NOT NULL,
    payment    VARCHAR(20)    NOT NULL,
    created_at TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);
 
-- Migrate orders: MySQL → PostgreSQL
INSERT INTO task3_migration.orders (oid, odate, pid, qty, revenue, region, payment)
SELECT oid, odate, pid, qty, revenue, region, payment
FROM task3_migration.mysql_orders
ORDER BY oid;
 
 
-- ============================================================
-- PHASE 3: Data Integrity Verification
-- ============================================================
 
-- Row count: MySQL vs PostgreSQL
SELECT 'mysql_products'  AS table_name, COUNT(*) AS row_count FROM task3_migration.mysql_products
UNION ALL
SELECT 'pg_products',                   COUNT(*)              FROM task3_migration.products
UNION ALL
SELECT 'mysql_orders',                  COUNT(*)              FROM task3_migration.mysql_orders
UNION ALL
SELECT 'pg_orders',                     COUNT(*)              FROM task3_migration.orders;
 
-- Revenue match: MySQL vs PostgreSQL
SELECT 'MySQL Source'       AS source, ROUND(SUM(revenue), 2) AS total_revenue FROM task3_migration.mysql_orders
UNION ALL
SELECT 'PostgreSQL Target',             ROUND(SUM(revenue), 2)                 FROM task3_migration.orders;
 
-- NULL check
SELECT
    COUNT(*)                                AS total_rows,
    COUNT(*) FILTER (WHERE pid     IS NULL) AS null_pid,
    COUNT(*) FILTER (WHERE revenue IS NULL) AS null_revenue,
    COUNT(*) FILTER (WHERE region  IS NULL) AS null_region
FROM task3_migration.orders;
 
-- Duplicate check
SELECT oid, COUNT(*) AS cnt
FROM task3_migration.orders
GROUP BY oid
HAVING COUNT(*) > 1;
 
-- Category wise verify
SELECT
    p.category,
    COUNT(o.oid)    AS total_orders,
    SUM(o.revenue)  AS total_revenue
FROM task3_migration.orders AS o
INNER JOIN task3_migration.products AS p
    ON o.pid = p.pid
GROUP BY p.category
ORDER BY total_revenue DESC;
 