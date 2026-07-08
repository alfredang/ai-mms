-- 314-home-slider-industry5-and-ai.sql
-- SG homepage carousel (Infortis UltraSlideshow -> block_slide1, block_slide2, block_slide3):
--   * Slide 1 (block_slide1): swap the WSQ-IBF banner for the new "WSQ & SkillsFuture
--     for Industry 5.0 Courses" banner, linking to the WSQ IBF SkillsFuture UTAP funded
--     courses page.
--   * Slide 2 (block_slide2): replace the CompTIA Certification Exam Prep banner with the
--     new "SkillsFuture AI Courses and Training" banner, linking to the WSQ Agentic AI
--     Courses page.
--   * Slide 3 (block_slide3): replace the "Certify Your Skills" banner with the new "WSQ &
--     SkillsFuture for Certification Exam Prep Courses" banner, linking to the
--     Certification Exam Prep Courses page.
--
-- Each is a targeted REPLACE() keyed off the FULL, unique SG <a> markup (the .com.sg
-- domain distinguishes it from the MY/GH/legacy slides that share the same
-- Comptia-cybsercurity.jpg / Certify_Your_Skills.png images). This guarantees only the
-- three SG homepage rows change and never a partner slide. Idempotent: after the swap the
-- old markup no longer matches, so a re-run is a no-op. MY/GH homepages never carried these
-- exact SG anchors, so this is a no-op on those partner DBs. New banner images ship in
-- media/wysiwyg/ (baked into the image via the .dockerignore wysiwyg negation).

-- Slide 1: WSQ-IBF -> Industry 5.0
UPDATE cms_block
SET content = REPLACE(
  content,
  '<a href="https://www.tertiarycourses.com.sg/wsq-courses.html"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/WSQ-IBF-SkillsFuture-Courses-Singapore.jpg" alt="WSQ IBF SkillsFuture Credit Courses in Singapore" /></a>',
  '<a href="https://www.tertiarycourses.com.sg/wsq-ibf-skillsfuture-utap-funded-courses.html"><img src="https://www.tertiarycourses.com.sg/media/wysiwyg/wsq-skillsfuture-industry5-courses.jpg" alt="WSQ SkillsFuture Industry 5.0 Funded Courses in Singapore" /></a>'
)
WHERE content LIKE '%media/wysiwyg/WSQ-IBF-SkillsFuture-Courses-Singapore.jpg" alt="WSQ IBF SkillsFuture Credit Courses in Singapore%';

-- Slide 2: CompTIA -> SkillsFuture AI Courses and Training
UPDATE cms_block
SET content = REPLACE(
  content,
  '<a href="https://www.tertiarycourses.com.sg/comptia-certification-exam-prep-courses.html"><img alt="CompTIA Certification Exam Prep - Tertiary Courses Singapore" src="https://www.tertiarycourses.com.sg/media/wysiwyg/Comptia-cybsercurity.jpg" /></a>',
  '<a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-courses.html"><img alt="WSQ SkillsFuture AI Courses and Training - Tertiary Courses Singapore" src="https://www.tertiarycourses.com.sg/media/wysiwyg/skillsfuture-ai-courses.jpg" /></a>'
)
WHERE content LIKE '%tertiarycourses.com.sg/comptia-certification-exam-prep-courses.html%';

-- Slide 3: "Certify Your Skills" -> Certification Exam Prep Courses
UPDATE cms_block
SET content = REPLACE(
  content,
  '<p><a href="https://www.tertiarycourses.com.sg/certification-courses.html" title="Certify Your Skills with Microsoft, AWS, Google, Autodesk Meta, CisCO COMPTIA Certification Exam Prep"><img alt="Certify Your Skills with Microsoft, AWS, Google, Autodesk Meta, CisCO COMPTIA Certification Exam Prep" src="https://www.tertiarycourses.com.sg/media/wysiwyg/Certify_Your_Skills.png" title="Certify Your Skills with Microsoft, AWS, Google, Autodesk Meta, CisCO COMPTIA Certification Exam Prep" /></a></p>',
  '<p><a href="https://www.tertiarycourses.com.sg/certification-exam-prep-courses.html" title="WSQ SkillsFuture Certification Exam Prep Courses"><img alt="WSQ SkillsFuture Certification Exam Prep Courses - Tertiary Courses Singapore" src="https://www.tertiarycourses.com.sg/media/wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg" title="WSQ SkillsFuture Certification Exam Prep Courses" /></a></p>'
)
WHERE content LIKE '%tertiarycourses.com.sg/certification-courses.html%';
