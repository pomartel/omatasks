import QtQuick
import qs.Commons as Commons
import "../Model.js" as Model

Label {
    id: root
    property string sourceText: ""
    function openLink(url) { Qt.openUrlExternally(url); }
    text: Model.linkText(sourceText)
    textFormat: Text.StyledText
    color: Commons.Color.popups.text
    linkColor: Commons.Color.accent
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: root.linkAt(mouseX, mouseY) ? Qt.PointingHandCursor : Qt.ArrowCursor
        property string pressedLink: ""
        onPressed: function(mouse) {
            pressedLink = root.linkAt(mouse.x, mouse.y);
            if (!pressedLink || (mouse.modifiers & Qt.ControlModifier)) mouse.accepted = false;
        }
        onClicked: function(mouse) {
            if (pressedLink && pressedLink === root.linkAt(mouse.x, mouse.y)) root.openLink(pressedLink);
        }
    }
}
