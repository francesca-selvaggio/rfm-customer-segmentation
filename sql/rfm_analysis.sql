-- STEP 1: DATA EXPLORATION

SELECT COUNT(*) AS total_rows
FROM retail;
-- null check
SELECT
    COUNT(*) AS total_rows,
    COUNT("Customer ID") AS rows_with_customer_id,
    COUNT(*) - COUNT("Customer ID") AS missing_customer_id,
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS negative_quantity,
    SUM(CASE WHEN Price <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_price
FROM retail;

-- Date range of transactions

SELECT
    MIN(InvoiceDate) AS first_transaction,
    MAX(InvoiceDate) AS last_transaction
FROM retail;


-- STEP 2: DATA CLEANING
-- Valid transactions only: quantity, price > 0 - Customer ID not null

SELECT COUNT(*) AS valid_rows
FROM retail
WHERE
    Quantity > 0
    AND Price > 0
    AND "Customer ID" IS NOT NULL;


-- STEP 3: RFM METRICS CALCULATION
-- Reference date: 2011-12-10 (day after last transaction)

CREATE VIEW IF NOT EXISTS rfm_base AS
SELECT
    "Customer ID"                                           AS customer_id,
    CAST(JULIANDAY('2011-12-10') - JULIANDAY(MAX(InvoiceDate)) AS INTEGER)                                            
    AS recency_days,
    COUNT(DISTINCT Invoice)                                 AS frequency,
    ROUND(SUM(Quantity * Price), 2)                         AS monetary
FROM retail
WHERE Quantity > 0
    AND Price > 0
    AND "Customer ID" IS NOT NULL
GROUP BY "Customer ID";

SELECT
    MIN(recency_days)   AS min_recency,
    MAX(recency_days)   AS max_recency,
    AVG(recency_days)   AS avg_recency,
    MIN(frequency)      AS min_frequency,
    MAX(frequency)      AS max_frequency,
    AVG(frequency)      AS avg_frequency,
    MIN(monetary)       AS min_monetary,
    MAX(monetary)       AS max_monetary,
    AVG(monetary)       AS avg_monetary
FROM rfm_base;


-- STEP 4: RFM SCORING (1–5)

CREATE VIEW IF NOT EXISTS rfm_scored AS
WITH quartiles AS (SELECT
                        customer_id,
                        recency_days,
                        frequency,
                        monetary,
                        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_quartile,
                        NTILE(4) OVER (ORDER BY frequency ASC)     AS f_quartile,
                        NTILE(4) OVER (ORDER BY monetary ASC)      AS m_quartile
    FROM rfm_base)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    -- R score: recency ascending (lower days = more recent = better)
    CASE
        WHEN r_quartile = 1 THEN 5
        WHEN r_quartile = 2 THEN 4
        WHEN r_quartile = 3 THEN 3
        ELSE 2
    END AS R_score,
    -- F score: frequency descending (more invoices = better)
    CASE
        WHEN f_quartile = 4 THEN 5
        WHEN f_quartile = 3 THEN 4
        WHEN f_quartile = 2 THEN 3
        ELSE 2
    END AS F_score,
    -- M score: monetary descending (higher spend = better)
    CASE
        WHEN m_quartile = 4 THEN 5
        WHEN m_quartile = 3 THEN 4
        WHEN m_quartile = 2 THEN 3
        ELSE 2
    END AS M_score
FROM quartiles;


-- STEP 5: CUSTOMER SEGMENTATION

CREATE VIEW IF NOT EXISTS rfm_segments AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    R_score,
    F_score,
    M_score,
    (R_score + F_score + M_score) AS RFM_total,
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4
             AND (R_score + F_score + M_score) >= 14
             THEN 'VIP'
        WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3
             THEN 'Loyal'
        WHEN R_score >= 4 AND F_score < 3
             THEN 'New Customer'
        WHEN R_score < 3 AND F_score >= 4
             THEN 'At Risk'
        ELSE 'Dormant'
    END AS Segment
FROM rfm_scored;


-- STEP 6: RESULTS & VALIDATION
SELECT *
FROM rfm_segments
ORDER BY RFM_total DESC, monetary DESC;

-- Segment summary
SELECT
    Segment,
    COUNT(*)                                                    AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)         AS pct_of_base,
    ROUND(AVG(recency_days), 0)                                 AS avg_recency_days,
    ROUND(AVG(frequency), 1)                                    AS avg_frequency,
    ROUND(AVG(monetary), 0)                                     AS avg_monetary_gbp,
    ROUND(SUM(monetary), 0)                                     AS total_revenue_gbp
FROM rfm_segments
GROUP BY Segment
ORDER BY customers DESC;

-- Revenue concentration check (VIP vs rest)
SELECT
    CASE WHEN Segment = 'VIP' THEN 'VIP' ELSE 'Other' END       AS group_label,
    COUNT(*)                                                    AS customers,
    ROUND(SUM(monetary), 0)                                     AS total_revenue_gbp,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (), 1) AS pct_of_revenue
FROM rfm_segments
GROUP BY group_label;
