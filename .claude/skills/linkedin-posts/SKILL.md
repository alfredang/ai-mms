---
name: linkedin-posts
description: When the user wants to create LinkedIn post copy or optimize for LinkedIn, OR to actually publish a blog post / course to the Tertiary Infotech LinkedIn feed. Also use when the user mentions "LinkedIn post," "push the blog to LinkedIn," "share on LinkedIn," "LinkedIn article," "professional post," "post to LinkedIn," "LinkedIn content," "LinkedIn copy," "B2B LinkedIn," "LinkedIn engagement," "LinkedIn feed," "share box," "document post," "poll," "Newsletter," "reshare," or "LinkedIn marketing." For LinkedIn ads, use linkedin-ads.
metadata:
  version: 1.3.0
---

# Platforms: LinkedIn

Guides LinkedIn post copy creation and optimization. Use for generating publish-ready professional content. Suitable for copy agents and design agents (image specs).

**When invoking**: On **first use**, if helpful, open with 1–2 sentences on what this skill covers and why it matters, then provide the main output. On **subsequent use** or when the user asks to skip, go directly to the main output.

## Output: Publish-Ready Copy

This skill enables agents to generate LinkedIn post copy optimized for engagement. Output includes character-counted text and structure for the "See more" threshold.

## Post Types and Entry Points (organic)

| Kind | What to know |
|------|----------------|
| **Start a post** | Short update; can include **link preview** if you paste a URL. Same feed format as other updates. |
| **Photo** | Single or multiple images (carousel in feed). |
| **Video** | Uploaded file (distinct from **LinkedIn Live**, which is live streaming and has separate gating). |
| **Write article** | **Article** = long-form editor, **separate** from the short post box; long URL, better for depth and some **off-site** discoverability. |
| **Document** | PDF / PPT / DOC (slides in feed). Official limits (check current help): on the order of **~100MB / ~300 pages** per file—verify when publishing. |
| **Poll** | Engagement driver; keep question and options scannable. |
| **More** (menu) | Often includes **celebrations**, **hiring**-style share, **Find an expert**, etc. (varies by product/region). |
| **Reshare** | Reshare or **quote** another member’s post with your take—adds context; avoid empty reshares. |
| **Newsletter** | **Series** subscription; not the same as a one-off post but compound reach over time. |
| **Event** | Create/promote events via a dedicated flow, not the same as a plain text post. |

