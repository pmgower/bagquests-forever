-- Tracker: RestedXP-style guide window with the next step for each questline.
-- The window frame itself (border, title bar, grip, scrolling, themes) is the
-- shared UI/Window.lua; this file fills it with steps.
local _, ns = ...
local Tracker = {}
ns.Tracker = Tracker
local Window = ns.Window

local MAX_LINES = 4
local DEFAULT_W = 270
local AUTO_MAX_H = 520     -- auto-fit height cap until the player resizes it

local win, frame, content, rows, separators, lockedText
local lastArgs -- last Render() arguments, so a resize can re-lay out the rows

-- Color schemes live in Window; these aliases keep /bq theme and tests simple.
Tracker.THEMES = Window.THEMES
Tracker.DEFAULT_THEME = Window.DEFAULT_THEME
Tracker.Theme = Window.Theme
local rgb, num = Window.Rgb, Window.Num
local function theme() return Window.Current() end

local function zoneName(mapID)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
  return info and info.name or ("map " .. tostring(mapID))
end

-- Same colors the game uses for quest levels (QuestDifficultyColors).
local DIFFICULTY_HEX = { red = "ff1a1a", orange = "ff8040", yellow = "ffd100", green = "40bf40", grey = "808080" }

-- "Req. Lvl 14  |  Sug. Lvl 22" ("||" is WoW's escaped pipe): Req turns red when you can't pick the quest up
-- yet; "Lvl 22" uses the game's quest colors for your level.
function Tracker.LevelLine(line, step, level)
  local fit = ns.Domain.LevelFit(line, step, level)
  local suggested = step.suggested or line.minLevel
  local greenRange = GetQuestGreenRange and tonumber(GetQuestGreenRange()) or nil
  local diff = ns.Domain.Difficulty(suggested, level, greenRange)
  local reqHex = fit == ns.Domain.FIT.BLOCKED and DIFFICULTY_HEX.red or "ffffff"
  return string.format("|cffbbbbbbReq.|r |cff%sLvl %d|r  |cff666666|||r  |cffbbbbbbSug.|r |cff%sLvl %d|r",
    reqHex, line.minLevel, DIFFICULTY_HEX[diff], suggested), fit
end

-- Progress pips: one circle per step. Filled = done, ringed = current,
-- gold ring with a slash = skipped, dim ring = still to do. Long chains fall
-- back to "n/N". Textures are tinted white TGAs in Media/.
local MEDIA = "Interface\\AddOns\\BagQuests\\Media\\"
local PIP = "|T" .. MEDIA .. "%s:%d:%d:0:0:32:32:0:32:0:32:%d:%d:%d|t"
local SKIP_RGB, LATER_RGB = { 201, 162, 39 }, { 110, 110, 110 }
Tracker.MAX_PIPS = 12

function Tracker.Pips(r)
  if r.total > Tracker.MAX_PIPS then return string.format("|cff888888%d/%d|r", r.current or r.total, r.total) end
  local tr, tg, tb = rgb(theme().title)
  local out = {}
  for i, e in ipairs(r.steps) do
    local tex, c = "ring", LATER_RGB
    local themed = { tr * 255, tg * 255, tb * 255 }
    if e.skipped then tex, c = "ring-skip", SKIP_RGB
    elseif i == r.current then tex, c = "ring", themed
    elseif e.state == ns.Domain.STEP.DONE then tex, c = "dot", themed end
    local size = (i == r.current) and 9 or 8
    table.insert(out, string.format(PIP, tex, size, size, math.floor(c[1]), math.floor(c[2]), math.floor(c[3])))
  end
  return table.concat(out, "")
end

-- " 12 slots" after the questline title: how big the reward bag is.
function Tracker.SlotsText(line)
  if not line.slots then return "" end
  return string.format("  |cffbbbbbb%d slots|r", line.slots)
end

-- Pure text for one questline result, so tests can check it without frames.
function Tracker.Lines(r, level)
  local s = r.steps[r.current].step
  local out = {
    string.format("|cff%s%s|r%s  %s", theme().title, r.line.title, Tracker.SlotsText(r.line), Tracker.Pips(r)),
    string.format("%s", s.title),
    (Tracker.LevelLine(r.line, s, level)),
    s.mapID and string.format("|cffbbbbbb%s %.1f, %.1f|r", zoneName(s.mapID), s.x or 0, s.y or 0)
      or string.format("|cffbbbbbb%s|r", s.where or "No map pin for this step"),
  }
  if s.object then table.insert(out, "|cffbbbbbbClick:|r " .. s.object) end
  if s.npc then table.insert(out, "|cffbbbbbbTalk to:|r " .. s.npc) end
  if s.hint then table.insert(out, "|cff" .. theme().hint .. s.hint .. "|r") end
  if s.reward then table.insert(out, "|cff66ff66Reward: " .. s.reward .. "|r") end
  return out
end

-- Mouse-button icons for the tooltip; plain words where the atlas is missing.
local function mouseIcon(which)
  local atlas = "newplayertutorial-icon-mouse-" .. which .. "button"
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
    return "|A:" .. atlas .. ":16:12|a "
  end
  return which == "left" and "|cffffd100Left-click:|r " or "|cffffd100Right-click:|r "
end

function Tracker.TooltipLines(r)
  local out = {
    mouseIcon("left") .. "Set waypoint",
    mouseIcon("right") .. "Skip this step",
  }
  local skipped = 0
  for _, e in ipairs(r.steps) do if e.skipped then skipped = skipped + 1 end end
  if skipped > 0 then
    table.insert(out, "|cff999999Shift +|r " .. mouseIcon("right") ..
      string.format("Undo skip |cffc9a227(%d skipped)|r", skipped))
  end
  local s = r.current and r.steps[r.current].step
  table.insert(out, string.format("|cff999999Required level %d, suggested level %d|r",
    r.line.minLevel, s and s.suggested or r.line.minLevel))
  table.insert(out, string.format("|cff999999Step %d of %d|r", r.current or r.total, r.total))
  return out
end

local function showTooltip(b)
  if not (b.result and GameTooltip) then return end
  GameTooltip:SetOwner(b, "ANCHOR_LEFT")
  local tr, tg, tb = rgb(theme().title)
  GameTooltip:SetText(b.result.line.title, tr, tg, tb)
  for _, l in ipairs(Tracker.TooltipLines(b.result)) do GameTooltip:AddLine(l, 1, 1, 1) end
  GameTooltip:Show()
end

local function buildRow()
  local b = CreateFrame("Button", nil, content)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("TOPLEFT", 2, -2); b.text:SetJustifyH("LEFT")
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(); win:AddHighlight(hl)
  -- Waypoint arrow at the right edge: shown on hover and on the step you're
  -- navigating to. A colored edge marks that step too.
  b.arrow = b:CreateTexture(nil, "OVERLAY")
  b.arrow:SetSize(14, 14); b.arrow:SetPoint("TOPRIGHT", -2, -3)
  b.arrow:SetTexture(MEDIA .. "arrow")
  b.arrow:Hide()
  b.edge = b:CreateTexture(nil, "ARTWORK")
  b.edge:SetPoint("TOPLEFT"); b.edge:SetPoint("BOTTOMLEFT"); b.edge:SetWidth(2)
  b.edge:Hide()
  -- Left-click: waypoint. Right-click: skip (RestedXP style). Shift-right: undo.
  if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
  win:ForwardDrag(b)
  b:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      if not self.result then return end
      if IsShiftKeyDown and IsShiftKeyDown() then ns.App.UnskipStep(self.result)
      else ns.App.SkipStep(self.result) end
    elseif self.step then
      if ns.Waypoints.Set(self.step) then Tracker.navStep = self.step; Tracker.Relayout() end
    end
  end)
  b:SetScript("OnEnter", function(self) self.arrow:Show(); showTooltip(self) end)
  b:SetScript("OnLeave", function(self)
    if self.step ~= Tracker.navStep then self.arrow:Hide() end
    if GameTooltip then GameTooltip:Hide() end
  end)
  return b
