# Call Centre Customer Management Database

## Overview
This project is a **fully documented Oracle SQL / PL/SQL database** designed for a call centre environment.
It demonstrates core database concepts such as relational design, constraints, stored procedures,
triggers, and audit logging.

This project is suitable for:
- College / university submission
- GitHub portfolio
- Entry-level database or IT roles

---

## Features
- Customer and agent management
- Call logging using stored procedures
- Automatic issue creation for escalated calls
- Audit logging for data changes (INSERT / UPDATE / DELETE)

---

## Database Structure

### Tables
- **CUSTOMERS** – stores customer details
- **AGENTS** – stores call centre agents
- **CALLS** – logs calls between customers and agents
- **ISSUES** – tracks escalated or unresolved calls
- **AUDIT_LOGS** – tracks all data changes

### Relationships
- One customer → many calls
- One agent → many calls
- One call → zero or one issue

---

## Technologies Used
- Oracle SQL
- PL/SQL
- Oracle SQL Developer

---

## How to Run
1. Open Oracle SQL Developer
2. Create a new SQL worksheet
3. Run `call-centre-database.sql`
4. Press **F5** to execute
5. Verify using SELECT queries

---

## Author
**Zuko Nqose**

---

## License
MIT License
