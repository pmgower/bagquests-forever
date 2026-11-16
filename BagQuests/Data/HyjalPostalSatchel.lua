-- Hyjal Postal Satchel (18 slots), both factions, new in WoW Forever. Mail
-- run between Sebelia on the Mount Hyjal summit and Everlook. IDs, NPCs and
-- coordinates from the Forever QuestieDB; slot count and level from Forever
-- guides (method.gg). NOT yet verified in game: run /bq verify.
local _, ns = ...
local SEBELIA = { mapID = 2482, x = 70.9, y = 51.6 }  -- Summit of Eternity, Mount Hyjal
local VIZZIE = { mapID = 1452, x = 61.4, y = 38.8 }   -- Innkeeper Vizzie, Everlook
local function at(p, t) t.mapID, t.x, t.y = p.mapID, p.x, p.y; return t end

ns.Domain.Register({
  id = "hyjal_postal",
  title = "Hyjal Postal Satchel",
  slots = 18,
  minLevel = 56,
  rewardItems = { 260307 },  -- Hyjal Postal Satchel (also Hyjal Postal Clasp 260308)
  note = "Reaching the summit needs Evie Whirlbrew's Potion of Winterspring Shrouding (Everlook).",
  quests = {
    [93197] = "Mending Communications", [93406] = "Unfrozen Deliveries",
    [93269] = "Top of the Post",
  },
  steps = {
    at(SEBELIA, { title = "Sebelia, summit of Mount Hyjal", suggested = 58, npc = "Sebelia",
      starts = 93197, hint = "Evie Whirlbrew in Everlook (60.8, 37.8) makes the potion that gets you up." }),
    at(VIZZIE, { title = "Deliver the parcels to Innkeeper Vizzie, Everlook", suggested = 58,
      npc = "Innkeeper Vizzie", turnsIn = 93197, starts = 93406 }),
    at(VIZZIE, { title = "Find 4 Missing Mail in the hills north of Everlook", suggested = 56,
      turnsIn = 93406, starts = 93269, hint = "Then bring the mail back to Innkeeper Vizzie." }),
    at(SEBELIA, { title = "Take the mail up to Sebelia", suggested = 58, npc = "Sebelia",
      turnsIn = 93269, reward = "Hyjal Postal Satchel (18 slots)" }),
  },
})
