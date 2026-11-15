-- A tiny fake WoW client: enough API for BagQuests to load and run.
-- Each Session() is one login; SavedVariables carry over between sessions.
local Fake = {}

local function stub()
  local s = {}
  local mt = {}
  mt.__index = function(t, k)
    local f = function() return stub() end
    if k == "IsShown" then f = function(self) return rawget(self, "_shown") == true end end
    if k == "Show" then f = function(self) rawset(self, "_shown", true) end end
    if k == "Hide" then f = function(self) rawset(self, "_shown", false) end end
    if k == "SetText" then f = function(self, v) rawset(self, "_text", v) end end
    if k == "GetText" then f = function(self) return rawget(self, "_text") end end
    if k == "GetStringHeight" then f = function() return 40 end end
    if k == "GetPoint" then f = function() return "CENTER", nil, "CENTER", 0, 0 end end
    if k == "SetScript" then f = function(self, ev, fn) rawset(self, "_on" .. ev, fn) end end
    rawset(t, k, f)
    return f
  end
  return setmetatable(s, mt)
end
Fake.stub = stub

function Fake.Session(root, saved, char)
  local env = setmetatable({}, { __index = _G })
  env._G = env
  local printed = {}
  env.printed = printed
  env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(printed, m) end }
  env.UIParent, env.GameTooltip = stub(), stub()
  env.UISpecialFrames, env.SlashCmdList = {}, {}
  env.tinsert = table.insert
  env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  local frames = {}
  env.CreateFrame = function() local f = stub(); rawset(f, "_shown", true); table.insert(frames, f); return f end
  env.CreateFromMixins = function() return {} end
  env.MapCanvasDataProviderMixin, env.MapCanvasPinMixin = {}, {}
  env.UnitName = function() return char.name, char.surname end
  env.GetRealmName = function() return "CAMWOW" end
  env.UnitClass = function() return "Warlock", char.class end
  env.UnitLevel = function() return char.level end
  env.UnitFactionGroup = function() return char.faction end
  env.time = function() return 1763200000 end
  env.C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return char.completed[id] == true end,
    GetNumQuestLogEntries = function() return #char.log end,
    GetInfo = function(i) return char.log[i] end,
    GetTitleForQuestID = function(id)
      for _, e in ipairs(char.log) do if e.questID == id then return e.title end end
    end,
  }
  env.C_Item = { GetItemCount = function(id) return char.items[id] or 0 end }
  env.C_Map = { GetMapInfo = function(id) return { name = "Zone" .. id } end,
    SetUserWaypoint = function(p) env.lastWaypoint = p end }
  env.UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { m = m, x = x, y = y } end }
  local pins = { world = {}, mini = {} }
  env.pinsPlaced = pins
  env.LibStub = function(name)
    if name == "HereBeDragons-Pins-2.0" then
      return {
        RemoveAllWorldMapIcons = function() pins.world = {} ; env.pinsPlaced.world = pins.world end,
        RemoveAllMinimapIcons = function() pins.mini = {} ; env.pinsPlaced.mini = pins.mini end,
        AddWorldMapIconMap = function(_, _, icon, m, x, y) table.insert(pins.world, { m = m, x = x, y = y, step = icon.step }) end,
        AddMinimapIconMap = function(_, _, icon, m, x, y) table.insert(pins.mini, { m = m, x = x, y = y, step = icon.step }) end,
      }
    end
  end
  env.HBD_PINS_WORLDMAP_SHOW_CONTINENT = 2
  for k, v in pairs(saved) do env[k] = v end

  local function loadAddon(name, skipLibs)
    local ns = {}
    for line in io.lines(root .. name .. "/" .. name .. ".toc") do
      if not line:match("^##") and line:match("%S") and not line:match("^Libs") then
        local path = root .. name .. "/" .. line:gsub("\\", "/"):gsub("%s+$", "")
        local chunk = assert(loadfile(path))
        setfenv(chunk, env)
        chunk(name, ns)
      end
    end
    return ns
  end
  env.ns = loadAddon("BagQuests")
  if char.alts ~= false then env.altsNs = loadAddon("BagQuests_Alts") end
  -- PLAYER_LOGIN
  env.ns.App.frame._onOnEvent(nil, "PLAYER_LOGIN")
  function env.fire(event, ...) env.ns.App.frame._onOnEvent(nil, event, ...) end
  function env.save()
    saved.BagQuestsDB, saved.BagQuestsAltsDB = env.BagQuestsDB, env.BagQuestsAltsDB
  end
  return env
end

return Fake
