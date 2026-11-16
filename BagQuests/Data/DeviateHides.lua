-- Deviate Hide Pack (10 slots), both factions. Quest ID, giver and coordinates
-- from the Forever QuestieDB; slot count from Forever guides (conquestcapped).
-- NOT yet verified in game: run /bq verify.
local _, ns = ...
ns.Domain.Register({
  id = "deviate_hides",
  title = "Deviate Hide Pack",
  slots = 10,
  minLevel = 13,
  rewardItems = { 918 },  -- Deviate Hide Pack (or Slick Deviate Leggings instead)
  note = "Pick the pack over the leggings. You don't need to run the dungeon.",
  quests = { [1486] = "Deviate Hides" },
  steps = {
    { title = "Nalpak, above the Wailing Caverns entrance", suggested = 17, npc = "Nalpak",
      mapID = 1413, x = 46.0, y = 35.7, starts = 1486,
      hint = "His cave is up the rock face around the dungeon entrance." },
    { title = "Collect 20 Deviate Hides, then return to Nalpak", suggested = 17, npc = "Nalpak",
      mapID = 1413, x = 46.0, y = 35.7, turnsIn = 1486,
      hint = "Deviate creatures in and around the Wailing Caverns drop them.",
      reward = "Deviate Hide Pack (10 slots)" },
  },
})
