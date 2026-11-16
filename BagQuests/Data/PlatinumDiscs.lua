-- Thawpelt Sack, both factions with different turn-ins (Ironforge or Thunder
-- Bluff). Starts at the Discs of Norgannon inside Uldaman (dungeon, Badlands).
-- IDs, NPCs and coordinates from the Forever QuestieDB. Slot count (14) comes
-- from Classic sources: unverified in Forever.
local _, ns = ...
local DISCS = "Uldaman (dungeon, Badlands): talk to the stone watcher first."
local function discs(t)
  t.object = "The Discs of Norgannon"; t.hint = DISCS; t.suggested = 47
  t.where = "Inside Uldaman (dungeon), Badlands"
  return t
end
ns.Domain.Register({
  id = "platinum_discs",
  title = "Thawpelt Sack",
  slots = 14,
  minLevel = 40,
  rewardItems = { 9587 },
  note = "Needs an Uldaman run; the bag is a reward voucher in your capital.",
  quests = {
    [2278] = "The Platinum Discs", [2279] = "The Platinum Discs", [2280] = "The Platinum Discs",
    [2439] = "The Platinum Discs", [2440] = "The Platinum Discs",
  },
  defaultRoute = "Horde",
  routes = {
    Alliance = {
      discs({ title = "Discs of Norgannon, Uldaman", starts = 2278 }),
      discs({ title = "Use the Discs again for a miniature copy", turnsIn = 2278, starts = 2279 }),
      { title = "High Explorer Magellas, Ironforge", suggested = 47, npc = "High Explorer Magellas",
        mapID = 1455, x = 69.9, y = 18.6, turnsIn = 2279, starts = 2439 },
      { title = "Dinita Stonemantle, the Vault, Ironforge", suggested = 47, npc = "Dinita Stonemantle",
        mapID = 1455, x = 33.9, y = 59.2, turnsIn = 2439, reward = "Thawpelt Sack" },
    },
    Horde = {
      discs({ title = "Discs of Norgannon, Uldaman", starts = 2278 }),
      discs({ title = "Use the Discs again for a miniature copy", turnsIn = 2278, starts = 2280 }),
      { title = "Sage Truthseeker, Thunder Bluff", suggested = 47, npc = "Sage Truthseeker",
        mapID = 1456, x = 34.4, y = 46.9, turnsIn = 2280, starts = 2440 },
      { title = "Bena Winterhoof, Thunder Bluff", suggested = 47, npc = "Bena Winterhoof",
        mapID = 1456, x = 46.6, y = 33.2, turnsIn = 2440, reward = "Thawpelt Sack" },
    },
  },
})
