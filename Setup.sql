/* ====================================================
   PROJECT: Call Centre Customer Management Database
   DATABASE: Oracle
   AUTHOR: (Your Name)
   DESCRIPTION:
   This script creates a call centre database including
   customers, agents, calls, issues, procedures,
   triggers, and audit logging.
==================================================== */

/* ================================
   TABLE: CUSTOMERS
================================ */
CREATE TABLE customers (
    customer_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR2(50) NOT NULL,
    last_name   VARCHAR2(50) NOT NULL,
    phone       VARCHAR2(15) UNIQUE,
    email       VARCHAR2(100),
    created_at  DATE DEFAULT SYSDATE
);

/* ================================
   TABLE: AGENTS
================================ */
CREATE TABLE agents (
    agent_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name VARCHAR2(100) NOT NULL,
    department VARCHAR2(50) NOT NULL
);

/* ================================
   TABLE: CALLS
================================ */
CREATE TABLE calls (
    call_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    agent_id    NUMBER NOT NULL,
    call_time   DATE DEFAULT SYSDATE,
    call_status VARCHAR2(30),

    CONSTRAINT fk_calls_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_calls_agent
        FOREIGN KEY (agent_id)
        REFERENCES agents(agent_id)
);

/* ================================
   TABLE: ISSUES
================================ */
CREATE TABLE issues (
    issue_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    call_id    NUMBER NOT NULL,
    issue_type VARCHAR2(100),
    resolution VARCHAR2(200),
    resolved   CHAR(1) CHECK (resolved IN ('Y','N')),

    CONSTRAINT fk_issues_call
        FOREIGN KEY (call_id)
        REFERENCES calls(call_id)
);

/* ================================
   TABLE: AUDIT_LOGS
================================ */
CREATE TABLE audit_logs (
    audit_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name  VARCHAR2(50),
    action_type VARCHAR2(10),
    record_id   NUMBER,
    changed_by  VARCHAR2(50),
    changed_at  DATE DEFAULT SYSDATE
);

/* ================================
   PROCEDURE: LOG_CALL
================================ */
CREATE OR REPLACE PROCEDURE log_call (
    p_customer_id IN NUMBER,
    p_agent_id    IN NUMBER,
    p_status      IN VARCHAR2
) AS
BEGIN
    INSERT INTO calls (customer_id, agent_id, call_status)
    VALUES (p_customer_id, p_agent_id, p_status);

    COMMIT;
END;
/

/* ================================
   TRIGGER: AUTO CREATE ISSUE
================================ */
CREATE OR REPLACE TRIGGER trg_create_issue
AFTER INSERT ON calls
FOR EACH ROW
WHEN (NEW.call_status = 'Escalated')
BEGIN
    INSERT INTO issues (
        call_id,
        issue_type,
        resolution,
        resolved
    )
    VALUES (
        :NEW.call_id,
        'Escalated call',
        'Pending investigation',
        'N'
    );
END;
/

/* ================================
   TRIGGER: AUDIT CALLS
================================ */
CREATE OR REPLACE TRIGGER trg_audit_calls
AFTER INSERT OR UPDATE OR DELETE ON calls
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO audit_logs
        (table_name, action_type, record_id, changed_by)
        VALUES ('CALLS', 'INSERT', :NEW.call_id, USER);

    ELSIF UPDATING THEN
        INSERT INTO audit_logs
        (table_name, action_type, record_id, changed_by)
        VALUES ('CALLS', 'UPDATE', :NEW.call_id, USER);

    ELSIF DELETING THEN
        INSERT INTO audit_logs
        (table_name, action_type, record_id, changed_by)
        VALUES ('CALLS', 'DELETE', :OLD.call_id, USER);
    END IF;
END;
/

/* ================================
   TRIGGER: AUDIT ISSUES
================================ */
CREATE OR REPLACE TRIGGER trg_audit_issues
AFTER UPDATE ON issues
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs
    (table_name, action_type, record_id, changed_by)
    VALUES ('ISSUES', 'UPDATE', :NEW.issue_id, USER);
END;
/
BEGIN
    log_call(1, 1, 'Completed');
END;
/
SELECT * FROM audit_logs;

