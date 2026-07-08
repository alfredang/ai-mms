<?php
class MMD_Blog_Block_Adminhtml_Post_Grid extends Mage_Adminhtml_Block_Widget_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setId('mmd_blog_post_grid');
        $this->setDefaultSort('post_id');
        $this->setDefaultDir('DESC');
        $this->setSaveParametersInSession(true);
    }

    protected function _prepareCollection()
    {
        $this->setCollection(Mage::getModel('mmd_blog/post')->getCollection());
        return parent::_prepareCollection();
    }

    protected function _prepareColumns()
    {
        $helper = Mage::helper('mmd_blog');

        $this->addColumn('post_id', array(
            'header' => $helper->__('ID'),
            'index'  => 'post_id',
            'width'  => '50px',
            'type'   => 'number',
        ));
        $this->addColumn('title', array(
            'header' => $helper->__('Title'),
            'index'  => 'title',
        ));
        $this->addColumn('url_key', array(
            'header' => $helper->__('Slug'),
            'index'  => 'url_key',
        ));
        $this->addColumn('status', array(
            'header'  => $helper->__('Status'),
            'index'   => 'status',
            'type'    => 'options',
            'width'   => '100px',
            'options' => array(
                MMD_Blog_Model_Post::STATUS_DRAFT     => $helper->__('Draft'),
                MMD_Blog_Model_Post::STATUS_PUBLISHED => $helper->__('Published'),
            ),
        ));
        $this->addColumn('likes', array(
            'header' => $helper->__('Likes'),
            'index'  => 'likes',
            'type'   => 'number',
            'width'  => '80px',
        ));
        $this->addColumn('related_skus', array(
            'header' => $helper->__('CTA Courses'),
            'index'  => 'related_skus',
        ));
        $this->addColumn('published_at', array(
            'header' => $helper->__('Published'),
            'index'  => 'published_at',
            'type'   => 'date',
            'width'  => '110px',
        ));
        $this->addColumn('updated_at', array(
            'header' => $helper->__('Updated'),
            'index'  => 'updated_at',
            'type'   => 'datetime',
            'width'  => '150px',
        ));
        $this->addColumn('action', array(
            'header'    => $helper->__('Action'),
            'width'     => '80px',
            'type'      => 'action',
            'getter'    => 'getId',
            'actions'   => array(
                array(
                    'caption' => $helper->__('Edit'),
                    'url'     => array('base' => '*/*/edit'),
                    'field'   => 'id',
                ),
                array(
                    'caption' => $helper->__('Delete'),
                    'url'     => array('base' => '*/*/delete'),
                    'field'   => 'id',
                    'confirm' => $helper->__('Delete this blog post? This cannot be undone.'),
                ),
            ),
            'filter'    => false,
            'sortable'  => false,
            'is_system' => true,
        ));
        return parent::_prepareColumns();
    }

    protected function _prepareMassaction()
    {
        $helper = Mage::helper('mmd_blog');
        $this->setMassactionIdField('post_id');
        $this->getMassactionBlock()->setFormFieldName('post_ids');

        $this->getMassactionBlock()->addItem('delete', array(
            'label'   => $helper->__('Delete'),
            'url'     => $this->getUrl('*/*/massDelete'),
            'confirm' => $helper->__('Delete the selected blog posts? This cannot be undone.'),
        ));
        $this->getMassactionBlock()->addItem('status', array(
            'label'      => $helper->__('Change status'),
            'url'        => $this->getUrl('*/*/massStatus'),
            'additional' => array(
                'status' => array(
                    'name'   => 'status',
                    'type'   => 'select',
                    'class'  => 'required-entry',
                    'label'  => $helper->__('Status'),
                    'values' => array(
                        MMD_Blog_Model_Post::STATUS_PUBLISHED => $helper->__('Published'),
                        MMD_Blog_Model_Post::STATUS_DRAFT     => $helper->__('Draft'),
                    ),
                ),
            ),
        ));
        return $this;
    }

    public function getRowUrl($row)
    {
        return $this->getUrl('*/*/edit', array('id' => $row->getId()));
    }
}
