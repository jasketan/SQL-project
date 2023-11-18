Select* from [PROJECT2].[dbo].[Credit_card_transactions]

--Query 1: Top 5 cities with highest spends and their percentage contribution of total credit card spends
WITH CitySpend AS (
    SELECT City, SUM(Amount) AS TotalAmount
    FROM [PROJECT2].[dbo].[Credit_card_transactions]
    GROUP BY City
)

SELECT TOP 5 City, TotalAmount,
    ROUND(100.0 * TotalAmount / (SELECT SUM(Amount) FROM [PROJECT2].[dbo].[Credit_card_transactions]), 2) AS PercentageContribution
FROM CitySpend
ORDER BY TotalAmount DESC
--Query 2: Highest spend month and amount spent in that month for each card type

WITH MonthlySpend AS (
    SELECT DATEPART(YEAR, Dt) AS Year, DATEPART(MONTH, Dt) AS Month, Card_Type, SUM(Amount) AS TotalAmount
    FROM [PROJECT2].[dbo].[Credit_card_transactions]
    GROUP BY Card_Type, DATEPART(YEAR, Dt), DATEPART(MONTH, Dt)
),
MaxMonthlySpend AS (
    SELECT Year, Month, Card_Type, MAX(TotalAmount) AS HighestAmount
    FROM MonthlySpend
    GROUP BY Year, Month, Card_Type
)

SELECT Year, Month, Card_Type, HighestAmount
FROM MaxMonthlySpend
--Query 3: Transaction details for each card type reaching a cumulative total spend of 1000000

SELECT *
FROM (
    SELECT *, SUM(Amount) OVER(PARTITION BY Card_Type ORDER BY Dt) AS RunningTotal
    FROM [PROJECT2].[dbo].[Credit_card_transactions]
) AS SubQuery
WHERE RunningTotal >= 1000000
--Query 4: City with the lowest percentage spend for gold card type

WITH GoldCitySpend AS (
    SELECT City, SUM(Amount) AS TotalAmount
    FROM [PROJECT2].[dbo].[Credit_card_transactions]
    WHERE Card_Type = 'Gold'
    GROUP BY City
)

SELECT TOP 1 City,
    ROUND(100.0 * TotalAmount / (SELECT SUM(Amount) FROM [PROJECT2].[dbo].[Credit_card_transactions] WHERE Card_Type = 'Gold'), 2) AS PercentageSpend
FROM GoldCitySpend
ORDER BY TotalAmount ASC
--Query 5: City, highest_expense_type, lowest_expense_type

SELECT City, 
    MAX(Exp_Type) AS highest_expense_type, 
    MIN(Exp_Type) AS lowest_expense_type
FROM [PROJECT2].[dbo].[Credit_card_transactions]
GROUP BY City
--Query 6: Percentage contribution of spends by females for each expense type

SELECT Exp_Type,
    ROUND(100.0 * SUM(CASE WHEN Gender = 'F' THEN Amount ELSE 0 END) / SUM(Amount), 2) AS FemaleContribution
FROM [PROJECT2].[dbo].[Credit_card_transactions]
GROUP BY Exp_Type
--Query 7: Card and expense type combination with the highest month-over-month growth in Jan-2014

WITH MonthlySpend AS (
    SELECT Card_Type, Exp_Type, DATEPART(MONTH, Dt) AS Month, SUM(Amount) AS TotalAmount
    FROM [PROJECT2].[dbo].[Credit_card_transactions]
    WHERE DATEPART(YEAR, Dt) = 2014 AND DATEPART(MONTH, Dt) = 1
    GROUP BY Card_Type, Exp_Type, DATEPART(MONTH, Dt)
),
Growth AS (
    SELECT Card_Type, Exp_Type, TotalAmount,
        LAG(TotalAmount) OVER(PARTITION BY Card_Type, Exp_Type ORDER BY Month) AS PrevMonthAmount
    FROM MonthlySpend
)

SELECT TOP 1 WITH TIES Card_Type, Exp_Type, 
    ROUND(100.0 * (TotalAmount - PrevMonthAmount) / PrevMonthAmount, 2) AS MonthOverMonthGrowth
FROM Growth
ORDER BY MonthOverMonthGrowth DESC
--Query 8: City with the highest total spend-to-total number of transactions ratio during weekends

WITH WeekendSpend AS (
    SELECT City, 
        SUM(Amount) / COUNT(*) AS SpendToTransactionRatio
    FROM [PROJECT2].[dbo].[Credit_card_transactions]
    WHERE DATEPART(WEEKDAY, Dt) IN (1, 7) -- Assuming 1: Sunday, 7: Saturday
    GROUP BY City
)

SELECT TOP 1 City, SpendToTransactionRatio
FROM WeekendSpend
ORDER BY SpendToTransactionRatio DESC
--Query 9: City taking the least number of days to reach the 500th transaction after the first transaction in that city

WITH RankedTransactions AS (
    SELECT *, 
        ROW_NUMBER() OVER(PARTITION BY City ORDER BY Dt) AS TransactionRank
    FROM [PROJECT2].[dbo].[Credit_card_transactions]
),
City500thTransaction AS (
    SELECT City, Dt
    FROM RankedTransactions
    WHERE TransactionRank = 500
),
FirstTransaction AS (
    SELECT City, Dt
    FROM RankedTransactions
    WHERE TransactionRank = 1
)

SELECT TOP 1 City, FirstTransaction.Dt AS First_Transaction_Date, City500thTransaction.Dt AS Transaction_500_Date,
    DATEDIFF(DAY, FirstTransaction.Dt, City500thTransaction.Dt) AS DaysTaken
FROM City500thTransaction
INNER JOIN FirstTransaction ON City500thTransaction.City = FirstTransaction.City
ORDER BY DaysTaken ASC