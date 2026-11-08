-- =============================================================================
-- TFFA SUPPORTER (supporter_atlas.lua) — chạy SONG SONG atlas
-- =============================================================================
-- NHIỆM VỤ (spec user):
--   1. Inventory có egg bất kỳ -> hatch vào ô trống trong hive (remote).
--   2. Đủ ticket -> mua Silver Egg TỪ XA (ItemPackageEvent) -> hatch đẩy
--      mạnh progress hive.
--   3. Song song: check Treat trong inventory -> feed hive TỪ XA cho nhiệm
--      vụ Mother Bear.
--   4. STAR EGG RE-ROLL: Star Egg KHÔNG hatch — user/atlas bỏ nó vào STICKER
--      PRINTER; supporter ARM lúc alert "star egg" (hoặc gọi tay
--      __TFFA_SUP.ArmStarEgg()), POLL Stickers.Inbox: sticker mới ra mà
--      KHÔNG phải "Star Sign"/"Star Cub" -> gọi REJOIN (tool user gửi sau,
--      fallback TeleportService cùng place). Sticker Printer = việc của atlas.
--   5. CHANGE ACC (Yummytool): đủ yêu cầu (sticker jackpot) -> ghi
--      playername.txt (Workspace mode) hoặc GET API main-session-group
--      (API mode) -> Yummytool change acc. Trigger cấu hình được.
--
-- REJOIN TOOL: Config.RejoinFn là SLOT cắm vào — user gửi tool sau thì gán:
--   getgenv().TFFA_SUPPORTER_CONFIG.RejoinFn = function() ... end
-- Chưa cắm thì dùng fallback TeleportService về cùng place (game.PlaceId).
--
-- CHẠY ĐỘC LẬP: không require kaitun. Nếu chạy CÙNG kaitun thì tắt
-- kaitun's AutoQuestFeedTasks/AutoStarTreat để tránh double-feed.
-- DỪNG: getgenv().__TFFA_SUP.Stop()
-- =============================================================================

local ENV = (getgenv and getgenv()) or _G
if ENV.__TFFA_SUP and type(ENV.__TFFA_SUP.Stop) == "function" then
    pcall(ENV.__TFFA_SUP.Stop)
    task.wait(0.2)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local BSS_PLACE_ID = 1537690962
if game.PlaceId ~= BSS_PLACE_ID then
    warn("[TFFA Sup] Wrong place " .. tostring(game.PlaceId))
    return
end

local Player = Players.LocalPlayer
repeat task.wait() until game:IsLoaded() and Player

local Config = {
    Enabled = true,
    -- 1) HATCH mọi egg trong inventory vào ô trống (ngoại lệ bên dưới).
    -- LƯU Ý: Star Egg KHÔNG hatch — nó bỏ vào Sticker Printer (re-roll flow).
    AutoHatchInventoryEggs = true,
    HatchPriority = {"Diamond", "Mythic", "Gold", "Silver", "Petal", "Basic"},
    -- 2) MUA Silver Egg bằng ticket khi đủ (mua từ xa, hatch tự theo).
    AutoBuySilverEgg = true,
    SilverEggMaxTickets = 500,        -- không mua nếu giá vượt mức này
    KeepTickets = 0,                  -- giữ lại N ticket cho việc khác
    -- 3) FEED treat cho Mother Bear task (từ xa, batch).
    AutoFeedTreats = true,
    TreatBatchMax = 50,
    FeedInterval = 10,
    -- 3b) MOTHER BEAR FOCUS FEED: luôn feed ĐÚNG food quest yêu cầu, đọc
    -- quest module của game; thiếu cũng feed đến hết stock rồi ngưng chờ,
    -- sau mỗi lượt quét lại quest, thiếu bao nhiêu loop tiếp đến khi xong.
    MotherBearFocusFeed = true,
    MBFeedBatchMax = 50,
    -- 3c) STAR JELLY từ reward → dùng vào Basic Bee trong hive ngay
    -- (dùng xong tự chuyển sang Basic khác vì cell cũ đã gifted).
    AutoUseStarJelly = true,
    -- 4) STAR EGG RE-ROLL: sticker mong muốn khi mở Star Egg.
    DesiredStarStickers = {"Star Sign", "Star Cub"},
    RejoinFn = nil,                   -- slot cắm tool rejoin (user gửi sau)
    RejoinFallbackTeleport = true,    -- chưa cắm tool -> TeleportService cùng place
    -- 5) CHANGE ACC (Yummytool bridge): script check đồ -> đủ yêu cầu ->
    --    gửi request tới tool -> tool change acc.
    ChangeAcc = {
        Enabled = true,
        Triggers = {StarEggJackpot = true, StarEggWrong = false},
        Mode = "Workspace",           -- "Workspace" (writefile) | "API" (GET)
        FileName = "playername.txt",  -- Workspace mode: ĐÚNG tên tool yêu cầu
        ApiURL = "",                  -- API mode: endpoint main-session-group
        ApiKey = "",                  -- X-API-KEY
        AccountQueue = {},            -- (tuỳ chọn) nếu WriteValue="next"
        WriteValue = "current",       -- CONFIRMED: ghi tên acc HIỆN TẠI
                                      -- (báo tool acc này xong việc)
        StopAfterChange = true,       -- dừng supporter sau khi gửi request
    },
    -- 6) TELE REWARDS đầu game: quét các reward point trên map (mỗi account
    --    một lần, ledger lưu file) — Diamond Egg, Star Jelly, Enzymes, Tickets...
    TeleRewards = {
        Enabled = true,
        Dwell = 0.4,                  -- giây đứng trên mỗi điểm (touch pickup)
        NudgeHeight = 1,              -- nhích lên/xuống kích hoạt touch
    },
    -- Cadences (giây) — cadence thấp vì chạy song song atlas.
    HatchInterval = 6,
    BuyInterval = 12,
    ScanInterval = 4,
}

do
    local overrides = ENV.TFFA_SUPPORTER_CONFIG
    if type(overrides) == "table" then
        for key, value in pairs(overrides) do Config[key] = value end
    end
end

local State = {
    Running = true,
    Hatched = 0,
    Bought = 0,
    Fed = 0,
    RejoinCalls = 0,
    ChangeAccRequests = 0,
}

local function status(text)
    print("[TFFA Sup] " .. text)
end

-- =============================================================================
-- Base helpers (standalone)
-- =============================================================================
local Events = ReplicatedStorage:FindFirstChild("Events")

