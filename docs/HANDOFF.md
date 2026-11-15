# Handoff: BagQuests: Forever

Read this first if you're picking the addon up in a new thread or project.

## Where things are
- **Repo:** https://github.com/pmgower/bagquests-forever (public, MIT). `main` is protected by
  a ruleset (PR + `test`, `lint`, `safety` checks) once Paul imports
  `docs/github/protect-main-ruleset.json`.
- **CurseForge:** project ID **1808477** (author Pheubar). First file 0.1.4-beta uploaded by
  hand 2026-11-15, awaiting first approval. Link: https://www.curseforge.com/projects/1808477
- **Auto-release:** `.github/workflows/release.yml` + `.pkgmeta` (BigWigs packager). Repo secret
  `CF_API_KEY` is set. Push a tag `vX.Y.Z` (or `vX.Y.Z-beta`) to build and upload. Not yet
  exercised; the first tag should be watched.
- **Local checkout:** every addon repo lives under `D:\OneDrive\code\wow-addons\` on Paul's PC
  (this one at `D:\OneDrive\code\wow-addons\bagquests-forever`).
- **Paul's install:** `D:\Blizzard Games\World of Warcraft\_forever_\Interface\AddOns\`
  (folders `BagQuests`, `BagQuests_Alts`). Claude has copied betas there via device folder access.

## Architecture (FishShare style)
`BagQuests/Core/Domain.lua` pure Lua (Questline, Step, Evaluate, LevelFit) ·
`Data/*.lua` one file per questline · `Adapters/` (QuestState, Waypoints, Pins) ·
`App.lua` use cases + events · `UI/` (Tracker, SettingsPanel, MinimapButton, Commands).
`BagQuests_Alts/` optional module (Roster + AltsWindow) hooked via `App.OnRefresh`,
`App.RegisterCommand`, `App.OnSettings`.

Checks: `lua5.1 tests/run.lua && luacheck . && lua5.1 tests/safety.lua`.

## Verified in game (2026-11-15)
Quest IDs 79007 ("...and that note you found") and 96260 (Stronger than Steel), tracker,
alts table, Forever two-part names (`UnitName("player")` 2nd value = surname).
Everything else in `Data/` comes from community guides.

## Roadmap
1. ~~Alliance route for Cozy Sleeping Bag.~~ Done in 0.2.1-beta: a questline can have
   `routes` per faction. Alliance swaps only the first two stops (Westfall, then the Barrens)
   and starts with quest 79008, not 79007; Stonetalon onward is shared. Not verified in game.
2. Confirm remaining quest IDs/coords in play (`/bq verify`).
3. More bag quests (Deviate Hide Pack, Scuffed Shipping Crate, Thawpelt Sack, ...).
4. First tagged release through the pipeline.
5. Later/nice-to-have: professions per alt (Altoholic-style), sharing with friends.
