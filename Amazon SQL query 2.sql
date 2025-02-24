--EDA

SELECT * FROM category;
SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM products;
SELECT * FROM sellers;
SELECT * FROM inventory;
SELECT * FROM payments;
SELECT * FROM shipping;

SELECT DISTINCT payment_status
FROM payments;

SELECT *
FROM shipping
WHERE return_date IS NOT NULL;

SELECT * 
FROM payments
WHERE payment_status = 'Refunded';

SELECT * 
FROM orders
WHERE order_status = 'Returned'

------------------------------------------
--Business problems - Advanced Analysis
------------------------------------------

/* 1. Top Selling Products 
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold & total sales value.
*/

WITH cte AS
(SELECT product_id, 
		SUM(quantity*price_per_unit) AS total_sales_value, 
		SUM(quantity) AS total_quantity_sold
FROM order_items 
GROUP BY product_id)

SELECT TOP 10 product_name, total_quantity_sold, total_sales_value
FROM cte c 
JOIN products p ON c.product_id = p.product_id 
ORDER BY total_sales_value DESC;


/* 2. Revenue by Category
Calculate total revenue geneated by each product category.
Challenge: Include the percentage contribution of each category to total revenue*/

WITH cte AS
(SELECT p.category_id, 
		SUM(quantity*price_per_unit) AS total_revenue
FROM products p
JOIN order_items o ON p.product_id = o.product_id
JOIN category c ON c.category_id = p.category_id
GROUP BY p.category_id)

SELECT category_name, 
		total_revenue, 
		ROUND(total_revenue/(SELECT SUM(total_revenue) FROM cte)*100,2) AS percentage_contribution
FROM cte 
JOIN category c ON c.category_id = cte.category_id
ORDER BY total_revenue DESC;


/* 3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders*/

SELECT c.customer_id, 
		CONCAT(first_name,' ',last_name) AS full_name, 
		SUM(quantity*price_per_unit)/COUNT(o.order_id) AS AOV, 
		COUNT(o.order_id) AS no_of_orders
FROM customers c 
JOIN 
orders o ON c.customer_id = o.customer_id
JOIN order_items i ON i.order_id = o.order_id
GROUP BY c.customer_id, CONCAT(first_name,' ',last_name)
HAVING COUNT(o.order_id)>5
ORDER BY AOV DESC;


/* 4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
*/

WITH cte AS
(SELECT	YEAR(order_date) AS sales_year, 
		MONTH(order_date) AS sales_month, 
		SUM(quantity*price_per_unit) AS total_sales
FROM orders o 
JOIN order_items i ON o.order_id = i.order_id
WHERE order_date >= DATEADD(year, -1, getdate())
GROUP BY YEAR(order_date), MONTH(order_date))

SELECT sales_year, 
	   sales_month,
	   total_sales AS current_month_sales, 
	   LAG(total_sales) OVER(ORDER BY sales_year, sales_month) AS last_month_sales
FROM cte;


/*
5. Customers with No Purchases
Find customers who have registered but never placed an order.
*/

SELECT customer_id, CONCAT(first_name,' ', last_name) AS full_name
FROM customers
WHERE customer_id NOT IN (SELECT DISTINCT customer_id
					      FROM orders)


/*
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.
*/

WITH cte AS
(SELECT state, 
		g.category_id, 
		category_name, 
		SUM(quantity*price_per_unit) AS total_sales,
        RANK() OVER(PARTITION BY state ORDER BY SUM(quantity*price_per_unit)) AS r
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items i ON o.order_id = i.order_id
JOIN products p ON i.product_id = p.product_id
JOIN category g ON p.category_id = g.category_id
GROUP BY state, g.category_id,  g.category_name)

SELECT state, category_name, total_sales
FROM cte
WHERE r=1


/*
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.
*/


SELECT c.customer_id, 
	   CONCAT(first_name, ' ', last_name),
	   SUM(quantity*price_per_unit) AS total_value,
	   DENSE_RANK() OVER (ORDER BY SUM(quantity*price_per_unit) DESC) AS ranking
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items i ON o.order_id = i.order_id
GROUP BY c.customer_id, CONCAT(first_name, ' ', last_name);