local function remoteCall(name, ...)
    local remote = Events and Events:FindFirstChild(name)
    if not remote then return false, "missing remote" end
    if remote:IsA("RemoteFunction") then
        local arguments = table.pack(...)
        local packed, completed
        task.spawn(function()
            packed = table.pack(pcall(remote.InvokeServer, remote, table.unpack(arguments, 1, arguments.n)))
            completed = true
        end)
        local deadline = os.clock() + 8
        while not completed and os.clock() < deadline do task.wait(0.05) end
        if not completed then return false, "timeout" end
        if not packed[1] then return false, packed[2] end
        return true, table.unpack(packed, 2, packed.n)
    end
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        return pcall(remote.FireServer, remote, ...)
    end
    return false, "bad class"
end

-- ClientStatCache stats (Get + single-flight Update)
local statCache
local function getStats(force)
    if not statCache then
        local module = ReplicatedStorage:FindFirstChild("ClientStatCache")
        if not module then return nil end
        local ok, result = pcall(require, module)
        if not ok or type(result) ~= "table" then return nil end
        statCache = result
    end
    if force and type(statCache.Update) == "function" then
        pcall(statCache.Update, statCache)
    end
    local ok, stats = pcall(statCache.Get, statCache)
    if ok and type(stats) == "table" then return stats end
    return nil
end

local function getCharacter(timeout)
    local deadline = os.clock() + (timeout or 2)
    while os.clock() < deadline do
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and root and humanoid.Health > 0 then
            return humanoid, root
        end
        task.wait(0.1)
    end
    return nil, nil
end

-- =============================================================================
-- Hive helpers: ô trống + ô ong thường (feed target)
-- =============================================================================
local function getHiveCells()
    local reference = Player:FindFirstChild("Honeycomb")
    local hive = reference and reference:IsA("ObjectValue") and reference.Value
    local cells = hive and hive:FindFirstChild("Cells")
    return cells and cells:GetChildren() or {}
end

local function beeTypePresent(value)
    local normalized = string.lower(tostring(value))
    return normalized ~= "" and normalized ~= "none"
        and normalized ~= "empty" and normalized ~= "nil"
end

local function cellCoordinates(cell)
    return cell.Name:match("^C(%d+),(%d+)$")
end

-- Ô TRỐNG (chưa có ong): hatch target.
local function findEmptyCell()
    for _, cell in ipairs(getHiveCells()) do
        local x, y = cellCoordinates(cell)
        if x and y then
            local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
            local value = cellType and cellType:IsA("ValueBase") and tostring(cellType.Value) or ""
            if not beeTypePresent(value) then
                return tonumber(x), tonumber(y)
            end
        end
    end
    return nil
end

-- Ô ong thường (chưa gifted): feed treat target.
local function findFeedCell()
    for _, cell in ipairs(getHiveCells()) do
        local x, y = cellCoordinates(cell)
        if x and y then
            local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
            local value = cellType and cellType:IsA("ValueBase") and tostring(cellType.Value) or ""
            local locked = cell:FindFirstChild("CellLocked")
            local lockedValue = locked and locked:IsA("ValueBase") and locked.Value == true
            if beeTypePresent(value) and not cell:FindFirstChild("GiftedCell") and not lockedValue then
                return tonumber(x), tonumber(y)
            end
        end
    end
    return nil
end

-- =============================================================================
-- EGG INVENTORY: stats.Eggs có key trùng egg type (tên có thể "Silver"/
-- "SilverEgg" — normalize strip-space + strip "egg" suffix khi khớp).
-- =============================================================================
local HATCHABLE_EGGS = {
    Diamond = true, Mythic = true, Gold = true,
    Silver = true, Petal = true, Basic = true,
    -- "Star" KHÔNG hatch: Star Egg đi Sticker Printer (re-roll flow).
}

local function normalizeEggKey(key)
    local n = string.lower(tostring(key)):gsub("[^%w]", "")
    return n:gsub("egg$", "")
end

local eggKeysSeen = false
local function findInventoryEggs(stats)
    local found = {} -- [canonicalName] = count
    local eggs = type(stats) == "table" and stats.Eggs or nil
    if type(eggs) ~= "table" then return found, false end
    for key, count in pairs(eggs) do
        local normalized = normalizeEggKey(key)
        local amount = tonumber(count) or 0
        if amount > 0 and HATCHABLE_EGGS[normalized] then
            found[normalized] = amount
        end
    end
    return found, true
end

-- =============================================================================
-- STICKER READER (atlas 44198): stats.Stickers{Book, Inbox, Stack} —
-- categories tùy chọn (mặc định cả Book+Inbox). Mỗi entry có GetTypeDef()
-- -> {ID, Name}. Trả về {name = category} + flag đọc được.
-- =============================================================================
local function readStickerBook(stats, categories)
    local names, readable = {}, false
    local stickers = type(stats) == "table" and stats.Stickers or nil
    if type(stickers) ~= "table" then
        return names, false
    end
    for _, category in ipairs(categories or {"Book", "Inbox"}) do
        local list = stickers[category]
        if type(list) == "table" then
            for _, sticker in ipairs(list) do
                local name
                if type(sticker) == "table" and type(sticker.GetTypeDef) == "function" then
                    local ok, def = pcall(sticker.GetTypeDef, sticker)
                    if ok and type(def) == "table" then
                        name = tostring(def.Name or def.ID or "?")
                    elseif ok and def ~= nil then
                        name = tostring(def)
                    end
                elseif type(sticker) == "table" then
                    name = tostring(sticker.Name or sticker.Type or sticker.ID or "?")
                elseif type(sticker) == "string" then
                    name = sticker
                end
                if name then
                    names[name] = category
                    readable = true
                end
            end
        end
    end
    return names, readable
end

local function containsDesiredSticker(names)
    for name in pairs(names) do
        for _, desired in ipairs(Config.DesiredStarStickers or {}) do
            if string.find(name, desired, 1, true) then return true, name end
        end
    end
    return false, nil
end

