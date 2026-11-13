.import "i18n/Fr.js" as Fr
// Recognize inline edit syntax without creating a temporary Todoist task.
// Todoist interprets due_string; this module only separates metadata from text.
function parse(task, draft, currentDate) {
  var text = String(draft || "").trim(), original = String(task.content || "")
  var consumed = [], protectedSpans = [], update = {}, projectName = "", hints = []
  function overlaps(start, end, spans) {
    return spans.some(function(s) { return start < s[1] && end > s[0] })
  }
  function isNew(start, end) {
    var token = text.slice(start, end)
    return text.slice(0, end).split(token).length > original.split(token).length
  }
  function collect(regex, callback) {
    var match
    while ((match = regex.exec(text)) !== null) {
      var start = match.index + (match[1] || "").length, end = match.index + match[0].length
      if (overlaps(start, end, consumed) || overlaps(start, end, protectedSpans) || !isNew(start, end)) continue
      callback(match, start, end); consumed.push([start, end])
    }
  }
  // Markdown, URLs, quoted prose and escaped words remain literal. Project and
  // explicit date quotes are parsed below, so don't protect those quote spans.
  var guard = /https?:\/\/\S+|\[[^\]]*\]\([^)]*\)|`[^`]*`|\\\S+|"[^"\n]*"/g, match
  while ((match = guard.exec(text)) !== null) {
    var before = text.slice(0, match.index)
    if (match[0][0] === '"' && /(?:^|\s)(?:#|(?:date|due):)$/.test(before)) continue
    protectedSpans.push([match.index, match.index + match[0].length])
  }
  // Project names accept quotes or Quick Add's escaped spaces.
  collect(/(^|\s)#("(?:\\.|[^"\\])+"|(?:\\.|[^\s\\])+)/g, function(m) {
    if (projectName) throw new Error(Fr.t("text.indiquez_un_seul_projet"))
    projectName = m[2].replace(/^"|"$/g, "").replace(/\\(.)/g, "$1").trim()
    if (!projectName) throw new Error(Fr.t("text.indiquez_un_nom_de_projet_apres"))
    hints.push(Fr.t("parser.project", projectName))
  })
  collect(/(^|\s)(?:p|!!)([1-4])(?=\s|$)/gi, function(m) {
    if (update.priority !== undefined) throw new Error(Fr.t("text.indiquez_une_seule_priorite"))
    update.priority = 5 - Number(m[2])
    hints.push("p" + m[2])
  })
  var date = "", time = ""
  collect(/(^|\s)(?:date|due):"((?:\\.|[^"\\])+)"/gi, function(m) {
    if (date) throw new Error(Fr.t("text.indiquez_une_seule_date"))
    date = m[2].replace(/\\(.)/g, "$1")
  })
  var days = "monday|tuesday|wednesday|thursday|friday|saturday|sunday|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche"
  var months = "january|february|march|april|may|june|july|august|september|october|november|december|janvier|février|fevrier|mars|avril|mai|juin|juillet|août|aout|septembre|octobre|novembre|décembre|decembre"
  var dates = "sans date|aucune date|no date|après-demain|apres-demain|day after tomorrow|aujourd['’]hui|demain|today|tomorrow|tonight|ce soir"
    + "|(?:every!? (?:other )?(?:[0-9]+ )?(?:days?|weeks?|months?|years?|weekdays?|" + days + ")s?)"
    + "|(?:(?:tous les|toutes les|chaque) (?:[0-9]+ )?(?:jours?|semaines?|mois|ans?|" + days + ")s?)"
    + "|(?:next|this) (?:week|month|" + days + ")"
    + "|(?:" + days + ")(?: prochain)?|(?:la )?semaine prochaine"
    + "|(?:in|dans) [0-9]+ (?:days?|weeks?|months?|hours?|minutes?|jours?|semaines?|mois|heures?)"
    + "|[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{1,2}/[0-9]{1,2}(?:/[0-9]{4})?"
    + "|[0-9]{1,2} (?:" + months + ")(?: [0-9]{4})?|(?:" + months + ") [0-9]{1,2}(?:,? [0-9]{4})?"
  collect(new RegExp("(^|\\s)(" + dates + ")(?=\\s|$)", "gi"), function(m) {
    if (date) throw new Error(Fr.t("text.indiquez_une_seule_date_ou_utilisez_date"))
    date = m[2]
  })
  collect(/(^|\s)((?:(?:at|à)\s+)?(?:[01]?\d|2[0-3])(?::[0-5]\d|\s*h(?:\s*[0-5]\d)?)(?:\s*(?:am|pm))?|(?:(?:at|à)\s+)?(?:0?[1-9]|1[0-2])(?::[0-5]\d)?\s*(?:am|pm)|(?:at|à)\s+(?:[01]?\d|2[0-3]))(?=\s|$)/gi, function(m) {
    if (time) throw new Error(Fr.t("text.indiquez_une_seule_heure"))
    time = m[2]
  })
  if (date || time) {
    if (/^(sans date|aucune date|no date)$/i.test(date)) {
      if (time) throw new Error(Fr.t("text.une_heure_ne_peut_pas_etre_combinee_avec_sans_date"))
      update.due_string = "no date"; update.due_lang = "en"
      hints.push(Fr.t("text.sans_date"))
    } else {
      if (!date && currentDate) {
        // A time-only edit keeps the existing day, including recurring dates.
        date = task.due && task.due.is_recurring && task.due.string
          ? task.due.string.replace(/\s+(?:(?:at|à)\s+)?\d{1,2}(?:(?::\d{2}|\s*h(?:\s*\d{2})?)(?:\s*(?:am|pm))?|\s*(?:am|pm))?\s*$/i, "") : currentDate
      }
      var due = [date, time].filter(Boolean).join(" ")
      update.due_string = due
      update.due_lang = /aujourd|demain|soir|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche|prochain|dans|tous|toutes|chaque|janvier|février|fevrier|mars|avril|mai|juin|juillet|août|aout|septembre|octobre|novembre|décembre|decembre|(?:^|\s)à\s|\dh/i.test(due) ? "fr" : "en"
      hints.push(Fr.t("parser.date", due))
    }
  }
  consumed.sort(function(a,b) { return a[0] - b[0] })
  var content = "", pos = 0
  consumed.forEach(function(span) { content += text.slice(pos, span[0]); pos = span[1] })
  content = (content + text.slice(pos)).trim()
  if (consumed.length) content = content.replace(/\s{2,}/g, " ")
  if (!content) throw new Error(Fr.t("text.le_nom_de_la_tache_ne_peut_pas_etre_vide"))
  update.content = content
  return { update: update, projectName: projectName, hints: hints }
}

function resolveProject(projects, name) {
  var matches = projects.filter(function(p) {
    return !p.is_archived && !p.is_deleted && String(p.name || "").toLocaleLowerCase() === name.toLocaleLowerCase()
  })
  if (!matches.length) throw new Error(Fr.t("parser.project_missing", name))
  if (matches.length !== 1) throw new Error(Fr.t("parser.project_ambiguous", name))
  return String(matches[0].id)
}

function parseProjectPage(text) {
  var page
  try { page = JSON.parse(text) } catch (e) { throw new Error(Fr.t("text.reponse_des_projets_invalide")) }
  if (!page || !Array.isArray(page.results)
      || !(page.next_cursor === null || (typeof page.next_cursor === "string" && page.next_cursor !== ""))
      || page.results.some(function(p) { return !p || typeof p.id !== "string" || !p.id || typeof p.name !== "string" }))
    throw new Error(Fr.t("text.reponse_des_projets_invalide"))
  return page
}
