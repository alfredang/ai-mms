-- 1800: two trust fixes requested 2026-10-10.
--
-- 1) Google review incentive removed. 487 course `prerequisite` texts (all sites
--    cloned from SG carry them) opened with a "Promotion Code" section:
--      "Your will get 10% discount voucher for 2nd course onwards if you write us
--       a Google review."  -> links https://g.page/r/CeH-OtN8J4r9EB0/review
--    Google prohibits incentivised reviews, so the whole section (heading + that
--    paragraph) is cut. Nothing else in the text changes.
--    (a) 479 rows: `<h2>Promotion Code</h2>` heading whose first paragraph is the
--        offer -> cut from the heading to the end of that paragraph (2 of these sit
--        mid-text: C-course with PeopleCert steps, Adobe XD course).
--    (b) 8 rows with a damaged / non-h2 heading (`h2>Promotion Code</h2>`,
--        `h2&gt;Promotion Code`, `<p>Promotion Code</p>`, `<p><span ...>`) where
--        heading + offer are the very start of the text -> drop that prefix.
--    Verified on SG prod: every prefix (b) removes is exactly the heading + offer.
--    Guarded on the SG review link, so it runs on every instance but only touches
--    copies of this exact offer. "Promo or discount cannot be applied to WSQ
--    courses" sections are untouched.
--
-- 2) SG FAQ (cms_page faq.html, page 9) corrected to match the live site:
--    - GST: was "There is no GST" -> fees shown GST-exclusive and 9% GST-inclusive,
--      funded courses: GST on the full fee before subsidy.
--    - Payment: Moneybooker / Cheque gone -> methods on payment-methods.html.
--    - "Pay on course day by cash/cheque" -> fees due before the course; Register
--      Your Interest Only; company invoice 30-day terms (payment-methods.html).
--    - Refund: dropped the 7-day "money back guarantee" (not in the policy) ->
--      mirrors cancellation-policy.html + Refund Request form.
--    - Contact: 9698 3731 / enquiry@tertiarycourses.com.sg / "9am-9pm daily" ->
--      +65 6100 0613, WhatsApp +65 8866 6375, enquiry@tertiaryinfotech.com
--      (as on the Contact page, footer, privacy policy, order email); no hours.
--    - "details never shared with anyone" -> Privacy Policy link.
--    SG only (@mms_instance + store guard). Same accordion markup/CSS/JS.
-- Idempotent: re-runs match nothing.

SET @a1800 := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'prerequisite' AND entity_type_id = 4);

UPDATE catalog_product_entity_text t
SET t.value = CONCAT(
      LEFT(t.value, LOCATE('<h2>Promotion Code</h2>', t.value) - 1),
      TRIM(LEADING '\r\n' FROM SUBSTRING(t.value, LOCATE('</p>', t.value, LOCATE('g.page/r/CeH-OtN8J4r9EB0/review', t.value)) + 4)))
WHERE t.attribute_id = @a1800
  AND LOCATE('<h2>Promotion Code</h2>', t.value) > 0
  AND LOCATE('g.page/r/CeH-OtN8J4r9EB0/review', t.value) > LOCATE('<h2>Promotion Code</h2>', t.value)
  AND LOCATE('</p>', t.value, LOCATE('<h2>Promotion Code</h2>', t.value)) = LOCATE('</p>', t.value, LOCATE('g.page/r/CeH-OtN8J4r9EB0/review', t.value));

UPDATE catalog_product_entity_text t
SET t.value = TRIM(LEADING '\r\n' FROM SUBSTRING(t.value, LOCATE('</p>', t.value, LOCATE('g.page/r/CeH-OtN8J4r9EB0/review', t.value)) + 4))
WHERE t.attribute_id = @a1800
  AND LOCATE('Promotion Code', t.value) BETWEEN 1 AND 60
  AND LOCATE('Your will get 10% discount voucher for 2nd course onwards', t.value) BETWEEN 1 AND 120
  AND LOCATE('Minimum Entry', t.value) NOT BETWEEN 1 AND LOCATE('g.page/r/CeH-OtN8J4r9EB0/review', t.value)
  AND LOCATE('g.page/r/CeH-OtN8J4r9EB0/review', t.value) BETWEEN 1 AND 400;

SET @sg1800 := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

