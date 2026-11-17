-- FeedbackWindow: /bq feedback. WoW chat can't be copied, so the issue link
-- and the report go in two read-only edit boxes the player can Ctrl+C from.
-- Same themed frame as the tracker and alts table (UI/Window.lua).
local _, ns = ...
local FeedbackWindow = {}
ns.FeedbackWindow = FeedbackWindow

local win, urlBox, reportBox, labels, boxBgs = nil, nil, nil, {}, {}
local LABEL_H, URL_H, GAP = 16, 20, 6

-- An edit box that selects everything on focus and undoes any typing, so
-- the text stays exactly what we generated.
local function readOnly(box)
  box:SetAutoFocus(false)
  box:SetFontObject("ChatFontNormal")
  box:SetTextInsets(4, 4, 3, 3)
  box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); win.frame:Hide() end)
  box:SetScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(self.fixedText or ""); self:HighlightText() end
    FeedbackWindow.Relayout()
  end)
  box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
  -- A faint panel behind the text, so it reads as something to select.
  local bg = box:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  table.insert(boxBgs, bg)
  return box
end

local function setFixed(box, text) box.fixedText = text; box:SetText(text) end

local function label(text)
  local fs = win.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  table.insert(labels, fs)
  return fs
end

local function applyTheme(theme)
  local r, g, b = ns.Window.Rgb(theme.title)
  for _, fs in ipairs(labels) do fs:SetTextColor(r, g, b) end
  for _, bg in ipairs(boxBgs) do bg:SetColorTexture(theme.edge[1], theme.edge[2], theme.edge[3], 0.12) end
end

-- Stack: label, link box, label, report box. Widths follow the window.
function FeedbackWindow.Relayout()
  if not (win and reportBox) then return end
  local w = win:ContentWidth()
  local c, y = win.content, -2
  labels[1]:ClearAllPoints(); labels[1]:SetPoint("TOPLEFT", c, "TOPLEFT", 0, y); labels[1]:SetWidth(w)
  y = y - LABEL_H
  urlBox:ClearAllPoints(); urlBox:SetPoint("TOPLEFT", c, "TOPLEFT", 0, y); urlBox:SetSize(w, URL_H)
  y = y - URL_H - GAP * 2
  labels[2]:ClearAllPoints(); labels[2]:SetPoint("TOPLEFT", c, "TOPLEFT", 0, y); labels[2]:SetWidth(w)
  y = y - LABEL_H
  reportBox:ClearAllPoints(); reportBox:SetPoint("TOPLEFT", c, "TOPLEFT", 0, y); reportBox:SetWidth(w)
  local reportH = ns.Window.Num(reportBox:GetHeight(), 200)
  c:SetSize(w, -y + reportH + GAP)
end

local function build()
  win = ns.Window.New({
    name = "BagQuestsFeedbackWindow", title = "BagQuests: report a problem", store = {},
    defaultPoint = { "CENTER", "CENTER", 0, 0 }, defaultSize = { 540, 380 },
    bounds = { 360, 200, 1000, 900 },
    onResize = function() FeedbackWindow.Relayout() end,
    onTheme = function(theme) applyTheme(theme) end,
  })
  win.frame:SetFrameStrata("DIALOG")
  tinsert(UISpecialFrames, "BagQuestsFeedbackWindow") -- Esc closes it

  label("1. Copy this link (Ctrl+C) into your browser:")
  urlBox = readOnly(CreateFrame("EditBox", nil, win.content))
  label("2. Copy this report (Ctrl+C) and paste it into the issue:")
  reportBox = readOnly(CreateFrame("EditBox", nil, win.content))
  reportBox:SetMultiLine(true)
  applyTheme(ns.Window.Current())
  win.frame:Hide() -- new frames start shown; Show below decides
end

-- Opens the window with the link and report, report selected and ready to copy.
function FeedbackWindow.Show(url, report)
  if not win then build() end
  FeedbackWindow.url, FeedbackWindow.report = url, report -- for tests
  setFixed(urlBox, url)
  setFixed(reportBox, report)
  FeedbackWindow.Relayout()
  win.frame:Show()
  reportBox:SetFocus()
  reportBox:HighlightText()
end

function FeedbackWindow.IsShown() return win ~= nil and win.frame:IsShown() end
