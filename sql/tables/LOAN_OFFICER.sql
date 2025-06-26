ALTER TABLE STAGING.LOAN_OFFICER
 DROP PRIMARY KEY CASCADE;

DROP TABLE STAGING.LOAN_OFFICER CASCADE CONSTRAINTS;

CREATE TABLE STAGING.LOAN_OFFICER
(
  OFFICER_ID  NUMBER,
  NAME        VARCHAR2(100 BYTE),
  USER_ID     NUMBER
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


--  There is no statement for index STAGING.SYS_C007665.
--  The object is created when the parent object is created.

ALTER TABLE STAGING.LOAN_OFFICER ADD (
  PRIMARY KEY
  (OFFICER_ID)
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