UPDATE cms_page SET content = '<style>.page-title,.page-title h1{text-align:center}</style><style>\n.tc-faq{max-width:880px;margin:0 auto}\n.tc-faq-item{border:1px solid #e6e9ef;border-radius:12px;margin:0 0 12px;background:#fff;overflow:hidden;transition:box-shadow .15s}\n.tc-faq-item.open{box-shadow:0 8px 26px rgba(15,23,42,.07);border-color:#cdd5e3}\n.tc-faq-q{width:100%;display:flex;align-items:center;justify-content:space-between;gap:16px;text-align:left;background:none;border:0;cursor:pointer;padding:18px 22px;font-size:16px;font-weight:600;color:#0f172a;line-height:1.45}\n.tc-faq-q:hover{color:#0d9488}\n.tc-faq-q svg{width:20px;height:20px;flex:0 0 auto;color:#94a3b8;transition:transform .2s}\n.tc-faq-item.open .tc-faq-q svg{transform:rotate(180deg);color:#0d9488}\n.tc-faq-a{max-height:0;overflow:hidden;transition:max-height .25s ease;color:#475569;font-size:15px;line-height:1.7}\n.tc-faq-item.open .tc-faq-a{max-height:600px}\n.tc-faq-a>*{margin:0}\n.tc-faq-a-inner{padding:0 22px 20px}\n</style><div class="tc-faq">\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>Is the price shown the final price I will pay?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>Each course shows its fee before GST (GST-exclusive) and with 9% GST (GST-inclusive). The GST-inclusive fee is what you pay before any funding. For WSQ, IBF and other funded courses, the subsidy is deducted from the fee, while GST is calculated on the full course fee before the subsidy. See the Funding section of each course page for details.</p></div></div>\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>How do I make payment?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>You can pay by credit card or PayNow (via HitPay), bank transfer, SkillsFuture Credit (for WSQ and IBF courses), company invoicing, or e-Invoice through Vendors@Gov / GeBIZ for public-sector organisations. Bank details and step-by-step instructions are on our <a href="{{store direct_url=\'payment-methods.html\'}}">Payment Methods</a> page.</p></div></div>\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>Can I pay on the course day?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>Course fees should be received before the course starts. If you are not ready to pay yet, you can register your interest without upfront payment by choosing <strong>Register Your Interest Only</strong> at checkout. Company-sponsored learners can ask for an invoice with 30-day payment terms.</p></div></div>\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>How do I cancel my booking or request a refund?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>Let us know before the class starts &mdash; there is no penalty for cancelling or withdrawing. If you did not pay with SkillsFuture Credit, we refund the course fee you paid in full. If you used SkillsFuture Credit, please cancel your claim on the MySkillsFuture portal on or before the course start date. Group training arranged with an external venue or catering cannot be cancelled. To request a refund, submit our <a href="{{store direct_url=\'refund-request.html\'}}">Refund Request form</a>. Full terms: <a href="{{store direct_url=\'cancellation-policy.html\'}}">Cancellation &amp; Refund Policy</a>.</p></div></div>\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>How do I register for a course?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>Open the course page, choose your class date and click <strong>Register Now</strong>. Then complete checkout:</p>\n<ol>\n<li>Enter your billing details</li>\n<li>Choose a payment method</li>\n<li>Review and place your order</li>\n</ol>\n<p>You will receive a confirmation email for your registration. Your personal data is handled according to our <a href="{{store direct_url=\'privacy-policy.html\'}}">Privacy Policy</a>.</p></div></div>\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>Can I book a course by phone or WhatsApp?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>Yes. Call us on <a href="tel:+6561000613">+65 6100 0613</a> or WhatsApp us at <a href="https://wa.me/6588666375" target="_blank" rel="noopener">+65 8866 6375</a>.</p></div></div>\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>Can I book a course by email?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>Yes. Send your enquiry to <a href="mailto:enquiry@tertiaryinfotech.com">enquiry@tertiaryinfotech.com</a> and we will reply within 1 business day.</p></div></div>\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>I&#39;m having a problem booking online. What can I do?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>Call us on <a href="tel:+6561000613">+65 6100 0613</a> or WhatsApp <a href="https://wa.me/6588666375" target="_blank" rel="noopener">+65 8866 6375</a> and we will help you complete your registration.</p></div></div>\n<div class="tc-faq-item"><button type="button" class="tc-faq-q"><span>Can I ask the trainer questions after the course?</span><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></button><div class="tc-faq-a"><p>Yes. Email your questions about the course subject to <a href="mailto:enquiry@tertiaryinfotech.com">enquiry@tertiaryinfotech.com</a> and we will forward them to the trainer.</p></div></div>\n</div>\n<script>(function(){document.querySelectorAll(".tc-faq-q").forEach(function(b){var a=b.nextElementSibling;a.innerHTML="<div class=\\"tc-faq-a-inner\\">"+a.innerHTML+"</div>";b.addEventListener("click",function(){b.parentNode.classList.toggle("open");});});})();</script>', update_time = NOW() WHERE @sg1800 AND page_id = 9 AND identifier = 'faq.html' AND content LIKE '%There is no GST%';
