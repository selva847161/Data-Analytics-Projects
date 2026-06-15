SELECT * FROM ORDERS;
SELECT * FROM PEOPLE;
SELECT * FROM [RETURNS];

------------------------------------------------------------------------------------------

--Data Cleaning
--Check for NULL values in each column
--In Orders Table
SELECT
	SUM(CASE WHEN Row_ID IS NULL THEN 1 ELSE 0 END) AS NULL_ROW_ID,
	SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS NULL_ORDER_ID,
	SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS NULL_ORDER_DATE,
	SUM(CASE WHEN Ship_Date IS NULL THEN 1 ELSE 0 END) AS NULL_SHIP_DATE,
	SUM(CASE WHEN Ship_Mode IS NULL THEN 1 ELSE 0 END) AS NULL_SHIP_MODE,
	SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS NULL_CUST_ID,
	SUM(CASE WHEN Customer_Name IS NULL THEN 1 ELSE 0 END) AS NULL_CUST_NAME,
	SUM(CASE WHEN Segment IS NULL THEN 1 ELSE 0 END) AS NULL_SEGMENT,
	SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS NULL_COUNTRY,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS NULL_CITY,
	SUM(CASE WHEN [State] IS NULL THEN 1 ELSE 0 END) AS NULL_STATE,
	SUM(CASE WHEN Postal_Code IS NULL THEN 1 ELSE 0 END) AS NULL_POSTAL_CODE,
	SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) AS NULL_REGION,
	SUM(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS NULL_PROD_ID,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS NULL_CATEGORY,
	SUM(CASE WHEN Sub_Category IS NULL THEN 1 ELSE 0 END) AS NULL_SUB_CATEGORY,
	SUM(CASE WHEN Product_Name IS NULL THEN 1 ELSE 0 END) AS NULL_PRODUCT_NAME,
	SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS NULL_SALES,
	SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS NULL_QUANTITY,
	SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS NULL_DISCOUNT,
	SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS NULL_PROFIT
FROM ORDERS;

--In Returns Table
SELECT
	SUM(CASE WHEN Returned IS NULL THEN 1 ELSE 0 END) AS NULL_RETURNS,
	SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS NULL_ORDER_ID
FROM [RETURNS];
-- THERE ARE NO NULL VALUES IN THE ORDERS AND RETURNS TABLE

------------------------------------------------------------------------------------------
--Blank or Empty Strings
--In Orders Table
SELECT 
	* 
FROM ORDERS 
WHERE 
	Order_ID = '' OR Ship_Mode = '' OR Customer_ID = '' OR
	Customer_Name = '' OR Segment = '' OR Country = '' OR
	City = '' OR [State] = '' OR Region = '' OR Product_ID = '' OR
	Category = '' OR Sub_Category = '' OR Product_Name = '';

--In Returns Table
SELECT 
	* 
FROM [RETURNS] 
WHERE 
	Returned = '' OR Order_ID = ''; 

--THERE ARE NO EMPTY STRINGS PRESENT IN THE ORDERS AND RETURNS TABLE

------------------------------------------------------------------------------------------
--Finding the duplicates in orders table
SELECT
	Order_ID,Order_Date,Ship_Date,Ship_Mode,Customer_ID,Customer_Name,
	Segment,Country,City,[State],Postal_Code,Region,Product_ID,Category,
	Sub_Category,Product_Name,Sales,Quantity,Discount,Profit,
	COUNT(*) AS CNT
FROM ORDERS 
GROUP BY 
	Order_ID,Order_Date,Ship_Date,Ship_Mode,Customer_ID,Customer_Name,
	Segment,Country,City,[State],Postal_Code,Region,Product_ID,Category,
	Sub_Category,Product_Name,Sales,Quantity,Discount,Profit
HAVING COUNT(*) > 1;

--Finding the duplicates in returns table
SELECT
	Order_ID,
	COUNT(*) AS CNT
FROM [RETURNS] 
GROUP BY 
	Order_ID
HAVING COUNT(*) > 1;

--THERE ARE NO DUPLICATE ROWS PRESENT IN THE ORDERS & RETURNS TABLE

------------------------------------------------------------------------------------------
--Check Data Types
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ORDERS';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'RETURNS';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'PEOPLE';

--Any Order_ID without Customer_ID
SELECT
	Order_ID
FROM ORDERS 
WHERE Customer_ID IS NULL;

--Any Customer_ID linked to multiple different names
SELECT
	Customer_ID 
FROM ORDERS 
GROUP BY Customer_ID
HAVING COUNT(DISTINCT Customer_Name) > 1;

--Any Product ID mapped to multiple categories
SELECT 
	Product_ID 
FROM ORDERS 
GROUP BY Product_ID
HAVING COUNT(DISTINCT Category) > 1;

--Any Product ID mapped to multiple Product names for the same customer
SELECT 
	Customer_ID,
	Product_ID,
	COUNT(DISTINCT Product_Name) AS COUNT_OF_PRODUCTS
FROM ORDERS 
GROUP BY Customer_ID,
		 Product_ID
HAVING COUNT(DISTINCT Product_Name) > 1;

--Orders where Ship Date < Order Date (date issue)
SELECT
	Order_Date,
	Ship_Date
FROM ORDERS 
WHERE Ship_Date < Order_Date;

--Trim & Standardize Text Columns
SELECT 
	*
FROM ORDERS 
WHERE Customer_Name LIKE ' %'
   OR Customer_Name LIKE '% ';

--Check Casing Issues
--Explore all the regions
SELECT DISTINCT Region FROM ORDERS;

--Explore all the shipping modes 
SELECT DISTINCT Ship_Mode FROM ORDERS;

--Explore all the categories 
SELECT DISTINCT Category,Sub_Category,Product_Name FROM ORDERS;

--Explore all the segments 
SELECT DISTINCT Segment FROM ORDERS;

--Explore all the states 
SELECT DISTINCT [State] FROM ORDERS;

--Explore all the cities 
SELECT DISTINCT City FROM ORDERS;

--Referential Completeness Check
--Does every Product_ID has Product_Name
SELECT
	*
FROM ORDERS 
WHERE Product_ID IS NOT NULL
  AND Product_Name IS NULL;

--Does every Customer_ID has Customer_Name
SELECT
	*
FROM ORDERS 
WHERE Customer_ID IS NOT NULL
  AND Customer_Name IS NULL;

--Returns Table Validation (Does every order_id in returns table exist in orders table)
--return records that do NOT have a matching order in the ORDERS table.
SELECT
	*
FROM [RETURNS] r
LEFT JOIN ORDERS o
ON r.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

--Valid_Return_Records
SELECT distinct r.Order_ID
FROM [RETURNS] r
JOIN ORDERS o
ON r.Order_ID = o.Order_ID;

------------------------------------------------------------------------------------------
--NUMERIC COLUMNS SANITY CHECKS
--Check for Negative Sales
SELECT
    'TOTAL TRANSACTIONS' AS METRIC,COUNT(*) AS VALUE
FROM ORDERS

UNION ALL

SELECT	
    'ZERO SALES TRANSACTION',COUNT(*) 
FROM ORDERS
WHERE Sales = 0 

UNION ALL
	
SELECT
	'NEGATIVE SALES TRANSACTION',COUNT(*)
FROM ORDERS 
WHERE Sales < 0;

--Check for Negative Quantity
SELECT 
	'TOTAL TRANSACTIONS' AS METRIC,COUNT(*) AS VALUE
FROM ORDERS

UNION ALL

SELECT 
	'NEGATIVE QUANTITY',COUNT(*)
FROM ORDERS 
WHERE Quantity < 0;

--Check for Invalid Discount
SELECT 
	'TOTAL TRANSACTIONS' AS METRIC,COUNT(*) AS VALUE
FROM ORDERS

UNION ALL

SELECT 
	'INVALID DISCOUNT (> 100%)',COUNT(*)
FROM ORDERS 
WHERE Discount > 1

UNION ALL

SELECT 
	'INVALID DISCOUNT (< 0)',COUNT(*)
FROM ORDERS 
WHERE Discount < 0;

--COUNT_OF_OUTLIERS_PROFIT
WITH Quartiles_Profit AS (
	SELECT
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Profit) OVER() AS Q1,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Profit) OVER() AS Q3,
		Profit
	FROM ORDERS 
)
SELECT
COUNT(*) AS COUNT_OF_OUTLIERS_PROFIT
FROM Quartiles_Profit
WHERE Profit < (Q1 - 1.5 * (Q3 - Q1))
   OR Profit > (Q3 + 1.5 * (Q3 - Q1));

