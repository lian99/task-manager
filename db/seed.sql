USE TaskManagerDB;
GO

-- Clear existing data (order matters due to foreign keys)
DELETE FROM Tasks;
DELETE FROM Employees;
DELETE FROM Departments;
GO

-- Reset identity counters so IDs start from 1 again
DBCC CHECKIDENT ('Tasks', RESEED, 0);
DBCC CHECKIDENT ('Employees', RESEED, 0);
DBCC CHECKIDENT ('Departments', RESEED, 0);
GO

-- 1. Departments
INSERT INTO Departments (DepartmentName) VALUES ('Engineering');
INSERT INTO Departments (DepartmentName) VALUES ('Human Resources');
INSERT INTO Departments (DepartmentName) VALUES ('Finance');
GO

-- 2. Employees
INSERT INTO Employees (FullName, Email, DepartmentID) VALUES ('Alice Johnson', 'alice@company.com', 1);
INSERT INTO Employees (FullName, Email, DepartmentID) VALUES ('Bob Smith', 'bob@company.com', 1);
INSERT INTO Employees (FullName, Email, DepartmentID) VALUES ('Carol White', 'carol@company.com', 2);
INSERT INTO Employees (FullName, Email, DepartmentID) VALUES ('David Brown', 'david@company.com', 2);
INSERT INTO Employees (FullName, Email, DepartmentID) VALUES ('Eva Martinez', 'eva@company.com', 3);
INSERT INTO Employees (FullName, Email, DepartmentID) VALUES ('Frank Wilson', 'frank@company.com', 3);
GO

-- 3. Tasks (mix of statuses, some overdue)
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Fix login bug', 'Users cant login on mobile', 1, 'In Progress', '2026-06-10');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Write unit tests', 'Cover auth module', 1, 'Pending', '2026-06-08');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Deploy to staging', 'Deploy v2.1 to staging server', 2, 'Done', '2026-06-01');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Update HR policy', 'Update remote work policy doc', 3, 'Pending', '2026-06-09');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Onboard new hire', 'Prepare onboarding checklist', 3, 'In Progress', '2026-06-20');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Process payroll', 'June payroll processing', 4, 'Pending', '2026-06-05');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Budget report Q2', 'Prepare Q2 budget summary', 5, 'In Progress', '2026-06-15');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Audit expenses', 'Review May expense reports', 5, 'Pending', '2026-06-07');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('Tax filing prep', 'Gather docs for tax filing', 6, 'Pending', '2026-06-25');
INSERT INTO Tasks (Title, Description, AssignedTo, Status, DueDate) VALUES ('API documentation', 'Document all REST endpoints', 2, 'Pending', '2026-06-30');
GO