-- 226: Fix footer "Our Websites" typo — "Tertiary Tabcard" -> "Tertiary Tapcard"
--      (matches the tapcard.tertiaryinfotech.com URL). SG footer CMS block 1.
--      Idempotent; no-op once corrected.

UPDATE cms_block SET content = REPLACE(content, 'Tertiary Tabcard', 'Tertiary Tapcard') WHERE block_id = 1 AND content LIKE '%Tertiary Tabcard%';
