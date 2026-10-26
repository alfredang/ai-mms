-- SG course pages: remove the "Job Roles" (Who Should Attend) list on 49 non-WSQ courses whose
-- list does not match the course (e.g. C141 Claude AI for Digital Marketing listed "Apple Watch
-- Developers"). Approved by Dr Ang 24 Oct 2026 ("Remove the who should attend").
-- Empty whoshouldattend => the Job Roles tab is not rendered (tabs.phtml skips empty children).
-- C437 left out: its live list was already corrected (Solution Architect ...).
-- The GCE / WPL entry-requirement line is NOT touched.
--
-- SG-only: double guard (@mms_instance from MMS_COUNTRY_CODE AND the singapore store) -> no-op on
-- MY/GH, whose own audiences are being revised separately with their partner. Idempotent.
-- Attribute is not in the flat table; post-deploy: flush cache.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @sg := IF(@mms_instance = 'SG', @sg, 0);
SET @a  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');

DELETE t FROM catalog_product_entity_text t
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id
 WHERE @sg = 1 AND t.attribute_id = @a
   AND TRIM(e.sku) IN (
     'C012','C057','C1148','C1259','C1276','C1319','C135','C1382','C141','C1417',
     'C1440','C163','C165','C169','C1750','C1756','C1759','C1760','C1762','C1871',
     'C188','C197','C20','C201','C207','C329','C349','C427','C436','C439',
     'C476','C485','C525','C526','C529','C590','C711','C744','C752','C776',
     'C798','C814','C818','C831','C864','C903','C989','C995','C996'
   );
