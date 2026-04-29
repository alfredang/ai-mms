<?php
/**
 * Override Mage_Core_Model_Variable_Config so the WYSIWYG editor's
 * "Insert Variable" plugin loads from the legacy TinyMCE 3.x path that
 * actually exists in this build.
 *
 * The OpenMage core upgraded the path to
 *   js/mage/adminhtml/wysiwyg/tinymce/plugins/openmagevariable.js
 * (and renamed the plugin to "openmagevariable") — but those new files
 * were never bundled. The 404 makes TinyMCE silently abort the entire
 * editor attach, leaving the textarea hidden and the Show/Hide Editor
 * toggle stuck calling turnOn() forever.
 *
 * This override redirects to the legacy
 *   js/mage/adminhtml/wysiwyg/tiny_mce/plugins/magentovariable/editor_plugin.js
 * which is present, registers as `magentovariable`, and uses the
 * `MagentovariablePlugin` global already defined in
 * js/mage/adminhtml/variables.js.
 */
class MMD_RoleManager_Model_Wysiwyg_VariableConfig extends Mage_Core_Model_Variable_Config
{
    /**
     * @return string
     */
    public function getWysiwygJsPluginSrc()
    {
        return Mage::getBaseUrl('js') . 'mage/adminhtml/wysiwyg/tiny_mce/plugins/magentovariable/editor_plugin.js';
    }

    /**
     * Override so the plugin name + onclick subject point at the legacy
     * MagentovariablePlugin global instead of the missing Openmagevariable one.
     *
     * @param Varien_Object $config
     * @return array
     */
    public function getWysiwygPluginSettings($config)
    {
        $variableConfig = [];
        $onclickParts = [
            'search' => ['html_id'],
            'subject' => 'MagentovariablePlugin.loadChooser(\'' . $this->getVariablesWysiwygActionUrl() . '\', \'{{html_id}}\');',
        ];
        $variableWysiwygPlugin = [[
            'name'    => 'magentovariable',
            'src'     => $this->getWysiwygJsPluginSrc(),
            'options' => [
                'title'   => Mage::helper('adminhtml')->__('Insert Variable...'),
                'url'     => $this->getVariablesWysiwygActionUrl(),
                'onclick' => $onclickParts,
                'class'   => 'add-variable plugin',
            ],
        ]];
        $configPlugins = $config->getData('plugins');
        $variableConfig['plugins'] = array_merge($configPlugins, $variableWysiwygPlugin);
        return $variableConfig;
    }
}
