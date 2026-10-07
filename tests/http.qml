import QtQuick
import Quickshell
import "plugin" as Plugin

Item {
    id: root
    property int step: 0
    property var active: null
    Component { id: factory; Plugin.HttpRequest {} }
    function run() {
        var path = step === 1 ? "/drop" : step === 3 ? "/wait" : "/echo";
        active = factory.createObject(root);
        active.send("POST", Quickshell.env("TODOIST_HTTP_TEST_URL") + path,
                    '@épreuve "citée"\nligne\\suite\t$(false)',
                    {Authorization: 'Bearer synthetic-token', 'X-Request-Id': 'synthetic-id'}, function(result) {
            active.dispose();
            if (step === 3) { console.log("HTTP TRANSPORT FAILED cancelled callback"); Qt.quit(); return; }
            if (result.status !== (step === 1 ? 0 : 200)) {
                console.log("HTTP TRANSPORT FAILED", step, result.status);
                Qt.quit(); return;
            }
            if (step !== 1 && (result.retryAfter !== '120' || JSON.parse(result.body).ok !== true)) {
                console.log("HTTP TRANSPORT FAILED response"); Qt.quit(); return;
            }
            step++;
            if (step === 5) { console.log("HTTP TRANSPORT PASSED"); Qt.quit(); }
            else Qt.callLater(run);
        });
        if (step === 3) cancellation.start();
    }
    Timer { id: cancellation; interval: 100; onTriggered: { active.dispose(); step++; run(); } }
    Component.onCompleted: run()
    Timer { interval: 15000; running: true; onTriggered: { console.log("HTTP TRANSPORT TIMED OUT"); Qt.quit(); } }
}
