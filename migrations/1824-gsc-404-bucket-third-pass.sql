-- 1824: third pass on the GSC "Not found (404)" / "Page with redirect" buckets for
-- www.tertiarycourses.com.sg.
--
-- WHY: GSC validation of 'Not found (404)' and 'Page with redirect' FAILED again
-- (export of 2026-10-12, re-crawled on prod 2026-10-16). 875/1000 already 301 -> 200
-- after 1796/1811. The real remainder: seven courses disabled AFTER 1811 shipped
-- (C1074 OpenVLA, C136 vLLM, C1384 PL-500, C1436 SC-100, C603 AI Vibe Coding for Web
-- Development, C615 IPv6 Masterclass, C636 PL-7003), so their slugs and every older
-- alias 301'd onto them now end in a 404. Old aliases that were 301'd onto those
-- products during repurposes are given a topic-matching target of their own instead of
-- inheriting the retired course's (e.g. ai-vibe-coding-for-javascript -> JavaScript,
-- not vLLM). Two malformed inbound links with an obvious intent are mapped too.
-- Also: 33 old category slugs (mostly pre-rename '-in-singapore' variants, no DB trace)
-- from the 'Crawled/Discovered - not indexed' and canonical buckets that now 404 ->
-- their renamed live category, else the nearest live topic category.
-- Every target was curl-verified '0 200' on prod before shipping.
-- Still 404 on purpose (unchanged from 1811): kids workshops, educational tours,
-- tuition, escape rooms, speed typing, the retired Tertiary Courses GPT page, and junk
-- inbound links (/assets/video/*.mp4, /player?id=..., truncated slugs).
--
-- HOW: identical mechanism to 1796/1811 (retire url_key -> '<slug>-retired', replace
-- the row on the slug with a manual RP 301, flatten inbound redirects + search terms).
-- SG only (@mms_instance + store guard) -> no-op on MY/GH. Idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

DROP TEMPORARY TABLE IF EXISTS tmp_gsc404;
CREATE TEMPORARY TABLE tmp_gsc404 (
  src VARCHAR(255) NOT NULL PRIMARY KEY,
  dst VARCHAR(255) NOT NULL,
  k   VARCHAR(255) NOT NULL DEFAULT ''
) DEFAULT CHARSET=utf8;

INSERT INTO tmp_gsc404 (src, dst) VALUES
('fine-tuning-openvla-model.html','fine-tuning-open-source-llm.html'),
('local-llm-deployment-with-vllm.html','ai-infrastructure-series.html'),
('microsoft-power-automate-rpa-developer-associate-pl-500-exam-prep.html','wsq-hands-on-power-automate-desktop-rpa-for-work-process-automation.html'),
('sc-100-microsoft-cybersecurity-architect-exam-prep.html','cybersecurity-threat-analysis-courses.html'),
('ai-vibe-coding-for-web-development.html','ai-vibe-coding-for-full-stack-web-development.html'),
('ipv6-masterclass.html','networks-training-in.html'),
('pl-7003-create-and-manage-model-driven-apps-with-power-apps-and-dataverse.html','microsoft-power-apps-software-training.html'),
('ai-vibe-coding-for-javascript.html','javascript-training-courses-in.html'),
('javascript-essential-training-singapore.html','javascript-training-courses-in.html'),
('ai-vibe-coding-for-mobile-apps-development.html','mobile-programming-courses.html'),
('vibe-coding-for-android-and-ios-mobile-apps.html','mobile-programming-courses.html'),
('from-novice-to-pro-building-coding-skills-with-github-copilot.html','git-and-github-courses.html'),
('ipv6-network-administrator-training.html','networks-training-in.html'),
('vibe-coding-for-building-professional-web-apps.html','ai-vibe-coding-for-full-stack-web-development.html'),
('3d-design-training-courses-in-singapore.html','3d-modeling-courses.html'),
('ai-900-microsoft-certified-azure-ai-fundamentals-practice-exams.html','microsoft-certifications-exams.html'),
('angularjs-trainings-in-singapore.html','javascript-training-courses-in.html'),
('arduino-courses-in-singapore.html','arduino-courses-in.html'),
('asp-net-training-in-singapore.html','programming-courses.html'),
('autodesk-inventor-training-singapore.html','autodesk-inventor-training.html'),
('business-innovation-entrepreneurship-skillsfuture-courses.html','business-soft-skills-courses.html'),
('ci-cd-courses.html','devops-courses.html'),
('comptia-practice-exams-18.html','comptia-certification-prep-courses.html'),
('computer-programming-and-infocomm-courses-in-singapore.html','computer-programming-and-infocomm-courses.html'),
('email-marketing-courses-in-singapore.html','email-marketing-courses-in.html'),
('embedded-systems-courses.html','internet-of-things-iot-training-in.html'),
('ethereum-skillsfuture-courses-in-singapore.html','ethereum-blockchain-courses.html'),
('fintech-courses-singapore.html','fintech-courses.html'),
('gaming-animation-and-video-courses-in-singapore.html','gaming-animation-and-video-courses-in.html'),
('graphics-design.html','graphics-design-courses.html'),
('huawei-certification-courses.html','certification-exam-prep-courses.html'),
('huawei-certification-exam-prep-courses.html','certification-exam-prep-courses.html'),
('ibf-sts-digital-enterprise-architecture-courses.html','ibf-sts-funded-courses.html'),
('ibf-sts-future-enabled-skills-courses.html','ibf-sts-funded-courses.html'),
('ibm-skills-academy-courses.html','certification-exam-prep-courses.html'),
('isc2-practice-exams.html','isc2-certification-exam-prep-courses.html'),
('jenkins-courses.html','devops-courses.html'),
('john-wiley-specialist-certification-courses.html','certification-exam-prep-courses.html'),
('ntuc-utap-courses.html','wsq-funded-courses.html'),
('perl-programming-training-courses-in-singapore.html','programming-courses.html'),
('pic-microcontroller.html','pic-microcontroller-courses.html'),
('power-bi-courses.html','power-bi-software-training.html'),
('ros-2-training.html','robot-operating-system-ros-courses.html'),
('ruby-programming-courses.html','programming-courses.html'),
('tensorflow-machine-learning-courses.html','ai-for-machine-learning.html'),
('wsq-manufacturing-courses-151.html','logistics-and-manufacturing-courses.html'),
('wsq-soft-skill-courses.html','wsq-soft-skills-courses.html'),
('wsq-comptia-a-training.html;315542','wsq-comptia-certified-a-training-core-1-and-core-2.html'),
('wsq-bioinformatics-data-analysis-with-r-bioconductor.htmles.com.sg','wsq-ai-for-life-science-and-bioinformatics.html');

UPDATE tmp_gsc404 SET k = LEFT(src, CHAR_LENGTH(src) - 5) WHERE src LIKE '%.html' AND src NOT LIKE '%/%';
DELETE FROM tmp_gsc404 WHERE @ok IS NULL OR @ok <> 1;

SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @cet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');
SET @p_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @pet AND attribute_code = 'url_key');
SET @p_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @pet AND attribute_code = 'url_path');
SET @p_st := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @pet AND attribute_code = 'status');
SET @c_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @cet AND attribute_code = 'url_key');
SET @c_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @cet AND attribute_code = 'url_path');
SET @c_ac := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @cet AND attribute_code = 'is_active');

-- 1a. Disabled products (effective SG status = 2) that still own a dead slug.
DROP TEMPORARY TABLE IF EXISTS tmp_gsc404_p;
CREATE TEMPORARY TABLE tmp_gsc404_p (entity_id INT UNSIGNED PRIMARY KEY, k VARCHAR(255)) DEFAULT CHARSET=utf8;
INSERT IGNORE INTO tmp_gsc404_p (entity_id, k)
SELECT v.entity_id, t.k
  FROM tmp_gsc404 t
  JOIN catalog_product_entity_varchar v ON v.attribute_id = @p_uk AND v.value = t.k
 WHERE t.k <> ''
   AND COALESCE((SELECT s.value FROM catalog_product_entity_int s WHERE s.entity_id = v.entity_id AND s.attribute_id = @p_st AND s.store_id = 1),
                (SELECT s.value FROM catalog_product_entity_int s WHERE s.entity_id = v.entity_id AND s.attribute_id = @p_st AND s.store_id = 0)) = 2
   AND NOT EXISTS (SELECT 1 FROM catalog_product_entity_varchar x WHERE x.attribute_id = @p_uk AND x.value = CONCAT(t.k, '-retired'));

UPDATE catalog_product_entity_varchar v JOIN tmp_gsc404_p p ON p.entity_id = v.entity_id
   SET v.value = CONCAT(p.k, '-retired')
 WHERE v.attribute_id = @p_uk AND v.value = p.k;
UPDATE catalog_product_entity_varchar v JOIN tmp_gsc404_p p ON p.entity_id = v.entity_id
   SET v.value = CONCAT(p.k, '-retired.html')
 WHERE v.attribute_id = @p_up AND v.value = CONCAT(p.k, '.html');

-- 1b. Inactive categories (effective SG is_active = 0) that still own a dead slug.
DROP TEMPORARY TABLE IF EXISTS tmp_gsc404_c;
CREATE TEMPORARY TABLE tmp_gsc404_c (entity_id INT UNSIGNED PRIMARY KEY, k VARCHAR(255)) DEFAULT CHARSET=utf8;
INSERT IGNORE INTO tmp_gsc404_c (entity_id, k)
SELECT v.entity_id, t.k
  FROM tmp_gsc404 t
  JOIN catalog_category_entity_varchar v ON v.attribute_id = @c_uk AND v.value = t.k
 WHERE t.k <> ''
   AND COALESCE((SELECT a.value FROM catalog_category_entity_int a WHERE a.entity_id = v.entity_id AND a.attribute_id = @c_ac AND a.store_id = 1),
                (SELECT a.value FROM catalog_category_entity_int a WHERE a.entity_id = v.entity_id AND a.attribute_id = @c_ac AND a.store_id = 0)) = 0
   AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_varchar x WHERE x.attribute_id = @c_uk AND x.value = CONCAT(t.k, '-retired'));

UPDATE catalog_category_entity_varchar v JOIN tmp_gsc404_c c ON c.entity_id = v.entity_id
   SET v.value = CONCAT(c.k, '-retired')
 WHERE v.attribute_id = @c_uk AND v.value = c.k;
UPDATE catalog_category_entity_varchar v JOIN tmp_gsc404_c c ON c.entity_id = v.entity_id
   SET v.value = CONCAT(c.k, '-retired.html')
 WHERE v.attribute_id = @c_up AND v.value = CONCAT(c.k, '.html');

-- 2. Replace whatever row sits on each dead slug with a manual 301.
DELETE r FROM core_url_rewrite r JOIN tmp_gsc404 t ON t.src = r.request_path
 WHERE r.store_id IN (0, 1) AND r.id_path NOT LIKE 'gsc404-%';

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 0, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc404 t
 WHERE NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 0);
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc404 t
 WHERE NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 1);

UPDATE core_url_rewrite r JOIN tmp_gsc404 t ON t.src = r.request_path
   SET r.target_path = t.dst, r.options = 'RP'
 WHERE r.store_id IN (0, 1) AND r.id_path LIKE 'gsc404-%' AND r.target_path <> t.dst;

-- 3. Flatten chains: redirects and search terms that pointed at a dead slug.
UPDATE core_url_rewrite r JOIN tmp_gsc404 t ON r.target_path IN (t.src, CONCAT('https://www.tertiarycourses.com.sg/', t.src))
   SET r.target_path = t.dst
 WHERE r.store_id IN (0, 1) AND r.options IN ('R', 'RP') AND r.request_path <> t.dst;

UPDATE catalogsearch_query q JOIN tmp_gsc404 t ON q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.src)
   SET q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.dst)
 WHERE q.store_id = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_gsc404_p;
DROP TEMPORARY TABLE IF EXISTS tmp_gsc404_c;
DROP TEMPORARY TABLE IF EXISTS tmp_gsc404;
