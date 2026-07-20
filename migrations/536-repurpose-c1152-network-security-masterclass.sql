-- Repurpose course C1152 (entity_id 1152) from "Network Security Essential
-- Training" to "Network Security Masterclass". Redesigned as a 2-day course
-- (duration 15h) with 4 topics (2 per day). Price ($700) is set in the
-- companion migration 537. NOT part of the AI Vibe Coding series: no series
-- badge, no AI-assistant copy.
--
-- The funding block (cms_block course_C1152_funding_and_grant) already points
-- to the matching "WSQ Network Securities for Beginners" course and is left
-- unchanged.
--
-- Scope: store_id 0 (single SG store). url_key intentionally unchanged
-- (network-security-essential-training) so the existing URL keeps resolving —
-- no url_path drop / rewrite reindex churn, no 301 needed. Clears per-store
-- overrides of the rewritten attributes so partner store scopes can't shadow
-- store 0. Guarded with @e IS NOT NULL so it is a no-op on sites without C1152.
-- Idempotent (INSERT ... ON DUPLICATE KEY UPDATE). No content line ends in a
-- semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1152');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

-- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Network Security Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview (2 paragraphs)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Take your network defence skills to the next level with the Network Security Masterclass, an intensive 2-day programme covering the full lifecycle of securing modern networks. You will learn to analyse threats and map vulnerabilities across network infrastructure and Virtual Private Networks (VPNs), then apply practical hardening techniques to close the gaps you find. The course blends foundational concepts with hands-on practice so you can identify weak links and build resilient, defensible network architectures.</p>
<p>Beyond hardening, the masterclass shows you how to validate your defences through security testing and benchmarking, debug and troubleshoot security issues, and review logs for effective incident detection and response. By the end of the two days you will be able to assess a network''s security posture, remediate weaknesses, measure the impact of your controls, and respond confidently when incidents occur.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (4 topics, 2 per day)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Network Threats and Vulnerability Analysis</h3>
<ul>
<li>Network Security Fundamentals and the Threat Landscape</li>
<li>Common Attack Vectors and Reconnaissance Techniques</li>
<li>Identifying Vulnerabilities and Weak Links in Network Infrastructure</li>
<li>Assessing Virtual Private Network (VPN) Security</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Network Hardening and Access Control</h3>
<ul>
<li>Firewall, Router and Switch Hardening</li>
<li>Secure Network Segmentation and Access Control</li>
<li>Securing VPNs and Remote Access</li>
<li>Encryption and Secure Protocols in Practice</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Security Testing and Benchmarking</h3>
<ul>
<li>Vulnerability Scanning and Penetration Testing Basics</li>
<li>Measuring and Benchmarking Security Performance</li>
<li>Debugging and Troubleshooting Security Issues</li>
<li>Validating and Remediating Identified Weaknesses</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Monitoring, Logging and Incident Response</h3>
<ul>
<li>Log Collection and Review for Security Events</li>
<li>Detecting Intrusions and Anomalies</li>
<li>Incident Detection, Response and Management</li>
<li>Building an Ongoing Network Security Posture</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Network Security Masterclass | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master network security in this hands-on 2-day masterclass — analyse threats and VPN vulnerabilities, harden network infrastructure, run security testing and benchmarking, and review logs for incident response at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Network Security Masterclass, Network Security Course, Network Security Training, Threat Analysis, Vulnerability Assessment, VPN Security, Network Hardening, Penetration Testing, Log Review, Incident Response, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- duration (2 days = 15h)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '15' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (new branded cover already uploaded to R2)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1152-20260717-184310.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- image labels (EAV)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Network Security Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Network Security Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Network Security Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Product-page zoom gallery renders the per-image gallery label, not the EAV labels
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Network Security Masterclass'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- Clear per-store overrides so partner scopes can't shadow store 0
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_dur, @a_img, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0
  AND attribute_id IN (@a_short, @a_desc, @a_mk);
