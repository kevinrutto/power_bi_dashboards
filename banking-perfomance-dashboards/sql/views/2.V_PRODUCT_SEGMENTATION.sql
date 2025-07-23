DROP VIEW STAGING.V_PRODUCT_SEGMENTATION;

/* Formatted on 6/26/2025 12:34:57 PM (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW STAGING.V_PRODUCT_SEGMENTATION
(
   PRODUCT_ID,
   PRODUCT_NAME,
   PRODUCT_TYPE,
   CUSTOMER_ID,
   ACCOUNT_ID,
   STATUS,
   OPENED_DATE,
   BALANCE,
   TOTAL_ACCOUNTS,
   TOTAL_BALANCE
)
   BEQUEATH DEFINER
AS
   (  SELECT PRODUCT_ID,
             PRODUCT_NAME,
             PRODUCT_TYPE,
             CUSTOMER_ID,
             ACCOUNT_ID,
             STATUS,
             OPENED_DATE,
             BALANCE,
             COUNT (ACCOUNT_ID) AS TOTAL_ACCOUNTS,
             SUM (BALANCE) AS TOTAL_BALANCE
        FROM (SELECT p.PRODUCT_ID,
                     p.PRODUCT_NAME,
                     p.PRODUCT_TYPE,
                     a.CUSTOMER_ID,
                     a.ACCOUNT_ID,
                     a.STATUS,
                     a.OPENED_DATE,
                     sa.BALANCE
                FROM account a
                     JOIN product p ON a.product_id = p.product_id
                     JOIN savings_account sa ON a.account_id = sa.account_id
              UNION ALL
              SELECT p.PRODUCT_ID,
                     p.PRODUCT_NAME,
                     p.PRODUCT_TYPE,
                     a.CUSTOMER_ID,
                     a.ACCOUNT_ID,
                     a.STATUS,
                     a.OPENED_DATE,
                     la.LOAN_AMOUNT AS BALANCE
                FROM account a
                     JOIN product p ON a.product_id = p.product_id
                     JOIN loan_account la ON a.account_id = la.account_id
              UNION ALL
              SELECT p.PRODUCT_ID,
                     p.PRODUCT_NAME,
                     p.PRODUCT_TYPE,
                     a.CUSTOMER_ID,
                     a.ACCOUNT_ID,
                     a.STATUS,
                     a.OPENED_DATE,
                     tda.DEPOSIT_AMOUNT AS BALANCE
                FROM account a
                     JOIN product p ON a.product_id = p.product_id
                     JOIN term_deposit_account tda
                        ON a.account_id = tda.account_id) unified
    GROUP BY PRODUCT_ID,
             PRODUCT_NAME,
             PRODUCT_TYPE,
             CUSTOMER_ID,
             ACCOUNT_ID,
             STATUS,
             OPENED_DATE,
             BALANCE);
