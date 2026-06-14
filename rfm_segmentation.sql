---Data Filtering + Subsetting + Table Creation
select
	top 50000 
	*
into retail
from OnlineRetail
where CustomerID is not null
  and Quantity > 0
  and UnitPrice > 0;
--------------------------------------------------------------------------------
--Cancelled Orders
select
    *
into retail_canc
from OnlineRetail
where InvoiceNo like 'C%';

--------------------------------------------------------------------------------
--- Cancelled Transactions (Dec 2010 – Feb 2011)

select
    *
from retail_canc
where CustomerID is not null
and Quantity < 0
and InvoiceDate >= '2010-12-01'
and InvoiceDate <  '2011-02-24'
and UPPER([Description]) not like '%Manual%'
and UPPER([Description]) not like '%Postage%'
and UPPER([Description]) not like '%Discount%'
and UPPER([Description]) not like '%Charge%'
and UPPER([Description]) not like '%Fee%';

--------------------------------------------------------------------------------
---Data Inspection
select 
	top 10
	*
from retail;
------------------
select
    top 10
    *
from retail_canc;
--------------------------------------------------------------------------------
---Data Cleaning and Validation
---Null Check
select
	sum(case when InvoiceNo is null then 1 else 0 end) as null_invoiceno,
    sum(case when StockCode is null then 1 else 0 end) as null_stockcode,
    sum(case when [Description] is null then 1 else 0 end) as null_description,
    sum(case when Quantity is null then 1 else 0 end) as null_quantity,
    sum(case when InvoiceDate is null then 1 else 0 end) as null_invoicedate,  
    sum(case when UnitPrice is null then 1 else 0 end) as null_unitprice,
    sum(case when CustomerID is null then 1 else 0 end) as null_customerid,  
    sum(case when Country is null then 1 else 0 end) as null_country
from retail;
--------------------------------------------------------------------------------
---Blank or Empty Strings
select
    *
from retail
where
    InvoiceNo = ''
 or StockCode = ''
 or [Description] = ''
 or CustomerID = ''
 or Country = '';
 --------------------------------------------------------------------------------
 ---Duplicate Detection
select 
    InvoiceNo,StockCode,[Description],Quantity,
    InvoiceDate,UnitPrice,CustomerID,Country,
    count(*) as cnt
from retail
group by InvoiceNo,StockCode,[Description],Quantity,
         InvoiceDate,UnitPrice,CustomerID,Country
having count(*) > 1;
--------------------------------------------------------------------------------
---Delete Duplicates
with del_cte as(
        select
            *,
            row_number() over(partition by InvoiceNo,StockCode,[Description],Quantity,
                                           InvoiceDate,UnitPrice,CustomerID,Country
                              order by (select null)
        ) as rn
        from retail
)
delete from del_cte 
where rn > 1;
--------------------------------------------------------------------------------
---Check for missing Customerid (Verification)
select
    *
from retail 
where CustomerID is null;
--------------------------------------------------------------------------------
---Check data types
select
    column_name,
    data_type 
from information_schema.columns 
where table_name = 'retail';
--------------------------------------------------------------------------------
---Problem Statements
---Total Revenue generated and its distribution across time
select
    format(InvoiceDate,'yyyy-MM') as Month,
    sum(UnitPrice * Quantity) as Total_Revenue
from retail
group by format(InvoiceDate,'yyyy-MM')
order by Month;

-------------------------------------------------------------------------------

---Do a small percentage of customers contribute to most of the revenue?
with customer_rev as (
    select
        CustomerID,
        sum(UnitPrice * Quantity) as Customer_Revenue
    from retail
    group by CustomerID
),
    ordered_rev as (
    select
        CustomerID,
        Customer_Revenue,
        sum(Customer_Revenue) over() as Total_Revenue,
        sum(Customer_Revenue) over(order by Customer_Revenue desc 
                                   rows between unbounded preceding and current row) as Cumulative_Revenue,
        row_number() over(order by Customer_Revenue desc) as rnk,
        count(*) over() as Total_Customers
    from customer_rev
),
    customer_percentage as (
    select
        CustomerID,
        Customer_Revenue,
        cast(
            (Customer_Revenue * 100.0 / Total_Revenue) as decimal(10,2)) as Percentage_Cont,
        cast(
            (Cumulative_Revenue * 100.0 / Total_Revenue) as decimal(10,2)) as Cumulative_Perc,
        cast(
            (rnk * 100.0 / Total_Customers) as decimal(6,2)) as Customer_Perc
    from ordered_rev
)
select 
    top 1 *
from customer_percentage
where Customer_Perc >= 20
order by Customer_Perc;

-------------------------------------------------------------------------------

---How frequently do customers make purchases?
with customer_purchases as (
    select
        CustomerID,
        count(distinct InvoiceNo) as Purchases
    from retail
    group by CustomerID
),
    customers_type as (
    select
        case 
            when Purchases = 1 then 'One-time buyers'
            when Purchases between 2 and 5 then 'Occasional buyers'
            else 'Frequent buyers'
        end as Customers_Category     
    from customer_purchases
)
select
    Customers_Category,
    count(*) as Customer_Count,
    cast(
        count(*) * 100.0 / sum(count(*)) over() as decimal(10,2)) as Perc_Contribution
