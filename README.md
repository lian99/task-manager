# Employee Task Manager

A full-stack internal task management system built with React, Node.js, and Microsoft SQL Server.

## Tech Stack
- **Database:** Microsoft SQL Server (MSSQL)
- **API:** Node.js + Express
- **Frontend:** React

---

## Prerequisites
- Microsoft SQL Server (Developer Edition)
- Node.js v18+
- npm

---

## 1. Database Setup

### Step 1 — Create the database
Open SSMS, connect to your local SQL Server and run:
```sql
CREATE DATABASE TaskManagerDB;
```

### Step 2 — Enable SQL Server Authentication
Run this in SSMS:
```sql
EXEC xp_instance_regwrite 
    N'HKEY_LOCAL_MACHINE', 
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'LoginMode', REG_DWORD, 2;
```
Then restart SQL Server from SQL Server Configuration Manager.

### Step 3 — Create a database user
```sql
USE master;
GO
CREATE LOGIN taskmanager_user WITH PASSWORD = 'TaskManager123!';
GO
USE TaskManagerDB;
GO
CREATE USER taskmanager_user FOR LOGIN taskmanager_user;
GO
GRANT EXECUTE TO taskmanager_user;
GRANT SELECT, INSERT, UPDATE, DELETE TO taskmanager_user;
GO
```

### Step 4 — Run SQL scripts in SSMS in this exact order:
1. `db/schema.sql` — creates the 3 tables
2. `db/seed.sql` — inserts sample data (3 departments, 6 employees, 10 tasks)
3. `db/stored_procedures.sql` — creates all 6 stored procedures

---

## 2. API Setup

Navigate to the api folder:
```bash
cd api
npm install
```

Create a `.env` file inside the `api` folder:

DB_SERVER=localhost

DB_DATABASE=TaskManagerDB

DB_USER=taskmanager_user

DB_PASSWORD=TaskManager123!

DB_ENCRYPT=false

DB_TRUST_SERVER_CERT=true

PORT=3001

Start the API:
```bash
node index.js
```

API runs on **http://localhost:3001**

---

## 3. React App Setup

Navigate to the client folder:
```bash
cd client
npm install
npm start
```

App runs on **http://localhost:3000**

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/employees` | Returns all employees with task summary |
| GET | `/tasks` | Returns all tasks with employee and department |
| PATCH | `/tasks/:id/status` | Updates a task status (body: `{ "status": "In Progress" }`) |

### PATCH Status Transitions
Valid transitions only:
- `Pending` → `In Progress`
- `In Progress` → `Done`

### HTTP Status Codes
- `200` — Success
- `400` — Invalid transition or missing input
- `404` — Task not found
- `500` — Server error

---

## Project Structure
task-manager/

├── api/

│   ├── index.js          # Express API

│   ├── package.json

│   └── .gitignore

├── client/

│   ├── src/

│   │   └── App.js        # React component

│   └── package.json

└── db/

├── schema.sql         # Table definitions

├── seed.sql           # Sample data

└── stored_procedures.sql  # All 6 stored procedures

---

## Assumptions & Design Decisions

- **SQL Login:** A dedicated `taskmanager_user` was created following the least privilege principle.only has permissions it needs (EXECUTE, SELECT, INSERT, UPDATE, DELETE).
- **usp_RebalanceTasks:** Tasks are only moved to employees with fewer than 3 open tasks to prevent ping-ponging. A second run may resolve remaining imbalances if room becomes available.
- **NearestDueTask:** Shows only future due dates for non-Done tasks. Employees with no upcoming tasks show NULL (displayed as — in the UI).
- **CORS:** Enabled on the API to allow the React app on port 3000 to communicate with the API on port 3001.
- **Connection Pool:** A single shared DB connection pool is reused across all requests for efficiency.
