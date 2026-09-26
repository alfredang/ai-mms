-- 1570: TGS-2024045795 "WSQ - Agentic AI for HR" -> "WSQ - Microsoft Copilot for HR"
--
-- Tool swap on an unchanged competency (admin request 2026-09-27). The SKU
-- and the accredited TSC (skills_framework block: "Human Resource
-- Digitalisation-4 HRS-HRM-4031-1.1") are UNCHANGED, so every SkillsFuture /
-- SFEC / SFC / PSEA / UTAP deep link, the funding_and_grant block, the 6
-- funding tags, the price ($900), duration (16) and sessions (2) all stay.
--
-- Pre-write probe (SG prod, entity 671) showed this entity has had THREE
-- lives: "Digital Transformation in HR: Leveraging Generative AI for the
-- Future of Work" (2024) -> "Agentic AI for HR" (2026-07) -> this one. The
-- Agentic AI rename touched only name, url_key and the cover; EVERY other
-- surface still describes the Digital Transformation course: meta_title,
-- meta_description, meta_keyword, short_description, description (the
-- 4-topic GAI outline), the 3 alt labels + gallery label, and the
-- course-teaching paragraph of all 6 trainer bios. All of them change here.
--
-- Deliberately NOT touched (verified correct on prod):
--   * cms_block course_TGS-2024045795_learning_outcomes -- the supplied
--     LO1-LO4 are byte-identical to the live block.
--   * brochure / funding_and_grant / skills_framework blocks.
--   * whoshouldattend -- 20 HR job roles, all still accurate for the new
--     delivery tool.
--   * All 15 categories, INCLUDING 189 Agentic AI Series / 196 WSQ Agentic AI
--     Courses (the course still teaches AI agents + Copilot Studio agents;
--     sibling TGS-2022017524 Copilot Studio Agents sits in 196 too) and 357
--     Microsoft Copilot Series (already a member).
--   * image / small_image / thumbnail PATHS (filesystem paths).
--   * news_from_date / news_to_date (no new validity window supplied).
--
-- SLUG: `wsq-microsoft-copilot-for-hr` -- probe found no product name or
-- url_key containing "copilot" + "hr" and no core_url_rewrite row on the new
-- path. The old bare slug 301s to the new one, and the 28 pre-existing 301s
-- from the Digital Transformation life (bare + category-prefixed) are
-- flattened to the new bare slug in ONE hop. The `agentic-ai-for-hr.html`
-- (no wsq- prefix) rows belong to C820 "AI for HR Management" and are NOT
-- matched by the `%wsq-agentic-ai-for-hr.html` patterns below.
--
-- SEARCH REDIRECTS: 33 rows (the course-code row "TGS-2024045795",
-- popularity 124, plus every "Digital Transformation in HR" / "Generative AI
-- for HR" / "AI hr" spelling) still pointed at the DEAD Digital
-- Transformation slug (a 301 chain), and 4 "agentic ai (for/in) hr" rows at
-- the slug retired here. All follow the course -- same TGS code, same TSC,
-- still the WSQ AI-for-HR course -- except four generic HR queries ("HR a",
-- "hr analytics", "wsq hr", "HR Professional Certification") that are not
-- about AI and go to the HR Management category page (200 verified).
--
-- COVER: pre-rendered PNG on R2 with the title baked in. Re-rendered on the
-- SG web container via MMD_CourseImage_Model_Cover with the product's OWN
-- badge set (WSQ, SkillsFuture Credit, PSEA, SFEC, Absentee Payroll, MCES)
-- and uploaded before this file was written:
--   course-covers/TGS-2024045795-20260926-162812.png  (147482 bytes, HTTP 200)
-- The superseded object is left on R2 so reverting is just repointing the URL.
--
-- The stored meta_title carried a baked-in "WSQ ... | Tertiary Courses
-- Singapore" (MMD_Seotitle adds both at render time, so the live <title>
-- double-printed). Fixed here: meta_title is the PLAIN title.
--
-- POST-DEPLOY (code paths a migration cannot run, on the SG web container):
--   1. Mage::getSingleton('catalog/url')->refreshProductRewrite(671)
--      then catalog_product_flat reindex + cache flush -- the NEW slug 404s
--      until this runs, even though the old slug already 301s.
--   2. scripts/local-dev/batch-generate-brochures.php --wid=1
--      --sku-like=TGS-2024045795 --regenerate --no-drive (the brochure PDF
--      is filesystem-first and has the old title baked in).
--   3. scripts/seo/generate-sitemaps.php so the sitemap lists the new slug.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2024045795
-- no-ops. Idempotent: plain UPDATEs, INSERT IGNORE, guarded REPLACE()s.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024045795' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------------------
-- 1. Identity: name, url_key, url_path
-- ---------------------------------------------------------------------------

-- name: keeps the `WSQ - ` prefix (the storefront H1 wants it)
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Microsoft Copilot for HR'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

-- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-microsoft-copilot-for-hr'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

-- url_path: DELETE at every scope (store 0 AND store 1 rows exist) so the URL
-- Rewrites indexer regenerates it
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_path' AND entity_type_id = @et);
DELETE FROM catalog_product_entity_varchar
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL AND @a_upath IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Meta
-- ---------------------------------------------------------------------------

-- meta_title: PLAIN title -- no leading "WSQ", no brand suffix (see header)
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_title' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Microsoft Copilot for HR'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- meta_description: varchar(255) -- this value is 215 chars
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Use Microsoft 365 Copilot, SharePoint, AI agents and Copilot Studio to automate HR processes from recruitment and onboarding to talent development and offboarding, with responsible AI. Up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

-- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = 'Microsoft Copilot for HR course Singapore, WSQ Copilot HR course, Microsoft 365 Copilot HR, Copilot Studio HR agents, AI agents recruitment screening, Copilot employee onboarding, HR policy agent SharePoint, Copilot talent development, AI employee offboarding, HR workflow automation, responsible AI in HR, WSQ funded HR course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Content: About narrative, Course Outline, software requirement
-- ---------------------------------------------------------------------------

-- short_description ("What's This Course About"): the supplied five-paragraph
-- narrative. This course's sections live in cms_block rows, so
-- short_description holds ONLY the intro copy -- a full replace is correct.
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p>Microsoft Copilot for HR equips participants with practical skills to use Microsoft Copilot 365, SharePoint, AI agents, and Microsoft Copilot Studio to enhance and automate HR processes across the employee lifecycle.</p>',
'\n<p>Participants will learn to use Copilot and AI agents for recruitment and candidate screening, including reviewing candidate information in SharePoint, matching candidates against job requirements, developing screening criteria, and supporting shortlisting. They will use Copilot to generate role-specific interview questions, develop interview rubrics, conduct interview practice sessions, and support structured candidate evaluation.</p>',
'\n<p>The course covers employee onboarding using Copilot Studio and AI agents to automate workflows, manage HR information, and provide employees with relevant resources. Participants will also create HR policy agents that retrieve information from SharePoint and respond to employee enquiries about policies, leave, benefits, and workplace procedures.</p>',
'\n<p>For talent development, participants will use Copilot to identify skills gaps, support development planning, and recommend relevant learning opportunities. They will also explore AI-enabled offboarding processes, including knowledge transfer, documentation, exit procedures, and workflow coordination.</p>',
'\n<p>Throughout the course, participants will apply responsible AI practices, including data privacy, security, fairness, appropriate access controls, and human oversight when using AI in HR processes.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- description (Course Outline): LSN_DATA JSON + rendered markup kept in the
-- shape the admin outline editor writes (one source, both forms). The supplied
-- outline is four topic titles, so subsecs are empty (same as 1565).
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: Microsoft Copilot and AI Agents for Recruitment and Interviewing","subsecs":[]},{"title":"Topic 2: Microsoft Copilot for Employee Onboarding and HR Policy Management","subsecs":[]},{"title":"Topic 3: Microsoft Copilot for Talent Development, Leave and Employee Benefits","subsecs":[]},{"title":"Topic 4: Microsoft Copilot Studio for HR Workflow Automation and Employee Offboarding","subsecs":[]}] -->',
'\n<p><strong>Topic 1: Microsoft Copilot and AI Agents for Recruitment and Interviewing</strong></p>',
'\n<p><strong>Topic 2: Microsoft Copilot for Employee Onboarding and HR Policy Management</strong></p>',
'\n<p><strong>Topic 3: Microsoft Copilot for Talent Development, Leave and Employee Benefits</strong></p>',
'\n<p><strong>Topic 4: Microsoft Copilot Studio for HR Workflow Automation and Employee Offboarding</strong></p>',
'\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- prerequisite ("Minimum Software/Hardware Requirement"): held only
-- "Softtware: Windows / Mac". Swap that pair of lines for the house shape the
-- sibling Copilot WSQ courses use (TGS-2024043856 / TGS-2022017524), naming
-- Microsoft 365 Copilot + Copilot Studio. This blob is ALSO the whole funding
-- apparatus (PWM, eligibility table, Appeal Process), so it is never
-- rewritten wholesale. Guarded on LOCATE so re-runs do not duplicate.
SET @a_pre := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'prerequisite' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<p><strong>Softtware:</strong> Windows / Mac</p><p><strong>Hardware:</strong> Laptop</p>',
       CONCAT('<p><strong>Software:</strong></p><p>You will need access to the following software:</p><ul>',
              '<li><a href="https://adoption.microsoft.com/en-us/copilot/" target="_blank"><span style="text-decoration: underline;">Microsoft 365 Copilot</span></a></li>',
              '<li><a href="https://www.microsoft.com/en-us/microsoft-copilot/microsoft-copilot-studio" target="_blank"><span style="text-decoration: underline;">Microsoft Copilot Studio</span></a></li>',
              '</ul><p><strong>Hardware:</strong> Windows and Mac Laptops</p>'))
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL
   AND LOCATE('microsoft-copilot-studio', value) = 0;

