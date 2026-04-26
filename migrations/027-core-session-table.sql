-- Make sure the core_session table exists before Magento tries to read/write
-- sessions to it. Magento auto-creates this table on first request, but if a
-- user is already logged in when the deploy lands, that auto-create can race
-- with their next request and produce a fatal "table doesn't exist" error.
--
-- Paired with <session_save>db</session_save> in app/etc/local.xml — sessions
-- now live in MySQL instead of /var/www/html/var/session/, so they survive
-- Coolify deploys (which replace the container's filesystem on every push).
CREATE TABLE IF NOT EXISTS core_session (
    session_id      VARCHAR(255) NOT NULL,
    session_expires INT UNSIGNED NOT NULL DEFAULT 0,
    session_data    MEDIUMBLOB   NOT NULL,
    PRIMARY KEY (session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Database sessions storage';
