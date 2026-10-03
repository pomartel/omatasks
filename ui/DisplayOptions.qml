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
    Label { font.family: root.fontFamily; text: "Tri"; font.bold: true }
    Repeater {
        model: [
            {key: "grouping", label: "Regroupement", values: [{value: "none", label: "Aucune"}, {value: "project", label: "Projet"}, {value: "priority", label: "Priorité"}, {value: "date", label: "Date"}, {value: "label", label: "Étiquette"}]},
            {key: "sorting", label: "Ordre", values: [{value: "smart", label: "Intelligent"}, {value: "manual", label: "Manuel"}, {value: "name", label: "Nom"}, {value: "assignee", label: "Responsable"}, {value: "date", label: "Date"}, {value: "added", label: "Date d’ajout"}, {value: "deadline", label: "Date limite"}, {value: "priority", label: "Priorité"}, {value: "project", label: "Projet"}]}
        ]
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Label { font.family: root.fontFamily; text: modelData.label; Layout.preferredWidth: Style.space(100) }
            UI.Dropdown { Layout.fillWidth: true; showLabel: false; fontFamily: root.fontFamily; value: root.options[modelData.key]; options: modelData.values; onChanged: function(value) { root.service.setOption(root.view, modelData.key, value); } }
        }
    }
    Label { font.family: root.fontFamily; text: "Filtres"; font.bold: true; Layout.topMargin: Style.space(6) }
    Repeater {
        model: [
            {key: "assignee", label: "Responsable", values: [{value: "mine", label: "Moi et non attribuées"}, {value: "all", label: "Tout le monde"}, {value: "me", label: "Moi"}, {value: "unassigned", label: "Non attribuée"}]},
            {key: "deadline", label: "Date limite", values: [{value: "all", label: "Toutes"}, {value: "has", label: "Avec date limite"}, {value: "none", label: "Sans date limite"}, {value: "overdue", label: "En retard"}]},
            {key: "priority", label: "Priorité", values: [{value: "all", label: "Toutes"}, {value: "4", label: "Priorité 1"}, {value: "3", label: "Priorité 2"}, {value: "2", label: "Priorité 3"}, {value: "1", label: "Priorité 4"}]},
            {key: "label", label: "Étiquette", values: [{value: "all", label: "Toutes"}].concat(root.service.labels.map(function(l) { return {value: l.name, label: l.name}; }))}
        ]
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Label { font.family: root.fontFamily; text: modelData.label; Layout.preferredWidth: Style.space(100) }
            UI.Dropdown { Layout.fillWidth: true; showLabel: false; fontFamily: root.fontFamily; value: root.options[modelData.key]; options: modelData.values; onChanged: function(value) { root.service.setOption(root.view, modelData.key, value); } }
        }
    }
    RowLayout {
        Action { fontFamily: root.fontFamily; text: "Réinitialiser la vue"; onClicked: root.service.resetView(root.view) }
        Item { Layout.fillWidth: true }
        Action { fontFamily: root.fontFamily; text: root.service.loading ? "Actualisation…" : "Actualiser"; enabled: !root.service.loading; onClicked: root.service.refresh(true) }
    }
}
