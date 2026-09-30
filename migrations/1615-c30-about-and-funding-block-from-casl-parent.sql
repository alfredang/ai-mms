-- C30 "Smart Phone Photography Masterclass" is the non-WSQ twin of
-- TGS-2026064718 "CASL - Master Mobile Photography: Capturing Professional
-- Photos with Your Smartphone" (courseware duplicated from that course).
--
-- 1) short_description ("What's This Course About") copied from the parent,
--    minus its "WSQ-accredited course" wording. Guarded: nothing is written if
--    the parent row is missing or the result would still mention WSQ or a day
--    count. The course topics (description) already match the parent's four
--    topics and are left alone (the parent's copy adds an Assessment section).
-- 2) Funding block repointed from a retired slug at the funded CASL twin.
--
-- SG-only (C-prefix course + SG-only parent). Idempotent.

SET @sg     := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid    := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C30');
SET @parent := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064718');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'short_description');

SET @new_sd := (SELECT REPLACE(value, 'WSQ-accredited course', 'hands-on masterclass')
                FROM catalog_product_entity_text
                WHERE entity_id = @parent AND attribute_id = @a_sd AND store_id = 0);

UPDATE catalog_product_entity_text
SET value = @new_sd
WHERE @sg = 1 AND @pid IS NOT NULL AND @new_sd IS NOT NULL
  AND @new_sd NOT LIKE '%WSQ%'
  AND @new_sd NOT LIKE '%2-day%' AND @new_sd NOT LIKE '%two-day%'
  AND @new_sd NOT LIKE '%16 hours%'
  AND entity_id = @pid AND attribute_id = @a_sd AND store_id = 0;

UPDATE cms_block
SET content = '<p>No funding is available for this course.</p> <p>For CASL funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-master-mobile-photography-capturing-professional-photos-with-your-smartphone.html" title="CASL - Master Mobile Photography: Capturing Professional Photos with Your Smartphone">CASL - Master Mobile Photography: Capturing Professional Photos with Your Smartphone</a></span></p>'
WHERE @sg = 1 AND identifier = 'course_C30_funding_and_grant';
