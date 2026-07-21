<?php

class MMD_Whatsapp_Helper_Data extends Mage_Core_Helper_Abstract
{
    public function isEnabled()
    {
        return (bool) Mage::getStoreConfig('mmd_whatsapp/general/enabled') && $this->getNumber() !== '';
    }

    public function getNumber()
    {
        // Prefer per-store number configured in admin Company Setting
        // (mmd_company/whatsapp/<store_code>). Falls back to the legacy
        // System Configuration field if not set.
        $code = Mage::app()->getStore()->getCode();
        $raw  = (string) Mage::getStoreConfig('mmd_company/whatsapp/' . $code);
        if (trim($raw) === '') {
            $raw = (string) Mage::getStoreConfig('mmd_whatsapp/general/number');
        }
        return preg_replace('/\D+/', '', $raw);
    }

    public function getLink()
    {
        $n = $this->getNumber();
        return $n === '' ? '' : 'https://wa.me/' . $n;
    }

    /**
     * wa.me deep-link with a pre-filled message. Used by the chat popup so
     * each enquiry option lands in WhatsApp with context already typed.
     */
    public function getLinkWithText($text)
    {
        $base = $this->getLink();
        if ($base === '') {
            return '';
        }
        return $base . '?text=' . rawurlencode((string) $text);
    }

    /**
     * Chat URL for the ADMIN ops launcher (TIA Operation Support / Kael).
     * Points at the WhatsApp Operation Group invite link when configured
     * (mmd_whatsapp/admin/chat_url — a chat.whatsapp.com invite URL);
     * falls back to the storefront wa.me number so the launcher still
     * works before the group link is set.
     */
    public function getAdminChatUrl()
    {
        $url = trim((string) Mage::getStoreConfig('mmd_whatsapp/admin/chat_url'));
        if ($url !== '') {
            return $url;
        }
        // Backend scope is the 'admin' store, which has no per-store company
        // number — resolve the wa.me fallback against the default store view.
        $store = Mage::app()->getDefaultStoreView();
        $raw   = (string) Mage::getStoreConfig('mmd_company/whatsapp/' . $store->getCode(), $store);
        if (trim($raw) === '') {
            $raw = (string) Mage::getStoreConfig('mmd_whatsapp/general/number', $store);
        }
        $n = preg_replace('/\D+/', '', $raw);
        return $n === '' ? '' : 'https://wa.me/' . $n;
    }

    /**
     * Per-store brand name shown in the popup header. Mirrors the auto-reply
     * branding (see MMD_Leads_Helper_Data::getStoreBrandName).
     */
    public function getBrandName()
    {
        if (Mage::helper('core')->isModuleEnabled('MMD_Leads')) {
            return Mage::helper('mmd_leads')->getStoreBrandName(Mage::app()->getStore()->getId());
        }
        $name = (string) Mage::app()->getStore()->getFrontendName();
        return $name !== '' ? $name : 'Tertiary Infotech Academy';
    }
}
