-- 221: Remove the "E-Learning" menu (category 438) and its self-paced products.
--
-- Tree: 438 E-Learning -> 439 CompTIA E-Learning, 440 Linux Foundations E-Learning,
--       441 Pearson Vue E-Learning. (The separate "eLearning" topic cat 299 under
--       Adult Courses is NOT touched.)
-- Products: CompTIA CertMaster/CertPREP, Linux Foundation, Pearson Vue self-paced
--       courses, all SKU "E<digits>" (E001..), every one exclusive to this tree.
--       Deleted by tree-membership + an E<digits> SKU guard so no WSQ/adult/IBF
--       course can ever be caught, and so it works regardless of entity-id drift.
--       Products are deleted FIRST so the membership join still resolves; the
--       category delete then cascades EAV/links/flat/url-rewrites.

DELETE p FROM catalog_product_entity p JOIN catalog_category_product cp ON cp.product_id = p.entity_id JOIN catalog_category_entity c ON c.entity_id = cp.category_id WHERE p.sku REGEXP '^E[0-9]+$' AND (c.entity_id = 438 OR c.path LIKE '1/2/438/%');
DELETE FROM catalog_category_entity WHERE entity_id = 438 OR path LIKE '1/2/438/%';
