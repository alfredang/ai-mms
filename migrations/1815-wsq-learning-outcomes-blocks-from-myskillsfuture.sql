-- 1815: seed the per-course Learning Outcomes cms_block for enabled SG WSQ/CASL
-- (TGS-) courses that had none, so the storefront Learning Outcomes card renders.
-- LOs are the course's registered Learning Outcomes as published on MySkillsFuture
-- (courses.myskillsfuture.gov.sg/courses/<SKU>), fetched 2026-10-14. Wording kept
-- verbatim apart from capitalisation, trailing full stop and obvious typos.
--
-- Held back (need a decision, registered LOs do not fit the storefront course):
-- TGS-2026064176, TGS-2026064859, TGS-2026064717; TGS-2025060519 has no listing.
--
-- cms_block.identifier has NO unique key -> guarded INSERT + UPDATE (converges on
-- re-run). Partner-safe: every INSERT requires the TGS- product to exist on this
-- site, so MY/GH (no TGS- SKUs) are no-ops. ASCII-only content.

-- TGS-2023040474 DevOps Engineering on AWS
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2023040474 - Learning Outcomes', 'course_TGS-2023040474_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Develop an AWS CI/CD pipelines proof of concept.</li>
<li>LO2: Identify the technical and practical requirements in an AWS cloud infrastructure setup.</li>
<li>LO3: Develop a resilient cloud solution based on AWS cloud components.</li>
<li>LO4: Implement regular AWS monitoring and perform necessary troubleshooting.</li>
<li>LO5: Demonstrate solutions to incidents and business problems on AWS cloud.</li>
<li>LO6: Prepare a technical blueprint to address security and compliance.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2023040474')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2023040474_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2023040474 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Develop an AWS CI/CD pipelines proof of concept.</li>
<li>LO2: Identify the technical and practical requirements in an AWS cloud infrastructure setup.</li>
<li>LO3: Develop a resilient cloud solution based on AWS cloud components.</li>
<li>LO4: Implement regular AWS monitoring and perform necessary troubleshooting.</li>
<li>LO5: Demonstrate solutions to incidents and business problems on AWS cloud.</li>
<li>LO6: Prepare a technical blueprint to address security and compliance.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2023040474_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2023040474_learning_outcomes';

-- TGS-2024048313 AI Vibe Coding for Android Apps Development
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2024048313 - Learning Outcomes', 'course_TGS-2024048313_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Develop a software design blueprint based on Java programming integrating design concepts with user requirements.</li>
<li>LO2: Develop software design standards using Java Object Oriented Programming methodologies.</li>
<li>LO3: Design Java data structures and API for software systems tailored to meet business and user needs.</li>
<li>LO4: Evaluate the issues involved in Java applications using debugging and exception handling tools.</li>
<li>LO5: Produce design documentation using Java generics to ensure conformity to technical standards.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2024048313')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2024048313_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2024048313 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Develop a software design blueprint based on Java programming integrating design concepts with user requirements.</li>
<li>LO2: Develop software design standards using Java Object Oriented Programming methodologies.</li>
<li>LO3: Design Java data structures and API for software systems tailored to meet business and user needs.</li>
<li>LO4: Evaluate the issues involved in Java applications using debugging and exception handling tools.</li>
<li>LO5: Produce design documentation using Java generics to ensure conformity to technical standards.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2024048313_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2024048313_learning_outcomes';

-- TGS-2026064172 Xero Essentials for SMEs: Streamlining Accounting and Tax Operations
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064172 - Learning Outcomes', 'course_TGS-2026064172_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Configure and import relevant data to Xero accounting system.</li>
<li>LO2: Input data to Xero.</li>
<li>LO3: Compute GST for expenses and invoices.</li>
<li>LO4: Generate financial and accounting reports.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064172')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064172_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064172 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Configure and import relevant data to Xero accounting system.</li>
<li>LO2: Input data to Xero.</li>
<li>LO3: Compute GST for expenses and invoices.</li>
<li>LO4: Generate financial and accounting reports.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064172_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064172_learning_outcomes';