/*
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.
*/


SELECT p.product_id, product_name, stock AS stock_left, warehouse_id, last_stock_date 
FROM inventory i 
JOIN products p ON i.product_id = p.product_id
WHERE stock < 10;


/*
9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.
*/

SELECT c.customer_id, 
	   o.order_id,
	   order_date, 
	   shipping_date, 
	   shipping_providers, 
	   DATEDIFF(day, order_date, shipping_date) AS days_took_to_ship
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN shipping s ON o.order_id = s.order_id
WHERE DATEDIFF(day, order_date, shipping_date)>3;


/*
10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).
*/

SELECT payment_status, 
	   COUNT(*) AS total_count, 
	   COUNT(*)*100.0/(SELECT COUNT(*) FROM payments) AS percentage_of_payments
FROM payments 
GROUP BY payment_status;


/*
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.
*/

WITH cte AS
(SELECT TOP 5 
		s.seller_id, 
		seller_name, 
		SUM(quantity*price_per_unit) AS total_sales_value,
		ROW_NUMBER() OVER(ORDER BY SUM(quantity*price_per_unit) DESC) AS ranking
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
JOIN order_items i ON o.order_id = i.order_id
GROUP BY s.seller_id, seller_name)

,cte2 AS
(SELECT cte.seller_id, COUNT(order_id) AS total_orders,
		SUM(CASE WHEN order_status = 'Completed' THEN 1 ELSE 0 END) AS successfull_orders,
		SUM(CASE WHEN order_status IN ('Cancelled', 'Returned') THEN 1 ELSE 0 END) AS failed_orders
FROM cte 
JOIN orders o ON cte.seller_id = o.seller_id
WHERE order_status NOT IN ('Inprogress')
GROUP BY cte.seller_id)

SELECT cte.seller_id, 
	   seller_name, 
	   total_sales_value,  
	   successfull_orders, 
	   failed_orders,
	   successfull_orders*100.0/total_orders AS sucess_percent,
	   ranking
FROM cte 
JOIN cte2 ON cte.seller_id = cte2.seller_id
ORDER BY ranking;


/*
12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
*/

WITH cte AS
(SELECT p.product_id, product_name,
	   SUM(price_per_unit*quantity) AS total_revenue,
	   SUM(cogs*quantity) AS total_cost_price
FROM products p 
JOIN order_items o ON p.product_id = o.product_id
GROUP BY p.product_id, product_name)

SELECT product_id, product_name,
	   total_revenue-total_cost_price AS profit,
	   ROUND((total_revenue-total_cost_price)*100.0/total_revenue,4) AS profit_margin,
	   RANK() OVER(ORDER BY total_revenue-total_cost_price DESC) AS ranking_by_profit
FROM cte;

/*
13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.
*/


SELECT TOP 10 p.product_id, 
		product_name, 
		COUNT(*) AS total_unit_sold,
		SUM(CASE WHEN order_status ='Returned' THEN 1 ELSE 0 END) AS no_of_returns,
		SUM(CASE WHEN order_status ='Returned' THEN 1 ELSE 0 END)*100.0/COUNT(*) AS return_rate
FROM products p 
JOIN order_items i ON p.product_id = i.product_id
JOIN orders o ON o.order_id = i.order_id
GROUP BY p.product_id, product_name
ORDER BY no_of_returns DESC;


/*
14. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.
*/

SELECT s.seller_id, 
	   seller_name, 
	   SUM(quantity*price_per_unit) AS total_sales, 
	   MAX(order_date) AS last_sale_date
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
JOIN order_items i ON o.order_id = i.order_id
WHERE order_date NOT IN (SELECT order_date
						 FROM orders
						 WHERE order_date >= DATEADD(month, -6, GETDATE()))
GROUP BY s.seller_id, seller_name
ORDER BY s.seller_id;



/*
15. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns
*/

