-- combining the data of the tables
-- after combining the data check is there is any duplicate after the compining of the data
--give names that are comfertable
--  work on the order of the column
-- give a surogate key to the table
--building the dim table for products and sales
create or replace view gold.dim_customers as 
select 
	row_number() over ( order by cst_id ) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname  as last_name,
	la.cntry as country,
	ci.cst_marital_status as marital_status,
	case when ci.cst_gndr!= 'n/a' then ci.cst_gndr -- crm is the master for gender info
		 else coalesce (ca.gen,'n/a')
	end as gender,	
	ca.bdate as birthdate,
	ci.cst_create_date as create_date

from silver.crm_cust_info as  ci
left join silver.erp_cust_az12 as ca
on ci.cst_key=ca.cid
left join silver.erp_loc_a101 as la
on ci.cst_key=la.cid;


-- making the second object that is product 
create or replace view gold.dim_products as 
select 
	row_number() over(order by pn.prd_start_dt,pn.prd_key) as product_key,
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat subcategory,
	pc.maintenance,
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date
from silver.crm_prd_info as  pn 
left join silver.erp_px_cat_g1v2 as  pc
on pn.cat_id =pc.id
where prd_end_dt is null; -- filter out historic data 




--creating fact table 
CREATE or replace  VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
	pr.product_key ,
	cu.customer_key ,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details  as sd
left join gold.dim_products as pr
on sd.sls_prd_key = pr.product_number
left join gold.dim_customers as cu
on sd.sls_cust_id =cu.customer_id;



