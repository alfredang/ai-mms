-- 229: ENQUIRIES menu cleanup.
--   * Remove "AI Chatbot" (cat 268) and "Tertiary Courses GPT" (cat 181) from
--     the Enquiries -> Support submenu (both are empty link-only categories).
--   * Rename "Regional Partnership" (cat 180) -> "Regional Franchisee" and point
--     its menu link at the franchise landing page (franchising-application.html)
--     via a permanent (RP) redirect on its flat category URL.
--
-- NOTE: the redirect lives on the category's own url_rewrite, so a future
-- "Catalog URL Rewrites" reindex can regenerate it back to the category view.
-- Re-run this migration (idempotent) after such a reindex if the link reverts.

DELETE FROM catalog_category_entity WHERE entity_id IN (181,268) AND path LIKE '1/2/172/260/%';

UPDATE catalog_category_entity_varchar v JOIN eav_attribute ea ON ea.attribute_id = v.attribute_id AND ea.attribute_code = 'name' AND ea.entity_type_id = 3 SET v.value = 'Regional Franchisee' WHERE v.entity_id = 180 AND v.value = 'Regional Partnership';

UPDATE core_url_rewrite SET target_path = 'franchising-application.html', options = 'RP' WHERE category_id = 180 AND request_path = 'regional-franchising-application.html';
