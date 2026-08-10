-- 919: "Register an IBF Course" guide page + Enquiries mega-menu item; retire footer link
-- 1) New CMS page how-to-register-ibf-course.html — SEO/lead-magnet step-by-step guide
--    modeled on how-to-register-wsq-course.html (913 pattern: tcf styles, HowTo + FAQ
--    JSON-LD, CTA buttons). Facts sourced from the live course_TGS-*_funding_and_grant
--    blocks (50% SC<40/PR, 70% SC 40+, from 1 Jan 2024; SFC ex-Additional; UTAP caps)
--    and the existing footer links (TG form forms.gle/GbBM6rAjpSkKg56m7, video guide
--    youtu.be/d1KLYrgq6FM — the video moves into the page instead of the footer).
-- 2) New mega-menu category "Register an IBF Course" under SWDA (formerly SSG) Support
--    (parent 260), position 3 — directly after "Register a WSQ Course" (428, pos 2) —
--    umm_cat_target -> the new page (relative, 913 pattern). Category creation follows
--    the 322/326 recipe (path='' placeholder then UPDATE; ancestor children_count bump).
-- 3) Footer block block_footer_row2_column5: remove the old
--    "Step by Step Guide for IBF Courses" youtube <li> (REPLACE no-ops once removed).
-- SG-guarded (IBF-STS is Singapore-only funding): every insert is gated on the SG
-- marker category url_key='course-development-service', so MY/GH partner DBs no-op.
-- Idempotent: NOT EXISTS page guard, @pre category guard, ON DUPLICATE KEY EAV writes.
-- After deploy: reindex catalog_url + catalog_category_flat, then flush cache (menu
-- block HTML is cached 1h).

SET @etype := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'url_key');
SET @sg := (SELECT COUNT(*) FROM catalog_category_entity_varchar WHERE attribute_id = @a_urlkey AND value = 'course-development-service');

-- 1) CMS page ---------------------------------------------------------------

