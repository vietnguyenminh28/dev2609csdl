CREATE DATABASE DevmasterLab03;
GO

USE DevmasterLab03;
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

-- Xóa bảng con trước, sau đó mới xóa bảng cha.
IF OBJECT_ID(N'dbo.Attendance', N'U') IS NOT NULL
    DROP TABLE dbo.Attendance;

IF OBJECT_ID(N'dbo.ClassStudents', N'U') IS NOT NULL
    DROP TABLE dbo.ClassStudents;

IF OBJECT_ID(N'dbo.Classes', N'U') IS NOT NULL
    DROP TABLE dbo.Classes;

IF OBJECT_ID(N'dbo.seq_ClassNo', N'SO') IS NOT NULL
    DROP SEQUENCE dbo.seq_ClassNo;
GO

-- Bài 1: Lớp học mở theo khóa học
CREATE TABLE dbo.Classes
(
    ClassId int IDENTITY(1,1)
        CONSTRAINT PK_Classes PRIMARY KEY,

    ClassCode varchar(20) NOT NULL
        CONSTRAINT UQ_Classes_ClassCode UNIQUE,

    CourseId int NOT NULL
        CONSTRAINT FK_Classes_Courses
        REFERENCES dbo.Courses(CourseId),

    StartDate date NOT NULL,
    EndDate date NOT NULL,

    MaxStudents int NOT NULL
        CONSTRAINT DF_Classes_MaxStudents DEFAULT (30),

    Room nvarchar(30) NULL,

    Status varchar(20) NOT NULL
        CONSTRAINT DF_Classes_Status DEFAULT ('Open'),

    CONSTRAINT CK_Classes_DateRange
        CHECK (EndDate > StartDate),

    CONSTRAINT CK_Classes_MaxStudents
        CHECK (MaxStudents BETWEEN 5 AND 60),

    CONSTRAINT CK_Classes_Status
        CHECK (Status IN ('Open', 'Running', 'Closed'))
);
GO

-- Bài 2: Mỗi học viên chỉ xuất hiện một lần trong một lớp.
-- Vì cặp (ClassId, StudentId) đã định danh duy nhất bản ghi,
-- không cần thêm cột Id tự tăng.
CREATE TABLE dbo.ClassStudents
(
    ClassId int NOT NULL,
    StudentId int NOT NULL,

    JoinedAt datetime2(0) NOT NULL
        CONSTRAINT DF_ClassStudents_JoinedAt DEFAULT (SYSDATETIME()),

    Grade decimal(4,2) NULL,

    CONSTRAINT PK_ClassStudents
        PRIMARY KEY (ClassId, StudentId),

    CONSTRAINT FK_ClassStudents_Classes
        FOREIGN KEY (ClassId) REFERENCES dbo.Classes(ClassId),

    CONSTRAINT FK_ClassStudents_Students
        FOREIGN KEY (StudentId) REFERENCES dbo.Students(StudentId),

    CONSTRAINT CK_ClassStudents_Grade
        CHECK (Grade BETWEEN 0 AND 10)
);
GO

-- Bài 3: Điểm danh; khóa ngoại tổng hợp tham chiếu ClassStudents.
CREATE TABLE dbo.Attendance
(
    AttendanceId int IDENTITY(1,1)
        CONSTRAINT PK_Attendance PRIMARY KEY,

    ClassId int NOT NULL,
    StudentId int NOT NULL,
    SessionDate date NOT NULL,

    IsPresent bit NOT NULL
        CONSTRAINT DF_Attendance_IsPresent DEFAULT (1),

    Note nvarchar(200) NULL,

    CONSTRAINT FK_Attendance_ClassStudents
        FOREIGN KEY (ClassId, StudentId)
        REFERENCES dbo.ClassStudents(ClassId, StudentId)
        ON DELETE CASCADE,

    CONSTRAINT UQ_Attendance_Class_Student_Session
        UNIQUE (ClassId, StudentId, SessionDate)
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

INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate, MaxStudents, Room) VALUES
 ('SQL-K01',   2, '2026-10-05', '2026-12-14', 25, N'P301'),
 ('REACT-K02', 3, '2026-10-12', '2027-01-18', 30, N'P302'),
 ('GIT-K01',   8, '2026-11-02', '2026-11-27', 20, NULL);

 SELECT * FROM dbo.Classes

 -- Bài 5(a): Ghi danh học viên ở Hà Nội vào SQL-K01.
DECLARE @Rows int;

INSERT INTO dbo.ClassStudents (ClassId, StudentId)
SELECT c.ClassId, s.StudentId
FROM dbo.Students AS s
CROSS JOIN dbo.Classes AS c
WHERE s.City = N'Hà Nội'
  AND c.ClassCode = 'SQL-K01'
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.ClassStudents AS cs
      WHERE cs.ClassId = c.ClassId
        AND cs.StudentId = s.StudentId
  );

