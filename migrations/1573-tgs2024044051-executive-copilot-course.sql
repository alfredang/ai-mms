-- Align the public TGS-2024044051 page with the verified v2 executive courseware.
-- The course identity, accredited outcomes, fees, funding and brochure file ID stay intact.
-- Safe for partner instances: the update is scoped to the exact course SKU.
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024044051' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
   SET v.value = 'Lead AI transformation with Microsoft Copilot. Set a business strategy, govern responsible use, redesign executive workflows and measure value. Practical planning for senior leaders. Up to 70% WSQ funding subsidy.'
 WHERE v.entity_id = @e AND @e IS NOT NULL AND a.attribute_code = 'meta_description';

UPDATE catalog_product_entity_text t
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = @et
   SET t.value = 'AI transformation strategy, Microsoft Copilot for executives, Microsoft 365 Copilot, Copilot Chat, Copilot in Word, Copilot in PowerPoint, Copilot in Excel, Copilot in Outlook, Copilot in Teams, AI governance, responsible AI, business outcomes, Copilot adoption, Copilot ROI, WSQ Copilot course'
 WHERE t.entity_id = @e AND @e IS NOT NULL AND a.attribute_code = 'meta_keyword';

UPDATE catalog_product_entity_text t
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = @et
   SET t.value = CONCAT(
     '<p><strong>AI Transformation with Microsoft Copilot</strong> is a practical leadership course for executives who must turn AI ambition into measurable business results. Participants use Microsoft Copilot to frame decisions, draft executive material, review evidence and coordinate action across Microsoft 365.</p>',
     '<p>Leaders build a transformation mandate around a real business problem, compare opportunities and set outcome measures. Guided activities use Copilot Chat, Word and PowerPoint to prepare decision briefs, strategy memos and board stories while checking claims against source material.</p>',
     '<p>The course covers responsible use, information boundaries, human review and clear accountability. Participants use Copilot in Teams and Outlook to improve meeting and communication decisions, then design a practical operating model, pilot and adoption plan.</p>',
     '<p>Executives use Copilot in Excel and PowerPoint to test a value case and communicate adoption, quality, risk and business impact. The final deliverable is a board-ready go, hold or stop recommendation with named owners, evidence and a 90-day roadmap.</p>')
 WHERE t.entity_id = @e AND @e IS NOT NULL AND a.attribute_code = 'short_description';

UPDATE catalog_product_entity_text t
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = @et
   SET t.value = CONCAT(
     '<!-- LSN_DATA: [{"title":"Topic 1: Set the Copilot Transformation Strategy and Lead by Example","subsecs":[]},{"title":"Topic 2: Govern Copilot Use and Protect Business Decisions","subsecs":[]},{"title":"Topic 3: Integrate Copilot into the Executive Operating Model","subsecs":[]},{"title":"Topic 4: Measure Value, Scale Adoption and Report to the Board","subsecs":[]}] -->',
     '\n<p><strong>Topic 1: Set the Copilot Transformation Strategy and Lead by Example</strong></p>',
     '\n<p><strong>Topic 2: Govern Copilot Use and Protect Business Decisions</strong></p>',
     '\n<p><strong>Topic 3: Integrate Copilot into the Executive Operating Model</strong></p>',
     '\n<p><strong>Topic 4: Measure Value, Scale Adoption and Report to the Board</strong></p>\n')
 WHERE t.entity_id = @e AND @e IS NOT NULL AND a.attribute_code = 'description';
