import "../i18n/Fr.js" as Fr
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as UI

ColumnLayout {
    id: root
    required property var service
    readonly property string fontFamily: service.fontFamily
    required property string view
    readonly property var options: service.viewOptions(view)
    spacing: Style.space(10)
    Label { font.family: root.fontFamily; text: Fr.t("text.tri"); font.bold: true }
    Repeater {
        model: [
            {key: "grouping", label: Fr.t("text.regroupement"), values: [{value: "none", label: Fr.t("text.aucune")}, {value: "project", label: Fr.t("text.projet")}, {value: "priority", label: Fr.t("text.priorite")}, {value: "date", label: Fr.t("text.date")}, {value: "label", label: Fr.t("text.etiquette")}]},
            {key: "sorting", label: Fr.t("text.ordre"), values: [{value: "smart", label: Fr.t("text.intelligent")}, {value: "manual", label: Fr.t("text.manuel")}, {value: "name", label: Fr.t("text.nom")}, {value: "assignee", label: Fr.t("text.responsable")}, {value: "date", label: Fr.t("text.date")}, {value: "added", label: Fr.t("text.date_dajout")}, {value: "deadline", label: Fr.t("text.date_limite")}, {value: "priority", label: Fr.t("text.priorite")}, {value: "project", label: Fr.t("text.projet")}]}
        ]
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Label { font.family: root.fontFamily; text: modelData.label; Layout.preferredWidth: Style.space(100) }
            UI.Dropdown { Layout.fillWidth: true; showLabel: false; fontFamily: root.fontFamily; value: root.options[modelData.key]; options: modelData.values; onChanged: function(value) { root.service.setOption(root.view, modelData.key, value); } }
        }
    }
    Label { font.family: root.fontFamily; text: Fr.t("text.filtres"); font.bold: true; Layout.topMargin: Style.space(6) }
    Repeater {
        model: [
            {key: "assignee", label: Fr.t("text.responsable"), values: [{value: "mine", label: Fr.t("text.moi_et_non_attribuees")}, {value: "all", label: Fr.t("text.tout_le_monde")}, {value: "me", label: Fr.t("text.moi")}, {value: "unassigned", label: Fr.t("text.non_attribuee")}]},
            {key: "deadline", label: Fr.t("text.date_limite"), values: [{value: "all", label: Fr.t("text.toutes")}, {value: "has", label: Fr.t("text.avec_date_limite")}, {value: "none", label: Fr.t("text.sans_date_limite")}, {value: "overdue", label: Fr.t("text.en_retard")}]},
            {key: "priority", label: Fr.t("text.priorite"), values: [{value: "all", label: Fr.t("text.toutes")}, {value: "4", label: Fr.t("text.priorite_1")}, {value: "3", label: Fr.t("text.priorite_2")}, {value: "2", label: Fr.t("text.priorite_3")}, {value: "1", label: Fr.t("text.priorite_4")}]},
            {key: "label", label: Fr.t("text.etiquette"), values: [{value: "all", label: Fr.t("text.toutes")}].concat(root.service.labels.map(function(l) { return {value: l.name, label: l.name}; }))}
        ]
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Label { font.family: root.fontFamily; text: modelData.label; Layout.preferredWidth: Style.space(100) }
            UI.Dropdown { Layout.fillWidth: true; showLabel: false; fontFamily: root.fontFamily; value: root.options[modelData.key]; options: modelData.values; onChanged: function(value) { root.service.setOption(root.view, modelData.key, value); } }
        }
    }
    RowLayout {
        Action { fontFamily: root.fontFamily; text: Fr.t("text.reinitialiser_la_vue"); onClicked: root.service.resetView(root.view) }
        Item { Layout.fillWidth: true }
        Action { fontFamily: root.fontFamily; text: root.service.loading ? Fr.t("text.actualisation") : Fr.t("text.actualiser"); enabled: !root.service.loading; onClicked: root.service.refresh(true) }
    }
}
