<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Mmdfilepatcher extends MMD_Mmdsys_Abstract_Model
{
    private $_aChanges = array();
    
    public function parsePatch($sPatchStr, $bSaveEmpty = true)
    {
        $this->_aChanges = array();
        $aStrings     = explode("\n", $sPatchStr);
        $iCurrentLine = 0;
        $iLinesCount  = count($aStrings);
        
        //look all strings
        while($iCurrentLine < $iLinesCount)
        {
            //if at current line begin new change
            if ('diff' == substr($aStrings[$iCurrentLine],0,4))
            {
                //go to string with name of destination file
                $iCurrentLine += 2;
                //find name of destination file
                preg_match("!^\+\+\+ ([^\s]*)!", $aStrings[$iCurrentLine], $aRes);
                if(isset($aRes[1]))
                {
                    //init array with changes for current file
                    $aFileChanges = array(
                        'file'          => substr($aRes[1],2),
                        'aChanges'      => array(),
                    );    
                    //go to line with count changed strings (like:" @@ -101,5 +101,9 @@")
                    $iCurrentLine++;
                    //wile next diff-line not found grabbing lines with changes
                    while( $iCurrentLine < $iLinesCount and 'diff' != substr($aStrings[$iCurrentLine], 0, 4) )
                    {
                        //get numbers of begin string, count strings in phpFox file,  begin string, count strings in patched file
                        $aRes = array();
                        preg_match("!@@ -(\d+)(,(\d+))? \+(\d+)(,(\d+))? @@!",$aStrings[$iCurrentLine],$aRes);
                        if(isset($aRes[1]))
                        {
                            $aChange = array(
                                'iBeginStr'         => intval($aRes[1]),
                                'iCountStr'         => isset($aRes[3])? intval($aRes[3]): $aChange['iBeginStr'],
                                'iBeginStrInModule' => intval($aRes[4]),
                                'iCountStrInModule' => isset($aRes[6])? intval($aRes[6]): $aChange['iCountStr'],
                                'aChangingStrings'  => array(),
                            );
                            //go to first line with script changes
                            ++$iCurrentLine;
                            //while next changes-block not found grabbing changes
                            while($iCurrentLine < $iLinesCount and in_array(substr($aStrings[$iCurrentLine], 0, 1), array(' ','+','-','\\')) )
                            {
                                $sFirstChar = substr($aStrings[$iCurrentLine],0,1);
                                $sStr = substr($aStrings[$iCurrentLine],1);
                                $sStrTrim = trim($sStr);
                                if('\\'!=$sFirstChar && ($bSaveEmpty || $sStrTrim))
                                {
                                    //if not comment or warning save line info
                                    $aChange['aChangingStrings'][] = array( $sFirstChar, $sStrTrim, $sStr);
                                }
                                //go to next line
                                ++$iCurrentLine;
                            }  
                            //add changes-block to changes of current file
                            $aFileChanges['aChanges'][] = $aChange;
                        }else{
                            //if numbers of begin string, count strings in phpFox file,  begin string, count strings in patched file not found
                            // ERROR
                            ++$iCurrentLine;
                        }
                    }
                    //add changes of current file to $this->aChangeList
                    $this->_aChanges[] = $aFileChanges;
                    
                }else{
                    //if in second line after diff-line script can not find name of destination file
                    // ERROR
                    ++$iCurrentLine;
                }
            }else{
                ++$iCurrentLine;
            }
        }
        return $this->_aChanges;
    }
    
    public function applyPatch($sApplyPatchTo)
    {
        $aErrors = array();
        $aCurrentResultLines = $this->_getLinesWithModulesData($sApplyPatchTo);
        $bThisModule = FALSE;
        
        foreach ($this->_aChanges as $aFileChange)
        {
            foreach($aFileChange['aChanges'] as $iCurrentChange => $aChangeData)
            {
                $aTmpResult = array();
                $iChangePoint = $this->_findChangesPoint($this->_getLinesWithoutModulesData($sApplyPatchTo), $aChangeData, array(' ', '-'));
                $iCurrentFileLine = 0;
                $iCntFileLine = count($aCurrentResultLines);
                
                // copy lines before $iChangePoint
                while( ('*'==$aCurrentResultLines[$iCurrentFileLine]['sType'] || ($iChangePoint!=$aCurrentResultLines[$iCurrentFileLine]['iPhpFoxLine'])) && $iCurrentFileLine<$iCntFileLine)
                {
                    $aTmpResult[] = $aCurrentResultLines[$iCurrentFileLine];
                    ++$iCurrentFileLine;
                }
                
                //insert changes
                foreach($aChangeData['aChangingStrings'] as $iPatchLine => $aStrInfo)
                {
                        //if PatchLine is FoxLine
                        if (' ' == $aStrInfo[0])
                        {
                            //close module comment if need
                            if($bThisModule)
                            {
                                /*
                                $sCommentStr = $this->_makeStrComment('end', $aFileChange['file']);
                                $aTmpResult[] = array(
                                    'iPhpFoxLine'   => FALSE,
                                    'sType'         => '*',
                                    'sStr'          => $sCommentStr,
                                    'sStrBefore'    => $sCommentStr,
                                    );
                                */
                                $bThisModule = FALSE;
                            }
                                
                            //copy empty strings from base file (before changes)
    
                            while( ($iCurrentFileLine < $iCntFileLine) && $aCurrentResultLines[$iCurrentFileLine]['sStr'] !== $aStrInfo[1])
                            {
                                $aTmpResult[] = $aCurrentResultLines[$iCurrentFileLine];
                                $iCurrentFileLine++;
                            }
    
                            //insert current string from base file
                            if ( isset($aCurrentResultLines[$iCurrentFileLine]) && $aCurrentResultLines[$iCurrentFileLine]['sStr'] === $aStrInfo[1] )
                            {
                                    $aTmpResult[] = $aCurrentResultLines[$iCurrentFileLine];
                                    $iCurrentFileLine++;
                                
                            }else{
                                $aErrors[] =  'Error patching';
                                break(2);
                            }
                        }
                        
                        //if New string
                        if ('+' == $aStrInfo[0])
                        {
                            if(!$bThisModule)
                            {
                                /*
                                $sCommentStr = $this->_makeStrComment('begin', $aFileChange['file']);
                                $aTmpResult[] = array(
                                    'iPhpFoxLine'   => FALSE,
                                    'sType'         => '*',
                                    'sStr'          => $sCommentStr,
                                    'sStrBefore'    => $sCommentStr . PHP_EOL,
                                    );
                                    
                                $sCommentStr = $this->_makeStrComment('module', $aFileChange['file']);
                                $aTmpResult[] = array(
                                    'iPhpFoxLine'   => FALSE,
                                    'sType'         => '*',
                                    'sStr'          => $sCommentStr,
                                    'sStrBefore'    => $sCommentStr . PHP_EOL,
                                    );
                                */
                                $bThisModule = TRUE;
                            }
                            $aTmpResult[] = array(
                                    'iPhpFoxLine'   => FALSE,
                                    'sType'         => '*',
                                    'sStr'          => $aStrInfo[1],
                                    'sStrBefore'    => $aStrInfo[2] . PHP_EOL,
                                    );
                        }
                        
                        if('-'==$aStrInfo[0])
                        {
                            if ( !isset($aCurrentResultLines[$iCurrentFileLine]) || $aCurrentResultLines[$iCurrentFileLine]['sStr'] !== $aStrInfo[1] )
                            {
                                $aErrors[] = 'Error patching';;
                                break(2);
                            }
                            $iCurrentFileLine++;
                        }
                        // end process current patch-line
                }
    
                if($bThisModule)
                {
                    /*
                    $sCommentStr = $this->_makeStrComment('end', $aFileChange['file']);
                    $aTmpResult[] = array(
                                    'iPhpFoxLine'   => FALSE,
                                    'sType'         => '*',
                                    'sStr'          => $sCommentStr,
                                    'sStrBefore'    => $sCommentStr,
                                    );
                    */
                    $bThisModule = FALSE;
                }
                
                //keep other file strings
                
                while($iCurrentFileLine<$iCntFileLine)
                {
                    $aTmpResult[] = $aCurrentResultLines[$iCurrentFileLine++];
                }
                
                $aCurrentResultLines = $aTmpResult;
                // end process current changes
    
            }// end changes
        }
        
        // write $aResult in to to file $aFileChange['file']
        if ( 0==count($aErrors) )
        {
            if($hFile = fopen($sApplyPatchTo, 'w') )
            {
                if (strstr($sApplyPatchTo,'.phtml'))
                {
                    $comment = 
                "<?php /* !!!ATTENTION!!! PLEASE DO NOT MODIFY THE FILE! 
Copy it preserving its path from the var/mmd_path folder to the
app folder. i.e. in var/mmd_path folder the file is located in folder 1, 
then in the app folder you also need to make folder 1 and put the file in it.
*/ ?>";
                    fwrite($hFile,$comment);
                }
                foreach($aCurrentResultLines as $aStrInfo)
                {
                    if (fwrite($hFile, $aStrInfo['sStrBefore']) === FALSE) {
                        $sMsg = 'Error writing to file';
                        $aErrors[] = $sMsg;
                        break;
                    }
                }
                fclose($hFile);
                
            }
            else
            {
                $sMsg =  'Error opening file';
                $aErrors[] = $sMsg;
            }
        }
    
        unset($aCurrentResultLines);
    }
    
    public function canApplyChanges($sFileToPatch)
    {
        $aLines = $this->_getLinesWithoutModulesData($sFileToPatch);
        $bResult = TRUE;
        foreach ($this->_aChanges as $aFileChange)
        {
            foreach($aFileChange['aChanges'] as $aChangeData)
            {
                if (FALSE===$this->_findChangesPoint($aLines, $aChangeData, array(' ', )))
                {
                    $bResult = FALSE;
                    break;
                }
            }
        }
        return $bResult;
    }
    
    /**
     * $aCangesTypes array chars, it's can be: ' ','+','-' (types of strings in patch)
     */
    function _findChangesPoint($aLines, $aChangeData, $aCangesTypes )
    {
        $iCntPatchLines = count($aChangeData['aChangingStrings']);
        $iCntFoxLines = count($aLines);
        $aStartMatches = array();
        for($iFoxLine=$aChangeData['iBeginStr']-1; $iFoxLine < $iCntFoxLines; ++$iFoxLine)
        {
            $bPointOfMatch = TRUE;
            $iCurFoxLine = $iFoxLine;
            for($iCurPatchLine=0 ; ($bPointOfMatch && ($iCurPatchLine<$iCntPatchLines) && ($iCurFoxLine < $iCntFoxLines) ) ; ++$iCurPatchLine)
            {
                if ( in_array( $aChangeData['aChangingStrings'][$iCurPatchLine][0], $aCangesTypes ))
                {
                    //d('fox:'.$aLines[$iCurFoxLine]['sStr'].'=='.$aChangeData['aChangingStrings'][$iCurPatchLine][1]);
                    if($aLines[$iCurFoxLine]['sStr'] != $aChangeData['aChangingStrings'][$iCurPatchLine][1])
                    {
                        $bPointOfMatch = FALSE;
                    }
                    //else{d('$iCurFoxLine='.$iCurFoxLine);}
                    ++$iCurFoxLine;
                }
            }
            if($bPointOfMatch AND $iCurPatchLine == $iCntPatchLines)
            {
                //$aStartMatches[] =  $aLines[$iFoxLine]['iPhpFoxLine'];
                return $aLines[$iFoxLine]['iPhpFoxLine'];
            }
        }
        return (1 == count($aStartMatches))? $aStartMatches[0] : FALSE;
    }
    
/** get lines with other modules data
     * @param string $sFile File name
     * @return array lines with other modules data
     * @access private
     */ 
    function _getLinesWithModulesData($sFile)//, $bSaveThisModule=TRUE
    {
        if(!file_exists($sFile))
        {
            $aErrors[] = 'No File';
            return array();
        }
        $aLines = file($sFile);
        $aResult = array();
        $iPhpFoxLineNum = 0;
        $iFileLineNum = 0;
        $bModulesString = FALSE;
        $bThisModuleString = FALSE;
        foreach($aLines as $i => $sStr)
        {
            $sStr = trim($aLines[$i]);
            //if($bSaveEmpty || $sStr)
            {
                /*
                if ($this->_isModuleComment($sStr, 'begin', $sFile))
                {
                    $bModulesString = TRUE;
                    if ($this->_isModuleComment($aLines[$i+1], 'module', $sFile ))
                    {
                        $bThisModuleString = TRUE;
                    }
                }
                */
                
                // $bThisModuleString is always false for now :)
                if(!$bThisModuleString)
                {
                    $aResult[$iFileLineNum] = array(
                        'iPhpFoxLine'   => $bModulesString? 0:$iPhpFoxLineNum,
                        'sType'         => $bModulesString? '*': ' ',
                        'sStr'          => $sStr,
                        'sStrBefore'    => $aLines[$i],
                        );
                    ++$iFileLineNum;
                    ++$iPhpFoxLineNum;
                }
                
                /*
                if ($this->_isModuleComment($sStr, 'end', $sFile))
                {
                    $bModulesString = FALSE;
                    $bThisModuleString = FALSE;
                }
                */
            }
        }
        return $aResult;
    }
    
    /** get lines without any modules data
     * @param string $sFile File name
     * @return array lines without any modules data
     * @access private
     */ 
    private function _getLinesWithoutModulesData($sFile, $bSaveThisModule=FALSE, $bSaveEmpty = true)
    {
        if(!file_exists($sFile))
        {
            $aErrors[] = 'No File';
            return array();
        }
        
        $aLines = file($sFile);
        $aResult = array();
        $bEgnoreString = FALSE;
        $iCntFoxLines = count($aLines);
        $iFoxLineNum = 0;
        for($i=0; $i<$iCntFoxLines ; ++$i)
        {
            //cut empty strings
            $sStr = trim($aLines[$i]);
            if($bSaveEmpty || $sStr)
            {
                /*
                if ($this->_isModuleComment($sStr, 'begin', $sFile))
                {
                    if($bSaveThisModule)
                    {
                        //find next string (not empty string)
                        $sNextStr = '';
                        while( (++$i<$iCntFoxLines) && (!$sNextStr = trim($aLines[$i])) ) {}
                        if($sNextStr)
                        {
                            if (!$this->_isModuleComment($sNextStr, 'module', $sFile ))
                            {
                                $bEgnoreString = TRUE;
                            }
                        }
                    }else
                    {
                        $bEgnoreString = TRUE;
                    }
                }
                elseif ($this->_isModuleComment($sStr, 'end', $sFile))
                {
                    $bEgnoreString = FALSE;
                }
                elseif(!$bEgnoreString) // $bEgnoreString is allways false for now
                */
                {
                    $aResult[] = array('iPhpFoxLine'=>$iFoxLineNum,'sType'=>' ', 'sStr'=> $sStr);
                    ++$iFoxLineNum;
                }
            }
            
        }
        return $aResult;
    }
    
    /** check if string is this Module Comment
     * DEPRECATED
     * 
     * @param string $sStr checking string
     * @param string $sType `begin` or `end` or `module`
     * @param string $sFile Name of file for that make comment 
     * @return boolean if string is this Module Comment return true
     * @access private 
     */ 
    private function _isModuleComment($sStr, $sType, $sFile)
    {
        $sComment = $this->_makeStrComment($sType, $sFile);
        if(!$sComment)
        {
            return FALSE;
        }else{
            return ( FALSE !== strpos(trim($sStr),trim($sComment)) );
        }
    }
    
    /** make String with comment 
     * DEPRECATED
     * 
     * @param string $sType `begin` or `end` or `module`
     * @param string $sFile Name of file for that make comment 
     * @return string Comment string
     * @access private 
     */ 
    function _makeStrComment($sType, $sFile)
    {
        $sResult = '';
        switch($sType)
        {
            case 'begin': 
                $sText = 'BEGIN MMD Module';
                break;
            case 'end':
                $sText = 'END MMD Module';
                break;
            case 'module':
                $sText = 'TEST MOD';
                break;
            default:
                $sText = '';
                
        }
        $aBeginTags = array(
                            'php'   =>'/***',
                            'html'  =>'<!--',
                            'phtml'  =>'<!--',
                            'htaccess'=> '#***'
                        );
        $aEndTags = array(
                            'php'   =>'***/',
                            'html'  =>'-->',
                            'phtml'  =>'-->',
                            'htaccess'=> '***#'
                        );
        $sFileType = substr($sFile, strrpos($sFile,'.')+1);
        if (isset($aBeginTags[$sFileType]) AND isset($aEndTags[$sFileType]))
        {
            $sResult = $aBeginTags[$sFileType].' '.$sText.' '.$aEndTags[$sFileType].PHP_EOL;
        }else{
            //$this->aErrors[] = 'Unknown comment file type - `'.$sFileType.'`';
        }
        
        return $sResult;
    }
    
    public function getChangeList()
    {
        return $this->_aChanges;
    }
    
}