--COUNT_OF_OUTLIERS_SALES
WITH Quartiles_Sales AS (
	SELECT
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Sales) OVER() AS Q1,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Sales) OVER() AS Q3,
		Sales
	FROM ORDERS 
)
SELECT
COUNT(*) AS COUNT_OF_OUTLIERS_SALES
FROM Quartiles_Sales
WHERE Sales < (Q1 - 1.5 * (Q3 - Q1))
   OR Sales > (Q3 + 1.5 * (Q3 - Q1));

--Profit < -Sales Business Rule Validation
SELECT 
	Sales,
	Profit,
	Discount
FROM ORDERS 
WHERE Profit < -Sales;

------------------------------------------------------------------------------------------

--CREATE SCHEMA (Fact and Dimension Tables)
--Create all Dimensions Table
--dim_sales_manager
CREATE TABLE dim_sales_manager(
	Sales_Manager_Key INT IDENTITY(1,1) PRIMARY KEY,
	Person VARCHAR(100)
);

--dim_location
CREATE TABLE dim_location(
	Location_Key INT IDENTITY(1,1) PRIMARY KEY,
	City VARCHAR(50),
	[State] VARCHAR(50),
	Region VARCHAR(20),
	Country VARCHAR(30),
	Postal_Code VARCHAR(50),
	Sales_Manager_Key INT,

	FOREIGN KEY(Sales_Manager_Key) REFERENCES dim_sales_manager(Sales_Manager_Key)
);

