USE sakila;

DROP VIEW IF EXISTS v_customer_rentals;

CREATE OR REPLACE VIEW v_customer_rentals AS
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.email,
  COUNT(r.rental_id) AS rental_count
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;

DROP TEMPORARY TABLE IF EXISTS tmp_customer_payments;

CREATE TEMPORARY TABLE tmp_customer_payments AS
SELECT
  v.customer_id,
  COALESCE(SUM(p.amount), 0) AS total_paid
FROM v_customer_rentals v
LEFT JOIN payment p ON p.customer_id = v.customer_id
GROUP BY v.customer_id;

WITH customer_summary AS (
  SELECT
    v.customer_name,
    v.email,
    v.rental_count,
    t.total_paid
  FROM v_customer_rentals v
  LEFT JOIN tmp_customer_payments t ON t.customer_id = v.customer_id
)
SELECT
  customer_name,
  email,
  rental_count,
  total_paid,
  CASE WHEN rental_count > 0 THEN ROUND(total_paid / rental_count, 2) ELSE NULL END AS average_payment_per_rental
FROM customer_summary
ORDER BY total_paid DESC, customer_name;