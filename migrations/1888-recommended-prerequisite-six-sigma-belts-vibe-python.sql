-- Recommended (not mandatory) prerequisite cards (user, 2026-10-26):
--   Lean Six Sigma Black Belt  -> Green Belt
--   Lean Six Sigma Green Belt  -> Yellow Belt
--   Lean Six Sigma Yellow Belt -> White Belt
--   AI Vibe Coding with Python -> Python Fundamentals
-- Non-WSQ (C-) courses point at the non-WSQ course, WSQ (TGS-) courses at the WSQ twin.
-- C- cards are replaced only while they still hold the beginners line (peer-safe); TGS- cards are
-- created only when missing (the storefront card now renders for TGS- too). SG-only (store guard).

SET @ok := ((SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);
SET @beg := '<p>This course is for beginners. No prerequisite is required.</p>';
SET @u := 'https://www.tertiarycourses.com.sg/';

DROP TEMPORARY TABLE IF EXISTS tmp_rec_prereq;
CREATE TEMPORARY TABLE tmp_rec_prereq (sku VARCHAR(32) NOT NULL PRIMARY KEY, url_key VARCHAR(255) NOT NULL,
                                       title VARCHAR(255) NOT NULL, code VARCHAR(32) NOT NULL) DEFAULT CHARSET = utf8;
INSERT INTO tmp_rec_prereq (sku, url_key, title, code) VALUES
('C913',           'certified-lean-six-sigma-green-belt',                      'Certified Lean Six Sigma Green Belt (CLSSGB)',                       'C481'),
('C481',           'certified-lean-six-sigma-yellow-belt',                     'Certified Lean Six Sigma Yellow Belt (CLSSYB)',                      'C524'),
('C524',           'certified-lean-six-sigma-white-belt',                      'Certified Lean Six Sigma White Belt (CLSSWB)',                       'C142'),
('C138',           'python-fundamentals-masterclass',                          'Python Fundamentals Masterclass',                                    'C179'),
('TGS-2024051900', 'wsq-certified-lean-six-sigma-green-belt-clssgb-training',  'WSQ - Certified Lean Six Sigma Green Belt (CLSSGB) Training',        'TGS-2025055775'),
('TGS-2025055775', 'wsq-certified-lean-six-sigma-yellow-belt-clssyb-training', 'WSQ - Certified Lean Six Sigma Yellow Belt (CLSSYB) Training',       'TGS-2025053922'),
('TGS-2025053922', 'wsq-certified-lean-six-sigma-white-belt-clsswb-training',  'WSQ - Certified Lean Six Sigma White Belt (CLSSWB) Training',        'TGS-2025053210'),
('TGS-2019504591', 'wsq-python-fundamental-course-for-beginners',              'WSQ - Python Fundamental Course for Beginners',                      'TGS-2019503161');

DROP TEMPORARY TABLE IF EXISTS tmp_rec_card;
CREATE TEMPORARY TABLE tmp_rec_card (sku VARCHAR(32) NOT NULL PRIMARY KEY, content TEXT NOT NULL) DEFAULT CHARSET = utf8;
INSERT INTO tmp_rec_card (sku, content)
SELECT r.sku, CONCAT('<p><strong>Recommended, not mandatory:</strong> we recommend completing <a href="', @u, r.url_key,
       '.html" title="', r.title, '">', r.title, ' (', r.code, ')</a> before taking this course.</p>\n',
       '<p>You may still enrol directly if you already have equivalent knowledge or experience.</p>')
  FROM tmp_rec_prereq r
 WHERE @ok AND EXISTS (SELECT 1 FROM catalog_product_entity e WHERE TRIM(e.sku) = r.sku);

UPDATE cms_block b
  JOIN tmp_rec_card c ON b.identifier = CONCAT('course_', c.sku, '_prerequisite') COLLATE utf8_general_ci
   SET b.content = c.content, b.update_time = NOW()
 WHERE TRIM(b.content) = @beg;

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', c.sku, ' - Prerequisite'), CONCAT('course_', c.sku, '_prerequisite'), c.content, NOW(), NOW(), 1
  FROM tmp_rec_card c
 WHERE NOT EXISTS (SELECT 1 FROM cms_block b WHERE b.identifier = CONCAT('course_', c.sku, '_prerequisite') COLLATE utf8_general_ci);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
  JOIN tmp_rec_card c ON b.identifier = CONCAT('course_', c.sku, '_prerequisite') COLLATE utf8_general_ci;

DROP TEMPORARY TABLE IF EXISTS tmp_rec_card;
DROP TEMPORARY TABLE IF EXISTS tmp_rec_prereq;
