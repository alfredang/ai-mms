<?php

/**
 * MMD_CourseImage general helper.
 *
 * Reads R2 credentials from the environment (loaded into Apache by Docker /
 * Coolify). The .env in this repo defines R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY,
 * R2_ENDPOINT, R2_BUCKET, R2_PUBLIC_URL — those are the only ones the cover
 * renderer + uploader use.
 */
class MMD_CourseImage_Helper_Data extends Mage_Core_Helper_Abstract
{
    public const ASSET_DIR = 'app/code/local/MMD/CourseImage/assets';

    public function getModuleBase(): string
    {
        return Mage::getBaseDir() . DIRECTORY_SEPARATOR . self::ASSET_DIR;
    }

    public function getFontPath(): string
    {
        // Inter Bold — modern, neutral, professional. Used for the title and
        // the brand wordmark. Replaced DejaVu Sans Bold which read too generic.
        return $this->getModuleBase() . DIRECTORY_SEPARATOR . 'Inter-Bold.ttf';
    }

    public function getSemiBoldFontPath(): string
    {
        // Inter SemiBold — used for kickers and chip labels where Bold would
        // shout too loud against the dark gradient.
        return $this->getModuleBase() . DIRECTORY_SEPARATOR . 'Inter-SemiBold.ttf';
    }

    public function getTertiaryLogoPath(): string
    {
        // The "T mark" — circular blue badge only, no wordmark. The wordmark
        // is drawn in code (white "Tertiary Infotech Academy") so it can be
        // tuned for the dark-gradient background.
        return $this->getModuleBase() . DIRECTORY_SEPARATOR . 'tertiary-mark.png';
    }

    public function getWsqLogoPath(): string
    {
        return $this->getModuleBase() . DIRECTORY_SEPARATOR . 'wsq-logo.png';
    }

    /**
     * WSQ-funded course detection. Production SKU pattern is "TGS-..." for
     * SSG/WSQ-funded products — see commit f1439f014 (TGS-2024043854).
     */
    public function isWsqCourse(string $sku): bool
    {
        return stripos($sku, 'TGS-') === 0;
    }

    /**
     * Master list of badge labels the AI cover renderer + chip checkboxes
     * support. Order here drives the order admins see them in the UI.
     */
    public function getAllBadges(): array
    {
        return [
            'WSQ',
            'SkillsFuture Credit',
            'PSEA',
            'UTAP',
            'IBF',
            'HRDF',
            'SFEC',
            'Absentee Payroll',
            'MCES',
        ];
    }

    /**
     * Per-website default-checked badges. The cover renderer is country-
     * neutral, but admins want country-appropriate funding badges pre-ticked
     * so the common case is one-click. Map keyed by website code (see
     * Mage::app()->getWebsites()): base = Singapore, others
     * default to none so we don't show SG-only funding hooks in NG/GH/IN.
     */
    public function getDefaultBadgesForWebsite(string $websiteCode): array
    {
        $map = [
            'base'     => ['WSQ', 'MCES', 'UTAP'],
        ];
        return $map[$websiteCode] ?? [];
    }

    /**
     * Only Singapore ('base') has country-specific funding schemes
     * (SkillsFuture/WSQ/MCES/UTAP). Nigeria
     * share the same generated PNG via
     * course_image_url but must render WITHOUT the FUNDING AVAILABLE header
     * and chip row — those schemes don't exist in those markets and would
     * be misleading on the cover.
     */
    public function isFundingEligibleWebsite(string $websiteCode): bool
    {
        return $websiteCode === 'base';
    }

    /**
     * Resolve default badges for a product based on the website it lives in.
     * Falls back to the SG defaults for the legacy WSQ shortcut so existing
     * callers that key off the SKU still behave sensibly.
     */
    public function getDefaultBadgesForProduct(Mage_Catalog_Model_Product $product): array
    {
        $websiteIds = $product->getWebsiteIds() ?: [];
        // Prefer the first website Magento returns; admins editing a course
        // are typically scoped to one country at a time.
        $code = '';
        if ($websiteIds) {
            try {
                $code = (string) Mage::app()->getWebsite((int) reset($websiteIds))->getCode();
            } catch (Throwable $e) {
                $code = '';
            }
        }
        return $this->getDefaultBadgesForWebsite($code);
    }

    /**
     * Badges that are *legitimate* to surface on a given country's storefront.
     * Used as a per-website whitelist applied AFTER the product-tag fetch so
     * data leakage across stores (e.g. a tagged product showing HRDF on
     * its GH listing because the catalog is shared) never reaches the chip
     * renderer. Unknown website codes return the full vocabulary so any new
     * country we add starts permissive and tightens as we learn its rules.
     */
    public function getApplicableBadgesForWebsite(string $websiteCode): array
    {
        $map = [
            'base'     => ['WSQ', 'SkillsFuture Credit', 'PSEA', 'UTAP', 'IBF', 'SFEC', 'Absentee Payroll', 'MCES'],
            // Nigeria has no government funding
            // schemes we model — explicit empty list so HRDF/WSQ never bleed
            // through from a shared product.
            'nigeria'  => [],
        ];
        return array_key_exists($websiteCode, $map) ? $map[$websiteCode] : $this->getAllBadges();
    }

