-- Tracker: RestedXP-style guide window with the next step for each questline.
-- A bordered, movable, resizable window: header with title and close button,
-- a scrolling list of steps, and a size grip in the bottom-right corner.
local _, ns = ...
local Tracker = {}
ns.Tracker = Tracker

local MAX_LINES = 4
local DEFAULT_W = 270
local MIN_W, MIN_H, MAX_W, MAX_H = 200, 80, 640, 900
local AUTO_MAX_H = 520     -- auto-fit height cap until the player resizes it
local HEADER_H, PAD, GRIP_PAD = 24, 10, 14

local frame, scroll, content, grip, header, countText, rows, separators, lockedText
local lastArgs -- last Render() arguments, so a resize can re-lay out the rows
local titleText, headerLine, highlights = nil, nil, {}

-- Color schemes (switch with /bq theme). Colors are 0-1 RGB(A); hex strings
-- are for |c escapes in text.
Tracker.THEMES = {
  { key = "deepwater", name = "Deepwater", bg = { 0.04, 0.09, 0.10, 0.90 }, edge = { 0.25, 0.65, 0.63 },
    title = "7fe3d8", hint = "8fd6ff" },
  { key = "frost", name = "Frost Steel", bg = { 0.05, 0.07, 0.11, 0.90 }, edge = { 0.50, 0.61, 0.76 },
    title = "b9d3f5", hint = "9fd0ff" },
  { key = "twilight", name = "Twilight", bg = { 0.08, 0.05, 0.12, 0.90 }, edge = { 0.56, 0.45, 0.84 },
    title = "cdb9ff", hint = "a8d8ff" },
  { key = "classic", name = "Classic Black", bg = { 0, 0, 0, 0.78 }, edge = { 0.42, 0.42, 0.42 },
    title = "ffd100", hint = "9fd0ff" },
}
Tracker.DEFAULT_THEME = "deepwater"

function Tracker.Theme(key)
  for _, t in ipairs(Tracker.THEMES) do if t.key == key then return t end end
  return Tracker.THEMES[1]
end
local theme = Tracker.Theme(Tracker.DEFAULT_THEME)

local function rgb(hex)
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function num(v, default) return tonumber(v) or default end

local function zoneName(mapID)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
  return info and info.name or ("map " .. tostring(mapID))
end

local FIT_TEXT = {
  ok = "|cff66ff66good level for you|r",
  low = "|cffffcc00a bit low for you|r",
  blocked = "|cffff6060too low to start|r",
}

-- "Req 14 · Suggested 24 · you 20 (a bit low)" colored by fit.
function Tracker.LevelLine(line, step, level)
  local fit = ns.Domain.LevelFit(line, step, level)
  return string.format("|cffbbbbbbReq %d  Suggested %d  You %d|r  %s",
    line.minLevel, step.suggested or line.minLevel, level or 0, FIT_TEXT[fit]), fit
end

-- Pure text for one questline result, so tests can check it without frames.
function Tracker.Lines(r, level)
  local s = r.steps[r.current].step
  local out = {
    string.format("|cff%s%s|r  |cff888888%d/%d|r", theme.title, r.line.title, r.current, r.total),
    string.format("%s", s.title),
    (Tracker.LevelLine(r.line, s, level)),
    s.mapID and string.format("|cffbbbbbb%s %.1f, %.1f|r", zoneName(s.mapID), s.x or 0, s.y or 0)
      or string.format("|cffbbbbbb%s|r", s.where or "No map pin for this step"),
  }
  if s.object then table.insert(out, "|cffbbbbbbClick:|r " .. s.object) end
  if s.npc then table.insert(out, "|cffbbbbbbTalk to:|r " .. s.npc) end
  if s.hint then table.insert(out, "|cff" .. theme.hint .. s.hint .. "|r") end
  if s.reward then table.insert(out, "|cff66ff66Reward: " .. s.reward .. "|r") end
  return out
end

-- Modern clients have SetResizeBounds; older ones SetMinResize/SetMaxResize.
local function setResizeBounds(f)
  if f.SetResizeBounds then
    f:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
  else
    if f.SetMinResize then f:SetMinResize(MIN_W, MIN_H) end
    if f.SetMaxResize then f:SetMaxResize(MAX_W, MAX_H) end
  end
end

local function savePosition(settings)
  local p, _, rp, x, y = frame:GetPoint()
  settings.point = { p, nil, rp, x, y }
end

local function contentWidth()
  return num(frame:GetWidth(), DEFAULT_W) - PAD * 2
end

local function applyBackdrop(f)
  if not f.SetBackdrop then return end
  f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
end

-- Recolor the window for a scheme. Text colors apply on the next Render.
function Tracker.ApplyTheme(key)
  theme = Tracker.Theme(key)
  if not frame then return theme end
  if frame.SetBackdropColor then
    frame:SetBackdropColor(theme.bg[1], theme.bg[2], theme.bg[3], theme.bg[4])
    frame:SetBackdropBorderColor(theme.edge[1], theme.edge[2], theme.edge[3], 1)
  end
  local r, g, b = rgb(theme.title)
  titleText:SetTextColor(r, g, b)
  headerLine:SetColorTexture(theme.edge[1], theme.edge[2], theme.edge[3], 0.55)
  for _, hl in ipairs(highlights) do hl:SetColorTexture(r, g, b, 0.10) end
  return theme
