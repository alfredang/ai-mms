<?php
/**
 * Adds the "Featured" checkbox to the stock review edit form.
 *
 * A featured review is what the storefront homepage strip and /testimonials
 * draw from. The flag itself is persisted by MMD_Reviews_Model_Observer on
 * `review_save_after`.
 */
class MMD_Reviews_Block_Adminhtml_Edit_Form extends Mage_Adminhtml_Block_Review_Edit_Form
{
    protected function _prepareForm()
    {
        parent::_prepareForm();

        $form = $this->getForm();
        if (!$form || !($fieldset = $form->getElement('review_details'))) {
            return $this;
        }

        $review = Mage::registry('review_data');

        // An unchecked checkbox posts nothing, which would make the observer's
        // hasData() guard treat "unfeatured" as "not submitted" and silently
        // keep the flag on. The hidden field always posts 0; the checkbox
        // (same name, rendered after) overrides it with 1 when ticked.
        $fieldset->addField('is_featured_default', 'hidden', array(
            'name'  => 'is_featured',
            'value' => 0,
        ));

        $fieldset->addField('is_featured', 'checkbox', array(
            'label'   => Mage::helper('review')->__('Featured'),
            'name'    => 'is_featured',
            'value'   => 1,
            'checked' => (bool) $review->getIsFeatured(),
            'note'    => Mage::helper('review')->__(
                'Show this review on the homepage testimonials strip and the Testimonials page. Only approved reviews are shown.'
            ),
        ));

        return $this;
    }
}
