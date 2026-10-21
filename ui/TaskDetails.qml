import "../i18n/Fr.js" as Fr
import QtQuick
import QtQuick.Controls as C
import QtQuick.Layouts
import qs.Commons
import qs.Commons as Commons
import "../Model.js" as Model
import "EditModel.js" as Edit

Item {
    id: root
    required property var service
    readonly property string fontFamily: service.fontFamily
    required property var task
    property bool editing: false
    property string highlightedSubtaskId: ""
    onTaskChanged: highlightedSubtaskId = ""
    property bool completing: false
    property string message: ""
    readonly property bool busy: completing || (editor.item ? editor.item.submitting : false)
    readonly property var subtasks: service.tasks.filter(function(t) { return String(t.parent_id) === String(root.task.id); })
    readonly property var taskReminders: service.reminders.filter(function(r) { return String(r.item_id) === String(root.task.id); })
    readonly property var parentTask: service.tasks.find(function(t) { return String(t.id) === String(root.task.parent_id); }) || null
    readonly property var person: Model.byId(service.collaborators)[Model.assigned(task)]
    readonly property int completedChildren: {
        var record = service.completedInfo.find(function(x) { return String(x.item_id) === String(root.task.id); });
        return record ? Number(record.completed_items) || 0 : 0;
    }
    readonly property var information: [
        {name: Fr.t("text.projet"), value: Model.projectPath(task.project_id, service.projectMap, task.section_id, service.sectionMap)},
        {name: Fr.t("text.date"), value: task.due ? Model.dueLabel(task, service.now, "details", "none") + (task.due.timezone ? " · " + task.due.timezone : "") : Fr.t("text.sans_date")},
        {name: Fr.t("text.repetition"), value: task.due && task.due.is_recurring ? task.due.string || Fr.t("text.recurrente") : ""},
        {name: Fr.t("text.duree"), value: task.duration ? task.duration.amount + " " + (task.duration.unit === "day" ? Fr.t("text.jours_5cd11d") : Fr.t("text.minutes_90e63d")) : ""},
        {name: Fr.t("text.date_limite"), value: task.deadline ? task.deadline.date : ""},
        {name: Fr.t("text.priorite"), value: "P" + (5 - Number(task.priority || 1)), color: ["#999999", "#999999", "#5297ff", "#eb9700", "#ef615b"][task.priority || 1]},
        {name: Fr.t("text.etiquettes"), value: (task.labels || []).join(" · ") || Fr.t("text.aucune")},
        {name: Fr.t("text.responsable"), value: person ? person.full_name || person.name || person.email : Model.assigned(task) === String(service.user.id) ? Fr.t("text.moi") : Model.assigned(task) ? Fr.t("text.responsable") : Fr.t("text.non_attribuee")}
    ].filter(function(row) { return row.value; })
    implicitHeight: body.implicitHeight + footer.implicitHeight + Style.space(14)
    signal closeRequested()
    signal taskRequested(var task)

    function startEditing() { editing = true; message = ""; scroll.contentItem.contentY = 0; Qt.callLater(function() { if (editor.item) editor.item.focusInput(); }); }
    function complete() { message = ""; completing = service.completeTask(task); if (!completing) message = service.error || Fr.t("text.attendez_la_fin_de_loperation_en_cours"); }
    function dismissEditor() { if (busy) return; if (editing) editing = false; else closeRequested(); }

    C.ScrollView {
        id: scroll
        objectName: "taskDetailScroll"
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.bottom: footer.top; anchors.bottomMargin: Style.space(12)
        clip: true
        contentWidth: availableWidth
        C.ScrollBar.horizontal.policy: C.ScrollBar.AlwaysOff
        ColumnLayout {
            id: body
            width: scroll.availableWidth
            spacing: Style.space(12)
            ColumnLayout {
                visible: !root.editing
                Layout.fillWidth: true; Layout.minimumWidth: 0
                spacing: Style.space(12)
                RowLayout {
                    Layout.fillWidth: true; Layout.minimumWidth: 0
                    spacing: Style.space(5)
                    TaskCheck { fontFamily: root.fontFamily; Layout.alignment: Qt.AlignTop; task: root.task; enabled: !root.service.saving; onClicked: root.complete() }
                    LinkLabel { font.family: root.fontFamily; Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.alignment: Qt.AlignTop; Layout.topMargin: Style.space(5); sourceText: root.task.content || ""; wrapMode: Text.Wrap; elide: Text.ElideNone; font.bold: true }
                }
                LinkLabel { font.family: root.fontFamily; Layout.fillWidth: true; Layout.minimumWidth: 0; sourceText: root.task.description || ""; visible: text !== ""; wrapMode: Text.Wrap; elide: Text.ElideNone; opacity: 0.7 }
                Rectangle { Layout.fillWidth: true; height: 1; color: Commons.Color.popups.text; opacity: 0.12 }
                Repeater {
                    model: root.information
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true; Layout.minimumWidth: 0
                        spacing: Style.space(10)
                        Label { font.family: root.fontFamily; Layout.preferredWidth: Style.space(90); Layout.alignment: Qt.AlignTop; text: modelData.name; opacity: 0.5; font.pixelSize: Style.font.bodySmall }
                        Label { font.family: root.fontFamily; Layout.fillWidth: true; Layout.minimumWidth: 0; text: modelData.value; color: modelData.color || Commons.Color.popups.text; wrapMode: Text.Wrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall }
                    }
                }
                Repeater {
                    model: root.taskReminders
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true; Layout.minimumWidth: 0
                        spacing: Style.space(10)
                        Label { font.family: root.fontFamily; Layout.preferredWidth: Style.space(90); Layout.alignment: Qt.AlignTop; text: Fr.t("text.rappel"); opacity: 0.5; font.pixelSize: Style.font.bodySmall }
                        Label { font.family: root.fontFamily; Layout.fillWidth: true; Layout.minimumWidth: 0; text: Edit.reminderText(modelData); wrapMode: Text.Wrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall }
                    }
                }
                Action { fontFamily: root.fontFamily; visible: root.parentTask !== null; text: "↑ " + Model.plain((root.parentTask || {}).content); maximumWidth: root.width; tip: Fr.t("text.tache_parente"); onClicked: root.taskRequested(root.parentTask) }
                Label { font.family: root.fontFamily; visible: root.subtasks.length + root.completedChildren > 0; text: Fr.t("task.subtasks", root.completedChildren, root.completedChildren + root.subtasks.length); font.bold: true }
                Repeater {
                    model: root.subtasks
                    TaskRow { required property var modelData; Layout.fillWidth: true; Layout.minimumWidth: 0; task: modelData; service: root.service; view: "details"; selected: root.highlightedSubtaskId === String(task.id); onHighlighted: function(task) { root.highlightedSubtaskId = String(task.id); } onSelectionToggled: function(task) { root.highlightedSubtaskId = selected ? "" : String(task.id); } onActivated: function(task) { root.taskRequested(task); } }
                }
                Action { fontFamily: root.fontFamily; visible: Number(root.task.note_count || root.task.comment_count || 0) > 0; text: Fr.t("task.comments", root.task.note_count || root.task.comment_count || 0); maximumWidth: root.width; onClicked: root.service.openTodoist(root.task) }
                Label { font.family: root.fontFamily; visible: !!root.task.added_at; Layout.fillWidth: true; Layout.minimumWidth: 0; text: root.task.added_at ? Fr.t("text.ajoutee_le") + new Date(root.task.added_at).toLocaleString(Qt.locale("fr_CA"), "d MMM yyyy, HH:mm") : ""; opacity: 0.4; font.pixelSize: Style.font.caption; wrapMode: Text.Wrap; elide: Text.ElideNone }
            }
            Loader {
                id: editor
                active: root.editing
                Layout.fillWidth: true; Layout.minimumWidth: 0
                sourceComponent: Composer {
                    service: root.service
                    editingTask: root.task
                    onFinished: root.editing = false
                    onCancelled: root.editing = false
                }
            }
            Label { font.family: root.fontFamily; Layout.fillWidth: true; Layout.minimumWidth: 0; visible: text !== ""; text: root.message; wrapMode: Text.Wrap; elide: Text.ElideNone; color: Commons.Color.urgent }
        }
    }
    ColumnLayout {
        id: footer
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        spacing: Style.space(6)
        RowLayout {
            Layout.fillWidth: true
            Action { fontFamily: root.fontFamily; objectName: "editTaskButton"; visible: !root.editing; text: Fr.t("text.modifier"); bordered: true; enabled: !root.service.saving; onClicked: root.startEditing() }
            Action { fontFamily: root.fontFamily; text: Fr.t("text.ouvrir_dans_todoist"); onClicked: root.service.openTodoist(root.task) }
            Item { Layout.fillWidth: true }
            Action { fontFamily: root.fontFamily; visible: !root.editing; text: Fr.t("text.fermer"); enabled: !root.busy; onClicked: root.dismissEditor() }
        }
    }
    Connections {
        target: root.service
        function onTaskCompleted(taskId) { if (taskId === String(root.task.id)) { root.completing = false; root.closeRequested(); } }
        function onOperationFailed(message) { if (root.completing) { root.completing = false; root.message = message; } }
    }
}
