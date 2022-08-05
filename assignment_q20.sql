/* Q20 */
CREATE FUNCTION Sales.ufn_order (@OrderId int)
RETURNS int AS
BEGIN
	DECLARE @Res int
	SELECT @Res = SUM(Quantity)
	FROM Sales.OrderLines
	GROUP BY OrderID
	HAVING OrderID = @OrderId
	RETURN @Res
END;
