# Use text collations for case-sensitive schedule-code regular expressions

Use `CONVERT(title USING utf8mb4) COLLATE utf8mb4_bin REGEXP 'pattern'` when a
query must work on both MySQL 5.7 and MySQL 8. Do not use `REGEXP BINARY`:
MySQL 8 rejects its binary-string operand with error 3995.

On 25 November 2026, the schedule list passed the isolated MySQL 5.7 fixture
but failed while rendering against the live database. The failure was in
`MMD_Adminhtml_Block_Customoptions_Options_Grid::durationCodeSql()`; it was
not a missing role. A binary *text collation* preserves uppercase A-E code
matching without passing a binary string to the MySQL 8 regexp engine.

Validate the real read query against each supported server version, including
uppercase/lowercase, embedded codes and unclassified titles. Keep live checks
inside read-only transactions. See `scripts/tests/schedule-page-rendering.php`
and `app/code/local/MMD/Adminhtml/Block/Customoptions/Options/Grid.php`.
