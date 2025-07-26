ALTER TABLE STAGING.ACH_TRANSACTIONS
 DROP PRIMARY KEY CASCADE;

DROP TABLE STAGING.ACH_TRANSACTIONS CASCADE CONSTRAINTS;

CREATE TABLE STAGING.ACH_TRANSACTIONS
(
  ARCH_TRANSACTION_ID     NUMBER(30)            NOT NULL,
  RELATED_TRANSACTION_ID  VARCHAR2(20 BYTE),
  CUSTOMER_ID             NUMBER(30)            NOT NULL,
  ACCOUNT_ID              NUMBER(30)            NOT NULL,
  TRANSACTION_DATE        TIMESTAMP(6)          NOT NULL,
  SETTLEMENT_DATE         TIMESTAMP(6),
  AMOUNT                  NUMBER(15,2)          NOT NULL,
  TRANSACTION_TYPE        VARCHAR2(100 BYTE)    NOT NULL,
  TRANSACTION_ROLE        VARCHAR2(100 BYTE)    NOT NULL,
  STATUS                  VARCHAR2(20 BYTE)     NOT NULL,
  STATUS_REASON           VARCHAR2(100 BYTE),
  BATCH_ID                VARCHAR2(20 BYTE),
  REFERENCE_NUMBER        VARCHAR2(100 BYTE),
  ORIGINATING_COMPANY     VARCHAR2(100 BYTE),
  TRANSACTION_CODE        VARCHAR2(5 BYTE),
  DR_CR_IND               VARCHAR2(20 BYTE),
  COUNTRY_OF_ORIGIN       VARCHAR2(40 BYTE)
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

COMMENT ON TABLE STAGING.ACH_TRANSACTIONS IS 'Table storing both sides of ACH transactions (debits and credits)';

COMMENT ON COLUMN STAGING.ACH_TRANSACTIONS.RELATED_TRANSACTION_ID IS 'Links the corresponding debit/credit transaction pair';

COMMENT ON COLUMN STAGING.ACH_TRANSACTIONS.TRANSACTION_ROLE IS 'Indicates whether this record is for the originator (debit) or receiver (credit) of funds';


CREATE INDEX STAGING.IDX_ACH_RELATED_TRANS ON STAGING.ACH_TRANSACTIONS
(RELATED_TRANSACTION_ID)
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

CREATE INDEX STAGING.IDX_ACH_SETTLE_DATE ON STAGING.ACH_TRANSACTIONS
(SETTLEMENT_DATE)
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

CREATE INDEX STAGING.IDX_ACH_STATUS ON STAGING.ACH_TRANSACTIONS
(STATUS)
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

CREATE INDEX STAGING.IDX_ACH_TRANS_DATE ON STAGING.ACH_TRANSACTIONS
(TRANSACTION_DATE)
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

CREATE INDEX STAGING.IDX_ACH_TRANS_TYPE ON STAGING.ACH_TRANSACTIONS
(TRANSACTION_TYPE)
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

--  There is no statement for index STAGING.SYS_C007960.
--  The object is created when the parent object is created.

CREATE OR REPLACE TRIGGER STAGING.trg_ach_transactions_bi
BEFORE INSERT OR UPDATE ON STAGING.ACH_TRANSACTIONS
FOR EACH ROW
DISABLE
DECLARE
    v_transaction_direction VARCHAR2(10);
BEGIN
    -- For IAT transactions (International ACH)
    IF :NEW.TRANSACTION_CODE = 'IAT' THEN
        :NEW.TRANSACTION_ROLE := 'Both';
        
        -- Determine debit/credit based on amount
        IF :NEW.AMOUNT < 0 THEN
            :NEW.DR_CR_IND := 'DEBIT';
        ELSE
            :NEW.DR_CR_IND := 'CREDIT';
        END IF;
        
        -- Additional IAT-specific validation
        IF :NEW.ORIGINATING_COMPANY IS NULL THEN
            :NEW.ORIGINATING_COMPANY := 'AcmeBank'; -- Default for international
        END IF;
    ELSE
        -- For domestic transactions
        -- Get transaction direction from transaction code
        SELECT 
            CASE 
                WHEN SUBSTR(TRANSACTION_CODE, -2) = '_D' THEN 'DEBIT'
                WHEN SUBSTR(TRANSACTION_CODE, -2) = '_C' THEN 'CREDIT'
                WHEN DIRECTION = 'DEBIT' THEN 'DEBIT'
                WHEN DIRECTION = 'CREDIT' THEN 'CREDIT'
                ELSE NULL
            END INTO v_transaction_direction
        FROM ACH_TRANSACTION_CODE
        WHERE TRANSACTION_CODE = :NEW.TRANSACTION_CODE;
        
        -- Set DR_CR_IND based on transaction code
        :NEW.DR_CR_IND := v_transaction_direction;
        
        -- Set transaction role if not provided
        IF :NEW.TRANSACTION_ROLE IS NULL THEN
            IF v_transaction_direction = 'DEBIT' THEN
                :NEW.TRANSACTION_ROLE := 'Receiver';
            ELSIF v_transaction_direction = 'CREDIT' THEN
                :NEW.TRANSACTION_ROLE := 'Originator';
            END IF;
        END IF;
    END IF;
    
    -- Additional validation
    IF :NEW.DR_CR_IND IS NULL THEN
        -- Fallback logic if direction couldn't be determined
        IF :NEW.AMOUNT < 0 THEN
            :NEW.DR_CR_IND := 'DEBIT';
        ELSE
            :NEW.DR_CR_IND := 'CREDIT';
        END IF;
    END IF;
    
    -- Ensure originating company is set for receiver transactions
    IF :NEW.TRANSACTION_ROLE = 'Receiver' AND :NEW.ORIGINATING_COMPANY IS NULL THEN
        :NEW.ORIGINATING_COMPANY := 'AcmeBank';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        DBMS_OUTPUT.PUT_LINE('Error in trg_ach_transactions_bi: ' || SQLERRM);
        RAISE;
END;
/


CREATE OR REPLACE TRIGGER STAGING.TRG_POPULATE_TRANSACTION_JOURNAL
AFTER INSERT ON STAGING.ACH_TRANSACTIONS
FOR EACH ROW
DECLARE
    v_description VARCHAR2(100);
    v_txn_type VARCHAR2(20);
    v_error_message VARCHAR2(4000);
    v_sqlcode NUMBER;
    v_sqlerrm VARCHAR2(4000);
    v_journal_id NUMBER;
BEGIN
    -- Determine transaction type description based on ACH transaction code
    BEGIN
        SELECT 
            CASE 
                WHEN :NEW.TRANSACTION_CODE LIKE '%_D' THEN 'ACH_DEBIT'
                WHEN :NEW.TRANSACTION_CODE LIKE '%_C' THEN 'ACH_CREDIT'
                ELSE 'ACH_TRANSACTION'
            END,
            CASE 
                WHEN :NEW.TRANSACTION_CODE = 'PPD_D' THEN 'Recurring Payment'
                WHEN :NEW.TRANSACTION_CODE = 'PPD_C' THEN 'Direct Deposit'
                WHEN :NEW.TRANSACTION_CODE = 'WEB_D' THEN 'Online Payment'
                WHEN :NEW.TRANSACTION_CODE = 'WEB_C' THEN 'Online Deposit'
                WHEN :NEW.TRANSACTION_CODE = 'CCD_D' THEN 'Business Payment'
                WHEN :NEW.TRANSACTION_CODE = 'CCD_C' THEN 'Business Deposit'
                WHEN :NEW.TRANSACTION_CODE = 'TEL_D' THEN 'Phone Payment'
                WHEN :NEW.TRANSACTION_CODE = 'ARC' THEN 'Check Conversion'
                WHEN :NEW.TRANSACTION_CODE = 'CTX' THEN 'Trade Payment'
                WHEN :NEW.TRANSACTION_CODE = 'TAX' THEN 'Tax Payment'
                ELSE 'ACH Transaction'
            END
        INTO v_txn_type, v_description
        FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            v_txn_type := 'ACH_TRANSACTION';
            v_description := 'Transaction';
    END;
    
    -- Get next journal ID from sequence
    SELECT STAGING.TRANSACTION_JOURNAL_SEQ.NEXTVAL
    INTO v_journal_id
    FROM DUAL;
    
    -- Insert record into journal for ORIGINATOR (debit) transactions
    IF :NEW.TRANSACTION_ROLE = 'Originator' THEN
        BEGIN
            INSERT INTO STAGING.TRANSACTION_JOURNAL (
                TRANSACTION_JOURNAL_ID,
                ACCOUNT_ID,
                TRANSACTION_DATE,
                AMOUNT,
                TRANSACTION_TYPE,
                DESCRIPTION,
                TXN_STATUS,
                ACH_TRANSACTION_ID
            ) VALUES (
                v_journal_id,
                :NEW.ACCOUNT_ID,
                :NEW.TRANSACTION_DATE,
                ABS(:NEW.AMOUNT),
                v_txn_type,
                v_description || ' - Debit',
                :NEW.STATUS,
                :NEW.ARCH_TRANSACTION_ID
            );
        EXCEPTION
            WHEN OTHERS THEN
                v_sqlcode := SQLCODE;
                v_sqlerrm := SUBSTR(SQLERRM, 1, 4000);
                v_error_message := 'Error creating originator journal entry: ' || v_sqlerrm;
                
                INSERT INTO STAGING.APPLICATION_ERRORS (
                    ERROR_DATE, 
                    ERROR_MESSAGE, 
                    ERROR_CODE,
                    SOURCE,
                    RELATED_ID
                ) VALUES (
                    SYSTIMESTAMP, 
                    v_error_message, 
                    v_sqlcode,
                    'trg_populate_transaction_journal',
                    :NEW.ARCH_TRANSACTION_ID
                );
                
                DBMS_OUTPUT.PUT_LINE(v_error_message);
        END;
    END IF;
    
    -- Insert record into journal for RECEIVER (credit) transactions
    IF :NEW.TRANSACTION_ROLE = 'Receiver' THEN
        BEGIN
            INSERT INTO STAGING.TRANSACTION_JOURNAL (
                TRANSACTION_JOURNAL_ID,
                ACCOUNT_ID,
                TRANSACTION_DATE,
                AMOUNT,
                TRANSACTION_TYPE,
                DESCRIPTION,
                TXN_STATUS,
                ACH_TRANSACTION_ID
            ) VALUES (
                v_journal_id,
                :NEW.ACCOUNT_ID,
                :NEW.TRANSACTION_DATE,
                :NEW.AMOUNT,
                v_txn_type,
                v_description || ' - Credit',
                :NEW.STATUS,
                :NEW.ARCH_TRANSACTION_ID
            );
        EXCEPTION
            WHEN OTHERS THEN
                v_sqlcode := SQLCODE;
                v_sqlerrm := SUBSTR(SQLERRM, 1, 4000);
                v_error_message := 'Error creating receiver journal entry: ' || v_sqlerrm;
                
                INSERT INTO STAGING.APPLICATION_ERRORS (
                    ERROR_DATE, 
                    ERROR_MESSAGE, 
                    ERROR_CODE,
                    SOURCE,
                    RELATED_ID
                ) VALUES (
                    SYSTIMESTAMP, 
                    v_error_message, 
                    v_sqlcode,
                    'trg_populate_transaction_journal',
                    :NEW.ARCH_TRANSACTION_ID
                );
                
                DBMS_OUTPUT.PUT_LINE(v_error_message);
        END;
    END IF;
END;
/


ALTER TABLE STAGING.ACH_TRANSACTIONS ADD (
  CONSTRAINT CK_AMOUNT
  CHECK (
    (TRANSACTION_ROLE = 'ORIGINATOR' AND AMOUNT < 0) OR
    (TRANSACTION_ROLE = 'RECEIVER' AND AMOUNT > 0)
)
  DISABLE NOVALIDATE,
  CHECK (TRANSACTION_ROLE IN ('ORIGINATOR', 'RECEIVER'))
  DISABLE NOVALIDATE,
  PRIMARY KEY
  (ARCH_TRANSACTION_ID)
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

ALTER TABLE STAGING.ACH_TRANSACTIONS ADD (
  CONSTRAINT FK_ACH_ACCOUNT_ID 
  FOREIGN KEY (ACCOUNT_ID) 
  REFERENCES STAGING.ACCOUNT (ACCOUNT_ID)
  ENABLE VALIDATE,
  CONSTRAINT FK_ACH_CUSTOMER_ID 
  FOREIGN KEY (CUSTOMER_ID) 
  REFERENCES STAGING.CUSTOMER (CUSTOMER_ID)
  ENABLE VALIDATE,
  CONSTRAINT FK_TRANS_CODE 
  FOREIGN KEY (TRANSACTION_CODE) 
  REFERENCES STAGING.ACH_TRANSACTION_CODE (TRANSACTION_CODE)
  ENABLE VALIDATE);
