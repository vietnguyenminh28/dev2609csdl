/* =====================================================================
   Devmaster Academy – Hệ quản trị CSDL SQL Server 2022
   BUỔI 5 – 21 BÀI LUYỆN TẬP LAB 5 (dành cho học viên)
   Chuẩn bị: chạy 00_DevmasterLab_Setup.sql để có dữ liệu gốc (không chạy file Demo/Lab 5 trước đó)
   Phạm vi: thủ tục lưu trữ, giao dịch, TRY…CATCH, THROW/RAISERROR, trigger, SQL động, temporal table
   Quy ước: thủ tục dbo.usp_<Động từ><Đối tượng> · trigger dbo.trg_<Bảng>_<Mục đích>
   ===================================================================== */
USE DevmasterLab;
GO

/* Cách làm: mỗi bài một khối '-- Bài n' dưới đề; tự viết rồi chạy, kèm lệnh gọi thử.
   Mức độ: ★ cơ bản (bài 1–6) · ★★ khá (bài 7–17) · ★★★ nâng cao (bài 18–21).
   Nhiều bài thay đổi dữ liệu: làm đúng phần 'dọn dữ liệu' / ROLLBACK ghi trong đề để các bài sau không bị lệch.
   Nên làm lần lượt; bài 17 dùng trigger của bài 16. */

/* ---------------------------------------------------------------------
   PHẦN A – THỦ TỤC LƯU TRỮ CƠ BẢN (bài 1–6)
   --------------------------------------------------------------------- */
-- Bài 1 (★). Viết dbo.usp_GetEnrollmentsByStudent (@StudentId int): trả các lượt ghi danh của học viên gồm EnrollmentId, CourseCode, EnrolledAt, PaidAmount, Status (sắp theo ngày ghi danh). RETURN 1 nếu học viên không tồn tại, 0 nếu thành công. Gọi thử với 1, 9 và 999 và in mã trả về.
--   Gợi ý: Kiểm tra IF NOT EXISTS trước; EXEC @rc = dbo.usp_… ; SET NOCOUNT ON.
--   Kết quả mong đợi: Học viên 1: 3 dòng, rc = 0 · học viên 9: 0 dòng, rc = 0 (tồn tại nhưng chưa ghi danh) · học viên 999: rc = 1.
CREATE OR ALTER PROCEDURE dbo.usp_GetEnrollmentsByStudent
    @StudentId int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Students
        WHERE StudentId = @StudentId
    )
        RETURN 1;

    SELECT
        e.EnrollmentId,
        c.CourseCode,
        e.EnrolledAt,
        e.PaidAmount,
        e.Status
    FROM dbo.Enrollments AS e
    INNER JOIN dbo.Courses AS c
        ON c.CourseId = e.CourseId
    WHERE e.StudentId = @StudentId
    ORDER BY e.EnrolledAt, e.EnrollmentId;

    RETURN 0;
END;
GO

DECLARE @rc int;

EXEC @rc = dbo.usp_GetEnrollmentsByStudent @StudentId = 1;
PRINT CONCAT('StudentId=1, rc=', @rc);

EXEC @rc = dbo.usp_GetEnrollmentsByStudent @StudentId = 9;
PRINT CONCAT('StudentId=9, rc=', @rc);

EXEC @rc = dbo.usp_GetEnrollmentsByStudent @StudentId = 999;
PRINT CONCAT('StudentId=999, rc=', @rc);
GO

-- Bài 2 (★). Viết dbo.usp_GetCoursesByCategory (@CategoryId int = NULL, @IncludeChildren bit = 1): trả khóa học (CourseCode, CourseName, Fee) của danh mục; nếu @IncludeChildren = 1 thì gồm cả danh mục con, cháu (CTE đệ quy). @CategoryId = NULL trả mọi khóa. Gọi thử: không tham số; (1, 1); (1, 0); (2).
--   Gợi ý: CTE đệ quy trong thủ tục; điều kiện đệ quy có thể dùng biến @IncludeChildren.
--   Kết quả mong đợi: Không tham số: 8 dòng · (1,1): 4 dòng (NET-FS, REACT, JAVA-WEB, GIT) · (1,0): 2 dòng (JAVA-WEB, GIT) · (2): 3 dòng (SQL-DEV, PY-DA, PBI).


-- Bài 3 (★). Viết dbo.usp_GetCourseStats (@CourseCode varchar(20), @NumEnrollments int OUTPUT, @Revenue decimal(14,0) OUTPUT): đếm lượt ghi danh chưa hủy và tổng PaidAmount của chúng. RETURN 1 nếu mã khóa không tồn tại (hai tham số OUTPUT = NULL). Gọi thử NET-FS, SQL-DEV, XXX và in kết quả.
--   Gợi ý: Tham số OUTPUT; gán NULL ngay đầu thủ tục; chú ý từ khóa OUTPUT cả ở lúc gọi.
--   Kết quả mong đợi: NET-FS: 4 lượt · 45.000.000 · SQL-DEV: 4 lượt · 24.000.000 (lượt hủy bị loại) · XXX: rc = 1, hai giá trị NULL.


-- Bài 4 (★). Viết dbo.usp_RegisterStudent (@FullName nvarchar(100), @Email varchar(150), @City nvarchar(50) = NULL, @StudentId int OUTPUT): RETURN 1 nếu Email không có dạng hợp lệ (LIKE '%_@_%'), 2 nếu Email đã tồn tại, 0 nếu thêm thành công (trả mã mới bằng SCOPE_IDENTITY). Gọi thử ba trường hợp rồi dọn dữ liệu thử.
--   Gợi ý: Kiểm tra trước khi INSERT để trả mã lỗi dễ hiểu; SCOPE_IDENTITY thay vì @@IDENTITY.
--   Kết quả mong đợi: Thêm mới: rc = 0, @StudentId = 13 · Email 'abc': rc = 1 · Email trùng an.nv@devmaster.vn: rc = 2. Dọn: DELETE học viên 13 và RESEED về 12.


-- Bài 5 (★). Viết MỘT khối lệnh (không cần thủ tục) dùng biến, WHILE và PRINT để in danh sách khóa học theo thứ tự CourseId dạng '1. NET-FS: 18000000' và cuối cùng in tổng học phí.
--   Gợi ý: @i, @n; mỗi vòng lấy dòng thứ @i bằng ROW_NUMBER; CONCAT để ghép chuỗi khi PRINT.
--   Kết quả mong đợi: 8 dòng: 1. NET-FS: 18000000 · 2. SQL-DEV: 6000000 · 3. REACT: 8000000 · 4. AI-APP: 9000000 · 5. PY-DA: 7500000 · 6. PBI: 5000000 · 7. JAVA-WEB: 17000000 · 8. GIT: 2500000; rồi 'Tổng học phí: 73000000'.