-- DUMP FULL STICKER BOOK ra console (sorted) — CHỈ ĐỌC ĐỂ CHECK (re-roll
-- decision), KHÔNG liên quan Sticker Printer (việc in sticker vào printer
-- là của atlas). Book không đọc được -> dump shape để biết key thật.
local function dumpStickerBook(tag)
    local stats = getStats(true)
    local names, readable = readStickerBook(stats)
    if not readable then
        warn("[TFFA Sup] [" .. tag .. "] Sticker Book KHÔNG đọc được — dump shape:")
        local stickers = type(stats) == "table" and stats.Stickers or nil
        if type(stickers) ~= "table" then
            warn("[TFFA Sup]   stats.Stickers không tồn tại (typeof=" .. typeof(stats) .. ")")
        else
            for key, value in pairs(stickers) do
                local shape = typeof(value)
                local count = type(value) == "table" and (" (" .. #value .. " entries)") or ""
                warn("[TFFA Sup]   Stickers." .. tostring(key) .. " = " .. shape .. count)
            end
        end
        return
    end
    local sorted = {}
    for name, category in pairs(names) do
        table.insert(sorted, name .. " [" .. category .. "]")
    end
    table.sort(sorted)
    warn("[TFFA Sup] [" .. tag .. "] STICKERS (Book+Inbox): " .. #sorted)
    for index, name in ipairs(sorted) do
        warn("[TFFA Sup]   " .. index .. ". " .. name)
    end
end

-- STAR EGG RE-ROLL WATCHER (đúng flow user): Star Egg KHÔNG hatch — nó
-- được bỏ vào STICKER PRINTER (do user/atlas đặt), printer in ra sticker
-- rồi sticker mới rơi vào INBOX. Supporter chỉ QUAN SÁT:
--   * ARM: khi alert "star egg" xuất hiện (egg vào printer / đang xử lý)
--     hoặc gọi tay __TFFA_SUP.ArmStarEgg() → chụp baseline INBOX.
--   * POLL: sticker mới xuất hiện trong Inbox (so baseline) → check
--     DesiredStarStickers: có = JACKPOT ở lại; sai = REJOIN ngay.
-- Không có sticker mới → chỉ log, KHÔNG rejoin mù (sai sự thật).
local starEggWatch = {Armed = false, Baseline = nil, ArmedAt = 0}

local function armStarEgg(reason)
    local stats = getStats(true)
    local inbox, readable = readStickerBook(stats, {"Inbox"})
    if not readable then
        status("ARM Star Egg THẤT BẠI - Sticker Inbox chưa đọc được (đợi tick sau)")
        return false
    end
    starEggWatch.Armed = true
    starEggWatch.Baseline = inbox
    starEggWatch.ArmedAt = os.clock()
    status("ARMED Star Egg re-roll (" .. reason .. ") | inbox baseline "
        .. (function() local n = 0 for _ in pairs(inbox) do n += 1 end return n end)()
        .. " sticker")
    return true
end

local function starEggReRollCheck()
    task.spawn(function()
        local fresh = getStats(true)
        local nowInbox, readable = readStickerBook(fresh, {"Inbox"})
        if not readable then
            status("Inbox chưa đọc được - không quyết định được, giữ ARMED")
            return
        end
        local newNames = {}
        for name, category in pairs(nowInbox) do
            if not starEggWatch.Baseline[name] then
                table.insert(newNames, name .. " [" .. category .. "]")
            end
        end
        if #newNames == 0 then
            status("Chưa thấy sticker mới từ Star Egg - chờ thêm")
            return
        end
        table.sort(newNames)
        dumpStickerBook("sau print star egg")
        local hasDesired, hitName = containsDesiredSticker(nowInbox)
        starEggWatch.Armed = false
        if hasDesired then
            status("JACKPOT! Sticker mong muốn: " .. tostring(hitName)
                .. " | sticker mới: " .. table.concat(newNames, ", "))
            -- ĐỦ YÊU CẦU -> change acc (Yummytool) nếu trigger bật.
            if Config.ChangeAcc and Config.ChangeAcc.Triggers.StarEggJackpot then
                requestChangeAcc("star egg jackpot - acc đủ yêu cầu")
            end
            return
        end
        status("RE-ROLL TRẬT: " .. table.concat(newNames, ", ")
            .. " không phải " .. table.concat(Config.DesiredStarStickers or {}, "/")
            .. " -> REJOIN")
        State.RejoinCalls += 1
        local rejoinFn = Config.RejoinFn or ENV.TFFA_REJOIN
        if type(rejoinFn) == "function" then
            pcall(rejoinFn, table.concat(newNames, ", "))
        elseif Config.RejoinFallbackTeleport then
            status("RejoinFn chưa cắm - fallback TeleportService cùng place")
            pcall(function()
                TeleportService:Teleport(game.PlaceId, Player)
            end)
        else
            status("REJOIN chưa cấu hình (Config.RejoinFn) - không thể rejoin")
        end
        -- Sticker sai -> change acc nếu trigger bật (mặc định tắt).
        if Config.ChangeAcc and Config.ChangeAcc.Triggers.StarEggWrong then
            requestChangeAcc("star egg sticker sai")
        end
    end)
end

-- =============================================================================
-- 5) CHANGE ACC (Yummytool bridge): script check đồ -> đủ yêu cầu -> gửi
--    request tới tool -> tool change acc. 2 mode theo doc tool:
--    * Workspace: writefile(FileName, <ĐÚNG 1 giá trị, KHÔNG text thừa>) —
--      tool đọc file playername.txt trong workspace và xử lý.
--    * API: GET <ApiURL> header X-API-KEY -> response chứa main + clone
--      accounts (log để đối chiếu); giá trị ghi vẫn theo WriteValue.
-- =============================================================================
local changeAccState = {QueueIndex = 1}

local function requestChangeAcc(reason)
    local ca = Config.ChangeAcc
    if not ca or not ca.Enabled then
        status("ChangeAcc disabled - bỏ qua (" .. reason .. ")")
        return false
    end
    -- Xác định GIÁ TRỊ ghi vào playername.txt (đúng 1 giá trị).
    local value
    if ca.WriteValue == "next" then
        local queue = ca.AccountQueue or {}
        if #queue == 0 then
            status("ChangeAcc: AccountQueue rỗng - không biết đổi sang acc nào")
            return false
        end
        value = tostring(queue[changeAccState.QueueIndex])
        changeAccState.QueueIndex = (changeAccState.QueueIndex % #queue) + 1
    elseif ca.WriteValue == "current" then
        value = Player.Name
    else
        value = tostring(ca.WriteValue)
    end
    -- API mode: fetch main-session-group (main + clone accounts) — log để
    -- đối chiếu; lỗi HTTP không chặn việc ghi playername.txt.
    if ca.Mode == "API" and ca.ApiURL ~= "" then
        local http = rawget(ENV, "request") or rawget(ENV, "http_request")
            or (type(syn) == "table" and syn.request) or nil
        if type(http) == "function" then
            local okHttp, resp = pcall(http, {
                Url = ca.ApiURL,
                Method = "GET",
                Headers = {["X-API-KEY"] = tostring(ca.ApiKey)},
            })
            if okHttp and resp and resp.Body then
                local body = tostring(resp.Body)
                status("ChangeAcc API response: " .. body:sub(1, 300))
                local okJson, decoded = pcall(HttpService.JSONDecode, HttpService, body)
                if okJson and type(decoded) == "table" then
                    status("ChangeAcc API decoded: " .. #decoded .. " account(s) trong session group")
                end
            else
                status("ChangeAcc API call FAIL: " .. tostring(resp))
            end
        else
            status("ChangeAcc API mode nhưng executor không có http request")
        end
    end
    -- WORKSPACE MODE: ghi playername.txt — CHÍNH XÁC 1 giá trị, không text
    -- thừa (doc tool: no logs, JSON, comments). Đường dẫn relative = workspace
    -- của executor mà Yummytool theo dõi.
    local writefileFn = rawget(ENV, "writefile") or (type(writefile) == "function" and writefile)
    if type(writefileFn) ~= "function" then
        status("ChangeAcc: executor không có writefile - không gửi request được")
        return false
    end
    local okWrite = pcall(writefileFn, ca.FileName, value)
    State.ChangeAccRequests += 1
    status(string.format("CHANGE ACC request #%d: %s -> %s = '%s'%s",
        State.ChangeAccRequests, reason, ca.FileName, value,
        okWrite and "" or " (WRITE FAIL!)"))
    if ca.StopAfterChange then
        status("Dừng supporter sau 3s để Yummytool change acc...")
        task.delay(3, function() State.Running = false end)
    end
    return okWrite
end

-- Poll worker: ARMED → check Inbox định kỳ (2s), timeout 8 phút (printer
-- xong muộn hơn thì coi như mất, hỏi user lấy cơ chế khác).
task.spawn(function()
    while State.Running do
        if starEggWatch.Armed then
            if os.clock() - starEggWatch.ArmedAt > 480 then
                starEggWatch.Armed = false
                status("Star Egg watch TIMEOUT 8 phút - disarm (printer xong muộn hơn dự kiến?)")
            else
                starEggReRollCheck()
            end
        end
        task.wait(2)
    end
end)

-- =============================================================================
-- 1) HATCH WORKER
-- =============================================================================
local function hatchStep()
    if #getHiveCells() == 0 then return false end
    local stats = getStats(true)
    if not stats then return false end
    local eggs = findInventoryEggs(stats)
    -- Thứ tự ưu tiên theo Config.HatchPriority.
    for _, wanted in ipairs(Config.HatchPriority) do
        local amount = eggs[wanted]
        if amount and amount > 0 then
            local x, y = findEmptyCell()
            if not x then
                status("Hive full - khong con o trong de hatch")
                return false
            end
            status(string.format("Hatch %s (%d con) vao o (%d,%d)", wanted, amount, x, y))
            local ok = remoteCall("ConstructHiveCellFromEgg", x, y, wanted, 1)
            if ok then
                State.Hatched += 1
                task.wait(1)
                return true
            end
            task.wait(1)
            return false
        end
    end
    return false
end

-- =============================================================================
-- 2) SILVER EGG BUY (ticket) — mua TU XA, hatch do worker 1 dam nhiem.
-- =============================================================================
local function ticketCount(stats)
    stats = stats or getStats(false)
    local eggs = type(stats) == "table" and stats.Eggs or nil
    return math.max(0, math.floor(tonumber(eggs and (eggs.Ticket or eggs.Tickets)) or 0))
end

-- =============================================================================
-- BUY EGG (TÁCH RIÊNG): mua bat ky loai egg tu xa — goi doc lap bat ky luc:
--   getgenv().__TFFA_SUP.BuyEgg("Silver")   -- / "Gold" / "Star" / "Basic"...
-- Tra ve: ok (bool), detail (string). Flow: tim shop package -> gate ticket
-- -> fire Purchase -> CONFIRM bang inventory delta that.
-- =============================================================================
local function discoverEggPackage(eggName)
    local wanted = normalizeEggKey(eggName) -- "Silver"/"Silver Egg" -> "silver"
    local shops = workspace:FindFirstChild("Shops")
    if shops then
        for _, shop in ipairs(shops:GetDescendants()) do
            if shop:IsA("BasePart") or shop:IsA("Model") then
                -- normalizeEggKey da strip "egg": "Silver Egg" -> "silver".
                if normalizeEggKey(shop.Name) == wanted then
                    local itemType = shop:FindFirstChild("ItemType")
                    local itemCategory = shop:FindFirstChild("ItemCategory")
                    if itemType and itemCategory and itemType:IsA("ValueBase") and itemCategory:IsA("ValueBase") then
                        return {Category = tostring(itemCategory.Value), Type = tostring(itemType.Value)}
                    end
                end
            end
        end
    end
    return {Category = "Eggs", Type = eggName}
end

local function getEggCount(stats, eggName)
    local eggs = type(stats) == "table" and stats.Eggs or nil
    if type(eggs) ~= "table" then return 0 end
    local wanted = normalizeEggKey(eggName)
    for key, count in pairs(eggs) do
        if tonumber(count) and normalizeEggKey(key) == wanted then
            return tonumber(count)
        end
    end
    return 0
end

local function buyEggRemote(eggName)
    local package = discoverEggPackage(eggName)
    local stats = getStats(true)
    local tickets = ticketCount(stats)
    if tickets < 1 then
        return false, "khong co ticket"
    end
    -- Cost: doc tu ItemPackages neu duoc — co gia thi gate chat, khong co
    -- thi de server tu choi (khong mua mu mui vi khong biet gia).
    local cost = nil
    local okPackages, ItemPackages = pcall(function()
        return require(ReplicatedStorage:FindFirstChild("ItemPackages"))
    end)
    if okPackages and type(ItemPackages) == "table" and type(ItemPackages.GetCost) == "function" then
        pcall(function()
            local okCost, value = ItemPackages.GetCost(package, stats)
            if okCost and tonumber(value) then cost = tonumber(value) end
        end)
    end
    if cost then
        if tickets < cost then
            return false, "khong du ticket (can " .. cost .. ", co " .. tickets .. ")"
        end
        if tickets - cost < Config.KeepTickets then
            return false, "mua se pha KeepTickets=" .. tostring(Config.KeepTickets)
        end
    end
    local beforeCount = getEggCount(stats, eggName)
    status(string.format("Mua %s tu xa | tickets %d%s", eggName, tickets,
        cost and (" | gia " .. cost) or ""))
    local ok, result = remoteCall("ItemPackageEvent", "Purchase",
        {Category = package.Category, Type = package.Type, Amount = 1})
    task.wait(0.8)
    local fresh = getStats(true)
    local afterCount = getEggCount(fresh, eggName)
    local confirmed = (ok and result == true) or afterCount > beforeCount
    if confirmed then
        status(string.format("Mua %s OK (inventory %d -> %d)", eggName, beforeCount, afterCount))
        return true
    end
    return false, tostring(result or "khong xac nhan")
end

local silverBuyState = {LastTry = 0, LastConfirm = 0}
local function buySilverEggStep()
    local now = os.clock()
    if now - silverBuyState.LastTry < Config.BuyInterval then return false end
    local stats = getStats(true)
    -- Da confirm mua gan day: cho hatch worker an truoc khi mua tiep.
    if now - silverBuyState.LastConfirm < Config.HatchInterval + 3 then return false end
    if getEggCount(stats, "Silver") > 0 then return false end -- con Silver chua hatch

    silverBuyState.LastTry = now
    local ok, detail = buyEggRemote("Silver")
    if ok then
        silverBuyState.LastConfirm = os.clock()
        State.Bought += 1
        status("Silver Egg da mua (" .. State.Bought .. " tong) - hatch tiep theo")
        return true
    end
    if type(detail) == "string" and not detail:find("khong du ticket", 1, true) then
        status("Mua Silver Egg chua xac nhan: " .. detail)
    end
    return false
end

-- =============================================================================
-- 3) TREAT FEED (Mother Bear task) — feed TU XA batch vao o ong thuong.
-- =============================================================================
local function treatStock(stats)
    stats = stats or getStats(false)
    local treats = type(stats) == "table" and stats.Treats or nil
    if type(treats) == "table" and tonumber(treats.Treat) then
        return math.floor(treats.Treat)
    end
    -- Fallback: quet sau nhung skip subtree tong ket (Totals/Used/...).
    local found
    local visited = {}
    local function scan(value, depth)
        if found or type(value) ~= "table" or visited[value] or depth > 4 then return end
        visited[value] = true
        for k, child in pairs(value) do
            if k == "Treat" and tonumber(child) then found = tonumber(child) return end
            local lowered = string.lower(tostring(k))
            if type(child) == "table"
                and not (lowered:find("total", 1, true) or lowered:find("used", 1, true)
                    or lowered:find("spent", 1, true) or lowered:find("history", 1, true)) then
                scan(child, depth + 1)
            end
        end
    end
    scan(stats, 0)
    return math.floor(found or 0)
