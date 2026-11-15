-- Stronger than Steel (Horde only). Sources: wowhandbook.com (giver + coords),
-- conquestcapped.com (says Skywatcher Plateau instead), maxdps.com.
-- Objectives not documented yet; NOT verified in game.
local _, ns = ...
ns.Domain.Register({
  id = "stronger_than_steel",
  title = "Stronger than Steel",
  faction = "Horde",
  minLevel = 23,   -- guides disagree: one table says 30
  rewardItems = { 276892, 276891 }, -- Spidersilk Sack (10 reagent) / Spidersilk Pouch (12)
  note = "Pick the Sack (10, reagent slot) unless your reagent slot already has 10+.",
  quests = { [96260] = "Stronger than Steel" },
  steps = {
    { title = "Yorn Grimtotem, Mulgore", suggested = 23, npc = "Yorn Grimtotem",
      mapID = 1412, x = 32.5, y = 20.1, starts = 96260,
      hint = "One guide says Skywatcher Plateau instead." },
    { title = "Turn in to Yorn Grimtotem", suggested = 23, npc = "Yorn Grimtotem",
      mapID = 1412, x = 32.5, y = 20.1, turnsIn = 96260,
      reward = "Spidersilk Sack (10 reagent) or Pouch (12)" },
  },
})
