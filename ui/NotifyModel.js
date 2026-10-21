.import "../Model.js" as Model

// What to announce, and when. The service checks this often against the
// synced tasks and reminders, so notifications need no requests of their own.
var DEFAULTS = { enabled: true, recap: true, recapTime: "08:00", atDueTime: true, deadlines: true, overdueHours: 0 };
var OVERDUE_HOURS = [0, 1, 2, 4];
// Deadlines this many days ahead appear in the morning recap.
var DEADLINE_DAYS = 3;
var SNOOZE_MS = 15 * 60000;
// A reminder older than this when first seen is history, not news: the
// computer was off or asleep when it came due.
var GRACE_MS = 10 * 60000;
var RECAP_LINES = 5;

function clockMinutes(text) {
    var m = /^(\d{1,2}):(\d{2})$/.exec(String(text || "").trim());
    if (!m || Number(m[1]) > 23 || Number(m[2]) > 59) return -1;
    return Number(m[1]) * 60 + Number(m[2]);
}
function normalClock(text) {
    var minutes = clockMinutes(text);
    return minutes < 0 ? "" : String(Math.floor(minutes / 60)).padStart(2, "0") + ":" + String(minutes % 60).padStart(2, "0");
}
function settings(preferences) {
    var saved = (preferences || {}).notifications, out = {};
    saved = saved && typeof saved === "object" ? saved : {};
    Object.keys(DEFAULTS).forEach(function(key) { out[key] = saved[key] !== undefined ? saved[key] : DEFAULTS[key]; });
    ["enabled", "recap", "atDueTime", "deadlines"].forEach(function(key) { out[key] = out[key] !== false; });
    out.recapTime = normalClock(out.recapTime) || DEFAULTS.recapTime;
    out.overdueHours = OVERDUE_HOURS.indexOf(Number(out.overdueHours)) >= 0 ? Number(out.overdueHours) : 0;
    return out;
}

// Only your own tasks and unassigned ones, as in the default Today view.
function mine(task, userId) { return Model.active(task) && Model.matches(task, Model.DEFAULT_VIEW, userId, ""); }

// Location reminders cannot be timed here; Todoist's apps handle them.
function reminderTime(reminder, task) {
    if (!reminder || reminder.is_deleted || reminder.type === "location") return null;
    if (reminder.type === "relative" || (reminder.minute_offset != null && !reminder.due)) {
        var due = Model.dueTime(task);
        return due && isFinite(due.getTime()) ? due.getTime() - Number(reminder.minute_offset || 0) * 60000 : null;
    }
    var value = String((reminder.due || {}).datetime || (reminder.due || {}).date || "");
    if (value.indexOf("T") < 0) return null;
    var at = new Date(value).getTime();
    return isFinite(at) ? at : null;
}

// Task notifications that have come due since the last look and not been
// shown. `sinceMs` is the floor, so restarting the shell does not replay the
// afternoon. A reminder at the task's own time and the at-time notification
// share a key, so the task is announced once.
function taskAlerts(tasks, reminders, userId, options, nowMs, sinceMs, shown, snoozed) {
    var floor = Math.max(Number(sinceMs) || 0, nowMs - GRACE_MS), out = [], seen = {};
    var own = tasks.filter(function(t) { return mine(t, userId); }), byId = Model.byId(own);
    function add(task, at, kind, urgent) {
        var key = task.id + "@" + at;
        if (at === null || at > nowMs || at < floor || seen[key] || (shown || {})[key]) return;
        seen[key] = true;
        out.push({key: key, task: task, at: at, kind: kind, urgent: !!urgent});
    }
    Model.asArray(reminders).forEach(function(r) {
        var task = byId[String(r.item_id)];
        if (task && (!r.notify_uid || String(r.notify_uid) === String(userId))) add(task, reminderTime(r, task), "reminder", r.is_urgent);
    });
    var today = Model.dateKey(new Date(nowMs)), step = options.overdueHours * 3600000;
    own.forEach(function(task) {
        var due = Model.dueTime(task);
        if (!due || !isFinite(due.getTime())) return;
        if (options.atDueTime) add(task, due.getTime(), "due", false);
        // Nagging stays within the task's day; the next recap lists it as overdue.
        if (step > 0 && Model.dateKey(due) === today && nowMs - due.getTime() >= step)
            add(task, due.getTime() + Math.floor((nowMs - due.getTime()) / step) * step, "overdue", false);
    });
    Object.keys(snoozed || {}).forEach(function(id) { if (byId[id]) add(byId[id], snoozed[id], "snooze", false); });
    return out.sort(function(a, b) { return a.at - b.at; });
}

