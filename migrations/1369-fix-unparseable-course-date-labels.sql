-- Repair Course Date labels the date parser cannot read.
--
-- These were written by the schedule generator before the pairLabel() fix:
--   * "0/1 Apr 2027"        - day-of-month arithmetic underflowed to 0
--   * "28 Sep - 1 Oct 2026" - cross-month hyphen range, not in the parser grammar
--   * "31 Dec 2026/1 Jan 2027" - an earlier hand-repair, also unparseable
--
-- Each replacement was verified two ways: it round-trips back to the intended
-- dates, AND the weekday names it carries match the real calendar. One row was
-- REMOVED from this migration because it failed the second check:
--   "28 Nov - 01 Dec 2026 (Sun-Tue)" on TGS-2023037829 - 28 Nov 2026 is a
--   Saturday, so either the date or the weekday is wrong and it is not for a
--   script to decide which. Nobody is booked on it. Left for a human.
-- Targeted by option_type_id and guarded on the exact old title, so a re-run
-- or a row already corrected by hand is a no-op.

UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 472935 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- TGS-2023036004 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 472960 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- TGS-2024047021 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 472966 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- TGS-2023039177 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 472972 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C1202 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 472978 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C1228 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 472996 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C841 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 473002 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C504 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 473052 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C722 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 473058 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C542 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 473070 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C1101 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 473088 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C810 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 473112 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C1747 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473831 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- TGS-2024043392 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473837 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- TGS-2024048318 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473843 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- TGS-2024049211 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473849 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1055 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473855 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1246 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473867 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C578 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473891 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1186 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473903 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C584 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473909 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1287 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473921 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1048 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473933 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C371 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473945 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1391 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473963 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C483 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 473975 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C855 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 474005 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1755 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 474011 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1760 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 476111 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- TGS-2024049214 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 476247 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C481 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 484144 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- TGS-2025053212 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 484184 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- TGS-2023039179 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 484339 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- TGS-2026062147 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '31 Oct 2026 - 3 Nov 2026 (Sat-Tue)'
 WHERE option_type_id = 490785 AND store_id = 0 AND title = '31 Oct - 03 Nov 2026 (Sat-Tue)';   -- TGS-2024045221 -> 2026-10-31..2026-11-03
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 492694 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- TGS-2025055775 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 493438 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- TGS-2023040474 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 494136 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C991 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 494510 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C711 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 2 Oct 2026 (Mon-Fri)'
 WHERE option_type_id = 495144 AND store_id = 0 AND title = '28 Sep - 2 Oct 2026 (Mon-Fri)';   -- C1543 -> 2026-09-28..2026-10-02
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495567 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C425 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495578 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C193 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495589 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C638 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495600 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C10 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495611 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C917 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495622 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C918 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495633 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C928 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495644 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C998 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495655 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C1176 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495677 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C976 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495688 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C204 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495699 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C802 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495710 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C603 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495721 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C625 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495732 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C1298 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495743 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C1318 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495754 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C1367 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495765 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C1416 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495776 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C605 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 495788 AND store_id = 0 AND title = '31 Dec 2026/1 Jan 2027 Evening (Thu/Fri)';   -- C015 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499683 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- TGS-2026064474 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499694 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- TGS-2026064719 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499705 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- TGS-2025056191 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499716 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C425 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499717 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C193 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499718 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C638 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499719 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C10 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499720 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C917 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499721 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C918 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499722 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C928 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499723 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C998 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499724 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C1176 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499726 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C976 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499727 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C204 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499728 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C802 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499729 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C603 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499730 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C625 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499731 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C1298 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499732 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C1318 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499733 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C1367 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499734 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C1416 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499735 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C605 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '31 Dec 2026 - 1 Jan 2027 Evening (Thu/Fri)'
 WHERE option_type_id = 499736 AND store_id = 0 AND title = '0/1 Jan 2027 Evening (Thu/Fri)';   -- C015 -> 2026-12-31..2027-01-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504174 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2023036004 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504191 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2024045221 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504198 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2024047021 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504205 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2023039177 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504212 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2025053212 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504219 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2023039179 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 504222 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- TGS-2025059028 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504230 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2025059028 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504237 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2026062147 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504244 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- TGS-2025055775 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504251 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C1202 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504258 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C1228 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '28 Sep 2026 - 1 Oct 2026 (Mon-Thu)'
 WHERE option_type_id = 504263 AND store_id = 0 AND title = '28 Sep - 1 Oct 2026 (Mon-Thu)';   -- C1406 -> 2026-09-28..2026-10-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504271 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C1406 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504278 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C841 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504285 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C504 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504334 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C722 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504341 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C542 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504355 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C1101 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504369 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C810 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504397 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C1747 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504411 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C481 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504425 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C991 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 1 Apr 2027 (Mon-Thu)'
 WHERE option_type_id = 504432 AND store_id = 0 AND title = '29 Mar - 1 Apr 2027 (Mon-Thu)';   -- C711 -> 2027-03-29..2027-04-01
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505152 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- TGS-2024043392 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505160 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- TGS-2024048318 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505167 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- TGS-2024049211 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505174 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- TGS-2024049214 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505181 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1055 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505188 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1246 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505202 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C578 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505230 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1186 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505244 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C584 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505251 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1287 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505265 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1048 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505279 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C371 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505293 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1391 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505314 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C483 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505328 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C855 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505363 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1755 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505370 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1760 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505377 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- TGS-2023040474 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '29 Mar 2027 - 2 Apr 2027 (Mon-Fri)'
 WHERE option_type_id = 505384 AND store_id = 0 AND title = '29 Mar - 2 Apr 2027 (Mon-Fri)';   -- C1543 -> 2027-03-29..2027-04-02
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506844 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- TGS-2026064711 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506849 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- TGS-2026064181 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506854 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- TGS-2020505317 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506859 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- TGS-2025053923 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506864 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C239 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506869 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C325 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506879 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C205 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506884 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C513 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506889 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C384 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506894 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C778 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506899 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C808 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506904 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C825 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506909 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C839 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506914 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C897 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506919 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C1231 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506929 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C134 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506934 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C201 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506994 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C235 -> 2027-03-31..2027-04-01
UPDATE catalog_product_option_type_title SET title = '31 Mar / 1 Apr 2027 Evening (Wed/Thu)'
 WHERE option_type_id = 506999 AND store_id = 0 AND title = '0/1 Apr 2027 Evening (Wed/Thu)';   -- C911 -> 2027-03-31..2027-04-01
