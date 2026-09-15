import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdir, mkdtemp, readFile, readdir, realpath, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const launcher = fileURLToPath(new URL('../dotfiles/zellij/scripts/opencode.sh', import.meta.url));

const fakeOpencode = String.raw`#!${process.execPath}
const fs = require('node:fs');
const path = require('node:path');
const root = process.env.LAUNCHER_FIXTURE;
const config = JSON.parse(fs.readFileSync(path.join(root, 'config.json'), 'utf8'));
const state = process.env.OPENCODE_ZELLIJ_STATE;
fs.appendFileSync(path.join(root, 'opencode.jsonl'), JSON.stringify({
  args: process.argv.slice(2),
  cwd: process.cwd(),
  status: process.env.OPENCODE_ZELLIJ_STATUS ?? null,
  directory: process.env.OPENCODE_ZELLIJ_DIRECTORY ?? null,
  state: state ?? null,
  stateExists: Boolean(state && fs.existsSync(state)),
  stateSize: state && fs.existsSync(state) ? fs.statSync(state).size : null,
}) + '\n');
if (state && config.journal !== undefined) {
  fs.writeFileSync(state, JSON.stringify(config.journal));
}
fs.writeFileSync(path.join(root, 'panes.json'), JSON.stringify(config.panes ?? []));
process.exit(config.exitCode);
`;

const fakeZellij = String.raw`#!${process.execPath}
const fs = require('node:fs');
const path = require('node:path');
const root = process.env.LAUNCHER_FIXTURE;
const args = process.argv.slice(2);
fs.appendFileSync(path.join(root, 'zellij.jsonl'), JSON.stringify(args) + '\n');
if (args[0] !== '--session' || args[1] !== 'fixture session' || args[2] !== 'action') {
  process.exit(91);
}
if (args[3] === 'list-panes' && args[4] === '--json' && args[5] === '--tab' && args.length === 6) {
  process.stdout.write(fs.readFileSync(path.join(root, 'panes.json')));
} else if (!(args[3] === 'rename-tab' && args[4] === '--tab-id' && args[6] === '--' && args.length === 8)) {
  process.exit(92);
}
`;

async function fixture(t) {
  await mkdir('/tmp/opencode', { recursive: true });
  const root = await mkdtemp('/tmp/opencode/launcher-test-');
  t.after(() => rm(root, { recursive: true, force: true }));
  const bin = path.join(root, 'bin');
  const tmp = path.join(root, 'tmp');
  const project = path.join(root, 'project');
  await Promise.all([bin, tmp, project].map((directory) => mkdir(directory)));
  await Promise.all([
    writeFile(path.join(bin, 'opencode'), fakeOpencode, { mode: 0o755 }),
    writeFile(path.join(bin, 'zellij'), fakeZellij, { mode: 0o755 }),
  ]);

  return {
    project,
    async run(args, { env: overrides = {}, exitCode = 0, journal, panes = [] } = {}) {
      await writeFile(path.join(root, 'config.json'), JSON.stringify({ exitCode, journal, panes }));
      const env = { ...process.env };
      for (const key of Object.keys(env)) {
        if (/^(OPENCODE_ZELLIJ_|ZELLIJ)/.test(key) || key === 'BASH_ENV' || key === 'ENV') {
          delete env[key];
        }
      }
      Object.assign(env, {
        PATH: `${bin}:${process.env.PATH}`,
        TMPDIR: tmp,
        LAUNCHER_FIXTURE: root,
        ZELLIJ_SESSION_NAME: 'fixture session',
        ZELLIJ_PANE_ID: '42',
      }, overrides);
      for (const key of Object.keys(env)) {
        if (env[key] === undefined) delete env[key];
      }

      const result = spawnSync('bash', [launcher, ...args], {
        cwd: project,
        env,
        encoding: 'utf8',
        timeout: 10_000,
      });
      assert.ifError(result.error);
      assert.equal(result.signal, null);
      assert.equal(result.status, exitCode, result.stderr);
      assert.equal(result.stderr, '');
      const readLog = async (name) => {
        try {
          return (await readFile(path.join(root, name), 'utf8')).trim().split('\n').map(JSON.parse);
        } catch (error) {
          if (error.code === 'ENOENT') return [];
          throw error;
        }
      };
      const calls = await readLog('opencode.jsonl');
      assert.equal(calls.length, 1, 'OpenCode is invoked exactly once');
      const [call] = calls;
      assert.deepEqual(call.args, args, 'all arguments are forwarded verbatim');
      assert.equal(call.cwd, await realpath(project), 'the launcher does not change directory');
      assert.deepEqual(await readdir(tmp), [], 'no temporary state files survive exit');
      if (call.state !== null) {
        assert.equal(path.dirname(call.state), tmp);
        assert.match(path.basename(call.state), /^opencode-zellij\./);
        await assert.rejects(readFile(call.state), { code: 'ENOENT' });
      }
      return { call, zellij: await readLog('zellij.jsonl') };
    },
  };
}

function assertUninstrumented({ call, zellij }, status = null) {
  assert.equal(call.status, status);
  assert.equal(call.directory, null);
  assert.equal(call.state, null);
  assert.equal(call.stateExists, false);
  assert.deepEqual(zellij, []);
}

test('forwards exact arguments and a nonzero exit code without Zellij', async (t) => {
  const f = await fixture(t);
  const args = ['run', '', 'two words', '"quoted"', '$literal;*', '--', '-path'];
  assertUninstrumented(await f.run(args, {
    env: { ZELLIJ_SESSION_NAME: undefined, ZELLIJ_PANE_ID: undefined },
    exitCode: 37,
  }));
});

