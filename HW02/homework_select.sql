/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT 
StockitemID
,StockItemName 
FROM Warehouse.StockItems 
WHERE StockItemName LIKE ('%urgent%') OR StockItemName LIKE ('Animal%')

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/
SELECT DISTINCT
S.SupplierID 
,S.SupplierName
FROM Purchasing.Suppliers S
LEFT JOIN Purchasing.PurchaseOrders P ON P.SupplierID = S.SupplierID
WHERE P.PurchaseOrderID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT DISTINCT
O.OrderID
,convert(varchar, O.OrderDate, 104) AS OrderDate
,datename(month, O.OrderDate) AS SalesMonth
,DATEPART(QUARTER, O.OrderDate) AS SalesQuater
,CASE
			WHEN MONTH(O.OrderDate) in (1, 2, 3, 4)
			THEN 1
			WHEN MONTH(O.OrderDate) in (5, 6, 7, 8)
			THEN 2
			WHEN MONTH(O.OrderDate) in (9, 10, 11, 12)
			THEN 3
			END AS SalesThird
,C.CustomerName
FROM Sales.Orders O
INNER JOIN Sales.Customers C ON C.CustomerID = O.CustomerIDa
INNER JOIN Sales.OrderLines OL ON OL.OrderID = O.OrderID
WHERE (OL.UnitPrice > 100 
OR  OL.Quantity > 20)
AND O.PickingCompletedWhen IS NOT NULL
ORDER BY SalesQuater,SalesThird,OrderDate
OFFSET 1000 ROWS
FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/
SELECT 
D.DeliveryMethodName
,PO.ExpectedDeliveryDate
,S.SupplierName
,P.FullName
FROM Purchasing.Suppliers S
INNER JOIN Purchasing.PurchaseOrders PO ON PO.SupplierID = S.SupplierID
INNER JOIN Application.DeliveryMethods D ON D.DeliveryMethodID = PO.DeliveryMethodID
INNER JOIN Application.People P ON P.PersonID = PO.ContactPersonID
WHERE PO.ExpectedDeliveryDate BETWEEN '20130101' AND '20130131'
AND D.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight') -- D.DeliveryMethodName = 'Air Freight'OR 'Refrigerated Air Freight'
AND PO.IsOrderFinalized = 1
/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/
SELECT TOP 10
 O.OrderID
,C.CustomerName  
,P.FullName 
FROM
Sales.Orders AS O
LEFT OUTER JOIN Sales.Customers C ON O.CustomerID = C.CustomerID
LEFT OUTER JOIN Application.People P ON O.SalespersonPersonID = P.PersonID
ORDER BY
O.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT 
C.CustomerID
,C.CustomerName
,C.PhoneNumber
FROM Sales.Customers C
INNER JOIN Sales.Orders O ON O.CustomerID = C.CustomerID
INNER JOIN Sales.OrderLines OL ON OL.OrderID = O.OrderID
INNER JOIN Warehouse.StockItems S ON S.StockItemID = OL.StockItemID
WHERE S.StockItemName = 'Chocolate frogs 250g'

