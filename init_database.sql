
-- Run this part while connected to 'postgres' database

-- Drop database if it exists
DROP DATABASE IF EXISTS datawarehouse;

-- Create fresh database
CREATE DATABASE datawarehouse;


-- Switch connection to 'datawarehouse' before running below
-- In psql: \c datawarehouse
-- In pgAdmin: open new query tool connected to datawarehouse


/*
==============================================
Schema Creation
==============================================
*/

-- Create schemas
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
