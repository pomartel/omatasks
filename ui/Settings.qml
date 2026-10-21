import "../i18n/Fr.js" as Fr
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
        Label { font.family: root.fontFamily; text: Fr.t("text.panneau_et_barre"); font.bold: true }
        RowLayout {
            Layout.fillWidth: true
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.largeur") }
            SizeControl { value: root.service.panelWidth; from: 360; to: 1000; Accessible.name: Fr.t("text.largeur_du_panneau"); onValueModified: root.service.setPanelSize("panelWidth", value) }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.hauteur_maximale") }
            SizeControl { value: root.service.panelHeight; from: 280; to: 1200; Accessible.name: Fr.t("text.hauteur_maximale_du_panneau"); onValueModified: root.service.setPanelSize("panelHeight", value) }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.en_pixels_le_panneau_sadapte_aux_listes_plus_courtes"); font.pixelSize: Style.font.bodySmall; opacity: 0.5; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Style.space(6)
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.dans_la_barre") }
            UI.Dropdown {
                objectName: "barMode"
                Layout.preferredWidth: Style.space(190)
                showLabel: false; fontFamily: root.fontFamily
                value: root.service.barMode
                options: [{value: "task", label: Fr.t("text.prochaine_tache")}, {value: "count", label: Fr.t("text.nombre_de_taches_aujourdhui")}, {value: "icon", label: Fr.t("text.icone_seulement")}]
                onChanged: function(value) { root.service.setBarMode(value); }
            }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.prochaine_tache_a_heure_fixe_celle_en_cours_puis_celle_en_retard_"); font.pixelSize: Style.font.bodySmall; opacity: 0.5; wrapMode: Text.WordWrap; elide: Text.ElideNone; visible: root.service.barMode === "task" }
    }
    Rectangle { visible: root.service.configured; Layout.fillWidth: true; height: 1; color: Commons.Color.popups.text; opacity: 0.12 }
    ColumnLayout {
        id: notifications
        visible: root.service.configured
        Layout.fillWidth: true
        spacing: Style.space(8)
        readonly property var options: root.service.notifySettings
        Label { font.family: root.fontFamily; text: Fr.t("text.notifications"); font.bold: true }
        Repeater {
            model: [
                {key: "enabled", label: Fr.t("text.afficher_les_notifications"), detail: Fr.t("text.vos_rappels_todoist_avec_les_boutons_terminer_et_reporter")},
                {key: "atDueTime", label: Fr.t("text.a_lheure_de_chaque_tache"), detail: Fr.t("text.meme_si_la_tache_na_pas_de_rappel")},
                {key: "deadlines", label: Fr.t("text.alertes_de_date_limite"), detail: Fr.t("text.la_veille_et_le_jour_de_la_date_limite_a_lheure_du_recapitulatif")},
                {key: "recap", label: Fr.t("text.recapitulatif_du_matin"), detail: Fr.t("text.les_taches_du_jour_et_les_dates_limites_des_trois_prochains_jours")}
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
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.heure_du_recapitulatif") }
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
                text: Fr.t("text.appliquer"); bordered: true
                function apply() { message = root.service.setNotification("recapTime", recapInput.text) ? "" : Fr.t("text.utilisez_une_heure_sur_24_heures_par_exemple_08_00"); }
                onClicked: apply()
            }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; visible: text !== ""; text: recapApply.message; color: Commons.Color.urgent; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall }
        RowLayout {
            Layout.fillWidth: true
            enabled: notifications.options.enabled
            opacity: enabled ? 1 : 0.4
            Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.repeter_les_taches_en_retard") }
            UI.Dropdown {
                Layout.preferredWidth: Style.space(150)
                showLabel: false; fontFamily: root.fontFamily
                value: String(notifications.options.overdueHours)
                options: [{value: "0", label: Fr.t("text.jamais")}, {value: "1", label: Fr.t("text.chaque_heure")}, {value: "2", label: Fr.t("text.toutes_les_2_heures")}, {value: "4", label: Fr.t("text.toutes_les_4_heures")}]
                onChanged: function(value) { root.service.setNotification("overdueHours", Number(value)); }
            }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.repete_les_rappels_des_taches_a_heure_fixe_encore_ouvertes_le_jou"); opacity: 0.5; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall; visible: notifications.options.enabled }
        Action { fontFamily: root.fontFamily;
            text: Fr.t("text.afficher_le_recapitulatif_maintenant"); leftAligned: true
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
        Label { font.family: root.fontFamily; text: Fr.t("text.raccourci_dajout_rapide"); font.bold: true }
        RowLayout {
            Layout.fillWidth: true
            UI.TextField { font.family: root.fontFamily;
                id: shortcutInput
                Layout.fillWidth: true
                text: root.service.shortcut.value
                placeholderText: Fr.t("text.desactive")
                enabled: !root.service.shortcut.busy
                onAccepted: root.service.shortcut.apply(text, true)
                // Typing drops the binding; show a saved or reset shortcut again.
                Connections { target: root.service; function onPreferencesChanged() { shortcutInput.text = root.service.shortcut.value; } }
            }
            Action { fontFamily: root.fontFamily; text: Fr.t("text.appliquer"); bordered: true; enabled: !root.service.shortcut.busy; onClicked: root.service.shortcut.apply(shortcutInput.text, true) }
        }
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: Fr.t("text.super_ctrl_alt_maj_une_touche_laissez_vide_pour_desactiver"); wrapMode: Text.WordWrap; elide: Text.ElideNone; opacity: 0.5; font.pixelSize: Style.font.bodySmall }
        Label { font.family: root.fontFamily;
            Layout.fillWidth: true
            visible: text !== ""
            text: root.service.shortcut.message
            color: root.service.shortcut.successful ? Commons.Color.popups.text : Commons.Color.urgent
            opacity: 0.7; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall
        }
    }
}
