<?php
class MMD_FeedbackForm_Helper_Data extends Mage_Core_Helper_Abstract
{
    const AUTOFILL_COURSE_TITLE = 'course_title';
    const AUTOFILL_COURSE_CODE  = 'course_code';
    const AUTOFILL_START_DATE   = 'start_date';
    const AUTOFILL_END_DATE     = 'end_date';
    const AUTOFILL_TRAINER_NAME = 'trainer_name';

    public function getDefaultTemplate()
    {
        return array(
            'title'    => 'Course Feedback Form',
            'sections' => array(
                array(
                    'id'     => 's1',
                    'title'  => 'Your Details',
                    'fields' => array(
                        array('id'=>'f1','label'=>'Course Title',     'type'=>'text',  'autofill'=>'course_title', 'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f2','label'=>'Course Code',      'type'=>'text',  'autofill'=>'course_code',  'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f3','label'=>'Trainer',          'type'=>'text',  'autofill'=>'trainer_name', 'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f4','label'=>'Your Full Name',   'type'=>'text',  'autofill'=>'',             'readonly'=>false, 'required'=>true, 'options'=>''),
                        array('id'=>'f5','label'=>'Class Start Date', 'type'=>'date',  'autofill'=>'start_date',   'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f6','label'=>'Class End Date',   'type'=>'date',  'autofill'=>'end_date',     'readonly'=>true,  'required'=>false,'options'=>''),
                    ),
                ),
                array(
                    'id'     => 's2',
                    'title'  => 'Course Evaluation',
                    'fields' => array(
                        array('id'=>'f7','label'=>'Overall, how would you rate the course meeting the learning objectives?', 'type'=>'rating1to5','autofill'=>'','readonly'=>false,'required'=>true, 'options'=>''),
                        array('id'=>'f8','label'=>'Overall, how would you rate the trainer\'s knowledge in this subject matter?',  'type'=>'rating1to5','autofill'=>'','readonly'=>false,'required'=>true, 'options'=>''),
                        array('id'=>'f9','label'=>'Overall, how would you rate the training environment?', 'type'=>'rating1to5','autofill'=>'','readonly'=>false,'required'=>true, 'options'=>''),
                        array('id'=>'f10','label'=>'Additional comments (optional)', 'type'=>'textarea','autofill'=>'','readonly'=>false,'required'=>false,'options'=>''),
                    ),
                ),
            ),
        );
    }

}