end

local feedState = {LastFeed = 0}
local function feedTreatsStep()
    local now = os.clock()
    if now - feedState.LastFeed < Config.FeedInterval then return false end
    feedState.LastFeed = now
    local stats = getStats(false)
    local treats = treatStock(stats)
    if treats <= 0 then return false end
    local x, y = findFeedCell()
    if not x then
        status("Khong co o ong thuong de feed (tat ca gifted/locked?)")
        return false
    end
    local batch = math.min(treats, math.max(1, math.floor(tonumber(Config.TreatBatchMax) or 50)))
    status(string.format("Feed %d Treats vao o (%d,%d) | stock %d", batch, x, y, treats))
    local ok = remoteCall("ConstructHiveCellFromEgg", x, y, "Treat", batch)
    if ok then
        State.Fed += batch
        task.wait(0.5)
        return true
    end
    return false
end

-- =============================================================================
-- 3b) MOTHER BEAR FOCUS FEED: luôn luôn feed ĐÚNG food quest yêu cầu
-- (đọc quest module của game). Thiếu cũng feed đến hết stock rồi ngưng chờ;
-- sau mỗi lượt quét lại quest 1 cái, thiếu bao nhiêu loop tiếp đến khi xong.
-- =============================================================================
local MB_FOOD_KEYS = {
    {Pattern = "sunflowerseed", Key = "SunflowerSeed", Label = "Sunflower Seeds"},
    {Pattern = "strawberry", Key = "Strawberry", Label = "Strawberries"},
    {Pattern = "blueberry", Key = "Blueberry", Label = "Blueberries"},
    {Pattern = "pineapple", Key = "Pineapple", Label = "Pineapples"},
    {Pattern = "treat", Key = "Treat", Label = "Treats"},
}

