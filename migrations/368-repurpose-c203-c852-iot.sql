-- Repurpose two IoT courses (both 2 days / 4 topics, NO AI Vibe Coding badge —
-- different branding). Topics use the Tertiary IoTFlow platform
-- (https://iot.tertiaryinfotech.com/).
--   C203  IoT with Raspberry Pi   (was Raspberry Pi Essential Training ...)
--   C852  Agentic AI for IoT      (was Getting Started with IoT ...; uses ESP8266)
-- Per-market price (700/2200/3000) applied direct on prod. Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

-- =========================================================================
-- C203 - IoT with Raspberry Pi
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C203');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'IoT with Raspberry Pi') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build real Internet of Things (IoT) projects with IoT with Raspberry Pi. This hands-on 2-day course teaches you how to use the Raspberry Pi together with our IoTFlow platform (<a href="https://iot.tertiaryinfotech.com/" target="_blank">https://iot.tertiaryinfotech.com/</a>) to connect sensors, control devices and stream data to the cloud. You will learn to set up a Raspberry Pi, read from sensors, control actuators, and visualise and act on your data through IoTFlow.</p>
<p>Through practical projects, participants will wire up sensors and actuators, program the Raspberry Pi, publish and subscribe to data with IoTFlow, build dashboards, and create automations that respond to real-world events. By the end of the course, you will be able to design, build and deploy connected IoT solutions with the Raspberry Pi and the IoTFlow platform.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Raspberry Pi and IoTFlow</h3>
<ul>
<li>Introduction to IoT and the Raspberry Pi</li>
<li>Setting Up the Raspberry Pi</li>
<li>Introduction to the IoTFlow Platform (https://iot.tertiaryinfotech.com/)</li>
<li>Connecting the Raspberry Pi to IoTFlow</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Reading Sensors and Controlling Devices</h3>
<ul>
<li>Wiring and Reading Sensors</li>
<li>Controlling Actuators and Outputs</li>
<li>Working with GPIO</li>
<li>Publishing Sensor Data to IoTFlow</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Building IoT Dashboards and Automations with IoTFlow</h3>
<ul>
<li>Visualising Data on IoTFlow Dashboards</li>
<li>Setting Up Alerts and Notifications</li>
<li>Creating Automations and Rules</li>
<li>Remote Monitoring and Control</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building and Deploying an IoT Project</h3>
<ul>
<li>Designing an End-to-End IoT Project</li>
<li>Connecting Multiple Devices</li>
<li>Securing Your IoT Solution</li>
<li>Deploying and Scaling with IoTFlow</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'IoT with Raspberry Pi | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build IoT projects with the Raspberry Pi and the IoTFlow platform. Connect sensors, control devices, build dashboards and automations in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'IoT, Raspberry Pi, IoTFlow, Sensors, GPIO, Dashboards, Automation, Internet of Things, Cloud')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C203-20260711-100600.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'iot-with-raspberry-pi') ON DUPLICATE KEY UPDATE value = VALUES(value);

-- =========================================================================
-- C852 - Agentic AI for IoT (ESP8266 + IoTFlow)
-- =========================================================================
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C852');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Agentic AI for IoT') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Bring AI agents to the physical world with Agentic AI for IoT. This hands-on 2-day course teaches you how to combine the ESP8266 microcontroller with our IoTFlow platform (<a href="https://iot.tertiaryinfotech.com/" target="_blank">https://iot.tertiaryinfotech.com/</a>) and AI agents to build smart, autonomous connected devices. You will learn to connect the ESP8266 to sensors and the cloud, stream data through IoTFlow, and use AI agents to make decisions and control devices intelligently.</p>
<p>Through practical projects, participants will program the ESP8266, publish sensor data to IoTFlow, integrate AI agents that analyse data and trigger actions, and build an end-to-end agentic IoT solution that senses, reasons and acts. By the end of the course, you will be able to design and deploy AI-powered IoT systems that combine the ESP8266, IoTFlow and autonomous agents.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with ESP8266 and IoTFlow</h3>
<ul>
<li>Introduction to Agentic AI and IoT</li>
<li>Setting Up the ESP8266</li>
<li>Introduction to the IoTFlow Platform (https://iot.tertiaryinfotech.com/)</li>
<li>Connecting the ESP8266 to IoTFlow</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Sensing and Streaming Data</h3>
<ul>
<li>Wiring Sensors to the ESP8266</li>
<li>Reading and Publishing Sensor Data</li>
<li>Controlling Devices and Actuators</li>
<li>Streaming Data to IoTFlow</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Adding AI Agents to IoT</h3>
<ul>
<li>Introduction to AI Agents for IoT</li>
<li>Connecting AI Agents to IoTFlow Data</li>
<li>Making Decisions and Triggering Actions</li>
<li>Building an Autonomous Agent Loop</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Building and Deploying an Agentic IoT Solution</h3>
<ul>
<li>Designing an End-to-End Agentic IoT Project</li>
<li>Coordinating Multiple Devices and Agents</li>
<li>Securing and Monitoring Your Solution</li>
<li>Deploying and Scaling with IoTFlow</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI for IoT | Tertiary Courses Singapore') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Build AI-powered IoT systems with the ESP8266, the IoTFlow platform and autonomous AI agents. Sense, reason and act on real-world data in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Agentic AI, IoT, ESP8266, IoTFlow, AI Agents, Sensors, Automation, Internet of Things, Microcontroller')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '15') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C852-20260711-100601.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-for-iot') ON DUPLICATE KEY UPDATE value = VALUES(value);
