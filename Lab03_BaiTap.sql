/* =====================================================================
   Devmaster Academy – Hệ quản trị CSDL SQL Server 2022
   BUỔI 4 – 30 BÀI LUYỆN TẬP TRUY VẤN 
   Dữ liệu: DevmasterLab (chạy 00_DevmasterLab_Setup.sql trước)
   Phạm vi: SELECT, WHERE, ORDER BY, TOP/OFFSET-FETCH, hàm tổng hợp, GROUP BY/HAVING, ROLLUP, STRING_AGG, JOIN
   ===================================================================== */
USE DevmasterLab;
GO

/* ---------------------------------------------------------------------
   PHẦN A – SELECT CƠ BẢN (bài 1–5)
   --------------------------------------------------------------------- */

-- Bài 1 (★). Liệt kê họ tên và email của mọi học viên, đổi tên cột thành HoTen và Email.
SELECT FullName AS HoTen, 
       Email 
FROM Students;


-- Bài 2 (★). Với mỗi khóa học hiển thị: mã khóa, học phí mỗi giờ và học phí đã cộng VAT 8%.
SELECT CourseId, 
       (Fee / Hours) AS FeePerHour, 
       Fee * 1.08 AS FeeWithVAT 
FROM Courses;


-- Bài 3 (★). Tạo cột Title có dạng 'SQL-DEV – SQL Server cho Developer' và cột FeeMillion là học phí tính theo triệu đồng (1 chữ số thập phân).
SELECT CONCAT(CourseId, ' – ', CourseName) AS Title, 
       ROUND(Fee / 1000000.0, 1) AS FeeMillion 
FROM Courses;


-- Bài 4 (★). Phân loại học phí: dưới 5 triệu 'Thấp', từ 5 đến dưới 10 triệu 'Trung bình', từ 10 triệu trở lên 'Cao'. Hiển thị mã khóa, học phí, nhóm.
SELECT CourseId, 
       Fee, 
       CASE 
           WHEN Fee < 5000000 THEN N'Thấp'
           WHEN Fee >= 5000000 AND Fee < 10000000 THEN N'Trung bình'
           ELSE N'Cao' 
       END AS FeeGroup 
FROM Courses;


-- Bài 5 (★). Liệt kê các thành phố khác nhau của học viên, rồi đếm số thành phố khác nhau. Giải thích vì sao hai kết quả lệch nhau 1.
-- 1. Liệt kê các thành phố:
SELECT DISTINCT City 
FROM Students;

-- 2. Đếm số thành phố khác nhau:
SELECT COUNT(DISTINCT City) AS TotalCities 
FROM Students;

-- Giải thích: Truy vấn 1 (DISTINCT) sẽ hiển thị cả giá trị NULL như một dòng riêng biệt. 
-- Truy vấn 2 (COUNT DISTINCT) sẽ bỏ qua hoàn toàn các giá trị NULL, nên số lượng sẽ ít hơn 1 so với số dòng của truy vấn 1.


/* ---------------------------------------------------------------------
   PHẦN B – LỌC, SẮP XẾP, PHÂN TRANG (bài 6–15)
   --------------------------------------------------------------------- */

-- Bài 6 (★). Các khóa học có học phí từ 5.000.000 đến 8.000.000 (gồm cả hai đầu mút), sắp xếp học phí tăng dần.
SELECT CourseId, CourseName, Fee 
FROM Courses 
WHERE Fee BETWEEN 5000000 AND 8000000 
ORDER BY Fee ASC;


-- Bài 7 (★). Học viên ở Hà Nội, Hải Phòng hoặc Đà Nẵng (dùng IN), hiển thị họ tên và thành phố.
SELECT FullName, City 
FROM Students 
WHERE City IN (N'Hà Nội', N'Hải Phòng', N'Đà Nẵng');


-- Bài 8 (★). Học viên có tên thành phố bắt đầu bằng 'Hà' (Hà Nội, Hà Nam, Hà Tĩnh…).
SELECT FullName, City 
FROM Students 
WHERE City LIKE N'Hà%';


-- Bài 9 (★). Học viên có thành phố nhưng chưa có số điện thoại.
SELECT FullName, City, Phone 
FROM Students 
WHERE City IS NOT NULL AND Phone IS NULL;


-- Bài 10 (★). Khóa học đang mở (IsActive = 1) có thẻ Tags chứa 'sql'.
SELECT CourseId, CourseName, Tags 
FROM Courses 
WHERE IsActive = 1 AND Tags LIKE '%sql%';


-- Bài 11 (★★). Các lượt ghi danh từ 05/10/2026 đến hết 11/10/2026.
SELECT EnrollmentId, StudentId, CourseId, EnrolledAt 
FROM Enrollments 
WHERE EnrolledAt >= '2026-10-05' AND EnrolledAt < '2026-10-12';


