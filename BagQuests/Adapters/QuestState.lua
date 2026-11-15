-- QuestState: the only file that asks the game about quests, items, level
-- and faction. Produces the plain snapshot table Domain.Evaluate expects.
local _, ns = ...
local QuestState = {}
ns.QuestState = QuestState

local function isCompleted(id)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    return C_QuestLog.IsQuestFlaggedCompleted(id) == true
  end
  return IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(id) == true or false
end

-- Quest IDs currently in the log, plus titles (for /bq verify).
function QuestState.LogEntries()
  local entries = {}
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
      local info = C_QuestLog.GetInfo(i)
      if info and not info.isHeader and info.questID and info.questID > 0 then
        table.insert(entries, { id = info.questID, title = info.title })
      end
    end
  end
  return entries
end

local function itemCount(id)
  if C_Item and C_Item.GetItemCount then return C_Item.GetItemCount(id, true) or 0 end
  return GetItemCount and GetItemCount(id, true) or 0
end

function QuestState.Title(questID)
  if C_QuestLog and C_QuestLog.GetTitleForQuestID then return C_QuestLog.GetTitleForQuestID(questID) end
end

function QuestState.Snapshot()
  local snap = { completed = {}, active = {}, items = {} }
  for id in pairs(ns.Domain.TrackedQuestIDs()) do
    if isCompleted(id) then snap.completed[id] = true end
  end
  for _, e in ipairs(QuestState.LogEntries()) do snap.active[e.id] = true end
  for id in pairs(ns.Domain.TrackedItemIDs()) do
    local n = itemCount(id)
    if n > 0 then snap.items[id] = n end
  end
  snap.level = UnitLevel and UnitLevel("player") or 1
  snap.faction = UnitFactionGroup and UnitFactionGroup("player") or nil
  return snap
end
