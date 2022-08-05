/* Q19 */
CREATE VIEW vYearGroupSold
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
	Pvt.*
FROM (
	SELECT StockGroupName, YearGroup, Quantity
	FROM Combined) Ready
PIVOT (
	SUM(Quantity)
	FOR StockGroupName IN (
		[Novelty Items], [Clothing], 
		[Mugs], [T-Shirts],
		[Airline Novelties], [Computing Novelties], 
		[USB Novelties], [Furry Footwear], 
		[Toys], [Packaging Materials]
		)
	) AS Pvt;
