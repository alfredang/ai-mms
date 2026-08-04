-- 886: Correct the certificate wording written by migration 885.
--
-- 885 shipped twice: the first deploy carried the old copy and recorded 885
-- in the ledger, so the corrected 885 can never re-run on an instance that
-- already applied it (feedback_edited_shared_migrations_never_rerun_on_prod).
-- This file does the rename as a data-only fix.
--
--   "Certificate of Completion from Tertiary Courses"
--     -> "Certificate of Achievement from Tertiary Infotech Academy Pte Ltd"
--
-- SG scope only: restricted to the per-course certification blocks whose
-- content 885 generated (matched by the <ul class="cert-bullets"> wrapper).
-- The M-prefix partner blocks use their own "Tertiary Infotech" wording and
-- free-text phrasing and are deliberately NOT touched.
--
-- Literals are hex-encoded so apply.php-s utf8 PDO connection cannot trip
-- error 1366 (feedback_migration_applyphp_utf8_outage).
-- Idempotent: REPLACE on an already-corrected row is a no-op.

UPDATE cms_block
   SET content = REPLACE(content, 0x4365727469666963617465206f6620436f6d706c6574696f6e2066726f6d20546572746961727920436f7572736573, 0x4365727469666963617465206f6620416368696576656d656e742066726f6d20546572746961727920496e666f746563682041636164656d7920507465204c7464),
       update_time = NOW()
 WHERE identifier LIKE 0x636f757273655c5f255c5f63657274696669636174696f6e
   AND content LIKE 0x25636572742d62756c6c65747325
   AND content LIKE 0x254365727469666963617465206f6620436f6d706c6574696f6e2066726f6d20546572746961727920436f757273657325;
