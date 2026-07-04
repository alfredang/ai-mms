#!/usr/bin/env bash
# Verify the agentic-flyer newsletter pipeline is intact after an edit.
# Fires from Claude Code's PostToolUse hook after edits to:
#   - app/code/local/MMD/Marketing/Helper/Flyer.php        (the flyer renderer)
#   - app/code/local/MMD/Marketing/Helper/Mailerlite.php   (create/schedule)
#   - app/code/local/MMD/Marketing/Helper/Blastguard.php   (the 2/week caps)
#   - app/design/adminhtml/default/default/template/marketing/templates/*
#
# Guards HARD RULE #1 (max 2 designs/blasts per week) by echoing the current
# week's headroom, and confirms the flyer still renders a real (non-empty,
# marker-complete) design so a broken edit can't silently ship an empty blast.
#
# Never blocks the Claude turn (always exit 0); failures print to stderr AND
# raise a Critical admin notification so operators see it too.

set -u
CONTAINER="ai-mms-web-1"
NOTIFY_TITLE="Agentic newsletter flyer broken"

notify_fail() {
  local msg="$1"
  docker exec "$CONTAINER" php -r "
    require_once '/var/www/html/app/Mage.php';
    Mage::app('admin');
    \$res = Mage::getSingleton('core/resource');
    \$w = \$res->getConnection('core_write');
    \$t = \$res->getTableName('adminnotification/inbox');
    \$w->delete(\$t, ['severity = ?' => 1, 'title = ?' => '$NOTIFY_TITLE', 'is_read = ?' => 0]);
    Mage::getModel('adminnotification/inbox')->addCritical('$NOTIFY_TITLE', '$(printf '%s' "$msg" | sed "s/'/\\\\'/g")', '');
  " >/dev/null 2>&1
  echo "[verify-newsletter-flyer] FAIL: $msg" >&2
  exit 0
}

notify_ok() {
  docker exec "$CONTAINER" php -r "
    require_once '/var/www/html/app/Mage.php';
    Mage::app('admin');
    \$res = Mage::getSingleton('core/resource');
    \$w = \$res->getConnection('core_write');
    \$t = \$res->getTableName('adminnotification/inbox');
    \$w->delete(\$t, ['severity = ?' => 1, 'title = ?' => '$NOTIFY_TITLE', 'is_read = ?' => 0]);
  " >/dev/null 2>&1
}

# 0. Container reachable?
docker exec "$CONTAINER" true 2>/dev/null \
  || { echo "[verify-newsletter-flyer] skip: container $CONTAINER not running"; exit 0; }

# 1. Lint the marketing helpers.
for f in \
  app/code/local/MMD/Marketing/Helper/Flyer.php \
  app/code/local/MMD/Marketing/Helper/Mailerlite.php \
  app/code/local/MMD/Marketing/Helper/Blastguard.php \
  app/code/local/MMD/Marketing/Model/Cron/Flyer.php ; do
  [ -f "$f" ] || continue
  docker exec "$CONTAINER" php -l "/var/www/html/$f" >/dev/null 2>&1 \
    || notify_fail "php -l failed on $f — the newsletter pipeline has a syntax error."
done

# 2. Render a real flyer + report cap headroom. Asserts the fragment is a
#    complete design (CTA + QR + funding footer), not an empty/placeholder body.
OUT=$(docker exec "$CONTAINER" php -r "
  require_once '/var/www/html/app/Mage.php';
  Mage::app();
  \$conn = Mage::getSingleton('core/resource')->getConnection('core_read');
  \$pid = (int)\$conn->fetchOne('SELECT entity_id FROM catalog_product_entity WHERE sku LIKE \"TGS-%\" LIMIT 1');
  if (!\$pid) { \$pid = (int)\$conn->fetchOne('SELECT entity_id FROM catalog_product_entity ORDER BY entity_id DESC LIMIT 1'); }
  \$html = Mage::helper('mmd_marketing/flyer')->render(\$pid);
  \$ok = strlen(\$html) > 3000
        && strpos(\$html, 'Register now') !== false
        && strpos(\$html, 'newsletter-review/index/qr') !== false
        && strpos(\$html, '{\$unsubscribe}') !== false; // HARD RULE: MailerLite unsubscribe footer in every design
  \$g = Mage::helper('mmd_marketing/blastguard');
  echo (\$ok ? 'FLYER_OK' : 'FLYER_BAD') . ' bytes=' . strlen(\$html)
     . ' designs=' . \$g->designsThisWeek() . '/2'
     . ' blasts='  . \$g->blastsThisWeek()  . '/2'
     . ' enabled=' . (\$g->isEnabled() ? 'yes' : 'no');
" 2>/dev/null)

case "$OUT" in
  FLYER_OK*)
    notify_ok
    echo "[verify-newsletter-flyer] OK — $OUT" >&2
    ;;
  FLYER_BAD*)
    notify_fail "Flyer render is empty/incomplete ($OUT) — Helper/Flyer::render() lost its CTA/QR/markers."
    ;;
  *)
    notify_fail "Flyer render threw a fatal — check var/log for the trace."
    ;;
esac
exit 0
