-- 565: Rewrite category descriptions that do not match their category title.
--
-- Audit of all 284 ACTIVE categories that hold products found 27 candidate
-- mismatches; an independent adversarial pass refuted 11, leaving 16 confirmed.
-- WSQ/IBF categories and the curated rails ("Popular Courses", "WSQ and IBF
-- courses") are OUT OF SCOPE by instruction, leaving the 8 non-WSQ categories
-- rewritten here.
--
-- Each is a real copy-paste artifact: the stored description describes a
-- different subject than the category title (e.g. "AI Devops Series" carried
-- AI-digital-human copy; "Codex AI Series" carried Keras/TensorFlow/JAX copy).
-- Replacement copy is TWO paragraphs and is grounded in the courses actually
-- assigned to each category, not generic filler.
--
-- Slug/url_key changes are deliberately NOT here — they ship separately in 566
-- with their 301 rewrites so a URL change can be rolled back independently of
-- a text change.
--
-- Matched by CURRENT url_key (stable across instances) rather than a hardcoded
-- entity_id, since ids drift between SG/MY/GH. store_id=0 (default scope) plus
-- any per-store override row. Idempotent: re-running rewrites the same value.
-- After deploy: reindex catalog_category_flat + flush block_html/FPC.

SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

-- ---------------------------------------------------------------------------
-- 75  Java  (url_key java-programming-courses)
-- Was: "Java and Scala are both popular programming languages..." — stale
-- comparative copy orphaned when "Java & Scala" was renamed to "Java" (555).
-- ---------------------------------------------------------------------------
SET @desc := '<p>Java is a general-purpose, object-oriented programming language that has been a mainstay of enterprise software since the mid-1990s. It is valued for its readability, stability and portability: code written once runs across desktop, server, web and Android environments without modification. Java remains one of the most widely deployed languages in banking, telecommunications, logistics and large-scale backend systems, which keeps demand for Java skills consistently strong.</p><p>Our Java courses take you from core language foundations through to practical application development. You will work through classes and objects, inheritance and polymorphism, collections, exception handling and file operations, before moving into building complete applications. The track spans beginner-friendly programming fundamentals, full Java development training, Android app development, and preparation for the Pearson VUE Certified IT Specialist Java certification, so you can join at the level that matches your experience.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'java-programming-courses';

-- ---------------------------------------------------------------------------
-- 81  Healthcare & WSH  (url_key life-science-courses-training)
-- Description was healthcare-only; the category also carries Workplace Safety
-- and Health plus the health/bio data-analysis courses.
-- ---------------------------------------------------------------------------
SET @desc := '<p>Healthcare and Workplace Safety and Health (WSH) sit at the intersection of people, process and data. Healthcare professionals are increasingly expected to interpret clinical and genomic data, while every process plant and workplace must apply WSH practices that keep staff safe and operations compliant. Both fields reward practitioners who can pair domain knowledge with practical analytical skill.</p><p>This category brings together training across that full span. You will find applied healthcare and AI-for-healthcare courses, Workplace Safety and Health training for process plant environments, employee health and wellness strategy, and the data-analysis skills that support them — including genomic and bioinformatics analysis with R and Bioconductor, and statistical data analysis with Excel, Python and R. Courses run from foundational to advanced, so both newcomers and experienced practitioners can find an appropriate entry point.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'life-science-courses-training';

-- ---------------------------------------------------------------------------
-- 126  Marketing Analytics  (url_key business-analytics-training-courses)
-- Was entirely about general "business analytics"; never mentioned marketing.
-- Actual courses are GA4, Google Tag Manager and geofencing.
-- ---------------------------------------------------------------------------
SET @desc := '<p>Marketing analytics turns raw campaign and website activity into decisions a marketing team can act on. Rather than reporting traffic for its own sake, it connects channels, journeys and conversions so you can see which campaigns earn their budget, where prospects drop out of the funnel, and what to change next. As privacy rules tighten and measurement moves to event-based models, these skills have become core to any digital marketing role.</p><p>Our marketing analytics courses are hands-on and platform-focused. You will learn Google Analytics 4 from basic setup through to advanced reporting and turning insight into action, implement and debug tracking with Google Tag Manager, and explore location-based approaches such as geofencing. Along the way you will practise configuring events and conversions, building reports that answer real business questions, and presenting findings to stakeholders in language they can use.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'business-analytics-training-courses';

-- ---------------------------------------------------------------------------
-- 139  AI Applications Series  (url_key machine-learning-courses)
-- Description covered machine learning as a discipline only; the category is
-- the broader applied-AI series (agents, LLMs, vendor certifications).
-- ---------------------------------------------------------------------------
SET @desc := '<p>The AI Applications Series covers artificial intelligence as it is actually put to work — building systems that solve a defined problem rather than studying algorithms in isolation. It spans the practical spread of modern AI: machine learning and deep learning, natural language processing, generative models, and the fast-growing area of autonomous and multi-agent systems that can reason, plan and act on a task from end to end.</p><p>Courses in this series run from foundations to specialisation and certification. You can build core skills through machine learning specialisations, deep learning with Keras and large language models, reinforcement learning and NLP with Python, then move into applied agent work such as multi-agent systems, agentic AI for logistics, and AI agents built with Gemini CLI. The series also includes recognised industry certifications from Microsoft Azure AI and CompTIA, so you can convert hands-on capability into a formal credential.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'machine-learning-courses';

-- ---------------------------------------------------------------------------
-- 214  AI Security Series  (url_key ai-security-series)
-- Description was wholly AI ethics/governance. Retitled copy leads on security
-- (the category title and its C-prefix course) while retaining the governance
-- courses that also sit here.
-- ---------------------------------------------------------------------------
SET @desc := '<p>As organisations move AI systems into production, securing them becomes a distinct discipline. AI introduces attack surfaces that traditional security controls were never designed for — prompt injection, model and data poisoning, unsafe tool use by autonomous agents, and leakage of sensitive information through model outputs. Securing an AI deployment means protecting the model, the data that trains it, and the actions it is permitted to take.</p><p>The AI Security Series addresses that challenge alongside the governance frameworks that support it. You will work through security and governance practices for AI agents, explainable AI techniques that make model behaviour auditable, and the responsible-AI principles that govern fair, transparent and accountable deployment. The courses suit security professionals extending their remit to AI systems, as well as AI practitioners who need to build and operate their systems safely.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'ai-security-series';

-- ---------------------------------------------------------------------------
-- 250  AI Devops Series  (url_key voice-agents-and-video-agents-coures)
-- Description was about AI digital humans — wrong subject entirely.
-- ---------------------------------------------------------------------------
SET @desc := '<p>AI DevOps applies automation and machine intelligence to the way software is built, released and operated. Pipelines that once depended on manually written rules can now use AI to speed up builds, catch defects earlier, interpret logs and telemetry, and reduce the manual toil of running services in production. For teams already practising DevOps, it is the next increment in reliability and delivery speed.</p><p>This series is hands-on and tool-based. You will work with the platforms that anchor a modern delivery pipeline — Docker for containerisation, Kubernetes for orchestration at scale, and Jenkins for continuous integration and delivery — and apply AI techniques across each. The series also covers building live voice and video agents with n8n and Google ADK, giving you practical experience of deploying and operating AI-driven services rather than only building them.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'voice-agents-and-video-agents-coures';

-- ---------------------------------------------------------------------------
-- 283  Codex AI Series  (url_key codex-ai-series)
-- Description was a Keras/TensorFlow/JAX deep-learning overview.
-- ---------------------------------------------------------------------------
SET @desc := '<p>Codex is OpenAI''s coding agent, built to work alongside developers on real engineering tasks — reading an existing codebase, writing and refactoring code, running tests and iterating on the result. Used well, it shifts a developer''s time away from boilerplate and towards design, review and judgement, and it is quickly becoming a standard part of the professional toolchain rather than a novelty.</p><p>The Codex AI Series teaches that workflow in practice. You will learn to drive Codex effectively — scoping a task, giving it the right context, reviewing and correcting what it produces, and keeping quality and security standards intact while working at speed. The series runs from AI vibe coding with Codex for those getting started, through to a Codex masterclass for developers who want to apply it confidently across day-to-day engineering work.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'codex-ai-series';

-- ---------------------------------------------------------------------------
-- 354  Health & Wellness  (url_key health-wellness-courses)
-- Description was generic "personal improvement soft skills" copy. The category
-- is specifically workplace health and wellness.
-- ---------------------------------------------------------------------------
SET @desc := '<p>Employee health and wellness has moved from a staff perk to an operational concern. Burnout, chronic stress and poor mental wellbeing show up directly in absenteeism, attrition and lost productivity, and organisations are increasingly expected to manage them deliberately rather than leave them to individuals. Building resilience across a team is now a core people-management capability.</p><p>Our health and wellness courses give managers, HR practitioners and team leaders practical strategies they can apply at work. You will learn to recognise the early signs of stress and burnout, design and run wellness initiatives that employees actually use, build individual and team resilience, and foster a workplace culture that supports sustained wellbeing. The emphasis throughout is on workable interventions and measurable outcomes rather than general wellness advice.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'health-wellness-courses';

-- ---------------------------------------------------------------------------
-- 314  Ethereum  (url_key ethereum-skillsfuture-courses-in)
-- Description was EMPTY. Note: the trailing '-in' in the url_key is a fossil of
-- the retired India store; the slug is corrected separately in 566.
-- ---------------------------------------------------------------------------
SET @desc := '<p>Ethereum is the programmable blockchain that introduced smart contracts — self-executing agreements that run exactly as written, without an intermediary. It underpins most of the decentralised application landscape, from DeFi protocols and NFTs to tokenised assets and Web3 platforms, and its developer ecosystem remains the largest in the industry. Understanding Ethereum is the practical starting point for building on blockchain at all.</p><p>Our Ethereum courses combine blockchain fundamentals with hands-on smart contract development. You will learn how the network, accounts, gas and transactions actually work, then write, test and deploy smart contracts using Solidity and interact with them through Web3 libraries in Python. The track extends to wider Web3 topics — crypto tokens, NFTs, DeFi and tokenomics — and includes multi-day blockchain specialisations for those who want comprehensive coverage rather than a single-topic introduction.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'ethereum-skillsfuture-courses-in';

-- Seed the row when the category has NO description row at all (rather than an
-- empty one), so the UPDATE above is not a silent no-op.
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_desc, 0, uk.entity_id, @desc
FROM catalog_category_entity_varchar uk
WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = 'ethereum-skillsfuture-courses-in'
  AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_text x
                  WHERE x.entity_id = uk.entity_id AND x.attribute_id = @a_desc AND x.store_id = 0);