-- Bài 6 (★). Viết dbo.usp_TopStudentsByPaid (@TopN int = 3, @CourseCode varchar(20) = NULL): trả @TopN học viên có tổng PaidAmount cao nhất (tùy chọn chỉ tính một khóa); hòa thì xếp theo StudentId. Gọi thử: mặc định; (2, 'SQL-DEV').
--   Gợi ý: TOP (@TopN) cần dấu ngoặc; điều kiện tùy chọn: @CourseCode IS NULL OR c.CourseCode = @CourseCode.
--   Kết quả mong đợi: Mặc định: Lê Minh Châu 26.000.000 · Nguyễn Văn An 19.500.000 · Hoàng Thu Hà 15.000.000 · (2, 'SQL-DEV'): Nguyễn Văn An 6.000.000 · Trần Thị Bình 6.000.000.



/* ---------------------------------------------------------------------
   PHẦN B – GIAO DỊCH VÀ XỬ LÝ LỖI (bài 7–12)
   --------------------------------------------------------------------- */
-- Bài 7 (★★). Viết dbo.usp_RegisterAndPay (@StudentId int, @CourseId int, @Paid decimal(12,0), @EnrollmentId int OUTPUT): trong MỘT giao dịch thêm lượt ghi danh (PaidAmount = @Paid) và, nếu @Paid > 0, thêm dòng Payments tương ứng. THROW 50010 nếu khóa không tồn tại hoặc ngừng tuyển sinh; THROW 50011 nếu @Paid < 0 hoặc > học phí. Gọi thử (9, 3, 3.000.000) và (9, 3, 9.000.000); đếm số dòng Enrollments/Payments trước và sau; dọn dữ liệu.
--   Gợi ý: SET XACT_ABORT ON; TRY…CATCH: IF @@TRANCOUNT > 0 ROLLBACK; THROW; kiểm tra điều kiện TRƯỚC khi mở giao dịch.
--   Kết quả mong đợi: Lần 1 thành công: @EnrollmentId = 21, Enrollments 20 → 21, Payments 21 → 22. Lần 2: Msg 50011, số dòng không đổi. Dọn: DELETE ghi danh 21 (Payments xóa theo CASCADE) và RESEED Enrollments = 20, Payments = 21.


-- Bài 8 (★★). Viết dbo.usp_RefundPayment (@PaymentId int): xóa dòng thanh toán và trừ số tiền đó khỏi Enrollments.PaidAmount. THROW 50012 nếu thanh toán không tồn tại; THROW 50013 nếu lượt ghi danh đã Completed. Thủ tục phải chạy được cả khi được gọi trong một giao dịch có sẵn (chỉ tự COMMIT/ROLLBACK khi chính nó mở giao dịch). Kiểm thử thanh toán 21 (trong BEGIN TRAN … ROLLBACK), 2 và 999.
--   Gợi ý: Mẫu 'sở hữu giao dịch': DECLARE @own bit = IIF(@@TRANCOUNT = 0, 1, 0); chỉ BEGIN/COMMIT/ROLLBACK khi @own = 1.
--   Kết quả mong đợi: Thanh toán 21 (4.500.000, ghi danh 20): PaidAmount 4.500.000 → 0 và Payments của ghi danh 20 còn 0 dòng; ROLLBACK trả lại. Thanh toán 2: Msg 50013. Thanh toán 999: Msg 50012.


-- Bài 9 (★★). Dùng PRINT @@TRANCOUNT để chứng minh: (a) BEGIN TRAN hai lần rồi COMMIT một lần thì @@TRANCOUNT còn 1; (b) một lệnh ROLLBACK hủy TẤT CẢ các mức. Với (b), sửa Fee khóa GIT ở cả hai mức rồi chứng minh học phí trở về 2.500.000 sau ROLLBACK, kể cả khi mức trong đã 'COMMIT'.
--   Gợi ý: COMMIT ở mức trong chỉ giảm @@TRANCOUNT, chưa ghi bền; ROLLBACK luôn về 0.
--   Kết quả mong đợi: (a) 0 → 1 → 2 → 1 → ROLLBACK → 0. (b) Fee GIT sau ROLLBACK = 2.500.000.


-- Bài 10 (★★). Viết MỘT khối lệnh gồm 5 cặp BEGIN TRY…CATCH, mỗi cặp cố ý gây một lỗi khác nhau và in ERROR_NUMBER() – ERROR_MESSAGE(): (a) chia cho 0; (b) ghi danh học viên 999; (c) thêm học viên trùng Email; (d) CAST('abc' AS int); (e) UPDATE Fee = -1. Điền bảng số lỗi.
--   Gợi ý: Mỗi cặp TRY…CATCH độc lập; ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE() cũng dùng được.
--   Kết quả mong đợi: (a) 8134 · (b) 547 (khóa ngoại) · (c) 2627 (UNIQUE) · (d) 245 (chuyển kiểu) · (e) 547 (CHECK).


-- Bài 11 (★★). So sánh RAISERROR và THROW bằng bốn thí nghiệm: (a) RAISERROR mức 10 trong TRY có nhảy vào CATCH không? (b) RAISERROR mức 16 → ERROR_NUMBER() là gì? (c) THROW 50100 → ERROR_NUMBER()? (d) TRY lồng nhau: CATCH trong dùng THROW; (không tham số) thì CATCH ngoài nhận mã lỗi nào?
--   Gợi ý: RAISERROR mức ≤ 10 chỉ là thông báo; THROW; (không tham số) ném lại lỗi gốc, giữ nguyên số lỗi.
--   Kết quả mong đợi: (a) Không vào CATCH, chương trình chạy tiếp · (b) 50000 · (c) 50100 · (d) 8134 (lỗi gốc chia cho 0).


