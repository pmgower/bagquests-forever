# CurseForge listing: copy and paste

**Project name:** BagQuests: Forever

**Summary (one line):** Track the quest chains that reward bags in WoW Forever (Cozy Sleeping Bag, Stronger than Steel) with a next-step tracker, map pins, and an alts table.

**Categories:** Quests & Leveling (main), Map & Minimap, Bags & Inventory

**License:** MIT

**Game version:** Forever (1.60.1)

---

## Description

Free bag slots and a 3% XP buff are hiding behind quest chains that are easy to miss. BagQuests: Forever tells you where to go next.

### What it tracks
* **Cozy Sleeping Bag**: the hidden 7-step chain to Arathi, with the right route for Alliance (starts in Westfall) and Horde (starts in the Barrens). It rewards the Old Toolbox (12 slots) on the way and the sleeping bag itself (+1% XP per minute rested, up to 3%, for 2 hours).
* **Stronger than Steel** (Horde): Spidersilk Sack (10-slot reagent bag) or Spidersilk Pouch (12 slots).
* **Deviate Hide Pack** (10 slots, both factions, level 13+): Deviate Hides for Nalpak at the Wailing Caverns.
* **Hunting Satchel** (10 slots, Alliance, level 11+): Daryl the Youngling's chain in Loch Modan, ending with Ol' Sooty.
* **Gunnysack of the Night Watch** (Alliance, level 18+): three Duskwood quests for Commander Ebonlocke.
* **Ooze-covered Bag** (Alliance, level 19+): Sida's lost bag in the Wetlands.
* **Explorer's Knapsack** (both factions, level 35+): Cortello's Riddle, from Stranglethorn to the Hinterlands.
* **Thawpelt Sack** (both factions, level 40+): The Platinum Discs from Uldaman.
* **Hyjal Postal Satchel** (18 slots, both factions, level 56+): the mail run between Mount Hyjal and Everlook, new in WoW Forever.

### Features
* **On-screen next step**: what to click, where it is, and the level you need. Each step shows its required and suggested level, colored green, yellow or red for your character.
* **World map and minimap pins**: hover a pin for details, click it for a waypoint (TomTom if installed, otherwise the game's own map pin).
* **Alts table** (optional `BagQuests_Alts` module): every character's progress side by side. Disable the module to turn alt tracking off.
* Picks up progress from before you installed it.

### Commands
`/bq` tracker on/off · `/bq way` waypoint · `/bq status` · `/bq alts` · `/bq verify` · `/bq help`

### Beta
The quest data comes from community guides. If you see a red "Quest ID mismatch" message, please post the output of `/bq verify` in the comments.

Source code and issues: https://github.com/pmgower/bagquests-forever

Map pins use HereBeDragons by Nevcairiel (BSD).