local questModule
local function getQuestModule()
    if questModule ~= nil then return questModule end
    local module = ReplicatedStorage:FindFirstChild("Quests")
    if not module then
        questModule = false
        return nil
    end
    local ok, result = pcall(require, module)
    questModule = (ok and type(result) == "table") and result or false
    return questModule
end

-- Stock tổng quát cho 1 food key: Treats trực tiếp → Eggs → deep scan
-- (skip subtree Totals/Used/Spent/History — lá ở đó là LƯỢT TIÊU không
-- phải stock).
local function foodStock(stats, key)
    stats = stats or getStats(false)
    local treats = type(stats) == "table" and stats.Treats or nil
    if type(treats) == "table" and tonumber(treats[key]) then
        return math.floor(treats[key])
    end
    local eggs = type(stats) == "table" and stats.Eggs or nil
    if type(eggs) == "table" and tonumber(eggs[key]) then
        return math.floor(eggs[key])
    end
    local found
    local visited = {}
    local function scan(value, depth)
        if found or type(value) ~= "table" or visited[value] or depth > 4 then return end
        visited[value] = true
        for k, child in pairs(value) do
            if k == key and tonumber(child) then found = tonumber(child) return end
            local lowered = string.lower(tostring(k))
            if type(child) == "table"
                and not (lowered:find("total", 1, true) or lowered:find("used", 1, true)
                    or lowered:find("spent", 1, true) or lowered:find("history", 1, true)) then
                scan(child, depth + 1)
            end
        end
    end
    scan(stats, 0)
    return math.floor(found or 0)
end

