use DevmasterLab 
Go

USE DevmasterLab;
GO

/* =========================================================
   MỨC 1 – MỘT BẢNG
   ========================================================= */

-- Câu 1. Khóa học đang mở; sắp xếp học phí giảm dần.
SELECT CourseCode, CourseName, Fee
FROM dbo.Courses
WHERE IsActive = 1
ORDER BY Fee DESC, CourseName;

-- Câu 2. Học viên ở Hà Nội hoặc Bắc Ninh, có số điện thoại.
SELECT FullName, City, Phone
FROM dbo.Students
WHERE City IN (N'Hà Nội', N'Bắc Ninh')
  AND Phone IS NOT NULL;

-- Câu 3. Họ Nguyễn, Trần hoặc Lê.
SELECT StudentId, FullName
FROM dbo.Students
WHERE FullName LIKE N'Nguyễn%'
   OR FullName LIKE N'Trần%'
   OR FullName LIKE N'Lê%';

-- Câu 4. Ghi danh trong tháng 10/2026.
SELECT EnrollmentId, StudentId, CourseId, EnrolledAt, Status
FROM dbo.Enrollments
WHERE EnrolledAt >= '20261001'
  AND EnrolledAt <  '20261101';

-- Câu 5. Khóa học có thời lượng dài nhất, kèm học phí mỗi giờ.
SELECT CourseCode,
       CourseName,
       Hours,
       Fee,
       CAST(Fee * 1.0 / Hours AS decimal(12, 2)) AS FeePerHour
FROM dbo.Courses
WHERE Hours = (SELECT MAX(Hours) FROM dbo.Courses);

-- Câu 6. Trang 2, mỗi trang 4 học viên; sắp xếp theo họ tên.
SELECT StudentId, FullName, Email, City
FROM dbo.Students
ORDER BY FullName, StudentId
OFFSET 4 ROWS FETCH NEXT 4 ROWS ONLY;

-- Câu 7. Phân loại Score3 và đếm số lượt ghi danh theo loại.
;WITH ScoredEnrollments AS
(
    SELECT CASE
               WHEN Score3 IS NULL THEN N'Chưa thi'
               WHEN Score3 >= 8.5 THEN N'Giỏi'
               WHEN Score3 >= 7.0 THEN N'Khá'
               WHEN Score3 >= 5.0 THEN N'Trung bình'
               ELSE N'Chưa đạt'
           END AS Score3Type
    FROM dbo.Enrollments
)
SELECT Score3Type, COUNT(*) AS EnrollmentCount
FROM ScoredEnrollments
GROUP BY Score3Type
ORDER BY CASE Score3Type
             WHEN N'Chưa thi' THEN 1
             WHEN N'Giỏi' THEN 2
             WHEN N'Khá' THEN 3
             WHEN N'Trung bình' THEN 4
             ELSE 5
         END;


/* =========================================================
   MỨC 2 – TỔNG HỢP
   ========================================================= */

-- Câu 8. Số lượt ghi danh, tổng tiền đã thu và tiền trung bình theo trạng thái.
SELECT Status,
       COUNT(*) AS EnrollmentCount,
       SUM(PaidAmount) AS TotalCollected,
       AVG(CAST(PaidAmount AS decimal(12, 2))) AS AverageCollected
FROM dbo.Enrollments
GROUP BY Status
ORDER BY Status;

-- Câu 9. Thành phố có từ 2 học viên trở lên; bỏ qua thành phố NULL/rỗng.
SELECT City, COUNT(*) AS StudentCount
FROM dbo.Students
WHERE City IS NOT NULL
  AND City <> N''
GROUP BY City
HAVING COUNT(*) >= 2
ORDER BY StudentCount DESC, City;


/* =========================================================
   MỨC 3 – KẾT NỐI BẢNG
   ========================================================= */

-- Câu 10. Danh sách ghi danh: học viên, khóa học, danh mục và số tiền đã đóng.
SELECT s.FullName,
       c.CourseCode,
       c.CourseName,
       cat.CategoryName,
       e.PaidAmount,
       e.EnrolledAt
FROM dbo.Enrollments AS e
JOIN dbo.Students AS s
    ON s.StudentId = e.StudentId
