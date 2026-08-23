-- 1080: Finish the TGS-2026064859 repurpose - "CASL - Business Transformation
-- with OpenClaw and NFT" -> "CASL - Autonomous AI Agents with OpenClaw".
--
-- An earlier pass already moved every other naming surface (url_key =
-- casl-autonomous-ai-agents-with-openclaw + 301s, meta_title,
-- meta_description, meta_keyword, image/alt labels, media-gallery label) and
-- fully repurposed the content surfaces (short_description, description
-- outline, whoshouldattend, trainerprofile course-teaching claims). This
-- migration closes the three remaining leaks:
--
--   1. `name` (store 0) still carried the old title. Keep the "CASL - "
--      segment prefix (SKU unchanged, CASL tag present).
--   2. `prerequisite` "Minimum Software/Hardware Requirement" still linked
--      the NFT-era Metamask Wallet. Swapped for OpenClaw, matching the house
--      shape used by the live OpenClaw courses. Targeted REPLACE on the one
--      <li> only - this attribute also holds the whole funding apparatus,
--      never rewrite it wholesale.
--   3. catalogsearch_query rows still pointed at the superseded
--      wsq-autonomous-ai-agents-with-openclaw.html slug, reaching the page
--      only through a 301 chain. Flattened to the live casl- slug. Anchored
--      on the FULL old filename so sibling "Autonomous AI Agents" courses
--      are untouched.
--
-- Funding Validity (news_from_date/news_to_date) is deliberately NOT touched:
-- migration 1068 already holds the SSG CASL-export window 2026-08-30 ->
-- 2027-08-29, confirmed correct.
--
-- Deliberately left alone: trainerprofile (the one NFT mention is a trainer's
-- career credential, not a course-teaching claim), image/small_image/thumbnail
-- (filesystem paths, not display text), description outline + all category
-- placements (already on-topic). The cover PNG is re-rendered out-of-band
-- (it bakes the title; SQL cannot regenerate it).
--
-- Idempotent: plain converging UPDATEs / no-op REPLACEs. Partner-safe: keyed
-- by TGS- SKU (MY/GH carry no TGS- SKUs, @pid is NULL there and every UPDATE
-- matches zero rows; the redirect flatten LIKE matches nothing off-SG).
-- ASCII-only values.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064859');
SET @name_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @prereq_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- 1. Course title (admin scope; no store-level overrides exist for name)
UPDATE catalog_product_entity_varchar
SET value = 'CASL - Autonomous AI Agents with OpenClaw'
WHERE entity_id = @pid
  AND attribute_id = @name_attr
  AND store_id = 0;

-- 2. Software requirement: Metamask Wallet (NFT era) -> OpenClaw
UPDATE catalog_product_entity_text
SET value = REPLACE(
    value,
    '<li><u><a href="https://metamask.io/" rel="noopener noreferrer" target="_blank">Metamask Wallet</a></u></li>',
    '<li>OpenClaw</li>'
)
WHERE entity_id = @pid
  AND attribute_id = @prereq_attr;

-- 3. Flatten search-redirect 301 chains onto the live casl- slug.
-- Full-filename anchor: does not touch the sibling courses
-- wsq-autonomous-ai-agents.html / wsq-ai-security-for-autonomous-ai-agents.html etc.
UPDATE catalogsearch_query
SET redirect = REPLACE(
    redirect,
    '/wsq-autonomous-ai-agents-with-openclaw.html',
    '/casl-autonomous-ai-agents-with-openclaw.html'
)
WHERE redirect LIKE '%/wsq-autonomous-ai-agents-with-openclaw.html';
