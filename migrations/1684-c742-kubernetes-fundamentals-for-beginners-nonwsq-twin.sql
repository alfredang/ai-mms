-- C742: reactivated (1679 disabled it as "Deploy Kubernetes with AI") and repurposed as
-- "Kubernetes Fundamentals for Beginners", the 2-day non-WSQ twin of TGS-2025053174
-- (WSQ - Kubernetes for Beginners).
--
-- 1. Status -> Enabled (store 0 + any store override).
-- 2. name, url_key/url_path (deploy-kubernetes-with-ai -> kubernetes-fundamentals-for-beginners),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 3. Fee / Duration / Sessions -> $700 / 15 hrs / 2.
-- 4. "What's This Course About", course topics (5, LSN_DATA), job roles and Course Info (entry +
--    software/hardware requirement) follow the WSQ parent; the About swaps the course name and
--    states no day count.
-- 5. Funding block: "No funding" pointing at the WSQ twin.
-- 6. 301s: the product's system rows on either previous-life slug (deploy-kubernetes-with-ai,
--    ai-devops-with-kubernetes) are renamed in place to the new slug; every old path 301s one hop
--    to the new bare slug; legacy RP rows are flattened onto it. Skipped if the new slug is
--    already taken by another row (would hit the request_path unique key).
-- 7. Off the AI categories (AI Courses, AI Infrastructure Series) its "AI DevOps" life filed it under;
--    Kubernetes / Docker / Infocomm stay. Category index rows mirrored.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): cover re-render (api_ops regenerate_image), schedule template
-- -> B05 via the code path, flat/price/url reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C742' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053174' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Kubernetes Fundamentals for Beginners';
SET @old_slug1 := 'deploy-kubernetes-with-ai';
SET @old_slug2 := 'ai-devops-with-kubernetes';
SET @new_slug  := 'kubernetes-fundamentals-for-beginners';

SET @clash := (SELECT COUNT(*) FROM core_url_rewrite
                WHERE (request_path = CONCAT(@new_slug, '.html') OR request_path LIKE CONCAT('%/', @new_slug, '.html'))
                  AND (product_id IS NULL OR product_id <> @pid));
SET @ok_rw := (@ok AND @clash = 0);

SET @a_status  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

-- ------------------------------------------------------------ status -----
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_status, 0, @pid, 1
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int SET value = 1
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_status;

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------- fee / duration / sessions -----
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '15'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '2'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Learn Kubernetes from scratch: clusters, pods, deployments, services, networking, storage, scaling and monitoring, with hands-on labs, at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Kubernetes, Kubernetes Fundamentals, Kubernetes for Beginners, Containers, Docker, kubectl, Minikube, Pods, Deployments, Services, Cloud Native, DevOps'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Orphan TEXT-table meta_description shadows the varchar value on render.
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

