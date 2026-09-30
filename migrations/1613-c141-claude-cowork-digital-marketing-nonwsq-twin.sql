-- C141 Claude Cowork for Digital Marketing = non-WSQ twin of TGS-2023018659
-- (WSQ - Claude Cowork for Digital Marketing). Both run 2 days; C141 is 15 hrs / $700.
--
-- Already correct on the storefront, so not touched here: price $700, duration 15,
-- sessions 2, short_description (identical to the parent), the funding block (already
-- links /wsq-claude-cowork-for-digital-marketing.html) and the schedule template
-- (B05, the counterpart of the parent's (SG) WSQ-B05).
--
-- 1. Course topics (`description`, store 0) copied verbatim from the WSQ parent so the
--    page carries the parent's LSN_DATA topic JSON (same three topics).
-- 2. meta_description drops the "2-day" day count.
--
-- Every statement joins on the TGS- parent, so partner sites (no parent) are no-ops.
-- Idempotent: re-running writes the same values.

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C141'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018659'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value)
   AND pt.value NOT LIKE '%WSQ%'
   AND pt.value NOT LIKE '%day%';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C141'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'meta_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018659'
   SET v.value = 'Use Claude Cowork as an AI workspace for digital marketing - connect MCP tools, build reusable Claude Skills and analyse campaign performance at Tertiary Courses Singapore.';
