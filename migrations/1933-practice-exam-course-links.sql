-- Practice Exams (MMD_PracticeExam): one row links a course to its practice exam on
-- exams.tertiaryinfotech.com. Edit Course -> Lesson Details -> Course Settings writes it;
-- the class page shows the Practice Exam section only for linked courses.
CREATE TABLE IF NOT EXISTS mmd_course_practice_exam (
    product_id INT UNSIGNED NOT NULL,
    exam_code  VARCHAR(64)  NOT NULL COMMENT 'display code, e.g. CCAR-F',
    exam_slug  VARCHAR(128) NOT NULL COMMENT 'exams site slug, sent to its API',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- SG only: switch the practice exam on for the Certification Exam Prep courses (category 182)
-- that have a matching exam on Tertiary Exams (catalogue read 2026-11-15). Courses with no
-- matching exam stay off. INSERT IGNORE: a link already set or changed in the admin is kept.
SET @ok := ((SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

DROP TEMPORARY TABLE IF EXISTS tmp_pe_map;
CREATE TEMPORARY TABLE tmp_pe_map (sku VARCHAR(64) NOT NULL PRIMARY KEY, exam_code VARCHAR(64) NOT NULL, exam_slug VARCHAR(128) NOT NULL) DEFAULT CHARSET=utf8;
INSERT INTO tmp_pe_map (sku, exam_code, exam_slug) VALUES
('TGS-2026061312','CCAR-F','anthropic-cca-foundations'),
('C437','CCAR-F','anthropic-cca-foundations'),
('C740','CCAR-P','anthropic-ccar-professional'),
('C991','CCAO-F','anthropic-ccao-foundations'),
('C1098','CCDV-F','anthropic-ccdv-foundations'),
('TGS-2024048318','SK0-005','comptia-server-plus'),
('C1048','SK0-005','comptia-server-plus'),
('TGS-2024049214','CV0-004','comptia-cloud-plus'),
('C855','CV0-004','comptia-cloud-plus'),
('TGS-2025054472','N10-009','comptia-network-plus'),
('TGS-2023040479','N10-009','comptia-network-plus'),
('C938','N10-009','comptia-network-plus'),
('TGS-2024048317','A-PLUS','comptia-a-plus'),
('C471','A-PLUS','comptia-a-plus'),
('TGS-2024048316','XK0-005','comptia-linux-plus'),
('C1162','XK0-005','comptia-linux-plus'),
('TGS-2024049212','DA0-001','comptia-data-plus'),
('C923','DA0-001','comptia-data-plus'),
('TGS-2024049211','CS0-004','comptia-cysa-plus'),
('C916','CS0-004','comptia-cysa-plus'),
('TGS-2025053927','SECURITYX','comptia-securityx'),
('C718','SECURITYX','comptia-securityx'),
('TGS-2026064471','PT0-003','comptia-pentest-plus'),
('C1136','PT0-003','comptia-pentest-plus'),
('TGS-2023039181','SY0-701','comptia-security-plus'),
('C628','SY0-701','comptia-security-plus'),
('C790','PROJECT-PLUS','comptia-project-plus'),
('TGS-2025053209','DEA-C01','aws-dea-c01'),
('TGS-2025053926','SAP-C02','aws-sap-c02'),
('C14','SAP-C02','aws-sap-c02'),
('TGS-2023039183','CLF-C02','aws-clf-c02'),
('C1041','CLF-C02','aws-clf-c02'),
('TGS-2024051413','SOA-C03','aws-soa-c03'),
('C1392','SOA-C03','aws-soa-c03'),
('TGS-2024049340','MLA-C01','aws-mla-c01'),
('C1330','MLA-C01','aws-mla-c01'),
('TGS-2025054815','DOP-C02','aws-dop-c02'),
('C503','DOP-C02','aws-dop-c02'),
('C19','AIF-C01','aws-aif-c01'),
('C1393','DVA-C02','aws-dva-c02'),
('C1407','SAA-C03','aws-saa-c03'),
('TGS-2025053212','CKAD','linuxfoundation-ckad'),
('C810','CKAD','linuxfoundation-ckad'),
('TGS-2025054612','CKA','linuxfoundation-cka'),
('C1394','CKA','linuxfoundation-cka'),
('C1799','CKS','linuxfoundation-cks'),
('TGS-2023039343','KCNA','linuxfoundation-kcna'),
('C426','KCNA','linuxfoundation-kcna'),
('TGS-2023037854','200-301','cisco-ccna'),
('C975','200-301','cisco-ccna'),
('TGS-2024044052','350-401','cisco-ccnp-encor'),
('C1287','350-401','cisco-ccnp-encor'),
('TGS-2024043392','CISSP','isc2-cissp'),
('C483','CISSP','isc2-cissp'),
('TGS-2024045797','PMP','pmi-pmp'),
('TGS-2024049350','ITIL4-FOUNDATION','axelos-itil-4'),
('C348','ITIL4-FOUNDATION','axelos-itil-4'),
('TGS-2025055775','LEAN-SIX-SIGMA-GREEN-BELT','iassc-lean-six-sigma-green'),
('C481','LEAN-SIX-SIGMA-GREEN-BELT','iassc-lean-six-sigma-green'),
('TGS-2025053207','FOUNDATIONS','github-foundations'),
('C385','FOUNDATIONS','github-foundations'),
('TGS-2023041024','ACE','google-ace'),
('TGS-2023040476','PROFESSIONAL-ML-ENGINEER','google-professional-ml-engineer'),
('C504','PROFESSIONAL-CLOUD-DEVOPS-ENGINEER','google-professional-cloud-devops-engineer'),
('C151','PROFESSIONAL-CLOUD-NETWORK-ENGINEER','google-professional-cloud-network-engineer'),
('C511','PROFESSIONAL-DATA-ENGINEER','google-professional-data-engineer'),
('TGS-2024042603','MD-102','microsoft-md-102'),
('TGS-2023036641','DP-900','microsoft-dp-900'),
('C1415','DP-900','microsoft-dp-900'),
('TGS-2023039923','PL-900','microsoft-pl-900'),
('C1358','PL-900','microsoft-pl-900'),
('TGS-2023037468','PL-300','microsoft-pl-300'),
('C1433','PL-300','microsoft-pl-300'),
('TGS-2023039182','AZ-104','microsoft-az-104'),
('C756','AZ-104','microsoft-az-104'),
('TGS-2024047021','SC-300','microsoft-sc-300'),
('C591','SC-300','microsoft-sc-300'),
('TGS-2024048319','DP-300','microsoft-dp-300'),
('C1389','DP-300','microsoft-dp-300'),
('C799','AZ-204','microsoft-az-204'),
('C1406','AZ-305','microsoft-az-305'),
('C1751','DP-600','microsoft-dp-600'),
('C251','MS-102','microsoft-ms-102'),
('C432','MS-102','microsoft-ms-102'),
('C1190','PL-600','microsoft-pl-600'),
('C1436','SC-100','microsoft-sc-100'),
('C542','SC-200','microsoft-sc-200'),
('C472','SC-900','microsoft-sc-900'),
('C919','TDA-C01','tableau-tcda');

INSERT IGNORE INTO mmd_course_practice_exam (product_id, exam_code, exam_slug)
SELECT p.entity_id, m.exam_code, m.exam_slug
  FROM tmp_pe_map m
  JOIN catalog_product_entity p ON p.sku = m.sku COLLATE utf8_general_ci
 WHERE @ok;

DROP TEMPORARY TABLE IF EXISTS tmp_pe_map;
