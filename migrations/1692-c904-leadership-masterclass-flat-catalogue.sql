-- Keep C904's SG listing/search projection aligned with the verified EAV rebrand.
-- The deploy URL/category reindex does not rebuild the product flat table.
SET @c904_pid := (SELECT entity_id FROM catalog_product_entity WHERE sku='C904' LIMIT 1);
SET @c904_flat_ok := (@mms_instance='SG' AND @c904_pid IS NOT NULL AND (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='catalog_product_flat_1' AND column_name IN ('name','short_description','url_key','course_image_url'))=4);
SET @c904_flat_sql := IF(@c904_flat_ok, CONCAT('UPDATE catalog_product_flat_1 SET name=''Leadership Masterclass'', short_description=REPLACE(short_description,''Effective Leadership Training'',''Leadership Masterclass''), url_key=''leadership-masterclass'', course_image_url=''https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C904-Leadership-Masterclass-20261002.png'' WHERE entity_id=',@c904_pid), 'SELECT 1');
PREPARE c904_flat_stmt FROM @c904_flat_sql;
EXECUTE c904_flat_stmt;
DEALLOCATE PREPARE c904_flat_stmt;
