--[[
    BSS Kaitun Bridge - cau noi "Bee Swarm Kaitun" -> Dashboard (API.md v1)
    KHONG tu farm: chi DOC trang thai live cua macro (getgenv().__BSS_KAITUN)
    va POST JSON ve dashboard (POST /api/ingest, header X-API-Key).

    Thu tu chay:
      1. node server.js  ->  mo http://127.0.0.1:8787 , lay API key o trang "Help - API Key".
      2. Execute kaitun_beeswarm.lua TRUOC (macro chinh).
      3. Execute bridge nay SAU. Chay lai an toan: bridge cu tu dong Shutdown.

    CAU HINH: da nhung san trong BUILTIN_CONFIG (cuoi phan CONFIG ben duoi) -
    chi can loadstring file nay la chay. Neu muon ghi de, set
    getgenv().BSS_KAITUN_BRIDGE_CONFIG TRUOC khi execute (bang nay KHONG con
    tu ghi de getgenv nhu ban cu nua - do la nguyen nhan mat config truoc day).
]]

-- ============================================================
-- BUILTIN_CONFIG - sua Url/ApiKey tai day neu doi may/doi key.
-- Url nen dung IP LAN (vi du 192.168.x.x) vi Roblox thuong bi
-- chan loopback 127.0.0.1 trong process game -> ConnectFail.
-- ============================================================
local BUILTIN_CONFIG = {
    Url = "http://192.168.1.142:8787/api/ingest",
    ApiKey = "kbs_4747b9574d383a332109e862a83ab8b3c54d264a5405be10",
    Interval = 3, -- giay giua cac lan POST
}

if game.PlaceId ~= 1537690962 then
    warn("[Kaitun Bridge] Wrong game. Current PlaceId: " .. tostring(game.PlaceId))
    return
end

local ENV = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
    repeat task.wait(0.1) until game:IsLoaded()
end
local Player = Players.LocalPlayer
while not Player do task.wait(0.1); Player = Players.LocalPlayer end

-- Re-execute safety: tat bridge cu (dung loop, ngat ket noi) truoc khi chay lai
local previous = rawget(ENV, "__BSS_KAITUN_BRIDGE")
if type(previous) == "table" and type(previous.Shutdown) == "function" then
    print("[Kaitun Bridge] Phat hien bridge cu - tat truoc khi chay lai")
    pcall(previous.Shutdown)
    task.wait(0.25)
end

-- API identity cua executor (kaitun goi Quests duoi identity 2; thieu thi bo qua)
local GetThreadIdentity, SetThreadIdentity = rawget(ENV, "getthreadidentity"), rawget(ENV, "setthreadidentity")
local SYN = rawget(ENV, "syn")
if type(SYN) == "table" then
    GetThreadIdentity = GetThreadIdentity or SYN.get_thread_identity
    SetThreadIdentity = SetThreadIdentity or SYN.set_thread_identity
end

local unpackFn = unpack or table.unpack
local warned = {}

local function warnOnce(key, message)
    if not warned[key] then warned[key] = true; warn(message) end
end

-- Chay fn trong pcall: mot section loi khong bao gio lam roi ca ban POST
local function safe(fn, default)
    local ok, result = pcall(fn)
    if ok and result ~= nil then return result end
    return default
end

local function isFinite(n)
    return n == n and n ~= math.huge and n ~= -math.huge
end

local function firstNumber(text) -- so dau tien trong chuoi, bo phay hang nghin
    if type(text) ~= "string" then return nil end
    return tonumber(text:gsub(",", ""):match("(%d+%.?%d*)"))
end

-- Ban sao chi giu key -> so huu han (JSON-an toan); nil neu nguon khong phai bang
local function sanitizeMap(source)
    if type(source) ~= "table" then return nil end
    local out = {}
    for key, value in pairs(source) do
        local n = tonumber(value)
        if n and isFinite(n) then out[tostring(key)] = n end
    end
    return out
end

