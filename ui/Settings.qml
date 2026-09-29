import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as UI

ColumnLayout {
    id: root
    required property var service
    spacing: Style.space(20)
    ColumnLayout {
        visible: root.service.configured
        Layout.fillWidth: true
        spacing: Style.space(8)
        Label { text: "Dimensions du panneau"; font.bold: true }
        RowLayout {
            Layout.fillWidth: true
            Label { Layout.fillWidth: true; text: "Largeur" }
            SizeControl { value: root.service.panelWidth; from: 360; to: 1000; Accessible.name: "Largeur du panneau"; onValueModified: root.service.setPanelSize("panelWidth", value) }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { Layout.fillWidth: true; text: "Hauteur maximale" }
            SizeControl { value: root.service.panelHeight; from: 280; to: 1200; Accessible.name: "Hauteur maximale du panneau"; onValueModified: root.service.setPanelSize("panelHeight", value) }
        }
        Label { Layout.fillWidth: true; text: "En pixels. Le panneau s’adapte aux listes plus courtes."; font.pixelSize: Style.font.caption; opacity: 0.5; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    }
    Rectangle { visible: root.service.configured; Layout.fillWidth: true; height: 1; color: Color.popups.text; opacity: 0.12 }
    Setup { Layout.fillWidth: true; service: root.service }
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.popups.text; opacity: 0.12 }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)
        Label { text: "Raccourci d’ajout rapide"; font.bold: true }
        RowLayout {
            Layout.fillWidth: true
            UI.TextField {
                id: shortcutInput
                Layout.fillWidth: true
                text: root.service.shortcut.value
                placeholderText: "Désactivé"
                enabled: !root.service.shortcut.busy
                onAccepted: root.service.shortcut.apply(text, true)
            }
            Action { text: "Appliquer"; bordered: true; enabled: !root.service.shortcut.busy; onClicked: root.service.shortcut.apply(shortcutInput.text, true) }
        }
        Label { Layout.fillWidth: true; text: "Super, Ctrl, Alt, Maj + une touche. Laissez vide pour désactiver."; wrapMode: Text.WordWrap; elide: Text.ElideNone; opacity: 0.5; font.pixelSize: Style.font.caption }
        Label {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.service.shortcut.message
            color: root.service.shortcut.successful ? Color.popups.text : Color.urgent
            opacity: 0.7; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.caption
        }
    }
}
