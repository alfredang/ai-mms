<?php
/**
 * Minimal .xlsx writer (no library in this install; ZipArchive only). Strings
 * are written inline, numbers as numbers. A cell is a scalar or
 * array('v' => value, 's' => style). Styles: 0 normal, 1 bold, 2 table header
 * (bold, grey fill, border), 3 bordered body cell.
 */
class MMD_Attendance_Model_Xlsx
{
    const S_BOLD   = 1;
    const S_HEAD   = 2;
    const S_CELL   = 3;

    protected $_sheets = array();

    /**
     * @param string $name   sheet name (made Excel-safe and unique)
     * @param array  $rows   list of rows, each a list of cells
     * @param array  $widths column widths in characters
     * @param int    $freezeRow rows above this (1-based) stay visible when scrolling; 0 = none
     */
    public function addSheet($name, array $rows, array $widths = array(), $freezeRow = 0)
    {
        $name = trim(preg_replace('/[\[\]\*\?\/\\\\:]+/', ' ', (string) $name));
        $name = mb_substr($name !== '' ? $name : 'Sheet', 0, 31);
        $base = $name;
        for ($i = 2; isset($this->_sheets[mb_strtolower($name)]); $i++) {
            $name = mb_substr($base, 0, 28) . ' ' . $i;
        }
        $this->_sheets[mb_strtolower($name)] = array('name' => $name, 'rows' => $rows, 'widths' => $widths, 'freeze' => (int) $freezeRow);
        return $this;
    }

    /** @return string the .xlsx file bytes */
    public function toString()
    {
        $tmp = tempnam(sys_get_temp_dir(), 'xlsx');
        $zip = new ZipArchive();
        if ($zip->open($tmp, ZipArchive::OVERWRITE) !== true) {
            throw new Exception('Could not build the spreadsheet.');
        }
        $sheets = array_values($this->_sheets);
        $ct = $wbRels = $wbSheets = '';
        foreach ($sheets as $i => $sh) {
            $n = $i + 1;
            $ct      .= '<Override PartName="/xl/worksheets/sheet' . $n . '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>';
            $wbRels  .= '<Relationship Id="rId' . $n . '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet' . $n . '.xml"/>';
            $wbSheets .= '<sheet name="' . $this->_x($sh['name']) . '" sheetId="' . $n . '" r:id="rId' . $n . '"/>';
            $zip->addFromString('xl/worksheets/sheet' . $n . '.xml', $this->_sheetXml($sh, $i === 0));
        }
        $styleRel = count($sheets) + 1;
        $zip->addFromString('[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            . '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            . '<Default Extension="xml" ContentType="application/xml"/>'
            . '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            . '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
            . $ct . '</Types>');
        $zip->addFromString('_rels/.rels', '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            . '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
            . '</Relationships>');
        $zip->addFromString('xl/workbook.xml', '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            . '<sheets>' . $wbSheets . '</sheets></workbook>');
        $zip->addFromString('xl/_rels/workbook.xml.rels', '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' . $wbRels
            . '<Relationship Id="rId' . $styleRel . '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
            . '</Relationships>');
        $zip->addFromString('xl/styles.xml', '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            . '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
            . '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
            . '<fill><patternFill patternType="solid"><fgColor rgb="FFE2E8F0"/><bgColor indexed="64"/></patternFill></fill></fills>'
            . '<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border>'
            . '<border><left style="thin"><color rgb="FFCBD5E1"/></left><right style="thin"><color rgb="FFCBD5E1"/></right>'
            . '<top style="thin"><color rgb="FFCBD5E1"/></top><bottom style="thin"><color rgb="FFCBD5E1"/></bottom><diagonal/></border></borders>'
            . '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
            . '<cellXfs count="4"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
            . '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
            . '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>'
            . '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1"/></cellXfs>'
            . '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
            . '</styleSheet>');
        $zip->close();
        $bytes = file_get_contents($tmp);
        @unlink($tmp);
        return $bytes;
    }

    protected function _sheetXml(array $sh, $selected)
    {
        $view = '<sheetView workbookViewId="0"' . ($selected ? ' tabSelected="1"' : '') . '>';
        if ($sh['freeze'] > 1) {
            $top = 'A' . $sh['freeze'];
            $view .= '<pane ySplit="' . ($sh['freeze'] - 1) . '" topLeftCell="' . $top . '" activePane="bottomLeft" state="frozen"/>'
                . '<selection pane="bottomLeft" activeCell="' . $top . '" sqref="' . $top . '"/>';
        }
        $view .= '</sheetView>';
        $cols = '';
        foreach ($sh['widths'] as $i => $w) {
            $cols .= '<col min="' . ($i + 1) . '" max="' . ($i + 1) . '" width="' . (float) $w . '" customWidth="1"/>';
        }
        $data = '';
        foreach ($sh['rows'] as $r => $row) {
            $data .= '<row r="' . ($r + 1) . '">';
            foreach (array_values($row) as $c => $cell) {
                $v = is_array($cell) ? (isset($cell['v']) ? $cell['v'] : '') : $cell;
                $s = is_array($cell) && isset($cell['s']) ? (int) $cell['s'] : 0;
                if ($v === null || $v === '') {
                    if ($s) $data .= '<c r="' . $this->_ref($c, $r) . '" s="' . $s . '"/>';
                    continue;
                }
                $attr = '<c r="' . $this->_ref($c, $r) . '"' . ($s ? ' s="' . $s . '"' : '');
                if (is_int($v) || is_float($v)) {
                    $data .= $attr . '><v>' . $v . '</v></c>';
                } else {
                    $data .= $attr . ' t="inlineStr"><is><t xml:space="preserve">' . $this->_x($v) . '</t></is></c>';
                }
            }
            $data .= '</row>';
        }
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            . '<sheetViews>' . $view . '</sheetViews>'
            . ($cols !== '' ? '<cols>' . $cols . '</cols>' : '')
            . '<sheetData>' . $data . '</sheetData></worksheet>';
    }

    protected function _ref($col, $row)
    {
        $letters = '';
        for ($n = $col + 1; $n > 0; $n = intdiv($n - 1, 26)) {
            $letters = chr(65 + ($n - 1) % 26) . $letters;
        }
        return $letters . ($row + 1);
    }

    /** XML-escape, dropping control characters Excel rejects. */
    protected function _x($s)
    {
        $s = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/', '', (string) $s);
        return htmlspecialchars($s, ENT_QUOTES | ENT_XML1, 'UTF-8');
    }
}
