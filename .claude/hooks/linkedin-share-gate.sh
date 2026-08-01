#!/usr/bin/env bash
# PreToolUse hook (Bash matcher): blocks a LinkedIn share that could go out
# WITHOUT an image.
#
# Why this exists (incident 2026-08-01): two blog posts were shared to LinkedIn
# with hero_image_url empty. MMD_Blog_Helper_Linkedin::share() takes the image
# as an OPTIONAL third arg and silently degrades to a text+link post when it is
# missing — no error, no warning. Both posts shipped image-less and had to be
# manually deleted and reposted, because LinkedIn's /rest/posts API rejects
# adding media to a live post (HTTP 422, "CreateOnly field present in a
# partial_update request"). Media is fixed at creation: there is NO edit path.
#
# The gate: any command that publishes to LinkedIn must also show evidence that
# it checks/attaches an image. We look for the share call, then require an
# image-related guard in the SAME command.
set -u
CMD="$(cat | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$CMD" ] && exit 0

# Does this command publish to LinkedIn?
#   ->share(...)          MMD_Blog_Helper_Linkedin / Marketing Helper
#   shareEverywhere(...)  blog pipeline (LinkedIn + Facebook)
#   postFlyer(...)        newsletter pipeline
#   /rest/posts           raw API call
echo "$CMD" | grep -qE '\->share\(|shareEverywhere\(|postFlyer\(|/rest/posts' || exit 0

# Reading/previewing is fine — only gate things that actually POST.
# A pure GET probe against /rest/posts is not a publish.
if echo "$CMD" | grep -q '/rest/posts' && ! echo "$CMD" | grep -qE '\->share\(|shareEverywhere\(|postFlyer\(|CUSTOMREQUEST.*POST|X-RestLi-Method'; then
  exit 0
fi

# Evidence that the command handles the image: it must reference a hero/image
# URL AND have some guard on it (generate, or refuse/skip when missing).
HAS_IMAGE_REF=0
echo "$CMD" | grep -qE 'HeroImageUrl|hero_image_url|generateHero|imageUrl|image_url' && HAS_IMAGE_REF=1

HAS_GUARD=0
echo "$CMD" | grep -qE 'generateHero|refus|continue;|throw new Exception|NO HERO|exit' && HAS_GUARD=1

if [ "$HAS_IMAGE_REF" -eq 1 ] && [ "$HAS_GUARD" -eq 1 ]; then
  echo "linkedin-share-gate: image handling present — share allowed." >&2
  exit 0
fi

cat >&2 <<'EOF'
LINKEDIN SHARE BLOCKED by .claude/hooks/linkedin-share-gate.sh.

This command publishes to LinkedIn but shows no image gate.

EVERY LinkedIn post must ship WITH an image. share() takes the image as an
OPTIONAL argument and SILENTLY posts text-only when it is missing — and a
published LinkedIn post can NEVER gain an image afterwards (the API returns
HTTP 422: media is a CreateOnly field). The only remedy is delete-and-repost,
which destroys the post's engagement.

Required in the publishing command:
  1. Read the hero:      $hero = $p->getHeroImageUrl();
  2. Generate if empty:  Mage::helper('mmd_blog/image')->generateHero(
                             $p->getTitle(), (string) $p->getSourceSku());
                         then ->setHeroImageUrl($hero)->save();
  3. REFUSE if still empty or if the URL is not HTTP 200 — do not post
     text-only. `continue;` / throw instead.
  4. Pass it:            $li->share($commentary, $url, $hero);

See the "BLOCKING: never publish a LinkedIn post without an image" section of
the linkedin-posts skill for the full recipe.
EOF
exit 2
