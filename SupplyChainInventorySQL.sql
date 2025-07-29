USE Project;

SELECT * FROM SupplyChainInventory;

SELECT CAST(Date AS DATE) AS 'Date' FROM SupplyChainInventory;

ALTER TABLE SupplyChainInventory
ADD Date_ DATE;

UPDATE SupplyChainInventory
SET Date_ = CAST(Date AS DATE);

ALTER TABLE SupplyChainInventory
DROP COLUMN Date;

ALTER TABLE SupplyChainInventory
ALTER COLUMN Inventory_Level FLOAT;

ALTER TABLE SupplyChainInventory
ALTER COLUMN Warehouse_Capacity FLOAT;

---------------------------------------------*** Warehouse Utility and Space Planning ***------------------------------------------------------
SELECT Warehouse ,ROUND((SUM(Inventory_Level)/ SUM(Warehouse_Capacity))*100.0,2) AS Warehouse_Utility
FROM SupplyChainInventory
GROUP BY Warehouse;
-->> It shows a consistent warehouse utility in all the warehouses. Though the percentage is on the lower side that suggests unused capacity.
-->> which can lead to high storage cost or inefficiencies.
-->> We can consider optimizing space or increasing usage.


--*** Units sold by Warehouses ***
SELECT Warehouse,SUM(Units_Sold) AS Total_Units_Sold, AVG(Units_Sold) AS Avg_Units_Sold FROM SupplyChainInventory
GROUP BY Warehouse
ORDER BY Total_Units_Sold DESC;


SELECT Region, ROUND(SUM(Transportation_Cost),0) AS 'Transportation_Cost' FROM SupplyChainInventory
GROUP BY Region
ORDER BY Transportation_Cost DESC;

SELECT ROUND(SUM(Cost_of_Goods_Sold_COGS)/SUM(Average_Inventory),2) AS Inventory_Turnover_Ratio FROM SupplyChainInventory;

SELECT Order_Status, COUNT(*) AS 'Total Orders',
ROUND(COUNT(Order_Status)*100/(SELECT COUNT(*) FROM SupplyChainInventory),0) AS 'Total Orders in %'
FROM SupplyChainInventory
GROUP BY Order_Status;




-----------------------------------------------**** Inventory Efficiency ****------------------------------------------------------

--**** Inventory Turnover Ratio ****
SELECT ROUND(SUM(Cost_of_Goods_Sold_COGS)/SUM(Average_Inventory),1) AS Inventory_Turnover_Ratio 
FROM SupplyChainInventory;


--**** Inventory Turnover Ratio by Category ****
SELECT Category, ROUND(SUM(Cost_of_Goods_Sold_COGS) / (Average_Inventory),2) AS InventoryTurnoverRatio
FROM SupplyChainInventory
GROUP BY Category
ORDER BY InventoryTurnoverRatio DESC;


-- **** Category with high inventory but low sales ****
SELECT Category,
SUM(Inventory_Level) AS TotalInventory,
SUM(Units_Sold) AS TotalSales,
ROUND(SUM(Units_Sold) * 100.0 / SUM(Inventory_Level), 1) AS '%_Of_Inventory_Sold'
FROM SupplyChainInventory
GROUP BY Category
HAVING SUM(Inventory_Level) > 2 * SUM(Units_Sold)
ORDER BY TotalInventory DESC;


---**** Days sales of inventory (DSI) ****
SELECT Category, AVG(Average_Inventory) / SUM(Cost_of_Goods_Sold_COGS) * 365 AS DaysSalesInventory
FROM SupplyChainInventory
GROUP BY Category;


----------------------------------------------**** Lead Time Monitoring ****----------------------------------------------
--**** Average Lead Time ****
SELECT AVG(Lead_Time_Days) AS 'Average Lead Time Days'  FROM SupplyChainInventory;

ALTER TABLE SupplyChainInventory
ALTER COLUMN Lead_Time_Days INT;

--**** Category-wise lead time greater than average ****
SELECT Category, Lead_Time_Days FROM SupplyChainInventory
WHERE Lead_Time_Days > (SELECT AVG(Lead_Time_Days) AS 'Average Lead Time Days'  FROM SupplyChainInventory)
GROUP BY Category;


