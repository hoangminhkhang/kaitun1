--[[
    Vox Seas — Kaitun / Auto-Farm script
    ====================================
    Game: Vox Seas (Roblox, formerly Blox Seas) — Elysium framework.
    Built from the decompiled RobloxProject (Volt bytecode export). All remote
    names, data paths and quest/enemy schemas below were derived from that dump.

    DERIVED API (client -> server). Remotes live in ReplicatedStorage.NetworkInstances,
    nested under RemoteEvents / RemoteFunctions / UnreliableRemoteEvents (current build).
    Wire format is remote:FireServer(action, ...) / remote:InvokeServer(action, ...).
      Quests            : FireServer("Repeat", questName) | "Accept" | "Track" | "Abandon"
      StatisticsData    : FireServer("UpgradeStats", statsTable) | "SaveStats" | "ResetStats"
      CombatTools       : FireServer("DefaultCombo", {Combo,CallTime,DelayTime,CurrentCombo})
      Elysium_Casting   : FireServer(request)  -- skills (Token/Kind/Key/Caster/State/Data)
      Elysium_DataStore : InvokeServer("FetchData") -> PlayerData  (RemoteFunction!)
      Busoshoku         : FireServer("Toggle")   -- haki (older builds: Abilitys/Toggle)
      StartGame         : FireServer()           -- spawn player from the start menu
      Fruits            : InvokeServer("Eat", ...)
      ToolsData         : FireServer("Store"|"Drop", ...)
      ShopSystem        : FireServer("Purchase", ...)

    NPC INTERACTION: not ProximityPrompt — the game shows a custom Talk button
    (PlayerGui InteractionHUD.InteractionButton, Label text "Talk"). The script
    walks to the NPC / its interest-point Part (e.g. "VillageChief"), clicks that
    button with real input, then proceeds the converse (Proceed / Accept).

    INTERIORS: some NPCs live inside buildings. Live layout is
    workspace.IgnoreList.Int.PrivateAreas.<Island>.<Area>.Enter/Leave, each with
    Entrance (outside door) and Destination (inside spawn) Parts; older builds use
    workspace.PrivateAreas + workspace.PrivateAreaDoors. Tweening straight to the
    interior coordinates is rejected (kick to lobby). The script walks to the
    entrance (K.EnterPoints saved positions / objective marker / door), holds the
    "Enter Area" interaction so the server teleports us in, then talks.

    RUNTIME DATA PATHS:
      Enemies : workspace.Playability.Enemys  (Model + Humanoid, attr OriginalName/Name)
      Drops   : workspace.Playability.DroppedTools
      NPCs    : quest giver Models named "<Island> Quest Giver"
      Quests  : require(ReplicatedStorage.Shared.MainModules.ProgressUtils.QuestsInfo)
      Enemies : require(ReplicatedStorage.Shared.MainModules.EnemysUtils.EnemysInfo)
      Tools   : require(ReplicatedStorage.Shared.MainModules.Tools.ToolsInfo)
      Player  : DataStore Statistics{Level,MaxLevel,XP,AvailablePoints}, Monetization{Gold,Fragment}
      Stats   : Strength, Endurance, Sword, Gun, DevilFruit

    The decision core (quest selection, stat distribution, enemy scoring, drop
    matching) is written as pure functions on table K so it can be unit-tested
    outside Roblox. The script auto-runs only inside Roblox and returns K otherwise.

    FollowGameQuest: reads the game's live objective from the quest tracker HUD
    and does it first — Talk/Warn/Return/Deliver -> walk to the NPC and proceed
    the converse; Defeat/Kill -> farm that mob; Collect/Catch -> pick up drops.
    With no tracker objective it falls back to level-based grinding quests.
]]

local K = {}

--==========================================================================
-- CONFIG
--==========================================================================
K.Config = {
    AutoFarm        = true,   -- master farm loop (quest + kill)
    AutoQuest       = true,   -- accept / repeat grinding quests
    AutoStats       = true,   -- spend available stat points
    AutoHaki        = true,   -- keep Busoshoku (Aura) active
    AutoEquip       = true,   -- equip best farming weapon
    AutoCollect     = true,   -- pick up dropped tools/items
    FastAttack      = true,   -- accelerated attacks
    UseRemoteAttack = false,  -- fire CombatTools.DefaultCombo directly (else simulate input)
    UseSkills       = false,  -- also cast fruit/sword skills via Elysium_Casting
    BossFarm        = false,  -- prefer boss quests / farm bosses for set drops
    ItemFarm        = false,  -- target enemies that drop TargetItem
    TargetItem      = "",     -- item name to farm when ItemFarm = true
    AntiAFK         = true,
    AutoRejoin      = false,  -- rejoin on death loop / stuck
    FPSBoost        = false,

    MoveMode        = "Tween",   -- "Tween" (glide at walk pace) or "Teleport" (instant)
    TweenSpeed      = 16,        -- studs/sec glide speed (~WalkSpeed; server-friendly)
    TweenMaxTime    = 20,        -- cap on a single glide's duration (seconds)
    Noclip          = true,      -- phase through walls/objects while gliding (no stuck)
    FarmAnyFallback = true,      -- no quest mob nearby? farm the nearest enemy instead
    HakiRemote      = "Busoshoku", -- current build uses a dedicated Busoshoku remote
    HakiAction      = "Toggle",
    AutoStartGame   = true,      -- auto-click the game's START GAME menu so a player spawns
    FollowGameQuest = true,      -- follow the game's live objective (talk/kill/collect) first
    AutoConverse    = true,      -- click through intro / NPC converse response options

    AttackDelay     = 0.12,   -- seconds between attacks (input mode)
    ComboDelay      = 0.08,   -- DelayTime sent with remote combo attack
    AttackRemote    = "CombatTools",  -- best-effort direct combo remote (unverified)
    AttackAction    = "DefaultCombo", -- action name for direct combo remote
    FarmDistance    = 6,      -- teleport offset from enemy
    MaxFarmRange    = 4000,   -- ignore enemies farther than this
    QuestRefresh    = 1.0,    -- seconds between quest/state checks
    CollectRange    = 60,     -- max distance to chase a drop
    StatWeights     = { Strength = 0, Endurance = 0.4, Sword = 0, Gun = 0.6, DevilFruit = 0 },
    WeaponPreference = { "Gun", "Sword", "Style", "Fruit" }, -- PvE: guns first
    PreferredIsland = "",     -- force a specific island quest ("" = auto by level)
    LogLevel        = 1,      -- 0 silent, 1 info, 2 debug
}

--==========================================================================
-- PURE LOGIC CORE (no Roblox dependencies — unit-testable)
--==========================================================================

local function trim(s)
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end
K.Trim = trim

-- Normalize an enemy/quest name for tolerant matching.
function K.NormalizeName(s)
    if s == nil then return "" end
    s = tostring(s):lower()
    s = s:gsub("[^%w ]", " ")
    s = s:gsub("%s+", " ")
    return trim(s)
end

-- True when two enemy identifiers refer to the same mob (tolerant).
function K.MatchName(a, b)
    local na, nb = K.NormalizeName(a), K.NormalizeName(b)
    if na == "" or nb == "" then return false end
    if na == nb then return true end
    -- one contains the other as a whole-word-ish substring
    if na:find(nb, 1, true) or nb:find(na, 1, true) then return true end
    -- space-insensitive: "village chief" == "VillageChief" (interest-point names)
    local ca, cb = na:gsub(" ", ""), nb:gsub(" ", "")
    if ca == cb or ca:find(cb, 1, true) or cb:find(ca, 1, true) then return true end
    return false
end

