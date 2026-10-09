/* =====================================================================
   Devmaster Academy – Học phần Hệ quản trị CSDL SQL Server (SQL Server 2022)
   00_DevmasterLab_Setup.sql – Tạo CSDL mẫu DevmasterLab dùng chung cho 5 buổi
   Chạy lại nhiều lần không lỗi (xóa và tạo lại CSDL). Yêu cầu SQL Server 2022+.
   Bảng: Categories · Courses · Students · Enrollments · Payments
   Quy ước: Enrollments.PaidAmount = tổng Payments.Amount của lượt ghi danh
   ===================================================================== */
USE master;
GO
IF DB_ID(N'DevmasterLab') IS NOT NULL
BEGIN
    ALTER DATABASE DevmasterLab SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DevmasterLab;
END
GO
CREATE DATABASE DevmasterLab;
GO
ALTER DATABASE DevmasterLab SET COMPATIBILITY_LEVEL = 160;
GO
USE DevmasterLab;
GO

CREATE TABLE dbo.Categories (
    CategoryId   int IDENTITY(1,1) CONSTRAINT PK_Categories PRIMARY KEY,
    CategoryName nvarchar(100) NOT NULL CONSTRAINT UQ_Categories_Name UNIQUE,
    ParentId     int NULL
                 CONSTRAINT FK_Categories_Parent REFERENCES dbo.Categories(CategoryId)
);

CREATE TABLE dbo.Courses (
    CourseId   int IDENTITY(1,1) CONSTRAINT PK_Courses PRIMARY KEY,
    CourseCode varchar(20)   NOT NULL CONSTRAINT UQ_Courses_Code UNIQUE,
    CourseName nvarchar(200) NOT NULL,
    CategoryId int           NOT NULL
               CONSTRAINT FK_Courses_Categories REFERENCES dbo.Categories(CategoryId),
    Fee        decimal(12,0) NOT NULL CONSTRAINT CK_Courses_Fee CHECK (Fee >= 0),
    Hours      int           NOT NULL CONSTRAINT CK_Courses_Hours CHECK (Hours > 0),
    Tags       nvarchar(400) NULL,
    IsActive   bit           NOT NULL CONSTRAINT DF_Courses_IsActive DEFAULT 1
);

CREATE TABLE dbo.Students (
    StudentId int IDENTITY(1,1) CONSTRAINT PK_Students PRIMARY KEY,
    FullName  nvarchar(100) NOT NULL,
    Email     varchar(150)  NOT NULL CONSTRAINT UQ_Students_Email UNIQUE,
    Phone     varchar(15)   NULL,
    City      nvarchar(50)  NULL,
    BirthDate date          NULL,
    Flags     int           NOT NULL CONSTRAINT DF_Students_Flags DEFAULT 0,
              -- bit 0: đã xác thực email · bit 1: học bổng · bit 2: cựu học viên
    CreatedAt datetime2(0)  NOT NULL CONSTRAINT DF_Students_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Students_Email CHECK (Email LIKE '%_@_%')
);

CREATE TABLE dbo.Enrollments (
    EnrollmentId int IDENTITY(1,1) CONSTRAINT PK_Enrollments PRIMARY KEY,
    StudentId    int           NOT NULL
                 CONSTRAINT FK_Enrollments_Students REFERENCES dbo.Students(StudentId),
    CourseId     int           NOT NULL
                 CONSTRAINT FK_Enrollments_Courses REFERENCES dbo.Courses(CourseId),
    EnrolledAt   datetime2(0)  NOT NULL CONSTRAINT DF_Enrollments_EnrolledAt DEFAULT SYSDATETIME(),
    PaidAmount   decimal(12,0) NOT NULL CONSTRAINT DF_Enrollments_Paid DEFAULT 0
                 CONSTRAINT CK_Enrollments_Paid CHECK (PaidAmount >= 0),
    Score1       decimal(4,2)  NULL,
    Score2       decimal(4,2)  NULL,
    Score3       decimal(4,2)  NULL,
    Status       varchar(20)   NOT NULL CONSTRAINT DF_Enrollments_Status DEFAULT 'Active',
    CONSTRAINT CK_Enrollments_Scores CHECK (Score1 BETWEEN 0 AND 10
                                        AND Score2 BETWEEN 0 AND 10
                                        AND Score3 BETWEEN 0 AND 10),
    CONSTRAINT CK_Enrollments_Status CHECK (Status IN ('Active', 'Completed', 'Cancelled'))
);

