
CREATE VIEW gold.dim_products AS
SELECT
ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm As product_name,
pn.cat_id As category_id,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance,
pn.prd_cost As cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL

SELECT * FROM gold.dim_products


INSERT INTO silver.crm_sales_details
(
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
        WHEN sls_order_dt = 0 THEN NULL
        WHEN sls_order_dt NOT BETWEEN 10000000 AND 99999999 THEN NULL
        ELSE TRY_CONVERT(DATE, CAST(sls_order_dt AS VARCHAR(8)), 112)
    END AS sls_order_dt,

    CASE 
        WHEN sls_ship_dt = 0 THEN NULL
        WHEN sls_ship_dt NOT BETWEEN 10000000 AND 99999999 THEN NULL
        ELSE TRY_CONVERT(DATE, CAST(sls_ship_dt AS VARCHAR(8)), 112)
    END AS sls_ship_dt,

    CASE 
        WHEN sls_due_dt = 0 THEN NULL
        WHEN sls_due_dt NOT BETWEEN 10000000 AND 99999999 THEN NULL
        ELSE TRY_CONVERT(DATE, CAST(sls_due_dt AS VARCHAR(8)), 112)
    END AS sls_due_dt,

    sls_sales,
    sls_quantity,
    sls_price

FROM bronze.crm_sales_details;


SELECT *
FROM bronze.crm_sales_details
WHERE TRY_CONVERT(DATE, CAST(sls_order_dt AS VARCHAR(8)), 112) IS NULL
   OR TRY_CONVERT(DATE, CAST(sls_ship_dt AS VARCHAR(8)), 112) IS NULL
   OR TRY_CONVERT(DATE, CAST(sls_due_dt AS VARCHAR(8)), 112) IS NULL;



CREATE VIEW gold.fact_sales AS
SELECT
sd.sls_ord_num AS order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customer cu
ON sd.sls_cust_id = cu.customer_id


SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON c.customer_key = f.customer_key
WHERE c.customer_key IS NULL

SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p 
ON p.product_key = f.product_key
WHERE p.product_key IS NULL
