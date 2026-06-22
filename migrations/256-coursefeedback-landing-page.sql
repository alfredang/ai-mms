-- 256: Course Feedback landing. Render the feedback form (same questions as the
--      LMS class feedback) on category 117 (Course Feedback, /course-feedback.html).

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) SELECT 'Course Feedback Landing','coursefeedback_landing',0x3c646976207374796c653d226d61782d77696474683a37383070783b6d617267696e3a30206175746f3b636f6c6f723a233066313732613b6c696e652d6865696768743a312e36223e3c70207374796c653d22636f6c6f723a233437353536393b666f6e742d73697a653a313670783b6d617267696e3a30203020367078223e57652076616c756520796f757220666565646261636b2e20506c6561736520736861726520796f757220657870657269656e6365206f662074686520636f7572736520796f7520617474656e64656420736f2077652063616e206b65657020696d70726f76696e67206f757220747261696e696e67207175616c6974792e3c2f703e3c2f6469763e7b7b626c6f636b20747970653d22636f72652f74656d706c617465222074656d706c6174653d226d6d645f636f75727365666565646261636b2f666f726d2e7068746d6c227d7d,NOW(),NOW(),1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier='coursefeedback_landing') t);

INSERT INTO cms_block_store (block_id, store_id) SELECT b.block_id,0 FROM cms_block b WHERE b.identifier='coursefeedback_landing' AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id=b.block_id);

INSERT INTO catalog_category_entity_varchar (entity_type_id,attribute_id,store_id,entity_id,value) VALUES (3,49,0,117,'PAGE') ON DUPLICATE KEY UPDATE value='PAGE';

INSERT INTO catalog_category_entity_int (entity_type_id,attribute_id,store_id,entity_id,value) SELECT 3,50,0,117,b.block_id FROM cms_block b WHERE b.identifier='coursefeedback_landing' LIMIT 1 ON DUPLICATE KEY UPDATE value=VALUES(value);
