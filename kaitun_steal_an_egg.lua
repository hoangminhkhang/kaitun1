--[[
    ╔══════════════════════════════════════════════════════════╗
    ║   KAITUN - STEAL AN EGG (place 107778070777162)          ║
    ║   Tự động: chọn trứng XỊN NHẤT area -> tween tới -> vác   ║
    ║   về plot -> đặt treadmill -> chờ/ấp -> lặp lại           ║
    ║   FOCUS: SECRET + ETERNAL                                 ║
    ╚══════════════════════════════════════════════════════════╝
    Lưu ý: game copy trong Studio bị mất source nên script này
    viết cho game THẬT (chạy bằng executor). Chế độ PROBE ở lần
    chạy đầu sẽ in cấu trúc dữ liệu ra console -> nếu script không
    bắt được trứng, copy console gửi lại để chỉnh field.
]]

--// ══════════════════ CONFIG ══════════════════
local CONFIG = {
    TARGET_RARITIES   = { "Eternal", "Secret" }, -- chỉ chạy khi trứng area thuộc nhóm này (xếp theo ưu tiên)
    ALLOW_ANY_IF_NONE = true,   -- nếu area không có Secret/Eternal -> vẫn lấy trứng xịn nhất có sẵn
    STOP_ON_FOUND     = false,  -- true = dừng hẳn khi ấp ra Secret/Eternal
    AUTO_EQUIP_BEST   = true,   -- tự Equip Best sau mỗi lần ấp
    AUTO_SELL_RANK_MAX = 0,     -- 0 = tắt. VD: 8 = tự bán mọi pet <= Legendary (theo RARITY_RANK)
    SKIP_GROWTH       = true,   -- thử dùng RequestSkipGrowth cho nhanh (tốn tiền in-game)
    TWEEN_SPEED       = 240,    -- studs/giây khi tween
    GROWTH_TIMEOUT    = 420,    -- giây chờ trứng lớn tối đa trước khi force hatch
    HATCH_DELAY       = 1.5,    -- giây giữa RequestHatchEgg và RequestCompleteHatchEgg
    LOOP_DELAY        = 2,      -- giây nghỉ giữa mỗi vòng
    DEBUG             = true,   -- in log chi tiết + PROBE lần đầu
}

-- Thứ hạng rarity (số càng lớn càng xịn) - theo Directory.Rarity._Index của game
local RARITY_RANK = {
    Basic = 1, Common = 2, Uncommon = 3, Rare = 4, SuperRare = 5,
    Epic = 6, Exotic = 7, Legendary = 8, Mythical = 9, Mythic = 9,
    Superior = 10, Divine = 11, Celestial = 12, Cosmic = 13,
    BrainrotGod = 14, Rainbow = 15, Exclusive = 16, Limited = 17,
    Secret = 18, Eternal = 19,
}

--// ══════════════════ SERVICES ══════════════════
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local SoundService      = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Network     = ReplicatedStorage:WaitForChild("Network")

--// ══════════════════ UTIL ══════════════════
local function log(...)
    print("[KAITUN]", ...)
end
local function warnLog(...)
    warn("[KAITUN]", ...)
end

-- Gọi remote an toàn, trả (ok, result)
local function invoke(name, ...)
    local r = Network:FindFirstChild(name)
    if not r or not r:IsA("RemoteFunction") then
        return false, "không tìm thấy RemoteFunction: " .. tostring(name)
    end
    local args = { ... }
    local ok, res = pcall(function() return r:InvokeServer(table.unpack(args)) end)
    return ok, res
end

local function fireEvent(name, ...)
    local r = Network:FindFirstChild(name)
    if r and r:IsA("RemoteEvent") then
        r:FireServer(...)
        return true
    end
    return false
end

-- Lấy giá trị theo nhiều key khả dị (data thật có thể khác tên)
local function pick(t, keys)
    if type(t) ~= "table" then return nil end
    for _, k in ipairs(keys) do
        if t[k] ~= nil then return t[k] end
    end
    return nil
end

