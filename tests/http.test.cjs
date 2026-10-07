const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const Http = vm.createContext({});
vm.runInContext(fs.readFileSync('Http.js', 'utf8'), Http);

test('curl config contains quoted stdin values and cannot inject extra options', () => {
    const text = Http.config('POST', 'https://example.invalid', '@data\n"\\\t', {Authorization: 'Bearer fake"\nurl = "https://wrong.invalid'});
    assert.equal(text.split('\n').filter(Boolean).length, 4);
    assert.match(text, /data-raw = "@data\\n\\"\\\\\\t"/);
    assert.match(text, /fake\\"\\nurl = \\"https/);
});
test('curl response separates multiline bodies and preserves HTTP errors and Retry-After', () => {
    const r = Http.response('{\n"error": "slow down"\n}\n429\n120', 0);
    assert.equal(r.status, 429); assert.equal(r.retryAfter, '120');
    assert.deepEqual(JSON.parse(r.body), {error: 'slow down'});
    assert.equal(Http.response('\n204\n', 0).status, 204);
    for (const [output, code] of [['partial\n200\n', 18], ['', 0], ['\n000\n', 0]])
        assert.equal(Http.response(output, code).status, 0);
});

const hasQuickshell = spawnSync('quickshell', ['--version']).status === 0;
test('QML transport recovers on a new connection after a dropped request without replaying it', {skip: !hasQuickshell, timeout: 20000}, async t => {
    const calls = [], sockets = new Set();
    const server = http.createServer((req, res) => {
        let body = '';
        req.setEncoding('utf8'); req.on('data', part => body += part);
        req.on('end', () => {
            calls.push({url: req.url, body, auth: req.headers.authorization, id: req.headers['x-request-id']});
            if (req.url === '/drop') { req.socket.destroy(); return; }
            if (req.url === '/wait') return;
            res.writeHead(200, {'Retry-After': '120', 'Content-Type': 'application/json'});
            res.end('{\n"ok":true\n}');
        });
    });
    server.on('connection', socket => sockets.add(socket));
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    t.after(() => { server.closeAllConnections(); server.close(); });
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'omatasks-http-'));
    t.after(() => fs.rmSync(dir, {recursive: true, force: true}));
    // A user's curlrc must not change destinations, logging, or retries.
    fs.writeFileSync(path.join(dir, '.curlrc'), 'url = "http://127.0.0.1:1/unwanted"\n');
    fs.mkdirSync(path.join(dir, 'plugin'));
    for (const name of ['HttpRequest.qml', 'Http.js']) fs.copyFileSync(name, path.join(dir, 'plugin', name));
    fs.copyFileSync('tests/http.qml', path.join(dir, 'shell.qml'));
    let output = '';
    const child = spawn('quickshell', ['-p', dir, '--no-color'], {
        env: {...process.env, QT_QPA_PLATFORM: 'offscreen', CURL_HOME: dir,
            TODOIST_HTTP_TEST_URL: `http://127.0.0.1:${server.address().port}`},
        stdio: ['ignore', 'pipe', 'pipe']
    });
    t.after(() => child.kill('SIGKILL'));
    child.stdout.on('data', data => output += data); child.stderr.on('data', data => output += data);
    await new Promise((resolve, reject) => { child.on('error', reject); child.on('exit', resolve); });
    assert.match(output, /HTTP TRANSPORT PASSED/, output);
    assert.deepEqual(calls.map(c => c.url), ['/echo', '/drop', '/echo', '/wait', '/echo']);
    assert.equal(sockets.size, 5, 'Each request must use a fresh connection');
    for (const call of calls) {
        assert.equal(call.body, '@épreuve "citée"\nligne\\suite\t$(false)');
        assert.equal(call.auth, 'Bearer synthetic-token');
        assert.equal(call.id, 'synthetic-id');
    }
    assert.doesNotMatch(output, /synthetic-token|épreuve/);
});
