/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates existing tables to ensure fresh data load
    - Loads data using PostgreSQL COPY command (bulk loading)
	- Measures execution time for each table to identify bottlenecks
    - Handles errors using exception block
    - Logs execution steps and total load time using RAISE NOTICE
-- NOTE:
-- Update file paths based on your local environment if needed.
-- This project uses relative paths assuming execution from project root.    

Usage Example:
	CALL bronze.load_bronze();
===============================================================================
*/
--Creating a stored Procedure in the schema
CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE 
    start_time TIMESTAMP; 
    end_time TIMESTAMP;
    step_start TIMESTAMP;
    step_end TIMESTAMP;  
BEGIN
    start_time := NOW();
    RAISE NOTICE 'Loading Bronze Layer';

    RAISE NOTICE 'Loading CRM Tables';

    -- crm_cust_info
    step_start := NOW();
    RAISE NOTICE 'Truncating bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;
	RAISE NOTICE 'Inserting in bronze.crm_cust_info';

    COPY bronze.crm_cust_info
    FROM 'datasets/source_crm/cust_info.csv'
    DELIMITER ','
	CSV HEADER;

    step_end := NOW();
    RAISE NOTICE 'Loaded crm_cust_info in % seconds', EXTRACT(EPOCH FROM (step_end - step_start));

    -- crm_prd_info
    step_start := NOW();
    RAISE NOTICE 'Truncating bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;
	RAISE NOTICE 'Inserting in bronze.crm_prd_info';

    COPY bronze.crm_prd_info
	FROM 'datasets/source_crm/prd_info.csv'
    DELIMITER ','
	CSV HEADER;

    step_end := NOW();
    RAISE NOTICE 'Loaded crm_prd_info in % seconds', EXTRACT(EPOCH FROM (step_end - step_start));

    -- crm_sales_details
    step_start := NOW();
    RAISE NOTICE 'Truncating bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;

	RAISE NOTICE 'Inserting in bronze.crm_sales_details';
    COPY bronze.crm_sales_details 
    FROM 'datasets/source_crm/sales_details.csv'
    DELIMITER ','
	CSV HEADER;

    step_end := NOW();
    RAISE NOTICE 'Loaded crm_sales_details in % seconds', EXTRACT(EPOCH FROM (step_end - step_start));


    RAISE NOTICE 'Loading ERP Tables';

    -- erp_cust_az12
    step_start := NOW();
    RAISE NOTICE 'Truncating bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;
	RAISE NOTICE 'Inserting in bronze.erp_cust_az12';
	
    COPY bronze.erp_cust_az12 
    FROM 'datasets/source_erp/CUST_AZ12.csv'
    DELIMITER ','
	CSV HEADER;

    step_end := NOW();
    RAISE NOTICE 'Loaded erp_cust_az12 in % seconds', EXTRACT(EPOCH FROM (step_end - step_start));

    -- erp_loc_a101
    step_start := NOW();
    RAISE NOTICE 'Truncating bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;
	RAISE NOTICE 'Inserting in bronze.erp_loc_a101';

    COPY bronze.erp_loc_a101 
    FROM 'datasets/source_erp/LOC_A101.csv'
    DELIMITER ','
	CSV HEADER;

    step_end := NOW();
    RAISE NOTICE 'Loaded erp_loc_a101 in % seconds', EXTRACT(EPOCH FROM (step_end - step_start));

    -- erp_px_cat_g1v2
    step_start := NOW();
    RAISE NOTICE 'Truncating bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	RAISE NOTICE 'Inserting in bronze.erp_px_cat_g1v2';

    COPY bronze.erp_px_cat_g1v2 
    FROM 'datasets/source_erp/PX_CAT_G1V2.csv'
    DELIMITER ','
	CSV HEADER;

    step_end := NOW();
    RAISE NOTICE 'Loaded erp_px_cat_g1v2 in % seconds', EXTRACT(EPOCH FROM (step_end - step_start));

    end_time := NOW();
    RAISE NOTICE 'Bronze Load Completed in % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred: %', SQLERRM;
END;
$$;

-- calling the stored producdure to load the data in the table 
CALL  bronze.load_bronze();
