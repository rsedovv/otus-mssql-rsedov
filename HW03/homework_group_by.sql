/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT 
 year(ct.TransactionDate) AS year
,month(ct.TransactionDate) AS Month
,AVG(ol.UnitPrice) AS [Average Unit Price]
,SUM(ct.TransactionAmount) AS [Transaction Amount Sum]
FROM
	Sales.Invoices i
	INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
	INNER JOIN Sales.OrderLines ol ON i.OrderID = ol.OrderID
GROUP BY year(ct.TransactionDate),month(ct.TransactionDate)
ORDER BY year ASC;

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT 
YEAR(C.TransactionDate) AS YEAR
,MONTH(C.TransactionDate) AS MONTH
,SUM(C.TransactionAmount) AS SUM
FROM Sales.Invoices I
INNER JOIN Sales.CustomerTransactions C ON C.InvoiceID = I.InvoiceID
GROUP BY 
YEAR(C.TransactionDate)
,MONTH(C.TransactionDate)
HAVING SUM(C.TransactionAmount) > 4600000
/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT 
YEAR(C.TransactionDate) AS YEAR
,MONTH(C.TransactionDate) AS MONTH
,S.StockItemName
,SUM(C.TransactionAmount) AS SUM
,MIN(C.TransactionDate) AS FirstSale
,COUNT(SI.Quantity) AS  Quantity
FROM Sales.Invoices I
INNER JOIN Sales.InvoiceLines SI ON SI.InvoiceID = I.InvoiceID
INNER JOIN Sales.CustomerTransactions C ON C.InvoiceID = I.InvoiceID
INNER JOIN Warehouse.StockItems S ON S.StockItemID = SI.StockItemID
GROUP BY 
YEAR(C.TransactionDate)
,MONTH(C.TransactionDate)
,S.StockItemName
HAVING COUNT(SI.Quantity) < 50

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
