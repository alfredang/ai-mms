-- Drop tpg_run_id_map.
--
-- The TPG (Training Provider Gateway) feature has been removed in its
-- entirety: sidebar groups, sub-page UIs (~5500 lines in dashboard
-- index.phtml), and all controller actions that backed those pages
-- (createClass, enrollLearner, runLookup, sessionAttendance, etc.).
-- The mapping table is now orphaned — drop it.
--
-- Site is going worldwide and the TPG concept (an integration with the
-- regional Training Provider Gateway) is no longer in scope.
--
-- Idempotent: DROP TABLE IF EXISTS is naturally re-runnable.

DROP TABLE IF EXISTS `tpg_run_id_map`;
