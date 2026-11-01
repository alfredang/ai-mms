-- SEO: rank Singapore for "cyber security training in Singapore" (user directive 2026-11-01).
--
--   161 IT Security     /cyber-security-digital-forensic-training-courses.html -> PRIMARY landing page for
--                        cyber security training / courses / cybersecurity course (+ "Singapore"). Google already
--                        ranks this page for the keyword (Firecrawl baseline 2026-11-01).
--   385 Cyber Security /cybersecurity-threat-analysis-courses.html -> retargeted to "cybersecurity certification"
--                        so it stops competing with the hub, and links up to it.
--
-- meta_title stored BARE (MMD_Seotitle adds "| Tertiary Courses Singapore"); keyword-first meta description;
-- copy = existing banner (alt text retargeted) + keyword H2, the category's real course list, who-should-attend,
-- FAQs, funding line, cross-links. Store-view overrides removed so store 0 wins.
--
-- SG-only (store guard) + keyed on entity id AND current name -> no-op on MY/GH and on a renamed category.
-- Idempotent. Post-apply: catalog_category_flat reindex + cache flush.

SET @site := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @c_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @c_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @c_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description' AND backend_type = 'text');
SET @c_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords' AND backend_type = 'text');
SET @c_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description' AND backend_type = 'text');
SET @ok := (@site = 1 AND @c_name IS NOT NULL AND @c_mtitle IS NOT NULL AND @c_mdesc IS NOT NULL AND @c_mkey IS NOT NULL AND @c_desc IS NOT NULL);

DROP TABLE IF EXISTS mms_seo_cyber_kw_stage;

CREATE TABLE mms_seo_cyber_kw_stage (
  id     INT UNSIGNED NOT NULL PRIMARY KEY,
  name   VARCHAR(255) NOT NULL,
  mt     VARCHAR(255) NOT NULL,
  md     TEXT NOT NULL,
  mk     TEXT NOT NULL,
  body   TEXT NOT NULL,
  banner TEXT NULL,
  full   MEDIUMTEXT NULL
) DEFAULT CHARSET = utf8;

