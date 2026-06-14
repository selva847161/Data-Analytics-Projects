---Cohort Analysis
---Schema & Basic Integrity
select
	column_name,data_type,is_nullable
from INFORMATION_SCHEMA.COLUMNS
where table_name = 'retail';

--------------------------------------------------------------

--CustomerID Quality(Null Check)
select
	count(*) as null_customers
from retail
where CustomerID is null;

--------------------------------------------------------------

--Check for negative quantities
select
	count(*) as neg_qty
from retail
where Quantity < 0;

--------------------------------------------------------------

---Check for cancellations
select
	count(distinct InvoiceNo) as cancel_invoices
from retail
where InvoiceNo like 'C%';

--------------------------------------------------------------

---Revenue Sanity
select
	*
from retail
where UnitPrice <= 0;

--------------------------------------------------------------

--Check for Non Product Noise
select
	distinct [description]
from retail 
where [description] like '%Manual%'
   or [description] like '%Postage%'
   or [description] like '%Discount%'
   or [description] like '%Charge%'
   or [description] like '%Fee%';

select
	*
into retail_clean
from retail 
where CustomerID is not null
and Quantity > 0
and not (
	UPPER([Description]) LIKE '%MANUAL%' OR
    UPPER([Description]) LIKE '%POSTAGE%' OR
    UPPER([Description]) LIKE '%DISCOUNT%' OR
    UPPER([Description]) LIKE '%CHARGE%' OR
    UPPER([Description]) LIKE '%FEE%'
)

--------------------------------------------------------------

--Date Range Check
SELECT MIN(InvoiceDate) AS min_date,
       MAX(InvoiceDate) AS max_date
FROM retail_clean;

--------------------------------------------------------------

--Row Counts
SELECT COUNT(*) AS total_rows FROM retail_clean;

SELECT COUNT(*) AS valid_rows
FROM retail_clean
WHERE Quantity > 0 AND CustomerID IS NOT NULL;

SELECT COUNT(*) AS cancelled_rows
FROM retail_clean
WHERE Quantity < 0;

--------------------------------------------------------------
--Analyze whether entry product (first purchase) influences retention, value and cancellations

--ENTRY PRODUCT
with first_order as (
	select
		CustomerID,
		min(
			cast(InvoiceDate as date)) as First_Order_Date
	from retail_clean 
	group by CustomerID
),
	ranked_products as (
	select
		r.CustomerID,
		r.[Description],
		f.First_Order_Date,
		ROW_NUMBER() over(partition by r.CustomerID
						  order by r.UnitPrice * r.Quantity desc) as rn
	from first_order f
	join retail_clean r
		on r.CustomerID = f.CustomerID
		and cast(r.InvoiceDate as Date) = f.First_Order_Date
)
select
	CustomerID,
	[Description] as Entry_Product,
	First_Order_Date
into entry_product_table
from ranked_products
where rn = 1;

-----------------------------------------------------------------------------------

--PRODUCT GROUP
with prod_rev as (
	select
		[Description],
		sum(UnitPrice * Quantity) as Revenue
	from retail_clean
	group by [Description]
),
	ranked as (
	select 
		*,
		DENSE_RANK() over(order by Revenue desc) as rnk
	from prod_rev
)
select
	[Description],
	case	
		when rnk <= 3 then 'Top Products'		
		else 'Other'
	end as Product_Group
into product_group_table
from ranked;

-------------------------------------------------------------------------

--CUSTOMER BASE TABLE
select
	c.CustomerID,
	e.Entry_Product,
	pg.Product_Group,
	isnull(sum(isnull(r.UnitPrice,0) * isnull(r.Quantity,0)),0) as Total_Revenue,
	count(distinct r.InvoiceNo) as Purchase_Frequency,
	max(cast(r.InvoiceDate as date)) AS Last_Purchase_Date,
	isnull(sum(isnull(rc.UnitPrice,0) * isnull(rc.Quantity,0) * -1),0) AS Cancelled_Revenue
into customer_base_table
from (select distinct CustomerID from retail_clean) c
left join entry_product_table e
	on c.CustomerID = e.CustomerID
left join product_group_table pg
	on e.Entry_Product = pg.[Description] 
left join retail_clean r 
	on c.CustomerID = r.CustomerID
left join retail_canc rc
	on c.CustomerID = rc.CustomerID
group by 
		 c.CustomerID,
		 e.Entry_Product,
		 pg.Product_Group;

-------------------------------------------------------------------------

--RETENTION FLAG
with first_order as (
	select 
		CustomerID,
		min(
			cast(invoicedate as date)) as First_Order_Date
	from retail_clean
	group by CustomerID
),
	customer_months as (
	select
		CustomerID,
		datefromparts(year(First_Order_Date),month(First_Order_Date),1) as First_Month,
		DATEADD(month,1,datefromparts(year(First_Order_Date),month(First_Order_Date),1)) as Next_Month
	from first_order 
),
	purchase_months as (
	select
	  distinct
		CustomerID,
		datefromparts(year(InvoiceDate),month(InvoiceDate),1) as purchase_month
	from retail_clean
)
select
	c.CustomerID,
	c.First_Month,
	case 
		when p.CustomerID is not null then 1
		else 0
	end as retained 
into retention_flag_table
from customer_months c
left join purchase_months p 
	on c.CustomerID = p.CustomerID
	and c.Next_Month = p.purchase_month;

---------------------------------------------------------

-- CUSTOMER + PRODUCT + RETENTION + CANCELLATION
select
	r.CustomerID,
	r.First_Month,
	cb.Product_Group,
	r.Retained,
	case	
		when rc.CustomerID is not null then 1 
		else 0
	end as Cancelled_Customers
into customer_behavior_table
from retention_flag_table r
join customer_base_table cb
	on r.CustomerID = cb.CustomerID
left join (select distinct CustomerID from retail_canc) rc
	on r.CustomerID = rc.CustomerID;

---------------------------------------------------------

--FINAL ANALYSIS
select
	Product_Group,
	First_Month,
	count(*) as Total_Customers,

	--Retention
	sum(Retained) as Retained_Customers,
	cast(
		 sum(Retained) * 100.0 / nullif(count(*),0) as decimal(6,2)) as Retention_Rate,

	--Cancellation
	sum(Cancelled_Customers) as Cancelled_Customers,
	cast(
		 sum(Cancelled_Customers) * 100.0 / nullif(count(*),0) as decimal(6,2)) as Cancellation_Rate
into final_analysis_table
from customer_behavior_table
where First_Month < '2011-02-01'
group by Product_Group,
		 First_Month
having count(*) > 30
order by First_Month,
		 Product_Group;

---------------------------------------------------------
