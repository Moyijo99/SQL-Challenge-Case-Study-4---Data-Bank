-- C. Data Allocation Challenge

-- 1. running customer balance column that includes the impact each transaction

SELECT customer_id,
txn_date,
txn_type,
txn_amount,
SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
         WHEN txn_type = 'withdrawal' THEN -txn_amount
         WHEN txn_type = 'purchase' THEN -txn_amount
         ELSE 0 END
) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM data_bank.customer_transactions;


-- 2. customer balance at the end of each month

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


-- 3. minimum, average and maximum values of the running balance for each customer

WITH running_balance AS (
    SELECT  customer_id,
            txn_date,
            txn_type,
            txn_amount,
            SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
                    WHEN txn_type = 'withdrawal' THEN -txn_amount
                    WHEN txn_type = 'purchase' THEN -txn_amount
                    ELSE 0 END
            ) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
    FROM data_bank.customer_transactions
)

SELECT customer_id,
       ROUND(MIN(running_balance)) AS min_running_balance,
       ROUND(AVG(running_balance)) AS avg_running_balance,
       ROUND(MAX(running_balance)) AS max_running_balance
FROM running_balance
GROUP BY customer_id;
       

-- option 1 would require the use of most data (5868 lines)
-- option2 would require the second most amount of data (1720 lines)
-- option 3 would require the least amount of data (500 lines)