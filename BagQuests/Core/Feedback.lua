-- Feedback: pure Lua, no WoW API. Turns a plain "what's going on" table into
-- the text block /bq feedback shows for pasting into a GitHub issue.
--
-- App.FeedbackContext() gathers the facts from the game; this file only
-- formats them, so the report can be tested outside the game. Nothing here
-- leaves the player's computer: they copy and paste it themselves.
--
-- The character's name is left out on purpose: issues are public, and the
-- name doesn't help us debug anything.
local _, ns = ...
ns = ns or {}

local Feedback = {}
ns.Feedback = Feedback

Feedback.ISSUES_URL = "https://github.com/pmgower/bagquests-forever/issues/new/choose"
Feedback.BUG_FORM_URL = "https://github.com/pmgower/bagquests-forever/issues/new?template=bug_report.yml"
Feedback.FORM_FIELD = "feedback" -- id of the report box in .github/ISSUE_TEMPLATE/bug_report.yml
Feedback.MAX_URL = 7000 -- GitHub refuses much longer links; fall back to the plain form past this
Feedback.MAX_ERRORS = 5

Feedback.MAX_ERROR_LEN = 600 -- one error plus its short stack, so the link stays short

-- Is this Lua error from BagQuests (or BagQuests_Alts)? Looks for our folder in
-- the message or the stack, so other addons' errors are left alone.
function Feedback.IsOurs(msg, stack)
  local hay = tostring(msg or "") .. "\n" .. tostring(stack or "")
  return hay:find("AddOns[/\\]BagQuests") ~= nil
end

-- The error message plus the first few stack lines that point into our code,
-- cut to MAX_ERROR_LEN.
function Feedback.ShortError(msg, stack)
  local out, n = { tostring(msg or "?") }, 0
  for line in tostring(stack or ""):gmatch("[^\n]+") do
    if n >= 4 then break end
    if line:find("AddOns[/\\]BagQuests") then table.insert(out, "  " .. line); n = n + 1 end
  end
  local s = table.concat(out, "\n")
  if #s > Feedback.MAX_ERROR_LEN then s = s:sub(1, Feedback.MAX_ERROR_LEN) .. "..." end
  return s
end

-- Percent-encodes everything but unreserved URL characters (RFC 3986).
function Feedback.UrlEncode(text)
  return (tostring(text):gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

-- A link that opens the Bug report form with the report already in its
-- "/bq feedback output" box (GitHub issue forms prefill a field from a
-- query parameter named after its id). Returns url, prefilled. When the
-- report makes the link too long, returns the plain form link and false, and
-- the player pastes the report by hand.
function Feedback.IssueUrl(report)
  local url = Feedback.BUG_FORM_URL .. "&" .. Feedback.FORM_FIELD .. "=" .. Feedback.UrlEncode(report)
  if #url <= Feedback.MAX_URL then return url, true end
  return Feedback.BUG_FORM_URL, false
end

local function onOff(v)
  if v == true then return "on" end
  if v == false then return "off" end
  return tostring(v)
end

local function sortedKeys(t)
  local keys = {}
  for k in pairs(t or {}) do table.insert(keys, k) end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  return keys
end

local function orNone(list) return #list > 0 and table.concat(list, ", ") or "none" end

-- "tracker=on locked=off ..." without the per-questline track_* flags (those
-- are reported as "Not tracked").
local function settingsLine(settings)
  local parts = {}
  for _, k in ipairs(sortedKeys(settings)) do
    if not tostring(k):match("^track_") then table.insert(parts, k .. "=" .. onOff(settings[k])) end
  end
  return orNone(parts)
end

-- "cozy_sleeping_bag: in_progress 3/9, next step 4 "Thoradin's Wall" (active), skipped to 2"
function Feedback.LineSummary(r)
  local s = string.format("%s: %s %d/%d", r.line.id, r.status, r.done or 0, r.total or 0)
  if r.current then
    local entry = r.steps[r.current]
    s = s .. string.format(", next step %d \"%s\" (%s)", r.current, entry.step.title, entry.state)
  end
  if (r.skipped or 0) > 0 then s = s .. ", skipped to " .. r.skipped end
  return s
end

-- ctx = {
--   version, altsLoaded,
--   client = { version, build, date, interface, locale },
--   character = { level, race, class, faction, realm },
--   settings = {...}, untracked = { lineID, ... }, results = { Domain.Evaluate results },
--   questsInLog = { questID, ... },  -- only quest IDs our data knows about
--   mismatches = { [name] = { expected, actual } },
--   addons = { TomTom = bool, Questie = bool },
--   errors = { "message", ... },
-- }
-- Returns the report as one string, one fact per line.
function Feedback.Report(ctx)
  local out = {}
  local function add(fmt, ...) table.insert(out, string.format(fmt, ...)) end
  local c, ch = ctx.client or {}, ctx.character or {}

  add("BagQuests feedback report")
  add("Addon: %s (Alts module %s)", tostring(ctx.version), ctx.altsLoaded and "loaded" or "not loaded")
  add("Client: %s build %s (%s), interface %s, locale %s", tostring(c.version or "?"), tostring(c.build or "?"),
    tostring(c.date or "?"), tostring(c.interface or "?"), tostring(c.locale or "?"))
  add("Character: level %s %s %s, %s, realm %s", tostring(ch.level or "?"), tostring(ch.race or "?"),
    tostring(ch.class or "?"), tostring(ch.faction or "?"), tostring(ch.realm or "?"))
  add("Settings: %s", settingsLine(ctx.settings))
  add("Not tracked: %s", orNone(ctx.untracked or {}))

  add("Questlines:")
  if #(ctx.results or {}) == 0 then add("  none tracked") end
  for _, r in ipairs(ctx.results or {}) do add("  %s", Feedback.LineSummary(r)) end

  local ids = {}
  for _, id in ipairs(ctx.questsInLog or {}) do table.insert(ids, tostring(id)) end
  add("Our quests in log: %s", orNone(ids))

  local mism = {}
  for _, name in ipairs(sortedKeys(ctx.mismatches)) do
    local m = ctx.mismatches[name]
    table.insert(mism, string.format("%s (Forever %s, data %s)", name, tostring(m.actual), tostring(m.expected)))
  end
  add("Quest ID mismatches: %s", orNone(mism))

  local addons = {}
  for _, name in ipairs(sortedKeys(ctx.addons)) do
    table.insert(addons, name .. " " .. (ctx.addons[name] and "loaded" or "not loaded"))
  end
  add("Other addons: %s", orNone(addons))

  local errs = ctx.errors or {}
  add("Errors this session: %s", #errs == 0 and "none" or tostring(#errs))
  for _, e in ipairs(errs) do add("  %s", tostring(e)) end
  return table.concat(out, "\n")
end

return Feedback
