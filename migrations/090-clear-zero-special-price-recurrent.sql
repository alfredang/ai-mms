-- Recurrence cleanup for the "$0 in cart but $350 on the product page"
-- bug (e.g. Basic Raspberry Pi and Node-RED Training, C467).
--
-- Migrations 076/077 already deleted special_price=0 rows once, but a
-- one-shot DELETE can't catch rows re-created afterwards: every time an
-- affected product is re-saved in admin or re-imported, the
-- special_price=0 EAV row comes back and Magento's final-price math
-- collapses the cart line to $0 — while the product page + frozen GST
-- still show the real fee (getCatalogPrice reads the untouched `price`
-- attribute, not special_price). This re-runs the cleanup on the
-- current data.
--
-- The durable prevention is the code guard in
-- MMD_SingaporePrice_Model_Catalog_Product_Type_Price::getFinalPrice()
-- (neutralises a zero special_price for every price computation). This
-- migration is the immediate data + price-index repair so the fix
-- lands without waiting for each product to be re-saved or the reindex
-- cron.
--
-- attribute_id is resolved dynamically (don't assume 76 — 076/077
-- hard-coded it; this is robust if the EAV id differs on any DB). A
-- plain subquery, not PREPARE, so it is safe under apply.php's
-- unbuffered PDO connection. Idempotent: deleting absent rows and
-- snapping an already-correct index are both no-ops.

DELETE FROM catalog_product_entity_decimal
WHERE attribute_id = (
        SELECT attribute_id FROM eav_attribute
        WHERE attribute_code = 'special_price'
          AND entity_type_id = (
              SELECT entity_type_id FROM eav_entity_type
              WHERE entity_type_code = 'catalog_product')
      )
  AND value = 0;

-- Snap any collapsed price-index rows back to the catalog price across
-- all websites so the storefront is consistent on first paint without
-- waiting for the price-reindex cron.
UPDATE catalog_product_index_price
SET final_price = price,
    min_price   = price,
    max_price   = price
WHERE price > 0
  AND (final_price IS NULL OR final_price = 0 OR final_price < price);
