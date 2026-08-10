-- 911: "Download SWDA SOA" guide page + Enquiries mega-menu link rename/repair
-- 1) New CMS page how-to-download-swda-soa.html (SEO guide, all stores), replacing the
--    dead myskillsfuture download-cert.html link (HTTP 500).
-- 2) Category "Download SWDA (formerly SSG) SOA" (url_key download-ssg-soa) renamed to
--    "Download SWDA SOA" and its umm_cat_target repointed at the new page (relative, so
--    it resolves on every partner domain). Store-scoped overrides removed (262 pattern).
-- 3) SEO meta backfill for the two sibling guide pages (only where NULL/empty).
-- Idempotent; partner-safe (category lookup by url_key at any store; no-op if absent).

INSERT INTO cms_page (title, root_template, meta_keywords, meta_description, identifier, content_heading, content, creation_time, update_time, is_active, sort_order)
SELECT 'How to Download SWDA SOA (Statement of Attainment)', 'one_column', 'download SWDA SOA, SSG SOA download, WSQ statement of attainment, download statement of attainment, MySkillsFuture SOA, OpenCerts SOA, SkillsFuture certificate download', 'Download your WSQ Statement of Attainment (SOA) from SWDA (formerly SSG) in 6 steps: log in to MySkillsFuture with Singpass, open your Skills Passport and download your verifiable OpenCerts e-certificate.', 'how-to-download-swda-soa.html', NULL,
'<style>.page-title,.page-title h1{text-align:center}</style><style>
.tcf{font-family:inherit;color:#0f172a;line-height:1.6;max-width:900px;margin:0 auto}
.tcf *{box-sizing:border-box}
.tcf-hero{background:linear-gradient(135deg,#0f172a,#14304a 60%,#0d9488 130%);color:#fff;border-radius:18px;padding:42px 38px;margin:0 0 34px}
.tcf-hero .e{color:#5eead4;font-weight:700;letter-spacing:.08em;text-transform:uppercase;font-size:12.5px;margin:0 0 10px}
.tcf-hero h1{color:#fff;font-size:32px;line-height:1.15;margin:0 0 12px;font-weight:800}
.tcf-hero p{color:#cbd5e1;font-size:17px;max-width:720px;margin:0}
.tcf-steps{position:relative;margin:0 0 32px;padding:0}
.tcf-step{position:relative;display:flex;gap:20px;padding:0 0 26px 0}
.tcf-step:last-child{padding-bottom:0}
.tcf-step:before{content:"";position:absolute;left:23px;top:46px;bottom:-4px;width:2px;background:linear-gradient(#0d9488,#cbd5e1)}
.tcf-step:last-child:before{display:none}
.tcf-num{flex:0 0 46px;height:46px;width:46px;border-radius:50%;background:#0d9488;color:#fff;font-weight:800;font-size:19px;display:flex;align-items:center;justify-content:center;box-shadow:0 6px 16px rgba(13,148,136,.32);z-index:1}
.tcf-card{flex:1;background:#fff;border:1px solid #e6e9ef;border-radius:14px;padding:18px 22px;box-shadow:0 8px 22px rgba(15,23,42,.05)}
.tcf-card h3{margin:0 0 6px;font-size:18px;font-weight:700;color:#0f172a}
.tcf-card p{margin:0;color:#475569;font-size:15px}
.tcf-card a{color:#0d9488;font-weight:600}
.tcf-note{background:#ecfdf5;border:1px solid #a7f3d0;border-radius:12px;padding:16px 20px;color:#065f46;font-size:14.5px;margin:0 0 30px}
.tcf-note strong{color:#047857}
.tcf-faq{margin:0 0 32px}
.tcf-faq h2{font-size:24px;font-weight:800;color:#0f172a;margin:0 0 16px;text-align:center}
.tcf-faq details{background:#fff;border:1px solid #e6e9ef;border-radius:12px;padding:14px 20px;margin:0 0 10px}
.tcf-faq summary{font-weight:700;color:#0f172a;cursor:pointer;font-size:16px}
.tcf-faq details p{color:#475569;font-size:15px;margin:10px 0 0}
.tcf-faq details a{color:#0d9488;font-weight:600}
.tcf-cta{text-align:center;margin:0 0 34px}
.tcf-cta a{display:inline-block;background:#f4511e;color:#fff;font-weight:700;padding:14px 32px;border-radius:999px;text-decoration:none;font-size:16px;margin:6px 8px}
.tcf-cta a:hover{background:#d63c0c;color:#fff}
.tcf-cta a.sec{background:#fff;color:#0d9488;border:2px solid #0d9488}
.tcf-cta a.sec:hover{background:#ecfdf5;color:#0d9488}
.tcf-rel{background:#f8fafc;border:1px solid #e6e9ef;border-radius:14px;padding:22px 26px;margin:0 0 8px}
.tcf-rel h2{font-size:19px;font-weight:800;color:#0f172a;margin:0 0 10px}
.tcf-rel ul{margin:0;padding:0 0 0 20px}
.tcf-rel li{color:#475569;font-size:15px;margin:0 0 6px}
.tcf-rel a{color:#0d9488;font-weight:600}
@media(max-width:600px){.tcf-hero h1{font-size:25px}.tcf-hero{padding:30px 22px}.tcf-num{flex-basis:40px;width:40px;height:40px;font-size:17px}.tcf-step:before{left:20px}}
</style><div class="tcf"><div class="tcf-hero"><p class="e">WSQ Statement of Attainment (SOA)</p><h1>How to Download Your SWDA SOA</h1><p>Completed a WSQ course? Your Statement of Attainment (SOA) is issued digitally by the SkillsFuture Workforce Development Agency &mdash; SWDA (formerly SSG) &mdash; as a secure, verifiable OpenCerts e-certificate. Follow these steps to download your SOA from the MySkillsFuture portal.</p></div>
<div class="tcf-steps">
<div class="tcf-step"><div class="tcf-num">1</div><div class="tcf-card"><h3>Complete Your WSQ Course &amp; Assessment</h3><p>Attend at least 75% of your WSQ course at <a href="https://www.tertiarycourses.com.sg/">Tertiary Infotech</a> and pass the assessment. We then submit your attendance and assessment results to SWDA (formerly SSG) for verification.</p></div></div>
<div class="tcf-step"><div class="tcf-num">2</div><div class="tcf-card"><h3>Wait for SWDA to Issue Your SOA</h3><p>SWDA typically issues the digital SOA within 2&ndash;4 weeks of course completion, after verifying your attendance and assessment results. No action is needed from you during this time.</p></div></div>
<div class="tcf-step"><div class="tcf-num">3</div><div class="tcf-card"><h3>Log in to MySkillsFuture with Singpass</h3><p>Go to the <a href="https://www.myskillsfuture.gov.sg/content/portal/en/individual/skills-passport.html" target="_blank" rel="noopener">MySkillsFuture Skills Passport</a> page and log in with your Singpass.</p></div></div>
<div class="tcf-step"><div class="tcf-num">4</div><div class="tcf-card"><h3>Open Your Skills Passport</h3><p>From your MySkillsFuture dashboard, select &ldquo;Skills Passport&rdquo;. It lists all your WSQ qualifications and Statements of Attainment.</p></div></div>
<div class="tcf-step"><div class="tcf-num">5</div><div class="tcf-card"><h3>Download Your SOA</h3><p>Locate the SOA for your course and download it. You will receive an OpenCerts (.opencerts) e-certificate file &mdash; the official, tamper-proof digital version of your SOA.</p></div></div>
<div class="tcf-step"><div class="tcf-num">6</div><div class="tcf-card"><h3>View, Print &amp; Share on OpenCerts</h3><p>Drag and drop the downloaded file into <a href="https://www.opencerts.io/" target="_blank" rel="noopener">OpenCerts.io</a> to view, print or share your SOA. Employers can verify its authenticity instantly &mdash; no hard copy needed.</p></div></div>
</div>
<div class="tcf-note"><strong>Tip:</strong> SOA not showing after 4 weeks? <a href="{{store direct_url="contacts"}}">Contact our support team</a> with your course title and course start date and we will follow up with SWDA (formerly SSG) on your behalf.</div>
<div class="tcf-faq"><h2>SWDA SOA &mdash; Frequently Asked Questions</h2>
<details><summary>What is a Statement of Attainment (SOA)?</summary><p>An SOA is the official certificate issued by SWDA (formerly SSG) confirming you have attained a WSQ competency standard. It is nationally recognised by employers in Singapore and issued digitally as an OpenCerts e-certificate.</p></details>
<details><summary>How long after my course will my SOA be ready?</summary><p>Typically 2&ndash;4 weeks after course completion. SWDA first verifies your attendance and assessment results submitted by the training provider before issuing the SOA.</p></details>
<details><summary>Is my old SSG SOA still valid?</summary><p>Yes. SkillsFuture Singapore (SSG) has been renamed the SkillsFuture Workforce Development Agency (SWDA). SOAs issued under SSG remain fully valid and are downloadable from MySkillsFuture the same way.</p></details>
<details><summary>Can I get a hard copy of my SOA?</summary><p>SOAs are digital-first. Open your .opencerts file at <a href="https://www.opencerts.io/" target="_blank" rel="noopener">OpenCerts.io</a> and use the print option to produce a paper copy whenever you need one.</p></details>
<details><summary>What is the difference between an SOA and a Certificate of Completion?</summary><p>Tertiary Infotech issues a Certificate of Completion for every course you complete. The SOA is issued separately by SWDA (formerly SSG) and only for WSQ courses &mdash; it certifies the national competency standard you attained.</p></details>
</div>
<div class="tcf-cta"><a href="{{store url=''''}}wsq-ibf-skillsfuture-utap-funded-courses.html">Browse WSQ Funded Courses</a><a class="sec" href="{{store direct_url="contacts"}}">Ask Us About Your SOA</a></div>
<div class="tcf-rel"><h2>Related Guides</h2><ul>
<li><a href="{{store url=''''}}how-to-claim-skillsfuture-credit.html">How to Claim SkillsFuture Credit</a></li>
<li><a href="{{store url=''''}}how-to-register-wsq-course.html">How to Register a WSQ Course</a></li>
<li><a href="{{store url=''''}}psea-submission/">Submit PSEA Form</a></li>
</ul></div>
</div>
<script type="application/ld+json">{"@context":"https://schema.org","@graph":[{"@type":"HowTo","name":"How to Download Your SWDA SOA (Statement of Attainment)","description":"Step-by-step guide to downloading your WSQ Statement of Attainment (SOA) issued by SWDA (formerly SSG) from the MySkillsFuture portal as an OpenCerts e-certificate.","totalTime":"P28D","step":[{"@type":"HowToStep","position":1,"name":"Complete your WSQ course and assessment","text":"Attend at least 75% of your WSQ course and pass the assessment. The training provider submits your attendance and results to SWDA (formerly SSG)."},{"@type":"HowToStep","position":2,"name":"Wait for SWDA to issue your SOA","text":"SWDA typically issues the digital SOA within 2 to 4 weeks of course completion."},{"@type":"HowToStep","position":3,"name":"Log in to MySkillsFuture with Singpass","text":"Go to the MySkillsFuture Skills Passport page and log in with your Singpass."},{"@type":"HowToStep","position":4,"name":"Open your Skills Passport","text":"From your MySkillsFuture dashboard, select Skills Passport to see your WSQ qualifications and Statements of Attainment."},{"@type":"HowToStep","position":5,"name":"Download your SOA","text":"Locate the SOA for your course and download the OpenCerts e-certificate file."},{"@type":"HowToStep","position":6,"name":"View, print and share on OpenCerts","text":"Drag and drop the file into OpenCerts.io to view, print or share your verifiable SOA."}]},{"@type":"FAQPage","mainEntity":[{"@type":"Question","name":"What is a Statement of Attainment (SOA)?","acceptedAnswer":{"@type":"Answer","text":"An SOA is the official certificate issued by SWDA (formerly SSG) confirming you have attained a WSQ competency standard. It is issued digitally as an OpenCerts e-certificate."}},{"@type":"Question","name":"How long after my course will my SOA be ready?","acceptedAnswer":{"@type":"Answer","text":"Typically 2 to 4 weeks after course completion, once SWDA verifies your attendance and assessment results."}},{"@type":"Question","name":"Is my old SSG SOA still valid?","acceptedAnswer":{"@type":"Answer","text":"Yes. SSG has been renamed SWDA, and SOAs issued under SSG remain fully valid and downloadable from MySkillsFuture."}},{"@type":"Question","name":"Can I get a hard copy of my SOA?","acceptedAnswer":{"@type":"Answer","text":"SOAs are digital-first. Open your OpenCerts file at OpenCerts.io and use the print option for a paper copy."}},{"@type":"Question","name":"What is the difference between an SOA and a Certificate of Completion?","acceptedAnswer":{"@type":"Answer","text":"The Certificate of Completion is issued by the training provider for every course. The SOA is issued by SWDA (formerly SSG) only for WSQ courses and certifies the national competency standard attained."}}]}]}</script>',
NOW(), NOW(), 1, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM cms_page WHERE identifier = 'how-to-download-swda-soa.html');

INSERT IGNORE INTO cms_page_store (page_id, store_id)
SELECT page_id, 0 FROM cms_page WHERE identifier = 'how-to-download-swda-soa.html';

SET @etype := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'url_key');
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'name');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'meta_title');
SET @a_target := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'umm_cat_target');
SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id = @a_urlkey AND value = 'download-ssg-soa' LIMIT 1);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @cat AND attribute_id IN (@a_name, @a_mtitle, @a_target) AND store_id <> 0;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_name, 0, @cat, 'Download SWDA SOA' FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 'Download SWDA SOA';

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_mtitle, 0, @cat, 'Download SWDA SOA' FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 'Download SWDA SOA';

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_target, 0, @cat, 'how-to-download-swda-soa.html' FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 'how-to-download-swda-soa.html';

UPDATE cms_page SET meta_description = 'Step-by-step guide to claim SkillsFuture Credit for Tertiary Infotech courses: log in to MySkillsFuture with Singpass, submit a claim and offset your course fees.'
WHERE identifier = 'how-to-claim-skillsfuture-credit.html' AND (meta_description IS NULL OR meta_description = '');

UPDATE cms_page SET meta_keywords = 'claim SkillsFuture credit, SkillsFuture credit claim, how to use SkillsFuture credit, MySkillsFuture claim, SkillsFuture claimable courses Singapore'
WHERE identifier = 'how-to-claim-skillsfuture-credit.html' AND (meta_keywords IS NULL OR meta_keywords = '');

UPDATE cms_page SET meta_description = 'How to register a WSQ course at Tertiary Infotech step by step: choose your course run, enrol online and apply SkillsFuture funding and subsidies.'
WHERE identifier = 'how-to-register-wsq-course.html' AND (meta_description IS NULL OR meta_description = '');

UPDATE cms_page SET meta_keywords = 'register WSQ course, WSQ course registration, WSQ funded courses Singapore, SkillsFuture WSQ courses, WSQ training Singapore'
WHERE identifier = 'how-to-register-wsq-course.html' AND (meta_keywords IS NULL OR meta_keywords = '');