--dim_product
CREATE TABLE dim_product(
	Product_Key INT IDENTITY(1,1) PRIMARY KEY,
	Product_ID VARCHAR(100),
	Product_Name VARCHAR(200),
	Category VARCHAR(100),
	Sub_Category VARCHAR(100)
);

--dim_customer
CREATE TABLE dim_customer(
	Customer_Key INT IDENTITY(1,1) PRIMARY KEY,
	Customer_ID VARCHAR(50),
	Customer_Name VARCHAR(100),
	Segment VARCHAR(50)
);

----CREATE FACT TABLE
CREATE TABLE fact_orders(
	Order_Key INT IDENTITY(1,1) PRIMARY KEY,
	Order_ID VARCHAR(100),

	Order_Date DATE,
	Ship_Date DATE,
	Ship_Mode VARCHAR(100),

	Sales DECIMAL(18,2),
	Quantity INT,
	Discount DECIMAL(4,2),
	Profit DECIMAL(18,2),

	Location_Key INT,
	Product_Key INT,
	Customer_Key INT,

	FOREIGN KEY (Location_Key) REFERENCES dim_location(Location_Key),
	FOREIGN KEY (Product_Key) REFERENCES dim_product(Product_Key),
	FOREIGN KEY (Customer_Key) REFERENCES dim_customer(Customer_Key)
);

--Insert Data in all Tables
--dim_sales_manager
INSERT INTO dim_sales_manager(Person)
SELECT DISTINCT
	Person
FROM PEOPLE;

--dim_location
INSERT INTO dim_location(City,[State],Region,Country,Postal_Code,Sales_Manager_Key)
SELECT DISTINCT
	o.City,
	o.[State],
	o.Region,
	o.Country,
	o.Postal_Code,
	sm.Sales_Manager_Key
FROM ORDERS o
JOIN PEOPLE p
	ON o.Region = p.Region 
JOIN dim_sales_manager sm
	ON p.Person = sm.Person;

--dim_product
INSERT INTO dim_product(Product_ID,Product_Name,Category,Sub_Category)
SELECT DISTINCT
	Product_ID,
	Product_Name,
	Category,
	Sub_Category
FROM ORDERS;

--dim_customer
INSERT INTO dim_customer(Customer_ID,Customer_Name,Segment)
SELECT DISTINCT
	Customer_ID,
	Customer_Name,
	Segment
FROM ORDERS;

--fact_orders
INSERT INTO fact_orders(
	Order_ID,
	Order_Date,
	Ship_Date,
	Ship_Mode,
	Sales,
	Quantity,
	Discount,
	Profit,
	Location_Key,
	Product_Key,
	Customer_Key
)
SELECT
	o.Order_ID,
	o.Order_Date,
	o.Ship_Date,
	o.Ship_Mode,
	o.Sales,
	o.Quantity,
	o.Discount,
	o.Profit,
	dl.Location_Key,
	dp.Product_Key,
	dc.Customer_Key
FROM ORDERS o

JOIN dim_customer dc
	ON dc.Customer_ID = o.Customer_ID

JOIN dim_product dp
	ON dp.Product_ID = o.Product_ID
	AND dp.Product_Name = o.Product_Name

