-- 1329: TGS-2024049182 "WSQ - Business Transformation with Agentic AI and AI Agents"
--
-- Follow-up to 961 (the Copilot -> agentic-AI repurpose). Two gaps remain, both
-- confirmed against the LIVE prod page on 2026-09-05:
--
--   A. url_key gains the "wsq-" prefix (admin request):
--        business-transformation-with-agentic-ai-and-ai-agents
--     -> wsq-business-transformation-with-agentic-ai-and-ai-agents
--
--   B. The learning_outcomes cms/block still reads "Microsoft 365 Copilot".
--      961 deliberately skipped it, recording it as "byte-identical to the
--      supplied wording => no-op". That was wrong: the live block was never
--      retargeted, so the page still advertises Copilot outcomes under an
--      agentic-AI title. Rewritten here to the admin-supplied LO1-LO3.
--      (The supplied LO2 read "CAgentic AI" -- an obvious typo, corrected.)
--
-- Scope deliberately NOT touched (probed clean on the live page):
--   - name / meta_title / meta_description / meta_keyword / alt labels
--     / description (3 topics) / short_description (About This Course)
--     / trainerprofile / prerequisite -- all already correct from 961.
--   - Remaining "Copilot" strings on the page are the MEGAMENU, a genuine
--     learner REVIEW, and RELATED-COURSE names -- none belong to this course
--     (feedback_repurpose_page_grep_must_exclude_megamenu).
--   - certification / skills_framework / funding_and_grant / brochure blocks,
--     categories, tags, image paths.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => no-op.
-- The cms_block guard keys on the SKU-scoped identifier, absent on partners.
-- All text is clean ASCII (apply.php connects charset=utf8).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024049182' LIMIT 1);

SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpth := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');

-- ------------------------------------------------- A. url_key / url_path / 301

-- 1. Clear any is_system = 0 squatter already sitting on the NEW path, else the
--    INSERT IGNORE below silently no-ops against a stale row (see 647).
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-business-transformation-with-agentic-ai-and-ai-agents.html'
   AND is_system = 0 AND @e IS NOT NULL;

-- 2. Drop the product's OWN is_system = 1 rewrite holding the OLD bare slug.
--    Its id_path is 'product/773' -- the SAME id_path the 301 needs -- so
--    without this DELETE the INSERT IGNORE hits the unique key and creates
--    nothing, leaving the old URL 404ing AND making refreshProductRewrite mint
--    a "-773" suffixed slug for the new path.
--    (feedback_repurpose_301_needs_system_row_delete /
--     feedback_rename_301_vs_system_rewrite_suffix_trap)
DELETE FROM core_url_rewrite
 WHERE product_id = @e
   AND request_path = 'business-transformation-with-agentic-ai-and-ai-agents.html'
   AND is_system = 1 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'wsq-business-transformation-with-agentic-ai-and-ai-agents'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- 3. Explicit 301 for the old BARE slug -> new bare slug. The indexer auto-301s
--    the ~20 category paths; this row covers the canonical flat URL.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'business-transformation-with-agentic-ai-and-ai-agents.html',
       'wsq-business-transformation-with-agentic-ai-and-ai-agents.html',
       0, 'RP', '1329 wsq slug prefix'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- 4. Flatten the EXISTING 301 chain. Rows minted by 961 point at the OLD bare
--    slug; left alone they become 301 -> 301 -> 200. Re-anchor them on the new
--    path so every legacy URL resolves in a single hop.
--    (feedback_rename_chain_flatten_must_anchor_request_path)
UPDATE core_url_rewrite
   SET target_path = 'wsq-business-transformation-with-agentic-ai-and-ai-agents.html'
 WHERE target_path = 'business-transformation-with-agentic-ai-and-ai-agents.html'
   AND is_system = 0
   AND request_path <> 'business-transformation-with-agentic-ai-and-ai-agents.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------------- B. Learning Outcomes
-- Full-content write (not a REPLACE): the live block is a fixed 3-item list and
-- rewriting it whole is idempotent and immune to entity/CRLF drift
-- (feedback_multiline_replace_fails_on_crlf_blobs).
UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Anticipate and address potential issues in transitioning to Agentic AI and AI Agents.</li>
<li>LO2: Plan and implement a smooth transition from old systems to Agentic AI and AI Agents.</li>
<li>LO3: Identify opportunities to adopt emerging technologies and plan training for Agentic AI and AI Agents.</li>
</ul>'
 WHERE identifier = 'course_TGS-2024049182_learning_outcomes';
