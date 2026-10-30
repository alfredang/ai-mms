-- 1882: Use the Microsoft Copilot courses destination verified on local and live SG.
-- Touch only the exact URL/anchor in this new guide; preserve all other content.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
UPDATE mmd_blog_post SET content = REPLACE(content, 'href="https://www.tertiarycourses.com.sg/microsoft-copilot-series.html">Microsoft Copilot training series</a>', 'href="https://www.tertiarycourses.com.sg/microsoft-copilot-courses.html">Microsoft Copilot training courses</a>'), updated_at = UTC_TIMESTAMP() WHERE @is_sg = 1 AND url_key = 'ai-trainings-in-singapore' AND content LIKE '%href="https://www.tertiarycourses.com.sg/microsoft-copilot-series.html">Microsoft Copilot training series</a>%';
