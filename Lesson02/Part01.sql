Create database Dev2601_Lesson02_lab02
Go
CREATE DATABASE ShopDemo
ON PRIMARY (
    NAME = N'ShopDemo_data',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\ShopDemo_data.mdf',
    SIZE = 64MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 64MB
)
LOG ON (
    NAME = N'ShopDemo_log',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\ShopDemo_log.ldf',
    SIZE = 32MB,
    FILEGROWTH = 32MB
)
COLLATE Vietnamese_100_CI_AS_SC_UTF8;

-- CI: không phân biệt hoa/thường; AI: không phân biệt dấu;
-- AS: phân biệt dấu.
SELECT
    CASE WHEN N'Hà Nội' = N'ha noi' COLLATE Vietnamese_100_CI_AI
        THEN 1 ELSE 0 END AS CI_AI,
    CASE WHEN N'Hà Nội' = N'ha noi' COLLATE Vietnamese_100_CI_AS
        THEN 1 ELSE 0 END AS CI_AS,
    CASE WHEN N'Hà Nội' = N'HÀ NỘI' COLLATE Vietnamese_100_CI_AS
        THEN 1 ELSE 0 END AS CI_AS_Upper;

SELECT name
FROM sys.fn_helpcollations()
WHERE name LIKE N'Vietnamese[_]100%UTF8';


-- Tùy chọn: đổi recovery model và giới hạn kích thước file dữ liệu
ALTER DATABASE ShopDemo
SET RECOVERY SIMPLE;
GO

ALTER DATABASE ShopDemo
MODIFY FILE
(
    NAME = ShopDemo_data,
    MAXSIZE = 4GB
);
GO

-- Xóa ShopDemo: chuyển sang master, ngắt kết nối khác rồi xóa
USE master;
GO

IF DB_ID(N'ShopDemo') IS NOT NULL
BEGIN
    ALTER DATABASE ShopDemo
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE ShopDemo;
END;
GO

USE ShopDemo
GO

CREATE TABLE dbo.DemoDefaults
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(100) NOT NULL, -- Bắt buộc
    Note NVARCHAR(200) NULL,      -- Được phép NULL
    IsActive BIT NOT NULL
        CONSTRAINT DF_DemoDefaults_IsActive DEFAULT 1,
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_DemoDefaults_Created DEFAULT SYSDATETIME()
);

INSERT INTO dbo.DemoDefaults (Title)
VALUES (N'Bỏ qua cột DEFAULT');

INSERT INTO dbo.DemoDefaults (Title, IsActive)
VALUES (N'Dùng từ khóa', DEFAULT);

INSERT INTO dbo.DemoDefaults (Title, Note, IsActive)
VALUES (N'Ghi đè', NULL, 0);

SELECT *
From dbo.DemoDefaults;

-- IDENTITY: tự tăng theo bảng
INSERT INTO dbo.DemoDefaults (Title)
VALUES (N'Bản ghi mới');

SELECT SCOPE_IDENTITY() AS NewId; 
SELECT IDENT_CURRENT('dbo.DemoDefaults') AS LastId; 

CREATE SEQUENCE dbo.InvoiceNo
    AS INT
    START WITH 1000
    INCREMENT BY 1;
GO

SELECT
    NEXT VALUE FOR dbo.InvoiceNo AS No1,
    NEXT VALUE FOR dbo.InvoiceNo AS No2;
GO

CREATE TABLE dbo.DemoInvoices
(
    InvoiceNo INT NOT NULL
        CONSTRAINT DF_DemoInvoices_No
            DEFAULT (NEXT VALUE FOR dbo.InvoiceNo)
        CONSTRAINT PK_DemoInvoices PRIMARY KEY,
    Amount DECIMAL(12,0) NOT NULL
);

INSERT INTO dbo.DemoInvoices (Amount)
VALUES (500000), (750000);

SELECT *
FROM dbo.DemoInvoices;