-- Tìm Instance đầu tiên lồng trong table (dùng để tìm Plot ref trong state)
local function deepFindInstance(t, depth)
    depth = depth or 0
    if depth > 4 or type(t) ~= "table" then return nil end
    for _, v in pairs(t) do
        if typeof(v) == "Instance" then return v end
        local found = deepFindInstance(v, depth + 1)
        if found then return found end
    end
    return nil
end

-- In cấu trúc table (PROBE)
local function dumpTable(t, name, depth, maxItems)
    depth = depth or 0
    maxItems = maxItems or 12
    if depth > 3 then return end
    if type(t) ~= "table" then
        log(string.rep("  ", depth) .. tostring(name) .. " = " .. tostring(t))
        return
    end
    local i = 0
    for k, v in pairs(t) do
        i = i + 1
        if i > maxItems then
            log(string.rep("  ", depth) .. tostring(k) .. " ... (cắt)")
            break
        end
        if type(v) == "table" then
            log(string.rep("  ", depth) .. tostring(k) .. " = table{")
            dumpTable(v, k, depth + 1, maxItems)
            log(string.rep("  ", depth) .. "}")
        elseif typeof(v) == "Instance" then
            log(string.rep("  ", depth) .. tostring(k) .. " = Instance:" .. v:GetFullName())
        else
            log(string.rep("  ", depth) .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

local function rankOf(rarity)
    if type(rarity) ~= "string" then return 0 end
    return RARITY_RANK[rarity] or RARITY_RANK[rarity:gsub("%s+", "")] or 0
end

local function isTarget(rarity)
    for _, t in ipairs(CONFIG.TARGET_RARITIES) do
        if rarity == t then return true end
    end
    return false
end

--// ══════════════════ NHÂN VẬT & DI CHUYỂN ══════════════════
local noclipConn = nil
local function setNoclip(on)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetChildren()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end
        end)
    end
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Tween mượt tới vị trí; trả về true/false
local function tweenTo(pos, yOff)
    local hrp = getHRP()
    if not hrp then return false end
    yOff = yOff or 3.5
    local target = CFrame.new(pos + Vector3.new(0, yOff, 0))
    local dist = (hrp.Position - target.Position).Magnitude
    if dist < 4 then return true end
    local dur = math.clamp(dist / CONFIG.TWEEN_SPEED, 0.2, 15)
    local tw = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = target })
    tw:Play()
    local done = false
    tw.Completed:Once(function() done = true end)
    local t0 = os.clock()
    while not done do
        if os.clock() - t0 > dur + 3 then break end -- kẹt -> thoát, sẽ retry
        if not getHRP() then return false end
        task.wait(0.1)
    end
    return done
end

--// ══════════════════ DATA GAME ══════════════════
-- Snapshot trứng area -> list các entry table
local function getAreaEggs(verbose)
    local ok, res = invoke("Eggs: RequestAreaEggSnapshot")
    if not ok or res == nil then return nil end
    if verbose then
        log("AreaEggSnapshot raw:")
        dumpTable(res, "snapshot", 0, 10)
    end
    -- res có thể là: {eggs={...}} | {...} | {slots={...}} | map id->entry
    local list = {}
    if type(res) == "table" then
        local container = pick(res, { "eggs", "Eggs", "slots", "Slots", "areaEggs", "list", "data" })
        if type(container) ~= "table" then container = res end
        for _, v in pairs(container) do
            if type(v) == "table" then
                table.insert(list, v)
            end
        end
    end
    return list
end

-- Rút trừ thông tin 1 entry trứng: id, rarity, position
local function parseEggEntry(e)
    if type(e) ~= "table" then return nil end
    local id = pick(e, { "id", "Id", "eggId", "eggID", "EggId", "uuid", "guid", "uid", "slotId" })
    local rarity = pick(e, { "rarity", "Rarity", "rarityName", "RarityName", "tier", "Tier", "grade" })
    local pos = pick(e, { "position", "Position", "pos", "Pos", "cframe", "CFrame" })
    local name = pick(e, { "name", "Name", "eggName", "assetName", "displayName", "DisplayName" })
    if typeof(pos) == "Instance" then pos = nil end -- không phải vector
    if type(rarity) ~= "string" then rarity = nil end
    if pos ~= nil and typeof(pos) ~= "Vector3" and typeof(pos) ~= "CFrame" then pos = nil end
    return {
        raw    = e,
        id     = id,
        rarity = rarity,
        name   = name,
        pos    = (typeof(pos) == "CFrame") and pos.Position or pos,
    }
