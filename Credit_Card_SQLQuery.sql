CREATE DATABASE credit_card

USE credit_card
SELECT * FROM DBO.[credit_card_transcations]

/*
solve below questions
1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
*/
SELECT TOP 5
	CITY, SUM(AMOUNT) AS SPENDS, 
	ROUND( 100*SUM(AMOUNT) / (SELECT SUM(AMOUNT) FROM dbo.[credit_card_transcations]), 2) AS PERCENT_CONTRIBUTION
FROM dbo.[credit_card_transcations] 
GROUP BY CITY
ORDER BY SPENDS DESC


/*
2- write a query to print highest spend month and amount spent in that month for each card type
*/
EXEC sp_help credit_card_transcations

WITH monthly_spend AS (
    SELECT
            card_type,
            FORMAT(transaction_date, 'yyyy-MM') AS spend_month,
            SUM(amount) AS total_spend
        FROM dbo.credit_card_transcations
        GROUP BY
            card_type,
            FORMAT(transaction_date, 'yyyy-MM')
),
RankedSpends AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY card_type ORDER BY total_spend DESC) AS rn
    FROM monthly_spend
)
SELECT
    card_type,
    spend_month,
    total_spend
FROM RankedSpends
WHERE rn = 1
ORDER BY total_spend DESC

/*
3- write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
*/

WITH cumulative AS (
    SELECT *,
        SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date, transaction_id ROWS UNBOUNDED PRECEDING) AS running_total
    FROM credit_card_transcations
),
threshold AS (
    SELECT *
    FROM cumulative
    WHERE running_total >= 1000000
)
SELECT *
FROM (SELECT *,
        ROW_NUMBER() OVER (PARTITION BY card_type ORDER BY transaction_date, transaction_id) AS rn
    FROM threshold) AS final
WHERE rn = 1



/*
4- write a query to find city which had lowest percentage spend for gold card type
*/

SELECT city,
       ROUND(100.0 * SUM(amount) / 
             (SELECT SUM(amount) FROM credit_card_transcations WHERE card_type = 'Gold'), 2) AS percent_spend
FROM credit_card_transcations
WHERE card_type = 'Gold'
GROUP BY city
ORDER BY percent_spend ASC


/*
5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
*/

WITH expense AS(
    SELECT city, exp_type, 
        SUM(amount) as spend,
        RANK() OVER (PARTITION BY city ORDER BY SUM(amount) DESC) AS highest,
        RANK() OVER (PARTITION BY city ORDER BY SUM(amount) ASC) AS lowest
    FROM credit_card_transcations
    GROUP BY city, exp_type
)
SELECT
    city,
    MAX(CASE WHEN highest = 1 THEN exp_type END) AS highest_expense_type,
    MAX(CASE WHEN lowest = 1 THEN exp_type END) AS lowest_expense_type
FROM expense
GROUP BY city
ORDER BY city


/*
6- write a query to find percentage contribution of spends by females for each expense type
*/

SELECT exp_type,
       ROUND(
        100.0 * SUM(CASE WHEN gender = 'F' THEN amount ELSE 0 END) / SUM(amount),2) AS female_percent_spend
FROM credit_card_transcations
GROUP BY exp_type
ORDER BY female_percent_spend DESC




/*
7- which card and expense type combination saw highest month over month growth in Jan-2014
*/

WITH MonthlySums AS (
    SELECT
        card_type,
        exp_type,
        FORMAT(transaction_date, 'yyyy-MM') AS txn_month,
        SUM(amount) AS total_spend
    FROM credit_card_transcations
    GROUP BY card_type, exp_type, FORMAT(transaction_date, 'yyyy-MM')
)
SELECT TOP 1
    curr.card_type,
    curr.exp_type,
    curr.txn_month,
    curr.total_spend,
    prev.total_spend AS prev_month_spend,
    ROUND(100.0 * (curr.total_spend - prev.total_spend) / NULLIF(prev.total_spend, 0), 2) AS percent_growth
FROM MonthlySums curr
JOIN MonthlySums prev
    ON curr.card_type = prev.card_type
    AND curr.exp_type = prev.exp_type
    AND curr.txn_month = '2014-01'
    AND prev.txn_month = '2013-12'
ORDER BY percent_growth DESC


/*
8- during weekends which city has highest total spend to total no of transcations ratio 
*/

SELECT TOP 1
    city,
    ROUND(SUM(amount) * 1.0 / COUNT(*), 2) AS spend_per_transaction
FROM credit_card_transcations
WHERE DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday')
GROUP BY city
ORDER BY spend_per_transaction DESC


/*
9- which city took least number of days to reach its 500th transaction after the first transaction in that city
*/

WITH RankedTxns AS (
    SELECT 
        city,
        transaction_date,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date) AS txn_rank
    FROM credit_card_transcations
),
City500 AS (
    SELECT city
    FROM RankedTxns
    WHERE txn_rank = 500
)
SELECT TOP 1
    r.city,
    DATEDIFF(DAY,
             MIN(CASE WHEN r.txn_rank = 1 THEN r.transaction_date END),
             MIN(CASE WHEN r.txn_rank = 500 THEN r.transaction_date END)) AS days_to_500
FROM RankedTxns r
JOIN City500 c ON r.city = c.city
WHERE r.txn_rank IN (1, 500)
GROUP BY r.city
ORDER BY days_to_500 


