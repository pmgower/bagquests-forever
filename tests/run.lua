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
  local s2 = cozy.steps[2] -- suggested 24
  eq(D.LevelFit(cozy, s2, 12), D.FIT.BLOCKED)
  eq(D.LevelFit(cozy, s2, 20), D.FIT.LOW)
  eq(D.LevelFit(cozy, s2, 24), D.FIT.OK)
end)

test("Register rejects a step with no quest", function()
  local ok = pcall(D.Register, { id = "bad", steps = { { title = "x" } } })
  eq(ok, false)
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

test("login: tracker shows both lines' first steps and pins", function()
  local env = Fake.Session(ADDONS, saved, warlock)
  local w = env.ns.App.Workable(env.ns.App.last.results)
  eq(#w, 2, "workable lines")
  local lines = env.ns.Tracker.Lines(w[1], 24)
  truthy(lines[1]:find("Cozy Sleeping Bag"), "title line")
  truthy(lines[2]:find("Burned tower"), "step line")
  truthy(lines[3]:find("Req 14") and lines[3]:find("Suggested 22") and lines[3]:find("good level"), "level line")
  eq(#env.pinsPlaced.mini, 2, "one minimap pin per line")
  truthy(#env.pinsPlaced.world > 2, "later steps on world map")
  env.save()
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
  eq(#locked, 1, "steel shown as locked for the hunter")
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
  eq(#w, 1); eq(w[1].line.id, "stronger_than_steel")
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
  truthy(lines[#lines]:find("Shift"), "alts hint when module loaded")
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

test("alt tracking off: main addon works without the Alts module", function()
  local env = Fake.Session(ADDONS, {}, char({ name = "Solo", level = 30, alts = false }))
  eq(env.BagQuestsAltsDB, nil)
  env.SlashCmdList.BAGQUESTS("alts")
  truthy(hasPrint(env, "unknown command"), "alts command absent")
end)

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
