-- 938: TGS-2020504020 (WSQ - Internet of Things (IoT) Fundamental for
-- Beginners) — remove the inline "Course Brochure" section from the course
-- description so the brochure renders ONLY in the left-column Brochure card
-- (fed by the per-course cms/block), like every other course.
--
-- Why this one was missed by 887 (sitewide brochure -> cms_block) and 915
-- (the IBF stragglers): the heading is wrapped in a styled span —
--   <h2><span style="font-size: 1.5em;">Course Brochure</span></h2>
-- and view.phtml::$_extractSection only tolerates optional <br> before the
-- title text, so the regex fallback never saw it. Result: the section stayed
-- inline inside the "What's This Course About" card while the Brochure card
-- rendered the same link from its block — a visible double-render.
--
-- Data-only, per feedback_section_to_cms_block_move_is_data_only: view.phtml
-- already reads block-first, so no template change is needed here. The block
-- course_TGS-2020504020_brochure already EXISTS, is_active=1 and is populated
-- with the generated PDF link
-- (media/courses/brochures/TGS-2020504020-SG.pdf), so this is a pure strip —
-- nothing to seed, and the card keeps rendering after the strip.
--
-- The stripped chunk is the LAST thing in the description (no following
-- wrapper <div>/heading), so there is no next-section opener to preserve
-- (cf. feedback_section_strip_must_preserve_next_wrapper_div). Verified: 0
-- headings and 0 <div> remain after the strip.
--
-- Idempotent + partner-safe: exact-byte SKU-joined REPLACE, so it no-ops once
-- applied and no-ops on any partner row whose bytes differ. Literals are
-- hex-encoded for apply.php's utf8 connection.
--
-- Scope check on SG prod: only 2 store_id=0 rows still matched '%Brochure%'
-- — this one, and C23 (Adobe InDesign), whose hit is the word "brochures" in
-- prose with no brochure heading. C23 is intentionally untouched.
--
-- Paired with a view.phtml fix that makes $_extractSection tolerate inline
-- wrapper tags around a heading's title, so any future WYSIWYG-styled heading
-- self-heals via the regex fallback instead of double-rendering. Replaying
-- OLD vs NEW extraction over all 437 prod descriptions x 5 sections (2185
-- extractions) changed exactly 2 results, both pre-existing double-renders:
--   - TGS-2020504020 brochure      -> stripped by this migration
--   - TGS-2026064173 certification -> needs NO data change; on SG the
--     Certification card self-supplies from the hardcoded SKU template, so
--     the template fix alone removes its inline duplicate.
-- Zero other rows changed, so the widened pattern is regression-free.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- TGS-2020504020
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id AND e.sku = 0x5447532d32303230353034303230
   SET t.value = REPLACE(t.value, 0x3c68323e3c7370616e207374796c653d22666f6e742d73697a653a20312e35656d3b223e436f757273652042726f63687572653c2f7370616e3e3c2f68323e0d0a3c703e3c7370616e207374796c653d22746578742d6465636f726174696f6e3a20756e6465726c696e653b223e3c6120687265663d2268747470733a2f2f64726976652e676f6f676c652e636f6d2f66696c652f642f313968796d613347414e316b3538686746584748445630676162714f344637314a2f766965773f7573703d73686172696e6722207469746c653d22575351202d20496e7465726e6574206f66205468696e67732028496f54292046756e64616d656e74616c20666f7220426567696e6e6572732042726f636875726522207461726765743d225f626c616e6b223e446f776e6c6f616420575351202d20496e7465726e6574206f66205468696e67732028496f54292046756e64616d656e74616c20666f7220426567696e6e6572732042726f63687572653c2f613e3c2f7370616e3e3c2f703e, '')
 WHERE t.attribute_id = @a_sdesc AND t.store_id = 0;
