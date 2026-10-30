USE DevmasterLab
GO
CREATE OR ALTER PROCEDURE dbo.usp_EnrollStudent
    @StudentId int,
    @CourseId int,
    @Paid decimal(12,0) = 0,
    @EnrollmentId int OUTPUT        -- trả mã ghi danh mới
AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON;
    
    -- ... SET @EnrollmentId = NULL; lấy @Fee, @Active ...
    DECLARE @Fee decimal(12,0);
DECLARE @Active bit;

-- Lấy giá trị Fee và Active từ bảng Courses theo CourseId truyền vào
SELECT 
    @Fee = Fee,          -- Đổi tên cột 'Fee' đúng với tên cột trong bảng Courses của bạn
    @Active = IsActive   -- Đổi tên cột 'IsActive' đúng với tên cột trong bảng Courses của bạn
FROM dbo.Courses
WHERE CourseId = @CourseId;

    IF NOT EXISTS (SELECT 1 FROM dbo.Students
                   WHERE StudentId = @StudentId) RETURN 1;
    IF @Fee IS NULL  RETURN 2;        -- khóa không tồn tại
    IF @Active = 0   RETURN 3;        -- ngừng tuyển sinh
    -- ... đã ghi danh -> 4; sai số tiền -> 5 ...
    
    BEGIN TRY
        BEGIN TRANSACTION;
            INSERT INTO dbo.Enrollments (StudentId, CourseId, PaidAmount)
            VALUES (@StudentId, @CourseId, @Paid);
            
            SET @EnrollmentId = SCOPE_IDENTITY();
            
            IF @Paid > 0 INSERT INTO dbo.Payments (EnrollmentId, Amount)
                         VALUES (@EnrollmentId, @Paid);
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

DECLARE @id int,@rc int;
EXEC @rc = dbo.usp_EnrollStudent
     @StudentId = 12, @CourseId = 6, @Paid= 2000000,
     @EnrollmentId = @id OUTPUT;
SELECT @rc AS ReturnCode, @id AS NewEnrollmentId;

EXEC @rc = dbo.usp_EnrollStudent 12, 6, 0, @id OUTPUT;
SELECT @rc AS ReturnCode;

EXEC @rc = dbo.usp_EnrollStudent 12, 7, 0, @id OUTPUT;
SELECT @rc AS ReturnCode;
GO


CREATE PROCEDURE dbo.usp_StudentDebt
    @StudentId int,
    @Debt      decimal(14,0) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @Debt = COALESCE(SUM(c.Fee - e.PaidAmount), 0)
    FROM dbo.Enrollments AS e
    JOIN dbo.Courses     AS c ON c.CourseId = e.CourseId
    WHERE e.StudentId = @StudentId AND e.Status <> 'Cancelled';
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_StudentReport
    @StudentId int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Debt decimal(14,0);
    EXEC dbo.usp_StudentDebt @StudentId, @Debt OUTPUT;  -- gọi lồng nhau
    SELECT FullName, @Debt AS TotalDebt, @@NESTLEVEL AS NestLevel
    FROM dbo.Students
    WHERE StudentId = @StudentId;
END;
GO
EXEC dbo.usp_StudentReport @StudentId = 4;  -- Phạm Quốc Dũng · 4.000.000 ·
