-- 323: Rename the Enquiries mega-menu item "Course Development" ->
--      "Custom Course Development" (category url_key course-development-service).
--      The mega-menu label is the category name. Partner-safe: no-op where the
--      category is absent. Run Category Flat Data reindex after apply.

SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_nm := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='course-development-service' LIMIT 1);

UPDATE catalog_category_entity_varchar SET value='Custom Course Development' WHERE attribute_id=@a_nm AND entity_id=@cid AND store_id=0;
