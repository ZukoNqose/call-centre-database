/* 
====================================================
 Project: Call Centre Customer Management Database
 Database: Oracle
 Description:
 This database stores customer information, call
 centre agents, call logs, and customer issues.
====================================================
*/

/* ================================
   TABLE: CUSTOMERS
   Stores customer personal details
================================ */

CREATE TABLE customers (
    customer_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Unique identifier for each customer

    first_name  VARCHAR2(50) NOT NULL,
    -- Customer first name

    last_name   VARCHAR2(50) NOT NULL,
    -- Customer last name

    phone       VARCHAR2(15) UNIQUE,
    -- Customer contact number

    email       VARCHAR2(100),
    -- Customer email address

    created_at  DATE DEFAULT SYSDATE
    -- Date the customer was created
);

----------------------------------------------------

/* ================================
   TABLE: AGENTS
   Stores call centre agent details
================================ */

CREATE TABLE agents (
    agent_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Unique identifier for each agent

    agent_name VARCHAR2(100) NOT NULL,
    -- Full name of the agent

    department VARCHAR2(50) NOT NULL
    -- Department the agent works in
);

----------------------------------------------------

/* ================================
   TABLE: CALLS
   Logs customer calls handled by agents
================================ */

CREATE TABLE calls (
    call_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Unique identifier for each call

    customer_id NUMBER NOT NULL,
    -- References the customer who made the call

    agent_id    NUMBER NOT NULL,
    -- References the agent who handled the call

    call_time   DATE DEFAULT SYSDATE,
    -- Date and time of the call

    call_status VARCHAR2(30),
    -- Status of the call (Completed, Dropped, Escalated)

    CONSTRAINT fk_calls_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    -- Ensures call belongs to a valid customer

    CONSTRAINT fk_calls_agent
        FOREIGN KEY (agent_id)
        REFERENCES agents(agent_id)
    -- Ensures call is handled by a valid agent
);

----------------------------------------------------

/* ================================
   TABLE: ISSUES
   Stores problems reported during calls
================================ */

CREATE TABLE issues (
    issue_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Unique identifier for each issue

    call_id    NUMBER NOT NULL,
    -- References the call where the issue was reported

    issue_type VARCHAR2(100),
    -- Type of issue reported by the customer

    resolution VARCHAR2(200),
    -- How the issue was resolved

    resolved   CHAR(1) CHECK (resolved IN ('Y','N')),
    -- Indicates whether the issue is resolved

    CONSTRAINT fk_issues_call
        FOREIGN KEY (call_id)
        REFERENCES calls(call_id)
    -- Ensures issue belongs to a valid call
);

----------------------------------------------------

/* ================================
   SAMPLE DATA INSERTION
   Used for testing and demonstration
================================ */

-- Insert sample customer
INSERT INTO customers (first_name, last_name, phone, email)
VALUES ('Thabo', 'Mokoena', '0712345678', 'thabo@gmail.com');

-- Insert sample agent
INSERT INTO agents (agent_name, department)
VALUES ('Sipho Dlamini', 'Technical Support');

-- Insert sample call
INSERT INTO calls (customer_id, agent_id, call_status)
VALUES (1, 1, 'Completed');

-- Insert sample issue
INSERT INTO issues (call_id, issue_type, resolution, resolved)
VALUES (1, 'Internet down', 'Router restarted', 'Y');

----------------------------------------------------

/* ================================
   REPORTING QUERIES
   Used by management and supervisors
================================ */

-- View all calls with customer and agent details
SELECT
    c.call_id,
    cu.first_name || ' ' || cu.last_name AS customer_name,
    a.agent_name,
    c.call_status,
    c.call_time
FROM calls c
JOIN customers cu ON c.customer_id = cu.customer_id
JOIN agents a ON c.agent_id = a.agent_id;

-- Count number of calls handled by each agent
SELECT
    a.agent_name,
    COUNT(*) AS total_calls
FROM calls c
JOIN agents a ON c.agent_id = a.agent_id
GROUP BY a.agent_name;

-- View unresolved customer issues
SELECT
    issue_type,
    resolution
FROM issues
WHERE resolved = 'N';

/* ============================================
   PROCEDURE: log_call
   Purpose:
   Automatically logs a customer call handled
   by an agent.
============================================ */

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

/* ============================================
   TRIGGER: trg_create_issue
   Purpose:
   Automatically creates an issue record when
   a call is escalated.
============================================ */

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
-- Log an escalated call
BEGIN
    log_call(1, 1, 'Escalated');
END;
/

SELECT * FROM issues;

/* ============================================
   TABLE: AUDIT_LOGS
   Purpose:
   Tracks changes made to important tables
   such as CALLS and ISSUES.
============================================ */

CREATE TABLE audit_logs (
    audit_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name   VARCHAR2(50),
    action_type  VARCHAR2(10),
    record_id    NUMBER,
    changed_by   VARCHAR2(50),
    changed_at   DATE DEFAULT SYSDATE
);

/* ============================================
   TRIGGER: trg_audit_calls
   Purpose:
   Logs INSERT, UPDATE, and DELETE actions
   performed on the CALLS table.
============================================ */

CREATE OR REPLACE TRIGGER trg_audit_calls
AFTER INSERT OR UPDATE OR DELETE ON calls
FOR EACH ROW
BEGIN
    -- INSERT action
    IF INSERTING THEN
        INSERT INTO audit_logs (
            table_name,
            action_type,
            record_id,
            changed_by
        )
        VALUES (
            'CALLS',
            'INSERT',
            :NEW.call_id,
            USER
        );

    -- UPDATE action
    ELSIF UPDATING THEN
        INSERT INTO audit_logs (
            table_name,
            action_type,
            record_id,
            changed_by
        )
        VALUES (
            'CALLS',
            'UPDATE',
            :NEW.call_id,
            USER
        );

    -- DELETE action
    ELSIF DELETING THEN
        INSERT INTO audit_logs (
            table_name,
            action_type,
            record_id,
            changed_by
        )
        VALUES (
            'CALLS',
            'DELETE',
            :OLD.call_id,
            USER
        );
    END IF;
END;
/

/* ============================================
   TRIGGER: trg_audit_issues
   Purpose:
   Logs UPDATE actions on the ISSUES table.
============================================ */

CREATE OR REPLACE TRIGGER trg_audit_issues
AFTER UPDATE ON issues
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (
        table_name,
        action_type,
        record_id,
        changed_by
    )
    VALUES (
        'ISSUES',
        'UPDATE',
        :NEW.issue_id,
        USER
    );
END;
/

BEGIN
    log_call(1, 1, 'Completed');
END;
/

UPDATE issues
SET resolved = 'Y'
WHERE issue_id = 1;

SELECT *
FROM audit_logs
ORDER BY changed_at DESC;