-- TGS-2026064174 AI Vibe Coding for Web Design
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064174 - Learning Outcomes', 'course_TGS-2026064174_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Create web and multimedia content according to web content requirements.</li>
<li>LO2: Manage web navigation and form to ensure that web and multimedia content is easily and conveniently accessible and visible and that information is clear, understandable and logical.</li>
<li>LO3: Manage multimedia content with reference to audience needs and site functionalities.</li>
<li>LO4: Style website to enhance user experience.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064174')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064174_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064174 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Create web and multimedia content according to web content requirements.</li>
<li>LO2: Manage web navigation and form to ensure that web and multimedia content is easily and conveniently accessible and visible and that information is clear, understandable and logical.</li>
<li>LO3: Manage multimedia content with reference to audience needs and site functionalities.</li>
<li>LO4: Style website to enhance user experience.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064174_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064174_learning_outcomes';

-- TGS-2026064181 Quickbooks Accounting System for Small and Medium Enterprises
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064181 - Learning Outcomes', 'course_TGS-2026064181_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Configure and import relevant data to Quickbooks accounting system.</li>
<li>LO2: Input data to Quickbooks.</li>
<li>LO3: Compute GST for expenses and invoices.</li>
<li>LO4: Generate financial and accounting reports.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064181')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064181_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064181 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Configure and import relevant data to Quickbooks accounting system.</li>
<li>LO2: Input data to Quickbooks.</li>
<li>LO3: Compute GST for expenses and invoices.</li>
<li>LO4: Generate financial and accounting reports.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064181_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064181_learning_outcomes';

-- TGS-2026064534 Build Full Stack React Web App with Vibe Coding
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064534 - Learning Outcomes', 'course_TGS-2026064534_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Program simple UI applications on React.</li>
<li>LO2: Render UI elements using JSX.</li>
<li>LO3: Code reusable React components.</li>
<li>LO4: Perform testing on component states.</li>
<li>LO5: Code API to handle events.</li>
<li>LO6: Perform bundling of single page applications with React Router.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064534')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064534_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064534 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Program simple UI applications on React.</li>
<li>LO2: Render UI elements using JSX.</li>
<li>LO3: Code reusable React components.</li>
<li>LO4: Perform testing on component states.</li>
<li>LO5: Code API to handle events.</li>
<li>LO6: Perform bundling of single page applications with React Router.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064534_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064534_learning_outcomes';

-- TGS-2026064608 Pattern Recognition and Machine Learning with R
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064608 - Learning Outcomes', 'course_TGS-2026064608_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Model pattern recognition problems suitable for machine learning.</li>
<li>LO2: Apply supervised regression techniques to predict pattern in the data.</li>
<li>LO3: Apply supervised classification techniques to classify pattern in the data.</li>
<li>LO4: Apply unsupervised clustering techniques to cluster patterns and detect anomaly in the data.</li>
<li>LO5: Apply principal component analysis as alternative method to detect pattern in the data.</li>
<li>LO6: Apply deep neural network and CNN models for visual recognition.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064608')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064608_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064608 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Model pattern recognition problems suitable for machine learning.</li>
<li>LO2: Apply supervised regression techniques to predict pattern in the data.</li>
<li>LO3: Apply supervised classification techniques to classify pattern in the data.</li>
<li>LO4: Apply unsupervised clustering techniques to cluster patterns and detect anomaly in the data.</li>
<li>LO5: Apply principal component analysis as alternative method to detect pattern in the data.</li>
<li>LO6: Apply deep neural network and CNN models for visual recognition.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064608_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064608_learning_outcomes';

-- TGS-2026064708 SharePoint Online for End Users
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064708 - Learning Outcomes', 'course_TGS-2026064708_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Implement digital asset management protocols for SharePoint Online.</li>
<li>LO2: Establish file naming system to streamline digital file organization using SharePoint Online.</li>
<li>LO3: Apply security and backup protocols for SharePoint Online to ensure data protection.</li>
<li>LO4: Utilize digital filing policies to maintain version control and document storage.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064708')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064708_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064708 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Implement digital asset management protocols for SharePoint Online.</li>
<li>LO2: Establish file naming system to streamline digital file organization using SharePoint Online.</li>
<li>LO3: Apply security and backup protocols for SharePoint Online to ensure data protection.</li>
<li>LO4: Utilize digital filing policies to maintain version control and document storage.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064708_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064708_learning_outcomes';

