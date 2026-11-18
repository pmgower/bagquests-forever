-- Pins: world map and minimap icons through HereBeDragons-Pins.
-- Current step = bright bag icon on both maps; later steps = dim, world map only.
-- World map and minimap icons come from separate frame pools. HereBeDragons
-- anchors a minimap icon to the minimap's center, so a frame reused for the
-- world map kept that anchor and stuck to the minimap, following the player.
local _, ns = ...
local Pins = {}
ns.Pins = Pins

local REF = "BagQuests"
local ICON = "Interface\\AddOns\\BagQuests\\Media\\bag"
local pools = { world = { frames = {}, used = 0 }, mini = { frames = {}, used = 0 } }
local playerLevel = 0

local function hbd() return LibStub and LibStub("HereBeDragons-Pins-2.0", true) end

local function acquire(kind)
  local pool = pools[kind]
  pool.used = pool.used + 1
  local f = pool.frames[pool.used]
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
    pool.frames[pool.used] = f
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
  for _, pool in pairs(pools) do
    for i = 1, pool.used do pool.frames[i]:Hide() end
    pool.used = 0
  end
  for _, r in ipairs(results) do
    -- Only lines you can work on now; level-locked lines would fill the map
    -- with pins you can't use yet (the tracker lists them as "unlocks at").
    if r.current and r.status ~= ns.Domain.LINE.TOO_LOW then
      for _, entry in ipairs(r.steps) do
        local s = entry.step
        local isCurrent = entry.index == r.current
        if s.mapID and (isCurrent or (entry.state == ns.Domain.STEP.LATER and settings.showLaterPins)) then
          -- No Show() here: HereBeDragons shows a world map icon when the map opens.
          local f = acquire("world")
          f.step, f.index, f.lineTitle, f.line = s, entry.index, r.line.title, r.line
          f:SetSize(isCurrent and 18 or 12, isCurrent and 18 or 12)
          f.tex:SetDesaturated(not isCurrent)
          f:SetAlpha(isCurrent and 1 or 0.6)
          P:AddWorldMapIconMap(REF, f, s.mapID, s.x / 100, s.y / 100, HBD_PINS_WORLDMAP_SHOW_CONTINENT)
          if isCurrent and settings.minimapPins then
            local m = acquire("mini")
            m.step, m.index, m.lineTitle, m.line = s, entry.index, r.line.title, r.line
            m:SetSize(14, 14)
            P:AddMinimapIconMap(REF, m, s.mapID, s.x / 100, s.y / 100, false, true)
          end
        end
      end
    end
  end
end
