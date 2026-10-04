-- 1767: WSQ catalog-placement audit #3 (WSQ / CASL / IBF = TGS- courses only;
-- non-WSQ C- courses are handled by 1766). Category memberships only: course
-- status, visibility and every other attribute are untouched.
--
-- 1. AI series rules (title -> series page), multi-agent courses stay on Multi
--    AI Agents Series as in 1766. Copilot, Codex/ChatGPT and Claude series
--    were already complete.
--  * series rule: name matches /agentic/:
--      + TGS-2025060552  WSQ - Agentic AI for Affiliate Marketing  ->  Agentic AI Series
--  * series rule: name matches /generative ai|genai|gen ai/:
--      + TGS-2025059025  WSQ - Generative AI Model Development and Fine Tuning  ->  Generative AI Series
--      + TGS-2026064719  CASL - Generative AI for Design Thinking  ->  Generative AI Series
--  * series rule: name matches /\bai[- ]agents?\b/:
--      + TGS-2023036657  WSQ - Agentic AI and AI Agents for Video Inbound Marketing  ->  AI Agents Series
--      + TGS-2024052081  WSQ - Automate Video and Voice AI Agents with n8n  ->  AI Agents Series
--      + TGS-2025060473  WSQ - AI Security for Autonomous AI Agents  ->  AI Agents Series
--  * agent course (multi-agent / agents wording):
--      + TGS-2023036651  WSQ - Developing AI Apps and Agents on Azure (AI-103)  ->  AI Agents Series
--      + TGS-2022017524  WSQ - Business Process Automation with Power Automate and Co  ->  AI Agents Series
--  * GenAI course:
--      + TGS-2023037589  WSQ - Generative AI for Content Creation  ->  WSQ Generative AI Courses
--  * 3D graphics design:
--      + TGS-2026065705  WSQ - 3D Modelling with Blender for Beginners  ->  WSQ Graphics Design & Media Courses
--  * ITIL 4 Foundation certification:
--      + TGS-2024049350  WSQ - ITIL 4 Foundation Training  ->  WSQ Certification Courses
--  * Lean Six Sigma White Belt certification:
--      + TGS-2025053210  WSQ - Certified Lean Six Sigma White Belt (CLSSWB) Training  ->  WSQ Certification Courses
--  * Claude Certified Architect certification:
--      + TGS-2026061312  WSQ - Claude Certified Architect Foundation  ->  WSQ Certification Courses
--  * SQL / data:
--      + TGS-2020505790  WSQ - SQL Fundamental for Beginners  ->  WSQ Data Analytics & Data Visualization
--  * WSQ sub-category (had none):
--      + TGS-2019504058  WSQ - R Fundamental and Statistical Analysis for Beginners  ->  WSQ Data Analytics & Data Visualization
--      + TGS-2020505561  WSQ - Network Securities for Beginners  ->  WSQ Cyber Security & PDPA
--      + TGS-2020513213  WSQ - Fundamentals of Robot Operating System ROS for Beginne  ->  WSQ Robotics & IoT
--      + TGS-2022015539  WSQ - Applications Integration with Power Apps and Power Aut  ->  WSQ RPA & Automation
--      + TGS-2022017589  WSQ - Linux Configuration and Shell Scripting  ->  WSQ Cloud Computing & Networking
--      + TGS-2023036640  WSQ - Neo4j Professional Graph Database Course  ->  WSQ Data Analytics & Data Visualization
--      + TGS-2023036648  WSQ - Create Intelligent Power Apps and Power Automate Workf  ->  WSQ RPA & Automation
--      + TGS-2023037468  WSQ - Microsoft Power BI Data Analyst Associate (PL-300)  ->  WSQ Data Analytics & Data Visualization
--      + TGS-2023037854  WSQ - Cisco Certified Network Associate (CCNA)  ->  WSQ Cloud Computing & Networking
--      + TGS-2023039179  WSQ - Autodesk Certified Professional (ACP) for Revit Struct  ->  WSQ Technical Drawing & BIM Courses
--      + TGS-2023039340  WSQ - Microsoft Power Platform Developer (PL-400)  ->  WSQ RPA & Automation
--      + TGS-2023039923  WSQ - Microsoft Power Platform Fundamentals (PL-900)  ->  WSQ RPA & Automation
--      + TGS-2023040479  WSQ - CompTIA Certified Network+ Training (Synchronous e-Lea  ->  WSQ Cloud Computing & Networking
--      + TGS-2024042602  WSQ - Microsoft Certified Fabric Data Engineer Associate (DP  ->  WSQ Data Analytics & Data Visualization
--      + TGS-2024042603  WSQ - Microsoft Certified Endpoint Administrator Associate (  ->  WSQ Cloud Computing & Networking
--      + TGS-2024044052  WSQ - Cisco Certified Network Professional (CCNP) for ENCOR   ->  WSQ Cloud Computing & Networking
--      + TGS-2024045221  WSQ - Mastering Robot Operating System (ROS) Essentials - De  ->  WSQ Robotics & IoT
--      + TGS-2024047021  WSQ - Microsoft Identity and Access Administrator (SC-300)  ->  WSQ Cyber Security & PDPA
--      + TGS-2024048316  WSQ - CompTIA Certified Linux+ Training  ->  WSQ Cloud Computing & Networking
--      + TGS-2024048317  WSQ - CompTIA A+ (Core 1 and 2)  ->  WSQ Cloud Computing & Networking
--      + TGS-2024048318  WSQ - CompTIA Server+ Training  ->  WSQ Cloud Computing & Networking
--      + TGS-2024049212  WSQ - CompTIA Certified Data+ Training  ->  WSQ Data Analytics & Data Visualization
--      + TGS-2024049213  WSQ - Enhance Data Insights with Google Sheets and Looker St  ->  WSQ Data Analytics & Data Visualization
--      + TGS-2024051249  WSQ - Practical Design of Experiment (DoE) for Engineers and  ->  WSQ Quality Assurance Courses
--      + TGS-2024052084  WSQ - Data Quality Management Framework  ->  WSQ Data Analytics & Data Visualization
--      + TGS-2025053207  WSQ - Github Foundations Certification Training  ->  WSQ RPA & Automation
--      + TGS-2025054472  WSQ - CompTIA Certified Network+ Training  ->  WSQ Cloud Computing & Networking
--      + TGS-2026061312  WSQ - Claude Certified Architect Foundation  ->  WSQ AI Applications Courses
--      + TGS-2026064180  CASL - Statistics Fundamental Training for Beginners  ->  WSQ Data Analytics & Data Visualization
--  * MD-102 is not RPA:
--      - TGS-2024042603  WSQ - Microsoft Certified Endpoint Administrator Associate (  ->  RPA
--  * MD-102 is not REST API:
--      - TGS-2024042603  WSQ - Microsoft Certified Endpoint Administrator Associate (  ->  REST API
--  * ML for trading is not blockchain:
--      - TGS-2023018794  IBF - Machine Learning 101 for Financial Trading  ->  IBF Blockchain & Crypto
--  * GenAI content creation is not agentic:
--      - TGS-2023037589  WSQ - Generative AI for Content Creation  ->  WSQ Agentic AI Courses
--  * Copilot for HR is not agentic:
--      - TGS-2024045795  WSQ - Microsoft Copilot for HR  ->  WSQ Agentic AI Courses
--      - TGS-2024045795  WSQ - Microsoft Copilot for HR  ->  Agentic AI Series
--  * Blender is 3D graphics, not technical drawing/BIM:
--      - TGS-2026065705  WSQ - 3D Modelling with Blender for Beginners  ->  WSQ Technical Drawing & BIM Courses
--  * CompTIA A+ is not a Linux course:
--      - TGS-2024048317  WSQ - CompTIA A+ (Core 1 and 2)  ->  Linux
--  * sales course is not Infocomm:
--      - TGS-2025052342  WSQ - Closing Sales with Empathy-Driven People-Focused Selli  ->  Infocomm Technology
--  * ISO 9001 is not Infocomm:
--      - TGS-2023020563  WSQ - Fundamentals of ISO 9001 Quality Management System  ->  Infocomm Technology
--  * not a certification course:
--      - TGS-2023039344  WSQ - AI for IT Security Professionals  ->  WSQ Certification Courses
--      - TGS-2023039344  WSQ - AI for IT Security Professionals  ->  Certification Exam Prep
--      - TGS-2025053174  WSQ - Kubernetes for Beginners  ->  WSQ Certification Courses
--  * SQL is data, not web design:
--      - TGS-2020505790  WSQ - SQL Fundamental for Beginners  ->  WSQ Web Design & Full Stack Courses
--  * business continuity is not quality assurance:
--      - TGS-2026061582  WSQ - Managing Business Disruptions and Continuity  ->  WSQ Quality Assurance Courses
--  * FMEA is quality, not business/soft skills:
--      - TGS-2021009031  WSQ - Continuous Process Improvement with FMEA  ->  Business & Soft Skills
--  * QuickBooks is accounting, not business/soft skills:
--      - TGS-2026064181  CASL - Quickbooks Accounting System for Small and Medium Ent  ->  Business & Soft Skills
--
-- 2. Catch-all cleanup (328 rows): a course is removed from WSQ Mfg & Green
--    ('wsq-finance-mfg-green-courses') / WSQ IT & Security ('wsq-it-security-courses')
--    when none of its WSQ sub-categories belongs to that group (legacy bulk rows;
--    e.g. Python, SEO, Photoshop on Mfg & Green). Four courses with no fitting
--    sub-category keep exactly one group: Python Fundamentals, Dynamics 365 MB-910,
--    SharePoint -> IT & Security; 3D Printing -> Mfg & Green.
--    WSQ AI / Finance group rows are deliberately left as they are.
-- 3. New sub-category rows also get the WSQ group parent row, like their siblings.
-- 4. Rows pointing at category ids that no longer exist are deleted.
--
-- Additions take MAX(TGS- position)+1 and shift any non-TGS row at/after that slot
-- down one (funded first, see 1269 -> 1273); is_parent=0 index rows are mirrored
-- onto every anchor ancestor (INSERT IGNORE). No removal touches a course that is
-- also in a child of that page, so a reindex cannot re-add it.
-- Categories by url_key, products by TRIM(sku); no-op on MY/GH (no TGS- courses).
-- Idempotent. AFTER APPLYING ON PROD: flush block_html / full_page / collections.

-- ------------------------------------------------------------------ removals

DROP TEMPORARY TABLE IF EXISTS tmp_1767_del;
CREATE TEMPORARY TABLE tmp_1767_del (sku VARCHAR(64) NOT NULL, url_key VARCHAR(255) NOT NULL, PRIMARY KEY (sku, url_key));
INSERT IGNORE INTO tmp_1767_del (sku, url_key) VALUES
  ('TGS-2024042603', 'rpa-api-it-automation-courses'),
  ('TGS-2024042603', 'rest-api-courses'),
  ('TGS-2023018794', 'ibf-blockchain-fintech-courses'),
  ('TGS-2023037589', 'wsq-agentic-ai-courses'),
  ('TGS-2024045795', 'wsq-agentic-ai-courses'),
  ('TGS-2024045795', 'agentic-ai-series'),
  ('TGS-2026065705', 'wsq-technical-drawing-and-bim-courses'),
  ('TGS-2024048317', 'linux-courses'),
  ('TGS-2025052342', 'computer-programming-and-infocomm-courses'),
  ('TGS-2023020563', 'computer-programming-and-infocomm-courses'),
  ('TGS-2023039344', 'wsq-certification-courses'),
  ('TGS-2023039344', 'certification-exam-prep-courses'),
  ('TGS-2025053174', 'wsq-certification-courses'),
  ('TGS-2020505790', 'wsq-web-design-cms-courses'),
  ('TGS-2026061582', 'wsq-quality-assurance-courses'),
  ('TGS-2021009031', 'business-soft-skills-courses'),
  ('TGS-2026064181', 'business-soft-skills-courses'),
  ('TGS-2019503161', 'wsq-finance-mfg-green-courses'),
  ('TGS-2019503343', 'wsq-finance-mfg-green-courses'),
  ('TGS-2019503343', 'wsq-it-security-courses'),
  ('TGS-2019504058', 'wsq-finance-mfg-green-courses'),
  ('TGS-2019504643', 'wsq-finance-mfg-green-courses'),
  ('TGS-2019504643', 'wsq-it-security-courses'),
  ('TGS-2019504744', 'wsq-finance-mfg-green-courses'),
  ('TGS-2019504744', 'wsq-it-security-courses'),
  ('TGS-2020503109', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020503109', 'wsq-it-security-courses'),
  ('TGS-2020503177', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020503207', 'wsq-it-security-courses'),
  ('TGS-2020503264', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020503395', 'wsq-it-security-courses'),
  ('TGS-2020503501', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020503501', 'wsq-it-security-courses'),
  ('TGS-2020504020', 'wsq-it-security-courses'),
  ('TGS-2020504082', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020505317', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020505433', 'wsq-it-security-courses'),
  ('TGS-2020505444', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020505545', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020505545', 'wsq-it-security-courses'),
  ('TGS-2020505550', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020505561', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020505790', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020505815', 'wsq-finance-mfg-green-courses'),
  ('TGS-2020505815', 'wsq-it-security-courses'),
  ('TGS-2020506075', 'wsq-it-security-courses'),
  ('TGS-2020513213', 'wsq-it-security-courses'),
  ('TGS-2021002336', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021002336', 'wsq-it-security-courses'),
  ('TGS-2021002619', 'wsq-it-security-courses'),
  ('TGS-2021003023', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021003023', 'wsq-it-security-courses'),
  ('TGS-2021003160', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021003160', 'wsq-it-security-courses'),
  ('TGS-2021003585', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021003585', 'wsq-it-security-courses'),
  ('TGS-2021004287', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021004287', 'wsq-it-security-courses'),
  ('TGS-2021005538', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021005538', 'wsq-it-security-courses'),
  ('TGS-2021005539', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021005539', 'wsq-it-security-courses'),
  ('TGS-2021005540', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021005540', 'wsq-it-security-courses'),
  ('TGS-2021006714', 'wsq-it-security-courses'),
  ('TGS-2021006715', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021006715', 'wsq-it-security-courses'),
  ('TGS-2021007827', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021007827', 'wsq-it-security-courses'),
  ('TGS-2021008700', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021009031', 'wsq-it-security-courses'),
  ('TGS-2021009334', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021009334', 'wsq-it-security-courses'),
  ('TGS-2021009337', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021009337', 'wsq-it-security-courses'),
  ('TGS-2021010046', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021010046', 'wsq-it-security-courses'),
  ('TGS-2021010185', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021010185', 'wsq-it-security-courses'),
  ('TGS-2021010195', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021010365', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021010366', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021010367', 'wsq-finance-mfg-green-courses'),
  ('TGS-2021010367', 'wsq-it-security-courses'),
  ('TGS-2022015539', 'wsq-finance-mfg-green-courses'),
  ('TGS-2022017519', 'wsq-finance-mfg-green-courses'),
  ('TGS-2022017519', 'wsq-it-security-courses'),
  ('TGS-2022017520', 'wsq-finance-mfg-green-courses'),
  ('TGS-2022017520', 'wsq-it-security-courses'),
  ('TGS-2022017524', 'wsq-it-security-courses'),
  ('TGS-2022017589', 'wsq-finance-mfg-green-courses'),
  ('TGS-2022017591', 'wsq-finance-mfg-green-courses'),
  ('TGS-2022017597', 'wsq-it-security-courses'),
  ('TGS-2023018262', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023018262', 'wsq-it-security-courses'),
  ('TGS-2023018659', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023018659', 'wsq-it-security-courses'),
  ('TGS-2023018967', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023018967', 'wsq-it-security-courses'),
  ('TGS-2023018987', 'wsq-it-security-courses'),
  ('TGS-2023018988', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023018988', 'wsq-it-security-courses'),
  ('TGS-2023018989', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023018989', 'wsq-it-security-courses'),
  ('TGS-2023018990', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023018990', 'wsq-it-security-courses'),
  ('TGS-2023020425', 'wsq-it-security-courses'),
  ('TGS-2023020563', 'wsq-it-security-courses'),
  ('TGS-2023020565', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023020565', 'wsq-it-security-courses'),
  ('TGS-2023020567', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023020567', 'wsq-it-security-courses'),
  ('TGS-2023021099', 'wsq-it-security-courses'),
  ('TGS-2023021100', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023021102', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023021102', 'wsq-it-security-courses'),
  ('TGS-2023021752', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023021752', 'wsq-it-security-courses'),
  ('TGS-2023036004', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036004', 'wsq-it-security-courses'),
  ('TGS-2023036153', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036153', 'wsq-it-security-courses'),
  ('TGS-2023036449', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036640', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036641', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036642', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036644', 'wsq-it-security-courses'),
  ('TGS-2023036648', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036651', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036653', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036653', 'wsq-it-security-courses'),
  ('TGS-2023036656', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036656', 'wsq-it-security-courses'),
  ('TGS-2023036661', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023036661', 'wsq-it-security-courses'),
  ('TGS-2023037466', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023037466', 'wsq-it-security-courses'),
  ('TGS-2023037467', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023037467', 'wsq-it-security-courses'),
  ('TGS-2023037468', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023037469', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023037469', 'wsq-it-security-courses'),
  ('TGS-2023037472', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023037472', 'wsq-it-security-courses'),
  ('TGS-2023037544', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023037544', 'wsq-it-security-courses'),
  ('TGS-2023037587', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023037587', 'wsq-it-security-courses'),
  ('TGS-2023037589', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023037589', 'wsq-it-security-courses'),
  ('TGS-2023037592', 'wsq-it-security-courses'),
  ('TGS-2023037829', 'wsq-it-security-courses'),
  ('TGS-2023037830', 'wsq-it-security-courses'),
  ('TGS-2023037843', 'wsq-it-security-courses'),
  ('TGS-2023037854', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023038152', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023038152', 'wsq-it-security-courses'),
  ('TGS-2023039177', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039179', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039179', 'wsq-it-security-courses'),
  ('TGS-2023039180', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039180', 'wsq-it-security-courses'),
  ('TGS-2023039181', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039182', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039183', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039340', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039341', 'wsq-it-security-courses'),
  ('TGS-2023039342', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039342', 'wsq-it-security-courses'),
  ('TGS-2023039344', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039835', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039923', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023039924', 'wsq-it-security-courses'),
  ('TGS-2023040473', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023040473', 'wsq-it-security-courses'),
  ('TGS-2023040476', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023040476', 'wsq-it-security-courses'),
  ('TGS-2023040479', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023040481', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023041022', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023041024', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023041080', 'wsq-finance-mfg-green-courses'),
  ('TGS-2023041080', 'wsq-it-security-courses'),
  ('TGS-2023041081', 'wsq-it-security-courses'),
  ('TGS-2024042306', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042307', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042307', 'wsq-it-security-courses'),
  ('TGS-2024042308', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042308', 'wsq-it-security-courses'),
  ('TGS-2024042309', 'wsq-it-security-courses'),
  ('TGS-2024042310', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042310', 'wsq-it-security-courses'),
  ('TGS-2024042369', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042369', 'wsq-it-security-courses'),
  ('TGS-2024042588', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042588', 'wsq-it-security-courses'),
  ('TGS-2024042603', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042604', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042605', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042961', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024042961', 'wsq-it-security-courses'),
  ('TGS-2024043392', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024043419', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024043420', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024043854', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024043854', 'wsq-it-security-courses'),
  ('TGS-2024043855', 'wsq-it-security-courses'),
  ('TGS-2024043856', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024043856', 'wsq-it-security-courses'),
  ('TGS-2024044051', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024044051', 'wsq-it-security-courses'),
  ('TGS-2024044052', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045220', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045220', 'wsq-it-security-courses'),
  ('TGS-2024045221', 'wsq-it-security-courses'),
  ('TGS-2024045222', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045222', 'wsq-it-security-courses'),
  ('TGS-2024045795', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045795', 'wsq-it-security-courses'),
  ('TGS-2024045797', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045797', 'wsq-it-security-courses'),
  ('TGS-2024045798', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045798', 'wsq-it-security-courses'),
  ('TGS-2024045799', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045799', 'wsq-it-security-courses'),
  ('TGS-2024045800', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045800', 'wsq-it-security-courses'),
  ('TGS-2024045801', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045801', 'wsq-it-security-courses'),
  ('TGS-2024045802', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045802', 'wsq-it-security-courses'),
  ('TGS-2024045803', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045803', 'wsq-it-security-courses'),
  ('TGS-2024045806', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024045806', 'wsq-it-security-courses'),
  ('TGS-2024047021', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024048313', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024048313', 'wsq-it-security-courses'),
  ('TGS-2024048316', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024048317', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024048318', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024048319', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049182', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049182', 'wsq-it-security-courses'),
  ('TGS-2024049183', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049183', 'wsq-it-security-courses'),
  ('TGS-2024049184', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049211', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049212', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049213', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049214', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049215', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049215', 'wsq-it-security-courses'),
  ('TGS-2024049338', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049339', 'wsq-it-security-courses'),
  ('TGS-2024049340', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049350', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049350', 'wsq-it-security-courses'),
  ('TGS-2024049780', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024049780', 'wsq-it-security-courses'),
  ('TGS-2024051248', 'wsq-it-security-courses'),
  ('TGS-2024051249', 'wsq-it-security-courses'),
  ('TGS-2024051412', 'wsq-it-security-courses'),
  ('TGS-2024051413', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024051414', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024051519', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024051519', 'wsq-it-security-courses'),
  ('TGS-2024052076', 'wsq-finance-mfg-green-courses'),
  ('TGS-2024052084', 'wsq-finance-mfg-green-courses'),
  ('TGS-2025052277', 'wsq-it-security-courses'),
  ('TGS-2025052341', 'wsq-it-security-courses'),
  ('TGS-2025052674', 'wsq-it-security-courses'),
  ('TGS-2025053210', 'wsq-it-security-courses'),
  ('TGS-2025053916', 'wsq-it-security-courses'),
  ('TGS-2025054471', 'wsq-it-security-courses'),
  ('TGS-2025054815', 'wsq-finance-mfg-green-courses'),
  ('TGS-2025055775', 'wsq-it-security-courses'),
  ('TGS-2025056191', 'wsq-it-security-courses'),
  ('TGS-2025056983', 'wsq-it-security-courses'),
  ('TGS-2025056988', 'wsq-it-security-courses'),
  ('TGS-2025059028', 'wsq-it-security-courses'),
  ('TGS-2025060472', 'wsq-it-security-courses'),
  ('TGS-2025060473', 'wsq-it-security-courses'),
  ('TGS-2025060552', 'wsq-it-security-courses'),
  ('TGS-2026061325', 'wsq-it-security-courses'),
  ('TGS-2026061329', 'wsq-it-security-courses'),
  ('TGS-2026061330', 'wsq-it-security-courses'),
  ('TGS-2026061581', 'wsq-it-security-courses'),
  ('TGS-2026061582', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026062147', 'wsq-it-security-courses'),
  ('TGS-2026064172', 'wsq-it-security-courses'),
  ('TGS-2026064175', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064175', 'wsq-it-security-courses'),
  ('TGS-2026064176', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064176', 'wsq-it-security-courses'),
  ('TGS-2026064177', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064178', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064178', 'wsq-it-security-courses'),
  ('TGS-2026064180', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064181', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064181', 'wsq-it-security-courses'),
  ('TGS-2026064471', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064472', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064474', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064474', 'wsq-it-security-courses'),
  ('TGS-2026064475', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064533', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064535', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064536', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064536', 'wsq-it-security-courses'),
  ('TGS-2026064608', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064608', 'wsq-it-security-courses'),
  ('TGS-2026064708', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064709', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064709', 'wsq-it-security-courses'),
  ('TGS-2026064710', 'wsq-it-security-courses'),
  ('TGS-2026064711', 'wsq-it-security-courses'),
  ('TGS-2026064712', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064712', 'wsq-it-security-courses'),
  ('TGS-2026064713', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064713', 'wsq-it-security-courses'),
  ('TGS-2026064714', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064714', 'wsq-it-security-courses'),
  ('TGS-2026064715', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064716', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064716', 'wsq-it-security-courses'),
  ('TGS-2026064717', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064717', 'wsq-it-security-courses'),
  ('TGS-2026064718', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064718', 'wsq-it-security-courses'),
  ('TGS-2026064719', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064719', 'wsq-it-security-courses'),
  ('TGS-2026064721', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064860', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064860', 'wsq-it-security-courses'),
  ('TGS-2026064861', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026064862', 'wsq-it-security-courses'),
  ('TGS-2026065048', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026065048', 'wsq-it-security-courses'),
  ('TGS-2026065049', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026065049', 'wsq-it-security-courses'),
  ('TGS-2026065050', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026065050', 'wsq-it-security-courses'),
  ('TGS-2026065705', 'wsq-finance-mfg-green-courses'),
  ('TGS-2026065705', 'wsq-it-security-courses');

DROP TEMPORARY TABLE IF EXISTS tmp_1767_delid;
CREATE TEMPORARY TABLE tmp_1767_delid (category_id INT UNSIGNED NOT NULL, product_id INT UNSIGNED NOT NULL, PRIMARY KEY (category_id, product_id));
INSERT IGNORE INTO tmp_1767_delid (category_id, product_id)
SELECT v.entity_id, p.entity_id
  FROM tmp_1767_del d
  JOIN catalog_category_entity_varchar v ON v.store_id = 0 AND v.value = d.url_key
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  JOIN catalog_product_entity p ON TRIM(p.sku) = d.sku;

DELETE cp FROM catalog_category_product cp
  JOIN tmp_1767_delid x ON x.category_id = cp.category_id AND x.product_id = cp.product_id;

DELETE i FROM catalog_category_product_index i
  JOIN tmp_1767_delid x ON x.category_id = i.category_id AND x.product_id = i.product_id;

DROP TEMPORARY TABLE IF EXISTS tmp_1767_delid;
DROP TEMPORARY TABLE IF EXISTS tmp_1767_del;

-- ------------------------------------------------- dangling category ids

DELETE cp FROM catalog_category_product cp
  LEFT JOIN catalog_category_entity e ON e.entity_id = cp.category_id
 WHERE e.entity_id IS NULL;

DELETE i FROM catalog_category_product_index i
  LEFT JOIN catalog_category_entity e ON e.entity_id = i.category_id
 WHERE e.entity_id IS NULL;

-- ------------------------------------------------------------------ additions

-- + TGS-2025060552 -> agentic-ai-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025060552' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='agentic-ai-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2025059025 -> generative-ai-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025059025' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='generative-ai-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2026064719 -> generative-ai-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026064719' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='generative-ai-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023036657 -> ai-agents-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023036657' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-agents-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024052081 -> ai-agents-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024052081' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-agents-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2025060473 -> ai-agents-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025060473' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-agents-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023036651 -> ai-agents-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023036651' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-agents-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2022017524 -> ai-agents-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2022017524' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-agents-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023037589 -> wsq-generative-ai-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023037589' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-generative-ai-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2026065705 -> wsq-graphics-design-media-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026065705' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-graphics-design-media-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024049350 -> wsq-certification-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024049350' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-certification-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2025053210 -> wsq-certification-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025053210' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-certification-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2026061312 -> wsq-certification-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026061312' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-certification-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2020505790 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2020505790' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2019504058 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2019504058' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2020505561 -> wsq-cyber-security-pdpa-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2020505561' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cyber-security-pdpa-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2020513213 -> wsq-iot-robotics-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2020513213' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-iot-robotics-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2022015539 -> wsq-rpa-automation-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2022015539' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-rpa-automation-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2022017589 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2022017589' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023036640 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023036640' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023036648 -> wsq-rpa-automation-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023036648' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-rpa-automation-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023037468 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023037468' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023037854 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023037854' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023039179 -> wsq-technical-drawing-and-bim-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023039179' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-technical-drawing-and-bim-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023039340 -> wsq-rpa-automation-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023039340' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-rpa-automation-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023039923 -> wsq-rpa-automation-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023039923' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-rpa-automation-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023040479 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023040479' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024042602 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024042602' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024042603 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024042603' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024044052 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024044052' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024045221 -> wsq-iot-robotics-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024045221' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-iot-robotics-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024047021 -> wsq-cyber-security-pdpa-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024047021' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cyber-security-pdpa-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024048316 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024048316' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024048317 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024048317' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024048318 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024048318' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024049212 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024049212' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024049213 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024049213' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024051249 -> wsq-quality-assurance-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024051249' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-quality-assurance-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024052084 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024052084' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2025053207 -> wsq-rpa-automation-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025053207' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-rpa-automation-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2025054472 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025054472' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2026061312 -> wsq-ai-applications-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026061312' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-ai-applications-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2026064180 -> wsq-data-analytics-wsq-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026064180' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-data-analytics-wsq-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2023039179 -> wsq-media-marketing-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023039179' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-media-marketing-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2026061312 -> wsq-ai-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026061312' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-ai-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;
