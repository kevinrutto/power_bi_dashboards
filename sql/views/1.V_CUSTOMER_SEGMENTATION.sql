DROP VIEW STAGING.V_CUSTOMER_SEGMENTATION;

/* Formatted on 6/26/2025 12:38:09 PM (QP5 v5.287) */
CREATE OR REPLACE FORCE VIEW STAGING.V_CUSTOMER_SEGMENTATION
(
   CUSTOMER_ID,
   CUSTOMER_NAME,
   EMAIL,
   PHONE,
   BRANCH_NAME,
   BRANCH_LOCATION,
   CUSTOMER_STATUS,
   CUSTOMER_SEGMENT,
   CUSTOMER_TENURE_DAYS,
   CREATE_DATE
)
   BEQUEATH DEFINER
AS
   SELECT c.customer_id,
          c.name AS customer_name,
          c.email,
          c.phone,
          b.branch_name,
          b.location AS branch_location,
          c.status AS customer_status,
          -- Customer segmentation based on tenure and status
          CASE
             WHEN c.status = 'INACTIVE'
             THEN
                'INACTIVE'
             WHEN MONTHS_BETWEEN (TRUNC (GET_SYSTEM_DATE ()), c.create_date) <=
                     6
             THEN
                'NEW'
             WHEN MONTHS_BETWEEN (TRUNC (GET_SYSTEM_DATE ()), c.create_date) <=
                     24
             THEN
                'ESTABLISHED'
             ELSE
                'LONG-TERM'
          END
             AS customer_segment,
          -- Customer tenure in days
          TRUNC (TRUNC (GET_SYSTEM_DATE ()) - c.create_date)
             AS customer_tenure_days,
          TRUNC (c.create_date) AS create_date
     FROM customer c LEFT JOIN branch b ON c.branch_id = b.branch_id;
