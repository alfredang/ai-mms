-- 322: Custom Course Development landing. Render the Course Development enquiry
--      form on the existing Enquiries mega-menu category
--      (url_key course-development-service, /course-development-service.html)
--      via a static block, and repoint its umm_cat_target off the external
--      www.tertiaryinfotech.com link to the on-site page.
--      Keyed by url_key + cms_block identifier so it is robust to entity_id /
--      block_id divergence, and partner-safe (no-op where the category is absent).

-- Landing block (intro copy + form template).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) SELECT 'Course Development Landing','coursedev_landing',0x3c646976207374796c653d226d61782d77696474683a37363070783b6d617267696e3a30206175746f3b636f6c6f723a233066313732613b6c696e652d6865696768743a312e36223e3c6832207374796c653d22666f6e742d73697a653a323670783b666f6e742d7765696768743a3830303b6d617267696e3a3020302031307078223e437573746f6d20436f7572736520446576656c6f706d656e743c2f68323e3c70207374796c653d22636f6c6f723a233437353536393b666f6e742d73697a653a313670783b6d617267696e3a30203020367078223e486176652065787065727469736520746f2073686172653f20506172746e6572207769746820757320746f20646576656c6f7020616e64206c61756e636820796f7572206f776e20636f757273652e2057652068616e646c652074686520706c6174666f726d2c206d61726b6574696e672c2066756e64696e672061646d696e697374726174696f6e20616e64206c6561726e657220726567697374726174696f6e20266d646173683b20796f75206272696e672074686520636f6e74656e7420616e64206561726e2061207368617265206f662074686520726576656e75652e20436f6d706c6574652074686520666f726d2062656c6f7720616e64206f757220636f7572736520646576656c6f706d656e74207465616d2077696c6c20626520696e20746f7563682e3c2f703e3c2f6469763e7b7b626c6f636b20747970653d22636f72652f74656d706c617465222074656d706c6174653d226d6d645f636f757273656465762f666f726d2e7068746d6c227d7d,NOW(),NOW(),1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier='coursedev_landing') t);

INSERT INTO cms_block_store (block_id, store_id) SELECT b.block_id,0 FROM cms_block b WHERE b.identifier='coursedev_landing' AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id=b.block_id);

SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_tg := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='umm_cat_target');
SET @a_dm := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='display_mode');
SET @a_lp := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='landing_page');
SET @cid := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id=@a_uk AND store_id=0 AND value='course-development-service' LIMIT 1);
SET @blk := (SELECT block_id FROM cms_block WHERE identifier='coursedev_landing' LIMIT 1);

-- Repoint mega-menu link off the external site to the on-site page.
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_tg AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_tg,0,@cid,'/course-development-service.html' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);

-- Force the category into PAGE mode so it renders the block, not a product list.
DELETE FROM catalog_category_entity_varchar WHERE attribute_id=@a_dm AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_dm,0,@cid,'PAGE' FROM dual WHERE @cid IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
DELETE FROM catalog_category_entity_int WHERE attribute_id=@a_lp AND entity_id=@cid AND store_id<>0;
INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,@a_lp,0,@cid,@blk FROM dual WHERE @cid IS NOT NULL AND @blk IS NOT NULL ON DUPLICATE KEY UPDATE value=VALUES(value);
