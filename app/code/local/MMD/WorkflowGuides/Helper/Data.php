<?php
/**
 * Static content for the admin "Workflow Guides" page — an introductory,
 * step-by-step reference for the features each role actually has access
 * to. Content is a plain PHP array (no DB table) since guides are authored
 * by developers, not edited live by admins.
 */
class MMD_WorkflowGuides_Helper_Data extends Mage_Core_Helper_Abstract
{
    /** Roles that get a Workflow Guides tab at all. */
    public function allowedRoles()
    {
        return array('admin', 'trainer', 'developer');
    }

    public function isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed($this->allowedRoles());
    }

    /**
     * Returns the guide categories for a given role code, or an empty
     * array if the role has no guides defined.
     *
     * Shape: array of
     *   'label' => category label
     *   'icon'  => emoji shown next to the guide title in the content header
     *   'guides' => array of
     *     'id'    => slug used for the left-nav anchor
     *     'title' => guide title
     *     'path'  => tab path shown under the title ('' if none — e.g. a
     *                conceptual explainer with no admin screen)
     *     'steps' => array of ['type' => 'ACTION'|'LOGIC', 'title' => ..., 'description' => ...]
     */
    public function getGuidesForRole($roleCode)
    {
        $all = $this->_getAllGuides();
        return isset($all[$roleCode]) ? $all[$roleCode] : array();
    }

    protected function _getAllGuides()
    {
        $createClass = array(
            'id' => 'create-class',
            'title' => 'Create a Class',
            'path' => 'Dashboard → Create New Class',
            'steps' => array(
                array('type' => 'ACTION', 'title' => 'Enter the course', 'description' => 'Type the Course Reference Number (SKU / TGS code), or pick the course from the "Available Courses" dropdown.'),
                array('type' => 'ACTION', 'title' => 'Set the schedule', 'description' => 'Course Start Date / End Date and Start / End Time are required. Opening and closing registration dates and venue address details are optional.'),
                array('type' => 'ACTION', 'title' => 'Pick mode of training', 'description' => 'Required: Classroom Facilitated, Synchronous e-Learning, Asynchronous e-Learning, or Blended Learning.'),
                array('type' => 'ACTION', 'title' => 'Pick course vacancy', 'description' => 'Required: Available, Limited, or Fully Booked.'),
                array('type' => 'LOGIC', 'title' => 'Optionally assign a trainer now', 'description' => 'Check "Assign Trainer" to add a candidate at creation time, or skip and invite one later from the Trainers tab.'),
                array('type' => 'ACTION', 'title' => 'Save', 'description' => 'The class appears in All Classes with a generated Class ID (e.g. C000042).'),
            ),
        );

        $assignTrainer = array(
            'id' => 'assign-trainer',
            'title' => 'Assign a Trainer',
            'path' => 'Class Management → Trainers → Assign trainer',
            'steps' => array(
                array('type' => 'ACTION', 'title' => 'Find the class', 'description' => 'Locate the class row you want to staff.'),
                array('type' => 'ACTION', 'title' => 'Choose a trainer', 'description' => 'Select a trainer by name or email from the dropdown, then save the configuration.'),
                array('type' => 'LOGIC', 'title' => 'Check the status message', 'description' => 'An inline message confirms whether the invitation was sent successfully.'),
                array('type' => 'LOGIC', 'title' => 'Optional controls', 'description' => '"Pause Invite" and "Block Reply" can be toggled per class if you need to stop the invitation flow temporarily.'),
            ),
        );

        $takeAttendance = array(
            'id' => 'take-attendance',
            'title' => 'Take Attendance',
            'path' => 'Class Management → E-Attendance',
            'steps' => array(
                array('type' => 'ACTION', 'title' => 'Choose Active or Completed', 'description' => 'Switch tabs depending on whether the class has already ended.'),
                array('type' => 'ACTION', 'title' => 'Select the class', 'description' => 'Pick the class from the dropdown to load its roster.'),
                array('type' => 'ACTION', 'title' => 'Mark attendance', 'description' => 'Tick "Present" per learner. If left unticked, a "Reason of Absence" field appears.'),
                array('type' => 'ACTION', 'title' => 'Add a walk-in (optional)', 'description' => 'Use "Add Learner" to register someone who wasn’t already enrolled (Name + Email).'),
                array('type' => 'ACTION', 'title' => 'Save', 'description' => 'Commits the roster.'),
                array('type' => 'LOGIC', 'title' => 'Completed classes stay editable', 'description' => 'Attendance can still be corrected after the class has ended.'),
            ),
        );

        $feedback = array(
            'id' => 'feedback',
            'title' => 'Feedback',
            'path' => 'Feedback Form → Form Builder / Responses',
            'steps' => array(
                array('type' => 'ACTION', 'title' => 'Build the form', 'description' => 'In Form Builder, add questions (short text, long text, rating, multiple choice) and save — this becomes the single active template.'),
                array('type' => 'ACTION', 'title' => 'Review responses', 'description' => 'In Responses, search/filter by keyword or date range. The grid shows learner, course, class ID, trainer, submission date, and answers.'),
                array('type' => 'ACTION', 'title' => 'Edit or delete a response', 'description' => 'Both actions are available inline on each row.'),
                array('type' => 'LOGIC', 'title' => 'Learners submit from the storefront', 'description' => 'The admin only builds the form and reviews results — learners fill it out from the storefront, not the admin.'),
            ),
        );

        $certificateAdmin = array(
            'id' => 'certificate',
            'title' => 'Generate a Certificate',
            'path' => 'System Configuration → Certificates',
            'steps' => array(
                array('type' => 'LOGIC', 'title' => 'It’s mostly automatic', 'description' => 'A daily cron auto-issues certificates to learners marked Present in attendance — there’s no manual "generate" button for the normal flow.'),
                array('type' => 'ACTION', 'title' => 'Turn on auto-send', 'description' => 'Toggle "Auto-Send Enabled" under System → Configuration → Certificates. It ships off by default.'),
                array('type' => 'LOGIC', 'title' => 'Only present learners qualify', 'description' => 'A learner must be marked Present in attendance for that class before a certificate is issued.'),
            ),
        );

        $certificateTrainer = array(
            'id' => 'certificate',
            'title' => 'Send a Certificate',
            'path' => 'Per-class manual send',
            'steps' => array(
                array('type' => 'LOGIC', 'title' => 'It’s mostly automatic', 'description' => 'A daily cron auto-issues certificates to learners marked Present — manual sending is only needed if you want to push it early for a specific class.'),
                array('type' => 'ACTION', 'title' => 'Send for this class', 'description' => 'From the class, trigger "Send Certificates for This Class" to issue certificates immediately to all present learners who don’t already have one.'),
                array('type' => 'LOGIC', 'title' => 'Only present learners qualify', 'description' => 'Mark attendance before sending, otherwise eligible learners will be skipped.'),
            ),
        );

        $updateCourse = array(
            'id' => 'update-course',
            'title' => 'Update a Course',
            'path' => 'Manage Courses',
            'steps' => array(
                array('type' => 'ACTION', 'title' => 'Find the course', 'description' => 'Locate it in Manage Courses and click Edit.'),
                array('type' => 'ACTION', 'title' => 'Edit the General tab', 'description' => 'Name, SKU, price, description.'),
                array('type' => 'ACTION', 'title' => 'Edit Trainer Details', 'description' => 'Update trainer information associated with the course.'),
                array('type' => 'ACTION', 'title' => 'Edit Course Information', 'description' => 'Outcomes, prerequisites, sessions, and other course-detail fields.'),
                array('type' => 'ACTION', 'title' => 'Edit Settings', 'description' => 'Status, visibility, category.'),
                array('type' => 'ACTION', 'title' => 'Save', 'description' => 'Commits the changes.'),
                array('type' => 'LOGIC', 'title' => 'SKU prefix guardrail', 'description' => 'SKUs starting with "C" or "TGS-" are reserved for SG-synced courses and can’t be created or edited on country instances.'),
            ),
        );

        $conductLesson = array(
            'id' => 'conduct-lesson',
            'title' => 'Conduct a Lesson',
            'path' => '',
            'steps' => array(
                array('type' => 'LOGIC', 'title' => 'There’s no dedicated admin screen for this', 'description' => 'A "lesson" is the scheduled class session itself — defined by the class’s date, time, and venue. Delivery happens live (in person or online), not inside the admin.'),
                array('type' => 'ACTION', 'title' => 'Take attendance during or after the session', 'description' => 'Use E-Attendance to record who showed up.'),
                array('type' => 'ACTION', 'title' => 'Feedback is collected afterward', 'description' => 'Learners submit course/trainer feedback from the storefront once the class is done.'),
            ),
        );

        return array(
            'admin' => array(
                array('label' => 'Class Management', 'icon' => '🗂️', 'guides' => array($createClass, $assignTrainer, $takeAttendance)),
                array('label' => 'Feedback & Certificates', 'icon' => '📝', 'guides' => array($feedback, $certificateAdmin)),
                array('label' => 'Courses', 'icon' => '📘', 'guides' => array($updateCourse)),
            ),
            'trainer' => array(
                array('label' => 'Lesson Delivery', 'icon' => '📚', 'guides' => array($conductLesson, $takeAttendance)),
                array('label' => 'Certificates', 'icon' => '🏅', 'guides' => array($certificateTrainer)),
            ),
            'developer' => array(
                array('label' => 'Courses', 'icon' => '📘', 'guides' => array($updateCourse)),
            ),
        );
    }
}
