<?php
/**
 * Fills one of the partner's own HRD Corp Word forms (data/claims/*.docx - the standard T3 / JD14 forms
 * and their Zoom attendance report, unchanged except that the sample values were replaced by
 * ${placeholders}). Only placeholder text is replaced; format and layout stay exactly as issued.
 * Placeholders without a value become blank. Built with ZipArchive; no external library.
 */
class MMD_AgentApi_Model_Claims_Docx
{
    protected $_template = '';
    protected $_values = array();

    /** @param string $name t3 | jd14 | zoom_report */
    public function load($name)
    {
        $this->_template = Mage::getModuleDir('', 'MMD_AgentApi') . DS . 'data' . DS . 'claims' . DS . $name . '.docx';
        if (!is_file($this->_template)) {
            throw new Exception('Claim form template missing: ' . $name);
        }
        return $this;
    }

    public function set(array $values)
    {
        $this->_values = array_merge($this->_values, $values);
        return $this;
    }

    public function save($path)
    {
        if (!copy($this->_template, $path)) {
            throw new Exception('Cannot write ' . $path);
        }
        $zip = new ZipArchive();
        if ($zip->open($path) !== true) {
            throw new Exception('Cannot open ' . $path);
        }
        $values = $this->_values;
        $xml = preg_replace_callback('/\$\{(\w+)\}/', function ($m) use ($values) {
            $v = isset($values[$m[1]]) ? (string) $values[$m[1]] : '';
            // a line break inside a value becomes a Word line break within the same run
            return str_replace("\n", '</w:t><w:br/><w:t xml:space="preserve">', htmlspecialchars($v, ENT_XML1 | ENT_QUOTES, 'UTF-8'));
        }, (string) $zip->getFromName('word/document.xml'));
        $zip->addFromString('word/document.xml', $xml);
        $zip->close();
        return $path;
    }
}