JOIN dim_location dl
	ON dl.City = o.City
	AND dl.[State] = o.[State]
	AND dl.Region = o.Region
	AND dl.Country = o.Country
	AND dl.Postal_Code = o.Postal_Code;

------------------------------------------------------------------------------------------

--DATABASE EXPLORATION
--Exploring all the objects in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

--Exploring all the columns in the database
SELECT 
	* FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_orders';

SELECT 
	* FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customer';

SELECT 
	* FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_location';

SELECT 
	* FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_product';

SELECT 
	* FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_sales_manager';

--Total Rows
SELECT
	COUNT(*) AS TOTAL_ROWS
FROM fact_orders;

--Total Columns
SELECT 
	COUNT(*) AS COLUMN_COUNT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_orders';

--Distinct Order ID
SELECT
	COUNT(DISTINCT Order_ID) AS TOTAL_UNIQUE_ORDERS
FROM fact_orders;

--Distinct Customer ID
SELECT
	COUNT(DISTINCT Customer_ID) AS TOTAL_UNIQUE_CUSTOMERS
FROM dim_customer;

--Distinct Product ID
SELECT
	COUNT(DISTINCT Product_ID) AS TOTAL_UNIQUE_PRODUCTS
FROM dim_product;

------------------------------------------------------------------------------------------
--DIMENSION EXPLORATION
--Explore all the shipping modes 
SELECT DISTINCT Ship_Mode FROM fact_orders;

--Explore all the categories 
SELECT DISTINCT Category,Sub_Category,Product_Name FROM dim_product
ORDER BY 1,2,3;

--Explore all the segments 
SELECT DISTINCT Segment FROM dim_customer;

--Explore all the regions 
SELECT DISTINCT Region,[State],City FROM dim_location
ORDER BY 1,2,3;

--Category Distribution
SELECT 
	Category,
	COUNT(*) AS COUNT_OF_CATEGORIES
FROM dim_product
GROUP BY Category;

--Sub Category Distribution
SELECT 
	Sub_Category,
	COUNT(*) AS COUNT_OF_SUBCATEGORIES
FROM dim_product 
GROUP BY Sub_Category
ORDER BY COUNT(*) DESC;

--Segment Distribution
SELECT 
	Segment,
	COUNT(*) AS COUNT_OF_SEGMENT
FROM dim_customer 
GROUP BY Segment;

------------------------------------------------------------------------------------------
--DATE EXPLORATION
--Minimum and Maximum Order Date
SELECT
	'Minimum_Order_Date' AS DATE_EXPLORATION,
	MIN(Order_Date) AS DATE_VALUE
FROM fact_orders

UNION ALL
SELECT
	'Maximum_Order_Date',
	MAX(Order_Date)
FROM fact_orders;

--Total years covered
SELECT
	CAST
		(DATEDIFF(DAY,MIN(Order_Date),MAX(Order_Date))
		/ 365.25 AS DECIMAL(10,2)) AS TOTAL_YEARS
FROM fact_orders;
------------------------------------------------------------------------------------------
--MEASURES EXPLORATION
--Exploring all the orders which are returned and not returned
SELECT 
	f.Order_Id,
	f.Sales,
	f.Profit,
	CASE 
		WHEN r.Order_ID IS NULL THEN 'NOT_RETURNED' ELSE 'RETURNED' END AS Order_Status
FROM fact_orders f
LEFT JOIN [returns] r
on f.Order_ID = r.Order_ID;

--Key Metrics of the business
--Sales
SELECT 'TOTAL_ORDERS'  AS MEASURE_NAME,COUNT(DISTINCT Order_ID) AS MEASURE_VALUE FROM fact_orders
UNION ALL
SELECT 'GROSS_SALES',SUM(Sales) 
FROM fact_orders
UNION ALL
SELECT 'RETURNED_SALES',
	   SUM(CASE 
			  WHEN r.Order_ID IS NOT NULL THEN f.Sales ELSE 0 END)
FROM fact_orders f 
LEFT JOIN [returns] r
	ON f.Order_ID = r.Order_ID
UNION ALL
SELECT 
	   'NET_SALES',
	   SUM(CASE 
			  WHEN r.Order_ID IS NULL THEN f.Sales ELSE 0 END)
FROM fact_orders f 
LEFT JOIN [returns] r
	ON f.Order_ID = r.Order_ID
UNION ALL

