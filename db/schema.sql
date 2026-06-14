USE TaskManagerDB;
GO

-- Drop tables if they exist
IF OBJECT_ID('Tasks', 'U') IS NOT NULL DROP TABLE Tasks;
IF OBJECT_ID('Employees', 'U') IS NOT NULL DROP TABLE Employees;
IF OBJECT_ID('Departments', 'U') IS NOT NULL DROP TABLE Departments;
GO

-- 1. Departments table (no foreign keys, created first)
CREATE TABLE Departments (
    DepartmentID   INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL
);
GO

-- 2. Employees table (depends on Departments)
CREATE TABLE Employees (
    EmployeeID   INT IDENTITY(1,1) PRIMARY KEY,
    FullName     NVARCHAR(100) NOT NULL,
    Email        NVARCHAR(100) NOT NULL UNIQUE,
    DepartmentID INT NOT NULL,
    CreatedAt    DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Employees_Departments 
        FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);
GO

-- 3. Tasks table (depends on Employees)
CREATE TABLE Tasks (
    TaskID      INT IDENTITY(1,1) PRIMARY KEY,
    Title       NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000),
    AssignedTo  INT NOT NULL,
    Status      NVARCHAR(20) NOT NULL DEFAULT 'Pending'
                CONSTRAINT CHK_Tasks_Status 
                CHECK (Status IN ('Pending', 'In Progress', 'Done')),
    DueDate     DATE NOT NULL,
    CreatedAt   DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Tasks_Employees 
        FOREIGN KEY (AssignedTo) REFERENCES Employees(EmployeeID)
);
GO