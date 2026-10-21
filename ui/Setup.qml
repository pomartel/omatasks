import "../i18n/Fr.js" as Fr
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as UI
import "../Model.js" as Model

ColumnLayout {
    id: root
    required property var service
    readonly property string fontFamily: service.fontFamily
    spacing: Style.space(14)
    function focusInput() { tokenInput.forceActiveFocus(); }
    Label { font.family: root.fontFamily; text: root.service.configured ? Fr.t("text.compte_todoist") : Fr.t("text.connexion_a_todoist"); font.bold: true; font.pixelSize: Style.font.heading }
    Label { font.family: root.fontFamily;
        Layout.fillWidth: true
        text: Fr.t("text.ouvrez_todoist_parametres_integrations_developpeur_copiez_votre_j")
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        opacity: 0.7
    }
    Action { fontFamily: root.fontFamily; text: Fr.t("text.ouvrir_les_parametres_developpeur"); bordered: true; onClicked: Qt.openUrlExternally(Model.TOKEN_URL) }
    UI.TextField {
        id: tokenInput
        Layout.fillWidth: true
        password: true
        font.family: root.fontFamily
        placeholderText: root.service.configured ? Fr.t("text.collez_un_nouveau_jeton_api") : Fr.t("text.collez_votre_jeton_api")
        enabled: !root.service.connecting
        onAccepted: root.service.connectToken(text)
    }
    RowLayout {
        Action { fontFamily: root.fontFamily;
            text: root.service.connecting ? Fr.t("text.connexion") : Fr.t("text.se_connecter")
            selected: true
            enabled: tokenInput.text.trim().length > 0 && !root.service.connecting
            onClicked: root.service.connectToken(tokenInput.text)
        }
        Action { fontFamily: root.fontFamily; visible: root.service.configured; text: Fr.t("text.se_deconnecter"); enabled: !root.service.connecting && !root.service.saving; onClicked: root.service.disconnect() }
    }
    Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.votre_jeton_reste_sur_cet_ordinateur"); opacity: 0.45; font.pixelSize: Style.font.caption }
    Connections { target: root.service; function onConnected() { tokenInput.text = ""; } }
}
