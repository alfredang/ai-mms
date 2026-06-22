-- 262: Fix Enquiries mega-menu Google links by ENTITY_ID (257 used a store-0
--      url_key lookup that no-oped on prod where url_key/target live at store 1).
--      Sets umm_cat_target to the on-site page at store 0 and removes any
--      non-zero-store override so the Google value cannot win. Also relabels the
--      franchise category to 'Regional Franchisee'. Reindex after applying.

SET @a_tg := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='umm_cat_target');
SET @a_lbl := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='umm_cat_label');
SET @a_nm := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=114 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,114,'/trainer-application.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=115 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,115,'/in-house-training.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=117 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,117,'/course-feedback.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=173 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,173,'/extract-cpf-contribution.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=180 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,180,'/franchising-application.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=254 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,254,'/in-house-training.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=255 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,255,'/customised-training.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=271 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,271,'/jobs.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=277 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,277,'/refund-request.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=428 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,428,'/how-to-register-wsq-course.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=430 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,430,'/how-to-claim-skillsfuture-credit.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=437 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_tg,0,437,'/assessment-appeal-form.html') ON DUPLICATE KEY UPDATE value=VALUES(value);

-- relabel category 180 to 'Regional Franchisee'
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_nm AND entity_id=180 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_nm,0,180,'Regional Franchisee') ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_lbl AND entity_id=180 AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_lbl,0,180,'Regional Franchisee') ON DUPLICATE KEY UPDATE value=VALUES(value);
