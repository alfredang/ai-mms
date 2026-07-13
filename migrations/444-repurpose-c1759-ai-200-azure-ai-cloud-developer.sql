-- Repurpose course C1759 from "MB-500 Microsoft Certified Dynamics 365 Finance
-- and Operations Apps Developer Associate" to "AI-200 Microsoft Certified Azure
-- AI Cloud Developer Associate". Microsoft certification exam-prep course. name,
-- url_key, overview (short_description), exam domains (description) with official
-- skills-measured weightings, meta (title/description/keyword). Price and
-- duration unchanged. Cover regenerated separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1759');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI-200 Microsoft Certified Azure AI Cloud Developer Associate') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AI-200 Microsoft Certified Azure AI Cloud Developer Associate course equips learners with the knowledge and skills required to build, deploy and operate AI cloud solutions on Azure with an emphasis on back-end services and components. Participants will explore developing containerized solutions with Azure Container Registry, Azure Container Apps and Azure Kubernetes Service, and building AI solutions on Azure data management services.</p>
<p>Learners will gain hands-on expertise working with vector search across Azure Cosmos DB, Azure Database for PostgreSQL and Azure Managed Redis, implementing retrieval-augmented generation, and connecting event- and message-based services with Azure Service Bus, Event Grid and Functions. Additionally, the course covers securing solutions with Azure Key Vault and App Configuration, and monitoring with OpenTelemetry and KQL. By completing this course, participants will be prepared to develop secure, scalable AI cloud applications on Azure.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AI-200</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Develop containerized solutions on Azure (20-25%)</h3>
<ul>
<li>Build, store, version and manage container images using Azure Container Registry and ACR Tasks</li>
<li>Deploy containers to Azure App Service, including environment variables and secrets</li>
<li>Deploy applications to Azure Container Apps with environment configuration and revision management</li>
<li>Implement event-driven scaling with Kubernetes Event-driven Autoscaling (KEDA) in Container Apps</li>
<li>Deploy and manage applications to Azure Kubernetes Service (AKS) using manifest files</li>
<li>Monitor and troubleshoot AKS and Container Apps by inspecting logs, events and end-to-end connectivity</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Develop AI solutions by using Azure data management services (25-30%)</h3>
<ul>
<li>Connect to Azure Cosmos DB for NoSQL with the SDK, run queries, and optimize performance and Request Units using indexing policies and consistency levels</li>
<li>Store and retrieve embeddings, execute vector similarity search, and implement a change feed processor</li>
<li>Connect to and query Azure Database for PostgreSQL, model schemas, and design indexing strategies including pgvector</li>
<li>Configure compute, memory and storage for vector workloads, and run vector similarity search with retrieval-augmented generation (RAG) patterns</li>
<li>Integrate Azure Managed Redis for caching, expiration and invalidation, and vector indexing for similarity search</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Connect to and consume Azure services (20-25%)</h3>
<ul>
<li>Queue and process back-end operations with Azure Service Bus, including dead-letter queues, messages, topics and subscriptions</li>
<li>Implement event-driven workflows with Azure Event Grid, including filters, custom events and retries</li>
<li>Build serverless APIs with Azure Functions, implementing triggers and bindings</li>
<li>Configure and deploy function apps</li>
</ul>
<h3 class="course-topic-h3">Domain 4 Secure, monitor, and troubleshoot Azure solutions (20-25%)</h3>
<ul>
<li>Secure secrets with Azure Key Vault, including rotation and retrieval</li>
<li>Store and retrieve app configuration information with Azure App Configuration</li>
<li>Trace distributed systems using OpenTelemetry SDKs</li>
<li>Write KQL queries to analyze logs and metrics</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI-200 Microsoft Certified Azure AI Cloud Developer Associate') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AI-200 and become an Azure AI Cloud Developer Associate. Build containerized AI solutions, vector search, and secure back-end services on Azure at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI-200 course Singapore, Azure AI Cloud Developer, Microsoft AI certification, Azure Kubernetes Service, Cosmos DB, vector search, RAG, Azure Functions, Azure Key Vault, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-200-microsoft-certified-azure-ai-cloud-developer-associate') ON DUPLICATE KEY UPDATE value = VALUES(value);
