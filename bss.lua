--[[
    ╔══════════════════════════════════════════════════════════╗
    ║              BSS KAITUN - Full Auto Script               ║
    ║  Claim Hive | Hatch Egg | Buy Egg | Buy Accessories     ║
    ║  Auto Redeem Codes | Quest Black Bear & Mother Bear     ║
    ║  Farm to 25 Bees | Tween Movement | Smart Logic         ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════
-- PLAYER REFERENCES
-- ═══════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Auto-update on respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    task.wait(1)
end)

-- ═══════════════════════════════════════════════════════════
-- REMOTE EVENTS & FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local Events = ReplicatedStorage:WaitForChild("Events")

local Remotes = {
    ClaimHive = Events:WaitForChild("ClaimHive"),
    PlayerHiveCommand = Events:WaitForChild("PlayerHiveCommand"),
    PlayerPurchase = Events:WaitForChild("PlayerPurchase"),
    GiveQuest = Events:WaitForChild("GiveQuest"),
    CompleteQuest = Events:WaitForChild("CompleteQuest"),
    PromoCodeEvent = Events:WaitForChild("PromoCodeEvent"),
    SelectNPCOption = Events:WaitForChild("SelectNPCOption"),
    PlayerActivesCommand = Events:WaitForChild("PlayerActivesCommand"),
    ToolCollect = Events:WaitForChild("ToolCollect"),
    ConstructHiveCellFromEgg = Events:WaitForChild("ConstructHiveCellFromEgg"),
    RetrievePlayerStats = Events:WaitForChild("RetrievePlayerStats"),
}

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════
local Config = {
    TargetBees = 25,
    TweenSpeed = 150,          -- studs per second
    ActionDelay = 1.5,         -- delay giữa các action
    FarmFieldTime = 30,        -- thời gian farm mỗi field (giây)
    ConvertDelay = 5,          -- thời gian chờ convert honey
    MaxRetries = 3,            -- số lần thử lại tối đa
    AntiAFK = true,            -- bật anti-afk
}

-- ═══════════════════════════════════════════════════════════
-- VỊ TRÍ CHÍNH XÁC (từ game data)
-- ═══════════════════════════════════════════════════════════
local Locations = {
    -- NPCs
    BlackBear = CFrame.new(-256.08, 3.81, 296.93),
    MotherBear = CFrame.new(-179.15, 3.95, 87.46),

    -- Shops
    BasicEggShop = CFrame.new(-145.86, 12, 230.83),
    BasicShop = CFrame.new(95.67, 11, 318.15),

    -- Hive
    HiveArea = CFrame.new(4.02, 6, 345.29),

    -- Fields (center positions, Y+3 để đứng trên)
    SunflowerField = CFrame.new(-208.95, 4.5, 176.58),
    MushroomField = CFrame.new(-89.70, 4.95, 111.73),
    DandelionField = CFrame.new(-30.72, 4.5, 220.62),
    BlueFlowerField = CFrame.new(146.87, 5.13, 99.31),
    CloverField = CFrame.new(157.55, 34.6, 196.35),
    StrawberryField = CFrame.new(-178.17, 21.13, -9.85),
}

-- ═══════════════════════════════════════════════════════════
-- PROMO CODES
-- ═══════════════════════════════════════════════════════════
local PromoCodes = {
    -- Verified working codes (BSS)
    "Wax", "Teespring", "Bopmaster", "Cog", "Connoisseur",
    "Roof", "Nectar", "Troggles", "1MLikes", "PlushFriday",
    "Millie", "Jumpstart", "WordFactory", "Cubly", "Mocito",
    "2MFavorites", "Gumaden", "Discord100k", "Sure",
    "SecretProfileCode", "ClubConverters", "RebootFriday",
    "FuzzyFriday", "Tornado", "Leftovers", "Luther",
    "Dysentery", "Crawlers", "Boosted", "Wink",
    "FourYearFiesta", "ClubBean", "Gummy", "Marshmallow",
    "500mil", "1BVisits", "2Billion", "3Billion",
    "ThnxCyasToyBox", "Afternoon", "Banned",
}

-- ═══════════════════════════════════════════════════════════
-- STATE MACHINE
-- ═══════════════════════════════════════════════════════════
local State = {
    Running = false,
    CurrentTask = "Idle",
    BeeCount = 0,
    HiveClaimed = false,
    CodesRedeemed = false,
    AccessoriesBought = false,
    QuestsAccepted = false,
}

-- ═══════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

-- Notification
local function notify(text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "🐝 Kaitun",
            Text = text,
            Duration = duration or 3,
        })
    end)
    print("[Kaitun] " .. text)
