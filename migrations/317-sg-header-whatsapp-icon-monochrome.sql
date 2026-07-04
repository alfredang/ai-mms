-- 317: SG header WhatsApp icon → monochrome (match the phone/email font icons).
-- The inline WhatsApp SVG added in migration 316 was WhatsApp-green (#25D366);
-- recolour it to currentColor so it inherits the dark header text colour and reads
-- consistently next to the ic-phone / ic-letter glyphs. Single-line REPLACE, SG-scoped
-- by the 61000613 hotline anchor so MY/GH partner DBs are untouched.
UPDATE cms_block
SET content = REPLACE(content, 'fill="#25D366"', 'fill="currentColor"')
WHERE identifier = 'block_header_top_left'
  AND content LIKE '%61000613%'
  AND content LIKE '%fill="#25D366"%';
