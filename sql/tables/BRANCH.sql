ALTER TABLE STAGING.BRANCH
 DROP PRIMARY KEY CASCADE;

DROP TABLE STAGING.BRANCH CASCADE CONSTRAINTS;

CREATE TABLE STAGING.BRANCH
(
  BRANCH_ID    NUMBER,
  BRANCH_NAME  VARCHAR2(100 BYTE),
  LOCATION     VARCHAR2(100 BYTE)
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


--  There is no statement for index STAGING.SYS_C007768.
--  The object is created when the parent object is created.

ALTER TABLE STAGING.BRANCH ADD (
  PRIMARY KEY
  (BRANCH_ID)
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
