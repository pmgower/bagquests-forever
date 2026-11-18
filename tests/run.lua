-- Test runner: lua5.1 tests/run.lua (from the bagquests folder)
local ROOT = (arg and arg[0] or "tests/run.lua"):gsub("tests/run%.lua$", "")
local passed, failed = 0, 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then passed = passed + 1; print("ok   " .. name)
  else failed = failed + 1; print("FAIL " .. name .. "\n     " .. tostring(err)) end
end
local function truthy(v, msg) if not v then error(msg or "expected truthy", 2) end end
local function eq(a, b, msg)
  if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end
end

local ns = {}
local function load(path) assert(loadfile(ROOT .. "BagQuests/" .. path))("BagQuests", ns) end
load("Core/Domain.lua"); load("Data/CozySleepingBag.lua"); load("Data/StrongerThanSteel.lua")
local D = ns.Domain
local cozy, steel = D.Get("cozy_sleeping_bag"), D.Get("stronger_than_steel")
local function set(...) local s = {} for _, v in ipairs({ ... }) do s[v] = true end return s end

test("registry keeps load order", function()
  eq(#D.All(), 2); eq(D.All()[1].id, "cozy_sleeping_bag")
end)

test("fresh level 10 Horde: cozy too low, steel too low", function()
  local snap = { level = 10, faction = "Horde" }
  eq(D.Evaluate(cozy, snap).status, D.LINE.TOO_LOW)
  eq(D.Summary(D.Evaluate(steel, snap)), "lvl 23")
end)

test("level 20 Horde: cozy available, first step is next", function()
  local r = D.Evaluate(cozy, { level = 20, faction = "Horde" })
  eq(r.status, D.LINE.AVAILABLE); eq(r.current, 1); eq(r.steps[1].state, D.STEP.NEXT)
end)

test("carrying the note: step 1 done, step 2 active", function()
  local r = D.Evaluate(cozy, { level = 24, faction = "Horde", active = set(79007) })
  eq(r.done, 1); eq(r.current, 2); eq(r.steps[2].state, D.STEP.ACTIVE)
  eq(D.Summary(r), "1/7")
end)

test("only a later quest flagged: earlier steps count as done", function()
  local r = D.Evaluate(cozy, { level = 30, completed = set(79974) })
  eq(r.done, 5); eq(r.current, 6); eq(r.steps[3].state, D.STEP.DONE)
end)

test("owning the sleeping bag marks the line done", function()
  local r = D.Evaluate(cozy, { level = 40, items = { [211527] = 1 } })
  eq(r.status, D.LINE.DONE); eq(r.current, nil); eq(D.Summary(r), "done")
end)

test("final turn-in marks the line done even if the bag was banked", function()
  eq(D.Evaluate(cozy, { completed = set(79976) }).status, D.LINE.DONE)
end)

test("Alliance sees steel as wrong faction", function()
  local r = D.Evaluate(steel, { level = 30, faction = "Alliance" })
  eq(r.status, D.LINE.WRONG_FACTION); eq(D.Summary(r), "-")
end)

test("NextStep picks the first workable line", function()
  local step, r = D.NextStep({ level = 25, faction = "Horde", completed = set(79976) })
  eq(r.line.id, "stronger_than_steel"); eq(step.index, 1)
end)

test("NextStep is nil when everything is done", function()
  eq(D.NextStep({ level = 30, faction = "Horde", completed = set(79976, 96260) }), nil)
end)

test("LevelFit: blocked below req, low below suggested, ok above", function()
  local s2 = D.StepsFor(cozy, "Horde")[2] -- suggested 24
  eq(D.LevelFit(cozy, s2, 12), D.FIT.BLOCKED)
  eq(D.LevelFit(cozy, s2, 20), D.FIT.LOW)
  eq(D.LevelFit(cozy, s2, 24), D.FIT.OK)
end)

test("Alliance route: Westfall first, then the Barrens, then the shared steps", function()
  local a, h = D.StepsFor(cozy, "Alliance"), D.StepsFor(cozy, "Horde")
  eq(#a, 7); eq(a[1].mapID, 1436, "Westfall first"); eq(a[2].mapID, 1413, "Barrens second")
  eq(a[1].starts, 79008); eq(a[2].turnsIn, 79008)
  eq(h[1].starts, 79007)
  for i = 3, 7 do eq(a[i], h[i], "step " .. i .. " shared") end
  eq(D.StepsFor(cozy, nil), h, "unknown faction falls back to Horde")
  eq(D.StepsFor(steel, "Alliance"), steel.steps, "single-route line")
end)

test("Alliance carrying the note: step 2 is the Barrens tower", function()
  local r = D.Evaluate(cozy, { level = 24, faction = "Alliance", active = set(79008) })
  eq(r.status, D.LINE.IN_PROGRESS); eq(r.current, 2); eq(r.steps[2].state, D.STEP.ACTIVE)
  truthy(r.steps[2].step.title:find("Burned tower"))
  eq(D.Evaluate(cozy, { level = 24, faction = "Horde", active = set(79008) }).done, 0,
    "the Alliance note does not move a Horde character")
end)

test("both factions' first quests are tracked and verified", function()
  local ids = D.TrackedQuestIDs()
  truthy(ids[79007] and ids[79008] and ids[79976])
  eq(D.CheckQuestID(79008, "...and that note you found"), nil, "Alliance ID is expected")
  eq(D.CheckQuestID(79007, "...and that note you found"), nil, "Horde ID is expected")
  truthy(D.CheckQuestID(12345, "...and that note you found"), "unknown ID still flagged")
end)

test("Register rejects routes without a defaultRoute", function()
  local ok = pcall(D.Register, { id = "bad2", routes = { Horde = { { title = "x", starts = 1 } } } })
  eq(ok, false)
end)

test("a skipped step counts as done; skipping the last step finishes the line", function()
  local r = D.Evaluate(cozy, { level = 24, faction = "Horde", skipped = { cozy_sleeping_bag = 2 } })
  eq(r.done, 2); eq(r.current, 3); eq(r.skipped, 2); eq(r.steps[2].state, D.STEP.DONE)
  eq(D.Evaluate(cozy, { level = 30, completed = set(79974), skipped = { cozy_sleeping_bag = 2 } }).current, 6,
    "real progress past the skip wins")
  eq(D.Evaluate(cozy, { skipped = { cozy_sleeping_bag = 99 } }).status, D.LINE.DONE)
  eq(D.Evaluate(steel, { level = 30, faction = "Horde", skipped = { cozy_sleeping_bag = 2 } }).done, 0,
    "skips are per questline")
end)

test("Stronger than Steel: required 23 to pick up, quest level 29", function()
  eq(steel.minLevel, 23); eq(steel.steps[1].suggested, 29); eq(steel.steps[2].suggested, 29)
  eq(D.LevelFit(steel, steel.steps[1], 25), D.FIT.LOW, "level 25 can take it but is under the quest level")
end)

test("Register rejects a step with no quest", function()
  local ok = pcall(D.Register, { id = "bad", steps = { { title = "x" } } })
  eq(ok, false)
end)

---------------------------------------------------------------- data files
-- Every data file the TOC loads, checked for the mistakes a typo would cause.
local function tocDataFiles()
  local files = {}
  for line in io.lines(ROOT .. "BagQuests/BagQuests.toc") do
    local f = line:match("^Data\\(.+%.lua)")
    if f then table.insert(files, f) end
  end
  return files
end

test("every data file: valid steps, quest names listed, slots and pins set", function()
  local dns = {}
  assert(loadfile(ROOT .. "BagQuests/Core/Domain.lua"))("BagQuests", dns)
  local files = tocDataFiles()
  truthy(#files >= 9, "TOC lists the data files")
  for _, f in ipairs(files) do assert(loadfile(ROOT .. "BagQuests/Data/" .. f))("BagQuests", dns) end
  local seenQuest = {}
  for _, line in ipairs(dns.Domain.All()) do
    truthy(line.slots and line.slots >= 10, line.id .. ": slots >= 10")
    truthy(#line.rewardItems > 0, line.id .. ": reward item")
    local routes = line.routes or { only = line.steps }
    for name, steps in pairs(routes) do
      local last = steps[#steps]
      truthy(last.turnsIn and last.reward, line.id .. " " .. name .. ": last step turns in the reward quest")
      for i, st in ipairs(steps) do
        for _, q in ipairs({ st.turnsIn, st.starts }) do
          truthy(line.quests[q], line.id .. " step " .. i .. ": quest " .. q .. " has a name for /bq verify")
          truthy(seenQuest[q] == nil or seenQuest[q] == line.id, "quest " .. q .. " used by two questlines")
          seenQuest[q] = line.id
        end
        truthy(st.mapID or st.where, line.id .. " step " .. i .. ": needs a map pin or a where text")
        truthy(st.suggested and st.suggested >= line.minLevel,
          line.id .. " step " .. i .. ": suggested level (the quest's level) is at least the required level")
        if st.mapID then
          truthy(st.x > 0 and st.x < 100 and st.y > 0 and st.y < 100, line.id .. " step " .. i .. ": coords 0-100")
        end
        if i > 1 and st.turnsIn and steps[i - 1].starts then
          -- consecutive steps chain: the quest you carry was started one step earlier,
          -- unless the previous step only turned something in (a new giver starts the next quest)
          truthy(steps[i - 1].starts == st.turnsIn, line.id .. " step " .. i .. ": turns in what step " .. (i - 1) .. " started")
        end
      end
    end
  end
end)

test("Thawpelt Sack: Alliance turns in at Ironforge, Horde at Thunder Bluff", function()
  local dns = {}
  assert(loadfile(ROOT .. "BagQuests/Core/Domain.lua"))("BagQuests", dns)
  assert(loadfile(ROOT .. "BagQuests/Data/PlatinumDiscs.lua"))("BagQuests", dns)
  local D2 = dns.Domain
  local line = D2.Get("platinum_discs")
  eq(D2.StepsFor(line, "Alliance")[4].mapID, 1455); eq(D2.StepsFor(line, "Horde")[4].mapID, 1456)
  local r = D2.Evaluate(line, { level = 45, faction = "Alliance", completed = set(2278), active = set(2279) })
  eq(r.current, 3); eq(r.steps[3].state, D2.STEP.ACTIVE)
  eq(D2.Evaluate(line, { level = 45, faction = "Horde", completed = set(2440) }).status, D2.LINE.DONE)
end)

---------------------------------------------------------------- game sim
local Fake = dofile(ROOT .. "tests/wow.lua")
local ADDONS = ROOT
local saved = {}
local function char(t)
  t.completed = t.completed or {}; t.log = t.log or {}; t.items = t.items or {}
  t.faction = t.faction or "Horde"; t.class = t.class or "WARLOCK"
  return t
end
local function hasPrint(env, pat)
  for _, m in ipairs(env.printed) do if m:find(pat) then return true end end
  return false
end

local warlock = char({ name = "Pheuneral", surname = "Undertaker", level = 24, class = "WARLOCK" })
local hunter = char({ name = "Pheuhunt", level = 15, class = "HUNTER" })

local function lineIds(list)
  local ids = {}
  for _, r in ipairs(list) do table.insert(ids, r.line.id) end
  return table.concat(ids, ",")
end

test("login: tracker shows each workable line's first step and pins", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local w = env.ns.App.Workable(env.ns.App.last.results)
  eq(lineIds(w), "cozy_sleeping_bag,stronger_than_steel,deviate_hides", "workable lines")
  local lines = env.ns.Tracker.Lines(w[1], 24)
  truthy(lines[1]:find("Cozy Sleeping Bag"), "title line")
  truthy(lines[2]:find("Burned tower"), "step line")
  truthy(lines[3]:find("Req.|r |cffffffffLvl 14") and lines[3]:find("Sug.|r |cffffd100Lvl 22") and not lines[3]:find("good level"), "level line, yellow at 24")
  eq(#env.pinsPlaced.mini, 3, "one minimap pin per line")
  truthy(#env.pinsPlaced.world > 2, "later steps on world map")
  env.save()
end)

test("minimap pins never reuse a world map frame (pin stuck to the player)", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local cb = env.settingsUI.checkboxes
  local role = {}
  local function check()
    for _, p in ipairs(env.pinsPlaced.world) do
      truthy(role[p.icon] ~= "mini", "world map icon was a minimap icon before")
      role[p.icon] = "world"
    end
    for _, p in ipairs(env.pinsPlaced.mini) do
      truthy(role[p.icon] ~= "world", "minimap icon was a world map icon before")
      role[p.icon] = "mini"
    end
  end
  check()
  -- Changing the pin set reorders frames; the old single pool swapped roles here.
  for _, v in ipairs({ false, true, false, true }) do cb.showLaterPins:SetValue(v); check() end
  cb.minimapPins:SetValue(false); check(); cb.minimapPins:SetValue(true); check()
end)

test("accepting the note moves the tracker to Westfall", function()
  table.insert(warlock.log, { questID = 79007, title = "...and that note you found" })
  local env = Fake.Session(ADDONS, saved, warlock)
  env.fire("QUEST_ACCEPTED", 79007)
  local step, r = env.ns.App.NextStep()
  eq(r.current, 2); truthy(step.title:find("Alexston"))
  truthy(not hasPrint(env, "mismatch"), "no mismatch for a correct ID")
  env.SlashCmdList.BAGQUESTS("way")
  eq(env.lastWaypoint.m, 1436, "waypoint map")
  env.save()
end)

test("a wrong quest ID in our data is reported", function()
  table.insert(warlock.log, { questID = 99999, title = "Stepping Stones" })
  local env = Fake.Session(ADDONS, saved, warlock)
  env.fire("QUEST_ACCEPTED", 99999)
  truthy(hasPrint(env, "mismatch"), "mismatch printed")
  eq(env.BagQuestsDB.mismatches["Stepping Stones"].actual, 99999)
  table.remove(warlock.log)
  env.BagQuestsDB.mismatches = {}
  env.save()
end)

test("second character joins the alts table", function()
  local env = Fake.Session(ADDONS, saved, hunter)
  local grid = env.altsNs.AltsWindow.Grid(env.BagQuestsAltsDB.characters, env.ns.Domain)
  eq(#grid, 3, "header + 2 characters")
  truthy(grid[2][1]:find("Pheuneral Undertaker"), "highest level first, surname shown by default")
  eq(env.BagQuestsAltsDB.characters["Pheuneral-CAMWOW"].class, "WARLOCK", "class token saved")
  eq(env.altsNs.AltsWindow.DisplayName(env.BagQuestsAltsDB.characters["Pheuneral-CAMWOW"], { hideSurnames = true }), "Pheuneral")
  eq(env.altsNs.AltsWindow.DisplayName(env.BagQuestsAltsDB.characters["Pheuhunt-CAMWOW"]), "Pheuhunt", "no surname -> first name only")
  truthy(grid[2][3]:find("1/7"), "warlock cozy progress")
  truthy(grid[3][4]:find("lvl 23"), "hunter too low for steel")
  truthy(grid[3][3]:find("sugg 22"), "hunter flagged low for cozy step 1")
  local locked = env.ns.App.Locked(env.ns.App.last.results)
  eq(lineIds(locked), "stronger_than_steel,cortellos_riddle,platinum_discs,hyjal_postal",
    "level-locked lines for the level 15 hunter; Alliance-only lines are left out")
  env.SlashCmdList.BAGQUESTS("alts")
  eq(env.altsNs.AltsWindow.IsShown(), true, "first /bq alts opens the window")
  env.SlashCmdList.BAGQUESTS("alts")
  eq(env.altsNs.AltsWindow.IsShown(), false, "second /bq alts closes it")
  env.save()
end)

test("finishing the chain clears it from the tracker", function()
  warlock.completed[79976] = true; warlock.items[211527] = 1; warlock.log = {}
  local env = Fake.Session(ADDONS, saved, warlock)
  local w = env.ns.App.Workable(env.ns.App.last.results)
  eq(lineIds(w), "stronger_than_steel,deviate_hides")
  env.SlashCmdList.BAGQUESTS("verify")
  truthy(hasPrint(env, "79976 This Must Be the Place: .*completed"), "verify lists completion")
  env.save()
end)

test("settings page: registered, checkboxes change behavior, alts row added", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  truthy(env.settingsUI.registered, "category registered")
  local cb = env.settingsUI.checkboxes
  for _, key in ipairs({ "tracker", "locked", "minimapButton", "minimapPins", "showLaterPins", "hideSurnames" }) do
    truthy(cb[key], "checkbox " .. key)
  end
  cb.minimapPins:SetValue(false)
  eq(#env.pinsPlaced.mini, 0, "minimap pins off")
  cb.minimapPins:SetValue(true)
  truthy(#env.pinsPlaced.mini > 0, "minimap pins back")
  cb.minimapButton:SetValue(false)
  eq(env.minimapIcon.shown, false, "minimap button hidden")
  eq(env.BagQuestsDB.minimapIcon.hide, true, "hide saved for LibDBIcon")
  cb.minimapButton:SetValue(true)
  eq(env.minimapIcon.shown, true)
  local dd = env.settingsUI.dropdowns and env.settingsUI.dropdowns.theme
  truthy(dd, "color scheme dropdown")
  eq(#dd.options, 4, "all four schemes offered")
  eq(dd.options[1].label, "Frost Steel", "default listed first")
  dd.setting:SetValue("twilight")
  eq(env.ns.Window.Current().key, "twilight", "dropdown applies the scheme")
  dd.setting:SetValue("frost")
  cb.hideSurnames:SetValue(true)
  eq(env.BagQuestsAltsDB.settings.hideSurnames, true, "alts setting stored in alts DB")
  cb.hideSurnames:SetValue(false)
  env.SlashCmdList.BAGQUESTS("settings")
  eq(env.settingsUI.opened, 42, "/bq settings opens the page")
  env.save()
end)

test("minimap button: tooltip shows next step, clicks route correctly", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local lines = env.ns.MinimapButton.TooltipLines()
  truthy(lines[2]:find("Next:"), "next step line")
  truthy(lines[#lines - 1]:find("Shift"), "alts hint when module loaded")
  truthy(lines[#lines]:find("Ctrl"), "report-a-bug hint last")
  local before = env.BagQuestsDB.settings.tracker
  env.ns.MinimapButton.OnClick("LeftButton")
  eq(env.BagQuestsDB.settings.tracker, not before, "left-click toggles tracker")
  env.ns.MinimapButton.OnClick("LeftButton")
  env.ns.MinimapButton.OnClick("RightButton")
  eq(env.settingsUI.opened, 42, "right-click opens settings")
  env.shiftDown = true
  env.ns.MinimapButton.OnClick("LeftButton")
  eq(env.altsNs.AltsWindow.IsShown(), true, "shift-click opens alts")
  env.save()
end)

test("Alliance character: tracker starts in Westfall, alts table shows their route", function()
  local paladin = char({ name = "Pheulight", level = 22, class = "PALADIN", faction = "Alliance" })
  local env = Fake.Session(ADDONS, saved, paladin)
  local w = env.ns.App.Workable(env.ns.App.last.results)
  eq(lineIds(w), "cozy_sleeping_bag,deviate_hides,vyrins_revenge,night_watch,digging_through_the_ooze",
    "steel is Horde-only; Alliance bag quests appear")
  truthy(env.ns.Tracker.Lines(w[1], 22)[2]:find("Alexston"), "Westfall step first")
  table.insert(paladin.log, { questID = 79008, title = "...and that note you found" })
  env.fire("QUEST_ACCEPTED", 79008)
  truthy(not hasPrint(env, "mismatch"), "79008 is not a mismatch")
  local step = env.ns.App.NextStep()
  truthy(step.title:find("Burned tower"), "then the Barrens")
  local rows = env.altsNs.Roster.Rows(env.BagQuestsAltsDB.characters, env.ns.Domain)
  for _, row in ipairs(rows) do
    if row.char.name == "Pheulight" then eq(row.cells[1].next, step.title, "alts row uses Alliance route") end
  end
  env.save()
end)

test("tracking choices: untick a questline in settings or with /bq track", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local cb = env.settingsUI.checkboxes
  truthy(cb.track_deviate_hides and cb.track_hyjal_postal, "one Track checkbox per questline")
  truthy(cb.track_hyjal_postal.label:find("18 slots") and cb.track_hyjal_postal.label:find("lvl 56"), "label shows slots and level")
  cb.track_deviate_hides:SetValue(false)
  eq(lineIds(env.ns.App.Workable(env.ns.App.last.results)), "stronger_than_steel", "deviate gone from tracker")
  for _, p in ipairs(env.pinsPlaced.world) do truthy(not p.step.title:find("Nalpak"), "and from the map") end
  local grid = env.altsNs.AltsWindow.Grid(env.BagQuestsAltsDB.characters, env.ns.Domain)
  for _, h in ipairs(grid[1]) do truthy(h ~= "Deviate Hide Pack", "and from the alts table") end
  env.SlashCmdList.BAGQUESTS("track")
  truthy(hasPrint(env, "%[ %] Deviate Hide Pack"), "/bq track lists it as off")
  env.SlashCmdList.BAGQUESTS("track 3")
  truthy(hasPrint(env, "Deviate Hide Pack: tracked"), "/bq track 3 turns it back on")
  eq(cb.track_deviate_hides.tbl.track_deviate_hides, true)
  env.save()
end)

test("skip step: right-click a tracker line, /bq skip, /bq unskip; per character", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local r = env.ns.App.Workable(env.ns.App.last.results)[1]
  eq(r.line.id, "stronger_than_steel"); eq(r.current, 1)
  local row = env.ns.Tracker.RowAt(1)
  row._onOnClick(row, "RightButton")
  truthy(hasPrint(env, "skipped"), "skip printed")
  r = env.ns.App.Workable(env.ns.App.last.results)[1]
  eq(r.current, 2, "tracker moved to step 2")
  env.SlashCmdList.BAGQUESTS("skip 2")
  eq(env.ns.App.Workable(env.ns.App.last.results)[2].current, 2, "/bq skip 2 skips the 2nd line (deviate)")
  env.save()
  local env2 = Fake.Session(ADDONS, saved, hunter)
  local hr = env2.ns.App.last.results
  for _, x in ipairs(hr) do if x.line.id == "deviate_hides" then eq(x.current, 1, "hunter keeps their own progress") end end
  env2.save()
  local env3 = Fake.Session(ADDONS, saved, warlock)
  eq(env3.ns.App.Workable(env3.ns.App.last.results)[1].current, 2, "skip survives a relog")
  env3.SlashCmdList.BAGQUESTS("unskip")
  eq(env3.ns.App.Workable(env3.ns.App.last.results)[1].current, 1, "unskip restores")
  env3.save()
end)

test("tracker window: resize grip saves size, reset clears it, themes switch", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local s = env.ns.App.Settings()
  eq(s.theme, "frost", "default theme")
  local grip = env.ns.Tracker.Grip()
  grip._onOnMouseDown(grip, "LeftButton")
  grip._onOnMouseUp(grip, "LeftButton")
  truthy(s.size and s.size[1] and s.size[2], "size saved after a resize")
  truthy(s.point, "position saved after a resize")
  env.SlashCmdList.BAGQUESTS("theme twilight")
  eq(s.theme, "twilight"); truthy(hasPrint(env, "theme: Twilight"))
  truthy(env.ns.Tracker.Lines(env.ns.App.Workable(env.ns.App.last.results)[1], 24)[1]:find("cdb9ff"), "title uses theme color")
  env.SlashCmdList.BAGQUESTS("theme")
  eq(s.theme, "classic", "no name cycles to the next scheme")
  env.SlashCmdList.BAGQUESTS("theme pink")
  eq(s.theme, "classic"); truthy(hasPrint(env, "unknown theme"))
  env.save()
  local env2 = Fake.Session(ADDONS, saved, warlock)
  local s2 = env2.ns.App.Settings()
  truthy(s2.size, "size survives a relog"); eq(s2.theme, "classic", "theme survives a relog")
  env2.SlashCmdList.BAGQUESTS("alts")
  truthy(env2.BagQuestsAltsDB.settings.window, "alts window has its own saved spot")
  env2.BagQuestsAltsDB.settings.window.size = { 500, 300 }
  env2.SlashCmdList.BAGQUESTS("reset")
  eq(env2.BagQuestsAltsDB.settings.window.size, nil, "reset covers the alts window")
  eq(s2.size, nil); eq(s2.point, nil)
  env2.SlashCmdList.BAGQUESTS("theme frost")
  env2.save()
end)

test("tracker hints: skipped pips, shift-right-click undo, tooltip, version", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local T = env.ns.Tracker
  local r = env.ns.App.Workable(env.ns.App.last.results)[1]
  eq(r.line.id, "stronger_than_steel")
  truthy(T.Pips(r):find("ring:9"), "current step is a ring")
  local row = T.RowAt(1)
  row._onOnClick(row, "RightButton")
  r = env.ns.App.Workable(env.ns.App.last.results)[1]
  eq(r.steps[1].skipped, true, "step 1 flagged skipped"); eq(r.steps[2].skipped, false)
  truthy(T.Pips(r):find("ring%-skip"), "skipped pip shown")
  truthy(table.concat(T.TooltipLines(r), "\n"):find("1 skipped"), "tooltip offers undo")
  truthy(table.concat(T.TooltipLines(r), "\n"):find("Step 2 of 2"), "tooltip has the count")
  env.IsShiftKeyDown = function() return true end
  row._onOnClick(row, "RightButton")
  env.IsShiftKeyDown = nil
  r = env.ns.App.Workable(env.ns.App.last.results)[1]
  eq(r.current, 1, "shift-right-click undid the skip"); eq(r.steps[1].skipped, false)
  truthy(not table.concat(T.TooltipLines(r), "\n"):find("skipped"), "no undo line without skips")
  row._onOnClick(row, "LeftButton")
  eq(T.navStep, r.steps[1].step, "left-click marks the step you're navigating to")
  local long = { total = 14, current = 3, steps = {} }
  eq(T.Pips(long), "|cff8888883/14|r", "long chains use n/N")
  env.save()
end)

test("tracker drags from a step row", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local s = env.ns.App.Settings()
  local row = env.ns.Tracker.RowAt(1)
  truthy(row._onOnDragStart, "rows forward drags to the window")
  s.point = nil
  row._onOnDragStart(row); row._onOnDragStop(row)
  truthy(s.point, "dragging a row moves and saves the window")
  env.save()
end)

test("tracker shows the reward bag's slot count", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local r = env.ns.App.Workable(env.ns.App.last.results)[1]
  truthy(env.ns.Tracker.Lines(r, 24)[1]:find(r.line.slots .. " slots"), "title line has slots")
  eq(env.ns.Tracker.SlotsText({}), "", "no slots, no text")
  env.save()
end)

test("level colors follow the game's quest colors", function()
  local Dif = D.DIFFICULTY
  eq(D.Difficulty(25, 20), Dif.RED); eq(D.Difficulty(23, 20), Dif.ORANGE)
  eq(D.Difficulty(22, 20), Dif.YELLOW); eq(D.Difficulty(18, 20), Dif.YELLOW)
  eq(D.Difficulty(17, 20), Dif.GREEN); eq(D.Difficulty(14, 20), Dif.GREEN)
  eq(D.Difficulty(13, 20), Dif.GREY, "grey level at 20 is 13")
  eq(D.Difficulty(48, 50), Dif.YELLOW); eq(D.Difficulty(40, 50), Dif.GREEN); eq(D.Difficulty(39, 50), Dif.GREY)
  eq(D.Difficulty(1, 5), Dif.GREEN, "nothing is grey at level 5")
  eq(D.Difficulty(10, 20, 10), Dif.GREEN, "uses the game's green range when given")
end)

test("alt tracking off: main addon works without the Alts module", function()
  local env = Fake.Session(ADDONS, {}, char({ name = "Solo", level = 30, alts = false }))
  eq(env.BagQuestsAltsDB, nil)
  env.SlashCmdList.BAGQUESTS("alts")
  truthy(hasPrint(env, "unknown command"), "alts command absent")
end)

test("feedback report: pure formatter", function()
  local F = assert(loadfile(ROOT .. "BagQuests/Core/Feedback.lua"))("BagQuests", ns)
  local text = F.Report({
    version = "0.2.0-beta", altsLoaded = true,
    client = { version = "1.16.1", build = "99999", date = "Nov 1 2026", interface = 16001, locale = "enUS" },
    character = { level = 24, race = "Scourge", class = "WARLOCK", faction = "Horde", realm = "CAMWOW" },
    settings = { tracker = true, locked = false, track_deviate_hides = false },
    untracked = { "deviate_hides" },
    results = { D.Evaluate(cozy, { level = 24, faction = "Horde", skipped = { cozy_sleeping_bag = 2 } }) },
    questsInLog = { 79007 }, mismatches = { ["Some Quest"] = { expected = 1, actual = 2 } },
    addons = { TomTom = true, Questie = false }, errors = { "boom" },
  })
  truthy(text:find("Addon: 0.2.0-beta (Alts module loaded)", 1, true), "version line")
  truthy(text:find("Client: 1.16.1 build 99999 (Nov 1 2026), interface 16001, locale enUS", 1, true), "client line")
  truthy(text:find("Character: level 24 Scourge WARLOCK, Horde, realm CAMWOW", 1, true), "character line")
  truthy(text:find("Settings: locked=off, tracker=on\n", 1, true), "settings sorted, track_* left out")
  truthy(text:find("Not tracked: deviate_hides", 1, true), "untracked")
  truthy(text:find("cozy_sleeping_bag: in_progress 2/%d+, next step 3 \"[^\"]+\" %(next%), skipped to 2"), "questline line")
  truthy(text:find("Our quests in log: 79007", 1, true), "log ids")
  truthy(text:find("Some Quest (Forever 2, data 1)", 1, true), "mismatch")
  truthy(text:find("Other addons: Questie not loaded, TomTom loaded", 1, true), "addons")
  truthy(text:find("Errors this session: 1\n  boom", 1, true), "errors")
end)

test("feedback issue link: prefills the bug form, falls back when too long", function()
  local F = ns.Feedback
  local url, prefilled = F.IssueUrl("line 1\nlevel 24 & 50% \"x\"")
  truthy(prefilled, "short report is prefilled")
  eq(url, F.BUG_FORM_URL .. "&feedback=line%201%0Alevel%2024%20%26%2050%25%20%22x%22"
    .. "&body=%60%60%60%0Aline%201%0Alevel%2024%20%26%2050%25%20%22x%22%0A%60%60%60", "form field plus plain body")
  local decoded = url:match("&feedback=([^&]*)"):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  eq(decoded, "line 1\nlevel 24 & 50% \"x\"", "round trip")
  local mid = F.IssueUrl(string.rep("x", math.floor(F.MAX_URL * 0.6)))
  truthy(mid:find("&feedback=", 1, true) and not mid:find("&body=", 1, true), "too long for both: form field only")
  local long, ok = F.IssueUrl(string.rep("x", F.MAX_URL))
  eq(long, F.BUG_FORM_URL); eq(ok, false, "too long falls back to the plain form")
end)

test("/bq feedback opens the copy window without the character's name", function()
  local env = Fake.Session(ADDONS, {}, char({ name = "Pheuneral", surname = "Undertaker", level = 24,
    log = { { questID = 79007, title = "Cozy start" }, { questID = 12345, title = "Not ours" } } }))
  env.SlashCmdList.BAGQUESTS("feedback")
  local W = env.ns.FeedbackWindow
  truthy(W.IsShown(), "window shown")
  truthy(W.url:find("issues/new?template=bug_report.yml&feedback=BagQuests%20feedback%20report%0A", 1, true), "link prefills the bug form")
  truthy(not W.url:find("Pheuneral"), "no character name in the link")
  local text = W.report
  truthy(text:find("Addon: " .. env.ns.App.VERSION .. " (Alts module loaded)", 1, true), "version and alts")
  truthy(text:find("level 24 Scourge WARLOCK, Horde, realm CAMWOW", 1, true), "character")
  truthy(text:find("locale enUS", 1, true), "client")
  truthy(text:find("Our quests in log: 79007\n", 1, true), "only our quest IDs")
  truthy(not text:find("Pheuneral") and not text:find("Undertaker"), "no character name")
  truthy(text:find("Errors this session: none", 1, true), "no errors")
  truthy(hasPrint(env, "Ctrl%+C"), "chat hint")
  env.SlashCmdList.BAGQUESTS("theme twilight")
  truthy(W.IsShown(), "theme change recolors the open feedback window without errors")
  env.ns.App.RecordError("x"); for _ = 1, 6 do env.ns.App.RecordError("y") end
  eq(#env.ns.App.errors, 5, "error buffer capped")
end)

test("feedback errors: only ours, short stack", function()
  local F = ns.Feedback
  truthy(F.IsOurs("Interface/AddOns/BagQuests/UI/Tracker.lua:12: boom"), "our file in the message")
  truthy(F.IsOurs("boom", "[string]\nInterface\\AddOns\\BagQuests_Alts\\Roster.lua:3: in function"), "Alts, backslashes, in the stack")
  truthy(not F.IsOurs("Interface/AddOns/Questie/Q.lua:1: x", "Interface/AddOns/Questie/Q.lua:1"), "someone else's error")
  local stack = "Interface/AddOns/Other/a.lua:1\n" .. string.rep("Interface/AddOns/BagQuests/App.lua:9: in function\n", 6)
  local short = F.ShortError("boom", stack)
  local _, lines = short:gsub("\n", "")
  eq(lines, 4, "message + 4 of our stack lines")
  truthy(not short:find("Other"), "other addons' frames dropped")
  truthy(#F.ShortError(string.rep("x", 2000)) <= F.MAX_ERROR_LEN + 3, "long error cut")
end)

test("addon errors: prompt once, report includes it, other addons ignored", function()
  local env = Fake.Session(ADDONS, {}, char({ name = "Err", level = 20 }))
  local W, App = env.ns.FeedbackWindow, env.ns.App
  env.raiseError("Interface/AddOns/Questie/Q.lua:1: not ours")
  eq(#App.errors, 0, "other addon's error not recorded"); truthy(not W.IsPromptShown(), "no prompt")
  eq(#env.handled, 1, "previous handler still gets every error")
  env.raiseError("Interface/AddOns/BagQuests/UI/Tracker.lua:42: attempt to index nil",
    "Interface/AddOns/BagQuests/UI/Tracker.lua:42: in function <Render>")
  eq(#env.handled, 2, "previous handler gets ours too")
  truthy(W.IsPromptShown(), "prompt shown"); truthy(W.promptMessage:find("Tracker.lua:42", 1, true), "prompt names the error")
  W.reportButton._onOnClick()
  truthy(not W.IsPromptShown(), "prompt closes"); truthy(W.IsShown(), "feedback window opens")
  truthy(W.report:find("Errors this session: 1\n  Interface/AddOns/BagQuests/UI/Tracker.lua:42", 1, true), "error in report")
  truthy(W.report:find("in function <Render>", 1, true), "stack line in report")
  W.promptMessage = nil
  env.raiseError("Interface/AddOns/BagQuests/App.lua:1: again")
  eq(W.promptMessage, nil, "only one prompt per session"); eq(#App.errors, 2, "still recorded")
end)

test("addon errors: setting off means no prompt", function()
  local env = Fake.Session(ADDONS, {}, char({ name = "Quiet", level = 20 }))
  env.settingsUI.checkboxes.errorPrompt:SetValue(false)
  env.raiseError("Interface/AddOns/BagQuests/App.lua:1: boom")
  truthy(not env.ns.FeedbackWindow.IsPromptShown(), "no prompt"); eq(#env.ns.App.errors, 1, "still recorded")
end)

test("report a bug from the UI: settings button and minimap ctrl-click", function()
  local env = Fake.Session(ADDONS, {}, char({ name = "Ui", level = 20 }))
  local b = env.settingsUI.buttons[1]
  eq(b and b.text, "Report a bug", "settings button")
  b.click(); truthy(env.ns.FeedbackWindow.IsShown(), "button opens the window")
  local found = false
  for _, l in ipairs(env.ns.MinimapButton.TooltipLines()) do if l:find("Ctrl%-click") then found = true end end
  truthy(found, "minimap tooltip hint")
  env.ns.FeedbackWindow.url = nil
  env.ctrlDown = true; env.ns.MinimapButton.OnClick("LeftButton"); env.ctrlDown = false
  truthy(env.ns.FeedbackWindow.url, "ctrl-click opens feedback")
end)

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
