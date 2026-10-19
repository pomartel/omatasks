import QtQuick
import QtQuick.Controls as C
import qs.Commons
import qs.Commons as Commons

C.SpinBox {
    id: root
    implicitWidth: Style.space(148)
    implicitHeight: Style.space(36)
    stepSize: 20
    editable: true
    leftPadding: down.indicator.width + Style.space(4)
    rightPadding: up.indicator.width + Style.space(4)
    topPadding: 0
    bottomPadding: 0
    font.family: Qt.application.font.family
    font.pixelSize: Style.font.bodySmall

    contentItem: TextInput {
        text: root.displayText
        font: root.font
        color: Commons.Color.popups.text
        selectionColor: Commons.Color.accent
        selectedTextColor: Commons.Color.popups.background
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhDigitsOnly
    }
    background: Rectangle {
        color: "transparent"
        radius: Style.cornerRadius
        border.width: 1
        border.color: Qt.rgba(Commons.Color.popups.text.r, Commons.Color.popups.text.g, Commons.Color.popups.text.b, root.activeFocus ? 0.6 : 0.25)
    }
    down.indicator: Rectangle {
        width: Style.space(36); height: root.height
        radius: Style.cornerRadius
        color: root.down.pressed || root.down.hovered ? Style.hoverFillFor(Commons.Color.popups.text, Commons.Color.accent) : Qt.rgba(Commons.Color.popups.text.r, Commons.Color.popups.text.g, Commons.Color.popups.text.b, 0.05)
        Label { font.family: root.font.family; anchors.centerIn: parent; text: "−"; font.pixelSize: Style.space(20); opacity: root.value > root.from ? 1 : 0.3 }
    }
    up.indicator: Rectangle {
        x: root.width - width
        width: Style.space(36); height: root.height
        radius: Style.cornerRadius
        color: root.up.pressed || root.up.hovered ? Style.hoverFillFor(Commons.Color.popups.text, Commons.Color.accent) : Qt.rgba(Commons.Color.popups.text.r, Commons.Color.popups.text.g, Commons.Color.popups.text.b, 0.05)
        Label { font.family: root.font.family; anchors.centerIn: parent; text: "+"; font.pixelSize: Style.space(20); opacity: root.value < root.to ? 1 : 0.3 }
    }
}
