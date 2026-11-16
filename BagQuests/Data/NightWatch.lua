-- Gunnysack of the Night Watch, Alliance. Three-part Duskwood chain from
-- Commander Althea Ebonlocke. IDs, NPCs and coordinates from the Forever
-- QuestieDB. Slot count (10) comes from Classic sources: unverified in Forever.
local _, ns = ...
local HINT = "Then report to Commander Althea Ebonlocke in Darkshire (73.5, 46.8)."
ns.Domain.Register({
  id = "night_watch",
  title = "Gunnysack of the Night Watch",
  slots = 10,
  faction = "Alliance",
  minLevel = 18,
  rewardItems = { 1729 }, -- Gunnysack of the Night Watch (or a quiver/bandolier)
  quests = { [56] = "The Night Watch", [57] = "The Night Watch", [58] = "The Night Watch" },
  steps = {
    { title = "Commander Althea Ebonlocke, Darkshire", suggested = 24,
      npc = "Commander Althea Ebonlocke", mapID = 1431, x = 73.5, y = 46.8, starts = 56 },
    { title = "Kill 8 Skeletal Warriors and 6 Skeletal Mages", suggested = 24,
      mapID = 1431, x = 77.4, y = 73.8, turnsIn = 56, starts = 57, hint = HINT },
    { title = "Kill 15 Skeletal Fiends and 15 Skeletal Horrors", suggested = 26,
      mapID = 1431, x = 79.7, y = 61.9, turnsIn = 57, starts = 58, hint = HINT },
    { title = "Kill 20 Plague Spreaders, eastern Raven Hill mausoleum", suggested = 30,
      mapID = 1431, x = 23.0, y = 28.0, turnsIn = 58, hint = HINT,
      reward = "Gunnysack of the Night Watch" },
  },
})