-- ------------------- About + topics + job roles + Course Info from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Kubernetes has become a key technology for deploying, managing, and scaling containerized applications across modern IT environments. Kubernetes Fundamentals for Beginners provides a practical introduction to Kubernetes, helping learners understand how containerized applications are orchestrated and managed using Kubernetes.</p>\n<p>The course introduces essential Kubernetes concepts, including clusters, nodes, pods, deployments, services, namespaces, and the Kubernetes architecture. Learners will gain hands-on experience setting up and interacting with Kubernetes environments, deploying containerized applications, managing application configurations, and using Kubernetes commands to monitor and troubleshoot workloads.</p>\n<p>Participants will also explore Kubernetes networking, service discovery, storage, configuration management, and basic security concepts. Practical exercises demonstrate how applications can be scaled, updated, and maintained while Kubernetes manages workload scheduling, availability, and application health.</p>\n<p>The course also introduces modern deployment and operational practices, including application monitoring, autoscaling, rolling updates, and basic CI/CD concepts for Kubernetes environments. Through guided demonstrations and hands-on labs, learners will build confidence in deploying and managing real-world containerized applications.</p>\n<p>Designed for beginners, IT professionals, system administrators, developers, and aspiring DevOps engineers, this course provides a strong practical foundation for working with Kubernetes and prepares learners to progress toward more advanced container orchestration and cloud-native technologies.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1 Kubernetes Fundamentals and Architecture","subsecs":[]},{"title":"Topic 2 Container Orchestration and Kubernetes Operations","subsecs":[]},{"title":"Topic 3 Cloud Native Architecture and Scalability","subsecs":[]},{"title":"Topic 4 Kubernetes Monitoring and Observability","subsecs":[]},{"title":"Topic 5 Kubernetes Application Deployment and Management","subsecs":[]}] -->\r\n<p><strong>Topic 1 Kubernetes Fundamentals and Architecture</strong></p>\r\n<p><strong>Topic 2 Container Orchestration and Kubernetes Operations</strong></p>\r\n<p><strong>Topic 3 Cloud Native Architecture and Scalability</strong></p>\r\n<p><strong>Topic 4 Kubernetes Monitoring and Observability</strong></p>\r\n<p><strong>Topic 5 Kubernetes Application Deployment and Management</strong></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul>\n<li>IT Professional new to Kubernetes</li>\n<li>System Administrator</li>\n<li>Application Developer</li>\n<li>Aspiring DevOps Engineer</li>\n<li>DevOps Engineer</li>\n<li>Cloud Engineer</li>\n<li>Platform Engineer</li>\n<li>Site Reliability Engineer (SRE)</li>\n<li>IT Infrastructure Engineer</li>\n<li>Software Engineer (Cloud)</li>\n<li>Backend Developer</li>\n<li>Automation Engineer</li>\n<li>Network Engineer (Cloud)</li>\n<li>IT Support Engineer</li>\n<li>Technical Operations Engineer</li>\n<li>Release Engineer</li>\n<li>Cloud Consultant</li>\n<li>Solution Architect</li>\n<li>Technical Team Lead</li>\n<li>IT Student or Career Switcher</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 21-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<ul>\n<li>Docker Desktop - <a href="https://www.docker.com/products/docker-desktop/" target="_blank">https://www.docker.com/products/docker-desktop/</a></li>\n<li>A local Kubernetes cluster: Minikube (<a href="https://minikube.sigs.k8s.io/docs/start/" target="_blank">https://minikube.sigs.k8s.io/docs/start/</a>) or kind (<a href="https://kind.sigs.k8s.io/" target="_blank">https://kind.sigs.k8s.io/</a>)</li>\n<li>kubectl command line tool - <a href="https://kubernetes.io/docs/tasks/tools/" target="_blank">https://kubernetes.io/docs/tasks/tools/</a></li>\n<li>Visual Studio Code - <a href="https://code.visualstudio.com/" target="_blank">https://code.visualstudio.com/</a></li>\n</ul>\n<p><strong>Hardware:</strong> Windows or Mac laptop with at least 8GB RAM and virtualization enabled</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- clear store-scope overrides -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_prereq, @a_mkey) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_dur, @a_sess) AND store_id <> 0;

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C742 - Funding and Grant', 'course_C742_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C742_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C742_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C742_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2> <p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-kubernetes-for-beginners.html" title="WSQ - Kubernetes for Beginners">WSQ - Kubernetes for Beginners</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C742_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed) on either old slug.
DROP TEMPORARY TABLE IF EXISTS tmp_c742_old;
CREATE TEMPORARY TABLE tmp_c742_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c742_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok_rw AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug1, '.html') OR request_path LIKE CONCAT('%/', @old_slug1, '.html')
     OR request_path = CONCAT(@old_slug2, '.html') OR request_path LIKE CONCAT('%/', @old_slug2, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(REPLACE(request_path, CONCAT(@old_slug1, '.html'), CONCAT(@new_slug, '.html')),
                              CONCAT(@old_slug2, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok_rw AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug1, '.html') OR request_path LIKE CONCAT('%/', @old_slug1, '.html')
     OR request_path = CONCAT(@old_slug2, '.html') OR request_path LIKE CONCAT('%/', @old_slug2, '.html'));

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok_rw AND options = 'RP'
   AND (target_path = CONCAT(@old_slug1, '.html') OR target_path LIKE CONCAT('%/', @old_slug1, '.html')
     OR target_path = CONCAT(@old_slug2, '.html') OR target_path LIKE CONCAT('%/', @old_slug2, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c742_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c742_old;

-- ------------------------------------------------- drop AI categories -----
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar k ON k.entity_id = cp.category_id AND k.attribute_id = @a_curlkey AND k.store_id = 0
 WHERE @ok AND cp.product_id = @pid
   AND k.value IN ('artificial-intelligence-courses', 'ai-infrastructure-series');

DELETE ci FROM catalog_category_product_index ci
  JOIN catalog_category_entity_varchar k ON k.entity_id = ci.category_id AND k.attribute_id = @a_curlkey AND k.store_id = 0
 WHERE @ok AND ci.product_id = @pid
   AND k.value IN ('artificial-intelligence-courses', 'ai-infrastructure-series');