INSERT INTO cms_page (title, root_template, meta_keywords, meta_description, identifier, content_heading, content, creation_time, update_time, is_active, sort_order)
SELECT 'How to Register an IBF Course', 'one_column', 'register IBF course, IBF course registration, IBF-STS funded courses Singapore, IBF-STS training grant, IBF funding Singapore, IBF accredited courses, IBF-STS eligibility', 'How to register an IBF-STS funded course at Tertiary Infotech Academy step by step: choose your course run, enrol online and enjoy up to 70% IBF-STS course fee funding.', 'how-to-register-ibf-course.html', NULL,
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
</style><div class="tcf"><div class="tcf-hero"><p class="e">IBF-STS Funded Courses</p><h1>How to Register an IBF Course</h1><p>IBF-STS accredited courses are supported by the Institute of Banking and Finance Singapore. Eligible Singapore Citizens and PRs enjoy 50% course fee funding &mdash; and Singapore Citizens aged 40 and above enjoy 70% &mdash; for courses commencing from 1 Jan 2024. Follow these steps to register.</p></div>
<div class="tcf-steps">
<div class="tcf-step"><div class="tcf-num">1</div><div class="tcf-card"><h3>Browse IBF Funded Courses</h3><p>Find IBF-STS accredited courses at <a href="{{store url=''''}}ibf-sts-funded-courses.html">tertiarycourses.com.sg</a> &mdash; covering investment and finance, data analytics, blockchain and programming for financial services professionals.</p></div></div>
<div class="tcf-step"><div class="tcf-num">2</div><div class="tcf-card"><h3>Choose Your Course Date</h3><p>Select your course and the available class date (course run) that suits you.</p></div></div>
<div class="tcf-step"><div class="tcf-num">3</div><div class="tcf-card"><h3>Add to Cart &amp; Select Funding</h3><p>Add the course to your cart and choose your funding type: Self-Sponsored or Company-Sponsored.</p></div></div>
<div class="tcf-step"><div class="tcf-num">4</div><div class="tcf-card"><h3>Provide Enrolment Details</h3><p>Enter your NRIC / FIN and the particulars required to process your IBF-STS training grant.</p></div></div>
<div class="tcf-step"><div class="tcf-num">5</div><div class="tcf-card"><h3>Pay the Nett Fee</h3><p>Check out and pay the nett fee after IBF-STS funding (or the full fee if you are not eligible for funding).</p></div></div>
<div class="tcf-step"><div class="tcf-num">6</div><div class="tcf-card"><h3>Submit the IBF-STS TG Application Form</h3><p>Complete the <a href="https://forms.gle/GbBM6rAjpSkKg56m7" target="_blank" rel="noopener">IBF-STS Training Grant Application Form</a> so we can process your training grant with IBF.</p></div></div>
<div class="tcf-step"><div class="tcf-num">7</div><div class="tcf-card"><h3>Attend &amp; Pass the Assessment</h3><p>Attend at least 75% of the course and pass the assessment &mdash; both are required to retain your IBF-STS funding.</p></div></div>
<div class="tcf-step"><div class="tcf-num">8</div><div class="tcf-card"><h3>Get Certified</h3><p>Receive your certificate of completion from Tertiary Infotech Academy and build your track record toward <a href="https://www.ibf.org.sg/home/for-individuals/ibf-certification/why-be-ibf-certified" target="_blank" rel="noopener">IBF Certification</a>.</p></div></div>
</div>
<div class="tcf-note"><strong>Prefer to watch?</strong> See our <a href="https://youtu.be/d1KLYrgq6FM" target="_blank" rel="noopener">step-by-step video guide to registering IBF-STS courses</a>, or <a href="{{store direct_url="contacts"}}">contact our team</a> and we will walk you through your funding eligibility before you register.</div>
<div class="tcf-faq"><h2>IBF Course Registration &mdash; Frequently Asked Questions</h2>
<details><summary>What is IBF-STS funding?</summary><p>The IBF Standards Training Scheme (IBF-STS) provides course fee funding for training accredited by the <a href="https://www.ibf.org.sg/home/for-individuals/skills-and-jobs-development/training-support/IBF-STS" target="_blank" rel="noopener">Institute of Banking and Finance Singapore</a> under the Skills Framework for Financial Services.</p></details>
<details><summary>How much IBF-STS funding will I get?</summary><p>For courses commencing from 1 Jan 2024, eligible Singapore Citizens below 40 and Permanent Residents receive 50% course fee funding, while Singapore Citizens aged 40 and above receive 70%, subject to IBF eligibility criteria and funding caps.</p></details>
<details><summary>Who is eligible for IBF-STS funding?</summary><p>Singapore Citizens and Permanent Residents who successfully complete an IBF-STS accredited course &mdash; at least 75% attendance and a pass in all assessments. Both self-sponsored individuals and company-sponsored staff can qualify.</p></details>
<details><summary>Can I use SkillsFuture Credit for an IBF course?</summary><p>Yes. Eligible Singapore Citizens can use SkillsFuture Credit to offset the out-of-pocket fee after IBF-STS funding. Note that the $4,000 Additional SkillsFuture Credit (Mid-Career Support) cannot be used. See our guide on <a href="{{store url=''''}}how-to-claim-skillsfuture-credit.html">how to claim SkillsFuture Credit</a>.</p></details>
<details><summary>Can I claim UTAP for an IBF course?</summary><p>Eligible NTUC members can apply to <a href="https://utap.ntuc.org.sg/onlineClaim" target="_blank" rel="noopener">UTAP</a> for 50% of the unfunded course fee, capped at $250 per year (or $500 per year for members aged 40 and above).</p></details>
<details><summary>What happens if I miss classes or fail the assessment?</summary><p>IBF-STS funding requires at least 75% attendance and a pass in all assessments. If you do not meet these requirements, the funding is forfeited and the full course fee becomes payable.</p></details>
</div>
<div class="tcf-cta"><a href="{{store url=''''}}ibf-sts-funded-courses.html">Browse IBF Funded Courses</a><a class="sec" href="{{store direct_url="contacts"}}">Ask Us About IBF Funding</a></div>
<div class="tcf-rel"><h2>Related Guides</h2><ul>
<li><a href="{{store url=''''}}how-to-register-wsq-course.html">How to Register a WSQ Course</a></li>
<li><a href="{{store url=''''}}how-to-claim-skillsfuture-credit.html">How to Claim SkillsFuture Credit</a></li>
<li><a href="{{store url=''''}}how-to-download-swda-soa.html">How to Download SWDA SOA</a></li>
</ul></div>
</div>
<script type="application/ld+json">{"@context":"https://schema.org","@graph":[{"@type":"HowTo","name":"How to Register an IBF Course","description":"Step-by-step guide to registering an IBF-STS funded course at Tertiary Infotech Academy and enjoying up to 70% course fee funding from the Institute of Banking and Finance Singapore.","step":[{"@type":"HowToStep","position":1,"name":"Browse IBF funded courses","text":"Find IBF-STS accredited courses at tertiarycourses.com.sg covering investment and finance, data analytics, blockchain and programming."},{"@type":"HowToStep","position":2,"name":"Choose your course date","text":"Select your course and the available class date that suits you."},{"@type":"HowToStep","position":3,"name":"Add to cart and select funding","text":"Add the course to your cart and choose Self-Sponsored or Company-Sponsored funding."},{"@type":"HowToStep","position":4,"name":"Provide enrolment details","text":"Enter your NRIC or FIN and the particulars required to process the IBF-STS training grant."},{"@type":"HowToStep","position":5,"name":"Pay the nett fee","text":"Check out and pay the nett fee after IBF-STS funding."},{"@type":"HowToStep","position":6,"name":"Submit the IBF-STS TG Application Form","text":"Complete the IBF-STS Training Grant Application Form so the training grant can be processed with IBF."},{"@type":"HowToStep","position":7,"name":"Attend and pass the assessment","text":"Attend at least 75% of the course and pass the assessment to retain the IBF-STS funding."},{"@type":"HowToStep","position":8,"name":"Get certified","text":"Receive your certificate of completion and build your track record toward IBF Certification."}]},{"@type":"FAQPage","mainEntity":[{"@type":"Question","name":"What is IBF-STS funding?","acceptedAnswer":{"@type":"Answer","text":"The IBF Standards Training Scheme (IBF-STS) provides course fee funding for training accredited by the Institute of Banking and Finance Singapore under the Skills Framework for Financial Services."}},{"@type":"Question","name":"How much IBF-STS funding will I get?","acceptedAnswer":{"@type":"Answer","text":"For courses commencing from 1 Jan 2024, eligible Singapore Citizens below 40 and Permanent Residents receive 50% course fee funding, while Singapore Citizens aged 40 and above receive 70%, subject to IBF eligibility criteria and funding caps."}},{"@type":"Question","name":"Who is eligible for IBF-STS funding?","acceptedAnswer":{"@type":"Answer","text":"Singapore Citizens and Permanent Residents who successfully complete an IBF-STS accredited course with at least 75% attendance and a pass in all assessments."}},{"@type":"Question","name":"Can I use SkillsFuture Credit for an IBF course?","acceptedAnswer":{"@type":"Answer","text":"Yes, eligible Singapore Citizens can use SkillsFuture Credit to offset the out-of-pocket fee after IBF-STS funding, except the $4,000 Additional SkillsFuture Credit (Mid-Career Support)."}},{"@type":"Question","name":"Can I claim UTAP for an IBF course?","acceptedAnswer":{"@type":"Answer","text":"Eligible NTUC members can apply to UTAP for 50% of the unfunded course fee, capped at $250 per year, or $500 per year for members aged 40 and above."}},{"@type":"Question","name":"What happens if I miss classes or fail the assessment?","acceptedAnswer":{"@type":"Answer","text":"IBF-STS funding requires at least 75% attendance and a pass in all assessments. Otherwise the funding is forfeited and the full course fee becomes payable."}}]}]}</script>',
NOW(), NOW(), 1, 0
FROM DUAL
WHERE @sg = 1 AND NOT EXISTS (SELECT 1 FROM cms_page WHERE identifier = 'how-to-register-ibf-course.html');

