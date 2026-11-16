-- SettingsPanel: the page under Options -> AddOns -> BagQuests: Forever.
-- Every checkbox writes straight into BagQuestsDB.settings (or a module's own
-- table) and refreshes, so the slash commands and this page stay in sync.
local _, ns = ...
local SettingsPanel = {}
ns.SettingsPanel = SettingsPanel

local App = ns.App
local category

-- Rows: key in the settings table, label, tooltip. Order = order on the page.
SettingsPanel.ROWS = {
  { "tracker", "Show on-screen tracker", "The next step for each bag questline. Same as /bq." },
  { "locked", "Lock tracker position", "Stops the tracker from being dragged." },
  { "minimapButton", "Show minimap button", "Left-click: tracker. Right-click: settings. Shift-click: alts table." },
  { "minimapPins", "Show next step on the minimap", "A bag icon on the minimap when you're in that zone." },
  { "showLaterPins", "Show later steps on the world map", "Dim bag icons for the steps after your current one." },
}

local function onChanged(key)
  if key == "minimapButton" and ns.MinimapButton then ns.MinimapButton.Apply(App.DB()) end
  App.Refresh()
end

-- addCheckbox(tbl, key, label, tooltip, default, onChange): modules use this too.
local function makeAdder(cat)
  return function(tbl, key, label, tooltip, default, onChange)
    if tbl[key] == nil then tbl[key] = default end
    local setting = Settings.RegisterAddOnSetting(cat, "BagQuests_" .. key, key, tbl, type(default), label, default)
    if setting.SetValueChangedCallback then
      setting:SetValueChangedCallback(function() if onChange then onChange(key) end end)
    end
    Settings.CreateCheckbox(cat, setting, tooltip)
    return setting
  end
end

function SettingsPanel.Init(settings)
  if not (Settings and Settings.RegisterVerticalLayoutCategory) then return end -- no Settings API
  category = Settings.RegisterVerticalLayoutCategory("BagQuests: Forever")
  local add = makeAdder(category)
  for _, row in ipairs(SettingsPanel.ROWS) do
    add(settings, row[1], row[2], row[3], App.DEFAULTS[row[1]], onChanged)
  end
  -- One "Track" checkbox per questline: untick the ones you don't care about.
  for _, line in ipairs(ns.Domain.All()) do
    local tip = string.format("%s%s. Required level %d. Unticked lines leave the tracker, map and alts table.",
      line.faction and (line.faction .. " only. ") or "", line.slots and (line.slots .. "-slot bag") or "Bag",
      line.minLevel)
    add(settings, "track_" .. line.id, string.format("Track: %s (%s slots, lvl %d)", line.title,
      tostring(line.slots or "?"), line.minLevel), tip, true, onChanged)
  end
  for _, hook in ipairs(App.SettingsHooks()) do pcall(hook, add) end
  Settings.RegisterAddOnCategory(category)
end

function SettingsPanel.Open()
  if category and Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(category:GetID())
    return true
  end
  App.Print("settings page isn't available; use /bq help")
  return false
end
