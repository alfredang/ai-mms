-- 326: Enquiries mega-menu additions (SG).
--   * Partnership column (category url_key 'partnership'): two new landing items —
--       "SCTP Program Development"  -> /sctp-program-development.html (PAGE, block sctp_landing)
--       "WPL Development"           -> /wpl-development.html          (PAGE, block wpl_landing)
--   * SSG Support column (category url_key 'support'): one new item —
--       "Class Reschedule"          -> /class-reschedule.html (existing CMS page 77), via umm_cat_target.
--
-- SG-scoped: every category insert is gated on @sg (the SG-only marker category
-- 'course-development-service' existing). Partner DBs lack that category, so this
-- migration is a no-op there. Idempotent: re-runs resolve the existing category by
-- url_key and re-apply the same attribute values (never a duplicate row).
--
-- After deploy, run the "Catalog URL Rewrites" + "Category Flat Data" indexers so the
-- new url_rewrites and mega-menu entries materialise (same as migrations 322/323).

-- ---- landing blocks (rendered when the SCTP / WPL categories are in PAGE mode) ----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'SCTP Programme Development Landing','sctp_landing','<div style="max-width:760px;margin:0 auto;color:#0f172a;line-height:1.6"><h2 style="font-size:26px;font-weight:800;margin:0 0 10px">SCTP Programme Development</h2><p style="color:#475569;font-size:16px;margin:0 0 6px">Are you an industry expert or training partner keen to develop a WSQ SCTP (SSG Career Transition Programme)? Partner with us to design and launch a place-and-train reskilling programme. We handle the SSG accreditation, funding administration and learner placement while you bring the domain expertise. Complete the form below and our programme development team will be in touch.</p></div>{{block type="core/template" template="mmd_sctp/form.phtml"}}',NOW(),NOW(),1
FROM dual WHERE NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier='sctp_landing') t);
INSERT INTO cms_block_store (block_id, store_id) SELECT b.block_id,0 FROM cms_block b WHERE b.identifier='sctp_landing' AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id=b.block_id);

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'WPL Development Landing','wpl_landing','<div style="max-width:760px;margin:0 auto;color:#0f172a;line-height:1.6"><h2 style="font-size:26px;font-weight:800;margin:0 0 10px">WPL Development</h2><p style="color:#475569;font-size:16px;margin:0 0 6px">Structure on-the-job training into a recognised Workplace Learning (WPL) programme. Partner with us to map your workplace tasks to competencies, build the on-the-job training blueprint and tap available funding. Complete the form below and our WPL development team will be in touch.</p></div>{{block type="core/template" template="mmd_wpl/form.phtml"}}',NOW(),NOW(),1
FROM dual WHERE NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier='wpl_landing') t);
INSERT INTO cms_block_store (block_id, store_id) SELECT b.block_id,0 FROM cms_block b WHERE b.identifier='wpl_landing' AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id=b.block_id);

-- ---- category attribute ids ----
SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_nm := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_dm := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='display_mode');
SET @a_pl := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='page_layout');
SET @a_tg := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='umm_cat_target');
SET @a_ia := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_an := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_anchor');
SET @a_im := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');
SET @a_cu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='custom_use_parent_settings');
SET @a_lp := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='landing_page');

-- SG-only marker + parents + block ids
SET @sg := (SELECT COUNT(*) FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='course-development-service');
SET @p_partner := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='partnership' LIMIT 1);
SET @p_support := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='support' LIMIT 1);
SET @partner_path := (SELECT path FROM catalog_category_entity WHERE entity_id=@p_partner);
SET @support_path := (SELECT path FROM catalog_category_entity WHERE entity_id=@p_support);
SET @pos_p := (SELECT COALESCE(MAX(position),0) FROM catalog_category_entity WHERE parent_id=@p_partner);
SET @pos_s := (SELECT COALESCE(MAX(position),0) FROM catalog_category_entity WHERE parent_id=@p_support);
SET @sctp_landing := (SELECT block_id FROM cms_block WHERE identifier='sctp_landing' LIMIT 1);
SET @wpl_landing := (SELECT block_id FROM cms_block WHERE identifier='wpl_landing' LIMIT 1);

-- =========================== SCTP (Partnership) ===========================
SET @sctp_pre := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='sctp-program-development' LIMIT 1);
SET @fresh_sctp := IF(@sctp_pre IS NULL AND @sg>0 AND @p_partner IS NOT NULL, 1, 0);
INSERT INTO catalog_category_entity (entity_type_id,attribute_set_id,parent_id,path,position,level,children_count,created_at,updated_at)
  SELECT 3,3,@p_partner,'',@pos_p+1,4,0,NOW(),NOW() FROM dual WHERE @fresh_sctp=1;
