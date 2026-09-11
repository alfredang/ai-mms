import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Codex } from '@openai/codex-sdk';
import { codexOptions, threadOptions, claudeOptions } from './bridge.mjs';

test('Codex SDK pins OAuth, model, sandbox, and disables non-research tools', () => {
  const options = codexOptions('/private-session');
  assert.deepEqual(Object.keys(options.env).sort(), ['CODEX_HOME', 'PATH']);
  assert.equal(options.config.forced_login_method, 'chatgpt');
  assert.equal(options.config.cli_auth_credentials_store, 'file');
  assert.equal(options.config.project_doc_max_bytes, 0);
  assert.equal(Object.keys(options.config.features).length, 17);
  assert.ok(Object.values(options.config.features).every(value => value === false));
  assert.deepEqual(threadOptions('/private-session', false), {
    model: 'gpt-5.6-sol', sandboxMode: 'read-only', workingDirectory: '/private-session',
    skipGitRepoCheck: true, approvalPolicy: 'never', webSearchMode: 'disabled',
  });
  assert.equal(threadOptions('/private-session', true).webSearchMode, 'live');
  const launcher = readFileSync(new URL('./codex-client', import.meta.url), 'utf8');
  assert.match(launcher, /"\$command_name" --ignore-user-config --ignore-rules "\$@" --ephemeral/);
});

test('real Codex SDK serializes text, images and restrictions to its subprocess', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'mmd-sdk-test-'));
  try {
    const options = codexOptions(dir);
    options.codexPathOverride = fileURLToPath(new URL('./fixtures/codex.mjs', import.meta.url));
    options.env.PATH = dirname(process.execPath) + ':/usr/bin:/bin';
    const client = new Codex(options);
    const turn = await client.startThread(threadOptions(dir, false)).run([
      { type: 'text', text: 'System instructions\n\nTest prompt' },
      { type: 'local_image', path: join(dir, 'image.png') },
    ]);
    assert.equal(turn.finalResponse, 'OK');
  } finally { rmSync(dir, { recursive: true }); }
});

test('Claude SDK pins Opus 5 and isolates credentials, settings and tools', async () => {
  const options = claudeOptions('/private-session', 'test-only-not-a-token', false);
  assert.equal(options.model, 'claude-opus-5');
  assert.equal(options.cwd, '/private-session');
  assert.deepEqual(options.tools, []);
  assert.deepEqual(options.allowedTools, []);
  assert.deepEqual(options.settingSources, []);
  assert.deepEqual(options.mcpServers, {});
  assert.deepEqual(options.skills, []);
  assert.equal(options.strictMcpConfig, true);
  assert.equal(options.persistSession, false);
  assert.equal(options.env.CLAUDE_CONFIG_DIR, '/private-session');
  assert.equal(options.env.CLAUDE_CODE_OAUTH_TOKEN, 'test-only-not-a-token');
  assert.equal(options.env.OPENAI_API_KEY, undefined);
  assert.equal(options.env.ANTHROPIC_API_KEY, undefined);
  assert.equal((await options.canUseTool('Bash', {})).behavior, 'deny');
  const research = claudeOptions('/private-session', 'test-only', true);
  assert.deepEqual(research.tools, ['WebSearch', 'WebFetch']);
  assert.deepEqual(research.allowedTools, research.tools);
  assert.equal((await research.canUseTool('WebSearch', { query: 'test' })).behavior, 'allow');
  assert.equal((await research.canUseTool('Bash', {})).behavior, 'deny');
});
