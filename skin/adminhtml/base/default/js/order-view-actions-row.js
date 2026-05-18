/*
 * Backward-compatibility shim.
 *
 * This file was kept because some layout update / cached head block still
 * references js/order-view-actions-row.js under adminhtml base/default.
 *
 * The functionality has been migrated to js/admin-actions-row.js.
 */
(function () {
  if (window.AdminActionsRowLoaded) return;
  window.AdminActionsRowLoaded = true;
})();
