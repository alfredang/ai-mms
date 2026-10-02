-- C1101 Quantum Computing Masterclass: "What's This Course About" and the course topics copied
-- from the WSQ parent TGS-2024043419 (Securing the Future with Quantum Computing and Cryptography),
-- so both catalogue entries describe the same 8-topic course. The old 7-topic syllabus is replaced.
-- About opener "This course, <parent title> , equips" -> "This masterclass equips". No day count.
-- Literal upserts at store 0 (a parent-JOIN copy can no-op on prod); store overrides removed.
-- SG-only (store guard + parent must exist) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1101' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024043419' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This masterclass equips learners with the essential knowledge to design and implement quantum computing applications. Starting with mathematical and quantum physics foundations, participants will explore two-level quantum systems, quantum gates, and circuits. The course will provide a deep understanding of how quantum computing can address complex problems, focusing on both theoretical and practical aspects.</p>\r\n<p>Participants will also evaluate quantum computing\'s applicability in business contexts and delve into quantum security and cryptography. Learners will develop the skills to spearhead the use of quantum algorithms and methodologies, ensuring they are well-prepared to apply quantum computing principles to real-world scenarios.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1 Quantum Physics Fundamentals</h3>\r\n<ul>\r\n<li>Postulates of Quantum Mechanics</li>\r\n<li>Mathematics for Quantum Mechanics</li>\r\n</ul>\r\n<h3 class="course-topic-h3">Topic 2 Introduction to Quantum Computing Systems</h3>\r\n<ul>\r\n<li>Overview of quantum computers</li>\r\n<li>Commercial quantum computing systems</li>\r\n<li>Superposition and Entanglement</li>\r\n</ul>\r\n<h3 class="course-topic-h3">Topic 3 Quantum Gates and Circuits</h3>\r\n<ul>\r\n<li>Single Qubit Gates</li>\r\n<li>Multi Qubits Gates</li>\r\n<li>Bell and GHZ States</li>\r\n<li>Phase Kickback</li>\r\n</ul>\r\n<h3 class="course-topic-h3">Topic 4 Quantum Protocols</h3>\r\n<ul>\r\n<li>No Cloning Theorem</li>\r\n<li>Quantum Teleportation</li>\r\n<li>Superdense Coding Protocol</li>\r\n<li>BB84 Quantum Key Distribution (QKD) Protocol</li>\r\n<li>CHSH Game</li>\r\n</ul>\r\n<h3 class="course-topic-h3">Topic 5 Quantum Algorithms</h3>\r\n<ul>\r\n<li>Deutsch Algorithm</li>\r\n<li>Deutsch-Jozsa Algorithm</li>\r\n<li>Bernstein Vazirani Algorithm</li>\r\n<li>Grover Algorithm</li>\r\n<li>Quantum Fourier Transform</li>\r\n</ul>\r\n<h3 class="course-topic-h3">Topic 6 Quantum Cryptography and Quantum Safety</h3>\r\n<ul>\r\n<li>Introduction to Classical Cryptography</li>\r\n<li>Quantum Threat</li>\r\n<li>Shor Algorithm</li>\r\n<li>Post Quantum Cryptography (PQC)</li>\r\n</ul>\r\n<h3 class="course-topic-h3">Topic 7 Quantum Computing Applications and Use Cases</h3>\r\n<ul>\r\n<li>Finance</li>\r\n<li>Healthcare</li>\r\n<li>Science</li>\r\n</ul>\r\n<h3 class="course-topic-h3">Topic 8 Quantum Error Correction</h3>\r\n<ul>\r\n<li>Introduction to Quantum Error Correction</li>\r\n<li>Bit and Phase Flip Errors</li>\r\n<li>Basic Quantum Error Correction Algorithms</li>\r\n<li>Fault Tolerance Quantum Computers</li>\r\n<li>The Future of Quantum Computers</li>\r\n</ul>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;
