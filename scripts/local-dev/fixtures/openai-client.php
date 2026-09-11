#!/usr/bin/env php
<?php
// No network. Validates the real subprocess boundary with synthetic credentials.
$dir = getenv('CODEX_HOME');
if (!$dir || (fileperms($dir) & 0777) !== 0700 || (fileperms($dir . '/auth.json') & 0777) !== 0600) exit(2);
if (getenv('OPENAI_API_KEY') || getenv('ANTHROPIC_API_KEY')) exit(3);
if (!in_array('/opt/mmd-ai-sdk/bridge.mjs', $argv, true) || !in_array('openai', $argv, true) || end($argv) !== '0') exit(4);
$input = json_decode(stream_get_contents(STDIN), true);
if ($input !== array(array('type' => 'text', 'text' => "System instructions\n\nTest prompt"))) exit(5);
echo json_encode(array('type' => 'item.completed', 'item' => array('type' => 'agent_message', 'text' => 'OK'))) . "\n";
echo json_encode(array('type' => 'turn.completed')) . "\n";
