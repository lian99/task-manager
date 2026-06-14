// Load environment variables from .env file into process.env
require('dotenv').config();

const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const app = express();

// Enable CORS — allows React (port 3000) to call this API (port 3001)
app.use(cors());

// Allow the API to parse JSON request bodies
app.use(express.json());

// ─────────────────────────────────────────
// DATABASE CONFIGURATION
// All values come from .env file 
// This follows the "least privilege" principle — the DB user
// only has the permissions it needs (EXECUTE, SELECT, INSERT, UPDATE, DELETE)
// ─────────────────────────────────────────
const dbConfig = {
    server: process.env.DB_SERVER,      // e.g. localhost
    database: process.env.DB_DATABASE,  // TaskManagerDB
    user: process.env.DB_USER,          // taskmanager_user
    password: process.env.DB_PASSWORD,  // from .env — never hardcoded
    options: {
        encrypt: false,                 // set to true in production with SSL
        trustServerCertificate: true,   // required for local SQL Server dev
        enableArithAbort: true          // recommended setting for mssql package
    }
};

// ─────────────────────────────────────────
// CONNECTION POOL
// Instead of opening a new DB connection on every request,
// we create one shared pool and reuse it 
// ─────────────────────────────────────────
let pool;
async function getPool() {
    if (!pool) {
        pool = await sql.connect(dbConfig);
    }
    return pool;
}

// ─────────────────────────────────────────
// GET /employees
// Returns all employees with their task summary:
// total tasks, count per status, nearest upcoming due task
// Calls stored procedure: usp_GetEmployeeTaskSummary
// ─────────────────────────────────────────
app.get('/employees', async (req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request()
            .execute('usp_GetEmployeeTaskSummary');
        res.json(result.recordset);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to fetch employee summary.' });
    }
});

// ─────────────────────────────────────────
// GET /tasks
// Returns all tasks with employee name and department
// Ordered by CreatedAt descending (newest first)
// Calls stored procedure: usp_GetAllTasks
// ─────────────────────────────────────────
app.get('/tasks', async (req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request()
            .execute('usp_GetAllTasks');
        res.json(result.recordset);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to fetch tasks.' });
    }
});

// ─────────────────────────────────────────
// PATCH /tasks/:id/status
// Updates a task's status (enforces valid transitions only):
// Pending → In Progress → Done (no skipping and no going backwards)
// Calls stored procedure: usp_UpdateTaskStatus
// ─────────────────────────────────────────
app.patch('/tasks/:id/status', async (req, res) => {
    const taskId = parseInt(req.params.id);
    const { status } = req.body;

    // Validate that status was provided in the request body
    if (!status) {
        return res.status(400).json({ error: 'Status is required in request body.' });
    }

    // Validate that status is one of the allowed values
    // This is a second layer of validation (the first is the CHECK constraint in the DB)
    const validStatuses = ['Pending', 'In Progress', 'Done'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ error: 'Invalid status. Must be Pending, In Progress, or Done.' });
    }

    // Validate that the task ID is a valid number
    if (isNaN(taskId)) {
        return res.status(400).json({ error: 'Invalid task ID.' });
    }

    try {
        const pool = await getPool();

        // Pass parameters safely using .input() — prevents SQL injection
        await pool.request()
            .input('TaskID', sql.Int, taskId)
            .input('NewStatus', sql.NVarChar(20), status)
            .execute('usp_UpdateTaskStatus');

        res.json({ message: `Task ${taskId} status updated to '${status}' successfully.` });
    } catch (err) {
        console.error(err);

        // Task not found → 404
        if (err.number === 50001) {
            return res.status(404).json({ error: err.message });
        }

        // Business logic errors (invalid transition, already Done) → 400
        if (err.number >= 50002 && err.number <= 50010) {
            return res.status(400).json({ error: err.message });
        }

        // Any other error is a server error → 500
        res.status(500).json({ error: 'Failed to update task status.' });
    }
});

// Start the Express server on the port defined in .env (default: 3001)
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});