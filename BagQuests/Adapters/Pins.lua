-- Pins: world map and minimap icons through HereBeDragons-Pins.
-- Current step = bright bag icon on both maps; later steps = dim, world map only.
local _, ns = ...
local Pins = {}
ns.Pins = Pins

local REF = "BagQuests"
local ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local pool, used = {}, 0
local playerLevel = 0

local function hbd() return LibStub and LibStub("HereBeDragons-Pins-2.0", true) end

local function acquire()
  used = used + 1
  local f = pool[used]
  if not f then
    f = CreateFrame("Button", nil, UIParent)
    f:SetSize(16, 16)
    f.tex = f:CreateTexture(nil, "OVERLAY")
    f.tex:SetAllPoints()
    f.tex:SetTexture(ICON)
    f:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(self.lineTitle, 1, 0.82, 0)
      GameTooltip:AddLine(string.format("Step %d: %s", self.index, self.step.title), 1, 1, 1)
      if ns.Tracker and self.line then GameTooltip:AddLine((ns.Tracker.LevelLine(self.line, self.step, playerLevel))) end
      if self.step.object then GameTooltip:AddLine("Click: " .. self.step.object, 0.8, 0.8, 0.8) end
      if self.step.npc then GameTooltip:AddLine("Talk to: " .. self.step.npc, 0.8, 0.8, 0.8) end
      if self.step.hint then GameTooltip:AddLine(self.step.hint, 0.6, 0.8, 1, true) end
      if self.step.reward then GameTooltip:AddLine("Reward: " .. self.step.reward, 0.4, 1, 0.4) end
      GameTooltip:AddLine("Click to set a waypoint", 0.5, 0.5, 0.5)
      GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f:SetScript("OnClick", function(self) ns.Waypoints.Set(self.step) end)
    pool[used] = f
  end
  return f
end

-- results = list of Domain.Evaluate results for this character.
function Pins.Refresh(results, settings, level)
  playerLevel = level or 0
  local P = hbd()
  if not P then return end
  P:RemoveAllWorldMapIcons(REF)
  P:RemoveAllMinimapIcons(REF)
  for i = 1, used do pool[i]:Hide() end
  used = 0
  for _, r in ipairs(results) do
    if r.current then
      for _, entry in ipairs(r.steps) do
        local s = entry.step
        local isCurrent = entry.index == r.current
        if s.mapID and (isCurrent or (entry.state == ns.Domain.STEP.LATER and settings.showLaterPins)) then
          local f = acquire()
          f.step, f.index, f.lineTitle, f.line = s, entry.index, r.line.title, r.line
          f:SetSize(isCurrent and 18 or 12, isCurrent and 18 or 12)
          f.tex:SetDesaturated(not isCurrent)
          f:SetAlpha(isCurrent and 1 or 0.6)
          f:Show()
          P:AddWorldMapIconMap(REF, f, s.mapID, s.x / 100, s.y / 100, HBD_PINS_WORLDMAP_SHOW_CONTINENT)
          if isCurrent and settings.minimapPins then
            local m = acquire()
            m.step, m.index, m.lineTitle, m.line = s, entry.index, r.line.title, r.line
            m:SetSize(14, 14); m.tex:SetDesaturated(false); m:SetAlpha(1); m:Show()
            P:AddMinimapIconMap(REF, m, s.mapID, s.x / 100, s.y / 100, false, true)
          end
        end
      end
    end
  end
end