-- Parse a quest-tracker objective line into {action, target, raw}.
-- Verbs come from the game's QuestsInfo UIText: Talk to / Warn / Return to /
-- Deliver ... to / Defeat / Kill / Collect / Catch / Find / Investigate.
function K.ParseObjective(text)
    if type(text) ~= "string" then return nil end
    local raw = trim(text)
    local t = K.NormalizeName(raw)
    if t == "" then return nil end
    local action, rest
    if t:find("^talk to ") or t:find("^speak to ") or t:find("^talk with ") then
        action, rest = "talk", t:gsub("^%a+ %a+ ", "")
    elseif t:find("^warn ") then
        action, rest = "talk", t:sub(6)
    elseif t:find("^return to ") then
        action, rest = "talk", t:sub(11)
    elseif t:find("^deliver ") then
        action, rest = "talk", t:match(" to the (.+)$") or t:match(" to (.+)$") or ""
    elseif t:find("^defeat ") or t:find("^kill ") or t:find("^slay ") then
        action, rest = "kill", t:match("^%a+ (.+)$")
    elseif t:find("^collect ") or t:find("^catch ") or t:find("^gather ") then
        action, rest = "collect", t:match("^%a+ (.+)$")
    elseif t:find("^pick up ") then
        action, rest = "collect", t:sub(9)
    elseif t:find("^find ") or t:find("^investigate ") or t:find("^locate ") then
        action, rest = "find", t:match("^%a+ (.+)$")
    else
        return nil
    end
    rest = trim(rest or "")
    rest = rest:gsub("^%d+ ", "")   -- "defeat 5 pirates" -> "pirates"
    rest = rest:gsub("^the ", "")   -- "the village chief" -> "village chief"
    rest = rest:gsub(" %d+ %d+$", ""):gsub(" %d+$", "") -- drop "(0/5)" progress
    rest = trim(rest)
    if rest == "" then return nil end
    return { action = action, target = rest, raw = raw }
end