end

local function buildHeader(settings)
  header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT", 4, -4); header:SetPoint("TOPRIGHT", -4, -4)
  header:SetHeight(HEADER_H - 4)
  local bg = header:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(); bg:SetColorTexture(1, 1, 1, 0.06)
  local icon = header:CreateTexture(nil, "ARTWORK")
  icon:SetSize(14, 14); icon:SetPoint("LEFT", 6, 0)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  titleText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
  titleText:SetText("BagQuests")
  local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
  close:SetSize(20, 20); close:SetPoint("RIGHT", 2, 0)
  close:SetScript("OnClick", function() Tracker.Toggle(settings) end)
  countText = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  countText:SetPoint("RIGHT", close, "LEFT", -2, 0)
  headerLine = frame:CreateTexture(nil, "ARTWORK")
  headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
  headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
  headerLine:SetHeight(1)
end

local function buildGrip(settings)
  grip = CreateFrame("Button", nil, frame)
  grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", -3, 3)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight", "ADD")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" and not settings.locked then frame:StartSizing("BOTTOMRIGHT") end
  end)
  grip:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    settings.size = { num(frame:GetWidth(), DEFAULT_W), num(frame:GetHeight(), 200) }
    savePosition(settings)
    Tracker.Relayout()
  end)
end

local function buildScroll()
  scroll = CreateFrame("ScrollFrame", nil, frame)
  scroll:SetPoint("TOPLEFT", PAD, -(HEADER_H + 4))
  scroll:SetPoint("BOTTOMRIGHT", -PAD, GRIP_PAD)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(DEFAULT_W - PAD * 2, 10)
  scroll:SetScrollChild(content)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local max = num(self:GetVerticalScrollRange(), 0)
    local v = num(self:GetVerticalScroll(), 0) - delta * 30
    self:SetVerticalScroll(math.max(0, math.min(max, v)))
  end)
end

local function buildRow()
  local b = CreateFrame("Button", nil, content)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("TOPLEFT", 2, -2); b.text:SetJustifyH("LEFT")
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(); table.insert(highlights, hl)
  -- Left-click: waypoint. Right-click: skip this step (RestedXP style).
  if b.RegisterForClicks then b:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
  b:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      if self.result then ns.App.SkipStep(self.result) end
    elseif self.step then
      ns.Waypoints.Set(self.step)
    end
  end)
  return b
end

function Tracker.Init(settings)
  frame = CreateFrame("Frame", "BagQuestsTracker", UIParent, "BackdropTemplate")
  local size = settings.size
  frame:SetSize(size and size[1] or DEFAULT_W, size and size[2] or 120)
  if settings.point then
    frame:SetPoint(settings.point[1], UIParent, settings.point[3], settings.point[4], settings.point[5])
  else
    frame:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
  end
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  applyBackdrop(frame)
  frame:SetMovable(true); frame:SetResizable(true); setResizeBounds(frame)
  frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(f) if not settings.locked then f:StartMoving() end end)
  frame:SetScript("OnDragStop", function(f)
    f:StopMovingOrSizing()
    savePosition(settings)
  end)
  -- Live re-wrap while the grip is dragged.
  frame:SetScript("OnSizeChanged", function() Tracker.Relayout() end)

  buildHeader(settings)
  buildScroll()
  buildGrip(settings)

  rows, separators = {}, {}
  for i = 1, MAX_LINES do
    rows[i] = buildRow()
    local sep = content:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1); sep:SetColorTexture(1, 1, 1, 0.08); sep:Hide()
    separators[i] = sep
  end
  Tracker.ApplyTheme(settings.theme)
end

function Tracker.RowAt(i) return rows and rows[i] end -- tests
function Tracker.Grip() return grip end -- tests

-- Lay out the rows inside the scroll area. Returns the content height.
local function layout(workable, level, locked)
  local w = contentWidth()
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
      b.text:SetWidth(w - 4)
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
  for _, r in ipairs(locked) do table.insert(parts, string.format("%s: unlocks at %d", r.line.title, r.line.minLevel)) end
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

  if settings.locked then grip:Hide() else grip:Show() end
  countText:SetText(#workable > 0 and string.format("%d active", #workable) or "")

  Tracker._inLayout = true
  local h = layout(workable, level, locked)
  -- Until the player sizes the window themselves, fit it to the content.
  if not settings.size then
    frame:SetHeight(math.max(MIN_H, math.min(AUTO_MAX_H, h + HEADER_H + 4 + GRIP_PAD)))
  end
  Tracker._inLayout = false
  frame:Show()
end

-- Back to the default spot, width and auto-fit height.
function Tracker.Reset(settings)
  settings.point, settings.size = nil, nil
  if not frame then return end
  frame:ClearAllPoints()
  frame:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
  frame:SetWidth(DEFAULT_W)
  ns.App.Refresh()
end

function Tracker.Toggle(settings)
  settings.tracker = not settings.tracker
  ns.App.Refresh()
  return settings.tracker
end
