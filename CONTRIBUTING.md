# Contributing

Thanks for helping! A few guardrails keep players' games safe:

* **Read-only addon.** BagQuests reads quest state and draws UI. It never
  spends gold, moves or deletes items, sends chat or mail, accepts, abandons or
  turns in quests, or changes settings. `tests/safety.lua` enforces this on
  every pull request.
* **Every PR must pass three checks:** `test` (lua5.1 test suite), `lint`
  (luacheck; any new WoW API must be added to `.luacheckrc` read_globals), and
  `safety` (the scan above plus pinned hashes for `BagQuests/Libs`).
* **New questline?** Add a file in `BagQuests/Data/`, list it in
  `BagQuests.toc`, and add a test in `tests/run.lua`. Please link the source
  for quest IDs and coordinates.
* Only the maintainer merges. Workflows from first-time contributors wait for
  approval before they run.

Run everything locally:

    lua5.1 tests/run.lua && luacheck . && lua5.1 tests/safety.lua
