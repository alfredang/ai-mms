-- C904 user-authorized rebrand. SG only; price, duration, topics and schedules preserved.
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id=1 AND code='singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku='C904' LIMIT 1);
SET @ok := (@sg=1 AND @pid IS NOT NULL);

SET @attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
INSERT INTO catalog_product_entity_varchar(entity_type_id,attribute_id,store_id,entity_id,value) SELECT 4,@attr,0,@pid,'Leadership Masterclass' FROM DUAL WHERE @ok AND @attr IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE @ok AND entity_id=@pid AND attribute_id=@attr AND store_id=1;

SET @attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
INSERT INTO catalog_product_entity_varchar(entity_type_id,attribute_id,store_id,entity_id,value) SELECT 4,@attr,0,@pid,'leadership-masterclass' FROM DUAL WHERE @ok AND @attr IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE @ok AND entity_id=@pid AND attribute_id=@attr AND store_id=1;

SET @attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
INSERT INTO catalog_product_entity_varchar(entity_type_id,attribute_id,store_id,entity_id,value) SELECT 4,@attr,0,@pid,'leadership-masterclass.html' FROM DUAL WHERE @ok AND @attr IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE @ok AND entity_id=@pid AND attribute_id=@attr AND store_id=1;

SET @attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
INSERT INTO catalog_product_entity_varchar(entity_type_id,attribute_id,store_id,entity_id,value) SELECT 4,@attr,0,@pid,'Leadership Masterclass | Tertiary Courses Singapore' FROM DUAL WHERE @ok AND @attr IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE @ok AND entity_id=@pid AND attribute_id=@attr AND store_id=1;

SET @attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
INSERT INTO catalog_product_entity_varchar(entity_type_id,attribute_id,store_id,entity_id,value) SELECT 4,@attr,0,@pid,'Leadership Masterclass' FROM DUAL WHERE @ok AND @attr IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE @ok AND entity_id=@pid AND attribute_id=@attr AND store_id=1;

SET @attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
INSERT INTO catalog_product_entity_varchar(entity_type_id,attribute_id,store_id,entity_id,value) SELECT 4,@attr,0,@pid,'Leadership Masterclass' FROM DUAL WHERE @ok AND @attr IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE @ok AND entity_id=@pid AND attribute_id=@attr AND store_id=1;

SET @attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
INSERT INTO catalog_product_entity_varchar(entity_type_id,attribute_id,store_id,entity_id,value) SELECT 4,@attr,0,@pid,'Leadership Masterclass' FROM DUAL WHERE @ok AND @attr IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE @ok AND entity_id=@pid AND attribute_id=@attr AND store_id=1;

SET @attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
INSERT INTO catalog_product_entity_varchar(entity_type_id,attribute_id,store_id,entity_id,value) SELECT 4,@attr,0,@pid,'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C904-Leadership-Masterclass-20261002.png' FROM DUAL WHERE @ok AND @attr IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE @ok AND entity_id=@pid AND attribute_id=@attr AND store_id=1;

UPDATE catalog_product_entity_text t JOIN eav_attribute a ON a.attribute_id=t.attribute_id SET t.value=REPLACE(t.value,'Effective Leadership Training','Leadership Masterclass') WHERE @ok AND t.entity_id=@pid AND t.store_id IN (0,1) AND a.attribute_code IN ('short_description','meta_description','meta_keyword');
UPDATE core_url_rewrite SET target_path='leadership-masterclass.html',is_system=0,options='RP',id_path='c904-leadership-masterclass-legacy' WHERE @ok AND store_id=1 AND request_path='effective-leadership-training.html';
INSERT INTO core_url_rewrite(store_id,id_path,request_path,target_path,is_system,options,product_id) SELECT 1,'product/904-leadership-masterclass','leadership-masterclass.html',CONCAT('catalog/product/view/id/',@pid),0,'',@pid FROM DUAL WHERE @ok AND NOT EXISTS(SELECT 1 FROM core_url_rewrite WHERE store_id=1 AND request_path='leadership-masterclass.html');
UPDATE catalogsearch_query SET redirect='https://www.tertiarycourses.com.sg/leadership-masterclass.html' WHERE @ok AND store_id=1 AND redirect='https://www.tertiarycourses.com.sg/effective-leadership-training.html';
