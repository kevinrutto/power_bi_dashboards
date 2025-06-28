DROP VIEW STAGING.V_LOAN_PORTFOLIO_ANALYSIS;

/* Formatted on 6/26/2025 12:33:22 PM (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW STAGING.V_LOAN_PORTFOLIO_ANALYSIS
(
   LOAN_ID,
   OFFICER_ID,
   APPLICATION_AMOUNT,
   LOAN_OFFICER_NAME,
   BRANCH_ID,
   BRANCH_NAME,
   PRODUCT_NAME,
   BRANCH_LOCATION,
   LOAN_AMOUNT,
   INTEREST_RATE,
   LOAN_TERM_MONTHS,
   START_DATE,
   MATURITY_DATE,
   PRINCIPAL_BALANCE,
   ACCRUED_INTEREST,
   TOTAL_INTEREST,
   MONTHS_REMAINING,
   MONTHS_ELAPSED,
   PERCENT_PAID,
   LOAN_AGE_YEARS,
   LOAN_TO_VALUE_RATIO,
   INTEREST_INCOME_TO_DATE,
   PROJECTED_INTEREST_INCOME,
   LOAN_STATUS,
   RISK_CATEGORY,
   CUSTOMER_ID,
   CUSTOMER_NAME
)
   BEQUEATH DEFINER
AS
   SELECT DISTINCT
          la.ACCOUNT_ID AS LOAN_ID,
          la.OFFICER_ID,
          la.application_amount,
          o.NAME AS LOAN_OFFICER_NAME,
          b.BRANCH_ID,
          b.BRANCH_NAME,
          p.PRODUCT_NAME,
          b.LOCATION AS BRANCH_LOCATION,
          la.LOAN_AMOUNT,
          la.INTEREST_RATE,
          la.LOAN_TERM_MONTHS,
          la.START_DATE,
          la.MATURITY_DATE,
          la.PRINCIPAL_BAL AS PRINCIPAL_BALANCE,
          la.ACCRUED_INTEREST,
          la.TOTAL_INTEREST,
          -- Time-based metrics
          CEIL (
             MONTHS_BETWEEN (la.MATURITY_DATE, TRUNC (GET_SYSTEM_DATE ())))
             AS MONTHS_REMAINING,
          FLOOR (MONTHS_BETWEEN (TRUNC (GET_SYSTEM_DATE ()), la.START_DATE))
             AS MONTHS_ELAPSED,
          ROUND ( (1 - (la.PRINCIPAL_BAL / la.LOAN_AMOUNT)) * 100, 2) / 100
             AS PERCENT_PAID,
          ROUND (
             MONTHS_BETWEEN (TRUNC (GET_SYSTEM_DATE ()), la.START_DATE) / 12,
             2)
             AS LOAN_AGE_YEARS,
          -- Risk metrics (collateral value sourced from COLLATERAL table)
          ROUND (
            (col.COLLATERAL_VALUE/ la.LOAN_AMOUNT),
             2)
             AS LOAN_TO_VALUE_RATIO,
          -- Interest calculations
          ROUND (
               la.TOTAL_INTEREST
             * (  MONTHS_BETWEEN (TRUNC (GET_SYSTEM_DATE ()), la.START_DATE)
                / la.LOAN_TERM_MONTHS),
             2)
             AS INTEREST_INCOME_TO_DATE,
          la.TOTAL_INTEREST AS PROJECTED_INTEREST_INCOME,
          -- Status classifications
          CASE
             WHEN la.PRINCIPAL_BAL = 0
             THEN
                'PAID OFF'
             WHEN la.MATURITY_DATE < TRUNC (GET_SYSTEM_DATE ())
             THEN
                'MATURED'
             WHEN MONTHS_BETWEEN (TRUNC (GET_SYSTEM_DATE ()), la.START_DATE) >
                     la.LOAN_TERM_MONTHS
             THEN
                'OVERDUE'
             WHEN la.PRINCIPAL_BAL > la.LOAN_AMOUNT * 0.9
             THEN
                'NEW'
             ELSE
                'ACTIVE'
          END
             AS LOAN_STATUS,
          CASE
             WHEN la.INTEREST_RATE > 8 THEN 'HIGH RISK'
             WHEN la.INTEREST_RATE BETWEEN 6 AND 8 THEN 'MEDIUM RISK'
             ELSE 'LOW RISK'
          END
             AS RISK_CATEGORY,
          -- Payment information
          -- Customer info
          c.CUSTOMER_ID,
          c.NAME AS CUSTOMER_NAME
     FROM loan_account la
          JOIN account a ON la.ACCOUNT_ID = a.ACCOUNT_ID
          JOIN PRODUCT p ON p.PRODUCT_ID = a.PRODUCT_ID
          JOIN customer c ON a.CUSTOMER_ID = c.CUSTOMER_ID
          JOIN branch b ON c.BRANCH_ID = b.BRANCH_ID
          LEFT JOIN loan_officer o ON la.OFFICER_ID = o.OFFICER_ID
          LEFT JOIN collateral col ON la.ACCOUNT_ID = col.LOAN_ACCOUNT_ID;
