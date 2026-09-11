#!/usr/bin/env node
// Synthetic, no-network SDK subprocess. Never accepts real credentials.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const args = process.argv.slice(2);
assert.equal(process.env.OPENAI_API_KEY, undefined);
assert.equal(process.env.ANTHROPIC_API_KEY, undefined);
assert.equal(args[args.indexOf('--model') + 1], 'gpt-5.6-sol');
assert.equal(args[args.indexOf('--sandbox') + 1], 'read-only');
assert.ok(args.includes('features.shell_tool=false'));
assert.ok(args.includes('web_search="disabled"'));
assert.ok(args.includes('approval_policy="never"'));
assert.equal(args[args.indexOf('--image') + 1], process.env.CODEX_HOME + '/image.png');
assert.equal(readFileSync(0, 'utf8'), 'System instructions\n\nTest prompt');
console.log(JSON.stringify({ type: 'item.completed', item: { id: 'test', type: 'agent_message', text: 'OK' } }));
console.log(JSON.stringify({ type: 'turn.completed', usage: {} }));
