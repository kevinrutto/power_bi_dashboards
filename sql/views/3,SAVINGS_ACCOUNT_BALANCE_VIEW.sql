DROP VIEW STAGING.SAVINGS_ACCOUNT_BALANCE_VIEW;

/* Formatted on 6/26/2025 12:32:14 PM (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW STAGING.SAVINGS_ACCOUNT_BALANCE_VIEW
(
   BRANCH_NAME,
   ACCOUNT_ID,
   PRODUCT_NAME,
   CREATE_DT,
   BALANCE,
   INTEREST_RATE,
   ACCRUED_INTEREST,
   BALANCE_DT,
   BALANCE_DATE,
   BALANCE_MONTH,
   BALANCE_YEAR,
   DAYS_SINCE_BALANCE_UPDATE,
   MONTHS_SINCE_BALANCE_UPDATE,
   BALANCE_RANGE,
   INTEREST_STATUS,
   ACCOUNT_ACTIVITY
)
   BEQUEATH DEFINER
AS
   SELECT b.branch_name,
          sa.ACCOUNT_ID,
          p.product_name,
          a.opened_date AS create_dt,
          sa.BALANCE,
          sa.INTEREST_RATE,
          sa.ACCRUED_INTEREST,
          sa.BALANCE_DT,
          -- Date-based calculations
          TRUNC (sa.BALANCE_DT) AS BALANCE_DATE,
          TO_CHAR (sa.BALANCE_DT, 'YYYY-MM') AS BALANCE_MONTH,
          EXTRACT (YEAR FROM sa.BALANCE_DT) AS BALANCE_YEAR,
          -- Age calculations
          TRUNC (GET_SYSTEM_DATE () - sa.BALANCE_DT)
             AS DAYS_SINCE_BALANCE_UPDATE,
          TRUNC (MONTHS_BETWEEN (TRUNC (GET_SYSTEM_DATE ()), sa.BALANCE_DT))
             AS MONTHS_SINCE_BALANCE_UPDATE,
          -- Balance categories
          CASE
             WHEN sa.BALANCE < 1000 THEN 'Under $1K'
             WHEN sa.BALANCE BETWEEN 1000 AND 5000 THEN '$1K-$5K'
             WHEN sa.BALANCE BETWEEN 5001 AND 10000 THEN '$5K-$10K'
             WHEN sa.BALANCE BETWEEN 10001 AND 20000 THEN '$10K-$20K'
             ELSE 'Over $20K'
          END
             AS BALANCE_RANGE,
          -- Interest earning status
          CASE
             WHEN sa.INTEREST_RATE > 0 THEN 'Interest-Bearing'
             ELSE 'Non-Interest'
          END
             AS INTEREST_STATUS,
          -- Activity flag
          CASE
             WHEN sa.BALANCE_DT >=
                     ADD_MONTHS (TRUNC (GET_SYSTEM_DATE ()), -3)
             THEN
                'Recently Updated'
             WHEN sa.BALANCE_DT >=
                     ADD_MONTHS (TRUNC (GET_SYSTEM_DATE ()), -12)
             THEN
                'Active'
             ELSE
                'Dormant'
          END
             AS ACCOUNT_ACTIVITY
     FROM SAVINGS_ACCOUNT sa,
          branch b,
          account a,
          customer c,
          product p
    WHERE     sa.ACCOUNT_ID = a.ACCOUNT_ID
          AND a.CUSTOMER_ID = c.customer_id
          AND b.BRANCH_ID = c.BRANCH_ID
          AND p.product_id = a.product_id;
