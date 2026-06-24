<?php
/**
 * Class-schedule date generator.
 *
 * Faithful PHP port of the Google Apps Script generateDates() that the
 * academy used to populate course "Course Date" option values from a slot
 * code (A01-E04) over a date range. The script (and this port) walk the range
 * day-by-day; on each day it derives (weekday, week-of-month) and, for every
 * slot triggered that day, emits the human label + reg_course date exactly as
 * the spreadsheet did.
 *
 * Why a port and not the wwa TypeScript version: the wwa branch's
 * generateScheduleDates.ts reformatted the labels ("Mon 06 Jul 2026") and
 * dropped the Saturday/Sunday weekend fills. Production Course Date values
 * follow the ORIGINAL GAS format ("10 Apr 2026 (Fri)", "9/10 Apr 2026
 * Evening (Thu/Fri)", "21 Mar 2026 (Sat)") and DO include the weekend
 * entries, so this port mirrors the GAS rather than the TS.
 *
 * Label format (group = slot letter, or 'evening' for the type-A night row):
 *   a         -> "10 Apr 2026 (Fri)"
 *   evening   -> "9/10 Apr 2026 Evening (Thu/Fri)"
 *   b         -> "3/6 Apr 2026 (Fri/Mon)"
 *   c/d/e Sat -> "7/14/21 Mar 2026 (Sat)" etc.
 *   c/d/e wkday-> generic "5-7 Jan 2026 (Mon-Wed)" span
 *
 * Week-of-month convention (matches GAS getWeekOfMonth):
 *   ceil((dayOfMonth + firstDayOfWeek - 1) / 7), firstDayOfWeek Sunday -> 7.
 *
 * Pure logic, no DB access — unit-testable in isolation.
 */
class MMD_Adminhtml_Model_Schedule_Generator
{
    /**
     * (weekday 1=Mon..7=Sun) => (week-of-month => [slot codes triggered]).
     * Built directly from the switch(currentDay) -> switch(currentWeek)
     * structure of the GAS. Saturday/Sunday week 1 includes the case-5 fills
     * because the GAS "case 1:" falls through to "case 5:" (no break).
     */
    protected $_triggers = array(
        1 => array( // Monday
            1 => array('a1', 'b1', 'c1', 'd1', 'e1'),
            5 => array('a1', 'b1', 'c1', 'd1', 'e1'),
            2 => array('a6', 'c2', 'd2', 'e2'),
            3 => array('a11', 'b11', 'e3'),
            4 => array('a16', 'e4'),
        ),
        2 => array( // Tuesday
            1 => array('a2'),
            5 => array('a2'),
            2 => array('a7', 'b7'),
            3 => array('a12', 'd3'),
            4 => array('a17', 'b17', 'd4'),
        ),
        3 => array( // Wednesday
            1 => array('a3', 'b3'),
            5 => array('a3', 'b3'),
            2 => array('a8'),
            3 => array('a13', 'b13', 'c3'),
            4 => array('a18', 'c4'),
        ),
        4 => array( // Thursday
            1 => array('a4'),
            5 => array('a4'),
            2 => array('a9', 'b9'),
            3 => array('a14', 'b21'),
            4 => array('a19', 'b19'),
        ),
        5 => array( // Friday
            1 => array('a5', 'b5'),
            5 => array('a5', 'b5'),
            2 => array('a10'),
            3 => array('a15', 'b15'),
            4 => array('a20'),
        ),
        6 => array( // Saturday
            1 => array('c3', 'd3', 'e3', 'a11', 'a13', 'a15', 'b11', 'b13', 'b15', 'b21'),
            5 => array('a11', 'a13', 'a15', 'b11', 'b13', 'b15', 'b21'),
            2 => array('a16', 'a18', 'a20', 'b17', 'b19', 'c1', 'd4'),
            3 => array('a1', 'a3', 'a5', 'b1', 'b3', 'b5', 'd1', 'd2', 'e1'),
            4 => array('a6', 'a8', 'a10', 'b7', 'b9'),
        ),
        7 => array( // Sunday
            1 => array('c2', 'a12', 'a14'),
            5 => array('a12', 'a14'),
            2 => array('a17', 'a19', 'c4', 'e4'),
            3 => array('a2', 'a4'),
            4 => array('a7', 'a9', 'e2'),
        ),
    );

    /**
     * Generate every slot's dates within [start, end].
     *
     * @param  string|DateTime $start 'Y-m-d' (or DateTime)
     * @param  string|DateTime $end   'Y-m-d' (or DateTime)
     * @return array slotCode (e.g. 'a10') => list of
     *               array('title' => label, 'reg_course' => 'm/d/y')
     */
    public function generateAll($start, $end)
    {
        $results = array();
        $cur = $this->_toDate($start);
        $endDate = $this->_toDate($end);
        if (!$cur || !$endDate || $cur > $endDate) {
            return $results;
        }

        while ($cur <= $endDate) {
            $wd = (int) $cur->format('N');           // 1=Mon..7=Sun
            $wk = $this->getWeekOfMonth($cur);
            if (isset($this->_triggers[$wd][$wk])) {
                foreach ($this->_triggers[$wd][$wk] as $slot) {
                    $this->_fill($results, $slot, $cur, $slot[0]);
                }
            }
            $cur->modify('+1 day');
        }

        return $results;
    }