-- Tìm task FEED FOOD đang làm dở của Mother Bear: trả về
-- {Food, Label, Remaining (nil = không parse được), Quest}.
local function findMotherBearFeedTask(stats)
    local qm = getQuestModule()
    if not qm or type(qm.Get) ~= "function" or type(qm.Progress) ~= "function" then
        return nil
    end
    local active = stats and stats.Quests and stats.Quests.Active
    if type(active) ~= "table" then return nil end
    for _, entry in pairs(active) do
        local questName = type(entry) == "table" and entry.Name or entry
        if type(questName) == "string" and questName ~= "" then
            local ok, info = pcall(qm.Get, qm, questName)
            if ok and type(info) == "table" and info.NPC == "Mother Bear" then
                local okP, progress = pcall(qm.Progress, qm, questName, stats)
                progress = type(progress) == "table" and progress or {}
                local tasks = info.Tasks or {}
                for index, taskData in ipairs(tasks) do
                    local text = string.lower(tostring(taskData.Type or "") .. " "
                        .. tostring(taskData.Description or ""))
                    if not text:find("collect", 1, true) then
                        for _, food in ipairs(MB_FOOD_KEYS) do
                            local isFeed = text:find("feed", 1, true) or text:find("use", 1, true)
                            if isFeed and text:find(food.Pattern, 1, true) then
                                -- Remaining: goal từ text (chống "1,000"),
                                -- progress pair {a,b} hoặc {fraction}.
                                local goalText = string.match(text, "feed%s+([%d%,%.]+)")
                                local goal = goalText
                                    and tonumber((goalText:gsub("[%,%.]", ""))) or nil
                                local p = progress[index] or {}
                                local a = tonumber(p[1]) or 0
                                local b = tonumber(p[2])
                                local remaining
                                if b then
                                    remaining = math.max(1, math.max(a, b) - math.min(a, b))
                                elseif goal then
                                    remaining = math.max(1, goal - math.floor(math.min(a, goal)))
                                else
                                    remaining = nil
                                end
                                return {
                                    Food = food.Key, Label = food.Label,
                                    Remaining = remaining, Quest = questName,
                                    TaskIndex = index,
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local mbFeedState = {LastFeed = 0}
local function motherBearFeedStep()
    if not Config.MotherBearFocusFeed then return false end
    local now = os.clock()
    if now - mbFeedState.LastFeed < Config.FeedInterval then return false end
    mbFeedState.LastFeed = now
    local stats = getStats(false)
    local taskInfo = findMotherBearFeedTask(stats)
    if not taskInfo then return false end

    -- LOOP: feed → quét lại quest → thiếu bao nhiêu feed tiếp, đến khi task
    -- xong hoặc hết stock thì ngưng ("không đủ cũng feed đến khi đủ").
    local passes = 0
    while State.Running and passes < 6 do
        passes += 1
        stats = getStats(true)
        local fresh = findMotherBearFeedTask(stats)
        if not fresh or (fresh.Remaining and fresh.Remaining <= 0) then
            status("MB focus feed: task ĐÃ ĐỦ - ngưng")
            return true
        end
        taskInfo = fresh
        local stock = foodStock(stats, taskInfo.Food)
        if stock <= 0 then
            status(string.format("MB focus feed: THIẾU %s (còn thiếu %s) - ngưng chờ thêm đồ",
                taskInfo.Label, tostring(taskInfo.Remaining)))
            return false
        end
        local x, y = findFeedCell()
        if not x then
            status("MB focus feed: không có ô ong thường để feed")
            return false
        end
        local batch = math.min(stock, taskInfo.Remaining or Config.MBFeedBatchMax,
            math.max(1, tonumber(Config.MBFeedBatchMax) or 50))
        status(string.format("MB FOCUS feed %d %s vào (%d,%d) | còn thiếu %s",
            batch, taskInfo.Label, x, y, tostring(taskInfo.Remaining)))
        local ok = remoteCall("ConstructHiveCellFromEgg", x, y, taskInfo.Food, batch)
        if not ok then
            task.wait(1)
            return false
        end
        State.Fed += batch
        task.wait(0.8)
    end
    return true
end

-- =============================================================================
-- 3c) STAR JELLY → BASIC BEE (rotate): reward từ Mother Bear — có trong
-- inventory là DÙNG NGAY vào 1 Basic bee thường; cell dùng xong sẽ gifted
-- nên lần sau TỰ CHUYỂN sang Basic khác (lưu buff gifted rải đều hive).
-- =============================================================================
local starJellyState = {LastCellKey = nil}

local function starJellyStock(stats)
    stats = stats or getStats(false)
    local eggs = type(stats) == "table" and stats.Eggs or nil
    if type(eggs) == "table" and tonumber(eggs.StarJelly) then
        return math.floor(eggs.StarJelly)
    end
    local found
    local visited = {}
    local function scan(value, depth)
        if found or type(value) ~= "table" or visited[value] or depth > 4 then return end
        visited[value] = true
        for k, child in pairs(value) do
            if k == "StarJelly" and tonumber(child) then found = tonumber(child) return end
            local lowered = string.lower(tostring(k))
            if type(child) == "table"
                and not (lowered:find("total", 1, true) or lowered:find("used", 1, true)
                    or lowered:find("spent", 1, true) or lowered:find("history", 1, true)) then
                scan(child, depth + 1)
            end
        end
    end
    scan(stats, 0)
    return math.floor(found or 0)
end

local function useStarJellyStep()
    if not Config.AutoUseStarJelly then return false end
    local stats = getStats(false)
    local stock = starJellyStock(stats)
    if stock <= 0 then return false end
    -- Tìm BASIC bee thường (non-gifted, unlocked), KHÔNG trùng cell lần
    -- trước (rotate để buff gifted rải đều từng con).
    for _, cell in ipairs(getHiveCells()) do
        local x, y = cellCoordinates(cell)
        if x and y then
            local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
            local value = cellType and cellType:IsA("ValueBase") and tostring(cellType.Value) or ""
            local locked = cell:FindFirstChild("CellLocked")
            local lockedValue = locked and locked:IsA("ValueBase") and locked.Value == true
            if string.lower(value):gsub("[^%w]", "") == "basic"
                and not cell:FindFirstChild("GiftedCell") and not lockedValue then
                local key = x .. "," .. y
                if key ~= starJellyState.LastCellKey then
                    status(string.format("Star Jelly → Basic bee (%d,%d) | stock %d", x, y, stock))
                    local ok = remoteCall("ConstructHiveCellFromEgg", x, y, "StarJelly", 1)
                    if ok then
                        starJellyState.LastCellKey = key
                        task.wait(0.8)
                        return true
                    end
                    return false
                end
            end
        end
    end
    return false -- không còn Basic thường để dùng
end

-- =============================================================================
-- 4) STAR EGG RE-ROLL WATCH: Alert popup tu PlayerGui.ScreenGui.Alerts —
-- atlas 5947 cung doc dung cho nay. Star Egg mo ra → text chua ten sticker:
-- neu KHONG co bat ky DesiredStarStickers nao -> REJOIN ngay.
-- =============================================================================
local alertWatchState = {Attached = false, Conns = {}}

local function detachAlerts()
    for _, conn in ipairs(alertWatchState.Conns) do pcall(conn.Disconnect, conn) end
    alertWatchState.Conns = {}
    alertWatchState.Attached = false
end

