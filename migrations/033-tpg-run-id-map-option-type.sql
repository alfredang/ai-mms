-- Extend tpg_run_id_map with option_type_id so a Course Run ID can be
-- pinned to a specific Course Date session of a product. Without this,
-- Search Enrolment would have to return every order ever placed for the
-- product (and its siblings), inflating counts well beyond what the
-- official SSG site shows for the same run.

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tpg_run_id_map' AND COLUMN_NAME='option_type_id');
SET @sql := IF(@has=0,
    'ALTER TABLE tpg_run_id_map ADD COLUMN `option_type_id` INT UNSIGNED NULL DEFAULT NULL COMMENT ''Specific Course Date session this run maps to''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Seed each existing mapping with the BUSIEST Course Date session of its
-- mapped product (the option_type_id that has been chosen by the most
-- order line-items so far). Picking by actual usage means Search Enrolment
-- returns rows; picking arbitrarily often pins a future/empty session.
-- Products with no usage data (older orders that predate the custom option)
-- are left with option_type_id=NULL so the search falls back to product-wide.
UPDATE tpg_run_id_map m
JOIN (
    SELECT o.product_id,
           ov.option_type_id AS busy_otv,
           cnt
    FROM (
        SELECT product_id, option_type_id, COUNT(*) AS cnt
        FROM (
            SELECT oi.product_id,
                   ov.option_type_id,
                   oi.product_options
            FROM sales_flat_order_item oi
            JOIN catalog_product_option o ON o.product_id = oi.product_id
            JOIN catalog_product_option_title ot ON ot.option_id=o.option_id AND ot.store_id=0
            JOIN catalog_product_option_type_value ov ON ov.option_id=o.option_id
            WHERE ot.title LIKE '%Date%'
              AND oi.product_options LIKE CONCAT('%s:', LENGTH(ov.option_type_id), ':"', ov.option_type_id, '"%')
        ) t
        GROUP BY product_id, option_type_id
    ) ranked
    JOIN catalog_product_option_type_value ov ON ov.option_type_id = ranked.option_type_id
    JOIN catalog_product_option o ON o.option_id = ov.option_id
    WHERE NOT EXISTS (
        SELECT 1 FROM (
            SELECT product_id, MAX(cnt) AS top_cnt
            FROM (
                SELECT oi.product_id, ov2.option_type_id, COUNT(*) AS cnt
                FROM sales_flat_order_item oi
                JOIN catalog_product_option o2 ON o2.product_id = oi.product_id
                JOIN catalog_product_option_title ot2 ON ot2.option_id=o2.option_id AND ot2.store_id=0
                JOIN catalog_product_option_type_value ov2 ON ov2.option_id=o2.option_id
                WHERE ot2.title LIKE '%Date%'
                  AND oi.product_options LIKE CONCAT('%s:', LENGTH(ov2.option_type_id), ':"', ov2.option_type_id, '"%')
                GROUP BY oi.product_id, ov2.option_type_id
            ) t2
            GROUP BY product_id
        ) tops
        WHERE tops.product_id = ranked.product_id AND tops.top_cnt > ranked.cnt
    )
) busiest ON busiest.product_id = m.product_id
SET m.option_type_id = busiest.busy_otv
WHERE m.option_type_id IS NULL;
