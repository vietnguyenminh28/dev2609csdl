use DevmasterLab
Go

SELECT * From dbo.Categories;
go


-- Chọn cột cụ thể (không dùng * trong code ứng dụng)
SELECT CourseCode, CourseName, Fee
FROM dbo.Courses;

-- Bí danh cột, hằng, biểu thức
SELECT CourseCode             AS Code,
	   N'khóa học'             AS Kind,        -- hằng
	   Fee / Hours             AS FeePerHour,  -- biểu thức
	   Fee * 1.08              AS FeeWithVAT,
	   CONCAT(CourseCode, N' - ', CourseName) AS Title
FROM dbo.Courses;

-- SELECT không cần FROM
SELECT SYSDATETIME() AS Now, 2 + 3 AS Result;

-- Phân loại điểm bằng biểu thức CASE
SELECT e.EnrollmentId,
	   e.Score3,
	   CASE
		   WHEN e.Score3 IS NULL THEN N'Chưa thi'
		   WHEN e.Score3 >= 8.5 THEN N'Giỏi'
		   WHEN e.Score3 >= 7.0 THEN N'Khá'
		   WHEN e.Score3 >= 5.0 THEN N'Trung bình'
		   ELSE N'Chưa đạt'
	   END AS Grade
FROM dbo.Enrollments AS e;	

-- AND được ưu tiên trước OR: kết quả khác nhau nếu không dùng ngoặc
SELECT FullName, City, Flags
FROM dbo.Students
WHERE City = N'Hà Nội' OR City = N'Bắc Ninh'
  AND Flags > 1; -- Ví dụ: 5 dòng

-- Dùng ngoặc để áp dụng điều kiện AND cho cả hai thành phố
SELECT FullName, City, Flags
FROM dbo.Students
WHERE (City = N'Hà Nội' OR City = N'Bắc Ninh')
  AND Flags > 1; -- Ví dụ: 3 dòng

-- IN: thuộc một tập giá trị
SELECT CourseCode, Fee
FROM dbo.Courses
WHERE CourseCode IN ('SQL-DEV', 'PY-DA', 'PBI');

-- BETWEEN: bao gồm cả hai đầu mút
SELECT CourseCode, Fee
FROM dbo.Courses
WHERE Fee BETWEEN 5000000 AND 9000000;

-- Khoảng thời gian: dùng >= và < (phù hợp cả khi cột có phần giờ)
SELECT EnrollmentId, EnrolledAt
FROM dbo.Enrollments
WHERE EnrolledAt >= '2026-10-01'
  AND EnrolledAt <  '2026-11-01';

-- NULL: dùng IS NULL / IS NOT NULL
SELECT FullName
FROM dbo.Students
WHERE Phone IS NULL;

-- LIKE: tìm chuỗi bắt đầu bằng 'Nguyễn'
SELECT FullName
FROM dbo.Students
WHERE FullName LIKE N'Nguyễn%';

-- LIKE: tìm chuỗi có chứa 'Thu'
SELECT FullName
FROM dbo.Students
WHERE FullName LIKE N'%Thu%';

-- Dấu gạch dưới (_) đại diện cho đúng một ký tự
SELECT CourseCode
FROM dbo.Courses
WHERE CourseCode LIKE '___'; -- đúng 3 ký tự

-- Tìm mã có ký tự đầu trong khoảng A đến P
SELECT CourseCode
FROM dbo.Courses
WHERE CourseCode LIKE '[A-P]%';

-- Tìm mã có ký tự đầu nằm ngoài khoảng A đến P
SELECT CourseCode
FROM dbo.Courses
WHERE CourseCode LIKE '[^A-P]%';

-- Tìm ký tự '_' theo nghĩa đen bằng ESCAPE
SELECT CASE
		   WHEN 'SQL_2022' LIKE '%!_%' ESCAPE '!'
			   THEN 1
		   ELSE 0
	   END AS HasUnderscore;

-- DISTINCT: mỗi thành phố chỉ xuất hiện một lần
SELECT DISTINCT City
FROM dbo.Students;

-- DISTINCT trên nhiều cột: loại bỏ các dòng trùng cả City và Flags
SELECT DISTINCT City, Flags
FROM dbo.Students;

