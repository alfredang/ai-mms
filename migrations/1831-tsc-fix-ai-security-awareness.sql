-- 1831: TGS-2025060472 (WSQ AI Security Awareness) — correct the Skills Framework block.
--   The block listed a second TSC (MED-ACE-2018-1.1: Data Analytics, "ICT and Media
--   Skills Framework") that is not in the course's CP. The CP
--   (course_application/1. CP_TIPL_Responsible AI v1.xlsx) maps exactly one TSC:
--   ICT-BAS-0055-1.1: Responsible AI and Generative AI Practices.
--   SG-only (TGS- course; the block does not exist on partner DBs). Idempotent.

UPDATE `cms_block`
   SET `content` = '<p>This course follows the guideline of <strong>ICT-BAS-0055-1.1: Responsible AI and Generative AI Practices</strong> under ICT Skills Framework</p>',
       `update_time` = NOW()
 WHERE @mms_instance = 'SG'
   AND `identifier` = 'course_TGS-2025060472_skills_framework';
