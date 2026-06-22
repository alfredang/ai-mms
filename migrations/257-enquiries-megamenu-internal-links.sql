-- 257: Repoint Enquiries mega-menu umm_cat_target from Google Forms / external
--      links to the on-site lead pages, and force the landing categories into
--      PAGE mode (store-scope-safe) so they render the form. Keyed by url_key +
--      cms_block identifier so it is robust to entity_id / block_id divergence.

SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_tg := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='umm_cat_target');
SET @a_dm := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='display_mode');
SET @a_lp := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='landing_page');

-- franchising-application -> /franchising-application.html (PAGE: franchise_landing)
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='franchising-application' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/franchising-application.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='franchise_landing' LIMIT 1);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- in-house-training -> /in-house-training.html (PAGE: corporate_landing)
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='in-house-training' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/in-house-training.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='corporate_landing' LIMIT 1);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- customised-training -> /customised-training.html (PAGE: customised_landing)
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='customised-training' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/customised-training.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='customised_landing' LIMIT 1);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- jobs -> /jobs.html (PAGE: hiring_landing)
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='jobs' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/jobs.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='hiring_landing' LIMIT 1);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- refund-request -> /refund-request.html (PAGE: refund_landing)
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='refund-request' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/refund-request.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='refund_landing' LIMIT 1);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- assessment-appeal-form -> /assessment-appeal-form.html (PAGE: appeal_landing)
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='assessment-appeal-form' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/assessment-appeal-form.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='appeal_landing' LIMIT 1);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- course-feedback -> /course-feedback.html (PAGE: coursefeedback_landing)
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='course-feedback' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/course-feedback.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='coursefeedback_landing' LIMIT 1);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- trainer-application -> /trainer-application.html (PAGE: trainer_landing)
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='trainer-application' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/trainer-application.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='trainer_landing' LIMIT 1);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- extract-cpf-contribution-report -> /extract-cpf-contribution.html
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='extract-cpf-contribution-report' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/extract-cpf-contribution.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- register-a-wsq-course -> /how-to-register-wsq-course.html
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='register-a-wsq-course' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/how-to-register-wsq-course.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- claim-skillsfuture-claim -> /how-to-claim-skillsfuture-credit.html
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='claim-skillsfuture-claim' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/how-to-claim-skillsfuture-credit.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- company-group-training-enquiry -> /in-house-training.html
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='company-group-training-enquiry' LIMIT 1);
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/in-house-training.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

