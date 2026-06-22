-- 230: Make the "Regional Franchisee" menu link durable.
--
-- 229 redirected the category URL to the franchise CMS page, but a "Catalog URL
-- Rewrites" reindex regenerates the category rewrite and wipes that redirect.
-- Instead, render the franchise landing content directly on the category page
-- via a static CMS block (display mode = static block only) — this survives any
-- reindex. The CMS page and the menu category both point at one shared block.

-- 1) Franchise content as a reusable CMS block (copied once from the landing page).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Franchise Landing', 'franchise_landing', p.content, NOW(), NOW(), 1
FROM cms_page p LEFT JOIN cms_block b ON b.identifier = 'franchise_landing'
WHERE p.identifier = 'franchising-application.html' AND b.block_id IS NULL LIMIT 1;

INSERT INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b WHERE b.identifier = 'franchise_landing'
AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id = b.block_id);

-- 2) Landing page renders the shared block (single source of truth).
UPDATE cms_page SET content = '{{block type="cms/block" block_id="franchise_landing"}}' WHERE identifier = 'franchising-application.html';

-- 3) Category 180 ("Regional Franchisee"): static-block-only display of that block.
INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (3, 49, 0, 180, 'PAGE') ON DUPLICATE KEY UPDATE value = 'PAGE';

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, 50, 0, 180, b.block_id FROM cms_block b WHERE b.identifier = 'franchise_landing' LIMIT 1
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- 4) Drop the 229 redirect — the category view now serves the content itself.
UPDATE core_url_rewrite SET target_path = 'catalog/category/view/id/180', options = '' WHERE category_id = 180 AND request_path = 'regional-franchising-application.html';