end

-- Safe character check
local function ensureCharacter()
    if not character or not character.Parent then
        character = player.Character or player.CharacterAdded:Wait()
    end
    if not humanoid or not humanoid.Parent then
        humanoid = character:WaitForChild("Humanoid")
    end
    if not rootPart or not rootPart.Parent then
        rootPart = character:WaitForChild("HumanoidRootPart")
    end
    return rootPart ~= nil and rootPart.Parent ~= nil
end

-- Tween di chuyển mượt
local function tweenTo(targetCFrame, callback)
    if not ensureCharacter() then
        task.wait(2)
        if not ensureCharacter() then return false end
    end

    local startPos = rootPart.Position
    local endPos = targetCFrame.Position
    local distance = (endPos - startPos).Magnitude

    -- Nếu quá gần thì không cần tween
    if distance < 5 then
        rootPart.CFrame = targetCFrame
        if callback then callback() end
        return true
    end

    -- Tính thời gian dựa trên tốc độ
    local tweenTime = math.clamp(distance / Config.TweenSpeed, 0.5, 15)

    -- Tạo tween info
    local tweenInfo = TweenInfo.new(
        tweenTime,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        0, false, 0
    )

    -- Tween CFrame
    local tween = TweenService:Create(rootPart, tweenInfo, {
        CFrame = targetCFrame
    })

    tween:Play()
    tween.Completed:Wait()

    task.wait(0.3)
    if callback then callback() end
    return true
end

-- Tween với waypoints (tránh bị kẹt)
local function tweenPath(waypoints)
    for i, wp in ipairs(waypoints) do
        if not State.Running then return false end
        local cf = typeof(wp) == "CFrame" and wp or CFrame.new(wp)
        tweenTo(cf)
        task.wait(0.2)
    end
    return true
end

-- Safe remote fire
local function fireRemote(remote, ...)
    local success, err = pcall(function(...)
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        end
    end, ...)
    if not success then
        warn("[Kaitun] Remote error: " .. tostring(err))
    end
    return success
end

-- Invoke remote function
local function invokeRemote(remote, ...)
    local success, result = pcall(function(...)
        return remote:InvokeServer(...)
    end, ...)
    if success then
        return result
    else
        warn("[Kaitun] Invoke error: " .. tostring(result))
        return nil
    end
end

-- Đếm bees hiện tại
local function countBees()
    local myHive = nil
    for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:IsA("Model") then
            local owner = hive:FindFirstChild("Owner")
            if owner and owner.Value == player then
                myHive = hive
                break
            end
        end
    end

    if not myHive then return 0 end

    local cells = myHive:FindFirstChild("Cells")
    if not cells then return 0 end

    local count = 0
    for _, cell in pairs(cells:GetChildren()) do
        if cell:IsA("Model") then
            -- Kiểm tra cell có bee không
            local beeType = cell:FindFirstChild("BeeType") or cell:FindFirstChild("Type")
            if beeType then
                count = count + 1
            else
                -- Đếm cell có children (occupied)
                if #cell:GetChildren() > 2 then
                    count = count + 1
                end
            end
        end
    end

    State.BeeCount = count
    return count
end

