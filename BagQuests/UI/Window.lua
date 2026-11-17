-- Window: the shared BagQuests window frame (tracker, alts table).
-- A bordered, themed, movable and resizable window with a title bar
-- (bag icon, title, version, right-hand text, close button), a scrolling
-- content area and a size grip in the bottom-right corner. Size and position
-- persist in the store table each window is given.
local _, ns = ...
local Window = {}
ns.Window = Window
if ns.App then ns.App.Window = Window end -- for BagQuests_Alts

local MEDIA = "Interface\\AddOns\\BagQuests\\Media\\"
local HEADER_H, PAD, GRIP_PAD = 24, 10, 14
Window.HEADER_H, Window.PAD, Window.GRIP_PAD = HEADER_H, PAD, GRIP_PAD
Window.CHROME_H = HEADER_H + 4 + GRIP_PAD -- height that isn't content

-- Color schemes (switch with /bq theme). Colors are 0-1 RGB(A); hex strings
-- are for |c escapes in text.
Window.THEMES = {
  { key = "frost", name = "Frost Steel", bg = { 0.05, 0.07, 0.11, 0.90 }, edge = { 0.50, 0.61, 0.76 },
    title = "b9d3f5", hint = "9fd0ff" },
  { key = "deepwater", name = "Deepwater", bg = { 0.04, 0.09, 0.10, 0.90 }, edge = { 0.25, 0.65, 0.63 },
    title = "7fe3d8", hint = "8fd6ff" },
  { key = "twilight", name = "Twilight", bg = { 0.08, 0.05, 0.12, 0.90 }, edge = { 0.56, 0.45, 0.84 },
    title = "cdb9ff", hint = "a8d8ff" },
  { key = "classic", name = "Classic Black", bg = { 0, 0, 0, 0.78 }, edge = { 0.42, 0.42, 0.42 },
    title = "ffd100", hint = "9fd0ff" },
}
Window.DEFAULT_THEME = "frost"

function Window.Theme(key)
  for _, t in ipairs(Window.THEMES) do if t.key == key then return t end end
  return Window.THEMES[1]
end

local theme = Window.Theme(Window.DEFAULT_THEME)
local windows = {}

function Window.Current() return theme end

function Window.Rgb(hex)
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function num(v, default) return tonumber(v) or default end
Window.Num = num

-- Recolor every BagQuests window for a scheme.
function Window.SetTheme(key)
  theme = Window.Theme(key)
  for _, w in ipairs(windows) do w:ApplyTheme() end
  return theme
end

local W = {}
W.__index = W

-- opts: name, title, store (table: point, size), defaultPoint {p, rp, x, y},
-- defaultSize {w, h}, bounds {minW, minH, maxW, maxH}, isLocked(), onClose(),
-- onResize(), onTheme().
function Window.New(opts)
  local self = setmetatable({ opts = opts, store = opts.store or {}, highlights = {} }, W)
  local f = CreateFrame("Frame", opts.name, UIParent, "BackdropTemplate")
  self.frame = f
  local size, d = self.store.size, opts.defaultSize or { 270, 120 }
  f:SetSize(size and size[1] or d[1], size and size[2] or d[2])
  self:PlaceDefault(self.store.point)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 14,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
  end
  f:SetMovable(true); f:SetResizable(true)
  local b = opts.bounds or { 200, 80, 640, 900 }
  if f.SetResizeBounds then
    f:SetResizeBounds(b[1], b[2], b[3], b[4]) -- modern clients
  else
    if f.SetMinResize then f:SetMinResize(b[1], b[2]) end
    if f.SetMaxResize then f:SetMaxResize(b[3], b[4]) end
  end
  self:ForwardDrag(f)
  -- Live re-flow while the grip is dragged.
  f:SetScript("OnSizeChanged", function() if opts.onResize then opts.onResize() end end)

  self:BuildHeader()
  self:BuildScroll()
  self:BuildGrip()
  -- Title bar and grip sit above the list so nothing in it takes their clicks.
  local base = num(f:GetFrameLevel(), 1)
  self.header:SetFrameLevel(base + 10); self.grip:SetFrameLevel(base + 10)

  table.insert(windows, self)
  self:ApplyTheme()
  return self
end

function W:PlaceDefault(point)
  local f, p = self.frame, point or self.opts.defaultPoint or { "CENTER", "CENTER", 0, 0 }
  f:ClearAllPoints()
  if point then f:SetPoint(p[1], UIParent, p[3], p[4], p[5])
  else f:SetPoint(p[1], UIParent, p[2], p[3], p[4]) end
end

function W:IsLocked() return self.opts.isLocked and self.opts.isLocked() or false end

function W:SavePosition()
  local p, _, rp, x, y = self.frame:GetPoint()
  self.store.point = { p, nil, rp, x, y }
end

-- The whole window drags: the frame, the title bar and any rows forward a
-- left-drag here. Without this a drag that starts on a child is swallowed.
function W:ForwardDrag(child)
  child:EnableMouse(true)
  child:RegisterForDrag("LeftButton")
  child:SetScript("OnDragStart", function() if not self:IsLocked() then self.frame:StartMoving() end end)
  child:SetScript("OnDragStop", function() self.frame:StopMovingOrSizing(); self:SavePosition() end)
end

