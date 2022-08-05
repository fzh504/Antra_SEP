/* Q18 */
CREATE VIEW vGroupYearSold
AS
WITH Main AS (
	SELECT 
		StockItemID, Quantity, YEAR(TransactionOccurredWhen) YearGroup
	FROM Warehouse.StockItemTransactions
	WHERE 
		Quantity < 0
		AND
		YEAR(TransactionOccurredWhen) >= '2013'
		AND
		YEAR(TransactionOccurredWhen) <= '2018'
), Sub AS (
	SELECT wsisg.*, wsg.StockGroupName
	FROM Warehouse.StockItemStockGroups wsisg
	LEFT JOIN Warehouse.StockGroups wsg
	ON wsisg.StockGroupID = wsg.StockGroupID
), Combined AS (
	SELECT m.*, s.StockGroupName
	FROM Main m
	LEFT JOIN Sub s
	ON m.StockItemID = s.StockItemID
)
SELECT 
	StockGroupName, [2013] AS '2013', 
	[2014] AS '2014', [2015] AS '2015',
	[2016] AS '2016', [2017] AS '2017'
FROM (
	SELECT StockGroupName, YearGroup, Quantity
	FROM Combined) Ready
PIVOT (
	SUM(Quantity)
	FOR YearGroup IN ([2013], [2014], [2015], [2016], [2017]) ) AS Pvt;
