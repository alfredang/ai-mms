<?php
/**
 * Renders a Pro Forma Invoice PDF directly from a Mage_Sales_Model_Order.
 *
 * Extends the core invoice PDF model purely to reuse its drawing
 * infrastructure (logo, store address, font helpers, page handling). It does
 * NOT render a real invoice - there is no sales/order_invoice involved. A pro
 * forma is produced from the registration (order) itself, before payment, so
 * self-sponsored SG learners can submit it to MySkillsFuture for their
 * SkillsFuture Credit (SFC) claim.
 *
 * WSQ funding breakdown
 * ---------------------
 * The storefront only ever stores the *net* fee the learner pays (item
 * row_total / order subtotal) - the original course list price is not kept on
 * the order. BUT SG GST is deliberately settled on the **pre-subsidy list
 * price** (see CLAUDE.md), so the stored tax_amount is exactly 9% of that list
 * price. We therefore recover the list price from the GST:
 *
 *     original_list = item.tax_amount / GST_RATE          (e.g. 67.50 / 0.09 = 750)
 *     total_funding = original_list - item.row_total      (e.g. 750 - 225 = 525)
 *     baseline      = original_list * 0.50                 (WSQ baseline, 50%)
 *     mces          = total_funding - baseline             (Mid-Career Enhanced Subsidy, 20%)
 *
 * This is automatically age-aware: a learner who did NOT qualify for MCES
 * (under 40) paid 50% (baseline only), so total_funding == baseline and the
 * MCES line is simply omitted. A learner above 40 paid 30%, so MCES = 20%
 * shows. Net fee + GST always reconciles to the stored grand_total.
 *
 * Totals (SUBTOTAL / GST / TOTAL / BALANCE DUE) are taken verbatim from the
 * stored order and never recomputed.
 */
class MMD_Proforma_Model_Proforma extends Mage_Sales_Model_Order_Pdf_Invoice
{
    /** SG GST rate the custom tax engine settles on the pre-subsidy list price. */
    const GST_RATE = 0.09;

    /** Payment term: due date = invoice date + this many days (Net 30). */
    const DUE_DAYS = 30;

    /**
     * Registered legal entity printed above the store address in the header.
     * Not held in any store config (sales/identity/address has only the
     * Address/Tel/Email lines; general/store_information/name is the trading
     * name without "Pte. Ltd."), so it lives here. Pro formas are SG
     * self-sponsored only, so the SG legal entity is the correct one.
     */
    const COMPANY_LEGAL_NAME = 'Tertiary Infotech Academy Pte. Ltd.';

    /** Royal-blue table header fill (matches the reference pro forma). */
    protected function _blue()
    {
        return new Zend_Pdf_Color_Rgb(0.13, 0.30, 0.80);
    }

    /* Column geometry (A4 content band 25..570pt). */
    protected $_colDesc      = 30;
    protected $_qtyCenter    = 412;
    protected $_rateCenter   = 487;
    protected $_amtCenter    = 543;
    protected $_qtyRight     = 432;
    protected $_rateRight    = 512;
    protected $_amtRight     = 567;

