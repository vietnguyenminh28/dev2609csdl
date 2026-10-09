USE DevmasterLab;
GO

-- Câu 1: Họ (từ đầu tiên), tên (từ cuối cùng), username,
--        che 3 chữ số giữa của số điện thoại
;WITH StudentData AS
(
    SELECT
        FullName,
        Email,
        TRIM(Phone) AS Phone,
        TRIM(FullName) AS CleanName
    FROM dbo.Students
)
SELECT
    LEFT(CleanName, CHARINDEX(N' ', CleanName + N' ') - 1) AS Ho,
    SUBSTRING(
        CleanName,
        LEN(CleanName) - CHARINDEX(N' ', REVERSE(CleanName) + N' ') + 2,
        LEN(CleanName)
    ) AS Ten,
    LEFT(Email, CHARINDEX('@', Email) - 1) AS UserName,
    CASE
        WHEN Phone IS NULL THEN NULL
        WHEN LEN(Phone) <= 6 THEN REPLICATE('*', LEN(Phone))
        ELSE STUFF(Phone, LEN(Phone) - 5, 3, '***')
    END AS Phone
FROM StudentData;
GO

-- Câu 2: Mã khóa học, học phí theo triệu, học phí/giờ,
--        học phí định dạng Việt Nam
SELECT
    CourseCode,
    CAST(Fee / 1000000.0 AS decimal(12, 1)) AS FeeInMillions,
    ROUND(Fee * 1.0 / NULLIF(Hours, 0), 0) AS FeePerHour,
    FORMAT(Fee, N'N0', 'vi-VN') AS FeeVietnamese
FROM dbo.Courses;
GO

-- Câu 3: Điểm cao nhất/thấp nhất, tên học viên và mã khóa;
--        chỉ lấy các lượt ghi danh 1, 2, 7
SELECT
    e.EnrollmentId,
    s.FullName,
    c.CourseCode,
    GREATEST(e.Score1, e.Score2, e.Score3) AS HighestScore,
    LEAST(e.Score1, e.Score2, e.Score3) AS LowestScore
FROM dbo.Enrollments AS e
JOIN dbo.Students AS s ON s.StudentId = e.StudentId
JOIN dbo.Courses AS c ON c.CourseId = e.CourseId
WHERE e.EnrollmentId IN (1, 2, 7)
ORDER BY e.EnrollmentId;
GO

-- Câu 4a: Thay số điện thoại NULL bằng N'Chưa có'
SELECT
    StudentId,
    FullName,
    COALESCE(Phone, N'Chưa có') AS Phone
FROM dbo.Students;
GO

-- Câu 4b: City khác Hà Nội, bao gồm cả City NULL
DECLARE @city nvarchar(50) = N'Hà Nội';

SELECT
    StudentId,
    FullName,
    City
FROM dbo.Students
WHERE City IS DISTINCT FROM @city;
GO

-- Câu 5: Tag đầu tiên của mỗi khóa học
SELECT
    c.CourseId,
    c.CourseName,
    firstTag.Tag AS FirstTag
FROM dbo.Courses AS c
OUTER APPLY
(
    SELECT TOP (1)
        TRIM(s.value) AS Tag
    FROM STRING_SPLIT(c.Tags, ',', 1) AS s
    WHERE TRIM(s.value) <> N''
    ORDER BY s.ordinal
) AS firstTag;
GO

-- Câu 6: Ngày ghi danh, đầu/cuối tháng, số ngày đến 31/10/2026
SELECT
    EnrollmentId,
    CAST(EnrolledAt AS date) AS EnrollmentDate,
    DATETRUNC(month, EnrolledAt) AS FirstDayOfMonth,
    EOMONTH(EnrolledAt) AS LastDayOfMonth,
    DATEDIFF(
        day,
        CAST(EnrolledAt AS date),
        DATEFROMPARTS(2026, 10, 31)
    ) AS DaysUntil20261031
FROM dbo.Enrollments;
GO

-- Câu 7, cách 1: Bit 0 và bit 1 đều được bật
SELECT
    StudentId,
    FullName,
    Flags
FROM dbo.Students
WHERE (Flags & 1) = 1
  AND (Flags & 2) = 2;
GO

-- Câu 7, cách 2: Dùng GET_BIT
SELECT
    StudentId,
    FullName,
    Flags
FROM dbo.Students
WHERE GET_BIT(Flags, 0) = 1
  AND GET_BIT(Flags, 1) = 1;
GO

-- Câu 8: Mỗi khóa học thành một JSON object
SELECT
    JSON_OBJECT(
        'code': CourseCode,
        'name': CourseName,
        'fee': Fee,
        'hours': Hours
    ) AS CourseJson
FROM dbo.Courses;
GO

-- Câu 9: Cộng học phí theo CourseId, dừng khi tổng vượt 40 triệu
DECLARE @courseId int;
DECLARE @lastCourseId int = 0;
DECLARE @fee decimal(12, 0);
DECLARE @total decimal(18, 0) = 0;
DECLARE @stopCourseId int = NULL;

WHILE 1 = 1
BEGIN
    SET @courseId = NULL;

    SELECT TOP (1)
        @courseId = CourseId,
        @fee = Fee
    FROM dbo.Courses
    WHERE CourseId > @lastCourseId
    ORDER BY CourseId;

    IF @courseId IS NULL
        BREAK;

    SET @total += @fee;
    SET @lastCourseId = @courseId;
    SET @stopCourseId = @courseId;

    IF @total > 40000000
        BREAK;
END;

SELECT
    @stopCourseId AS StoppedAtCourseId,
    @total AS TotalFee;
GO

-- Câu 10: Tách chuỗi, đếm giá trị hợp lệ/không hợp lệ và tính tổng
DECLARE @input nvarchar(100) = N'120000, 45, abc, 7500000, 12x';

DECLARE @ParsedValues TABLE
(
    RawValue nvarchar(100),
    NumericValue bigint NULL
);

INSERT INTO @ParsedValues (RawValue, NumericValue)
SELECT
    TRIM(value),
    TRY_CONVERT(bigint, TRIM(value))
FROM STRING_SPLIT(@input, N',');

-- Xem từng giá trị sau khi chuyển đổi
SELECT RawValue, NumericValue
FROM @ParsedValues;

-- Tổng hợp số lượng và tổng các giá trị hợp lệ
SELECT
    COUNT(CASE WHEN NumericValue IS NOT NULL THEN 1 END) AS ValidCount,
    COUNT(CASE WHEN NumericValue IS NULL THEN 1 END) AS InvalidCount,
    COALESCE(SUM(NumericValue), 0) AS ValidTotal
FROM @ParsedValues;
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