SET @sctp_id := IF(@fresh_sctp=1, LAST_INSERT_ID(), @sctp_pre);
UPDATE catalog_category_entity SET path=CONCAT(@partner_path,'/',@sctp_id) WHERE entity_id=@sctp_id AND @sctp_id IS NOT NULL;
UPDATE catalog_category_entity SET children_count=children_count+1 WHERE FIND_IN_SET(entity_id, REPLACE(@partner_path,'/',',')) AND @fresh_sctp=1;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_nm,0,@sctp_id,'SCTP Program Development' FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_uk,0,@sctp_id,'sctp-program-development' FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@sctp_id,'PAGE' FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_pl,0,@sctp_id,'one_column' FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@sctp_id,'/sctp-program-development.html' FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_ia,0,@sctp_id,1 FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_an,0,@sctp_id,0 FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_im,0,@sctp_id,1 FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_cu,0,@sctp_id,0 FROM dual WHERE @sctp_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@sctp_id,@sctp_landing FROM dual WHERE @sctp_id IS NOT NULL AND @sctp_landing IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- =========================== WPL (Partnership) ============================
SET @wpl_pre := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='wpl-development' LIMIT 1);
SET @fresh_wpl := IF(@wpl_pre IS NULL AND @sg>0 AND @p_partner IS NOT NULL, 1, 0);
INSERT INTO catalog_category_entity (entity_type_id,attribute_set_id,parent_id,path,position,level,children_count,created_at,updated_at)
  SELECT 3,3,@p_partner,'',@pos_p+2,4,0,NOW(),NOW() FROM dual WHERE @fresh_wpl=1;
SET @wpl_id := IF(@fresh_wpl=1, LAST_INSERT_ID(), @wpl_pre);
UPDATE catalog_category_entity SET path=CONCAT(@partner_path,'/',@wpl_id) WHERE entity_id=@wpl_id AND @wpl_id IS NOT NULL;
UPDATE catalog_category_entity SET children_count=children_count+1 WHERE FIND_IN_SET(entity_id, REPLACE(@partner_path,'/',',')) AND @fresh_wpl=1;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_nm,0,@wpl_id,'WPL Development' FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_uk,0,@wpl_id,'wpl-development' FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@wpl_id,'PAGE' FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_pl,0,@wpl_id,'one_column' FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@wpl_id,'/wpl-development.html' FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_ia,0,@wpl_id,1 FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_an,0,@wpl_id,0 FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_im,0,@wpl_id,1 FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_cu,0,@wpl_id,0 FROM dual WHERE @wpl_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@wpl_id,@wpl_landing FROM dual WHERE @wpl_id IS NOT NULL AND @wpl_landing IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- ===================== Class Reschedule (SSG Support) =====================
-- Links out to the existing CMS page /class-reschedule.html via umm_cat_target.
SET @resch_pre := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='class-reschedule-request' LIMIT 1);
SET @fresh_resch := IF(@resch_pre IS NULL AND @sg>0 AND @p_support IS NOT NULL, 1, 0);
INSERT INTO catalog_category_entity (entity_type_id,attribute_set_id,parent_id,path,position,level,children_count,created_at,updated_at)
  SELECT 3,3,@p_support,'',@pos_s+1,4,0,NOW(),NOW() FROM dual WHERE @fresh_resch=1;
SET @resch_id := IF(@fresh_resch=1, LAST_INSERT_ID(), @resch_pre);
UPDATE catalog_category_entity SET path=CONCAT(@support_path,'/',@resch_id) WHERE entity_id=@resch_id AND @resch_id IS NOT NULL;
UPDATE catalog_category_entity SET children_count=children_count+1 WHERE FIND_IN_SET(entity_id, REPLACE(@support_path,'/',',')) AND @fresh_resch=1;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_nm,0,@resch_id,'Class Reschedule' FROM dual WHERE @resch_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_uk,0,@resch_id,'class-reschedule-request' FROM dual WHERE @resch_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@resch_id,'PRODUCTS' FROM dual WHERE @resch_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@resch_id,'/class-reschedule.html' FROM dual WHERE @resch_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_ia,0,@resch_id,1 FROM dual WHERE @resch_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_an,0,@resch_id,0 FROM dual WHERE @resch_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_im,0,@resch_id,1 FROM dual WHERE @resch_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_cu,0,@resch_id,0 FROM dual WHERE @resch_id IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
