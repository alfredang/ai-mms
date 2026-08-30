-- 1246: Convert C143 "AI Vibe Coding with R" into "Develop Child Creativity
-- with Generative AI", and move it from the AI Vibe Coding Series to
-- AI for STEM.
--
-- SKU stays C143. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, new meta, plus a written-from-scratch
-- "What's This Course About" (three paragraphs) and "What You'll Learn"
-- (four topics) — no donor course was named.
--
-- It becomes AI for STEM's second course, after "AI for Early Childhood",
-- which it pairs with naturally (both are about children and AI).
--
-- It also leaves the Data Management / R trees, which no longer describe the
-- course. It keeps All Courses (3), Infocomm Technology (55) and AI Courses
-- (252).
--
-- C143 ALREADY has a funding block (checked before writing this — see
-- feedback_conversion_drops_legacy_funding_fallback for why that check
-- matters when rewriting short_description), so it is repointed at
-- WSQ - Generative AI for Content Creation rather than created.
--
-- Course is 7.5h / 1 day; the copy reflects that. Topic HTML uses the
-- LSN_DATA + <h3 class="course-topic-h3"> shape the product page expects.
-- The 301 uses a slug-derived id_path so a future rename cannot collide.
--
-- SG-guarded; C-prefix SKU and these url_keys are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pmetad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_pdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_psdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @e143 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C143' LIMIT 1);

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);
SET @stem := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-stem' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e143, 'Develop Child Creativity with Generative AI'
FROM dual WHERE @e143 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e143 AND attribute_id = @a_pname AND store_id <> 0
  AND @e143 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e143, 'develop-child-creativity-with-generative-ai'
