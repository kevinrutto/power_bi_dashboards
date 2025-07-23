DROP VIEW STAGING.V_LOAN_REPAYMENT_AGGREGATES;

/* Formatted on 6/26/2025 12:34:35 PM (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW STAGING.V_LOAN_REPAYMENT_AGGREGATES
(
   LOAN_ACCOUNT_ID,
   TOTAL_AMOUNT_DUE,
   TOTAL_PRINCIPAL_DUE,
   TOTAL_INTEREST_DUE,
   TOTAL_AMOUNT_PAID,
   PRINCIPAL_PAID,
   INTEREST_PAID,
   OUTSTANDING_AMOUNT,
   OUTSTANDING_PRINCIPAL,
   OUTSTANDING_INTEREST,
   PAST_DUE_PRINCIPAL,
   PAST_DUE_INTEREST,
   DAYS_PAST_DUE,
   TOTAL_INSTALLMENTS,
   INSTALLMENTS_PAID,
   INSTALLMENTS_PENDING,
   LAST_DUE_DATE,
   NEXT_DUE_DATE
)
   BEQUEATH DEFINER
AS
     SELECT LOAN_ACCOUNT_ID,
            -- Total Scheduled Amounts
            SUM (AMOUNT_DUE) AS TOTAL_AMOUNT_DUE,
            SUM (PRINCIPAL_AMOUNT) AS TOTAL_PRINCIPAL_DUE,
            SUM (INTEREST_AMOUNT) AS TOTAL_INTEREST_DUE,
            -- Paid Aggregates
            SUM (CASE WHEN STATUS = 'PAID' THEN AMOUNT_DUE ELSE 0 END)
               AS TOTAL_AMOUNT_PAID,
            SUM (CASE WHEN STATUS = 'PAID' THEN PRINCIPAL_AMOUNT ELSE 0 END)
               AS PRINCIPAL_PAID,
            SUM (CASE WHEN STATUS = 'PAID' THEN INTEREST_AMOUNT ELSE 0 END)
               AS INTEREST_PAID,
            -- Pending Aggregates
            SUM (CASE WHEN STATUS = 'PENDING' THEN AMOUNT_DUE ELSE 0 END)
               AS OUTSTANDING_AMOUNT,
            SUM (CASE WHEN STATUS = 'PENDING' THEN PRINCIPAL_AMOUNT ELSE 0 END)
               AS OUTSTANDING_PRINCIPAL,
            SUM (CASE WHEN STATUS = 'PENDING' THEN INTEREST_AMOUNT ELSE 0 END)
               AS OUTSTANDING_INTEREST,
            -- Past Due Principal and Interest
            SUM (
               CASE
                  WHEN     STATUS = 'PENDING'
                       AND DUE_DATE < TRUNC (GET_SYSTEM_DATE ())
                  THEN
                     PRINCIPAL_AMOUNT
                  ELSE
                     0
               END)
               AS PAST_DUE_PRINCIPAL,
            SUM (
               CASE
                  WHEN     STATUS = 'PENDING'
                       AND DUE_DATE < TRUNC (GET_SYSTEM_DATE ())
                  THEN
                     INTEREST_AMOUNT
                  ELSE
                     0
               END)
               AS PAST_DUE_INTEREST,
            -- Days Past Due (maximum value for the loan account)
            MAX (
               CASE
                  WHEN     STATUS = 'PENDING'
                       AND DUE_DATE < TRUNC (GET_SYSTEM_DATE ())
                  THEN
                     TRUNC (TRUNC (GET_SYSTEM_DATE ())) - TRUNC (DUE_DATE)
                  ELSE
                     0
               END)
               AS DAYS_PAST_DUE,
            -- Installment Counts
            COUNT (*) AS TOTAL_INSTALLMENTS,
            SUM (CASE WHEN STATUS = 'PAID' THEN 1 ELSE 0 END)
               AS INSTALLMENTS_PAID,
            SUM (CASE WHEN STATUS = 'PENDING' THEN 1 ELSE 0 END)
               AS INSTALLMENTS_PENDING,
            -- Due Dates
            MAX (DUE_DATE) AS LAST_DUE_DATE,
            MIN (CASE WHEN STATUS = 'PENDING' THEN DUE_DATE END)
               AS NEXT_DUE_DATE
       FROM REPAYMENT_SCHEDULE
   GROUP BY LOAN_ACCOUNT_ID;
