-- Storefront "Session" layered-nav filter (progromming_language): show "1 day",
-- "2 days" ... instead of bare "1", "2". Store-level option labels only — the
-- admin (store 0) values stay numeric. Partner-safe: keyed on attribute_code +
-- numeric admin value, applied to every non-admin store on this site.

DELETE v FROM eav_attribute_option_value v
JOIN eav_attribute_option o ON o.option_id = v.option_id
JOIN eav_attribute a ON a.attribute_id = o.attribute_id
JOIN eav_attribute_option_value v0 ON v0.option_id = o.option_id AND v0.store_id = 0
WHERE a.attribute_code = 'progromming_language'
  AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
  AND TRIM(v0.value) REGEXP '^[0-9]+$'
  AND v.store_id > 0;

INSERT INTO eav_attribute_option_value (option_id, store_id, value)
SELECT o.option_id, s.store_id,
       CONCAT(TRIM(v0.value), IF(TRIM(v0.value) = '1', ' day', ' days'))
FROM eav_attribute_option o
JOIN eav_attribute a ON a.attribute_id = o.attribute_id
JOIN eav_attribute_option_value v0 ON v0.option_id = o.option_id AND v0.store_id = 0
JOIN core_store s ON s.store_id > 0
WHERE a.attribute_code = 'progromming_language'
  AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
  AND TRIM(v0.value) REGEXP '^[0-9]+$';