--****Category-wise lead time greater than average ****
SELECT Category, COUNT(Lead_Time_Days) AS Delayed_Orders
FROM SupplyChainInventory
WHERE Lead_Time_Days > (SELECT AVG(Lead_Time_Days)
						FROM SupplyChainInventory)
GROUP BY Category;


--**** Trend of increasing lead time over months ****
SELECT FORMAT(Date_, 'yyyy-MM') AS Month, AVG(Lead_Time_Days) AS AvgLeadTime
FROM SupplyChainInventory
GROUP BY FORMAT(Date_, 'yyyy-MM')
ORDER BY Month;


-------------------------------------------------------***** Cost Monitoring ****-------------------------------------------------------

-- **** Total transportation cost by region ****
SELECT Region, ROUND(SUM(Transportation_Cost),0) AS Transportation_Cost
FROM SupplyChainInventory
GROUP BY Region
ORDER BY Transportation_Cost DESC;

--**** Transportation cost per unit sold ****
SELECT Category, 
ROUND(SUM(Transportation_Cost) / SUM(Units_Sold),1) AS Transportation_CostPerUnit
FROM SupplyChainInventory
GROUP BY Category;

--****Top 5 highest transportation cost orders details ****
SELECT TOP 5 * FROM SupplyChainInventory
ORDER BY Transportation_Cost DESC;


-------------------------------------------------***** Order Status ****------------------------------------------------------------
--**** Total Orders by status ****
SELECT COUNT(*) AS Total_Orders FROM SupplyChainInventory;


--**** Order status breakdown ****
SELECT Order_Status, COUNT(*) AS Total_Orders FROM SupplyChainInventory
GROUP BY Order_Status;

-- **** Region wise Order Status ****
SELECT Region, Order_Status, 
COUNT(*) AS Total_Orders FROM SupplyChainInventory
GROUP BY Region, Order_Status
ORDER BY Region, Order_Status;


--**** Yearly trend of canceled orders ****
SELECT YEAR(Date_) AS Years, COUNT(*) AS Canceled_Orders FROM SupplyChainInventory
WHERE Order_Status = 'Canceled'
GROUP BY YEAR(Date_);


------------------------------------------------------**** Back Orders ****-----------------------------------------------------------
--**** Count of Back orders by Warehouse ****
SELECT Warehouse, COUNT(*) AS BackorderCount
FROM SupplyChainInventory
WHERE Backorder = 'True'
GROUP BY Warehouse;


--**** Backorder % by categories ****
SELECT Category, 
CAST(SUM(CASE WHEN Backorder = 'True' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS BackorderRate
FROM SupplyChainInventory
GROUP BY Category;


--**** Total backorders and backorder rate ****
SELECT COUNT(*) AS Total_Orders,
SUM(CASE WHEN Backorder = 'True' THEN 1 ELSE 0 END) AS Backorders,
CAST(SUM(CASE WHEN Backorder = 'True' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS BackorderRate
FROM SupplyChainInventory;


-- **** Backorders by category ****
SELECT Category, COUNT(*) AS Total_Orders,
SUM(CASE WHEN Backorder = 'True' THEN 1 ELSE 0 END) AS Backorders,
CAST(SUM(CASE WHEN Backorder = 'True' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS BackorderRate
FROM SupplyChainInventory
GROUP BY Category;


-- **** Monthly backorder trend ****
SELECT FORMAT(Date_, 'yyyy-MM') AS OrderMonth,
COUNT(CASE WHEN Backorder = 'True' THEN 1 END) AS Backorders
FROM SupplyChainInventory
GROUP BY FORMAT(Date_, 'yyyy-MM')
ORDER BY OrderMonth;




---------------------------------------------***** High Transportation Cost Across Regions *****---------------------------------------------

--**** Total transportation cost by region ****
SELECT Region, ROUND(SUM(Transportation_Cost),0) AS Transportation_Cost
FROM SupplyChainInventory
GROUP BY Region
ORDER BY Transportation_Cost DESC;

--**** Top 5 Orders with Highest Transportation Cost ****
SELECT TOP 5 * FROM SupplyChainInventory
ORDER BY Transportation_Cost DESC;


---------------------------------------------------------------***-----------------------------------------------------------------------------