SET @Rows = @@ROWCOUNT;
SELECT N'Bài 5(a) - số dòng thêm' AS Result, @Rows AS RowsAdded;


-- Bài 5(b): Ghi danh học viên có bit 1 (học bổng) bật vào REACT-K02.
INSERT INTO dbo.ClassStudents (ClassId, StudentId)
SELECT c.ClassId, s.StudentId
FROM dbo.Students AS s
CROSS JOIN dbo.Classes AS c
WHERE (s.Flags & 2) = 2
  AND c.ClassCode = 'REACT-K02'
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.ClassStudents AS cs
      WHERE cs.ClassId = c.ClassId
        AND cs.StudentId = s.StudentId
  );

SELECT N'Bài 5(b) - số dòng thêm' AS Result, @@ROWCOUNT AS RowsAdded;


-- Bài 6(a): Điểm danh ngày 05/10/2026; IsPresent mặc định là 1.
INSERT INTO dbo.Attendance (ClassId, StudentId, SessionDate)
SELECT cs.ClassId, cs.StudentId, CONVERT(date, '20261005', 112)
FROM dbo.ClassStudents AS cs
JOIN dbo.Classes AS c ON c.ClassId = cs.ClassId
WHERE c.ClassCode = 'SQL-K01'
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Attendance AS a
      WHERE a.ClassId = cs.ClassId
        AND a.StudentId = cs.StudentId
        AND a.SessionDate = CONVERT(date, '20261005', 112)
  );

SELECT N'Bài 6(a) - số dòng thêm' AS Result, @@ROWCOUNT AS RowsAdded;


-- Bài 6(b): Điểm danh ngày 07/10/2026; IsPresent mặc định là 1.
INSERT INTO dbo.Attendance (ClassId, StudentId, SessionDate)
SELECT cs.ClassId, cs.StudentId, CONVERT(date, '20261007', 112)
FROM dbo.ClassStudents AS cs
JOIN dbo.Classes AS c ON c.ClassId = cs.ClassId
WHERE c.ClassCode = 'SQL-K01'
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Attendance AS a
      WHERE a.ClassId = cs.ClassId
        AND a.StudentId = cs.StudentId
        AND a.SessionDate = CONVERT(date, '20261007', 112)
  );

SELECT N'Bài 6(b) - số dòng thêm' AS Result, @@ROWCOUNT AS RowsAdded;


-- Bài 6(c): Học viên 10 vắng ngày 05/10/2026, ghi chú Ốm.
UPDATE a
SET IsPresent = 0,
    Note = N'Ốm'
FROM dbo.Attendance AS a
JOIN dbo.Classes AS c ON c.ClassId = a.ClassId
WHERE c.ClassCode = 'SQL-K01'
  AND a.StudentId = 10
  AND a.SessionDate = CONVERT(date, '20261005', 112);

SELECT N'Số dòng cập nhật ngày 05/10' AS Result, @@ROWCOUNT AS RowsUpdated;


-- Học viên 3 và 10 vắng ngày 07/10/2026.
UPDATE a
SET IsPresent = 0
FROM dbo.Attendance AS a
JOIN dbo.Classes AS c ON c.ClassId = a.ClassId
WHERE c.ClassCode = 'SQL-K01'
  AND a.StudentId IN (3, 10)
  AND a.SessionDate = CONVERT(date, '20261007', 112);

SELECT N'Số dòng cập nhật ngày 07/10' AS Result, @@ROWCOUNT AS RowsUpdated;


-- Đếm số dòng vắng trong hai buổi của lớp SQL-K01.
SELECT COUNT(*) AS AbsentRows
FROM dbo.Attendance AS a
JOIN dbo.Classes AS c ON c.ClassId = a.ClassId
WHERE c.ClassCode = 'SQL-K01'
  AND a.IsPresent = 0
  AND a.SessionDate IN
  (
      CONVERT(date, '20261005', 112),
      CONVERT(date, '20261007', 112)
  );


-- Bài 7: Mỗi lệnh dưới đây cố ý gây lỗi; chạy riêng từng lệnh để xem lỗi.

-- (a) Vi phạm CK_Classes_DateRange — Msg 547.
UPDATE dbo.Classes
SET EndDate = DATEADD(day, -1, StartDate)
WHERE ClassCode = 'SQL-K01';

-- (b) Vi phạm CK_Classes_MaxStudents — Msg 547.
UPDATE dbo.Classes
SET MaxStudents = 3
WHERE ClassCode = 'SQL-K01';

