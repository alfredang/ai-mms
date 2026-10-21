<?php
/** Cross-runtime hash/contract check. Reads only JSON from stdin; no Magento/DB bootstrap. */
require dirname(__DIR__,2).'/app/code/local/MMD/Courses/Model/TmsContract.php';
$data=json_decode(stream_get_contents(STDIN),true,64,JSON_THROW_ON_ERROR);
MMD_Courses_Model_TmsContract::validate($data);
echo "PASS: TMS-to-MMS JSON contract and content hash\n";
