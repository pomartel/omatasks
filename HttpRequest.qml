import QtQuick
import Quickshell.Io
import "Http.js" as Http

// A process per request gives retries a new connection and route after suspend
// or a Wi-Fi/Ethernet switch. QML XHR shares the engine's connection pool, which
// can keep reusing an unreachable HTTP/2 socket even after xhr.abort().
Item {
    id: root
    property string input: ""
    property var callback: null

    function send(method, url, payload, headers, done) {
        callback = done;
        input = Http.config(method, url, payload, headers);
        process.running = true;
    }
    function dispose() {
        callback = null;
        input = "";
        process.signal(9);
        destroy();
    }
    Process {
        id: process
        // -q must be first: ignore ~/.curlrc. No automatic retries or redirects
        // (writes may have succeeded, and auth must not go to another host).
        command: ["curl", "-q", "--silent", "--connect-timeout", "10", "--max-time", "20",
                  "--write-out", "\n%{http_code}\n%header{retry-after}", "--config", "-"]
        stdinEnabled: true
        onStarted: { write(root.input); root.input = ""; stdinEnabled = false; }
        stdout: StdioCollector { id: output }
        stderr: StdioCollector {}
        onExited: function(code) {
            var result = Http.response(output.text, code);
            if (root.callback) root.callback(result);
        }
    }
}
