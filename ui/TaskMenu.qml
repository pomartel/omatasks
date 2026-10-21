import "../i18n/Fr.js" as Fr
import QtQuick
import QtQuick.Controls as C
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui as UI
import "../Model.js" as Model

C.Popup {
    id: root
    required property var service
    readonly property string fontFamily: service.fontFamily
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
    background: Rectangle { color: Commons.Color.popups.background; border.color: Commons.Color.popups.border; radius: Style.cornerRadius }
    onOpened: { page = "main"; message = ""; canRetry = false; input.text = ""; search.text = ""; }
    onPageChanged: Qt.callLater(function() { scroll.contentItem.contentY = 0; })

    function run(action, value) {
        pending = true; message = ""; canRetry = false;
        if (!service.applyTaskAction(taskIds, action, value)) {
            pending = false;
            message = service.error || Fr.t("text.attendez_la_fin_de_loperation_en_cours");
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
                Action { fontFamily: root.fontFamily; visible: root.page !== "main"; text: "‹"; tip: Fr.t("text.retour"); enabled: !root.busy; onClicked: root.page = "main" }
                Label { font.family: root.fontFamily; Layout.fillWidth: true; text: root.tasks.length === 1 ? Fr.t("text.1_tache_selectionnee") : Fr.t("selection.many", root.tasks.length); font.bold: true }
                Action { fontFamily: root.fontFamily; text: "×"; tip: Fr.t("text.fermer_le_menu"); enabled: !root.busy; onClicked: root.close() }
            }
            Label { font.family: root.fontFamily; visible: root.busy; text: Fr.t("text.enregistrement"); opacity: 0.6 }
            Label { font.family: root.fontFamily; visible: text !== ""; text: root.message; color: Commons.Color.urgent; Layout.fillWidth: true; wrapMode: Text.Wrap; elide: Text.ElideNone }
            Action { fontFamily: root.fontFamily;
                visible: root.canRetry && !!root.service.bulkRetry
                text: Fr.t("text.reessayer_les_modifications_restantes"); enabled: !root.busy
                onClicked: { root.pending = true; root.message = ""; if (!root.service.retryTaskAction()) { root.pending = false; root.message = root.service.error || Fr.t("text.veuillez_patienter_avant_de_reessayer"); } }
            }
            ColumnLayout {
                visible: root.page === "main"
                enabled: !root.busy
                Layout.fillWidth: true
                spacing: Style.space(5)
                Action { fontFamily: root.fontFamily; visible: root.tasks.length === 1; text: Fr.t("text.modifier"); leftAligned: true; Layout.fillWidth: true; onClicked: { var task = root.tasks[0]; root.close(); root.editRequested(task); } }
                Action { fontFamily: root.fontFamily; text: Fr.t("text.terminer_dac711"); objectName: "bulkComplete"; leftAligned: true; Layout.fillWidth: true; onClicked: root.run("complete", null) }
                Rectangle { Layout.fillWidth: true; height: 1; color: Commons.Color.popups.text; opacity: 0.12 }
                Label { font.family: root.fontFamily; text: Fr.t("text.date"); font.bold: true; Layout.topMargin: Style.space(4) }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(2)
                    Repeater {
                        model: [
                            {value: "today", text: String(root.service.now.getDate()), tip: Fr.t("text.aujourdhui"), color: "#4baf63"},
                            {value: "tomorrow", text: "☀", tip: Fr.t("text.demain"), color: "#eb9700"},
                            {value: "weekend", text: "▱", tip: Fr.t("text.cette_fin_de_semaine"), color: "#5297ff"},
                            {value: "nextweek", text: "→", tip: Fr.t("text.lundi_prochain"), color: "#b58ce8"},
                            {value: "", text: "∅", tip: Fr.t("text.retirer_la_date"), color: Commons.Color.popups.text},
                            {value: "custom", text: "…", tip: Fr.t("text.choisir_une_date_ou_une_recurrence"), color: Commons.Color.popups.text}
                        ]
                        Action { fontFamily: root.fontFamily;
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredWidth: 0
                            text: modelData.text; tip: modelData.tip; foreground: modelData.color
                            objectName: "bulkDate_" + modelData.value
                            onClicked: modelData.value === "custom" ? root.showPage("customDate") : root.run("date", modelData.value)
                        }
                    }
                }
                Label { font.family: root.fontFamily; text: Fr.t("text.priorite"); font.bold: true; Layout.topMargin: Style.space(4) }
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: [4, 3, 2, 1]
                        Action { fontFamily: root.fontFamily;
                            required property int modelData
                            Layout.fillWidth: true; text: "⚑ P" + (5 - modelData)
                            objectName: "bulkPriority_" + modelData
                            foreground: ["", "#999999", "#5297ff", "#eb9700", "#ef615b"][modelData]
                            selected: root.tasks.length > 0 && root.tasks.every(function(t) { return (t.priority || 1) === modelData; })
                            onClicked: root.run("priority", modelData)
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Commons.Color.popups.text; opacity: 0.12; Layout.topMargin: Style.space(4) }
                Action { fontFamily: root.fontFamily; text: Fr.t("text.date_limite_1d0c16"); leftAligned: true; Layout.fillWidth: true; onClicked: root.showPage("deadline") }
                Action { fontFamily: root.fontFamily; text: Fr.t("text.ajouter_un_rappel_219fb9"); leftAligned: true; Layout.fillWidth: true; onClicked: root.showPage("reminder") }
                Action { fontFamily: root.fontFamily; text: Fr.t("text.deplacer_vers"); objectName: "bulkMove"; leftAligned: true; Layout.fillWidth: true; onClicked: root.showPage("move") }
                Action { fontFamily: root.fontFamily; text: Fr.t("text.dupliquer"); objectName: "bulkDuplicate"; leftAligned: true; Layout.fillWidth: true; tip: Fr.t("text.copier_les_taches_et_sous_taches_sans_commentaires_ni_rappels"); onClicked: root.run("duplicate", null) }
                Action { fontFamily: root.fontFamily;
                    text: root.tasks.length === 1 ? Fr.t("text.copier_le_lien_de_la_tache") : Fr.t("text.copier_les_liens_des_taches")
                    leftAligned: true; Layout.fillWidth: true
                    onClicked: { Quickshell.clipboardText = root.tasks.map(function(t) { return "https://app.todoist.com/app/task/" + encodeURIComponent(t.id); }).join("\n"); root.close(); }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Commons.Color.popups.text; opacity: 0.12 }
                Action { fontFamily: root.fontFamily; text: Fr.t("text.supprimer"); objectName: "bulkDelete"; foreground: Commons.Color.urgent; leftAligned: true; Layout.fillWidth: true; onClicked: root.run("delete", null) }
            }
            ColumnLayout {
                visible: ["customDate", "deadline", "reminder"].indexOf(root.page) >= 0
                enabled: !root.busy
                Layout.fillWidth: true
                Label { font.family: root.fontFamily; text: root.page === "customDate" ? Fr.t("text.date_ou_recurrence") : root.page === "deadline" ? Fr.t("text.date_limite") : Fr.t("text.ajouter_un_rappel"); font.bold: true }
                UI.TextField {
                    id: input
                    objectName: "bulkDateInput"
                    Layout.fillWidth: true
                    placeholderText: root.page === "deadline" ? Fr.t("text.aaaa_mm_jj_ou_demain") : root.page === "reminder" ? Fr.t("text.demain_a_9h_ou_30mb") : Fr.t("text.vendredi_a_10h_ou_chaque_lundi")
                    onAccepted: root.submitInput()
                }
                Action { fontFamily: root.fontFamily; text: Fr.t("text.appliquer_a") + root.tasks.length + (root.tasks.length === 1 ? Fr.t("text.tache") : Fr.t("text.taches")); enabled: input.text.trim() !== ""; objectName: "bulkApplyInput"; onClicked: root.submitInput() }
                Action { fontFamily: root.fontFamily; visible: root.page === "deadline"; text: Fr.t("text.retirer_la_date_limite"); onClicked: root.run("deadline", "") }
            }
            ColumnLayout {
                visible: root.page === "move"
                enabled: !root.busy
                Layout.fillWidth: true
                Label { font.family: root.fontFamily; text: Fr.t("text.deplacer_vers_un_projet_ou_une_section"); font.bold: true }
                UI.TextField { id: search; Layout.fillWidth: true; placeholderText: Fr.t("text.rechercher_un_projet_ou_une_section") }
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
                    Action { fontFamily: root.fontFamily; required property var modelData; text: modelData.text; leftAligned: true; Layout.fillWidth: true; onClicked: root.run("move", modelData.args) }
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
