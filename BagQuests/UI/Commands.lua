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
      local s = App.Settings(); s.locked = not s.locked; App.Print("tracker " .. (s.locked and "locked" or "unlocked")) end },
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
