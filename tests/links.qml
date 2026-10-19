import QtQuick
import QtTest
import Quickshell
import "plugin/ui" as Tasks

ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 440
        implicitHeight: 120
        color: "#131c2f"
        MouseArea {
            id: row
            anchors.fill: parent
            property int clicks: 0
            onClicked: clicks++
        }
        Tasks.LinkLabel {
            id: label
            x: 20; y: 20; width: 400
            sourceText: "Consulter [le site](https://example.com)"
            property string opened: ""
            function openLink(url) { opened = url; }
        }
    }
    TestCase {
        name: "TaskLinks"
        when: window.visible
        function cleanupTestCase() { console.log("LINK RESULTS", qtest_results.passCount, "passed", qtest_results.failCount, "failed"); Qt.callLater(Qt.quit); }
        function test_link_click_and_row_fallback() {
            wait(50);
            var linkX = -1;
            for (var x = 0; x < label.width; x++) {
                if (label.linkAt(x, label.height / 2)) { linkX = x + 2; break; }
            }
            verify(linkX >= 0);
            mouseClick(label, linkX, label.height / 2);
            compare(label.opened, "https://example.com");
            compare(row.clicks, 0);
            label.opened = "";
            mouseClick(label, 2, label.height / 2);
            compare(row.clicks, 1);
            mouseClick(label, linkX, label.height / 2, Qt.LeftButton, Qt.ControlModifier);
            compare(row.clicks, 2);
            compare(label.opened, "");
        }
    }
}
