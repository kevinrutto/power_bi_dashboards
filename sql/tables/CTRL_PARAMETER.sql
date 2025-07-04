ALTER TABLE STAGING.CTRL_PARAMETER
 DROP PRIMARY KEY CASCADE;

DROP TABLE STAGING.CTRL_PARAMETER CASCADE CONSTRAINTS;

CREATE TABLE STAGING.CTRL_PARAMETER
(
  ID               NUMBER Generated as Identity ( START WITH 21 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCYCLE CACHE 20 NOORDER NOKEEP) NOT NULL,
  PARAMETER_VALUE  VARCHAR2(100 BYTE),
  PARAMETER_NAME   VARCHAR2(100 BYTE),
  PARAMETER_CODE   VARCHAR2(10 BYTE)
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


--  There is no statement for index STAGING.SYS_C007811.
--  The object is created when the parent object is created.

ALTER TABLE STAGING.CTRL_PARAMETER ADD (
  PRIMARY KEY
  (ID)
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
