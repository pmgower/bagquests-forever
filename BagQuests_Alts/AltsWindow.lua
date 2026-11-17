-- AltsWindow: one row per character, one column per bag questline.
local _, ns = ...
local AltsWindow = {}
ns.AltsWindow = AltsWindow

local App = _G.BagQuests
local frame, cells = nil, {}
local COLORS = {
  done = "|cff66ff66", in_progress = "|cffffff00", available = "|cffffffff",
  too_low = "|cff888888", wrong_faction = "|cff555555",
}

-- Text grid (header + rows) so tests can check content without frames.
-- "First Second" by default; opts.hideSurnames shows just the first name.
function AltsWindow.DisplayName(char, opts)
  if char.surname and not (opts and opts.hideSurnames) then return char.name .. " " .. char.surname end
  return char.name
end

-- Only the questlines the player tracks get a column.
local function shownLines(Domain)
  if App and App.Lines then return App.Lines() end
  return Domain.All()
end

function AltsWindow.Grid(store, Domain, opts)
  local lines = shownLines(Domain)
  local header = { "Character", "Lvl" }
  for _, line in ipairs(lines) do table.insert(header, line.title) end
  local grid = { header }
  for _, row in ipairs(ns.Roster.Rows(store, Domain, lines)) do
    local cls = row.char.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[row.char.class]
    local shown = AltsWindow.DisplayName(row.char, opts)
    local name = cls and cls.colorStr and ("|c" .. cls.colorStr .. shown .. "|r") or shown
    local out = { name, tostring(row.char.level or "?") }
    for _, cell in ipairs(row.cells) do
      local left = ""
      if cell.status == "in_progress" or cell.status == "available" then
        left = " (" .. cell.left .. " left)"
        if cell.fit == "low" then left = left .. " |cffffcc00sugg " .. cell.suggested .. "|r" end
      end
      table.insert(out, (COLORS[cell.status] or "") .. cell.text .. left .. "|r")
    end
    table.insert(grid, out)
  end
  return grid
end

local COL = { 170, 34, 150, 150, 150, 150 }
local ROW_H = 18

-- Same window frame as the tracker (border, title bar, theme, resize grip),
-- from BagQuests' shared UI/Window.lua.
local win, stripes, headerLine = nil, {}, nil
local lastGrid, lastOpts

local function store()
  BagQuestsAltsDB.settings = BagQuestsAltsDB.settings or {}
  BagQuestsAltsDB.settings.window = BagQuestsAltsDB.settings.window or {}
  return BagQuestsAltsDB.settings.window
end

local function build()
  win = App.Window.New({
    name = "BagQuestsAltsWindow", title = "BagQuests Alts", store = store(),
    defaultPoint = { "CENTER", "CENTER", 0, 0 }, defaultSize = { 480, 200 },
    bounds = { 260, 100, 1400, 900 },
    isLocked = function() return App.Settings and App.Settings().locked end,
    onResize = function() AltsWindow.Relayout() end,
    onTheme = function() AltsWindow.Relayout() end,
  })
  frame = win.frame
  tinsert(UISpecialFrames, "BagQuestsAltsWindow") -- Esc closes it
  frame:Hide() -- new frames start shown; Toggle below expects hidden
end

local function cell(r, c)
  cells[r] = cells[r] or {}
  local fs = cells[r][c]
  if not fs then
    fs = win.content:CreateFontString(nil, "OVERLAY", r == 1 and "GameFontNormalSmall" or "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    cells[r][c] = fs
  end
  return fs
end

-- Every other row gets a faint stripe so wide rows are easy to follow.
local function stripe(r)
  local t = stripes[r]
  if not t then
    t = win.content:CreateTexture(nil, "BACKGROUND")
    t:SetColorTexture(1, 1, 1, 0.04)
    stripes[r] = t
  end
  return t
end

local function layout(grid, opts)
  local content = win.content
  local width = 0
  for c = 1, #grid[1] do width = width + (COL[c] or 120) end
  if opts.hideSurnames then width = width - 60 end
  for _, row in pairs(cells) do for _, fs in pairs(row) do fs:Hide() end end
  for _, t in pairs(stripes) do t:Hide() end
  local tr, tg, tb = App.Window.Rgb(App.Window.Current().title)
  for r, row in ipairs(grid) do
    local x, y = 2, -(r - 1) * ROW_H - (r > 1 and 4 or 0)
    if r > 1 and r % 2 == 1 then
      local t = stripe(r)
      t:ClearAllPoints(); t:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y + 2)
      t:SetSize(width + 4, ROW_H); t:Show()
    end
    for c, text in ipairs(row) do
      local w = COL[c] or 120
      if c == 1 and opts.hideSurnames then w = w - 60 end
      local fs = cell(r, c)
      fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
      fs:SetWidth(w - 6); fs:SetText(text); fs:Show()
      if r == 1 then fs:SetTextColor(tr, tg, tb) end
      x = x + w
    end
  end
  headerLine = headerLine or content:CreateTexture(nil, "ARTWORK")
  local e = App.Window.Current().edge
  headerLine:SetColorTexture(e[1], e[2], e[3], 0.45)
  headerLine:ClearAllPoints(); headerLine:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -ROW_H + 2)
  headerLine:SetSize(width + 4, 1)
  local height = #grid * ROW_H + 8
  content:SetSize(width + 4, height)
  return width + 4, height
end

function AltsWindow.Relayout()
  if not (win and lastGrid) or AltsWindow._inLayout then return end
  AltsWindow._inLayout = true
  layout(lastGrid, lastOpts)
  AltsWindow._inLayout = false
end

function AltsWindow.Render()
  local opts = BagQuestsAltsDB.settings or {}
  local grid = AltsWindow.Grid(BagQuestsAltsDB.characters, App.Domain, opts)
  lastGrid, lastOpts = grid, opts
  win:UpdateGrip()
  win:SetRightText(string.format("%d characters", #grid - 1))
  AltsWindow._inLayout = true
  local w, h = layout(grid, opts)
  win:AutoFit(w, h) -- fits the table until the player resizes the window
  AltsWindow._inLayout = false
end

function AltsWindow.Toggle()
  BagQuestsAltsDB = BagQuestsAltsDB or { characters = {} }
  if not frame then build() end
  if frame:IsShown() then frame:Hide() else App.Refresh(); AltsWindow.Render(); frame:Show() end
end

function AltsWindow.IsShown() return frame ~= nil and frame:IsShown() end

function AltsWindow.RefreshIfShown()
  if frame and frame:IsShown() then AltsWindow.Render() end
end

if App then
  App.RegisterCommand("alts", AltsWindow.Toggle, "Show bag questline progress for every character")
end
