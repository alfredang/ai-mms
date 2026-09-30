-- C141: remove the orphan meta_description row in catalog_product_entity_text.
--
-- meta_description is a VARCHAR attribute, but migration 1212 wrote C141's old
-- "Claude Code ... all driven from the terminal." copy into the TEXT table. The storefront
-- renders that orphan, shadowing the real varchar value set by 1425/1613, so the page
-- still described the old Claude Code course.
--
-- Guarded on backend_type = 'varchar' so it only removes a row that can never be the
-- attribute's real value. Idempotent: a re-run deletes nothing.

DELETE t
  FROM catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C141'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = 4
                      AND a.attribute_code = 'meta_description' AND a.backend_type = 'varchar';
