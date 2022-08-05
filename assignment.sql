/* Q1 */
SELECT 
	ap.FullName, ap.PhoneNumber, ap.FaxNumber, 
	COALESCE(ps.PhoneNumber, sc.PhoneNumber) CompanyPhoneNumber, COALESCE(ps.FaxNumber, sc.FaxNumber) CompanyFaxNumber
FROM 
	Application.People ap
LEFT JOIN 
	Purchasing.Suppliers ps
ON 
	ap.PersonId = ps.PrimaryContactPersonID 
	OR 
	ap.PersonId = ps.AlternateContactPersonID
LEFT JOIN 
	Sales.Customers sc
ON 
	ap.PersonId = sc.PrimaryContactPersonID 
	OR 
	ap.PersonId = sc.AlternateContactPersonID;


/* Q2 */
WITH FirstExtract AS (
	SELECT sc.CustomerID, sc.CustomerName, SUBSTRING(WebsiteURL, 12, LEN(WebsiteURL)) CustomerWebsiteDomain, sc.PhoneNumber, sc.PrimaryContactPersonID, ap.PersonID
	FROM Sales.Customers sc
	INNER JOIN Application.People ap
	ON sc.PrimaryContactPersonID = ap.PersonID
	WHERE sc.PhoneNumber = ap.PhoneNumber
)
SELECT SUBSTRING(CustomerWebsiteDomain, 1, CHARINDEX('.', CustomerWebsiteDomain) - 1) CustomerCompany, CustomerID, CustomerName
FROM FirstExtract;


/* Q3 */
SELECT CustomerID, MAX(TransactionDate) LastSaleTransaction
FROM Sales.CustomerTransactions
GROUP BY CustomerID
HAVING MAX(TransactionDate) < '2016';


/* Q4 */
SELECT StockItemID, SUM(Quantity) AS TotalQuantity
FROM Warehouse.StockItemTransactions
WHERE TransactionOccurredWhen >= '2013' AND TransactionOccurredWhen < '2014' AND PurchaseOrderID IS NOT NULL
GROUP BY StockItemID;


/* Q5 */
SELECT DISTINCT StockItemID
FROM Purchasing.PurchaseOrderLines
WHERE LEN(Description) >= 10;


/* Q6 */
WITH FilterJoined AS (
	SELECT wsit.CustomerID, sc.DeliveryCityID
	FROM Warehouse.StockItemTransactions wsit
	JOIN Sales.Customers sc
	ON wsit.CustomerID = sc.CustomerID
	WHERE wsit.TransactionOccurredWhen >= '2014' AND wsit.TransactionOccurredWhen < '2015'
)
SELECT *
FROM FilterJoined
WHERE FilterJoined.DeliveryCityID NOT IN (
	SELECT ac.CityID
	FROM Application.Cities ac
	JOIN Application.StateProvinces asp
	ON ac.StateProvinceID = asp.StateProvinceID
	WHERE StateProvinceName = 'Alabama' OR StateProvinceName = 'Georgia'
);


/* Q7 */
WITH CityState AS (
	SELECT ac.CityID, asp.StateProvinceName
	FROM Application.Cities ac
	JOIN Application.StateProvinces asp
	ON ac.StateProvinceID = asp.StateProvinceID
), CustomerState AS (
	SELECT sc.CustomerID, cs.StateProvinceName
	FROM Sales.Customers sc
	JOIN CityState cs
	ON sc.DeliveryCityID = cs.CityID
), OrderDelivery AS (
	SELECT so.OrderID, so.CustomerID, so.OrderDate, CONVERT(DATE, si.ConfirmedDeliveryTime) ConfirmedDeliveryDate
	FROM Sales.Orders so
	LEFT JOIN Sales.Invoices si
	ON so.OrderID = si.OrderID
), StateDays AS (
	SELECT cs.StateProvinceName, DATEDIFF(DAY, od.OrderDate, od.ConfirmedDeliveryDate) ProcessingDays
	FROM OrderDelivery od
	LEFT JOIN CustomerState cs
	ON od.CustomerId = cs.CustomerID
)
SELECT StateProvinceName, AVG(ProcessingDays) AvgProcessingDays
FROM StateDays
GROUP BY StateProvinceName;


