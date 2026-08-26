-- 1136: Seed the Learning Outcomes cms/block for TGS-2023035977
-- (WSQ - Agentic AI Automation with n8n).
--
-- Purely ADDITIVE. Probed prod 2026-08-27: entity_id 877 exists with
-- sibling blocks (brochure / certification / skills_framework /
-- funding_and_grant) but NO `course_TGS-2023035977_learning_outcomes`
-- block, and short_description carries NO inline Learning Outcomes
-- section for the regex fallback -- it is the four-paragraph About-This-
-- Course narrative only. So the Learning Outcomes card renders nothing
-- at all today; seeding the block is what makes it appear. Nothing to
-- strip from short_description.
--
-- The requested Course Outline (5 topics) and About This Course text
-- already match prod byte-for-byte (description + short_description,
-- store 0, no store-scoped overrides), so this migration deliberately
-- touches neither.
--
-- Block content is the section BODY only, no <h2> heading: the card
-- supplies its own. Shape + "LOn: " label convention copied from 1075
-- (course_TGS-2026064536_learning_outcomes). "ifor" typo in the supplied
-- LO2 corrected to "for".
--
-- Idempotent per [[feedback_cms_block_identifier_has_no_unique_key]]:
-- cms_block has ONLY PRIMARY KEY(block_id) -- no unique index on
-- `identifier`, so ON DUPLICATE KEY UPDATE would never fire and each
-- re-apply would insert a DUPLICATE row. Hence guarded INSERT (NOT
-- EXISTS, via the derived-table wrapper MySQL requires when the subquery
-- names the INSERT target) + an unconditional UPDATE, which converges to
-- exactly one correct row no matter how many times it runs.
--
-- Partner-safe: TGS- SKUs exist only on SG. @e is NULL on MY/GH, the
-- guarded INSERT is gated on @e IS NOT NULL so it inserts nothing, and
-- the UPDATE matches no row. cms_block_store gets store_id 0 (all
-- stores), matching every sibling course block.

SET @sku   := 'TGS-2023035977';
SET @e     := (SELECT entity_id FROM catalog_product_entity WHERE sku = @sku LIMIT 1);
SET @ident := CONCAT('course_', @sku, '_learning_outcomes');
SET @title := CONCAT('Course ', @sku, ' Learning Outcomes');

-- Body as UNHEX so the exact bytes are pinned and no client-charset or
-- quoting layer can mangle them in transit. Decodes to:
--   <p>By the end of the course, learners will be able to</p>
--   <ul><li>LO1: Identify required functions based on business needs and
--   design applications accordingly</li><li>LO2: Analyse business drivers
--   to design and apply search techniques for expected outcomes</li>
--   <li>LO3: Decompose complex scenarios into subproblems and resolve
--   them using cooperative intelligent subsystems</li><li>LO4: Design
--   cooperative reasoning modules and create hybrid systems using
--   suitable techniques and programming</li><li>LO5: Build hybrid
--   reasoning systems fusing appropriate techniques and sub-modules</li></ul>
SET @lo_body := UNHEX('3C703E42792074686520656E64206F662074686520636F757273652C206C6561726E6572732077696C6C2062652061626C6520746F3C2F703E3C756C3E3C6C693E4C4F313A204964656E746966792072657175697265642066756E6374696F6E73206261736564206F6E20627573696E657373206E6565647320616E642064657369676E206170706C69636174696F6E73206163636F7264696E676C793C2F6C693E3C6C693E4C4F323A20416E616C79736520627573696E657373206472697665727320746F2064657369676E20616E64206170706C792073656172636820746563686E697175657320666F72206578706563746564206F7574636F6D65733C2F6C693E3C6C693E4C4F333A204465636F6D706F736520636F6D706C6578207363656E6172696F7320696E746F2073756270726F626C656D7320616E64207265736F6C7665207468656D207573696E6720636F6F706572617469766520696E74656C6C6967656E742073756273797374656D733C2F6C693E3C6C693E4C4F343A2044657369676E20636F6F706572617469766520726561736F6E696E67206D6F64756C657320616E6420637265617465206879627269642073797374656D73207573696E67207375697461626C6520746563686E697175657320616E642070726F6772616D6D696E673C2F6C693E3C6C693E4C4F353A204275696C642068796272696420726561736F6E696E672073797374656D7320667573696E6720617070726F70726961746520746563686E697175657320616E64207375622D6D6F64756C65733C2F6C693E3C2F756C3E');

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT @title, @ident, @lo_body, NOW(), NOW(), 1
FROM dual
WHERE @e IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = @ident) x
  );

UPDATE cms_block
   SET title       = @title,
       content     = @lo_body,
       is_active   = 1,
       update_time = NOW()
 WHERE identifier = @ident
   AND @e IS NOT NULL;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b WHERE b.identifier = @ident;