end

-- Tìm vị trí vật lý của trứng khi snapshot không kèm pos:
-- đối chiếu id với render trong PlacedEggSlotsClient / AreaEggSlotsClient
local function findEggWorldPos(egg)
    if egg.pos then return egg.pos end
    local ws = workspace
    for _, folderName in ipairs({ "AreaEggSlotsClient", "PlacedEggRenders", "ClientRenderedAssets" }) do
        local folder = ws:FindFirstChild(folderName)
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                local nm = string.lower(m.Name)
                local idStr = egg.id and string.lower(tostring(egg.id)) or ""
                if idStr ~= "" and (nm:find(idStr, 1, true) or string.lower(m.Name) == idStr) then
                    local hb = m:FindFirstChild("Hitbox") or m:FindFirstChildWhichIsA("BasePart")
                    if hb then return hb.Position end
                end
            end
        end
    end
    -- Fallback: ăn theo ProximityPrompt/Model mới xuất hiện gần nhất
    local folder = ws:FindFirstChild("AreaEggSlotsClient")
    if folder and egg.id then
        for _, m in ipairs(folder:GetChildren()) do
            for _, d in ipairs(m:GetDescendants()) do
                if (d:IsA("StringValue") or d:IsA("ObjectValue")) and tostring(d.Value) == tostring(egg.id) then
                    local hb = m:FindFirstChild("Hitbox") or m:FindFirstChildWhichIsA("BasePart")
                    if hb then return hb.Position end
				end
            end
        end
    end
    return nil
end

-- Plot của mình: thử Plots: RequestState -> tìm Instance; fallback scan Workspace.Plots
local function getMyPlot(verbose)
    local ok, state = invoke("Plots: RequestState")
    if ok and type(state) == "table" then
        if verbose then
            log("Plots:RequestState:")
            dumpTable(state, "state", 0, 10)
        end
        local inst = deepFindInstance(state)
        if inst then
            local model = inst:FindFirstAncestorOfClass("Model")
            if model and model.Parent and model.Parent.Name == "Plots" then return model end
            if inst.Parent and inst.Parent.Name == "Plots" then return inst end
        end
        local pid = pick(state, { "plotId", "plot", "Plot", "plotIndex", "baseId" })
        if pid then
            local folder = workspace:FindFirstChild("Plots")
            if folder then
                local byName = folder:FindFirstChild(tostring(pid))
                if byName then return byName end
            end
        end
    end
    -- Fallback: plot có attribute Owner trùng tên mình, hoặc plot gần nhất
    local folder = workspace:FindFirstChild("Plots")
    if folder then
        local best, bestDist = nil, math.huge
        local hrp = getHRP()
        for _, p in ipairs(folder:GetChildren()) do
            local owner = p:GetAttribute("Owner") or p:GetAttribute("owner") or p:GetAttribute("OwnerId")
            if owner and (tostring(owner) == LocalPlayer.Name or tostring(owner) == tostring(LocalPlayer.UserId)) then
                return p
            end
            if hrp then
                local c = p:FindFirstChild("CenterPoint") or p:FindFirstChild("TreadmillBottom") or p:FindFirstChildWhichIsA("BasePart")
                if c then
                    local d = (c.Position - hrp.Position).Magnitude
                    if d < bestDist then best, bestDist = p, d end
                end
            end
        end
        return best
    end
    return nil
end

local function getPlotDropPos(plot)
    local p = plot:FindFirstChild("CenterPoint")
        or plot:FindFirstChild("TreadmillBottom")
        or plot:FindFirstChildWhichIsA("BasePart")
    return p and p.Position or nil
