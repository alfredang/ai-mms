-- 324: SG footer → drop the "(Disabled-Friendly)" suffix from the Contact Us address.
-- The footer Contact block (block_footer_column5, "Singapore Footer Row 1") rendered the
-- venue address ending in "Singapore 737715 (Disabled-Friendly)". Remove just the suffix,
-- leaving "Singapore 737715". Single-line REPLACE, SG-scoped by the exact "737715
-- (Disabled-Friendly)" literal (the Contact Us page block uses different <em> markup and
-- MY/GH partner DBs carry their own addresses), so the statement is a no-op everywhere else.
-- Idempotent: re-runs find nothing left to replace.
UPDATE cms_block
SET content = REPLACE(content, '737715 (Disabled-Friendly)', '737715')
WHERE identifier = 'block_footer_column5'
  AND content LIKE '%737715 (Disabled-Friendly)%';
