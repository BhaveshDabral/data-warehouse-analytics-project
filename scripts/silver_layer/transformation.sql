--working of the crm_cust_info
--checking the data quality
select * from bronze.crm_cust_info

--check for the duplicate or null value in pkey
select cst_id,count(*)
from bronze.crm_cust_info
group by cst_id
having count(cst_id)>1 or cst_id is null;

-- check for the unwanted string 
select * from bronze.crm_cust_info
where trim(cst_firstname)!= cst_firstname

-- checking the distinct value in in column
select distinct(cst_gndr)
from bronze.crm_cust_info

----------------
-- working on the second table
select * from bronze.crm_prd_info

select 	prd_id,
replace(substring(prd_key,1,5),'-','_') as cat_id,
substring(prd_key,7) as prd_key,
prd_nm,
coalesce(prd_cost,0) as prd_cost,
case upper(trim(prd_line))
   when 'M' then 'Mountain'
   when 'R' then 'Road' 
   when 'S' then 'Other Sales' 
   when 'T' then 'Touring' 
   else 'n/a'
end as prd_line,   
cast(prd_start_dt as date) as prd_start_dt,
cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)- INTERVAL '1 day' as date) as prd_end_dt
from bronze.crm_prd_info

--checking duplicate and null in pkey
select prd_id,count(*)
from bronze.crm_prd_info
group by prd_id
having count(*) >1 or prd_id is null 


--chhecking for unwanted spaces
select *  from bronze.crm_prd_info
where prd_key!=trim(prd_key)

--chekcing or null or neagtive number
select prd_cost 
from bronze.crm_prd_info 
where prd_cost is null or prd_cost <=0

--checking for the data standardiztion and 
select distinct prd_line 
from bronze.crm_prd_info

--checking for the invalid date orders
select *  from bronze.crm_prd_info 
where prd_end_dt<prd_start_dt


--working on crm_sales_details

SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    CASE 
        WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::text) != 8 THEN NULL 
        ELSE TO_DATE(sls_order_dt::text, 'YYYYMMDD')
    END AS sls_order_dt,

    CASE 
        WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::text) != 8 THEN NULL 
        ELSE TO_DATE(sls_ship_dt::text, 'YYYYMMDD')
    END AS sls_ship_dt,	 

    CASE 
        WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::text) != 8 THEN NULL 
        ELSE TO_DATE(sls_due_dt::text, 'YYYYMMDD')
    END AS sls_due_dt,	 
	 
	case when sls_sales is null or sls_sales <=0 
	        then  sls_quantity * sls_price
	     else sls_sales
    end as sls_sales,
    sls_quantity,	
	case when sls_price <=0 or sls_price is null
             then sls_sales/nullif(sls_quantity,0)
	     else sls_price
    end as sls_price

	case when sls_sales is null or sls_sales <=0 or sls_sales!= sls_quantity * sls_price

FROM bronze.crm_sales_details;

--check for unwanted space
select * from bronze.crm_sales_details
where trim(sls_ord_num)!= sls_ord_num

-- checking that primcary key match with primcary key with other table 
select * from bronze.crm_sales_details
where sls_cust_id not in (select cst_id from silver.crm_cust_info)

--check for invalid dates
select sls_order_dt
from bronze.crm_sales_details
where sls_order_dt <=0

select * from bronze.crm_sales_details
where sls_order_dt>sls_ship_dt or sls_order_dt>sls_due_dt or sls_due_dt <sls_ship_dt

--aplying businnes rule and checking data consitency 
select 

	
	case when sls_sales is null or sls_sales <=0 
	        then  sls_quantity * sls_price
	     else sls_sales
    end as sls_sales,
    sls_quantity,	
	case when sls_price <=0 or sls_price is null
             then sls_sales/nullif(sls_quantity,0)
	     else sls_price
    end as sls_price
	
from bronze.crm_sales_details 
where sls_sales!= sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null 
or sls_quantity <=0 or sls_sales <=0 or sls_price<=0

select 
    sls_sales,
    sls_quantity,
    sls_price
	
from silver.crm_sales_details 
where sls_sales!= sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null 
or sls_quantity <=0 or sls_sales <=0 or sls_price<=0

-- WORKING ON THE  erp schema
select 
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2


select id from bronze.erp_px_cat_g1v2
where subcat != trim(subcat)

select distinct maintenance from bronze.erp_px_cat_g1v2



select 
case when cid like 'NAS%' then substring(cid,4)
     else cid
end cid,	 
	 
case when bdate>current_date then null
     else bdate
end bdate,

case when upper(trim(gen))in ('M','MALE') then 'Male'
     when upper(trim(gen))in ('F','FEMALE') then 'Female'
     else 'n/a'
end gen	 	 
from bronze.erp_cust_az12

--checking for inconsisitent date 
select distinct gen  from bronze.erp_cust_az12

-- check for unwanted char in pkey
select * from bronze.erp_cust_az12 
where cid like '%AW00011000%'

--indetiy out of range dates 
select distinct bdate
from bronze.erp_cust_az12 
where bdate>current_date












