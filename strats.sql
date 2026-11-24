-- Greek NPL Portfolio Due Diligence & Pricing  (synthetic data)
-- Stratification ("strats") queries on the clean loan tape.
-- Table: loans  (loaded from data/npl_loan_tape_clean.csv)

-- 1) Portfolio overview
SELECT COUNT(*)                         AS loans,
       COUNT(DISTINCT borrower_id)      AS borrowers,
       ROUND(SUM(gross_book_value)/1e6, 1) AS gbv_eur_m,
       ROUND(AVG(gross_book_value), 0)  AS avg_gbv_eur,
       ROUND(100.0 * SUM(CASE WHEN secured = 1 THEN gross_book_value END) / SUM(gross_book_value), 1) AS secured_pct_gbv
FROM loans;

-- 2) Strat by segment: count, GBV, % of GBV, secured share
SELECT segment,
       COUNT(*) AS loans,
       ROUND(SUM(gross_book_value)/1e6, 1) AS gbv_eur_m,
       ROUND(100.0 * SUM(gross_book_value) / (SELECT SUM(gross_book_value) FROM loans), 1) AS pct_gbv,
       ROUND(100.0 * AVG(secured), 1) AS pct_loans_secured
FROM loans
GROUP BY segment
ORDER BY gbv_eur_m DESC;

-- 3) Strat by legal status
SELECT legal_status,
       COUNT(*) AS loans,
       ROUND(SUM(gross_book_value)/1e6, 1) AS gbv_eur_m,
       ROUND(100.0 * SUM(gross_book_value) / (SELECT SUM(gross_book_value) FROM loans), 1) AS pct_gbv
FROM loans
GROUP BY legal_status
ORDER BY gbv_eur_m DESC;

-- 4) Strat by LTV bucket (secured loans with a valid valuation)
WITH s AS (
  SELECT *, gross_book_value / collateral_value_omv AS ltv
  FROM loans
  WHERE secured = 1 AND omv_missing = 0
)
SELECT CASE WHEN ltv < 0.8 THEN '1) <80%'
            WHEN ltv < 1.0 THEN '2) 80-100%'
            WHEN ltv < 1.2 THEN '3) 100-120%'
            WHEN ltv < 1.5 THEN '4) 120-150%'
            ELSE '5) >150%' END AS ltv_bucket,
       COUNT(*) AS loans,
       ROUND(SUM(gross_book_value)/1e6, 1) AS gbv_eur_m,
       ROUND(SUM(collateral_value_omv)/1e6, 1) AS omv_eur_m
FROM s
GROUP BY ltv_bucket
ORDER BY ltv_bucket;

-- 5) Top 10 regions by GBV
SELECT region,
       COUNT(*) AS loans,
       ROUND(SUM(gross_book_value)/1e6, 1) AS gbv_eur_m
FROM loans
GROUP BY region
ORDER BY gbv_eur_m DESC
LIMIT 10;

-- 6) Borrower concentration: share of GBV held by the top 20 borrowers
WITH b AS (
  SELECT borrower_id, SUM(gross_book_value) AS gbv
  FROM loans GROUP BY borrower_id
)
SELECT ROUND(100.0 * SUM(gbv) / (SELECT SUM(gross_book_value) FROM loans), 1) AS top20_pct_gbv
FROM (SELECT gbv FROM b ORDER BY gbv DESC LIMIT 20);
