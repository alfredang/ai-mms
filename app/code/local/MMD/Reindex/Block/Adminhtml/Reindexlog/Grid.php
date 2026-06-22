<?php
class MMD_Reindex_Block_Adminhtml_Reindexlog_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setId('reindexLogGrid');
        $this->setDefaultSort('log_id');
        $this->setDefaultDir('DESC');
        $this->setSaveParametersInSession(true);
        $this->setUseAjax(true);
    }

    protected function _prepareCollection()
    {
        $this->setCollection(Mage::getModel('mmd_reindex/log')->getCollection());
        return parent::_prepareCollection();
    }

    protected function _prepareColumns()
    {
        $h = Mage::helper('mmd_reindex');
        $this->addColumn('log_id', array('header' => $h->__('ID'), 'index' => 'log_id', 'width' => 50));
        $this->addColumn('started_at', array('header' => $h->__('Run At'), 'index' => 'started_at', 'type' => 'datetime', 'width' => 150));
        $this->addColumn('source', array(
            'header' => $h->__('Trigger'), 'index' => 'source', 'width' => 80,
            'type' => 'options', 'options' => array('cron' => 'Cron', 'manual' => 'Manual'),
        ));
        $this->addColumn('status', array(
            'header' => $h->__('Status'), 'index' => 'status', 'width' => 90,
            'type' => 'options', 'options' => array('success' => 'Success', 'partial' => 'Partial', 'failed' => 'Failed'),
            'frame_callback' => array($this, 'decorateStatus'),
        ));
        $this->addColumn('ok_count', array('header' => $h->__('OK'), 'index' => 'ok_count', 'width' => 50, 'type' => 'number'));
        $this->addColumn('fail_count', array('header' => $h->__('Failed'), 'index' => 'fail_count', 'width' => 60, 'type' => 'number'));
        $this->addColumn('duration_seconds', array('header' => $h->__('Duration (s)'), 'index' => 'duration_seconds', 'width' => 100, 'type' => 'number'));
        $this->addColumn('summary', array(
            'header' => $h->__('Indexes'), 'index' => 'summary', 'sortable' => false, 'filter' => false,
            'frame_callback' => array($this, 'decorateSummary'),
        ));
        return parent::_prepareColumns();
    }

    public function decorateStatus($value, $row)
    {
        $s = $row->getStatus();
        $color = $s === 'success' ? '#16a34a' : ($s === 'failed' ? '#dc2626' : '#d97706');
        return '<span style="color:' . $color . ';font-weight:600;">' . $this->escapeHtml($value) . '</span>';
    }

    public function decorateSummary($value, $row)
    {
        $data = json_decode((string) $value, true);
        if (!is_array($data)) {
            return $this->escapeHtml((string) $value);
        }
        $parts = array();
        foreach ($data as $code => $res) {
            $ok = $res === 'ok';
            $title = $ok ? '' : ' title="' . $this->escapeHtml((string) $res) . '"';
            $parts[] = '<span' . $title . ' style="color:' . ($ok ? '#16a34a' : '#dc2626') . ';">' . $this->escapeHtml($code) . '</span>';
        }
        return '<span style="font-size:11px;line-height:1.7;">' . implode(', ', $parts) . '</span>';
    }

    public function getGridUrl()
    {
        return $this->getUrl('*/*/grid', array('_current' => true));
    }

    public function getRowUrl($row)
    {
        return false;
    }
}
