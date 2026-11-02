-- SEO: keyword landing pages for SG (user directive 2026-10-30) - one category per keyword, with and
-- without "Singapore". Builds on 1877 (AI training / agentic / generative / AI agents pages).
--
--   281 Claude AI Series                  claude training, claude code training
--   370 Claude Certification Exam Prep    claude certification (training)
--   283 Codex AI Series                   chatgpt training, codex training
--   357 Microsoft Copilot Series          (microsoft) copilot training
--   214 AI Security Series                ai security training
--   403 Gemini AI Series                  (google) gemini training
--   143 Internet of Things (IoT)          iot training
--   294 Quantum Computing                 quantum computing training
--   304 DevOps                            devops training (+ kubernetes / docker)
--   135 Microsoft Certification Exam Prep microsoft certification (training)
--    71 Autodesk                          autodesk training
--   211 Autodesk Revit                    revit training
--   209 Autodesk AutoCAD                  autocad training
--
-- Each page: meta_title BARE "<Keyword> ... in Singapore" (MMD_Seotitle adds the brand), keyword-first meta
-- description 130-160 chars, 7-8 meta keywords (with and without Singapore), and a description of the existing
-- banner + H2 sections with the keyword bolded ("<kw> in Singapore" and bare "<kw>") at ~1-2% density, the
-- category's real course list, who-should-attend, FAQs, funding line and cross-links. Store-view overrides removed.
--
-- SG-only (store guard) + keyed on entity id AND current name -> no-op on MY/GH and on a renamed category.
-- Idempotent. Post-deploy: catalog_category_flat reindex + cache flush.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @c_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @c_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @c_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description' AND backend_type = 'text');
SET @c_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords' AND backend_type = 'text');
SET @c_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description' AND backend_type = 'text');
SET @ok := (@sg = 1 AND @c_name IS NOT NULL AND @c_mtitle IS NOT NULL AND @c_mdesc IS NOT NULL AND @c_mkey IS NOT NULL AND @c_desc IS NOT NULL);

DROP TABLE IF EXISTS mms_seo_ai_kw_stage;

CREATE TABLE mms_seo_ai_kw_stage (
  id     INT UNSIGNED NOT NULL PRIMARY KEY,
  name   VARCHAR(255) NOT NULL,
  mt     VARCHAR(255) NOT NULL,
  md     TEXT NOT NULL,
  mk     TEXT NOT NULL,
  body   TEXT NOT NULL,
  banner TEXT NULL,
  full   MEDIUMTEXT NULL
) DEFAULT CHARSET = utf8;

