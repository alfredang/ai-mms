-- 633: route high-traffic UNMATCHED search terms to a relevant CATEGORY page.
--
-- WHY: 632 cleared 3,359 redirects that pointed at disabled courses, which was right
-- (a search-results page beats a 404). But that leaves high-traffic terms landing on
-- a thin or empty result set -- "Basic Docker Training" (189 searches) returned an
-- unrelated GenAI course, "Devops essential training" (173) returned nothing useful.
-- These terms name a TOPIC we still teach; only the specific old course is retired.
--
-- WHAT: maps each term to a live CATEGORY page that actually holds enabled courses,
-- e.g. Basic Docker Training -> docker-courses (14 live courses),
--      Devops essential training -> devops-courses (16),
--      NICF Python -> python-programming (13).
--
-- WHY CATEGORY, NOT PRODUCT: an auto-matched PRODUCT redirect is dangerous. Naive
-- name matching confidently proposed "Database Training with Microsoft Access" ->
-- Identity and *Access* Administrator, and "ADOBE ANIMATE CC" -> InDesign Masterclass.
-- A category page shows the whole topic and lets the learner choose, so a slightly
-- loose match degrades gracefully instead of landing on a confidently wrong course.
--
-- HOW THE MAP WAS BUILT (not hand-guessed):
--   * stopword-filtered token overlap between the query and the CATEGORY name
--     (drops training/course/basic/advanced/wsq/nicf/exam/prep/... so
--     "Basic Docker Training" reduces to {docker})
--   * SYMMETRIC score = overlap / max(|query|, |category|), so a one-word hit against
--     a long category name does NOT score 1.0; threshold 0.75
--   * category must be is_active = 1 AND contain >= 1 ENABLED product
--   * every one of the 27 distinct target URLs was HTTP-verified 200 before shipping
--
-- Fills EMPTY redirects only, so nothing from 621-631 and no curated redirect is
-- overwritten. Partner-safe via the SG store-code guard. Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

DROP TEMPORARY TABLE IF EXISTS tmp_cat_route;
CREATE TEMPORARY TABLE tmp_cat_route (
  term   VARCHAR(191) NOT NULL PRIMARY KEY,
  target VARCHAR(255) NOT NULL
) ENGINE=MEMORY;