-- COUNT(DISTINCT ...) không đếm giá trị NULL
SELECT COUNT(DISTINCT City) AS NumCities
FROM dbo.Students;

-- ORDER BY nhiều cột: sắp xếp theo CategoryId trước, rồi Fee
SELECT CourseCode, CategoryId, Fee
FROM dbo.Courses
ORDER BY CategoryId ASC, Fee DESC;

-- SQL Server xếp NULL ở đầu khi sắp xếp ASC
SELECT FullName, BirthDate
FROM dbo.Students
ORDER BY BirthDate ASC;

-- Có thể sắp xếp theo bí danh cột
SELECT CourseCode, Fee / Hours AS FeePerHour
FROM dbo.Courses
ORDER BY FeePerHour DESC;

-- TOP: lấy 3 khóa học có học phí cao nhất
SELECT TOP (3) CourseCode, Fee
FROM dbo.Courses
ORDER BY Fee DESC;

-- WITH TIES: lấy các dòng đồng hạng với dòng cuối cùng
SELECT TOP (1) WITH TIES CourseCode, Hours -- Có thể trả về nhiều khóa học
FROM dbo.Courses
ORDER BY Hours DESC;

-- PERCENT: lấy 25 phần trăm số dòng
SELECT TOP (25) PERCENT FullName
FROM dbo.Students
ORDER BY StudentId;

-- Phân trang cho API
DECLARE @Page int = 2, @PageSize int = 5;

SELECT StudentId, FullName, Email
FROM dbo.Students
ORDER BY StudentId -- Bắt buộc khi dùng OFFSET/FETCH
OFFSET (@Page - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;

-- Tổng số dòng để tính số trang
SELECT COUNT(*) AS TotalRows
FROM dbo.Students;

-- Các hàm tổng hợp trên dữ liệu đăng ký
SELECT COUNT(*)               AS NumRows,      -- đếm mọi dòng
	   COUNT(Score3)           AS NumScore3,    -- bỏ qua NULL
	   COUNT(DISTINCT StudentId) AS NumStudents,
	   SUM(PaidAmount)         AS TotalPaid,
	   AVG(PaidAmount)         AS AvgPaid,
	   MIN(EnrolledAt)         AS FirstDate,
	   MAX(EnrolledAt)         AS LastDate
FROM dbo.Enrollments;

-- AVG trên cột int trả về int; ép kiểu để giữ phần thập phân
SELECT AVG(Hours) AS AvgHoursInt,
	   AVG(CAST(Hours AS decimal(10, 2))) AS AvgHoursDec
FROM dbo.Courses;

-- GROUP BY: thống kê số lượt ghi danh và tổng tiền theo trạng thái
SELECT Status,
	   COUNT(*) AS NumEnrollments,
	   SUM(PaidAmount) AS TotalPaid
FROM dbo.Enrollments
GROUP BY Status
ORDER BY TotalPaid DESC;

-- Lỗi Msg 8120: StudentId không nằm trong GROUP BY hoặc hàm tổng hợp
-- SELECT Status, StudentId, COUNT(*)
-- FROM dbo.Enrollments
-- GROUP BY Status;

-- Quy tắc: cột trong SELECT phải nằm trong GROUP BY hoặc hàm tổng hợp.


SELECT City, Count(*) AS NumStudents
From dbo.Students
WHERE City Is Not Null
Group By City
Having Count(*) >=2
Order by NumStudents DESC;

-- Danh sách khóa học của từng học viên trên một dòng
SELECT e.StudentId,
	   STRING_AGG(c.CourseCode, ', ')
		   WITHIN GROUP (ORDER BY e.EnrolledAt) AS Courses
FROM dbo.Enrollments AS e
JOIN dbo.Courses AS c ON c.CourseId = e.CourseId
GROUP BY e.StudentId;


-- Trung vị xấp xỉ (SQL Server 2022+)
SELECT CourseId,
	   APPROX_PERCENTILE_CONT(0.5)
		   WITHIN GROUP (ORDER BY PaidAmount) AS MedianPaid
FROM dbo.Enrollments
GROUP BY CourseId;
