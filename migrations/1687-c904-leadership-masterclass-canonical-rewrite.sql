-- Correct the C904 canonical row so Magento's product API and canonical tag use the new flat slug.
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id=1 AND code='singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku='C904' LIMIT 1);
SET @ok := (@sg=1 AND @pid IS NOT NULL);
DELETE FROM core_url_rewrite WHERE @ok AND store_id=1 AND product_id=@pid AND id_path=CONCAT('product/',@pid) AND request_path<>'leadership-masterclass.html';
UPDATE core_url_rewrite SET id_path=CONCAT('product/',@pid),is_system=1,options=NULL,category_id=NULL,target_path=CONCAT('catalog/product/view/id/',@pid) WHERE @ok AND store_id=1 AND product_id=@pid AND request_path='leadership-masterclass.html';