-- ---------------------------------------------------------------------------
-- 4. Trainer bios: retarget ONLY the course-teaching paragraph of each of the
--    6 bios (all still named the Digital Transformation course). Credentials
--    in each bio's first paragraph are facts and stay. Single-paragraph
--    REPLACEs, so line endings between paragraphs do not matter.
-- ---------------------------------------------------------------------------
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation in HR: Leveraging Generative AI for the Future of Work,&rdquo; Sivanesan helps participants understand how AI and automation reshape HR operations, talent management, and learning strategies. His sessions focus on integrating agile project principles into HR digitalization, enabling organizations to adopt AI tools responsibly and effectively. Through real-world examples, he empowers HR professionals to lead transformation projects that enhance productivity, engagement, and workforce adaptability.',
       'In &ldquo;Microsoft Copilot for HR,&rdquo; Sivanesan helps participants understand how Microsoft 365 Copilot and AI agents reshape HR operations, talent management, and learning strategies. His sessions focus on integrating agile project principles into HR digitalization, enabling organizations to adopt Copilot and Copilot Studio agents responsibly and effectively. Through real-world examples, he empowers HR professionals to lead automation projects that enhance productivity, engagement, and workforce adaptability.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation in HR: Leveraging Generative AI for the Future of Work,&rdquo; Woei Ming guides learners on applying AI models and analytics to HR workflows such as performance evaluation, recruitment optimization, and employee engagement. His sessions emphasize the use of generative AI for process redesign, predictive insights, and workforce analytics. By translating technical concepts into business value, he helps HR professionals leverage AI to build smarter, data-informed talent ecosystems.',
       'In &ldquo;Microsoft Copilot for HR,&rdquo; Woei Ming guides learners on applying Copilot and AI agents to HR workflows such as candidate screening, interview preparation, and skills-gap analysis. His sessions emphasize grounding Copilot Studio agents in SharePoint data for onboarding, HR policy enquiries, and workforce insights. By translating technical concepts into business value, he helps HR professionals leverage Copilot to build smarter, data-informed talent ecosystems.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation in HR: Leveraging Generative AI for the Future of Work,&rdquo; Siew Yee helps participants explore how data and AI can transform traditional HR functions. His lessons focus on AI ethics, governance, and the integration of generative AI in employee lifecycle management. He empowers HR leaders to utilize AI tools for smarter workforce planning, personalized learning, and automation&mdash;bridging analytics with strategic human capital development.',
       'In &ldquo;Microsoft Copilot for HR,&rdquo; Siew Yee helps participants explore how Microsoft 365 Copilot and AI agents can transform traditional HR functions. His lessons focus on responsible AI, data privacy, access controls, and human oversight when integrating Copilot across the employee lifecycle. He empowers HR leaders to utilize Copilot for smarter workforce planning, personalized learning, and workflow automation&mdash;bridging analytics with strategic human capital development.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation in HR: Leveraging Generative AI for the Future of Work,&rdquo; Truman introduces HR professionals to the integration of AI systems within enterprise infrastructures. His sessions emphasize deploying generative AI tools for employee support systems, HR analytics, and workflow automation while ensuring compliance and data protection. He equips learners with the technical understanding and strategic mindset to manage AI transformation projects that modernize HR operations effectively.',
       'In &ldquo;Microsoft Copilot for HR,&rdquo; Truman introduces HR professionals to the integration of Copilot and Copilot Studio agents within the Microsoft 365 environment. His sessions emphasize building HR policy agents on SharePoint, automating onboarding and offboarding workflows, and configuring access controls while ensuring compliance and data protection. He equips learners with the technical understanding and strategic mindset to manage Copilot deployments that modernize HR operations effectively.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation in HR: Leveraging Generative AI for the Future of Work,&rdquo; James focuses on human-centered AI applications that enhance the employee experience. His training explores how HR professionals can use AI-powered tools for onboarding, communication, and digital learning. By combining creativity with technology, he equips participants with practical skills to design adaptive, AI-enhanced HR processes that foster innovation and inclusivity in the workplace.',
       'In &ldquo;Microsoft Copilot for HR,&rdquo; James focuses on human-centered Copilot applications that enhance the employee experience. His training explores how HR professionals can use Microsoft 365 Copilot and AI agents for onboarding, employee communication, and personalised learning recommendations. By combining creativity with technology, he equips participants with practical skills to design adaptive, Copilot-enhanced HR processes that foster innovation and inclusivity in the workplace.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation in HR: Leveraging Generative AI for the Future of Work,&rdquo; Dwight teaches how HR departments can harness AI to enhance decision-making, talent analytics, and organizational efficiency. His sessions cover the integration of generative AI into HR dashboards, recruitment analytics, and workforce forecasting. Through hands-on case studies, he demonstrates how data-driven AI approaches can transform human resource management into a strategic, insight-led function.',
       'In &ldquo;Microsoft Copilot for HR,&rdquo; Dwight teaches how HR departments can harness Copilot and AI agents to enhance decision-making, talent analytics, and organizational efficiency. His sessions cover using Copilot for candidate matching, interview rubrics, skills-gap identification, and development planning. Through hands-on case studies, he demonstrates how Copilot-driven approaches can transform human resource management into a strategic, insight-led function.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. Cover image + alt text