INSERT IGNORE INTO cms_page_store (page_id, store_id)
SELECT page_id, 0 FROM cms_page WHERE identifier = 'how-to-register-ibf-course.html';

-- 2) Mega-menu category under SWDA (formerly SSG) Support (260), after 428 --

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'name');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'meta_title');
SET @a_target := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'umm_cat_target');
SET @a_display := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'display_mode');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'is_active');
SET @a_anchor := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'is_anchor');
SET @a_menu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'include_in_menu');
SET @a_cups := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etype AND attribute_code = 'custom_use_parent_settings');

SET @pre := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id = @a_urlkey AND value = 'register-an-ibf-course' LIMIT 1);
SET @fresh := IF(@sg = 1 AND @pre IS NULL, 1, 0);

UPDATE catalog_category_entity SET position = position + 1
WHERE parent_id = 260 AND position >= 3 AND @fresh = 1;

INSERT INTO catalog_category_entity (entity_type_id, attribute_set_id, parent_id, created_at, updated_at, path, position, level, children_count)
SELECT @etype, 3, 260, NOW(), NOW(), '', 3, 4, 0 FROM DUAL WHERE @fresh = 1;

SET @cat := IF(@fresh = 1, LAST_INSERT_ID(), @pre);

UPDATE catalog_category_entity SET path = CONCAT('1/2/172/260/', entity_id)
WHERE entity_id = @cat AND @fresh = 1;

UPDATE catalog_category_entity SET children_count = children_count + 1
WHERE entity_id IN (1, 2, 172, 260) AND @fresh = 1;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_name, 0, @cat, 'Register an IBF Course' FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 'Register an IBF Course';

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_urlkey, 0, @cat, 'register-an-ibf-course' FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 'register-an-ibf-course';

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_mtitle, 0, @cat, 'Register an IBF Course' FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 'Register an IBF Course';

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_display, 0, @cat, 'PRODUCTS' FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 'PRODUCTS';

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_target, 0, @cat, 'how-to-register-ibf-course.html' FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 'how-to-register-ibf-course.html';

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_active, 0, @cat, 1 FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 1;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_anchor, 0, @cat, 1 FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 1;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_menu, 0, @cat, 1 FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 1;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_cups, 0, @cat, 0 FROM DUAL WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = 0;

-- 3) Remove the old footer link (no-op once gone / on partner DBs) ----------

UPDATE cms_block
   SET content = REPLACE(content,
       '<li><a href="https://youtu.be/d1KLYrgq6FM" title="Step by Step Guide to Register IBF-STS Courses" target="_blank">Step by Step Guide for IBF Courses</a></li>',
       '')
 WHERE identifier = 'block_footer_row2_column5'
   AND content LIKE '%Step by Step Guide for IBF Courses%';
