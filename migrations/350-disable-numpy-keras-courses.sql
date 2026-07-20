-- Disable retired courses (set status = 2 / Disabled):
--   C171  - NumPy and SciPy Essential Training
--   C842  - Advanced Keras Training
--   C873  - Deep Learning for Image Classification Using Keras
--   C1228 - Build LLM and Deep Learning Applications with Keras 3
--   C425  - Solving Problems with Machine Learning
--   C188  - Python Machine Learning with Scikit-Learn Training
--   C1043 - Basic Generative Adversarial Network (GAN) Training
--   C173  - Basic Swift Programming for Beginners
--   C150  - Google Cloud Certified Professional Cloud Database Engineer Training
--   C151  - Google Cloud Certified Professional Cloud Network Engineer Training
--   C1201 - 5 Days Full Stack Specialization Course
--   C1074 - AI Vibe Coding for Mobile Apps
--   C141  - AI Vibe Coding for iOS Ecommerce App
--   C435  - AI Vibe Coding for Augmented Reality (AR)
--
-- Sets the default-scope (store_id 0) status to Disabled and flips any
-- per-store override rows to Disabled too, so the products drop off the
-- storefront on every store. Idempotent. A catalog reindex + cache flush
-- after deploy makes the change visible on the storefront.

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');

-- Default scope: ensure a store_id 0 row exists and is Disabled.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku IN ('C171', 'C842', 'C873', 'C1228', 'C425', 'C188', 'C1043', 'C173', 'C150', 'C151', 'C1201', 'C1074', 'C141', 'C435')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flip any per-store override rows to Disabled as well. Must list ALL disabled
-- SKUs (a per-store status override left at Enabled keeps the course live on
-- that store even when store_id 0 is Disabled — this bit GH store_id 3 for
-- C188/C1043).
UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr AND e.sku IN ('C171', 'C842', 'C873', 'C1228', 'C425', 'C188', 'C1043', 'C173', 'C150', 'C151', 'C1201', 'C1074', 'C141', 'C435');
