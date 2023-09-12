/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
SELECT DISTINCT
	 p.PersonID
	,p.FullName

FROM
	Application.People p
  INNER JOIN Sales.Invoices I ON I.SalespersonPersonID = P.PersonID

WHERE
 P.IsSalesperson = 1
 AND NOT  EXISTS
			(
				SELECT ct.InvoiceID 
				FROM Sales.CustomerTransactions ct 
				WHERE I.InvoiceID = ct.InvoiceID AND  ct.TransactionDate = '20150715'
			)

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT 
	 StockItemID
	,StockItemName
	,UnitPrice
FROM Warehouse.StockItems
WHERE
	UnitPrice = 
	(
		SELECT min(UnitPrice) 
		FROM Warehouse.StockItems
	);

SELECT 
	 si.StockItemID
	,si.StockItemName
	,si.UnitPrice
FROM 
	Warehouse.StockItems si
	INNER JOIN
	(
		SELECT min(UnitPrice) as [MinPrice]
		FROM Warehouse.StockItems
	) minPrice ON si.UnitPrice = minPrice.MinPrice;

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT DISTINCT
	 c.CustomerID
	,c.CustomerName
	,c.PhoneNumber 
FROM 
	(
		SELECT TOP 5 CustomerID
		FROM Sales.CustomerTransactions 
		ORDER BY TransactionAmount DESC
	) a
	INNER JOIN Sales.Customers c ON a.CustomerID = c.CustomerID;

SELECT DISTINCT
	 CustomerID
	,CustomerName
	,PhoneNumber 
FROM Sales.Customers
WHERE
	CustomerID IN
	(
		SELECT TOP 5 CustomerID
		FROM Sales.CustomerTransactions 
		ORDER BY TransactionAmount DESC
	);

WITH Top5TranAmount AS
(
	SELECT TOP 5
		 CustomerID
		,TransactionAmount
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC
)
SELECT DISTINCT
	 c.CustomerID
	,c.CustomerName
	,c.PhoneNumber 
FROM
	Sales.Customers c 
	INNER JOIN Top5TranAmount t ON c.CustomerID = t.CustomerID
/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

SELECT DISTINCT
	 cts.CityID
	,cts.CityName
	,p.FullName
FROM
	(
		SELECT TOP 3 StockItemID
		FROM Warehouse.StockItems
		ORDER BY UnitPrice DESC
	) si
	INNER JOIN Sales.OrderLines ol ON si.StockItemID = ol.StockItemID
	INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
	INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
	INNER JOIN Application.People p ON o.PickedByPersonID = p.PersonID
	INNER JOIN Application.Cities cts ON c.DeliveryCityID = cts.CityID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

--TODO: напишите здесь свое решение