-- Collect the set of enemy goal names from a quest definition.
-- Handles raw defs (Goal / SubQuests) and assembled defs (Objectives).
function K.QuestGoals(quest)
    local goals, seen = {}, {}
    local function add(g)
        if g == nil then return end
        g = trim(g)
        if g == "" then return end
        local key = K.NormalizeName(g)
        if not seen[key] then
            seen[key] = true
            goals[#goals + 1] = g
        end
    end
    if type(quest) ~= "table" then return goals end
    add(quest.Goal)
    if type(quest.SubQuests) == "table" then
        for _, sq in pairs(quest.SubQuests) do
            if type(sq) == "table" then
                add(sq.Goal); add(sq.Name)
                if type(sq.Objectives) == "table" then
                    for _, o in pairs(sq.Objectives) do
                        if type(o) == "table" then add(o.Goal) end
                    end
                end
            end
        end
    end
    if type(quest.Objectives) == "table" then
        for _, o in pairs(quest.Objectives) do
            if type(o) == "table" then add(o.Goal) end
        end
    end
    return goals
end

-- Flatten the QuestsInfo table (keyed by folder path) into a quest list.
function K.BuildQuestList(questsInfo)
    local list = {}
    if type(questsInfo) ~= "table" then return list end
    for key, q in pairs(questsInfo) do
        if type(q) == "table" and (q.Name or q.Goal or q.Objectives) then
            local goals = K.QuestGoals(q)
            local island = tostring(key):match("Grinding[\\/](.+)[\\/]") or q.Island or ""
            list[#list + 1] = {
                Name = q.Name or tostring(key),
                Goals = goals,
                Giver = q.Giver or (island ~= "" and (island .. " Quest Giver") or nil),
                MinLevel = tonumber(q.MinLevel) or 0,
                MaxLevel = tonumber(q.MaxLevel) or math.huge,
                IsBoss = q.IsBoss == true,
                Type = q.Type or "Grinding",
                Island = island,
                Raw = q,
            }
        end
    end
    return list
end

-- Choose the best grinding quest for a level.
-- opts: {boss=bool, island=string, exclude=setName}
function K.SelectQuest(list, level, opts)
    opts = opts or {}
    level = tonumber(level) or 0
    local best, bestScore = nil, -math.huge
    for _, q in ipairs(list or {}) do
        local isGrinding = (q.Type == "Grinding") or (q.Type == nil)
        if isGrinding and q.Goals and #q.Goals > 0 then
            local okBoss = (not q.IsBoss) or opts.boss
            local okIsland = (opts.island == nil or opts.island == "" or q.Island == opts.island)
            local inRange = level >= (q.MinLevel or 0) and level <= (q.MaxLevel or math.huge)
            local unlocked = level >= (q.MinLevel or 0)
            if okBoss and okIsland and unlocked then
                -- prefer quests whose range contains the level, then highest MinLevel
                local score = (q.MinLevel or 0)
                if inRange then score = score + 100000 end
                if q.IsBoss and opts.boss then score = score + 5000 end
                if opts.exclude and opts.exclude[q.Name] then score = score - 1000000 end
                if score > bestScore then
                    best, bestScore = q, score
                end
            end
        end
    end
    return best
end

-- Distribute available stat points by weights, respecting per-stat caps.
-- weights: map stat->weight ; current: map stat->already invested ;
-- cap: optional max total per stat (nil = unlimited). Returns map stat->pointsToAdd.
function K.DistributeStats(available, weights, current, cap)
    available = math.max(0, math.floor(tonumber(available) or 0))
    weights = weights or {}
    current = current or {}
    local result = {}
    local totalWeight = 0
    for _, w in pairs(weights) do totalWeight = totalWeight + (tonumber(w) or 0) end
    if available == 0 or totalWeight <= 0 then return result end

    -- ideal fractional allocation
    local ideal, order = {}, {}
    for stat, w in pairs(weights) do
        w = tonumber(w) or 0
        if w > 0 then
            ideal[stat] = available * (w / totalWeight)
            order[#order + 1] = stat
        end
    end
    table.sort(order)

    local assigned = 0
    local floors = {}
    for _, stat in ipairs(order) do
        local room = available
        if cap and cap[stat] then
            room = math.max(0, cap[stat] - (tonumber(current[stat]) or 0))
        end
        local give = math.min(math.floor(ideal[stat]), room)
        floors[stat] = give
        assigned = assigned + give
    end
    -- hand out remaining points by largest fractional remainder, respecting caps
    local remainder = available - assigned
    local fracOrder = {}
    for _, stat in ipairs(order) do
        fracOrder[#fracOrder + 1] = { stat = stat, frac = ideal[stat] - math.floor(ideal[stat]) }
    end
    table.sort(fracOrder, function(a, b)
        if a.frac == b.frac then return a.stat < b.stat end
        return a.frac > b.frac
    end)
    local i = 1
    while remainder > 0 and #fracOrder > 0 do
        local entry = fracOrder[((i - 1) % #fracOrder) + 1]
        local stat = entry.stat
        local room = available
        if cap and cap[stat] then
            room = math.max(0, cap[stat] - (tonumber(current[stat]) or 0) - floors[stat])
        end
        if floors[stat] < room then
            floors[stat] = floors[stat] + 1
            remainder = remainder - 1
        end
        i = i + 1
        if i > #fracOrder * (available + 1) then break end -- safety
    end
    for _, stat in ipairs(order) do
        if floors[stat] > 0 then result[stat] = floors[stat] end
    end
    return result
end

-- Score an enemy for farming priority. Higher = better target.
-- enemy: {Name, Level, Health, MaxHealth, Distance, IsBoss}
function K.ScoreEnemy(enemy, goals, opts)
    opts = opts or {}
    if type(enemy) ~= "table" then return -math.huge end
    local matches = false
    for _, g in ipairs(goals or {}) do
        if K.MatchName(enemy.Name, g) then matches = true break end
    end
    if not matches and not opts.allowAny then return -math.huge end
    local hp = tonumber(enemy.Health) or 0
    if hp <= 0 then return -math.huge end
    local dist = tonumber(enemy.Distance) or math.huge
    if opts.maxRange and dist > opts.maxRange then return -math.huge end
    local score = 1000
    score = score - dist * 0.5                       -- closer is better
    local maxhp = tonumber(enemy.MaxHealth) or hp
    if maxhp > 0 then score = score + (1 - hp / maxhp) * 200 end -- finish low hp
    if enemy.IsBoss then score = score + (opts.boss and 300 or -200) end
    if not matches then score = score - 500 end
    return score
end

-- Pick the best enemy from a list given quest goals.
function K.PickEnemy(enemies, goals, opts)
    local best, bestScore = nil, -math.huge
    for _, e in ipairs(enemies or {}) do
        local s = K.ScoreEnemy(e, goals, opts)
        if s > bestScore then best, bestScore = e, s end
    end
    return best, bestScore
end

-- Find enemies/bosses whose drop table contains itemName.
-- enemysInfo: flat map name->def with Rewards.Drops (list of {Item,Chance,Quantity})
function K.FindItemDroppers(enemysInfo, itemName)
    local out = {}
    if type(enemysInfo) ~= "table" or not itemName or itemName == "" then return out end
    local target = K.NormalizeName(itemName)
    local function scanDrops(drops, name, def)
        if type(drops) ~= "table" then return end
        for _, d in pairs(drops) do
            if type(d) == "table" then
                local it = d.Item or d.Name or d.Tool
                if it and K.NormalizeName(it) == target then
                    out[#out + 1] = { Name = name, Chance = d.Chance, Quantity = d.Quantity, IsBoss = def and def.IsBoss }
                end
            end
        end
    end
    for name, def in pairs(enemysInfo) do
        if type(def) == "table" then
            local rewards = def.Rewards
            if type(rewards) == "table" then scanDrops(rewards.Drops, name, def) end
            scanDrops(def.Drops, name, def)
            if type(def.DropsSet) == "table" then scanDrops(def.DropsSet, name, def) end
        end
    end
    return out
end

-- Fallback progression (approximate level ranges from public wiki, mapped to the
-- new-build island names). Used ONLY when runtime QuestsInfo cannot be read.
K.FallbackProgression = {
    { Island = "Solmar Island",    MinLevel = 0,    Goals = { "Cutlass Pirate", "Flint Pirate", "Marine Recruit" } },
    { Island = "Skull Island",     MinLevel = 25,   Goals = { "Boar", "Alpha Boar" } },
    { Island = "Forbidden Island", MinLevel = 60,   Goals = { "Werewolf", "Fierce Werewolf" } },
    { Island = "Circus Town",      MinLevel = 110,  Goals = { "Bugg Cutlass Pirate", "Bugg Flint Pirate", "Dual Katana Clown" } },
    { Island = "Golden Dunes",     MinLevel = 180,  Goals = { "Desert Ruffian", "Desert Outlaw" } },
    { Island = "Frost Island",     MinLevel = 255,  Goals = { "Viking Warrior", "Old Viking Warrior", "Haunted Knight" } },
    { Island = "Marine Ford",      MinLevel = 330,  Goals = { "Marine Sergeant", "Marine Lieutenant" } },
    { Island = "Windhaven",        MinLevel = 405,  Goals = { "Sky Royal Guard", "Elite Sky Royal Guard" } },
    { Island = "Prison",           MinLevel = 455,  Goals = { "Elite Prison Guard", "Elite Prison Supervisor" } },
    { Island = "Valoria Island",   MinLevel = 580,  Goals = { "Veteran Gladiator", "Elite Assassin Gladiator" } },
    { Island = "Rustfall",         MinLevel = 630,  Goals = { "Iron Sentinel", "Old Iron Sentinel" } },
    { Island = "Volcano Island",   MinLevel = 660,  Goals = { "Volcano Guard", "Volcano Supervisor" } },
    { Island = "Shark Park",       MinLevel = 705,  Goals = { "Sharkman Patroller", "Sharkman Guard", "Elite Sharkman" } },
    { Island = "Nerúvia",          MinLevel = 930,  Goals = { "VoidWalker Musket", "Elite VoidWalker Musket" } },
}

function K.FallbackQuest(level)
    local best = K.FallbackProgression[1]
    for _, e in ipairs(K.FallbackProgression) do
        if level >= e.MinLevel then best = e end
    end
    return {
        Name = best.Island .. " (fallback)",
        Goals = best.Goals,
        Giver = best.Island .. " Quest Giver",
        MinLevel = best.MinLevel,
        MaxLevel = math.huge,
        IsBoss = false,
        Type = "Grinding",
        Island = best.Island,
    }
end

--==========================================================================
-- RUNTIME (Roblox only). Everything below guards against a non-Roblox env.
--==========================================================================

local Services = {}
local LocalPlayer, ReplicatedStorage, Workspace, RunService, VirtualInput
local QuestsInfo, EnemysInfo, ToolsInfo
local questList = {}
local activeQuest = nil
local running = false
local connections = {}

local function log(level, ...)
    if level <= (K.Config.LogLevel or 1) then
        print("[VoxKaitun]", ...)
    end
end
K.Log = log

local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then log(2, "error:", err) end
    return ok, err
end
K.Safe = safe

local function getService(name)
    if Services[name] then return Services[name] end
    local ok, svc = pcall(function() return game:GetService(name) end)
    if ok then Services[name] = svc end
    return svc
end

-- Resolve a network remote by channel name from NetworkInstances (with fallback).
local remoteCache = {}
local function getRemote(name, wantFunction)
    local key = name .. (wantFunction and "#F" or "#E")
    if remoteCache[key] then return remoteCache[key] end
    local rs = ReplicatedStorage or getService("ReplicatedStorage")
    if not rs then return nil end
    local ni = rs:FindFirstChild("NetworkInstances")
    local found
    if ni then
        -- current build nests remotes under RemoteEvents / RemoteFunctions
        local sub = ni:FindFirstChild(wantFunction and "RemoteFunctions" or "RemoteEvents")
        if sub then found = sub:FindFirstChild(name) end
        if not found then found = ni:FindFirstChild(name, true) end
    end
    if not found then found = rs:FindFirstChild(name, true) end
    if not found then return nil end
    local isF = found:IsA("RemoteFunction")
    local isE = found:IsA("RemoteEvent") or found:IsA("UnreliableRemoteEvent")
    if (wantFunction and isF) or (not wantFunction and isE) then
        remoteCache[key] = found
        return found
    end
    return nil
end
K.GetRemote = getRemote

local function fire(name, action, ...)
    local r = getRemote(name, false)
    if not r then log(2, "remote missing:", name) return false end
    local args = { ... }
    if r:IsA("RemoteFunction") then
        return safe(function() return r:InvokeServer(action, table.unpack(args)) end)
    end
    return safe(function() r:FireServer(action, table.unpack(args)) end)
end
K.Fire = fire

local function invoke(name, action, ...)
    local r = getRemote(name, true)
    if not r then return nil end
    local args = { ... }
    local ok, res = safe(function() return r:InvokeServer(action, table.unpack(args)) end)
    if ok then return res end
    return nil
end
K.Invoke = invoke

-- ---- Player data ---------------------------------------------------------
local dataCache, dataStamp = nil, 0
local function getData(force)
    local now = os.clock()
    if not force and dataCache and (now - dataStamp) < 0.5 then return dataCache end
    local d = invoke("Elysium_DataStore", "FetchData")
    if type(d) == "table" then
        dataCache, dataStamp = d, now
    end
    return dataCache
end
K.GetData = getData

local function dig(t, ...)
    for _, k in ipairs({ ... }) do
        if type(t) ~= "table" then return nil end
        t = t[k]
    end
    return t
end

local function readLevelFallback()
    if not LocalPlayer then return 0 end
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            if K.MatchName(v.Name, "Level") then
                local n = tonumber(v.Value)
                if n then return n end
            end
        end
    end
    local a = tonumber(LocalPlayer:GetAttribute("Level"))
    if a then return a end
    return 0
end

local function getLevel()
    local d = getData()
    local lvl = tonumber(dig(d, "Statistics", "Level"))
    if lvl then return lvl end
    return readLevelFallback()
end
K.GetLevel = getLevel

local function getAvailablePoints()
    local d = getData()
    return tonumber(dig(d, "Statistics", "AvailablePoints")) or 0
end

local function getActiveQuests()
    local d = getData()
    local q = dig(d, "Quests", "Actives")
    return type(q) == "table" and q or {}
end
K.GetActiveQuests = getActiveQuests

-- ---- Require game data modules ------------------------------------------
local function requirePath(root, path)
    local node = root
    for part in path:gmatch("[^%.]+") do
        if not node then return nil end
        node = node:FindFirstChild(part)
    end
    if not node then return nil end
    if node:IsA("ModuleScript") then
        local ok, res = pcall(require, node)
        if ok then return res end
    elseif node:IsA("Folder") then
        local init = node:FindFirstChild("init")
        if init and init:IsA("ModuleScript") then
            local ok, res = pcall(require, init)
            if ok then return res end
        end
    end
    return nil
end

local function loadDataModules()
    local rs = ReplicatedStorage
    if not rs then return end
    QuestsInfo = requirePath(rs, "Shared.MainModules.ProgressUtils.QuestsInfo")
    EnemysInfo = requirePath(rs, "Shared.MainModules.EnemysUtils.EnemysInfo")
    ToolsInfo = requirePath(rs, "Shared.MainModules.Tools.ToolsInfo")
    if QuestsInfo then
        questList = K.BuildQuestList(QuestsInfo)
        log(1, "loaded quests:", #questList)
    else
        log(1, "QuestsInfo unavailable — using fallback progression")
    end
end

-- ---- Quest selection / accept / repeat ----------------------------------
local function chooseQuest()
    local level = getLevel()
    local opts = { boss = K.Config.BossFarm, island = K.Config.PreferredIsland }
    local q = K.SelectQuest(questList, level, opts)
    if not q then q = K.FallbackQuest(level) end
    return q
end
K.ChooseQuest = chooseQuest

local function hasActiveQuest(name)
    local actives = getActiveQuests()
    for k, v in pairs(actives) do
        if K.MatchName(k, name) then return true end
        if type(v) == "table" and (K.MatchName(v.Name, name) or K.MatchName(v.QuestName, name)) then
            return true
        end
    end
    return false
end

-- Position of an NPC model: HRP, PrimaryPart, any BasePart, or pivot.
local function npcPosition(m)
    local hrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
    if hrp then return hrp end
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function npcMatches(m, name)
    if K.MatchName(m.Name, name) then return true end
    local ok, disp = pcall(function()
        return m:GetAttribute("NPCName") or m:GetAttribute("DisplayName")
    end)
    if ok and type(disp) == "string" and K.MatchName(disp, name) then return true end
    return false
end

-- Private areas root: live layout is IgnoreList.Int.PrivateAreas.<Island>.<Area>,
-- older builds use workspace.PrivateAreas directly.
local function privateAreasRoot()
    if not Workspace then return nil end
    local pa = Workspace:FindFirstChild("PrivateAreas")
    if pa then return pa end
    local ignore = Workspace:FindFirstChild("IgnoreList")
    local int = ignore and ignore:FindFirstChild("Int")
    return int and int:FindFirstChild("PrivateAreas") or nil
end

-- Saved Enter positions harvested from Studio (2026-11-15), one entry per area:
-- entrance = outside door to walk to, destination = inside spawn after Enter.
-- Stored as {x,y,z} so the table loads without Vector3.
K.EnterPoints = {
    WitchHouse            = { island = "Forbidden Island", entrance = {6282.3, 132.3, -5187.3},   destination = {6091.5, -569.6, -4640.6} },
    Crypt                 = { island = "Forbidden Island", entrance = {6578.2, 93.3, -4729.3},    destination = {6036.3, -725.5, -4132.7} },
    Barber                = { island = "Harbor Island",    entrance = {5681.5, 40.1, 3302.9},     destination = {5686.3, -776.4, 4167.2} },
    Pawnshop              = { island = "Harbor Island",    entrance = {5658.0, 40.1, 3213.3},     destination = {5691.6, -804.7, 2808.7} },
    Tailor                = { island = "Harbor Island",    entrance = {5677.9, 40.1, 3602.2},     destination = {6283.4, -776.5, 3170.9} },
    Bank                  = { island = "Harbor Island",    entrance = {5967.7, 42.4, 3304.1},     destination = {5351.8, -768.8, 3440.2} },
    HarborBoatShop        = { island = "Harbor Island",    entrance = {5849.9, 40.2, 3663.5},     destination = {6281.2, -1368.1, 3579.2} },
    KrakensRestBoatShop   = { island = "Kraken's rest",    entrance = {15713.6, 40.1, 4322.8},    destination = {17420.7, -1484.7, 5669.6} },
    KrakensRestBarber     = { island = "Kraken's rest",    entrance = {15881.2, 39.7, 4350.3},    destination = {15839.6, -1002.4, 4291.5} },
    KrakensRestTailor     = { island = "Kraken's rest",    entrance = {16415.1, 159.5, 3902.9},   destination = {15212.0, -777.4, 3451.9} },
    KrakensRestPawnshop   = { island = "Kraken's rest",    entrance = {16173.4, 107.0, 4300.1},   destination = {15383.3, -806.5, 3879.4} },
    MayorHouse            = { island = "Circus Town",      entrance = {-7380.4, 75.9, -8988.1},   destination = {-9819.2, -510.8, -5912.5} },
    Circus                = { island = "Circus Town",      entrance = {-7601.0, 164.3, -9347.1},  destination = {-8490.3, -628.5, -8356.3} },
    Pyramid               = { island = "Golden Dunes",     entrance = {-7221.0, 55.0, 11909.0},   destination = {-7040.0, -1406.0, 12741.0} },
    BlackMarket           = { island = "Golden Dunes",     entrance = {-7551.8, 55.1, 11493.8},   destination = {-7636.4, -751.1, 11356.9} },
    SkyLift               = { island = "Rustfall",         entrance = {6637.7, 24.0, 10673.1},    destination = {6545.0, 1353.3, 10652.0} },
    SolmarBoatShop        = { island = "Solmar Island",    entrance = {-92.3, 26.4, 400.4},       destination = {-143.8, -1250.2, -482.1} },
    MarineBase            = { island = "Solmar Island",    entrance = {-196.6, 37.0, 680.1},      destination = {191.4, -389.4, -3106.2} },
    ElderHouse            = { island = "Solmar Island",    entrance = {-323.0, 16.7, 320.0},      destination = {-320.4, -764.6, -33.1} },
    OldLadyHouse          = { island = "Solmar Island",    entrance = {21.8, 25.6, 538.7},        destination = {353.7, -864.8, 19.0} },
    RoyalForge            = { island = "Frost Island",     entrance = {-19272.6, 482.2, 158.9},   destination = {-19409.2, -1123.9, -2726.2} },
    ThroneRoom            = { island = "Frost Island",     entrance = {-19012.2, 482.2, 186.7},   destination = {-22950.9, -1178.8, -1883.8} },
    BlazeboundArena       = { island = "Volcano Island",   entrance = {-17620.8, -9606.1, 11355.8}, destination = {-16976.2, -11407.9, 12237.2} },
    VolcanoInterior       = { island = "Volcano Island",   entrance = {-16992.5, 339.7, 10178.3}, destination = {-18135.0, -9547.5, 10318.7} },
    VolcanoBossRoom       = { island = "Volcano Island",   entrance = {-18133.1, -9534.6, 11502.7}, destination = {-18973.0, -4709.5, 10300.5} },
}
-- WolfBossRoom / CavernRoof / CavernShell have no Enter door (reached via other
-- areas); their Leave exits: WolfBossRoom -> (6569.2,93.3,-4729.3),
-- CavernRoof/CavernShell -> (718.0,30.6,6495.0).

-- Area containers and doors share names with NPCs/areas but are not talkable
-- characters; never target them.
local function isAreaContainerOrDoor(m)
    local pa = privateAreasRoot()
    if pa then
        if m.Parent == pa then return true end
        -- island layout: area containers hold Enter/Leave folders, NPCs do not
        if m.Parent and m.Parent.Parent == pa and m:FindFirstChild("Enter") then return true end
    end
    local pd = Workspace and Workspace:FindFirstChild("PrivateAreaDoors")
    if pd then
        local p = m
        while p do
            if p == pd then return true end
            p = p.Parent
        end
    end
    return false
end

local function findGiver(giverName)
    if not giverName or not Workspace then return nil end
    local best, bestDist = nil, math.huge
    local char = LocalPlayer and LocalPlayer.Character
    local pos = char and char:GetPivot().Position
    for _, m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") and npcMatches(m, giverName) and not isAreaContainerOrDoor(m) then
            local hrp = npcPosition(m)
            if hrp then
                local d = pos and (hrp.Position - pos).Magnitude or 0
                if d < bestDist then best, bestDist = m, d end
            end
        end
    end
    return best
end
K.FindGiver = findGiver

-- Interest points are invisible Parts named e.g. "VillageChief" (no spaces).
local function findInterestPoint(name)
    if not name or not Workspace then return nil end
    local best, bestDist = nil, math.huge
    local char = LocalPlayer and LocalPlayer.Character
    local pos = char and char:GetPivot().Position
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("BasePart") and K.MatchName(p.Name, name) then
            local d = pos and (p.Position - pos).Magnitude or 0
            if d < bestDist then best, bestDist = p, d end
        end
    end
    return best
end
K.FindInterestPoint = findInterestPoint

-- NPCs that live inside a building are under the PrivateAreas root (flat
-- workspace.PrivateAreas.<Area> or IgnoreList.Int.PrivateAreas.<Island>.<Area>).
-- Tweening straight to them is rejected by the server (kick to lobby); we must
-- enter through the area's door instead. Return the area name, or nil if the
-- instance is in the overworld.
local function interiorAreaName(inst)
    if not inst then return nil end
    local flat = Workspace and Workspace:FindFirstChild("PrivateAreas")
    local pa = privateAreasRoot()
    if not pa then return nil end
    local p = inst
    while p do
        if p.Parent == pa then return p.Name end
        -- island layout only: the area sits one level below the island folder
        if pa ~= flat and p.Parent and p.Parent.Parent == pa then return p.Name end
        p = p.Parent
    end
    return nil
end
K.InteriorAreaName = interiorAreaName

-- The outside door position for a private area: legacy PrivateAreaDoors folder,
-- live <Area>.Enter.Entrance part, or the saved K.EnterPoints table as fallback.
local function findAreaDoor(areaName)
    if not areaName then return nil end
    local char = LocalPlayer and LocalPlayer.Character
    local pos = char and char:GetPivot().Position
    local best, bestDist
    local doors = Workspace and Workspace:FindFirstChild("PrivateAreaDoors")
    if doors then
        for _, d in ipairs(doors:GetChildren()) do
            if K.MatchName(d.Name, areaName) then
                local part = d:IsA("BasePart") and d or d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local dist = pos and (part.Position - pos).Magnitude or 0
                    if not bestDist or dist < bestDist then best, bestDist = part, dist end
                end
            end
        end
    end
    if best then return best end
    local pa = privateAreasRoot()
    if pa then
        for _, island in ipairs(pa:GetChildren()) do
            local area = island:FindFirstChild(areaName)
            local enter = area and area:FindFirstChild("Enter")
            local part = enter and enter:FindFirstChild("Entrance")
            if part and part:IsA("BasePart") then return part end
        end
    end
    local saved = K.EnterPoints[areaName]
    if saved then
        local e = saved.entrance
        return { Position = Vector3.new(e[1], e[2], e[3]) }
    end
    return nil
end
K.FindAreaDoor = findAreaDoor

local function teleportTo(cf)
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        safe(function()
            hrp.CFrame = cf
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end)
    end
end

-- Ground surface Y at (x, z) by raycasting straight down from fromY. Returns nil
-- when raycast is unavailable (some executors block it) or misses, so callers can
-- fall back instead of trusting a buried destination Y.
local function groundYAt(x, z, fromY)
    local gy
    safe(function()
        if not Workspace or not Workspace.Raycast then return end
        local char = LocalPlayer and LocalPlayer.Character
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        if char then params.FilterDescendantsInstances = { char } end
        local hit = Workspace:Raycast(Vector3.new(x, fromY, z), Vector3.new(0, -1000, 0), params)
        if hit then gy = hit.Position.Y end
    end)
    return gy
end
K.GroundYAt = groundYAt

-- Keep a destination on the ground so we never glide underground. Lift a buried
-- interest-point Y onto the real surface; if raycast is blocked, never dive more
-- than a few studs below the character's current height.
local function groundSafePos(pos)
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local curY = hrp and hrp.Position.Y or pos.Y
    local gy = groundYAt(pos.X, pos.Z, pos.Y + 300)
    if gy then
        local standY = gy + 3
        if standY > pos.Y then return Vector3.new(pos.X, standY, pos.Z) end
        return pos
    end
    local floorY = curY - 5
    if pos.Y < floorY then return Vector3.new(pos.X, floorY, pos.Z) end
    return pos
end
K.GroundSafePos = groundSafePos

-- Phase through walls/objects while gliding so the character never gets stuck
-- on geometry. Collision is restored once the glide finishes.
local function setNoclip(on)
    if not K.Config.Noclip then return end
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            safe(function() d.CanCollide = not on end)
        end
    end
end
K.SetNoclip = setNoclip

-- Glide to a CFrame at walking pace by stepping the root part directly. The root
-- is anchored for the whole glide: with noclip on, an unanchored character gets
-- pulled through the floor by gravity (the "tween underground" bug), while an
-- anchored root moved by CFrame passes through walls/objects without sticking.
-- Every step is clamped to the real ground surface so we never travel under the
-- map, and the pace (studs/sec ~= WalkSpeed) keeps the server from reading it as
-- a teleport and snapping the character back to spawn.
local gliding = false
local function moveTo(cf)
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dest = groundSafePos(cf.Position)
    if K.Config.MoveMode == "Teleport" then
        teleportTo(CFrame.new(dest))
        return
    end
    local startPos = hrp.Position
    local dist = (startPos - dest).Magnitude
    if dist < 1 then return end
    if gliding then return end
    gliding = true

    local speed = K.Config.TweenSpeed or 16
    local stepTime = 0.05
    local duration = dist / speed
    local maxTime = K.Config.TweenMaxTime or 20
    if duration > maxTime then duration = maxTime end
    local steps = math.max(1, math.floor(duration / stepTime))
    local dx, dy, dz = dest.X - startPos.X, dest.Y - startPos.Y, dest.Z - startPos.Z

    local wasAnchored = false
    safe(function() wasAnchored = hrp.Anchored; hrp.Anchored = true end)
    setNoclip(true)
    for i = 1, steps do
        if not hrp.Parent then break end
        local a = i / steps
        local x, y, z = startPos.X + dx * a, startPos.Y + dy * a, startPos.Z + dz * a
        local gy = groundYAt(x, z, y + 5)
        if gy and y < gy + 3 then y = gy + 3 end
        safe(function()
            hrp.CFrame = CFrame.new(x, y, z)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end)
        task.wait(stepTime)
    end
    -- final placement clamped to the surface, then hand physics back
    local fy = dest.Y
    local gy = groundYAt(dest.X, dest.Z, fy + 5)
    if gy and fy < gy + 3 then fy = gy + 3 end
    safe(function() hrp.CFrame = CFrame.new(dest.X, fy, dest.Z) end)
    setNoclip(false)
    safe(function() hrp.Anchored = wasAnchored end)
    gliding = false
end

-- True when an instance lives inside one of our own GUIs (never click those).
local function inOurUI(inst)
    local p = inst
    while p do
        if p.Name == "VoxKaitunUI" then return true end
        p = p.Parent
    end
    return false
end

-- True only when the instance and every GUI ancestor are shown (the game hides
-- whole interface groups, so a button can be Visible=true inside a hidden panel).
local function guiVisible(inst)
    local p = inst
    while p do
        if p.Visible == false then return false end
        p = p.Parent
    end
    return true
end

-- Click the single best accept-like option in an open NPC converse dialog.
local function proceedConverse()
    local clicked = false
    safe(function()
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        local bestBtn, bestScore = nil, 0
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextButton") and d.Visible and not inOurUI(d) then
                local t = K.NormalizeName(d.Text)
                local score = 0
                if t == "accept" or t:find("accept quest") then score = 5
                elseif t:find("accept") then score = 4
                elseif t == "yes" or t == "ok" then score = 3
                elseif t:find("continue") or t:find("next") or t:find("proceed") then score = 2 end
                if score > bestScore then bestBtn, bestScore = d, score end
            end
        end
        if bestBtn and bestScore >= 2 and firesignal then
            firesignal(bestBtn.MouseButton1Click)
            clicked = true
        end
    end)
    return clicked
end
K.ProceedConverse = proceedConverse

-- Fire a GUI button for real: its click signal plus a physical click at its
-- center (so InputBegan-style handlers also run).
local function pressButton(btn)
    local clicked = false
    safe(function()
        if firesignal then
            firesignal(btn.MouseButton1Click)
            clicked = true
        end
    end)
    safe(function()
        local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
        local x, y = pos.X + size.X / 2, pos.Y + size.Y / 2
        if VirtualInput then
            VirtualInput:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.02)
            VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 0)
            clicked = true
        elseif mouse1click then
            mouse1click()
            clicked = true
        end
    end)
    return clicked
end

-- The game's NPC interaction is a custom Talk button (InteractionHUD.
-- InteractionButton with a Label), not a ProximityPrompt. Click it for real.
local function clickTalkButton()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    local btn
    for _, d in ipairs(pg:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and not inOurUI(d) then
            local visible = true
            pcall(function() visible = d.Visible end)
            if visible ~= false then
                local t = ""
                pcall(function() t = K.NormalizeName(d.Text or "") end)
                if t == "" then
                    local lbl = d:FindFirstChild("Label", true) or d:FindFirstChildWhichIsA("TextLabel", true)
                    if lbl then pcall(function() t = K.NormalizeName(lbl.Text or "") end) end
                end
                if t == "talk" or t == "interact" or t == "speak" or d.Name == "InteractionButton" then
                    btn = d
                    break
                end
            end
        end
    end
    if not btn then return false end
    return pressButton(btn)
end
K.ClickTalkButton = clickTalkButton

-- The intro / NPC converse (InteractionHUD.Converse) lists response options as
-- ImageButtons under Converse.Options (cloned Template, each with a Label). Their
-- text is the player's line ("Me? What's up?"), not accept/proceed keywords, so
-- click the option itself to advance the dialogue one segment.
local function advanceConverse()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    local converse
    for _, d in ipairs(pg:GetDescendants()) do
        if d.Name == "Converse" and not inOurUI(d) then converse = d break end
    end
    if not converse then return false end
    if not guiVisible(converse) then return false end
    local btn
    local options = converse:FindFirstChild("Options", true)
    if options then
        for _, ch in ipairs(options:GetChildren()) do
            if (ch:IsA("ImageButton") or ch:IsA("TextButton")) and ch.Name ~= "Template" then
                if guiVisible(ch) then btn = ch break end
            end
        end
    end
    if not btn then
        -- narration / single-option segments expose a Continue control instead
        for _, d in ipairs(converse:GetDescendants()) do
            if (d:IsA("ImageButton") or d:IsA("TextButton")) and not inOurUI(d) and guiVisible(d) then
                local t = ""
                pcall(function() t = K.NormalizeName(d.Text or "") end)
                if t == "" then
                    local lbl = d:FindFirstChild("Label", true)
                    if lbl then pcall(function() t = K.NormalizeName(lbl.Text or "") end) end
                end
                if d.Name == "Continue" or t == "continue" then btn = d break end
            end
        end
    end
    if not btn then return false end
    return pressButton(btn)
end
K.AdvanceConverse = advanceConverse

-- At a building door the game shows a hold "Enter Area" context on the same
-- InteractionButton. Hold it so the hold completes and the server teleports us
-- into the private area (the only legitimate way to reach an interior NPC).
local function clickEnterArea()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    local btn
    for _, d in ipairs(pg:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and not inOurUI(d) and guiVisible(d) then
            if d.Name == "InteractionButton" then
                local t = ""
                pcall(function() t = K.NormalizeName(d.Text or "") end)
                if t == "" then
                    local lbl = d:FindFirstChild("Label", true)
                    if lbl then pcall(function() t = K.NormalizeName(lbl.Text or "") end) end
                end
                if t:find("enter", 1, true) then btn = d break end
            end
        end
    end
    if not btn then return false end
    local clicked = false
    safe(function()
        if firesignal then firesignal(btn.MouseButton1Click) clicked = true end
    end)
    safe(function()
        local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
        local x, y = pos.X + size.X / 2, pos.Y + size.Y / 2
        if VirtualInput then
            VirtualInput:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(1.0)
            VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 0)
            clicked = true
        elseif mouse1click then
            mouse1click()
            clicked = true
        end
    end)
    return clicked
end
K.ClickEnterArea = clickEnterArea

local function acceptQuest(quest)
    if not quest then return false end
    if hasActiveQuest(quest.Name) then return true end
    -- 1) direct accept attempt (some builds expose Quests/Accept)
    fire("Quests", "Accept", quest.Name)
    -- 2) walk to giver and interact, then proceed the converse
    local giver = findGiver(quest.Giver)
    if giver then
        local hrp = giver:FindFirstChild("HumanoidRootPart") or giver.PrimaryPart
        if hrp then
            teleportTo(hrp.CFrame * CFrame.new(0, 0, 3))
            task.wait(0.2)
            local prompt = giver:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                safe(function()
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    else
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration + 0.05)
                        prompt:InputHoldEnd()
                    end
                end)
            end
            task.wait(0.3)
            proceedConverse()
        end
    end
    task.wait(0.3)
    return hasActiveQuest(quest.Name)
end
K.AcceptQuest = acceptQuest

local function repeatQuest(quest)
    if not quest then return false end
    return fire("Quests", "Repeat", quest.Name)
end
K.RepeatQuest = repeatQuest

-- ---- Live game objective (quest tracker HUD) ------------------------------
-- Read the objective the game is currently showing, e.g. "Talk to the Village
-- Chief". The tracker lives in PlayerGui; skip our own panel labels.
local function getGameObjective()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, d in ipairs(pg:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and not inOurUI(d) then
            local ok, txt = pcall(function() return d.Text end)
            if ok and type(txt) == "string" then
                local obj = K.ParseObjective(txt)
                if obj then return obj end
            end
        end
    end
    return nil
end
K.GetGameObjective = getGameObjective

-- Walk to a named NPC (or its interest point), fire its prompt, proceed dialog.
local npcCache = { name = nil, npc = nil, point = nil, t = 0 }
local lastNpcWarn = 0
local function interactWithNpc(name)
    if npcCache.name ~= name or os.clock() - npcCache.t > 5 then
        npcCache.name = name
        npcCache.npc = findGiver(name)
        npcCache.point = findInterestPoint(name)
        npcCache.t = os.clock()
    end
    local npc, point = npcCache.npc, npcCache.point
    local area = npc and interiorAreaName(npc) or nil
    local char = LocalPlayer and LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local nroot = npc and npcPosition(npc)
    -- Already inside the private area (the Enter teleport landed): stay and talk,
    -- do not walk back out to the door.
    local inside = (area and root and nroot
        and (nroot.Position - root.Position).Magnitude < 100) or false
    local dest
    if inside then
        dest = groundSafePos(nroot.Position)
    elseif point then
        -- the objective marker sits at the building entrance (outside)
        dest = groundSafePos(point.Position)
    elseif npc and not area then
        if nroot then dest = groundSafePos(nroot.Position) end
    elseif npc and area then
        local door = findAreaDoor(area)
        if door then dest = groundSafePos(door.Position) end
    end
    if not dest then
        if os.clock() - lastNpcWarn > 10 then
            lastNpcWarn = os.clock()
            log(1, "NPC/interest point not found:", name)
        end
        return false
    end
    moveTo(CFrame.new(dest))
    task.wait(0.3)
    -- Interior NPC: hold Enter at the door and let the server teleport us in.
    -- Tweening straight to the interior coordinates gets us kicked to lobby.
    if not inside and (area or point) then
        for _ = 1, 3 do
            if not clickEnterArea() then break end
            task.wait(1.5)
        end
        if area then npc = findGiver(name) or npc end
        -- Once the Enter teleport has actually landed us inside (NPC now close),
        -- close the last gap to it. While still outside, never glide inward.
        if area and npc then
            local nr = npcPosition(npc)
            if root and nr and (nr.Position - root.Position).Magnitude < 100 then
                moveTo(CFrame.new(groundSafePos(nr.Position)))
            end
        end
    end
    -- interest point only: the NPC stands nearby — pick the closest prompt holder
    if not npc then
        local char = LocalPlayer and LocalPlayer.Character
        local pos = char and char:GetPivot().Position
        local best, bestDist = nil, 25
        for _, m in ipairs(Workspace:GetDescendants()) do
            if m:IsA("Model") and m:FindFirstChildWhichIsA("ProximityPrompt", true) then
                local hrp = npcPosition(m)
                if hrp and pos then
                    local d = (hrp.Position - pos).Magnitude
                    if d < bestDist then best, bestDist = m, d end
                end
            end
        end
        npc = best
    end
    if npc then
        local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            safe(function()
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.05)
                    prompt:InputHoldEnd()
                end
            end)
        end
    end
    task.wait(0.3)
    clickTalkButton()
    task.wait(0.2)
    proceedConverse()
    for _ = 1, 8 do
        if not advanceConverse() then break end
        task.wait(0.35)
    end
    return true
end
K.InteractWithNpc = interactWithNpc

-- ---- Enemies -------------------------------------------------------------
local function getEnemies()
    local out = {}
    if not Workspace then return out end
    local folder = Workspace:FindFirstChild("Playability")
    folder = folder and folder:FindFirstChild("Enemys")
    if not folder then return out end
    local char = LocalPlayer and LocalPlayer.Character
    local pos = char and char:GetPivot().Position
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local hum = m:FindFirstChildOfClass("Humanoid")
            local hrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if hum and hrp and hum.Health > 0 then
                local name = m:GetAttribute("OriginalName") or m:GetAttribute("Name") or m.Name
                out[#out + 1] = {
                    Model = m, Humanoid = hum, Root = hrp,
                    Name = name,
                    Level = tonumber(m:GetAttribute("Level")) or 0,
                    Health = hum.Health, MaxHealth = hum.MaxHealth,
                    IsBoss = m:GetAttribute("IsBoss") == true,
                    Distance = pos and (hrp.Position - pos).Magnitude or math.huge,
                }
            end
        end
    end
    return out
end
K.GetEnemies = getEnemies

-- ---- Attack --------------------------------------------------------------
local lastAttack = 0
local comboIndex = 0

local function faceTarget(root)
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and root then
        safe(function()
            local look = CFrame.lookAt(hrp.Position, Vector3.new(root.Position.X, hrp.Position.Y, root.Position.Z))
            hrp.CFrame = look
        end)
    end
end

local function screenCenter()
    local cam = Workspace and Workspace.CurrentCamera
    if cam then
        local v = cam.ViewportSize
        return v.X / 2, v.Y / 2
    end
    return 0, 0
end

local function simulateClick()
    safe(function()
        local x, y = screenCenter()
        if VirtualInput then
            VirtualInput:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.01)
            VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 0)
        elseif mouse1click then
            mouse1click()
        end
    end)
