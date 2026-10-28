USE DevmasterLab;
GO

/* =====================================================================
   PHẦN A – TRUY VẤN CON VÀ TOÁN TỬ SO SÁNH TẬP (Bài 1–5)
   ===================================================================== */

-- Bài 1 (★). Lượt ghi danh có PaidAmount cao hơn mức PaidAmount trung bình của CHÍNH khóa học đó. 
-- Hiển thị mã lượt, mã khóa, số tiền; sắp xếp theo khóa rồi số tiền giảm dần.
-- Kết quả mong đợi: 11 dòng.
SELECT 
    e.EnrollmentId, 
    e.CourseId, 
    e.PaidAmount
FROM Enrollments e
WHERE e.PaidAmount > (
    SELECT AVG(e2.PaidAmount)
    FROM Enrollments e2
    WHERE e2.CourseId = e.CourseId
)
ORDER BY e.CourseId, e.PaidAmount DESC;
GO

-- Bài 2 (★). Các khóa học KHÔNG có lượt ghi danh nào ở trạng thái Active (kể cả khóa chưa có ai ghi danh).
-- Kết quả mong đợi: 2 dòng.
SELECT 
    c.CourseId, 
    c.CourseName
FROM Courses c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Enrollments e
    WHERE e.CourseId = c.CourseId 
      AND e.Status = 'Active'
);
GO

-- Bài 3 (★). Khóa học có học phí cao hơn MỌI khóa thuộc danh mục 'Phân tích dữ liệu' (CategoryId = 7). 
-- Giải thích kết quả sẽ thay đổi thế nào nếu dùng ANY.
-- Kết quả mong đợi: 4 dòng.
SELECT 
    c.CourseId, 
    c.CourseName, 
    c.Fee
FROM Courses c
WHERE c.Fee > ALL (
    SELECT c2.Fee 
    FROM Courses c2 
    WHERE c2.CategoryId = 7
);
GO
/*
 * Giải thích sự khác nhau giữa ALL và ANY:
 * - Dùng > ALL: Điều kiện thỏa mãn khi Fee lớn hơn mức học phí CAO NHẤT trong danh mục 7.
 * - Nếu thay bằng > ANY: Điều kiện chỉ cần Fee lớn hơn mức học phí THẤP NHẤT trong danh mục 7. 
 *   Kết quả khi dùng > ANY sẽ trả về nhiều dòng hơn (bao gồm các khóa học vượt qua tối thiểu 1 khóa trong danh mục 7).
 */

-- Bài 4 (★). Với mỗi học viên: họ tên, số lượt ghi danh và ngày ghi danh gần nhất. 
-- Dùng truy vấn con vô hướng trong SELECT (không dùng JOIN/GROUP BY).
-- Kết quả mong đợi: 12 dòng.
SELECT 
    s.FullName,
    (
        SELECT COUNT(*) 
        FROM Enrollments e 
        WHERE e.StudentId = s.StudentId
    ) AS NumEnrollments,
    (
        SELECT MAX(e.EnrolledAt) 
        FROM Enrollments e 
        WHERE e.StudentId = s.StudentId
    ) AS LatestEnrollment
FROM Students s;
GO

-- Bài 5 (★). So sánh doanh thu kỳ vọng (học phí × số lượt chưa hủy) với số tiền đã thu của từng khóa có ghi danh; 
-- hiển thị chênh lệch (Gap), sắp xếp giảm dần.
-- Kết quả mong đợi: 6 dòng.
SELECT 
    c.CourseId,
    c.CourseName,
    dt.ExpectedRevenue,
    dt.ActualPaid,
    (dt.ExpectedRevenue - dt.ActualPaid) AS Gap
FROM Courses c
INNER JOIN (
    SELECT 
        e.CourseId,
        SUM(CASE WHEN e.Status <> 'Cancelled' THEN c_sub.Fee ELSE 0 END) AS ExpectedRevenue,
        SUM(e.PaidAmount) AS ActualPaid
    FROM Enrollments e
    INNER JOIN Courses c_sub ON e.CourseId = c_sub.CourseId
    GROUP BY e.CourseId
) dt ON c.CourseId = dt.CourseId
ORDER BY Gap DESC;
GO


/* =====================================================================
   PHẦN B – CTE, ĐỆ QUY, UNION / INTERSECT / EXCEPT (Bài 6–10)
   ===================================================================== */

