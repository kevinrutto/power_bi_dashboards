ALTER TABLE STAGING.PRODUCT
 DROP PRIMARY KEY CASCADE;

DROP TABLE STAGING.PRODUCT CASCADE CONSTRAINTS;

CREATE TABLE STAGING.PRODUCT
(
  PRODUCT_ID    NUMBER,
  PRODUCT_NAME  VARCHAR2(100 BYTE),
  PRODUCT_TYPE  VARCHAR2(50 BYTE)
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


--  There is no statement for index STAGING.SYS_C007669.
--  The object is created when the parent object is created.

ALTER TABLE STAGING.PRODUCT ADD (
  PRIMARY KEY
  (PRODUCT_ID)
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
