--B. Customer Transactions

--What is the unique count and total amount for each transaction type?

SELECT 
    DISTINCT txn_type,
    COUNT(txn_type) AS unique_count,
    SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
GROUP BY txn_type;

--What is the average total historical deposit counts and amounts for all customers?

WITH historical_deposit AS (
    SELECT customer_id,
    txn_type,
    COUNT (*) AS deposit_count,
    SUM(txn_amount) AS deposit_amount
    FROM data_bank.customer_transactions
    GROUP BY customer_id, txn_type
    ORDER BY customer_id
)

SELECT 
    txn_type,
    ROUND(AVG(deposit_count)) AS average_count,
    ROUND(AVG(deposit_amount)) AS average_deposit
FROM historical_deposit
WHERE txn_type = 'deposit'
GROUP BY txn_type;

--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH transactions AS (
    SELECT
    TO_CHAR(txn_date, 'Month') AS month_name,
    customer_id,
    SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) as deposits,
    SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) AS withdrawals_and_purchases
    FROM data_bank.customer_transactions
    GROUP BY customer_id, TO_CHAR(txn_date, 'Month')
    HAVING SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) > 1
    AND SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) > 1
)
SELECT
month_name,
COUNT(customer_id) AS customers
FROM transactions
GROUP BY month_name;

--What is the closing balance for each customer at the end of the month?

SELECT 
    customer_id,
    TO_CHAR(txn_date, 'Month') AS month_name,
    SUM(
        CASE WHEN txn_type = 'deposit' THEN txn_amount
             WHEN txn_type = 'withdrawal' THEN -txn_amount
             WHEN txn_type = 'purchase' THEN -txn_amount
    ELSE 0 END) AS closing_balance
FROM data_bank.customer_transactions
GROUP BY customer_id, 
TO_CHAR(txn_date, 'Month')
ORDER BY customer_id, month_name;

--What is the percentage of customers who increase their closing balance by more than 5%?

-- CTE 1: Monthly transactions of each customer
WITH monthly_transactions AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', txn_date) AS end_date,
        SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount ELSE txn_amount END) AS transactions
    FROM
        data_bank.customer_transactions
    GROUP BY
        customer_id, DATE_TRUNC('month', txn_date)
) 
-- CTE 2: Calculate the closing balance for each customer for each month
, closing_balances AS (
    SELECT
        customer_id,
        end_date,
        COALESCE(SUM(transactions) OVER (PARTITION BY customer_id ORDER BY end_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS closing_balance
    FROM
        monthly_transactions
)
-- CTE 3: Calculate the percentage increase in closing balance for each customer for each month
, pct_increase AS (
    SELECT
        customer_id,
        end_date,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date) AS prev_closing_balance,
        100 * (closing_balance - LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date)) / NULLIF(LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date), 0) AS pct_increase
    FROM
        closing_balances
)
-- Calculate the percentage of customers whose closing balance increased 5% compared to the previous month
,CustomerCount AS (
    SELECT COUNT(DISTINCT customer_id) AS total_customers
    FROM pct_increase
)
SELECT
    CAST(100.0 * COUNT(DISTINCT CASE WHEN pct_increase > 5 THEN customer_id END) / MAX(total_customers) AS FLOAT) AS pct_customers
FROM
    pct_increase
CROSS JOIN
    CustomerCount;

