-- Slash commands: /bq and /bagquests.
local _, ns = ...
local App, Domain = ns.App, ns.Domain

local function onOff(v) return v and "on" or "off" end

local builtins
builtins = {
  { "", "Show or hide the on-screen tracker", function()
      App.Print("tracker " .. onOff(ns.Tracker.Toggle(App.Settings()))) end },
  { "way", "Waypoint to your next step", function()
      local step = App.NextStep()
      if step and ns.Waypoints.Set(step) then App.Print("waypoint: " .. step.title)
      else App.Print("no next step for this character") end end },
  { "status", "Every bag questline for this character", function()
      App.Refresh()
      for _, r in ipairs(App.last.results) do
        local where = ""
        if r.current then
          local step = r.steps[r.current].step
          where = string.format(" - next: %s (req %d, suggested %d)", step.title, r.line.minLevel, step.suggested or r.line.minLevel)
        end
        App.Print(string.format("%s: %s%s", r.line.title, Domain.Summary(r), where))
      end end },
  { "verify", "Check our quest IDs against the game", function()
      local snap = App.last and App.last.snap or ns.QuestState.Snapshot()
      for _, line in ipairs(Domain.All()) do
        for id, name in pairs(line.quests or {}) do
          local state = snap.completed[id] and "|cff66ff66completed|r" or (snap.active[id] and "|cffffff00in log|r" or "not started")
          App.Print(string.format("%d %s: %s", id, name, state))
        end
      end
      App.Print("Your quest log:")
      for _, e in ipairs(ns.QuestState.LogEntries()) do App.Print(string.format("  %d %s", e.id, e.title or "?")) end
      for name, m in pairs(App.DB().mismatches) do
        App.Print(string.format("|cffff6060mismatch|r %s: Forever %d, data %d", name, m.actual, m.expected))
      end end },
  { "pins", "Toggle dim pins for later steps on the world map", function()
      local s = App.Settings(); s.showLaterPins = not s.showLaterPins
      App.Refresh(); App.Print("later-step pins " .. onOff(s.showLaterPins)) end },
  { "minimap", "Toggle the minimap pin", function()
      local s = App.Settings(); s.minimapPins = not s.minimapPins
      App.Refresh(); App.Print("minimap pin " .. onOff(s.minimapPins)) end },
  { "lock", "Lock or unlock the tracker position", function()
      local s = App.Settings(); s.locked = not s.locked; App.Refresh()
      App.Print("tracker " .. (s.locked and "locked" or "unlocked")) end },
  { "reset", "Move the tracker and alts windows back to their default spot and size", function()
      ns.Window.ResetAll(); App.Refresh(); App.Print("window positions and sizes reset") end },
  { "theme", "Tracker color scheme: /bq theme twilight (frost, deepwater, twilight, classic). No name cycles", function(rest)
      local s, themes = App.Settings(), ns.Tracker.THEMES
      local key = rest and rest:lower():match("%a+")
      if not key then
        for i, t in ipairs(themes) do
          if t.key == s.theme then key = themes[i % #themes + 1].key end
        end
        key = key or themes[1].key
      end
      local found = false
      for _, t in ipairs(themes) do if t.key == key then found = true end end
      if not found then App.Print("unknown theme: " .. key .. " (frost, deepwater, twilight, classic)"); return end
      s.theme = key; ns.Tracker.ApplyTheme(key); App.Refresh()
      App.Print("theme: " .. ns.Tracker.Theme(key).name) end },
  { "skip", "Skip the current step (/bq skip 2 for the 2nd tracker line). Right-click a tracker line does the same", function(rest)
      App.Refresh()
      local w = App.Workable(App.last.results)
      local r = w[tonumber(rest) or 1]
      if not App.SkipStep(r) then App.Print("nothing to skip") end end },
  { "unskip", "Undo every skipped step for this character", function()
      App.Print(string.format("cleared skipped steps on %d questline(s)", App.Unskip())) end },
  { "track", "List questlines; /bq track 3 turns the 3rd on or off", function(rest)
      local all, n = Domain.All(), tonumber(rest)
      if n and all[n] then
        App.SetTracked(all[n], not App.IsTracked(all[n])); App.Refresh()
        App.Print(string.format("%s: %s", all[n].title, App.IsTracked(all[n]) and "tracked" or "not tracked"))
        return
      end
      for i, line in ipairs(all) do
        App.Print(string.format("%d. [%s] %s (%s slots, lvl %d%s)", i, App.IsTracked(line) and "x" or " ",
          line.title, tostring(line.slots or "?"), line.minLevel, line.faction and (", " .. line.faction) or ""))
      end
      App.Print("/bq track <number> to turn one on or off") end },
  { "settings", "Open the settings page (Options > AddOns)", function() ns.SettingsPanel.Open() end },
  { "help", "This list", function()
      App.Print("v" .. App.VERSION .. " commands:")
      for _, c in ipairs(builtins) do App.Print(string.format("  /bq %s - %s", c[1], c[2])) end
      for name, c in pairs(App.Commands()) do App.Print(string.format("  /bq %s - %s", name, c.help or "")) end
    end },
}

function ns.HandleCommand(msg)
  local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd = (cmd or ""):lower()
  for _, c in ipairs(builtins) do if c[1] == cmd then return c[3](rest) end end
  local ext = App.Commands()[cmd]
  if ext then return ext.fn(rest) end
  App.Print("unknown command, try /bq help")
end

SLASH_BAGQUESTS1, SLASH_BAGQUESTS2 = "/bq", "/bagquests"
SlashCmdList.BAGQUESTS = ns.HandleCommand
