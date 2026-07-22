-- 743: Add the standard WSQ sections (Course Brochure / Certification /
-- WSQ Funding with fee table + SFEC/SFC/PSEA links) to three repurposed
-- courses whose short_description lacked them entirely:
--   TGS-2023037545 iOS C++ Vibe ($800), TGS-2024048313 Android Java Vibe
--   ($1600), TGS-2023036088 Creative Video Agentic AI ($750).
-- Fees: GST 9%; Baseline nett = 50% fee + GST; MCES/SME nett = 30% fee + GST.
-- Skills Framework section intentionally omitted (TSC codes not on file).
-- Guarded: appends only while 'WSQ Funding' is absent. Partner-safe.

SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037545');
UPDATE catalog_product_entity_text SET value = CONCAT(value, '\n', '<h2>Course Brochure</h2>
<p><span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2023037545-SG.pdf" title="WSQ - Native iOS Apps Development with C++ and Vibe Coding Brochure" target="_blank">Download WSQ - Native iOS Apps Development with C++ and Vibe Coding Brochure</a></span></p>
<h2>Certification</h2>
<ul>
<li>
<p><strong>Certificate of Completion from Tertiary Infotech</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Infotech.</p>
</li>
<li>
<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>
</li>
</ul>
<div style=" width: 100%; padding: 10px; border-radius: 25px;">
<h2>WSQ Funding</h2>
<p>WSQ funding is only applicable to Singaporeans and PR. Subject to eligibility, the funding support is subjected to funding caps.</p>
<table border="1" style="width: 100%;">
<tbody>
<tr>
<td colspan="5" style="text-align: center;"><strong><span>Effective for courses starting from 1 Jan 2024</span></strong></td>
</tr>
<tr>
<td rowspan="2" style="text-align: center;"><strong>Full Fee</strong></td>
<td rowspan="2" style="text-align: center;"><strong>GST</strong></td>
<td colspan="3" style="text-align: center;"><strong>Nett Fee after Funding (Incl. GST)</strong></td>
</tr>
<tr>
<td style="text-align: center;"><span><strong>Baseline</strong></span></td>
<td style="text-align: center;"><strong>MCES / SME</strong></td>
</tr>
<tr>
<td style="text-align: center;">$800.00</td>
<td style="text-align: center;">$72.00</td>
<td style="text-align: center;">$472.00</td>
<td style="text-align: center;">$312.00</td>
</tr>
</tbody>
</table>
<p>Baseline: Singaporean/PR age 21 and above<br />MCES(Mid-Career Enhanced Subsidy): S''porean age 40 &amp; above</p>
<p>Upon registration, we will advise further on how to tap on the WSQ Training Subsidy.</p>
<hr />
<p>You can pay the nett fee (after the WSQ training subsidy) by the following :</p>
<h3>SkillsFuture Enterprise Credit (SFEC)</h3>
<p>Eligible Singapore-registered companies can tap on $10000 SFEC to cover out-of-pocket expenses. <a href="https://skillsfuture.gobusiness.gov.sg/course-directory/courses/TGS-2023037545" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Click here to submit SkillsFuture Enterprise Credit</span></a></p>
<h3>SkillsFuture Credit (SFC)</h3>
<p>Eligible Singapore Citizens can use their SFC to offset course fee payable after funding but the $4,000 Additional SFC (Mid-Career Support) cannot be used. <a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber=TGS-2023037545" title="SkillsFuture Credit" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Click here for SkillsFuture Credit submission</span></a></p>
<h3>PSEA</h3>
<p>Eligible Singapore Citizens can use their PSEA funds to offset course fee payable after funding.</p>
<p><span>To check for Post-Secondary Education Account (PSEA) eligibility for this course, <a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber=TGS-2023037545" title="SkillsFuture Credit" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Visit SkillsFuture (course code: TGS-2023037545) </span></a></span></p>
<ul>
<li>Scroll down to &ldquo;Keyword Tags&rdquo; to verify for PSEA eligibility.</li>
<li>If there is &ldquo;PSEA&rdquo; under keyword tags, the course is eligible for PSEA.</li>
</ul>
<p>Once you are eligible for PSEA, please download and fill up the <a href="https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf" title="PSEA Withdrawal Form" target="_blank"><span style="text-decoration: underline; color: #ff0000;">PSEA Withdrawal Form</span></a> and email to us.&nbsp;</p>
</div>')
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('WSQ Funding', value) = 0;

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024048313');
UPDATE catalog_product_entity_text SET value = CONCAT(value, '\n', '<h2>Course Brochure</h2>
<p><span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2024048313-SG.pdf" title="WSQ - Native Android Apps Development with Java and Vibe Coding Brochure" target="_blank">Download WSQ - Native Android Apps Development with Java and Vibe Coding Brochure</a></span></p>
<h2>Certification</h2>
<ul>
<li>
<p><strong>Certificate of Completion from Tertiary Infotech</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Infotech.</p>
</li>
<li>
<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>
</li>
</ul>
<div style=" width: 100%; padding: 10px; border-radius: 25px;">
<h2>WSQ Funding</h2>
<p>WSQ funding is only applicable to Singaporeans and PR. Subject to eligibility, the funding support is subjected to funding caps.</p>
<table border="1" style="width: 100%;">
<tbody>
<tr>
<td colspan="5" style="text-align: center;"><strong><span>Effective for courses starting from 1 Jan 2024</span></strong></td>
</tr>
<tr>
<td rowspan="2" style="text-align: center;"><strong>Full Fee</strong></td>
<td rowspan="2" style="text-align: center;"><strong>GST</strong></td>
<td colspan="3" style="text-align: center;"><strong>Nett Fee after Funding (Incl. GST)</strong></td>
</tr>
<tr>
<td style="text-align: center;"><span><strong>Baseline</strong></span></td>
<td style="text-align: center;"><strong>MCES / SME</strong></td>
</tr>
<tr>
<td style="text-align: center;">$1,600.00</td>
<td style="text-align: center;">$144.00</td>
<td style="text-align: center;">$944.00</td>
<td style="text-align: center;">$624.00</td>
</tr>
</tbody>
</table>
<p>Baseline: Singaporean/PR age 21 and above<br />MCES(Mid-Career Enhanced Subsidy): S''porean age 40 &amp; above</p>
<p>Upon registration, we will advise further on how to tap on the WSQ Training Subsidy.</p>
<hr />
<p>You can pay the nett fee (after the WSQ training subsidy) by the following :</p>
<h3>SkillsFuture Enterprise Credit (SFEC)</h3>
<p>Eligible Singapore-registered companies can tap on $10000 SFEC to cover out-of-pocket expenses. <a href="https://skillsfuture.gobusiness.gov.sg/course-directory/courses/TGS-2024048313" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Click here to submit SkillsFuture Enterprise Credit</span></a></p>
<h3>SkillsFuture Credit (SFC)</h3>
<p>Eligible Singapore Citizens can use their SFC to offset course fee payable after funding but the $4,000 Additional SFC (Mid-Career Support) cannot be used. <a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber=TGS-2024048313" title="SkillsFuture Credit" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Click here for SkillsFuture Credit submission</span></a></p>
<h3>PSEA</h3>
<p>Eligible Singapore Citizens can use their PSEA funds to offset course fee payable after funding.</p>
<p><span>To check for Post-Secondary Education Account (PSEA) eligibility for this course, <a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber=TGS-2024048313" title="SkillsFuture Credit" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Visit SkillsFuture (course code: TGS-2024048313) </span></a></span></p>
<ul>
<li>Scroll down to &ldquo;Keyword Tags&rdquo; to verify for PSEA eligibility.</li>
<li>If there is &ldquo;PSEA&rdquo; under keyword tags, the course is eligible for PSEA.</li>
</ul>
<p>Once you are eligible for PSEA, please download and fill up the <a href="https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf" title="PSEA Withdrawal Form" target="_blank"><span style="text-decoration: underline; color: #ff0000;">PSEA Withdrawal Form</span></a> and email to us.&nbsp;</p>
</div>')
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('WSQ Funding', value) = 0;

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036088');
UPDATE catalog_product_entity_text SET value = CONCAT(value, '\n', '<h2>Course Brochure</h2>
<p><span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2023036088-SG.pdf" title="WSQ - End to End Creative Video Creation with Agentic AI and Vibe Coding Brochure" target="_blank">Download WSQ - End to End Creative Video Creation with Agentic AI and Vibe Coding Brochure</a></span></p>
<h2>Certification</h2>
<ul>
<li>
<p><strong>Certificate of Completion from Tertiary Infotech</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Infotech.</p>
</li>
<li>
<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>
</li>
</ul>
<div style=" width: 100%; padding: 10px; border-radius: 25px;">
<h2>WSQ Funding</h2>
<p>WSQ funding is only applicable to Singaporeans and PR. Subject to eligibility, the funding support is subjected to funding caps.</p>
<table border="1" style="width: 100%;">
<tbody>
<tr>
<td colspan="5" style="text-align: center;"><strong><span>Effective for courses starting from 1 Jan 2024</span></strong></td>
</tr>
<tr>
<td rowspan="2" style="text-align: center;"><strong>Full Fee</strong></td>
<td rowspan="2" style="text-align: center;"><strong>GST</strong></td>
<td colspan="3" style="text-align: center;"><strong>Nett Fee after Funding (Incl. GST)</strong></td>
</tr>
<tr>
<td style="text-align: center;"><span><strong>Baseline</strong></span></td>
<td style="text-align: center;"><strong>MCES / SME</strong></td>
</tr>
<tr>
<td style="text-align: center;">$750.00</td>
<td style="text-align: center;">$67.50</td>
<td style="text-align: center;">$442.50</td>
<td style="text-align: center;">$292.50</td>
</tr>
</tbody>
</table>
<p>Baseline: Singaporean/PR age 21 and above<br />MCES(Mid-Career Enhanced Subsidy): S''porean age 40 &amp; above</p>
<p>Upon registration, we will advise further on how to tap on the WSQ Training Subsidy.</p>
<hr />
<p>You can pay the nett fee (after the WSQ training subsidy) by the following :</p>
<h3>SkillsFuture Enterprise Credit (SFEC)</h3>
<p>Eligible Singapore-registered companies can tap on $10000 SFEC to cover out-of-pocket expenses. <a href="https://skillsfuture.gobusiness.gov.sg/course-directory/courses/TGS-2023036088" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Click here to submit SkillsFuture Enterprise Credit</span></a></p>
<h3>SkillsFuture Credit (SFC)</h3>
<p>Eligible Singapore Citizens can use their SFC to offset course fee payable after funding but the $4,000 Additional SFC (Mid-Career Support) cannot be used. <a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber=TGS-2023036088" title="SkillsFuture Credit" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Click here for SkillsFuture Credit submission</span></a></p>
<h3>PSEA</h3>
<p>Eligible Singapore Citizens can use their PSEA funds to offset course fee payable after funding.</p>
<p><span>To check for Post-Secondary Education Account (PSEA) eligibility for this course, <a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber=TGS-2023036088" title="SkillsFuture Credit" target="_blank"><span style="color: #ff0000; text-decoration-line: underline;">Visit SkillsFuture (course code: TGS-2023036088) </span></a></span></p>
<ul>
<li>Scroll down to &ldquo;Keyword Tags&rdquo; to verify for PSEA eligibility.</li>
<li>If there is &ldquo;PSEA&rdquo; under keyword tags, the course is eligible for PSEA.</li>
</ul>
<p>Once you are eligible for PSEA, please download and fill up the <a href="https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf" title="PSEA Withdrawal Form" target="_blank"><span style="text-decoration: underline; color: #ff0000;">PSEA Withdrawal Form</span></a> and email to us.&nbsp;</p>
</div>')
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('WSQ Funding', value) = 0;
