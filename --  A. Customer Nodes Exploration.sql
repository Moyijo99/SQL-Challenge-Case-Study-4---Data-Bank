-- SECTION A. Customer Nodes Exploration


--How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM data_bank.customer_nodes;

--What is the number of nodes per region?

SELECT region_name, COUNT(node_id) AS nodes 
FROM data_bank.customer_nodes AS C
INNER JOIN data_bank.regions AS R on C.region_id = R.region_id
GROUP BY region_name;

--How many customers are allocated to each region?

SELECT region_name, COUNT(DISTINCT customer_id) AS customers
FROM data_bank.customer_nodes AS C
INNER JOIN data_bank.regions AS R on C.region_id = R.region_id
GROUP BY region_name;

--How many days on average are customers reallocated to a different node?

WITH DAYS_DIFFERENCE AS (
    SELECT 
    customer_id,
    node_id,
    (end_date - start_date) as days_difference
    FROM data_bank.customer_nodes
    WHERE end_date <> '9999-12-31'
)
SELECT 
ROUND(AVG(days_difference)) as average_days_in_node
FROM DAYS_DIFFERENCE;

--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH DAYS_DIFFERENCE AS (
    SELECT 
    region_id,
    customer_id,
    node_id,
    (end_date - start_date) as days_difference
    FROM data_bank.customer_nodes
    WHERE end_date <> '9999-12-31'
)
SELECT 
region_id,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_difference) AS median_days,
PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY days_difference) AS percentile_80,
PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_difference) AS percentile_95
FROM DAYS_DIFFERENCE
GROUP BY region_id;

