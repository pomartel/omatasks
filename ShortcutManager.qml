import "i18n/Fr.js" as Fr
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "ShortcutModel.js" as Model
import "Model.js" as Tasks

Item {
    id: root
    required property var service
    readonly property string value: service.preferences.quickAddShortcut === undefined ? Model.DEFAULT : String(service.preferences.quickAddShortcut)
    readonly property string ownerId: Tasks.uuid()
    property string registered: ""
    property string candidate: ""
    property string message: ""
    property bool busy: false
    property bool persistPending: false
    property bool successful: true
    property bool destroying: false

    function apply(value, persist) {
        if (busy || !enabled) return;
        var parsed = Model.parse(value);
        successful = false;
        if (!parsed) { message = Fr.t("text.indiquez_les_modificateurs_et_une_touche_par_exemple_alt_space"); return; }
        candidate = parsed.text; persistPending = persist === true;
        message = ""; busy = true; readBindings.running = true;
    }
    function checkBindings(text, code) {
        if (code !== 0 || !text.trim()) { busy = false; message = Fr.t("text.impossible_de_lire_les_raccourcis_hyprland"); return; }
        var list = Model.bindings(text), conflict = Model.conflict(list, Model.parse(candidate));
        if (conflict) { busy = false; message = Fr.t("shortcut.conflict", candidate, conflict.description || Fr.t("text.une_autre_action")); return; }
        registerBinding.command = ["hyprctl", "eval", Model.registerCode(list, registered, candidate, ownerId)];
        registerBinding.running = true;
    }
    onValueChanged: if (enabled) applyLater.restart()
    onEnabledChanged: if (enabled) applyLater.restart()
    Component.onDestruction: {
        destroying = true;
        if (registered) Quickshell.execDetached(["hyprctl", "eval", Model.releaseCode(registered, ownerId)]);
    }
    Timer { id: applyLater; interval: 250; onTriggered: if (root.busy) restart(); else root.apply(root.value, false) }
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (root.enabled && event.name === "configreloaded") applyLater.restart(); }
    }
    Process {
        id: readBindings
        command: ["hyprctl", "binds"]
        stdout: StdioCollector { id: bindsOutput }
        onExited: function(code) { root.checkBindings(bindsOutput.text, code); }
    }
    Process {
        id: registerBinding
        stdout: StdioCollector { id: registerOutput }
        onExited: function(code) {
            root.busy = false;
            if (code !== 0 || registerOutput.text.trim() !== "ok") { root.message = Fr.t("text.impossible_dappliquer_le_raccourci_verifiez_votre_configuration_h"); return; }
            root.registered = root.candidate; root.successful = true;
            root.message = root.candidate ? Fr.t("text.raccourci_enregistre") : Fr.t("text.raccourci_dajout_rapide_desactive");
            if (root.persistPending) root.service.saveShortcut(root.candidate);
        }
    }
}
