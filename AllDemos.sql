USE SQLPresentation


EXEC Mock.GenerateAll



-- //////////////////////////////////////////////////////////////
-- Demo 1: Why Implicit Conversions Are Bad
-- //////////////////////////////////////////////////////////////


-- Add index
CREATE NONCLUSTERED INDEX [IX_Customer_DateOfBirth] ON [Customer].[Customer]([DateOfBirth] ASC) INCLUDE ([FirstName],[LastName],[StateId]) ON [PRIMARY] 


-- Drop index
DROP INDEX [IX_Customer_DateOfBirth] ON [Customer].[Customer]


-- With implicit conversion
SELECT 
	[FirstName],
	[LastName],
	[DisplayName] = [FirstName]+ ' ' + [LastName],
	[DateOfBirth]
FROM 
	[SQLPresentation].[Customer].[Customer] AS Cust
WHERE
	[StateId] = 'MN' AND 
	[DateOfBirth] LIKE '198_%'
ORDER BY
	[LastName],
	[FirstName]


-- No implicit conversion
SELECT 
	[FirstName],
	[LastName],
	[DisplayName] = [FirstName]+ ' ' + [LastName],
	[DateOfBirth]
FROM 
	[SQLPresentation].[Customer].[Customer] AS Cust
WHERE
	[StateId] = 'MN' AND 
	[DateOfBirth] BETWEEN DateAdd(yy, 80, DateAdd(m, 0, 0)) AND DateAdd(yy, 89, DateAdd(m, 11, 30))
	-- Note: SQL Server 2012 has a DATEFROMPARTS which is slightly more convenient
	-- [DateOfBirth] BETWEEN DATEFROMPARTS(1980,1,1) AND DATEFROMPARTS(1989,12,31)
ORDER BY
	[LastName],
	[FirstName]















-- //////////////////////////////////////////////////////////////
-- Demo 2: INNER JOIN VS LEFT OUTER JOIN
-- //////////////////////////////////////////////////////////////


-- INNER JOIN (SELF JOIN) ONE-TO-ONE
SELECT TOP (1000)
	Customer					= Cust1.FirstName + ' ' + Cust1.LastName,
	ReferredBy					= Cust2.FirstName + ' ' + Cust2.LastName,
	State						= State.DisplayName
FROM Customer.Customer Cust1
JOIN Customer.Customer Cust2	ON Cust1.ReferredBy =Cust2.CustomerId
JOIN Customer.State				ON State.StateId = Cust1.StateId
ORDER BY						Cust1.LastName,	Cust1.FirstName







-- LEFT OUTER JOIN (SELF JOIN) ONE-TO-ONE
SELECT TOP (1000)
	Customer						= Cust1.FirstName + ' ' + Cust1.LastName,
	ReferredBy						= Cust2.FirstName + ' ' + Cust2.LastName,
	State							= State.DisplayName
FROM Customer.Customer Cust1
LEFT JOIN Customer.Customer Cust2	ON Cust1.ReferredBy =Cust2.CustomerId
JOIN Customer.State					ON State.StateId = Cust1.StateId					
ORDER BY							Cust1.LastName, Cust1.FirstName








-- LEFT OUTER JOIN, ONE-TO-ONE
SELECT TOP (1000)
	 Product 				= Product.ProductDescription,
	 SerialNumber 			= SUBSTRING(Item.SerialNumber,0,9),
	 Price 					= Product.Cost,
	 DiscountAmount			= Product.Cost - Receipt_Item.AppliedPrice,
	 DiscountedPrice 		= Receipt_Item.AppliedPrice,
	 DiscountPercent 		= CONVERT(decimal(3,2),
			ROUND(1 - Receipt_Item.AppliedPrice * 1.0 / Product.Cost, 2)),
	 SoldOn 				= Receipt.PurchasedOn,
	 Customer				= Customer.FirstName + ' ' + Customer.LastName
FROM Product.Item 
JOIN Product.Product	     ON Product.ProductId = Item.ProductId
LEFT JOIN Sale.Receipt_Item  ON Receipt_Item.ItemId = Item.ItemId
LEFT JOIN Sale.Receipt		 ON Receipt.ReceiptId = Receipt_Item.ReceiptId
LEFT JOIN Customer.Customer	 ON Customer.CustomerId = Receipt.CustomerId
WHERE						 Product.CategoryId = 3
ORDER BY					 Product, SerialNumber








-- (MOSTLY) INNER JOIN, ONE-TO-MANY PHONES
SELECT TOP (1000)
	 Product 					= Product.ProductDescription,
	 SerialNumber 				= SUBSTRING(Item.SerialNumber,0,9),
	 SoldOn 					= Receipt.PurchasedOn,
	 Customer					= Customer.FirstName + ' ' + Customer.LastName,
	 PhoneNumber.Number,
	 PhoneNumber.Type
