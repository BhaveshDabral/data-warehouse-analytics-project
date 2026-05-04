--final ultimate query
create or replace procedure silver.load_silver()
language plpgsql
as $$ 
DECLARE 
	start_time timestamp;
	end_time timestamp;
	step_start timestamp;
	step_end  timestamp;
begin  
	start_time := now();
	RAISE NOTICE 'Starting Silver Layer Load'; 
	step_start := now();
	RAISE NOTICE 'Truncating silver.crm_cust_info';
	truncate silver.crm_cust_info;
	RAISE NOTICE 'Inserting in silver.crm_cust_info';	
	insert into silver.crm_cust_info(
	cst_id, 
	cst_key, 
	cst_firstname, 
	cst_lastname, 
	cst_marital_status, 
	cst_gndr,
	cst_create_date)
	select
	cst_id,
	cst_key,
	trim(cst_firstname),
	trim(cst_lastname),
	CASE  WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	      WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	      ELSE 'n/a'
	END  cst_marital_status, 
	CASE  WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	      WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	      ELSE 'n/a'
	END  cst_gndr,
	cst_create_date
	from (
	select * ,
	row_number() over(partition by cst_id order by cst_create_date desc) as flag_last
	from bronze.crm_cust_info 
	where cst_id is not null)t
	where t.flag_last = 1;
	step_end:=now();
	raise notice 'Total time taken to load this crm_cust_info is % seconds',extract(epoch from (step_end-step_start));

	step_start := now();
	RAISE NOTICE 'Truncating silver.crm_prd_info'	;
	truncate  silver.crm_prd_info;
	insert into silver.crm_prd_info(
				prd_id,
				cat_id,
				prd_key,
				prd_nm,
				prd_cost,
				prd_line,
				prd_start_dt,
				prd_end_dt
	)
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
	from bronze.crm_prd_info;
	step_end:=now();
    raise notice 'Total time taken to load this crm_prd_info is % seconds',extract(epoch from (step_end-step_start));

	step_start := now();
	RAISE NOTICE 'Truncating silver.crm_sales_details';	
	TRUNCATE silver.crm_sales_details;
	INSERT INTO silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
	
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
		CASE WHEN sls_price IS NULL or sls_price <=0
			    then sls_sales/NULLIF(sls_quantity,0)
			 ELSE sls_price	
		END as sls_price
	FROM bronze.crm_sales_details;
	step_end:=now();
	raise notice 'Total time taken to load this crm_sales_details is % seconds',extract(epoch from (step_end-step_start));

	step_start := now();
	RAISE NOTICE 'Truncating silver.erp_cust_az12';	
	truncate silver.erp_cust_az12;
	INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen
	) 
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
	from bronze.erp_cust_az12;
	step_end:=now();
	raise notice 'Total time taken to load this erp_cust_az12 is % seconds',extract(epoch from (step_end-step_start));

	step_start := now();
	RAISE NOTICE 'Truncating silver.erp_loc_a101';	
	truncate silver.erp_loc_a101;
	insert into silver.erp_loc_a101(
	cid,
	cntry
	)
	select replace(cid,'-','')cid,
	case when upper(trim(cntry)) ='DE' then 'GERMANY'
		 when upper(trim(cntry)) IN('US','USA') THEN 'UNITED STATES'
		 when upper(trim(cntry)) ='' OR CNTRY IS NULL THEN 'n/a'
		 else upper(trim(cntry)) 
	 end as cntry 
	from bronze.erp_loc_a101;
	step_end:=now();
	raise notice 'Total time taken to load this erp_loc_a101 is % seconds',extract(epoch from (step_end-step_start));

	step_start := now();
	RAISE NOTICE 'Truncating silver.erp_px_cat_g1v2';	
	truncate silver.erp_px_cat_g1v2;
	insert into silver.erp_px_cat_g1v2(id,
	cat,
	subcat,
	maintenance)
	select 
	id,
	cat,
	subcat,
	maintenance
	from bronze.erp_px_cat_g1v2;
	end_time := now();
	step_end:=now();
	raise notice 'Total time taken to load this erp_px_cat_g1v2 is % seconds',extract(epoch from (step_end-step_start));

	RAISE NOTICE 'Load completed in % seconds', Extract(EPOCH from (end_time-start_time));
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;


END;
$$;

call silver.load_silver();
call bronze.load_bronze();
