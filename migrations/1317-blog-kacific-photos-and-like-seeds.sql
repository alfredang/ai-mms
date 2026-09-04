-- 1317: Kacific case study -- add the two class photos to the post body, and seed
-- display like counts (100-200) on the published posts that were still at 0.
-- Both were applied LIVE on prod first (blog content/likes are data, not code);
-- this file keeps a rebuilt DB in the same state. SG-only, fully idempotent.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

-- Photos: R2 objects uploaded 2026-09-04, both verified HTTP 200.
-- Guarded on the image basename so a re-run cannot double-insert the figures.
UPDATE mmd_blog_post
   SET content = REPLACE(content, '<h2>Who Kacific is, and why their workflow is hard</h2>', CONCAT('<figure class="mmd-blog-figure"><img src="https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/kacific-2026-09-alfred-rocket.jpg" alt="Dr. Alfred Ang at the Kacific Satellite Broadband office in Singapore, beside a model of the Ariane launch vehicle." /><figcaption>Dr. Alfred Ang at Kacific&rsquo;s Singapore office, next to an Arianespace/ESA launcher model &mdash; a fitting backdrop for three days of agentic AI training with a satellite operator.</figcaption></figure>', ' ', '<h2>Who Kacific is, and why their workflow is hard</h2>'))
 WHERE @is_sg = 1 AND url_key = 'agentic-ai-training-kacific-satellite-broadband-erp-case-study'
   AND content NOT LIKE '%kacific-2026-09-alfred-rocket%';

UPDATE mmd_blog_post
   SET content = REPLACE(content, '<h2>What the team actually learned</h2>', CONCAT('<figure class="mmd-blog-figure"><img src="https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/kacific-2026-09-team-selfie.jpg" alt="Dr. Alfred Ang with a member of the Kacific team during the three-day agentic AI training programme." /><figcaption>With the Kacific team between sessions. The class ran 2&ndash;4 September 2026.</figcaption></figure>', ' ', '<h2>What the team actually learned</h2>'))
 WHERE @is_sg = 1 AND url_key = 'agentic-ai-training-kacific-satellite-broadband-erp-case-study'
   AND content NOT LIKE '%kacific-2026-09-team-selfie%';

-- Like seeds. `AND likes = 0` means real storefront likes are never overwritten,
-- and a re-run after genuine likes accrue is a no-op.
UPDATE mmd_blog_post SET likes = 122 WHERE @is_sg = 1 AND url_key = 'adobe-illustrator-course-singapore-wsq-graphic-design' AND likes = 0;
UPDATE mmd_blog_post SET likes = 178 WHERE @is_sg = 1 AND url_key = 'autocad-technical-drawing-course-singapore-wsq-guide' AND likes = 0;
UPDATE mmd_blog_post SET likes = 155 WHERE @is_sg = 1 AND url_key = 'e-invoicing-quickbooks-online-singapore-invoicenow' AND likes = 0;
UPDATE mmd_blog_post SET likes = 151 WHERE @is_sg = 1 AND url_key = 'free-premium-ai-subscriptions-singapore-2026' AND likes = 0;
UPDATE mmd_blog_post SET likes = 141 WHERE @is_sg = 1 AND url_key = 'gpt-6-astra-agi-era-agentic-ai-codex' AND likes = 0;
UPDATE mmd_blog_post SET likes = 116 WHERE @is_sg = 1 AND url_key = 'lean-six-sigma-green-belt-training-singapore-wsq-guide' AND likes = 0;
UPDATE mmd_blog_post SET likes = 122 WHERE @is_sg = 1 AND url_key = 'power-apps-power-automate-with-copilot-guide-singapore' AND likes = 0;
UPDATE mmd_blog_post SET likes = 165 WHERE @is_sg = 1 AND url_key = 'project-management-with-generative-ai-wsq-guide' AND likes = 0;
UPDATE mmd_blog_post SET likes = 115 WHERE @is_sg = 1 AND url_key = 'swda-utap-ai-tools-subscription-maximise-both' AND likes = 0;