end

function Tracker.Init(settings)
  win = Window.New({
    name = "BagQuestsTracker", title = "BagQuests", store = settings,
    defaultPoint = { "RIGHT", "RIGHT", -40, 120 }, defaultSize = { DEFAULT_W, 120 },
    bounds = { 200, 80, 640, 900 },
    isLocked = function() return settings.locked end,
    onClose = function() Tracker.Toggle(settings) end,
    onResize = function() Tracker.Relayout() end,
    onTheme = function() Tracker.Relayout() end,
  })
  frame, content = win.frame, win.content
  rows, separators = {}, {}
  for i = 1, MAX_LINES do
    rows[i] = buildRow()
    local sep = content:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1); sep:SetColorTexture(1, 1, 1, 0.08); sep:Hide()
    separators[i] = sep
  end
  Window.SetTheme(settings.theme)
end

-- Recolor every window for a scheme. Text colors apply on the next Render.
function Tracker.ApplyTheme(key) return Window.SetTheme(key) end

function Tracker.RowAt(i) return rows and rows[i] end -- tests
function Tracker.Grip() return win and win.grip end -- tests

-- Lay out the rows inside the scroll area. Returns the content height.
local function layout(workable, level, locked)
  local w = win:ContentWidth()
  content:SetWidth(w)
  local y = 0
  local shown = 0
  for i = 1, MAX_LINES do
    local b, r, sep = rows[i], workable[i], separators[i]
    sep:Hide()
    if r then
      if shown > 0 then
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y - 3)
        sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y - 3)
        sep:Show()
        y = y + 7
      end
      b.step, b.result = r.steps[r.current].step, r
      b.text:SetWidth(w - 22) -- room for the waypoint arrow
      local nav = Tracker.navStep ~= nil and b.step == Tracker.navStep
      local er, eg, eb = rgb(theme().title)
      b.arrow:SetVertexColor(er, eg, eb); b.edge:SetColorTexture(er, eg, eb, 0.9)
      if nav then b.arrow:Show(); b.edge:Show() else b.arrow:Hide(); b.edge:Hide() end
      b.text:SetText(table.concat(Tracker.Lines(r, level), "\n"))
      local h = num(b.text:GetStringHeight(), 60) + 6
      b:SetSize(w, h)
      b:ClearAllPoints(); b:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
      y = y + h
      shown = shown + 1
      b:Show()
    else
      b:Hide()
    end
  end
  lockedText = lockedText or content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  local parts = {}
  for _, r in ipairs(locked) do table.insert(parts, string.format("%s%s: unlocks at %d", r.line.title,
    r.line.slots and string.format(" (%d slots)", r.line.slots) or "", r.line.minLevel)) end
  if #parts > 0 then
    if shown > 0 then y = y + 6 end
    lockedText:ClearAllPoints(); lockedText:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -y)
    lockedText:SetJustifyH("LEFT"); lockedText:SetWidth(w - 4)
    lockedText:SetText(table.concat(parts, "\n")); lockedText:Show()
    y = y + num(lockedText:GetStringHeight(), 14 * #parts) + 4
  else
    lockedText:Hide()
  end
  content:SetHeight(math.max(y, 1))
  return y, shown
end

-- Re-flow the text after a resize, using the last data we rendered.
function Tracker.Relayout()
  if not (frame and lastArgs) or Tracker._inLayout then return end
  Tracker._inLayout = true
  local a = lastArgs
  layout(a.workable, a.level, a.locked)
  Tracker._inLayout = false
end

-- workable = lines with a current step; locked = too-low lines (shown dim).
function Tracker.Render(workable, settings, level, locked)
  if not frame then return end
  locked = locked or {}
  lastArgs = { workable = workable, level = level, locked = locked }
  if not settings.tracker or (#workable == 0 and #locked == 0) then frame:Hide(); return end

  win:UpdateGrip()
  win:SetRightText(#workable > 0 and string.format("%d active", #workable) or "")

  Tracker._inLayout = true
  local h = layout(workable, level, locked)
  win:AutoFit(nil, h, AUTO_MAX_H) -- fits height until the player resizes it
  Tracker._inLayout = false
  frame:Show()
end

-- Back to the default spot, width and auto-fit height.
function Tracker.Reset(settings)
  settings.point, settings.size = nil, nil
  if not win then return end
  win:Reset()
  ns.App.Refresh()
end

function Tracker.Toggle(settings)
  settings.tracker = not settings.tracker
  ns.App.Refresh()
  return settings.tracker
end