--Profit
SELECT 'GROSS_PROFIT',SUM(Profit)
FROM fact_orders
UNION ALL
SELECT 'RETURNED_PROFIT',
	   SUM(CASE 
			  WHEN r.Order_ID IS NOT NULL THEN f.Profit ELSE 0 END)
FROM fact_orders f 
LEFT JOIN [returns] r
	ON f.Order_ID = r.Order_ID
UNION ALL
SELECT 'NET_PROFIT',
	   SUM(CASE 
			  WHEN r.Order_ID IS NULL THEN f.Profit ELSE 0 END)
FROM fact_orders f 
LEFT JOIN [returns] r
	ON f.Order_ID = r.Order_ID
UNION ALL

--Quantity
SELECT 'GROSS_QUANTITY',SUM(Quantity) FROM fact_orders
UNION ALL
SELECT 'RETURNED_QUANTITY',
	   SUM(CASE 
			  WHEN r.Order_ID IS NOT NULL THEN f.Quantity ELSE 0 END)
FROM fact_orders f 
LEFT JOIN [returns] r
	ON f.Order_ID = r.Order_ID
UNION ALL
SELECT 'NET_QUANTITY',
	   SUM(CASE 
			  WHEN r.Order_ID IS NULL THEN f.Quantity ELSE 0 END)
FROM fact_orders f 
LEFT JOIN [returns] r
	ON f.Order_ID = r.Order_ID;

--Percentage of returns
SELECT 
		FORMAT(100.0 * COUNT(DISTINCT r.Order_ID)
			 /COUNT(DISTINCT f.Order_ID),'N2') + '%' AS RETURN_PERCENT
FROM fact_orders f
LEFT JOIN [returns] r
	ON f.Order_ID = r.Order_ID;

--Net Profit Margin
WITH Net_Sales_Profit AS(
	SELECT
		SUM
		   (CASE WHEN r.Order_ID IS NULL THEN f.Sales ELSE 0 END) AS NET_SALES,
		SUM
		   (CASE WHEN r.Order_ID IS NULL THEN f.Profit ELSE 0 END) AS NET_PROFIT
	FROM fact_orders f
	LEFT JOIN [returns] r
		ON f.Order_ID = r.Order_ID
)
SELECT
	CAST(
		CAST(
			 (NET_PROFIT * 100.0/NULLIF(NET_SALES,0)) AS DECIMAL(4,2)) AS VARCHAR(10)) + '%' 
			 AS NET_PROFIT_MARGIN
FROM Net_Sales_Profit;
------------------------------------------------------------------------------------------
--MAGNITUDE EXPLORATION
--Total Sales by Category , % of total
WITH Sales_by_Category AS(
	SELECT
		p.Category,
		SUM(f.SALES) AS TOTAL_SALES
	FROM fact_orders f
	JOIN dim_product p
		ON f.Product_Key = p.Product_Key
	GROUP BY p.Category
)
SELECT
	Category,
	TOTAL_SALES,
	FORMAT
		(TOTAL_SALES * 100.0 / SUM(TOTAL_SALES) OVER(),'N2') + '%' AS PERCENTAGE_OF_TOTAL
FROM Sales_by_Category
ORDER BY TOTAL_SALES DESC;


--Total Sales by Sub_Category , % of total
WITH Sales_by_Sub_Category AS(
	SELECT
		p.Sub_Category,
		SUM(f.SALES) AS TOTAL_SALES
	FROM fact_orders f
	JOIN dim_product p
		ON f.Product_Key = p.Product_Key
	GROUP BY p.Sub_Category
)
SELECT
	Sub_Category,
	TOTAL_SALES,
	FORMAT
		(TOTAL_SALES * 100.0 / SUM(TOTAL_SALES) OVER(),'N2') + '%' AS PERCENTAGE_OF_TOTAL
FROM Sales_by_Sub_Category
ORDER BY TOTAL_SALES DESC;

--Total Sales by Segment , % of total
WITH Sales_by_Segment AS(
	SELECT
		c.Segment,
		SUM(f.SALES) AS TOTAL_SALES
	FROM fact_orders f
	JOIN dim_customer c
		ON f.Customer_Key = c.Customer_Key
	GROUP BY c.Segment
)
SELECT
	Segment,
	TOTAL_SALES,
	FORMAT
		(TOTAL_SALES * 100.0 / SUM(TOTAL_SALES) OVER(),'N2') + '%' AS PERCENTAGE_OF_TOTAL