-- ---------------------------------------------------------------------------

-- image alt-text labels: plain title, no `WSQ - ` prefix (the cover itself
-- strips it via Cover.php::cleanTitle)
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
    SET v.value = 'Microsoft Copilot for HR'
  WHERE v.entity_id = @e AND @e IS NOT NULL
    AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label');

-- media gallery label -- the real alt text on the product image (the stored
-- file PATH is left alone: renaming it 404s the file)
UPDATE catalog_product_entity_media_gallery_value gv
   JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
    SET gv.label = 'Microsoft Copilot for HR'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'course_image_url' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045795-20260926-162812.png'
  WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0
   AND @e IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. URL rewrites: 301 the old slug, flatten the chain history
-- ---------------------------------------------------------------------------
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- The old bare slug is held by the canonical is_system=1 row on
-- id_path='product/<e>'. INSERT IGNORE would silently no-op against it, so
-- DELETE it first; refreshProductRewrite re-mints the canonical row at the
-- NEW slug post-deploy.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'wsq-agentic-ai-for-hr.html'
   AND @e IS NOT NULL;

-- Clear any is_system=0 squatter sitting on the NEW path
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-microsoft-copilot-for-hr.html'
   AND is_system = 0;

-- Permanent 301: old bare slug -> new bare slug. The indexer auto-301s the
-- category-prefixed paths once the rewrites are refreshed.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('tgs2024045795-copilot-bare-', @e),
       'wsq-agentic-ai-for-hr.html',
       'wsq-microsoft-copilot-for-hr.html',
       0, 'RP', '1570: TGS-2024045795 repurposed to Microsoft Copilot for HR'
 WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that point at the OLD slug -- both the bare
