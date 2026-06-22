-- 265: Remove 'Blockchain Certificate Verify' (cat 258) and 'Pearson Vue Exams'
--      (cat 113) from the Enquiries mega-menu (SKILL CERTIFICATIONS column) by
--      setting include_in_menu=0 (by entity_id, store-scope-safe). Reindex after.

SET @a_im := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_im AND entity_id IN (113,258) AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,@a_im,0,113,0),(3,@a_im,0,258,0) ON DUPLICATE KEY UPDATE value=0;
