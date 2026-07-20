select 
order_status,
cust_city,
cust_state,
customer_delivered_dt,
est_delivery_dt
from olist_db.fact_orders_flat
where delivery_delay_days > 1 AND 
order_status = "delivered";


# delay rate and avg delay per region

SELECT count(*)
FROM olist_db.fact_orders_flat
WHERE delivery_delay_days > 1 AND 
order_status = "delivered"
;

# delivery delay(delay_rate, avg_delivery_date, delivery_count, delayed vs on-time deliveries)
SELECT
SUM(CASE
	WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN 1 ELSE 0 END
) AS delayed_orders,
SUM(CASE
	WHEN delivery_delay_days  <= 0 AND order_status = "delivered" THEN 1 ELSE 0 END
) AS on_time_orders,
SUM(CASE WHEN order_status = "delivered" THEN 1 ELSE 0 END) AS total_delivered,
ROUND(AVG(CASE WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN delivery_delay_days END)) AS avg_delay_days,
ROUND(
	SUM(CASE WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN 1 ELSE 0 END) /
	SUM(CASE WHEN order_status = "delivered" THEN 1 ELSE 0 END) * 100, 2) AS delay_rate
FROM olist_db.fact_orders_flat
WHERE customer_delivered_dt IS NOT NULL;


# delivery delay per state (delay_rate, avg_delivery_date, delivery_count, delayed vs on-time deliveries)
SELECT
cust_state,
SUM(CASE WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN 1 ELSE 0 END) AS delayed_orders,
SUM(CASE WHEN delivery_delay_days <= 0 AND order_status = "delivered" THEN 1 ELSE 0 END) AS on_time_orders,
SUM(CASE WHEN order_status = "delivered" THEN 1 ELSE 0 END) AS total_delivered,
ROUND(AVG(CASE WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN delivery_delay_days END)) AS avg_delay_days,
ROUND(SUM(CASE WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN 1 ELSE 0 END)/
SUM(CASE WHEN order_status = "delivered" THEN 1 ELSE 0 END) * 100, 2) AS delay_rate
FROM olist_db.fact_orders_flat
WHERE 
  purchase_ts IS NOT NULL
  AND approved_ts IS NOT NULL
  AND carrier_delivered_dt IS NOT NULL
  AND customer_delivered_dt IS NOT NULL
GROUP BY cust_state
ORDER BY delay_rate DESC ;

SELECT COUNT(*) 
FROM olist_db.fact_orders_flat
WHERE order_status = "delivered" AND customer_delivered_dt IS NULL;




# monthly OTD%

SELECT
DATE_FORMAT(customer_delivered_dt, '%Y-%m') AS `year_month`,
COUNT(*) AS on_time_delivery
FROM olist_db.fact_orders_flat
WHERE delivery_delay_days <= 0 AND order_status = "delivered"
GROUP BY DATE_FORMAT(customer_delivered_dt, '%Y-%m')
ORDER BY 1
;


# top 10 worst delivery rates
SELECT
cust_state,
SUM(CASE WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN 1 ELSE 0 END) AS delayed_orders,
SUM(CASE WHEN delivery_delay_days <= 0 AND order_status = "delivered" THEN 1 ELSE 0 END) AS on_time_orders,
SUM(CASE WHEN order_status = "delivered" THEN 1 ELSE 0 END) AS total_delivered,
ROUND(AVG(CASE WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN delivery_delay_days END)) AS avg_delay_days,
ROUND(SUM(CASE WHEN delivery_delay_days > 0 AND order_status = "delivered" THEN 1 ELSE 0 END)/
SUM(CASE WHEN order_status = "delivered" THEN 1 ELSE 0 END) * 100, 2) AS delay_rate
FROM olist_db.fact_orders_flat
WHERE 
  purchase_ts IS NOT NULL
  AND approved_ts IS NOT NULL
  AND carrier_delivered_dt IS NOT NULL
  AND customer_delivered_dt IS NOT NULL
GROUP BY cust_state
ORDER BY delay_rate DESC
LIMIT 10;

# lead time by stage
SELECT*
FROM olist_db.fact_orders_flat;

SELECT
    ROUND(AVG(TIMESTAMPDIFF(SECOND, purchase_ts, approved_ts)) / 86400, 2) AS stage_1_approval_days,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, approved_ts, carrier_delivered_dt)) / 86400, 2) AS stage_2_carrier_pickup_days,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, carrier_delivered_dt, customer_delivered_dt)) / 86400, 2) AS stage_3_transit_days
FROM olist_db.fact_orders_flat
WHERE order_status = "delivered"
  AND purchase_ts IS NOT NULL
  AND approved_ts IS NOT NULL
  AND carrier_delivered_dt IS NOT NULL
  AND customer_delivered_dt IS NOT NULL;

# breakdown of order status
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM olist_db.fact_orders_flat) * 100, 2) AS pct_of_total
FROM olist_db.fact_orders_flat
GROUP BY order_status
ORDER BY order_count DESC;

# exception rate
SELECT
    COUNT(*) AS order_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM olist_db.fact_orders_flat) * 100, 2) AS pct_of_total
FROM olist_db.fact_orders_flat
WHERE order_status = "cancelled" OR order_status = "unavailable"
ORDER BY order_count DESC;