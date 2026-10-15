-- Tạo cơ sở dữ liệu nếu chưa tồn tại
IF DB_ID(N'Lab02') IS NULL
    CREATE DATABASE Lab02;
GO

USE Lab02;
GO

-- Khai báo biến và in giá trị
DECLARE @Name NVARCHAR(50) = N'Nguyen Van An';
DECLARE @Age INT = 20;

PRINT N'Name: ' + @Name;
PRINT N'Age: ' + CONVERT(NVARCHAR(10), @Age);
GO

-- Tạo bảng Employee
IF OBJECT_ID(N'dbo.Employee', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Employee
    (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeCode VARCHAR(10) NOT NULL UNIQUE,
        FullName NVARCHAR(35),
        Gender BIT,
        BirthDay DATETIME,
        Address NVARCHAR(MAX),
        Email VARCHAR(50),
        Salary FLOAT
    );
END;
GO

-- Thêm cột Phone nếu chưa có
IF COL_LENGTH(N'dbo.Employee', N'Phone') IS NULL
    ALTER TABLE dbo.Employee ADD Phone VARCHAR(20);
GO

-- Thêm 5 bản ghi mẫu (chạy phần này một lần)
INSERT INTO dbo.Employee
    (EmployeeCode, FullName, Gender, BirthDay, Address, Email, Salary, Phone)
VALUES
    ('NV01', N'Nguyen Van An', 1, '1995-05-12', N'Hà Nội', 'an@example.com', 2500000, '0900000001'),
    ('NV02', N'Tran Thi Binh', 0, '1980-08-20', N'Hà Nội', 'binh@example.com', 1800000, '0900000002'),
    ('NV03', N'Le Van Cuong', 1, '1965-03-10', N'Đà Nẵng', 'cuong@example.com', 3200000, '0900000003'),
    ('NV04', N'Pham Thi Dung', 0, '2000-11-25', N'Hồ Chí Minh', 'dung@example.com', 2100000, '0900000004'),
    ('NV05', N'Hoang Van E', 1, '1970-10-02', N'Hà Nội', 'e@example.com', 4000000, '0900000005');
GO

-- Đưa ra tất cả nhân viên
SELECT *
FROM dbo.Employee;

-- Đưa ra nhân viên có lương > 2.000.000
SELECT *
FROM dbo.Employee
WHERE Salary > 2000000;

-- Đưa ra nhân viên có sinh nhật trong tháng hiện tại
SELECT *
FROM dbo.Employee
WHERE MONTH(BirthDay) = MONTH(GETDATE());

-- Danh sách nhân viên, tuổi và ngày sinh định dạng dd/mm/yyyy
SELECT
    EmployeeCode,
    FullName,
    DATEDIFF(YEAR, BirthDay, GETDATE())
        - CASE
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, BirthDay, GETDATE()), BirthDay) > GETDATE()
                THEN 1
            ELSE 0
          END AS Age,
    CONVERT(VARCHAR(10), BirthDay, 103) AS BirthDay
FROM dbo.Employee;

-- Đưa ra nhân viên có địa chỉ ở Hà Nội
SELECT *
FROM dbo.Employee
WHERE Address LIKE N'%Hà Nội%';

-- Đổi tên nhân viên mã NV01 thành John
UPDATE dbo.Employee
SET FullName = N'John'
WHERE EmployeeCode = 'NV01';

-- Tạo bảng lưu nhân viên trên 50 tuổi nếu bảng chưa tồn tại
IF OBJECT_ID(N'dbo.EmployeeOver50', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EmployeeOver50
    (
        ID INT PRIMARY KEY,
        EmployeeCode VARCHAR(10) NOT NULL UNIQUE,
        FullName NVARCHAR(35),
        Gender BIT,
        BirthDay DATETIME,
        Address NVARCHAR(MAX),
        Email VARCHAR(50),
        Salary FLOAT,
        Phone VARCHAR(20)
    );
END;
GO

-- Sao chép nhân viên trên 50 tuổi sang bảng mới trước khi xóa
INSERT INTO dbo.EmployeeOver50
    (ID, EmployeeCode, FullName, Gender, BirthDay, Address, Email, Salary, Phone)
SELECT
    E.ID, E.EmployeeCode, E.FullName, E.Gender, E.BirthDay,
    E.Address, E.Email, E.Salary, E.Phone
FROM dbo.Employee AS E
WHERE CONVERT(DATE, E.BirthDay) < DATEADD(YEAR, -50, CONVERT(DATE, GETDATE()))
  AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.EmployeeOver50 AS A
          WHERE A.ID = E.ID
      );

-- Xóa nhân viên trên 50 tuổi khỏi bảng Employee
DELETE FROM dbo.Employee
WHERE CONVERT(DATE, BirthDay) < DATEADD(YEAR, -50, CONVERT(DATE, GETDATE()));

-- Đếm số nhân viên còn lại
SELECT COUNT(*) AS EmployeeCount
FROM dbo.Employee;