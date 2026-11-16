-- Ooze-covered Bag, Alliance. Sida in Menethil Harbor. IDs, NPC and
-- coordinates from the Forever QuestieDB. Slot count (10) comes from Classic
-- sources: unverified in Forever.
local _, ns = ...
ns.Domain.Register({
  id = "digging_through_the_ooze",
  title = "Ooze-covered Bag",
  slots = 10,
  faction = "Alliance",
  minLevel = 19,
  rewardItems = { 3352 },
  quests = { [470] = "Digging Through the Ooze" },
  steps = {
    { title = "Sida, Menethil Harbor", suggested = 24, npc = "Sida",
      mapID = 1437, x = 11.8, y = 58.0, starts = 470 },
    { title = "Find Sida's Bag on the oozes at Ironbeard's Tomb", suggested = 24,
      mapID = 1437, x = 44.4, y = 24.8, turnsIn = 470,
      hint = "Crimson, Black and Monstrous Oozes can carry it. Then bring it back to Sida in Menethil Harbor (11.8, 58.0).",
      reward = "Ooze-covered Bag" },
  },
})