INSERT INTO mms_seo_cyber_kw_stage (id, name, mt, md, mk, body) VALUES
(161, 'IT Security', 'Cyber Security Training & Courses in Singapore', 'Cyber security training in Singapore: CISSP, CompTIA Security+, CySA+ and PenTest+ prep, AI for cyber security and staff awareness. WSQ-funded options.', 'cyber security training singapore, cyber security courses singapore, cybersecurity course singapore, cyber security training, CISSP training, CompTIA Security+ training, WSQ cyber security course, SkillsFuture Credit course', '<h2>Cyber Security Training in Singapore</h2>
<p>Our <strong>cyber security training in Singapore</strong> helps IT teams, security analysts and everyday staff protect systems, data and people from cyber threats. Classes are instructor-led with hands-on labs, from a one-day awareness workshop to exam prep for leading <strong>cybersecurity</strong> certifications such as CISSP and CompTIA Security+.</p>
<p>The <strong>cyber security courses</strong> below cover security operations, threat analysis, penetration testing, network security and data protection, plus AI for cyber security and securing AI agents. Pick one course for a specific skill, or follow a certification path from foundation to advanced level.</p>
<h3>Cybersecurity Certification Courses</h3>
<ul>
<li>ISC2 Information Systems Security Professional (CISSP) Training</li>
<li>CompTIA Certified Security+ Training</li>
<li>CompTIA Cybersecurity Analyst (CySA+) Training</li>
<li>CompTIA PenTest+ Training</li>
<li>CompTIA Certified SecurityX Training</li>
<li>CompTIA SecAI+ Training</li>
<li>Microsoft Identity and Access Administrator (SC-300)</li>
</ul>
<h3>AI for Cyber Security</h3>
<ul>
<li>AI for Cyber Security</li>
<li>AI Agent Cybersecurity</li>
<li>Security Operations for Autonomous AI Agents</li>
<li>AI for IT Security</li>
<li>AI for IT Security Professionals</li>
<li>AI Security Governance for Businesses</li>
</ul>
<h3>Security Awareness and Data Protection</h3>
<ul>
<li>Cyber Security Awareness Workshop</li>
<li>Cyber Security Awareness Course for Personal and Businesses</li>
<li>Navigating Digital Threats: Proactive Measures Against Cyber Frauds and Scams</li>
<li>Personal Data Protection Management for SMEs</li>
</ul>
<h3>Network Security</h3>
<ul>
<li>Network Securities for Beginners</li>
<li>AI for Network Security</li>
<li>AI for IT Networking</li>
<li>Wireshark Network Analysis Masterclass</li>
</ul>
<p>Prefer to study online? The Advanced Certificate in Cyber Security (E-Learning) covers the core topics at your own pace.</p>
<h2>Who Should Attend</h2>
<p>IT and network administrators, security analysts, developers, risk and compliance staff, and managers who are responsible for protecting company systems and data. Awareness courses suit any employee who uses email and the internet at work.</p>
<h2>Cyber Security Training FAQs</h2>
<p><strong>Do I need IT experience to start?</strong> Not for the awareness courses, which are written for everyday staff. Certification and technical courses expect basic IT and networking knowledge, and each course page lists its prerequisites.</p>
<p><strong>Which cybersecurity certification should I start with?</strong> Most people start with CompTIA Security+. From there, CySA+ builds threat detection and analysis skills, PenTest+ covers penetration testing, and CISSP suits experienced practitioners moving into security management. Compare them on our <a href="/cybersecurity-threat-analysis-courses.html">cybersecurity certification courses</a> page.</p>
<p><strong>Can you run these courses for our company?</strong> Yes. Any course can run as in-house training for your team in Singapore, at your office or online.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/cybersecurity-threat-analysis-courses.html">cybersecurity certification courses</a>, <a href="/pentest-ethical-hacking-courses.html">ethical hacking and pentest training</a>, <a href="/network-securities-courses.html">network security courses</a>, <a href="/wsq-cyber-security-pdpa-courses.html">WSQ cyber security and PDPA courses</a>, <a href="/ai-security-series.html">AI security training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(385, 'Cyber Security', 'Cybersecurity Certification Courses in Singapore', 'Cybersecurity certification courses in Singapore: exam prep for CISSP, CompTIA Security+, CySA+, SecurityX, SecAI+ and SC-300. WSQ-funded options.', 'cybersecurity certification singapore, cybersecurity certification courses, CISSP training singapore, CompTIA Security+ training, CySA+ training, SecAI+ training, WSQ CISSP course', '<h2>Cybersecurity Certification Courses in Singapore</h2>
<p>Prepare for a recognised <strong>cybersecurity certification</strong> with instructor-led exam prep for ISC2 CISSP, CompTIA Security+, CySA+, SecurityX and SecAI+, and Microsoft SC-300. Each course follows the official exam objectives, with practice questions and hands-on labs. Staff who need the basics can start with a security awareness, scam prevention or PDPA course.</p>
<h2>Courses in This Category</h2>
<ul>
<li>ISC2 Information Systems Security Professional (CISSP) Training</li>
<li>CISSP Exam Prep</li>
<li>CompTIA Certified Security+ Training</li>
<li>CompTIA Cybersecurity Analyst (CySA+) Training</li>
<li>CompTIA Certified SecurityX Training</li>
<li>CompTIA SecAI+ Training</li>
<li>Microsoft Identity and Access Administrator (SC-300)</li>
<li>Advanced Certificate in Cyber Security (E-Learning)</li>
<li>Cyber Security Awareness Course for Personal and Businesses</li>
<li>Navigating Digital Threats: Proactive Measures Against Cyber Frauds and Scams</li>
<li>Personal Data Protection Management for SMEs</li>
</ul>
<h2>Which Certification Should I Take?</h2>
<p>Start with CompTIA Security+ if you are new to security work. Move on to CySA+ for threat detection and incident response, SecurityX for senior security engineering, and SecAI+ for securing AI systems. CISSP suits experienced practitioners heading into security management; ISC2 requires relevant work experience for the full CISSP credential.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Looking for penetration testing, network security or AI for cyber security as well? See all our <a href="/cyber-security-digital-forensic-training-courses.html">cyber security training in Singapore</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>');

-- keep only categories whose current (store-view else store-0) name still matches
DELETE s FROM mms_seo_cyber_kw_stage s
  LEFT JOIN catalog_category_entity_varchar n0 ON n0.entity_id = s.id AND n0.attribute_id = @c_name AND n0.store_id = 0
  LEFT JOIN catalog_category_entity_varchar n1 ON n1.entity_id = s.id AND n1.attribute_id = @c_name AND n1.store_id = 1
 WHERE TRIM(COALESCE(n1.value, n0.value, '')) <> s.name;

-- keep the existing banner paragraph (first <p class="category-image">...</p>), retarget its alt text,
-- and replace the copy after it
UPDATE mms_seo_cyber_kw_stage s
  LEFT JOIN catalog_category_entity_text t ON t.entity_id = s.id AND t.attribute_id = @c_desc AND t.store_id = 0
   SET s.banner = IF(t.value LIKE '<p class="category-image">%', SUBSTRING(t.value, 1, LOCATE('</p>', t.value) + 3), '');

UPDATE mms_seo_cyber_kw_stage
   SET banner = REPLACE(REPLACE(banner,
         'alt="IT Security training courses in Singapore"', 'alt="Cyber security training courses in Singapore"'),
         'alt="Cyber Security training courses in Singapore"', 'alt="Cybersecurity certification courses in Singapore"');

UPDATE mms_seo_cyber_kw_stage SET full = IF(banner = '', body, CONCAT(banner, '\n', body));

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mtitle, 0, s.id, s.mt FROM mms_seo_cyber_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mdesc, 0, s.id, s.md FROM mms_seo_cyber_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mkey, 0, s.id, s.mk FROM mms_seo_cyber_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_desc, 0, s.id, s.full FROM mms_seo_cyber_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE v FROM catalog_category_entity_varchar v JOIN mms_seo_cyber_kw_stage s ON s.id = v.entity_id
 WHERE @ok AND v.attribute_id = @c_mtitle AND v.store_id <> 0;

DELETE t FROM catalog_category_entity_text t JOIN mms_seo_cyber_kw_stage s ON s.id = t.entity_id
 WHERE @ok AND t.attribute_id IN (@c_mdesc, @c_mkey, @c_desc) AND t.store_id <> 0;

-- mirror into the store category flat table when it exists (reindex would do the same)
SET @has_flat := (SELECT COUNT(*) FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
                     AND COLUMN_NAME IN ('meta_title', 'meta_description', 'meta_keywords', 'description'));
SET @q := IF(@ok AND @has_flat = 4,
  'UPDATE catalog_category_flat_store_1 f JOIN mms_seo_cyber_kw_stage s ON s.id = f.entity_id SET f.meta_title = s.mt, f.meta_description = s.md, f.meta_keywords = s.mk, f.description = s.full',
  'DO 0');
PREPARE st FROM @q;
EXECUTE st;
DEALLOCATE PREPARE st;

DROP TABLE IF EXISTS mms_seo_cyber_kw_stage;
