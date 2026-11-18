# CurseForge listing: copy and paste

Written for **0.2.0**. Paste everything below the "Description" line into the project's
**Description** field (CurseForge accepts Markdown). It covers the tracker redesign (#11),
bug reporting (#13) and the window scroll bars (#14).

**Screenshots (gallery order):**
1. Tracker window, Frost Steel, a few lines showing (have: bagquests-active-screen-screenshot-001.png).
2. World map with the bag pin on the next step and the dim pins for later steps.
3. Hovering a tracker line: tooltip on the right and the waypoint arrow.
4. Alts table (have: bagquests-alts-screenshot-001.png).
5. Minimap: the bag pin, plus the minimap button tooltip.
6. Settings page with Frost Steel and the "Report a bug" button (retake: the current ones show Deepwater and predate the button).
7. Optional: the /bq feedback window, and the four color schemes side by side.
Remove the 0.1.4 shots (the old tracker and the old alts window) from the gallery.

**Project name:** BagQuests: Forever

**Summary (one line):** Track the quest chains that reward bags in WoW Forever with a next-step tracker, map pins, and an alts table.

**Categories:** Quests & Leveling (main), Map & Minimap, Bags & Inventory

**License:** MIT

**Game version:** Forever (1.60.1)

---

## Description

# BagQuests: Forever

**Never miss a free bag again.** WoW Forever hides extra bag slots and a rested-XP buff behind quest chains that are easy to miss: some start from objects on the ground with no quest giver and no "!". BagQuests: Forever finds those chains for you and shows exactly where to go next, step by step, on screen and on your map.

It is a small, read-only helper. It never accepts, abandons or turns in quests for you, never touches your gold or items, and sends nothing to chat.

## What it tracks

Nine bag questlines, from 10 to 18 slots:

* **Cozy Sleeping Bag** (both factions, level 14+): a hidden 7-step chain across both continents to Thoradin's Wall. A 12-slot bag partway through, and at the end a toy that gives +1% XP per minute rested, up to 3%, for 2 hours. Alliance starts in Westfall, Horde in the Barrens.
* **Stronger than Steel** (Horde, level 23+): Spidersilk Pouch (12 slots) or Spidersilk Sack (10-slot reagent bag).
* **Deviate Hide Pack** (10 slots, both factions, level 13+): Deviate Hides for Nalpak at the Wailing Caverns.
* **Hunting Satchel** (10 slots, Alliance, level 11+): Daryl the Youngling's chain in Loch Modan, ending with Ol' Sooty.
* **Gunnysack of the Night Watch** (10 slots, Alliance, level 18+): three Duskwood quests for Commander Ebonlocke.
* **Ooze-covered Bag** (10 slots, Alliance, level 19+): Sida's lost bag in the Wetlands.
* **Explorer's Knapsack** (14 slots, both factions, level 35+): Cortello's Riddle, from Stranglethorn to the Hinterlands.
* **Thawpelt Sack** (14 slots, both factions, level 40+): The Platinum Discs from Uldaman.
* **Hyjal Postal Satchel** (18 slots, both factions, level 56+): the mail run between Mount Hyjal and Everlook, new in WoW Forever.

## How it works

1. **Log in.** The tracker shows the next step of every bag questline your character can do.
2. **Follow the pin.** Hover a tracker line or map pin for details, and click it for a waypoint (TomTom if you have it, otherwise the game's own map pin).
3. **Do the step.** The tracker moves on by itself once the game counts the quest as accepted or completed.

It reads your quest history, so progress you made **before** installing the addon is picked up automatically.

## Features

* **Guide-style tracker window**: bordered, movable and resizable (with scroll bars when it's small), in four color schemes (pick one in settings or with `/bq theme`). Each line shows how many bag slots it gives, and progress dots show which steps are done, current and skipped.
* **Level hints**: each step shows the level to start and the suggested level, colored like the game colors quests for your character.
* **Pick what to track**: turn questlines on or off in the settings page or with `/bq track`. Right-click a step to skip it, shift-right-click to undo.
* **World map and minimap pins**, plus a **minimap button**: left-click toggles the tracker, right-click opens settings, shift-click opens the alts table, ctrl-click reports a bug.
* **Settings page** under Options > AddOns.
* **Alts table** (optional `BagQuests_Alts` module): every character's progress side by side, in the same resizable window. Disable the module to turn alt tracking off.
* **Easy bug reports**: `/bq feedback`, the settings page or a ctrl-click on the minimap button opens a GitHub bug report with your version and details already filled in. If BagQuests itself hits an error, it offers the same report once per session (you can turn that off in settings).

## Commands

| Command | What it does |
| --- | --- |
| `/bq` | Show or hide the tracker |
| `/bq way` | Waypoint to your next step |
| `/bq status` | Every bag questline for this character |
| `/bq track` | List questlines and turn them on or off |
| `/bq skip` / `/bq unskip` | Skip the current step, or undo all skips |
| `/bq theme` | Change the tracker's color scheme |
| `/bq lock` / `/bq reset` | Lock the tracker, or put the windows back to their default spot and size |
| `/bq pins` / `/bq minimap` | Toggle dim pins for later steps, or the minimap pin |
| `/bq alts` | Table of all your characters (needs BagQuests_Alts) |
| `/bq verify` | Compare our quest IDs with your quest log |
| `/bq feedback` | Report a bug with the details filled in |
| `/bq settings` | Open the settings page |
| `/bq help` | List all commands |

## Compatibility

* Made for **WoW Forever** (1.60.1).
* **TomTom** is optional. Waypoints use it when it is installed.
* Map pins use the bundled HereBeDragons library. No other addons are required.

## Please help verify

The routes and quest IDs come from the Forever quest database and community guides, and are being checked in game. If you see a red **"Quest ID mismatch"** line in chat, or a pin in the wrong spot, use `/bq feedback`: it fills in your quest progress and any ID mismatches for us. Or post in the comments. The Alliance route for the Cozy Sleeping Bag is new in this version, so reports from Alliance players are especially welcome.

## Coming next

* Filter questlines by bag size and by your level.
* More bag quests as they are confirmed in Forever.
* Tell us what you'd like next in the comments or on GitHub.

## Source, issues and license

Open source under the MIT license: https://github.com/pmgower/bagquests-forever

Map pins use HereBeDragons by Nevcairiel (BSD).
