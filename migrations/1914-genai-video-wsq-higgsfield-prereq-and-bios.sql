-- 1914: finish the Higgsfield switch on the WSQ GenAI video page (owner request 2026-11-09; follows 1913).
--
--   After 1913 the rendered WSQ TGS-2024043855 page still named the retired tool stack in two fields:
--     * prerequisite (value_id 94345): the Software list asked for "A free VEED account";
--     * trainerprofile (value_id 94348): four per-course trainer bios described the course as using
--       "Sora, Runway and VEED / Veed.io".
--   Courseware v11 runs the whole pipeline in Higgsfield (Supercomputer agent + Cinema Studio), so only those
--   phrases are replaced; every other word of the prerequisite and of each bio is untouched.
--
--   PROBED on SG prod 2026-11-09 (both rows store 0 only). Peer-safe: each UPDATE runs only while the row's
--   MD5 still equals the probed value, so a later manual edit is never overwritten. SG-only -> no-op on MY/GH.
--   Idempotent (after the first run the MD5 no longer matches).

SET NAMES utf8mb4;
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @w0 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024043855' LIMIT 1);
SET @w  := IF(@sg = 1, @w0, NULL);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://www.veed.io/" target="_blank">A free VEED account</a></li>',
       '<li>A <a href="https://higgsfield.ai" target="_blank">Higgsfield</a> account on a paid plan: every lab runs on higgsfield.ai (sign-up is covered on Day 1)</li>')
 WHERE value_id = 94345 AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL
   AND MD5(value) = '4dac1882ebf9c3b4bcac116640426114';

UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(REPLACE(REPLACE(value,
       'generate new video with AI-powered platforms such as Sora, Runway and VEED',
       'generate new video in Higgsfield with its Supercomputer agent and Cinema Studio'),
       'generating new videos from scratch using AI-powered platforms such as Sora, Runway and Veed.io',
       'generating new videos from scratch in Higgsfield, with its Supercomputer agent and Cinema Studio'),
       'with generative AI tools such as Sora, Runway and Veed.io',
       'with generative AI in Higgsfield, using its Supercomputer agent and Cinema Studio'),
       'generate new video from scratch on AI-powered platforms such as Sora, Runway and Veed.io',
       'generate new video from scratch in Higgsfield''s Supercomputer and Cinema Studio')
 WHERE value_id = 94348 AND entity_id = @w AND store_id = 0 AND @w IS NOT NULL
   AND MD5(value) = '63b74adbe2ab9aec3eb2e2dcd4384f19';
