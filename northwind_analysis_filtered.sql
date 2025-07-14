-- SQL Analysis Project from Northwind Database
-- Author: Luong Thi My Chau
USE Northwind
--A/ Truy vấn tổng quan hoạt động kinh doanh
--1. Tổng doanh thu, lợi nhuận theo năm/quý
SELECT  ROUND(SUM(OD.UnitPrice*OD.Quantity*(1-OD.Discount)),2) AS Tong_doanh_thu, 
ROUND(SUM(OD.Quantity*OD.UnitPrice*(1 - OD.Discount) - OD.Quantity*P.UnitPrice*0.6),2) AS Tong_loi_nhuan,
DATEPART(QUARTER,O.OrderDate) AS QUY, YEAR(O.OrderDate) AS NAM
	FROM [Order Details] OD JOIN Orders O ON OD.OrderID = O.OrderID
	JOIN Products P ON P.ProductID = OD.ProductID
	GROUP BY YEAR(O.OrderDate), DATEPART(QUARTER,O.OrderDate)
	ORDER BY NAM DESC, Tong_doanh_thu DESC 

--2. Doanh thu, lợi nhuận theo quốc gia
SELECT ROUND(SUM(OD.UnitPrice*OD.Quantity*(1-OD.Discount)),2) AS Tong_doanh_thu,
ROUND(SUM(OD.Quantity*OD.UnitPrice*(1 - OD.Discount) - OD.Quantity*P.UnitPrice*0.6),2) AS Tong_loi_nhuan, O.ShipCountry
	FROM [Order Details] OD JOIN Orders O ON OD.OrderID = O.OrderID
	JOIN Products P ON P.ProductID = OD.ProductID
	GROUP BY O.ShipCountry
	ORDER BY Tong_loi_nhuan DESC

--3. Tổng số đơn hàng theo quý, năm
SELECT COUNT(O.OrderID) AS Tong_don_hang, DATEPART(QUARTER,O.OrderDate) AS Quy, YEAR(O.OrderDate) as Nam
	FROM Orders O
	GROUP BY DATEPART(QUARTER,O.OrderDate), YEAR(O.OrderDate)
	ORDER BY NAM DESC, Tong_don_hang DESC

--4. Doanh thu theo phương thức giao hàng
SELECT SUM(OD.UnitPrice*OD.Quantity*(1-OD.Discount)) AS Tong_doanh_thu, S.CompanyName AS Don_vi_van_chuyen
	FROM [Order Details] OD JOIN Orders O
	ON OD.OrderID = O.OrderID
	JOIN  Shippers S
	ON O.ShipVia = S.ShipperID
	GROUP BY S.CompanyName
	ORDER BY Tong_doanh_thu DESC

--B/ Truy vấn theo khách hàng
--1. Top 10 khách hàng có giá trị đơn hàng cao nhất
SELECT TOP 10 C.CustomerID, C.CompanyName, SUM(OD.Quantity*OD.UnitPrice) AS Gia_tri_don_hang
	FROM [Order Details] OD JOIN Orders O ON OD.OrderID = O.OrderID
	JOIN Customers C ON O.CustomerID = C.CustomerID
	GROUP BY C.CustomerID, C.CompanyName
	ORDER BY Gia_tri_don_hang DESC

--2. Khách hàng chưa từng đặt hàng
SELECT C.CustomerID, C.CompanyName
	FROM Customers C LEFT JOIN Orders O
	ON C.CustomerID = O.CustomerID
	WHERE C.CustomerID NOT IN (SELECT CustomerID FROM Orders)

--3. Số lượng đơn hàng theo khách hàng
SELECT C.CustomerID, C.CompanyName, COUNT(O.OrderID) AS So_luong_don_hang
	FROM Customers C JOIN Orders O
	ON C.CustomerID = O.CustomerID
	GROUP BY C.CustomerID, C.CompanyName
	ORDER BY So_luong_don_hang DESC

--4. Doanh thu trung bình của từng khách hàng
SELECT C.CustomerID, C.CompanyName, SUM(OD.UnitPrice*OD.Quantity*(1-OD.Discount))/COUNT(O.OrderID) AS Doanh_thu_trung_binh
	FROM [Order Details] OD JOIN Orders O ON OD.OrderID = O.OrderID
	JOIN Customers C ON O.CustomerID = C.CustomerID
	GROUP BY C.CustomerID, C.CompanyName
	ORDER BY Doanh_thu_trung_binh ASC
	--=> Doanh thu trung bình của tất cả khách hàng = Số tiền trung bình khách hàng chịu chi