-- TGS-2026064709 UI Design with AI
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064709 - Learning Outcomes', 'course_TGS-2026064709_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Identify the user needs and information flows.</li>
<li>LO2: Develop components of user interface prototypes using Adobe XD.</li>
<li>LO3: Design and evaluate the user interface design.</li>
<li>LO4: Document, update and craft assets for user interface design.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064709')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064709_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064709 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Identify the user needs and information flows.</li>
<li>LO2: Develop components of user interface prototypes using Adobe XD.</li>
<li>LO3: Design and evaluate the user interface design.</li>
<li>LO4: Document, update and craft assets for user interface design.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064709_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064709_learning_outcomes';

-- TGS-2026064710 IoT with Arduino
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064710 - Learning Outcomes', 'course_TGS-2026064710_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Apply key concepts of IoT to design an IoT application.</li>
<li>LO2: Setup equipment and programming environment for IoT implementation.</li>
<li>LO3: Manage IoT application on the cloud dashboard.</li>
<li>LO4: Manage data and triggers in IoT applications.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064710')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064710_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064710 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Apply key concepts of IoT to design an IoT application.</li>
<li>LO2: Setup equipment and programming environment for IoT implementation.</li>
<li>LO3: Manage IoT application on the cloud dashboard.</li>
<li>LO4: Manage data and triggers in IoT applications.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064710_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064710_learning_outcomes';

-- TGS-2026064712 Mastering Adobe Lightroom for Photo Editing
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064712 - Learning Outcomes', 'course_TGS-2026064712_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Explore ideas and techniques of digital imagery and improve on the techniques for image production using Lightroom.</li>
<li>LO2: Evaluate the capabilities of digital imaging techniques with regard to the theoretical contexts and principle of design.</li>
<li>LO3: Discuss the image production process with others with intellectual property considerations.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064712')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064712_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064712 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Explore ideas and techniques of digital imagery and improve on the techniques for image production using Lightroom.</li>
<li>LO2: Evaluate the capabilities of digital imaging techniques with regard to the theoretical contexts and principle of design.</li>
<li>LO3: Discuss the image production process with others with intellectual property considerations.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064712_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064712_learning_outcomes';

-- TGS-2026064713 Computer Vision for Beginners
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064713 - Learning Outcomes', 'course_TGS-2026064713_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Understand basic vision systems concepts and applications.</li>
<li>LO2: Apply basic computer vision techniques.</li>
<li>LO3: Implement image classification.</li>
<li>LO4: Implement object detection and video analytics.</li>
<li>LO5: Evaluate edge and cloud-based computer vision systems.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064713')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064713_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064713 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Understand basic vision systems concepts and applications.</li>
<li>LO2: Apply basic computer vision techniques.</li>
<li>LO3: Implement image classification.</li>
<li>LO4: Implement object detection and video analytics.</li>
<li>LO5: Evaluate edge and cloud-based computer vision systems.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064713_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064713_learning_outcomes';

-- TGS-2026064714 Practical Reinforcement Learning for Beginners
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064714 - Learning Outcomes', 'course_TGS-2026064714_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Understand and apply the fundamental concepts of reinforcement learning.</li>
<li>LO2: Use RL on OpenAI Gym.</li>
<li>LO3: Build value-based reinforcement learning systems.</li>
<li>LO4: Build model-based reinforcement learning systems.</li>
<li>LO5: Build policy-based reinforcement learning systems.</li>
<li>LO6: Assess reinforcement learning systems and suggest more advanced reinforcement learning systems.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064714')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064714_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064714 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Understand and apply the fundamental concepts of reinforcement learning.</li>
<li>LO2: Use RL on OpenAI Gym.</li>
<li>LO3: Build value-based reinforcement learning systems.</li>
<li>LO4: Build model-based reinforcement learning systems.</li>
<li>LO5: Build policy-based reinforcement learning systems.</li>
<li>LO6: Assess reinforcement learning systems and suggest more advanced reinforcement learning systems.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064714_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064714_learning_outcomes';

