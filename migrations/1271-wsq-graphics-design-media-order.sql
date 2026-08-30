-- 1271: WSQ Graphics Design & Media Courses (url_key
-- 'wsq-graphics-design-media-courses') — remove two courses and pin the
-- requested order for the remaining twenty.
--
-- REMOVED from this category:
--   TGS-2023039835  WSQ - Business Innovation with Metaverse and Immersive Technologies
--   TGS-2023040473  WSQ - AI for Unity 2D and 3D Game Development
-- This category is a child of WSQ Media & Marketing (cat 72), which per
-- migration 1265 lists only courses reachable through its sub-categories.
-- UNLIKE the 1267/1269 removals, both of these remain in ANOTHER child of 72
-- (Metaverse -> WSQ Immersive AR 397, Unity -> WSQ Gaming 376), so they must
-- KEEP their rows on the parent — no parent cleanup here. Deliberate: deleting
-- them from 72 would wrongly drop them off the Media & Marketing listing.
--
-- Requested order (all twenty are TGS-; the category holds no C-prefix course,
-- so the nightly sweep's alphabetical pass has nothing to reorder and it
-- preserves TGS relative order — no curated-allowlist entry needed):
--   1  TGS-2026064178  CASL - Infographics and Data Visualization with PowerPoint
--   2  TGS-2026064718  CASL - Master Mobile Photography
--   3  TGS-2024042308  WSQ - Mastering Articulate Storyline 360
--   4  TGS-2025056983  WSQ - Generative AI for Script Development and Storytelling
--   5  TGS-2021003585  WSQ - Professional Digital Image Editing with Photoshop
--   6  TGS-2021003160  WSQ - Creating Professional Graphics with Adobe Illustrator
--   7  TGS-2026064712  CASL - Mastering Adobe Lightroom for Photo Editing
--   8  TGS-2021007827  WSQ - Creating Stunning Print and Digital Publications with InDesign
--   9  TGS-2026065048  CASL - Compositing and Visual Effects with After Effects
--  10  TGS-2026064536  CASL - Video Editing with Premiere Pro
--  11  TGS-2023037829  WSQ - Creative Digital Art and Design
--  12  TGS-2026064709  CASL - UI Design with AI
--  13  TGS-2024045220  WSQ - Generative AI (GenAI) Visuals in Photoshop and Firefly
--  14  TGS-2024042369  WSQ - Exploring the Art of Visual Communication with Canva
--  15  TGS-2024045798  WSQ - Figma Fundamentals for Aspiring UI/UX Designers
--  16  TGS-2021010046  WSQ - Mastering UI Design Techniques for Web and Mobile
--  17  TGS-2024043855  WSQ - Creating Engaging Videos with Generative AI (GenAI)
--  18  TGS-2020505925  WSQ - Generative AI for Image and Video Creation
--  19  TGS-2023036088  WSQ - Agentic AI for Video Creation
--  20  TGS-2026065705  WSQ - 3D Modelling with Blender for Beginners
--
-- Negative positions keep the pinned block ahead of anything unpinned.
-- Business-key lookups only. Idempotent.

SET @gd := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-graphics-design-media-courses' LIMIT 1);

-- 1. Remove the two courses from this category (parent rows deliberately kept) -

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @gd AND @gd IS NOT NULL
  AND p.sku IN ('TGS-2023039835','TGS-2023040473');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @gd AND @gd IS NOT NULL
  AND p.sku IN ('TGS-2023039835','TGS-2023040473');

-- 2. Pin the requested order --------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064178' THEN -20
  WHEN 'TGS-2026064718' THEN -19
  WHEN 'TGS-2024042308' THEN -18
  WHEN 'TGS-2025056983' THEN -17
  WHEN 'TGS-2021003585' THEN -16
  WHEN 'TGS-2021003160' THEN -15
  WHEN 'TGS-2026064712' THEN -14
  WHEN 'TGS-2021007827' THEN -13
  WHEN 'TGS-2026065048' THEN -12
  WHEN 'TGS-2026064536' THEN -11
  WHEN 'TGS-2023037829' THEN -10
  WHEN 'TGS-2026064709' THEN  -9
  WHEN 'TGS-2024045220' THEN  -8
  WHEN 'TGS-2024042369' THEN  -7
  WHEN 'TGS-2024045798' THEN  -6
  WHEN 'TGS-2021010046' THEN  -5
  WHEN 'TGS-2024043855' THEN  -4
  WHEN 'TGS-2020505925' THEN  -3
  WHEN 'TGS-2023036088' THEN  -2
  WHEN 'TGS-2026065705' THEN  -1
END
WHERE cp.category_id = @gd AND @gd IS NOT NULL
  AND p.sku IN ('TGS-2026064178','TGS-2026064718','TGS-2024042308','TGS-2025056983',
                'TGS-2021003585','TGS-2021003160','TGS-2026064712','TGS-2021007827',
                'TGS-2026065048','TGS-2026064536','TGS-2023037829','TGS-2026064709',
                'TGS-2024045220','TGS-2024042369','TGS-2024045798','TGS-2021010046',
                'TGS-2024043855','TGS-2020505925','TGS-2023036088','TGS-2026065705');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064178' THEN -20
  WHEN 'TGS-2026064718' THEN -19
  WHEN 'TGS-2024042308' THEN -18
  WHEN 'TGS-2025056983' THEN -17
  WHEN 'TGS-2021003585' THEN -16
  WHEN 'TGS-2021003160' THEN -15
  WHEN 'TGS-2026064712' THEN -14
  WHEN 'TGS-2021007827' THEN -13
  WHEN 'TGS-2026065048' THEN -12
  WHEN 'TGS-2026064536' THEN -11
  WHEN 'TGS-2023037829' THEN -10
  WHEN 'TGS-2026064709' THEN  -9
  WHEN 'TGS-2024045220' THEN  -8
  WHEN 'TGS-2024042369' THEN  -7
  WHEN 'TGS-2024045798' THEN  -6
  WHEN 'TGS-2021010046' THEN  -5
  WHEN 'TGS-2024043855' THEN  -4
  WHEN 'TGS-2020505925' THEN  -3
  WHEN 'TGS-2023036088' THEN  -2
  WHEN 'TGS-2026065705' THEN  -1
END
WHERE i.category_id = @gd AND @gd IS NOT NULL
  AND p.sku IN ('TGS-2026064178','TGS-2026064718','TGS-2024042308','TGS-2025056983',
                'TGS-2021003585','TGS-2021003160','TGS-2026064712','TGS-2021007827',
                'TGS-2026065048','TGS-2026064536','TGS-2023037829','TGS-2026064709',
                'TGS-2024045220','TGS-2024042369','TGS-2024045798','TGS-2021010046',
                'TGS-2024043855','TGS-2020505925','TGS-2023036088','TGS-2026065705');
