-- Cozy Sleeping Bag, Horde order. Sources: wowforever.gg, forevermastery.com
-- (quest IDs from Wowhead), pro-gamer.gg, space4games.com. NOT yet verified
-- in game: run /bq verify to check the quest IDs on your character.
-- mapIDs are uiMapIDs (C_Map); coordinates are 0-100.
local _, ns = ...
ns.Domain.Register({
  id = "cozy_sleeping_bag",
  title = "Cozy Sleeping Bag",
  faction = nil, -- both factions; this is the Horde route order
  minLevel = 14,   -- required to pick up the first note
  -- suggested = the Wowhead quest level of the quest you carry to that step
  rewardItems = { 211527 },                 -- Cozy Sleeping Bag
  bonusItems = { 221498, 1652 },            -- Old Toolbox (12) / Sturdy Lunchbox (12), at step 3
  note = "Quests are level 22-32; guides suggest doing it around 30.",
  quests = { -- names let /bq verify spot a wrong quest ID
    [79007] = "...and that note you found", [79192] = "Stepping Stones",
    [79980] = "Scramble", [79974] = "Wet Job", [79975] = "Eagle's Fist",
    [79976] = "This Must Be the Place",
  },
  steps = {
    { title = "Burned tower south of Camp Taurajo", suggested = 22, object = "Burned-Out Remains",
      mapID = 1413, x = 46.1, y = 74.3, starts = 79007 },
    { title = "Wrecked cart, Alexston Farmstead", suggested = 24, object = "Nailed Plank",
      mapID = 1436, x = 37.1, y = 50.1, turnsIn = 79007, starts = 79192,
      hint = "Zeppelin to Grom'gol, swim north along the coast." },
    { title = "Abandoned camp near Sun Rock", suggested = 24, object = "Pocket Litter",
      mapID = 1442, x = 40.6, y = 52.4, turnsIn = 79192, starts = 79980,
      reward = "Old Toolbox (12 slots)" },
    { title = "Ledge north of the camp", suggested = 24, object = "Mound of Dirt",
      mapID = 1442, x = 39.6, y = 49.9, turnsIn = 79980, starts = 79974 },
    { title = "Stonewrought Dam, north face", suggested = 32, object = "Carved Figurine",
      mapID = 1432, x = 49.4, y = 12.9, turnsIn = 79974, starts = 79975,
      hint = "Drop from the upper walkway onto the ledge. Alliance guards." },
    { title = "Broken cart at Thoradin's Wall", suggested = 32, object = "Broken cart",
      mapID = 1424, x = 87.4, y = 49.6, turnsIn = 79975, starts = 79976 },
    { title = "Hanging Messenger Bag, Arathi", suggested = 32, object = "Hastily Rolled-Up Satchel",
      mapID = 1417, x = 22.5, y = 24.2, turnsIn = 79976,
      reward = "Cozy Sleeping Bag" },
  },
})
