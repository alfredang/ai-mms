-- C437 Claude Certified Architect - Foundations (CCAR-F) Exam Prep: two extra tiles at the FRONT of
-- the "Why Take This Course?" card (view.phtml prepends cms/block course_<SKU>_why_take, same
-- mechanism as C1098 / 1837):
--   1. Free Practice Exam -> exams.tertiaryinfotech.com CCAR-F practice exam.
--   2. Register with Our Claude Partner Network (text only, no link).
-- Also: the "Bonus: Free Practice Exams" card links to the CCAR-F exam instead of the portal home
-- (course_C437_practice_exams), the certification-exam block says learners can register under our
-- Claude Partner Network, and the legacy `trainers` multiselect (stale ids 364/443/31) is set to
-- Dr. Alfred Ang's profile (courses_trainers 1) -- he is the sole trainer (mmd_product_trainer + bio, 1834).
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C437' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);
SET @pe  := 'https://exams.tertiaryinfotech.com/practice-exams/anthropic/anthropic-cca-foundations';

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT t.title, t.identifier, '', NOW(), NOW(), 1
  FROM (SELECT 'Course C437 - Why Take This Course' AS title, 'course_C437_why_take' AS identifier
        UNION ALL SELECT 'Course C437 - Practice Exams', 'course_C437_practice_exams') t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block b WHERE b.identifier = t.identifier);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier IN ('course_C437_why_take', 'course_C437_practice_exams');

UPDATE cms_block
   SET content = CONCAT(
'<li class="why-tile why-tile--practice"><span class="why-tile__icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span>',
'<strong class="why-tile__title">Free Practice Exam</strong>',
'<span class="why-tile__text">Test yourself on realistic scenario questions across all 5 CCAR-F exam domains before you book the real exam. <a href="', @pe, '" target="_blank" rel="noopener">Start the free practice exam &rarr;</a></span></li>',
'<li class="why-tile why-tile--partner"><span class="why-tile__icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg></span>',
'<strong class="why-tile__title">Register with Our Claude Partner Network</strong>',
'<span class="why-tile__text">Official Claude exams are open only through the Claude Partner Network. Register with our partner network to access the Anthropic Partner Academy and book your CCAR-F exam.</span></li>'),
       is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C437_why_take';

UPDATE cms_block
   SET content = CONCAT(
'<p>Get exam-ready on our free <strong>CCAR-F Practice Exam</strong> &mdash; realistic scenario questions across all 5 official exam domains, in <strong>Practice Mode</strong> and timed <strong>Exam Mode</strong>, which you can retake as many times as you like before the real exam.</p>',
'<p><a class="practice-exam-cta" href="', @pe, '" target="_blank" rel="noopener">Start Practising &rarr;</a></p>'),
       is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C437_practice_exams';

UPDATE cms_block
   SET content = REPLACE(content,
         'registration requires a company email address on the organisation&rsquo;s partner record.',
         'registration requires a company email address on the organisation&rsquo;s partner record; if your organisation is not a member, you can register with our Claude Partner Network.'),
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C437_certification_exam'
   AND LOCATE('register with our Claude Partner Network', content) = 0;

-- Legacy trainers multiselect -> Dr. Alfred Ang only.
SET @a_tr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainers');
-- courses_trainers is read via PREPARE so a partner DB whose schema lacks it is never parsed.
SET @t_alfred := NULL;
SET @has_ct := (SELECT COUNT(*) FROM information_schema.columns
                 WHERE table_schema = DATABASE() AND table_name = 'courses_trainers' AND column_name = 'linkedin_url');
SET @q := IF(@ok AND @has_ct = 1,
  'SET @t_alfred := (SELECT MIN(trainers_id) FROM courses_trainers WHERE TRIM(title) = ''Alfred Ang'' AND linkedin_url LIKE ''%linkedin.com/in/angchewhoe%'')',
  'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
UPDATE catalog_product_entity_text SET value = @t_alfred
 WHERE @ok AND @t_alfred IS NOT NULL AND entity_id = @pid AND attribute_id = @a_tr;
DELETE FROM catalog_product_entity_text
 WHERE @ok AND @t_alfred IS NOT NULL AND entity_id = @pid AND attribute_id = @a_tr AND store_id <> 0;
