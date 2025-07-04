ALTER TABLE STAGING.ACCOUNT
 DROP PRIMARY KEY CASCADE;

DROP TABLE STAGING.ACCOUNT CASCADE CONSTRAINTS;

CREATE TABLE STAGING.ACCOUNT
(
  ACCOUNT_ID      NUMBER,
  ACCOUNT_NUMBER  VARCHAR2(20 BYTE),
  CUSTOMER_ID     NUMBER,
  PRODUCT_ID      NUMBER,
  OPENED_DATE     DATE,
  ACCOUNT_TYPE    VARCHAR2(50 BYTE),
  STATUS          VARCHAR2(10 BYTE)
)
TABLESPACE USERS
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;



ALTER TABLE STAGING.ACCOUNT ADD (
  PRIMARY KEY
  (ACCOUNT_ID)
  USING INDEX
    TABLESPACE USERS
    PCTFREE    10
    INITRANS   2
    MAXTRANS   255
    STORAGE    (
                INITIAL          64K
                NEXT             1M
                MAXSIZE          UNLIMITED
                MINEXTENTS       1
                MAXEXTENTS       UNLIMITED
                PCTINCREASE      0
                BUFFER_POOL      DEFAULT
               )
  ENABLE VALIDATE);

ALTER TABLE STAGING.ACCOUNT ADD (
  FOREIGN KEY (PRODUCT_ID) 
  REFERENCES STAGING.PRODUCT (PRODUCT_ID)
  ENABLE VALIDATE);
  
  ALTER TABLE STAGING.ACCOUNT ADD (
  FOREIGN KEY (CUSTOMER_ID) 
  REFERENCES STAGING.CUSTOMER (CUSTOMER_ID)
  ENABLE VALIDATE);



CREATE INDEX STAGING.IDX_ACCOUNT_CUSTOMER_ID ON STAGING.ACCOUNT
(CUSTOMER_ID)
LOGGING
TABLESPACE USERS
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );

