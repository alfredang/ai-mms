-- 948: Follow-up to 946 (TGS-2019504744 -> "WSQ - AI Vibe Coding for Deep Learning").
--
-- The post-apply verification sweep of 946 caught two surfaces that its own
-- statements did not reach. Both are recorded here rather than by editing 946,
-- because an already-applied migration never re-runs on prod
-- (feedback_edited_shared_migrations_never_rerun_on_prod).
--
--   1. meta_keyword had a STORE-1 override row. 946 scoped its UPDATE to
--      store_id = 0, so the store-1 value still read "Deep Learning, Tensorflow
--      Keras, ... Basic Deep Learning" and that is the row the SG storefront
--      actually renders. (meta_title / meta_description had store-1 rows too,
--      but those UPDATEs were NOT store-scoped, so they were already correct —
--      the inconsistency in 946 is exactly what let this one through.)
--
--   2. The old-slug 301 from 946 never inserted. core_url_rewrite's unique key
--      is (request_path, store_id), and an is_system = 1 row already occupied
--      'wsq-building-your-first-machine-learning-model-with-python-and-tensorflow.html'
--      at store 1 => the INSERT IGNORE silently no-opped. 946 only cleared
--      is_system = 0 squatters (per migration 647's lesson), which does not
--      cover a SYSTEM row. The fix follows the shape the URL indexer itself
--      produces for a renamed product (verified against the live rewrite for
--      the TGS-2026064472 rename): convert the row IN PLACE at
--      id_path 'product/<entity_id>' into an RP redirect, rather than deleting
--      it and racing the indexer to re-create it.
--
-- Partner-safe: @e IS NULL on MY/GH => every statement no-ops there.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2019504744' LIMIT 1);

SET @a_mkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');

-- ------------------------------------- 1. meta_keyword at EVERY scope
-- Drop the store scoping so any per-store override is brought in line with
-- store 0 (and so a re-run stays convergent).
UPDATE catalog_product_entity_text
   SET value = 'AI vibe coding course Singapore, deep learning course Singapore, WSQ deep learning training, neural network course, CNN image classification course, transfer learning training, AI coding assistant course, Python deep learning course, WSQ AI certification'
 WHERE entity_id = @e AND attribute_id = @a_mkey;

-- --------------------------------------------- 2. old-slug 301 redirect
-- Convert the stale system row at this product's own id_path into the RP
-- redirect. Guarded on the OLD request_path so a re-run (by which time the
-- indexer has regenerated 'product/<id>' at the NEW path) matches nothing and
-- leaves the live rewrite alone.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-vibe-coding-for-deep-learning.html',
       is_system   = 0,
       options     = 'RP',
       description = '946/948 rename: Building Your First ML Model -> AI Vibe Coding for Deep Learning'
 WHERE @e IS NOT NULL
   AND id_path      = CONCAT('product/', @e)
   AND request_path = 'wsq-building-your-first-machine-learning-model-with-python-and-tensorflow.html';

-- Same treatment for the ~15 category-scoped system rows still sitting on the
-- old slug. The indexer auto-301s these on reindex, but converting them here
-- means the old category URLs redirect correctly even before the next reindex.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-vibe-coding-for-deep-learning.html',
       is_system   = 0,
       options     = 'RP',
       description = '946/948 rename: category path -> AI Vibe Coding for Deep Learning'
 WHERE @e IS NOT NULL
   AND is_system = 1
   AND id_path LIKE CONCAT('product/', @e, '/%')
   AND request_path LIKE '%/wsq-building-your-first-machine-learning-model-with-python-and-tensorflow.html';