INSERT INTO tmp_cat_route (term, target) VALUES
  ('advanced cyber security','https://www.tertiarycourses.com.sg/cybersecurity-threat-analysis-courses.html'),
  ('advanced cyber security course','https://www.tertiarycourses.com.sg/cybersecurity-threat-analysis-courses.html'),
  ('advanced docker','https://www.tertiarycourses.com.sg/docker-courses.html'),
  ('advanced docker training','https://www.tertiarycourses.com.sg/docker-courses.html'),
  ('advanced facebook','https://www.tertiarycourses.com.sg/facebook-marketing-advertisting-courses.html'),
  ('advanced google analytics','https://www.tertiarycourses.com.sg/google-analytics-courses.html'),
  ('advanced google analytics training','https://www.tertiarycourses.com.sg/google-analytics-courses.html'),
  ('advanced google workspace','https://www.tertiarycourses.com.sg/google-g-suite-trainings.html'),
  ('advanced kubernetes training','https://www.tertiarycourses.com.sg/kubernetes-courses.html'),
  ('advanced raspberry pi','https://www.tertiarycourses.com.sg/raspberry-pi-courses-in.html'),
  ('advanced raspberry pi training','https://www.tertiarycourses.com.sg/raspberry-pi-courses-in.html'),
  ('advanced rpa','https://www.tertiarycourses.com.sg/rpa-api-it-automation-courses.html'),
  ('arduino internet of things (iot) course','https://www.tertiarycourses.com.sg/internet-of-things-iot-training-in.html'),
  ('autodesk civil 3d essential training','https://www.tertiarycourses.com.sg/autodesk-civil-3d-courses.html'),
  ('autodesk inventor essential training','https://www.tertiarycourses.com.sg/autodesk-inventor-training.html'),
  ('autodesk inventor training','https://www.tertiarycourses.com.sg/autodesk-inventor-training.html'),
  ('basic cyber security','https://www.tertiarycourses.com.sg/cybersecurity-threat-analysis-courses.html'),
  ('basic docker','https://www.tertiarycourses.com.sg/docker-courses.html'),
  ('basic docker training','https://www.tertiarycourses.com.sg/docker-courses.html'),
  ('basic facebook','https://www.tertiarycourses.com.sg/facebook-marketing-advertisting-courses.html'),
  ('basic java','https://www.tertiarycourses.com.sg/java-programming-courses.html'),
  ('basic ros','https://www.tertiarycourses.com.sg/robot-operating-system-ros-courses.html'),
  ('cyber security course','https://www.tertiarycourses.com.sg/cybersecurity-threat-analysis-courses.html'),
  ('data analytics and visualization','https://www.tertiarycourses.com.sg/wsq-data-analytics-wsq-courses.html'),
  ('devops essential training','https://www.tertiarycourses.com.sg/devops-courses.html'),
  ('digital marketing','https://www.tertiarycourses.com.sg/digital-marketing-courses-in.html'),
  ('docker essential training','https://www.tertiarycourses.com.sg/docker-courses.html'),
  ('email marketing','https://www.tertiarycourses.com.sg/email-marketing-courses-in.html'),
  ('full autodesk fusion 360 training','https://www.tertiarycourses.com.sg/autodesk-fusion-360-trainings.html'),
  ('full google analytics training','https://www.tertiarycourses.com.sg/google-analytics-courses.html'),
  ('google analytics essential','https://www.tertiarycourses.com.sg/google-analytics-courses.html'),
  ('google analytics essential training','https://www.tertiarycourses.com.sg/google-analytics-courses.html'),
  ('google analytics training','https://www.tertiarycourses.com.sg/google-analytics-courses.html'),
  ('internet-of-things (iot) training with esp32','https://www.tertiarycourses.com.sg/internet-of-things-iot-training-in.html'),
  ('internet-of-things (iot) training with lora','https://www.tertiarycourses.com.sg/internet-of-things-iot-training-in.html'),
  ('internet-of-things (iot) training with nodemcu','https://www.tertiarycourses.com.sg/internet-of-things-iot-training-in.html'),
  ('nicf - python','https://www.tertiarycourses.com.sg/python-programming.html'),
  ('nicf python','https://www.tertiarycourses.com.sg/python-programming.html'),
  ('nicf seo','https://www.tertiarycourses.com.sg/search-engine-optimisation-seo-training-courses.html'),
  ('nosql essential training','https://www.tertiarycourses.com.sg/nosql-courses.html'),
  ('notion essential training','https://www.tertiarycourses.com.sg/notion-courses.html'),
  ('python wsq','https://www.tertiarycourses.com.sg/python-programming.html'),
  ('responsive web design','https://www.tertiarycourses.com.sg/responsive-web-design-training-in.html'),
  ('responsive web design training','https://www.tertiarycourses.com.sg/responsive-web-design-training-in.html'),
  ('social media marketing with linkedin','https://www.tertiarycourses.com.sg/social-media-marketing-training-courses.html'),
  ('wsq - social media marketing with linkedin','https://www.tertiarycourses.com.sg/social-media-marketing-training-courses.html'),
  ('wsq ai','https://www.tertiarycourses.com.sg/artificial-intelligence-courses.html'),
  ('wsq data analytics','https://www.tertiarycourses.com.sg/data-analytics-courses.html'),
  ('wsq linkedin','https://www.tertiarycourses.com.sg/linkedin-social-media-marketing-courses.html'),
  ('wsq python','https://www.tertiarycourses.com.sg/python-programming.html'),
  ('wsq seo','https://www.tertiarycourses.com.sg/search-engine-optimisation-seo-training-courses.html');

UPDATE catalogsearch_query q
  JOIN tmp_cat_route m ON m.term = LOWER(TRIM(q.query_text))
SET q.redirect = m.target
WHERE @sg = 1 AND q.store_id = 1 AND (q.redirect IS NULL OR q.redirect = '');

DROP TEMPORARY TABLE IF EXISTS tmp_cat_route;
