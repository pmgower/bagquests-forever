-- Safety scan: lua5.1 tests/safety.lua (from the repo root)
--
-- BagQuests only READS quest state and draws UI. This scan fails the build
-- if addon code calls any game API that could act for the player: spend or
-- move gold, delete or move items, send chat/mail/addon messages, accept or
-- abandon quests, change settings or keybinds, or run arbitrary code.
--
-- If a future feature truly needs one, put "-- safety: allow <reason>" at the
-- end of that line so the exception is visible in the PR diff.
local ROOT = (arg and arg[0] or "tests/safety.lua"):gsub("tests/safety%.lua$", "")
local ADDON_DIRS = { "BagQuests", "BagQuests_Alts" }

-- name -> why it's dangerous
local DENY = {
  -- running arbitrary code
  loadstring = "runs arbitrary code", RunScript = "runs arbitrary code",
  setfenv = "rewrites function environments", getfenv = "reaches into other code's globals",
  -- talking as the player
  SendChatMessage = "sends chat as the player", SendAddonMessage = "sends addon messages",
  C_ChatInfo = "addon/chat messaging", BNSendWhisper = "sends Battle.net whispers",
  -- gold, trade, mail, auction, vendor
  SendMail = "sends mail", TakeInboxMoney = "takes mail gold", TakeInboxItem = "takes mail items",
  AutoLootMailItem = "loots mail", AcceptTrade = "accepts trades", AddTradeMoney = "puts gold in trade",
  SetTradeMoney = "puts gold in trade", PickupPlayerMoney = "picks up gold",
  BuyMerchantItem = "spends gold", RepairAllItems = "spends gold", PlaceAuctionBid = "spends gold",
  C_AuctionHouse = "auction house actions", BuybackItem = "spends gold",
  -- items
  DeleteCursorItem = "destroys items", PickupContainerItem = "moves items",
  UseContainerItem = "uses or sells items", SplitContainerItem = "moves items",
  C_Container = "moves, uses or deletes items", EquipItemByName = "changes gear", UseItemByName = "uses items",
  -- quests (choosing the wrong reward or abandoning a chain is unrecoverable)
  AcceptQuest = "accepts quests", AbandonQuest = "abandons quests", CompleteQuest = "turns in quests",
  GetQuestReward = "picks a quest reward", SetAbandonQuest = "abandons quests",
  -- client settings, binds, macros, session
  SetCVar = "changes game settings", C_CVar = "changes game settings", ConsoleExec = "runs console commands",
  SetBinding = "changes keybinds", SaveBindings = "changes keybinds", SetBindingClick = "changes keybinds",
  CreateMacro = "creates macros", EditMacro = "edits macros", DeleteMacro = "deletes macros",
  Logout = "logs the player out", Quit = "quits the game", ForceQuit = "quits the game",
  ReloadUI = "reloads the UI", DisableAddOn = "turns off addons", EnableAddOn = "turns on addons",
  C_AddOns = "turns addons on or off",
  -- talents, spells, group
  LearnTalent = "spends talent points", ConfirmTalentWipe = "resets talents", CastSpellByName = "casts spells",
  LeaveParty = "leaves the group", InviteUnit = "invites players", C_PartyInfo = "group actions",
}

-- The only SavedVariables the addons may declare (new ones need a review).
local ALLOWED_SAVEDVARS = { BagQuestsDB = true, BagQuestsAltsDB = true }

local failures = {}
local function fail(msg) table.insert(failures, msg) end

local function listLua(dir)
  local files = {}
  local p = io.popen('find "' .. ROOT .. dir .. '" -name "*.lua" -not -path "*/Libs/*" 2>/dev/null')
  for f in p:lines() do table.insert(files, f) end
  p:close()
  return files
end

-- Drop "--" comments (outside strings, good enough for our code) so a word in
-- a comment doesn't trip the scan, but keep the allow marker visible.
local function codePart(line)
  local out, i, quote = {}, 1, nil
  while i <= #line do
    local c = line:sub(i, i)
    if quote then
      if c == "\\" then table.insert(out, line:sub(i, i + 1)); i = i + 1
      elseif c == quote then quote = nil; table.insert(out, c)
      else table.insert(out, c) end
    elseif c == '"' or c == "'" then quote = c; table.insert(out, c)
    elseif line:sub(i, i + 1) == "--" then break
    else table.insert(out, c) end
    i = i + 1
  end
  return table.concat(out)
end

for _, dir in ipairs(ADDON_DIRS) do
  for _, file in ipairs(listLua(dir)) do
    local n = 0
    for line in io.lines(file) do
      n = n + 1
      if not line:find("%-%- safety: allow %S") then
        local code = codePart(line)
        for name, why in pairs(DENY) do
          if code:find("%f[%w_]" .. name .. "%f[^%w_]") then
            fail(string.format("%s:%d uses %s (%s)", file:gsub("^" .. ROOT, ""), n, name, why))
          end
        end
        if code:find("_G%s*%[") then
          fail(string.format("%s:%d uses _G[...] dynamic global access", file:gsub("^" .. ROOT, ""), n))
        end
      end
    end
  end
  -- TOC: every listed file exists, and only known SavedVariables.
  local toc = ROOT .. dir .. "/" .. dir .. ".toc"
  for line in io.lines(toc) do
    local sv = line:match("^##%s*SavedVariables[%w]*:%s*(.+)$")
    if sv then
      for name in sv:gmatch("[%w_]+") do
        if not ALLOWED_SAVEDVARS[name] then fail(toc .. " declares new SavedVariables " .. name) end
      end
    elseif not line:match("^#") and line:match("%S") then
      local path = ROOT .. dir .. "/" .. line:gsub("\\", "/"):gsub("%s+$", "")
      local f = io.open(path, "r")
      if f then f:close() else fail(toc .. " lists missing file " .. line) end
    end
  end
end

-- Workflows must never run fork code with repository secrets.
local p = io.popen('find "' .. ROOT .. '.github/workflows" -name "*.yml" 2>/dev/null')
for wf in p:lines() do
  for line in io.lines(wf) do
    if line:find("pull_request_target") then fail(wf .. " uses pull_request_target (exposes secrets to forks)") end
  end
end
p:close()

if #failures > 0 then
  print("SAFETY SCAN FAILED")
  for _, f in ipairs(failures) do print("  " .. f) end
  os.exit(1)
end
print("safety scan passed")