-- Bài 12 (★★). Sắp xếp học viên theo ngày sinh giảm dần. Học viên chưa có ngày sinh nằm ở đầu hay cuối? Giải thích.
SELECT FullName, BirthDate 
FROM Students 
ORDER BY BirthDate DESC;
-- Giải thích: Học viên chưa có ngày sinh (NULL) sẽ nằm ở CUỐI danh sách.
-- Vì trong SQL Server, NULL được xem là giá trị nhỏ nhất nên khi sắp xếp giảm dần (DESC), nó sẽ bị đẩy xuống cuối cùng.


-- Bài 13 (★★). Ba khóa học có học phí cao nhất.
SELECT TOP (3) CourseId, CourseName, Fee 
FROM Courses 
ORDER BY Fee DESC;


-- Bài 14 (★★). Lấy TOP (2) WITH TIES các lượt ghi danh có PaidAmount cao nhất. Vì sao kết quả nhiều hơn 2 dòng?
SELECT TOP (2) WITH TIES EnrollmentId, PaidAmount 
FROM Enrollments 
ORDER BY PaidAmount DESC;
-- Giải thích: Mệnh đề WITH TIES sẽ lấy thêm tất cả các dòng có giá trị PaidAmount bằng với giá trị PaidAmount 
-- của dòng cuối cùng lọt vào TOP (dòng thứ 2). Do có nhiều người đóng số tiền bằng nhau, kết quả sẽ vượt quá 2 dòng.


-- Bài 15 (★★). Trang 3 của danh sách lượt ghi danh (sắp theo ngày ghi danh, mã tăng dần), mỗi trang 5 dòng. Dùng biến @Page, @PageSize.
DECLARE @Page INT = 3;
DECLARE @PageSize INT = 5;

SELECT EnrollmentId, StudentId, CourseId, EnrolledAt 
FROM Enrollments 
ORDER BY EnrolledAt ASC, EnrollmentId ASC 
OFFSET (@Page - 1) * @PageSize ROWS 
FETCH NEXT @PageSize ROWS ONLY;


/* ---------------------------------------------------------------------
   PHẦN C – HÀM TỔNG HỢP VÀ NHÓM (bài 16–23)
   --------------------------------------------------------------------- */

-- Bài 16 (★★). Trên Enrollments: tổng số dòng, số lượt đã có Score3, điểm Score3 trung bình, tổng PaidAmount. Giải thích vì sao COUNT(*) khác COUNT(Score3).
SELECT COUNT(*) AS TotalRows, 
       COUNT(Score3) AS CountScore3, 
       AVG(Score3) AS AvgScore3, 
       SUM(PaidAmount) AS TotalPaidAmount 
FROM Enrollments;
-- Giải thích: COUNT(*) đếm toàn bộ số dòng vật lý trong bảng kể cả dòng đó có chứa NULL hay không. 
-- COUNT(Score3) chỉ đếm các dòng mà cột Score3 có dữ liệu (khác NULL). Do có học viên chưa có Score3 nên kết quả lệch nhau.


-- Bài 17 (★★). Trên Courses: học phí thấp nhất, cao nhất, trung bình và thời lượng trung bình (AVG(Hours) dạng nguyên và dạng thập phân).
SELECT MIN(Fee) AS MinFee, 
       MAX(Fee) AS MaxFee, 
       AVG(Fee) AS AvgFee, 
       AVG(Hours) AS AvgHoursInt, 
       AVG(CAST(Hours AS FLOAT)) AS AvgHoursFloat 
FROM Courses;


-- Bài 18 (★★). Với mỗi khóa học (theo CourseId) có ghi danh: số lượt ghi danh và tổng tiền đã thu, sắp xếp tổng tiền giảm dần.
SELECT CourseId, 
       COUNT(EnrollmentId) AS TotalEnrollments, 
       SUM(PaidAmount) AS TotalRevenue 
FROM Enrollments 
GROUP BY CourseId 
ORDER BY TotalRevenue DESC;


-- Bài 19 (★★). Số học viên theo từng thành phố (kể cả học viên chưa có thành phố), sắp xếp giảm dần theo số học viên.
SELECT City, 
       COUNT(StudentId) AS TotalStudents 
FROM Students 
GROUP BY City 
ORDER BY TotalStudents DESC;


-- Bài 20 (★★). Các khóa học có từ 3 lượt ghi danh trở lên, không tính lượt đã hủy (Status = 'Cancelled').
SELECT CourseId, 
       COUNT(EnrollmentId) AS TotalEnrollments 
FROM Enrollments 
WHERE Status <> 'Cancelled' 
GROUP BY CourseId 
HAVING COUNT(EnrollmentId) >= 3;