-- Bài 6 (★★). Dùng hai CTE nối tiếp: CTE đầu tính doanh thu (PaidAmount) từng khóa, 
-- CTE sau tính doanh thu trung bình các khóa. Liệt kê khóa có doanh thu cao hơn mức trung bình.
-- Kết quả mong đợi: 2 dòng.
WITH CourseRevenue AS (
    SELECT 
        e.CourseId,
        SUM(e.PaidAmount) AS TotalRevenue
    FROM Enrollments e
    GROUP BY e.CourseId
),
AvgRevenue AS (
    SELECT 
        AVG(TotalRevenue) AS AvgRev 
    FROM CourseRevenue
)
SELECT 
    cr.CourseId,
    c.CourseName,
    cr.TotalRevenue
FROM CourseRevenue cr
JOIN Courses c ON cr.CourseId = c.CourseId
CROSS JOIN AvgRevenue ar
WHERE cr.TotalRevenue > ar.AvgRev;
GO

-- Bài 7 (★★). CTE đệ quy: với mỗi danh mục GỐC (ParentId IS NULL) tính số khóa học thuộc cả nhánh (chính nó và mọi danh mục con, cháu).
-- Kết quả mong đợi: 3 dòng.
WITH CategoryHierarchy AS (
    -- Neo (Anchor): Các danh mục gốc
    SELECT 
        CategoryId AS RootId, 
        CategoryId
    FROM Categories
    WHERE ParentId IS NULL

    UNION ALL

    -- Phần đệ quy: Nối các danh mục con, cháu vào cùng RootId
    SELECT 
        ch.RootId, 
        c.CategoryId
    FROM Categories c
    INNER JOIN CategoryHierarchy ch ON c.ParentId = ch.CategoryId
)
SELECT 
    cat.CategoryId AS RootCategoryId,
    cat.CategoryName AS RootCategoryName,
    COUNT(crs.CourseId) AS TotalCourses
FROM CategoryHierarchy ch
JOIN Categories cat ON ch.RootId = cat.CategoryId
LEFT JOIN Courses crs ON ch.CategoryId = crs.CategoryId
GROUP BY cat.CategoryId, cat.CategoryName;
GO

-- Bài 8 (★★). Dùng CTE đệ quy sinh 7 ngày từ 19/10/2026 đến 25/10/2026, 
-- rồi LEFT JOIN để đếm số lượt ghi danh mỗi ngày (ngày không có lượt nào hiện 0).
-- Kết quả mong đợi: 7 dòng.
WITH DaysCTE AS (
    -- Neo
    SELECT CAST('2026-10-19' AS DATE) AS EnrollmentDate
    UNION ALL
    -- Đệ quy
    SELECT DATEADD(day, 1, EnrollmentDate)
    FROM DaysCTE
    WHERE EnrollmentDate < '2026-10-25'
)
SELECT 
    d.EnrollmentDate,
    COUNT(e.EnrollmentId) AS NumEnrollments
FROM DaysCTE d
LEFT JOIN Enrollments e ON CAST(e.EnrolledAt AS DATE) = d.EnrollmentDate
GROUP BY d.EnrollmentDate
ORDER BY d.EnrollmentDate;
GO

-- Bài 9 (★★). Học viên đã ghi danh CẢ HAI khóa SQL-DEV (CourseId = 2) và AI-APP (CourseId = 4). Dùng INTERSECT.
-- Kết quả mong đợi: 2 dòng.
SELECT StudentId FROM Enrollments WHERE CourseId = 2
INTERSECT
SELECT StudentId FROM Enrollments WHERE CourseId = 4;
GO

-- Bài 10 (★★). Học viên đã ghi danh NET-FS (CourseId = 1) nhưng CHƯA ghi danh SQL-DEV (CourseId = 2), kèm họ tên.
-- Kết quả mong đợi: 3 dòng.
WITH ExceptStudents AS (
    SELECT StudentId FROM Enrollments WHERE CourseId = 1
    EXCEPT
    SELECT StudentId FROM Enrollments WHERE CourseId = 2
)
SELECT 
    s.StudentId,
    s.FullName
FROM ExceptStudents es
JOIN Students s ON es.StudentId = s.StudentId;
GO


/* =====================================================================
   PHẦN C – HÀM WINDOW (Bài 11–16)
   ===================================================================== */