    /**
     * @param  Mage_Sales_Model_Order $order
     * @return Zend_Pdf
     */
    public function getOrderPdf(Mage_Sales_Model_Order $order)
    {
        $this->_beforeGetPdf();

        $pdf = new Zend_Pdf();
        $this->_setPdf($pdf);

        $storeId = $order->getStoreId();
        if ($storeId) {
            Mage::app()->getLocale()->emulate($storeId);
            Mage::app()->setCurrentStore($storeId);
        }
        $store = $order->getStore();

        $page = $this->newPage();

        /* Header: store logo (left) + store identity address (right) */
        $this->insertLogo($page, $store);
        $this->insertAddress($page, $store);

        /* BILL TO (left) + INVOICE / DATE / DUE DATE (right) */
        $this->y = 700;
        $this->_drawBillTo($page, $order);
        $this->_drawInvoiceMeta($page, $order);

        // Drop below BOTH the bill-to name and the 3-row meta block before the
        // table, so the blue header bar never overlaps the DUE DATE line.
        $this->y = 648;

        /* Items table */
        $this->_drawTableHeader($page);

        foreach ($order->getAllVisibleItems() as $item) {
            if ($this->y < 170) {
                $page = $this->newPage();
                $this->y = 790;
                $this->_drawTableHeader($page);
            }
            $this->_drawItemBlock($page, $order, $item);
        }

        /* "To Less SkillsFuture Credit" payable line. A pro forma is only ever
           issued for self-sponsored registrations, which can offset the amount
           below with SkillsFuture Credit - so this always shows (WSQ funded or
           not). The figure is the net amount payable incl. GST. */
        if ($this->y < 150) {
            $page = $this->newPage();
            $this->y = 790;
        }
        $this->_setFontRegular($page, 9);
        $page->drawText(
            'To Less SkillsFuture Credit: SGD' . $this->_num($order->getGrandTotal()),
            $this->_colDesc, $this->y, 'UTF-8'
        );
        $this->y -= 8;
        $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.6));
        $page->setLineWidth(0.6);
        $page->drawLine(25, $this->y, 570, $this->y);
        $this->y -= 16;

        /* Totals */
        if ($this->y < 150) {
            $page = $this->newPage();
            $this->y = 790;
        }
        $this->_drawTotals($page, $order);
        $this->_drawNotes($page, $order);

        if ($storeId) {
            Mage::app()->getLocale()->revert();
        }

        $this->_afterGetPdf();
        return $pdf;
    }

    /* ------------------------------------------------------------------ */

    /**
     * Header identity block (top-right). Core insertAddress() renders only the
     * sales/identity/address store config (Address / Tel / Email). The
     * registered company name is not part of that config, so draw it as a bold
     * line at the top of the block, then the address lines below - preserving
     * core's right-aligned layout (column 130..440, regular size 10).
     */
    protected function insertAddress(&$page, $store = null)
    {
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
        $page->setLineWidth(0);
        $top = 815;

        // Company legal name (bold) above the address.
        $fontBold = $this->_setFontBold($page, 10);
        $page->drawText(
            self::COMPANY_LEGAL_NAME,
            $this->getAlignRight(self::COMPANY_LEGAL_NAME, 130, 440, $fontBold, 10),
            $top,
            'UTF-8'
        );
        $top -= 12;

        // Address lines (regular) - identical wrapping/alignment to core.
        $font = $this->_setFontRegular($page, 10);
        foreach (explode("\n", (string) Mage::getStoreConfig('sales/identity/address', $store)) as $value) {
            if ($value !== '') {
                $value = preg_replace('/<br[^>]*>/i', "\n", $value);
                foreach (Mage::helper('core/string')->str_split($value, 45, true, true) as $str) {
                    $page->drawText(
                        trim(strip_tags($str)),
                        $this->getAlignRight($str, 130, 440, $font, 10),
                        $top,
                        'UTF-8'
                    );
                    $top -= 10;
                }
            }
        }
        $this->y = $top;
    }

    protected function _drawBillTo(&$page, Mage_Sales_Model_Order $order)
    {
        $this->_setFontBold($page, 11);
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
        $page->drawText('BILL TO', $this->_colDesc, $this->y, 'UTF-8');

        $name = trim((string) $order->getCustomerName());
        if ($name === '' || strcasecmp($name, 'Guest') === 0) {
            $billing = $order->getBillingAddress();
            $name = $billing ? trim((string) $billing->getName()) : '';
        }
        if ($name === '') {
            $name = '-';
        }

        $this->_setFontRegular($page, 11);
        $page->drawText($name, $this->_colDesc, $this->y - 18, 'UTF-8');
    }

    protected function _drawInvoiceMeta(&$page, Mage_Sales_Model_Order $order)
    {
        $ts = strtotime((string) $order->getCreatedAtStoreDate());
        if (!$ts) {
            $ts = strtotime((string) $order->getCreatedAt());
        }
        $invoiceDate = $ts ? date('d/m/Y', $ts) : '';
        $dueDate     = $ts ? date('d/m/Y', $ts + self::DUE_DAYS * 86400) : '';

        $labelRight = 478;   // right edge of the label column
        $valueLeft  = 486;   // left edge of the value column
        $y = $this->y;

        $rows = array(
            array('INVOICE',  'PF-' . $order->getIncrementId()),
            array('DATE',     $invoiceDate),
            array('DUE DATE', $dueDate),
        );
        foreach ($rows as $r) {
            $this->_setFontBold($page, 10);
            $this->_textRight($page, $r[0], $labelRight, $y, 10, true);
            $this->_setFontRegular($page, 10);
            $page->drawText($r[1], $valueLeft, $y, 'UTF-8');
            $y -= 16;
        }
    }

    protected function _drawTableHeader(&$page)
    {
        $page->setFillColor($this->_blue());
        $page->setLineColor($this->_blue());
        $page->drawRectangle(25, $this->y, 570, $this->y - 22, Zend_Pdf_Page::SHAPE_DRAW_FILL);

        $this->_setFontBold($page, 9);
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(1));
        $textY = $this->y - 15;
        $page->drawText('DESCRIPTION', $this->_colDesc, $textY, 'UTF-8');
        $this->_textCenter($page, 'QTY',    $this->_qtyCenter,  $textY, 9, true);
        $this->_textCenter($page, 'RATE',   $this->_rateCenter, $textY, 9, true);
        $this->_textCenter($page, 'AMOUNT', $this->_amtCenter,  $textY, 9, true);

        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
        $this->y -= 34;
    }

    /**
     * Draw the course line + its WSQ funding breakdown.
     *
     * @return bool true if a funding breakdown was rendered (so the caller can
     *              decide whether to print the SkillsFuture-Credit note).
     */
    protected function _drawItemBlock(&$page, Mage_Sales_Model_Order $order, $item)
    {
        $qty = (float) $item->getQtyOrdered();
        if ($qty <= 0) {
            $qty = 1.0;
        }

        list($original, $net, $baseline, $mces, $hasFunding) = $this->_itemFunding($item);

        /* ---- Course row ---- */
        $rowTop = $this->y;

        // Description: "<name> - <sku>" then participant + course date sub-lines.
        $title = trim((string) $item->getName());
        $sku   = trim((string) $item->getSku());
        if ($sku !== '' && stripos($title, $sku) === false) {
            $title .= ' - ' . $sku;
        }
        $this->_setFontRegular($page, 9);
        $y = $rowTop;
        foreach (Mage::helper('core/string')->str_split($title, 62, true, true) as $tl) {
            $page->drawText(trim($tl), $this->_colDesc, $y, 'UTF-8');
            $y -= 11;
        }

        $participant = $this->_participantName($order, $item);
        if ($participant !== '') {
            $page->drawText('Participant Name: ' . $participant, $this->_colDesc, $y, 'UTF-8');
            $y -= 11;
        }
        $courseDate = $this->_itemOption($item, 'Course Date');
        if ($courseDate !== '') {
            $page->drawText('Course Date: ' . $courseDate, $this->_colDesc, $y, 'UTF-8');
            $y -= 11;
        }

        // Numeric columns aligned to the title line. For a WSQ-funded course
        // the AMOUNT is the pre-subsidy list price (the funding rows below bring
        // it down to net); for a non-WSQ course there is no subsidy, so the
        // AMOUNT is simply the net the learner pays (matching the SUBTOTAL).
        $rowAmount = $hasFunding ? $original : $net;
        $unit      = $qty > 0 ? $rowAmount / $qty : $rowAmount;
        $this->_textRight($page, $this->_qtyStr($qty),   $this->_qtyRight,  $rowTop, 9);
        $this->_textRight($page, $this->_num($unit),     $this->_rateRight, $rowTop, 9);
        $this->_textRight($page, $this->_num($rowAmount), $this->_amtRight, $rowTop, 9);

        $this->y = $y - 6;

        /* ---- Funding rows (WSQ subsidised courses only) ---- */
        if ($hasFunding) {
            $this->_drawFundingRow($page, 'Less: WSQ funding (Baseline)', $qty, -$baseline);
            if ($mces > 0.005) {
                $this->_drawFundingRow($page, 'Less: WSQ funding (Mid-Career Enhanced Subsidy)', $qty, -$mces);
            }
        }

        return $hasFunding;
    }

    protected function _drawFundingRow(&$page, $label, $qty, $rowAmount)
    {
        $this->_setFontRegular($page, 9);
        $page->drawText($label, $this->_colDesc, $this->y, 'UTF-8');

        $unit = $qty > 0 ? $rowAmount / $qty : $rowAmount;
        $this->_textRight($page, $this->_qtyStr($qty),    $this->_qtyRight,  $this->y, 9);
        $this->_textRight($page, $this->_num($unit),      $this->_rateRight, $this->y, 9);
        $this->_textRight($page, $this->_num($rowAmount), $this->_amtRight,  $this->y, 9);

        $this->y -= 16;
    }

    /**
     * Derive the WSQ funding breakdown for one order item from the stored GST.
     *
     * @return array [original_list, net_fee, baseline, mces, hasFunding]
     */
    protected function _itemFunding($item)
    {
        // Net fee = list row total minus any discount. This is storage-pattern
        // agnostic: some orders bake the subsidy straight into the price
        // (row_total already net, discount 0); others keep the list price in
        // row_total and record the subsidy as discount_amount. Both yield the
        // same net here.
        $net = round((float) $item->getRowTotal() - (float) $item->getDiscountAmount(), 2);
        $tax = round((float) $item->getTaxAmount(), 2);

        // List price recovered from GST (settled on the pre-subsidy list price).
        $original = $net;
        if ($tax > 0.001 && self::GST_RATE > 0) {
            $original = round($tax / self::GST_RATE, 2);
        }

        $totalFunding = round($original - $net, 2);

        // Funding lines only for WSQ (TGS-) courses that actually carry a subsidy.
        $isWsq      = strncasecmp((string) $item->getSku(), 'TGS-', 4) === 0;
        $hasFunding = $isWsq && $totalFunding > 0.005;

        $baseline = $hasFunding ? round($original * 0.50, 2) : 0.0;
        $mces     = $hasFunding ? round($totalFunding - $baseline, 2) : 0.0;
        if ($mces < 0) {
            // Funding below baseline (rare/partial): fold it all into baseline.
            $baseline = $totalFunding;
            $mces     = 0.0;
        }

        return array($original, $net, $baseline, $mces, $hasFunding);
    }

    protected function _drawTotals(&$page, Mage_Sales_Model_Order $order)
    {
        $labelX = 400;
        $valX   = $this->_amtRight;

        // Net fee = grand total minus GST. There is never any shipping, so this
        // always equals the post-subsidy amount the learner pays before tax -
        // and it is correct whether the subsidy was baked into the price or
        // stored as a Magento discount (getSubtotal() would be the pre-discount
        // figure in the latter case and must NOT be used here).
        $netTotal = (float) $order->getGrandTotal() - (float) $order->getTaxAmount();
        $rows = array(
            array('SUBTOTAL',  $this->_num($netTotal), false),
            array('GST TOTAL', $this->_num($order->getTaxAmount()), false),
            array('TOTAL',     $this->_num($order->getGrandTotal()), false),
        );
        foreach ($rows as $r) {
            $this->_setFontRegular($page, 10);
            $page->drawText($r[0], $labelX, $this->y, 'UTF-8');
            $this->_textRight($page, $r[1], $valX, $this->y, 10);
            $this->y -= 18;
        }

        // BALANCE DUE - emphasised, with the rule line above it.
        $this->y -= 2;
        $page->setLineColor(new Zend_Pdf_Color_GrayScale(0.4));
        $page->setLineWidth(0.8);
        $page->drawLine($labelX, $this->y + 14, 570, $this->y + 14);

        $this->_setFontBold($page, 11);
        $page->drawText('BALANCE DUE', $labelX, $this->y, 'UTF-8');
        $this->_textRight(
            $page,
            $order->getOrderCurrencyCode() . ' ' . $this->_num($order->getGrandTotal()),
            $valX, $this->y, 11, true
        );
        $this->y -= 22;
    }

    protected function _drawNotes(&$page, Mage_Sales_Model_Order $order)
    {
        $this->y -= 12;
        if ($this->y < 90) {
            $page = $this->newPage();
            $this->y = 790;
        }

        $this->_setFontBold($page, 9);
        $page->drawText('Notes', 25, $this->y, 'UTF-8');
        $this->y -= 14;

        $this->_setFontRegular($page, 9);
        $notes = array(
            'This is a pro forma invoice issued for course registration and funding-claim purposes '
                . '(e.g. SkillsFuture Credit). It is not a receipt of payment.',
            'For SkillsFuture Credit (SFC) claims, submit this pro forma invoice via the MySkillsFuture '
                . 'portal before the class start date.',
            'For an official tax invoice for payment processing, reply to your registration email or '
                . 'contact ' . $this->_storeEmail($order) . '.',
        );
        foreach ($notes as $note) {
            foreach (Mage::helper('core/string')->str_split($note, 110, true, true) as $line) {
                $page->drawText(trim($line), 25, $this->y, 'UTF-8');
                $this->y -= 12;
            }
            $this->y -= 3;
        }

        $this->y -= 6;
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0.5));
        $this->_setFontItalic($page, 8);
        $page->drawText('Computer-generated pro forma invoice - no signature required.', 25, $this->y, 'UTF-8');
        $page->setFillColor(new Zend_Pdf_Color_GrayScale(0));
    }

    /* ------------------------------------------------------------------ */

    /**
     * Participant name for the course line - the account holder (matches the
     * reference pro forma, which prints the BILL TO name as the participant).
     */
    protected function _participantName(Mage_Sales_Model_Order $order, $item)
    {
        $name = trim((string) $order->getCustomerName());
        if ($name === '' || strcasecmp($name, 'Guest') === 0) {
            $billing = $order->getBillingAddress();
            $name = $billing ? trim((string) $billing->getName()) : '';
        }
        return $name;
    }

    /**
     * Pull a named custom-option value (e.g. "Course Date") off an order item.
     */
    protected function _itemOption($item, $label)
    {
        $opts = $item->getProductOptions();
        if (is_array($opts) && !empty($opts['options'])) {
            foreach ($opts['options'] as $o) {
                if (isset($o['label']) && strcasecmp(trim($o['label']), $label) === 0) {
                    return isset($o['value']) ? trim((string) $o['value']) : '';
                }
            }
        }
        return '';
    }

    protected function _storeEmail(Mage_Sales_Model_Order $order)
    {
        $email = Mage::getStoreConfig('trans_email/ident_sales/email', $order->getStoreId());
        return $email ?: 'sales@tertiarycourses.com.sg';
    }

    /** Plain money formatter: 1,234.50 (no currency symbol). */
    protected function _num($n)
    {
        return number_format((float) $n, 2, '.', ',');
    }

    /** Qty formatter: trims trailing zeros (1, 1.5, 2). */
    protected function _qtyStr($qty)
    {
        return rtrim(rtrim(number_format((float) $qty, 2), '0'), '.');
    }

    /** Draw right-aligned text ending at $rightX on baseline $y. */
    protected function _textRight(&$page, $text, $rightX, $y, $size, $bold = false)
    {
        $font  = $bold ? $this->_setFontBold($page, $size) : $this->_setFontRegular($page, $size);
        $width = $this->widthForStringUsingFontSize($text, $font, $size);
        $page->drawText($text, $rightX - $width, $y, 'UTF-8');
    }

    /** Draw text centered on $centerX at baseline $y. */
    protected function _textCenter(&$page, $text, $centerX, $y, $size, $bold = false)
    {
        $font  = $bold ? $this->_setFontBold($page, $size) : $this->_setFontRegular($page, $size);
        $width = $this->widthForStringUsingFontSize($text, $font, $size);
        $page->drawText($text, $centerX - $width / 2, $y, 'UTF-8');
    }
}
