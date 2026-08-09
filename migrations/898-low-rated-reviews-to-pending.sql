-- 898: Send low-rated reviews back to moderation (2026-08).
--
-- Any APPROVED product review whose average vote across its rating questions
-- is 2.00 or below is flipped to PENDING (status_id 2) so it drops off the
-- live storefront and an admin re-reads it before it can go public again.
--
-- Why average and not per-question: a review carries one vote per active
-- rating question ("meets expectation", "trainer knowledgeable", "training
-- environment") — 3 votes for virtually every row. The learner-visible score
-- is the mean of those, so the mean is what the threshold must be applied to.
-- AVG(value) <= 2 catches 1.00 / 1.33 / 1.67 / 2.00 and leaves 2.33 alone.
--
-- Scope notes:
--   * Only status_id = 1 rows are touched. Already-pending / not-approved
--     rows are left as they are — this is a demotion, never a promotion.
--   * Reviews with NO votes at all are NOT touched (10 such rows locally):
--     an absent score is not a low score, and demoting them would hide
--     comment-only reviews for no stated reason.
--   * Featured testimonials (migration 897) all sit at 5.00, so none are
--     affected. The homepage strip and /testimonials are untouched.
--
-- Partner safety: `review` / `rating_option_vote` exist on every site and the
-- statement is data-only with no SKU or store literals, so SG/MY/GH each
-- demote their own low-rated rows and nothing cross-site is assumed.
--
-- Idempotent: re-running matches only rows still at status_id = 1, so a
-- second run demotes nothing further. Deliberately NOT reversible in SQL —
-- re-approval is the admin's manual decision in the All Reviews grid.

UPDATE review r
JOIN (
    SELECT v.review_id
    FROM rating_option_vote v
    GROUP BY v.review_id
    HAVING AVG(v.value) <= 2
) low ON low.review_id = r.review_id
SET r.status_id = 2
WHERE r.status_id = 1;
