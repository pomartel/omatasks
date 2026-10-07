import QtQuick
import QtQuick.Window
import QtQuick.Controls as C
import QtQuick.Layouts
import qs.Commons
import "../Model.js" as Model
import "OrderModel.js" as Order
import "BulkModel.js" as Bulk

FocusScope {
    id: root
    required property var service
    readonly property string fontFamily: service.fontFamily
    property string view: "today"
    property string keyboardTaskId: ""
    property string keyboardAddKey: ""
    property var completionFocus: null
    property bool helpOpen: false
    property bool settingsOpen: false
    property string composerKey: ""
    property string composerProject: ""
    property var heldRows: null
    property var selectedTask: null
    property var selectedIds: []
    property var dragRows: null
    property int dragIndex: -1
    property int dropIndex: -1
    property bool dropAfter: false
    property real dragX: 0
    property real dragY: 0
    property real dropY: 0
    readonly property bool dragging: dragIndex >= 0
    readonly property var options: service.viewOptions(view)
    readonly property var rows: dragRows || heldRows || Model.viewRows(service.tasks, service.projects, service.collaborators, options, view, service.user.id, service.now)
    readonly property bool setupVisible: !service.configured || settingsOpen
    readonly property real preferredHeight: Math.min(Style.space(service.panelHeight), setupVisible ? setup.implicitHeight + Style.space(68) : Math.max(display.opened || details.opened || taskMenu.visible ? Style.space(440) : Style.space(110), list.contentHeight + header.height + status.height + selectionBar.height + Style.space(8)))
    signal closeRequested()

    function updateListModel() {
        if (!list) return;
        var offset = list.contentY - list.originY;
        list.model = rows;
        list.forceLayout();
        list.contentY = list.originY + Math.max(0, Math.min(offset, list.contentHeight - list.height));
    }
    onRowsChanged: {
        updateListModel();
        var visible = Bulk.visibleIds(rows);
        selectedIds = selectedIds.filter(function(id) { return visible.indexOf(id) >= 0; });
        if (visible.indexOf(keyboardTaskId) < 0) keyboardTaskId = "";
        if (!rows.some(function(r) { return r.kind === "add" && r.key === keyboardAddKey; })) keyboardAddKey = "";
    }
    Component.onCompleted: updateListModel()

    function addAt(key, projectId) {
        clearSelection();
        heldRows = rows;
        composerProject = projectId || "";
        composerKey = key;
        Qt.callLater(function() { var index = root.rows.findIndex(function(row) { return row.key === key; }); if (index >= 0) list.positionViewAtIndex(index, ListView.Contain); });
    }
    function clearSelection() { selectedIds = []; taskMenu.close(); }
    function toggleSelection(task) {
        if (dragging || service.saving) return;
        selectedIds = Bulk.toggle(selectedIds, task.id);
        forceActiveFocus();
    }
    function openTaskMenu(task, point) {
        if (dragging || service.saving || composerKey) return;
        if (selectedIds.indexOf(String(task.id)) < 0) selectedIds = [String(task.id)];
        taskMenu.tasks = service.tasks.filter(function(t) { return root.selectedIds.indexOf(String(t.id)) >= 0; });
        taskMenu.location = point;
        display.close();
        taskMenu.open();
    }
    function reset() { completionFocus = null; keyboardTaskId = ""; keyboardAddKey = ""; helpOpen = false; clearSelection(); settingsOpen = false; display.close(); details.close(); }
    function completeTask(task) {
        if (service.saving) return;
        var ids = Bulk.visibleIds(rows), id = String(task.id), index = ids.indexOf(id);
        completionFocus = {id: id, candidates: ids.slice(index + 1).concat(ids.slice(0, index).reverse())};
        if (!service.completeTask(task)) completionFocus = null;
    }
    function focusAfterCompletion(taskId) {
        if (!completionFocus || completionFocus.id !== taskId) return;
        var visibleIds = Bulk.visibleIds(rows);
        keyboardTaskId = completionFocus.candidates.find(function(id) { return visibleIds.indexOf(id) >= 0; }) || "";
        keyboardAddKey = "";
        completionFocus = null;
        list.forceActiveFocus();
        var index = rows.findIndex(function(row) { return row.kind === "task" && String(row.task.id) === root.keyboardTaskId; });
        if (index >= 0) list.positionViewAtIndex(index, ListView.Contain);
    }
    function showTask(task) { clearSelection(); selectedTask = task; details.open(); }
    function startDrag(index, point) {
        if (service.saving || composerKey || setupVisible || selectedIds.length) return;
        dragRows = rows;
        dragIndex = index;
        // ListView keeps its current delegate alive outside the cache while the
        // user scrolls. The pressed MouseArea must survive a long drag.
        list.currentIndex = index;
        forceActiveFocus();
        moveDrag(point);
    }
    function moveDrag(point) {
        if (!dragging) return;
        dragX = point.x; dragY = point.y;
        locateDrop();
    }
    function locateDrop() {
        dropIndex = -1;
        var point = list.mapFromItem(root, dragX, dragY);
        if (point.x < 0 || point.x > list.width || point.y < 0 || point.y > list.height) return;
        var y = point.y + list.contentY;
        var index = list.indexAt(Math.min(Style.space(40), list.width / 2), y);
        if (index < 0) return;
        var row = list.itemAtIndex(index);
        if (!row) return;
        var after = y > row.y + row.height / 2;
        // A group's Add task row also accepts a drop after its last task.
        if (rows[index].kind === "add" && index > 0) { index--; row = list.itemAtIndex(index); after = true; }
        if (!row || !Order.changedOrder(rows, dragIndex, index, after, view)) return;
        dropIndex = index; dropAfter = after;
        dropY = list.y + row.y - list.contentY + (after ? row.height : 0);
    }
    function cancelDrag() { dragIndex = -1; dropIndex = -1; dragRows = null; }
    function finishDrag() {
        if (!dragging) return;
        var source = rows[dragIndex], target = dropIndex >= 0 ? rows[dropIndex] : null, after = dropAfter;
        if (target) service.reorderTasks(view, String(source.task.id), String(target.task.id), after, source.groupKey);
        cancelDrag();
    }
    Keys.onEscapePressed: { if (dragging) cancelDrag(); else if (taskMenu.visible) { if (!taskMenu.busy) taskMenu.close(); } else if (display.opened) display.close(); else if (details.opened && detailLoader.item) detailLoader.item.dismissEditor(); else if (composerKey) { composerKey = ""; forceActiveFocus(); } else if (selectedIds.length) clearSelection(); else if (settingsOpen) settingsOpen = false; else if (keyboardTaskId || keyboardAddKey) { keyboardTaskId = ""; keyboardAddKey = ""; } else closeRequested(); }
    function keyboardTask() {
        return service.tasks.find(function(t) { return String(t.id) === keyboardTaskId; }) || null;
    }
    function moveKeyboard(step) {
        list.forceActiveFocus();
        var entries = rows.filter(function(r) { return r.kind === "task" || r.kind === "add"; });
        if (!entries.length) return;
        var index = entries.findIndex(function(r) {
            return r.kind === "task" ? String(r.task.id) === root.keyboardTaskId : r.key === root.keyboardAddKey;
        });
        index = index < 0 ? (step > 0 ? 0 : entries.length - 1) : Math.max(0, Math.min(entries.length - 1, index + step));
        var entry = entries[index];
        keyboardTaskId = entry.kind === "task" ? String(entry.task.id) : "";
        keyboardAddKey = entry.kind === "add" ? entry.key : "";
        list.positionViewAtIndex(rows.indexOf(entry), ListView.Contain);
    }
    function editKeyboardTask(task) {
        showTask(task);
        Qt.callLater(function() { if (detailLoader.item) detailLoader.item.startEditing(); });
    }
    function openInTodoist(task) { service.openTodoist(task); }
    function handleShortcut(event) {
        if (dragging || composerKey || details.visible || display.visible || taskMenu.visible || helpOpen) return;
        // Text controls own their keystrokes, including settings fields.
        var focused = Window.activeFocusItem;
        if (focused && focused.cursorPosition !== undefined) return;
        var ctrl = !!(event.modifiers & Qt.ControlModifier), key = event.key;
        var task = keyboardTask(), tabs = ["today", "upcoming", "inbox"];
        if (key === Qt.Key_P) { settingsOpen = !settingsOpen; event.accepted = true; return; }
        if (setupVisible) {
            if (key === Qt.Key_T) { service.openTodoist(); event.accepted = true; }
            return;
        }
        if (key === Qt.Key_Tab || key === Qt.Key_Backtab || key === Qt.Key_Left || key === Qt.Key_Right) {
            view = tabs[(tabs.indexOf(view) + ((event.modifiers & Qt.ShiftModifier) || key === Qt.Key_Backtab || key === Qt.Key_Left ? 2 : 1)) % 3];
        } else if (ctrl && [Qt.Key_A, Qt.Key_D, Qt.Key_I].indexOf(key) >= 0 && task) {
            service.applyTaskAction([String(task.id)], "date", key === Qt.Key_A ? "today" : key === Qt.Key_D ? "tomorrow" : "");
        } else if (ctrl && key === Qt.Key_A) {
            selectedIds = Bulk.visibleIds(rows);
        } else if (!ctrl && [Qt.Key_A, Qt.Key_D, Qt.Key_I].indexOf(key) >= 0) {
            view = key === Qt.Key_A ? "today" : key === Qt.Key_D ? "upcoming" : "inbox";
        } else if (!ctrl && [Qt.Key_J, Qt.Key_Down, Qt.Key_K, Qt.Key_Up].indexOf(key) >= 0) {
            moveKeyboard(key === Qt.Key_J || key === Qt.Key_Down ? 1 : -1);
        } else if (!ctrl && keyboardAddKey && [Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space].indexOf(key) >= 0) {
            var selectedAdd = rows.find(function(r) { return r.kind === "add" && r.key === keyboardAddKey; });
            if (selectedAdd) addAt(selectedAdd.key, selectedAdd.projectId);
        } else if (!ctrl && task && [Qt.Key_Return, Qt.Key_Enter].indexOf(key) >= 0) {
            showTask(task);
        } else if (!ctrl && task && key === Qt.Key_E) {
            editKeyboardTask(task);
        } else if (!ctrl && task && key === Qt.Key_Space) {
            if (!event.isAutoRepeat) completeTask(task);
        } else if (!ctrl && key === Qt.Key_U) {
            if (!event.isAutoRepeat) service.undoCompletion();
        } else if (!ctrl && task && key === Qt.Key_O) {
            openInTodoist(task);
        } else if (!ctrl && task && key === Qt.Key_X) {
            openTaskMenu(task, Qt.point(0, header.height)); taskMenu.run("delete", null);
        } else if (!ctrl && key === Qt.Key_Q) {
            var add = rows.filter(function(r) { return r.kind === "add"; }).pop();
            if (add) addAt(add.key, add.projectId);
        } else if (!ctrl && key === Qt.Key_R) {
            service.refresh(true);
        } else if (event.text === "?") {
            helpOpen = true;
        } else return;
        event.accepted = true;
    }
    Keys.onPressed: function(event) { handleShortcut(event); }
    onViewChanged: { completionFocus = null; keyboardTaskId = ""; keyboardAddKey = ""; cancelDrag(); clearSelection(); composerKey = ""; list.positionViewAtBeginning(); }
    onSetupVisibleChanged: if (setupVisible) { cancelDrag(); clearSelection(); }
    onVisibleChanged: if (!visible) { completionFocus = null; cancelDrag(); clearSelection(); }
    onComposerKeyChanged: if (!composerKey) heldRows = null

    RowLayout {
        id: header
        anchors.top: parent.top; width: parent.width
        height: Style.space(28); spacing: Style.space(4)
        Repeater {
            model: [{id: "today", title: "Aujourd’hui"}, {id: "upcoming", title: "Prochainement"}, {id: "inbox", title: "Inbox"}]
            Action { fontFamily: root.fontFamily;
                required property var modelData
                objectName: "viewTab_" + modelData.id
                highlightOnHover: false
                Layout.fillWidth: true
                Layout.preferredWidth: implicitWidth
                Layout.minimumWidth: 0
                text: modelData.title
                tip: modelData.id === "inbox" ? "Tâches sans date dans tous les projets" : modelData.title
                iconName: modelData.id
                iconDay: root.service.now.getDate()
                bold: true
                selected: root.view === modelData.id && !root.settingsOpen
                onClicked: { root.view = modelData.id; root.settingsOpen = false; }
            }
        }
        Action { fontFamily: root.fontFamily; id: displayButton; objectName: "displayButton"; iconName: "display"; iconSize: Style.space(17); tip: "Affichage"; selected: display.opened; enabled: root.service.configured; onClicked: display.opened ? display.close() : display.open() }
        Action { fontFamily: root.fontFamily; iconName: "settings"; iconSize: Style.space(17); tip: "Réglages"; selected: root.settingsOpen; onClicked: root.settingsOpen = !root.settingsOpen }
    }
    ColumnLayout {
        id: status
        anchors.top: header.bottom; anchors.topMargin: visible ? Style.space(10) : 0
        width: parent.width
        height: visible ? implicitHeight + Style.space(8) : 0
        visible: statusText.text !== ""
        spacing: Style.space(4)
        Label { font.family: root.fontFamily;
            id: statusText
            Layout.fillWidth: true
            text: root.service.error || (!root.service.loaded && root.service.configured ? "Chargement des tâches…" : "")
            color: root.service.error ? Color.urgent : Color.popups.text
            wrapMode: Text.WordWrap; elide: Text.ElideNone
            font.pixelSize: Style.font.bodySmall
        }
        Action { fontFamily: root.fontFamily;
            objectName: "retrySync"
            visible: root.service.configured && root.service.error !== ""
            text: root.service.loading ? "Nouvel essai…" : "Réessayer"
            enabled: !root.service.loading && !root.service.saving && !root.service.connecting
            onClicked: root.service.refresh(true)
        }
    }
    RowLayout {
        id: selectionBar
        anchors.top: status.bottom
        width: parent.width
        height: visible ? Style.space(34) : 0
        visible: root.selectedIds.length > 0 && !root.setupVisible
        Label { font.family: root.fontFamily; Layout.fillWidth: true; text: root.selectedIds.length + " sélectionnée(s)"; color: Color.accent; font.pixelSize: Style.font.bodySmall }
        Action { fontFamily: root.fontFamily;
            text: "Actions…"; objectName: "selectionActions"; enabled: !root.service.saving
            onClicked: {
                var task = root.service.tasks.find(function(t) { return String(t.id) === root.selectedIds[0]; });
                if (task) root.openTaskMenu(task, mapToItem(root, 0, height));
            }
        }
        Action { fontFamily: root.fontFamily; text: "Effacer"; enabled: !root.service.saving; onClicked: root.clearSelection() }
    }
    C.ScrollView {
        visible: root.setupVisible
        anchors.top: status.bottom; anchors.topMargin: Style.space(18)
        anchors.bottom: parent.bottom
        width: parent.width; clip: true
        contentWidth: availableWidth
        Settings { id: setup; width: parent.width; service: root.service }
    }
    ListView {
        id: list
        objectName: "taskListView"
        visible: !root.setupVisible
        anchors.top: selectionBar.bottom; anchors.topMargin: Style.space(8)
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !root.dragging
        model: []
        spacing: 0
        keyNavigationEnabled: false
        Keys.onPressed: function(event) { root.handleShortcut(event); }
        cacheBuffer: Style.space(1000)
        C.ScrollBar.vertical: C.ScrollBar { policy: list.contentHeight > list.height ? C.ScrollBar.AsNeeded : C.ScrollBar.AlwaysOff }
        header: Label { font.family: root.fontFamily;
            width: list.width
            height: visible ? Style.space(60) : 0
            visible: root.service.loaded && !root.rows.some(function(row) { return row.kind === "task"; })
            text: "Aucune tâche dans cette vue."
            verticalAlignment: Text.AlignVCenter
            opacity: 0.5
        }
        delegate: Loader {
            id: rowLoader
            required property var modelData
            required property int index
            width: list.width - Style.space(4)
            height: item ? item.implicitHeight : 0
            sourceComponent: modelData.kind === "group" ? groupComponent : modelData.kind === "task" ? taskComponent : addComponent
            Component {
                id: groupComponent
                Item {
                    implicitHeight: Style.space(40)
                    Label { font.family: root.fontFamily; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: Style.space(9); text: rowLoader.modelData.title; font.bold: true; color: text === "En retard" ? "#ef615b" : Color.popups.text }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Color.popups.text; opacity: 0.12 }
                }
            }
            Component {
                id: taskComponent
                TaskRow {
                    function completeTask() { root.completeTask(task); }
                    task: rowLoader.modelData.task; service: root.service; view: root.view; grouping: root.options.grouping
                    reorderEnabled: !root.service.saving && !root.composerKey && !root.selectedIds.length
                    selected: root.keyboardTaskId === String(task.id)
                    bulkSelected: root.selectedIds.indexOf(String(task.id)) >= 0
                    dragging: root.dragIndex === rowLoader.index
                    listDragging: root.dragging
                    opacity: dragging ? 0.3 : 1
                    onActivated: function(task) { root.showTask(task); }
                    onHighlighted: function(task) {
                        root.clearSelection();
                        root.keyboardTaskId = String(task.id);
                        root.keyboardAddKey = "";
                        root.forceActiveFocus();
                    }
                    onHoverHighlighted: function(task) {
                        if (root.dragging || root.service.saving || root.composerKey || root.setupVisible || details.visible || display.visible || taskMenu.visible || root.helpOpen) return;
                        var focused = Window.activeFocusItem;
                        if (focused && focused.cursorPosition !== undefined) return;
                        root.keyboardTaskId = String(task.id);
                        root.keyboardAddKey = "";
                    }
                    onSelectionToggled: function(task) { root.toggleSelection(task); }
                    onContextRequested: function(task, x, y) { root.openTaskMenu(task, mapToItem(root, x, y)); }
                    onDragStarted: function(x, y) { root.startDrag(rowLoader.index, mapToItem(root, x, y)); }
                    onDragMoved: function(x, y) { root.moveDrag(mapToItem(root, x, y)); }
                    onDragEnded: root.finishDrag()
                    onDragCancelled: root.cancelDrag()
                }
            }
            Component {
                id: addComponent
                Item {
                    implicitHeight: root.composerKey === rowLoader.modelData.key ? composerLoader.implicitHeight + Style.space(20) : Style.space(40)
                    Action { fontFamily: root.fontFamily;
                        visible: root.composerKey !== rowLoader.modelData.key
                        y: Style.space(5)
                        text: "+   Ajouter une tâche"
                        objectName: "addTask_" + rowLoader.modelData.key
                        Keys.onPressed: function(event) {
                            if (!(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) && [Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space].indexOf(event.key) >= 0) {
                                event.accepted = true;
                                if (!event.isAutoRepeat) root.addAt(rowLoader.modelData.key, rowLoader.modelData.projectId);
                            }
                        }
                        selected: root.keyboardAddKey === rowLoader.modelData.key
                        foreground: Color.popups.text
                        onClicked: root.addAt(rowLoader.modelData.key, rowLoader.modelData.projectId)
                    }
                    Loader {
                        id: composerLoader
                        y: Style.space(10)
                        active: root.composerKey === rowLoader.modelData.key
                        width: parent.width
                        sourceComponent: Composer {
                            service: root.service
                            initialProjectId: root.composerProject
                            initialDue: root.view === "today" ? "aujourd’hui" : root.view === "upcoming" ? "demain" : ""
                            onFinished: { root.composerKey = ""; list.forceActiveFocus(); }
                            onCancelled: { root.composerKey = ""; list.forceActiveFocus(); }
                            Component.onCompleted: Qt.callLater(focusInput)
                        }
                    }
                }
            }
        }
    }
    Timer {
        interval: 16; repeat: true; running: root.dragging
        onTriggered: {
            var y = root.dragY - list.y, edge = Style.space(36), speed = 0;
            if (root.dragX < 0 || root.dragX > list.width) return;
            if (y >= -edge && y < edge) speed = -Math.min(12, (edge - y) / 3);
            else if (y > list.height - edge && y <= list.height + edge) speed = Math.min(12, (y - list.height + edge) / 3);
            if (!speed) return;
            list.contentY = Math.max(list.originY, Math.min(list.originY + Math.max(0, list.contentHeight - list.height), list.contentY + speed));
            root.locateDrop();
        }
    }
    Rectangle {
        objectName: "taskDropMarker"
        visible: root.dragging && root.dropIndex >= 0
        x: Style.space(31); y: root.dropY - 1
        width: root.width - x; height: Style.space(2)
        color: Color.accent; z: 2
    }
    Rectangle {
        visible: root.dragging
        x: Style.space(24); y: Math.max(list.y, Math.min(root.height - height, root.dragY + Style.space(18)))
        width: root.width - x; height: dragLabel.implicitHeight + Style.space(16)
        color: Color.popups.background; border.color: Color.popups.border
        radius: Style.cornerRadius; opacity: 0.95; z: 3
        Label { font.family: root.fontFamily;
            id: dragLabel
            anchors.centerIn: parent; width: parent.width - Style.space(20)
            text: root.dragging ? Model.plain(root.rows[root.dragIndex].task.content) : ""
            maximumLineCount: 1
        }
    }
    C.Popup {
        id: shortcutHelp
        objectName: "shortcutHelp"
        visible: root.helpOpen
        onClosed: { root.helpOpen = false; root.forceActiveFocus(); }
        width: root.width
        height: Math.min(root.height, helpBody.implicitHeight + padding * 2)
        padding: Style.space(16)
        focus: true
        closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutside
        background: Rectangle { color: Color.popups.background; border.color: Color.popups.border; radius: Style.cornerRadius }
        contentItem: C.ScrollView {
            contentWidth: availableWidth
            ColumnLayout {
                id: helpBody
                width: parent.width
                spacing: Style.space(10)
                Label { font.family: root.fontFamily; text: "Raccourcis clavier"; font.bold: true }
                Label { font.family: root.fontFamily;
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap; elide: Text.ElideNone
                    text: "Tab / Maj+Tab : changer de vue\na / d / i : Aujourd’hui / Prochainement / Inbox\n↑ / ↓ ou k / j : sélectionner une tâche ou l’ajout\nEntrée : détails\ne : modifier\nEspace : terminer\nu : annuler la dernière tâche terminée\no : ouvrir dans Todoist\nx : supprimer\nCtrl+a / Ctrl+d / Ctrl+i : aujourd’hui / demain / sans date\nCtrl+a sans curseur : tout sélectionner\nq : ajouter une tâche\nr : actualiser\np : réglages\n? : cette aide\nÉchap : revenir / fermer"
                }
                Action { fontFamily: root.fontFamily; text: "Fermer"; onClicked: shortcutHelp.close() }
            }
        }
    }
    TaskMenu {
        id: taskMenu
        service: root.service
        onCompleted: root.clearSelection()
        onEditRequested: function(task) { root.showTask(task); Qt.callLater(function() { if (detailLoader.item) detailLoader.item.startEditing(); }); }
    }
    C.Popup {
        id: display
        objectName: "displayPopup"
        parent: displayButton
        x: displayButton.width - width; y: displayButton.height + Style.space(8)
        width: Math.min(root.width, Style.space(340))
        height: Math.min(root.height - y, displayOptions.implicitHeight + padding * 2)
        padding: Style.space(16)
        focus: true
        closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutsideParent
        background: Rectangle { color: Color.popups.background; border.width: 1; border.color: Color.popups.border; radius: Style.cornerRadius }
        contentItem: C.ScrollView {
            clip: true; contentWidth: availableWidth
            DisplayOptions { id: displayOptions; width: parent.width; service: root.service; view: root.view }
        }
    }
    C.Popup {
        id: details
        objectName: "taskDetailsPopup"
        onClosed: list.forceActiveFocus()
        x: 0; y: header.height + Style.space(8)
        width: root.width
        height: Math.min(root.height - y, (detailLoader.item ? detailLoader.item.implicitHeight : 0) + padding * 2)
        padding: Style.space(16); focus: true
        closePolicy: detailLoader.item && (detailLoader.item.editing || detailLoader.item.busy) ? C.Popup.NoAutoClose : C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutside
        background: Rectangle { color: Color.popups.background; border.width: 1; border.color: Color.popups.border; radius: Style.cornerRadius }
        contentItem: Loader {
            id: detailLoader
            active: details.visible && root.selectedTask !== null
            sourceComponent: TaskDetails {
                service: root.service
                task: root.selectedTask
                onCloseRequested: details.close()
                onTaskRequested: function(task) { root.showTask(task); }
            }
        }
    }
    Connections {
        target: root.service
        function onTaskCompleted(taskId) { root.focusAfterCompletion(taskId); }
        function onOperationFailed(message) { root.completionFocus = null; }
        function onTasksChanged() {
            if (!root.selectedTask) return;
            var current = root.service.tasks.find(function(t) { return String(t.id) === String(root.selectedTask.id); });
            if (current) root.selectedTask = current;
            else if (details.visible && !(detailLoader.item && detailLoader.item.busy)) details.close();
        }
    }
    Connections { target: root.service; function onConnected() { if (root.service.configured) root.settingsOpen = false; } }
}
