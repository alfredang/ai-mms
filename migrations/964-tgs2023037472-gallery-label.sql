-- 964: Follow-up to 943 -- retarget the media-gallery label for TGS-2023037472.
--
-- 943 updated image_label / small_image_label / thumbnail_label but missed the
-- media GALLERY label, which is a separate table
-- (catalog_product_entity_media_gallery_value). The post-apply rendered-page
-- grep caught it: it feeds BOTH the cover anchor's title= and the <img alt=>,
-- so the old "Generative AI (GAI)" title was still visible on the page twice.
-- Separate file because 943 is already in the ledger and edited migrations
-- never re-run on prod.
--
-- Plain title, no 'WSQ - ' prefix, matching the *_label attrs 943 set (the
-- cover renderer strips the prefix -- Cover.php::cleanTitle).
-- NOTE: the cover PNG itself still bakes the old title; regenerate it from the
-- admin (Course Cover -> re-render) after this deploys.
--
-- Partner-safe: TGS- SKUs exist only on SG => no matching gallery row on MY/GH.
-- Idempotent: full-value SET.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037472' LIMIT 1);

UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'Business Innovation with Agentic AI and AI Agents'
 WHERE g.entity_id = @e AND @e IS NOT NULL;
