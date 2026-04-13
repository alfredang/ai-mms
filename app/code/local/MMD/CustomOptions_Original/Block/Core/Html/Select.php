<?php
class MMD_CustomOptions_Block_Core_Html_Select extends Mage_Core_Block_Html_Select {
    public function addOption($value, $label, $params=array()) {
        $this->_options[] = array('value'=>$value, 'label'=>$label, 'params' => $params);
        return $this;
    }

    protected function _toHtml()
    {
        if (!$this->_beforeToHtml()) {
            return '';
        }

        $html = '<select name="'.$this->getName().'" id="'.$this->getId().'" class="'
            .$this->getClass().'" title="'.$this->getTitle().'" '.$this->getExtraParams().'>';
        $values = $this->getValue();

        if (!is_array($values)){
            if (!is_null($values)) {
                $values = array($values);
            } else {
                $values = array();
            }
        }

        $isArrayOption = true;
        foreach ($this->getOptions() as $key => $option) {
            $params = array();
            if ($isArrayOption && is_array($option)) {
                $value = $option['value'];
                $label = $option['label'];
                $params = isset($option['params']) ? $option['params'] : array();
            }
            else {
                $value = $key;
                $label = $option;
                $isArrayOption = false;
            }

            if (is_array($value)) {
                $html.= '<optgroup label="'.$label.'">';
                foreach ($value as $keyGroup => $optionGroup) {
                    if (!is_array($optionGroup)) {
                        $optionGroup = array(
                            'value' => $keyGroup,
                            'label' => $optionGroup
                        );
                    }
                    $html.= $this->_optionToHtml(
                        $optionGroup,
                        in_array($optionGroup['value'], $values)
                    );
                }
                $html.= '</optgroup>';
            } else {
                $html.= $this->_optionToHtml(array(
                    'value' => $value,
                    'label' => $label,
                    'params'=> $params

                ),
                    in_array($value, $values)
                );
            }
        }
        $html.= '</select>';
        return $html;
    }

    protected function _optionToHtml($option, $selected=false) {
        $selectedHtml = $selected ? ' selected="selected"' : '';
        $params = '';
        if (isset($option['params']) && $option['params'] != '') {
            foreach ($option['params'] as $key => $value) {
                $params .= $key . '="' . $value . '" ';
            }
        }
        $html = '<option ' . $params . 'value="'.$this->htmlEscape($option['value']).'"'.$selectedHtml.'>'.$this->htmlEscape($option['label']).'</option>';

        return $html;
    }
}
