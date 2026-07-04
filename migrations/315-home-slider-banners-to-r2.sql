-- 315-home-slider-banners-to-r2.sql
-- Point the three SG homepage carousel banners (set by migration 314) at their
-- Cloudflare R2 public URLs instead of the baked-in /media/wysiwyg/ path, so the
-- images are served from R2 (bucket tertiarycourses-media, key wysiwyg/<file>) and
-- no longer need to ship inside the Docker image.
--
-- Each is a targeted REPLACE keyed off the full, unique SG media URL, so it only
-- touches the SG carousel rows and is idempotent (after the swap the old URL no
-- longer matches). No-op on MY/GH partner DBs, which never carried these filenames.
--
-- R2 public base: https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/wysiwyg/
-- Uploaded via MMD_CourseImage_Helper_R2::putObject (see the catalog-category R2
-- convention in scripts/maintenance/upload-category-images-to-r2.php).

-- Slide 1: Industry 5.0
UPDATE cms_block
SET content = REPLACE(
  content,
  'https://www.tertiarycourses.com.sg/media/wysiwyg/wsq-skillsfuture-industry5-courses.jpg',
  'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/wysiwyg/wsq-skillsfuture-industry5-courses.jpg'
)
WHERE content LIKE '%tertiarycourses.com.sg/media/wysiwyg/wsq-skillsfuture-industry5-courses.jpg%';

-- Slide 2: SkillsFuture AI Courses and Training
UPDATE cms_block
SET content = REPLACE(
  content,
  'https://www.tertiarycourses.com.sg/media/wysiwyg/skillsfuture-ai-courses.jpg',
  'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/wysiwyg/skillsfuture-ai-courses.jpg'
)
WHERE content LIKE '%tertiarycourses.com.sg/media/wysiwyg/skillsfuture-ai-courses.jpg%';

-- Slide 3: Certification Exam Prep Courses
UPDATE cms_block
SET content = REPLACE(
  content,
  'https://www.tertiarycourses.com.sg/media/wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg',
  'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg'
)
WHERE content LIKE '%tertiarycourses.com.sg/media/wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg%';