-- Bài 21 (★★). Tổng tiền đã đóng của từng học viên chỉ tính các lượt Active; chỉ giữ học viên có tổng từ 10.000.000 trở lên.
SELECT StudentId, 
       SUM(PaidAmount) AS TotalPaid 
FROM Enrollments 
WHERE Status = 'Active' 
GROUP BY StudentId 
HAVING SUM(PaidAmount) >= 10000000
ORDER BY TotalPaid DESC;


-- Bài 22 (★★). Mỗi thành phố một dòng: số học viên và danh sách họ tên cách nhau bởi '; ' (sắp theo họ tên). Bỏ học viên chưa có thành phố.
SELECT City, 
       COUNT(StudentId) AS TotalStudents, 
       STRING_AGG(FullName, '; ') WITHIN GROUP (ORDER BY FullName ASC) AS StudentList 
FROM Students 
WHERE City IS NOT NULL 
GROUP BY City;


-- Bài 23 (★★). Tổng số tiền thanh toán (Payments) theo phương thức, có thêm dòng tổng cộng; dòng tổng ghi nhãn 'TỔNG'.
SELECT COALESCE(Method, N'TỔNG') AS Method, 
       SUM(Amount) AS TotalAmount 
FROM Payments 
GROUP BY ROLLUP(Method);


/* ---------------------------------------------------------------------
   PHẦN D – KẾT NỐI BẢNG (bài 24–30)
   --------------------------------------------------------------------- */

-- Bài 24 (★★★). Học viên ở Hà Nội và các khóa họ đã ghi danh: họ tên, mã khóa, ngày ghi danh (INNER JOIN 3 bảng), sắp theo họ tên rồi ngày.
SELECT s.FullName, 
       c.CourseId, 
       c.CourseName,
       e.EnrolledAt 
FROM Students s 
INNER JOIN Enrollments e ON s.StudentId = e.StudentId 
INNER JOIN Courses c ON e.CourseId = c.CourseId 
WHERE s.City = N'Hà Nội' 
ORDER BY s.FullName ASC, e.EnrolledAt ASC;


-- Bài 25 (★★★). Mọi học viên kèm số lượt ghi danh (học viên chưa ghi danh hiện 0).
SELECT s.StudentId, 
       s.FullName, 
       COUNT(e.EnrollmentId) AS TotalEnrollments 
FROM Students s 
LEFT JOIN Enrollments e ON s.StudentId = e.StudentId 
GROUP BY s.StudentId, s.FullName;


-- Bài 26 (★★★). Các khóa học chưa có lượt ghi danh nào (anti-join).
SELECT c.CourseId, 
       c.CourseName 
FROM Courses c 
LEFT JOIN Enrollments e ON c.CourseId = e.CourseId 
WHERE e.EnrollmentId IS NULL;


-- Bài 27 (★★★). Danh sách (không trùng) học viên đã từng thanh toán bằng thẻ (Method = 'Card').
SELECT DISTINCT s.StudentId, 
                s.FullName 
FROM Students s 
INNER JOIN Enrollments e ON s.StudentId = e.StudentId 
INNER JOIN Payments p ON e.EnrollmentId = p.EnrollmentId 
WHERE p.Method = 'Card';


-- Bài 28 (★★★). Các cặp học viên cùng thành phố (mỗi cặp một lần): hai họ tên và thành phố.
SELECT a.FullName AS Student1, 
       b.FullName AS Student2, 
       a.City 
FROM Students a 
INNER JOIN Students b ON a.City = b.City 
                      AND a.StudentId < b.StudentId;


-- Bài 29 (★★★). Tạo khung báo cáo: mọi tổ hợp (danh mục gốc × trạng thái ghi danh Active / Completed / Cancelled). Danh mục gốc là danh mục có ParentId IS NULL.
SELECT c.CategoryId, 
       c.CategoryName, 
       s.StatusName 
FROM Categories c 
CROSS JOIN (VALUES ('Active'), ('Completed'), ('Cancelled')) AS s(StatusName)
WHERE c.ParentId IS NULL;


-- Bài 30 (★★★). Tổng hợp doanh thu (PaidAmount) theo danh mục CHA (nâng cao): danh mục gốc coi là cha của chính nó; sắp xếp giảm dần.
SELECT COALESCE(parent.CategoryName, child.CategoryName) AS ParentCategoryName, 
       SUM(e.PaidAmount) AS TotalRevenue 
FROM Enrollments e 
INNER JOIN Courses c ON e.CourseId = c.CourseId 
INNER JOIN Categories child ON c.CategoryId = child.CategoryId 
LEFT JOIN Categories parent ON child.ParentId = parent.CategoryId 
GROUP BY COALESCE(parent.CategoryId, child.CategoryId), 
         COALESCE(parent.CategoryName, child.CategoryName) 
ORDER BY TotalRevenue DESC;


