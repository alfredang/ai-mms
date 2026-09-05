-- 1331: TGS-2025053174 "WSQ - Kubernetes and Cloud Native Associate (KCNA)
--       Training" -> "WSQ - Kubernetes for Beginners"
--
-- Repurpose AWAY from the CNCF/Linux Foundation KCNA certification, but the
-- TOOL (Kubernetes) is KEPT -- so only the exam-prep framing retires, not the
-- Kubernetes mentions (feedback_repurpose_keeps_tool_when_only_exam_prep_retires).
-- SKU is UNCHANGED, so every SkillsFuture / SFC / SFEC / PSEA deep link keyed on
-- TGS-2025053174 stays valid, and the SSG-accredited LO1-LO5 stay as registered.
--
-- Probed against LIVE SG prod 2026-09-05 (product entity_id 753, virtual):
--
--   TOUCHED
--     name                -> WSQ - Kubernetes for Beginners
--     meta_title          -> PLAIN title (was "WSQ Kubernetes and Cloud Native
--                            Associate (KCNA) Training | Tertiary Courses
--                            Singapore" -- baking in BOTH the funding token and
--                            the brand suffix that MMD_Seotitle adds at render
--                            time, so the live <title> read "WSQ funded WSQ
--                            Kubernetes ... | Tertiary Courses Singapore".
--                            Confirmed by curl before writing this file.)
--     meta_description    -> retargeted, <= 255 chars
--     meta_keyword        -> retargeted (KCNA / certification terms dropped)
--     url_key + url_path  -> wsq-kubernetes-for-beginners  (+ 301 from the old
--                            bare slug; the ~13 category paths auto-301 via the
--                            URL-rewrite indexer)
--     image_label / small_image_label / thumbnail_label / media gallery label
--                         -> plain new title (alt text on the cover)
--     short_description   -> the admin-supplied "About This Course" (4 paras).
--                            Full replace is correct: this course is post-885
--                            block-extracted, so sdesc is prose ONLY -- no
--                            <h2>Course Brochure</h2> tail to splice onto, and
--                            no inline vendor/exam-voucher sections to preserve.
--     description         -> the 5 admin-supplied topics (Course Outline).
--                            LSN_DATA JSON comment regenerated to match; the
--                            old value also carried mojibake (0xEF 0xBF 0xBD)
--                            in three topic titles, cleaned out here.
--     whoshouldattend     -> KCNA/cert-flavoured roles retargeted; the genuinely
--                            Kubernetes roles STAY (the course still teaches it)
--     prerequisite        -> ONLY the "Minimum Software/Hardware Requirement"
--                            <li>/<p> block. It still listed PyCharm +
--                            TensorFlow-on-Mac/Windows + Anaconda + Python 3.5
--                            -- dead copy left over from this recycled entity's
--                            earlier life as "Deep Learning Neural Network
--                            TensorFlow" (still visible in its 301 history), and
--                            plainly wrong for a Kubernetes course. The Promotion
--                            Code + Minimum Entry Requirement sections and the
--                            whole funding apparatus are left byte-identical.
--     categories          -> DROP 182 Certification Exam Prep,
--                            331 Linux Foundation Certification Exam Prep,
--                            409 Linux Foundation Cert Prep.
--                            Measured: 331 is 16/16 and 409 is 11/11 pure
--                            cert-prep listings, and no surviving child preps an
--                            exam, so the parent 182 goes too (the WSQ Statement
--                            of Achievement is already covered by 345 WSQ
--                            Certification Courses). Mirrored into
--                            catalog_category_product_index or the storefront
--                            listing never changes
--                            (feedback_category_swap_needs_index_mirror).
--                            KEPT: 3, 15, 55, 193 Docker, 220 Kubernetes,
--                            292, 301, 304 DevOps, 345, 426 -- the course still
--                            teaches Kubernetes, it just no longer preps KCNA.
--     search redirects    -> the 4 rows whose INTENT is the KCNA exam are sent to
--                            the still-live KCNA courses (C426 exam prep / the
--                            TGS-2023039343 twin); only the bare course code
--                            TGS-2025053174 follows this course to its new slug.
--
--   DELIBERATELY NOT TOUCHED
--     learning_outcomes block  -- the admin-supplied LO1-LO5 are byte-identical
--       to the live block (bar one stray space before a full stop). These are
--       the SSG-accredited outcomes registered against the UNCHANGED SKU, so the
--       new topics are delivered against those same outcomes. Do not "fix" the
--       Cloud Native wording they contain.
--     skills_framework  -- ICT-DES-4006-1.1 Solution Architecture, accredited
--       against the SKU, unchanged.
--     certification / funding_and_grant / brochure blocks -- SKU-keyed, no
--       old-title text (grepped: the funding block is clean).
--     trainerprofile -- Truman Ng's bio is career-history CREDENTIALS only
--       (Huawei HCIE, CCNP, Linux/DevOps/Docker delivery history). It names no
--       course-teaching claim scoped to KCNA, so rewriting it would falsify a
--       real bio. LOCATE('KCNA') = 0 confirmed.
--     image / small_image / thumbnail -- filesystem paths to the uploaded JPG.
--       Renaming them 404s the file; the storefront renders the R2
--       course_image_url cover. The cover PNG itself bakes the old title and is
--       re-rendered OUT OF BAND (a migration cannot draw a PNG).
--     tags (WSQ / SkillsFuture Credit / PSEA / UTAP / SFEC / MCES / Absentee
--       Payroll), price, duration (24h), sessions (3), venue.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement no-ops. All text is clean ASCII (apply.php connects charset=utf8).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025053174' LIMIT 1);

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpth  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_ilab    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_wsa     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- --------------------------------------------------------------- 1. name

UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Kubernetes for Beginners'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. meta_title / desc
-- PLAIN title: no leading "WSQ", no "| Tertiary Courses Singapore" suffix.
-- MMD_Seotitle composes <title> at render time (Block/Html/Head.php::_fundingPrefix).

UPDATE catalog_product_entity_varchar
   SET value = 'Kubernetes for Beginners'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn Kubernetes from scratch with WSQ Kubernetes for Beginners. Hands-on with clusters, pods, deployments, services, networking, storage, scaling and monitoring. Up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'Kubernetes for beginners, Kubernetes training Singapore, learn Kubernetes, Kubernetes basics, container orchestration, Kubernetes pods, Kubernetes deployments, Kubernetes services, Kubernetes networking, Kubernetes storage, autoscaling, rolling updates, cloud native, WSQ Kubernetes course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------- 3. url_key / url_path / 301

-- Clear any is_system = 0 squatter on the NEW path first, else the INSERT
-- IGNORE below silently no-ops against a stale row (see 647).
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-kubernetes-for-beginners.html'
   AND is_system = 0 AND @e IS NOT NULL;

-- Drop the product's OWN is_system = 1 rewrite holding the OLD bare slug. Its
-- id_path is 'product/753' -- the SAME id_path the 301 needs -- so without this
-- DELETE the INSERT IGNORE hits the unique key and creates nothing, leaving the
-- old URL 404ing AND making refreshProductRewrite mint a suffixed slug for the
-- new path (feedback_repurpose_301_needs_system_row_delete).
DELETE FROM core_url_rewrite
 WHERE product_id = @e
   AND request_path = 'wsq-kubernetes-and-cloud-native-associate-kcna-training-753.html'
   AND is_system = 1 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'wsq-kubernetes-for-beginners'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- Explicit 301 for the old bare slug. The ~13 category paths are auto-301'd by
