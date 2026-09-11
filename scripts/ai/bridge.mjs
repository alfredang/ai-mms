import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { Codex } from '@openai/codex-sdk';
import { query } from '@anthropic-ai/claude-agent-sdk';

// PHP supplies a private working directory and an allowlisted environment.
// Never inherit the web application's environment into either SDK subprocess.
export function codexOptions(dir) {
  return {
    codexPathOverride: fileURLToPath(new URL('./codex-client', import.meta.url)),
    env: { PATH: '/usr/local/bin:/usr/bin:/bin', CODEX_HOME: dir },
    config: {
      forced_login_method: 'chatgpt', cli_auth_credentials_store: 'file',
      project_doc_max_bytes: 0,
      features: Object.fromEntries([
        'shell_tool', 'unified_exec', 'multi_agent', 'multi_agent_v2', 'apps',
        'plugins', 'hooks', 'memories', 'skill_search', 'image_generation',
        'view_image', 'browser_use', 'browser_use_external', 'computer_use',
        'code_mode', 'code_mode_host', 'tool_suggest',
      ].map(name => [name, false])),
    },
  };
}

export function threadOptions(dir, webSearch) {
  return {
    model: 'gpt-5.6-sol', sandboxMode: 'read-only', workingDirectory: dir,
    skipGitRepoCheck: true, approvalPolicy: 'never',
    webSearchMode: webSearch ? 'live' : 'disabled',
  };
}

export function claudeOptions(dir, token, webSearch) {
  const tools = webSearch ? ['WebSearch', 'WebFetch'] : [];
  return {
    model: 'claude-opus-5', cwd: dir, tools, allowedTools: tools,
    settingSources: [], mcpServers: {}, strictMcpConfig: true,
    persistSession: false, skills: [],
    env: { PATH: '/usr/local/bin:/usr/bin:/bin', CLAUDE_CONFIG_DIR: dir,
      CLAUDE_CODE_OAUTH_TOKEN: token, DISABLE_AUTOUPDATER: '1',
      CLAUDE_AGENT_SDK_CLIENT_APP: 'tertiary-ai-mms/1.0.0' },
    canUseTool: async (name, input) => tools.includes(name)
      ? { behavior: 'allow', updatedInput: input }
      : { behavior: 'deny', message: 'Tool not permitted for content generation.' },
    stderr: () => {},
  };
}

export async function runBridge(provider, input, webSearch, emit) {
  const dir = process.cwd();
  if (provider === 'openai') {
    const client = new Codex(codexOptions(dir));
    const { events } = await client.startThread(threadOptions(dir, webSearch))
      .runStreamed(input, { signal: AbortSignal.timeout(105000) });
    for await (const event of events) {
      // Do not forward reasoning, raw errors, prompts, or tool arguments to PHP.
      if (event.type === 'turn.completed' ||
          (event.type === 'item.completed' && event.item.type === 'agent_message')) emit(event);
      if (event.type === 'error' || event.type === 'turn.failed') throw new Error('Generation failed');
    }
  } else if (provider === 'claude') {
    const options = claudeOptions(dir, process.env.CLAUDE_CODE_OAUTH_TOKEN, webSearch);
    options.abortController = new AbortController();
    const timer = setTimeout(() => options.abortController.abort(), 55000);
    async function* messages() { yield input; }
    try {
      for await (const message of query({ prompt: messages(), options })) {
        if (message.type === 'result') {
          if (message.is_error) throw new Error('Generation failed');
          emit({ type: 'result', is_error: false, result: message.result });
        }
      }
    } finally { clearTimeout(timer); }
  } else throw new Error('Unknown provider');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    const input = JSON.parse(readFileSync(0, 'utf8'));
    await runBridge(process.argv[2], input, process.argv[3] === '1',
      event => process.stdout.write(JSON.stringify(event) + '\n'));
  } catch {
    // Never output an SDK exception: it may contain credentials or private copy.
    process.stderr.write('AI SDK generation failed.\n');
    process.exitCode = 1;
  }
}
