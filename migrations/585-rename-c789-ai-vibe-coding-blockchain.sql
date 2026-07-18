-- Rename course C789 from "AI Vibe Coding for Web 3 Smart Contract" to
-- "AI Vibe Coding for Blockchain".
--
-- C789 was already repurposed into the AI Vibe Coding Series in migration 484
-- (badge, duration 15, price $700, 4 topics in the h3 format). This migration
-- is a TITLE-ONLY change on top of that:
--   name, meta_title, meta_description, cover image (re-rendered from the new
--   title), and the two subtopic lines whose wording named "Web 3 Development"
--   as the course framing.
-- The topic bodies are deliberately UNCHANGED -- Solidity, Ethereum, ERC-20 /
-- ERC-721 and dApps are exactly what "Blockchain" covers, so the syllabus is
-- already accurate under the new name.
--
-- NOT touched, and why:
--   duration / price / course_series_badge -- already 15 / 700 / set by 484.
--   funding block (485) -- already points at "WSQ - Develop Blockchain and
--     Web3 App with Vibe Coding", which matches the new name.
--   url_key -- intentionally unchanged (series rule: preserves URL + SEO).
--
-- Cover re-rendered 2026-07-18 and validated HTTP 200 on R2 before shipping.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C789.
-- Store scope 0, and clears per-store overrides so a partner scope cannot
-- shadow the new title. Idempotent. No content line ends in a semicolon.

SET @e     := (SELECT entity_id FROM catalog_product_entity WHERE sku='C789');
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_img  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

-- Name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Vibe Coding for Blockchain' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar WHERE entity_id=@e AND attribute_id=@a_name AND store_id<>0 AND @e IS NOT NULL;

-- Meta title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI Vibe Coding for Blockchain' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar WHERE entity_id=@e AND attribute_id=@a_mt AND store_id<>0 AND @e IS NOT NULL;

-- Meta description
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Vibe code blockchain applications with Cursor, GitHub Copilot and Claude in this hands-on 2-day course. Build Solidity smart contracts, ERC-20 tokens, NFTs and a full dApp from plain-English prompts.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text WHERE entity_id=@e AND attribute_id=@a_md AND store_id<>0 AND @e IS NOT NULL;

-- Image labels follow the course name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI Vibe Coding for Blockchain' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI Vibe Coding for Blockchain' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI Vibe Coding for Blockchain' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Cover re-rendered from the new title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C789-20260718-062852.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar WHERE entity_id=@e AND attribute_id=@a_img AND store_id<>0 AND @e IS NOT NULL;

-- Overview paragraphs opened by framing the course as "Web 3". Re-frame the
-- hook and the journey line to Blockchain; the rest of the copy (Solidity,
-- Ethereum, tokens, dApps) is accurate as-is. No-op once already applied.
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');

UPDATE catalog_product_entity_text
SET value = REPLACE(value, 'Build and ship Web 3 smart contracts without writing', 'Build and ship blockchain smart contracts without writing')
WHERE entity_id=@e AND attribute_id=@a_short AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value, 'you will vibe code the full Web 3 journey', 'you will vibe code the full blockchain journey')
WHERE entity_id=@e AND attribute_id=@a_short AND @e IS NOT NULL;

-- Two subtopic lines framed the course as "Web 3 Development" / "Web 3 Project".
-- Re-frame to Blockchain. REPLACE() is a no-op once already applied.
UPDATE catalog_product_entity_text
SET value = REPLACE(value, 'Setting Up Cursor, GitHub Copilot and Claude for Web 3 Development', 'Setting Up Cursor, GitHub Copilot and Claude for Blockchain Development')
WHERE entity_id=@e AND attribute_id=@a_desc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
SET value = REPLACE(value, 'Packaging and Demoing a Complete Web 3 Project', 'Packaging and Demoing a Complete Blockchain Project')
WHERE entity_id=@e AND attribute_id=@a_desc AND @e IS NOT NULL;