    /**
     * Return the canonical funding badges currently assigned to a product
     * via Magento's tag system, filtered to the controlled vocabulary in
     * getAllBadges() and ordered by that vocabulary (not by tag_id).
     *
     * Reads tag_relation joined to tag with status = APPROVED. Storefront
     * callers must filter by name whitelist so any non-canonical tag (e.g.
     * legacy "1"-"5" rating tags) never reaches the chip renderer.
     *
     * Further intersects with the current store's website-applicable list
     * (see getApplicableBadgesForWebsite) so country-irrelevant badges from
     * the shared catalog (HRDF on GH, WSQ on NG, etc.) never render. Admin
     * context — no resolvable frontend website — skips this filter so the
     * cover-dialog read path keeps showing all assigned tags.
     *
     * Returns an empty array on any error so the catalog page never fatals
     * because of a tag lookup.
     */
    public function getProductBadges(Mage_Catalog_Model_Product $product): array
    {
        try {
            $hiddenBadgeSkus = ['TGS-2020504243', 'C167'];
            if (in_array((string) $product->getSku(), $hiddenBadgeSkus, true)) {
                return [];
            }

            $productId = (int) $product->getId();
            if ($productId <= 0) {
                return [];
            }
            /** @var Mage_Core_Model_Resource $resource */
            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $tagTbl   = $resource->getTableName('tag/tag');
            $relTbl   = $resource->getTableName('tag/relation');

            $allowed = $this->getAllBadges();
            $rows = $read->fetchCol(
                $read->select()
                    ->from(['t' => $tagTbl], ['name'])
                    ->joinInner(['r' => $relTbl], 'r.tag_id = t.tag_id', [])
                    ->where('r.product_id = ?', $productId)
                    ->where('t.status = ?', 1) // Mage_Tag_Model_Tag::STATUS_APPROVED
                    ->where('t.name IN (?)', $allowed)
                    ->distinct()
            );

            // Apply per-website applicability filter when we can resolve
            // the current frontend website. Admin/CLI contexts (no resolvable
            // website code) skip the filter so they keep seeing all tags.
            $websiteCode = '';
            try {
                $store = Mage::app()->getStore();
                if ($store && !$store->isAdmin()) {
                    $websiteCode = (string) $store->getWebsite()->getCode();
                }
            } catch (Throwable $e) {
                $websiteCode = '';
            }
            $applicable = $websiteCode !== ''
                ? $this->getApplicableBadgesForWebsite($websiteCode)
                : $allowed;

            // Preserve canonical order from getAllBadges()
            $set = array_flip($rows);
            $ordered = [];
            foreach ($allowed as $name) {
                if (isset($set[$name]) && in_array($name, $applicable, true)) {
                    $ordered[] = $name;
                }
            }
            return $ordered;
        } catch (Throwable $e) {
            Mage::logException($e);
            return [];
        }
    }

