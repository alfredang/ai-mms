<?php
class MMD_Reschedule_Block_Adminhtml_Reschedulelead_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setId('rescheduleLeadGrid');
        $this->setDefaultSort('created_at');
        $this->setDefaultDir('DESC');
        $this->setSaveParametersInSession(true);
        $this->setUseAjax(true);
    }

    protected function _prepareCollection()
    {
        $this->setCollection(Mage::getModel('mmd_reschedule/lead')->getCollection());
        return parent::_prepareCollection();
    }

    protected function _prepareColumns()
    {
        $h = Mage::helper('mmd_reschedule');

        $this->addColumn('lead_id', array(
            'header' => $h->__('ID'), 'index' => 'lead_id', 'width' => 50,
        ));
        $this->addColumn('created_at', array(
            'header' => $h->__('Submitted'), 'index' => 'created_at', 'type' => 'datetime', 'width' => 140,
        ));
        $this->addColumn('name', array(
            'header' => $h->__('Name'), 'index' => 'name',
        ));
        $this->addColumn('email', array(
            'header' => $h->__('Email'), 'index' => 'email',
        ));
        $this->addColumn('telephone', array(
            'header' => $h->__('Phone'), 'index' => 'telephone', 'width' => 120,
        ));
        $this->addColumn('course_code', array(
            'header' => $h->__('Code'), 'index' => 'course_code', 'width' => 90,
        ));
        $this->addColumn('course', array(
            'header' => $h->__('Course Title'), 'index' => 'course',
        ));
        $this->addColumn('course_start_date', array(
            'header' => $h->__('Class Date'), 'index' => 'course_start_date', 'width' => 110,
        ));
        $this->addColumn('next_course_start_date', array(
            'header' => $h->__('Preferred Date'), 'index' => 'next_course_start_date', 'width' => 120,
        ));
        $this->addColumn('is_wsq', array(
            'header'  => $h->__('WSQ'),
            'index'   => 'is_wsq',
            'width'   => 55,
            'type'    => 'options',
            'options' => array(0 => 'No', 1 => 'Yes'),
        ));
        $this->addColumn('lms_status', array(
            'header'  => $h->__('LMS'),
            'index'   => 'lms_status',
            'width'   => 110,
            'type'    => 'options',
            'options' => array(
                ''             => '—',
                'pending_push' => 'Pending push',
                'pushed'       => 'Pushed',
                'failed'       => 'Push failed',
            ),
        ));
        $this->addColumn('status', array(
            'header'  => $h->__('Status'),
            'index'   => 'status',
            'width'   => 90,
            'type'    => 'options',
            'options' => array('new' => 'New', 'confirmed' => 'Confirmed', 'closed' => 'Closed'),
        ));
        $this->addColumn('action', array(
            'header'   => $h->__('Action'),
            'width'    => 150,
            'type'     => 'action',
            'getter'   => 'getId',
            'filter'   => false,
            'sortable' => false,
            'actions'  => array(
                array(
                    'caption' => $h->__('Approve'),
                    'url'     => array('base' => '*/*/approve'),
                    'field'   => 'id',
                ),
                array(
                    'caption' => $h->__('Close'),
                    'url'     => array('base' => '*/*/close'),
                    'field'   => 'id',
                ),
                array(
                    'caption' => $h->__('Resend to LMS'),
                    'url'     => array('base' => '*/*/resendlms'),
                    'field'   => 'id',
                ),
            ),
        ));

        return parent::_prepareColumns();
    }

    public function getGridUrl()
    {
        return $this->getUrl('*/*/grid', array('_current' => true));
    }

    public function getRowUrl($r)
    {
        return false;
    }
}