-- TGS-2026064715 Python Text Mining and Analytics: Transforming Text into Insights
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064715 - Learning Outcomes', 'course_TGS-2026064715_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Identify and develop text analytics solutions using Cross-Industry Standard Process for Data Mining (CRISP-DM).</li>
<li>LO2: Read in text corpus and perform text pre-processing using Python.</li>
<li>LO3: Perform text analytics and modify the data using Python with feature engineering.</li>
<li>LO4: Perform sentimental analysis using Python from social media data.</li>
<li>LO5: Perform sentiment summarization and visualization using Python.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064715')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064715_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064715 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Identify and develop text analytics solutions using Cross-Industry Standard Process for Data Mining (CRISP-DM).</li>
<li>LO2: Read in text corpus and perform text pre-processing using Python.</li>
<li>LO3: Perform text analytics and modify the data using Python with feature engineering.</li>
<li>LO4: Perform sentimental analysis using Python from social media data.</li>
<li>LO5: Perform sentiment summarization and visualization using Python.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064715_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064715_learning_outcomes';

-- TGS-2026064718 Master Mobile Photography: Capturing Professional Photos with Your Smartphone
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064718 - Learning Outcomes', 'course_TGS-2026064718_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Setup mobile phone camera for shooting and interpret shot plan.</li>
<li>LO2: Perform basic photography on mobile phone camera and meet safety regulations.</li>
<li>LO3: Perform framing and composition on mobile phone camera.</li>
<li>LO4: Enhance the visual quality and effects on mobile phone camera.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064718')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064718_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064718 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Setup mobile phone camera for shooting and interpret shot plan.</li>
<li>LO2: Perform basic photography on mobile phone camera and meet safety regulations.</li>
<li>LO3: Perform framing and composition on mobile phone camera.</li>
<li>LO4: Enhance the visual quality and effects on mobile phone camera.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064718_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064718_learning_outcomes';

-- TGS-2026064720 AI Vibe Coding for Advanced Data Modeling
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064720 - Learning Outcomes', 'course_TGS-2026064720_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Apply machine learning principles to gain business insights.</li>
<li>LO2: Aggregate data to help test problem.</li>
<li>LO3: Apply predictive data modeling techniques to identify underlying trend and patterns in data using neural networks.</li>
<li>LO4: Develop prototype classification model using machine learning techniques to gain new insight from data.</li>
<li>LO5: Identify patterns using convolutional neural network model to derive insights and make decision.</li>
<li>LO6: Use data visualisation tool to create interactive visualizations of data.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064720')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026064720_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026064720 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Apply machine learning principles to gain business insights.</li>
<li>LO2: Aggregate data to help test problem.</li>
<li>LO3: Apply predictive data modeling techniques to identify underlying trend and patterns in data using neural networks.</li>
<li>LO4: Develop prototype classification model using machine learning techniques to gain new insight from data.</li>
<li>LO5: Identify patterns using convolutional neural network model to derive insights and make decision.</li>
<li>LO6: Use data visualisation tool to create interactive visualizations of data.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026064720_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026064720_learning_outcomes';

-- TGS-2026065049 Python Programming for Finance
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026065049 - Learning Outcomes', 'course_TGS-2026065049_learning_outcomes', '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Apply Python programming to meet business requirements.</li>
<li>LO2: Code data types and operators.</li>
<li>LO3: Organize codes using conditional and loop for problem-solving.</li>
<li>LO4: Code Python functions and scripts for business use cases.</li>
<li>LO5: Code import and prepare finance data using Python Pandas package.</li>
<li>LO6: Test Python codes with aggregation and visualization.</li>
<li>LO7: Improve and document Python codes to analyse finance data.</li>
</ul>', NOW(), NOW(), 1 FROM dual
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026065049')
  AND NOT EXISTS (SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2026065049_learning_outcomes') x);
UPDATE cms_block SET title = 'Course TGS-2026065049 - Learning Outcomes', content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Apply Python programming to meet business requirements.</li>
<li>LO2: Code data types and operators.</li>
<li>LO3: Organize codes using conditional and loop for problem-solving.</li>
<li>LO4: Code Python functions and scripts for business use cases.</li>
<li>LO5: Code import and prepare finance data using Python Pandas package.</li>
<li>LO6: Test Python codes with aggregation and visualization.</li>
<li>LO7: Improve and document Python codes to analyse finance data.</li>
</ul>', is_active = 1, update_time = NOW()
 WHERE identifier = 'course_TGS-2026065049_learning_outcomes';
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2026065049_learning_outcomes';
