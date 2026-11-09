-- 1918: SG agentic AI video workflow article, supplied demo and exact course CTA.
-- Original examples; official connection/model sources verified 9 Nov 2026.
-- Publication only: social sentinels prevent automated external sharing.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

INSERT INTO mmd_blog_post (title, url_key, excerpt, content, author, status, related_skus, source_sku, hero_image_url, meta_title, meta_description, meta_keywords, linkedin_urn, linkedin_org_urn, facebook_post_id, published_at, created_at, updated_at) SELECT 'Agentic AI Video Creation: Claude Code to Higgsfield', 'agentic-ai-video-creation-claude-code-higgsfield', 'Plan scripts, storyboards and character assets with Claude Code, then use Higgsfield MCP and Seedance 2.5. Watch the demo and explore our WSQ course.', '<p><strong>Turn a video idea into a repeatable production workflow.</strong> Use Claude Code to develop the story, write the video script, organise a storyboard and prepare prompts for consistent character assets. Then connect <a href="https://higgsfield.ai/mcp">Higgsfield MCP</a> so the agent can use video-generation tools, with <a href="https://higgsfield.ai/seedance/2.5">Seedance 2.5</a> for the video stage.</p>
<p>This is a practical way to approach <strong>agentic AI for video creation</strong>: give the agent a clear brief, let it organise the work and call connected tools, and review the results at each creative decision. Learn to design the wider production process in our <a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-video-creation.html"><strong>WSQ - Agentic AI for Video Creation course</strong></a>.</p>
<h2>Watch the demo: AI video creation in action</h2>
<p>Start with this Tertiary Courses demo Short. Then use the suggested workflow below to plan and produce your own short video.</p>
<figure style="margin:24px auto;max-width:360px;width:100%;">
<div style="position:relative;width:100%;height:0;padding-top:177.7778%;overflow:hidden;border-radius:16px;background:#101827;">
<iframe src="https://www.youtube.com/embed/k-FEeYSxmZc" title="Tertiary Courses AI video creation demo" width="360" height="640" style="position:absolute;top:0;left:0;width:100%;height:100%;border:0;" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</div>
<figcaption style="text-align:center;margin-top:10px;">Demo: AI video creation. <a href="https://www.youtube.com/shorts/k-FEeYSxmZc">Watch the Short on YouTube</a>.</figcaption>
</figure>
<h2>How Claude Code and Higgsfield work together</h2>
<p>Claude Code acts as the project organiser and writing assistant. Your project files hold the approved brief, script, shot list, character descriptions and review notes. MCP, short for Model Context Protocol, connects the agent to external tools. Higgsfield supplies the image and video generation capabilities; Seedance 2.5 is the video model selected for this example.</p>
<table><thead><tr><th>Stage</th><th>What to ask for</th><th>What you approve</th></tr></thead><tbody>
<tr><td>Story and script</td><td>A hook, narrative beats, voiceover and closing message</td><td>The message, factual claims and pacing</td></tr>
<tr><td>Storyboard</td><td>A shot table with framing, action, timing and audio</td><td>Whether the sequence tells the story clearly</td></tr>
<tr><td>Character assets</td><td>A character description and reference-image prompts</td><td>The reference images and visual continuity</td></tr>
<tr><td>Video generation</td><td>Higgsfield MCP calls using Seedance 2.5</td><td>Model settings, estimated cost and each selected take</td></tr>
<tr><td>Final edit</td><td>A sequence plan, captions and a review checklist</td><td>The finished video before publication</td></tr>
</tbody></table>
<h2>1. Give Claude Code a focused creative brief</h2>
<p>Start small: one audience, one message and one fictional character. For this original practice example, imagine a neighbourhood cafe promoting its morning coffee. A 20-second vertical video is enough to practise the whole process.</p>
<pre style="white-space:pre-wrap;overflow-wrap:anywhere;"><code>Act as my video production assistant. Plan a 20-second, 9:16 video for a fictional Singapore neighbourhood cafe called Morning Light.
Audience: commuters looking for a calm start to the day.
Message: a small morning ritual can make the day feel more welcoming.
Character: Maya, a fictional cafe owner.
Tone: warm, cinematic and grounded.
Create brief.md, script.md, storyboard.md and character-prompts.md.
Begin with the story and script. Do not generate media yet. Ask me to approve the plan before spending generation credits.</code></pre>
<p>Separate the intended message from evidence. Do not invent customer reviews, sales figures or health claims for a real business. A fictional scenario gives you room to explore the visuals.</p>
<h2>2. Develop the storyboard and video script</h2>
<p>Ask Claude Code to make the sequence concrete. A storyboard should explain what the viewer sees and hears in each shot, rather than simply naming a mood. Keep voiceover, dialogue and on-screen text in separate fields so they remain easy to edit.</p>
<pre style="white-space:pre-wrap;overflow-wrap:anywhere;"><code>Expand the approved brief into four shots totalling 20 seconds.
For each shot, include: shot ID, duration, framing, camera movement, character action, setting, lighting, voiceover, ambient sound and transition.
Keep the voiceover below 40 words. Reserve the last three seconds for a closing caption added during editing. Save the shot table in storyboard.md and the spoken words in script.md.</code></pre>
<p>A possible sequence is: the cafe opens; Maya prepares a coffee; she places it on the counter; the film closes with the invitation, &ldquo;Make room for a better morning.&rdquo; This is a suggested exercise, separate from the embedded demo.</p>
<h2>3. Prepare character-asset prompts and references</h2>
<p>A detailed character description helps you specify the same person in each shot. Define the face, hairstyle, clothing, accessories and visual style once. Generate reference images, inspect them and select the approved references before animating. Reusing references helps guide consistency, but every take still needs a continuity check.</p>
<pre style="white-space:pre-wrap;overflow-wrap:anywhere;"><code>Create reference-image prompts for Maya, a fictional Singaporean woman in her early 30s, with an oval face, dark brown eyes, a chin-length black bob, an olive-green apron over a cream shirt and a simple silver wristwatch.
Style: natural cinematic realism, warm morning light, consistent proportions.
Prepare separate front portrait, three-quarter portrait and full-body prompts. Keep the same identifying details in every prompt. Use a neutral background, no lettering and no logos. Return prompts first for approval.</code></pre>
<p>Use Claude Code to keep a small asset register: character name, approved reference filenames, wardrobe and the shots that use them. Upload only material you have permission to use. Obtain consent before generating a recognisable real person''s likeness or voice.</p>
<h2>4. Connect Claude Code to Higgsfield MCP</h2>
<p>Follow the <a href="https://higgsfield.ai/mcp">official Higgsfield MCP connection page</a>. For Claude Code, add the hosted server with the HTTP connection command below:</p>
<pre style="white-space:pre-wrap;overflow-wrap:anywhere;"><code>claude mcp add --transport http higgsfield https://mcp.higgsfield.ai/mcp</code></pre>
<p>Open Claude Code, run <code>/mcp</code>, select Higgsfield and complete the sign-in flow when prompted. Check the server''s connection status. Anthropic''s <a href="https://code.claude.com/docs/en/mcp">Claude Code MCP documentation</a> explains remote-server setup and authentication.</p>
<p>Before a generation, ask the agent to discover the current model options and supported inputs. Confirm that Seedance 2.5 is available to your account through the connected tools. Check the proposed settings and cost estimate; available options and credit usage can change.</p>
<h2>5. Generate video with Seedance 2.5</h2>
<p>Send one approved shot at a time through Higgsfield MCP. Include the approved character reference, the shot''s action, framing, camera movement, lighting and intended audio. Start with one test take before scaling up to the rest of the sequence.</p>
<pre style="white-space:pre-wrap;overflow-wrap:anywhere;"><code>Use Higgsfield MCP to check Seedance 2.5 availability and supported reference inputs.
Prepare shot S02 from storyboard.md using Maya''s approved character reference.
Shot: medium close-up inside the cafe. Maya gently sets a ceramic coffee cup on a wooden counter. Slow camera push-in, warm window light from the left, natural hand movement. Keep her face, bob haircut, olive apron, cream shirt and silver watch consistent with the reference.
Audio direction: soft cafe ambience and a cup touching wood; no dialogue.
Request a 5-second vertical take if those settings are supported. Show the model, references, supported settings and estimated cost before generation. Generate one take after my approval and save its job ID and output URL.</code></pre>
<p>Higgsfield''s <a href="https://higgsfield.ai/seedance/2.5">Seedance 2.5 page</a> describes reference-guided video and audio generation. Use the connected tool''s current schema for actual calls. If a requested option is unavailable, have the agent report it before selecting an alternative.</p>
<h2>6. Review, assemble and publish</h2>
<p>Play each take in full. Check face and wardrobe continuity, hands, prop movement, camera motion, unwanted text and audio. Give precise feedback such as &ldquo;the wristwatch changes between shots S01 and S02&rdquo; so the agent can revise the affected prompt.</p>
<p>Keep the good takes and regenerate only the shots that need work. Assemble the selected clips in your editor, add the approved voiceover and captions, balance audio and export in the required format. Check captions on a phone, including the platform''s interface overlays. Review consent, copyright, music rights and any required AI-content disclosure before uploading.</p>
<h2>Learn to manage the complete AI video workflow</h2>
<p>The useful skill is connecting creative planning, asset generation, editing and review into a process you can repeat. Our <a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-video-creation.html"><strong>WSQ - Agentic AI for Video Creation</strong></a> course, <strong>TGS-2023036088</strong>, covers AI-powered production workflows from ideation and scripting to assets, editing, quality assurance and distribution.</p>
<p><strong>Ready to develop your own production workflow?</strong> <a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-video-creation.html">View the course outline, upcoming dates and registration options</a>. Check the current course page for prerequisites, fees and funding eligibility.</p>
<h2>Frequently asked questions</h2>
<h3>Can Claude Code generate the video itself?</h3>
<p>Claude Code can organise the project, write production material and call connected tools. In this workflow, Higgsfield handles media generation using the selected model, while you direct and approve the work.</p>
<h3>Will one character prompt guarantee the same face in every clip?</h3>
<p>No. Detailed descriptions and approved reference images help, but you still need to review each take and correct visible changes before assembling the final edit.</p>
<h3>Do I need to generate everything again after a script change?</h3>
<p>Ask Claude Code to identify which shots and assets the change affects. Reuse approved material where it still fits, then revise the affected shots and check the complete sequence again.</p>
<p><em>Connection and model sources checked 9 November 2026: <a href="https://higgsfield.ai/mcp">Higgsfield MCP</a>, <a href="https://higgsfield.ai/seedance/2.5">Seedance 2.5</a> and <a href="https://code.claude.com/docs/en/mcp">Claude Code MCP documentation</a>. The cafe scenario and prompts are original practice examples.</em></p>
', 'Tertiary Infotech Academy', '1', 'TGS-2023036088', 'TGS-2023036088', 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20261109-135617-agentic-ai-video-creation-claude-code-to-higgsfield.png', 'Agentic AI Video Creation: Claude Code + Higgsfield', 'Use Claude Code for scripts, storyboards and character prompts, then Higgsfield MCP with Seedance 2.5. Watch the demo and explore our WSQ course.', 'agentic AI video creation,Claude Code storyboard,Higgsfield MCP,Seedance 2.5,AI video course Singapore', 'manual-skip', 'manual-skip', 'manual-skip', UTC_TIMESTAMP(), UTC_TIMESTAMP(), UTC_TIMESTAMP() WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM mmd_blog_post WHERE url_key = 'agentic-ai-video-creation-claude-code-higgsfield');

INSERT IGNORE INTO tag (name, status, first_customer_id, first_store_id) SELECT 'Agentic AI', 1, NULL, 1 WHERE @is_sg = 1 AND NOT EXISTS (SELECT 1 FROM tag WHERE name = 'Agentic AI');

INSERT IGNORE INTO mmd_blog_post_tag (post_id, tag_id) SELECT p.post_id, t.tag_id FROM mmd_blog_post p JOIN tag t ON t.name IN ('Agentic AI', 'Generative AI') WHERE @is_sg = 1 AND p.url_key = 'agentic-ai-video-creation-claude-code-higgsfield';