function W:BuildHeader()
  local f = self.frame
  local header = CreateFrame("Frame", nil, f)
  self.header = header
  header:SetPoint("TOPLEFT", 4, -4); header:SetPoint("TOPRIGHT", -4, -4)
  header:SetHeight(HEADER_H - 4)
  self:ForwardDrag(header)
  local bg = header:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(); bg:SetColorTexture(1, 1, 1, 0.06)
  local icon = header:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18); icon:SetPoint("LEFT", 3, 0)
  icon:SetTexture(MEDIA .. "bag")
  self.titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.titleText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
  self.titleText:SetText(self.opts.title or "BagQuests")
  local ver = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  ver:SetPoint("LEFT", self.titleText, "RIGHT", 5, 0)
  ver:SetText("v" .. tostring(ns.App and ns.App.VERSION or "?"))
  if ver.SetScale then ver:SetScale(0.9) end
  local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
  close:SetSize(20, 20); close:SetPoint("RIGHT", 2, 0)
  close:SetScript("OnClick", function()
    if self.opts.onClose then self.opts.onClose() else f:Hide() end
  end)
  self.closeButton = close
  self.rightText = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.rightText:SetPoint("RIGHT", close, "LEFT", -2, 0)
  self.headerLine = f:CreateTexture(nil, "ARTWORK")
  self.headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
  self.headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
  self.headerLine:SetHeight(1)
end

function W:BuildScroll()
  local scroll = CreateFrame("ScrollFrame", nil, self.frame)
  self.scroll = scroll
  scroll:SetPoint("TOPLEFT", PAD, -(HEADER_H + 4))
  scroll:SetPoint("BOTTOMRIGHT", -PAD, GRIP_PAD)
  self.content = CreateFrame("Frame", nil, scroll)
  self.content:SetSize(200, 10)
  scroll:SetScrollChild(self.content)
  scroll:EnableMouseWheel(true)
  -- Wheel scrolls up and down; shift-wheel scrolls sideways (wide tables).
  scroll:SetScript("OnMouseWheel", function(s, delta)
    if IsShiftKeyDown and IsShiftKeyDown() then
      local max = num(s:GetHorizontalScrollRange(), 0)
      s:SetHorizontalScroll(math.max(0, math.min(max, num(s:GetHorizontalScroll(), 0) - delta * 40)))
    else
      local max = num(s:GetVerticalScrollRange(), 0)
      s:SetVerticalScroll(math.max(0, math.min(max, num(s:GetVerticalScroll(), 0) - delta * 30)))
    end
  end)
end

function W:BuildGrip()
  local grip = CreateFrame("Button", nil, self.frame)
  self.grip = grip
  grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", -3, 3)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight", "ADD")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" and not self:IsLocked() then self.frame:StartSizing("BOTTOMRIGHT") end
  end)
  grip:SetScript("OnMouseUp", function()
    self.frame:StopMovingOrSizing()
    local d = self.opts.defaultSize or { 270, 120 }
    self.store.size = { num(self.frame:GetWidth(), d[1]), num(self.frame:GetHeight(), d[2]) }
    self:SavePosition()
    if self.opts.onResize then self.opts.onResize() end
  end)
end

-- Width available to content inside the border.
function W:ContentWidth()
  local d = self.opts.defaultSize or { 270, 120 }
  return num(self.frame:GetWidth(), d[1]) - PAD * 2
end

function W:SetRightText(text) self.rightText:SetText(text or "") end

-- Lock hides the grip.
function W:UpdateGrip() if self:IsLocked() then self.grip:Hide() else self.grip:Show() end end

-- Until the player resizes the window, size it to its content.
function W:AutoFit(contentW, contentH, maxH)
  if self.store.size then return end
  local b = self.opts.bounds or { 200, 80, 640, 900 }
  if contentW then self.frame:SetWidth(math.max(b[1], math.min(b[3], contentW + PAD * 2))) end
  if contentH then
    self.frame:SetHeight(math.max(b[2], math.min(maxH or b[4], contentH + Window.CHROME_H)))
  end
end

-- Back to the default spot and auto-fit size.
function W:Reset()
  self.store.point, self.store.size = nil, nil
  self:PlaceDefault(nil)
  local d = self.opts.defaultSize or { 270, 120 }
  self.frame:SetSize(d[1], d[2])
end

-- /bq reset: every window back to its default spot and size.
function Window.ResetAll() for _, w in ipairs(windows) do w:Reset() end end

-- Rows register their highlight so it follows the theme color.
function W:AddHighlight(tex) table.insert(self.highlights, tex); self:ApplyTheme() end

function W:ApplyTheme()
  local f = self.frame
  if f.SetBackdropColor then
    f:SetBackdropColor(theme.bg[1], theme.bg[2], theme.bg[3], theme.bg[4])
    f:SetBackdropBorderColor(theme.edge[1], theme.edge[2], theme.edge[3], 1)
  end
  local r, g, b = Window.Rgb(theme.title)
  if self.titleText then self.titleText:SetTextColor(r, g, b) end
  if self.headerLine then self.headerLine:SetColorTexture(theme.edge[1], theme.edge[2], theme.edge[3], 0.55) end
  for _, hl in ipairs(self.highlights) do hl:SetColorTexture(r, g, b, 0.10) end
  if self.opts.onTheme then self.opts.onTheme(theme) end
end
