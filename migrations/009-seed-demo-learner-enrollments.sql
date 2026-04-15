-- Seed demo Learner enrollments so the Learner "My Classes" dashboard
-- has visible courses on a fresh setup (Current / Upcoming / Past).
--
-- Re-runnable: checks for existing SEED009-prefixed orders before inserting.
--
-- Requires the base dump (courses_mysql2.sql) to already be imported so
-- products 251, 432, 450 and the admin_user table exist.

SET @start_attr := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='news_from_date' AND entity_type_id=4);
SET @end_attr   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='news_to_date'   AND entity_type_id=4);
SET @today      := CURDATE();

-- Pick the first active admin user as the demo learner
SET @demo_email := (SELECT email FROM admin_user WHERE is_active = 1 ORDER BY user_id LIMIT 1);
SET @demo_first := (SELECT COALESCE(firstname, 'Demo') FROM admin_user WHERE is_active = 1 ORDER BY user_id LIMIT 1);
SET @demo_last  := (SELECT COALESCE(lastname,  'User') FROM admin_user WHERE is_active = 1 ORDER BY user_id LIMIT 1);

-- Skip if already seeded
SET @already_seeded := (SELECT COUNT(*) FROM sales_flat_order WHERE increment_id LIKE 'SEED009%');

-- Set product dates for 251 (Current), 432 (Upcoming), 450 (Past)
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

-- Create 3 sales orders only if not already seeded and demo email exists
INSERT INTO sales_flat_order
    (state, status, store_id, customer_email, customer_firstname, customer_lastname, customer_is_guest,
     base_grand_total, grand_total, base_subtotal, subtotal, total_qty_ordered, total_item_count,
     base_currency_code, order_currency_code, store_currency_code, increment_id, protect_code,
     created_at, updated_at)
SELECT 'processing','processing',1,@demo_email,@demo_first,@demo_last,1,
       0,0,0,0,1,1,'SGD','SGD','SGD',
       'SEED009-CURR', MD5(RAND()), NOW(), NOW()
FROM dual
WHERE @demo_email IS NOT NULL AND @already_seeded = 0;

INSERT INTO sales_flat_order_item (order_id, store_id, created_at, updated_at, product_id, product_type, sku, name, qty_ordered, base_price, price, base_row_total, row_total)
SELECT entity_id, 1, NOW(), NOW(), 251, 'simple', 'C251', 'Microsoft 365 Administrator Training (MS-102)', 1, 0, 0, 0, 0
FROM sales_flat_order WHERE increment_id = 'SEED009-CURR' LIMIT 1;

INSERT INTO sales_flat_order
    (state, status, store_id, customer_email, customer_firstname, customer_lastname, customer_is_guest,
     base_grand_total, grand_total, base_subtotal, subtotal, total_qty_ordered, total_item_count,
     base_currency_code, order_currency_code, store_currency_code, increment_id, protect_code,
     created_at, updated_at)
SELECT 'processing','processing',1,@demo_email,@demo_first,@demo_last,1,
       0,0,0,0,1,1,'SGD','SGD','SGD',
       'SEED009-UPC', MD5(RAND()), NOW(), NOW()
FROM dual
WHERE @demo_email IS NOT NULL AND @already_seeded = 0;

INSERT INTO sales_flat_order_item (order_id, store_id, created_at, updated_at, product_id, product_type, sku, name, qty_ordered, base_price, price, base_row_total, row_total)
SELECT entity_id, 1, NOW(), NOW(), 432, 'simple', 'C432', 'MS-102 Microsoft 365 Administrator Training', 1, 0, 0, 0, 0
FROM sales_flat_order WHERE increment_id = 'SEED009-UPC' LIMIT 1;

INSERT INTO sales_flat_order
    (state, status, store_id, customer_email, customer_firstname, customer_lastname, customer_is_guest,
     base_grand_total, grand_total, base_subtotal, subtotal, total_qty_ordered, total_item_count,
     base_currency_code, order_currency_code, store_currency_code, increment_id, protect_code,
     created_at, updated_at)
SELECT 'complete','complete',1,@demo_email,@demo_first,@demo_last,1,
       0,0,0,0,1,1,'SGD','SGD','SGD',
       'SEED009-PAST', MD5(RAND()),
       DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY)
FROM dual
WHERE @demo_email IS NOT NULL AND @already_seeded = 0;

INSERT INTO sales_flat_order_item (order_id, store_id, created_at, updated_at, product_id, product_type, sku, name, qty_ordered, base_price, price, base_row_total, row_total)
SELECT entity_id, 1, NOW(), NOW(), 450, 'simple', 'M450', 'MS-102 Microsoft 365 Administrator Training', 1, 0, 0, 0, 0
FROM sales_flat_order WHERE increment_id = 'SEED009-PAST' LIMIT 1;
