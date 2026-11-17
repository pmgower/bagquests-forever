-- Domain: pure Lua, no WoW API. Safe to load and test outside the game.
--
-- A Questline is an ordered list of Steps that ends in a bag (or other
-- reward). A Step is a place you go. Arriving there usually turns in one quest
-- and starts the next, so a step counts as done when the quest it turns in is
-- completed, or when the quest it starts is in your log or completed.
--
-- Progress is derived, never stored: Evaluate(line, snapshot) turns a
-- character snapshot (completed quests, active quests, level, faction, items)
-- into step states. The same function drives the on-screen list, the map
-- pins, and the alts table.
--
-- A Questline can take a different Route per faction (Alliance and Horde
-- visit places in a different order). Define either `steps` (one route for
-- everyone) or `routes = { Alliance = {...}, Horde = {...} }`; StepsFor picks
-- the one for a character.
local _, ns = ...
ns = ns or {}

local Domain = {}
ns.Domain = Domain

Domain.STEP = { DONE = "done", ACTIVE = "active", NEXT = "next", LATER = "later" }
Domain.LINE = {
  DONE = "done",               -- reward earned
  IN_PROGRESS = "in_progress", -- at least one step done
  AVAILABLE = "available",     -- can start now
  TOO_LOW = "too_low",         -- below minLevel
  WRONG_FACTION = "wrong_faction",
}

local registry, order = {}, {}