CREATE TABLE dbo.Students (
    StudentId int IDENTITY(1,1) CONSTRAINT PK_Students PRIMARY KEY,
    FullName  nvarchar(100) NOT NULL,
    Email     varchar(150) NOT NULL CONSTRAINT UQ_Students_Email UNIQUE,
    Phone     varchar(15) NULL,
    City      nvarchar(50) NULL,
    BirthDate date        NULL,
    Flags     int         NOT NULL CONSTRAINT DF_Students_Flags DEFAULT 0,
    CreatedAt datetime2(0) NOT NULL
              CONSTRAINT DF_Students_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Students_Email CHECK (Email LIKE '%_@_%')
);


CREATE TABLE dbo.Categories (
    CategoryId   int IDENTITY(1,1) 
                 CONSTRAINT PK_Categories PRIMARY KEY,
    CategoryName nvarchar(100) NOT NULL
                 CONSTRAINT UQ_Categories_Name UNIQUE,
    ParentId     int NULL             
                 CONSTRAINT FK_Categories_Parent
                 REFERENCES dbo.Categories(CategoryId)
);

CREATE TABLE dbo.Courses (
    CourseId   int IDENTITY(1,1) CONSTRAINT PK_Courses PRIMARY KEY,
    CourseCode varchar(20)   NOT NULL CONSTRAINT UQ_Courses_Code UNIQUE,
    CourseName nvarchar(200) NOT NULL,
    CategoryId int           NOT NULL
               CONSTRAINT FK_Courses_Categories
               REFERENCES dbo.Categories(CategoryId),
    Fee        decimal(12,0) NOT NULL
               CONSTRAINT CK_Courses_Fee CHECK (Fee >= 0),
    Hours      int           NOT NULL
               CONSTRAINT CK_Courses_Hours CHECK (Hours > 0),
    Tags       nvarchar(400) NULL,
    IsActive   bit           NOT NULL
               CONSTRAINT DF_Courses_IsActive DEFAULT 1
);

Alter Table dbo.Courses
    ADD FeePerHour AS  CAST(Fee / Hours AS decimal(12,0)) PERSISTED;


ALTER TABLE dbo.Students
    ADD Gender char(1) NULL
        CONSTRAINT CK_Students_Gender CHECK (Gender IN ('M', 'F'));

ALTER TABLE dbo.Students ALTER COLUMN Phone varchar(20) NULL;

ALTER TABLE dbo.Students DROP CONSTRAINT CK_Students_Gender;
ALTER TABLE dbo.Students DROP COLUMN Gender;

-- Thêm ràng buộc; WITH CHECK kiểm tra cả dữ liệu đang có
ALTER TABLE dbo.Courses WITH CHECK
    ADD CONSTRAINT CK_Courses_CodeLen CHECK (LEN(CourseCode) >= 2);

-- Tạm tắt FK khi nạp dữ liệu lớn, sau đó bật lại và kiểm tra
ALTER TABLE dbo.Courses NOCHECK CONSTRAINT FK_Courses_Categories;
ALTER TABLE dbo.Courses WITH CHECK CHECK CONSTRAINT FK_Courses_Categories;

-- Xóa ràng buộc theo tên
ALTER TABLE dbo.Courses DROP CONSTRAINT CK_Courses_CodeLen;


 INSERT INTO dbo.Categories(CategoryName, ParentId)
 Values (N'Lập trình', NULL),(N'Dữ liệu', NULL),
        (N'Trí tuệ nhân tạo', NULL),(N'Lập trình web .NET', 1),
        (N'FrontEnd', 1),(N'Cơ sở dữ liệu', 2),
        (N'Phân tích dữ liệu', 2),(N'Ứng dụng AI', 3);

        SELECT * INTO dbo.Categories_Backup
        From dbo.Categories WHERE 1=0;
        INSERT INTO dbo.Categories_Backup(CategoryName,ParentId)
        SELECT CategoryName,ParentId
        From dbo.Categories Where ParentId IS NULL;

      
UPDATE dbo.Students
SET City = N'Hà Nội', Flags = Flags | 1          -- bật bit 0
WHERE Email = 'tam.nt@devmaster.vn';

UPDATE c
SET c.Fee = c.Fee * 0.9
FROM dbo.Courses AS c
JOIN dbo.Categories AS cat ON cat.CategoryId = c.CategoryId
WHERE cat.CategoryName = N'Frontend';