/* Q8 */
WITH CityState AS (
	SELECT ac.CityID, asp.StateProvinceName
	FROM Application.Cities ac
	JOIN Application.StateProvinces asp
	ON ac.StateProvinceID = asp.StateProvinceID
), CustomerState AS (
	SELECT sc.CustomerID, cs.StateProvinceName
	FROM Sales.Customers sc
	JOIN CityState cs
	ON sc.DeliveryCityID = cs.CityID
), OrderDelivery AS (
	SELECT so.OrderID, so.CustomerID, so.OrderDate, CONVERT(DATE, si.ConfirmedDeliveryTime) ConfirmedDeliveryDate
	FROM Sales.Orders so
	LEFT JOIN Sales.Invoices si
	ON so.OrderID = si.OrderID
), StateDays AS (
	SELECT cs.StateProvinceName, MONTH(od.OrderDate) OrderMonth, DATEDIFF(DAY, od.OrderDate, od.ConfirmedDeliveryDate) ProcessingDays
	FROM OrderDelivery od
	LEFT JOIN CustomerState cs
	ON od.CustomerId = cs.CustomerID
)
SELECT StateProvinceName, OrderMonth, AVG(ProcessingDays) AvgProcessingDays
FROM StateDays
GROUP BY StateProvinceName, OrderMonth;


/* Q9 */
WITH CteBuy AS (
	SELECT StockItemID, SUM(Quantity) TotalBuy
	FROM Warehouse.StockItemTransactions
	WHERE 
		TransactionOccurredWhen >= '2015' AND TransactionOccurredWhen < '2016'
		AND
		SupplierID IS NOT NULL
	GROUP BY StockItemID
), CteSell AS (
	SELECT StockItemID, ABS(SUM(Quantity)) TotalSell
	FROM Warehouse.StockItemTransactions
	WHERE 
		TransactionOccurredWhen >= '2015' AND TransactionOccurredWhen < '2016'
		AND
		CustomerID IS NOT NULL
	GROUP BY StockItemID
)
SELECT cb.StockItemID
FROM CteBuy cb
FULL OUTER JOIN CteSell cs
ON cb.StockItemID = cs.StockItemID
WHERE 
	TotalBuy IS NOT NULL
	AND
	TotalSell IS NOT NULL
	AND
	TotalBuy > TotalSell;


/* Q10 */
WITH CteFiltered AS (
	SELECT wst.CustomerID,  SUM(Quantity) total
	FROM Warehouse.StockItemTransactions wst
	WHERE 
		TransactionOccurredWhen >= '2016' AND TransactionOccurredWhen < '2017' 
		AND 
		CustomerID IS NOT NULL
		AND
		wst.StockItemID IN (
			SELECT StockItemID
			FROM Warehouse.StockItemStockGroups as wsisg
			WHERE wsisg.StockGroupID = (
				SELECT StockGroupID
				FROM Warehouse.StockGroups
				WHERE StockGroupName = 'Mugs'
			)
		)
	GROUP BY CustomerID
	HAVING SUM(Quantity) >= -10
)
SELECT sc.CustomerID, sc.CustomerName, sc.PhoneNumber, ap.FullName PrimaryContactPersonName
FROM CteFIltered cf
LEFT JOIN Sales.Customers sc
ON cf.CustomerID = sc.CustomerID
LEFT JOIN Application.People ap
ON sc.PrimaryContactPersonID = ap.PersonID;


/* Q11 */
SELECT CityName
FROM Application.Cities
WHERE ValidFrom > '2015-01-01';


/* Q12 */
WITH CteMain AS (
	SELECT StockItemTransactionID, StockItemID, wst.CustomerID, InvoiceID, Quantity, sc.CustomerName, sc.PrimaryContactPersonID, sc.PhoneNumber CustomerPhone, CONCAT(sc.DeliveryAddressLine2, ' ', sc.DeliveryAddressLine1) as DeliveryAddress, sc.DeliveryCityID
	FROM Warehouse.StockItemTransactions wst
	LEFT JOIN Sales.Customers sc
	ON wst.CustomerID = sc.CustomerID
	WHERE TransactionOccurredWhen BETWEEN '2014-07-01' AND '2014-07-02' AND wst.CustomerId IS NOT NULL
), CteContact AS (
	SELECT sc.CustomerID, sc.PrimaryContactPersonID, ap.FullName AS CustomerContactPersonName
	FROM Sales.Customers sc
	JOIN Application.People ap
	ON sc.PrimaryContactPersonID = ap.PersonID
), CteLocation AS (
	SELECT sc.CustomerID, sc.CustomerName, ac.CityName, asp.StateProvinceName, actry.CountryName
	FROM Sales.Customers sc
	LEFT JOIN Application.Cities ac
	ON sc.DeliveryCityID = ac.CityID
	LEFT JOIN Application.StateProvinces asp
	ON ac.StateProvinceID = asp.StateProvinceID
	LEFT JOIN Application.Countries actry
	ON asp.CountryID = actry.CountryID
)
SELECT ws.StockItemName, cm.DeliveryAddress, cl.StateProvinceName DeliveryState, cl.CityName DeliveryCity, cl.CountryName DeliveryCountry, cm.CustomerName, cc.CustomerContactPersonName, cm.CustomerPhone, ABS(cm.Quantity) Quantity
FROM CteMain cm
LEFT JOIN CteContact cc
ON cm.CustomerID = cc.CustomerID
LEFT JOIN CteLocation cl
ON cm.CustomerID = cl.CustomerID
LEFT JOIN Warehouse.StockItems ws
ON cm.StockItemID = ws.StockItemID;