FROM Sales_by_Segment
ORDER BY TOTAL_SALES DESC;

--Customer participation distribution across categories
WITH Count_Customer_Category AS(
	SELECT
		p.Category,
		COUNT(DISTINCT f.Customer_Key) AS CUSTOMER_COUNT
	FROM fact_orders f
	JOIN dim_product p
		ON f.Product_Key = P.Product_Key
	GROUP BY p.Category
)
SELECT 
	Category,
	CUSTOMER_COUNT,
	FORMAT
			(CUSTOMER_COUNT * 100.0 / SUM(CUSTOMER_COUNT) OVER(),'N2') + '%' AS PERCENT_OF_CUSTOMERS_CATEGORY_WISE
FROM Count_Customer_Category cc
ORDER BY CUSTOMER_COUNT DESC;


--Total Sales by State , % of total
WITH Sales_by_State AS(
	SELECT
		l.[State],
		SUM(f.SALES) AS TOTAL_SALES
	FROM fact_orders f
	JOIN dim_location l
		ON f.Location_Key = l.Location_Key
	GROUP BY l.[State]
)
SELECT
	[State],
	TOTAL_SALES,
	FORMAT
		(TOTAL_SALES * 100.0 / SUM(TOTAL_SALES) OVER(),'N2') + '%' AS PERCENTAGE_OF_TOTAL,
	RANK() OVER(ORDER BY TOTAL_SALES DESC) AS SALES_RNK
FROM Sales_by_State;


--Total revenue generated for each customer
SELECT
	c.Customer_Name,
	SUM(f.Sales) AS TOTAL_SALES
FROM fact_orders f
JOIN dim_customer c
	ON f.Customer_Key = c.Customer_Key
GROUP BY c.Customer_Name
ORDER BY TOTAL_SALES DESC;


--Total Sales by Year
SELECT
	YEAR(Order_Date) AS YEAR,
	SUM(Sales) AS TOTAL_SALES
FROM fact_orders
GROUP BY YEAR(Order_Date)
ORDER BY YEAR(Order_Date);