FROM Product.Item 
JOIN Product.Product			ON Product.ProductId = Item.ProductId
JOIN Sale.Receipt_Item			ON Receipt_Item.ItemId = Item.ItemId
JOIN Sale.Receipt				ON Receipt.ReceiptId = Receipt_Item.ReceiptId
JOIN Customer.Customer			ON Customer.CustomerId = Receipt.CustomerId
LEFT JOIN Customer.PhoneNumber	ON PhoneNumber.CustomerId = Customer.CustomerId  -- !
WHERE							Product.CategoryId = 3
ORDER BY						Product, SerialNumber











-- //////////////////////////////////////////////////////////////
-- Demo 3: GROUP BY AND ITS LIMITATIONS
-- //////////////////////////////////////////////////////////////



-- Sales by month
SELECT TOP (20)
	Year					= DATEPART(YEAR, Receipt.PurchasedOn),
	Month					= DATEPART(MONTH, Receipt.PurchasedOn),
	Orders					= COUNT(DISTINCT Receipt.ReceiptId),
	Items					= COUNT(Receipt_Item.ItemId),
	Total					= SUM(Receipt_Item.AppliedPrice)
FROM Sale.Receipt			
JOIN Sale.Receipt_Item		ON Receipt_Item.ReceiptId = Receipt.ReceiptId
WHERE						DATEPART(YEAR, Receipt.PurchasedOn) = 2013
GROUP BY					DATEPART(YEAR, Receipt.PurchasedOn),
							DATEPART(MONTH, Receipt.PurchasedOn)
ORDER BY					Year, Month







-- Top customers
SELECT TOP (20)
	Customer.CustomerId,
	Orders					= COUNT(DISTINCT Receipt.ReceiptId),
	Items					= COUNT(Receipt_Item.ItemId),
	AvgCost					= CONVERT(decimal(6,2), AVG(Receipt_Item.AppliedPrice)),
	Total					= SUM(Receipt_Item.AppliedPrice)
FROM Customer.Customer
JOIN Sale.Receipt			ON Receipt.CustomerId = Customer.CustomerId
JOIN Sale.Receipt_Item 		ON Receipt_Item.ReceiptId = Receipt.ReceiptId
-- WHERE					Receipt.PurchasedOn >= DATEADD(YEAR, 2013-1900, 0)
GROUP BY					Customer.CustomerId
-- HAVING					COUNT(Receipt_Item.ItemId) >= 10
ORDER BY					Total DESC;












-- //////////////////////////////////////////////////////////////
-- Demo 4: BACK TO PHONE NUMBERS
-- //////////////////////////////////////////////////////////////


-- Our original query
SELECT TOP (1000)
	 Product 					= Product.ProductDescription,
	 SerialNumber 				= SUBSTRING(Item.SerialNumber,0,9),
	 SoldOn 					= Receipt.PurchasedOn,
	 Customer					= Customer.FirstName + ' ' + Customer.LastName,
	 PhoneNumber.Number,
	 PhoneNumber.Type
FROM Product.Item 
JOIN Product.Product			ON Product.ProductId = Item.ProductId
JOIN Sale.Receipt_Item			ON Receipt_Item.ItemId = Item.ItemId
JOIN Sale.Receipt				ON Receipt.ReceiptId = Receipt_Item.ReceiptId
JOIN Customer.Customer			ON Customer.CustomerId = Receipt.CustomerId
LEFT JOIN Customer.PhoneNumber	ON PhoneNumber.CustomerId = Customer.CustomerId  -- !
WHERE							Product.CategoryId = 3
ORDER BY						Product, SerialNumber



-- Correlated subquery solution
SELECT TOP (1000)
	 Product 					= Product.ProductDescription,
	 SerialNumber 				= SUBSTRING(Item.SerialNumber,0,9),
	 SoldOn 					= Receipt.PurchasedOn,
	 Customer					= Customer.FirstName + ' ' + Customer.LastName,
	 HomePhone					= ( SELECT TOP 1 Number
									FROM   Customer.PhoneNumber
									WHERE  PhoneNumber.CustomerId = Customer.CustomerId AND
										   PhoneNumber.Type = 'H'),
     MobilePhone				= ( SELECT TOP 1 Number
     							    FROM   Customer.PhoneNumber
     							    WHERE  PhoneNumber.CustomerId = Customer.CustomerId AND
     									   PhoneNumber.Type = 'M'),
     WorkPhone				    = ( SELECT TOP 1 Number
     							    FROM   Customer.PhoneNumber
     							    WHERE  PhoneNumber.CustomerId = Customer.CustomerId AND
     									   PhoneNumber.Type = 'W')