CREATE TABLE dbo.Payments (
    PaymentId    int IDENTITY(1,1) CONSTRAINT PK_Payments PRIMARY KEY,
    EnrollmentId int           NOT NULL
                 CONSTRAINT FK_Payments_Enrollments REFERENCES dbo.Enrollments(EnrollmentId)
                 ON DELETE CASCADE,
    Amount       decimal(12,0) NOT NULL CONSTRAINT CK_Payments_Amount CHECK (Amount > 0),
    PaidAt       datetime2(0)  NOT NULL CONSTRAINT DF_Payments_PaidAt DEFAULT SYSDATETIME(),
    Method       varchar(20)   NOT NULL CONSTRAINT DF_Payments_Method DEFAULT 'Transfer'
                 CONSTRAINT CK_Payments_Method CHECK (Method IN ('Cash', 'Transfer', 'Card'))
);
GO

SET IDENTITY_INSERT dbo.Categories ON;
INSERT INTO dbo.Categories (CategoryId, CategoryName, ParentId) VALUES
 (1, N'Lập trình', NULL),
 (2, N'Dữ liệu', NULL),
 (3, N'Trí tuệ nhân tạo', NULL),
 (4, N'Lập trình Web .NET', 1),
 (5, N'Frontend', 1),
 (6, N'Cơ sở dữ liệu', 2),
 (7, N'Phân tích dữ liệu', 2),
 (8, N'Ứng dụng AI', 3);
SET IDENTITY_INSERT dbo.Categories OFF;

SET IDENTITY_INSERT dbo.Courses ON;
INSERT INTO dbo.Courses (CourseId, CourseCode, CourseName, CategoryId, Fee, Hours, Tags, IsActive) VALUES
 (1, 'NET-FS', N'Lập trình .NET Full Stack (ReactJS)', 4, 18000000, 240, N'csharp,aspnetcore,sql,react', 1),
 (2, 'SQL-DEV', N'SQL Server cho Developer', 6, 6000000, 60, N'sql,tsql,database', 1),
 (3, 'REACT', N'ReactJS chuyên sâu', 5, 8000000, 90, N'javascript,react,frontend', 1),
 (4, 'AI-APP', N'Ứng dụng AI cho lập trình viên', 8, 9000000, 72, N'ai,python,sql', 1),
 (5, 'PY-DA', N'Python phân tích dữ liệu', 7, 7500000, 80, N'python,pandas,sql', 1),
 (6, 'PBI', N'Power BI cho doanh nghiệp', 7, 5000000, 40, N'bi,dax,sql', 1),
 (7, 'JAVA-WEB', N'Java Web Full Stack', 1, 17000000, 240, N'java,spring,sql', 0),
 (8, 'GIT', N'Git & DevOps cơ bản', 1, 2500000, 24, N'git,devops', 1);
SET IDENTITY_INSERT dbo.Courses OFF;

SET IDENTITY_INSERT dbo.Students ON;
INSERT INTO dbo.Students (StudentId, FullName, Email, Phone, City, BirthDate, Flags, CreatedAt) VALUES
 (1, N'Nguyễn Văn An', 'an.nv@devmaster.vn', '0912345678', N'Hà Nội', '2003-05-12', 1, '2026-09-01T08:00:00'),
 (2, N'Trần Thị Bình', 'binh.tt@devmaster.vn', NULL, N'Bắc Ninh', '2004-11-02', 3, '2026-09-01T08:00:00'),
 (3, N'Lê Minh Châu', 'chau.lm@devmaster.vn', '0987654321', N'Hà Nội', '2002-01-25', 5, '2026-09-01T08:00:00'),
 (4, N'Phạm Quốc Dũng', 'dung.pq@devmaster.vn', NULL, N'Hà Nam', NULL, 0, '2026-09-01T08:00:00'),
 (5, N'Hoàng Thu Hà', 'ha.ht@devmaster.vn', '0901112233', N'Hà Nội', '2005-07-19', 7, '2026-09-01T08:00:00'),
 (6, N'Vũ Đức Huy', 'huy.vd@devmaster.vn', NULL, NULL, '2001-09-30', 0, '2026-09-01T08:00:00'),
 (7, N'Đỗ Ngọc Lan', 'lan.dn@devmaster.vn', '0934445566', N'Hà Tĩnh', '2004-03-08', 1, '2026-09-01T08:00:00'),
 (8, N'Bùi Gia Khánh', 'khanh.bg@devmaster.vn', NULL, N'Hải Phòng', '2003-12-21', 2, '2026-09-01T08:00:00'),
 (9, N'Ngô Thanh Tâm', 'tam.nt@devmaster.vn', '0977001122', N'Đà Nẵng', '2006-02-14', 0, '2026-09-01T08:00:00'),
 (10, N'Đặng Minh Quân', 'quan.dm@devmaster.vn', NULL, N'Hà Nội', '2002-08-05', 1, '2026-09-01T08:00:00'),
 (11, N'Trịnh Thu Trang', 'trang.tt@devmaster.vn', '0966778899', N'TP. Hồ Chí Minh', '2003-10-10', 3, '2026-09-01T08:00:00'),
 (12, N'Lý Văn Phúc', 'phuc.lv@devmaster.vn', NULL, N'Bắc Ninh', NULL, 0, '2026-09-01T08:00:00');