SELECT AVG(Doanh_thu_trung_binh) AS DTTB
	FROM (SELECT C.CustomerID, SUM(OD.UnitPrice*OD.Quantity*(1-OD.Discount))/COUNT(O.OrderID) AS Doanh_thu_trung_binh
	FROM [Order Details] OD JOIN Orders O ON OD.OrderID = O.OrderID
	JOIN Customers C ON O.CustomerID = C.CustomerID
	GROUP BY C.CustomerID) AS DOANH_THU_TB_MOI_KH

--C/ Truy vấn theo sản phẩm
--1. Top 10 sản phẩm bán chạy nhất
SELECT TOP 10 P.ProductID, P.ProductName, SUM(OD.Quantity) AS Doanh_so
	FROM Products P JOIN [Order Details] OD
	ON P.ProductID = OD.ProductID
	GROUP BY P.ProductID, P.ProductName
	ORDER BY Doanh_so DESC

--2. Sản phẩm chưa từng được đặt hàng
SELECT P.ProductID, P.ProductName
	FROM Products P LEFT JOIN [Order Details] OD
	ON P.ProductID = OD.ProductID
	WHERE P.ProductID NOT IN 
		(SELECT P.ProductID 
			FROM Products P JOIN [Order Details] OD
			ON P.ProductID = OD.ProductID)

--3. TOP 10 sản phẩm có tỷ suất lợi nhuận cao nhất trong thực tế 
--(Giả sử giá vốn = 60% giá bán niêm yết => tỷ suất lợi nhuận kỳ vọng cho mỗi đơn vị sản phẩm là 40%)
SELECT TOP 10 P.ProductID, P.ProductName, 
	ROUND(SUM((OD.UnitPrice*(1-OD.Discount) - 0.6*P.UnitPrice)*OD.Quantity)/NULLIF(SUM(OD.UnitPrice*(1-OD.Discount)*OD.Quantity),0)*100,2) AS Ty_suat_loi_nhuan
	FROM Products P JOIN [Order Details] OD
	ON P.ProductID = OD.ProductID
	GROUP BY P.ProductID, P.ProductName
	ORDER BY Ty_suat_loi_nhuan DESC

--4. Giá sản phẩm > trung bình ngành
SELECT * FROM
(SELECT P.ProductID, P.ProductName, P.UnitPrice, TBN.CategoryName , TBN.TB_Nganh
	FROM Products P JOIN (
			SELECT P.CategoryID, C.CategoryName ,AVG(P.UnitPrice) AS TB_Nganh
			FROM Products P JOIN Categories C
			ON P.CategoryID = C.CategoryID
			GROUP BY P.CategoryID, C.CategoryName) AS TBN 
	ON P.CategoryID = TBN.CategoryID
	WHERE P.UnitPrice > TBN.TB_Nganh) B1 JOIN (SELECT P.ProductName, SUM(OD.Quantity) AS Doanh_so FROM Products P JOIN [Order Details] OD
ON P.ProductID = OD.ProductID
GROUP BY P.ProductName) B2 
ON B1.ProductName = B2.ProductName
ORDER BY B1.CategoryName ASC, Doanh_so DESC
--D/ Truy vấn theo nhân viên
--1. Nhân viên có doanh số cao nhất mỗi tháng
WITH Doanh_so_hang_thang AS (
	SELECT E.FirstName+' '+E.LastName AS Full_name, ROUND(SUM(OD.UnitPrice*(1-OD.Discount)*OD.Quantity),2) AS Doanh_so,
		MONTH(O.OrderDate) AS Thang, YEAR(O.OrderDate) AS Nam
		 FROM Orders O JOIN Employees E ON O.EmployeeID = E.EmployeeID
		 JOIN [Order Details] OD ON OD.OrderID = O.OrderID
		 GROUP BY E.FirstName, E.LastName, MONTH(O.OrderDate), YEAR(O.OrderDate)),	
	Xep_hang_ban_hang AS(
		SELECT *, RANK() OVER (PARTITION BY Nam, Thang ORDER BY Doanh_so DESC) AS Xep_hang_trong_thang
			FROM Doanh_so_hang_thang)
	SELECT * 
		FROM Xep_hang_ban_hang
		WHERE Xep_hang_trong_thang = 1

--2. Nhân viên chưa từng bán hàng
	SELECT E.EmployeeID, E.FirstName, E.LastName
		FROM Employees E LEFT JOIN Orders O
		ON E.EmployeeID = O.EmployeeID
		WHERE E.EmployeeID NOT IN (SELECT EmployeeID FROM Orders)

--3. Số đơn của mỗi nhân viên theo tháng
	SELECT E.FirstName+' '+E.LastName AS Full_name, MONTH(O.OrderDate) AS Thang, YEAR(O.OrderDate) AS Nam,
			 COUNT(O.OrderID) AS So_don
		 FROM Orders O JOIN Employees E ON O.EmployeeID = E.EmployeeID
		 GROUP BY  MONTH(O.OrderDate), YEAR(O.OrderDate),E.FirstName, E.LastName

