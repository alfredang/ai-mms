<?php
/**
 * Renders grid action cells as icon-only buttons (eye for View, X for
 * Cancel, …) instead of the default caption text. Each `<a>` carries the
 * caption as its `title` attribute for accessibility / tooltip.
 *
 * We build the anchor HTML directly instead of delegating to the parent's
 * `_toLinkHtml()` — that helper escapes the caption, which would turn our
 * inline `<svg>` markup into visible angle-bracket gibberish.
 *
 * Captions are matched case-insensitively against a small icon table.
 * Unknown captions fall back to the original text — so a future action
 * added to the grid without an icon mapping won't disappear silently.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Actionlinks
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Action
{
    /** SVG library — 14px stroked icons, currentColor so CSS controls hue. */
    protected $_icons = array(
        'view'    => '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/></svg>',
        'cancel'  => '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>',
        'edit'    => '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>',
        'delete'  => '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>',
        'print'   => '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>',
    );

    public function render(Varien_Object $row)
    {
        $actions = $this->getColumn()->getActions();
        if (empty($actions) || !is_array($actions)) {
            return '&nbsp;';
        }

        $links = array();
        foreach ($actions as $action) {
            if (!is_array($action) || empty($action['caption'])) continue;
            $links[] = $this->_toIconLink($action, $row);
        }
        return '<span class="mmd-grid-actions">' . implode('', $links) . '</span>';
    }

    /**
     * Build a single icon-only `<a>` for one action entry. We replicate
     * the URL-building / field-substitution / confirm-prompt behaviour
     * of `Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Action` but
     * emit raw SVG in the anchor body so the icon isn't escaped.
     */
    protected function _toIconLink($action, Varien_Object $row)
    {
        $caption = (string) $action['caption'];
        $key     = strtolower(trim($caption));
        $icon    = isset($this->_icons[$key]) ? $this->_icons[$key] : htmlspecialchars($caption);

        $url = '#';
        if (!empty($action['url']) && is_array($action['url'])) {
            $params  = isset($action['url']['params']) ? $action['url']['params'] : array();
            $field   = isset($action['field']) ? $action['field'] : 'id';
            $idValue = $row->getData($field);
            if ($idValue === null) {
                $getter  = isset($action['field']) ? 'get' . str_replace(' ', '', ucwords(str_replace('_', ' ', $action['field']))) : 'getId';
                if (method_exists($row, $getter)) $idValue = $row->{$getter}();
            }
            $params[$field] = $idValue;
            $url = Mage::helper('adminhtml')->getUrl($action['url']['base'], $params);
        }

        $onclick = '';
        if (!empty($action['confirm'])) {
            $confirm = addslashes(html_entity_decode($action['confirm'], ENT_QUOTES, 'UTF-8'));
            $onclick = ' onclick="return confirm(\'' . $confirm . '\');"';
        }

        return '<a href="' . htmlspecialchars($url) . '"'
             . ' title="' . htmlspecialchars($caption) . '"'
             . ' class="mmd-grid-action mmd-grid-action--' . htmlspecialchars($key) . '"'
             . $onclick . '>'
             . $icon
             . '</a>';
    }
}