for (const [name, env] of [
  ['missing session', { ZELLIJ_SESSION_NAME: undefined }],
  ['empty session', { ZELLIJ_SESSION_NAME: '' }],
  ['missing pane ID', { ZELLIJ_PANE_ID: undefined }],
  ['nonnumeric pane ID', { ZELLIJ_PANE_ID: 'pane-42' }],
  ['negative pane ID', { ZELLIJ_PANE_ID: '-1' }],
]) {
  test(`disables instrumentation with ${name}`, async (t) => {
    const f = await fixture(t);
    assertUninstrumented(await f.run([], { env: { OPENCODE_ZELLIJ_STATUS: '1', ...env } }));
  });
}

test('nested OPENCODE_ZELLIJ_STATUS=0 opts out even inside Zellij', async (t) => {
  const f = await fixture(t);
  assertUninstrumented(await f.run(['--continue'], {
    env: { OPENCODE_ZELLIJ_STATUS: '0' },
    exitCode: 23,
  }), '0');
});

for (const args of [
  ['run', 'prompt with spaces'],
  ['--print-logs', 'run', 'prompt'],
  ['--log-level', 'DEBUG', 'serve'],
  ['--log-level=DEBUG', 'serve'],
  ['run'],
  ['serve'],
  ['session'],
  ['--help'],
  ['--unknown-option'],
  ['missing-directory'],
]) {
  test(`does not instrument non-TUI invocation ${JSON.stringify(args)}`, async (t) => {
    const f = await fixture(t);
    // Bare subcommands must not become TUI projects just because these directories exist.
    await Promise.all(['run', 'serve', 'session'].map((name) => mkdir(path.join(f.project, name))));
    assertUninstrumented(await f.run(args));
  });
}

for (const [name, args, directory] of [
  ['default project', [], '.'],
  ['local boolean and value options', [
    '--print-logs', '--log-level', 'DEBUG', '--mdns', '--port', '1234',
    '--hostname', 'localhost', '--mdns-domain', 'local.test', '-c', '--continue',
    '--fork', '--auto', '--mini', '--no-replay', '-m', 'provider/model',
    '--model', 'provider/other', '-s', 'session-id', '--session', 'another-session',
    '--prompt', 'serve', '--agent', 'run', '--replay-limit', '10',
  ], '.'],
  ['equals-form options', [
    '--log-level=DEBUG', '--port=1234', '--hostname=localhost', '--mdns-domain=local.test',
    '--model=provider/model', '--session=session-id', '--prompt=two words',
    '--agent=run', '--replay-limit=10',
  ], '.'],
  ['project path containing spaces', ['--continue', 'project with spaces', '--model', 'provider/model'], 'project with spaces'],
  ['explicit relative subcommand directory', ['./run'], 'run'],
  // OpenCode's populate-- parser keeps these separate from its project positional.
  ['arguments after -- do not change project', ['--', '-project with spaces'], '.'],
  ['subcommand after -- is not a project', ['--', 'serve'], '.'],
  ['project before -- is preserved', ['project with spaces', '--', 'serve'], 'project with spaces'],
]) {
  test(`instruments TUI with ${name}`, async (t) => {
    const f = await fixture(t);
    if (directory !== '.') await mkdir(path.join(f.project, directory));
    const { call, zellij } = await f.run(args);
    assert.equal(call.status, '1');
    assert.equal(call.directory, await realpath(path.join(f.project, directory)));
    assert.equal(call.stateExists, true);
    assert.equal(call.stateSize, 0, 'the launcher provides a fresh empty state file');
    assert.deepEqual(zellij, [], 'an empty state file needs no Zellij cleanup calls');
  });
}

for (const exitCode of [0, 29]) {
  test(`restores only journal-owned names and removes state on exit ${exitCode}`, async (t) => {
    const f = await fixture(t);
    const journal = [
      { id: 7, original: 'original project', last: '! working' },
      { id: 8, original: 'second original', last: 'done' },
      { id: 9, original: 'before manual rename', last: '! working' },
      { id: 10, original: 'before bang rename', last: '! working' },
      { id: 11, original: 'closed tab', last: '! working' },
      { id: 12, original: '--original with spaces', last: '! waiting' },
    ];
    const panes = [
      { tab_id: 7, tab_name: '! working' },
      { tab_id: 7, tab_name: '! working' },
      { tab_id: 8, tab_name: 'done' },
      { tab_id: 9, tab_name: 'manually named' },
      { tab_id: 10, tab_name: '! manually named' },
      { tab_id: 12, tab_name: '! waiting' },
      { tab_id: 99, tab_name: '! working' },
    ];
    const { call, zellij } = await f.run([], { exitCode, journal, panes });
    assert.equal(call.status, '1');
    assert.equal(call.stateExists, true);
    assert.equal(call.stateSize, 0);
    assert.deepEqual(zellij, [
      ['--session', 'fixture session', 'action', 'list-panes', '--json', '--tab'],
      ['--session', 'fixture session', 'action', 'rename-tab', '--tab-id', '7', '--', 'original project'],
      ['--session', 'fixture session', 'action', 'rename-tab', '--tab-id', '8', '--', 'second original'],
      ['--session', 'fixture session', 'action', 'rename-tab', '--tab-id', '12', '--', '--original with spaces'],
    ], 'manual names (including ! prefixes), missing tabs, and unjournaled tabs are untouched');
  });
}