    /**
     * Sync a product's funding-badge tags to exactly the names in $badgeNames.
     *
     * - Canonical badge names outside $badgeNames are detached.
     * - Canonical badge names in $badgeNames that aren't yet attached are added.
     * - Non-canonical tags on the product (e.g. legacy "1"-"5" rating tags)
     *   are left untouched — we only manage the funding-badge vocabulary.
     *
     * Writes one row per (tag, store) for every store the product belongs to,
     * since Magento's tag rendering filters by store_id. Recomputes tag_summary
     * at the end so the admin Tags grid shows accurate product counts.
     *
     * Safe to call repeatedly — diff-based, no duplicates created.
     */
    public function syncProductTags(Mage_Catalog_Model_Product $product, array $badgeNames): void
    {
        $productId = (int) $product->getId();
        if ($productId <= 0) {
            return;
        }

        $allowed = $this->getAllBadges();
        $desired = [];
        foreach ($badgeNames as $b) {
            if (is_string($b)) {
                $b = trim($b);
                if ($b !== '' && in_array($b, $allowed, true) && !in_array($b, $desired, true)) {
                    $desired[] = $b;
                }
            }
        }

        /** @var Mage_Core_Model_Resource $resource */
        $resource = Mage::getSingleton('core/resource');
        $write    = $resource->getConnection('core_write');
        $tagTbl   = $resource->getTableName('tag/tag');
        $relTbl   = $resource->getTableName('tag/relation');
        $sumTbl   = $resource->getTableName('tag/summary');

        // Map canonical name -> tag_id (only seeded canonical rows count).
        $idByName = $write->fetchPairs(
            $write->select()
                ->from($tagTbl, ['name', 'tag_id'])
                ->where('name IN (?)', $allowed)
                ->where('status = ?', 1)
        );
        if (empty($idByName)) {
            return;
        }
        $canonicalIds = array_values(array_map('intval', $idByName));

        // Stores this product is visible in. saveAttribute writes at admin
        // scope but tag_relation is store-scoped, so iterate every active
        // store on every website this product belongs to.
        $storeIds = [];
        $websiteIds = $product->getWebsiteIds() ?: [];
        foreach ($websiteIds as $wId) {
            try {
                foreach (Mage::app()->getWebsite((int) $wId)->getStores() as $st) {
                    $storeIds[(int) $st->getId()] = true;
                }
            } catch (Throwable $e) {
                // Skip unknown website; continue with what we have.
            }
        }
        if (empty($storeIds)) {
            return;
        }
        $storeIds = array_keys($storeIds);

        // Delete canonical-tag relations not in the desired set.
        $desiredIds = [];
        foreach ($desired as $name) {
            if (isset($idByName[$name])) {
                $desiredIds[] = (int) $idByName[$name];
            }
        }
        $toDelete = array_values(array_diff($canonicalIds, $desiredIds));
        if (!empty($toDelete)) {
            $write->delete($relTbl, [
                'product_id = ?' => $productId,
                'tag_id IN (?)'  => $toDelete,
                'store_id IN (?)' => $storeIds,
            ]);
        }

        // Insert missing (tag, store) rows.
        foreach ($desiredIds as $tagId) {
            foreach ($storeIds as $storeId) {
                $exists = (int) $write->fetchOne(
                    $write->select()->from($relTbl, ['COUNT(*)'])
                        ->where('tag_id = ?', $tagId)
                        ->where('product_id = ?', $productId)
                        ->where('store_id = ?', $storeId)
                );
                if ($exists === 0) {
                    $write->insert($relTbl, [
                        'tag_id'     => $tagId,
                        'product_id' => $productId,
                        'store_id'   => $storeId,
                        'active'     => 1,
                        'created_at' => Varien_Date::now(),
                    ]);
                }
            }
        }

        // Recompute tag_summary for the touched tags so the admin Tags grid
        // shows accurate counts. One row per (tag_id, store_id).
        try {
            foreach ($canonicalIds as $tagId) {
                foreach ($storeIds as $storeId) {
                    $row = $write->fetchRow(
                        $write->select()
                            ->from($relTbl, [
                                'products' => new Zend_Db_Expr('COUNT(DISTINCT product_id)'),
                                'uses'     => new Zend_Db_Expr('COUNT(*)'),
                                'customers' => new Zend_Db_Expr('COUNT(DISTINCT customer_id)'),
                            ])
                            ->where('tag_id = ?', $tagId)
                            ->where('store_id = ?', $storeId)
                    );
                    $products = (int) ($row['products'] ?? 0);
                    $uses     = (int) ($row['uses'] ?? 0);
                    $customers = (int) ($row['customers'] ?? 0);
                    if ($products === 0) {
                        $write->delete($sumTbl, [
                            'tag_id = ?'   => $tagId,
                            'store_id = ?' => $storeId,
                        ]);
                    } else {
                        $write->insertOnDuplicate($sumTbl, [
                            'tag_id'     => $tagId,
                            'store_id'   => $storeId,
                            'products'   => $products,
                            'uses'       => $uses,
                            'customers'  => $customers,
                            'popularity' => $products,
                        ], ['products', 'uses', 'customers', 'popularity']);
                    }
                }
            }
        } catch (Throwable $e) {
            Mage::logException($e);
        }

        // Bust cache for this product so the storefront re-reads chips.
        try {
            Mage::app()->cleanCache(['catalog_product_' . $productId]);
        } catch (Throwable $e) {
            Mage::logException($e);
        }
    }

    /**
     * Map a canonical badge name to its CSS modifier suffix. Used by the
     * storefront template to emit class="course-badge course-badge--wsq"
     * and friends — the palette lives in skin/.../css/custom.css.
     */
    public function getBadgeCssClass(string $badgeName): string
    {
        $map = [
            'WSQ'                 => 'wsq',
            'SkillsFuture Credit' => 'sfc',
            'PSEA'                => 'psea',
            'UTAP'                => 'utap',
            'IBF'                 => 'ibf',
            'HRDF'                => 'hrdf',
            'SFEC'                => 'sfec',
            'Absentee Payroll'   => 'ap',
            'MCES'                => 'mces',
        ];
        return $map[$badgeName] ?? 'default';
    }

    public function env(string $key, ?string $default = null): ?string
    {
        $val = getenv($key);
        if ($val !== false && $val !== '') {
            return $val;
        }
        return $default;
    }
}
