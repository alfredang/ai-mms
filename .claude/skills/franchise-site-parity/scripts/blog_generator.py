#!/usr/bin/env python3
"""Replace a partner blog with partner-relevant posts that funnel to PARTNER courses.
Deletes cloned SG posts, inserts new ones. PARTNER-DB-ONLY. Table: mmd_blog_post.

Edit POSTS below (or load from JSON). Funnel links use {{store direct_url='<url_key>.html'}}
which resolves to the PARTNER domain. NEVER reference WSQ/SkillsFuture/Singapore.
Hero images: any R2 URL. Also hide the hardcoded blog funding CTA via remove_funding.sql (§6).
Output: blog.sql  (apply; then flush).
"""
import sys
W = sys.argv[1] if len(sys.argv) > 1 else "/tmp/parity"
AUTHOR = "Tertiary Courses <Country>"
R2 = "https://pub-77c0dec029944b0386e40673ce81081f.r2.dev"
# each: title,url_key,excerpt,body(HTML),hero,related_skus,pub(YYYY-MM-DD),meta_title,meta_desc,meta_kw
POSTS = [
    dict(title="Example AI news headline", url_key="example-ai-post",
         excerpt="One-line hook.", hero=f"{R2}/catalog/category/artificial-intelligence-courses_1.jpg",
         skus="C037,C057", pub="2026-04-24",
         mt="SEO title | AI Courses in <Country>", md="SEO meta description.", mk="ai, <country>, ai courses",
         body="<p>Original summary of the news, cite the source.</p>"
              "<p><a href=\"{{store direct_url='artificial-intelligence-courses.html'}}\"><strong>Explore our AI courses &rarr;</strong></a></p>"),
]
esc = lambda s: s.replace("\\", "\\\\").replace("'", "''")
L = ["DELETE FROM mmd_blog_post_vote;", "DELETE FROM mmd_blog_post_tag;", "DELETE FROM mmd_blog_post;"]
cols = "(title,url_key,excerpt,content,hero_image_url,author,status,published_at,related_skus,meta_title,meta_description,meta_keywords,created_at,updated_at)"
for p in POSTS:
    v = (f"('{esc(p['title'])}','{esc(p['url_key'])}','{esc(p['excerpt'])}','{esc(p['body'])}',"
         f"'{esc(p['hero'])}','{esc(AUTHOR)}',1,'{p['pub']} 09:00:00','{esc(p['skus'])}',"
         f"'{esc(p['mt'])}','{esc(p['md'])}','{esc(p['mk'])}',NOW(),NOW())")
    L.append(f"INSERT INTO mmd_blog_post {cols} VALUES {v};")
open(f"{W}/blog.sql", "w").write("\n".join(L) + "\n")
print(f"wrote blog.sql with {len(POSTS)} posts")
