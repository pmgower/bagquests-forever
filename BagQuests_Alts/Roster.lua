-- Roster: account-wide store of each character's last snapshot. Pure Lua
-- except for the hook at the bottom. Snapshots are stored raw and evaluated on
-- display, so a fixed data file re-scores old snapshots correctly.
local _, ns = ...
ns = ns or {}
local Roster = {}
ns.Roster = Roster

function Roster.Key(name, realm) return tostring(name) .. "-" .. tostring(realm) end

function Roster.Save(store, who, snap, now)
  local key = Roster.Key(who.name, who.realm)
  store[key] = {
    name = who.name, surname = who.surname, realm = who.realm, class = who.class,
    level = snap.level, faction = snap.faction, seen = now,
    completed = snap.completed, active = snap.active, items = snap.items,
    skipped = snap.skipped,
  }
  return key
end

function Roster.Forget(store, name)
  local removed = 0
  for key, c in pairs(store) do
    if c.name and c.name:lower() == tostring(name):lower() then store[key] = nil; removed = removed + 1 end
  end
  return removed
end

-- Rows for the table: { char, cells = { {text, status}, ... } }, highest level first.
-- lines = the questlines to show (default: all of them).
function Roster.Rows(store, Domain, lines)
  local rows = {}
  for _, c in pairs(store) do
    local cells = {}
    for _, line in ipairs(lines or Domain.All()) do
      local r = Domain.Evaluate(line, c)
      local left = r.total - r.done
      local step = r.current and r.steps[r.current].step or nil
      table.insert(cells, { text = Domain.Summary(r), status = r.status, left = left,
        next = step and step.title or nil,
        suggested = step and (step.suggested or line.minLevel) or nil,
        fit = step and Domain.LevelFit(line, step, c.level) or nil })
    end
    table.insert(rows, { char = c, cells = cells })
  end
  table.sort(rows, function(a, b)
    if (a.char.level or 0) ~= (b.char.level or 0) then return (a.char.level or 0) > (b.char.level or 0) end
    return tostring(a.char.name) < tostring(b.char.name)
  end)
  return rows
end

if _G.BagQuests then
  local App = _G.BagQuests
  App.OnRefresh(function(snap, _, who)
    BagQuestsAltsDB = BagQuestsAltsDB or { characters = {} }
    Roster.Save(BagQuestsAltsDB.characters, who, snap, time and time() or os.time())
    if ns.AltsWindow then ns.AltsWindow.RefreshIfShown() end
  end)
  App.OnSettings(function(addCheckbox)
    BagQuestsAltsDB = BagQuestsAltsDB or { characters = {} }
    BagQuestsAltsDB.settings = BagQuestsAltsDB.settings or {}
    addCheckbox(BagQuestsAltsDB.settings, "hideSurnames", "Alts table: first names only",
      "Hide second names (e.g. 'Undertaker') to make the alts table narrower. Same as /bq surnames.",
      false, function() if ns.AltsWindow then ns.AltsWindow.RefreshIfShown() end end)
  end)
  App.RegisterCommand("surnames", function()
    BagQuestsAltsDB = BagQuestsAltsDB or { characters = {} }
    BagQuestsAltsDB.settings = BagQuestsAltsDB.settings or {}
    local st = BagQuestsAltsDB.settings
    st.hideSurnames = not st.hideSurnames
    App.Print("alts table surnames " .. (st.hideSurnames and "hidden" or "shown"))
    if ns.AltsWindow then ns.AltsWindow.RefreshIfShown() end
  end, "Show or hide second names in the alts table")
  App.RegisterCommand("forget", function(name)
    local n = Roster.Forget((BagQuestsAltsDB or { characters = {} }).characters, name)
    App.Print(string.format("forgot %d character(s) named %s", n, name))
  end, "<name>: remove a character from the alts table")
end
