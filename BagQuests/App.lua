-- App: use cases and event wiring. Adapters and UI call in here; Domain never
-- calls out. Other addons (BagQuests_Alts) subscribe with BagQuests.OnRefresh.
local _, ns = ...

local App = {}
ns.App = App
_G.BagQuests = App

App.VERSION = "0.2.1-beta"
local Domain = ns.Domain
App.Domain = Domain
local db
local listeners, commands = {}, {}

App.DEFAULTS = { tracker = true, minimapPins = true, showLaterPins = true, locked = false,
  minimapButton = true }

function App.Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffe0a040BagQuests|r " .. tostring(msg)) end

function App.Settings() return db.settings end
function App.DB() return db end

-- Modules add rows to the settings page: fn(addCheckbox) runs when it's built.
local settingsHooks = {}
function App.OnSettings(fn) table.insert(settingsHooks, fn) end
function App.SettingsHooks() return settingsHooks end

-- fn(snapshot, results, character) runs after every refresh.
function App.OnRefresh(fn) table.insert(listeners, fn) end

-- Lets modules add slash subcommands: App.RegisterCommand("alts", fn, "help text").
function App.RegisterCommand(name, fn, help) commands[name] = { fn = fn, help = help } end
function App.Commands() return commands end

local function plain(v)
  if v == nil then return nil end
  if issecretvalue and issecretvalue(v) then return nil end -- Forever can return secret strings
  if v == "" then return nil end
  return v
end

-- Forever names have two parts. There UnitName's second value is the
-- surname, not a realm (AllTheThings issue #2630), and the realm comes
-- from GetRealmName.
function App.Character()
  local first, second
  if UnitName then first, second = UnitName("player") end -- "a and f()" would drop the 2nd value
  local realm = GetRealmName and GetRealmName() or "?"
  local class
  if UnitClass then class = select(2, UnitClass("player")) end -- class token, e.g. "WARLOCK"
  return { name = plain(first) or "?", surname = plain(second), realm = realm, class = class }
end

---------------------------------------------------------------- use cases

function App.Evaluate(snap)
  local results = {}
  for _, line in ipairs(Domain.All()) do table.insert(results, Domain.Evaluate(line, snap)) end
  return results
end

-- Lines this character can work on right now, current step first.
function App.Workable(results)
  local list = {}
  for _, r in ipairs(results) do
    if r.current and (r.status == Domain.LINE.IN_PROGRESS or r.status == Domain.LINE.AVAILABLE) then
      table.insert(list, r)
    end
  end
  return list
end

App.last = nil -- { snap, results }

-- Lines this character can't start yet (below the required level).
function App.Locked(results)
  local list = {}
  for _, r in ipairs(results) do
    if r.status == Domain.LINE.TOO_LOW then table.insert(list, r) end
  end
  return list
end

function App.Refresh()
  if not db then return end
  local snap = ns.QuestState.Snapshot()
  local results = App.Evaluate(snap)
  App.last = { snap = snap, results = results }
  if ns.Tracker then ns.Tracker.Render(App.Workable(results), db.settings, snap.level, App.Locked(results)) end
  if ns.Pins then ns.Pins.Refresh(results, db.settings, snap.level) end
  local who = App.Character()
  for _, fn in ipairs(listeners) do
    local ok, err = pcall(fn, snap, results, who)
    if not ok then App.Print("module error: " .. tostring(err)) end
  end
end

local pending = false
function App.RequestRefresh(delay)
  if pending then return end
  pending = true
  local function run() pending = false; App.Refresh() end
  if C_Timer and C_Timer.After then C_Timer.After(delay or 0.5, run) else run() end
end

-- Record when Forever uses a different quest ID than our data file.
function App.CheckAccepted(questID)
  local title = ns.QuestState.Title(questID)
  local m = Domain.CheckQuestID(questID, title)
  if m then
    db.mismatches[m.name] = { expected = m.expected, actual = m.actual }
    App.Print(string.format("|cffff6060Quest ID mismatch:|r \"%s\" is %d in Forever, data file says %d. Tell Claude (/bq verify).",
      m.name, m.actual, m.expected))
  end
end

function App.NextStep()
  if not App.last then return nil end
  local r = App.Workable(App.last.results)[1]
  if r then return r.steps[r.current].step, r end
end

---------------------------------------------------------------- events

local frame = CreateFrame("Frame")
App.frame = frame
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN" then
    BagQuestsDB = BagQuestsDB or {}
    db = BagQuestsDB
    db.settings = db.settings or {}
    for k, v in pairs(App.DEFAULTS) do if db.settings[k] == nil then db.settings[k] = v end end
    db.mismatches = db.mismatches or {}
    for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED",
      "QUEST_LOG_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_LEVEL_UP" }) do frame:RegisterEvent(e) end
    if ns.Tracker then ns.Tracker.Init(db.settings) end
    if ns.SettingsPanel then ns.SettingsPanel.Init(db.settings) end
    if ns.MinimapButton then ns.MinimapButton.Init(db) end
    App.Refresh()
  elseif event == "QUEST_ACCEPTED" then
    App.CheckAccepted(arg1)
    App.RequestRefresh(0.5)
  elseif event == "QUEST_TURNED_IN" then
    App.RequestRefresh(1.5) -- completion flag lags the event slightly
  else
    App.RequestRefresh(0.5)
  end
end)
