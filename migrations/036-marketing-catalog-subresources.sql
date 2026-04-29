-- Migration 035 stripped `admin/catalog` from the Marketing role because
-- Marketing shouldn't reach Manage Categories / Products / Attributes.
-- But Marketing's sidebar exposes four narrower catalog tools that Magento's
-- standard _isAllowed() still gates on per-controller resources:
--
--   catalog_search               → checks admin/catalog/search
--   catalog_product_review       → checks admin/catalog/reviews_ratings/...
--   urlrewrite                   → checks admin/catalog/urlrewrite
--   sitemap                      → checks admin/catalog/sitemap
--
-- Grant just those sub-resources to the Marketing group so its standard
-- ACL agrees with our predispatch allow-list and the sidebar links work.
-- The heavy catalog admin (categories, products, product_attribute) stays
-- denied because we don't grant admin/catalog itself.

SET @marketing_id := (SELECT role_id FROM admin_role WHERE role_name='Marketing' AND role_type='G' LIMIT 1);

INSERT INTO admin_rule (role_id, resource_id, role_type, privileges, permission)
SELECT @marketing_id, t.resource_id, 'G', NULL, 'allow'
FROM (
    SELECT 'admin/catalog/search'           AS resource_id UNION ALL
    SELECT 'admin/catalog/reviews_ratings'                 UNION ALL
    SELECT 'admin/catalog/urlrewrite'                      UNION ALL
    SELECT 'admin/catalog/sitemap'
) t
WHERE @marketing_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM admin_rule
      WHERE role_id = @marketing_id AND resource_id = t.resource_id
  );
