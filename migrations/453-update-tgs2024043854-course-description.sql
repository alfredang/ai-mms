-- Update course overview (short_description) for WSQ course TGS-2024043854
-- "Build a Human-AI Workforce with Autonomous AI Agents"
-- SG-only by construction: TGS- SKUs exist only on the SG instance, so this
-- UPDATE is a natural no-op on partner (MY/GH) databases. Idempotent: re-runs
-- set the same value.

UPDATE catalog_product_entity_text t
JOIN catalog_product_entity p ON p.entity_id = t.entity_id
JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = 4 AND a.attribute_code = 'short_description'
SET t.value = '<p>Build a Human–AI Workforce with Autonomous AI Agents equips participants with practical skills to develop, deploy, and manage autonomous AI agents that collaborate with people and other agents in a digital workforce.</p><p>Participants will begin by building LLM-powered applications with Hermes Agent. They will learn how to configure autonomous agents, connect tools and APIs, define agent skills, and design intelligent workflows for business and operational tasks.</p><p>The course then explores Retrieval-Augmented Generation (RAG) and context engineering with OpenClaw. Participants will learn to provide agents with relevant knowledge, persistent memory, user preferences, and task context. They will apply contextual retrieval and memory-driven techniques to improve the accuracy, continuity, and usefulness of agent responses.</p><p>Finally, participants will use Paperclip to manage multi-agent teams. They will learn how to define agent roles, delegate tasks, coordinate workflows, monitor progress, and facilitate effective collaboration between human users and AI agents.</p><p>By the end of the course, participants will be able to build LLM applications, develop context-aware autonomous agents, and manage multi-agent systems that support workflow automation, business operations, customer engagement, software development, and organisational digital transformation.</p>'
WHERE p.sku = 'TGS-2024043854';
