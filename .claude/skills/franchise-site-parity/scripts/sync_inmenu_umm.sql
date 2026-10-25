-- Enable include_in_menu on the whole 4-root subtree (SG has ALL descendants in-menu).
-- Replace <adultId> <softwareId> <certprepId> <bootcampId> with the PARTNER root entity_ids
-- (find by url_key: adult-training-courses / software-training-courses /
--  certification-exam-prep-courses / specialisation-courses). PARTNER-DB-ONLY.
-- After: reindex catalog_category_flat + flush. Do this for ALL 4 roots (the classic bug is
-- only doing Adult and leaving Software/Cert Prep menus empty).

SET @im := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='include_in_menu' AND entity_type_id=3);
INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @im, 0, e.entity_id, 1
FROM catalog_category_entity e
WHERE e.path LIKE '1/2/<adultId>/%' OR e.path LIKE '1/2/<softwareId>/%'
   OR e.path LIKE '1/2/<certprepId>/%' OR e.path LIKE '1/2/<bootcampId>/%'
ON DUPLICATE KEY UPDATE value = 1;

-- Mega-menu layout (umm_dd_*) per category — generate these from SG by url_key (clear+set).
-- Attr types: umm_dd_type=185 varchar, umm_dd_width=186 varchar, umm_dd_proportions=187 varchar,
-- umm_dd_columns=188 int. Example for the AI category (partner entity_id = <aiId>):
--   INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES
--     (3,185,0,<aiId>,'1'),(3,186,0,<aiId>,'800px'),(3,187,0,<aiId>,'4;4;4;')
--   ON DUPLICATE KEY UPDATE value=VALUES(value);
--   INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) VALUES
--     (3,188,0,<aiId>,3) ON DUPLICATE KEY UPDATE value=VALUES(value);
-- Roots are dd_type=1 with 5/4/3 cols, 1200px. Verify: the <li> gains class "mega",
-- style="width:...px", and a "dd-itemgrid-Ncol" <ul>.