local function checkSteps(label, steps)
  assert(type(steps) == "table" and #steps > 0, label .. ": needs steps")
  for i, s in ipairs(steps) do
    assert(s.turnsIn or s.starts, label .. " step " .. i .. ": needs turnsIn or starts")
    assert(s.title, label .. " step " .. i .. ": needs a title")
  end
end

-- Validates and registers a questline definition (see Data/*.lua).
function Domain.Register(def)
  assert(type(def) == "table" and def.id, "questline needs an id")
  if def.routes then
    assert(not def.steps, def.id .. ": use steps or routes, not both")
    for faction, steps in pairs(def.routes) do checkSteps(def.id .. " (" .. faction .. ")", steps) end
    assert(def.defaultRoute and def.routes[def.defaultRoute], def.id .. ": needs a defaultRoute")
  else
    checkSteps(def.id, def.steps)
  end
  def.minLevel = def.minLevel or 1
  def.rewardItems = def.rewardItems or {}
  if not registry[def.id] then table.insert(order, def.id) end
  registry[def.id] = def
  return def
end

function Domain.Get(id) return registry[id] end

function Domain.All()
  local list = {}
  for _, id in ipairs(order) do table.insert(list, registry[id]) end
  return list
end

-- The steps this character follows: their faction's route, else the default
-- route (faction unknown), else the single shared route.
function Domain.StepsFor(line, faction)
  if not line.routes then return line.steps end
  return line.routes[faction] or line.routes[line.defaultRoute]
end

-- Every route of a questline (one for single-route lines).
local function allRoutes(line)
  if not line.routes then return { line.steps } end
  local list = {}
  for _, steps in pairs(line.routes) do table.insert(list, steps) end
  return list
end

function Domain.Reset() registry, order = {}, {} end -- tests only

local function has(set, id) return id ~= nil and set ~= nil and set[id] == true end

local function stepDone(step, snap)
  if has(snap.completed, step.turnsIn) then return true end
  if has(snap.completed, step.starts) or has(snap.active, step.starts) then return true end
  return false
end

local function ownsReward(line, snap)
  for _, itemID in ipairs(line.rewardItems) do
    if snap.items and (snap.items[itemID] or 0) > 0 then return true end
  end
  return false
end

-- snap = { completed = {[questID]=true}, active = {[questID]=true},
--          level = n, faction = "Horde"|"Alliance", items = {[itemID]=count},
--          skipped = {[lineID]=stepIndex} }  -- steps the player marked done by hand
-- Returns { line, status, done, total, current (index or nil), steps = {
--          { step, index, state, skipped } } }
function Domain.Evaluate(line, snap)
  snap = snap or {}
  local steps = Domain.StepsFor(line, snap.faction)
  local result = { line = line, steps = {}, total = #steps, done = 0 }

  -- Steps are sequential: once one is done, everything before it is too
  -- (covers quests turned in before the addon was installed).
  local lastDone = 0
  for i, step in ipairs(steps) do
    if stepDone(step, snap) then lastDone = i end
  end
  if ownsReward(line, snap) or has(snap.completed, steps[#steps].turnsIn) then
    lastDone = #steps
  end
  -- A skipped step counts as done, like RestedXP's "skip step": for when the
  -- game doesn't flag a step you did, or you want to jump ahead.
  local skippedTo = math.min(snap.skipped and snap.skipped[line.id] or 0, #steps)
  local gameDone = lastDone
  if skippedTo > lastDone then lastDone = skippedTo end
  result.skipped = skippedTo
  result.gameDone = gameDone -- steps the game itself shows as done

  for i, step in ipairs(steps) do
    local state
    if i <= lastDone then state = Domain.STEP.DONE
    elseif i == lastDone + 1 then
      -- The quest you carry to this step is the one the previous step started.
      local carrying = step.turnsIn and has(snap.active, step.turnsIn)
      state = carrying and Domain.STEP.ACTIVE or Domain.STEP.NEXT
      result.current = i
    else state = Domain.STEP.LATER end
    -- skipped: marked done by hand, not by the game.
    table.insert(result.steps, { step = step, index = i, state = state,
      skipped = i > gameDone and i <= skippedTo })
  end
  result.done = lastDone

  if lastDone == #steps then result.status = Domain.LINE.DONE
  elseif line.faction and snap.faction and line.faction ~= snap.faction then
    result.status = Domain.LINE.WRONG_FACTION; result.current = nil
  elseif lastDone > 0 then result.status = Domain.LINE.IN_PROGRESS
  elseif (snap.level or 0) < line.minLevel then result.status = Domain.LINE.TOO_LOW
  else result.status = Domain.LINE.AVAILABLE end
  return result
end

-- The step to show on screen: the current step of the first unfinished
-- questline this character can work on.
function Domain.NextStep(snap)
  for _, line in ipairs(Domain.All()) do
    local r = Domain.Evaluate(line, snap)
    if r.current and (r.status == Domain.LINE.IN_PROGRESS or r.status == Domain.LINE.AVAILABLE) then
      return r.steps[r.current], r
    end
  end
end

-- One-line summary for the alts table, e.g. "3/7" or "done".
function Domain.Summary(result)
  if result.status == Domain.LINE.DONE then return "done" end
  if result.status == Domain.LINE.WRONG_FACTION then return "-" end
  if result.status == Domain.LINE.TOO_LOW then return "lvl " .. result.line.minLevel end
  return string.format("%d/%d", result.done, result.total)
end

-- Every quest ID any registered questline cares about (for snapshots).
function Domain.TrackedQuestIDs()
  local ids = {}
  for _, line in ipairs(Domain.All()) do
    for _, steps in ipairs(allRoutes(line)) do
      for _, s in ipairs(steps) do
        if s.turnsIn then ids[s.turnsIn] = true end
        if s.starts then ids[s.starts] = true end
      end
    end
  end
  return ids
end

function Domain.TrackedItemIDs()
  local ids = {}
  for _, line in ipairs(Domain.All()) do
    for _, id in ipairs(line.rewardItems) do ids[id] = true end
    for _, id in ipairs(line.bonusItems or {}) do ids[id] = true end
  end
  return ids
end

local function norm(name) return (tostring(name or ""):lower():gsub("[^%w]", "")) end

-- Called when a quest is accepted. Returns nil when the ID is one we expect or
-- the quest isn't one of ours, otherwise { name, expected, actual, line }:
-- the quest's real ID in Forever differs from our data file. One name can
-- have several IDs (the Alliance and Horde copies of a quest).
function Domain.CheckQuestID(questID, title)
  if not title then return nil end
  local key = norm(title)
  local miss
  for _, line in ipairs(Domain.All()) do
    for id, name in pairs(line.quests or {}) do
      if norm(name) == key then
        if id == questID then return nil end
        miss = miss or { name = name, expected = id, actual = questID, line = line }
      end
    end
  end
  return miss
end

-- How well a character's level fits a step:
--   "ok" at or above suggested, "low" between required and suggested,
--   "blocked" below the questline's required level.
Domain.FIT = { OK = "ok", LOW = "low", BLOCKED = "blocked" }
function Domain.LevelFit(line, step, level)
  level = level or 0
  if level < line.minLevel then return Domain.FIT.BLOCKED end
  if level < (step.suggested or line.minLevel) then return Domain.FIT.LOW end
  return Domain.FIT.OK
end

-- WoW's quest-level colors relative to the player: red 5+ above you,
-- orange 3-4 above, yellow within 2, green below that, grey once trivial.
-- greenRange is how far below you a quest stays green (the game's
-- GetQuestGreenRange); without it we use the Classic rule of thumb.
Domain.DIFFICULTY = { RED = "red", ORANGE = "orange", YELLOW = "yellow", GREEN = "green", GREY = "grey" }
function Domain.Difficulty(questLevel, playerLevel, greenRange)
  local diff = questLevel - (playerLevel or 0)
  if diff >= 5 then return Domain.DIFFICULTY.RED end
  if diff >= 3 then return Domain.DIFFICULTY.ORANGE end
  if diff >= -2 then return Domain.DIFFICULTY.YELLOW end
  greenRange = greenRange or (math.floor((playerLevel or 0) / 10) + 5)
  if -diff <= greenRange then return Domain.DIFFICULTY.GREEN end
  return Domain.DIFFICULTY.GREY
end

return Domain
