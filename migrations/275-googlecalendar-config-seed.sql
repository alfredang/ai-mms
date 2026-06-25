-- 275: Seed empty core_config_data rows for Google Calendar OAuth credentials.
--      Values must be filled by a developer/DBA before the GCal sync feature is live.
--      INSERT IGNORE so re-running never overwrites credentials already set.
INSERT IGNORE INTO `core_config_data` (`scope`, `scope_id`, `path`, `value`) VALUES
  ('default', 0, 'mmd_googlecalendar/oauth/client_id',      ''),
  ('default', 0, 'mmd_googlecalendar/oauth/client_secret',  ''),
  ('default', 0, 'mmd_googlecalendar/oauth/refresh_token',  ''),
  ('default', 0, 'mmd_googlecalendar/calendar/calendar_id', '');
