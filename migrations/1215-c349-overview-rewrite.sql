-- 1215: Rewrite the "What's This Course About" overview for C349
-- "Multi AI Agents System for Digital Marketing" — three paragraphs, house
-- style matching C1164 (problem/premise -> hands-on build -> outcome).
--
-- Overview lives in short_description; the product page renders it in the
-- "What's This Course About" card. Store-level overrides are cleared so the
-- store-0 value wins. Duration is 15h (2 days), reflected in the copy.
--
-- SG-guarded; C-prefix SKU is SG-only (partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_psdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e349 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C349' LIMIT 1);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e349,
'<p>Digital marketing is being rebuilt around agentic AI. Instead of one person prompting a chatbot for a caption at a time, a multi AI agents system puts a whole marketing team to work &mdash; a market research agent, an SEO and keyword agent, a copywriter, a creative agent, a campaign scheduler and a performance analyst &mdash; that brief each other, review each other''s output and keep working while you sleep. In this hands-on 2-day course, you will learn to design, build and orchestrate those agent teams with leading multi-agent frameworks.</p><p>Through guided exercises, you will build agents that research your market and competitors, generate on-brand content and ad variants at scale, publish across channels on a schedule, then read the analytics and feed what they learn back into the next campaign. You will wire in human approval checkpoints, brand-voice guardrails and quality gates, so the system moves fast without putting your brand at risk.</p><p>By the end of the course, you will walk away with a working multi-agent marketing crew and a practical blueprint you can point at your own campaigns &mdash; turning weeks of manual content, reporting and optimisation work into a pipeline that runs on its own. Ideal for marketers, agency teams, founders and consultants who want the output of a full marketing department without the headcount.</p>'
FROM dual
WHERE @e349 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e349
  AND attribute_id = @a_psdesc
  AND store_id <> 0
  AND @e349 IS NOT NULL AND @is_sg > 0;
