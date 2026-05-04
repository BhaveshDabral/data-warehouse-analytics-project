/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Usage Example:
    CALL Silver.load_silver;
===============================================================================
*/
CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$ 
DECLARE 
    start_time TIMESTAMP;
    end_time   TIMESTAMP;
    step_start TIMESTAMP;
    step_end   TIMESTAMP;
BEGIN  
    start_time := NOW();
    RAISE NOTICE 'STARTING SILVER LAYER LOAD'; 

    -- =========================
    -- CRM CUSTOMER INFO
    -- =========================
    step_start := NOW();
    RAISE NOTICE 'TRUNCATING SILVER.CRM_CUST_INFO';
    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE 'INSERTING INTO SILVER.CRM_CUST_INFO';	
    INSERT INTO silver.crm_cust_info (
        cst_id, 
        cst_key, 
        cst_firstname, 
        cst_lastname, 
        cst_marital_status, 
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE  
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END AS cst_marital_status, 
        CASE  
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END AS cst_gndr,
        cst_create_date
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info 
        WHERE cst_id IS NOT NULL
    ) t
    WHERE t.flag_last = 1;

    step_end := NOW();
    RAISE NOTICE 'CRM_CUST_INFO LOADED IN % SECONDS', EXTRACT(EPOCH FROM (step_end - step_start));

    -- =========================
    -- CRM PRODUCT INFO
    -- =========================
    step_start := NOW();
    RAISE NOTICE 'TRUNCATING SILVER.CRM_PRD_INFO';
    TRUNCATE TABLE silver.crm_prd_info;

    RAISE NOTICE 'INSERTING INTO SILVER.CRM_PRD_INFO';
    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT  
        prd_id,
        REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
        SUBSTRING(prd_key,7) AS prd_key,
        prd_nm,
        COALESCE(prd_cost,0) AS prd_cost,
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road' 
            WHEN 'S' THEN 'Other Sales' 
            WHEN 'T' THEN 'Touring' 
            ELSE 'n/a'
        END AS prd_line,   
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        CAST(
            LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day'
            AS DATE
        ) AS prd_end_dt
    FROM bronze.crm_prd_info;

    step_end := NOW();
    RAISE NOTICE 'CRM_PRD_INFO LOADED IN % SECONDS', EXTRACT(EPOCH FROM (step_end - step_start));

    -- =========================
    -- CRM SALES DETAILS
    -- =========================
    step_start := NOW();
    RAISE NOTICE 'TRUNCATING SILVER.CRM_SALES_DETAILS';
    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE 'INSERTING INTO SILVER.CRM_SALES_DETAILS';
    INSERT INTO silver.crm_sales_details (
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
            WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL 
            ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
        END,
        CASE 
            WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL 
            ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
        END,
        CASE 
            WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL 
            ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
        END,
        CASE 
            WHEN sls_sales IS NULL OR sls_sales <= 0 THEN sls_quantity * sls_price
            ELSE sls_sales
        END,
        sls_quantity,
        CASE 
            WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity,0)
            ELSE sls_price
        END
    FROM bronze.crm_sales_details;

    step_end := NOW();
    RAISE NOTICE 'CRM_SALES_DETAILS LOADED IN % SECONDS', EXTRACT(EPOCH FROM (step_end - step_start));

    -- =========================
    -- ERP CUSTOMER
    -- =========================
    step_start := NOW();
    RAISE NOTICE 'TRUNCATING SILVER.ERP_CUST_AZ12';
    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE 'INSERTING INTO SILVER.ERP_CUST_AZ12';
    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT 
        CASE 
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4)
            ELSE cid
        END,
        CASE 
            WHEN bdate > CURRENT_DATE THEN NULL
            ELSE bdate
        END,
        CASE 
            WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
            WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
            ELSE 'n/a'
        END
    FROM bronze.erp_cust_az12;

    step_end := NOW();
    RAISE NOTICE 'ERP_CUST_AZ12 LOADED IN % SECONDS', EXTRACT(EPOCH FROM (step_end - step_start));

    -- =========================
    -- ERP LOCATION
    -- =========================
    step_start := NOW();
    RAISE NOTICE 'TRUNCATING SILVER.ERP_LOC_A101';
    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE 'INSERTING INTO SILVER.ERP_LOC_A101';
    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT 
        REPLACE(cid,'-',''),
        CASE 
            WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'GERMANY'
            WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'UNITED STATES'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE UPPER(TRIM(cntry))
        END
    FROM bronze.erp_loc_a101;

    step_end := NOW();
    RAISE NOTICE 'ERP_LOC_A101 LOADED IN % SECONDS', EXTRACT(EPOCH FROM (step_end - step_start));

    -- =========================
    -- ERP PRODUCT CATEGORY
    -- =========================
    step_start := NOW();
    RAISE NOTICE 'TRUNCATING SILVER.ERP_PX_CAT_G1V2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE 'INSERTING INTO SILVER.ERP_PX_CAT_G1V2';
    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;

    step_end := NOW();
    RAISE NOTICE 'ERP_PX_CAT_G1V2 LOADED IN % SECONDS', EXTRACT(EPOCH FROM (step_end - step_start));

    end_time := NOW();
    RAISE NOTICE 'SILVER LOAD COMPLETED IN % SECONDS', EXTRACT(EPOCH FROM (end_time - start_time));

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: %', SQLERRM;
END;
$$;

CALL silver.load_silver();