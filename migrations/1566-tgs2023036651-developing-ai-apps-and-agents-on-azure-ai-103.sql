-- 1566: TGS-2023036651 "WSQ - Microsoft Certified Azure AI Engineer Associate
--       (AI-102) Training" -> "WSQ - Developing AI Apps and Agents on Azure (AI-103)"
--
-- Microsoft is replacing exam AI-102 with AI-103 (Azure AI Apps and Agents
-- Developer Associate). The course keeps its SKU (every SkillsFuture / SFEC /
-- PSEA deep link is keyed on it), its TSC (skills_framework block: "Artificial
-- Intelligence Application in Product Development ICT-TEM-4034-1.1"), its
-- 7 funding tags, all 20 categories, trainers, price ($900), duration (16)
-- and sessions (2).
--
-- Deliberately NOT touched (already correct on prod, verified 2026-09-27):
--   * cms_block course_TGS-2023036651_learning_outcomes -- LO1-LO3 are
--     byte-identical to the supplied outcomes.
--   * brochure / certification / skills_framework / funding_and_grant blocks.
--   * whoshouldattend (role list is framework-neutral Azure AI roles).
--   * prerequisite (no AI-102 reference; holds the funding apparatus).
--   * image / small_image / thumbnail PATHS (filesystem paths).
--
-- Rewritten here:
--   * name, url_key, url_path
--   * meta_title -- stored value started with "WSQ" and the live <title> read
--     "WSQ funded WSQ AI-102 ..." (MMD_Seotitle prepends "WSQ funded" at
--     render time). New value starts at the course name.
--   * meta_description (<= 255), meta_keyword
--   * short_description -- the supplied 4-paragraph "About This Course".
--   * description -- the supplied 5-heading course outline, headings-only
--     house shape (<h3 class="course-topic-h3">), replacing the 6 AI-102
--     topics + their LSN_DATA comment.
--   * image_label / small_image_label / thumbnail_label + media-gallery label
--     (the cover alt text) -> plain title, no "WSQ - " prefix.
--   * course_image_url -> re-rendered R2 cover (title is baked into the PNG),
--     rendered on prod with the product's own badge set, HTTP 200, 188461 bytes:
--       course-covers/TGS-2023036651-20260926-162023.png
--     Guarded on SG's old URL so partner sites (no TGS- SKUs anyway) no-op.
--   * cms_block course_TGS-2023036651_certification_exam -- the exam link
--     pointed at the AI-102 (azure-ai-engineer) credential; now the AI-103
--     credential page (verified 200).
--   * trainerprofile -- five course-teaching sentences said "AI-102 program"
--     / "AI-102 certification"; token swap to AI-103 only, credentials and
--     career history untouched. Single-token REPLACE, so CRLF-safe.
--   * URL rewrites: every is_system=1 path on the old slug (bare + 20
--     category prefixes) becomes a permanent 301 to the flat new slug under its
--     own id_path; the 61 pre-existing 301s that still target an old path are
--     flattened onto the new slug (one hop).
--   * on-site search redirects: rows on the current slug and on the 2023
--     "ai-102-designing-and-implementing-...-exam-prep" slug -> new slug;
--     the bare "C926" term -> C926's own (non-WSQ AI-103) page.
--
-- Post-deploy on prod (the indexer, not this SQL, mints the canonical
-- is_system=1 row): refreshProductRewrite(1442), flat reindex, cache flush,
-- regenerate sitemaps.
--
-- SG production only; keyed by SKU so a site without it no-ops. Idempotent.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023036651' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------- name / slug / metas
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
   SET v.value = CASE a.attribute_code
         WHEN 'name'             THEN 'WSQ - Developing AI Apps and Agents on Azure (AI-103)'
         WHEN 'url_key'          THEN 'wsq-developing-ai-apps-and-agents-on-azure-ai-103'
         WHEN 'url_path'         THEN 'wsq-developing-ai-apps-and-agents-on-azure-ai-103.html'
         WHEN 'meta_title'       THEN 'Developing AI Apps and Agents on Azure (AI-103) Course | Tertiary Courses Singapore'
         WHEN 'meta_description' THEN 'Learn to build generative AI apps and AI agents on Microsoft Azure with Microsoft Foundry, RAG, computer vision, text analysis and information extraction. Prepares you for the AI-103 exam. Up to 70% WSQ funding subsidy.'
         ELSE 'Developing AI Apps and Agents on Azure (AI-103)'
       END
 WHERE v.entity_id = @pid AND @pid IS NOT NULL
   AND a.attribute_code IN ('name','url_key','url_path','meta_title','meta_description',
                            'image_label','small_image_label','thumbnail_label');

-- media-gallery label = the alt text the product page actually renders
UPDATE catalog_product_entity_media_gallery_value g
  JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
   SET g.label = 'Developing AI Apps and Agents on Azure (AI-103)'
 WHERE m.entity_id = @pid AND @pid IS NOT NULL;

SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = 'AI-103, Developing AI Apps and Agents on Azure, Azure AI Apps and Agents Developer Associate, Microsoft Foundry, Azure AI Agents, Generative AI on Azure, Retrieval-Augmented Generation, Azure AI Course, Azure AI Training, Microsoft Azure AI Certification'
 WHERE attribute_id = @a_mk AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- About This Course
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_sd, 0, @pid, CONCAT(
  '<p>Developing AI Apps and Agents on Azure (AI-103) equips learners with the practical knowledge and skills to design, develop, deploy, and manage intelligent AI applications and autonomous agents using Microsoft Azure AI technologies. The course focuses on building modern AI solutions that combine generative AI, AI agents, enterprise data, and cloud-based AI services to address real-world business requirements.</p>',
  '<p>Learners will explore how to develop generative AI applications using Microsoft Foundry, foundation models, and related Azure AI services. They will learn to select and configure suitable AI models, design effective prompts, integrate AI capabilities into applications, and apply retrieval-augmented generation (RAG) to create solutions grounded in organisational data.</p>',
  '<p>The course also introduces agentic AI development, enabling learners to build AI agents that can reason, use tools, access knowledge sources, and perform multi-step tasks. Participants will gain hands-on experience developing and orchestrating agents, integrating external services and APIs, and designing agent-based workflows that support business process automation and decision-making.</p>',
  '<p>Throughout the course, learners will apply responsible AI, security, content safety, evaluation, monitoring, and optimisation practices to improve the reliability and performance of their solutions. Through practical exercises and real-world scenarios, participants will develop end-to-end AI applications and agents on Azure, preparing them to apply these capabilities effectively within modern enterprise environments.</p>')
  FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- Course Outline
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_desc, 0, @pid, CONCAT(
  '<h3 class="course-topic-h3">Topic 1: Plan and Manage an Azure AI Solution</h3>',
  '<h3 class="course-topic-h3">Topic 2: Implement Generative AI and Agentic Solutions</h3>',
  '<h3 class="course-topic-h3">Topic 3: Implement Computer Vision Solutions</h3>',
  '<h3 class="course-topic-h3">Topic 4: Implement Text Analysis Solutions</h3>',
  '<h3 class="course-topic-h3">Topic 5: Implement Information Extraction Solutions</h3>')
  FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- store-0 copy is what every scope serves
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @pid AND @pid IS NOT NULL
   AND attribute_id IN (@a_sd, @a_desc, @a_mk) AND store_id <> 0;

-- ---------------------------------------------------------------- trainer bios
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'AI-102', 'AI-103')
 WHERE attribute_id = @a_tp AND entity_id = @pid AND @pid IS NOT NULL
   AND value LIKE '%AI-102%';

