<?php
/**
 * Override Mage_Widget_Model_Widget_Config so the WYSIWYG "Insert
 * Widget" plugin loads from the legacy TinyMCE 3.x path that actually
 * exists. See VariableConfig.php for the full backstory — same problem,
 * same fix.
 */
class MMD_RoleManager_Model_Wysiwyg_WidgetConfig extends Mage_Widget_Model_Widget_Config
{
    /**
     * @param Varien_Object $config
     * @return array
     */
    public function getPluginSettings($config)
    {
        $settings = parent::getPluginSettings($config);
        $settings['widget_plugin_src'] = Mage::getBaseUrl('js')
            . 'mage/adminhtml/wysiwyg/tiny_mce/plugins/magentowidget/editor_plugin.js';
        return $settings;
    }
}
