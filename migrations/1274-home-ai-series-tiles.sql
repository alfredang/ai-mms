-- 1274: SG homepage — add a band of 4 colorful tiles linking to the four AI
-- Series landing categories (Generative AI / Agentic AI / AI Agents /
-- Microsoft Copilot), inserted immediately ABOVE the "SkillsFuture Funded
-- Cyber Security Courses" slider row (migration 587).
--
-- Each tile has its own gradient color (purple / green / red-pink / blue),
-- white text, and a hover lift. Styles are scoped under .ai-series-tiles so
-- nothing leaks into the rest of the page.
--
-- Anchored on the SG-only cyber-security slider widget prefix (verified on
-- prod 2026-08-31: only cms_page.page_id=2 matches), so this is a no-op on
-- the MY/GH partner DBs. Idempotent via the NOT LIKE marker guard.
UPDATE cms_page
SET content = REPLACE(
  content,
  '{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="364"',
  '<div class="ai-series-tiles">
<style>
.ai-series-tiles{margin:35px 0 15px}
.ai-series-tiles .ast-grid{display:flex;flex-wrap:wrap;gap:20px}
.ai-series-tiles a.ast-card{flex:1 1 180px;box-sizing:border-box;display:block;padding:32px 20px;border-radius:14px;text-align:center;text-decoration:none;color:#fff;transition:transform .2s ease,box-shadow .2s ease}
.ai-series-tiles a.ast-card:hover{transform:translateY(-4px);box-shadow:0 10px 24px rgba(0,0,0,.18);color:#fff;text-decoration:none}
.ai-series-tiles .ast-name{display:block;font-size:20px;font-weight:700;line-height:1.3;margin-bottom:12px}
.ai-series-tiles .ast-cta{display:inline-block;font-size:12px;font-weight:600;letter-spacing:.5px;text-transform:uppercase;color:#fff;border:1px solid rgba(255,255,255,.65);border-radius:999px;padding:6px 16px}
.ai-series-tiles .ast-generative{background:linear-gradient(135deg,#7b2ff7,#c026d3)}
.ai-series-tiles .ast-agentic{background:linear-gradient(135deg,#0ba360,#3cba92)}
.ai-series-tiles .ast-agents{background:linear-gradient(135deg,#ff512f,#dd2476)}
.ai-series-tiles .ast-copilot{background:linear-gradient(135deg,#005bea,#00c6fb)}
</style>
<div class="ast-grid">
<a class="ast-card ast-generative" href="https://www.tertiarycourses.com.sg/generative-ai-series.html"><span class="ast-name">Generative AI Series</span><span class="ast-cta">Explore Courses</span></a>
<a class="ast-card ast-agentic" href="https://www.tertiarycourses.com.sg/agentic-ai-series.html"><span class="ast-name">Agentic AI Series</span><span class="ast-cta">Explore Courses</span></a>
<a class="ast-card ast-agents" href="https://www.tertiarycourses.com.sg/ai-agents-series.html"><span class="ast-name">AI Agents Series</span><span class="ast-cta">Explore Courses</span></a>
<a class="ast-card ast-copilot" href="https://www.tertiarycourses.com.sg/microsoft-copilot-series.html"><span class="ast-name">Microsoft Copilot Series</span><span class="ast-cta">Explore Courses</span></a>
</div>
</div>
{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="364"'
)
WHERE identifier = 'home'
  AND content LIKE '%{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="364"%'
  AND content NOT LIKE '%ai-series-tiles%';