-- (c) Vi phạm FK_Attendance_ClassStudents — Msg 547.
-- StudentId = -1 không có trong ClassStudents của lớp này.
INSERT INTO dbo.Attendance (ClassId, StudentId, SessionDate)
SELECT c.ClassId, -1, CONVERT(date, '20991231', 112)
FROM dbo.Classes AS c
WHERE c.ClassCode = 'SQL-K01';

-- (d) Vi phạm UQ_Attendance_Class_Student_Session — Msg 2627.
-- Sao chép một dòng đã có để tạo trùng (lớp, học viên, ngày).
INSERT INTO dbo.Attendance (ClassId, StudentId, SessionDate)
SELECT TOP (1) a.ClassId, a.StudentId, a.SessionDate
FROM dbo.Attendance AS a
JOIN dbo.Classes AS c ON c.ClassId = a.ClassId
WHERE c.ClassCode = 'SQL-K01'
  AND a.SessionDate = CONVERT(date, '20261005', 112)
ORDER BY a.StudentId;

-- (e) Vi phạm CK_Classes_Status — Msg 547.
UPDATE dbo.Classes
SET Status = 'Paused'
WHERE ClassCode = 'SQL-K01';


;WITH CategoryTree AS
(
    SELECT CategoryId
    FROM dbo.Categories
    WHERE CategoryName = N'Lập trình'

    UNION ALL

    SELECT child.CategoryId
    FROM dbo.Categories AS child
    JOIN CategoryTree AS parent
      ON child.ParentId = parent.CategoryId
)
UPDATE cl
SET EndDate = DATEADD(day, 7, cl.EndDate)
OUTPUT
    inserted.ClassCode,
    deleted.EndDate AS OldEndDate,
    inserted.EndDate AS NewEndDate
FROM dbo.Classes AS cl
JOIN dbo.Courses AS co
  ON co.CourseId = cl.CourseId
JOIN CategoryTree AS ct
  ON ct.CategoryId = co.CategoryId
OPTION (MAXRECURSION 100);

--Bai 9
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @ClassId int;

    SELECT @ClassId = ClassId
    FROM dbo.Classes
    WHERE ClassCode = 'SQL-K01';

    IF @ClassId IS NULL
    BEGIN
        THROW 50001, 'Không tìm thấy lớp SQL-K01.', 1;
    END;

    SELECT
        N'Trước khi xóa' AS Stage,
        (SELECT COUNT(*)
         FROM dbo.ClassStudents
         WHERE ClassId = @ClassId) AS ClassStudentsRows,
        (SELECT COUNT(*)
         FROM dbo.Attendance
         WHERE ClassId = @ClassId) AS AttendanceRows;

    DELETE FROM dbo.ClassStudents
    OUTPUT deleted.*
    WHERE ClassId = @ClassId
      AND StudentId = 10;

    SELECT
        N'Sau khi xóa' AS Stage,
        (SELECT COUNT(*)
         FROM dbo.ClassStudents
         WHERE ClassId = @ClassId) AS ClassStudentsRows,
        (SELECT COUNT(*)
         FROM dbo.Attendance
         WHERE ClassId = @ClassId) AS AttendanceRows;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;

-- (a) Số ngày tính cả ngày bắt đầu và ngày kết thúc.
ALTER TABLE dbo.Classes
ADD DurationDays AS (DATEDIFF(day, StartDate, EndDate) + 1) PERSISTED;
GO

-- (b) Chỉ áp dụng tính duy nhất khi Room khác NULL.
-- SQL Server không hỗ trợ filtered UNIQUE constraint qua ALTER TABLE;
-- trường hợp này cần dùng CREATE UNIQUE INDEX.
CREATE UNIQUE INDEX UQ_Classes_Room_StartDate
ON dbo.Classes (Room, StartDate)
WHERE Room IS NOT NULL;
GO

IF OBJECT_ID(N'dbo.seq_ClassNo', N'SO') IS NOT NULL
    DROP SEQUENCE dbo.seq_ClassNo;
GO

CREATE SEQUENCE dbo.seq_ClassNo
    AS int
    START WITH 4
    INCREMENT BY 1;
GO


INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate)
SELECT
    CONCAT('DM-2026-', FORMAT(NEXT VALUE FOR dbo.seq_ClassNo, '000')),
    c.CourseId,
    CONVERT(date, '20261102', 112),
    CONVERT(date, '20270111', 112)
FROM dbo.Courses AS c
WHERE c.CourseCode = 'SQL-DEV';


                            --Part 2

