-- Explorer's Knapsack, both factions. Cortello's Riddle: a scroll aboard the
-- Bloodsail ships in Stranglethorn leads to Swamp of Sorrows, Dustwallow Marsh
-- and the Hinterlands. IDs, objects and coordinates from the Forever QuestieDB.
-- Slot count (14) comes from Classic sources: unverified in Forever.
local _, ns = ...
ns.Domain.Register({
  id = "cortellos_riddle",
  title = "Explorer's Knapsack",
  slots = 14,
  minLevel = 35,
  rewardItems = { 11324 },
  note = "The quests are level 43-51; the ships are full of Bloodsail pirates.",
  quests = { [624] = "Cortello's Riddle", [625] = "Cortello's Riddle", [626] = "Cortello's Riddle" },
  steps = {
    { title = "Scroll aboard a Bloodsail ship, south Stranglethorn", suggested = 43,
      object = "Cortello's Riddle", mapID = 1434, x = 29.2, y = 88.6, starts = 624,
      hint = "It can be on any of the three ships off the coast." },
    { title = "A Soggy Scroll under the western bridge, Swamp of Sorrows", suggested = 43,
      object = "A Soggy Scroll", mapID = 1435, x = 22.9, y = 48.2, turnsIn = 624, starts = 625 },
    { title = "Musty Scroll in a cave, southwest Dustwallow Marsh", suggested = 43,
      object = "Musty Scroll", mapID = 1445, x = 31.1, y = 66.1, turnsIn = 625, starts = 626 },
    { title = "Cortello's Treasure under the waterfall, Hinterlands coast", suggested = 51,
      object = "Cortello's Treasure", mapID = 1425, x = 80.8, y = 46.8, turnsIn = 626,
      hint = "Underwater at the foot of the waterfall.", reward = "Explorer's Knapsack" },
  },
})