local function onAlert(child)
    task.wait(0.3) -- cho text populate
    local text = tostring(child.Text or "")
    if text == "" then return end
    local lowered = string.lower(text)
    -- Chi quan tam alert lien quan Star Egg.
    if not lowered:find("star egg", 1, true) then return end
    -- EGG VÀO PRINTER (alert đặt egg / tiến trình) → ARM inbox watcher.
    if lowered:find("print", 1, true) then
        pcall(armStarEgg, "alert: " .. text)
        return
    end
    -- Alert có sticker mong muốn trực tiếp → JACKPOT.
    for _, desired in ipairs(Config.DesiredStarStickers or {}) do
        if string.find(text, desired, 1, true) then
            status("JACKPOT! Star Egg ra sticker mong muốn: " .. text)
            starEggWatch.Armed = false
            return
        end
    end
    -- Alert kết quả nhắc "sticker" mà thiếu desired → để POLL Inbox quyết
    -- định (delta thật), KHÔNG rejoin từ text mù.
    status("Star Egg alert: " .. text .. " | đợi Inbox diff để quyết định")
end

local function attachAlerts()
    if alertWatchState.Attached then return end
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
    local alerts = screenGui and screenGui:FindFirstChild("Alerts")
    if not alerts then return end
    alertWatchState.Attached = true
    table.insert(alertWatchState.Conns, alerts.ChildAdded:Connect(onAlert))
    status("Alert watch attached (Star Egg re-roll armed)")
end

task.spawn(function()
    while State.Running do
        attachAlerts()
        task.wait(2)
    end
end)

-- =============================================================================
-- 6) TELE REWARDS đầu game (từ telebss rewards): 40 reward point trên map —
-- Diamond Egg, Star Jelly, Gold Egg, Enzymes, Tickets, Jelly, Glue, Gumdrops...
-- Mỗi account quét MỘT LẦN: pin CFrame từng điểm (touch pickup), dwell nhẹ,
-- ledger per-spot lưu file ngay sau mỗi điểm (crash-safe — chết giữa chừng
-- chỉ mất đúng điểm đang bay).
-- =============================================================================
local TELE_REWARD_SPOTS = {
    {CFrame.new(42, 149, -531), "Diamond Egg"},
    {CFrame.new(-413.77, 17.17, 467.18), "Star Jelly"},
    {CFrame.new(83.94, 68.01, -142.12), "Gold Egg"},
    {CFrame.new(-435.52, 93.26, 48.78), "Star Jelly"},
    {CFrame.new(-480.57, 69.39, -0.42), "Star Jelly"},
    {CFrame.new(5.215, 174.664, -96.96), "Ticket"},
    {CFrame.new(-105.185, 71.711, 557.967), "Enzymes"},
    {CFrame.new(-115.21, 71.747, 558.186), "Enzymes"},
    {CFrame.new(-124.223, 71.747, 558.221), "Enzymes"},
    {CFrame.new(87.597, 310.219, -294.334), "Jelly"},
    {CFrame.new(524.506, 151.902, -411.876), "Star Jelly"},
    {CFrame.new(369.314, 84.816, -237.077), "Glue"},
    {CFrame.new(110.861, 63.718, -59.578), "Jelly"},
    {CFrame.new(218.618, 35.427, -29.126), "Jelly"},
    {CFrame.new(263.946, 57.138, 108.369), "Jelly"},
    {CFrame.new(314.312, 61.638, 213.964), "Jelly"},
    {CFrame.new(34.864, 57.965, 190.511), "Jelly"},
    {CFrame.new(-64.232, 37.717, 113.388), "Jelly"},
    {CFrame.new(146.351, 37.496, 266.086), "Jelly"},
    {CFrame.new(47.836, 52.594, 398.93), "Gummy"},
    {CFrame.new(226.929, 25252.527, -716.011), "Enzymes"},
    {CFrame.new(301.8563537597656, 25283.02734375, -807.7046508789062), "Glitter"},
    {CFrame.new(271.973, 25294.129, -871.085), "Star Jelly"},
    {CFrame.new(-189.317, 64.263, 367.295), "Jelly"},
    {CFrame.new(3.3575220108032227, 304.2304992675781, -266.304931640625), "Enzymes"},
    {CFrame.new(329.359, 193.14, -234.35), "Bloom"},
    {CFrame.new(-336.5309143066406, 132.36778259277344, -384.9282531738281), "Glitter"},
    {CFrame.new(-357.5382080078125, 129.8998565673828, -227.21456909179688), "Jelly"},
    {CFrame.new(-232.84506225585938, 184.9242706298828, -249.955322265625), "Ticket"},
    {CFrame.new(-465.8412780761719, 109.4454116821289, -175.78443908691406), "Gummy"},
    {CFrame.new(98.66006469726562, 35.20281219482422, 355.489013671875), "Ticket"},
    {CFrame.new(-374.18780517578125, 19.293209075927734, 494.7056884765625), "Ticket"},
    {CFrame.new(14.022793769836426, 4.5928144454956055, 68.14900207519531), "Ticket"},
    {CFrame.new(-54.35238265991211, 19.424358367919922, -62.27788543701172), "Ticket"},
    {CFrame.new(-380.6947021484375, 54.6801872253418, 206.6320037841797), "Ticket"},
    {CFrame.new(131.64907836914062, 117.50926208496094, -63.04363250732422), "Ticket"},
    {CFrame.new(338.76171875, 130.92079162597656, -233.84364318847656), "Ticket"},
    {CFrame.new(23.648874282836914, 17.36900520324707, 390.58270263671875), "Pine"},
    {CFrame.new(32.6508674621582, 13.400006294250488, 405.8634033203125), "Gumdrop"},
    {CFrame.new(43.54356384277344, 13.86900520324707, 373.79779052734375), "Pine"},
}

local function teleRewardLedgerPath()
    return "tffa_sup_rewards_" .. tostring(Player.UserId) .. ".txt"
end

local function loadTeleRewardLedger()
    local readfileFn = rawget(ENV, "readfile") or (type(readfile) == "function" and readfile)
    if type(readfileFn) ~= "function" then return {} end
    local ledger = {}
    local ok, content = pcall(readfileFn, teleRewardLedgerPath())
    if ok and type(content) == "string" then
        for key in content:gmatch("[^%s\r\n]+") do ledger[key] = true end
    end
    return ledger
end

local function saveTeleRewardSpot(key)
    local writefileFn = rawget(ENV, "writefile") or (type(writefile) == "function" and writefile)
    if type(writefileFn) ~= "function" then return end
    local ledger = loadTeleRewardLedger()
    ledger[key] = true
    local keys = {}
    for key in pairs(ledger) do table.insert(keys, key) end
    table.sort(keys)
    pcall(writefileFn, teleRewardLedgerPath(), table.concat(keys, "\n"))
