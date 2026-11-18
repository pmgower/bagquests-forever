-- luacheck config for WoW Forever addon code. Bundled Libs/ are excluded
-- (they're pinned by hash in tests/safety.lua instead).
std = "lua51"
max_line_length = false
exclude_files = { "BagQuests/Libs/**", "tests/**", ".luacheckrc" }
ignore = { "212" } -- unused arguments (event handlers often ignore some)

-- Globals our addon is allowed to create.
globals = {
  "BagQuests", "BagQuestsDB", "BagQuestsAltsDB",
  "SLASH_BAGQUESTS1", "SLASH_BAGQUESTS2", "SlashCmdList",
}

-- WoW API we read. Anything not listed here fails the lint, so a PR that
-- reaches for a new game API has to add it here, in plain sight.
read_globals = {
  "C_Item", "C_Map", "C_QuestLog", "C_SuperTrack", "C_Texture", "C_Timer",
  "CreateFrame", "DEFAULT_CHAT_FRAME", "GameTooltip", "GetItemCount", "GetRealmName",
  "HBD_PINS_WORLDMAP_SHOW_CONTINENT", "IsQuestFlaggedCompleted", "LibStub",
  "GetCursorPosition", "GetQuestGreenRange", "IsMouseButtonDown", "IsShiftKeyDown", "RAID_CLASS_COLORS", "Settings", "TomTom", "UIParent", "UISpecialFrames", "UiMapPoint",
  "UnitClass", "UnitFactionGroup", "UnitLevel", "UnitName", "issecretvalue",
  "time", "tinsert",
}
