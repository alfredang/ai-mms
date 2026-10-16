<?php

class Infortis_Infortis_Helper_Image extends Mage_Core_Helper_Abstract
{
	/**
	 * Get image URL of the given product
	 *
	 * @param Mage_Catalog_Model_Product	$product		Product
	 * @param int							$w				Image width
	 * @param int							$h				Image height
	 * @param string						$imgVersion		Image version: image, small_image, thumbnail
	 * @param mixed							$file			Specific file
	 * @return string
	 */
	public function getImg($product, $w, $h, $imgVersion='image', $file=NULL)
	{
		// If course_image_url is set, use it directly (external URL)
		$courseImgUrl = trim((string) $product->getData('course_image_url'));
		if ($courseImgUrl !== '') {
			return $courseImgUrl;
		}

		$url = '';
		if ($h <= 0)
		{
			$url = Mage::helper('catalog/image')
				->init($product, $imgVersion, $file)
				->constrainOnly(true)
				->keepAspectRatio(true)
				->keepFrame(false)
				//->setQuality(90)
				->resize($w);
		}
		else
		{
			$url = Mage::helper('catalog/image')
				->init($product, $imgVersion, $file)
				->resize($w, $h);
		}
		return $url;
	}

	/**
	 * width/height attributes matching the URL getImg() returns, so the browser
	 * reserves the image's box before it loads (no layout shift). height:auto is
	 * inline so the height attribute can never stretch the image, even while a
	 * browser still has an older custom.css cached (custom.css repeats it).
	 * Course covers are 1600x900. Callers' <img> tags must not have a style attribute.
	 *
	 * @return string e.g. ' width="1600" height="900" style="height:auto"', or '' when unknown
	 */
	public function getImgSizeAttr($product, $w, $h)
	{
		if (trim((string) $product->getData('course_image_url')) !== '') {
			return ' width="1600" height="900" style="height:auto"';
		}
		return ($w > 0 && $h > 0) ? ' width="' . (int) $w . '" height="' . (int) $h . '" style="height:auto"' : '';
	}
}
