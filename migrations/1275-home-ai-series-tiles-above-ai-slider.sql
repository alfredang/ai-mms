-- 1275: SG homepage — move the 4 AI Series tiles (migration 1274) so they sit
-- ABOVE the "SkillsFuture Funded AI Courses" slider row (category 196) instead
-- of between it and the cyber-security slider row (category 364).
--
-- One atomic UPDATE: the inner REPLACE removes the tile band from its current
-- spot (directly before the 364 widget), the outer REPLACE re-inserts it
-- before the 196 widget. Guarded on the tiles currently sitting before the
-- 364 widget, so a re-run (or a DB where 1274 never matched — MY/GH partner
-- homes) is a no-op and the band can never be duplicated.
UPDATE cms_page
SET content = REPLACE(
  REPLACE(
    content,
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
{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="364"',
    '{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="364"'
  ),
  '{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="196"',
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
{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="196"'
)
WHERE identifier = 'home'
  AND content LIKE '%</div>
{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="364"%';
