-- MinimapButton: LibDBIcon button. Position and visibility live in
-- BagQuestsDB.minimapIcon (LibDBIcon's own format).
local _, ns = ...
local MinimapButton = {}
ns.MinimapButton = MinimapButton

local App = ns.App
local NAME = "BagQuests"
local icon

-- Tooltip lines, pure so tests can check them.
function MinimapButton.TooltipLines()
  local lines = { "BagQuests: Forever" }
  local step, r = App.NextStep()
  if step then
    table.insert(lines, string.format("Next: %s (%s %d/%d)", step.title, r.line.title, r.current, r.total))
  else
    table.insert(lines, "No bag questline to work on right now")
  end
  table.insert(lines, "|cffbbbbbbLeft-click:|r tracker on/off")
  table.insert(lines, "|cffbbbbbbRight-click:|r settings")
  if App.Commands()["alts"] then table.insert(lines, "|cffbbbbbbShift-click:|r alts table") end
  return lines
end

function MinimapButton.OnClick(button)
  if button == "RightButton" then
    ns.SettingsPanel.Open()
  elseif IsShiftKeyDown and IsShiftKeyDown() and App.Commands()["alts"] then
    App.Commands()["alts"].fn("")
  else
    ns.Tracker.Toggle(App.Settings())
  end
end

function MinimapButton.Init(db)
  local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
  icon = LibStub and LibStub("LibDBIcon-1.0", true)
  if not (ldb and icon) then return end
  db.minimapIcon = db.minimapIcon or {}
  local obj = ldb:NewDataObject(NAME, {
    type = "launcher",
    text = "BagQuests",
    icon = "Interface\\AddOns\\BagQuests\\Media\\logo",
    OnClick = function(_, button) MinimapButton.OnClick(button) end,
    OnTooltipShow = function(tt)
      for i, line in ipairs(MinimapButton.TooltipLines()) do
        if i == 1 then tt:AddLine(line, 1, 0.82, 0) else tt:AddLine(line, 1, 1, 1, true) end
      end
    end,
  })
  icon:Register(NAME, obj, db.minimapIcon)
  MinimapButton.Apply(db)
end

-- Sync LibDBIcon with the "Show minimap button" setting.
function MinimapButton.Apply(db)
  if not icon then return end
  db.minimapIcon.hide = not db.settings.minimapButton
  if db.minimapIcon.hide then icon:Hide(NAME) else icon:Show(NAME) end
end
