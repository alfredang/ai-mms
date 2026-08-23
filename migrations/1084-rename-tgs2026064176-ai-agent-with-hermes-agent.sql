-- 1084-rename-tgs2026064176-ai-agent-with-hermes-agent.sql
--
-- Rename TGS-2026064176 "CASL - Build Agentic AI and NLP Applications with
-- Langflow" -> "CASL - AI Agent with Hermes Agent" (SKU unchanged, so every
-- SkillsFuture / SFEC / SFC / PSEA deep link keyed on the course code stays valid).
--
-- PROBE-FIRST RESULT (SG prod, 2026-08-23): an earlier session had already
-- migrated MOST surfaces to the Hermes Agent topic. Verified already-correct and
-- therefore NOT touched here:
--   url_key/url_path (casl-ai-agent-with-hermes-agent), the ~10 is_system
--   category rewrites + the 301s off both old slugs, meta_title (correctly plain,
--   no baked "WSQ"/brand — MMD_Seotitle composes those at render time),
--   meta_description, meta_keyword, short_description, description outline,
--   image_label / small_image_label / thumbnail_label / media-gallery label,
--   prerequisite (tool links are Python/VSCode/Anaconda/Colab — still in scope),
--   all 11 category placements, tags (CASL/SFEC/PSEA/MCES/Absentee Payroll).
--
-- Deliberately left alone (hits that are NOT leaks):
--   * image / small_image / thumbnail hold the uploaded JPG's filesystem path
--     (/w/s/wsq-build-agentic-ai-...jpg). They are paths, not display text — the
--     storefront renders the R2 course_image_url cover. Renaming them 404s the file.
--   * trainerprofile: the NLP mentions are genuine trainer CREDENTIALS (para 1
--     career history) and in-scope course skills (NLP models, LLM integration);
--     every course-teaching paragraph already reads "In 'AI Agent with Hermes
--     Agent,'". No leak.
--
-- This migration closes the three surfaces that were still on the old topic:
--   1. name              — still the full old Langflow title
--   2. whoshouldattend   — 15 job roles, all NLP/text-mining era
--   3. catalogsearch_query.redirect — rows still pointing at the superseded
--      wsq-build-agentic-ai-and-nlp-applications-with-langflow.html slug
--   4. meta_title        — PRE-EXISTING bug this rename is the moment to fix:
--      the stored value baked in both "WSQ" and the brand suffix that
--      MMD_Seotitle adds at render time, so the live <title> read
--      "WSQ funded WSQ AI Agent with Hermes Agent | Tertiary Courses Singapore"
--      (duplicated WSQ). Store the PLAIN title; the composer adds the rest.
--
-- Store-guarded: SG only (the TGS- SKU exists only on the SG site).
-- Idempotent: every statement is a guarded UPDATE keyed on the old value.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064176');

-- ---------------------------------------------------------------------------
-- Surface 1: name. Keep the "CASL - " segment prefix (SKU unchanged).
-- ---------------------------------------------------------------------------
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = 4);

UPDATE catalog_product_entity_varchar
   SET value = 'CASL - AI Agent with Hermes Agent'
 WHERE entity_id = @pid
   AND attribute_id = @a_name
   AND value LIKE '%Langflow%';

-- ---------------------------------------------------------------------------
-- Surface 2: whoshouldattend. Re-point the 15 NLP-era job roles at their
-- agentic-AI equivalents. Full-value replace guarded on the old first role.
-- ---------------------------------------------------------------------------
SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'whoshouldattend' AND entity_type_id = 4);

UPDATE catalog_product_entity_text
   SET value = CONCAT(
       '<ul>',
       '<li>AI Agent Developer</li>',
       '<li>AI Engineer</li>',
       '<li>Machine Learning Engineer (agentic AI focus)</li>',
       '<li>Data Scientist</li>',
       '<li>AI Research Scientist (large language models)</li>',
       '<li>Chatbot Developer</li>',
       '<li>Automation Engineer</li>',
       '<li>AI Solutions Architect</li>',
       '<li>Conversational AI Designer</li>',
       '<li>Workflow Automation Specialist</li>',
       '<li>RAG and Knowledge Systems Engineer</li>',
       '<li>Business Process Automation Analyst</li>',
       '<li>Prompt Engineer</li>',
       '<li>Software Developer (AI integration)</li>',
       '<li>IT Operations Engineer.</li>',
       '</ul>')
 WHERE entity_id = @pid
   AND attribute_id = @a_wsa
   AND value LIKE '%NLP Engineer%';

-- ---------------------------------------------------------------------------
-- Surface 4: meta_title — plain title only. MMD_Seotitle prepends "WSQ funded"
-- for any SG TGS- SKU (Block/Html/Head.php::_fundingPrefix) and appends the
-- brand postfix, so baking either in yields a duplicated "WSQ".
-- ---------------------------------------------------------------------------
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_title' AND entity_type_id = 4);

UPDATE catalog_product_entity_varchar
   SET value = 'AI Agent with Hermes Agent'
 WHERE entity_id = @pid
   AND attribute_id = @a_mt
   AND value <> 'AI Agent with Hermes Agent';

-- ---------------------------------------------------------------------------
-- Surface 3: catalogsearch_query.redirect — retarget rows still pointing at the
-- superseded slug. Anchored on the FULL old filename so no sibling course's
-- rows are swept up. Terms whose INTENT is the retired Langflow/NLP topic are
-- retargeted deliberately: this is a repurpose, and the course code + the
-- course-title queries follow the course to its new page.
-- ---------------------------------------------------------------------------
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/casl-ai-agent-with-hermes-agent.html'
 WHERE redirect LIKE '%wsq-build-agentic-ai-and-nlp-applications-with-langflow.html%';

-- The bare-slug 301 already exists in core_url_rewrite for both old slugs
-- (wsq-build-agentic-ai-and-nlp-applications-with-langflow.html and
-- wsq-ai-agent-with-hermes-agent.html), so no rewrite row is inserted here.

-- ---------------------------------------------------------------------------
-- Mirror name into the flat table when flat catalog is on (guarded: the column
-- and table only exist on sites with flat catalog built).
-- ---------------------------------------------------------------------------
SET @has_flat := (SELECT COUNT(*) FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_product_flat_1');
SET @sql := IF(@has_flat > 0,
  'UPDATE catalog_product_flat_1 SET name = ''CASL - AI Agent with Hermes Agent'' WHERE entity_id = @pid AND name LIKE ''%Langflow%''',
  'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