-- Bài 11 (★★). Lượt ghi danh ĐẦU TIÊN của mỗi học viên: họ tên, mã khóa, ngày ghi danh (ROW_NUMBER + PARTITION BY).
-- Sắp xếp theo ngày ghi danh.
-- Kết quả mong đợi: 10 dòng.
WITH RankedEnrollments AS (
    SELECT 
        e.StudentId,
        e.CourseId,
        e.EnrolledAt,
        ROW_NUMBER() OVER (
            PARTITION BY e.StudentId 
            ORDER BY e.EnrolledAt ASC, e.EnrollmentId ASC
        ) AS rn
    FROM Enrollments e
)
SELECT 
    s.FullName,
    re.CourseId,
    re.EnrolledAt
FROM RankedEnrollments re
JOIN Students s ON re.StudentId = s.StudentId
WHERE re.rn = 1
ORDER BY re.EnrolledAt;
GO

-- Bài 12 (★★). Xếp hạng các lượt ghi danh theo PaidAmount giảm dần TRONG TỪNG khóa học bằng cả RANK và DENSE_RANK; 
-- so sánh hai cột ở khóa NET-FS và SQL-DEV.
-- Kết quả mong đợi: 20 dòng.
SELECT 
    e.EnrollmentId,
    e.CourseId,
    e.PaidAmount,
    RANK() OVER (
        PARTITION BY e.CourseId 
        ORDER BY e.PaidAmount DESC
    ) AS [Rank],
    DENSE_RANK() OVER (
        PARTITION BY e.CourseId 
        ORDER BY e.PaidAmount DESC
    ) AS [DenseRank]
FROM Enrollments e
ORDER BY e.CourseId, e.PaidAmount DESC;
GO

-- Bài 13 (★★). Top-N theo nhóm: tại mỗi thành phố, lấy tối đa 2 học viên có tổng tiền đã đóng cao nhất 
-- (chỉ tính học viên có thành phố và có ghi danh).
-- Kết quả mong đợi: 7 dòng.
WITH StudentPaid AS (
    SELECT 
        s.StudentId,
        s.FullName,
        s.City,
        SUM(e.PaidAmount) AS TotalPaid
    FROM Students s
    INNER JOIN Enrollments e ON s.StudentId = e.StudentId
    WHERE s.City IS NOT NULL
    GROUP BY s.StudentId, s.FullName, s.City
),
RankedByCity AS (
    SELECT 
        StudentId,
        FullName,
        City,
        TotalPaid,
        ROW_NUMBER() OVER (
            PARTITION BY City 
            ORDER BY TotalPaid DESC
        ) AS rn
    FROM StudentPaid
)
SELECT 
    StudentId,
    FullName,
    City,
    TotalPaid
FROM RankedByCity
WHERE rn <= 2
ORDER BY City, TotalPaid DESC;
GO

