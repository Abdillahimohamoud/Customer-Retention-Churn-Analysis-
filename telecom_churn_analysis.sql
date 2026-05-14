-- ============================================================
-- PROJECT : Telecom Customer Churn Analysis
-- Author  : Abdillahi
-- Tool    : MySQL 8.0+
-- ============================================================
-- CHURN DEFINITION:
--   Churned  = subscription was cancelled (is_churned = 1)
--   Active   = subscription still running (is_churned = 0)
--   subscription_end is NULL for active customers — by design
-- ============================================================


-- ============================================================
-- SECTION 1 — DATABASE & TABLE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS telecom_churn_project;
USE telecom_churn_project;
DROP TABLE IF EXISTS telecom_customers;

CREATE TABLE telecom_customers (
    customer_id         VARCHAR(20),
    customer_name       VARCHAR(100),
    country             VARCHAR(50),
    plan_type           VARCHAR(50),
    monthly_charge      DECIMAL(10,2),
    subscription_start  DATE,
    subscription_end    DATE,        -- NULL = still active
    is_churned          TINYINT(1),  -- 1 = churned | 0 = active
    tenure_months       INT,
    avg_monthly_gb      DECIMAL(10,2),
    support_tickets     INT,
    total_revenue       DECIMAL(10,2)
);

-- Import: Right-click table > Table Data Import Wizard
-- Select: telecom_churn_dataset.csv


-- ============================================================
-- SECTION 2 — DATA VALIDATION
-- ============================================================

-- 2.1 Total Rows (Expected: 200)
SELECT COUNT(*) AS total_rows
FROM telecom_customers;

-- 2.2 Missing Values (Expected: all zeros)
SELECT
    SUM(CASE WHEN customer_id    IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN plan_type      IS NULL THEN 1 ELSE 0 END) AS missing_plan_type,
    SUM(CASE WHEN is_churned     IS NULL THEN 1 ELSE 0 END) AS missing_is_churned,
    SUM(CASE WHEN total_revenue  IS NULL THEN 1 ELSE 0 END) AS missing_revenue
FROM telecom_customers;

-- 2.3 Churn Flag Consistency
-- churned=1 must have end date | churned=0 must not
SELECT
    is_churned,
    SUM(CASE WHEN subscription_end IS NULL     THEN 1 ELSE 0 END) AS no_end_date,
    SUM(CASE WHEN subscription_end IS NOT NULL THEN 1 ELSE 0 END) AS has_end_date
FROM telecom_customers
GROUP BY is_churned;


-- ============================================================
-- SECTION 3 — CUSTOMER & CHURN OVERVIEW
-- ============================================================

-- 3.1 Total Customers, Churn Rate, Retention Rate
SELECT
    COUNT(*)                                                    AS total_customers,
    SUM(is_churned)                                             AS churned_customers,
    COUNT(*) - SUM(is_churned)                                  AS active_customers,
    ROUND(SUM(is_churned) * 100.0 / COUNT(*), 2)               AS churn_rate_pct,
    ROUND((COUNT(*) - SUM(is_churned)) * 100.0 / COUNT(*), 2)  AS retention_rate_pct
FROM telecom_customers;

-- 3.2 Churn Rate by Plan Type
SELECT
    plan_type,
    COUNT(*)                                            AS total_customers,
    SUM(is_churned)                                     AS churned,
    ROUND(SUM(is_churned) * 100.0 / COUNT(*), 2)       AS churn_rate_pct
FROM telecom_customers
GROUP BY plan_type
ORDER BY churn_rate_pct DESC;

-- 3.3 Churn Rate by Country
SELECT
    country,
    COUNT(*)                                            AS total_customers,
    SUM(is_churned)                                     AS churned,
    ROUND(SUM(is_churned) * 100.0 / COUNT(*), 2)       AS churn_rate_pct
FROM telecom_customers
GROUP BY country
ORDER BY churn_rate_pct DESC;


-- ============================================================
-- SECTION 4 — REVENUE ANALYSIS
-- ============================================================

-- 4.1 Total Revenue, Lost Revenue, Active Revenue
SELECT
    ROUND(SUM(total_revenue), 2)                                    AS total_revenue,
    ROUND(SUM(CASE WHEN is_churned = 0 THEN total_revenue END), 2)  AS active_revenue,
    ROUND(SUM(CASE WHEN is_churned = 1 THEN total_revenue END), 2)  AS revenue_lost_to_churn,
    ROUND(AVG(total_revenue), 2)                                    AS avg_customer_value
FROM telecom_customers;

-- 4.2 Revenue by Plan Type
SELECT
    plan_type,
    COUNT(*)                            AS customers,
    ROUND(SUM(total_revenue), 2)        AS total_revenue,
    ROUND(AVG(total_revenue), 2)        AS avg_revenue_per_customer
FROM telecom_customers
GROUP BY plan_type
ORDER BY total_revenue DESC;

-- 4.3 Top 10 Customers by Revenue
SELECT
    customer_name,
    plan_type,
    country,
    tenure_months,
    ROUND(total_revenue, 2)                                         AS total_revenue,
    CASE WHEN is_churned = 1 THEN 'Churned' ELSE 'Active' END      AS status
FROM telecom_customers
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- SECTION 5 — MONTHLY SUBSCRIPTION TREND
-- ============================================================

-- 5.1 New Subscriptions per Month
SELECT
    DATE_FORMAT(subscription_start, '%Y-%m')    AS month,
    COUNT(*)                                     AS new_subscriptions
FROM telecom_customers
GROUP BY month
ORDER BY month;

-- 5.2 Cancellations per Month
SELECT
    DATE_FORMAT(subscription_end, '%Y-%m')      AS month,
    COUNT(*)                                     AS cancellations
FROM telecom_customers
WHERE is_churned = 1
GROUP BY month
ORDER BY month;


-- ============================================================
-- END OF PROJECT
-- ============================================================
