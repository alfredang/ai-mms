-- Retarget the course-specific parts of trainer bios to the executive v2 curriculum.
-- Professional credentials and all other courses remain untouched.
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024044051' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     'His sessions focus on Copilot implementation planning, redesigning business processes, and responsible AI use across Microsoft 365.',
     'His sessions focus on defining business outcomes, leading adoption and governing responsible Microsoft Copilot use across Microsoft 365.')
 WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     'from writing effective prompts to designing custom agents in Copilot Studio and automating workflows with Power Platform. His practical sessions cover cross-platform integration, multi-agent workflows, and verifying AI-generated output before acting on it.',
     'from framing an executive question in Copilot Chat to preparing a reviewed decision brief. His practical sessions cover Microsoft 365 workflows, stakeholder communication and verification of AI-generated output before acting on it.')
 WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     'he equips learners to apply access controls, governance, and safeguards against prompt injection and sensitive-data exposure, ensuring responsible, compliant, and trustworthy AI use in modern workplace ecosystems.',
     'he equips leaders to set information boundaries, human review and clear accountability for responsible Microsoft Copilot use in business decisions.')
 WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     'how Copilot integrates with organisational data, applications and AI agents across the Microsoft ecosystem. His training emphasizes evaluating integrations against business objectives, human oversight, and verifying AI output to ensure reliable solutions.',
     'how leaders can use Microsoft Copilot in everyday decision work across Microsoft 365. His training emphasizes evaluating business value, human oversight and verifying AI output before recommendations reach decision makers.')
 WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     'His sessions cover monitoring agent performance, interpreting telemetry, and ROI analysis to measure business value.',
     'His sessions cover measuring adoption, testing an investment case and reporting business outcomes to leadership.')
 WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;