-- ═══════════════════════════════════════════════════════════
-- CORE FUNCTIONS
-- ═══════════════════════════════════════════════════════════

-- ▶ 1. CLAIM HIVE
local function claimHive()
    State.CurrentTask = "Claiming Hive"
    notify("Đang tìm và claim hive...")

    -- Check đã có hive chưa
    for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:IsA("Model") then
            local owner = hive:FindFirstChild("Owner")
            if owner and owner.Value == player then
                State.HiveClaimed = true
                notify("✅ Đã có hive!")
                return true
            end
        end
    end

    -- Tween đến khu vực hive
    tweenTo(Locations.HiveArea)
    task.wait(1)

    -- Tìm hive trống và claim
    for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:IsA("Model") then
            local owner = hive:FindFirstChild("Owner")
            local hiveID = hive:FindFirstChild("HiveID")
            if owner and owner.Value == nil and hiveID then
                Remotes.ClaimHive:FireServer(hiveID.Value)
                task.wait(2)

                -- Verify
                if owner.Value == player then
                    State.HiveClaimed = true
                    notify("✅ Claim Hive " .. hiveID.Value .. " thành công!")
                    return true
                end
            end
        end
    end

    notify("⚠️ Không tìm thấy hive trống, thử lại...")
    return false
end

-- ▶ 2. REDEEM ALL CODES
local function redeemAllCodes()
    State.CurrentTask = "Redeeming Codes"
    notify("Đang nhập " .. #PromoCodes .. " codes...")

    for i, code in ipairs(PromoCodes) do
        if not State.Running then return end
        Remotes.PromoCodeEvent:FireServer(code)
        task.wait(0.8)

        if i % 10 == 0 then
            notify("Codes: " .. i .. "/" .. #PromoCodes)
        end
    end

    State.CodesRedeemed = true
    notify("✅ Đã nhập xong " .. #PromoCodes .. " codes!")
end

-- ▶ 3. BUY ACCESSORIES
local function buyAccessories()
    State.CurrentTask = "Buying Accessories"
    notify("Đang mua accessories từ Basic Shop...")

    -- Tween đến Basic Shop
    tweenTo(Locations.BasicShop)
    task.wait(1.5)

    -- Danh sách items cần mua (theo thứ tự ưu tiên)
    local shopItems = {
        -- Tools
        {name = "Rake", category = "Tool"},
        {name = "Scooper", category = "Tool"},
        {name = "Magnet", category = "Tool"},
        {name = "Clippers", category = "Tool"},
        {name = "Vacuum", category = "Tool"},
        -- Bags
        {name = "Pouch", category = "Bag"},
        {name = "Jar", category = "Container"},
        {name = "Canister", category = "Container"},
        {name = "Backpack", category = "Container"},
        -- Accessories
        {name = "Helmet", category = "Accessory"},
        {name = "Belt Pocket", category = "Accessory"},
        {name = "Basic Boots", category = "Accessory"},
    }

    for _, item in ipairs(shopItems) do
        if not State.Running then return end
        Remotes.PlayerPurchase:FireServer(item.name, 1)
        task.wait(0.6)
    end

    State.AccessoriesBought = true
    notify("✅ Đã mua xong accessories!")
end

-- ▶ 4. BUY BASIC EGG
local function buyBasicEgg(amount)
    amount = amount or 1
    State.CurrentTask = "Buying Basic Egg"

    -- Tween đến Egg Shop
    tweenTo(Locations.BasicEggShop)
    task.wait(1)

    for i = 1, amount do
        if not State.Running then return false end
        Remotes.PlayerPurchase:FireServer("BasicEgg", 1)
        task.wait(0.8)
    end

    notify("🥚 Đã mua " .. amount .. " Basic Egg!")
    return true
end

-- ▶ 5. HATCH EGG
local function hatchEgg()
    State.CurrentTask = "Hatching Egg"

    -- Cần ở gần hive để hatch
    tweenTo(Locations.HiveArea)
    task.wait(1)

    local result = invokeRemote(Remotes.ConstructHiveCellFromEgg, "BasicEgg")
    task.wait(1.5)

    if result then
        notify("🐝 Hatch egg thành công!")
        return true
    else
        notify("⚠️ Hatch egg thất bại")
        return false
    end
end

-- ▶ 6. TALK TO NPC (với tween)
local function talkToNPC(npcName)
    State.CurrentTask = "Talking to " .. npcName

    local targetCFrame
    if npcName == "Black Bear" then
        targetCFrame = Locations.BlackBear
    elseif npcName == "Mother Bear" then
        targetCFrame = Locations.MotherBear
    else
        return false
    end

    -- Tween đến NPC
    tweenTo(targetCFrame)
    task.wait(1)

    -- Interact với NPC
    Remotes.PlayerActivesCommand:FireServer("npc talk", npcName)
    task.wait(1.5)

    return true
end

-- ▶ 7. ACCEPT QUEST
local function acceptQuest(npcName)
    talkToNPC(npcName)
    task.wait(1)

    -- Nhận quest
    Remotes.GiveQuest:FireServer(npcName)
    task.wait(1)

    -- Chọn option đầu tiên (Yes/Accept)
    Remotes.SelectNPCOption:FireServer(1)
    task.wait(0.5)

    notify("📋 Đã nhận quest từ " .. npcName)
    return true
end

-- ▶ 8. FARM FIELD (thu thập pollen)
local function farmField(fieldName, duration)
    duration = duration or Config.FarmFieldTime
    State.CurrentTask = "Farming " .. fieldName

    local fieldPart = Workspace.FlowerZones:FindFirstChild(fieldName)
    if not fieldPart then
        notify("⚠️ Không tìm thấy " .. fieldName)
        return false
    end

    local fieldPos = fieldPart.Position
    local fieldSize = fieldPart.Size

    -- Tween đến field
    tweenTo(CFrame.new(fieldPos.X, fieldPos.Y + 3, fieldPos.Z))
    task.wait(1)

    notify("🌻 Farming " .. fieldName .. " (" .. duration .. "s)...")

    -- Farm pattern: di chuyển zigzag trong field
    local startTime = tick()
    local rows = 5
    local cols = 5

    while (tick() - startTime) < duration and State.Running do
        for row = 1, rows do
            for col = 1, cols do
                if (tick() - startTime) >= duration or not State.Running then
                    return true
                end

                local xOffset = (col / cols - 0.5) * fieldSize.X * 0.8
                local zOffset = (row / rows - 0.5) * fieldSize.Z * 0.8

                -- Zigzag pattern
                if row % 2 == 0 then
                    xOffset = -xOffset
                end

                local targetPos = CFrame.new(
                    fieldPos.X + xOffset,
                    fieldPos.Y + 3,
                    fieldPos.Z + zOffset
                )

                tweenTo(targetPos)
                task.wait(0.3)

                -- Simulate tool use (click)
                Remotes.PlayerActivesCommand:FireServer("collect")
                task.wait(0.2)
            end
        end
    end

    return true
end

-- ▶ 9. CONVERT HONEY (về hive)
local function convertHoney()
    State.CurrentTask = "Converting Honey"
    notify("🍯 Đang convert honey...")

    tweenTo(Locations.HiveArea)
    task.wait(Config.ConvertDelay)

    -- Đợi convert xong
    Remotes.PlayerHiveCommand:FireServer("



")
    task.wait(3)

    notify("✅ Convert xong!")
end

-- ▶ 10. FARM TO 25 BEES (logic hoàn chỉnh)
local function farmTo25Bees()
    State.CurrentTask = "Farming to 25 Bees"
    local currentBees = countBees()
    notify("🐝 Hiện có " .. currentBees .. "/" .. Config.TargetBees .. " bees")

    -- Fields dễ farm cho newbie
    local farmFields = {"Dandelion Field", "Sunflower Field", "Mushroom Field"}
    local fieldIndex = 1

    while currentBees < Config.TargetBees and State.Running do
        -- Bước 1: Farm pollen để kiếm honey
        local currentField = farmFields[fieldIndex]
        farmField(currentField, Config.FarmFieldTime)

        -- Bước 2: Convert honey
        convertHoney()
        task.wait(2)

        -- Bước 3: Mua egg
        local bought = buyBasicEgg(1)
        if not bought then
            -- Không đủ tiền, farm thêm
            notify("💰 Chưa đủ honey, farm thêm...")
            farmField(currentField, Config.FarmFieldTime * 2)
            convertHoney()
            task.wait(2)
            buyBasicEgg(1)
        end

        -- Bước 4: Hatch egg
        task.wait(1)
        hatchEgg()
        task.wait(1)

        -- Update bee count
        currentBees = countBees()
        notify("🐝 Bees: " .. currentBees .. "/" .. Config.TargetBees)

        -- Rotate fields
        fieldIndex = fieldIndex % #farmFields + 1

        task.wait(1)
    end

    if currentBees >= Config.TargetBees then
        notify("🎉 ĐÃ ĐẠT " .. Config.TargetBees .. " BEES!")
    end
end

-- ═══════════════════════════════════════════════════════════
-- ANTI-AFK
-- ═══════════════════════════════════════════════════════════
local function antiAFK()
    if not Config.AntiAFK then return end

    local vu = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
        notify("🔄 Anti-AFK triggered")
    end)
end

-- ═══════════════════════════════════════════════════════════
-- MAIN EXECUTION PIPELINE
-- ═══════════════════════════════════════════════════════════
local function runPipeline()
    State.Running = true
    notify("🚀 KAITUN BẮT ĐẦU CHẠY!", 5)
    task.wait(2)

    -- ═══ PHASE 1: Setup cơ bản ═══
    notify("━━━ PHASE 1: Setup ━━━", 4)

    -- 1.1 Claim Hive
    local retries = 0
    while not State.HiveClaimed and retries < Config.MaxRetries and State.Running do
        claimHive()
        retries = retries + 1
        task.wait(2)
    end

    if not State.HiveClaimed then
        notify("❌ Không thể claim hive! Dừng script.")
        State.Running = false
        return
    end

    -- 1.2 Redeem Codes
    if not State.CodesRedeemed and State.Running then
        redeemAllCodes()
        task.wait(2)
    end

    -- 1.3 Buy Accessories
    if not State.AccessoriesBought and State.Running then
        buyAccessories()
        task.wait(2)
    end

    -- ═══ PHASE 2: Quests ═══
    notify("━━━ PHASE 2: Quests ━━━", 4)

    if not State.QuestsAccepted and State.Running then
        -- Black Bear quest
        acceptQuest("Black Bear")
        task.wait(2)

        -- Mother Bear quest
        acceptQuest("Mother Bear")
        task.wait(2)

        State.QuestsAccepted = true
    end

    -- ═══ PHASE 3: Farm to 25 Bees ═══
    notify("━━━ PHASE 3: Farm 25 Bees ━━━", 4)

    if State.Running then
        farmTo25Bees()
    end

    -- ═══ DONE ═══
    notify("🏆 KAITUN HOÀN THÀNH! Account đã setup xong.", 10)
    State.Running = false
    State.CurrentTask = "Completed"
end

-- ═══════════════════════════════════════════════════════════
-- STOP FUNCTION
-- ═══════════════════════════════════════════════════════════
local function stopKaitun()
    State.Running = false
    State.CurrentTask = "Stopped"
    notify("⏹️ Kaitun đã dừng.")
end

-- Expose global stop
getgenv().StopKaitun = stopKaitun
getgenv().KaitunState = State

-- ═══════════════════════════════════════════════════════════
-- START
-- ═══════════════════════════════════════════════════════════
antiAFK()
runPipeline()
