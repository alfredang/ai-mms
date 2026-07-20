-- Standardize TGS-2023035977 "What You'll Learn" topics to the standard
-- bullet-list markup (<ul><li><strong>) used by other WSQ courses (e.g.
-- TGS-2023037545), replacing the h3 headings shipped in migration 458.
-- Partner-safe: TGS- SKUs exist only on SG, so @e is NULL on MY/GH and the
-- statement is a no-op. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2023035977');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<ul>
<li><strong>Topic 1: Workflow Automation with n8n</strong></li>
<li><strong>Topic 2: Agentic Process Automation with AI Agents</strong></li>
<li><strong>Topic 3: Agentic Automation with Webhooks and HTTP Requests</strong></li>
<li><strong>Topic 4: Enhancing Workflow Automation with Agentic RAG</strong></li>
<li><strong>Topic 5: Human-in-the-Loop, Monitoring, and Security in n8n</strong></li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE @e IS NOT NULL AND entity_id=@e AND store_id<>0 AND attribute_id=@a_desc;
