CREATE DATABASE DevmasterLab02;
GO

USE DevmasterLab02;
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
--Bài 1
CREATE TABLE dbo.Enrollments
(
    EnrollmentId int IDENTITY(1,1) NOT NULL,
    StudentId    int NOT NULL,
    CourseId     int NOT NULL,
    EnrolledAt   datetime2(0) NOT NULL
        CONSTRAINT DF_Enrollments_EnrolledAt DEFAULT (SYSDATETIME()),
    PaidAmount   decimal(12,0) NOT NULL
        CONSTRAINT DF_Enrollments_PaidAmount DEFAULT (0),
    Score1       decimal(4,2) NULL,
    Score2       decimal(4,2) NULL,
    Score3       decimal(4,2) NULL,
    Status       varchar(20) NOT NULL
        CONSTRAINT DF_Enrollments_Status DEFAULT ('Active'),

    CONSTRAINT PK_Enrollments PRIMARY KEY (EnrollmentId),
    CONSTRAINT FK_Enrollments_Students
        FOREIGN KEY (StudentId) REFERENCES dbo.Students (StudentId),
    CONSTRAINT FK_Enrollments_Courses
        FOREIGN KEY (CourseId) REFERENCES dbo.Courses (CourseId),
    CONSTRAINT CK_Enrollments_PaidAmount CHECK (PaidAmount >= 0),
    CONSTRAINT CK_Enrollments_Score1 CHECK (Score1 BETWEEN 0 AND 10),
    CONSTRAINT CK_Enrollments_Score2 CHECK (Score2 BETWEEN 0 AND 10),
    CONSTRAINT CK_Enrollments_Score3 CHECK (Score3 BETWEEN 0 AND 10),
    CONSTRAINT CK_Enrollments_Status
        CHECK (Status IN ('Active', 'Completed', 'Cancelled'))
);
GO
--Bài 2
CREATE TABLE dbo.Payments
(
    PaymentId    int IDENTITY(1,1) NOT NULL,
    EnrollmentId int NOT NULL,
    Amount       decimal(12,0) NOT NULL,
    PaidAt       datetime2(0) NOT NULL
        CONSTRAINT DF_Payments_PaidAt DEFAULT (SYSDATETIME()),
    Method       varchar(20) NOT NULL
        CONSTRAINT DF_Payments_Method DEFAULT ('Transfer'),

    CONSTRAINT PK_Payments PRIMARY KEY (PaymentId),
    CONSTRAINT FK_Payments_Enrollments
        FOREIGN KEY (EnrollmentId)
        REFERENCES dbo.Enrollments (EnrollmentId)
        ON DELETE CASCADE,
    CONSTRAINT CK_Payments_Amount CHECK (Amount > 0),
    CONSTRAINT CK_Payments_Method
        CHECK (Method IN ('Cash', 'Transfer', 'Card'))
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
--Bài 3
-- Thêm dữ liệu mẫu vào Enrollments
SET IDENTITY_INSERT dbo.Enrollments ON;

INSERT INTO dbo.Enrollments
    (EnrollmentId, StudentId, CourseId, EnrolledAt, PaidAmount,
     Score1, Score2, Score3, Status)
VALUES
    (1,  1,  1, '2026-09-07T09:15:00',  9000000, 7.50, 8.00, NULL, 'Active'),
    (2,  2,  2, '2026-09-08T14:00:00',  6000000, 6.00, NULL, 7.50, 'Completed'),
    (3,  3,  1, '2026-09-10T10:30:00', 18000000, 8.50, 9.00, 8.00, 'Active'),
    (4,  1,  2, '2026-09-15T19:00:00',  6000000, NULL, 8.50, 9.00, 'Completed'),
    (5,  4,  3, '2026-09-17T08:45:00',  4000000, 5.50, 6.50, 7.00, 'Active'),
    (6,  5,  4, '2026-09-30T20:10:00',  9000000, 9.00, NULL, NULL, 'Active'),
    (7,  6,  2, '2026-10-01T09:00:00',  3000000, NULL, NULL, NULL, 'Cancelled'),
    (8,  7,  1, '2026-10-06T15:20:00',  9000000, 7.00, 7.50, 8.00, 'Active'),
    (9,  8,  3, '2026-10-08T11:00:00',  8000000, 6.50, NULL, 8.50, 'Active'),
    (10, 1,  4, '2026-10-20T18:30:00',  4500000, 8.00, 8.50, NULL, 'Active'),
    (11, 5,  2, '2026-10-22T09:40:00',  6000000, 9.50, 9.00, 9.50, 'Active'),
    (12, 3,  3, '2026-10-23T13:15:00',  8000000, NULL, 7.00, NULL, 'Active'),
    (13, 10, 5, '2026-09-09T10:00:00',  7500000, 7.00, 8.00, NULL, 'Active'),
    (14, 11, 1, '2026-09-16T14:30:00',  9000000, 8.00, NULL, NULL, 'Active'),
    (15, 11, 5, '2026-10-02T19:45:00',  3750000, NULL, NULL, NULL, 'Active'),
    (16, 2,  8, '2026-10-07T08:30:00',  2500000, 9.00, 9.50, NULL, 'Completed'),
    (17, 7,  8, '2026-10-09T16:00:00',        0, NULL, NULL, NULL, 'Active'),
    (18, 4,  5, '2026-10-19T10:10:00',  7500000, NULL, NULL, NULL, 'Active'),
    (19, 10, 2, '2026-10-21T20:00:00',  6000000, 7.50, 8.00, 8.50, 'Active'),
    (20, 8,  4, '2026-10-24T09:30:00',  4500000, NULL, NULL, NULL, 'Active');

SET IDENTITY_INSERT dbo.Enrollments OFF;
GO

-- Thêm dữ liệu mẫu vào Payments
SET IDENTITY_INSERT dbo.Payments ON;

INSERT INTO dbo.Payments
    (PaymentId, EnrollmentId, Amount, PaidAt, Method)
VALUES
    (1,  1,  9000000, '2026-09-07T09:20:00', 'Transfer'),
    (2,  2,  6000000, '2026-09-08T14:05:00', 'Card'),
    (3,  3,  9000000, '2026-09-10T10:35:00', 'Transfer'),
    (4,  3,  9000000, '2026-09-30T10:35:00', 'Transfer'),
    (5,  4,  6000000, '2026-09-16T19:05:00', 'Cash'),
    (6,  5,  4000000, '2026-09-17T08:50:00', 'Cash'),
    (7,  6,  9000000, '2026-09-30T20:15:00', 'Card'),
    (8,  7,  3000000, '2026-10-01T09:05:00', 'Transfer'),
    (9,  8,  9000000, '2026-10-06T15:25:00', 'Transfer'),
    (10, 9,  5000000, '2026-10-08T11:05:00', 'Card'),
    (11, 9,  3000000, '2026-10-18T11:05:00', 'Card'),
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
--Bài 4
INSERT INTO dbo.Enrollments (StudentId, CourseId, PaidAmount, Status)
VALUES (9999999, 0999991 , 0, 'Active');

INSERT INTO dbo.Students (FullName, Email)
VALUES (N'Học viên trùng email', 'an.nv@devmaster.vn');

INSERT INTO dbo.Students (FullName, Email)
VALUES (NULL, 'bai4-notnull@devmaster.vn');

INSERT INTO dbo.Courses( CourseCode,CourseName,CategoryId,Fee,Hours)
VALUES ('B4-CHECK',N'Khóa học kiểm tra CHECK',1 ,-1,1);

INSERT INTO dbo.Students(FullName,Email,Phone)
VALUES(N'Học viên thử độ dài','bai4-notnull@devmaster.vn','123456789');

--Bài 5

;WITH DataCategories AS
(
    -- Danh mục gốc
    SELECT CategoryId
    FROM dbo.Categories
    WHERE CategoryName = N'Dữ liệu'

    UNION ALL

    -- Các danh mục con
    SELECT c.CategoryId
    FROM dbo.Categories AS c
    INNER JOIN DataCategories AS dc
        ON c.ParentId = dc.CategoryId
)
UPDATE c
SET Fee = Fee * 1.05
OUTPUT
    inserted.CourseCode AS CourseCode,
    deleted.Fee         AS OldFee,
    inserted.Fee        AS NewFee
FROM dbo.Courses AS c
INNER JOIN DataCategories AS dc
    ON dc.CategoryId = c.CategoryId;


--Bài 6

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT COUNT(*) AS PaymentsBefore
    FROM dbo.Payments
    WHERE EnrollmentId = 9;

    DELETE FROM dbo.Enrollments
    WHERE EnrollmentId = 9;

    SELECT COUNT(*) AS PaymentsAfterDelete
    FROM dbo.Payments
    WHERE EnrollmentId = 9;

    ROLLBACK TRANSACTION;

    SELECT COUNT(*) AS PaymentsAfterDelete
    FROM dbo.Payments
    WHERE EnrollmentId = 9;

    SELECT CASE
                WHEN EXISTS
                    (SELECT 1 FROM dbo.Enrollments WHERE EnrollmentId = 9)
                    THEN N'Enrollment 9 đã được khôi phục'
                    ELSE N'Không tim thấy Enrollment 9'
                END AS RollbackCheck;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

        THROW;
    END CATCH;


                                        --Phần 2
--Bài 1 
CREATE TABLE dbo.Instructors
(
    InstructorId int IDENTITY(1,1) NOT NULL,
    FullName     nvarchar(100) NOT NULL,
    Email        varchar(150) NOT NULL,
    HireDate     date NOT NULL,
    IsActive     bit NOT NULL
        CONSTRAINT DF_Instructors_IsActive DEFAULT (1),

    CONSTRAINT PK_Instructors PRIMARY KEY (InstructorId),
    CONSTRAINT UQ_Instructors_Email UNIQUE (Email)
);
GO

ALTER TABLE dbo.Courses
ADD InstructorId int NULL;
GO

ALTER TABLE dbo.Courses
ADD CONSTRAINT FK_Courses_Instructors
    FOREIGN KEY (InstructorId)
    REFERENCES dbo.Instructors (InstructorId);
GO

--Bài 2
-- Tạo bảng Instructors nếu chưa có
IF OBJECT_ID(N'dbo.Instructors', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Instructors
    (
        InstructorId int IDENTITY(1,1) NOT NULL,
        FullName     nvarchar(100) NOT NULL,
        Email        varchar(150) NOT NULL,
        HireDate     date NOT NULL,
        IsActive     bit NOT NULL
            CONSTRAINT DF_Instructors_IsActive DEFAULT (1),

        CONSTRAINT PK_Instructors PRIMARY KEY (InstructorId),
        CONSTRAINT UQ_Instructors_Email UNIQUE (Email)
    );
END;
GO

-- Thêm cột InstructorId nếu chưa có
IF COL_LENGTH(N'dbo.Courses', N'InstructorId') IS NULL
BEGIN
    ALTER TABLE dbo.Courses
    ADD InstructorId int NULL;
END;
GO

-- Thêm khóa ngoại nếu chưa có
IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_Courses_Instructors'
      AND parent_object_id = OBJECT_ID(N'dbo.Courses')
)
BEGIN
    ALTER TABLE dbo.Courses WITH CHECK
    ADD CONSTRAINT FK_Courses_Instructors
        FOREIGN KEY (InstructorId)
        REFERENCES dbo.Instructors (InstructorId);
END;
GO

--Bài 3 
-- Nếu chưa tạo #PriceList trong query window hiện tại:
CREATE TABLE #PriceList
(
    CourseCode varchar(20) NOT NULL PRIMARY KEY,
    Fee        decimal(12,0) NOT NULL CHECK (Fee >= 0)
);

-- Nạp dữ liệu vào #PriceList trước khi chạy MERGE.

;MERGE dbo.Courses AS target
USING #PriceList AS source
    ON target.CourseCode = source.CourseCode
WHEN MATCHED THEN
    UPDATE SET target.Fee = source.Fee
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CourseCode, CourseName, CategoryId, Fee, Hours)
    VALUES (source.CourseCode, source.CourseCode, 1, source.Fee, 40)