-- Doc config: getgenv (neu user set TRUOC khi execute) > BUILTIN_CONFIG
local cfgIn = rawget(ENV, "BSS_KAITUN_BRIDGE_CONFIG")
local src = (type(cfgIn) == "table" and cfgIn) or BUILTIN_CONFIG
local CFG = {
    Url = tostring(src.Url or "http://127.0.0.1:8787/api/ingest"),
    ApiKey = tostring(src.ApiKey or ""),
    Interval = math.max(1, tonumber(src.Interval) or 3),
}
-- Tu them duong dan ingest neu user chi dan URL goc (http://127.0.0.1:8787)
local ingestPath = "/api/ingest"
if #CFG.Url >= #ingestPath and CFG.Url:sub(-#ingestPath) ~= ingestPath then
    if CFG.Url:sub(-1) == "/" then CFG.Url = CFG.Url:sub(1, -2) end
    CFG.Url = CFG.Url .. ingestPath
    warn("[Kaitun Bridge] Url thieu duong dan - tu dung: " .. CFG.Url)
end
if CFG.ApiKey == "" or CFG.ApiKey:find("dán API key", 1, true) then
    warn("[Kaitun Bridge] ApiKey trống hoặc placeholder - vẫn gửi, nếu server trả 401 hãy dán ApiKey vào BUILTIN_CONFIG hoặc getgenv().BSS_KAITUN_BRIDGE_CONFIG")
end

-- Danh sach host du phong: ConnectFail o host nay thi tu chuyen sang host khac
-- (Roblox thuong chan loopback 127.0.0.1 -> uu tien IP LAN truoc).
local sch, host0, path0 = CFG.Url:match("^(https?://)([^/]+)(/.*)$")
if not sch then sch, host0, path0 = "http://", "127.0.0.1:8787", "/api/ingest" end
local LAN_HOST = BUILTIN_CONFIG.Url:match("^https?://([^/]+)") or "192.168.1.142:8787"
local seenHosts, hostList = {}, {}
for _, h in ipairs({ host0, LAN_HOST, "127.0.0.1:8787", "localhost:8787" }) do
    if not seenHosts[h] then
        seenHosts[h] = true
        hostList[#hostList + 1] = h
    end
end
local hostIdx = 1
local function rotateHost()
    hostIdx = hostIdx % #hostList + 1
    CFG.Url = sch .. hostList[hostIdx] .. path0
    return CFG.Url
end

-- Module game: require lazy bang FindFirstChild (khong block vong POST).
-- moduleStates[name]: false = chua co (thu lai lan sau), nil = require loi (bo qua)
local moduleStates = { ClientStatCache = false, Quests = false, LocalPlanters = false }

local function getModule(name)
    local state = moduleStates[name]
    if state ~= false then return state end
    local module = ReplicatedStorage:FindFirstChild(name)
    if not module then return false end
    local ok, result = pcall(require, module)
    state = (ok and type(result) == "table") and result or nil
    moduleStates[name] = state
    return state
end

-- Stats: kaitun dung StatCache:Update() roi StatCache:Get() (xem getStats).
-- Bridge goi nhe: Get moi tick, chi Update toi da 15s/lan
local statsCache, lastStatsUpdate = nil, -math.huge

local function fetchStats()
    local cache = getModule("ClientStatCache")
    if not cache then return statsCache end
    if os.clock() - lastStatsUpdate >= 15 then
        lastStatsUpdate = os.clock()
        local ok, updated = pcall(cache.Update, cache)
        if ok and type(updated) == "table" then statsCache = updated end
    end
    local okGet, got = pcall(cache.Get, cache)
    if okGet and type(got) == "table" then statsCache = got end
    return statsCache
end

-- Goi Quests:Get/Progress duoi identity 2 giong kaitun (pcall, thieu API thi goi thang)
local function questCall(method, ...)
    local quests = getModule("Quests")
    if type(quests) ~= "table" or type(quests[method]) ~= "function" then return nil end
    local oldIdentity
    if type(GetThreadIdentity) == "function" then pcall(function() oldIdentity = GetThreadIdentity() end) end
    if type(SetThreadIdentity) == "function" then pcall(SetThreadIdentity, 2) end
    local results = { pcall(quests[method], quests, ...) }
    if type(SetThreadIdentity) == "function" and oldIdentity ~= nil then pcall(SetThreadIdentity, oldIdentity) end
    if not results[1] then return nil end
    return unpackFn(results, 2, #results)
end

-- Cac section payload: moi section mot ham/pcall rieng qua safe()
local function buildPlayer()
    local lp = Players.LocalPlayer
    return lp and { name = lp.Name, userId = lp.UserId } or nil
end

local function coreStat(name) -- CoreStats: Honey / Pollen / Capacity (ValueBase .Value)
    local v = Player:FindFirstChild("CoreStats")
    v = v and v:FindFirstChild(name)
    if v and v:IsA("ValueBase") then
        local ok, value = pcall(function() return v.Value end)
        if ok then return tonumber(value) end
    end
    return nil
end

-- Dem ong: o khong rong trong stats.Honeycomb; suc chua: 25 + so HiveSlots da mua
local function buildBees(stats)
    if type(stats) ~= "table" then return nil end
    local count = 0
    if type(stats.Honeycomb) == "table" then
        for _, cell in pairs(stats.Honeycomb) do
            local bee = type(cell) == "table" and (cell.BeeType or cell.Type) or nil
            if type(bee) == "string" and bee ~= "" then count = count + 1 end
        end
    end
    local purchases = type(stats.Totals) == "table" and stats.Totals.Purchases or nil
    local slots = type(purchases) == "table" and tonumber(purchases.HiveSlots) or nil
    return { count = count, capacity = 25 + (slots or 0) }
end

-- Quests: tu stats.Quests.Active, moi quest goi Quests:Get + Quests:Progress.
-- target = so dau tien trong mo ta (bo phay); current = floor(frac * target)
local function buildQuests(stats)
    if type(stats) ~= "table" then return nil end
    local active = type(stats.Quests) == "table" and stats.Quests.Active or nil
    if type(active) ~= "table" then return nil end
    local out = {}
    for _, entry in pairs(active) do
        if #out >= 25 then break end -- cap 25 quest
        local questName = type(entry) == "table" and entry.Name or entry
        if type(questName) == "string" and questName ~= "" then
            local info = questCall("Get", questName)
            if type(info) == "table" then
                local progress = questCall("Progress", questName, stats)
                local infoTasks = type(info.Tasks) == "table" and info.Tasks or {}
                local tasks = {}
                for index, task in ipairs(infoTasks) do
                    local desc = type(task) == "table" and tostring(task.Description or "") or ""
                    local target = firstNumber(desc) or 0
                    local prog = type(progress) == "table" and progress[index] or nil
                    local frac = (type(prog) == "table" and (tonumber(prog[1]) or 0))
                        or (type(prog) == "number" and prog or 0)
                    if frac ~= frac or frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
                    table.insert(tasks, { description = desc, current = math.floor(frac * target),
                        target = target, done = frac >= 1 })
                end
                table.insert(out, { name = questName, npc = type(info.NPC) == "string" and info.NPC or "",
                    count = #tasks, tasks = tasks })
            end
        end
    end
    return out
end

-- Planters (best-effort): doc upvalues cua planters.LoadPlanter nhu kaitun lam
local function planterPercent(data)
    local gui = data and data.Gui
    if not (gui and gui.Bar and gui.Bar.FillBar) then return nil end
    local ok, value = pcall(function()
        return gui.Bar.FillBar.Size.X.Scale / math.max(0.001, gui.Bar.Size.X.Scale)
    end)
    local n = ok and tonumber(value) or nil
    if not n or n ~= n or n < 0 then return nil end
    return math.min(1, n)
end

local function buildPlanters()
    local planters = getModule("LocalPlanters")
    if type(planters) ~= "table" or type(planters.LoadPlanter) ~= "function" then return nil end
    local getUpvalues = (type(debug) == "table" and debug.getupvalues) or rawget(ENV, "getupvalues")
    if type(getUpvalues) ~= "function" then return nil end
    local ok, upvalues = pcall(getUpvalues, planters.LoadPlanter)
    if not ok or type(upvalues) ~= "table" then return nil end
    local out, seen = {}, {}
    for _, candidate in pairs(upvalues) do
        if type(candidate) == "table" then
            for _, data in pairs(candidate) do
                local percent = type(data) == "table" and data.IsMine and data.ActorID
                    and not seen[data.ActorID] and planterPercent(data) or nil
                if percent then
                    seen[data.ActorID] = true
                    table.insert(out, { planter = data.PotModel and tostring(data.PotModel)
                        or "Unknown Planter", percent = percent })
                end
            end
        end
    end
    return out
end

-- Amulets: quet phong thu stats tim key chua "amulet" (khong phan biet hoa thuong)
-- voi gia tri dang {Name, Stats} (Stats la chuoi thuyet minh raw); ho tro grouped map
local function buildAmulets(stats)
    if type(stats) ~= "table" then return nil end
    local out = {}
    local function push(typeKey, value)
        local name = type(value) == "table" and value.Name or nil
        local text = type(value) == "table" and value.Stats or nil
        if type(name) ~= "string" and type(text) ~= "string" then return end
        local t = tostring(typeKey):gsub("[Aa]mulet", ""):gsub("^%s*(.-)%s*$", "%1")
        if t == "" then t = tostring(typeKey) end
        table.insert(out, { type = t, name = type(name) == "string" and name or (t .. " Amulet"),
            statsText = type(text) == "string" and text or "" })
    end
    for key, value in pairs(stats) do
        if type(key) == "string" and key:lower():find("amulet", 1, true) and type(value) == "table" then
            local before = #out
            push(key, value)
            if #out == before then -- grouped map: key con -> {Name, Stats}
                for subKey, subValue in pairs(value) do
                    push(type(subKey) == "number" and key or subKey, subValue)
                end
            end
        end
    end
    return out
end

-- Hive: uu tien mirror instance live (Player.Honeycomb -> .Value -> Cells),
-- fallback ve stats.Honeycomb khi chua replicate
local function buildHive(stats)
    local live = {}
    local readLive = pcall(function()
        local ref = Player:FindFirstChild("Honeycomb")
        local container = ref and ref:IsA("ObjectValue") and ref.Value
        container = container and container:FindFirstChild("Cells")
        if not container then return end
        for _, cell in ipairs(container:GetChildren()) do
            local x, y = cell.Name:match("^C(%d+),(%d+)$")
            local kind = x and (cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType"))
            if kind and kind:IsA("ValueBase") then
                local level = cell:FindFirstChild("Level") or cell:FindFirstChild("BeeLevel")
                if level and not level:IsA("ValueBase") then level = nil end
                table.insert(live, { x = tonumber(x), y = tonumber(y), type = tostring(kind.Value),
                    gifted = cell:FindFirstChild("GiftedCell") ~= nil,
                    level = level and tonumber(level.Value) or nil })
            end
        end
    end)
    if readLive and #live > 0 then return live end
    local out = {}
    local cells = type(stats) == "table" and stats.Honeycomb or nil
    if type(cells) ~= "table" then return out end
    for key, cell in pairs(cells) do
        local x, y = tostring(key):match("^(%d+)%s*,%s*(%d+)$")
        local bee = x and type(cell) == "table" and (cell.BeeType or cell.Type) or nil
        if type(bee) == "string" and bee ~= "" then
            table.insert(out, { x = tonumber(x), y = tonumber(y), type = bee,
                gifted = cell.Gifted == true, level = tonumber(cell.Level) })
        end
    end
    return out
end

local function buildBlender(stats)
    if type(stats) ~= "table" then return nil end
    local b = stats.BlenderState
    if type(b) ~= "table" then return nil end
    local recipe, count = b.Recipe, tonumber(b.Count) or 0
    if recipe == nil and count == 0 then return nil end
    local out = { recipe = tostring(recipe or ""), count = count }
    local minutes = tonumber(b.MinutesLeft) or tonumber(b.TimeLeft) -- neu module cho san
    if minutes then out.minutesLeft = minutes end
    return out
end

-- CompletedGear co the la set {ten=true} hoac mang {ten,...} - tu nhan dang shape
local function buildCompletedGear(rt)
    if type(rt) ~= "table" or type(rt.CompletedGear) ~= "table" then return nil end
    local out = {}
    if #rt.CompletedGear > 0 then
        for _, value in ipairs(rt.CompletedGear) do
            if type(value) == "string" then table.insert(out, value) end
        end
    end
    if #out == 0 then
        for key, value in pairs(rt.CompletedGear) do
            if type(key) == "string" and value then table.insert(out, key)
            elseif type(value) == "string" then table.insert(out, value) end
        end
    end
    table.sort(out)
    return out
end

-- Gom payload: moi section mot pcall (safe), section loi -> bi bo qua
local function getRuntime() -- runtime cua kaitun (nil -> che do standalone)
    local rt = rawget(ENV, "__BSS_KAITUN")
    return type(rt) == "table" and rt or nil
end

local function buildPayload()
    local rt = getRuntime()
    if not rt then
        warnOnce("standalone", "[Kaitun Bridge] Kaitun Runtime not found - sending basic data only")
    end
    local stats = safe(fetchStats, nil)
    local payload = {}
    payload.player = safe(buildPlayer, nil)
    payload.core = safe(function()
        local honey, pollen, capacity = coreStat("Honey"), coreStat("Pollen"), coreStat("Capacity")
        if honey == nil and pollen == nil and capacity == nil then return nil end
        return { honey = honey, pollen = pollen, capacity = capacity }
    end, nil)
    payload.uptime = safe(function()
        local started = type(rt) == "table" and tonumber(rt.StartedAt) or nil
        return started and { seconds = math.max(0, math.floor(os.clock() - started)) } or nil
    end, nil)
    payload.bees = safe(function() return buildBees(stats) end, nil)
    payload.eggs = safe(function() return sanitizeMap(stats and stats.Eggs) end, nil)
    payload.treats = safe(function()
        if type(stats) ~= "table" then return nil end
        local map = sanitizeMap(stats.Treats)
        if map then return map end
        local n = tonumber(stats.Treats) -- Treats dang so (hiem): goi lai theo shape map
        return n and isFinite(n) and { Treat = n } or nil
    end, nil)
    payload.tickets = safe(function()
        local eggs = type(stats) == "table" and sanitizeMap(stats.Eggs) or nil
        return eggs and (eggs.Ticket or eggs.Tickets) or nil
    end, nil)
    payload.quests = safe(function() return buildQuests(stats) end, nil)
    payload.planters = safe(buildPlanters, nil)
    payload.amulets = safe(function() return buildAmulets(stats) end, nil)
    payload.hive = safe(function() return buildHive(stats) end, nil)
    payload.blender = safe(function() return buildBlender(stats) end, nil)
    payload.state = safe(function() return type(rt) == "table" and rt.State ~= nil and tostring(rt.State) or nil end, nil)
    payload.detail = safe(function() return type(rt) == "table" and rt.Detail ~= nil and tostring(rt.Detail) or nil end, nil)
    payload.progressStage = safe(function() return type(rt) == "table" and rt.ProgressStage ~= nil and tostring(rt.ProgressStage) or nil end, nil)
    payload.honeyPerHour = safe(function()
        if type(rt) ~= "table" or type(rt.HoneyPerHour) ~= "function" then return nil end
        local ok, value = pcall(rt.HoneyPerHour)
        return (ok and type(value) == "number" and isFinite(value)) and value or nil
    end, nil)
    payload.boost = safe(function()
        if type(rt) ~= "table" then return nil end
        local left = (tonumber(rt.BoostedFieldUntil) or 0) - os.clock()
        if type(rt.BoostedField) == "string" and rt.BoostedField ~= "" and left > 0 then
            return { field = rt.BoostedField, secondsLeft = math.floor(left) }
        end
    end, nil)
    payload.nextGear = safe(function()
        local target = type(rt) == "table" and rt.NextGearTarget or nil
        if type(target) ~= "table" then return nil end
        return { item = tostring(target.Item or target.Type or "?"), cost = tonumber(target.Cost) or nil }
    end, nil)
    payload.completedGear = safe(function() return buildCompletedGear(rt) end, nil)
    return payload
end

-- HTTP (executor tu mang): http_request / syn.request / request / http.request
local function responseCode(resp)
    if type(resp) ~= "table" then return nil end
    return tonumber(resp.StatusCode) or tonumber(resp.statusCode)
        or tonumber(resp.code) or tonumber(resp.Code) or tonumber(resp.Status)
end

local function resolveHttp()
    local httpGlobal = rawget(ENV, "http")
    local candidates = { rawget(ENV, "http_request"), type(SYN) == "table" and SYN.request or nil,
        rawget(ENV, "request"), type(httpGlobal) == "table" and httpGlobal.request or nil }
    for _, fn in ipairs(candidates) do
        if type(fn) == "function" then return fn end
    end
end

local function httpPost(send, body)
    local headers = { ["Content-Type"] = "application/json" }
    if CFG.ApiKey ~= "" then headers["X-API-Key"] = CFG.ApiKey end
    local ok, resp = pcall(send, { Url = CFG.Url, Method = "POST", Headers = headers, Body = body })
    if not ok then return false, tostring(resp) end
    local code = responseCode(resp)
    if not code then return false, "phan hoi HTTP khong doc duoc ma trang thai" end
    if code < 200 or code >= 300 then return false, code end
    return true, code
end

-- Vong POST: loi lien tiep x3 tro len thi backoff x2 (toi da 60s), thanh cong reset
local Bridge = {
    Running = false,
    Connections = {}, -- place cho cac ket noi event (neu can mo rong)
    Http = nil,
    PostedOnce = false,
}

local function postLoop()
    if not Bridge.Http then return end -- khong co HTTP API: da warn va disable
    local waitSeconds, fails = CFG.Interval, 0
    while Bridge.Running do
        local okEncode, body = pcall(function() return HttpService:JSONEncode(buildPayload()) end)
        if okEncode and type(body) == "string" then
            local okSend, info = httpPost(Bridge.Http, body)
            if okSend then
                fails, waitSeconds = 0, CFG.Interval -- thanh cong: reset backoff
                if not Bridge.PostedOnce then
                    Bridge.PostedOnce = true
                    print("[Kaitun Bridge] posted")
                end
            else
                fails = fails + 1
                if info == 401 then
                    warnOnce("http401", "[Kaitun Bridge] Server trả 401 (invalid_api_key) - ApiKey sai, dán key trang Help vào BUILTIN_CONFIG/getgenv rồi execute lại")
                elseif tostring(info):find("ConnectFail", 1, true) then
                    -- host hiện tại không nối được (vd 127.0.0.1 bị Roblox chặn) -> thử host kế tiếp ngay
                    warn("[Kaitun Bridge] ConnectFail @ " .. tostring(hostList[hostIdx])
                        .. " - chuyển host: " .. tostring(rotateHost()))
                    fails, waitSeconds = 0, CFG.Interval
                elseif fails == 1 or fails % 10 == 0 then
                    warn("[Kaitun Bridge] POST thất bại (" .. tostring(info) .. ") - thử lại sau " .. tostring(waitSeconds) .. "s")
                end
                if fails >= 3 then waitSeconds = math.min(waitSeconds * 2, 60) end
            end
        else
            fails = fails + 1
            warnOnce("encode", "[Kaitun Bridge] Không đóng gói được JSON: " .. tostring(body))
            if fails >= 3 then waitSeconds = math.min(waitSeconds * 2, 60) end
        end
        local slept = 0 -- ngu theo buoc nho de Shutdown phan hoi nhanh
        while Bridge.Running and slept < waitSeconds do
            local step = math.min(0.25, waitSeconds - slept)
            task.wait(step)
            slept = slept + step
        end
    end
end

function Bridge.Shutdown()
    Bridge.Running = false
    for _, connection in ipairs(Bridge.Connections) do pcall(function() connection:Disconnect() end) end
    Bridge.Connections = {}
    if rawget(ENV, "__BSS_KAITUN_BRIDGE") == Bridge then rawset(ENV, "__BSS_KAITUN_BRIDGE", nil) end
    print("[Kaitun Bridge] da tat")
end

Bridge.Http = resolveHttp()
if not Bridge.Http then
    warn("[Kaitun Bridge] Không tìm thấy HTTP API (http_request / syn.request / request / http.request) - bridge disable")
end
Bridge.Running = true
ENV.__BSS_KAITUN_BRIDGE = Bridge
task.spawn(postLoop)
if Bridge.Http then
    -- log trang thai config de debug: thieu config -> mac dinh 127.0.0.1 (Roblox co the bi chan loopback)
    if type(cfgIn) == "table" then
        print("[Kaitun Bridge] config: da tim thay getgenv().BSS_KAITUN_BRIDGE_CONFIG (ghi de BUILTIN)")
    else
        print("[Kaitun Bridge] config: khong co getgenv - dung BUILTIN_CONFIG trong file")
    end
    local keyState = (CFG.ApiKey ~= "" and not CFG.ApiKey:find("dán API key", 1, true))
        and ("OK (" .. #CFG.ApiKey .. " ky tu)") or "CHUA CO"
    print("[Kaitun Bridge] started -> " .. CFG.Url .. " | moi " .. tostring(CFG.Interval)
        .. "s | ApiKey: " .. keyState)
end
