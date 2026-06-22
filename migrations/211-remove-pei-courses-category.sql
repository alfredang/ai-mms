-- 211: Remove the "PEI Courses" category tree from the storefront menu.
--
-- Tree: 169 PEI Courses  ->  148 Diploma, 317 Certifcates, 82 Advanced Certificates.
-- The courses sitting under PEI are SHARED WSQ/CompTIA courses (TGS- SKUs) that also
-- live in WSQ Courses / CompTIA / Cyber Security categories, so we delete the CATEGORY
-- nodes only and KEEP every product. FK CASCADE removes the EAV values, category-product
-- links, flat-category rows and category URL rewrites automatically.
--
-- NOTE: SG and Nigeria share root category 2, so this removes PEI from both storefronts.

DELETE FROM catalog_category_entity WHERE entity_id = 169 OR path LIKE '1/2/169/%';