--Total Sales by Quarter
WITH Quarterly_Sales AS(
	SELECT
		YEAR(Order_Date) AS Year,
		DATEPART(QUARTER,Order_Date) AS QUARTER,
		SUM(Sales) AS TOTAL_SALES_QUARTERLY					 
	FROM fact_orders
	GROUP BY YEAR(Order_Date),
			 DATEPART(QUARTER,Order_Date)
)
SELECT
	YEAR,
	QUARTER,
	TOTAL_SALES_QUARTERLY,
	SUM(TOTAL_SALES_QUARTERLY) OVER(PARTITION BY YEAR ORDER BY QUARTER
									ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CUMULATIVE_SALES
FROM Quarterly_Sales
ORDER BY Year, Quarter;


--Total Sales by Month
WITH Monthly_Sales AS(
	SELECT
		YEAR(Order_Date) AS YEAR,
		MONTH(Order_Date) AS MONTH,
		SUM(SALES) AS TOTAL_SALES_MONTHLY
	FROM fact_orders
	GROUP BY YEAR(Order_Date),
			 MONTH(Order_Date)
)
SELECT
	YEAR,
	MONTH,
	TOTAL_SALES_MONTHLY,
	SUM(TOTAL_SALES_MONTHLY) OVER(PARTITION BY YEAR ORDER BY MONTH
								  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CUMULATIVE_SALES_MONTHLY
FROM Monthly_Sales
ORDER BY YEAR,MONTH;

------------------------------------------------------------------------------------------
--Advanced Analysis
--1.Identify the customers whose total sales are above the average sales of all customers

--Customers with Total_Sales 
WITH Customer_with_Total_Sales AS(
	SELECT 
		c.Customer_ID,
		c.Customer_Name,
		SUM(CASE WHEN r.Order_ID IS NULL THEN f.Sales ELSE 0 END) AS TOTAL_SALES
	FROM dim_customer c
	JOIN fact_orders f
		ON c.Customer_Key = f.Customer_Key
	LEFT JOIN [returns] r
		ON r.Order_ID = f.Order_ID
	GROUP BY c.Customer_ID,
			 c.Customer_Name
),
--Average sales of all customers
	Average_sales_of_all_customers AS(
	SELECT
		AVG(TOTAL_SALES) AS AVG_SALES_ALLCUSTOMERS
FROM Customer_with_Total_Sales
)
--Customers whose total sales are above the average sales of all customers
SELECT
	Customer_ID,
	Customer_Name,
	TOTAL_SALES,
	AVG_SALES_ALLCUSTOMERS
FROM Customer_with_Total_Sales c
CROSS JOIN Average_sales_of_all_customers
WHERE TOTAL_SALES > AVG_SALES_ALLCUSTOMERS
ORDER BY TOTAL_SALES DESC;

------------------------------------------------------------------------------------------
--2.Find the customer who has made the maximum number of orders in each category

--No of orders by each customer
WITH Customer_Order_Count AS(
	SELECT 
		dc.Customer_ID,
		dc.Customer_Name,
		dp.Category,

		COUNT(DISTINCT CASE
							WHEN r.Order_ID IS NULL THEN f.Order_ID END) AS NUMBER_OF_ORDERS
	FROM dim_customer dc
	JOIN fact_orders f
		ON dc.Customer_Key = f.Customer_Key
	JOIN dim_product dp
		ON dp.Product_Key = f.Product_Key
	LEFT JOIN [returns] r
		ON r.Order_ID = f.Order_ID
	GROUP BY dc.Customer_ID,
			 dc.Customer_Name,
			 dp.Category
),
--Ranking the customers based on the no or orders
	Ranking_of_Customers AS(
	SELECT 
		   Customer_ID,
		   Customer_Name,
		   Category,
		   NUMBER_OF_ORDERS,
		   DENSE_RANK() OVER(PARTITION BY Category ORDER BY NUMBER_OF_ORDERS DESC) AS RNK_CUSTOMERS
	FROM Customer_Order_Count
)
--customer who has made the maximum number of orders in each category
SELECT 
	Customer_ID,
	Customer_Name,
	Category,
	NUMBER_OF_ORDERS,
	RNK_CUSTOMERS
FROM Ranking_of_Customers
WHERE RNK_CUSTOMERS = 1
ORDER BY Category;
------------------------------------------------------------------------------------------

--3.Find the top 3 products in each category based on their sales

--Sales by Product and Category
WITH Sales_by_Product_Category AS(
	SELECT
		dp.Product_ID,
		dp.Product_Name,
		dp.Category,
		dp.Sub_Category,
		AVG(CASE 
				WHEN r.Order_ID IS NULL THEN f.Discount END) AS AVG_DISCOUNT,								
		SUM(CASE 
				WHEN r.Order_ID IS NULL then f.Sales END) AS TOTAL_SALES,
		SUM(CASE 
				WHEN r.Order_ID IS NULL then f.Profit END) AS TOTAL_PROFIT
	FROM dim_product dp
	JOIN fact_orders f
		ON dp.Product_Key = f.Product_Key
	LEFT JOIN [returns] r
		ON r.Order_ID = f.Order_ID
	GROUP BY dp.Product_ID,
			 dp.Product_Name,
			 dp.Category,
			 dp.Sub_Category
),
--Ranking products by Sales
	Ranking_Products_by_Sales AS(
	SELECT
		Product_ID,
		Product_Name,
		Category,
		Sub_Category,
		CAST(AVG_DISCOUNT AS DECIMAL (6,2)) AS AVG_DISCOUNT,
		TOTAL_SALES,
		TOTAL_PROFIT,
		ROW_NUMBER() OVER(PARTITION BY Category ORDER BY TOTAL_SALES DESC) AS RNK_PRODUCTS
	FROM Sales_by_Product_Category
)
--Top 3 products in each category based on their sales
SELECT
	Product_ID,
	Product_Name,
	Category,
	Sub_Category,
	AVG_DISCOUNT,
	TOTAL_SALES,
	TOTAL_PROFIT,
	RNK_PRODUCTS
FROM Ranking_Products_by_Sales
WHERE RNK_PRODUCTS <=3;


------------------------------------------------------------------------------------------

--4.Calculate year-over-year(YOY) sales growth

--Yearly Sales
WITH Yearly_Sales AS(
	SELECT
		YEAR(Order_Date) AS YEAR,
		SUM(CASE
				WHEN r.Order_ID IS NULL THEN f.Sales ELSE 0 END) AS YEARLY_SALES
	FROM fact_orders f
	LEFT JOIN [returns] r
		ON f.Order_ID = r.Order_ID
	GROUP BY YEAR(Order_Date)
),
--Year Over year Comparison
	Year_Over_Year_Comparison AS(
	SELECT
		YEAR,
		YEARLY_SALES,
		LAG(YEARLY_SALES) OVER(ORDER BY YEAR) AS PREVIOUS_YEAR_SALES
	FROM Yearly_Sales
)
--YOY SALES GROWTH
SELECT
YEAR,
YEARLY_SALES,
PREVIOUS_YEAR_SALES,
(YEARLY_SALES - PREVIOUS_YEAR_SALES) AS YEAR_OVER_YEAR_SALES_GROWTH,
CAST(
	  (YEARLY_SALES - PREVIOUS_YEAR_SALES) * 100.0
	   /NULLIF(PREVIOUS_YEAR_SALES,0) AS DECIMAL(6,2)) AS YOY_GROWTH_PERCENT
FROM Year_Over_Year_Comparison;

------------------------------------------------------------------------------------------
--5.Find the most profitable shipping mode for each region

--since the dataset contains only south region,I didnt partition the data by region

--Total_Profit_by_Ship_Mode
WITH Total_Profit_by_Ship_Mode AS(
	SELECT
		dl.Region,
        f.Ship_Mode,
		SUM(CASE
				WHEN r.Order_ID IS NULL THEN f.Profit ELSE 0 END) AS PROFIT_BY_SHIPMODE
	FROM fact_orders f
	LEFT JOIN [returns] r
		ON f.Order_ID = r.Order_ID
    JOIN dim_location dl 
        ON f.Location_Key = dl.Location_Key
	GROUP BY dl.Region,
             f.Ship_Mode
),
--Overall Profit and Ranking
	Total_Profit_And_Ranking AS(
	SELECT
        Region,
		Ship_Mode,
		PROFIT_BY_SHIPMODE,
		CAST(
			 PROFIT_BY_SHIPMODE * 100.0/NULLIF(SUM(PROFIT_BY_SHIPMODE) OVER(),0) AS Decimal(6,2)) AS PERCENT_OF_TOTAL,
		DENSE_RANK() OVER(PARTITION BY Region ORDER BY PROFIT_BY_SHIPMODE DESC) AS RNK_SHIPMODE
	FROM Total_Profit_by_Ship_Mode
)
--Most profitable shipping mode
SELECT
	*
FROM Total_Profit_And_Ranking
WHERE RNK_SHIPMODE = 1;


----------------------------------------------------------------------------------------------
---Operational Cost by Shipping Mode

SELECT 
    Ship_Mode,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Sales - Profit) AS Estimated_Operational_Cost
FROM fact_orders
GROUP BY Ship_Mode
ORDER BY Estimated_Operational_Cost DESC;

--Operational Cost Impact from Returns

SELECT 
    COUNT(r.Order_ID) AS Total_Returns,
    SUM(f.Sales) AS Returned_Sales,
	SUM(f.Profit) AS Profit_From_Returned_Orders,
    SUM(f.Sales - f.Profit) AS Estimated_Product_Cost
FROM fact_orders f
JOIN returns r
ON f.Order_ID = r.Order_ID;

-------------------------------------------------------------------------------------
--Customers Discount Behaviour
WITH Customer_with_Total_Sales AS(
	SELECT 
		c.Customer_ID,
		SUM(CASE WHEN r.Order_ID IS NULL THEN f.Sales ELSE 0 END) AS TOTAL_SALES,
		avg(CASE WHEN r.Order_ID IS NULL THEN f.Discount END) AS avg_discount
	FROM dim_customer c
	JOIN fact_orders f
		ON c.Customer_Key = f.Customer_Key
	LEFT JOIN [returns] r
		ON r.Order_ID = f.Order_ID
	GROUP BY c.Customer_ID			
),
--Average sales of all customers
	Average_sales_of_all_customers AS(
	SELECT
		AVG(TOTAL_SALES) AS AVG_SALES_ALLCUSTOMERS
FROM Customer_with_Total_Sales
)
--Customers whose total sales are above the average sales of all customers
SELECT
	case
		when c.TOTAL_SALES > a.AVG_SALES_ALLCUSTOMERS then 'High value customers'
		else 'Other Customers'
	end as Customer_Group,
	avg(c.avg_discount) as AVG_Discount
FROM Customer_with_Total_Sales c
CROSS JOIN Average_sales_of_all_customers a
group by case
			when c.TOTAL_SALES > a.AVG_SALES_ALLCUSTOMERS then 'High value customers'
			else 'Other Customers'
		 end;