FROM Product.Item 
JOIN Product.Product			ON Product.ProductId = Item.ProductId
JOIN Sale.Receipt_Item			ON Receipt_Item.ItemId = Item.ItemId
JOIN Sale.Receipt				ON Receipt.ReceiptId = Receipt_Item.ReceiptId
JOIN Customer.Customer			ON Customer.CustomerId = Receipt.CustomerId
WHERE							Product.CategoryId = 3
ORDER BY						Product, SerialNumber




-- Multiple join solution, no subquery
SELECT TOP (1000)
	 Product 					= Product.ProductDescription,
	 SerialNumber 				= SUBSTRING(Item.SerialNumber,0,9),
	 SoldOn 					= Receipt.PurchasedOn,
	 Customer					= Customer.FirstName + ' ' + Customer.LastName,
	 HomePhone					= HomePhone.Number,
	 MobilePhone				= MobilePhone.Number,
	 WorkPhone					= WorkPhone.Number
FROM Product.Item 
JOIN Product.Product			ON Product.ProductId = Item.ProductId
JOIN Sale.Receipt_Item			ON Receipt_Item.ItemId = Item.ItemId
JOIN Sale.Receipt				ON Receipt.ReceiptId = Receipt_Item.ReceiptId
JOIN Customer.Customer			ON Customer.CustomerId = Receipt.CustomerId
LEFT JOIN Customer.PhoneNumber  AS HomePhone ON
								HomePhone.CustomerId = Customer.CustomerId AND
								HomePhone.Type = 'H'
LEFT JOIN Customer.PhoneNumber  AS MobilePhone ON
								MobilePhone.CustomerId = Customer.CustomerId AND
								MobilePhone.Type = 'M'
LEFT JOIN Customer.PhoneNumber  AS WorkPhone ON
								WorkPhone.CustomerId = Customer.CustomerId AND
								WorkPhone.Type = 'W'					
WHERE							Product.CategoryId = 3
ORDER BY						Product, SerialNumber;






-- //////////////////////////////////////////////////////////////
-- Demo 5: GROUP BY WITH COMMON TABLE EXPRESSION
-- //////////////////////////////////////////////////////////////



-- CTE top customers
WITH GroupedResults AS
(
	SELECT TOP (20)
		Customer.CustomerId,
		Orders					= COUNT(DISTINCT Receipt.ReceiptId),
		Items					= COUNT(Receipt_Item.ItemId),
		AvgCost					= CONVERT(decimal(6,2), AVG(Receipt_Item.AppliedPrice)),
		Total					= SUM(Receipt_Item.AppliedPrice)
	FROM Customer.Customer
	JOIN Sale.Receipt			ON Receipt.CustomerId = Customer.CustomerId
	JOIN Sale.Receipt_Item 		ON Receipt_Item.ReceiptId = Receipt.ReceiptId
	GROUP BY					Customer.CustomerId
	ORDER BY					Total DESC
)
SELECT
	Customer					= Customer.FirstName + ' ' + Customer.LastName,
	GroupedResults.*
FROM GroupedResults
JOIN Customer.Customer			ON Customer.CustomerId = GroupedResults.CustomerId



-- Essentially what the CTE is doing is making a non-correlated subquery
SELECT
	Customer							= Customer.FirstName + ' ' + Customer.LastName,
	GroupedResults.*
FROM    (
			SELECT TOP (20)
				Customer.CustomerId,
				Orders					= COUNT(DISTINCT Receipt.ReceiptId),
				Items					= COUNT(Receipt_Item.ItemId),
				AvgCost					= CONVERT(decimal(6,2), AVG(Receipt_Item.AppliedPrice)),
				Total					= SUM(Receipt_Item.AppliedPrice)
			FROM Customer.Customer
			JOIN Sale.Receipt			ON Receipt.CustomerId = Customer.CustomerId
			JOIN Sale.Receipt_Item 		ON Receipt_Item.ReceiptId = Receipt.ReceiptId
			GROUP BY					Customer.CustomerId
			ORDER BY					Total DESC
		) AS GroupedResults
JOIN Customer.Customer			ON Customer.CustomerId = GroupedResults.CustomerId