INSERT INTO mms_seo_ai_kw_stage (id, name, mt, md, mk, body) VALUES
(281, 'Claude AI Series', 'Claude Training & Claude Code Courses in Singapore', 'Claude training in Singapore: hands-on Claude AI, Claude Code, Claude Design and Claude for Microsoft 365 courses for professionals and developers.', 'claude training singapore, claude training in singapore, claude training, claude code training, claude ai courses, claude ai training', '<h2>Claude Training in Singapore</h2>
<p>Our <strong>Claude training in Singapore</strong> teaches you to use Anthropic''s Claude for real work: writing, research, analysis, design and software development. Every class is hands-on, so you leave with prompts, projects and workflows you can reuse at work the next day.</p>
<p>Developers can go further with <strong>Claude Code training</strong>, building and shipping applications with an AI coding agent. If you want a formal credential, our <a href="/claude-certification-exam-prep-courses.html">Claude certification courses</a> prepare you for the Claude certification exams.</p>
<h2>Courses in This Category</h2>
<ul>
<li>Claude AI for Digital Marketing</li>
<li>Claude AI Masterclass</li>
<li>Claude Certified Architect - Foundations (CCAR-F) Exam Prep</li>
<li>Claude Certified Architect - Professional (CCAR-P) Exam Prep</li>
<li>Claude Certified Associate - Foundations (CCAO-F) Exam Prep</li>
<li>Claude Certified Developer - Foundations (CCDV-F) Exam Prep</li>
<li>Claude Code Masterclass</li>
<li>Claude Design for UX/UI</li>
<li>Claude Design Masterclass</li>
<li>Claude for Microsoft 365 Masterclass</li>
<li>Agentic AI Applications with Claude Code</li>
<li>Agentic AI for Affiliate Marketing</li>
</ul>
<p>Plus 4 more courses listed below.</p>
<h2>Who Should Attend</h2>
<p>Professionals, marketers, designers and managers who want Claude to speed up everyday work, and developers who want Claude Code training to build software faster. Most Claude courses need no coding background.</p>
<h2>Claude Training FAQs</h2>
<p><strong>Do I need coding experience for Claude training?</strong> No for most courses, such as the Claude AI Masterclass and Claude for Microsoft 365. The Claude Code Masterclass is built for developers and technical staff, and lists its prerequisites on the course page.</p>
<p><strong>What is the difference between Claude and Claude Code training?</strong> Claude training covers the Claude app for writing, research, analysis and design. Claude Code training teaches developers to plan, write, test and ship code with Claude as a coding agent.</p>
<p>Singapore Citizens and PRs can take the WSQ versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/claude-certification-exam-prep-courses.html">Claude certification training</a>, <a href="/agentic-ai-series.html">agentic AI training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(370, 'Claude Certification Exam Prep', 'Claude Certification Training in Singapore', 'Claude certification training in Singapore: exam prep for the Claude Certified Associate, Developer and Architect exams with practice questions.', 'claude certification singapore, claude certification in singapore, claude certification, claude certification training, claude certification exam prep, claude certified architect, claude certified developer', '<h2>Claude Certification in Singapore</h2>
<p>Prepare for your <strong>Claude certification</strong> with instructor-led exam prep. Our <strong>Claude certification training in Singapore</strong> covers the Claude Certified Associate, Developer and Architect exams, with guided practice on the skills each exam tests.</p>
<p>Choose the Associate - Foundations exam if you use Claude in a business role, the Developer - Foundations exam if you build with Claude, and the Architect exams if you design Claude solutions for an organisation.</p>
<h2>Courses in This Category</h2>
<ul>
<li>Claude Certified Architect - Foundations (CCAR-F) Exam Prep</li>
<li>Claude Certified Architect - Professional (CCAR-P) Exam Prep</li>
<li>Claude Certified Associate - Foundations (CCAO-F) Exam Prep</li>
<li>Claude Certified Developer - Foundations (CCDV-F) Exam Prep</li>
<li>Claude Certified Architect Foundation</li>
</ul>
<h2>Who Should Attend</h2>
<p>Business users, developers and solution architects who want a recognised Claude certification to prove their skills to employers and clients. Each exam prep course lists its recommended experience on the course page.</p>
<h2>Claude Certification FAQs</h2>
<p><strong>Which Claude certification should I take first?</strong> Most people start with the Claude Certified Associate - Foundations exam. Developers usually begin with the Developer - Foundations exam, and architects progress from Foundations to Professional.</p>
<p><strong>Do I need Claude training before the exam prep?</strong> It helps. If you are new to Claude, start with our <a href="/claude-ai-series.html">Claude training courses</a> and then move on to Claude certification exam prep.</p>
<p>Singapore Citizens and PRs can take the WSQ versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/claude-ai-series.html">Claude training</a>, <a href="/microsoft-certifications-exams.html">Microsoft certification training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(283, 'Codex AI Series', 'ChatGPT & Codex Training Courses in Singapore', 'ChatGPT training in Singapore: hands-on ChatGPT and OpenAI Codex courses for marketing, productivity and building agentic AI applications. WSQ-funded options.', 'chatgpt training singapore, chatgpt training in singapore, chatgpt training, codex training, chatgpt courses, openai codex course, chatgpt for digital marketing', '<h2>ChatGPT Training in Singapore</h2>
<p>Our <strong>ChatGPT training in Singapore</strong> shows you how to use ChatGPT for writing, research, analysis and marketing work, with practical exercises built around your own tasks.</p>
<p>For technical teams, <strong>Codex training</strong> covers OpenAI Codex, the AI coding agent that writes, reviews and fixes code, so you can build agentic AI applications faster. Together these courses form our <strong>ChatGPT and Codex training</strong> track.</p>
<h2>Courses in This Category</h2>
<ul>
<li>Agentic AI Applications with Codex</li>
<li>Agentic AI Solutions with ChatGPT Work and Codex</li>
<li>ChatGPT WORK for Digital Marketing</li>
<li>ChatGPT WORK Masterclass</li>
<li>Codex Masterclass</li>
</ul>
<h2>Who Should Attend</h2>
<p>Professionals and marketers who want to get more done with ChatGPT, and developers who want Codex training to build software and AI agents with OpenAI tools.</p>
<h2>ChatGPT Training FAQs</h2>
<p><strong>Is ChatGPT training suitable for beginners?</strong> Yes. The ChatGPT courses need no coding background. Codex training is aimed at developers and lists its prerequisites on each course page.</p>
<p><strong>What will I build in Codex training?</strong> You use Codex to plan, write and test code, and build agentic AI applications that automate real business tasks.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/claude-ai-series.html">Claude training</a>, <a href="/agentic-ai-series.html">agentic AI training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(357, 'Microsoft Copilot Series', 'Microsoft Copilot Training Courses in Singapore', 'Microsoft Copilot training in Singapore: hands-on Microsoft 365 Copilot courses for Word, Excel, PowerPoint and Teams, plus Copilot Studio agents.', 'microsoft copilot training singapore, microsoft copilot training in singapore, microsoft copilot training, copilot training, microsoft 365 copilot training, copilot studio course, copilot courses', '<h2>Microsoft Copilot Training in Singapore</h2>
<p>Our <strong>Microsoft Copilot training in Singapore</strong> teaches you to use Copilot across Word, Excel, PowerPoint, Outlook, Teams, Power BI and Power Apps, so you finish everyday work faster.</p>
<p>The <strong>Copilot training</strong> track also covers Copilot Studio for building AI agents and chatbots, Copilot for finance and HR teams, and the Microsoft AB-620, AB-731 and AB-900 certifications.</p>
<h2>Courses in This Category</h2>
<ul>
<li>AB-620 Microsoft Certified AI Agent Builder Associate</li>
<li>AB-731 Microsoft Certified AI Transformation Leader</li>
<li>AB-900 Microsoft 365 Copilot and Agent Administration Fundamentals</li>
<li>AI Transformation with Microsoft Copilot</li>
<li>Create Powerpoint Infographics with AI</li>
<li>Microsoft Copilot for Finance</li>
<li>Copilot Studio and Power Automate</li>
<li>Creating AI Agents and Chatbots with Microsoft Copilot Studio</li>
<li>Microsoft 365 Copilot for Excel</li>
<li>Microsoft 365 Copilot Masterclass</li>
<li>Microsoft Copilot for HR</li>
<li>Microsoft Copilot for Power Apps</li>
</ul>
<p>Plus 7 more courses listed below.</p>
<h2>Who Should Attend</h2>
<p>Office workers, managers, finance and HR teams who use Microsoft 365 every day, and IT staff who roll out Microsoft 365 Copilot and Copilot Studio agents. No coding background is needed for most courses.</p>
<h2>Microsoft Copilot Training FAQs</h2>
<p><strong>Do I need a Microsoft 365 Copilot licence for the course?</strong> Check each course page for the software requirements. Our trainers show you what each Copilot feature needs.</p>
<p><strong>Is there Copilot training for building AI agents?</strong> Yes. Copilot Studio courses show you how to build AI agents and chatbots and automate workflows with Power Automate.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/ai-agents-series.html">AI agents training</a>, <a href="/microsoft-certifications-exams.html">Microsoft certification training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(214, 'AI Security Series', 'AI Security Training Courses in Singapore', 'AI security training in Singapore: secure AI systems and AI agents, AI security governance, and AI for cyber and network security. CompTIA SecAI+ prep.', 'ai security training singapore, ai security training in singapore, ai security training, ai security courses, ai for cyber security course, ai agent security training, comptia secai+ training', '<h2>AI Security Training in Singapore</h2>
<p>Our <strong>AI security training in Singapore</strong> covers both sides of AI and cybersecurity: securing AI systems and AI agents, and using AI to detect and respond to cyber threats.</p>
<p>You learn AI security governance, network and IT security with AI, and how to protect autonomous AI agents, with hands-on labs throughout. The <strong>AI security</strong> track also includes CompTIA SecAI+ exam prep.</p>
<h2>Courses in This Category</h2>
<ul>
<li>AI Agent Security</li>
<li>AI for Cyber Security</li>
<li>AI for Network Security</li>
<li>AI Security and Governance</li>
<li>Agentic AI and Gen AI Ethics and Governance</li>
<li>CompTIA SecAI+ Training</li>
<li>AI Agent Cybersecurity</li>
<li>AI for IT Security</li>
<li>AI for IT Security Professionals</li>
<li>AI Security Awareness</li>
<li>AI Security for Autonomous AI Agents</li>
<li>AI Security Governance for Businesses</li>
</ul>
<p>Plus 2 more courses listed below.</p>
<h2>Who Should Attend</h2>
<p>IT and security professionals, network engineers, risk and compliance teams, and managers responsible for deploying AI safely in their organisation.</p>
<h2>AI Security Training FAQs</h2>
<p><strong>Do I need a security background for AI security training?</strong> Awareness and governance courses suit any professional. Technical courses such as AI for network security list their prerequisites on each course page.</p>
<p><strong>Does AI security training cover AI agents?</strong> Yes. Our AI agent security courses cover the risks of autonomous agents and how to monitor and govern them.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/ai-agents-series.html">AI agents training</a>, <a href="/artificial-intelligence-courses.html">AI training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(403, 'Gemini AI Series', 'Google Gemini Training & Courses in Singapore', 'Gemini training in Singapore: hands-on Google Gemini courses for Google Sheets, AI agents with Gemini Spark and multi agent apps with Gemini ADK.', 'gemini training singapore, gemini training in singapore, gemini training, google gemini training, gemini ai courses, gemini adk course, gemini for google sheets', '<h2>Gemini Training in Singapore</h2>
<p>Our <strong>Gemini training in Singapore</strong> teaches you to use Google Gemini for productivity, data work and building AI agents, with hands-on exercises in every class.</p>
<p>Courses range from Gemini for Google Sheets to building AI agents with Gemini Spark and multi agent applications with the Gemini Agent Development Kit (ADK), so the <strong>Google Gemini training</strong> track suits both business users and developers.</p>
<h2>Courses in This Category</h2>
<ul>
<li>AI Agents with Gemini Spark</li>
<li>Building Multi Agent Applications with Gemini ADK</li>
<li>Gemini for Google Sheet</li>
<li>Develop Multi AI Agent Applications with Gemini Agent ADK</li>
</ul>
<h2>Who Should Attend</h2>
<p>Google Workspace users who want Gemini to speed up everyday work, and developers who want to build AI agents and multi agent applications on Google''s Gemini models.</p>
<h2>Gemini Training FAQs</h2>
<p><strong>Is Gemini training suitable for beginners?</strong> Yes. Gemini for Google Sheets needs no coding. The Gemini ADK course is for developers and lists its prerequisites.</p>
<p><strong>Can I build AI agents in Gemini training?</strong> Yes. Our Gemini Spark and Gemini ADK courses show you how to build and run AI agents.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/ai-agents-series.html">AI agents training</a>, <a href="/multi-agents-series.html">multi AI agents courses</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(143, 'Internet of Things (IoT)', 'IoT Training & IoT Courses in Singapore', 'IoT training in Singapore: hands-on Internet of Things courses with Raspberry Pi, from IoT fundamentals for beginners to real IoT projects. WSQ-funded options.', 'iot training singapore, iot training in singapore, iot training, internet of things training, iot courses, raspberry pi course, iot for beginners', '<h2>IoT Training in Singapore</h2>
<p>Our <strong>IoT training in Singapore</strong> teaches you to build Internet of Things projects from the ground up: sensors, microcontrollers, connectivity and data, using boards such as Raspberry Pi.</p>
<p>Every <strong>Internet of Things training</strong> course is hands-on. You wire up devices, write simple code and connect your project to the cloud, so you understand how IoT solutions work in practice.</p>
<h2>Courses in This Category</h2>
<ul>
<li>Business Innovation with Internet-of-Things (IoT)</li>
<li>IoT with Arduino</li>
<li>Mastering Raspberry Pi: Hands-On Practical Applications for Beginners</li>
<li>Internet of Things (IoT) Fundamentals for Beginners</li>
<li>IoT with Raspberry Pi</li>
<li>Internet of Things (IoT) Fundamental for Beginners</li>
</ul>
<h2>Who Should Attend</h2>
<p>Beginners, students, engineers and makers who want practical IoT skills, and managers exploring IoT for business innovation. Beginner courses need no prior electronics experience.</p>
<h2>IoT Training FAQs</h2>
<p><strong>Do I need programming experience for IoT training?</strong> No for the beginner courses. You learn the basic coding you need in class.</p>
<p><strong>Which hardware is used in the IoT courses?</strong> Our IoT courses use Raspberry Pi boards with common sensors.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/iot-robotics-courses-in.html">robotics and IoT courses</a>, <a href="/artificial-intelligence-courses.html">AI training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(294, 'Quantum Computing', 'Quantum Computing Training & Courses in Singapore', 'Quantum computing training in Singapore: learn qubits, superposition, quantum circuits and algorithms in hands-on courses for beginners and IT pros.', 'quantum computing training singapore, quantum computing training in singapore, quantum computing training, quantum computing courses, quantum computing for beginners, quantum computing course, qubits training', '<h2>Quantum Computing Training in Singapore</h2>
<p>Our <strong>quantum computing training in Singapore</strong> explains qubits, superposition, entanglement and quantum circuits in plain language, then lets you run your own quantum programs.</p>
<p>The <strong>quantum computing</strong> courses start from fundamentals for beginners and build up to quantum algorithms and real-world applications of quantum computing.</p>
<h2>Courses in This Category</h2>
<ul>
<li>Quantum Computing Fundamentals for Beginners</li>
<li>Quantum Computing Masterclass</li>
<li>Quantum Computing for Beginners</li>
<li>Securing the Future with Quantum Computing and Cryptography</li>
</ul>
<h2>Who Should Attend</h2>
<p>IT professionals, developers, students and managers who want to understand quantum computing and prepare for its impact on their industry. Beginner courses assume no physics background.</p>
<h2>Quantum Computing Training FAQs</h2>
<p><strong>Do I need a physics or maths degree for quantum computing training?</strong> No. Beginner courses explain the concepts from first principles with hands-on examples.</p>
<p><strong>Will I write quantum programs?</strong> Yes. You build and run simple quantum circuits during class.</p>
<p>Singapore Citizens and PRs can take the WSQ versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/artificial-intelligence-courses.html">AI training</a>, <a href="/ai-security-series.html">AI security training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(304, 'DevOps', 'DevOps Training & Kubernetes Courses in Singapore', 'DevOps training in Singapore: hands-on Docker, Kubernetes, GitHub and CI/CD courses, with CKA, CKAD and KCNA certification prep. WSQ-funded options.', 'devops training singapore, devops training in singapore, devops training, devops courses, kubernetes training, docker training, cka training, github foundations training', '<h2>DevOps Training in Singapore</h2>
<p>Our <strong>DevOps training in Singapore</strong> teaches you to build, ship and run software faster with Docker, Kubernetes, GitHub and cloud DevOps tools.</p>
<p>Courses cover <strong>Kubernetes training</strong> for the CKA, CKAD and KCNA certifications, Docker fundamentals for beginners and GitHub Foundations, with hands-on labs in every class.</p>
<h2>Courses in This Category</h2>
<ul>
<li>Certified Kubernetes Administrator (CKA) Training</li>
<li>Certified Kubernetes Application Developer (CKAD) Training</li>
<li>Docker Fundamentals for Beginners</li>
<li>Github Foundations Certification Training</li>
<li>Kubernetes and Cloud Native Associate (KCNA) Training</li>
<li>AWS Certified DevOps Engineer Professional Training</li>
<li>Designing and Implementing Microsoft DevOps Solutions (AZ-400)</li>
<li>DevOps Engineering on AWS</li>
<li>Kubernetes for Beginners</li>
</ul>
<h2>Who Should Attend</h2>
<p>Developers, system administrators, cloud engineers and IT teams moving to containers, CI/CD and cloud native operations. Beginner courses suit anyone new to DevOps.</p>
<h2>DevOps Training FAQs</h2>
<p><strong>Where should I start with DevOps training?</strong> Start with Docker Fundamentals for Beginners, then move on to Kubernetes and the CKA or CKAD certification.</p>
<p><strong>Does DevOps training prepare me for certification?</strong> Yes. Our Kubernetes courses prepare you for the CKA, CKAD and KCNA exams, and GitHub Foundations prepares you for the GitHub exam.</p>
<p>Singapore Citizens and PRs can take the WSQ versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/microsoft-certifications-exams.html">Microsoft certification training</a>, <a href="/artificial-intelligence-courses.html">AI training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(135, 'Microsoft Certification Exam Prep', 'Microsoft Certification Training in Singapore', 'Microsoft certification training in Singapore: exam prep for Azure, AI, Microsoft 365 Copilot, Power Platform and Power BI with labs and practice tests.', 'microsoft certification singapore, microsoft certification in singapore, microsoft certification, microsoft certification training, azure certification course, microsoft exam prep, az-900 course', '<h2>Microsoft Certification in Singapore</h2>
<p>Earn your <strong>Microsoft certification</strong> with instructor-led exam prep. Our <strong>Microsoft certification training in Singapore</strong> covers Azure, AI, Microsoft 365 Copilot, Power Platform, Power BI and Fabric exams.</p>
<p>Each course follows the official exam skills outline, with hands-on labs and practice questions, from fundamentals exams such as AZ-900 and AI-901 to associate-level exams.</p>
<h2>Courses in This Category</h2>
<ul>
<li>AB-100 Microsoft Certified Agentic AI Business Solutions Architect</li>
<li>AB-620 Microsoft Certified AI Agent Builder Associate</li>
<li>AB-730 Microsoft Certified AI Business Professional</li>
<li>AB-731 Microsoft Certified AI Transformation Leader</li>
<li>AB-900 Microsoft 365 Copilot and Agent Administration Fundamentals</li>
<li>AI-103 Microsoft Certified Azure AI Apps and Agents Developer Associate</li>
<li>AI-200 Microsoft Certified Azure AI Cloud Developer Associate</li>
<li>AI-300 Microsoft Certified Machine Learning Operations Engineer Associate Exam Prep</li>
<li>AI-901 Microsoft Azure AI Fundamentals</li>
<li>AZ-104 Azure Administrator Associate Training</li>
<li>AZ-900 Azure Fundamentals Training</li>
<li>Operationalizing Machine Learning and Generative AI Solutions (AI-300)</li>
</ul>
<p>Plus 21 more courses listed below.</p>
<h2>Who Should Attend</h2>
<p>IT professionals, developers, data analysts and business users who want a Microsoft certification to advance their career. Fundamentals exams need no prior experience.</p>
<h2>Microsoft Certification FAQs</h2>
<p><strong>Which Microsoft certification should I start with?</strong> Start with a fundamentals exam such as AZ-900 Azure Fundamentals, AI-901 Azure AI Fundamentals or PL-900 Power Platform Fundamentals, then move to an associate exam for your role.</p>
<p><strong>Do the courses include practice exams?</strong> Yes. Our Microsoft certification courses include practice questions so you can check you are ready before booking the exam.</p>
<p>Singapore Citizens and PRs can take the WSQ and CASL versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/microsoft-copilot-series.html">Microsoft Copilot training</a>, <a href="/devops-courses.html">DevOps training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(71, 'Autodesk', 'Autodesk Training & Software Courses in Singapore', 'Autodesk training in Singapore: hands-on AutoCAD, AutoCAD Electrical, AutoCAD Mechanical and Revit BIM courses for architects, engineers and drafters.', 'autodesk training singapore, autodesk training in singapore, autodesk training, autodesk courses, autocad training, revit training, autodesk software training', '<h2>Autodesk Training in Singapore</h2>
<p>Our <strong>Autodesk training in Singapore</strong> covers the design software used in architecture, engineering and construction: AutoCAD, Revit and more, taught hands-on by experienced trainers.</p>
<p>Pick a course for your discipline, from <strong>AutoCAD training</strong> for 2D drafting and electrical or mechanical drawings to <strong>Revit training</strong> for architecture and BIM.</p>
<h2>Courses in This Category</h2>
<ul>
<li>AutoCAD Electrical Masterclass</li>
<li>AutoCAD Masterclass</li>
<li>AutoCAD Mechanical Masterclass</li>
<li>Autodesk Revit Architecture Masterclass</li>
<li>Revit BIM Masterclass</li>
<li>Application of BIM using Revit</li>
<li>Architectural Visualization with 3ds Max</li>
<li>Architecture Drawing with Revit</li>
<li>AutoCAD Civil 3D for Infrastructure Design</li>
<li>Autodesk Certified Professional (ACP) - AutoCAD Design and Drafting</li>
<li>Autodesk Certified Professional (ACP) for Revit Architectural Design</li>
<li>Autodesk Certified Professional (ACP) for Revit Mechanical Design</li>
</ul>
<p>Plus 8 more courses listed below.</p>
<h2>Who Should Attend</h2>
<p>Architects, engineers, drafters, designers and students who want practical Autodesk software skills for work or a new career in design and construction.</p>
<h2>Autodesk Training FAQs</h2>
<p><strong>Should I learn AutoCAD or Revit first?</strong> Start with AutoCAD if you need 2D drafting. Choose Revit if you work on building design and BIM projects.</p>
<p><strong>Are the Autodesk courses hands-on?</strong> Yes. You work on real drawings and models in the software throughout each class.</p>
<p>Singapore Citizens and PRs can take the WSQ versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/autodesk-autocad-trainings.html">AutoCAD training</a>, <a href="/autodesk-revit-trainings.html">Revit training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(211, 'Autodesk Revit', 'Revit Training & Revit BIM Courses in Singapore', 'Revit training in Singapore: hands-on Autodesk Revit Architecture and Revit BIM courses, from basic modelling to sheets, schedules and BIM workflows.', 'revit training singapore, revit training in singapore, revit training, revit bim training, revit courses, autodesk revit course, bim training', '<h2>Revit Training in Singapore</h2>
<p>Our <strong>Revit training in Singapore</strong> teaches you to design buildings in Autodesk Revit, from walls, floors and roofs to sheets, schedules and coordinated BIM models.</p>
<p>Every <strong>Revit BIM training</strong> course is hands-on: you build a project model step by step and learn the workflows architecture and engineering firms use every day.</p>
<h2>Courses in This Category</h2>
<ul>
<li>Autodesk Revit Architecture Masterclass</li>
<li>Revit BIM Masterclass</li>
<li>Application of BIM using Revit</li>
<li>Architecture Drawing with Revit</li>
<li>Autodesk Certified Professional (ACP) for Revit Architectural Design</li>
<li>Autodesk Certified Professional (ACP) for Revit Mechanical Design</li>
<li>Autodesk Certified Professional (ACP) for Revit Structural Design</li>
</ul>
<h2>Who Should Attend</h2>
<p>Architects, architectural designers, engineers, BIM coordinators and drafters moving from AutoCAD to BIM. Basic computer skills are enough for the masterclass.</p>
<h2>Revit Training FAQs</h2>
<p><strong>Is Revit training suitable for beginners?</strong> Yes. Our Revit courses start from the interface and basic modelling.</p>
<p><strong>What is the difference between Revit and AutoCAD?</strong> AutoCAD is mainly for 2D drafting, while Revit builds an intelligent 3D BIM model that produces plans, sections and schedules.</p>
<p>Singapore Citizens and PRs can take the WSQ versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/autodesk-autocad-trainings.html">AutoCAD training</a>, <a href="/autodesk-software-courses.html">Autodesk training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>'),
(209, 'Autodesk AutoCAD', 'AutoCAD Training & AutoCAD Courses in Singapore', 'AutoCAD training in Singapore: hands-on AutoCAD, AutoCAD Electrical and AutoCAD Mechanical courses for 2D drafting and technical drawings. WSQ-funded options.', 'autocad training singapore, autocad training in singapore, autocad training, autocad courses, autocad course, autocad electrical course, autocad mechanical course', '<h2>AutoCAD Training in Singapore</h2>
<p>Our <strong>AutoCAD training in Singapore</strong> teaches you to create accurate 2D drawings and technical plans in Autodesk AutoCAD, with hands-on exercises from the first lesson.</p>
<p>Beyond the core <strong>AutoCAD course</strong>, specialist courses cover AutoCAD Electrical for wiring and panel drawings and AutoCAD Mechanical for mechanical parts and assemblies.</p>
<h2>Courses in This Category</h2>
<ul>
<li>AutoCAD Electrical Masterclass</li>
<li>AutoCAD Masterclass</li>
<li>AutoCAD Mechanical Masterclass</li>
<li>AutoCAD Civil 3D for Infrastructure Design</li>
<li>Autodesk Certified Professional (ACP) - AutoCAD Design and Drafting</li>
<li>Technical Drawing with AutoCAD</li>
<li>Technical Drawing with AutoCAD Electrical</li>
<li>Technical Drawing with AutoCAD Mechanical</li>
</ul>
<h2>Who Should Attend</h2>
<p>Drafters, engineers, architects, designers and technicians who produce technical drawings, and beginners starting a career in design and drafting.</p>
<h2>AutoCAD Training FAQs</h2>
<p><strong>Is AutoCAD training suitable for beginners?</strong> Yes. The AutoCAD Masterclass starts from the interface and drawing basics.</p>
<p><strong>Which AutoCAD course should engineers take?</strong> Electrical engineers should choose AutoCAD Electrical, and mechanical engineers AutoCAD Mechanical.</p>
<p>Singapore Citizens and PRs can take the WSQ versions of these courses with up to 70% course fee funding, and use SkillsFuture Credit on eligible courses. Each course page shows its own funding and claim options.</p>
<p>Related: <a href="/autodesk-revit-trainings.html">Revit training</a>, <a href="/autodesk-software-courses.html">Autodesk training</a>.</p>
<p>Need help choosing, or want in-house training for your team in Singapore? <a href="mailto:enquiry@tertiaryinfotech.com">Email our team</a> or <a href="https://wa.me/6588666375">chat with us on WhatsApp</a>.</p>');

-- keep only categories whose current (store-view else store-0) name still matches
DELETE s FROM mms_seo_ai_kw_stage s
  LEFT JOIN catalog_category_entity_varchar n0 ON n0.entity_id = s.id AND n0.attribute_id = @c_name AND n0.store_id = 0
  LEFT JOIN catalog_category_entity_varchar n1 ON n1.entity_id = s.id AND n1.attribute_id = @c_name AND n1.store_id = 1
 WHERE TRIM(COALESCE(n1.value, n0.value, '')) <> s.name;

-- keep the existing banner paragraph (first <p class="category-image">...</p>) and replace the copy after it
UPDATE mms_seo_ai_kw_stage s
  LEFT JOIN catalog_category_entity_text t ON t.entity_id = s.id AND t.attribute_id = @c_desc AND t.store_id = 0
   SET s.banner = IF(t.value LIKE '<p class="category-image">%', SUBSTRING(t.value, 1, LOCATE('</p>', t.value) + 3), '');

UPDATE mms_seo_ai_kw_stage SET full = IF(banner = '', body, CONCAT(banner, '\n', body));

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mtitle, 0, s.id, s.mt FROM mms_seo_ai_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mdesc, 0, s.id, s.md FROM mms_seo_ai_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_mkey, 0, s.id, s.mk FROM mms_seo_ai_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @c_desc, 0, s.id, s.full FROM mms_seo_ai_kw_stage s WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE v FROM catalog_category_entity_varchar v JOIN mms_seo_ai_kw_stage s ON s.id = v.entity_id
 WHERE @ok AND v.attribute_id = @c_mtitle AND v.store_id <> 0;

DELETE t FROM catalog_category_entity_text t JOIN mms_seo_ai_kw_stage s ON s.id = t.entity_id
 WHERE @ok AND t.attribute_id IN (@c_mdesc, @c_mkey, @c_desc) AND t.store_id <> 0;

-- mirror into the store category flat table when it exists (reindex would do the same)
SET @has_flat := (SELECT COUNT(*) FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
                     AND COLUMN_NAME IN ('meta_title', 'meta_description', 'meta_keywords', 'description'));
SET @q := IF(@ok AND @has_flat = 4,
  'UPDATE catalog_category_flat_store_1 f JOIN mms_seo_ai_kw_stage s ON s.id = f.entity_id SET f.meta_title = s.mt, f.meta_description = s.md, f.meta_keywords = s.mk, f.description = s.full',
  'DO 0');
PREPARE st FROM @q;
EXECUTE st;
DEALLOCATE PREPARE st;

DROP TABLE IF EXISTS mms_seo_ai_kw_stage;