SET IDENTITY_INSERT dbo.Students OFF;

-- Tuần 21/09 và 12/10/2026 cố ý không có ghi danh (dùng cho bài chuỗi thời gian)
SET IDENTITY_INSERT dbo.Enrollments ON;
INSERT INTO dbo.Enrollments (EnrollmentId, StudentId, CourseId, EnrolledAt, PaidAmount, Score1, Score2, Score3, Status) VALUES
 (1, 1, 1, '2026-09-07T09:15:00', 9000000, 7.50, 8.00, NULL, 'Active'),
 (2, 2, 2, '2026-09-08T14:00:00', 6000000, 6.00, NULL, 7.50, 'Completed'),
 (3, 3, 1, '2026-09-10T10:30:00', 18000000, 8.50, 9.00, 8.00, 'Active'),
 (4, 1, 2, '2026-09-15T19:00:00', 6000000, NULL, 8.50, 9.00, 'Completed'),
 (5, 4, 3, '2026-09-17T08:45:00', 4000000, 5.50, 6.50, 7.00, 'Active'),
 (6, 5, 4, '2026-09-30T20:10:00', 9000000, 9.00, NULL, NULL, 'Active'),
 (7, 6, 2, '2026-10-01T09:00:00', 3000000, NULL, NULL, NULL, 'Cancelled'),
 (8, 7, 1, '2026-10-06T15:20:00', 9000000, 7.00, 7.50, 8.00, 'Active'),
 (9, 8, 3, '2026-10-08T11:00:00', 8000000, 6.50, NULL, 8.50, 'Active'),
 (10, 1, 4, '2026-10-20T18:30:00', 4500000, 8.00, 8.50, NULL, 'Active'),
 (11, 5, 2, '2026-10-22T09:40:00', 6000000, 9.50, 9.00, 9.50, 'Active'),
 (12, 3, 3, '2026-10-23T13:15:00', 8000000, NULL, 7.00, NULL, 'Active'),
 (13, 10, 5, '2026-09-09T10:00:00', 7500000, 7.00, 8.00, NULL, 'Active'),
 (14, 11, 1, '2026-09-16T14:30:00', 9000000, 8.00, NULL, NULL, 'Active'),
 (15, 11, 5, '2026-10-02T19:45:00', 3750000, NULL, NULL, NULL, 'Active'),
 (16, 2, 8, '2026-10-07T08:30:00', 2500000, 9.00, 9.50, NULL, 'Completed'),
 (17, 7, 8, '2026-10-09T16:00:00', 0, NULL, NULL, NULL, 'Active'),
 (18, 4, 5, '2026-10-19T10:10:00', 7500000, NULL, NULL, NULL, 'Active'),
 (19, 10, 2, '2026-10-21T20:00:00', 6000000, 7.50, 8.00, 8.50, 'Active'),
 (20, 8, 4, '2026-10-24T09:30:00', 4500000, NULL, NULL, NULL, 'Active');
SET IDENTITY_INSERT dbo.Enrollments OFF;