function recapDue(options, now) {
    return clockMinutes(options.recapTime) <= now.getHours() * 60 + now.getMinutes();
}

// Deadlines today and tomorrow each get their own notification at recap time.
function deadlineAlerts(tasks, userId, now) {
    var today = Model.dateKey(now), tomorrow = Model.addDays(today, 1);
    return tasks.filter(function(t) {
        var day = (t.deadline || {}).date;
        return mine(t, userId) && (day === today || day === tomorrow);
    }).map(function(t) {
        var day = t.deadline.date;
        return {key: "deadline-" + t.id + "-" + day + "-" + today, task: t, kind: "deadline", urgent: day === today, today: day === today};
    });
}

// The morning summary: today's tasks in Smart order, then upcoming deadlines.
function recap(tasks, projects, userId, now) {
    var today = Model.dateKey(now), horizon = Model.addDays(today, DEADLINE_DAYS), projectMap = Model.byId(projects);
    var list = tasks.filter(function(t) { return mine(t, userId) && Model.inView(t, "today", today, projectMap); });
    list = Model.sortTasks(list, "smart", "today", projectMap, {});
    var overdue = list.filter(function(t) { return Model.scheduledDay(t) < today; }).length;
    var title = list.length === 0 ? "Nothing due today" : list.length + (list.length === 1 ? " task" : " tasks") + " today";
    if (overdue) title += ", " + overdue + " overdue";
    var lines = list.slice(0, RECAP_LINES).map(function(t) {
        var due = Model.dueTime(t);
        var when = Model.scheduledDay(t) < today ? "Overdue" : due && Model.dateKey(due) === today ? Model.clockText(due) : "";
        return (when ? when + "  " : "") + Model.plain(t.content);
    });
    if (list.length > RECAP_LINES) lines.push("and " + (list.length - RECAP_LINES) + " more");
    var deadlines = tasks.filter(function(t) {
        var day = (t.deadline || {}).date;
        return mine(t, userId) && day && day >= today && day <= horizon;
    }).sort(function(a, b) { return Model.compareText(a.deadline.date, b.deadline.date); });
    deadlines.slice(0, 3).forEach(function(t) {
        lines.push("Deadline " + deadlineDay(t.deadline.date, today) + ": " + Model.plain(t.content));
    });
    return {title: title, body: lines.join("\n")};
}
function deadlineDay(key, today) {
    if (key === today) return "today";
    if (key === Model.addDays(today, 1)) return "tomorrow";
    return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][Model.dateFromKey(key).getDay()];
}

// "In 15 min", "Now", "Overdue since 10:00": what a task notification leads with.
function lead(alert, nowMs) {
    var due = Model.dueTime(alert.task);
    if (!due || !isFinite(due.getTime())) return "Reminder";
    var minutes = Math.round((due.getTime() - nowMs) / 60000), time = Model.dueLabel(alert.task, new Date(nowMs), "today", "none");
    if (minutes < -1) return "Overdue since " + Model.clockText(due);
    if (minutes <= 0) return "Now · " + time;
    if (minutes < 60) return "In " + minutes + " min · " + time;
    return time;
}
function taskBody(alert, nowMs, projectText) {
    if (alert.kind === "deadline") return (alert.today ? "Deadline today" : "Deadline tomorrow") + "\n" + projectText;
    return lead(alert, nowMs) + "\n" + projectText;
}
