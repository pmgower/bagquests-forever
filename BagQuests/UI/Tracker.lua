-- Tracker: RestedXP-style on-screen list of the next step for each questline.
local _, ns = ...
local Tracker = {}
ns.Tracker = Tracker

local MAX_LINES = 4
local frame, rows, lockedText

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
    string.format("|cffe0a040%s|r  %d/%d", r.line.title, r.current, r.total),
    string.format("%s", s.title),
    (Tracker.LevelLine(r.line, s, level)),
    s.mapID and string.format("|cffbbbbbb%s %.1f, %.1f|r", zoneName(s.mapID), s.x or 0, s.y or 0)
      or string.format("|cffbbbbbb%s|r", s.where or "No map pin for this step"),
  }
  if s.object then table.insert(out, "|cffbbbbbbClick:|r " .. s.object) end
  if s.npc then table.insert(out, "|cffbbbbbbTalk to:|r " .. s.npc) end
  if s.hint then table.insert(out, "|cff99ccff" .. s.hint .. "|r") end
  if s.reward then table.insert(out, "|cff66ff66Reward: " .. s.reward .. "|r") end
  return out
end

function Tracker.Init(settings)
  frame = CreateFrame("Frame", "BagQuestsTracker", UIParent, "BackdropTemplate")
  frame:SetSize(260, 40)
  if settings.point then
    frame:SetPoint(settings.point[1], UIParent, settings.point[3], settings.point[4], settings.point[5])
  else
    frame:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
  end
  if frame.SetBackdrop then
    frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
    frame:SetBackdropColor(0, 0, 0, 0.45)
  end
  frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(f) if not settings.locked then f:StartMoving() end end)
  frame:SetScript("OnDragStop", function(f)
    f:StopMovingOrSizing()
    local p, _, rp, x, y = f:GetPoint()
    settings.point = { p, nil, rp, x, y }
  end)
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  title:SetPoint("TOPLEFT", 8, -6)
  title:SetText("BagQuests")
  rows = {}
  for i = 1, MAX_LINES do
    local b = CreateFrame("Button", nil, frame)
    b:SetSize(244, 16)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("TOPLEFT"); b.text:SetJustifyH("LEFT"); b.text:SetWidth(244)
    b:SetScript("OnClick", function(self) if self.step then ns.Waypoints.Set(self.step) end end)
    rows[i] = b
  end
end

-- workable = lines with a current step; locked = too-low lines (shown dim).
function Tracker.Render(workable, settings, level, locked)
  if not frame then return end
  locked = locked or {}
  if not settings.tracker or (#workable == 0 and #locked == 0) then frame:Hide(); return end
  local y = -22
  for i = 1, MAX_LINES do
    local b, r = rows[i], workable[i]
    if r then
      b.step = r.steps[r.current].step
      b.text:SetText(table.concat(Tracker.Lines(r, level), "\n"))
      local h = (b.text.GetStringHeight and b.text:GetStringHeight() or 60) + 4
      b:SetHeight(h)
      b:ClearAllPoints(); b:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, y)
      y = y - h - 6
      b:Show()
    else
      b:Hide()
    end
  end
  lockedText = lockedText or frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  local parts = {}
  for _, r in ipairs(locked) do table.insert(parts, string.format("%s: unlocks at %d", r.line.title, r.line.minLevel)) end
  if #parts > 0 then
    lockedText:ClearAllPoints(); lockedText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, y)
    lockedText:SetJustifyH("LEFT"); lockedText:SetWidth(244)
    lockedText:SetText(table.concat(parts, "\n")); lockedText:Show()
    y = y - 14 * #parts - 4
  else
    lockedText:Hide()
  end
  frame:SetHeight(-y + 4)
  frame:Show()
end

function Tracker.Toggle(settings)
  settings.tracker = not settings.tracker
  ns.App.Refresh()
  return settings.tracker
end