end

--// ══════════════════ HÀNH ĐỘNG GAME ══════════════════
local function carryEgg(egg)
    -- Thử lần lượt các dạng arg phổ biến
    local variants = {
        function() return invoke("Eggs: RequestAreaEggCarry", egg.id) end,
        function() return invoke("Eggs: RequestAreaEggCarry", egg.raw) end,
        function() return invoke("Eggs: RequestAreaEggCarry", tostring(egg.id)) end,
    }
    for i, f in ipairs(variants) do
        local ok, res = f()
        if ok and res ~= false then
            log("Carry OK (variant " .. i .. ") id=", egg.id, "res=", tostring(res))
            return true
        end
        if CONFIG.DEBUG then log("Carry variant " .. i .. " ->", tostring(res)) end
    end
    return false
end

local function placeEgg(egg, plot)
    local dropPos = getPlotDropPos(plot)
    if dropPos then tweenTo(dropPos, 4) end
    local variants = {
        function() return invoke("Eggs: RequestPlaceEgg") end,
        function() return invoke("Eggs: RequestPlaceEgg", egg.id) end,
        function() return invoke("Eggs: RequestPlaceEgg", egg.id, plot) end,
        function() return invoke("Eggs: RequestPlaceEgg", egg.raw) end,
    }
    for i, f in ipairs(variants) do
        local ok, res = f()
        if ok and res ~= false then
            log("PlaceEgg OK (variant " .. i .. ") res=", tostring(res))
            return true
        end
        if CONFIG.DEBUG then log("PlaceEgg variant " .. i .. " ->", tostring(res)) end
    end
    -- Last resort: thả trứng xuống (server có thể auto-place khi ở plot)
    invoke("Eggs: RequestAreaEggDrop")
    return false
end

-- Danh sách trứng đang nuôi trên plot của mình
local function getMyEggs(verbose)
    local ok, res = invoke("Eggs: RequestRuntimeSnapshot")
    if not ok or type(res) ~= "table" then return {} end
    if verbose then
        log("Eggs RuntimeSnapshot:")
        dumpTable(res, "runtime", 0, 10)
    end
    local container = pick(res, { "eggs", "Eggs", "growing", "list", "data" }) or res
    local list = {}
    for _, v in pairs(container) do
        if type(v) == "table" then table.insert(list, v) end
    end
    return list
end

local function eggReady(e)
    local ready = pick(e, { "ready", "Ready", "canHatch", "CanHatch", "grown", "isReady", "hatchable" })
    if ready == true then return true end
    local prog = pick(e, { "progress", "Progress", "growth", "Growth", "percent", "growthPercent" })
    if type(prog) == "number" and prog >= 1 then return true end -- 0..1
    if type(prog) == "number" and prog >= 100 then return true end -- 0..100
    local rem = pick(e, { "remainingTime", "timeRemaining", "RemainingHatchTime", "growTimeLeft" })
    if type(rem) == "number" and rem <= 0 then return true end
    return false
end

local function hatchMyEggs()
    local hatched = 0
    for _, e in ipairs(getMyEggs()) do
        local id = pick(e, { "id", "Id", "eggId", "uuid", "uid" })
        if id then
            if CONFIG.SKIP_GROWTH and not eggReady(e) then
                invoke("Eggs: RequestSkipGrowth", id)
            end
            if eggReady(e) or CONFIG.SKIP_GROWTH then
                local ok1 = invoke("Eggs: RequestHatchEgg", id)
                task.wait(CONFIG.HATCH_DELAY)
                local ok2 = invoke("Eggs: RequestCompleteHatchEgg", id)
                if CONFIG.DEBUG then log("Hatch", tostring(id), "->", tostring(ok1), tostring(ok2)) end
                hatched = hatched + 1
                task.wait(0.5)
            end
        end
    end
    return hatched
end