from customers_type
group by Customers_Category
order by Customer_Count desc;

-------------------------------------------------------------------------------

---What is the distribution of transaction values?
with Transactions_val as (
    select
        InvoiceNo,
        sum(UnitPrice * Quantity) as Transactions
    from retail
    group by InvoiceNo
),
    Transaction_grp as(
    select
        case 
            when Transactions < 100 then 'Low'
            when Transactions between 100 and 500 then 'Medium'
            else 'High'
        end as Segmentation
    from Transactions_val
)
select
    Segmentation,
    count(*) as Transactions_Cnt,
    cast(
        count(*) * 100.0 / sum(count(*)) over() as decimal(10,2)) as Cnt_Perc
from Transaction_grp
group by Segmentation
order by Transactions_Cnt desc;

-------------------------------------------------------------------------------

---Which countries contribute most to revenue and customer count?
with Country_rev as (
    select
        Country,
        count(distinct CustomerID) as Customer_Count,
        sum(UnitPrice * Quantity) as Revenue
    from retail
    group by Country
),
    Perc_Contribution as (
    select
        Country,
        Customer_Count,
        Revenue,
        sum(Customer_Count) over() as Overall_CustomerCnt,
        sum(Revenue) over() as Overall_Revenue
    from Country_rev
)
select
    top 10
    Country,
    Customer_Count,
    Revenue,
    cast(
        Customer_Count * 100.0 / Overall_CustomerCnt as decimal(10,2)) as Customer_Perc_Cont,
    cast(
        Revenue * 100.0 / Overall_Revenue as decimal(10,2)) as Rev_Perc_Cont
from Perc_Contribution
order by Revenue desc;
     
--------------------------------------------------------------------------------
---Customer segmentation logic (RFM scoring)
WITH base AS (
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS Last_Order_Date,
        COUNT(DISTINCT InvoiceNo) AS Frequency,
        SUM(UnitPrice * Quantity) AS Monetary
    FROM retail
    GROUP BY CustomerID
),
rfm AS (
    SELECT *,
        DATEDIFF(day, Last_Order_Date,
            MAX(Last_Order_Date) OVER()) AS Recency
    FROM base
)
SELECT TOP 10 *
FROM rfm;

--------------------------------------------------------------------------------
---High-value cancellation concentration
with canc_rev as (
    select
        sum(unitprice * quantity * -1) as canc_rev,
        description
    from retail_canc
    where CustomerID is not null
    and Quantity < 0
    and InvoiceDate >= '2010-12-01'
    and InvoiceDate <  '2011-02-24'
    and description not like '%Manual%'
    and description not like '%Postage%'
    and description not like '%Discount%'
    and description not like '%Charge%'
    and description not like '%Fee%'
    group by description
),
    overall_cancrev as (
    select
        *,
        sum(canc_rev) over() as overall_rev_canc
    from canc_rev
)
select
    top 5
    Description,
    canc_rev,
    cast(
        (canc_rev * 100.0 / overall_rev_canc) as decimal(6,2)) as perc_cont
from overall_cancrev
order by canc_rev desc;

--------------------------------------------------------------------------------
---End-to-End Customer Segmentation using RFM Analysis (SQL + Business Insights)
with base as (
    select
        CustomerID,
        max(InvoiceDate) as Last_Order_Date,
        count(distinct InvoiceNo) as Frequency,
        sum(UnitPrice * Quantity) as Monetary
    from retail 
    group by CustomerID
),
    RFM as (
    select  
        CustomerID,
        datediff(day,Last_Order_Date,
                     DATEADD(day, 1, MAX(Last_Order_Date) OVER ())) as Recency,
        Frequency,
        Monetary
    from base
),
    RFM_Buckets as (
    select
        *,
        ntile(5) over(order by Recency desc) as R,
        ntile(5) over(order by Frequency desc) as F,
        ntile(5) over(order by Monetary desc) as M
    from RFM 
),
    RFM_Score as (
    select
        *,
        R*100 + F*10 + M as RFM_Scored
    from RFM_Buckets
),
    Segmentation as (
    select
        *,
        case
            when R = 5 and F >= 4 then 'Champions'
            when R >= 4 and F >= 3 then 'Loyal Customers'
            when R = 5 and F <= 2 then 'New Customers'
            when R >= 4 and F <= 2 then 'Potential Loyalists'
            when R <= 2 and F >= 4 then 'At Risk'
            when R <= 2 and F <= 2 then 'Lost Customers'
            else 'Average Customers'
        end as Segment
    from RFM_Score
)
select
    Segment,
    count(*) as Customer_Count,
    cast(
        count(*) * 100.0/ sum(count(*)) over() as decimal(10,2)) as Perc_Contribution
from Segmentation
group by Segment
order by Customer_Count desc;
--------------------------------------------------------------------------------



    