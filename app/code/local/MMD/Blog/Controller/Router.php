<?php
/**
 * Slug router for the blog — same mechanism as Mage_Cms_Controller_Router.
 *
 * /blog                -> handled by the standard router (blog/index/index).
 * /blog/tag/<name>     -> blog/index/tag,  param tag=<name>
 * /blog/<url_key>      -> blog/index/view, param id=<post_id>  (published only)
 *
 * Runs after the standard router: it only sees /blog/* paths the standard
 * router could not dispatch. Returning true re-enters the router loop, where
 * the standard router dispatches the module/controller/action set here.
 */
class MMD_Blog_Controller_Router extends Mage_Core_Controller_Varien_Router_Abstract
{
    /** controller_front_init_routers observer — same wiring as Mage_Cms. */
    public function initControllerRouters($observer)
    {
        $observer->getEvent()->getFront()->addRouter('mmd_blog_slug', $this);
    }

    public function match(Zend_Controller_Request_Http $request)
    {
        $path = trim($request->getPathInfo(), '/');
        if ($path === 'blog' || strpos($path, 'blog/') !== 0) {
            return false;
        }
        $rest = substr($path, strlen('blog/'));

        if (strpos($rest, 'tag/') === 0) {
            $tag = urldecode(substr($rest, strlen('tag/')));
            if ($tag === '') {
                return false;
            }
            $request->setModuleName('blog')
                ->setControllerName('index')
                ->setActionName('tag')
                ->setParam('tag', $tag);
            $request->setAlias(Mage_Core_Model_Url_Rewrite::REWRITE_REQUEST_PATH_ALIAS, $path);
            return true;
        }

        // Single path segment only — anything deeper is not a post slug.
        if (strpos($rest, '/') !== false) {
            return false;
        }

        $post = Mage::getModel('mmd_blog/post')->loadByUrlKey($rest);
        if (!$post->getId() || !$post->isPublished()) {
            return false;
        }

        $request->setModuleName('blog')
            ->setControllerName('index')
            ->setActionName('view')
            ->setParam('id', $post->getId());
        $request->setAlias(Mage_Core_Model_Url_Rewrite::REWRITE_REQUEST_PATH_ALIAS, $path);
        return true;
    }
}