/* Q13 */
WITH Joined AS (
	SELECT wsit.StockItemTransactionID, wsit.StockItemID, wsisg.StockItemStockGroupID, wsisg.StockGroupID, wsit.Quantity
	FROM Warehouse.StockItemTransactions wsit
	FULL OUTER JOIN Warehouse.StockItemStockGroups wsisg
	ON wsit.StockItemID = wsisg.StockItemID
), PurchaseSold AS (
	SELECT StockItemTransactionID, StockItemID, StockItemStockGroupID, StockGroupID, Quantity, 
	(
		CASE
			WHEN Quantity > 0 THEN Quantity
			ELSE 0
		END
	) AS Purchased,
	(
		CASE
			WHEN Quantity < 0 THEN Quantity
			ELSE 0
		END
	) AS Sold
	FROM Joined
), Grouped AS (
	SELECT StockGroupID, SUM(Purchased) TotalQuantityPurchased, SUM(Sold) TotalQuantitySold
	FROM PurchaseSold
	GROUP BY StockGroupID
) 
SELECT *, (TotalQuantityPurchased + TotalQuantitySold) AS RemainingStockQuantity
FROM Grouped;


/* Q14 */
WITH USCities AS (
	SELECT *
	FROM Application.Cities
	WHERE StateProvinceID in (
		SELECT StateProvinceID
		FROM Application.StateProvinces
		WHERE CountryID = (
			SELECT CountryID
			FROM Application.Countries
			WHERE CountryName = 'United States'
		)
	)
-- Actually the WWI sample database contains only US cities so WHERE clause is not needed but just for generosity
), CityItemCount AS (
	SELECT DeliveryCityID, sol.StockItemID, COUNT(*) ItemCounts
	FROM Sales.Invoices si
	LEFT JOIN Sales.Customers sc
	ON si.CustomerID = sc.CustomerID
	LEFT JOIN Sales.OrderLines sol
	ON si.OrderID = sol.OrderID
	WHERE YEAR(ConfirmedDeliveryTime) = '2016'
	GROUP BY DeliveryCityID, StockItemID
), SubRankTbl AS (
	SELECT * 
	FROM (
		SELECT DeliveryCityID, StockItemID, RANK() OVER (PARTITION BY DeliveryCityID ORDER BY ItemCounts DESC) as Rnk
		FROM CityItemCount
	) Sub
	WHERE Sub.Rnk <= 1
)
SELECT 
	CityID, 
	CityName, 
	(CASE 
		WHEN StockItemID IS NULL THEN 'No Sales'
		ELSE CAST(StockItemID AS VARCHAR(10)) 
	END
	) AS TopDeliveredStockItemID
FROM USCities uc
LEFT JOIN SubRankTbl srt
ON srt.DeliveryCityID = uc.CityID;


/* Q15 */
SELECT InvoiceID, CustomerID, OrderID, ReturnedDeliveryData
FROM Sales.Invoices
WHERE JSON_VALUE(ReturnedDeliveryData, '$.Events[1].Comment') = 'Receiver not present'


/* Q16 */
SELECT StockItemID, JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture
FROM Warehouse.StockItems
WHERE JSON_VALUE(CustomFields, '$.CountryOfManufacture') = 'China';


/* Q17 */
WITH ItemCountry AS (
	SELECT StockItemID, JSON_VALUE(CustomFields, '$.CountryOfManufacture') CountryOfManufacture
	FROM Warehouse.StockItems
)
SELECT CountryOfManufacture, ABS(SUM(Quantity)) TotalQuantityOfStockItemSold
FROM Warehouse.StockItemTransactions wsit
JOIN ItemCountry ic
ON wsit.StockItemID = ic.StockItemID
WHERE
	Quantity < 0
	AND
	YEAR(TransactionOccurredWhen) = '2015'
GROUP BY CountryOfManufacture;