-- And it wouldn't make sense to make a correlated one, but yet...
SELECT TOP (20)
	Customer.CustomerId,
	Customer				= (	SELECT FirstName + ' ' + LastName
								FROM Customer.Customer CustomerSubquery
								WHERE CustomerSubquery.CustomerId = Customer.CustomerId),
	Orders					= COUNT(DISTINCT Receipt.ReceiptId),
	Items					= COUNT(Receipt_Item.ItemId),
	AvgCost					= CONVERT(decimal(6,2), AVG(Receipt_Item.AppliedPrice)),
	Total					= SUM(Receipt_Item.AppliedPrice)
FROM Customer.Customer
JOIN Sale.Receipt			ON Receipt.CustomerId = Customer.CustomerId
JOIN Sale.Receipt_Item 		ON Receipt_Item.ReceiptId = Receipt.ReceiptId
GROUP BY					Customer.CustomerId
ORDER BY					Total DESC





-------




--Phone numbers with a pivot
WITH 
	CustomerPurchases AS
	(
		SELECT TOP (1000)
			 Receipt.CustomerId,
			 Product 					= Product.ProductDescription,
			 SerialNumber 				= SUBSTRING(Item.SerialNumber,0,9),
			 SoldOn 					= Receipt.PurchasedOn,
			 Customer					= Customer.FirstName + ' ' + Customer.LastName
		FROM Product.Item 
		JOIN Product.Product			ON Product.ProductId = Item.ProductId
		JOIN Sale.Receipt_Item			ON Receipt_Item.ItemId = Item.ItemId
		JOIN Sale.Receipt				ON Receipt.ReceiptId = Receipt_Item.ReceiptId
		JOIN Customer.Customer			ON Customer.CustomerId = Receipt.CustomerId
		WHERE							Product.CategoryId = 3
		ORDER BY						Product, SerialNumber
	),
	PhoneNumberPivot AS
	(
		SELECT	CustomerId, H, M, W
		FROM	Customer.PhoneNumber
		PIVOT	(
					MAX (Number) 
					FOR Type IN (H,M,W)
				) AS PhonePivot
	)
SELECT
	Customers.*,
	HomePhone							= Numbers.H,
	MobilePhone							= Numbers.M,
	WorkPhone							= Numbers.W
FROM CustomerPurchases Customers
JOIN PhoneNumberPivot Numbers			ON Numbers.CustomerId = Customers.CustomerId





-- //////////////////////////////////////////////////////////////
-- Demo 6: GROUP BY WITH TABLE VARIABLE
-- //////////////////////////////////////////////////////////////


DECLARE @GroupedResults TABLE
(
	CustomerId INT,
	Orders INT,
	Items INT,
	AvgCost	DECIMAL(6,2),
	Total DECIMAL(7,2)
)

-- If inserting into a real table, always name your columns for forward compatibility!
INSERT INTO @GroupedResults
SELECT TOP (20)
	Customer.CustomerId,
	Orders					= COUNT(DISTINCT Receipt.ReceiptId),
	Items					= COUNT(Receipt_Item.ItemId),
	AvgCost					= CONVERT(decimal(6,2), AVG(Receipt_Item.AppliedPrice)),
	Total					= SUM(Receipt_Item.AppliedPrice)
FROM Customer.Customer
JOIN Sale.Receipt			ON Receipt.CustomerId = Customer.CustomerId
JOIN Sale.Receipt_Item 		ON Receipt_Item.ReceiptId = Receipt.ReceiptId
GROUP BY					Customer.CustomerId
ORDER BY					Total DESC

SELECT
	Customer				= Customer.FirstName + ' ' + Customer.LastName,
	[@GroupedResults].*
FROM @GroupedResults
JOIN Customer.Customer		ON Customer.CustomerId = [@GroupedResults].CustomerId







-- //////////////////////////////////////////////////////////////
-- Demo 7: GROUP BY WITH TEMPORARY TABLE
-- //////////////////////////////////////////////////////////////


SELECT TOP (20)
	Customer.CustomerId,
	Orders					= COUNT(DISTINCT Receipt.ReceiptId),
	Items					= COUNT(Receipt_Item.ItemId),
	AvgCost					= CONVERT(decimal(6,2), AVG(Receipt_Item.AppliedPrice)),
	Total					= SUM(Receipt_Item.AppliedPrice)
INTO #GroupedResults
FROM Customer.Customer
JOIN Sale.Receipt			ON Receipt.CustomerId = Customer.CustomerId
JOIN Sale.Receipt_Item 		ON Receipt_Item.ReceiptId = Receipt.ReceiptId
GROUP BY					Customer.CustomerId
ORDER BY					Total DESC

SELECT
	Customer				= Customer.FirstName + ' ' + Customer.LastName,
	#GroupedResults.*
FROM #GroupedResults
JOIN Customer.Customer		ON Customer.CustomerId = #GroupedResults.CustomerId;

DROP TABLE #GroupedResults;