// Synthetic tasks and intercepted requests: this test never contacts Todoist.
import QtQuick
import QtTest
import Quickshell
import qs.Commons
import "plugin" as Plugin
import "plugin/ui" as Tasks

ShellRoot {
    Plugin.Service {
        id: service
        enableShortcuts: false
        stateDir: Quickshell.env("TODOIST_TEST_DIR") + "/state"
        property var captured: []
        property var completions: []
        property bool failNext: false
        function applyToken(value) {}
        property bool manualRefresh: false
        function refresh(manual) { manualRefresh = manual === true; }
        function completeTask(task) { completions = completions.concat([String(task.id)]); }
        function request(method, path, body, credential, callback, requestId) {
            if (path !== "/sync" || !body.commands) throw new Error("Unexpected request");
            captured = captured.concat(body.commands);
            if (failNext) { failNext = false; callback(null, "Connection lost"); return; }
            var statuses = {};
            body.commands.forEach(function(c) { statuses[c.uuid] = "ok"; });
            callback({sync_token: "fixture", sync_status: statuses}, "");
        }
    }
    Plugin.Service {
        id: completionService
        enableShortcuts: false
        stateDir: Quickshell.env("TODOIST_TEST_DIR") + "/completion-state"
        property var captured: []
        function applyToken(value) {}
        function refresh(manual) {}
        function request(method, path, body, credential, callback, requestId) {
            if (path.indexOf("/close") >= 0) { Qt.callLater(function() { callback({}, ""); }); return; }
            captured = captured.concat(body.commands);
            var command = body.commands[0], statuses = {};
            statuses[command.uuid] = "ok";
            Qt.callLater(function() { callback({sync_token: "undo", sync_status: statuses, items: [{id: "completed", content: "Synthetic task", priority: 1, project_id: "inbox", due: {date: "2026-09-15"}}]}, ""); });
        }
    }
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 456; implicitHeight: 540
        color: Color.popups.background
        Tasks.TaskList { id: taskList; property string openedTask: ""; function openInTodoist(task) { openedTask = String(task.id); } anchors.fill: parent; anchors.margins: 18; service: service }
    }
    TestCase {
        id: checks
        name: "TodoistDrag"
        when: window.visible
        function cleanupTestCase() { console.log("DRAG UI RESULTS", qtest_results.passCount, "passed", qtest_results.failCount, "failed"); Qt.callLater(Qt.quit); }
        function cleanup() { console.log("TEST", qtest_results.functionName, qtest_results.failed ? "FAILED" : "PASSED"); }
        function init() {
            taskList.service = service;
            mouseMove(taskList, 1, 1);
            service.token = "fixture"; service.loaded = true; service.error = ""; service.bulkRetry = null;
            service.now = new Date(2026, 8, 15, 12);
            service.user = {id: "me"}; service.preferences = {};
            service.projects = [{id: "inbox", name: "Inbox", inbox_project: true}];
            service.tasks = Array.from({length: 24}, function(_, i) { return {id: String(i), content: "Task " + (i + 1) + " with a useful description", description: "Description of the task to check dragging and layout.", priority: 1, project_id: "inbox", day_order: i, due: {date: "2026-09-15"}}; });
            service.captured = []; service.completions = []; service.failNext = false; taskList.reset(); taskList.anchors.bottomMargin = 18;
            var list = findChild(taskList, "taskListView"); list.positionViewAtBeginning();
            tryCompare(findChild(taskList, "taskDetailsPopup"), "visible", false);
            list.forceActiveFocus();
            wait(150);
        }
        function test_only_selected_tab_has_a_filled_background() {
            var today = findChild(taskList, "viewTab_today");
            var inbox = findChild(taskList, "viewTab_inbox");
            mouseClick(inbox);
            taskList.view = "today";
            mouseMove(inbox, inbox.width / 2, inbox.height / 2);
            compare(inbox.hovered, true);
            compare(today.selected, true);
            compare(inbox.selected, false);
            compare(inbox.background.color.a, 0);
            verify(today.background.color.a > 0);
            compare(inbox.background.border.width, 0);
            taskList.forceActiveFocus();
            mouseMove(taskList, taskList.width - 1, taskList.height - 1);
        }
        function test_hover_selects_for_shortcuts_and_preserves_bulk_selection() {
            var first = findChild(taskList, "taskPointer_0");
            var second = findChild(taskList, "taskPointer_1");
            mouseMove(taskList, 1, 1);
            taskList.keyboardAddKey = "add";
            mouseMove(first, 65, 12);
            compare(taskList.keyboardTaskId, "0");
            compare(taskList.keyboardAddKey, "");
            compare(taskList.selectedIds.length, 0);
            var simple = findChild(taskList, "taskHighlight_0");
            compare(simple.color, Style.hoverFillFor(Color.popups.text, Color.accent));
            compare(simple.opacity, 0.5);
            mouseClick(first, 65, 12, Qt.LeftButton, Qt.ControlModifier);
            compare(taskList.selectedIds.join(","), "0");
            compare(simple.color, Style.selectedFillFor(Color.popups.text, Color.accent));
            compare(simple.opacity, 1);
            mouseMove(second, 65, 12);
            compare(taskList.keyboardTaskId, "1");
            compare(taskList.selectedIds.join(","), "0");
            verify(simple.visible);
            var next = findChild(taskList, "taskHighlight_1");
            compare(next.color, Style.hoverFillFor(Color.popups.text, Color.accent));
            verify(simple.color.toString() !== next.color.toString());
            keyClick(Qt.Key_Down); compare(taskList.keyboardTaskId, "2");
            mouseMove(second, 75, 12); compare(taskList.keyboardTaskId, "1");
            keyClick(Qt.Key_Space); compare(service.completions.join(","), "1");
            taskList.composerKey = "add";
            mouseMove(first, 75, 12); compare(taskList.keyboardTaskId, "1");
            mouseMove(taskList, 1, 1);
            taskList.composerKey = "";
        }
        function test_imported_navigation_and_actions() {
            taskList.forceActiveFocus(); keyClick(Qt.Key_J);
            compare(taskList.keyboardTaskId, "0");
            keyClick(Qt.Key_Down); compare(taskList.keyboardTaskId, "1");
            keyClick(Qt.Key_K); compare(taskList.keyboardTaskId, "0");
            keyClick(Qt.Key_O); compare(taskList.openedTask, "0");
            keyClick(Qt.Key_Space); compare(service.completions[0], "0");
            keyClick(Qt.Key_X);
            var menu = findChild(taskList,"taskContextMenu");
            compare(service.captured.length,1); compare(service.captured[0].type,"item_delete");
            tryCompare(menu,"opened",false); taskList.clearSelection();
            taskList.forceActiveFocus(); keyClick(Qt.Key_R); compare(service.manualRefresh,true);

            keyClick(Qt.Key_D); compare(taskList.view,"upcoming");
            keyClick(Qt.Key_I); compare(taskList.view,"inbox");
            keyClick(Qt.Key_A); compare(taskList.view,"today");
            keyClick(Qt.Key_Tab); compare(taskList.view,"upcoming");
            keyClick(Qt.Key_Tab); compare(taskList.view,"inbox");
            keyClick(Qt.Key_Backtab); compare(taskList.view,"upcoming");
            keyClick(Qt.Key_Backtab); compare(taskList.view,"today");
            keyClick(Qt.Key_P); compare(taskList.settingsOpen,true);
            keyClick(Qt.Key_Escape); compare(taskList.settingsOpen,false);
        }
        function test_imported_date_shortcuts() {
            taskList.forceActiveFocus(); keyClick(Qt.Key_J);
            keyClick(Qt.Key_D,Qt.ControlModifier);
            compare(service.captured[0].args.due.date,"2026-09-16");
            keyClick(Qt.Key_I,Qt.ControlModifier);
            compare(service.captured[1].args.due,null);
            keyClick(Qt.Key_A,Qt.ControlModifier);
            compare(service.captured[2].args.due.date,"2026-09-15");
        }
        function test_real_completion_then_keyboard_undo() {
            completionService.token = "fixture"; completionService.now = service.now;
            completionService.projects = service.projects; completionService.user = service.user;
            completionService.tasks = [{id: "completed", content: "Synthetic task", priority: 1, project_id: "inbox", due: {date: "2026-09-15"}}];
            completionService.captured = []; completionService.lastCompletion = null;
            taskList.service = completionService;
            taskList.forceActiveFocus(); keyClick(Qt.Key_J); keyClick(Qt.Key_Space);
            tryCompare(completionService, "saving", false);
            compare(completionService.tasks.length, 0);
            keyClick(Qt.Key_U);
            tryCompare(completionService, "lastCompletion", null);
            compare(completionService.captured.length, 1);
            taskList.service = service;
        }
        function test_undo_while_completion_is_in_flight() {
            completionService.token = "fixture"; completionService.now = service.now;
            completionService.projects = service.projects; completionService.user = service.user;
            completionService.tasks = [{id: "completed", content: "Synthetic task", priority: 1, project_id: "inbox", due: {date: "2026-09-15"}}];
            completionService.captured = []; completionService.lastCompletion = null;
            taskList.service = completionService;
            taskList.forceActiveFocus(); keyClick(Qt.Key_J); keyClick(Qt.Key_Space);
            keyClick(Qt.Key_U);
            tryCompare(completionService, "lastCompletion", null);
            compare(completionService.captured.length, 1);
            taskList.service = service;
        }
        function test_details_completion_then_keyboard_undo() {
            completionService.token = "fixture"; completionService.now = service.now;
            completionService.projects = service.projects; completionService.user = service.user;
            completionService.tasks = [{id: "completed", content: "Synthetic task", priority: 1, project_id: "inbox", due: {date: "2026-09-15"}}];
            completionService.captured = []; completionService.lastCompletion = null;
            taskList.service = completionService;
            taskList.forceActiveFocus(); keyClick(Qt.Key_J); keyClick(Qt.Key_Return);
            tryVerify(function() { return findChild(taskList, "taskDetailScroll") !== null; });
            findChild(taskList, "taskDetailScroll").parent.complete();
            tryCompare(completionService, "saving", false);
            compare(completionService.tasks.length, 0);
            tryCompare(findChild(taskList, "taskDetailsPopup"), "visible", false);
            keyClick(Qt.Key_U);
            tryCompare(completionService, "lastCompletion", null);
            compare(completionService.captured.length, 1);
            taskList.service = service;
        }
        function test_keyboard_navigation_moves_focus_from_buttons_before_space() {
            findChild(taskList, "viewTab_today").forceActiveFocus();
            keyClick(Qt.Key_Down);
            compare(taskList.keyboardTaskId, "0");
            keyClick(Qt.Key_Space);
            compare(service.completions.join(","), "0");
        }
        function test_enter_opens_details_and_u_undoes_without_selection() {
            taskList.forceActiveFocus(); keyClick(Qt.Key_J); keyClick(Qt.Key_Return);
            tryCompare(findChild(taskList, "taskDetailsPopup"), "visible", true);
            verify(findChild(taskList, "taskName") === null);
            findChild(taskList, "taskDetailsPopup").close();
            taskList.keyboardTaskId = "";
            service.lastCompletion = {task: {id: "0"}, uuid: "undo-test"};
            taskList.forceActiveFocus(); keyClick(Qt.Key_U);
            compare(service.captured[0].type, "item_uncomplete");
            compare(service.lastCompletion, null);
        }
        function test_editor_shortcut_and_typing() {
            taskList.forceActiveFocus(); keyClick(Qt.Key_J); keyClick(Qt.Key_E);
            tryVerify(function() { return findChild(taskList,"taskName") !== null });
            var input=findChild(taskList,"taskName");
            tryCompare(input,"activeFocus",true);
            keyClick(Qt.Key_A); keyClick(Qt.Key_D); keyClick(Qt.Key_I);
            compare(taskList.view,"today");
            compare(service.captured.length,0);
            input.text="Réviser demain à 17h p1"; keyClick(Qt.Key_Return);
            compare(service.captured.length,1);
            compare(service.captured[0].args.content,"Réviser");
            compare(service.captured[0].args.due.lang,"fr");
            compare(service.captured[0].args.priority,4);
            findChild(taskList,"taskDetailsPopup").close();
        }
        function test_description_tab_moves_focus_without_changing_text() {
            taskList.forceActiveFocus(); keyClick(Qt.Key_J); keyClick(Qt.Key_E);
            tryVerify(function() { return findChild(taskList, "taskDescription") !== null; });
            var description = findChild(taskList, "taskDescription");
            description.forceActiveFocus();
            var original = description.text;
            var next = description.nextItemInFocusChain(true);
            verify(next !== description);
            keyClick(Qt.Key_Tab);
            tryCompare(next, "activeFocus", true);
            compare(description.text, original);
            description.forceActiveFocus();
            var previous = description.nextItemInFocusChain(false);
            verify(previous !== description);
            keyClick(Qt.Key_Backtab);
            tryCompare(previous, "activeFocus", true);
            compare(description.text, original);
            compare(service.captured.length, 0);
            findChild(taskList, "taskDetailsPopup").close();
        }
        function test_arrow_navigation_reaches_add_task() {
            taskList.forceActiveFocus();
            taskList.keyboardTaskId = "23";
            keyClick(Qt.Key_Down);
            compare(taskList.keyboardTaskId, "");
            compare(taskList.keyboardAddKey, "add");
            tryVerify(function() { return findChild(taskList, "addTask_add") !== null; });
            compare(findChild(taskList, "addTask_add").selected, true);
            keyClick(Qt.Key_Up); compare(taskList.keyboardTaskId, "23");
            compare(taskList.keyboardAddKey, "");
            keyClick(Qt.Key_Down); keyClick(Qt.Key_Return);
            compare(taskList.composerKey, "add");
            tryVerify(function() { var input = findChild(taskList, "taskName"); return input && input.activeFocus; });
            keyClick(Qt.Key_Escape);
            service.tasks = []; taskList.forceActiveFocus();
            keyClick(Qt.Key_Down); compare(taskList.keyboardAddKey, "add");
            keyClick(Qt.Key_Return); compare(taskList.composerKey, "add");
            keyClick(Qt.Key_Escape);
            taskList.view = "inbox"; compare(taskList.keyboardAddKey, "");
        }
        function test_focused_add_button_opens_composer_data() {
            return [{tag: "Return", key: Qt.Key_Return}, {tag: "Enter", key: Qt.Key_Enter}, {tag: "Space", key: Qt.Key_Space}];
        }
        function test_focused_add_button_opens_composer(data) {
            taskList.keyboardTaskId = "23";
            findChild(taskList, "taskListView").positionViewAtEnd();
            var add = findChild(taskList, "addTask_add");
            tryVerify(function() { return add !== null; });
            add.forceActiveFocus();
            keyClick(data.key);
            compare(taskList.composerKey, "add");
            tryVerify(function() { var input = findChild(taskList, "taskName"); return input && input.activeFocus; });
            compare(service.completions.length, 0);
            compare(findChild(taskList, "taskDetailsPopup").visible, false);
            keyClick(Qt.Key_Escape);
        }
        function test_keyboard_selected_add_opens_composer_data() {
            return [{tag: "Return", key: Qt.Key_Return}, {tag: "Enter", key: Qt.Key_Enter}, {tag: "Space", key: Qt.Key_Space}];
        }
        function test_keyboard_selected_add_opens_composer(data) {
            taskList.forceActiveFocus(); taskList.keyboardTaskId = "23";
            keyClick(Qt.Key_Down);
            compare(taskList.keyboardAddKey, "add");
            keyClick(data.key);
            compare(taskList.composerKey, "add");
            tryVerify(function() { var input = findChild(taskList, "taskName"); return input && input.activeFocus; });
            compare(service.completions.length, 0);
            keyClick(Qt.Key_Escape);
        }
        function test_add_shortcut_and_french_picker() {
            taskList.forceActiveFocus(); keyClick(Qt.Key_Q);
            tryVerify(function() { return findChild(taskList,"taskName") !== null });
            var input=findChild(taskList,"taskName"); tryCompare(input,"activeFocus",true);
            keyClick(Qt.Key_I); compare(taskList.view,"today");
            keyClick(Qt.Key_Escape); compare(taskList.composerKey,"");
        }
        function test_sync_retry_button() {
            service.error = "Could not reach Todoist. Retrying automatically.";
            service.manualRefresh = false;
            var button = findChild(taskList, "retrySync");
            tryCompare(button, "visible", true);
            wait(100);
            mouseClick(button);
            compare(service.manualRefresh, true, "Retry button requests an immediate sync");
            service.loading = true;
            compare(button.enabled, false); compare(button.text, "Nouvel essai…");
            service.loading = false; service.error = "";
            tryCompare(button, "visible", false);
        }
        function test_drag_saves_order() {
            var source = findChild(taskList, "taskPointer_2"), target = findChild(taskList, "taskPointer_0");
            verify(source !== null); verify(target !== null);
            mousePress(source, 65, 12); mouseMove(source, 65, 35, 50);
            console.log("STARTED", taskList.dragging); verify(taskList.dragging);
            var point = source.mapFromItem(target, 65, 6);
            mouseMove(source, point.x, point.y, 50); wait(80);
            console.log("DROP", taskList.dropIndex, taskList.dropAfter); compare(taskList.dropIndex, 0); compare(taskList.dropAfter, false);

            mouseRelease(source, point.x, point.y); wait(100);
            compare(taskList.dragging, false); compare(service.captured.length, 1);
            compare(service.captured[0].type, "item_update_day_orders");
            compare(service.preferences.today.sorting, "manual");
            compare(taskList.rows[0].task.id, "2");
            verify(!findChild(taskList, "taskDetailsPopup").opened);
        }
        function test_escape_cancels() {
            var source = findChild(taskList, "taskPointer_1");
            mousePress(source, 65, 12); mouseMove(source, 65, 40, 50);
            verify(taskList.dragging); keyClick(Qt.Key_Escape); verify(!taskList.dragging);
            mouseRelease(source, 65, 40); wait(80);
            compare(service.captured.length, 0);
            verify(!findChild(taskList, "taskDetailsPopup").opened);
        }
        function test_edge_scroll_and_outside_cancel() {
            var source = findChild(taskList, "taskPointer_1"), list = findChild(taskList, "taskListView");
            mousePress(source, 65, 12); mouseMove(source, 65, 40, 50);
            var point = source.mapFromItem(list, 65, list.height - 5);
            mouseMove(source, point.x, point.y, 50); tryVerify(function() { return list.contentY > 1100; }, 4000); verify(taskList.dragging);
            point = source.mapFromItem(list, -30, list.height / 2);
            mouseMove(source, point.x, point.y, 50); compare(taskList.dropIndex, -1);
            mouseRelease(source, point.x, point.y); wait(80);
            compare(service.captured.length, 0); verify(!taskList.dragging);
        }
        function test_long_drag_keeps_scroll_position() {
            var source = findChild(taskList, "taskPointer_1"), list = findChild(taskList, "taskListView");
            mousePress(source, 65, 12); mouseMove(source, 65, 40, 50);
            var point = source.mapFromItem(list, 65, list.height - 5);
            mouseMove(source, point.x, point.y, 50); tryVerify(function() { return list.contentY > 1100; }, 4000); verify(taskList.dragging);
            point = source.mapFromItem(list, 65, list.height / 2);
            mouseMove(source, point.x, point.y, 50);
            verify(taskList.dropIndex > 10);
            var offset = list.contentY;
            mouseRelease(source, point.x, point.y); wait(150);
            console.log("SCROLL AFTER DROP", offset, list.contentY);
            verify(Math.abs(list.contentY - offset) < 50);
            compare(service.captured.length, 1);
        }
        function test_click_highlights_and_opens_details_without_bulk_selection() {
            taskList.keyboardAddKey = "add";
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12);
            compare(taskList.keyboardTaskId, "0");
            compare(taskList.keyboardAddKey, "");
            compare(taskList.selectedIds.length, 0);
            verify(findChild(taskList, "taskDetailsPopup").opened);
            compare(String(taskList.selectedTask.id), "0");
            keyClick(Qt.Key_Escape);
            tryCompare(findChild(taskList, "taskDetailsPopup"), "visible", false);
            taskList.forceActiveFocus();
            keyClick(Qt.Key_Down); compare(taskList.keyboardTaskId, "1");
            keyClick(Qt.Key_Space); compare(service.completions.join(","), "1");
            compare(service.captured.length, 0);
        }
        function test_plain_click_replaces_bulk_selection_with_simple_selection() {
            var first = findChild(taskList, "taskPointer_0");
            var second = findChild(taskList, "taskPointer_1");
            mouseClick(first, 65, 12, Qt.LeftButton, Qt.ControlModifier);
            mouseClick(second, 65, 12, Qt.LeftButton, Qt.ControlModifier);
            compare(taskList.selectedIds.join(","), "0,1");
            mouseClick(first, 65, 12);
            compare(taskList.selectedIds.length, 0);
            compare(taskList.keyboardTaskId, "0");
            var highlight = findChild(taskList, "taskHighlight_0");
            compare(highlight.color, Style.hoverFillFor(Color.popups.text, Color.accent));
            compare(highlight.opacity, 0.5);
            verify(findChild(taskList, "taskDetailsPopup").opened);
            keyClick(Qt.Key_Escape);
            tryCompare(findChild(taskList, "taskDetailsPopup"), "visible", false);
            compare(service.completions.length, 0);
            mouseClick(second, 65, 12, Qt.LeftButton, Qt.ControlModifier);
            mouseClick(first, 65, 12);
            compare(taskList.selectedIds.length, 0);
            compare(taskList.keyboardTaskId, "0");
        }
        function test_click_opens_details_and_clears_selection() {
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12); wait(80);
            verify(findChild(taskList, "taskDetailsPopup").opened);
            compare(String(taskList.selectedTask.id), "0");
            compare(taskList.selectedIds.length, 0);
            compare(service.completions.length, 0);
            compare(service.captured.length, 0);
        }
        function test_ctrl_click_selects_and_toggles() {
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            mouseClick(findChild(taskList, "taskPointer_1"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            compare(taskList.selectedIds.join(","), "0,1");
            verify(!findChild(taskList, "taskDetailsPopup").opened);
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            compare(taskList.selectedIds.join(","), "1");
            compare(service.captured.length, 0);
            keyClick(Qt.Key_Escape); compare(taskList.selectedIds.length, 0);
        }
        function test_ctrl_click_circle_selects_without_completing() {
            mouseClick(findChild(taskList, "taskPointer_0"), 13, 18, Qt.LeftButton, Qt.ControlModifier);
            compare(taskList.selectedIds.join(","), "0");
            compare(service.completions.length, 0);
            verify(!findChild(taskList, "taskDetailsPopup").opened);
        }
        function test_plain_click_circle_still_completes() {
            mouseClick(findChild(taskList, "taskPointer_0"), 13, 18);
            compare(service.completions.join(","), "0");
            verify(!findChild(taskList, "taskDetailsPopup").opened);
        }
        function test_context_priority_applies_to_entire_selection() {
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            mouseClick(findChild(taskList, "taskPointer_1"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.RightButton);
            var menu = findChild(taskList, "taskContextMenu");
            tryCompare(menu, "opened", true); wait(50);
            compare(menu.taskIds.join(","), "0,1");
            verify(menu.x >= 0 && menu.y >= 0 && menu.x + menu.width <= taskList.width && menu.y + menu.height <= taskList.height);
            var priority = findChild(menu.contentItem, "bulkPriority_4");
            if (Quickshell.env("TODOIST_SELECTION_SCREENSHOT")) grabImage(window.contentItem).save(Quickshell.env("TODOIST_SELECTION_SCREENSHOT"));
            mouseClick(priority, priority.width / 2, priority.height / 2); wait(50);
            compare(service.captured.length, 2);
            compare(service.captured[0].args.priority, 4); compare(service.captured[1].args.priority, 4);
            compare(taskList.selectedIds.length, 0); verify(!menu.opened);
        }
        function test_right_click_unselected_task_replaces_selection() {
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            mouseClick(findChild(taskList, "taskPointer_1"), 65, 12, Qt.RightButton);
            var menu = findChild(taskList, "taskContextMenu"); tryCompare(menu, "opened", true);
            compare(taskList.selectedIds.join(","), "1"); compare(menu.taskIds.join(","), "1");
            keyClick(Qt.Key_Escape); tryCompare(menu, "opened", false);
            compare(service.captured.length, 0);
        }
        function test_selection_prevents_accidental_drag_and_clears_on_tab_change() {
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            var source = findChild(taskList, "taskPointer_0");
            mousePress(source, 65, 12, Qt.LeftButton, Qt.ControlModifier); mouseMove(source, 65, 40, 50);
            verify(!taskList.dragging);
            mouseRelease(source, 65, 40, Qt.LeftButton, Qt.ControlModifier);
            taskList.view = "inbox"; compare(taskList.selectedIds.length, 0);
        }
        function test_select_all_deduplicates_label_groups_and_prunes_hidden_tasks() {
            service.tasks = service.tasks.slice(0, 2).map(function(t) { return Object.assign({}, t, {labels: ["work", "next"]}); });
            service.setOption("today", "grouping", "label");
            taskList.forceActiveFocus(); keyClick(Qt.Key_A, Qt.ControlModifier);
            compare(taskList.selectedIds.length, 2);
            service.tasks = service.tasks.slice(1); wait(30);
            compare(taskList.selectedIds.join(","), "1");
        }
        function test_bulk_delete_without_confirmation() {
            taskList.selectedIds = ["0", "1"];
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.RightButton);
            var menu = findChild(taskList, "taskContextMenu"); tryCompare(menu, "opened", true);
            compare(service.captured.length, 0);
            // Activate the menu action directly; it can be below the fold.
            findChild(menu, "bulkDelete").clicked();
            compare(service.captured.length, 2);
            compare(service.captured[0].type, "item_delete");
            compare(service.captured[1].type, "item_delete");
            tryCompare(menu, "opened", false);
        }
        function test_bulk_custom_date_and_deadline_validation() {
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.RightButton);
            var menu = findChild(taskList, "taskContextMenu"); tryCompare(menu, "opened", true);
            menu.showPage("deadline"); wait(30);
            var input = findChild(menu, "bulkDateInput"); input.text = "2026-02-30";
            var apply = findChild(menu, "bulkApplyInput"); mouseClick(apply, apply.width / 2, apply.height / 2);
            verify(menu.message.indexOf("AAAA-MM-JJ") >= 0); compare(service.captured.length, 0);
            menu.showPage("customDate"); input.text = "every Monday at 10am"; wait(30);
            mouseClick(apply, apply.width / 2, apply.height / 2);
            compare(service.captured.length, 1); compare(service.captured[0].args.due.string, "every Monday at 10am");
        }
        function test_menu_fits_short_panel_and_resets_after_subpage() {
            taskList.anchors.bottomMargin = window.height - 262; wait(30);
            compare(taskList.height, 244);
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.RightButton);
            var menu = findChild(taskList, "taskContextMenu"); tryCompare(menu, "opened", true); wait(30);
            verify(menu.height <= taskList.height); verify(menu.y >= 0);
            menu.showPage("move"); wait(30); menu.close();
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.RightButton);
            tryCompare(menu, "opened", true); compare(menu.page, "main");
            menu.close(); taskList.anchors.bottomMargin = 18;
        }
        function test_bulk_failure_preserves_menu_and_retry() {
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            mouseClick(findChild(taskList, "taskPointer_1"), 65, 12, Qt.LeftButton, Qt.ControlModifier);
            mouseClick(findChild(taskList, "taskPointer_0"), 65, 12, Qt.RightButton);
            var menu = findChild(taskList, "taskContextMenu"); tryCompare(menu, "opened", true); wait(30);
            service.failNext = true;
            var priority = findChild(menu.contentItem, "bulkPriority_4"); mouseClick(priority, priority.width / 2, priority.height / 2);
            verify(menu.opened); verify(menu.canRetry); verify(!menu.pending); compare(taskList.selectedIds.length, 2);
            verify(menu.message.indexOf("Connection lost") >= 0);
            var firstId = service.captured[0].uuid;
            menu.pending = true; verify(service.retryTaskAction());
            compare(service.captured[2].uuid, firstId); verify(!menu.opened); compare(taskList.selectedIds.length, 0);
        }
    }
}
