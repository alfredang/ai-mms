-- 318: SG homepage carousel — same-origin fallback if R2 fails.
-- Banners are served from Cloudflare R2 (migration 315). Add an onerror handler to
-- each of the 3 slide <img>s so that if the R2 URL fails to load, the browser falls
-- back to the same-origin copy at /media/wysiwyg/<file>.jpg (files restored to the
-- repo, baked into the image). R2 stays primary; onerror only fires on failure.
--
-- Idempotent + SG-scoped: each REPLACE keys off the unique R2 filename immediately
-- followed by '" alt=' — a substring that exists ONLY before the onerror is injected
-- (afterwards it reads '...jpg" onerror=...'), so a re-run is a no-op. MY/GH partner
-- DBs never carry these SG R2 URLs, so they never match. The single-quote inside the
-- onerror JS is SQL-escaped as ''; the ';' in this.onerror=null;this.src is mid-line,
-- never at end-of-line, so apply.php's semicolon splitter is not tripped.

UPDATE cms_block SET content = REPLACE(content, 'wsq-skillsfuture-industry5-courses.jpg" alt=', 'wsq-skillsfuture-industry5-courses.jpg" onerror="this.onerror=null;this.src=''/media/wysiwyg/wsq-skillsfuture-industry5-courses.jpg''" alt=') WHERE identifier='block_slide1' AND content LIKE '%r2.dev/wysiwyg/wsq-skillsfuture-industry5-courses.jpg" alt=%';

UPDATE cms_block SET content = REPLACE(content, 'skillsfuture-ai-courses.jpg" />', 'skillsfuture-ai-courses.jpg" onerror="this.onerror=null;this.src=''/media/wysiwyg/skillsfuture-ai-courses.jpg''" />') WHERE identifier='block_slide2' AND content LIKE '%r2.dev/wysiwyg/skillsfuture-ai-courses.jpg" />%';

UPDATE cms_block SET content = REPLACE(content, 'wsq-skillsfuture-certification-exam-prep-courses.jpg" title=', 'wsq-skillsfuture-certification-exam-prep-courses.jpg" onerror="this.onerror=null;this.src=''/media/wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg''" title=') WHERE identifier='block_slide3' AND content LIKE '%r2.dev/wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg" title=%';