end

local function teleRewardSpotKey(cf)
    local p = cf.Position
    return math.floor(p.X + 0.5) .. "_" .. math.floor(p.Y + 0.5) .. "_" .. math.floor(p.Z + 0.5)
end

local function teleRewardsSweep()
    local dwell = math.max(0.2, tonumber(Config.TeleRewards.Dwell) or 0.4)
    local nudge = math.max(0.5, tonumber(Config.TeleRewards.NudgeHeight) or 1)
    local _, root = getCharacter(3)
    if not root then
        status("Tele rewards: chưa có character - bỏ lượt")
        return false
    end
    local ledger = loadTeleRewardLedger()
    local visited, collected = 0, 0
    for index, spot in ipairs(TELE_REWARD_SPOTS) do
        if not State.Running then break end
        local key = teleRewardSpotKey(spot[1])
        if ledger[key] then
            visited += 1
        else
            local humanoid, currentRoot = getCharacter(2)
            if not humanoid or not currentRoot then break end
            status(string.format("Tele reward %d/%d: %s", index, #TELE_REWARD_SPOTS, spot[2]))
            -- Pin thẳng CFrame vào điểm (touch pickup), nhích lên/xuống kích hoạt.
            pcall(function()
                currentRoot.Anchored = true
                currentRoot.CFrame = spot[1]
                currentRoot.AssemblyLinearVelocity = Vector3.zero
            end)
            task.wait(dwell)
            pcall(function()
                currentRoot.CFrame = spot[1] + Vector3.new(0, nudge, 0)
            end)
            task.wait(dwell * 0.5)
            pcall(function()
                currentRoot.CFrame = spot[1]
                currentRoot.Anchored = false
            end)
            ledger[key] = true
            visited += 1
            collected += 1
            saveTeleRewardSpot(key)
            task.wait(0.1)
        end
    end
    -- Unanchor safety: đảm bảo root thoát ra (nếu break giữa chừng).
    local _, currentRoot = getCharacter(1)
    if currentRoot then pcall(function() currentRoot.Anchored = false end) end
    status(string.format("Tele rewards xong: %d điểm xử lý (%d mới)", visited, collected))
    return true
end

-- =============================================================================
-- MAIN LOOP
-- =============================================================================
print(string.format(
    "[TFFA Sup] Loaded (supporter build 1 | hatch=%s silver=%s feed=%s | desired: %s)",
    tostring(Config.AutoHatchInventoryEggs), tostring(Config.AutoBuySilverEgg),
    tostring(Config.AutoFeedTreats),
    table.concat(Config.DesiredStarStickers or {}, " + ")))

task.spawn(function()
    while State.Running do
        if not Config.Enabled then
            task.wait(1)
        else
            -- 0) TELE REWARDS đầu game: quét 1 lượt trước khi vào các worker
            --    (reward point one-time per account — Diamond Egg, Enzymes,
            --    Tickets... rơi ra item nhiều giá trị).
            if Config.TeleRewards.Enabled then
                local okTele, errTele = pcall(teleRewardsSweep)
                if not okTele then status("teleRewardsSweep error: " .. tostring(errTele)) end
            end
            -- 1) HATCH egg trong inventory (uu tien cao nhat).
            local okHatch, errHatch = pcall(hatchStep)
            if not okHatch then status("hatchStep error: " .. tostring(errHatch)) end
            task.wait(math.max(2, tonumber(Config.HatchInterval) or 6))
            -- 2) MUA Silver Egg bang ticket.
            if State.Running and Config.AutoBuySilverEgg then
                local okBuy, errBuy = pcall(buySilverEggStep)
                if not okBuy then status("buySilverEggStep error: " .. tostring(errBuy)) end
            end
            -- 3) FEED treats cho Mother Bear.
            if State.Running and Config.AutoFeedTreats then
                local okFeed, errFeed = pcall(feedTreatsStep)
                if not okFeed then status("feedTreatsStep error: " .. tostring(errFeed)) end
            end
            -- 4) MOTHER BEAR FOCUS FEED (đúng food quest yêu cầu, loop).
            if State.Running and Config.MotherBearFocusFeed then
                local okMB, errMB = pcall(motherBearFeedStep)
                if not okMB then status("motherBearFeedStep error: " .. tostring(errMB)) end
            end
            -- 5) STAR JELLY → Basic bee (rotate).
            if State.Running and Config.AutoUseStarJelly then
                local okJelly, errJelly = pcall(useStarJellyStep)
                if not okJelly then status("useStarJellyStep error: " .. tostring(errJelly)) end
            end
            task.wait(math.max(1, tonumber(Config.ScanInterval) or 4))
        end
    end
    status("Stopped")
end)

-- Boot: dump sticker book 1 lần (sau khi stats replicate) + expose API.
task.spawn(function()
    task.wait(6)
    if State.Running then dumpStickerBook("boot") end
end)

ENV.__TFFA_SUP = {
    Stop = function()
        State.Running = false
        status("Stop requested")
    end,
    State = State,
    Config = Config,
    -- GOI DOC LAP tu console: getgenv().__TFFA_SUP.BuyEgg("Silver")
    BuyEgg = buyEggRemote,
    -- Xem toan bo sticker book: getgenv().__TFFA_SUP.DumpStickers()
    DumpStickers = function() dumpStickerBook("manual") end,
    -- ARM tay khi Star Egg vao printer: getgenv().__TFFA_SUP.ArmStarEgg()
    ArmStarEgg = function() return armStarEgg("manual arm") end,
    -- Gửi request change acc tới Yummytool: __TFFA_SUP.RequestChangeAcc("lý do")
    RequestChangeAcc = function(reason) return requestChangeAcc(reason or "manual") end,
    -- Quét lại tele rewards (xóa ledger): __TFFA_SUP.ResetTeleRewards()
    ResetTeleRewards = function()
        local writefileFn = rawget(ENV, "writefile") or (type(writefile) == "function" and writefile)
        if type(writefileFn) == "function" then
            pcall(writefileFn, teleRewardLedgerPath(), "")
            status("Tele rewards ledger đã xóa - quét lại ở vòng sau")
        end
    end,
}

-- Alias toan cuc cho tien goi tay: getgenv().TFFA_BUY_EGG("Silver")
ENV.TFFA_BUY_EGG = buyEggRemote

return ENV.__TFFA_SUP
