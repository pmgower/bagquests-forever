-- Stronger than Steel (Horde only). Giver, coordinates, levels and the
-- objective come from the Forever QuestieDB: required level 23, quest level 29.
-- Quest 96260 verified in game.
local _, ns = ...
local YORN = { mapID = 1412, x = 32.5, y = 20.0 } -- Yorn Grimtotem, north Mulgore
ns.Domain.Register({
  id = "stronger_than_steel",
  title = "Stronger than Steel",
  slots = 12, -- Spidersilk Pouch (or the 10-slot reagent Sack)
  faction = "Horde",
  minLevel = 23,   -- required to pick up; the quest itself is level 29
  rewardItems = { 276892, 276891 }, -- Spidersilk Sack (10 reagent) / Spidersilk Pouch (12)
  note = "Pick the Sack (10, reagent slot) unless your reagent slot already has 10+.",
  quests = { [96260] = "Stronger than Steel" },
  steps = {
    { title = "Yorn Grimtotem, Mulgore", suggested = 29, npc = "Yorn Grimtotem",
      mapID = YORN.mapID, x = YORN.x, y = YORN.y, starts = 96260 },
    { title = "Gather 3 Crystalline Silk from Gloomrise Spinners", suggested = 29,
      mapID = 1412, x = 32.0, y = 12.0, turnsIn = 96260,
      hint = "The spiders are just north of Yorn. Then return to him (32.5, 20.0).",
      reward = "Spidersilk Sack (10 reagent) or Pouch (12)" },
  },
})