--Bai 1
CREATE TABLE dbo.Rooms
(
    RoomCode nvarchar(30) NOT NULL
        CONSTRAINT PK_Rooms PRIMARY KEY,

    Capacity int NOT NULL,

    HasProjector bit NOT NULL
        CONSTRAINT DF_Rooms_HasProjector DEFAULT (1),

    CONSTRAINT CK_Rooms_Capacity
        CHECK (Capacity BETWEEN 5 AND 100)
);
GO

INSERT INTO dbo.Rooms (RoomCode, Capacity)
VALUES
    (N'P301', 30),
    (N'P302', 40);
GO

-- Thêm FK sau khi các mã phòng đã tồn tại trong Rooms.
ALTER TABLE dbo.Classes
ADD CONSTRAINT FK_Classes_Rooms
    FOREIGN KEY (Room)
    REFERENCES dbo.Rooms(RoomCode);
GO

--Bai 2
CREATE TABLE dbo.ClassesArchive
(
    ClassId int NOT NULL,
    ClassCode varchar(20) NOT NULL,
    CourseId int NOT NULL,
    StartDate date NOT NULL,
    EndDate date NOT NULL,
    MaxStudents int NOT NULL,
    Room nvarchar(30) NULL,
    Status varchar(20) NOT NULL,
    DurationDays int NOT NULL,
    ArchivedAt datetime2(0) NOT NULL
);
GO

DELETE c
OUTPUT
    deleted.ClassId,
    deleted.ClassCode,
    deleted.CourseId,
    deleted.StartDate,
    deleted.EndDate,
    deleted.MaxStudents,
    deleted.Room,
    deleted.Status,
    deleted.DurationDays,
    CONVERT(datetime2(0), SYSDATETIME())
INTO dbo.ClassesArchive
(
    ClassId,
    ClassCode,
    CourseId,
    StartDate,
    EndDate,
    MaxStudents,
    Room,
    Status,
    DurationDays,
    ArchivedAt
)
FROM dbo.Classes AS c
WHERE c.Status = 'Closed'
  AND c.EndDate < CONVERT(date, GETDATE());

  DECLARE @TestCode varchar(20) =
    'ARC-' + LEFT(REPLACE(CONVERT(varchar(36), NEWID()), '-', ''), 16);

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Classes
        (ClassCode, CourseId, StartDate, EndDate, Status)
    SELECT
        @TestCode,
        c.CourseId,
        CONVERT(date, '20000101', 112),
        CONVERT(date, '20000102', 112),
        'Closed'
    FROM dbo.Courses AS c
    WHERE c.CourseCode = 'SQL-DEV';

    DELETE cl
    OUTPUT
        deleted.ClassId,
        deleted.ClassCode,
        deleted.CourseId,
        deleted.StartDate,
        deleted.EndDate,
        deleted.MaxStudents,
        deleted.Room,
        deleted.Status,
        deleted.DurationDays,
        CONVERT(datetime2(0), SYSDATETIME())
    INTO dbo.ClassesArchive
    (
        ClassId, ClassCode, CourseId, StartDate, EndDate,
        MaxStudents, Room, Status, DurationDays, ArchivedAt
    )
    FROM dbo.Classes AS cl
    WHERE cl.ClassCode = @TestCode
      AND cl.Status = 'Closed'
      AND cl.EndDate < CONVERT(date, GETDATE());

    SELECT *
    FROM dbo.ClassesArchive
    WHERE ClassCode = @TestCode;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;

SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityBefore;

BEGIN TRANSACTION;
DELETE FROM dbo.Attendance;
SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityAfterDelete;
ROLLBACK TRANSACTION;

SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityAfterRollback;

SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityBefore;

BEGIN TRANSACTION;
TRUNCATE TABLE dbo.Attendance;
SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityAfterTruncate;
ROLLBACK TRANSACTION;

SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityAfterRollback;

SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityBefore;

BEGIN TRANSACTION;
DROP TABLE dbo.Attendance;
SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityAfterDrop;
ROLLBACK TRANSACTION;

SELECT IDENT_CURRENT(N'dbo.Attendance') AS IdentityAfterRollback;

CREATE TABLE dbo.ClassSessions
(
    ClassId int NOT NULL,
    SessionNo int NOT NULL,
    SessionDate date NOT NULL,
    RoomCode nvarchar(30) NULL,
    Content nvarchar(200) NULL,

    CONSTRAINT PK_ClassSessions
        PRIMARY KEY (ClassId, SessionNo),

    CONSTRAINT FK_ClassSessions_Classes
        FOREIGN KEY (ClassId)
        REFERENCES dbo.Classes(ClassId),

    CONSTRAINT FK_ClassSessions_Rooms
        FOREIGN KEY (RoomCode)
        REFERENCES dbo.Rooms(RoomCode),

    CONSTRAINT CK_ClassSessions_SessionNo
        CHECK (SessionNo > 0)
);