-- Bài 12 (★★). Dùng SAVE TRANSACTION: trong một giao dịch, sửa Fee của GIT thành 3.000.000, đặt điểm lưu sp_after_git, sửa Fee của PBI thành 5.500.000, rồi ROLLBACK TRANSACTION sp_after_git. Cho biết học phí GIT và PBI lúc đó, và @@TRANCOUNT. Cuối cùng ROLLBACK toàn bộ để giữ dữ liệu gốc.
--   Gợi ý: ROLLBACK TRANSACTION <tên điểm lưu> chỉ hoàn tác phần sau điểm lưu và KHÔNG đóng giao dịch.
--   Kết quả mong đợi: Sau rollback điểm lưu: GIT = 3.000.000, PBI = 5.000.000, @@TRANCOUNT = 1. Sau ROLLBACK toàn bộ: GIT = 2.500.000.



/* ---------------------------------------------------------------------
   PHẦN C – TRIGGER (bài 13–17)
   --------------------------------------------------------------------- */
-- Bài 13 (★★). Tạo bảng dbo.PaymentAudit (AuditId, PaymentId, EnrollmentId, Amount, Action char(1), ChangedAt mặc định SYSDATETIME(), ChangedBy mặc định SUSER_SNAME()) và trigger dbo.trg_Payments_Audit AFTER INSERT, DELETE ghi 'I' hoặc 'D'. Phải đúng khi thao tác nhiều dòng. Kiểm thử trong giao dịch: INSERT 2 thanh toán cùng lúc cho ghi danh 20 rồi DELETE chúng; xem PaymentAudit; ROLLBACK.
--   Gợi ý: inserted / deleted là bảng, không phải một dòng; UNION ALL hai nhánh; chạy trên CSDL chưa tạo trigger đồng bộ PaidAmount.
--   Kết quả mong đợi: Sau INSERT: 2 dòng 'I'; sau DELETE: thêm 2 dòng 'D' (tổng 4). Sau ROLLBACK: PaymentAudit trống. Lưu ý: IDENTITY không được hoàn lại → RESEED Payments = 21.


-- Bài 14 (★★). Tạo trigger INSTEAD OF DELETE dbo.trg_Students_Protect trên Students: nếu BẤT KỲ học viên nào trong lệnh xóa đã có ghi danh thì THROW 50020 và không xóa dòng nào; ngược lại thực hiện xóa. Kiểm thử trong giao dịch: xóa (9, 12) → thành công; xóa (9, 1) → lỗi, số học viên vẫn 12.
--   Gợi ý: INSTEAD OF: tự viết lệnh DELETE thật từ bảng deleted; kiểm tra tập hợp bằng EXISTS, không dùng biến đơn.
--   Kết quả mong đợi: DELETE (9,12): còn 10 học viên (rồi ROLLBACK). DELETE (9,1): Msg 50020, vẫn 12 học viên.


-- Bài 15 (★★). Tạo bảng dbo.EnrollmentStatusLog (LogId, EnrollmentId, OldStatus, NewStatus, ChangedAt) và trigger dbo.trg_Enrollments_StatusLog AFTER UPDATE chỉ ghi khi Status THỰC SỰ đổi (dùng UPDATE(Status) và so sánh inserted với deleted). Kiểm thử trong giao dịch: đổi Status của ghi danh 1 và 3 sang 'Completed'; sửa PaidAmount; gán Status = Status. Đếm dòng log.
--   Gợi ý: IF NOT UPDATE(Status) RETURN; JOIN inserted/deleted theo khóa chính; điều kiện i.Status <> d.Status.
--   Kết quả mong đợi: Chỉ 2 dòng log (1 và 3: Active → Completed). Sửa PaidAmount hoặc gán Status = Status không thêm dòng nào. ROLLBACK trả lại dữ liệu và log.


-- Bài 16 (★★). Tạo trigger dbo.trg_Courses_LimitFeeDrop AFTER UPDATE trên Courses: không cho GIẢM học phí quá 30% trong một lệnh (Fee mới < 70% Fee cũ → ROLLBACK và THROW 50030). Phải đúng với UPDATE nhiều dòng. Thử: GIT 2.500.000 → 1.000.000 (lỗi); GIT → 2.000.000 (được, rồi trả về 2.500.000); UPDATE Fee = Fee * 0.5 cho danh mục 4 và 5 (lỗi, không dòng nào đổi).
--   Gợi ý: Dùng EXISTS trên inserted JOIN deleted; trong trigger, ROLLBACK TRANSACTION rồi THROW.
--   Kết quả mong đợi: 1.000.000: Msg 50030, Fee vẫn 2.500.000 · 2.000.000: thành công · cả hai khóa danh mục 4, 5 giữ nguyên học phí.


-- Bài 17 (★★). Liệt kê các trigger trong CSDL (tên, bảng, có phải INSTEAD OF không, đang bị tắt không) bằng sys.triggers. Sau đó DISABLE trigger dbo.trg_Courses_LimitFeeDrop, giảm học phí GIT xuống 1.000.000 (thành công), ENABLE lại và trả học phí về 2.500.000. Dùng OBJECTPROPERTY để kiểm tra trạng thái.
--   Gợi ý: sys.triggers, OBJECT_NAME(parent_id), is_disabled; DISABLE TRIGGER … ON …; ENABLE TRIGGER … ON ….
--   Kết quả mong đợi: Danh sách có 4 trigger của bài 13–16 (nếu chạy trên CSDL sạch) · khi tắt: UPDATE thành công · khi bật lại: ExecIsTriggerDisabled = 0.



/* ---------------------------------------------------------------------
   PHẦN D – SQL ĐỘNG VÀ AN TOÀN (bài 18–19)
   --------------------------------------------------------------------- */
-- Bài 18 (★★★). Viết dbo.usp_FindCourses (@Keyword nvarchar(100) = NULL, @MinFee decimal(12,0) = NULL, @MaxFee decimal(12,0) = NULL, @SortBy sysname = N'CourseCode', @Desc bit = 0) bằng SQL động: lọc tùy chọn theo từ khóa (CourseName hoặc Tags), khoảng học phí; @SortBy chỉ nhận CourseCode, Fee, Hours (ngược lại THROW 50050); dùng sp_executesql có tham số và QUOTENAME. Thử: @Keyword = N'sql'; học phí 7–9 triệu sắp theo Fee giảm dần; @SortBy = N'Fee; DROP TABLE dbo.Payments'.
--   Gợi ý: Danh sách trắng cho cột sắp xếp; giá trị đi qua tham số, KHÔNG nối vào chuỗi.
--   Kết quả mong đợi: 'sql': 6 dòng (AI-APP, JAVA-WEB, NET-FS, PBI, PY-DA, SQL-DEV) · 7–9 triệu, Fee DESC: AI-APP 9.000.000, REACT 8.000.000, PY-DA 7.500.000 · chuỗi tấn công: Msg 50050, bảng Payments còn nguyên.