OUTPUT
    CASE
        WHEN deleted.CourseCode IS NULL THEN 'INSERT'
        ELSE 'UPDATE'
    END AS ActionTaken,
    inserted.CourseCode,
    deleted.Fee  AS OldFee,
    inserted.Fee AS NewFee;

    -- Sao lưu COPY_ONLY
BACKUP DATABASE [DevmasterLab02]
TO DISK = N'C:\SQLBackups\DevmasterLab02_CopyOnly.bak'
WITH COPY_ONLY, CHECKSUM, STATS = 10;
GO

-- Xem logical file names trong backup trước khi restore
RESTORE FILELISTONLY
FROM DISK = N'C:\SQLBackups\DevmasterLab02_CopyOnly.bak';
GO

-- Chỉ chạy khi DevmasterLab_Test chưa tồn tại
RESTORE DATABASE [DevmasterLab_Test]
FROM DISK = N'C:\SQLBackups\DevmasterLab02_CopyOnly.bak'
WITH
    MOVE N'DevmasterLab02'
        TO N'C:\SQLData\DevmasterLab_Test.mdf',
    MOVE N'DevmasterLab02_log'
        TO N'C:\SQLData\DevmasterLab_Test_log.ldf',
    RECOVERY,
    CHECKSUM,
    STATS = 10;
GO

SELECT N'Categories' AS TableName, COUNT_BIG(*) AS TotalRows
    FROM [DevmasterLab_Test].[dbo].[Categories]
UNION ALL
SELECT N'Courses', COUNT_BIG(*)
    FROM [DevmasterLab_Test].[dbo].[Courses]
UNION ALL
SELECT N'Students', COUNT_BIG(*)
    FROM [DevmasterLab_Test].[dbo].[Students]
UNION ALL
SELECT N'Enrollments', COUNT_BIG(*)
    FROM [DevmasterLab_Test].[dbo].[Enrollments]
UNION ALL
SELECT N'Payments', COUNT_BIG(*)
    FROM [DevmasterLab_Test].[dbo].[Payments];