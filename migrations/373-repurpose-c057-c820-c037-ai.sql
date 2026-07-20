-- Repurpose three more AI courses (NO AI Vibe Coding badge):
--   C057  Agentic AI for Finance          (2 days / 4 topics; normalised from 4 days)
--   C820  Agentic AI for HR               (1 day / 2 topics)
--   C037  Generative AI for Concept Art   (1 day / 2 topics)
-- Per-market price (2d 700/2200/3000; 1d 350/1100/1500) direct on prod.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

-- ================= C057 - Agentic AI for Finance (2 days / 4 topics) =================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C057');
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Agentic AI for Finance') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Transform finance operations with Agentic AI for Finance. This hands-on 2-day course teaches you how to build AI agents that automate financial tasks, analyse data and support decision-making, using tools such as ChatGPT, Claude and agentic AI platforms. You will learn to design agents that handle reporting, analysis and workflows while keeping compliance and oversight in place.</p>
<p>Through practical projects, participants will build AI agents that gather and analyse financial data, generate reports and insights, automate reconciliation and forecasting, and support planning and risk assessment. By the end of the course, you will be able to design, deploy and govern AI agents that make finance functions faster, more accurate and more strategic.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Agentic AI for Finance</h3>
<ul>
<li>Introduction to Agentic AI in Finance</li>
<li>Popular AI Agent Tools and Platforms</li>
<li>Writing Effective Prompts for Finance</li>
<li>Connecting Agents to Financial Data</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Automating Financial Workflows with AI Agents</h3>
<ul>
<li>Automating Reporting and Reconciliation</li>
<li>Building Forecasting and Planning Agents</li>
<li>Document and Invoice Processing</li>
<li>Human-in-the-Loop Controls</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Analysis and Insights with AI Agents</h3>
<ul>
<li>Financial Analysis with AI</li>
<li>Risk and Scenario Analysis</li>
<li>Generating Insights and Recommendations</li>
<li>Visualising Financial Data</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Deploying and Governing Financial AI Agents</h3>
<ul>
<li>Securing Financial Data and Access</li>
<li>Compliance and Auditability</li>
<li>Monitoring and Improving Agents</li>
<li>Deploying and Scaling in Finance</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI for Finance | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build AI agents that automate and enhance finance. Automate reporting, forecasting, analysis and risk with tools like ChatGPT and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Agentic AI, Finance, AI Agents, ChatGPT, Claude, Automation, Forecasting, Financial Analysis, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C057-20260711-101142.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-for-finance') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ================= C820 - Agentic AI for HR (1 day / 2 topics) =================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C820');
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Agentic AI for HR') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Reinvent HR with Agentic AI for HR. This hands-on 1-day course teaches you how to build AI agents that automate and enhance human resource tasks, from recruitment to employee support, using tools such as ChatGPT, Claude and agentic AI platforms. You will learn to design agents that save time while keeping the human touch.</p>
<p>Through practical exercises, participants will build AI agents that screen candidates, draft job descriptions and communications, answer employee questions, and streamline onboarding and HR workflows. By the end of the course, you will be able to design and deploy AI agents that make HR faster, fairer and more responsive.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Agentic AI for HR</h3>
<ul>
<li>Introduction to Agentic AI in HR</li>
<li>Popular AI Agent Tools and Platforms</li>
<li>Writing Effective Prompts for HR</li>
<li>Connecting Agents to HR Data</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Automating HR Workflows with AI Agents</h3>
<ul>
<li>Recruitment and Candidate Screening Agents</li>
<li>Onboarding and Employee Support Agents</li>
<li>Drafting HR Content and Communications</li>
<li>Governance, Fairness and Human Oversight</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI for HR | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build AI agents that automate and enhance HR. Streamline recruitment, onboarding and employee support with tools like ChatGPT and Claude in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Agentic AI, HR, Human Resources, AI Agents, ChatGPT, Claude, Recruitment, Onboarding, Automation, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C820-20260711-101143.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-for-hr') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ================= C037 - Generative AI for Concept Art (1 day / 2 topics) =================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C037');
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Generative AI for Concept Art') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Unlock your creativity with Generative AI for Concept Art. This hands-on 1-day course teaches you how to use generative AI image tools such as Midjourney, Stable Diffusion and Firefly to create stunning concept art. You will learn to craft effective prompts, generate and refine artwork, and develop your own visual style with AI.</p>
<p>Through practical exercises, participants will generate characters, environments and props, iterate on styles and compositions, and refine their favourite pieces into polished concept art. By the end of the course, you will be able to use generative AI to bring your creative ideas to life quickly and explore new artistic directions.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for Concept Art</h3>
<ul>
<li>Introduction to Generative AI for Art</li>
<li>Popular AI Image Tools (Midjourney, Stable Diffusion, Firefly)</li>
<li>Writing Effective Prompts for Concept Art</li>
<li>Generating Characters, Environments and Props</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Creating and Refining Concept Art with AI</h3>
<ul>
<li>Developing Styles and Compositions</li>
<li>Iterating and Refining Artwork</li>
<li>Editing and Enhancing with AI</li>
<li>Building a Concept Art Portfolio</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Generative AI for Concept Art | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Create stunning concept art with generative AI. Generate characters, environments and props with tools like Midjourney, Stable Diffusion and Firefly in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Generative AI, Concept Art, Midjourney, Stable Diffusion, Firefly, Digital Art, Image Generation, Creativity, AI')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C037-20260711-101143.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'generative-ai-for-concept-art') ON DUPLICATE KEY UPDATE value = VALUES(value);