-- Bài 19 (★★★). Minh họa SQL injection: tạo dbo.usp_FindCourseUnsafe (@Code varchar(100)) nối chuỗi trực tiếp rồi EXEC (@s), và dbo.usp_FindCourseSafe cùng chức năng nhưng dùng sp_executesql có tham số. Gọi cả hai với 'GIT' và với chuỗi N'x'' OR 1 = 1 --'. Sau đó, trong giao dịch, chứng minh chuỗi N'x''; UPDATE dbo.Courses SET Tags = NULL; --' làm mất dữ liệu ở bản không an toàn (rồi ROLLBACK).
--   Gợi ý: Dấu nháy trong chuỗi tấn công đóng chuỗi sớm; chú thích -- cắt phần còn lại của câu lệnh.
--   Kết quả mong đợi: 'GIT': 1 dòng cho cả hai · chuỗi OR 1 = 1: Unsafe 8 dòng, Safe 0 dòng · UPDATE tiêm vào: COUNT(Tags) 8 → 0 rồi ROLLBACK → 8.



/* ---------------------------------------------------------------------
   PHẦN E – KIỂM TOÁN VÀ BÁO CÁO (bài 20–21)
   --------------------------------------------------------------------- */
-- Bài 20 (★★★). Tạo bảng temporal dbo.PriceBook (PriceId, CourseCode, Price) có SYSTEM_VERSIONING (bảng lịch sử dbo.PriceBookHistory). Thêm 3 dòng (NET-FS 18.000.000, SQL-DEV 6.000.000, GIT 2.500.000), ghi lại thời điểm @t1, rồi sửa giá SQL-DEV hai lần (6.500.000, 7.000.000). Viết 4 truy vấn: (a) toàn bộ lịch sử (FOR SYSTEM_TIME ALL); (b) bảng giá tại @t1 (AS OF); (c) lịch sử riêng của SQL-DEV; (d) các phiên bản đã hết hạn trong bảng lịch sử. Dọn dẹp bằng cách tắt versioning rồi DROP cả hai bảng.
--   Gợi ý: Cột ValidFrom/ValidTo khai báo HIDDEN; WAITFOR DELAY '00:00:01' để các mốc thời gian khác nhau; tắt SYSTEM_VERSIONING trước khi DROP.
--   Kết quả mong đợi: (a) 5 dòng · (b) 3 dòng, SQL-DEV = 6.000.000 · (c) 3 dòng: 6.000.000 → 6.500.000 → 7.000.000 · (d) 2 dòng (hai phiên bản cũ của SQL-DEV).


-- Bài 21 (★★★). Viết dbo.usp_RevenueReport (@FromDate date, @ToDate date) trả HAI tập kết quả cho khoảng ngày (gồm cả hai đầu): (1) theo phương thức thanh toán: Method, NumPayments, Total (giảm dần); (2) 3 học viên đóng nhiều nhất: FullName, Total. THROW 50040 nếu @FromDate > @ToDate. Gọi thử ('2026-10-01', '2026-10-31') và ('2026-10-31', '2026-10-01').
--   Gợi ý: Cận trên dùng PaidAt < DATEADD(day, 1, @ToDate); SET NOCOUNT ON; hai SELECT liên tiếp.
--   Kết quả mong đợi: Tập 1: Transfer 6 lần · 36.500.000; Card 5 lần · 23.750.000; Cash 1 lần · 2.500.000. Tập 2: Bùi Gia Khánh 12.500.000; Đỗ Ngọc Lan 9.000.000; Lê Minh Châu 8.000.000. Gọi ngược ngày: Msg 50040.


-- Bài 2 (★)
CREATE OR ALTER PROCEDURE dbo.usp_GetCoursesByCategory
    @CategoryId int = NULL,
    @IncludeChildren bit = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @CategoryId IS NULL
    BEGIN
        SELECT CourseCode, CourseName, Fee
        FROM dbo.Courses
        ORDER BY CourseId;
        RETURN;
    END

    ;WITH CategoryTree AS
    (
        SELECT CategoryId
        FROM dbo.Categories
        WHERE CategoryId = @CategoryId

        UNION ALL

        SELECT c.CategoryId
        FROM dbo.Categories c
        INNER JOIN CategoryTree ct ON c.ParentId = ct.CategoryId
        WHERE @IncludeChildren = 1
    )
    SELECT DISTINCT c.CourseCode, c.CourseName, c.Fee
    FROM dbo.Courses c
    INNER JOIN CategoryTree ct ON c.CategoryId = ct.CategoryId
    ORDER BY c.CourseCode;
END;
GO

-- Gọi thử Bài 2
EXEC dbo.usp_GetCoursesByCategory;
EXEC dbo.usp_GetCoursesByCategory @CategoryId = 1, @IncludeChildren = 1;
EXEC dbo.usp_GetCoursesByCategory @CategoryId = 1, @IncludeChildren = 0;
EXEC dbo.usp_GetCoursesByCategory @CategoryId = 2;
GO

-- Bài 3 (★)
CREATE OR ALTER PROCEDURE dbo.usp_GetCourseStats
    @CourseCode varchar(20),
    @NumEnrollments int OUTPUT,
    @Revenue decimal(14,0) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @NumEnrollments = NULL;
    SET @Revenue = NULL;

    IF NOT EXISTS (SELECT 1 FROM dbo.Courses WHERE CourseCode = @CourseCode)
        RETURN 1;

    SELECT 
        @NumEnrollments = COUNT(e.EnrollmentId),
        @Revenue = ISNULL(SUM(e.PaidAmount), 0)
    FROM dbo.Courses c
    LEFT JOIN dbo.Enrollments e ON c.CourseId = e.CourseId AND e.Status <> 'Cancelled'
    WHERE c.CourseCode = @CourseCode;

    RETURN 0;
END;
GO

-- Gọi thử Bài 3
DECLARE @rc int, @num int, @rev decimal(14,0);

EXEC @rc = dbo.usp_GetCourseStats @CourseCode = 'NET-FS', @NumEnrollments = @num OUTPUT, @Revenue = @rev OUTPUT;
PRINT CONCAT('NET-FS: rc=', @rc, ', Num=', @num, ', Rev=', @rev);

EXEC @rc = dbo.usp_GetCourseStats @CourseCode = 'SQL-DEV', @NumEnrollments = @num OUTPUT, @Revenue = @rev OUTPUT;
PRINT CONCAT('SQL-DEV: rc=', @rc, ', Num=', @num, ', Rev=', @rev);