-- form and the category-prefixed form (`<category>/wsq-agentic-ai-for-hr.html`,
-- which the indexer never regenerates and would otherwise 301 -> 404) -- so
-- they redirect to the new BARE slug in ONE hop. The old filename is unique
-- to this product (verified: all 28 matching rows belong to entity 671), so
-- no foreign alias is repointed.
UPDATE core_url_rewrite
   SET target_path = 'wsq-microsoft-copilot-for-hr.html'
 WHERE is_system = 0
   AND target_path LIKE '%wsq-agentic-ai-for-hr.html'
   AND id_path NOT LIKE 'tgs2024045795-copilot-%';

-- ---------------------------------------------------------------------------
-- 7. Search-term redirects (SG data; partner sites have no matching rows)
-- ---------------------------------------------------------------------------

-- Generic HR intent (not AI-specific) -> the HR Management category page.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/human-resource-management-courses.html'
 WHERE redirect LIKE '%wsq-digital-transformation-in-hr-leveraging-generative-ai-for-the-future-of-work.html'
   AND query_text IN ('HR a', 'hr analytics', 'wsq hr', 'HR Professional Certification');

-- Everything else on either retired slug (the course code, the Digital
-- Transformation title spellings, GenAI-for-HR, agentic-AI-for-HR) follows
-- the course -- it is the same accredited course under the same TGS code.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-microsoft-copilot-for-hr.html'
 WHERE redirect LIKE '%wsq-agentic-ai-for-hr.html'
    OR redirect LIKE '%wsq-digital-transformation-in-hr-leveraging-generative-ai-for-the-future-of-work.html'
    OR (query_text = 'TGS-2024045795' AND (redirect IS NULL OR redirect = ''));
