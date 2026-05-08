# Data Warehouse Analytics Project

## 📖 Overview
Built an end-to-end Data Warehouse using PostgreSQL with ETL pipelines (Bronze → Silver → Gold), enabling business analytics and reporting through advanced SQL.

This project demonstrates the design and implementation of a layered data architecture to ingest, clean, transform, and analyze data.

---

## 🏗️ Architecture

The project follows a multi-layered architecture:

- **Bronze Layer** → Raw data ingestion from CSV files  
- **Silver Layer** → Data cleaning, transformation, and standardization  
- **Gold Layer** → Business-ready data models (Star Schema)  

---

## 🛠️ Tech Stack

- PostgreSQL  
- SQL (Window Functions, CTEs, Aggregations)  
- ETL Pipelines  
- Data Modeling (Star Schema)  

---

## 🔄 ETL Process

- Extracted data from multiple CSV sources (CRM & ERP)  
- Loaded raw data into Bronze tables  
- Transformed and cleaned data in Silver layer  
- Built analytical views in Gold layer  

---

## 📊 Key Features

- End-to-end ETL pipeline using SQL  
- Data cleaning and transformation logic  
- Star schema implementation (Fact & Dimension tables)  
- Advanced SQL analytics (ranking, trends, segmentation)  
- Business reports (Customer & Product insights)  

---

## 📈 Analysis & Insights

- Customer segmentation (VIP, Regular, New)  
- Product performance analysis  
- Sales trends over time  
- Revenue distribution across categories  

---

## 📁 Project Structure

```bash
data-warehouse-analytics-project/
│
├── datasets/                     
│
├── scripts/
│   │
│   ├── bronze_layer/            
│   │   ├── ddl_bronze_layer.sql
│   │   └── procedure_bronze_layer.sql
│   │
│   ├── silver_layer/             
│   │   ├── ddl_silver_layer.sql
│   │   ├── procedure_silver_layer.sql
│   │   └── data_quality_checks.sql
│   │
│   ├── gold_layer/              
│   │   ├── ddl_gold_layer.sql
│   │   ├── customer_report.sql
│   │   ├── product_report.sql
│   │   ├── eda_basic.sql
│   │   └── eda_advanced.sql
│
├── init_database.sql            
│
├── README.md                    
│
└── LICENSE
