-- Security categories (user request 2026-11-02): make every page name distinct so visitors and Google
-- cannot confuse them. Follows 1884 (cyber security training landing page).
--
--   161 "IT Security"        -> "Cyber Security"               main page for "cyber security training"
--   385 "Cyber Security"     -> "Cybersecurity Certifications" exam prep only
--   386 "Network Securities" -> "Network Security"             grammar
--
-- URLs unchanged. The main page takes the existing "CYBER SECURITY" banner from 385 (its own banner reads
-- "IT SECURITY"); 385 shows no banner until a certifications banner is made. 385 becomes
-- certification-only: awareness / AI / scam / PDPA / specialisation courses come off it (they stay on the main
-- page - any without a direct row there get one first, else the anchor main page would lose them) and
-- CompTIA PenTest+ is added. Membership keyed on SKU, renames on the current name.
--
-- SG-only (store guard) -> no-op on MY/GH.
-- Idempotent. Post-apply: catalog_category_product + catalog_category_flat reindex, cache flush.

SET @site := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @c_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @c_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @c_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description' AND backend_type = 'text');
SET @c_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords' AND backend_type = 'text');
SET @c_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description' AND backend_type = 'text');
SET @ok := (@site = 1 AND @c_name IS NOT NULL AND @c_mtitle IS NOT NULL AND @c_mdesc IS NOT NULL AND @c_mkey IS NOT NULL AND @c_desc IS NOT NULL);

-- ---- 1. renames (every store row; keyed on entity id AND the current name) ----
UPDATE catalog_category_entity_varchar SET value = 'Cyber Security'
 WHERE @ok AND attribute_id = @c_name AND entity_id = 161 AND TRIM(value) = 'IT Security';
UPDATE catalog_category_entity_varchar SET value = 'Cybersecurity Certifications'
 WHERE @ok AND attribute_id = @c_name AND entity_id = 385 AND TRIM(value) = 'Cyber Security';
UPDATE catalog_category_entity_varchar SET value = 'Network Security'
 WHERE @ok AND attribute_id = @c_name AND entity_id = 386 AND TRIM(value) = 'Network Securities';

SET @hub_ok  := @ok AND (SELECT COUNT(*) FROM catalog_category_entity_varchar WHERE attribute_id = @c_name AND entity_id = 161 AND store_id = 0 AND value = 'Cyber Security') = 1;
SET @cert_ok := @ok AND (SELECT COUNT(*) FROM catalog_category_entity_varchar WHERE attribute_id = @c_name AND entity_id = 385 AND store_id = 0 AND value = 'Cybersecurity Certifications') = 1;

-- ---- 2. banner: main page takes the certifications page's "CYBER SECURITY" banner ----
SET @cert_desc := (SELECT value FROM catalog_category_entity_text WHERE attribute_id = @c_desc AND entity_id = 385 AND store_id = 0);
SET @cert_banner := IF(@cert_desc LIKE '<p class="category-image">%', SUBSTRING(@cert_desc, 1, LOCATE('</p>', @cert_desc) + 3), '');
UPDATE catalog_category_entity_text
   SET value = CONCAT(REPLACE(@cert_banner, 'alt="Cybersecurity certification courses in Singapore"', 'alt="Cyber security training courses in Singapore"'),
                      SUBSTRING(value, LOCATE('</p>', value) + 4))
 WHERE @hub_ok AND @cert_ok AND @cert_banner <> '' AND attribute_id = @c_desc AND entity_id = 161 AND store_id = 0
   AND value LIKE '<p class="category-image">%';

-- ---- 3. certifications page copy + meta (no banner) ----
INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mtitle, 0, 385, 'Cybersecurity Certification Courses in Singapore' FROM DUAL WHERE @cert_ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mdesc, 0, 385, 'Cybersecurity certification courses in Singapore: exam prep for CISSP, CompTIA Security+, CySA+, PenTest+, SecurityX, SecAI+ and SC-300. WSQ-funded.' FROM DUAL WHERE @cert_ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mkey, 0, 385, 'cybersecurity certification singapore, cybersecurity certification courses, CISSP training singapore, CompTIA Security+ training, CySA+ training, SecAI+ training, WSQ CISSP course' FROM DUAL WHERE @cert_ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_desc, 0, 385, '<h2>Cybersecurity Certification Courses in Singapore</h2>
<p>Prepare for a recognised <strong>cybersecurity certification</strong> with instructor-led exam prep for ISC2 CISSP, CompTIA Security+, CySA+, PenTest+, SecurityX and SecAI+, and Microsoft SC-300. Each course follows the official exam objectives, with practice questions and hands-on labs.</p>
<h2>Courses in This Category</h2>
<ul>
<li>ISC2 Information Systems Security Professional (CISSP) Training</li>
<li>CISSP Exam Prep</li>
<li>CompTIA Certified Security+ Training</li>
<li>CompTIA Security+ Exam Prep</li>
<li>CompTIA Cybersecurity Analyst (CySA+) Training</li>
<li>CompTIA PenTest+ Training</li>
<li>CompTIA Certified SecurityX Training</li>
<li>CompTIA SecAI+ Training</li>
<li>Microsoft Identity and Access Administrator (SC-300)</li>
</ul>
<h2>Which Certification Should I Take?</h2>
<p>Start with CompTIA Security+ if you are new to security work. Then choose by role: CySA+ for threat detection and incident response, PenTest+ for penetration testing, SecurityX for senior security engineering, and SecAI+ for securing AI systems. CISSP suits experienced practitioners heading into security management; ISC2 requires relevant work experience for the full CISSP credential.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>New to cyber security, or training everyday staff? Our <a href="/cyber-security-digital-forensic-training-courses.html">cyber security training in Singapore</a> also covers security awareness, AI for cyber security and network security courses.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>' FROM DUAL WHERE @cert_ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_category_entity_text
 WHERE @cert_ok AND entity_id IN (161, 385) AND attribute_id IN (@c_mdesc, @c_mkey, @c_desc) AND store_id <> 0;

