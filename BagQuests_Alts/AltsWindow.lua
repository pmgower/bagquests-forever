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

local function build()
  frame = CreateFrame("Frame", "BagQuestsAltsWindow", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(480, 300)
  frame:SetPoint("CENTER")
  frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  if type(frame.TitleText) == "table" then frame.TitleText:SetText("BagQuests: alts") end
  tinsert(UISpecialFrames, "BagQuestsAltsWindow") -- Esc closes it
  frame:Hide() -- new frames start shown; Toggle below expects hidden
end

local function cell(r, c)
  cells[r] = cells[r] or {}
  local fs = cells[r][c]
  if not fs then
    fs = frame:CreateFontString(nil, "OVERLAY", r == 1 and "GameFontNormalSmall" or "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    cells[r][c] = fs
  end
  return fs
end

function AltsWindow.Render()
  local opts = BagQuestsAltsDB.settings or {}
  local grid = AltsWindow.Grid(BagQuestsAltsDB.characters, App.Domain, opts)
  local width = 24
  for c = 1, #grid[1] do width = width + (COL[c] or 120) end
  if opts.hideSurnames then width = width - 60 end
  for _, row in pairs(cells) do for _, fs in pairs(row) do fs:Hide() end end
  for r, row in ipairs(grid) do
    local x = 12
    for c, text in ipairs(row) do
      local w = COL[c] or 120
      if c == 1 and opts.hideSurnames then w = w - 60 end
      local fs = cell(r, c)
      fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -32 - (r - 1) * 18)
      fs:SetWidth(w); fs:SetText(text); fs:Show()
      x = x + w
    end
  end
  frame:SetHeight(48 + #grid * 18)
  frame:SetWidth(width)
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
