import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as UI
import "../Model.js" as Model

ColumnLayout {
    id: root
    required property var service
    spacing: Style.space(14)
    function focusInput() { tokenInput.forceActiveFocus(); }
    Label { text: root.service.configured ? "Compte Todoist" : "Connexion à Todoist"; font.bold: true; font.pixelSize: Style.font.heading }
    Label {
        Layout.fillWidth: true
        text: "Ouvrez Todoist → Paramètres → Intégrations → Développeur. Copiez votre jeton API et collez-le ci-dessous."
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        opacity: 0.7
    }
    Action { text: "Ouvrir les paramètres développeur ↗"; bordered: true; onClicked: Qt.openUrlExternally(Model.TOKEN_URL) }
    UI.TextField {
        id: tokenInput
        Layout.fillWidth: true
        password: true
        font.family: Style.font.family
        placeholderText: root.service.configured ? "Collez un nouveau jeton API" : "Collez votre jeton API"
        enabled: !root.service.connecting
        onAccepted: root.service.connectToken(text)
    }
    RowLayout {
        Action {
            text: root.service.connecting ? "Connexion…" : "Se connecter"
            selected: true
            enabled: tokenInput.text.trim().length > 0 && !root.service.connecting
            onClicked: root.service.connectToken(tokenInput.text)
        }
        Action { visible: root.service.configured; text: "Se déconnecter"; enabled: !root.service.connecting && !root.service.saving; onClicked: root.service.disconnect() }
    }
    Label { Layout.fillWidth: true; text: "Votre jeton reste sur cet ordinateur."; opacity: 0.45; font.pixelSize: Style.font.caption }
    Connections { target: root.service; function onConnected() { tokenInput.text = ""; } }
}