SET IDENTITY_INSERT dbo.Payments ON;
INSERT INTO dbo.Payments (PaymentId, EnrollmentId, Amount, PaidAt, Method) VALUES
 (1, 1, 9000000, '2026-09-07T09:20:00', 'Transfer'),
 (2, 2, 6000000, '2026-09-08T14:05:00', 'Card'),
 (3, 3, 9000000, '2026-09-10T10:35:00', 'Transfer'),
 (4, 3, 9000000, '2026-09-30T10:35:00', 'Transfer'),
 (5, 4, 6000000, '2026-09-16T19:05:00', 'Cash'),
 (6, 5, 4000000, '2026-09-17T08:50:00', 'Cash'),
 (7, 6, 9000000, '2026-09-30T20:15:00', 'Card'),
 (8, 7, 3000000, '2026-10-01T09:05:00', 'Transfer'),
 (9, 8, 9000000, '2026-10-06T15:25:00', 'Transfer'),
 (10, 9, 5000000, '2026-10-08T11:05:00', 'Card'),
 (11, 9, 3000000, '2026-10-18T11:05:00', 'Card'),
 (12, 10, 4500000, '2026-10-20T18:35:00', 'Transfer'),
 (13, 11, 6000000, '2026-10-22T09:45:00', 'Card'),
 (14, 12, 8000000, '2026-10-23T13:20:00', 'Transfer'),
 (15, 13, 7500000, '2026-09-09T10:05:00', 'Transfer'),
 (16, 14, 9000000, '2026-09-16T14:35:00', 'Transfer'),
 (17, 15, 3750000, '2026-10-02T19:50:00', 'Card'),
 (18, 16, 2500000, '2026-10-07T08:35:00', 'Cash'),
 (19, 18, 7500000, '2026-10-21T10:15:00', 'Transfer'),
 (20, 19, 6000000, '2026-10-21T20:05:00', 'Card'),
 (21, 20, 4500000, '2026-10-24T09:35:00', 'Transfer');
SET IDENTITY_INSERT dbo.Payments OFF;
GO

-- Kiểm tra nhanh
SELECT 'Categories' AS TableName, COUNT(*) AS NumRows FROM dbo.Categories
UNION ALL SELECT 'Courses',     COUNT(*) FROM dbo.Courses
UNION ALL SELECT 'Students',    COUNT(*) FROM dbo.Students
UNION ALL SELECT 'Enrollments', COUNT(*) FROM dbo.Enrollments
UNION ALL SELECT 'Payments',    COUNT(*) FROM dbo.Payments;
GO


-- BT1: Giữ 2 ký tự đầu phần tên email, che phần còn lại,
--      giữ nguyên @ và tên miền
SELECT
    Email,
    CONCAT(
        LEFT(Email, 2),
        '***',
        SUBSTRING(Email, CHARINDEX('@', Email), LEN(Email))
    ) AS MaskedEmail
FROM dbo.Students;
GO

-- BT2: Tính tuổi theo số năm đầy đủ
DECLARE @today date = CAST(GETDATE() AS date);

SELECT
    StudentId,
    FullName,
    BirthDate,
    DATEDIFF(year, BirthDate, @today)
      - CASE
            WHEN DATEADD(
                     year,
                     DATEDIFF(year, BirthDate, @today),
                     BirthDate
                 ) > @today
            THEN 1
            ELSE 0
        END AS Age
FROM dbo.Students
WHERE BirthDate IS NOT NULL;
GO

-- BT3: So sánh City với @city, xem NULL là bằng NULL
DECLARE @city nvarchar(50) = N'Hà Nội';

SELECT
    StudentId,
    FullName,
    City
FROM dbo.Students
WHERE City IS NOT DISTINCT FROM @city;
GO

-- BT4: Mỗi lượt ghi danh thành một JSON object;
--      điểm NULL vẫn xuất hiện trong mảng scores dưới dạng null
SELECT
    JSON_OBJECT(
        'enrollmentId': EnrollmentId,
        'scores': JSON_QUERY(
            JSON_ARRAY(Score1, Score2, Score3 NULL ON NULL)
        )
    ) AS EnrollmentJson
FROM dbo.Enrollments;
GO

-- BT5: So sánh kiểu dữ liệu và kết quả ISNULL / COALESCE
DECLARE @v varchar(3) = NULL;

SELECT
    ISNULL(@v, 'abcdef') AS IsNullResult,
    COALESCE(@v, 'abcdef') AS CoalesceResult;
GO