-- ---- 4. certifications membership (by SKU) ----
DROP TABLE IF EXISTS mms_cyber_cert_stage;
CREATE TABLE mms_cyber_cert_stage (
  sku        VARCHAR(64) NOT NULL PRIMARY KEY,
  pos        INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NULL
) DEFAULT CHARSET = utf8;
INSERT INTO mms_cyber_cert_stage (sku, pos) VALUES
('TGS-2024043392', 1),
('TGS-2023039181', 2),
('TGS-2024049211', 3),
('TGS-2026064471', 4),
('TGS-2025053927', 5),
('TGS-2024047021', 6),
('C371', 7),
('C893', 8),
('C483', 9),
('C718', 10),
('C916', 11),
('C1136', 12),
('C1750', 13),
('C628', 14),
('C876', 15),
('C920', 16),
('C1436', 17),
('C542', 18),
('C591', 19),
('C217', 20),
('C164', 21),
('C472', 22);
UPDATE mms_cyber_cert_stage s JOIN catalog_product_entity p ON p.sku = s.sku SET s.product_id = p.entity_id;

-- courses leaving the certifications page keep a DIRECT row on the main page (TGS- in the funded block)
SET @hub_tgs_pos := (SELECT COALESCE(MAX(cp.position), 0) FROM catalog_category_product cp
                       JOIN catalog_product_entity p ON p.entity_id = cp.product_id
                      WHERE cp.category_id = 161 AND p.sku LIKE 'TGS-%');
SET @hub_max_pos := (SELECT COALESCE(MAX(position), 0) FROM catalog_category_product WHERE category_id = 161);
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 161, cp.product_id, IF(p.sku LIKE 'TGS-%', @hub_tgs_pos, @hub_max_pos + 1)
  FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  LEFT JOIN mms_cyber_cert_stage s ON s.product_id = cp.product_id
 WHERE @cert_ok AND cp.category_id = 385 AND s.sku IS NULL;

DELETE cp FROM catalog_category_product cp
  LEFT JOIN mms_cyber_cert_stage s ON s.product_id = cp.product_id
 WHERE @cert_ok AND cp.category_id = 385 AND s.sku IS NULL;

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 385, s.product_id, s.pos FROM mms_cyber_cert_stage s WHERE @cert_ok AND s.product_id IS NOT NULL
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- mirror into the product index (a reindex does the same)
DELETE i FROM catalog_category_product_index i
  LEFT JOIN mms_cyber_cert_stage s ON s.product_id = i.product_id
 WHERE @cert_ok AND i.category_id = 385 AND s.sku IS NULL;
INSERT INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 385, s.product_id, s.pos, 1, h.store_id, h.visibility
  FROM mms_cyber_cert_stage s
  JOIN catalog_category_product_index h ON h.category_id = 161 AND h.product_id = s.product_id
 WHERE @cert_ok
ON DUPLICATE KEY UPDATE position = VALUES(position);

DROP TABLE IF EXISTS mms_cyber_cert_stage;

-- ---- 5. mirror names / copy into the store category flat table when it exists ----
SET @has_flat := (SELECT COUNT(*) FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
                     AND COLUMN_NAME IN ('name', 'meta_title', 'meta_description', 'meta_keywords', 'description'));
SET @q := IF(@ok AND @has_flat = 5,
  'UPDATE catalog_category_flat_store_1 f
      JOIN catalog_category_entity_varchar n ON n.entity_id = f.entity_id AND n.attribute_id = @c_name AND n.store_id = 0
      LEFT JOIN catalog_category_entity_varchar t ON t.entity_id = f.entity_id AND t.attribute_id = @c_mtitle AND t.store_id = 0
      LEFT JOIN catalog_category_entity_text md ON md.entity_id = f.entity_id AND md.attribute_id = @c_mdesc AND md.store_id = 0
      LEFT JOIN catalog_category_entity_text mk ON mk.entity_id = f.entity_id AND mk.attribute_id = @c_mkey AND mk.store_id = 0
      LEFT JOIN catalog_category_entity_text d ON d.entity_id = f.entity_id AND d.attribute_id = @c_desc AND d.store_id = 0
      SET f.name = n.value, f.meta_title = t.value, f.meta_description = md.value, f.meta_keywords = mk.value, f.description = d.value
    WHERE f.entity_id IN (161, 385, 386)',
  'DO 0');
PREPARE st FROM @q;
EXECUTE st;
DEALLOCATE PREPARE st;