FROM dual WHERE @e143 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e143 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e143 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e143, 'Develop Child Creativity with Generative AI | Tertiary Courses Singapore'
FROM dual WHERE @e143 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e143, 'Use generative AI to grow children''s creativity - storytelling, art and music projects, age-appropriate tools, safe supervised use and creative confidence.'
FROM dual WHERE @e143 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e143, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C143-20260830-130330.png'
FROM dual WHERE @e143 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) "What's This Course About" — three paragraphs.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e143,
'<p>The worry about children and generative AI is a fair one: if a tool can produce the story, the drawing or the song in seconds, what is left for the child to do? Used badly, AI hands over the thinking. Used well, it does the opposite &mdash; it lets a seven-year-old hear the melody they hummed, see the creature they described, and iterate on an idea a dozen times in the space of one afternoon. The difference is entirely in how the adult sets up the activity.</p><p>In this hands-on 1-day course, you will learn to design creative projects where generative AI amplifies a child''s imagination instead of replacing it. You will work through practical activities across storytelling, visual art and music &mdash; choosing age-appropriate tools, framing prompts so the child supplies the ideas, and building in the moments where they critique, revise and decide. You will also cover the parts that matter to parents and schools: safe supervised use, privacy, screen-time balance, and honest conversations about what AI made versus what the child made.</p><p>You will leave with a set of ready-to-run creative activities, a toolkit of child-safe AI tools, and a clear framework for keeping the child in the driver''s seat. Ideal for parents, preschool and primary educators, enrichment teachers and anyone designing creative programmes for young learners.</p>'
FROM dual WHERE @e143 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3) "What You'll Learn" — four topics.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e143,
'<!-- LSN_DATA: [{"title":"Topic 1 Generative AI and Childhood Creativity","subsecs":[{"title":"What generative AI can and cannot do for young learners","links":[]},{"title":"Amplifying imagination vs replacing the thinking","links":[]},{"title":"Age-appropriate tools and what to avoid","links":[]},{"title":"Setting up a safe, supervised creative space","links":[]}]},{"title":"Topic 2 Storytelling and Writing Projects","subsecs":[{"title":"Co-creating stories where the child drives the plot","links":[]},{"title":"Turning a child''s idea into characters and settings","links":[]},{"title":"Illustrated storybooks and comic strips","links":[]},{"title":"Prompting so the child supplies the ideas","links":[]}]},{"title":"Topic 3 Art, Music and Making","subsecs":[{"title":"From a child''s sketch or description to generated art","links":[]},{"title":"Simple music and sound creation activities","links":[]},{"title":"Animation and short video projects","links":[]},{"title":"Combining AI output with hands-on making","links":[]}]},{"title":"Topic 4 Guiding, Critiquing and Staying Safe","subsecs":[{"title":"Teaching children to critique and revise AI output","links":[]},{"title":"What the AI made vs what I made: honest conversations","links":[]},{"title":"Privacy, screen time and healthy boundaries","links":[]},{"title":"Building a term of creative activities","links":[]}]}] -->
<h3 class="course-topic-h3">Topic 1 Generative AI and Childhood Creativity</h3>
<ul>
<li>What generative AI can and cannot do for young learners</li>
<li>Amplifying imagination vs replacing the thinking</li>
<li>Age-appropriate tools and what to avoid</li>
<li>Setting up a safe, supervised creative space</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Storytelling and Writing Projects</h3>
<ul>
<li>Co-creating stories where the child drives the plot</li>
<li>Turning a child''s idea into characters and settings</li>
<li>Illustrated storybooks and comic strips</li>
<li>Prompting so the child supplies the ideas</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Art, Music and Making</h3>
<ul>
<li>From a child''s sketch or description to generated art</li>
<li>Simple music and sound creation activities</li>
<li>Animation and short video projects</li>
<li>Combining AI output with hands-on making</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Guiding, Critiquing and Staying Safe</h3>
<ul>
<li>Teaching children to critique and revise AI output</li>
<li>What the AI made vs what I made: honest conversations</li>
<li>Privacy, screen time and healthy boundaries</li>
<li>Building a term of creative activities</li>
</ul>'
FROM dual WHERE @e143 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e143 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e143 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) 301 the old slug, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'advanced-r-data-analysis-training.html'
  AND store_id = 1
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/advanced-r-data-analysis-training-301',
       'advanced-r-data-analysis-training.html', 'develop-child-creativity-with-generative-ai.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e143) AND store_id = 1
  AND request_path <> 'develop-child-creativity-with-generative-ai.html'
  AND @e143 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e143), 'develop-child-creativity-with-generative-ai.html',
       CONCAT('catalog/product/view/id/', @e143), 1, @e143
FROM dual WHERE @e143 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Leave the AI Vibe Coding Series and the Data Management / R trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e143
  AND cp.category_id IN (@vibe, 99, 106)
  AND @e143 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e143
  AND i.category_id IN (@vibe, 99, 106)
  AND @e143 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 6) Join AI for STEM, after "AI for Early Childhood".
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @stem, p.entity_id, 102
FROM catalog_product_entity p
WHERE @stem IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C143';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @stem, p.entity_id, 102, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @stem IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C143'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku WHEN 'C831' THEN 101 WHEN 'C143' THEN 102 END
WHERE cp.category_id = @stem
  AND p.sku IN ('C831', 'C143');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku WHEN 'C831' THEN 101 WHEN 'C143' THEN 102 END
WHERE i.category_id = @stem
  AND p.sku IN ('C831', 'C143');

-- ---------------------------------------------------------------------------
-- 7) Repoint the existing funding card at a subject-relevant WSQ course.
-- ---------------------------------------------------------------------------

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-content-creation.html" title="WSQ - Generative AI for Content Creation">WSQ - Generative AI for Content Creation</a></span></p>',
    is_active = 1
WHERE identifier = 'course_C143_funding_and_grant'
  AND @is_sg > 0;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
FROM (SELECT * FROM cms_block) b
WHERE b.identifier = 'course_C143_funding_and_grant'
  AND @is_sg > 0;
