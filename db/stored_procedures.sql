USE TaskManagerDB;
GO
---usp_GetAllTasks
CREATE OR ALTER PROCEDURE usp_GetAllTasks
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            t.TaskID,
            t.Title,
            t.Description,
            t.Status,
            t.DueDate,
            t.CreatedAt,
            e.FullName      AS EmployeeName,
            d.DepartmentName AS DepartmentName
        FROM Tasks t
        INNER JOIN Employees e ON t.AssignedTo = e.EmployeeID
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        ORDER BY t.CreatedAt DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO


---- usp_GetOverdueTasks
CREATE OR ALTER PROCEDURE usp_GetOverdueTasks
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            t.TaskID,
            t.Title,
            t.Description,
            t.Status,
            t.DueDate,
            e.FullName       AS EmployeeName,
            d.DepartmentName AS DepartmentName
        FROM Tasks t
        INNER JOIN Employees e ON t.AssignedTo = e.EmployeeID
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        WHERE t.DueDate < CAST(GETDATE() AS DATE)
          AND t.Status != 'Done'
        ORDER BY t.DueDate ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE usp_UpdateTaskStatus
    @TaskID INT,
    @NewStatus NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check task exists
        IF NOT EXISTS (SELECT 1 FROM Tasks WHERE TaskID = @TaskID)
            THROW 50001, 'Task not found.', 1;

        -- Get current status
        DECLARE @CurrentStatus NVARCHAR(20);
        SELECT @CurrentStatus = Status FROM Tasks WHERE TaskID = @TaskID;

        -- Enforce valid transitions only
        IF @CurrentStatus = 'Done'
            THROW 50002, 'Task is already Done. No further updates allowed.', 1;

        IF @CurrentStatus = 'Pending' AND @NewStatus != 'In Progress'
            THROW 50003, 'Invalid transition: Pending can only move to In Progress.', 1;

        IF @CurrentStatus = 'In Progress' AND @NewStatus != 'Done'
            THROW 50004, 'Invalid transition: In Progress can only move to Done.', 1;

        -- Apply the update
        UPDATE Tasks
        SET Status = @NewStatus
        WHERE TaskID = @TaskID;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE usp_AssignTask
    @TaskID     INT,
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate task exists
        IF NOT EXISTS (SELECT 1 FROM Tasks WHERE TaskID = @TaskID)
            THROW 50001, 'Task not found.', 1;

        -- Validate employee exists
        IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID)
            THROW 50002, 'Employee not found.', 1;

        -- Check task is not already Done
        DECLARE @CurrentStatus NVARCHAR(20);
        SELECT @CurrentStatus = Status FROM Tasks WHERE TaskID = @TaskID;

        IF @CurrentStatus = 'Done'
            THROW 50003, 'Cannot assign a task that is already Done.', 1;

        -- Assign the task inside a transaction
        BEGIN TRANSACTION;

            UPDATE Tasks
            SET AssignedTo = @EmployeeID
            WHERE TaskID = @TaskID;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE usp_GetEmployeeTaskSummary
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            e.EmployeeID,
            e.FullName,
            d.DepartmentName,
            COUNT(t.TaskID)                                    AS TotalTasks,
            SUM(CASE WHEN t.Status = 'Pending'     THEN 1 ELSE 0 END) AS PendingTasks,
            SUM(CASE WHEN t.Status = 'In Progress' THEN 1 ELSE 0 END) AS InProgressTasks,
            SUM(CASE WHEN t.Status = 'Done'        THEN 1 ELSE 0 END) AS DoneTasks,
            MIN(CASE WHEN t.DueDate >= CAST(GETDATE() AS DATE)
                     AND t.Status != 'Done'
                     THEN t.DueDate END)                       AS NearestDueTask
        FROM Employees e
        INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
        LEFT JOIN Tasks t ON t.AssignedTo = e.EmployeeID
        GROUP BY e.EmployeeID, e.FullName, d.DepartmentName;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- NOTE: This procedure only redistributes tasks to employees with fewer than 3 open tasks.
-- If no colleague has room (all have 3+ tasks), the overloaded employee keeps their tasks.
-- This is a conscious design decision to prevent tasks from ping-ponging between employees.
-- A second run may resolve remaining imbalances if room becomes available.
CREATE OR ALTER PROCEDURE usp_RebalanceTasks
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeID     INT;
    DECLARE @DepartmentID   INT;
    DECLARE @OpenTasks      INT;
    DECLARE @ExcessCount    INT;
    DECLARE @TargetEmployee INT;

    BEGIN TRY
        DECLARE overloaded_cursor CURSOR FOR
            SELECT
                e.EmployeeID,
                e.DepartmentID,
                COUNT(t.TaskID) AS OpenTasks
            FROM Employees e
            INNER JOIN Tasks t ON t.AssignedTo = e.EmployeeID
            WHERE t.Status IN ('Pending', 'In Progress')
            GROUP BY e.EmployeeID, e.DepartmentID
            HAVING COUNT(t.TaskID) > 3;

        OPEN overloaded_cursor;

        FETCH NEXT FROM overloaded_cursor
        INTO @EmployeeID, @DepartmentID, @OpenTasks;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @ExcessCount = @OpenTasks - 3;
            SET @TargetEmployee = NULL;

            -- Only pick a target who has room (less than 3 open tasks)
            -- In case of tie, pick lowest EmployeeID
            SELECT TOP 1 @TargetEmployee = e.EmployeeID
            FROM Employees e
            LEFT JOIN Tasks t ON t.AssignedTo = e.EmployeeID
                AND t.Status IN ('Pending', 'In Progress')
            WHERE e.DepartmentID = @DepartmentID
              AND e.EmployeeID != @EmployeeID
            GROUP BY e.EmployeeID
            HAVING COUNT(t.TaskID) < 3
            ORDER BY COUNT(t.TaskID) ASC, e.EmployeeID ASC;

            -- If no target found, skip this employee
            IF @TargetEmployee IS NOT NULL
            BEGIN
                UPDATE TOP (@ExcessCount) Tasks
                SET AssignedTo = @TargetEmployee
                WHERE AssignedTo = @EmployeeID
                  AND Status IN ('Pending', 'In Progress');
            END

            FETCH NEXT FROM overloaded_cursor
            INTO @EmployeeID, @DepartmentID, @OpenTasks;
        END

        CLOSE overloaded_cursor;
        DEALLOCATE overloaded_cursor;

    END TRY
    BEGIN CATCH
        -- Clean up cursor if error occurs
        IF CURSOR_STATUS('global', 'overloaded_cursor') >= 0
        BEGIN
            CLOSE overloaded_cursor;
            DEALLOCATE overloaded_cursor;
        END;

        DECLARE @ErrorMessage  NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT            = ERROR_SEVERITY();
        DECLARE @ErrorState    INT            = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO