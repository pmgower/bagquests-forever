-- Hunting Satchel (10 slots), Alliance. Daryl the Youngling's chain at the
-- Farstrider Lodge, Loch Modan. IDs, NPCs and coordinates from the Forever
-- QuestieDB (Hunting Satchel 270017 is Forever-only); slot count from Forever
-- guides (leprestore). NOT yet verified in game: run /bq verify.
local _, ns = ...
local LODGE = { mapID = 1432, x = 83.5, y = 65.5 }   -- Daryl the Youngling
local VYRIN = { mapID = 1432, x = 81.7, y = 64.1 }   -- Vyrin Swiftwind
local function at(p, t) t.mapID, t.x, t.y = p.mapID, p.x, p.y; return t end

ns.Domain.Register({
  id = "vyrins_revenge",
  title = "Hunting Satchel",
  slots = 10,
  faction = "Alliance",
  minLevel = 11,
  rewardItems = { 270017 }, -- Hunting Satchel (also offers an ammo sack or quiver)
  note = "Ol' Sooty is elite: bring a friend if you're near the minimum level.",
  quests = {
    [257] = "A Hunter's Boast", [258] = "A Hunter's Challenge",
    [271] = "Vyrin's Revenge", [531] = "Vyrin's Revenge",
  },
  steps = {
    at(LODGE, { title = "Daryl the Youngling, Farstrider Lodge", suggested = 16,
      npc = "Daryl the Youngling", starts = 257 }),
    at(LODGE, { title = "Kill 6 Mountain Buzzards, return within 15 minutes", suggested = 16,
      turnsIn = 257, starts = 258, hint = "Timed: you have 15 minutes once you accept." }),
    { title = "Kill Elder Mountain Boars, return to Daryl", suggested = 17,
      mapID = 1432, x = 64.9, y = 38.8, turnsIn = 258 },
    at(VYRIN, { title = "Vyrin Swiftwind, Farstrider Lodge", suggested = 20,
      npc = "Vyrin Swiftwind", starts = 271 }),
    { title = "Kill Ol' Sooty (elite), show Daryl his head", suggested = 20,
      mapID = 1432, x = 37.9, y = 63.4, turnsIn = 271, starts = 531 },
    at(VYRIN, { title = "Bring the head to Vyrin Swiftwind", suggested = 20,
      npc = "Vyrin Swiftwind", turnsIn = 531, reward = "Hunting Satchel (10 slots)" }),
  },
})
