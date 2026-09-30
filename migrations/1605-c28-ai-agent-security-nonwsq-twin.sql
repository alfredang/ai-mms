-- C28 AI Agent Security = non-WSQ twin of TGS-2025060473
-- (WSQ - AI Security for Autonomous AI Agents), converted to a 1-day course.
--
-- 1. Fee $700 -> $350 (1 day at the standard $350/day), every scope row.
-- 2. Duration tile 15 -> 7.5 hrs; Sessions tile 2 -> 1.
-- 3. Funding block pointed at the WSQ twin (it still named the previous course's
--    WSQ Vibe Coding parent).
-- 4. Prerequisite software: the recycled entity still listed XAMPP from its previous
--    PHP life; replaced with what the activities actually use.
--
-- Description + topics already match the parent (verified on prod 2026-09-30), and C28
-- plus the parent already sit in AI Security Series (category 214) — nothing to do.
-- The schedule template (A06) is switched through the code path, not SQL.
--
-- Every statement joins on the TGS- parent, so partner sites (no parent) are no-ops.
-- Idempotent: re-running writes the same values.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity c ON c.entity_id = d.entity_id AND TRIM(c.sku) = 'C28'
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.attribute_code = 'price' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
   SET d.value = 350;

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C28'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'duration' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
   SET v.value = '7.5';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C28'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'sessions' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
   SET v.value = '1';

UPDATE cms_block b
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
   SET b.content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-security-for-autonomous-ai-agents.html" title="WSQ - AI Security for Autonomous AI Agents">WSQ - AI Security for Autonomous AI Agents</a></span></p>'
 WHERE b.identifier = 'course_C28_funding_and_grant';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C28'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'prerequisite' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
   SET t.value = CONCAT(
         SUBSTRING_INDEX(t.value, '<h2>Minimum Software/Hardware Requirement</h2>', 1),
         '<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<ul>\n<li>A modern web browser (Chrome, Edge or Safari)</li>\n<li>WhatsApp on your phone</li>\n<li><a href="https://hermes-agent.nousresearch.com" target="_blank"><span style="text-decoration: underline;">Hermes Agent</span></a> desktop app, with a free <a href="https://www.minimax.io" target="_blank"><span style="text-decoration: underline;">MiniMax</span></a> account for a low-limit training API key</li>\n</ul>\n<p><strong>Hardware:</strong> Windows and Mac Laptops</p>')
 WHERE t.value LIKE '%apachefriends%';