WITH cte AS
(SELECT c.customer_id, CONCAT(first_name,' ',last_name) AS full_name,
		SUM(CASE WHEN order_status = 'Returned' THEN 1 ELSE 0 END) AS total_returns,
		COUNT(order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, CONCAT(first_name,' ',last_name))

SELECT *,
	   CASE WHEN total_returns>5 THEN 'returning' ELSE 'new' END AS category
FROM cte c;


/*
16. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
*/

WITH cte AS
(SELECT state,
       c.customer_id, 
	   CONCAT(first_name,' ',last_name) AS full_name, 
	   COUNT(*) AS total_orders,  
	   SUM(quantity*price_per_unit) AS total_sales,
	   DENSE_RANK() OVER(PARTITION BY state ORDER BY COUNT(*) DESC) AS cust_ranking
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items i ON o.order_id = i.order_id
GROUP BY state, c.customer_id, CONCAT(first_name,' ',last_name))

SELECT * 
FROM cte WHERE cust_ranking<=5;


/*
17. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled.
*/

SELECT shipping_providers, 
	   SUM(quantity*price_per_unit) AS total_revenue, 
	   COUNT(s.order_id) AS total_orders
FROM shipping s
JOIN orders o ON s.order_id = o.order_id
JOIN order_items i ON i.order_id = o.order_id
GROUP BY shipping_providers;

/*
18. Top 10 products with the highest decrease in revenue ratio in 2023 compared to 2022 
Challenge: Return product_id, product_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result
Note: Decrease ratio = ls-cr/ls* 100 (cs = current_year ls=last_year)
*/


WITH cte AS
(SELECT p.product_id, product_name,
	  SUM(CASE WHEN YEAR(order_date) = 2022 THEN quantity*price_per_unit ELSE 0 END) AS revenue_2022,
	  SUM(CASE WHEN YEAR(order_date) = 2023 THEN quantity*price_per_unit ELSE 0 END) AS revenue_2023
FROM orders o 
JOIN order_items i ON i.order_id = o.order_id
JOIN products p ON p.product_id = i.product_id
GROUP BY p.product_id, product_name)

SELECT TOP 10 * 
FROM (SELECT TOP 10 product_id, product_name, 
	   revenue_2022, revenue_2023, 
	   ROUND((revenue_2022-revenue_2023)*100/NULLIF(revenue_2022,0),4) AS decrease_ratio
	   FROM cte) AS a
ORDER BY decrease_ratio DESC;


/*

Stored Procedure
Create a function to reduce the stocks from the inventory table as soon as the product is sold
and after adding any sales records it should update the stock in the inventory table based on the product and qty purchased
-- 
*/

GO
CREATE PROCEDURE new_order

@p_order_id INT,
@p_customer_id INT,
@p_seller_id INT,
@p_order_item_id INT,
@p_product_id INT,
@p_quantity INT

AS
BEGIN
	DECLARE 
		@v_count INT,
		@v_price DECIMAL(10,2);
	BEGIN TRANSACTION;

	BEGIN TRY

		SELECT @v_count = SUM(stock)
		FROM inventory
		WHERE product_id = @p_product_id AND stock >= @p_quantity;

		SELECT @v_price = price 
		FROM products
		WHERE product_id = @p_product_id;

		IF @v_count > 0 
		BEGIN
			INSERT INTO orders(order_id, order_date, customer_id, seller_id)
			VALUES(@p_order_id, GETDATE(), @p_customer_id, @p_seller_id);

			INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit)
			VALUES(@p_order_item_id, @p_order_id, @p_product_id, @p_quantity, @v_price);

			UPDATE inventory
			SET stock = stock- @p_quantity
			WHERE product_id = @p_product_id;

			PRINT 'Thank you! Your order# ' + CAST(@p_order_id AS VARCHAR) + ' has been placed successfully';

			COMMIT TRANSACTION;
		END
		ELSE 
		BEGIN
			RAISERROR( 'Insufficient stock. Sorry order cannot be placed',16,1);
		END
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;

		PRINT 'Error:' +ERROR_MESSAGE();
	END CATCH
END;
GO


EXEC new_order 
    @p_order_id = 25000, 
    @p_customer_id = 2, 
    @p_seller_id = 5, 
    @p_order_item_id = 25001, 
    @p_product_id = 1, 
    @p_quantity = 40;
