--E/ Truy vấn nâng cao & Logic kinh doanh
--1. Đơn hàng giao trễ (ShippedDate>RequiredDate)
SELECT  O.OrderID, O.CustomerID, S.CompanyName AS Don_vi_van_chuyen, O.RequiredDate, O.ShippedDate, 
	DATEDIFF(DAY, O.RequiredDate, O.ShippedDate) AS Thoi_gian_tre
	FROM Orders O JOIN Shippers S
	ON O.ShipVia = S.ShipperID
	WHERE O.ShippedDate > O.RequiredDate

	SELECT COUNT(*) FROM Orders
	--=> Tỷ lệ đơn hàng bị giao trễ theo từng đơn vị vận chuyển
	SELECT A1.CompanyName, A1.So_luong_don_giao_tre, A1.Thoi_gian_giao_tre_trung_binh, A1.So_luong_don_giao_tre*100.00/A2.So_luong_don_hang_da_giao AS Ty_le_giao_tre
	FROM
(SELECT S.CompanyName, COUNT(*) AS So_luong_don_giao_tre,
		AVG(DATEDIFF(DAY, O.RequiredDate, O.ShippedDate)) AS Thoi_gian_giao_tre_trung_binh
	FROM Orders O JOIN Shippers S ON  O.ShipVia = S.ShipperID
	WHERE ShippedDate > RequiredDate
	GROUP BY S.CompanyName) A1 JOIN (SELECT COUNT(O.OrderID) AS So_luong_don_hang_da_giao, S.CompanyName FROM Orders O JOIN Shippers S ON  O.ShipVia = S.ShipperID
GROUP BY S.CompanyName) A2 ON A1.CompanyName=A2.CompanyName
	--=> Thời điểm dễ bị trễ
	SELECT  DATEPART(QUARTER,O.OrderDate) AS Quy, COUNT(O.OrderID) AS So_luong_don_hang_tre,
	STRING_AGG(SPGT.Danh_sach_san_pham, ', ') AS DSSP
	FROM Orders O JOIN 
	(SELECT O.OrderDate AS Ngay_dat_hang , DATEPART(QUARTER,O.OrderDate) AS Thang,
	STRING_AGG(P.ProductName, ', ') AS Danh_sach_san_pham
	FROM Orders O JOIN [Order Details] OD ON OD.OrderID = O.OrderID
	JOIN Products P ON P.ProductID = OD.ProductID
	WHERE ShippedDate > RequiredDate
	GROUP BY  DATEPART(QUARTER,O.OrderDate), O.OrderDate) SPGT ON O.OrderDate = SPGT.Ngay_dat_hang
	WHERE ShippedDate > RequiredDate
	GROUP BY  DATEPART(QUARTER,O.OrderDate)
	ORDER BY Quy
	--Sản phẩm hay bị giao trễ
SELECT P.ProductName, COUNT(*) AS Tan_suat_giao_tre
	FROM Products P JOIN [Order Details] OD ON P.ProductID = OD.ProductID
	JOIN Orders O ON O.OrderID = OD.OrderID
	WHERE O.ShippedDate > O.RequiredDate
	GROUP BY P.ProductName
	ORDER BY Tan_suat_giao_tre DESC