-- Kiểm tra pet xịn mới (Secret/Eternal) trong active assets
local function scanForTargetPets()
    local ok, res = invoke("ActiveAssets: RequestRuntimeSnapshot")
    if not ok or type(res) ~= "table" then return {} end
    local found = {}
    local function scan(t, depth)
        depth = depth or 0
        if depth > 5 or type(t) ~= "table" then return end
        for _, v in pairs(t) do
            if type(v) == "string" and isTarget(v) then
                table.insert(found, v)
            elseif type(v) == "table" then
                scan(v, depth + 1)
            end
        end
    end
    scan(res)
    return found
end

local function equipBest()
    invoke("Backpack: EquipBest")
end

local function sellTrash()
    if CONFIG.AUTO_SELL_RANK_MAX <= 0 then return end
    -- Dùng SellAllAssets của AssetInventory (RemoteEvent) khi có; game có AutoSell state riêng
    local ok = fireEvent("AssetInventory: SellAllAssets")
    if not ok then
        invoke("Backpack: SetAutoSellState", true)
    end
end

--// ══════════════════ GUI ══════════════════
local gui
local statusLabel, statLabel
local running = false

local function buildGUI()
    if gui then return end
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    gui = Instance.new("ScreenGui")
    gui.Name = "KaitunSAE"
    gui.ResetOnSpawn = false
    gui.Parent = pg

    local main = Instance.new("Frame")
    main.Size = UDim2.fromOffset(270, 170)
    main.Position = UDim2.new(0, 12, 0.4, 0)
    main.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true -- executor legacy, vẫn hoạt động đa số
    main.Parent = gui
    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 26)
    title.BackgroundTransparency = 1
    title.Text = "🥚 KAITUN - STEAL AN EGG"
    title.TextColor3 = Color3.fromRGB(255, 220, 90)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = main

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -16, 0, 22)
    statusLabel.Position = UDim2.new(0, 8, 0, 30)
    statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Text = "Đang tắt"
    statusLabel.Parent = main
    Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

    statLabel = Instance.new("TextLabel")
    statLabel.Size = UDim2.new(1, -16, 0, 20)
    statLabel.Position = UDim2.new(0, 8, 0, 56)
    statLabel.BackgroundTransparency = 1
    statLabel.TextColor3 = Color3.fromRGB(170, 230, 170)
    statLabel.Font = Enum.Font.Gotham
    statLabel.TextSize = 12
    statLabel.Text = "Ấp: 0 | Tìm thấy: 0"
    statLabel.Parent = main

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(1, -16, 0, 34)
    toggle.Position = UDim2.new(0, 8, 0, 82)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    toggle.Text = "▶ BẬT KAITUN"
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.Parent = main
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

    local equipBtn = toggle:Clone()
    equipBtn.Size = UDim2.new(1, -16, 0, 26)
    equipBtn.Position = UDim2.new(0, 8, 0, 122)
    equipBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
    equipBtn.Text = "⚡ Equip Best"
    equipBtn.Parent = main
    equipBtn.MouseButton1Click:Connect(equipBest)

    toggle.MouseButton1Click:Connect(function()
        running = not running
        toggle.Text = running and "⏸ TẮT KAITUN" or "▶ BẬT KAITUN"
        toggle.BackgroundColor3 = running and Color3.fromRGB(170, 70, 60) or Color3.fromRGB(60, 160, 90)
    end)
end

local function setStatus(txt)
    if statusLabel then statusLabel.Text = txt end
end

local hatchCount, foundCount = 0, 0
local function updateStats()
    if statLabel then
        statLabel.Text = ("Ấp: %d | Tìm thấy: %d"):format(hatchCount, foundCount)
    end
end

local function announceFound(list)
    foundCount = foundCount + #list
    updateStats()
    warnLog("★ PET XỊN:", table.concat(list, ", "))
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://12221967"
    s.Volume = 1
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
    setStatus("★ TÌM THẤY: " .. table.concat(list, ", "))
end

