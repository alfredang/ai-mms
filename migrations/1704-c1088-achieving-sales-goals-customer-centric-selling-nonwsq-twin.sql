-- C1088 Achieving Sales Goals with Customer-Centric Selling Techniques = the 2-day non-WSQ twin of TGS-2025052342
-- (WSQ - Closing Sales with Empathy-Driven People-Focused Selling). Courseware v1 converted from the WSQ v8 set
-- (github.com/tertiarycourses/C1088-Achieving-Sales-Goals-with-Customer-Centric-Selling-Techniques).
--
-- 1. "What's This Course About" + course topics copied verbatim from the parent (same 4 topics; the
--    parent's trailing NBSP bytes after three topic titles stripped, otherwise byte-identical). No day count,
--    no WSQ wording. Store-scope overrides of both fields removed.
-- 2. Funding block course_C1088_funding_and_grant (already linked the WSQ twin) brought to the house wording;
--    target https://www.tertiarycourses.com.sg/wsq-closing-sales-with-empathy-driven-people-focused-selling.html
--    returns 200.
-- Name / slug / duration 15 / sessions 2 / meta description are already right (meta states no day count).
-- Schedule template -> B09 is a code path (CoursesaveController::switchScheduleTemplateAction), not SQL -
-- done separately on prod.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1088' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025052342' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course empowers participants with empathy-driven and people-focused selling techniques designed to build trust, understand customer needs, and close sales effectively. Participants will explore methods to analyze customer preferences and develop tailored recommendations. Advanced upselling and cross-selling strategies will also be covered to enhance sales outcomes while addressing customer challenges through problem-solving techniques.</p>\r\n<p>The course further delves into effective follow-up processes to improve customer engagement and retention. Participants will also master objection-handling techniques, the psychology behind buyer decisions, and methods for evaluating the sales closure process with key metrics. By the end of the program, learners will be equipped to lead sales processes that are empathetic, impactful, and aligned with long-term customer relationships.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1. Foundations of Selling","subsecs":[{"title":"Selling Mindset","links":[]},{"title":"Selling Like a Human","links":[]},{"title":"You\'ve Got to Want It","links":[]},{"title":"Confidence & Focus","links":[]},{"title":"Fear Reduction","links":[]},{"title":"Sales Strategy","links":[]},{"title":"Math of Sales","links":[]},{"title":"Goal Setting","links":[]},{"title":"Understanding Buyer Psychology","links":[]},{"title":"Psychology of Influence","links":[]},{"title":"Why People Buy","links":[]},{"title":"Buyer\'s Matrix","links":[]},{"title":"Exactly What to Say","links":[]},{"title":"The Power of Words","links":[]},{"title":"Illusion of Choice Using Leads","links":[]},{"title":"Building Trust & Rapport","links":[]},{"title":"Tone","links":[]},{"title":"Champion Selling","links":[]},{"title":"Discovery Process","links":[]},{"title":"What is the Point of Discovery?","links":[]},{"title":"Bucket Questions","links":[]},{"title":"Why Why Why","links":[]},{"title":"Gap Questions","links":[]},{"title":"Permission-Based Selling","links":[]}]},{"title":"Topic 2. Selling Techniques & Problem-Solving","subsecs":[{"title":"Sales Methods","links":[]},{"title":"Problem-Based Selling","links":[]},{"title":"What Would Your Customer Say (WWYCS)?","links":[]},{"title":"Upselling and Cross Selling tecniques","links":[]},{"title":"Sales Tactics","links":[]},{"title":"How to Run a Great Demo","links":[]},{"title":"Educate (\\"The What\\")","links":[]},{"title":"Demonstrate (\\"The How\\")","links":[]},{"title":"Buy-In (\\"The Why\\")","links":[]},{"title":"Mini Close","links":[]},{"title":"Champion Selling","links":[]}]},{"title":"Topic 3. Closing the Sale","subsecs":[{"title":"Closing Techniques","links":[]},{"title":"What is a Close?","links":[]},{"title":"Do They Want It?","links":[]},{"title":"Justify the Price","links":[]},{"title":"Discounting","links":[]},{"title":"Mini Close","links":[]},{"title":"Make it Easy for Them to Buy","links":[]},{"title":"Proper Follow Up","links":[]},{"title":"Common ChallengesCommon Flubs & Flaws","links":[]},{"title":"Common Flubs & Flaws","links":[]},{"title":"Champion Selling","links":[]}]},{"title":"Topic 4. Handling Objections & Rejections","subsecs":[{"title":"Objection vs. Deflection vs. Rejection","links":[]},{"title":"Sales objection Handling techniques","links":[]},{"title":"Answer & Ask","links":[]},{"title":"Using Testimonials for Objections","links":[]},{"title":"Metrics of Sales Closure Process ","links":[]}]}] -->\r\n<p><strong>Topic 1. Foundations of Selling</strong></p>\r\n<p><em>Selling Mindset</em></p>\r\n<p><em>Selling Like a Human</em></p>\r\n<p><em>You\'ve Got to Want It</em></p>\r\n<p><em>Confidence &amp; Focus</em></p>\r\n<p><em>Fear Reduction</em></p>\r\n<p><em>Sales Strategy</em></p>\r\n<p><em>Math of Sales</em></p>\r\n<p><em>Goal Setting</em></p>\r\n<p><em>Understanding Buyer Psychology</em></p>\r\n<p><em>Psychology of Influence</em></p>\r\n<p><em>Why People Buy</em></p>\r\n<p><em>Buyer\'s Matrix</em></p>\r\n<p><em>Exactly What to Say</em></p>\r\n<p><em>The Power of Words</em></p>\r\n<p><em>Illusion of Choice Using Leads</em></p>\r\n<p><em>Building Trust &amp; Rapport</em></p>\r\n<p><em>Tone</em></p>\r\n<p><em>Champion Selling</em></p>\r\n<p><em>Discovery Process</em></p>\r\n<p><em>What is the Point of Discovery?</em></p>\r\n<p><em>Bucket Questions</em></p>\r\n<p><em>Why Why Why</em></p>\r\n<p><em>Gap Questions</em></p>\r\n<p><em>Permission-Based Selling</em></p>\r\n<p><strong>Topic 2. Selling Techniques &amp; Problem-Solving</strong></p>\r\n<p><em>Sales Methods</em></p>\r\n<p><em>Problem-Based Selling</em></p>\r\n<p><em>What Would Your Customer Say (WWYCS)?</em></p>\r\n<p><em>Upselling and Cross Selling tecniques</em></p>\r\n<p><em>Sales Tactics</em></p>\r\n<p><em>How to Run a Great Demo</em></p>\r\n<p><em>Educate (&quot;The What&quot;)</em></p>\r\n<p><em>Demonstrate (&quot;The How&quot;)</em></p>\r\n<p><em>Buy-In (&quot;The Why&quot;)</em></p>\r\n<p><em>Mini Close</em></p>\r\n<p><em>Champion Selling</em></p>\r\n<p><strong>Topic 3. Closing the Sale</strong></p>\r\n<p><em>Closing Techniques</em></p>\r\n<p><em>What is a Close?</em></p>\r\n<p><em>Do They Want It?</em></p>\r\n<p><em>Justify the Price</em></p>\r\n<p><em>Discounting</em></p>\r\n<p><em>Mini Close</em></p>\r\n<p><em>Make it Easy for Them to Buy</em></p>\r\n<p><em>Proper Follow Up</em></p>\r\n<p><em>Common ChallengesCommon Flubs &amp; Flaws</em></p>\r\n<p><em>Common Flubs &amp; Flaws</em></p>\r\n<p><em>Champion Selling</em></p>\r\n<p><strong>Topic 4. Handling Objections &amp; Rejections</strong></p>\r\n<p><em>Objection vs. Deflection vs. Rejection</em></p>\r\n<p><em>Sales objection Handling techniques</em></p>\r\n<p><em>Answer &amp; Ask</em></p>\r\n<p><em>Using Testimonials for Objections</em></p>\r\n<p><em>Metrics of Sales Closure Process </em></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C1088 - Funding and Grant', 'course_C1088_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C1088_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C1088_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C1088_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2> <p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-closing-sales-with-empathy-driven-people-focused-selling.html" title="WSQ - Closing Sales with Empathy-Driven People-Focused Selling">WSQ - Closing Sales with Empathy-Driven People-Focused Selling</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C1088_funding_and_grant';