--2. Các dòng sản phẩm có chiết khấu cao
	SELECT O.OrderID, P.ProductName,OD.Quantity, OD.UnitPrice , OD.Discount, ROUND(OD.Quantity*OD.UnitPrice*OD.Discount,2) AS Gia_tri_chiet_khau 
		FROM [Order Details] OD JOIN Orders O
		ON OD.OrderID = O.OrderID
		JOIN Products P ON P. ProductID = OD.ProductID
		WHERE OD.Discount >= 0.2
		ORDER BY Gia_tri_chiet_khau DESC
 --=> Các KH nhận được chiết khấu nhiều nhất
 SELECT C1.CompanyName, C1.CustomerID, C1.Tong_gia_tri_chiet_khau_da_nhan, C2.So_luong_don_hang
 FROM(
	SELECT O.CustomerID, C.CompanyName, ROUND(SUM(OD.Quantity*OD.UnitPrice*OD.Discount),2) AS Tong_gia_tri_chiet_khau_da_nhan
		FROM [Order Details] OD JOIN Orders O
		ON OD.OrderID = O.OrderID
		JOIN Customers C ON C.CustomerID = O.CustomerID
		GROUP BY O.CustomerID, C.CompanyName) C1 JOIN

		(SELECT C.CustomerID, C.CompanyName, COUNT(O.OrderID) AS So_luong_don_hang
	FROM Customers C JOIN Orders O
	ON C.CustomerID = O.CustomerID
	GROUP BY C.CustomerID, C.CompanyName) C2 ON C1.CustomerID = C2.CustomerID

			ORDER BY C1.Tong_gia_tri_chiet_khau_da_nhan DESC

 --=> Chiết khấu theo nhân viên bán hàng ( Có ai dùng chiết khấu để chốt sale quá nhiều?)
	SELECT NVTD.EmployeeID, NVTD.FullName, NVTD.So_don_da_tao, 
			COUNT(O.OrderID) AS So_don_co_ap_chiet_khau,
			FORMAT(COUNT(O.OrderID)*100.0/NVTD.So_don_da_tao,'N2') AS Ty_le_don_ap_chiet_khau,
			ROUND(SUM(OD.Quantity*OD.UnitPrice*OD.Discount),2) AS Tong_gia_tri_chiet_khau
		FROM Orders O JOIN [Order Details] OD ON O.OrderID = OD.OrderID
		JOIN  
		(SELECT E.EmployeeID, E.FirstName +' '+E.LastName AS FullName, COUNT(O.OrderID) AS So_don_da_tao
 FROM Orders O JOIN [Order Details] OD ON O.OrderID = OD.OrderID
 JOIN Employees E ON E.EmployeeID = O.EmployeeID
 GROUP BY  E.EmployeeID, E.FirstName, E.LastName) AS NVTD ON O.EmployeeID = NVTD.EmployeeID
		WHERE OD.Discount > 0
		GROUP BY NVTD.EmployeeID, NVTD.FullName, NVTD.So_don_da_tao
		ORDER BY Ty_le_don_ap_chiet_khau DESC

--3. Tính tống lợi nhuận theo sản phẩm và thời gian (UnitPrice - UnitCost)*Quantity
	SELECT * FROM
	(SELECT P.ProductID, P.ProductName, SUM(OD.Quantity) AS San_luong_da_ban ,
	ROUND(SUM(OD.Quantity*OD.UnitPrice*(1 - OD.Discount) - OD.Quantity*P.UnitPrice*0.6),2) AS Tong_loi_nhuan,
	DATEPART(QUARTER,O.OrderDate) AS Quy, YEAR(O.OrderDate) AS Nam,
	RANK() OVER (PARTITION BY YEAR(O.OrderDate), DATEPART(QUARTER,O.OrderDate) ORDER BY ROUND(SUM(OD.Quantity*OD.UnitPrice*(1 - OD.Discount) - OD.Quantity*P.UnitPrice*0.6),2) DESC) AS Xep_hang_trong_quy
		FROM [Order Details] OD JOIN Products P ON OD.ProductID = P.ProductID
		JOIN Orders O ON O.OrderID = OD.OrderID
		GROUP BY P.ProductID, P.ProductName,YEAR(O.OrderDate), DATEPART(QUARTER,O.OrderDate)) A1
		WHERE A1.Xep_hang_trong_quy IN (1,2,3)


		SELECT * FROM
		(SELECT P.ProductID, P.ProductName, SUM(OD.Quantity) AS San_luong_da_ban ,
	ROUND(SUM(OD.Quantity*OD.UnitPrice*(1 - OD.Discount) - OD.Quantity*P.UnitPrice*0.6),2) AS Tong_loi_nhuan,
	DATEPART(QUARTER,O.OrderDate) AS Quy, YEAR(O.OrderDate) AS Nam,
	RANK() OVER (PARTITION BY YEAR(O.OrderDate), DATEPART(QUARTER,O.OrderDate) ORDER BY ROUND(SUM(OD.Quantity*OD.UnitPrice*(1 - OD.Discount) - OD.Quantity*P.UnitPrice*0.6),2) DESC) AS Xep_hang_trong_quy,
	LAG (SUM(OD.Quantity*OD.UnitPrice*(1 - OD.Discount) - OD.Quantity*P.UnitPrice*0.6)) OVER (PARTITION BY P.ProductID ORDER BY YEAR(O.OrderDate), DATEPART(QUARTER,O.OrderDate)) AS Loi_nhuan_quy_truoc
		FROM [Order Details] OD JOIN Products P ON OD.ProductID = P.ProductID
		JOIN Orders O ON O.OrderID = OD.OrderID 
		GROUP BY P.ProductID, P.ProductName,YEAR(O.OrderDate), DATEPART(QUARTER,O.OrderDate)) B1
		WHERE B1.Loi_nhuan_quy_truoc IS NOT NULL AND B1.Loi_nhuan_quy_truoc>B1.Tong_loi_nhuan
		
