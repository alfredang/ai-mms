#!/usr/bin/env php
<?php
// No network. Validates the real subprocess boundary with synthetic credentials.
$dir = getenv('CODEX_HOME');
if (!$dir || (fileperms($dir) & 0777) !== 0700 || (fileperms($dir . '/auth.json') & 0777) !== 0600) exit(2);
if (getenv('OPENAI_API_KEY') || getenv('ANTHROPIC_API_KEY')) exit(3);
if (!in_array('gpt-5.6-sol', $argv, true) || !in_array('shell_tool', $argv, true) || !in_array('read-only', $argv, true)) exit(4);
$prompt = stream_get_contents(STDIN);
if ($prompt !== "System instructions\n\nTest prompt") exit(5);
echo json_encode(array('type' => 'item.completed', 'item' => array('type' => 'agent_message', 'text' => 'OK'))) . "\n";
echo json_encode(array('type' => 'turn.completed')) . "\n";