end

-- Simulate skill key presses so the game's own SkillsSystem casts validly.
local skillKeys = { "Z", "X", "C", "V", "F" }
local skillIdx = 0
local lastSkill = 0
local function simulateSkills()
    if not K.Config.UseSkills then return end
    local now = os.clock()
    if now - lastSkill < 0.6 then return end
    lastSkill = now
    skillIdx = (skillIdx % #skillKeys) + 1
    local key = skillKeys[skillIdx]
    safe(function()
        if VirtualInput then
            VirtualInput:SendKeyEvent(true, key, false, game)
            task.wait(0.03)
            VirtualInput:SendKeyEvent(false, key, false, game)
        elseif keypress then
            keypress(key)
        end
    end)
end

local function serverTime()
    if Workspace then
        local ok, t = pcall(function() return Workspace:GetServerTimeNow() end)
        if ok and t then return t end
    end
    return os.clock()
end

local function remoteCombo()
    comboIndex = (comboIndex % 4) + 1
    local args = {
        Combo = comboIndex,
        CurrentCombo = comboIndex,
        CallTime = serverTime(),
        DelayTime = K.Config.ComboDelay,
    }
    fire(K.Config.AttackRemote or "CombatTools", K.Config.AttackAction or "DefaultCombo", args)
end

local function attackOnce()
    local now = os.clock()
    if now - lastAttack < (K.Config.AttackDelay or 0.12) then return end
    lastAttack = now
    if K.Config.UseRemoteAttack then
        remoteCombo()
    else
        simulateClick()
    end
    simulateSkills()
end
K.AttackOnce = attackOnce

-- ---- Stats ---------------------------------------------------------------
local function autoStats()
    if not K.Config.AutoStats then return end
    local pts = getAvailablePoints()
    if pts <= 0 then return end
    local d = getData()
    local current = dig(d, "Statistics") or {}
    local add = K.DistributeStats(pts, K.Config.StatWeights, current, nil)
    if not next(add) then return end
    fire("StatisticsData", "UpgradeStats", add)
    fire("StatisticsData", "SaveStats", add)
    log(2, "allocated stats points:", pts)
end
K.AutoStats = autoStats

-- ---- Haki ----------------------------------------------------------------
local function autoHaki()
    if not K.Config.AutoHaki then return end
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    local on = char:GetAttribute("Busoshoku")
    if on == false or on == nil then
        if not fire(K.Config.HakiRemote or "Busoshoku", K.Config.HakiAction or "Toggle") then
            fire("Abilitys", "Toggle", "Busoshoku") -- older builds
        end
    end
end

-- ---- Equip best weapon ---------------------------------------------------
local function toolType(tool)
    if ToolsInfo and type(ToolsInfo) == "table" then
        local def = ToolsInfo[tool.Name]
        if type(def) == "table" and def.ToolType then return def.ToolType end
    end
    return tool:GetAttribute("ToolType") or "Sword"
end

local function autoEquip()
    if not K.Config.AutoEquip then return end
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    local current = char:FindFirstChildOfClass("Tool")
    local pref = K.Config.WeaponPreference
    local function rank(t)
        local ty = toolType(t)
        for i, p in ipairs(pref) do
            if K.MatchName(ty, p) then return i end
        end
        return #pref + 1
    end
    if current and rank(current) == 1 then return end
    local best, bestRank = current, current and rank(current) or math.huge
    for _, t in ipairs(backpack:GetChildren()) do
        if t:IsA("Tool") then
            local r = rank(t)
            if r < bestRank then best, bestRank = t, r end
        end
    end
    if best and best ~= current then
        safe(function()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(best) end
        end)
    end
end

-- ---- Collect drops -------------------------------------------------------
local function autoCollect()
    if not K.Config.AutoCollect then return end
    if not Workspace then return end
    local folder = Workspace:FindFirstChild("Playability")
    folder = folder and folder:FindFirstChild("DroppedTools")
    if not folder then return end
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, d in ipairs(folder:GetChildren()) do
        local part = d:IsA("BasePart") and d or (d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")))
        if part then
            local dist = (part.Position - hrp.Position).Magnitude
            if dist <= (K.Config.CollectRange or 60) then
                local prompt = d:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    teleportTo(part.CFrame * CFrame.new(0, 2, 0))
                    safe(function()
                        if fireproximityprompt then fireproximityprompt(prompt) end
                    end)
                end
            end
        end
    end
end

-- ---- FPS boost -----------------------------------------------------------
local fpsApplied = false
local function applyFPSBoost()
    if not K.Config.FPSBoost or fpsApplied then return end
    fpsApplied = true
    safe(function()
        local lighting = getService("Lighting")
        if lighting then
            lighting.GlobalShadows = false
            lighting.FogEnd = 1e6
        end
    end)
    safe(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam")
                or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
    end)
    safe(function()
        if settings and settings().Rendering then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end
    end)
    log(1, "FPS boost applied")
end
K.ApplyFPSBoost = applyFPSBoost

-- ---- Farm loop -----------------------------------------------------------
local currentGoals = {}
local objectiveMode = "farm"   -- "farm" | "talk" | "collect"
local lastObjectiveRaw = nil

local function refreshGoals()
    local goals = activeQuest and activeQuest.Goals or {}
    if K.Config.ItemFarm and K.Config.TargetItem ~= "" and EnemysInfo then
        local droppers = K.FindItemDroppers(EnemysInfo, K.Config.TargetItem)
        if #droppers > 0 then
            goals = {}
            for _, dr in ipairs(droppers) do goals[#goals + 1] = dr.Name end
        end
    end
    currentGoals = goals
end

-- slow loop: quest management + stats / haki / equip / collect
local function farmTick()
    -- New-account intro / any open converse: click through the response options
    -- until the dialogue closes (each click advances one segment).
    if K.Config.AutoConverse then
        for _ = 1, 8 do
            if not advanceConverse() then break end
            task.wait(0.35)
        end
    end
    -- Follow the game's live objective first (talk / kill / collect).
    if K.Config.FollowGameQuest then
        local obj = getGameObjective()
        if obj then
            if obj.raw ~= lastObjectiveRaw then
                lastObjectiveRaw = obj.raw
                log(1, "objective:", obj.raw)
            end
            if obj.action == "kill" then
                objectiveMode = "farm"
                currentGoals = { obj.target }
                if obj.target:sub(-1) == "s" then
                    currentGoals[#currentGoals + 1] = obj.target:sub(1, -2)
                end
            elseif obj.action == "talk" or obj.action == "find" then
                objectiveMode = "talk"
                currentGoals = {}
                interactWithNpc(obj.target)
            elseif obj.action == "collect" then
                objectiveMode = "collect"
                currentGoals = {}
                autoCollect()
            end
            autoStats()
            autoHaki()
            autoEquip()
            applyFPSBoost()
            return
        end
    end
    objectiveMode = "farm"
    if K.Config.AutoQuest then
        local level = getLevel()
        -- Accept (teleport to giver) only when we have no quest or out-leveled it.
        -- Otherwise keep the quest and re-accept via Repeat, which needs no teleport,
        -- so the character stays on the mob instead of jittering back to the giver.
        local outgrown = activeQuest and tonumber(activeQuest.MaxLevel) and level > activeQuest.MaxLevel
        if not activeQuest or outgrown then
            activeQuest = chooseQuest()
            if activeQuest then
                acceptQuest(activeQuest)
                log(1, "quest:", activeQuest.Name, "goals:", table.concat(activeQuest.Goals, ", "))
            end
        else
            repeatQuest(activeQuest)
        end
    end
    if not activeQuest then activeQuest = chooseQuest() end
    refreshGoals()
    autoStats()
    autoHaki()
    autoEquip()
    autoCollect()
    applyFPSBoost()
end
K.FarmTick = farmTick

-- fast loop: reposition to the best target and attack
local function combatTick()
    if not K.Config.AutoFarm then return end
    if objectiveMode ~= "farm" then return end
    local enemies = getEnemies()
    local opts = { maxRange = K.Config.MaxFarmRange, boss = K.Config.BossFarm }
    opts.allowAny = (#currentGoals == 0)
    local target = K.PickEnemy(enemies, currentGoals, opts)
    if not target and K.Config.FarmAnyFallback then
        opts.allowAny = true
        target = K.PickEnemy(enemies, currentGoals, opts)
    end
    if target then
        local root = target.Root
        moveTo(root.CFrame * CFrame.new(0, 0, K.Config.FarmDistance or 6))
        faceTarget(root)
        attackOnce()
    end
end
K.CombatTick = combatTick

-- ---- Main loop -----------------------------------------------------------
local function startLoop()
    if running then return end
    running = true
    task.spawn(function()
        while running do
            local ok = safe(farmTick)
            if not ok then task.wait(0.5) end
            task.wait(K.Config.QuestRefresh or 1.0)
        end
    end)
    task.spawn(function()
        while running do
            safe(combatTick)
            task.wait(K.Config.FastAttack and (K.Config.AttackDelay or 0.12) or 0.4)
        end
    end)
end

local function stopLoop()
    running = false
end
K.Stop = stopLoop
K.Resume = startLoop

-- ---- Anti-AFK / auto-rejoin ----------------------------------------------
local rejoining = false
local function doRejoin()
    if rejoining then return end
    rejoining = true
    log(1, "death loop detected — rejoining")
    safe(function()
        local ts = getService("TeleportService")
        if ts then ts:Teleport(game.PlaceId, LocalPlayer) end
    end)
end
K.Rejoin = doRejoin

local deathTimes = {}
local function trackCharacter(char)
    if not char then return end
    safe(function()
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
        if not hum then return end
        hum.Died:Connect(function()
            local now = os.clock()
            deathTimes[#deathTimes + 1] = now
            while #deathTimes > 0 and now - deathTimes[1] > 60 do
                table.remove(deathTimes, 1)
            end
            if K.Config.AutoRejoin and #deathTimes >= 5 then doRejoin() end
        end)
    end)
end

local function setupUtility()
    if K.Config.AntiAFK then
        safe(function()
            local vu = getService("VirtualUser")
            LocalPlayer.Idled:Connect(function()
                if vu then
                    vu:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    vu:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                end
            end)
        end)
    end
    safe(function()
        if LocalPlayer.Character then trackCharacter(LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(trackCharacter)
    end)
end

-- ---- UI ------------------------------------------------------------------
local panelGui
local function buildUI()
    safe(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local gui = Instance.new("ScreenGui")
        gui.Name = "VoxKaitunUI"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = pg
        panelGui = gui

        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 230, 0, 320)
        main.Position = UDim2.new(0, 20, 0.5, -160)
        main.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
        main.BorderSizePixel = 0
        main.Active = true
        main.Draggable = true
        main.Parent = gui
        Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 30)
        title.BackgroundTransparency = 1
        title.Text = "Vox Seas Kaitun"
        title.TextColor3 = Color3.fromRGB(120, 200, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        title.Parent = main

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -16, 1, -70)
        scroll.Position = UDim2.new(0, 8, 0, 34)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 4
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = main
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.Parent = scroll

        local toggles = {
            "AutoFarm", "AutoQuest", "FastAttack", "AutoStats", "AutoHaki",
            "AutoEquip", "AutoCollect", "UseRemoteAttack", "UseSkills",
            "BossFarm", "ItemFarm", "AntiAFK", "AutoRejoin", "FPSBoost",
        }
        for _, name in ipairs(toggles) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
            btn.TextColor3 = Color3.fromRGB(230, 230, 230)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.Text = "  " .. name .. ": " .. (K.Config[name] and "ON" or "OFF")
            btn.Parent = scroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            btn.MouseButton1Click:Connect(function()
                K.Config[name] = not K.Config[name]
                btn.Text = "  " .. name .. ": " .. (K.Config[name] and "ON" or "OFF")
                btn.BackgroundColor3 = K.Config[name] and Color3.fromRGB(40, 70, 90) or Color3.fromRGB(35, 38, 50)
            end)
        end

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -90, 0, 28)
        status.Position = UDim2.new(0, 8, 1, -32)
        status.BackgroundTransparency = 1
        status.TextColor3 = Color3.fromRGB(160, 170, 190)
        status.Font = Enum.Font.Gotham
        status.TextSize = 12
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Text = "Lv ? | starting..."
        status.Parent = main

        local stopBtn = Instance.new("TextButton")
        stopBtn.Size = UDim2.new(0, 74, 0, 24)
        stopBtn.Position = UDim2.new(1, -82, 1, -30)
        stopBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
        stopBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.TextSize = 12
        stopBtn.Text = "STOP"
        stopBtn.Parent = main
        Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 5)
        stopBtn.MouseButton1Click:Connect(function()
            if running then
                stopLoop()
                stopBtn.Text = "RESUME"
                stopBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 50)
            else
                startLoop()
                stopBtn.Text = "STOP"
                stopBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
            end
        end)

        task.spawn(function()
            while gui.Parent do
                local q = activeQuest and activeQuest.Name or "-"
                status.Text = string.format("Lv %d | %s", getLevel(), q)
                task.wait(1)
            end
        end)
    end)
end

-- ---- Auto start: click the game's START GAME menu so a player spawns ------
local function clickGameStart()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextButton") and d.Visible and not inOurUI(d) then
            local t = K.NormalizeName(d.Text)
            if t == "start game" or t == "start" or t == "play" then
                local clicked = false
                safe(function()
                    if firesignal then
                        firesignal(d.MouseButton1Click)
                        clicked = true
                    end
                end)
                if clicked then return true end
            end
        end
    end
    return false
end
K.ClickGameStart = clickGameStart

local function hasCharacter()
    local c = LocalPlayer and LocalPlayer.Character
    return c ~= nil and c:FindFirstChild("HumanoidRootPart") ~= nil
end
K.HasCharacter = hasCharacter

-- Wait for the player to exist (game start menu), auto-clicking START if enabled.
local function startWatcher()
    task.spawn(function()
        local tries = 0
        while not hasCharacter() and tries < 300 do
            if K.Config.AutoStartGame then
                if not clickGameStart() then
                    safe(function()
                        local r = getRemote("StartGame", false)
                        if r then r:FireServer() end
                    end)
                end
            end
            task.wait(1)
            tries = tries + 1
        end
        if hasCharacter() then
            log(1, "player spawned — farming")
            startLoop()
        end
    end)
end

-- ---- Init / Start --------------------------------------------------------
local initialized = false
function K.Init()
    if initialized then return true end
    local ok = pcall(function()
        LocalPlayer = getService("Players").LocalPlayer
        ReplicatedStorage = getService("ReplicatedStorage")
        Workspace = getService("Workspace")
        RunService = getService("RunService")
        VirtualInput = getService("VirtualInputManager")
    end)
    if not ok or not LocalPlayer then return false end
    loadDataModules()
    setupUtility()
    buildUI()
    initialized = true
    return true
end

function K.Start()
    if not K.Init() then
        log(0, "not in Roblox / no LocalPlayer — idle")
        return false
    end
    log(1, "started. level:", getLevel())
    startLoop()
    return true
end

--==========================================================================
-- AUTO-RUN (only inside Roblox). Returns K for external testing otherwise.
--==========================================================================
local inRoblox = false
pcall(function()
    if game and game:GetService("Players") and game:GetService("Players").LocalPlayer then
        inRoblox = true
    end
end)
if inRoblox then
    if K.Init() then
        startWatcher()
    end
end

return K
