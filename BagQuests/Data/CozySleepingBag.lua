-- Cozy Sleeping Bag. Both factions run the same chain; only the first two
-- stops swap places, and the first quest has a different ID per faction.
-- Sources: wowforever.gg, forevermastery.com (quest IDs from Wowhead),
-- pro-gamer.gg, space4games.com; Alliance route from warcraft.wiki.gg,
-- warcrafttavern.com and wow.gg. Objects, coordinates and quest levels checked
-- against the Forever QuestieDB (2026-11-16). Hints from Wowhead Forever comments
-- on 79007 and 79976 (2026-11-22). Horde 79007 is verified in game;
-- the rest is NOT yet: run /bq verify to check the quest IDs on your character.
-- mapIDs are uiMapIDs (C_Map); coordinates are 0-100.
local _, ns = ...

-- suggested = the quest level of the quest you carry to that step (or start,
-- on step 1). Both first stops have Burned-Out Remains and a Nailed Plank: the
-- first stop only uses the remains; the second turns the note in at the
-- remains and starts Stepping Stones from the plank.
local FIRST, SECOND = "Burned-Out Remains", "Burned-Out Remains, then the Nailed Plank"
local function barrensTower(t)
  t.title = "Burned tower south of Camp Taurajo"
  t.mapID, t.x, t.y = 1413, 46.4, 73.9
  return t
end
local function westfallCart(t)
  t.title = "Wrecked cart, Alexston Farmstead"
  t.mapID, t.x, t.y = 1436, 37.4, 50.7
  return t
end

-- From Stonetalon on, both factions follow the same steps.
local TAIL = {
    { title = "Abandoned camp near Sun Rock", suggested = 24, object = "Pocket Litter",
      mapID = 1442, x = 40.8, y = 52.6, turnsIn = 79192, starts = 79980,
      reward = "Old Toolbox (12 slots)",
      hint = "Leave the road at 51.6, 52.4 and head west up the hill to the camp." },
    { title = "Ledge north of the camp", suggested = 24, object = "Mound of Dirt",
      mapID = 1442, x = 39.6, y = 49.9, turnsIn = 79980, starts = 79974,
      hint = "Jump down from the camp. If you miss, hug the wall on your right and walk back up." },
    { title = "Stonewrought Dam, north face", suggested = 32, object = "Carved Figurine",
      mapID = 1432, x = 49.4, y = 12.9, turnsIn = 79974, starts = 79975,
      hint = "Walk backward off the dam from about 49.6, 13.4 onto the ledge so you don't overshoot. "
        .. "Horde: Alliance guards on the dam, and the dwarves in the Dun Algaz tunnel flag you for PvP." },
    { title = "Messenger Bag atop Thoradin's Wall, Arathi", suggested = 32, object = "Messenger Bag",
      mapID = 1417, x = 22.5, y = 24.1, turnsIn = 79975, starts = 79976,
      hint = "Before the arch into Arathi, go left along the wall to the broken cart (Hillsbrad 87.5, 47.7). "
        .. "Jump from the drum in the cart to its right rail, then to the fallen ladder, then up the rocks. "
        .. "Male night elves can't fit under the cargo netting (game bug)." },
    { title = "Satchel under the Messenger Bag, same platform", suggested = 32, object = "Hastily Rolled-Up Satchel",
      mapID = 1417, x = 22.5, y = 24.2, turnsIn = 79976,
      reward = "Cozy Sleeping Bag and 5 Student Fodder" },
}
local function route(first, second)
  local steps = { first, second }
  for _, s in ipairs(TAIL) do table.insert(steps, s) end
  return steps
end

ns.Domain.Register({
  id = "cozy_sleeping_bag",
  title = "Cozy Sleeping Bag",
  slots = 12, -- Old Toolbox or Sturdy Lunchbox at step 3; the sleeping bag itself is a toy
  faction = nil, -- both factions, each with its own route
  minLevel = 14,   -- required to pick up the first note
  rewardItems = { 211527 },                 -- Cozy Sleeping Bag
  bonusItems = { 221498, 1652 },            -- Old Toolbox (12) / Sturdy Lunchbox (12), at step 3
  note = "Quests are level 22-32. Do it in your 20s: one player at 35 couldn't pick up Stepping Stones.",
  quests = { -- names let /bq verify spot a wrong quest ID
    [79007] = "...and that note you found", [79008] = "...and that note you found",
    [79192] = "Stepping Stones", [79980] = "Scramble", [79974] = "Wet Job",
    [79975] = "Eagle's Fist", [79976] = "This Must Be the Place",
  },
  defaultRoute = "Horde", -- used when the faction is unknown
  routes = {
    Horde = route(
      barrensTower({ suggested = 22, object = FIRST, starts = 79007 }),
      westfallCart({ suggested = 22, object = SECOND, turnsIn = 79007, starts = 79192,
        hint = "Zeppelin to Grom'gol, swim north along the coast." })),
    Alliance = route(
      westfallCart({ suggested = 22, object = FIRST, starts = 79008 }),
      barrensTower({ suggested = 22, object = SECOND, turnsIn = 79008, starts = 79192,
        hint = "Boat from Menethil Harbor to Theramore, then run west." })),
  },
})
