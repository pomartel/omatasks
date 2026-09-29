import QtQuick
import QtQuick.Controls as C
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui as UI
import "../Model.js" as Model

C.Popup {
    id: root
    required property var service
    property var tasks: []
    property string page: "main"
    property string message: ""
    property bool pending: false
    property bool canRetry: false
    property point location: Qt.point(0, 0)
    readonly property var taskIds: tasks.map(function(t) { return String(t.id); })
    readonly property bool busy: pending || service.saving
    signal completed()
    signal editRequested(var task)
    objectName: "taskContextMenu"
    width: Math.min(parent.width, Style.space(310))
    height: Math.min(parent.height, body.implicitHeight + padding * 2)
    x: Math.max(0, Math.min(location.x, parent.width - width))
    y: Math.max(0, Math.min(location.y, parent.height - height))
    padding: Style.space(10)
    focus: true
    closePolicy: busy ? C.Popup.NoAutoClose : C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutside
    background: Rectangle { color: Color.popups.background; border.color: Color.popups.border; radius: Style.cornerRadius }
    onOpened: { page = "main"; message = ""; canRetry = false; input.text = ""; search.text = ""; }
    onPageChanged: Qt.callLater(function() { scroll.contentItem.contentY = 0; })

    function run(action, value) {
        pending = true; message = ""; canRetry = false;
        if (!service.applyTaskAction(taskIds, action, value)) {
            pending = false;
            message = service.error || "Attendez la fin de l’opération en cours.";
        }
    }
    function showPage(value) { page = value; input.text = ""; if (["customDate", "deadline", "reminder"].indexOf(page) >= 0) input.forceActiveFocus(); }
    function submitInput() { if (input.text.trim()) run(page, input.text); }
    contentItem: C.ScrollView {
        id: scroll
        clip: true
        contentWidth: availableWidth
        C.ScrollBar.horizontal.policy: C.ScrollBar.AlwaysOff
        ColumnLayout {
            id: body
            width: parent.width
            spacing: Style.space(5)
            RowLayout {
                Layout.fillWidth: true
                Action { visible: root.page !== "main"; text: "‹"; tip: "Retour"; enabled: !root.busy; onClicked: root.page = "main" }
                Label { Layout.fillWidth: true; text: root.tasks.length === 1 ? "1 tâche sélectionnée" : root.tasks.length + " tâches sélectionnées"; font.bold: true }
                Action { text: "×"; tip: "Fermer le menu"; enabled: !root.busy; onClicked: root.close() }
            }
            Label { visible: root.busy; text: "Enregistrement…"; opacity: 0.6 }
            Label { visible: text !== ""; text: root.message; color: Color.urgent; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone }
            Action {
                visible: root.canRetry && !!root.service.bulkRetry
                text: "Réessayer les modifications restantes"; enabled: !root.busy
                onClicked: { root.pending = true; root.message = ""; if (!root.service.retryTaskAction()) { root.pending = false; root.message = root.service.error || "Veuillez patienter avant de réessayer."; } }
            }
            ColumnLayout {
                visible: root.page === "main"
                enabled: !root.busy
                Layout.fillWidth: true
                spacing: Style.space(5)
                Action { visible: root.tasks.length === 1; text: "Modifier"; leftAligned: true; Layout.fillWidth: true; onClicked: { var task = root.tasks[0]; root.close(); root.editRequested(task); } }
                Action { text: "✓   Terminer"; objectName: "bulkComplete"; leftAligned: true; Layout.fillWidth: true; onClicked: root.run("complete", null) }
                Rectangle { Layout.fillWidth: true; height: 1; color: Color.popups.text; opacity: 0.12 }
                Label { text: "Date"; font.bold: true; Layout.topMargin: Style.space(4) }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(2)
                    Repeater {
                        model: [
                            {value: "today", text: String(root.service.now.getDate()), tip: "Aujourd’hui", color: "#4baf63"},
                            {value: "tomorrow", text: "☀", tip: "Demain", color: "#eb9700"},
                            {value: "weekend", text: "▱", tip: "Cette fin de semaine", color: "#5297ff"},
                            {value: "nextweek", text: "→", tip: "Lundi prochain", color: "#b58ce8"},
                            {value: "", text: "∅", tip: "Retirer la date", color: Color.popups.text},
                            {value: "custom", text: "…", tip: "Choisir une date ou une récurrence", color: Color.popups.text}
                        ]
                        Action {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredWidth: 0
                            text: modelData.text; tip: modelData.tip; foreground: modelData.color
                            objectName: "bulkDate_" + modelData.value
                            onClicked: modelData.value === "custom" ? root.showPage("customDate") : root.run("date", modelData.value)
                        }
                    }
                }
                Label { text: "Priorité"; font.bold: true; Layout.topMargin: Style.space(4) }
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: [4, 3, 2, 1]
                        Action {
                            required property int modelData
                            Layout.fillWidth: true; text: "⚑ P" + (5 - modelData)
                            objectName: "bulkPriority_" + modelData
                            foreground: ["", "#999999", "#5297ff", "#eb9700", "#ef615b"][modelData]
                            selected: root.tasks.length > 0 && root.tasks.every(function(t) { return (t.priority || 1) === modelData; })
                            onClicked: root.run("priority", modelData)
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Color.popups.text; opacity: 0.12; Layout.topMargin: Style.space(4) }
                Action { text: "⚑   Date limite…"; leftAligned: true; Layout.fillWidth: true; onClicked: root.showPage("deadline") }
                Action { text: "◷   Ajouter un rappel…"; leftAligned: true; Layout.fillWidth: true; onClicked: root.showPage("reminder") }
                Action { text: "Déplacer vers…"; objectName: "bulkMove"; leftAligned: true; Layout.fillWidth: true; onClicked: root.showPage("move") }
                Action { text: "Dupliquer"; objectName: "bulkDuplicate"; leftAligned: true; Layout.fillWidth: true; tip: "Copier les tâches et sous-tâches, sans commentaires ni rappels"; onClicked: root.run("duplicate", null) }
                Action {
                    text: root.tasks.length === 1 ? "Copier le lien de la tâche" : "Copier les liens des tâches"
                    leftAligned: true; Layout.fillWidth: true
                    onClicked: { Quickshell.clipboardText = root.tasks.map(function(t) { return "https://app.todoist.com/app/task/" + encodeURIComponent(t.id); }).join("\n"); root.close(); }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Color.popups.text; opacity: 0.12 }
                Action { text: "Supprimer…"; objectName: "bulkDelete"; foreground: Color.urgent; leftAligned: true; Layout.fillWidth: true; onClicked: root.showPage("delete") }
            }
            ColumnLayout {
                visible: ["customDate", "deadline", "reminder"].indexOf(root.page) >= 0
                enabled: !root.busy
                Layout.fillWidth: true
                Label { text: root.page === "customDate" ? "Date ou récurrence" : root.page === "deadline" ? "Date limite" : "Ajouter un rappel"; font.bold: true }
                UI.TextField {
                    id: input
                    objectName: "bulkDateInput"
                    Layout.fillWidth: true
                    placeholderText: root.page === "deadline" ? "AAAA-MM-JJ ou demain" : root.page === "reminder" ? "Demain à 9h ou 30mb" : "Vendredi à 10h ou chaque lundi"
                    onAccepted: root.submitInput()
                }
                Action { text: "Appliquer à " + root.tasks.length + (root.tasks.length === 1 ? " tâche" : " tâches"); enabled: input.text.trim() !== ""; objectName: "bulkApplyInput"; onClicked: root.submitInput() }
                Action { visible: root.page === "deadline"; text: "Retirer la date limite"; onClicked: root.run("deadline", "") }
            }
            ColumnLayout {
                visible: root.page === "move"
                enabled: !root.busy
                Layout.fillWidth: true
                Label { text: "Déplacer vers un projet ou une section"; font.bold: true }
                UI.TextField { id: search; Layout.fillWidth: true; placeholderText: "Rechercher un projet ou une section…" }
                Repeater {
                    model: {
                        var destinations = [];
                        root.service.projects.forEach(function(project) {
                            destinations.push({text: project.name, args: {project_id: String(project.id)}});
                            root.service.sections.filter(function(s) { return String(s.project_id) === String(project.id); }).forEach(function(section) {
                                destinations.push({text: project.name + " / " + section.name, args: {section_id: String(section.id)}});
                            });
                        });
                        return destinations.filter(function(d) { return d.text.toLowerCase().indexOf(search.text.toLowerCase()) >= 0; });
                    }
                    Action { required property var modelData; text: modelData.text; leftAligned: true; Layout.fillWidth: true; onClicked: root.run("move", modelData.args) }
                }
            }
            ColumnLayout {
                visible: root.page === "delete"
                enabled: !root.busy
                Layout.fillWidth: true
                Label { text: "Supprimer " + root.tasks.length + (root.tasks.length === 1 ? " tâche" : " tâches") + " et leurs sous-tâches ?"; wrapMode: Text.Wrap; elide: Text.ElideNone; Layout.fillWidth: true }
                RowLayout {
                    Action { text: "Annuler"; onClicked: root.page = "main" }
                    Action { text: "Supprimer"; objectName: "bulkConfirmDelete"; foreground: Color.urgent; bordered: true; onClicked: root.run("delete", null) }
                }
            }
        }
    }
    Connections {
        target: root.service
        function onTaskActionFinished() { if (root.pending) { root.pending = false; root.close(); root.completed(); } }
        function onOperationFailed(message) { if (root.pending) { root.pending = false; root.message = message; root.canRetry = true; } }
        function onTokenChanged() { root.pending = false; root.canRetry = false; root.close(); }
        function onTasksChanged() {
            if (!root.visible || root.pending || root.canRetry) return;
            var ids = root.taskIds;
            root.tasks = root.service.tasks.filter(function(t) { return ids.indexOf(String(t.id)) >= 0; });
            if (!root.tasks.length) root.close();
        }
    }
}