-- ---------------------------------------------------------------- certification exam block
UPDATE cms_block
   SET content = REPLACE(REPLACE(content,
        'https://learn.microsoft.com/en-us/credentials/certifications/azure-ai-engineer/?practice-assessment-type=certification',
        'https://learn.microsoft.com/en-us/credentials/certifications/azure-ai-apps-and-agents-developer-associate/'),
        'title="AI-102"', 'title="AI-103"')
 WHERE identifier = 'course_TGS-2023036651_certification_exam';

-- ---------------------------------------------------------------- cover
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
   SET v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036651-20260926-162023.png'
 WHERE v.entity_id = @pid AND @pid IS NOT NULL
   AND a.attribute_code = 'course_image_url'
   AND v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036651-20260717-163438.png';

-- ---------------------------------------------------------------- URL rewrites
-- Every old system path (bare + category-prefixed) becomes a custom 301 to the
-- flat new slug under its OWN id_path. The system rows are deleted first: a 301
-- left on id_path product/<id> blocks the indexer from minting the new
-- canonical row, and INSERT IGNORE onto the same id_path silently no-ops.
DROP TEMPORARY TABLE IF EXISTS tmp_1566_old;
CREATE TEMPORARY TABLE tmp_1566_old AS
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @pid IS NOT NULL AND is_system = 1 AND product_id = @pid
   AND (request_path = 'wsq-microsoft-certified-azure-ai-engineer-associate-ai-102-training.html'
        OR request_path LIKE '%/wsq-microsoft-certified-azure-ai-engineer-associate-ai-102-training.html');

DELETE r FROM core_url_rewrite r
  JOIN tmp_1566_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

-- clear any non-system squatter on the NEW paths
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND (request_path = 'wsq-developing-ai-apps-and-agents-on-azure-ai-103.html'
        OR request_path LIKE '%/wsq-developing-ai-apps-and-agents-on-azure-ai-103.html');

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/tgs2023036651-ai102-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'wsq-developing-ai-apps-and-agents-on-azure-ai-103.html', 0, 'RP',
       '1566: TGS-2023036651 renamed to Developing AI Apps and Agents on Azure (AI-103)'
  FROM tmp_1566_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_1566_old;

-- flatten every legacy 301 that pointed at an old path, so all resolve in one hop
UPDATE core_url_rewrite
   SET target_path = 'wsq-developing-ai-apps-and-agents-on-azure-ai-103.html', options = 'RP'
 WHERE is_system = 0
   AND (target_path = 'wsq-microsoft-certified-azure-ai-engineer-associate-ai-102-training.html'
        OR target_path LIKE '%/wsq-microsoft-certified-azure-ai-engineer-associate-ai-102-training.html');

-- ---------------------------------------------------------------- search redirects
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-developing-ai-apps-and-agents-on-azure-ai-103.html'
 WHERE redirect IN ('https://www.tertiarycourses.com.sg/wsq-microsoft-certified-azure-ai-engineer-associate-ai-102-training.html',
                    'https://www.tertiarycourses.com.sg/ai-102-designing-and-implementing-a-microsoft-azure-ai-solution-exam-prep.html')
   AND query_text <> 'C926';

-- "C926" is the non-WSQ AI-103 twin's own course code; send it to its own page
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/ai-103-microsoft-certified-azure-ai-apps-and-agents-developer-associate.html'
 WHERE query_text = 'C926'
   AND redirect = 'https://www.tertiarycourses.com.sg/ai-102-designing-and-implementing-a-microsoft-azure-ai-solution-exam-prep.html';
