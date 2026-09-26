-- 1568: TGS-2026065050 "CASL - Generative AI for Finance and Fintech"
--       -> "CASL - Microsoft Copilot for Finance"
--
-- The course keeps its SKU (every SkillsFuture / SFEC / PSEA deep link is
-- keyed on it), its CASL prefix + 7 funding tags, its TSC (skills_framework
-- block: "Digital Technology Adoption and Innovation ACC-ICT-5004-1.1"), all
-- 20 categories (already in Microsoft Copilot Series, 357), trainers, price,
-- duration (32) and sessions (4).
--
-- Name + slug keep the "CASL" prefix: non-WSQ twin C057 (entity 157) is live
-- and already owns "Microsoft Copilot for Finance" and the bare slug
-- microsoft-copilot-for-finance (precedent: 937, 956).
--
-- Deliberately NOT touched (already correct on prod, verified 2026-09-27):
--   * cms_block course_TGS-2026065050_learning_outcomes -- LO1-LO5 match the
--     supplied outcomes (LO4 differs only by a straight vs curly apostrophe).
--   * brochure / certification / skills_framework / funding_and_grant blocks.
--   * whoshouldattend, prerequisite (no old-title reference).
--   * image / small_image / thumbnail PATHS (filesystem paths).
--
-- Rewritten here:
--   * name, url_key, url_path, meta_title, meta_description, meta_keyword
--   * short_description -- the supplied 6-paragraph "About This Course".
--   * description -- the supplied 5-topic outline, headings-only house shape.
--   * image_label / small_image_label / thumbnail_label + media-gallery label
--     (the cover alt text).
--   * course_image_url -> re-rendered R2 cover (title is baked into the PNG),
--     rendered on prod with the product's own badge set, HTTP 200, 156681 bytes:
--       course-covers/TGS-2026065050-20260926-162818.png
--     Guarded on SG's old URL so partner sites no-op.
--   * trainerprofile -- five "In &ldquo;Generative AI for Finance and
--     Fintech,&rdquo;" course references -> new title; bios otherwise untouched.
--   * URL rewrites: every is_system=1 path on the old slug (bare + category
--     prefixes) becomes a permanent 301 to the flat new slug under its own
--     id_path; every pre-existing 301 that targets an old path is flattened
--     onto the new slug (one hop).
--   * on-site search redirects on the old CASL / WSQ / GAI slugs -> new slug.
--
-- Post-deploy on prod (the indexer, not this SQL, mints the canonical
-- is_system=1 row): refreshProductRewrite(1084), flat reindex, cache flush.
--
-- SG production only; keyed by SKU so a site without it no-ops. Idempotent.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026065050' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------- name / slug / metas
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
   SET v.value = CASE a.attribute_code
         WHEN 'name'             THEN 'CASL - Microsoft Copilot for Finance'
         WHEN 'url_key'          THEN 'casl-microsoft-copilot-for-finance'
         WHEN 'url_path'         THEN 'casl-microsoft-copilot-for-finance.html'
         WHEN 'meta_title'       THEN 'CASL Microsoft Copilot for Finance | Tertiary Courses Singapore'
         WHEN 'meta_description' THEN 'Apply Microsoft Copilot, Copilot in Excel and Copilot Studio to financial analysis, reporting, AI agents and multi-agent finance workflows, with PDPA-aware AI governance. Funding available.'
         ELSE 'CASL - Microsoft Copilot for Finance'
       END
 WHERE v.entity_id = @pid AND @pid IS NOT NULL
   AND a.attribute_code IN ('name','url_key','url_path','meta_title','meta_description',
                            'image_label','small_image_label','thumbnail_label');

-- media-gallery label = the alt text the product page actually renders
UPDATE catalog_product_entity_media_gallery_value g
  JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
   SET g.label = 'CASL - Microsoft Copilot for Finance'
 WHERE m.entity_id = @pid AND @pid IS NOT NULL;

SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = 'Microsoft Copilot for Finance, CASL Copilot finance course, Copilot in Excel financial analysis, Copilot Studio finance agents, multi-agent finance workflows, AI governance finance, Generative AI finance Singapore, Agentic AI finance'
 WHERE attribute_id = @a_mk AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- About This Course
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_sd, 0, @pid, CONCAT(
  '<p><strong>Microsoft Copilot for Finance</strong> equips participants with practical knowledge and skills to apply Generative AI, Agentic AI, AI agents, Microsoft Copilot, and automation technologies to improve financial analysis, reporting, decision-making, and business processes.</p>',
  '<p>The course begins with an overview of Generative AI, Agentic AI, and AI agents, exploring how these technologies can support finance use cases such as financial analysis, forecasting, reporting, reconciliation, data interpretation, and process automation.</p>',
  '<p>Participants will develop hands-on skills using Microsoft Excel and Copilot for financial data analysis, visualisation, and dashboard creation. They will learn to analyse financial datasets, identify trends and variances, generate insights, and communicate financial performance through effective charts, reports, and dashboards.</p>',
  '<p>The course also introduces Microsoft Copilot Studio for designing workflows and AI agents that automate finance-related tasks. Participants will progress to multi-agent workflows, where specialised AI agents collaborate to perform interconnected finance activities, coordinate tasks, analyse information, and support business decisions.</p>',
  '<p>Emphasis is placed on responsible and secure AI adoption, including PDPA considerations, data privacy, data ownership, access controls, human-in-the-loop oversight, governance, and frameworks for managing AI risks.</p>',
  '<p>Finally, participants will learn how to analyse business and finance requirements, identify suitable AI opportunities, design AI-enabled processes, evaluate feasibility and risks, and develop an implementation approach for AI transformation within the finance function.</p>')
  FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- Course Outline
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_desc, 0, @pid, CONCAT(
  '<h3 class="course-topic-h3">Topic 1: Microsoft Copilot and Generative AI for Finance</h3>',
  '<h3 class="course-topic-h3">Topic 2: Microsoft Copilot in Excel for Financial Analysis and Visualisation</h3>',
  '<h3 class="course-topic-h3">Topic 3: Microsoft Copilot Studio for Finance Workflow and AI Agents</h3>',
  '<h3 class="course-topic-h3">Topic 4: Microsoft Copilot for AI Security, Governance and Risk Management</h3>',
  '<h3 class="course-topic-h3">Topic 5: Microsoft Copilot for Finance Transformation and Multi-Agent Workflows</h3>')
  FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- store-0 copy is what every scope serves
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @pid AND @pid IS NOT NULL
   AND attribute_id IN (@a_sd, @a_desc, @a_mk) AND store_id <> 0;

-- ---------------------------------------------------------------- trainer bios
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '&ldquo;Generative AI for Finance and Fintech,&rdquo;', '&ldquo;Microsoft Copilot for Finance,&rdquo;')
 WHERE attribute_id = @a_tp AND entity_id = @pid AND @pid IS NOT NULL
   AND value LIKE '%&ldquo;Generative AI for Finance and Fintech,&rdquo;%';

-- ---------------------------------------------------------------- cover
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
   SET v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026065050-20260926-162818.png'
 WHERE v.entity_id = @pid AND @pid IS NOT NULL
   AND a.attribute_code = 'course_image_url'
   AND v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026065050-20260729-035340.png';

-- ---------------------------------------------------------------- URL rewrites
-- Every old system path (bare + category-prefixed) becomes a custom 301 to the
-- flat new slug under its OWN id_path. The system rows are deleted first: a 301
-- left on id_path product/<id> blocks the indexer from minting the new
-- canonical row, and INSERT IGNORE onto the same id_path silently no-ops.
DROP TEMPORARY TABLE IF EXISTS tmp_1568_old;
CREATE TEMPORARY TABLE tmp_1568_old AS
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @pid IS NOT NULL AND is_system = 1 AND product_id = @pid
   AND (request_path = 'casl-generative-ai-for-finance-and-fintech.html'
        OR request_path LIKE '%/casl-generative-ai-for-finance-and-fintech.html');

DELETE r FROM core_url_rewrite r
  JOIN tmp_1568_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

-- clear any non-system squatter on the NEW paths
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND (request_path = 'casl-microsoft-copilot-for-finance.html'
        OR request_path LIKE '%/casl-microsoft-copilot-for-finance.html');

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/tgs2026065050-copilot-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'casl-microsoft-copilot-for-finance.html', 0, 'RP',
       '1568: TGS-2026065050 renamed to Microsoft Copilot for Finance'
  FROM tmp_1568_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_1568_old;

-- flatten every legacy 301 that pointed at an old path, so all resolve in one hop
UPDATE core_url_rewrite
   SET target_path = 'casl-microsoft-copilot-for-finance.html', options = 'RP'
 WHERE is_system = 0
   AND (target_path = 'casl-generative-ai-for-finance-and-fintech.html'
        OR target_path LIKE '%/casl-generative-ai-for-finance-and-fintech.html');

-- ---------------------------------------------------------------- search redirects
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/casl-microsoft-copilot-for-finance.html'
 WHERE redirect IN ('https://www.tertiarycourses.com.sg/casl-generative-ai-for-finance-and-fintech.html',
                    'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-finance-and-fintech.html',
                    'https://www.tertiarycourses.com.sg/generative-ai-gai-for-finance-and-fintech.html');
