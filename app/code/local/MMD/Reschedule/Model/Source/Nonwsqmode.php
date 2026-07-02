<?php
class MMD_Reschedule_Model_Source_Nonwsqmode
{
    public function toOptionArray()
    {
        return array(
            array('value' => 'manual', 'label' => 'Manual — staff approve each request in the admin grid'),
            array('value' => 'auto',   'label' => 'Auto — acknowledge on submission (staff still reschedules manually)'),
        );
    }
}
