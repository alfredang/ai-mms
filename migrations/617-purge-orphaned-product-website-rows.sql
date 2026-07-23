-- 617: Purge catalog_product_website rows pointing at websites that no longer exist.
--
-- Why: the SG install was collapsed to a single store (franchise model, one store
-- per site), but deleting core_website rows does not cascade. 1,586 orphaned rows
-- (793 ex-MY + 793 ex-GH) survived, so the Edit Course dashboard card rendered
-- "MY" / "GH" store badges on a site that has exactly one store.
--
-- Partner-safe: scoped by "website_id not present in core_website" rather than by
-- hardcoded id. On the MY server website 2 IS real and on GH website 3 IS real, so
-- this deletes nothing there. Never hardcode website ids here -- see memory
-- feedback_sku_migrations_hit_partners_irreversibly.
--
-- Idempotent: re-running matches zero rows once the orphans are gone.

DELETE pw FROM catalog_product_website pw
LEFT JOIN core_website w ON w.website_id = pw.website_id
WHERE w.website_id IS NULL;
