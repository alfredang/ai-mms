-- 320: SG header WhatsApp icon → 18px (match the phone/email ic-lg font icons).
-- The inline WhatsApp SVG (migrations 316/317) rendered at 14x14, visibly smaller
-- than the neighbouring ic-phone / ic-letter glyphs which render at .ic-lg = 1.333em
-- (~18px on the header text). Bump width/height 14 -> 18 so all three icons match.
-- Single-line REPLACE, SG-scoped by the 61000613 hotline anchor so MY/GH partner DBs
-- are untouched.
UPDATE cms_block
SET content = REPLACE(content, 'width="14" height="14"', 'width="18" height="18"')
WHERE identifier = 'block_header_top_left'
  AND content LIKE '%61000613%'
  AND content LIKE '%width="14" height="14"%';