JOIN dbo.Courses AS c
    ON c.CourseId = e.CourseId
JOIN dbo.Categories AS cat
    ON cat.CategoryId = c.CategoryId
ORDER BY e.EnrolledAt, s.FullName;

-- Câu 11. Doanh thu từng khóa học, kể cả khóa chưa có ghi danh.
SELECT c.CourseCode,
       c.CourseName,
       COALESCE(SUM(e.PaidAmount), 0) AS TotalRevenue
FROM dbo.Courses AS c
LEFT JOIN dbo.Enrollments AS e
    ON e.CourseId = c.CourseId
GROUP BY c.CourseId, c.CourseCode, c.CourseName
ORDER BY TotalRevenue DESC, c.CourseName;

-- Câu 12. Học viên chưa ghi danh khóa học nào.
SELECT s.StudentId, s.FullName, s.Email
FROM dbo.Students AS s
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Enrollments AS e
    WHERE e.StudentId = s.StudentId
)
ORDER BY s.FullName;

-- Câu 13. Danh mục cha, danh mục con và số khóa học của từng danh mục con.
SELECT parent.CategoryName AS ParentCategory,
       child.CategoryName AS ChildCategory,
       COUNT(c.CourseId) AS CourseCount
FROM dbo.Categories AS child
JOIN dbo.Categories AS parent
    ON parent.CategoryId = child.ParentId
LEFT JOIN dbo.Courses AS c
    ON c.CategoryId = child.CategoryId
GROUP BY parent.CategoryName, child.CategoryName
ORDER BY parent.CategoryName, child.CategoryName;

-- Câu 14. Công nợ từng lượt ghi danh chưa hủy, chỉ lấy lượt còn nợ.
SELECT e.EnrollmentId,
       s.FullName,
       c.CourseCode,
       c.CourseName,
       c.Fee,
       e.PaidAmount,
       c.Fee - e.PaidAmount AS AmountOwed
FROM dbo.Enrollments AS e
JOIN dbo.Students AS s
    ON s.StudentId = e.StudentId
JOIN dbo.Courses AS c
    ON c.CourseId = e.CourseId
WHERE e.Status <> 'Cancelled'
  AND c.Fee - e.PaidAmount > 0
ORDER BY AmountOwed DESC, s.FullName;

-- Câu 15. Học viên có tổng tiền đã đóng từ 10 triệu trở lên.
-- Danh sách mã khóa học được xếp theo thời điểm ghi danh.
SELECT s.StudentId,
       s.FullName,
       COUNT(*) AS EnrollmentCount,
       SUM(e.PaidAmount) AS TotalPaid,
       STRING_AGG(
           CONVERT(nvarchar(max), c.CourseCode), N', '
       ) WITHIN GROUP (ORDER BY e.EnrolledAt, e.EnrollmentId) AS CourseCodes
FROM dbo.Students AS s
JOIN dbo.Enrollments AS e
    ON e.StudentId = s.StudentId
JOIN dbo.Courses AS c
    ON c.CourseId = e.CourseId
GROUP BY s.StudentId, s.FullName
HAVING SUM(e.PaidAmount) >= 10000000
ORDER BY TotalPaid DESC, s.FullName;


/* =========================================================
   BÀI TẬP VỀ NHÀ BUỔI 3
   ========================================================= */

-- BT1. Doanh thu theo tháng thanh toán và phương thức thanh toán.
SELECT DATEFROMPARTS(YEAR(PaidAt), MONTH(PaidAt), 1) AS PaymentMonth,
       Method,
       SUM(Amount) AS Revenue
FROM dbo.Payments
GROUP BY DATEFROMPARTS(YEAR(PaidAt), MONTH(PaidAt), 1), Method
ORDER BY PaymentMonth, Method;

-- BT2. Số học viên theo năm sinh; nhóm riêng ngày sinh chưa cập nhật.
SELECT CASE
           WHEN BirthDate IS NULL THEN N'Chưa cập nhật'
           ELSE CONVERT(nvarchar(4), YEAR(BirthDate))
       END AS BirthYear,
       COUNT(*) AS StudentCount
