-- Drop orphaned SSG / SkillsFuture CMS content.
--
-- These CMS blocks and pages were only referenced by storefront
-- templates that have been removed in the same commit; the rows are now
-- dead code in the cms_block / cms_page tables. Site is going worldwide
-- so SkillsFuture-Singapore content is no longer relevant.
--
-- Idempotent — DELETE is naturally re-runnable as a no-op when the rows
-- are already gone.
--
-- NOT removed (intentional): cms_page rows whose TITLE happens to
-- mention SSG / SkillsFuture (id=3 / 72 / 73 — homepage and about-us).
-- Those are substantive pages whose body text and meta should be
-- rewritten through the Magento CMS admin rather than dropped.

DELETE FROM cms_block WHERE identifier IN ('skillsfuture', 'skillsfuturecredit');
DELETE FROM cms_page  WHERE identifier IN ('sfec.html');