**Product detail**: [Get started with posting on LinkedIn](https://www.linkedin.com/help/linkedin/answer/a518996) · [Upload and share documents](https://www.linkedin.com/help/linkedin/answer/a518909)

**Why it matters for copy**: Match CTA and length to the **form** (e.g. a document deck vs a 5-line hot take). Do not treat a **short post** and an **Article** as interchangeable.

## Platform Positioning

LinkedIn is a professional network—its core value is career identity, B2B relationships, and professional content. Key differences from general social platforms:

| Dimension | LinkedIn | Meta / X / TikTok |
|-----------|----------|--------------------|
| **Primary intent** | Job seeking, B2B networking, industry learning | Entertainment, social, discovery |
| **Identity** | Real name + career history | Username or lifestyle persona |
| **Content tone** | Professional, constructive | Casual, entertaining, opinion |
| **B2B lead value** | High (job title + company targeting) | Low to medium |
| **Algorithm signal** | Professional interest + network + editorial | Engagement, watch time, virality |

**Prioritize LinkedIn when**: targeting B2B buyers, building professional authority, recruiting, or publishing industry thought leadership. For consumer brand awareness or entertainment, other platforms are often more effective.

## How the Feed Ranks (what to write for)

- The feed is **not** a pure reverse-chronological friend list. It blends **1st-degree connections, follows, company/topic interest, and recommended “out of network”** content from the **Economic Graph**, plus ads. [How the Feed ranks content](https://www.linkedin.com/help/linkedin/answer/a9554004)
- Relevance uses **context** of the post, **profile and network signals**, and **behavior** (read, react, comment, share, **dwell**). Demographics like age or gender are **not** used to rank feed visibility (per public help guidance).
- Platform direction in recent public communications: more **LLM/semantic** understanding, less **inauthentic engagement** and **engagement-bait** / low-quality repetition; favor **real expertise** and **meaningful** discussion. [Background on feed engineering (blog)](https://www.linkedin.com/blog/engineering/feed/engineering-the-next-generation-of-linkedins-feed)

**Writing implications**: Strong **first line** and **on-topic depth**; comments that add substance; avoid templates that look automated or “pod” coordinated.

## Off-Site Search Visibility (SEO & GEO)

LinkedIn content is visible to search engines on a **selective** basis—understand what gets indexed for SEO and cited for GEO.

### What Google Indexes vs. What Is Login-Gated

| Surface | Search Visibility | GEO (AI citation) Value |
|---------|-----------------|-------------------------|
| **Public profile** (Headline, About, Experience) | Indexed for name/company/role queries | Strong entity signal; citable paragraphs |
| **Articles** (long-form editor) | Indexed when set to public | High; structured paragraphs with keywords |
| **Company Page** | Indexed for brand queries | Medium; brand entity signals |
| **Short feed posts** | **Login-gated**—not indexed | **Low**; cannot be cited if behind login |
| **Newsletter issues** | Indexed if public; behind login if subscriber-only | Depends on visibility setting |

### SEO Through LinkedIn

- **Headline** is the most SEO-visible field on your profile—treat it as a title tag. Include primary keyword + value proposition (e.g. “B2B SaaS Marketing | Helping startups scale through content”).
- **About section**: Write public-facing paragraphs with keywords and proof points. This is indexed and often appears in Google search snippets.
- **Featured section**: Use to showcase key links (site, case studies, press). These appear on your public profile and add backlink value.
- **Articles**: Long-form content on LinkedIn ranks independently on Google. Treat as secondary publication, not primary—repurpose site content with canonical or unique article.
- **Consistency**: Align name, headline, and entity names across LinkedIn, your site, and other public bios. See **entity-seo** for `sameAs` alignment.

### GEO Through LinkedIn

- **Entity consistency**: Your LinkedIn profile is a high-authority entity source. AI search tools (ChatGPT, Perplexity, Google AI Overviews) can cite your LinkedIn profile when answering “who is [person]” or “what does [company] do” queries.
- **Citable paragraphs**: Write your About section in answer-first format (40–60 words per block) so AI tools can extract and cite it directly.
- **Evidence links**: Add links to your site, case studies, talks, and publications in Featured and About. AI tools cite external links as supporting references.
- **Public articles**: Publish LinkedIn Articles on relevant topics; well-structured articles with data and citations increase the likelihood of AI citation.
- **Limitation**: Short feed posts behind login walls are invisible to AI crawlers and search engines. Do not rely on feed posts for GEO.

**Actionable checklist**:
- [ ] Headline includes primary keyword + value proposition (treat as meta title)
- [ ] About section written in answer-first format (quotable paragraphs)
- [ ] Featured section showcases site, case studies, key publications
- [ ] Entity names (name, company, role) consistent across LinkedIn and site
- [ ] At least one public Article published on a relevant industry topic
- [ ] LinkedIn profile URL uses custom alias (not default ID string)

For implementation details: **open-graph** (link previews), **entity-seo** (people/org sameAs), **generative-engine-optimization** (cross-platform GEO).

## Profile Modules for Discovery

Key LinkedIn profile modules that affect search visibility and AI citation:

| Module | SEO/GEO Value | Optimization |
|--------|---------------|--------------|
| **Headline** | Highest—indexed, appears in search snippets | Customize beyond job title; include keyword + audience + value |
| **About** | High—indexed; citable for AI | Write in answer-first format; include proof points, external links |
| **Featured** | Medium—showcases key links on public profile | Add site URL, case studies, press, portfolio |
| **Experience (media)** | Low-medium—media attachments are indexed | Add relevant documents, links, images to each role |
| **Skills & Endorsements** | Low—indexed but thin signal | Include relevant skills; endorsements add social proof |
| **Articles** | High—indexed and rankable | Publish long-form content with keywords and data |
| **Custom URL** | Indirect—clean URL improves shareability | Set to firstnamelastname or similar |

For the full profile module inventory, see [LinkedIn help: Add sections to your profile](https://www.linkedin.com/help/linkedin/answer/a540837).

## Character Limits

| Type | Limit | Notes |
|------|-------|-------|
| **Post** | 3,000 characters | Optimal: 1,300–1,600 |
| **First line (critical)** | 210–235 chars | Visible before "See more"; 60–80% decide here |
| **Short posts** | 100–200 chars | Polls, announcements, quotes |

## Optimal Length by Content Type

| Type | Characters | Use |
|------|------------|-----|
| **Short** | 100–200 | Polls, announcements, quotes |
| **Medium** | 300–1,200 | Case studies, tips, BTS |
| **Long** | 1,200–2,000 | Thought leadership, analysis |
| **Sweet spot** | 1,300–1,600 | Highest engagement |
| **Avoid** | >2,000 | ~35% engagement drop |

## First Line (Hook)

- **Place key message in first 140 chars**
- **Strong openings**: Specific results, pain points, bold claims, surprising stats
- **Avoid**: Vague teases, hashtag-first, generic greetings

## Image Specs (for Design Agents)

| Format | Dimensions | Use |
|--------|------------|-----|
| **Single image** | 1200×627 (1.91:1) | Feed; link previews |
| **Square** | 1200×1200 | Single image |
| **Carousel (organic)** | Up to 20 images | Multi-image post |
| **File** | ≤10 MB; JPG/PNG | Native uploads perform better |
| **Vertical** | Preferred | 88% browse on mobile |

## Best Practices

- **Mobile-first**: 88% users on mobile
- **Polls and document (PDF) posts**: Often strong for reach; pair with a clear takeaway
- **Post frequency**: Weekly minimum is a common bar for company pages; individuals often **several times per week** if sustainable
- **Alt text**: Add for accessibility
- **B2B tone**: Professional and constructive; see **influencer-marketing** and **about-page-generator** for voice alignment with profile/brand

## Output Format

When generating LinkedIn copy, provide:

1. **First line** (≤210 chars; hook)
2. **Full post** with character count
3. **Hashtags** (a few, relevant; end of post)
4. **Image specs** (if design agent needs dimensions)
5. **Form note** if not a plain post (e.g. “pair with a 5-slide document” or “use Article for 1,200+ words”)

## Related Skills

- **linkedin-ads**: Paid promotion; same professional tone as organic
- **open-graph**: Link share previews (Facebook, LinkedIn, etc.)
- **entity-seo**: People/org **sameAs** and entity consistency
- **generative-engine-optimization**: AI search / answer visibility (cross-platform; not only LinkedIn)
- **influencer-marketing**: LinkedIn influencers for B2B
- **about-page-generator**: Professional brand alignment
- **visual-content**: Cross-channel visual planning; LinkedIn image specs in context

## Official references (index)

- [Get started with posting](https://www.linkedin.com/help/linkedin/answer/a518996) · [Feed ranking (help)](https://www.linkedin.com/help/linkedin/answer/a9554004) · [Share photos](https://www.linkedin.com/help/linkedin/answer/a527229) · [Share videos](https://www.linkedin.com/help/linkedin/answer/a7174587)

## House format — Tertiary Infotech blog/course shares (added 2026-07-28)

Every LinkedIn share of a blog post or course MUST be **in-depth, not a teaser**:

1. **Hook line**: 🚀 + the article/course title.
2. **Excerpt**: the post's own excerpt (≤300 chars).
3. **Outline block**: "🔍 Inside the full guide:" followed by ▪-bulleted points
   taken from the article's OWN h2/h3 headings (max 6) — this is what makes the
   post read as analysis rather than an ad. Fall back to opening-paragraph
   sentences when the article has no headings.
4. **Funding line** (WSQ/TGS- courses only): 💰 up to 70% SkillsFuture funding +
   SkillsFuture Credit claimable.
5. **Two links, always**: 📖 the full blog analysis AND 👉 the specific course
   registration deep link (never the bare domain).
6. **Hashtags** at the end: funding staples (#WSQ #SkillsFuture
   #SkillsFutureCredit) + the post's own tags, ≤6 total.
7. **Attach the hero image** — image posts follow the newsletter's proven 3-step
   flow (initializeUpload → PUT binary → reference URN). The binary PUT MUST send
   `Content-Type: image/png` or LinkedIn returns HTTP 400.

### CRITICAL — LinkedIn "little text" escaping

The `/rest/posts` `commentary` field treats `( ) { } [ ] < > * _ ~ | @ \` as
markup. Unescaped, LinkedIn **silently truncates the post at the first reserved
char** (real incident 2026-07-28: everything after "(up to 70% subsidy" vanished,
including the course link and hashtags). Backslash-escape all of them; leave `#`
unescaped so hashtags keep working. Implementation:
`MMD_Blog_Helper_Linkedin::escapeLittleText()`.

### Verified live example (2026-07-28, post urn:li:share:7487766319459856387)

This exact output shipped and rendered correctly on LinkedIn (image attached,
nothing truncated) — use it as the reference shape:

```
🚀 Automating Digital Marketing with Claude Cowork and Higgsfield MCP

How we wired Claude Cowork agents and Higgsfield MCP into a self-running
digital marketing pipeline — research, copy, video creative, approval and
posting on autopilot.

🔍 Inside the full guide:
▪ Why agentic marketing \(and why now\)
▪ The Claude Cowork agent team architecture
▪ Wiring Higgsfield MCP for video creative
▪ Human-in-the-loop approval flows
▪ Measuring ROI: impressions to registrations

💰 Up to 70% SkillsFuture funding — WSQ course, SkillsFuture Credit claimable
📖 Full analysis: https://www.tertiarycourses.com.sg/blog/<url_key>
👉 Register for the hands-on course: https://www.tertiarycourses.com.sg/<course_url_key>.html

#WSQ #SkillsFuture #SkillsFutureCredit
```

Note the `\(...\)` — that is the little-text escaping as sent over the API;
LinkedIn renders it as plain parentheses.

### Implementation pointers (this repo)

- Copy builder: `_linkedinCommentary()` + `_contentOutline()` in
  `app/code/local/MMD/Blog/Model/Cron/Autoblog.php`
- Escaping + image upload: `app/code/local/MMD/Blog/Helper/Linkedin.php`
  (`escapeLittleText()`, `_uploadImage()` — PUT must send `Content-Type: image/png`)
- Newsletter equivalent: `app/code/local/MMD/Marketing/Helper/Linkedin.php`
  (`postFlyer()` / `_defaultCommentary()`) — NO escaping there; its copy must
  keep avoiding reserved chars, or port `escapeLittleText()` over.
- Shared credential: `mmd_marketing/linkedin/*` — a 60-day member token with no
  auto-refresh; renewal playbook lives in the project memory
  (`feedback_linkedin_token_expiry_renewal_playbook`).

## PUBLISHING an existing blog post to LinkedIn (verified 2026-08-01)

**Never hand-write the copy for a blog share.** The pipeline's own
`_linkedinCommentary()` already implements the house format above — hook,
excerpt, heading-derived outline, SKU-gated funding line, dual links, hashtags —
and routes through `escapeLittleText()`. Hand-written copy re-introduces the
truncation bug and drifts from the format. Build the copy with the pipeline;
your job is to choose WHICH posts and to verify before sending.

### The rule that matters

Publishing is **public and irreversible** — a LinkedIn post cannot be edited to
add an image afterwards, and deleting one loses its engagement. So:

1. **EVERY POST SHIPS WITH AN IMAGE. No exceptions.** See the blocking rule
   below — generate the hero *before* sharing, never publish text-only.
2. **Preview the exact commentary before sending** (script below). Read it.
3. **Confirm scope with the user when `shareEverywhere()` would over-share** —
   it posts to LinkedIn *and* Facebook in one pass. If the user said "LinkedIn",
   call the LinkedIn branch only (recipe below), or Facebook goes out
   unrequested and cannot be recalled.
4. **Verify every CTA URL returns 200** on its own store domain first.
5. **Check `linkedin_urn` is empty** — non-empty means already shared; posting
   again double-posts. Always write the URN back after a successful share so the
   publish cron and admin re-saves stay no-ops.

### 🚨 BLOCKING: never publish a LinkedIn post without an image

`share()` accepts `$imageUrl` and **silently degrades to a text+link post** when
it is empty — no error, no warning. Posts inserted by migration (every
hand-written blog post) have `hero_image_url = NULL`, so they ship image-less
unless you generate one first. Image posts get materially better reach, and
**this is unfixable after publishing** — LinkedIn cannot add an image to a live
post.

**If `hero_image_url` is empty, generate it BEFORE calling `share()`:**

```php
if (!$p->getHeroImageUrl()) {
    $hero = Mage::helper('mmd_blog/image')->generateHero(
        $p->getTitle(),
        (string) $p->getSourceSku()      // TGS- adds the WSQ + SkillsFuture chips
    );
    if ($hero === '') {
        // Renderer AND local fallback both failed — STOP. Do not publish
        // text-only; fix the image path first.
        throw new Exception('hero generation failed — not publishing');
    }
    $p->setHeroImageUrl($hero)->save();  // persist so the blog page gets it too
}
// only now:
$r = $li->share($commentary, $url, $p->getHeroImageUrl());
```

`generateHero()` renders the title through the branded CourseImage GD cover and
uploads to R2 under `blog/auto-*` (that prefix marks it pipeline-replaceable; an
admin-uploaded hero has no prefix and must never be overwritten). It falls back
to local `media/blog/` if R2 is down, and returns `''` only if both failed.

Verify the URL returns HTTP 200 before sharing — a 404 hero makes
`_uploadImage()` throw, and `share()` catches that and quietly posts text-only,
which is the exact failure this rule exists to prevent.

**Enforced by a hook.** `.claude/hooks/linkedin-share-gate.sh` (PreToolUse /
Bash) blocks any command containing `->share(`, `shareEverywhere(`, `postFlyer(`
or a `/rest/posts` POST unless the same command also references the hero image
AND guards on it. Previews and read-only GET probes pass through. If it blocks
you, add the gate — do not work around it.

**Incident 2026-08-01:** the UTAP and n8n posts were published with
`hero=(none)`. The gap was noticed pre-flight but treated as a note rather than
a blocker, and both went out text-only. Confirmed unfixable in place — a
`PARTIAL_UPDATE` adding `content.media` returns **HTTP 422 "CreateOnly field
present in a partial_update request"**. Both had to be deleted and reposted,
losing their original URNs and engagement.

### Working recipe (SG prod)

Find the web container fresh each time — deploys rename it:

```bash
ssh root@76.13.180.29 'for c in $(docker ps -q); do docker exec $c test -f /var/www/html/app/Mage.php 2>/dev/null && docker ps --format "{{.Names}}" -f id=$c; done'
```

Pipe a PHP script in: `ssh sg "docker exec -i <web> php" < script.php`.
`_linkedinCommentary()` is private — reach it with Reflection:

```php
$m = new ReflectionMethod('MMD_Blog_Model_Cron_Autoblog','_linkedinCommentary');
$m->setAccessible(true);
$model = Mage::getModel('mmd_blog/cron_autoblog');
$h = Mage::helper('mmd_blog');
$p = Mage::getModel('mmd_blog/post')->getCollection()
       ->addFieldToFilter('url_key', $slug)->getFirstItem();
$url = $h->getPostUrl($p);
echo $m->invoke($model, $p, $url);          // PREVIEW first — do not send blind
```

**LinkedIn-only share** (skips Facebook, keeps the dedup contract):

```php
$li = Mage::helper('mmd_blog/linkedin');
if ($p->getLinkedinUrn())     { /* already shared — stop */ }
if ((int)$p->getStatus() !== 1) { /* not published — stop */ }
$r = $li->share($m->invoke($model,$p,$url), $url, $p->getHeroImageUrl() ?: null);
$p->setLinkedinUrn($r['externalId'])->save();   // dedup marker — never skip
```

Use `shareEverywhere($post)` instead only when BOTH networks are wanted.

### Pre-flight checklist

- [ ] **`hero_image_url` set and returning HTTP 200 — generate it if empty.
      This is a BLOCKER, not a nice-to-have. Never publish text-only.**
- [ ] Post `status = 1` (published) and reachable at its public URL
- [ ] `linkedin_urn` empty (not already shared)
- [ ] `linkedin_enabled = 1` and `Mage::helper('mmd_blog/linkedin')->isConfigured()`
- [ ] Commentary previewed and read; length 1,000–1,600 chars
- [ ] Every link in the commentary returns HTTP 200
- [ ] Facebook scope confirmed with the user
- [ ] After: re-read the post row and confirm the URN persisted, and eyeball the
      live post to confirm the image actually rendered

### A published LinkedIn post CANNOT be edited to add an image

There is no API or UI path to attach media to a live post — `/rest/posts` allows
editing `commentary`, but the `content` (media) block is fixed at creation. The
only ways to get an image onto an already-published share are:

1. **Delete and repost** — loses all reactions, comments and reshares, and
   burns the original URN. Only worth it within minutes of posting, and only
   with the user's explicit go-ahead.
2. **Leave it and fix forward** — keep the text post, make sure the *next* one
   has its hero.

Never silently delete-and-repost to "fix" a missing image; the engagement loss
is the user's call, not yours. Ask first.