FROM dbo.Students
GROUP BY CASE
             WHEN BirthDate IS NULL THEN N'Chưa cập nhật'
             ELSE CONVERT(nvarchar(4), YEAR(BirthDate))
         END
ORDER BY BirthYear;

-- BT3. Học viên học từ 2 khóa trở lên, kèm danh sách tên khóa.
SELECT s.StudentId,
       s.FullName,
       COUNT(DISTINCT e.CourseId) AS CourseCount,
       STRING_AGG(
           CONVERT(nvarchar(max), courseList.CourseName), N', '
       ) WITHIN GROUP (ORDER BY courseList.CourseName) AS CourseNames
FROM dbo.Students AS s
JOIN dbo.Enrollments AS e
    ON e.StudentId = s.StudentId
JOIN
(
    SELECT DISTINCT e2.StudentId, c2.CourseId, c2.CourseName
    FROM dbo.Enrollments AS e2
    JOIN dbo.Courses AS c2
        ON c2.CourseId = e2.CourseId
) AS courseList
    ON courseList.StudentId = s.StudentId
GROUP BY s.StudentId, s.FullName
HAVING COUNT(DISTINCT e.CourseId) >= 2
ORDER BY s.FullName;

-- BT4. Doanh thu theo danh mục cha – danh mục con, có tổng phụ và tổng cộng.
;WITH CourseRevenue AS
(
    SELECT CASE
               WHEN child.ParentId IS NULL THEN child.CategoryName
               ELSE parent.CategoryName
           END AS ParentCategory,
           CASE
               WHEN child.ParentId IS NULL THEN NULL
               ELSE child.CategoryName
           END AS ChildCategory,
           COALESCE(SUM(e.PaidAmount), 0) AS Revenue
    FROM dbo.Categories AS child
    LEFT JOIN dbo.Categories AS parent
        ON parent.CategoryId = child.ParentId
    LEFT JOIN dbo.Courses AS c
        ON c.CategoryId = child.CategoryId
    LEFT JOIN dbo.Enrollments AS e
        ON e.CourseId = c.CourseId
    GROUP BY CASE
                 WHEN child.ParentId IS NULL THEN child.CategoryName
                 ELSE parent.CategoryName
             END,
             CASE
                 WHEN child.ParentId IS NULL THEN NULL
                 ELSE child.CategoryName
             END
)
SELECT CASE
           WHEN GROUPING(ParentCategory) = 1 THEN N'TỔNG CỘNG'
           ELSE ParentCategory
       END AS ParentCategory,
       CASE
           WHEN GROUPING(ParentCategory) = 1 THEN NULL
           WHEN GROUPING(ChildCategory) = 1 THEN N'Tổng danh mục cha'
           WHEN ChildCategory IS NULL THEN N'(Khóa học gán trực tiếp)'
           ELSE ChildCategory
       END AS ChildCategory,
       SUM(Revenue) AS Revenue
FROM CourseRevenue
GROUP BY ROLLUP(ParentCategory, ChildCategory)
ORDER BY GROUPING(ParentCategory),
         ParentCategory,
         GROUPING(ChildCategory),
         ChildCategory;

-- BT5. Tìm khóa học theo mã, tên hoặc tags; phân trang và trả tổng số trang.
DECLARE @kw nvarchar(100) = N'sql';
DECLARE @Page int = 1;
DECLARE @PageSize int = 5;

-- Kết quả trang được yêu cầu.
SELECT CourseId, CourseCode, CourseName, Tags, Fee, IsActive
FROM dbo.Courses
WHERE CourseCode LIKE '%' + CONVERT(varchar(100), @kw) + '%'
   OR CourseName LIKE N'%' + @kw + N'%'
   OR Tags LIKE N'%' + @kw + N'%'
ORDER BY CourseName, CourseId
OFFSET (@Page - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;

-- Tổng số kết quả phù hợp và tổng số trang.
SELECT COUNT(*) AS TotalCourses,
       (COUNT(*) + @PageSize - 1) / @PageSize AS TotalPages
FROM dbo.Courses
WHERE CourseCode LIKE '%' + CONVERT(varchar(100), @kw) + '%'
   OR CourseName LIKE N'%' + @kw + N'%'
   OR Tags LIKE N'%' + @kw + N'%';