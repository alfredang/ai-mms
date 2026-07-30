-- 853: Follow-up to 851 — drop the redundant leading "WSQ" from
-- TGS-2024045797's meta_title.
--
-- MMD_Seotitle composes the <title> at render time and PREPENDS "WSQ funded"
-- for any SG TGS- SKU (Block/Html/Head.php::_fundingPrefix). With meta_title
-- also starting with "WSQ", the rendered tag read:
--
--   "WSQ funded WSQ Project Management Professional | Tertiary Courses Singapore"
--
-- meta_title now omits the WSQ token so the composer supplies it once:
--
--   "WSQ funded Project Management Professional | Tertiary Courses Singapore"
--
-- The storefront course NAME / H1 keeps its "WSQ - " prefix — this only affects
-- the <title> tag. The brand suffix is appended idempotently by the same block,
-- so it is left off here.
--
-- Partner-safe: guarded on @e (TGS- SKUs are SG-only); idempotent.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045797' LIMIT 1);
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'Project Management Professional' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mt;
