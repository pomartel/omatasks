// curl config is sent over stdin, never through argv or a temporary file.
function quote(value) {
    return '"' + String(value).replace(/\\/g, '\\\\').replace(/"/g, '\\"')
        .replace(/\n/g, '\\n').replace(/\r/g, '\\r').replace(/\t/g, '\\t').replace(/\v/g, '\\v') + '"';
}
function config(method, url, payload, headers) {
    var lines = ['request = ' + quote(method), 'url = ' + quote(url)];
    Object.keys(headers).forEach(function(key) { lines.push('header = ' + quote(key + ': ' + headers[key])); });
    // --data-raw preserves a leading @ rather than interpreting it as a filename.
    lines.push('data-raw = ' + quote(payload));
    return lines.join('\n') + '\n';
}
function response(output, exitCode) {
    // The last two lines are curl's metadata, even when the body has newlines.
    var end = output.lastIndexOf('\n'), start = output.lastIndexOf('\n', end - 1);
    var status = Number(output.slice(start + 1, end));
    if (exitCode !== 0 || start < 0 || !/^[1-5][0-9]{2}$/.test(output.slice(start + 1, end)))
        return {status: 0, body: '', retryAfter: ''};
    return {status: status, body: output.slice(0, start), retryAfter: output.slice(end + 1)};
}