EXEC @rc = dbo.usp_GetCourseStats @CourseCode = 'XXX', @NumEnrollments = @num OUTPUT, @Revenue = @rev OUTPUT;
PRINT CONCAT('XXX: rc=', @rc, ', Num=', ISNULL(CAST(@num AS varchar), 'NULL'), ', Rev=', ISNULL(CAST(@rev AS varchar), 'NULL'));
GO

-- Bài 4 (★)
CREATE OR ALTER PROCEDURE dbo.usp_RegisterStudent
    @FullName nvarchar(100),
    @Email varchar(150),
    @City nvarchar(50) = NULL,
    @StudentId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @StudentId = NULL;

    IF @Email NOT LIKE '%_@_%'
        RETURN 1;

    IF EXISTS (SELECT 1 FROM dbo.Students WHERE Email = @Email)
        RETURN 2;

    INSERT INTO dbo.Students (FullName, Email, City)
    VALUES (@FullName, @Email, @City);

    SET @StudentId = SCOPE_IDENTITY();
    RETURN 0;
END;
GO

-- Gọi thử Bài 4
DECLARE @rc int, @sid int;

EXEC @rc = dbo.usp_RegisterStudent @FullName = N'Trần Văn Test', @Email = 'test.student@devmaster.vn', @City = N'Hà Nội', @StudentId = @sid OUTPUT;
PRINT CONCAT('Thêm mới: rc=', @rc, ', StudentId=', @sid);

EXEC @rc = dbo.usp_RegisterStudent @FullName = N'Lỗi Email', @Email = 'abc', @StudentId = @sid OUTPUT;
PRINT CONCAT('Email sai: rc=', @rc);

EXEC @rc = dbo.usp_RegisterStudent @FullName = N'Trùng Email', @Email = 'an.nv@devmaster.vn', @StudentId = @sid OUTPUT;
PRINT CONCAT('Email trùng: rc=', @rc);

-- Dọn dữ liệu Bài 4
DELETE FROM dbo.Students WHERE StudentId = 13;
DBCC CHECKIDENT ('dbo.Students', RESEED, 12);
GO

-- Bài 5 (★)
DECLARE @i int = 1, @n int, @total decimal(14,0) = 0;
DECLARE @code varchar(20), @fee decimal(12,0);

SELECT @n = COUNT(*) FROM dbo.Courses;

WHILE @i <= @n
BEGIN
    WITH OrderedCourses AS (
        SELECT CourseCode, Fee, ROW_NUMBER() OVER (ORDER BY CourseId) AS RowNum
        FROM dbo.Courses
    )
    SELECT @code = CourseCode, @fee = Fee
    FROM OrderedCourses
    WHERE RowNum = @i;

    PRINT CONCAT(@i, '. ', @code, ': ', @fee);
    SET @total = @total + @fee;
    SET @i = @i + 1;
END

PRINT CONCAT('Tổng học phí: ', @total);
GO

-- Bài 6 (★)
CREATE OR ALTER PROCEDURE dbo.usp_TopStudentsByPaid
    @TopN int = 3,
    @CourseCode varchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@TopN)
        s.StudentId,
        s.FullName,
        SUM(e.PaidAmount) AS TotalPaid
    FROM dbo.Students s
    INNER JOIN dbo.Enrollments e ON s.StudentId = e.StudentId
    INNER JOIN dbo.Courses c ON e.CourseId = c.CourseId
    WHERE (@CourseCode IS NULL OR c.CourseCode = @CourseCode)
    GROUP BY s.StudentId, s.FullName
    ORDER BY TotalPaid DESC, s.StudentId ASC;
END;
GO

-- Gọi thử Bài 6
EXEC dbo.usp_TopStudentsByPaid;
EXEC dbo.usp_TopStudentsByPaid @TopN = 2, @CourseCode = 'SQL-DEV';
GO

-- Bài 7 (★★)
CREATE OR ALTER PROCEDURE dbo.usp_RegisterAndPay
    @StudentId int,
    @CourseId int,
    @Paid decimal(12,0),
    @EnrollmentId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Fee decimal(12,0), @IsActive bit;
    SELECT @Fee = Fee, @IsActive = IsActive FROM dbo.Courses WHERE CourseId = @CourseId;

    IF @Fee IS NULL OR @IsActive = 0
        THROW 50010, N'Khóa học không tồn tại hoặc đã ngừng tuyển sinh.', 1;

    IF @Paid < 0 OR @Paid > @Fee
        THROW 50011, N'Số tiền thanh toán không hợp lệ.', 1;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO dbo.Enrollments (StudentId, CourseId, EnrolledAt, PaidAmount, Status)
        VALUES (@StudentId, @CourseId, SYSDATETIME(), @Paid, 'Active');

        SET @EnrollmentId = SCOPE_IDENTITY();

        IF @Paid > 0
        BEGIN
            INSERT INTO dbo.Payments (EnrollmentId, Amount, PaidAt, Method)
            VALUES (@EnrollmentId, @Paid, SYSDATETIME(), 'Transfer');
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- Kiểm thử Bài 7
DECLARE @eid int;
EXEC dbo.usp_RegisterAndPay @StudentId = 9, @CourseId = 3, @Paid = 3000000, @EnrollmentId = @eid OUTPUT;
PRINT CONCAT('Thành công EnrollmentId = ', @eid);

BEGIN TRY
    EXEC dbo.usp_RegisterAndPay @StudentId = 9, @CourseId = 3, @Paid = 9000000, @EnrollmentId = @eid OUTPUT;