-- ---------------------------------------------------------------------------
-- 419  Google Certification Exam Prep  (url_key google-certification-courses)
-- Description was EMPTY.
-- ---------------------------------------------------------------------------
SET @desc := '<p>Google Cloud certifications are among the most recognised credentials in cloud computing, validating that you can design, deploy and operate real workloads on Google Cloud Platform rather than simply recall its features. They are widely used by employers as a hiring and promotion signal, and the professional-level exams in particular carry weight for architecture, data and security roles.</p><p>Our Google certification exam preparation courses map directly to the official exam blueprints. Coverage spans the Associate Cloud Engineer pathway and the professional tracks — Cloud Architect, Data Engineer, Cloud Security Engineer, Cloud Network Engineer, Cloud Database Engineer, Cloud DevOps Engineer, Machine Learning Engineer and Google Workspace Administrator. Each course pairs the underlying concepts with hands-on practice and exam-style questions, so you sit the exam having built the skills it tests rather than having memorised answers.</p>';
UPDATE catalog_category_entity_text t
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = t.entity_id AND uk.attribute_id = @a_uk AND uk.store_id = 0
  SET t.value = @desc
  WHERE t.attribute_id = @a_desc AND uk.value = 'google-certification-courses';

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_desc, 0, uk.entity_id, @desc
FROM catalog_category_entity_varchar uk
WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = 'google-certification-courses'
  AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_text x
                  WHERE x.entity_id = uk.entity_id AND x.attribute_id = @a_desc AND x.store_id = 0);
