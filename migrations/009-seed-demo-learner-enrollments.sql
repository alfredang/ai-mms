-- Seed demo Learner enrollments so every active admin user sees courses
-- in their "My Classes" dashboard when they log in.
--
-- Creates 3 sales orders (Current / Upcoming / Past) for each active
-- admin user in the admin_user table. Idempotent — re-running the
-- migration doesn't duplicate orders because each increment_id is
-- derived from the user_id.

SET @start_attr := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='news_from_date' AND entity_type_id=4);
SET @end_attr   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='news_to_date'   AND entity_type_id=4);
SET @today      := CURDATE();

-- Set start/end dates on the 3 products used as test courses
DELETE FROM catalog_product_entity_datetime
WHERE entity_id IN (251, 432, 450)
  AND attribute_id IN (@start_attr, @end_attr)
  AND store_id = 0;

INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value) VALUES
    (4, @start_attr, 0, 251, DATE_SUB(@today, INTERVAL 1 DAY)),
    (4, @end_attr,   0, 251, DATE_ADD(@today, INTERVAL 3 DAY)),
    (4, @start_attr, 0, 432, DATE_ADD(@today, INTERVAL 7 DAY)),
    (4, @end_attr,   0, 432, DATE_ADD(@today, INTERVAL 12 DAY)),
    (4, @start_attr, 0, 450, DATE_SUB(@today, INTERVAL 30 DAY)),
    (4, @end_attr,   0, 450, DATE_SUB(@today, INTERVAL 14 DAY));

-- Temporary table of (user_id, email, firstname, lastname) for every active admin
DROP TEMPORARY TABLE IF EXISTS _seed_users;
CREATE TEMPORARY TABLE _seed_users AS
SELECT user_id, email, COALESCE(firstname, 'Demo') AS firstname, COALESCE(lastname, 'User') AS lastname
FROM admin_user
WHERE is_active = 1 AND email IS NOT NULL AND email != '';

-- Order 1: Current class (product 251)
INSERT INTO sales_flat_order
    (state, status, store_id, customer_email, customer_firstname, customer_lastname, customer_is_guest,
     base_grand_total, grand_total, base_subtotal, subtotal, total_qty_ordered, total_item_count,
     base_currency_code, order_currency_code, store_currency_code, increment_id, protect_code,
     created_at, updated_at)
SELECT 'processing','processing',1,u.email,u.firstname,u.lastname,1,
       0,0,0,0,1,1,'SGD','SGD','SGD',
       CONCAT('SEED-CURR-', u.user_id), MD5(RAND()), NOW(), NOW()
FROM _seed_users u
WHERE NOT EXISTS (SELECT 1 FROM sales_flat_order WHERE increment_id = CONCAT('SEED-CURR-', u.user_id));

INSERT INTO sales_flat_order_item (order_id, store_id, created_at, updated_at, product_id, product_type, sku, name, qty_ordered, base_price, price, base_row_total, row_total)
SELECT o.entity_id, 1, NOW(), NOW(), 251, 'simple', 'C251', 'Microsoft 365 Administrator Training (MS-102)', 1, 0, 0, 0, 0
FROM sales_flat_order o
WHERE o.increment_id LIKE 'SEED-CURR-%'
  AND NOT EXISTS (SELECT 1 FROM sales_flat_order_item WHERE order_id = o.entity_id);

-- Order 2: Upcoming class (product 432)
INSERT INTO sales_flat_order
    (state, status, store_id, customer_email, customer_firstname, customer_lastname, customer_is_guest,
     base_grand_total, grand_total, base_subtotal, subtotal, total_qty_ordered, total_item_count,
     base_currency_code, order_currency_code, store_currency_code, increment_id, protect_code,
     created_at, updated_at)
SELECT 'processing','processing',1,u.email,u.firstname,u.lastname,1,
       0,0,0,0,1,1,'SGD','SGD','SGD',
       CONCAT('SEED-UPC-', u.user_id), MD5(RAND()), NOW(), NOW()
FROM _seed_users u
WHERE NOT EXISTS (SELECT 1 FROM sales_flat_order WHERE increment_id = CONCAT('SEED-UPC-', u.user_id));

INSERT INTO sales_flat_order_item (order_id, store_id, created_at, updated_at, product_id, product_type, sku, name, qty_ordered, base_price, price, base_row_total, row_total)
SELECT o.entity_id, 1, NOW(), NOW(), 432, 'simple', 'C432', 'MS-102 Microsoft 365 Administrator Training', 1, 0, 0, 0, 0
FROM sales_flat_order o
WHERE o.increment_id LIKE 'SEED-UPC-%'
  AND NOT EXISTS (SELECT 1 FROM sales_flat_order_item WHERE order_id = o.entity_id);

-- Order 3: Past class (product 450)
INSERT INTO sales_flat_order
    (state, status, store_id, customer_email, customer_firstname, customer_lastname, customer_is_guest,
     base_grand_total, grand_total, base_subtotal, subtotal, total_qty_ordered, total_item_count,
     base_currency_code, order_currency_code, store_currency_code, increment_id, protect_code,
     created_at, updated_at)
SELECT 'complete','complete',1,u.email,u.firstname,u.lastname,1,
       0,0,0,0,1,1,'SGD','SGD','SGD',
       CONCAT('SEED-PAST-', u.user_id), MD5(RAND()),
       DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY)
FROM _seed_users u
WHERE NOT EXISTS (SELECT 1 FROM sales_flat_order WHERE increment_id = CONCAT('SEED-PAST-', u.user_id));

INSERT INTO sales_flat_order_item (order_id, store_id, created_at, updated_at, product_id, product_type, sku, name, qty_ordered, base_price, price, base_row_total, row_total)
SELECT o.entity_id, 1, NOW(), NOW(), 450, 'simple', 'M450', 'MS-102 Microsoft 365 Administrator Training', 1, 0, 0, 0, 0
FROM sales_flat_order o
WHERE o.increment_id LIKE 'SEED-PAST-%'
  AND NOT EXISTS (SELECT 1 FROM sales_flat_order_item WHERE order_id = o.entity_id);

DROP TEMPORARY TABLE IF EXISTS _seed_users;
