#!/usr/bin/env python3
"""Generate a PHP script that creates (on the partner) the categories SG has but the partner
lacks, via the catalog/category MODEL (builds path/url_rewrite/indexes correctly). PARTNER-ONLY.

Input:  create_rows.tsv = url_key <TAB> parent_url_key <TAB> position <TAB> name <TAB> is_active
        <TAB> include_in_menu <TAB> is_anchor <TAB> display_mode <TAB> image(or \\N) <TAB> base64(description)
        (dump from SG for each missing url_key; resolve its parent url_key too)
Output: create_categories.php  — copy into the partner web container and run:
   ssh $HOST 'docker exec -i $WEB sh -c "cat > /tmp/create.php"' < create_categories.php
   ssh $HOST 'docker exec $WEB php -l /tmp/create.php && docker exec $WEB php /tmp/create.php'
Then reindex catalog_url + catalog_category_flat + flush.
"""
import sys, base64
W = sys.argv[1] if len(sys.argv) > 1 else "/tmp/parity"
def php(s):
    return "null" if s is None else "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"
rows = []
for l in open(f"{W}/create_rows.tsv"):
    f = l.rstrip("\n").split("\t")
    if len(f) < 10: continue
    img = None if f[8] in ("\\N", "") else f[8]
    rows.append(f[:8] + [img, f[9]])
L = ["<?php", "require '/var/www/html/app/Mage.php';", "Mage::app('admin');", "umask(0);",
     "Mage::register('isSecureArea', true);",
     "function ghCat($uk){$c=Mage::getModel('catalog/category')->getCollection()->addAttributeToFilter('url_key',$uk)->setPageSize(1);$c->load();$i=$c->getFirstItem();return $i->getId()?$i:null;}",
     "$recs=array("]
for r in rows:
    L.append("array('url_key'=>%s,'parent'=>%s,'position'=>%s,'name'=>%s,'is_active'=>%s,'include_in_menu'=>%s,'is_anchor'=>%s,'display_mode'=>%s,'image'=>%s,'descb64'=>%s),"
             % (php(r[0]), php(r[1]), r[2], php(r[3]), r[4], r[5], r[6], php(r[7]), php(r[8]), php(r[9])))
L += [");", "foreach($recs as $r){",
      "  if(ghCat($r['url_key'])){echo 'EXISTS '.$r['url_key'].PHP_EOL;continue;}",
      "  $p=ghCat($r['parent']); if(!$p){echo 'NO PARENT '.$r['url_key'].' <- '.$r['parent'].PHP_EOL;continue;}",
      "  $c=Mage::getModel('catalog/category'); $c->setStoreId(0);",
      "  $d=array('name'=>$r['name'],'url_key'=>$r['url_key'],'is_active'=>$r['is_active'],'include_in_menu'=>$r['include_in_menu'],'is_anchor'=>$r['is_anchor'],'display_mode'=>$r['display_mode'],'position'=>$r['position']);",
      "  if($r['descb64']!==''){$d['description']=base64_decode($r['descb64']);}",
      "  if($r['image']!==null){$d['image']=$r['image'];}",
      "  $c->addData($d); $c->setPath($p->getPath()); $c->setParentId($p->getId()); $c->setLevel($p->getLevel()+1);",
      "  try{$c->save(); echo 'CREATED '.$r['url_key'].' id='.$c->getId().' path='.$c->getPath().PHP_EOL;}",
      "  catch(Exception $e){echo 'ERROR '.$r['url_key'].': '.$e->getMessage().PHP_EOL;}",
      "}", "echo 'done'.PHP_EOL;"]
open(f"{W}/create_categories.php", "w").write("\n".join(L) + "\n")
print(f"wrote create_categories.php with {len(rows)} categories")
