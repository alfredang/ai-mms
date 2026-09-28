-- Align the public TGS-2024044051 page with the verified v3 Copilot courseware.
-- Preserve identity, accredited outcomes, fees, funding, and existing brochure link.
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024044051' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

UPDATE catalog_product_entity_varchar v
 JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
 SET v.value = 'Lead AI transformation with Microsoft 365 Copilot, no-code Copilot Workflows and focused Copilot agents. Practise business tasks, human controls, adoption and measurable outcomes in a three-day WSQ course.'
 WHERE v.entity_id = @e AND @e IS NOT NULL AND a.attribute_code = 'meta_description';

UPDATE catalog_product_entity_text t
 JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = @et
 SET t.value = 'Microsoft 365 Copilot, Copilot Chat, Copilot Workflows, Copilot Agents, Agent Builder, Word, PowerPoint, Excel, Outlook, Teams, AI transformation leadership, business outcomes, WSQ Copilot course'
 WHERE t.entity_id = @e AND @e IS NOT NULL AND a.attribute_code = 'meta_keyword';

UPDATE catalog_product_entity_text t
 JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = @et
 SET t.value = CONCAT(
 '<p><strong>AI Transformation with Microsoft Copilot</strong> is a practical three-day WSQ course for executives and senior managers. Use Microsoft 365 Copilot in everyday business work, design a no-code Copilot Workflow and build a focused Copilot agent. The emphasis is better decisions, safe handoffs and measurable outcomes.</p>',
 '<p>In Copilot Chat, Word, PowerPoint, Excel, Outlook and Teams, participants turn a synthetic service case into sourced briefs, analysis, meeting actions and leadership messages. They check claims and keep a human owner for consequential decisions.</p>',
 '<p>Participants describe a repeatable service process to Copilot Workflows, map its trigger, steps, approval and exception path, then test normal and failure cases. They use Copilot Agent Builder to define a bounded purpose, instructions, approved knowledge and starter prompts, and test the agent before any sharing. Feature availability depends on the organisation’s Microsoft 365 tenant; an offline design and test path is provided.</p>',
 '<p>Leaders finish with a pilot cohort, adoption plan, quality and value scorecard, and a board-ready go, hold or stop recommendation. No coding is required. The course is informed by Microsoft AB-730 and AB-731 themes; it is not Microsoft exam preparation.</p>')
 WHERE t.entity_id = @e AND @e IS NOT NULL AND a.attribute_code = 'short_description';

UPDATE catalog_product_entity_text t
 JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = @et
 SET t.value = CONCAT(
 '<!-- LSN_DATA: [{"title":"Topic 1: Use Microsoft 365 Copilot for everyday business work","subsecs":[]},{"title":"Topic 2: Design safe Copilot Workflows and human controls","subsecs":[]},{"title":"Topic 3: Create and test bounded Copilot agents","subsecs":[]},{"title":"Topic 4: Lead adoption, measure value and scale outcomes","subsecs":[]}] -->',
 '\n<p><strong>Topic 1: Use Microsoft 365 Copilot for everyday business work</strong></p>',
 '\n<p><strong>Topic 2: Design safe Copilot Workflows and human controls</strong></p>',
 '\n<p><strong>Topic 3: Create and test bounded Copilot agents</strong></p>',
 '\n<p><strong>Topic 4: Lead adoption, measure value and scale outcomes</strong></p>\n')
 WHERE t.entity_id = @e AND @e IS NOT NULL AND a.attribute_code = 'description';
