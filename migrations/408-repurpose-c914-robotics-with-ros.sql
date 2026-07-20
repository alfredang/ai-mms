-- Rename course C914 from "Full Robot Operating System (ROS) Training" to
-- "Robotics with ROS" (2 days / 4 topics). name, overview, topics, meta
-- (title/description/keyword), cover, url_key. Price and duration unchanged
-- (600 SG / 15h). Not an AI Vibe Coding course (no badge). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C914');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Robotics with ROS') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Build and program robots with Robotics with ROS. This hands-on 2-day course teaches you the Robot Operating System (ROS), the industry-standard framework for building robot software. You will learn how ROS works, how to model and simulate robots, and how to program perception, navigation and motion so your robots can sense and move through the world.</p>
<p>Through practical projects, participants will set up a ROS workspace, create nodes that publish and subscribe to topics, model a robot and its sensors, run it in simulation, and build a robot application that navigates and reacts to its environment. By the end of the course, you will be able to develop, simulate and run robot applications with ROS and have a solid foundation for real-world robotics projects.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with ROS</h3>
<ul>
<li>Introduction to Robotics and the Robot Operating System (ROS)</li>
<li>Setting Up the ROS Environment and Workspace</li>
<li>ROS Architecture: Master, Nodes and the Computation Graph</li>
<li>Running and Managing ROS Packages and Tools</li>
</ul>
<h3 class="course-topic-h3">Topic 2 ROS Nodes, Topics and Messages</h3>
<ul>
<li>Creating Publisher and Subscriber Nodes</li>
<li>Working with Topics, Messages and Services</li>
<li>Using Parameters, Launch Files and roslaunch</li>
<li>Debugging with rqt, rostopic and rosbag</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Robot Modelling, Sensors and Simulation</h3>
<ul>
<li>Describing Robots with URDF and TF Transforms</li>
<li>Integrating Sensors (LiDAR, Camera, IMU)</li>
<li>Simulating Robots in Gazebo</li>
<li>Visualising Robots and Data in RViz</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Navigation, Motion and Robot Applications</h3>
<ul>
<li>Robot Motion and Controlling Actuators</li>
<li>Mapping and Localisation (SLAM)</li>
<li>Path Planning and Autonomous Navigation</li>
<li>Building and Running a Complete Robot Application</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Robotics with ROS') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Learn robotics with ROS (Robot Operating System). Build nodes, model and simulate robots in Gazebo and RViz, and program navigation and motion in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Robotics, ROS, Robot Operating System, Gazebo, RViz, SLAM, Navigation, URDF, Robot Programming, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C914-20260712-032849.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'robotics-with-ros') ON DUPLICATE KEY UPDATE value = VALUES(value);
