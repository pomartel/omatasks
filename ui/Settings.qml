import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Commons as Commons
import qs.Ui as UI

ColumnLayout {
    id: root
    required property var service
    readonly property string fontFamily: service.fontFamily
    spacing: Style.space(20)
    ColumnLayout {
        visible: root.service.configured
        Layout.fillWidth: true
        spacing: Style.space(8)
        Label { font.family: root.fontFamily; text: "Panneau et barre"; font.bold: true }
        RowLayout {
            Layout.fillWidth: true
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "Largeur" }
            SizeControl { value: root.service.panelWidth; from: 360; to: 1000; Accessible.name: "Largeur du panneau"; onValueModified: root.service.setPanelSize("panelWidth", value) }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "Hauteur maximale" }
            SizeControl { value: root.service.panelHeight; from: 280; to: 1200; Accessible.name: "Hauteur maximale du panneau"; onValueModified: root.service.setPanelSize("panelHeight", value) }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "En pixels. Le panneau s’adapte aux listes plus courtes."; font.pixelSize: Style.font.bodySmall; opacity: 0.5; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.space(6)
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "Dans la barre" }
            UI.Dropdown {
                objectName: "barMode"
                Layout.preferredWidth: Style.space(190)
                showLabel: false; fontFamily: root.fontFamily
                value: root.service.barMode
                options: [{value: "task", label: "Prochaine tâche"}, {value: "count", label: "Nombre de tâches aujourd’hui"}, {value: "icon", label: "Icône seulement"}]
                onChanged: function(value) { root.service.setBarMode(value); }
            }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "Prochaine tâche à heure fixe : celle en cours, puis celle en retard. Le nombre de tâches s’affiche ensuite."; font.pixelSize: Style.font.bodySmall; opacity: 0.5; wrapMode: Text.WordWrap; elide: Text.ElideNone; visible: root.service.barMode === "task" }
    }
    Rectangle { visible: root.service.configured; Layout.fillWidth: true; height: 1; color: Commons.Color.popups.text; opacity: 0.12 }
    ColumnLayout {
        id: notifications
        visible: root.service.configured
        Layout.fillWidth: true
        spacing: Style.space(8)
        readonly property var options: root.service.notifySettings
        Label { font.family: root.fontFamily; text: "Notifications"; font.bold: true }
        Repeater {
            model: [
                {key: "enabled", label: "Afficher les notifications", detail: "Vos rappels Todoist, avec les boutons Terminer et Reporter."},
                {key: "atDueTime", label: "À l’heure de chaque tâche", detail: "Même si la tâche n’a pas de rappel."},
                {key: "deadlines", label: "Alertes de date limite", detail: "La veille et le jour de la date limite, à l’heure du récapitulatif."},
                {key: "recap", label: "Récapitulatif du matin", detail: "Les tâches du jour et les dates limites des trois prochains jours, à votre retour."}
            ]
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                enabled: modelData.key === "enabled" || notifications.options.enabled
                opacity: enabled ? 1 : 0.4
                spacing: Style.space(10)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(2)
                    Label { font.family: root.fontFamily; Layout.fillWidth: true; text: modelData.label }
                    Label { font.family: root.fontFamily; Layout.fillWidth: true; text: modelData.detail; opacity: 0.5; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall }
                }
                UI.ToggleSwitch {
                    Layout.alignment: Qt.AlignVCenter
                    objectName: "notify-" + modelData.key
                    checked: notifications.options[modelData.key]
                    foreground: Commons.Color.popups.text
                    Accessible.name: modelData.label
                    onToggled: root.service.setNotification(modelData.key, !checked)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            enabled: notifications.options.enabled && notifications.options.recap
            opacity: enabled ? 1 : 0.4
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "Heure du récapitulatif" }
            UI.TextField { font.family: root.fontFamily;
                id: recapInput
                Layout.preferredWidth: Style.space(70)
                text: notifications.options.recapTime
                placeholderText: "08:00"
                onAccepted: recapApply.apply()
                Connections { target: root.service; function onPreferencesChanged() { recapInput.text = root.service.notifySettings.recapTime; } }
            }
            Action { fontFamily: root.fontFamily;
                id: recapApply
                property string message: ""
                text: "Appliquer"; bordered: true
                function apply() { message = root.service.setNotification("recapTime", recapInput.text) ? "" : "Utilisez une heure sur 24 heures, par exemple 08:00."; }
                onClicked: apply()
            }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; visible: text !== ""; text: recapApply.message; color: Commons.Color.urgent; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall }
        RowLayout {
            Layout.fillWidth: true
            enabled: notifications.options.enabled
            opacity: enabled ? 1 : 0.4
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "Répéter les tâches en retard" }
            UI.Dropdown {
                Layout.preferredWidth: Style.space(150)
                showLabel: false; fontFamily: root.fontFamily
                value: String(notifications.options.overdueHours)
                options: [{value: "0", label: "Jamais"}, {value: "1", label: "Chaque heure"}, {value: "2", label: "Toutes les 2 heures"}, {value: "4", label: "Toutes les 4 heures"}]
                onChanged: function(value) { root.service.setNotification("overdueHours", Number(value)); }
            }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "Répète les rappels des tâches à heure fixe encore ouvertes le jour prévu."; opacity: 0.5; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall; visible: notifications.options.enabled }
        Action { fontFamily: root.fontFamily;
            text: "Afficher le récapitulatif maintenant"; leftAligned: true
            enabled: notifications.options.enabled && root.service.loaded
            onClicked: root.service.notifyRecap(true)
        }
    }
    Rectangle { visible: root.service.configured; Layout.fillWidth: true; height: 1; color: Commons.Color.popups.text; opacity: 0.12 }
    Setup { Layout.fillWidth: true; service: root.service }
    Rectangle { Layout.fillWidth: true; height: 1; color: Commons.Color.popups.text; opacity: 0.12 }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)
        Label { font.family: root.fontFamily; text: "Raccourci d’ajout rapide"; font.bold: true }
        RowLayout {
            Layout.fillWidth: true
            UI.TextField { font.family: root.fontFamily;
                id: shortcutInput
                Layout.fillWidth: true
                text: root.service.shortcut.value
                placeholderText: "Désactivé"
                enabled: !root.service.shortcut.busy
                onAccepted: root.service.shortcut.apply(text, true)
                // Typing drops the binding; show a saved or reset shortcut again.
                Connections { target: root.service.shortcut; function onValueChanged() { shortcutInput.text = root.service.shortcut.value; } }
            }
            Action { fontFamily: root.fontFamily; text: "Appliquer"; bordered: true; enabled: !root.service.shortcut.busy; onClicked: root.service.shortcut.apply(shortcutInput.text, true) }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: "Super, Ctrl, Alt, Maj + une touche. Laissez vide pour désactiver."; wrapMode: Text.WordWrap; elide: Text.ElideNone; opacity: 0.5; font.pixelSize: Style.font.bodySmall }
        Label { font.family: root.fontFamily;
            Layout.fillWidth: true
            visible: text !== ""
            text: root.service.shortcut.message
            color: root.service.shortcut.successful ? Commons.Color.popups.text : Commons.Color.urgent
            opacity: 0.7; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall
        }
    }
}
