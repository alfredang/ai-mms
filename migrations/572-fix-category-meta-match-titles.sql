-- 572: Fix category SEO meta (meta_title / meta_description / meta_keywords)
--      that describes a different subject than the category title.
--
-- 565 fixed the visible descriptions, but the same copy-paste drift also sits in
-- the meta fields — which is what search engines actually index. Found while
-- verifying 565: the Java category page still rendered "Java and Scala
-- Programming ..." in <title> and og:title even though the body copy was
-- already corrected.
--
-- Categories fixed here (non-WSQ scope only, same as 565/566):
--   75  Java                   meta still sold "Java and Scala" (rename orphan, cf. 555)
--   126 Marketing Analytics    meta was "Business Analytics ..."
--   250 AI Devops Series       meta_description/keywords were AI digital humans
--   283 Codex AI Series        meta_description/keywords were Keras/TensorFlow/JAX
--   419 Google Cert Exam Prep  had no meta at all
--
-- Left alone deliberately: 81, 214, 314, 354 — their meta is on-topic for the
-- title even where wording differs from the new body copy.
--
-- Matched by CURRENT url_key (ids drift across SG/MY/GH). store_id=0 scope.
-- INSERTs are guarded with NOT EXISTS on the SAME attribute+entity+store, so a
-- missing row is seeded and an existing row is updated — note this guard is
-- attribute-scoped, unlike the over-broad request_path guard that broke 566.
-- Idempotent. After deploy: flush block_html/FPC (meta is not flat-indexed).

SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description');
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords');

-- ---------------------------------------------------------------- 75 --------
SET @uk := 'java-programming-courses';
SET @mt := 'Java Programming Courses in Singapore | Tertiary Courses';
SET @md := 'Learn Java programming with hands-on courses covering core syntax, object-oriented design, application development and Android. Beginner to certification level.';
SET @mk := 'Java courses, Java programming, object-oriented programming, Android development, Java certification, programming courses Singapore';

UPDATE catalog_category_entity_varchar v
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = v.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET v.value = @mt WHERE v.attribute_id = @a_mt AND v.store_id = 0 AND uk.value = @uk;
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @md WHERE t.attribute_id = @a_md AND t.store_id = 0 AND uk.value = @uk;
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @mk WHERE t.attribute_id = @a_mk AND t.store_id = 0 AND uk.value = @uk;

-- ---------------------------------------------------------------- 126 -------
SET @uk := 'marketing-analytics-courses';
SET @mt := 'Marketing Analytics Courses in Singapore | Tertiary Courses';
SET @md := 'Master marketing analytics with hands-on GA4 and Google Tag Manager training. Track campaigns, measure conversions and turn web data into marketing decisions.';
SET @mk := 'marketing analytics, Google Analytics 4, GA4 courses, Google Tag Manager, web analytics, digital marketing analytics, conversion tracking';

UPDATE catalog_category_entity_varchar v
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = v.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET v.value = @mt WHERE v.attribute_id = @a_mt AND v.store_id = 0 AND uk.value = @uk;
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @md WHERE t.attribute_id = @a_md AND t.store_id = 0 AND uk.value = @uk;
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @mk WHERE t.attribute_id = @a_mk AND t.store_id = 0 AND uk.value = @uk;

-- ---------------------------------------------------------------- 250 -------
-- meta_title was already correct; description + keywords were digital-human copy.
SET @uk := 'ai-devops-series-courses';
SET @md := 'Apply AI to your DevOps pipeline with hands-on Docker, Kubernetes and Jenkins training, plus building live voice and video agents with n8n and Google ADK.';
SET @mk := 'AI DevOps, Docker courses, Kubernetes training, Jenkins CI/CD, DevOps automation, voice agents, n8n';

UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @md WHERE t.attribute_id = @a_md AND t.store_id = 0 AND uk.value = @uk;
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @mk WHERE t.attribute_id = @a_mk AND t.store_id = 0 AND uk.value = @uk;

-- ---------------------------------------------------------------- 283 -------
-- meta_title was already correct; description + keywords were Keras/TF/JAX copy.
SET @uk := 'codex-ai-series';
SET @md := 'Learn to build software with OpenAI Codex. Hands-on courses covering agentic coding workflows, prompting Codex effectively and reviewing AI-generated code.';
SET @mk := 'Codex, OpenAI Codex, agentic coding, AI coding assistant, AI pair programming, vibe coding';

UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @md WHERE t.attribute_id = @a_md AND t.store_id = 0 AND uk.value = @uk;
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @mk WHERE t.attribute_id = @a_mk AND t.store_id = 0 AND uk.value = @uk;

-- ---------------------------------------------------------------- 419 -------
-- No meta rows at all -> seed them.
SET @uk := 'google-certification-courses';
SET @mt := 'Google Cloud Certification Exam Prep Courses | Tertiary Courses';
SET @md := 'Prepare for Google Cloud certification with courses mapped to the official exam blueprints - Associate Cloud Engineer through the Professional Architect, Data, Security and ML Engineer tracks.';
SET @mk := 'Google Cloud certification, Associate Cloud Engineer, Professional Cloud Architect, Professional Data Engineer, GCP exam prep, Google certification courses';

UPDATE catalog_category_entity_varchar v
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = v.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET v.value = @mt WHERE v.attribute_id = @a_mt AND v.store_id = 0 AND uk.value = @uk;
INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_mt, 0, uk.entity_id, @mt FROM catalog_category_entity_varchar uk
WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @uk
  AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_varchar x
                  WHERE x.entity_id = uk.entity_id AND x.attribute_id = @a_mt AND x.store_id = 0);

UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @md WHERE t.attribute_id = @a_md AND t.store_id = 0 AND uk.value = @uk;
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_md, 0, uk.entity_id, @md FROM catalog_category_entity_varchar uk
WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @uk
  AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_text x
                  WHERE x.entity_id = uk.entity_id AND x.attribute_id = @a_md AND x.store_id = 0);

UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @mk WHERE t.attribute_id = @a_mk AND t.store_id = 0 AND uk.value = @uk;
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_mk, 0, uk.entity_id, @mk FROM catalog_category_entity_varchar uk
WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @uk
  AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_text x
                  WHERE x.entity_id = uk.entity_id AND x.attribute_id = @a_mk AND x.store_id = 0);
