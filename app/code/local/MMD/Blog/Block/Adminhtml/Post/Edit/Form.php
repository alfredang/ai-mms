<?php
/**
 * Blog post edit form — deliberately shaped like the CMS Page editor:
 * content + WYSIWYG, slug, SEO meta fieldset, plus blog-specific extras
 * (tags, hero image -> R2, lead-magnet CTA SKUs, LinkedIn share).
 */
class MMD_Blog_Block_Adminhtml_Post_Edit_Form extends Mage_Adminhtml_Block_Widget_Form
{
    protected function _prepareForm()
    {
        $helper = Mage::helper('mmd_blog');
        $post   = Mage::registry('current_blog_post');

        $form = new Varien_Data_Form(array(
            'id'      => 'edit_form',
            'action'  => $this->getUrl('*/*/save', array('id' => $post ? $post->getId() : null)),
            'method'  => 'post',
            'enctype' => 'multipart/form-data',
        ));
        $form->setUseContainer(true);
        $this->setForm($form);

        $fieldset = $form->addFieldset('content_fieldset', array('legend' => $helper->__('Post')));
        $fieldset->addField('title', 'text', array(
            'name'     => 'title',
            'label'    => $helper->__('Title'),
            'required' => true,
        ));
        $fieldset->addField('url_key', 'text', array(
            'name'  => 'url_key',
            'label' => $helper->__('URL Key (Slug)'),
            'note'  => $helper->__('Post lives at /blog/&lt;slug&gt;. Leave empty to generate from the title.'),
        ));
        $statusValues = array();
        foreach ($helper->statusOptions() as $code => $label) {
            $statusValues[] = array('value' => $code, 'label' => $label);
        }
        $fieldset->addField('status', 'select', array(
            'name'   => 'status',
            'label'  => $helper->__('Status'),
            'values' => $statusValues,
            'note'   => $helper->__('Setting Published shares the post to LinkedIn + Facebook (once). Pending Review / Scheduled are normally driven by the auto-blog approval flow.'),
        ));
        $fieldset->addField('published_at', 'date', array(
            'name'   => 'published_at',
            'label'  => $helper->__('Publish Date'),
            'image'  => $this->getSkinUrl('images/grid-cal.gif'),
            'format' => Mage::app()->getLocale()->getDateFormat(Mage_Core_Model_Locale::FORMAT_TYPE_SHORT),
        ));
        $fieldset->addField('author', 'text', array(
            'name'  => 'author',
            'label' => $helper->__('Author'),
        ));
        $fieldset->addField('hero_image', 'file', array(
            'name'  => 'hero_image',
            'label' => $helper->__('Hero Image'),
            'note'  => $post && $post->getHeroImageUrl()
                ? $helper->__('Current: <a href="%s" target="_blank" rel="noopener">%s</a> — uploading a new file replaces it (stored on Cloudflare R2).', $post->getHeroImageUrl(), $this->escapeHtml($post->getHeroImageUrl()))
                : $helper->__('Optional. Uploaded to Cloudflare R2 (like product images). Without one, a branded gradient banner is shown.'),
        ));
        $fieldset->addField('excerpt', 'textarea', array(
            'name'  => 'excerpt',
            'label' => $helper->__('Excerpt'),
            'note'  => $helper->__('Short teaser for the blog listing, meta description fallback and LinkedIn share.'),
            'style' => 'height:70px;',
        ));

        $wysiwygConfig = Mage::getSingleton('cms/wysiwyg_config')->getConfig(array(
            'add_variables' => false,
            'add_widgets'   => false,
        ));
        $fieldset->addField('content', 'editor', array(
            'name'     => 'content',
            'label'    => $helper->__('Content'),
            'required' => true,
            'style'    => 'height:420px;',
            'wysiwyg'  => true,
            'config'   => $wysiwygConfig,
        ));

        $lead = $form->addFieldset('lead_fieldset', array('legend' => $helper->__('Lead Magnet')));
        $lead->addField('related_skus', 'text', array(
            'name'  => 'related_skus',
            'label' => $helper->__('CTA Course SKUs'),
            'note'  => $helper->__('Comma-separated course SKUs (e.g. TGS-2025052468, C603). Rendered as "register now" cards with the WSQ funding / SkillsFuture Credit hook under the article. Every post should funnel readers to at least one course.'),
        ));
        $lead->addField('tags', 'text', array(
            'name'  => 'tags',
            // Not __('Tags') — the Mage_Tag locale CSV globally translates
            // "Tags" to "Funding Tags" (funding-badge rebrand).
            'label' => $helper->__('Blog Tags'),
            'note'  => $helper->__('Comma-separated. Shared with the Magento product tag vocabulary.'),
        ));
        if (Mage::helper('mmd_blog/linkedin')->isConfigured()) {
            $lead->addField('share_linkedin', 'checkbox', array(
                'name'    => 'share_linkedin',
                'label'   => $helper->__('Share on LinkedIn'),
                'value'   => 1,
                'checked' => false,
                'note'    => $helper->__('Post this article to LinkedIn when saving (published posts only).'),
            ));
        }

        $seo = $form->addFieldset('seo_fieldset', array('legend' => $helper->__('SEO Meta')));
        $seo->addField('meta_title', 'text', array(
            'name'  => 'meta_title',
            'label' => $helper->__('Meta Title'),
        ));
        $seo->addField('meta_description', 'textarea', array(
            'name'  => 'meta_description',
            'label' => $helper->__('Meta Description'),
            'style' => 'height:70px;',
        ));
        $seo->addField('meta_keywords', 'textarea', array(
            'name'  => 'meta_keywords',
            'label' => $helper->__('Meta Keywords'),
            'style' => 'height:50px;',
        ));

        if ($post) {
            $data = $post->getData();
            if ($post->getId()) {
                $data['tags'] = implode(', ', $helper->getPostTags($post->getId()));
            }
            $form->setValues($data);
        }
        return parent::_prepareForm();
    }
}