    /**
     * Generate the dates for a single slot code within [start, end].
     *
     * @param  string $code  e.g. 'A10', 'a10', '(SG) WSQ-A01 ...'
     * @return array list of array('title' => ..., 'reg_course' => 'm/d/y')
     */
    public function generateForCode($code, $start, $end)
    {
        $key = $this->normalizeCode($code);
        if ($key === '') {
            return array();
        }
        $all = $this->generateAll($start, $end);
        return isset($all[$key]) ? $all[$key] : array();
    }

    /**
     * Normalise a slot code / template title to the internal key form
     * ('A01' -> 'a1', 'B03' -> 'b3', '(SG) WSQ-A10 ...' -> 'a10').
     * Returns '' when no A-E + number token is present.
     */
    public function normalizeCode($code)
    {
        if (preg_match('/([A-Ea-e])\s*0*([0-9]+)/', (string) $code, $m)) {
            return strtolower($m[1]) . (int) $m[2];
        }
        return '';
    }

    /**
     * True when the code maps to a slot the GAS algorithm actually fills.
     */
    public function isKnownCode($code)
    {
        $key = $this->normalizeCode($code);
        if ($key === '') {
            return false;
        }
        foreach ($this->_triggers as $weeks) {
            foreach ($weeks as $slots) {
                if (in_array($key, $slots, true)) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Week-of-month, GAS convention. ceil((dom + firstDow - 1)/7), Sun -> 7.
     */
    public function getWeekOfMonth(DateTime $date)
    {
        $first = new DateTime($date->format('Y-m-01'));
        $fdow = (int) $first->format('w'); // 0=Sun..6=Sat
        if ($fdow === 0) {
            $fdow = 7;
        }
        $dom = (int) $date->format('j');
        return (int) ceil(($dom + $fdow - 1) / 7);
    }

    /**
     * Append the entry/entries for one slot fill on $date.
     * Group 'a' on a weekday emits an evening row then a daytime row (matching
     * the GAS fillCells); everything else emits a single row.
     */
    protected function _fill(array &$results, $slot, DateTime $date, $group)
    {
        $wd = (int) $date->format('N');
        $day = (int) $date->format('j');

        if ($group === 'a' && $wd <= 5) {
            // Evening row. reg_course = earlier day when the label leads with
            // (day-1) (GAS: backDate when split[0] != day).
            $evLabel = $this->_dateString($date, 'evening');
            if ($evLabel !== '') {
                $reg = clone $date;
                $parts = explode('/', $evLabel);
                if ((int) $parts[0] !== $day) {
                    $reg->modify('-1 day');
                }
                $results[$slot][] = array(
                    'title'      => $evLabel,
                    'reg_course' => $reg->format('m/d/y'),
                );
            }
            // Daytime row (no slash in label -> reg_course = the day itself).
            $results[$slot][] = array(
                'title'      => $this->_dateString($date, 'a'),
                'reg_course' => $date->format('m/d/y'),
            );
            return;
        }

        $label = $this->_dateString($date, $group);
        if ($label === '') {
            return;
        }
        $reg = clone $date;
        if (strpos($label, '/') !== false) {
            $parts = explode('/', $label);
            if ((int) $parts[0] !== $day) {
                // GAS: newDate.setDate(parseInt(split[0])) — same month/year.
                $reg->setDate(
                    (int) $date->format('Y'),
                    (int) $date->format('n'),
                    (int) $parts[0]
                );
            }
        }
        $results[$slot][] = array(
            'title'      => $label,
            'reg_course' => $reg->format('m/d/y'),
        );
    }

    /**
     * Port of the GAS generateDateString(date, group).
     */
    protected function _dateString(DateTime $date, $group)
    {
        $week  = $this->getWeekOfMonth($date);
        $day   = (int) $date->format('j');
        $month = $date->format('M');
        $year  = (int) $date->format('Y');
        $dow   = $date->format('D');

        if ($group === 'evening') {
            switch ($week) {
                case 1:
                case 5:
                    return $this->_evening($date, array('Thu', 'Fri'));
                case 3:
                    return $this->_evening($date, array('Fri'));
                case 4:
                case 2:
                    return $this->_evening($date, array('Tue', 'Fri'));
            }
            return '';
        }

        if ($group === 'a') {
            return $day . ' ' . $month . ' ' . $year . ' (' . $dow . ')';
        }

        if ($group === 'b') {
            $next = clone $date;
            $next->modify($dow === 'Fri' ? '+3 day' : '+1 day');
            $ndow = $next->format('D');
            $nday = (int) $next->format('j');
            if ($nday < $day) {
                return $day . ' ' . $month . ' / ' . $nday . ' ' . $this->_nextMonth($date)
                    . ' ' . $year . ' (' . $dow . '/' . $ndow . ')';
            }
            return $day . '/' . $nday . ' ' . $month . ' ' . $year . ' (' . $dow . '/' . $ndow . ')';
        }

        // c / d / e — recurring weekend patterns, else a generic span.
        $endDay = clone $date;
        if ($group === 'c') {
            $endDay->modify('+2 day');
            if ($dow === 'Sat' && ($week === 1 || $week === 2)) {
                return $day . '/' . ($day + 7) . '/' . ($day + 14) . ' ' . $month . ' ' . $year . ' (Sat)';
            }
            if ($dow === 'Sun' && ($week === 1 || $week === 2)) {
                return $day . '/' . ($day + 7) . '/' . ($day + 14) . ' ' . $month . ' ' . $year . ' (Sun)';
            }
        } elseif ($group === 'd') {
            $endDay->modify('+3 day');
            if ($dow === 'Sat' && ($week === 1 || $week === 2 || $week === 3)) {
                return $day . '/' . ($day + 1) . '/' . ($day + 7) . '/' . ($day + 8)
                    . ' ' . $month . ' ' . $year . ' (Sat/Sun)';
            }
        } elseif ($group === 'e') {
            $endDay->modify('+4 day');
            if ($dow === 'Sat' && $week === 1) {
                return $day . '/' . ($day + 7) . '/' . ($day + 14) . '/' . ($day + 21) . '/' . ($day + 22)
                    . ' ' . $month . ' ' . $year . ' (Sat/Sun)';
            }
            if ($dow === 'Sat' && $week === 3) {
                return ($day - 14) . '/' . ($day - 7) . '/' . ($day - 6) . '/' . $day . '/' . ($day + 7)
                    . ' ' . $month . ' ' . $year . ' (Sat/Sun)';
            }
            if ($dow === 'Sun' && $week === 2) {
                return ($day - 8) . '/' . ($day - 7) . '/' . $day . '/' . ($day + 7) . '/' . ($day + 14)
                    . ' ' . $month . ' ' . $year . ' (Sat/Sun)';
            }
            if ($dow === 'Sun' && $week === 4) {
                return ($day - 21) . '/' . ($day - 14) . '/' . ($day - 8) . '/' . ($day - 7) . '/' . $day
                    . ' ' . $month . ' ' . $year . ' (Sat/Sun)';
            }
        }

        // Generic span (weekday c/d/e fills, e.g. Mon-Wed).
        $endNum = (int) $endDay->format('j');
        $endDow = $endDay->format('D');
        if ($endNum < $day) {
            return $day . ' ' . $month . ' - ' . $endNum . ' ' . $this->_nextMonth($date)
                . ' ' . $year . ' (' . $dow . '-' . $endDow . ')';
        }
        return $day . '-' . $endNum . ' ' . $month . ' ' . $year . ' (' . $dow . '-' . $endDow . ')';
    }

    /**
     * Evening-row label. $backDows lists the weekdays that pair BACKWARD
     * (evening spans day-1 + day); all other weekdays pair forward.
     */
    protected function _evening(DateTime $date, array $backDows)
    {
        $day   = (int) $date->format('j');
        $month = $date->format('M');
        $year  = (int) $date->format('Y');
        $dow   = $date->format('D');

        if (in_array($dow, $backDows, true)) {
            $extra = clone $date;
            $extra->modify('-1 day');
            return ($day - 1) . '/' . $day . ' ' . $month . ' ' . $year
                . ' Evening (' . $extra->format('D') . '/' . $dow . ')';
        }

        if ($dow === 'Sat' || $dow === 'Sun') {
            return '';
        }

        $extra = clone $date;
        $extra->modify('+1 day');
        $eday = (int) $extra->format('j');
        if ($eday < $day) {
            return $day . ' ' . $month . ' / ' . $eday . ' ' . $this->_nextMonth($date)
                . ' ' . $year . ' Evening (' . $dow . '/' . $extra->format('D') . ')';
        }
        return $day . '/' . $eday . ' ' . $month . ' ' . $year
            . ' Evening (' . $dow . '/' . $extra->format('D') . ')';
    }

    /**
     * Short month name of the calendar month after $date's month.
     */
    protected function _nextMonth(DateTime $date)
    {
        $d = new DateTime($date->format('Y-m-01'));
        $d->modify('first day of next month');
        return $d->format('M');
    }

    /**
     * Coerce a 'Y-m-d' string (or DateTime) to a midnight DateTime.
     */
    protected function _toDate($value)
    {
        if ($value instanceof DateTime) {
            $d = clone $value;
            $d->setTime(0, 0, 0);
            return $d;
        }
        $d = DateTime::createFromFormat('Y-m-d', (string) $value);
        if ($d instanceof DateTime) {
            $d->setTime(0, 0, 0);
            return $d;
        }
        return false;
    }
}