-- Bài 14 (★★). Lũy kế số tiền thanh toán theo từng phương thức (Payments.Method), sắp theo thời điểm thanh toán; 
-- hiển thị PaymentId, Method, PaidAt, Amount, RunningTotal.
-- Kết quả mong đợi: 21 dòng.
SELECT 
    p.PaymentId,
    p.Method,
    p.PaidAt,
    p.Amount,
    SUM(p.Amount) OVER (
        PARTITION BY p.Method 
        ORDER BY p.PaidAt, p.PaymentId 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Payments p
ORDER BY p.Method, p.PaidAt;
GO

-- Bài 15 (★★). Với những học viên ghi danh từ 2 khóa trở lên: số ngày kể từ lần ghi danh liền trước (LAG + DATEDIFF). 
-- Chỉ giữ các dòng có lần trước; sắp theo học viên rồi ngày ghi danh.
-- Kết quả mong đợi: 10 dòng.
WITH EnrollmentGaps AS (
    SELECT 
        e.StudentId,
        e.EnrollmentId,
        e.EnrolledAt,
        LAG(e.EnrolledAt) OVER (
            PARTITION BY e.StudentId 
            ORDER BY e.EnrolledAt ASC
        ) AS PrevEnrolledAt
    FROM Enrollments e
)
SELECT 
    StudentId,
    EnrollmentId,
    EnrolledAt,
    PrevEnrolledAt,
    DATEDIFF(day, PrevEnrolledAt, EnrolledAt) AS DaysSincePrev
FROM EnrollmentGaps
WHERE PrevEnrolledAt IS NOT NULL
ORDER BY StudentId, EnrolledAt;
GO

-- Bài 16 (★★). Chia 8 khóa học thành 4 nhóm đều nhau theo học phí giảm dần bằng NTILE(4); 
-- hiển thị mã khóa, học phí, nhóm.
-- Kết quả mong đợi: 8 dòng.
SELECT 
    CourseId,
    CourseName,
    Fee,
    NTILE(4) OVER (
        ORDER BY Fee DESC
    ) AS TileGroup
FROM Courses
ORDER BY Fee DESC;
GO

USE DevmasterLab;
GO

/* =====================================================================
   PHẦN C – HÀM WINDOW (Bài 17–18)
   ===================================================================== */

-- Bài 17 (★★★). Với mỗi lượt ghi danh hiển thị đồng thời tổng tiền, tiền trung bình và số lượt của khóa tương ứng. 
-- Viết gọn bằng mệnh đề WINDOW của SQL Server 2022 (đặt tên cửa sổ w một lần).
-- Kết quả mong đợi: 20 dòng.
-- (Lưu ý: Yêu cầu CSDL ở mức tương thích COMPATIBILITY_LEVEL = 160)
SELECT 
    e.EnrollmentId,
    e.CourseId,
    e.PaidAmount,
    SUM(e.PaidAmount) OVER w AS TotalPaidByCourse,
    AVG(e.PaidAmount) OVER w AS AvgPaidByCourse,
    COUNT(*) OVER w AS NumEnrollmentsByCourse
FROM Enrollments e
WINDOW w AS (PARTITION BY e.CourseId);
GO

-- Bài 18 (★★★). Doanh thu thanh toán (Payments.Amount) theo TUẦN từ 07/09/2026 đến 25/10/2026, 
-- kể cả tuần không có thanh toán (hiện 0). Dùng GENERATE_SERIES để sinh danh sách tuần và DATE_BUCKET để gom ngày về đầu tuần.
-- Kết quả mong đợi: 7 dòng.
-- (Lưu ý: GENERATE_SERIES và DATE_BUCKET yêu cầu SQL Server 2022 / COMPATIBILITY_LEVEL = 160)
DECLARE @FromDate DATE = '2026-09-07';
DECLARE @ToDate DATE = '2026-10-25';

WITH WeeksCTE AS (
    SELECT 
        DATEADD(week, s.value, @FromDate) AS WeekStart
    FROM GENERATE_SERIES(0, DATEDIFF(week, @FromDate, @ToDate) - 1) s
)
SELECT 
    w.WeekStart,
    COALESCE(SUM(p.Amount), 0) AS TotalRevenue
FROM WeeksCTE w
LEFT JOIN Payments p 
    ON DATE_BUCKET(week, 1, CAST(p.PaidAt AS DATE), @FromDate) = w.WeekStart
GROUP BY w.WeekStart
ORDER BY w.WeekStart;
GO


/* =====================================================================
   PHẦN D – VIEW, INLINE TVF, INDEXED VIEW (Bài 19–22)
   ===================================================================== */

-- Bài 19 (★★★). Tạo view dbo.vw_CourseRevenue (CourseId, CourseCode, CategoryName, NumEnrollments, Revenue) 
-- gồm cả khóa chưa có ghi danh. Sau đó dùng view để lấy 3 khóa có doanh thu cao nhất.
-- Kết quả mong đợi: 3 dòng.
CREATE OR ALTER VIEW dbo.vw_CourseRevenue
AS
SELECT 
    c.CourseId,
    c.CourseCode,
    cat.CategoryName,
    COUNT(e.EnrollmentId) AS NumEnrollments,
    COALESCE(SUM(e.PaidAmount), 0) AS Revenue
FROM Courses c
LEFT JOIN Categories cat ON c.CategoryId = cat.CategoryId
LEFT JOIN Enrollments e ON c.CourseId = e.CourseId
GROUP BY c.CourseId, c.CourseCode, cat.CategoryName;
GO

-- Truy vấn sử dụng view để lấy Top 3 khóa học có doanh thu cao nhất:
SELECT TOP 3 
    CourseId,
    CourseCode,
    CategoryName,
    NumEnrollments,
    Revenue
FROM dbo.vw_CourseRevenue
ORDER BY Revenue DESC;
GO

-- Bài 20 (★★★). Tạo view dbo.vw_BacNinhStudents (StudentId, FullName, Email, City) 
-- chỉ gồm học viên ở Bắc Ninh, WITH CHECK OPTION.
-- Thử đổi City của học viên 2 sang 'Hà Nội' qua view: ghi lại số lỗi và giải thích. 
-- Chứng minh UPDATE Email qua view vẫn thành công (dùng giao tác và ROLLBACK).
-- Kết quả mong đợi: 2 dòng.
CREATE OR ALTER VIEW dbo.vw_BacNinhStudents
AS
SELECT 
    StudentId, 
    FullName, 
    Email, 
    City
FROM Students
WHERE City = N'Bắc Ninh'
WITH CHECK OPTION;
GO

-- 1. Thử đổi City sang 'Hà Nội' (Thất bại do ràng buộc WITH CHECK OPTION):
/*
UPDATE dbo.vw_BacNinhStudents
SET City = N'Hà Nội'
WHERE StudentId = 2;
-- Lỗi phát sinh: Msg 550, Level 16, State 1
-- Giải thích: Cụm từ WITH CHECK OPTION ngăn chặn các thao tác INSERT/UPDATE dữ liệu làm cho dòng dữ liệu 
-- không còn thỏa mãn điều kiện WHERE của View (ở đây là City = N'Bắc Ninh').
*/

-- 2. Thử UPDATE Email qua View (Thành công vì không vi phạm điều kiện City = N'Bắc Ninh'):
BEGIN TRANSACTION;

UPDATE dbo.vw_BacNinhStudents
SET Email = 'updated_test@gmail.com'
WHERE StudentId = 2;

-- Kiểm tra kết quả trong giao tác:
SELECT * FROM dbo.vw_BacNinhStudents WHERE StudentId = 2;

ROLLBACK TRANSACTION;
GO

-- Bài 21 (★★★). Tạo inline TVF dbo.fn_StudentsByCity(@City nvarchar(50)) 
-- trả về StudentId, FullName, NumEnrollments, TotalPaid của học viên thuộc thành phố đó (học viên chưa ghi danh vẫn có, tổng 0). 
-- Gọi hàm cho 'Hà Nội', sắp xếp theo TotalPaid giảm dần.
-- Kết quả mong đợi: 4 dòng.
CREATE OR ALTER FUNCTION dbo.fn_StudentsByCity(@City NVARCHAR(50))
RETURNS TABLE
AS
RETURN (
    SELECT 
        s.StudentId,
        s.FullName,
        COUNT(e.EnrollmentId) AS NumEnrollments,
        COALESCE(SUM(e.PaidAmount), 0) AS TotalPaid
    FROM Students s
    LEFT JOIN Enrollments e ON s.StudentId = e.StudentId
    WHERE s.City = @City
    GROUP BY s.StudentId, s.FullName
);
GO

-- Gọi hàm lấy danh sách học viên ở 'Hà Nội':
SELECT 
    StudentId,
    FullName,
    NumEnrollments,
    TotalPaid
FROM dbo.fn_StudentsByCity(N'Hà Nội')
ORDER BY TotalPaid DESC;
GO

-- Bài 22 (★★★). Tạo indexed view dbo.vw_CourseStats (WITH SCHEMABINDING) 
-- gồm CourseId, NumEnrollments (COUNT_BIG), TotalPaid từ Enrollments, 
-- rồi tạo UNIQUE CLUSTERED INDEX trên CourseId. 
-- Thử xóa cột PaidAmount của Enrollments và ghi số lỗi. Dọn dẹp sau khi làm.
-- Kết quả mong đợi: 6 dòng.
CREATE OR ALTER VIEW dbo.vw_CourseStats
WITH SCHEMABINDING
AS
SELECT 
    CourseId,
    COUNT_BIG(*) AS NumEnrollments,
    SUM(PaidAmount) AS TotalPaid
FROM dbo.Enrollments
GROUP BY CourseId;
GO

-- Tạo UNIQUE CLUSTERED INDEX trên View:
CREATE UNIQUE CLUSTERED INDEX IX_vw_CourseStats_CourseId 
ON dbo.vw_CourseStats(CourseId);
GO

-- Thử xóa cột PaidAmount (Thất bại do ràng buộc SCHEMABINDING):
/*
ALTER TABLE dbo.Enrollments DROP COLUMN PaidAmount;
-- Lỗi phát sinh: Msg 5074, Level 16, State 1
-- Giải thích: Thuộc tính PaidAmount đang được tham chiếu bởi object 'vw_CourseStats' do view được tạo với tùy chọn SCHEMABINDING.
*/

-- Hiển thị dữ liệu từ Indexed View:
SELECT 
    CourseId, 
    NumEnrollments, 
    TotalPaid 
FROM dbo.vw_CourseStats;
GO

-- Dọn dẹp đối tượng sau khi hoàn thành:
DROP VIEW IF EXISTS dbo.vw_CourseStats;
GO