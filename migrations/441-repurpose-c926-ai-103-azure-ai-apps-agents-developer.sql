-- Repurpose course C926 from "AI-102 Azure AI Engineer Training" to "AI-103
-- Microsoft Certified Azure AI Apps and Agents Developer Associate". Microsoft
-- certification exam-prep course. name, url_key, overview (short_description),
-- exam domains (description) with official skills-measured weightings, meta
-- (title/description/keyword). Price and duration unchanged. Cover regenerated
-- separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C926');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI-103 Microsoft Certified Azure AI Apps and Agents Developer Associate') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AI-103 Microsoft Certified Azure AI Apps and Agents Developer Associate course equips learners with the knowledge and skills required to build, manage and deploy AI apps and agents on Azure using Microsoft Foundry. Participants will explore planning and managing Azure AI solutions, choosing the right models and Foundry services, and implementing generative AI and agentic solutions with retrieval-augmented generation, multi-agent orchestration and responsible AI.</p>
<p>Learners will gain hands-on expertise implementing computer vision, text analysis and information extraction solutions &mdash; from image and video generation and multimodal understanding to sentiment analysis, speech, translation, and OCR-based document extraction with Azure Content Understanding. Additionally, the course covers securing, monitoring and operationalizing AI systems with observability, guardrails and CI/CD. By completing this course, participants will be prepared to develop and operate production-grade AI apps and agents on Azure.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AI-103</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Plan and manage an Azure AI solution (25-30%)</h3>
<ul>
<li>Choose appropriate models (LLMs, small and multimodal models) and Foundry services for generative tasks, grounding, vector search, agent workflows and multimodal processing</li>
<li>Choose retrieval and indexing methods and memory, tool and knowledge integration services for agents</li>
<li>Design Azure infrastructure, choose deployment options, configure model and agent deployments, and integrate Foundry projects with CI/CD pipelines</li>
<li>Manage quotas, scaling, rate limits and cost, and monitor model performance, drift, safety events and grounding quality</li>
<li>Configure security including managed identity, private networking, keyless credentials and role policies</li>
<li>Implement responsible AI: safety filters, guardrails, content moderation, evaluators, audit trace logging and agent oversight controls</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Implement generative AI and agentic solutions (30-35%)</h3>
<ul>
<li>Deploy and consume LLMs, small, code and multimodal models, and implement retrieval-augmented generation (RAG)</li>
<li>Design tool-augmented flows and multistep reasoning pipelines, and evaluate models and apps for fabrications, relevance, quality and safety</li>
<li>Integrate generative workflows using Foundry SDKs and connectors, and connect an application to a Foundry project</li>
<li>Define agent roles, goals and tool schemas, and build agents integrating retrieval, function-calling and conversation memory</li>
<li>Implement orchestrated multi-agent solutions and autonomous workflows with safeguards and approval controls</li>
<li>Optimize with prompt engineering, model parameters, reflection and self-critique loops, and set up observability with tracing, token analytics and safety signals</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Implement computer vision solutions (10-15%)</h3>
<ul>
<li>Generate images and videos from text prompts and reference media, and configure image and video editing workflows</li>
<li>Build multimodal understanding: analyze visual context, produce captions, and enable question-answering grounded in visual evidence</li>
<li>Generate accessible alt-text and image descriptions, and extract visual characteristics with Azure Content Understanding in Foundry Tools</li>
<li>Implement video analysis and identify objects, components or regions within images and video</li>
<li>Implement responsible AI for multimodal content: filter unsafe visuals, detect indirect prompt injection in images, and enforce visual policy rules</li>
</ul>
<h3 class="course-topic-h3">Domain 4 Implement text analysis solutions (10-15%)</h3>
<ul>
<li>Extract entities, topics, summaries and structured JSON using generative prompting and Foundry Tools</li>
<li>Configure detection of sentiment, tone, safety issues and sensitive content</li>
<li>Translate text using Azure Translator in Foundry Tools or LLM-powered translation flows</li>
<li>Customize language model outputs for domain tasks such as compliance summarization and domain extraction</li>
<li>Implement speech-to-text and text-to-speech, custom speech models, multimodal reasoning from audio, and speech translation</li>
</ul>
<h3 class="course-topic-h3">Domain 5 Implement information extraction solutions (10-15%)</h3>
<ul>
<li>Ingest and index documents, images, audio and video, and configure semantic, hybrid and vector search for grounding</li>
<li>Implement enrichment skills and configure RAG ingestion flow including optical character recognition (OCR)</li>
<li>Connect retrieval pipelines directly to workflows and agent tools</li>
<li>Extract information using multimodal pipelines combining OCR, layout analysis and field extraction</li>
<li>Produce clean, grounded representations and structured or markdown outputs with Content Understanding</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI-103 Microsoft Certified Azure AI Apps and Agents Developer Associate') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AI-103 and become an Azure AI Apps and Agents Developer Associate. Build generative AI and agentic solutions on Azure with Microsoft Foundry at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI-103 course Singapore, Azure AI Apps and Agents Developer, Microsoft AI certification, Microsoft Foundry, generative AI, AI agents, RAG, computer vision, Azure AI, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-103-microsoft-certified-azure-ai-apps-and-agents-developer-associate') ON DUPLICATE KEY UPDATE value = VALUES(value);
