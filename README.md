# BagQuests: Forever (beta 0.1.5)

Tracks the WoW Forever quest chains that reward bags. It shows your next step on
screen (RestedXP style), puts pins on the world map and minimap, and has an
optional alts table.

Questlines so far: **Cozy Sleeping Bag** (plus the Old Toolbox along the way)
and **Stronger than Steel** (Spidersilk Sack 10 reagent / Pouch 12).

## Level hints

Each step on the tracker shows **Req** (the level needed to start the questline),
**Suggested** (the quest's level, from Wowhead) and your level, colored green
(good), yellow (a bit low) or red (too low to start). Questlines you can't start
yet show at the bottom as "unlocks at N". The alts table adds "sugg N" when a
character is under the suggested level for its current step.

## Two addons

| Folder | What it does |
| --- | --- |
| `BagQuests` | On-screen next step, map + minimap pins, waypoints (TomTom if installed). |
| `BagQuests_Alts` | Optional. Remembers each character when you log in and shows `/bq alts`. Untick it in the AddOns list to turn alt tracking off. |

## Commands

| Command | What it does |
| --- | --- |
| `/bq` | Show or hide the on-screen tracker (drag it to move) |
| `/bq way` | Waypoint to your next step (clicking a tracker line or pin does the same) |
| `/bq status` | Every bag questline for this character |
| `/bq alts` | Table of every character's progress (needs BagQuests_Alts) |
| `/bq verify` | Our quest IDs vs your quest log, plus any ID mismatches |
| `/bq pins` / `/bq minimap` / `/bq lock` | Toggle later-step pins, the minimap pin, tracker lock |
| `/bq surnames` | Show or hide second names in the alts table (shown by default) |
| `/bq forget <name>` | Drop a character from the alts table |

## Beta test plan

1. Log in on the Warlock. The tracker should show both questlines with step 1.
   Open the world map on Mulgore and The Barrens: you should see bag pins.
2. `/bq alts`. Log in on one or two alts, then `/bq alts` again: each should appear.
3. When you click the burned tower in the Barrens, watch chat. A red "Quest ID
   mismatch" line means our data has a wrong ID: send Claude a screenshot of
   `/bq verify`. No red line + the tracker moving to Westfall = IDs are right.
4. Report anything red (Lua errors) and whether the pins sit in the right spots.

## Developing

`lua5.1 tests/run.lua` runs the domain tests plus a simulated game (two
characters, quest accept, ID mismatch, alts table, alts module disabled).

Layout follows FishShare: `Core/Domain.lua` is pure Lua (Questline, Step,
Evaluate); `Data/` has one file per questline, so adding a bag quest is just a
new data file and a line in the TOC; `Adapters/` talk to the game; `App.lua`
holds the use cases; `UI/` is the tracker and slash commands. Libraries in
`Libs/` (HereBeDragons 2.18, BSD) are copied unmodified.
