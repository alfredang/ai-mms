-- C356 "AI for Network Security": finish the storefront side of the non-WSQ twin of
-- TGS-2024051414 (WSQ - AI for Network Security). The courseware conversion (deck, LP, LG,
-- 12 labs) is published separately; 1227 already renamed the course, moved the slug and
-- copied the parent's About + topics. This clears what the retired "AI Vibe Coding for
-- Java" course left behind on the product:
--
-- 1. meta_keyword still listed Java / JDK / Cursor.
-- 2. Cover alt text (image/small_image/thumbnail labels + gallery labels) still read
--    "AI Vibe Coding for Java".
-- 3. The "AI Vibe Coding Series" badge still rendered beside the course code.
-- 4. Job Roles (whoshouldattend) listed Java developer roles -> the WSQ parent's list.
-- 5. Minimum Software requirement listed Python / VS Code / Anaconda -> the lab toolchain
--    (Nmap, Wireshark, Python 3 with pandas + scikit-learn, an AI assistant).
-- 6. Funding block: idempotent re-assert of the WSQ-twin link (already live on prod).
--
-- Duration 15 hrs, Sessions 2 and $700 stay as they are (2 days, 9:30am - 5:30pm).
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template B17 -> B09 (counterpart of the
-- parent's "(SG) WSQ-B09") via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C356' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024051414' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @title := 'AI for Network Security';

SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_series  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_series_badge');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- --------------------------------------------------------- meta keyword -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AI for Network Security, AI Threat Detection, Network Anomaly Detection, Vulnerability Prioritisation, Network Risk Management, Zero Trust, Firewall Policy, Intrusion Detection, SIEM, SOAR, Incident Response, Adversarial Machine Learning, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- cover alt text -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @title
 WHERE @ok AND g.entity_id = @pid;

-- ------------------------------------------------- series badge removed -----
UPDATE catalog_product_entity_varchar SET value = NULL
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_series;

-- ------------------------------------------- job roles from the parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul>\n<li>IT Security Specialist</li>\n<li>Network Administrator</li>\n<li>Cybersecurity Analyst</li>\n<li>Network Security Engineer</li>\n<li>Risk Management Consultant</li>\n<li>Systems Administrator</li>\n<li>Penetration Tester</li>\n<li>IT Infrastructure Specialist</li>\n<li>Security Compliance Officer</li>\n<li>Incident Response Analyst</li>\n<li>Information Security Consultant</li>\n<li>Cybersecurity Auditor</li>\n<li>SOC (Security Operations Center) Analyst</li>\n<li>Ethical Hacker</li>\n<li>Technical Support Engineer</li>\n<li>IT Project Manager (Cybersecurity)</li>\n<li>Vulnerability Analyst</li>\n<li>Wireless Network Engineer</li>\n<li>Security Operations Specialist</li>\n<li>Cloud Security Specialist</li>\n</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------- entry + software/hardware requirement -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 21-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<p>You can download and install the following software:</p>\n<ul>\n<li><span style="text-decoration: underline;"><a href="https://nmap.org/download" target="_blank">Nmap</a></span></li>\n<li><span style="text-decoration: underline;"><a href="https://www.wireshark.org/download.html" target="_blank">Wireshark</a></span> (with tshark)</li>\n<li><span style="text-decoration: underline;"><a href="https://www.python.org/downloads/" target="_blank">Python 3</a></span> with pandas and scikit-learn</li>\n<li>A generative AI assistant (Claude, ChatGPT or Copilot &mdash; the free tier is sufficient)</li>\n<li>A spreadsheet (Excel, Numbers or Google Sheets)</li>\n</ul>\n<p><strong>Hardware:</strong> Windows or Mac laptop with administrator rights to install software</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_mkey, @a_who, @a_prereq) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C356 - Funding and Grant', 'course_C356_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C356_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C356_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C356_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-for-network-security.html" title="WSQ - AI for Network Security">WSQ - AI for Network Security</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C356_funding_and_grant';