-- the indexer once url_key changes.
INSERT IGNORE INTO core_url_rewrite
  (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e, CONCAT('product/', @e),
       'wsq-kubernetes-and-cloud-native-associate-kcna-training-753.html',
       'wsq-kubernetes-for-beginners.html',
       0, 'RP', NULL
  FROM dual WHERE @e IS NOT NULL;

-- Flatten the alias rows that pointed at the OLD bare path so they land in one
-- hop instead of 301-chaining (feedback_rename_chain_flatten_must_anchor_request_path).
UPDATE core_url_rewrite
   SET target_path = 'wsq-kubernetes-for-beginners.html'
 WHERE product_id = @e AND is_system = 0
   AND target_path = 'wsq-kubernetes-and-cloud-native-associate-kcna-training-753.html'
   AND request_path <> 'wsq-kubernetes-and-cloud-native-associate-kcna-training-753.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------------------- 4. alt labels
-- Plain title, no "WSQ - " prefix: the cover itself strips it
-- (CourseImage/Model/Cover.php::cleanTitle).

UPDATE catalog_product_entity_varchar
   SET value = 'Kubernetes for Beginners'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'Kubernetes for Beginners'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------------- 5. short_description (About)

UPDATE catalog_product_entity_text
   SET value = '<p>Kubernetes has become a key technology for deploying, managing, and scaling containerized applications across modern IT environments. Kubernetes for Beginners provides a practical introduction to Kubernetes, helping learners understand how containerized applications are orchestrated and managed using Kubernetes.</p>\n<p>The course introduces essential Kubernetes concepts, including clusters, nodes, pods, deployments, services, namespaces, and the Kubernetes architecture. Learners will gain hands-on experience setting up and interacting with Kubernetes environments, deploying containerized applications, managing application configurations, and using Kubernetes commands to monitor and troubleshoot workloads.</p>\n<p>Participants will also explore Kubernetes networking, service discovery, storage, configuration management, and basic security concepts. Practical exercises demonstrate how applications can be scaled, updated, and maintained while Kubernetes manages workload scheduling, availability, and application health.</p>\n<p>The course also introduces modern deployment and operational practices, including application monitoring, autoscaling, rolling updates, and basic CI/CD concepts for Kubernetes environments. Through guided demonstrations and hands-on labs, learners will build confidence in deploying and managing real-world containerized applications.</p>\n<p>Designed for beginners, IT professionals, system administrators, developers, and aspiring DevOps engineers, this course provides a strong practical foundation for working with Kubernetes and prepares learners to progress toward more advanced container orchestration and cloud-native technologies.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND @e IS NOT NULL;

-- ------------------------------------------------- 6. description (Outline)
-- Topics only, matching the shape the admin supplied. The LSN_DATA JSON comment
-- drives the outline widget and must mirror the visible markup.

UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1 Kubernetes Fundamentals and Architecture","subsecs":[]},{"title":"Topic 2 Container Orchestration and Kubernetes Operations","subsecs":[]},{"title":"Topic 3 Cloud Native Architecture and Scalability","subsecs":[]},{"title":"Topic 4 Kubernetes Monitoring and Observability","subsecs":[]},{"title":"Topic 5 Kubernetes Application Deployment and Management","subsecs":[]}] -->\n<p><strong>Topic 1 Kubernetes Fundamentals and Architecture</strong></p>\n<p><strong>Topic 2 Container Orchestration and Kubernetes Operations</strong></p>\n<p><strong>Topic 3 Cloud Native Architecture and Scalability</strong></p>\n<p><strong>Topic 4 Kubernetes Monitoring and Observability</strong></p>\n<p><strong>Topic 5 Kubernetes Application Deployment and Management</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. whoshouldattend
-- The Kubernetes/DevOps roles STAY (the course still teaches Kubernetes). Only
-- the certification-flavoured and senior-architect roles are re-pointed at the
-- beginner audience the new title targets.

UPDATE catalog_product_entity_text
   SET value = '<ul>\n<li>IT Professional new to Kubernetes</li>\n<li>System Administrator</li>\n<li>Application Developer</li>\n<li>Aspiring DevOps Engineer</li>\n<li>DevOps Engineer</li>\n<li>Cloud Engineer</li>\n<li>Platform Engineer</li>\n<li>Site Reliability Engineer (SRE)</li>\n<li>IT Infrastructure Engineer</li>\n<li>Software Engineer (Cloud)</li>\n<li>Backend Developer</li>\n<li>Automation Engineer</li>\n<li>Network Engineer (Cloud)</li>\n<li>IT Support Engineer</li>\n<li>Technical Operations Engineer</li>\n<li>Release Engineer</li>\n<li>Cloud Consultant</li>\n<li>Solution Architect</li>\n<li>Technical Team Lead</li>\n<li>IT Student or Career Switcher</li>\n</ul>'
 WHERE entity_id = @e AND attribute_id = @a_wsa AND @e IS NOT NULL;

-- ------------------- 8. prerequisite: software section only (PyCharm/TensorFlow)
-- Rebuilt by CONCAT of the surviving head (everything up to and including the
-- "Minimum Software/Hardware Requirement" heading) + a Kubernetes software list.
-- Anchoring on LOCATE keeps the Promotion Code + Minimum Entry Requirement
-- sections byte-identical and sidesteps the CRLF trap that makes a multi-line
-- REPLACE() silently no-op (feedback_multiline_replace_fails_on_crlf_blobs).

SET @prereq := (SELECT value FROM catalog_product_entity_text
                 WHERE entity_id = @e AND attribute_id = @a_prereq LIMIT 1);
SET @cut := IF(@prereq IS NULL, 0,
                LOCATE('<h2>Minimum Software/Hardware Requirement</h2>', @prereq));

UPDATE catalog_product_entity_text
   SET value = CONCAT(
         SUBSTRING(@prereq, 1, @cut - 1),
         '<h2>Minimum Software/Hardware Requirement</h2>\n',
         '<p><strong>Software:</strong></p>\n',
         '<ul>\n',
         '<li>Docker Desktop - <a href="https://www.docker.com/products/docker-desktop/" target="_blank">https://www.docker.com/products/docker-desktop/</a></li>\n',
         '<li>A local Kubernetes cluster: Minikube (<a href="https://minikube.sigs.k8s.io/docs/start/" target="_blank">https://minikube.sigs.k8s.io/docs/start/</a>) or kind (<a href="https://kind.sigs.k8s.io/" target="_blank">https://kind.sigs.k8s.io/</a>)</li>\n',
         '<li>kubectl command line tool - <a href="https://kubernetes.io/docs/tasks/tools/" target="_blank">https://kubernetes.io/docs/tasks/tools/</a></li>\n',
         '<li>Visual Studio Code - <a href="https://code.visualstudio.com/" target="_blank">https://code.visualstudio.com/</a></li>\n',
         '</ul>\n',
         '<p><strong>Hardware:</strong> Windows or Mac laptop with at least 8GB RAM and virtualization enabled</p>')
 WHERE entity_id = @e AND attribute_id = @a_prereq AND @e IS NOT NULL AND @cut > 0;

-- ----------------------------------------------- 9. drop exam-prep categories
-- 182 Certification Exam Prep, 331 Linux Foundation Certification Exam Prep,
-- 409 Linux Foundation Cert Prep. Mirror into the index or listings never change.

DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (182, 331, 409) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (182, 331, 409) AND @e IS NOT NULL;

-- Drop the now-orphaned is_system rewrites for those three category paths.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND category_id IN (182, 331, 409) AND @e IS NOT NULL;

-- --------------------------------------------------- 10. search-term redirects
-- KCNA-exam intent goes to the courses that still teach/prep it, NOT to this
-- renamed page (feedback_search_redirect_rot_into_live_200_repurposed_slug).
-- The KCNA twin TGS-2023039343 keeps the unsuffixed kcna slug and is live.

UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/kubernetes-and-cloud-native-associate-kcna-exam-prep.html'
 WHERE redirect = 'https://www.tertiarycourses.com.sg/wsq-kubernetes-and-cloud-native-associate-kcna-training-753.html'
   AND query_text = 'kcna';

UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-kubernetes-for-beginners.html'
 WHERE query_text = 'TGS-2025053174';

-- 'Cloud native architecture' / 'Kubernetes and Cloud Native Security Associate'
-- / 'WSQ - Kubernetes and Cloud Native Associate (KCNA)' etc. already point at
-- the UNSUFFIXED kcna slug, which belongs to the still-live twin TGS-2023039343
-- -- correct intent, left alone.

-- ----------------------------------------------------------- 11. flat mirror
-- Keep catalog_product_flat_1 in step so the storefront listing/name updates
-- before the next full reindex. Only columns that actually EXIST on the flat
-- table are touched: meta_description is NOT a flat column and referencing it
-- would fatal 1054, aborting apply.php and 502-ing every host
-- (feedback_meta_title_flat_has_no_column). Verified against prod's
-- information_schema before writing this.

UPDATE catalog_product_flat_1
   SET name = 'WSQ - Kubernetes for Beginners',
       url_key = 'wsq-kubernetes-for-beginners',
       url_path = 'wsq-kubernetes-for-beginners.html',
       short_description = (SELECT value FROM catalog_product_entity_text
                             WHERE entity_id = @e AND attribute_id = @a_sdesc
                             ORDER BY store_id LIMIT 1)
 WHERE entity_id = @e AND @e IS NOT NULL;