--// ══════════════════ VÒNG LẶP KAITUN ══════════════════
local probed = false
local function kaitunLoop()
    while task.wait(CONFIG.LOOP_DELAY) do
        while not running do task.wait(0.5) end

        -- 0. Ấp nốt trứng sẵn sàng trên plot
        local h = hatchMyEggs()
        if h > 0 then
            hatchCount = hatchCount + h
            updateStats()
            local found = scanForTargetPets()
            if #found > 0 then
                announceFound(found)
                if CONFIG.STOP_ON_FOUND then running = false end
            end
            if CONFIG.AUTO_EQUIP_BEST then equipBest() end
            sellTrash()
        end

        -- 1. Lấy snapshot trứng area
        local eggs = getAreaEggs()
        if not probed and CONFIG.DEBUG then probed = true end
        if not eggs or #eggs == 0 then
            setStatus("Chờ trứng area spawn...")
            continue
        end

        -- 2. Chọn trứng: ưu tiên Secret/Eternal, không có thì xịn nhất
        local best, bestRank = nil, -1
        local anyBest, anyRank = nil, -1
        local hrp = getHRP()
        for _, raw in ipairs(eggs) do
            local e = parseEggEntry(raw)
            if e then
                local r = rankOf(e.rarity)
                if r > anyRank then anyBest, anyRank = e, r end
                if isTarget(e.rarity) and r > bestRank then best, bestRank = e, r end
            end
        end
        local target = best
        if not target and CONFIG.ALLOW_ANY_IF_NONE then target = anyBest end
        if not target then
            setStatus("Không có trứng hợp lệ (chờ Secret/Eternal)...")
            continue
        end

        -- 3. Tween tới trứng
        local pos = findEggWorldPos(target)
        if not pos then
            setStatus("Không xác định được vị trí trứng (xem console PROBE)")
            warnLog("PROBE entry trứng để chỉnh field:")
            dumpTable(target.raw, "egg", 0, 15)
            continue
        end
        setStatus(("Đi tới %s (%s)"):format(target.name or target.id or "?", target.rarity or "?"))
        setNoclip(true)
        tweenTo(pos)

        -- 4. Vác trứng về plot
        if not carryEgg(target) then
            setStatus("Carry thất bại -> thử lại")
            task.wait(1)
            setNoclip(false)
            continue
        end
        local plot = getMyPlot()
        if not plot then
            setStatus("Không tìm thấy plot của mình (xem console)")
            setNoclip(false)
            continue
        end
        setStatus("Vác trứng về plot...")
        local dropPos = getPlotDropPos(plot)
        if dropPos then
            tweenTo(dropPos, 4)
        else
            warnLog("Không tìm thấy điểm đặt trong plot - đứng tại chỗ")
        end
        task.wait(0.4)

        -- 5. Đặt lên treadmill
        placeEgg(target, plot)
        setNoclip(false)
        setStatus("Đã đặt trứng - chờ nuôi lớn...")

        -- 6. Chờ growth rồi ấp
        local t0 = os.clock()
        while os.clock() - t0 < CONFIG.GROWTH_TIMEOUT do
            if not running then break end
            local mine = getMyEggs()
            local anyReady = false
            for _, e in ipairs(mine) do
                if eggReady(e) then anyReady = true break end
            end
            if anyReady or #mine == 0 then break end
            task.wait(3)
        end
    end
end

--// ══════════════════ ANTI-AFK + KHỞI ĐỘNG ══════════════════
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end)
end)

buildGUI()
setStatus("Sẵn sàng - nhấn BẬT KAITUN")

-- PROBE lần đầu: in cấu trúc để hiệu chỉnh field nếu cần
if CONFIG.DEBUG then
    task.spawn(function()
        task.wait(2)
        log("=== PROBE AREA EGG SNAPSHOT ===")
        getAreaEggs(true)
        log("=== PROBE PLOT STATE ===")
        getMyPlot(true)
        log("=== PROBE EGGS RUNTIME ===")
        getMyEggs(true)
        log("=== HẾT PROBE ===")
    end)
end

task.spawn(kaitunLoop)
log("Kaitun Steal An Egg đã load. Focus:", table.concat(CONFIG.TARGET_RARITIES, ", "))