END TRY
BEGIN CATCH
    PRINT CONCAT('Lỗi expected: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE());
END CATCH

-- Dọn dữ liệu Bài 7
DELETE FROM dbo.Enrollments WHERE EnrollmentId = 21;
DBCC CHECKIDENT ('dbo.Enrollments', RESEED, 20);
DBCC CHECKIDENT ('dbo.Payments', RESEED, 21);
GO

-- Bài 8 (★★)
CREATE OR ALTER PROCEDURE dbo.usp_RefundPayment
    @PaymentId int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EnrollmentId int, @Amount decimal(12,0), @Status varchar(20);
    SELECT 
        @EnrollmentId = p.EnrollmentId,
        @Amount = p.Amount,
        @Status = e.Status
    FROM dbo.Payments p
    INNER JOIN dbo.Enrollments e ON p.EnrollmentId = e.EnrollmentId
    WHERE p.PaymentId = @PaymentId;

    IF @EnrollmentId IS NULL
        THROW 50012, N'Thanh toán không tồn tại.', 1;

    IF @Status = 'Completed'
        THROW 50013, N'Không thể hoàn tiền cho lượt ghi danh đã hoàn thành.', 1;

    DECLARE @own bit = IIF(@@TRANCOUNT = 0, 1, 0);

    BEGIN TRY
        IF @own = 1 BEGIN TRAN;

        DELETE FROM dbo.Payments WHERE PaymentId = @PaymentId;

        UPDATE dbo.Enrollments
        SET PaidAmount = PaidAmount - @Amount
        WHERE EnrollmentId = @EnrollmentId;

        IF @own = 1 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @own = 1 AND @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- Kiểm thử Bài 8
BEGIN TRAN;
EXEC dbo.usp_RefundPayment @PaymentId = 21;
ROLLBACK TRAN;

BEGIN TRY EXEC dbo.usp_RefundPayment @PaymentId = 2; END TRY
BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;

BEGIN TRY EXEC dbo.usp_RefundPayment @PaymentId = 999; END TRY
BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- Bài 9 (★★)
-- Thí nghiệm (a)
PRINT CONCAT('Ban dau: ', @@TRANCOUNT);
BEGIN TRAN;
PRINT CONCAT('Sau BEGIN 1: ', @@TRANCOUNT);
BEGIN TRAN;
PRINT CONCAT('Sau BEGIN 2: ', @@TRANCOUNT);
COMMIT TRAN;
PRINT CONCAT('Sau COMMIT 1: ', @@TRANCOUNT);
ROLLBACK TRAN;
PRINT CONCAT('Sau ROLLBACK: ', @@TRANCOUNT);

-- Thí nghiệm (b)
BEGIN TRAN;
UPDATE dbo.Courses SET Fee = 3000000 WHERE CourseCode = 'GIT';
BEGIN TRAN;
UPDATE dbo.Courses SET Fee = 4000000 WHERE CourseCode = 'GIT';
COMMIT TRAN; -- Mức trong COMMIT
ROLLBACK TRAN; -- Mức ngoài ROLLBACK

SELECT CourseCode, Fee FROM dbo.Courses WHERE CourseCode = 'GIT';
GO

-- Bài 10 (★★)
-- (a)
BEGIN TRY SELECT 1/0; END TRY
BEGIN CATCH PRINT CONCAT('(a) Error: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE()); END CATCH

-- (b)
BEGIN TRY INSERT INTO dbo.Enrollments (StudentId, CourseId) VALUES (999, 1); END TRY
BEGIN CATCH PRINT CONCAT('(b) Error: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE()); END CATCH

-- (c)
BEGIN TRY INSERT INTO dbo.Students (FullName, Email) VALUES (N'An', 'an.nv@devmaster.vn'); END TRY
BEGIN CATCH PRINT CONCAT('(c) Error: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE()); END CATCH

-- (d)
BEGIN TRY SELECT CAST('abc' AS int); END TRY
BEGIN CATCH PRINT CONCAT('(d) Error: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE()); END CATCH

-- (e)
BEGIN TRY UPDATE dbo.Courses SET Fee = -1 WHERE CourseId = 1; END TRY
BEGIN CATCH PRINT CONCAT('(e) Error: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE()); END CATCH
GO

-- Bài 11 (★★)
-- (a) RAISERROR Severity <= 10
BEGIN TRY
    RAISERROR('Thong bao severity 10', 10, 1);
    PRINT 'Chay tiep qua CATCH';
END TRY
BEGIN CATCH
    PRINT 'Vao CATCH';
END CATCH

-- (b) RAISERROR Severity 16
BEGIN TRY
    RAISERROR('Loi severity 16', 16, 1);
END TRY
BEGIN CATCH
    PRINT CONCAT('RAISERROR Error Code: ', ERROR_NUMBER());
END CATCH

-- (c) THROW
BEGIN TRY
    THROW 50100, 'Loi THROW custom', 1;
END TRY
BEGIN CATCH
    PRINT CONCAT('THROW Error Code: ', ERROR_NUMBER());
END CATCH

-- (d) TRY lồng nhau
BEGIN TRY
    BEGIN TRY
        SELECT 1/0;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END TRY
BEGIN CATCH
    PRINT CONCAT('Catch ngoai nhan Error Code: ', ERROR_NUMBER());
END CATCH
GO

-- Bài 12 (★★)
BEGIN TRAN;
UPDATE dbo.Courses SET Fee = 3000000 WHERE CourseCode = 'GIT';
SAVE TRANSACTION sp_after_git;

UPDATE dbo.Courses SET Fee = 5500000 WHERE CourseCode = 'PBI';

ROLLBACK TRANSACTION sp_after_git;

SELECT CourseCode, Fee FROM dbo.Courses WHERE CourseCode IN ('GIT', 'PBI');
PRINT CONCAT('@@TRANCOUNT sau rollback savepoint: ', @@TRANCOUNT);

ROLLBACK TRAN;

SELECT CourseCode, Fee FROM dbo.Courses WHERE CourseCode = 'GIT';
GO

-- Bài 13 (★★)
IF OBJECT_ID('dbo.PaymentAudit', 'U') IS NOT NULL DROP TABLE dbo.PaymentAudit;
CREATE TABLE dbo.PaymentAudit (
    AuditId int IDENTITY(1,1) PRIMARY KEY,
    PaymentId int,
    EnrollmentId int,
    Amount decimal(12,0),
    Action char(1),
    ChangedAt datetime2 DEFAULT SYSDATETIME(),
    ChangedBy nvarchar(128) DEFAULT SUSER_SNAME()
);
GO

CREATE OR ALTER TRIGGER dbo.trg_Payments_Audit
ON dbo.Payments
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.PaymentAudit (PaymentId, EnrollmentId, Amount, Action)
    SELECT PaymentId, EnrollmentId, Amount, 'I' FROM inserted
    UNION ALL
    SELECT PaymentId, EnrollmentId, Amount, 'D' FROM deleted;
END;
GO

-- Kiểm thử Bài 13
BEGIN TRAN;
INSERT INTO dbo.Payments (EnrollmentId, Amount, PaidAt, Method) VALUES (20, 100000, SYSDATETIME(), 'Cash'), (20, 200000, SYSDATETIME(), 'Cash');
DELETE FROM dbo.Payments WHERE EnrollmentId = 20 AND Method = 'Cash';
SELECT * FROM dbo.PaymentAudit;
ROLLBACK TRAN;

DBCC CHECKIDENT ('dbo.Payments', RESEED, 21);
GO

-- Bài 14 (★★)
CREATE OR ALTER TRIGGER dbo.trg_Students_Protect
ON dbo.Students
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM deleted d
        INNER JOIN dbo.Enrollments e ON d.StudentId = e.StudentId
    )
    BEGIN
        THROW 50020, N'Không thể xóa học viên đã có lượt ghi danh.', 1;
    END

    DELETE FROM dbo.Students
    WHERE StudentId IN (SELECT StudentId FROM deleted);
END;
GO

-- Kiểm thử Bài 14
BEGIN TRAN;
DELETE FROM dbo.Students WHERE StudentId IN (9, 12);
SELECT COUNT(*) AS StudentCount FROM dbo.Students;
ROLLBACK TRAN;

BEGIN TRY
    DELETE FROM dbo.Students WHERE StudentId IN (9, 1);
END TRY
BEGIN CATCH
    PRINT CONCAT('Loi expected: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE());
END CATCH;
GO

-- Bài 15 (★★)
IF OBJECT_ID('dbo.EnrollmentStatusLog', 'U') IS NOT NULL DROP TABLE dbo.EnrollmentStatusLog;
CREATE TABLE dbo.EnrollmentStatusLog (
    LogId int IDENTITY(1,1) PRIMARY KEY,
    EnrollmentId int,
    OldStatus varchar(20),
    NewStatus varchar(20),
    ChangedAt datetime2 DEFAULT SYSDATETIME()
);
GO

CREATE OR ALTER TRIGGER dbo.trg_Enrollments_StatusLog
ON dbo.Enrollments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(Status) RETURN;

    INSERT INTO dbo.EnrollmentStatusLog (EnrollmentId, OldStatus, NewStatus)
    SELECT i.EnrollmentId, d.Status, i.Status
    FROM inserted i
    INNER JOIN deleted d ON i.EnrollmentId = d.EnrollmentId
    WHERE i.Status <> d.Status;
END;
GO

-- Kiểm thử Bài 15
BEGIN TRAN;
UPDATE dbo.Enrollments SET Status = 'Completed' WHERE EnrollmentId IN (1, 3);
UPDATE dbo.Enrollments SET PaidAmount = PaidAmount + 1000 WHERE EnrollmentId = 1;
UPDATE dbo.Enrollments SET Status = Status WHERE EnrollmentId = 1;
SELECT * FROM dbo.EnrollmentStatusLog;
ROLLBACK TRAN;
GO

-- Bài 16 (★★)
CREATE OR ALTER TRIGGER dbo.trg_Courses_LimitFeeDrop
ON dbo.Courses
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d ON i.CourseId = d.CourseId
        WHERE i.Fee < d.Fee * 0.7
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50030, N'Không được phép giảm học phí quá 30%.', 1;
    END
END;
GO

-- Kiểm thử Bài 16
BEGIN TRY UPDATE dbo.Courses SET Fee = 1000000 WHERE CourseCode = 'GIT'; END TRY
BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;

UPDATE dbo.Courses SET Fee = 2000000 WHERE CourseCode = 'GIT';
UPDATE dbo.Courses SET Fee = 2500000 WHERE CourseCode = 'GIT';

BEGIN TRY UPDATE dbo.Courses SET Fee = Fee * 0.5 WHERE CategoryId IN (4, 5); END TRY
BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- Bài 17 (★★)
SELECT 
    name AS TriggerName,
    OBJECT_NAME(parent_id) AS TableName,
    is_instead_of_trigger AS IsInsteadOf,
    is_disabled AS IsDisabled
FROM sys.triggers
WHERE parent_class = 1;

DISABLE TRIGGER dbo.trg_Courses_LimitFeeDrop ON dbo.Courses;
UPDATE dbo.Courses SET Fee = 1000000 WHERE CourseCode = 'GIT';

ENABLE TRIGGER dbo.trg_Courses_LimitFeeDrop ON dbo.Courses;
UPDATE dbo.Courses SET Fee = 2500000 WHERE CourseCode = 'GIT';

SELECT OBJECTPROPERTY(OBJECT_ID('dbo.trg_Courses_LimitFeeDrop'), 'ExecIsTriggerDisabled') AS IsDisabled;
GO

-- Bài 18 (★★★)
CREATE OR ALTER PROCEDURE dbo.usp_FindCourses
    @Keyword nvarchar(100) = NULL,
    @MinFee decimal(12,0) = NULL,
    @MaxFee decimal(12,0) = NULL,
    @SortBy sysname = N'CourseCode',
    @Desc bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @SortBy NOT IN (N'CourseCode', N'Fee', N'Hours')
        THROW 50050, N'Cột sắp xếp không hợp lệ.', 1;

    DECLARE @sql nvarchar(MAX) = N'
    SELECT CourseCode, CourseName, Fee, Hours, Tags
    FROM dbo.Courses
    WHERE 1=1';

    IF @Keyword IS NOT NULL
        SET @sql += N' AND (CourseName LIKE @Kw OR Tags LIKE @Kw)';

    IF @MinFee IS NOT NULL
        SET @sql += N' AND Fee >= @Min';

    IF @MaxFee IS NOT NULL
        SET @sql += N' AND Fee <= @Max';

    SET @sql += N' ORDER BY ' + QUOTENAME(@SortBy) + IIF(@Desc = 1, N' DESC', N' ASC');

    DECLARE @paramDefs nvarchar(500) = N'
        @Kw nvarchar(102),
        @Min decimal(12,0),
        @Max decimal(12,0)';

    DECLARE @KwParam nvarchar(102) = N'%' + @Keyword + N'%';

    EXEC sp_executesql @sql, @paramDefs, 
        @Kw = @KwParam, 
        @Min = @MinFee, 
        @Max = @MaxFee;
END;
GO

-- Gọi thử Bài 18
EXEC dbo.usp_FindCourses @Keyword = N'sql';
EXEC dbo.usp_FindCourses @MinFee = 7000000, @MaxFee = 9000000, @SortBy = N'Fee', @Desc = 1;

BEGIN TRY
    EXEC dbo.usp_FindCourses @SortBy = N'Fee; DROP TABLE dbo.Payments';
END TRY
BEGIN CATCH
    PRINT CONCAT('Lỗi an toàn: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE());
END CATCH;
GO

-- Bài 19 (★★★)
CREATE OR ALTER PROCEDURE dbo.usp_FindCourseUnsafe
    @Code varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql varchar(MAX) = 'SELECT * FROM dbo.Courses WHERE CourseCode = ''' + @Code + '''';
    EXEC (@sql);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_FindCourseSafe
    @Code varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql nvarchar(MAX) = N'SELECT * FROM dbo.Courses WHERE CourseCode = @c';
    EXEC sp_executesql @sql, N'@c varchar(100)', @c = @Code;
END;
GO

-- Gọi thử Bài 19
EXEC dbo.usp_FindCourseUnsafe @Code = 'GIT';
EXEC dbo.usp_FindCourseSafe @Code = 'GIT';

EXEC dbo.usp_FindCourseUnsafe @Code = 'x'' OR 1 = 1 --';
EXEC dbo.usp_FindCourseSafe @Code = 'x'' OR 1 = 1 --';

-- Thử nghiệm Injection gây mất dữ liệu
BEGIN TRAN;
EXEC dbo.usp_FindCourseUnsafe @Code = 'x''; UPDATE dbo.Courses SET Tags = NULL; --';
SELECT COUNT(Tags) AS ValidTagsCount FROM dbo.Courses;
ROLLBACK TRAN;

SELECT COUNT(Tags) AS ValidTagsCountAfterRollback FROM dbo.Courses;
GO

-- Bài 20 (★★★)
-- Dọn dẹp trước khi tạo (chú ý kiểm tra bật versioning trước khi DROP)
-- Dọn dẹp an toàn trước khi tạo
IF OBJECT_ID('dbo.PriceBook', 'U') IS NOT NULL
BEGIN
    IF OBJECTPROPERTY(OBJECT_ID('dbo.PriceBook'), 'TableTemporalType') = 2
    BEGIN
        ALTER TABLE dbo.PriceBook SET (SYSTEM_VERSIONING = OFF);
    END;
    DROP TABLE dbo.PriceBook;
END;

IF OBJECT_ID('dbo.PriceBookHistory', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.PriceBookHistory;
END;
GO

-- Tạo bảng Temporal
CREATE TABLE dbo.PriceBook (
    PriceId int IDENTITY(1,1) PRIMARY KEY,
    CourseCode varchar(20) NOT NULL,
    Price decimal(12,0) NOT NULL,
    ValidFrom datetime2 GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    ValidTo datetime2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.PriceBookHistory));
GO

-- Chèn dữ liệu ban đầu
INSERT INTO dbo.PriceBook (CourseCode, Price) 
VALUES ('NET-FS', 18000000), ('SQL-DEV', 6000000), ('GIT', 2500000);

WAITFOR DELAY '00:00:01';
DECLARE @t1 datetime2 = SYSDATETIME();
WAITFOR DELAY '00:00:01';

-- Cập nhật giá để phát sinh history
UPDATE dbo.PriceBook SET Price = 6500000 WHERE CourseCode = 'SQL-DEV';
WAITFOR DELAY '00:00:01';

UPDATE dbo.PriceBook SET Price = 7000000 WHERE CourseCode = 'SQL-DEV';

-- (a) Toàn bộ lịch sử
SELECT PriceId, CourseCode, Price, ValidFrom, ValidTo 
FROM dbo.PriceBook FOR SYSTEM_TIME ALL;

-- (b) Bảng giá tại thời điểm @t1
SELECT PriceId, CourseCode, Price 
FROM dbo.PriceBook FOR SYSTEM_TIME AS OF @t1;

-- (c) Lịch sử riêng của SQL-DEV
SELECT CourseCode, Price, ValidFrom, ValidTo 
FROM dbo.PriceBook FOR SYSTEM_TIME ALL 
WHERE CourseCode = 'SQL-DEV';

-- (d) Các phiên bản đã hết hạn trong bảng lịch sử
IF OBJECT_ID('dbo.PriceBookHistory', 'U') IS NOT NULL
BEGIN
    SELECT * FROM dbo.PriceBookHistory;
END;

-- Dọn dẹp sau khi kết thúc Bài 20
IF OBJECT_ID('dbo.PriceBook', 'U') IS NOT NULL
BEGIN
    IF OBJECTPROPERTY(OBJECT_ID('dbo.PriceBook'), 'TableTemporalType') = 2
    BEGIN
        ALTER TABLE dbo.PriceBook SET (SYSTEM_VERSIONING = OFF);
    END;
    DROP TABLE dbo.PriceBook;
END;

IF OBJECT_ID('dbo.PriceBookHistory', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.PriceBookHistory;
END;
GO

-- Bài 21 (★★★)
CREATE OR ALTER PROCEDURE dbo.usp_RevenueReport
    @FromDate date,
    @ToDate date
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate > @ToDate
        THROW 50040, N'Từ ngày phải nhỏ hơn hoặc bằng Đến ngày.', 1;

    DECLARE @UpperLimit datetime2 = DATEADD(day, 1, CAST(@ToDate AS datetime2));

    -- Tập kết quả 1: Báo cáo theo phương thức thanh toán
    SELECT 
        p.Method,
        COUNT(p.PaymentId) AS NumPayments,
        SUM(p.Amount) AS Total
    FROM dbo.Payments p
    WHERE p.PaidAt >= CAST(@FromDate AS datetime2) 
      AND p.PaidAt < @UpperLimit
    GROUP BY p.Method
    ORDER BY Total DESC;

    -- Tập kết quả 2: Top 3 học viên đóng nhiều tiền nhất
    SELECT TOP 3
        s.FullName,
        SUM(p.Amount) AS Total
    FROM dbo.Payments p
    INNER JOIN dbo.Enrollments e ON p.EnrollmentId = e.EnrollmentId
    INNER JOIN dbo.Students s ON e.StudentId = s.StudentId
    WHERE p.PaidAt >= CAST(@FromDate AS datetime2) 
      AND p.PaidAt < @UpperLimit
    GROUP BY s.StudentId, s.FullName
    ORDER BY Total DESC;
END;
GO

-- Gọi thử Bài 21
EXEC dbo.usp_RevenueReport @FromDate = '2026-10-01', @ToDate = '2026-10-31';

BEGIN TRY
    EXEC dbo.usp_RevenueReport @FromDate = '2026-10-31', @ToDate = '2026-10-01';
END TRY
BEGIN CATCH
    PRINT CONCAT('Lỗi expected: ', ERROR_NUMBER(), ' - ', ERROR_MESSAGE());
END CATCH;
GO