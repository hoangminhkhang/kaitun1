--[[
    BSS Kaitun v5 - Full Auto Pipeline
    Chức năng:
    1. Claim Hive
    2. Redeem Codes
    3. Buy Accessories (theo bee count)
    4. Accept Quests từ NPC
    5. Smart Farm theo quest
    6. Buy Egg + Hatch
    7. Loop đến đủ bees target
]]

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local plr = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════
local TARGET_BEES = 25
local FARM_TIME = 30
local TWEEN_SPEED = 130
local FARM_WALK_SPEED = 90
local NORMAL_WALK_SPEED = 16
local TOKEN_COLLECT_RANGE = 60

local running = true

-- ═══════════════════════════════════════════════════════════
-- CHARACTER REFERENCES
-- ═══════════════════════════════════════════════════════════
local char, hum, hrp

local function refreshCharacter()
    char = plr.Character or plr.CharacterAdded:Wait()
    hum = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end
refreshCharacter()

plr.CharacterAdded:Connect(function()
    task.wait(0.5)
    refreshCharacter()
end)

-- ═══════════════════════════════════════════════════════════
-- REMOTE EVENTS
-- ═══════════════════════════════════════════════════════════
local Events = ReplicatedStorage:WaitForChild("Events", 10)

local function fireEvent(name, ...)
    local r = Events:FindFirstChild(name)
    if not r then
        warn("[Kaitun] Remote not found: " .. name)
        return false
    end
    local ok, err = pcall(r.FireServer, r, ...)
    if not ok then
        warn("[Kaitun] Fire error " .. name .. ": " .. tostring(err))
    end
    return ok
end

local function invokeEvent(name, ...)
    local r = Events:FindFirstChild(name)
    if not r then
        warn("[Kaitun] Remote not found: " .. name)
        return nil
    end
    local ok, res = pcall(r.InvokeServer, r, ...)
    if not ok then
        warn("[Kaitun] Invoke error " .. name .. ": " .. tostring(res))
        return nil
    end
    return res
end

-- ═══════════════════════════════════════════════════════════
-- LOG
-- ═══════════════════════════════════════════════════════════
local function log(msg)
    print("[Kaitun] " .. tostring(msg))
end

-- ═══════════════════════════════════════════════════════════
-- NPC CONFIG
-- ═══════════════════════════════════════════════════════════
local NPC_QUESTS = {
    {name = "Black Bear",   pos = Vector3.new(-256, 6, 297),   minBees = 0},
    {name = "Mother Bear",  pos = Vector3.new(-179, 6, 87),    minBees = 0},
    {name = "Brown Bear",   pos = Vector3.new(281, 46, 237),   minBees = 0},
    {name = "Panda Bear",   pos = Vector3.new(104, 36, 48),    minBees = 5},
    {name = "Science Bear", pos = Vector3.new(269, 104, 20),   minBees = 10},
    {name = "Honey Bee",    pos = Vector3.new(-387, 90, -220), minBees = 15},
    {name = "Polar Bear",   pos = Vector3.new(-107, 120, -77), minBees = 15},
    {name = "Spirit Bear",  pos = Vector3.new(-365, 98, 479),  minBees = 35},
}

-- ═══════════════════════════════════════════════════════════
-- FIELD KEYWORD MAP
-- ═══════════════════════════════════════════════════════════
local FIELD_MAP = {
    ["sunflower"]   = "Sunflower Field",
    ["mushroom"]    = "Mushroom Field",
    ["dandelion"]   = "Dandelion Field",
    ["blue flower"] = "Blue Flower Field",
    ["clover"]      = "Clover Field",
    ["strawberry"]  = "Strawberry Field",
    ["spider"]      = "Spider Field",
    ["bamboo"]      = "Bamboo Field",
    ["pine tree"]   = "Pine Tree Forest",
    ["rose"]        = "Rose Field",
    ["cactus"]      = "Cactus Field",
    ["pumpkin"]     = "Pumpkin Patch",
    ["stump"]       = "Stump Field",
    ["mountain"]    = "Mountain Top Field",
    ["coconut"]     = "Coconut Field",
    ["pepper"]      = "Pepper Patch",
    ["pineapple"]   = "Pineapple Patch",
    ["ant"]         = "Ant Field",
}

-- ═══════════════════════════════════════════════════════════
-- BACKGROUND TASKS (Noclip + Auto Skip Dialog + Anti-AFK)
-- ═══════════════════════════════════════════════════════════

-- Noclip: cho phép đi xuyên part
RunService.Stepped:Connect(function()
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Auto skip NPC dialog (IncrementDialogue)
RunService.Stepped:Connect(function()
    pcall(function()
        local sg = plr.PlayerGui:FindFirstChild("ScreenGui")
        if sg and sg:FindFirstChild("NPC") and sg.NPC.Visible then
            plr.PlayerGui.Camera.Controllers.NPC.IncrementDialogue:Invoke()
        end
    end)
end)

-- Anti-AFK
pcall(function()
    plr.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        log("Anti-AFK triggered")
    end)
end)

-- ═══════════════════════════════════════════════════════════
-- TWEEN (di chuyển mượt bằng TweenService)
-- ═══════════════════════════════════════════════════════════
local function tweenTo(targetCFrame, speed)
    speed = speed or TWEEN_SPEED
    if not hrp or not hrp.Parent then refreshCharacter() end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance < 5 then
        hrp.CFrame = targetCFrame
        return
    end

    local tweenTime = distance / speed
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(tweenTime, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()
    tween.Completed:Wait()
    task.wait(0.15)
end

-- ═══════════════════════════════════════════════════════════
-- HIVE & BEE COUNT
-- ═══════════════════════════════════════════════════════════
local function getMyHive()
    for _, hive in pairs(workspace.Honeycombs:GetChildren()) do
        if hive:IsA("Model") and hive:FindFirstChild("Owner") and hive.Owner.Value == plr then
            return hive
        end
    end
    return nil
end

local function countBees()
    local hive = getMyHive()
    if not hive or not hive:FindFirstChild("Cells") then
        return 0
    end

    local count = 0
    for _, cell in pairs(hive.Cells:GetChildren()) do
        local cellType = cell:FindFirstChild("CellType")
        if cellType and cellType.Value ~= "Empty" and cellType.Value ~= "" then
            count = count + 1
        end
    end
    return count
end

local function getEmptyHiveSlot()
    local hive = getMyHive()
    if not hive or not hive:FindFirstChild("Cells") then return nil, nil end

    for _, cell in pairs(hive.Cells:GetChildren()) do
        local cellType = cell:FindFirstChild("CellType")
        if cellType and (cellType.Value == "Empty" or cellType.Value == "") then
            local cellX = cell:FindFirstChild("CellX")
            local cellY = cell:FindFirstChild("CellY")
            if cellX and cellY then
                return cellX.Value, cellY.Value
            end
        end
    end
    return nil, nil
end

local function getHivePosition()
    local hive = getMyHive()
    if not hive then
        return CFrame.new(4, 7, 345)
    end

    local spawnPos = hive:FindFirstChild("SpawnPos")
    if spawnPos and spawnPos:IsA("CFrameValue") then
        return spawnPos.Value * CFrame.new(0, 3, 0)
    end

    return CFrame.new(4, 7, 345)
end

-- ═══════════════════════════════════════════════════════════
-- 1. CLAIM HIVE
-- ═══════════════════════════════════════════════════════════
local function claimHive()
    log(">> Claim Hive")

    if getMyHive() then
        log("OK: đã có hive")
        return true
    end

    for _, hive in pairs(workspace.Honeycombs:GetChildren()) do
        if hive:IsA("Model") and hive:FindFirstChild("Owner") and hive.Owner.Value == nil then
            local hiveID = hive:FindFirstChild("HiveID")
            if not hiveID then continue end

            -- Tween đến LightHolder (giống source mẫu)
            local lh = hive:FindFirstChildWhichIsA("BasePart", true)
            for _, child in pairs(hive:GetChildren()) do
                if child.Name == "LightHolder" and child:IsA("BasePart") then
                    lh = child
                    break
                end
            end

            if lh then
                tweenTo(lh.CFrame)
            end
            task.wait(1)

            fireEvent("ClaimHive", hiveID.Value)
            task.wait(2)

            if hive.Owner.Value == plr then
                log("Claimed hive " .. hiveID.Value)
                return true
            end
        end
    end

    log("FAIL: không claim được hive")
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 2. REDEEM CODES
-- ═══════════════════════════════════════════════════════════
local function redeemCodes()
    log(">> Redeem Codes")

    local codes = {
        -- Codes từ guide
        "BeesBuzz123", "38217", "BopMaster", "Connoisseur",
        "Crawlers", "Nectar", "Roof", "Wax",
    }

    for i, code in ipairs(codes) do
        if not running then return end
        fireEvent("PromoCodeEvent", code)
        task.wait(0.5)
    end

    log("Codes done (" .. #codes .. ")")
end

-- ═══════════════════════════════════════════════════════════
-- 3. BUY ITEMS (ItemPackageEvent)
-- ═══════════════════════════════════════════════════════════
local function buyItem(category, itemType, amount)
    local args = {Category = category, Type = itemType}
    if amount then
        args.Amount = amount
    end

    local result = invokeEvent("ItemPackageEvent", "Purchase", args)
    return result ~= nil
end

-- Track items đã mua để không mua lại
local boughtItems = {}

local function tryBuy(category, itemType, shopPos)
    if boughtItems[itemType] then
        return true
    end
    if shopPos then
        tweenTo(shopPos)
        task.wait(0.5)
    end
    local ok = buyItem(category, itemType, 1)
    if ok then
        boughtItems[itemType] = true
        log("Bought: " .. itemType)
    else
        log("FAIL buy " .. itemType .. " (not enough resources)")
    end
    task.wait(0.5)
    return ok
end

-- Shop positions
local SHOPS = {
    Basic   = CFrame.new(98, 15, 292),
    Pro     = CFrame.new(165, 84, -178),
    Egg     = CFrame.new(-146, 15, 231),
}

-- Phase 1: 0->5 bees
local function phase1_buy()
    log(">> Phase 1: Buy Clippers + Scissors")
    tryBuy("Collector", "Clippers", SHOPS.Basic)
    tryBuy("Collector", "Scissors", SHOPS.Pro)
end

-- Phase 2: 5->10 bees
local function phase2_buy()
    log(">> Phase 2: Buy Canister + Vacuum + Boots/Belt/Helmet")
    tryBuy("Accessory", "Canister", SHOPS.Basic)
    tryBuy("Collector", "Vacuum", SHOPS.Basic)
    -- Optional nếu đủ
    tryBuy("Accessory", "Basic Boots", SHOPS.Basic)
    tryBuy("Accessory", "Belt Pocket", SHOPS.Basic)
    tryBuy("Accessory", "Helmet", SHOPS.Basic)
end

-- Phase 3: 10->15 bees
local function phase3_buy()
    log(">> Phase 3: Buy Compressor + Pulsar")
    tryBuy("Accessory", "Compressor", SHOPS.Pro)
    tryBuy("Collector", "Pulsar", SHOPS.Pro)
end

-- Phase 4: 15->20 bees
local function phase4_buy()
    log(">> Phase 4: Buy Port-O-Hive")
    tryBuy("Accessory", "Port-O-Hive", SHOPS.Pro)
end

-- Phase 5: 20->25 bees
local function phase5_buy()
    log(">> Phase 5: Buy Propeller Hat")
    tryBuy("Accessory", "Propeller Hat", SHOPS.Pro)
end

-- ═══════════════════════════════════════════════════════════
-- ROYAL JELLY: reroll Basic/Brave bee → Blue bee
-- ═══════════════════════════════════════════════════════════
-- List bee Blue mong muốn (target khi reroll)
local TARGET_BLUE_BEES = {
    BumbleBee = true,
    CoolBee = true,
    BubbleBee = true,
    BuckoBee = true,
    FrostyBee = true,
    DiamondBee = true,
    NinjaBee = true,
    BuoyantBee = true,
    TadpoleBee = true,
}

-- Bee cần reroll (Basic/Brave)
local REROLL_TARGETS = {
    BasicBee = true,
    BraveBee = true,
}

local function isBlueBee(beeType)
    return TARGET_BLUE_BEES[beeType] == true
end

-- Tìm cell Basic/Brave bee để reroll
local function findCellToReroll()
    local hive = getMyHive()
    if not hive or not hive:FindFirstChild("Cells") then return nil end

    for _, cell in pairs(hive.Cells:GetChildren()) do
        local ct = cell:FindFirstChild("CellType")
        local locked = cell:FindFirstChild("CellLocked")

        if ct and (locked == nil or not locked.Value) then
            if REROLL_TARGETS[ct.Value] then
                local cellX = cell:FindFirstChild("CellX")
                local cellY = cell:FindFirstChild("CellY")
                if cellX and cellY then
                    return {x = cellX.Value, y = cellY.Value, cell = cell, original = ct.Value}
                end
            end
        end
    end
    return nil
end

-- Reroll 1 cell cho đến khi ra Blue bee
local function rerollCellToBlue(cellInfo, maxAttempts)
    maxAttempts = maxAttempts or 100
    log(">> Reroll C" .. cellInfo.x .. "," .. cellInfo.y .. " (" .. cellInfo.original .. ") -> Blue bee")

    for i = 1, maxAttempts do
        if not running then return false end

        local ct = cellInfo.cell:FindFirstChild("CellType")
        if ct and isBlueBee(ct.Value) then
            log("✅ Got Blue bee: " .. ct.Value .. " after " .. i .. " rolls!")
            return true
        end

        invokeEvent("ConstructHiveCellFromEgg", cellInfo.x, cellInfo.y, "RoyalJelly", 1, false)
        task.wait(0.6)
    end

    log("RJ max attempts reached")
    return false
end

-- Main: reroll all Basic/Brave -> Blue
local function rerollBasicToBlue()
    log(">> Royal Jelly: Basic/Brave -> Blue bees")
    tweenTo(getHivePosition())
    task.wait(1)

    local maxCells = 25
    for i = 1, maxCells do
        if not running then break end

        local cellInfo = findCellToReroll()
        if not cellInfo then
            log("No more Basic/Brave cells to reroll")
            break
        end

        rerollCellToBlue(cellInfo, 80)
        task.wait(0.3)
    end

    log("RJ reroll done")
end

-- ═══════════════════════════════════════════════════════════
-- 4. BUY EGG + HATCH
-- ═══════════════════════════════════════════════════════════
local function buyBasicEgg(amount)
    amount = amount or 1
    log(">> Buy " .. amount .. " Basic Egg(s)")
    tweenTo(SHOPS.Egg)
    task.wait(1)
    for i = 1, amount do
        if not running then break end
        buyItem("Eggs", "Basic", 1)
        task.wait(0.4)
    end
end

-- Đếm số slot trống trong hive
local function countEmptySlots()
    local hive = getMyHive()
    if not hive or not hive:FindFirstChild("Cells") then return 0 end
    local n = 0
    for _, cell in pairs(hive.Cells:GetChildren()) do
        local ct = cell:FindFirstChild("CellType")
        if ct and (ct.Value == "Empty" or ct.Value == "") then
            n += 1
        end
    end
    return n
end

local function hatchEgg()
    log(">> Hatch Basic Egg")
    tweenTo(getHivePosition())
    task.wait(1)

    local x, y = getEmptyHiveSlot()
    if not x then log("FAIL: no empty slot") return false end

    log("Hatch C" .. x .. "," .. y)
    -- Args: (x, y, eggType, amount, useRoyalJelly)
    local result = invokeEvent("ConstructHiveCellFromEgg", x, y, "Basic", 1, false)
    task.wait(1)
    log("Hatch: " .. tostring(result ~= nil))
    return result ~= nil
end

local function hatchAllEggs()
    log(">> Hatch ALL eggs")
    tweenTo(getHivePosition())
    task.wait(1)

    local hatched = 0
    for i = 1, 50 do
        if not running then break end

        local x, y = getEmptyHiveSlot()
        if not x then log("No empty slot left") break end

        -- Args: (x, y, "Basic", 1, false) - KHÔNG có hiveID
        local result = invokeEvent("ConstructHiveCellFromEgg", x, y, "Basic", 1, false)
        task.wait(0.8)

        if result then
            hatched = hatched + 1
            log("Hatched #" .. hatched .. " C" .. x .. "," .. y)
        else
            log("No more eggs or fail")
            break
        end
    end

    log("Hatch done: " .. hatched)
    return hatched
end

-- ═══════════════════════════════════════════════════════════
-- 5. NPC ALERT CHECK
-- ═══════════════════════════════════════════════════════════
local function npcHasAlert(npcName)
    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then return false end

    local platform = npc:FindFirstChild("Platform")
    if not platform then return false end

    local alertPos = platform:FindFirstChild("AlertPos")
    if not alertPos then return false end

    local alertGui = alertPos:FindFirstChild("AlertGui")
    if not alertGui then return false end

    for _, child in pairs(alertGui:GetDescendants()) do
        if child:IsA("ImageLabel") and child.ImageTransparency == 0 then
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════
-- 6. TALK NPC (nhận quest)
-- ═══════════════════════════════════════════════════════════
local function talkNPC(npcName, npcPos)
    log(">> Talk to: " .. npcName)

    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then
        log("FAIL: NPC not found")
        return false
    end

    -- Tween đến NPC
    tweenTo(CFrame.new(npcPos))
    task.wait(0.3)
    hrp.CFrame = CFrame.new(npcPos)
    task.wait(0.3)

    -- Gọi ButtonEffect 2 lần để nhận cả Beesmas + quest thường
    for i = 1, 2 do
        pcall(function()
            local NPCsModule = require(ReplicatedStorage.Activatables.NPCs)
            NPCsModule.ButtonEffect(plr, npc)
        end)

        -- Đợi dialog hiện
        local npcGui = plr.PlayerGui.ScreenGui.NPC
        local waited = 0
        while not npcGui.Visible and waited < 3 do
            task.wait(0.2)
            waited = waited + 0.2
        end

        -- Đợi dialog đóng (auto skip ở RunService loop)
        if npcGui.Visible then
            local waited2 = 0
            while npcGui.Visible and waited2 < 10 do
                task.wait(0.2)
                waited2 = waited2 + 0.2
            end
            task.wait(0.5)
        end
    end

    log("OK: " .. npcName)
    return true
end

local function acceptAllQuests()
    local beeCount = countBees()
    log(">> Accept all quests | Bees: " .. beeCount)

    for _, info in ipairs(NPC_QUESTS) do
        if not running then return end

        if beeCount >= info.minBees then
            if npcHasAlert(info.name) then
                log("Alert ON: " .. info.name)
                talkNPC(info.name, info.pos)
                task.wait(1)
            else
                log("Skip " .. info.name .. " (no alert)")
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- 7. QUEST UI - đọc quest
-- ═══════════════════════════════════════════════════════════
local function openQuestTab()
    pcall(function()
        local sg = plr.PlayerGui:FindFirstChild("ScreenGui")
        if not sg then return end

        local menus = sg:FindFirstChild("Menus")
        if not menus then return end

        -- Force show parent frames
        if menus:IsA("GuiObject") then menus.Visible = true end

        local children = menus:FindFirstChild("Children")
        if children and children:IsA("GuiObject") then
            children.Visible = true
        end

        local questsFrame = children and children:FindFirstChild("Quests")
        if questsFrame and questsFrame:IsA("GuiObject") then
            questsFrame.Visible = true
        end

        local childTabs = menus:FindFirstChild("ChildTabs")
        if childTabs and childTabs:IsA("GuiObject") then
            childTabs.Visible = true
        end

        -- Click Quests Tab button
        local questTab = childTabs and childTabs:FindFirstChild("Quests Tab")
        if questTab then
            -- Method 1: Activate
            pcall(function() questTab:Activate() end)

            -- Method 2: VirtualInput click
            pcall(function()
                local pos = questTab.AbsolutePosition
                local size = questTab.AbsoluteSize
                local centerX = pos.X + size.X / 2
                local centerY = pos.Y + size.Y / 2
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
            end)

            -- Method 3: Fire connections
            pcall(function()
                if getconnections then
                    for _, conn in pairs(getconnections(questTab.MouseButton1Click)) do
                        conn:Fire()
                    end
                end
            end)
        end
    end)
    task.wait(1)
end

local function getQuestTasks()
    -- Mở quest UI trước
    openQuestTab()

    local beeCount = countBees()
    local tasks = {}

    -- Tạo danh sách NPC đủ điều kiện
    local allowedNPCs = {}
    for _, info in ipairs(NPC_QUESTS) do
        if beeCount >= info.minBees then
            allowedNPCs[info.name] = true
            -- Tên rút gọn để match title (VD: "Black Bear's Honey Wreath" -> match "Black")
            local short = info.name:gsub(" Bear", ""):gsub(" Bee", "")
            allowedNPCs[short] = true
        end
    end

    -- Đọc từ quest UI
    pcall(function()
        local QuestF = plr.PlayerGui.ScreenGui.Menus.Children.Quests.Content

        for _, frame in pairs(QuestF:GetDescendants()) do
            if frame:IsA("Frame") and frame.Name == "QuestBox" then
                local titleBar = frame:FindFirstChild("TitleBarBG")
                local titleLabel = titleBar and titleBar:FindFirstChild("TitleBar")

                if titleLabel then
                    local title = titleLabel.Text

                    -- Check NPC có trong danh sách allowed không
                    local isAllowed = false
                    for npcName in pairs(allowedNPCs) do
                        if title:find(npcName) then
                            isAllowed = true
                            break
                        end
                    end

                    if isAllowed then
                        local taskBar = frame:FindFirstChild("TaskBar")
                        if taskBar then
                            for _, desc in pairs(taskBar:GetChildren()) do
                                if desc:IsA("TextLabel") and desc.Name == "Description" and desc.Text ~= "" then
                                    table.insert(tasks, desc.Text)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    log("Found " .. #tasks .. " quest tasks")
    return tasks
end

local function getQuestFields()
    local tasks = getQuestTasks()
    local fields = {}
    local seen = {}

    for _, descText in ipairs(tasks) do
        local lower = descText:lower()

        -- Chỉ lấy task collect pollen
        if lower:find("collect") and lower:find("pollen") then
            for keyword, fieldName in pairs(FIELD_MAP) do
                if lower:find(keyword) and not seen[fieldName] then
                    seen[fieldName] = true
                    table.insert(fields, fieldName)
                    log("Quest field: " .. fieldName)
                end
            end
        end
    end

    return fields
end

-- ═══════════════════════════════════════════════════════════
-- 8. TOKEN DETECTION (giống source mẫu IsToken + IsValidTokenPos)
-- ═══════════════════════════════════════════════════════════
local function isToken(obj)
    if obj == nil then return false end
    if not obj.Parent then return false end
    if not obj:IsA("Part") then return false end
    if obj.Orientation.Z ~= 0 then return false end
    if not obj:FindFirstChild("FrontDecal") then return false end
    if obj.Name ~= "C" then return false end
    return true
end

-- Check token có nằm trong field không (giống source mẫu IsValidTokenPos)
local function isValidTokenPos(token, fieldName)
    local field = workspace.FlowerZones:FindFirstChild(fieldName)
    if not field then return false end

    local pos = typeof(token) == "Vector3" and token or token.Position
    local range = field:FindFirstChild("Range") and field.Range.Value or 60

    if (pos - field.Position).Magnitude < range then
        return math.abs(pos.Y - field.Position.Y)
    end
    return false
end

local function getNearbyTokens(fieldName, range)
    range = range or 60
    local list = {}
    local collectibles = workspace:FindFirstChild("Collectibles")
    if not collectibles then return list end

    for _, obj in pairs(collectibles:GetChildren()) do
        if isToken(obj) and isValidTokenPos(obj, fieldName) then
            table.insert(list, obj)
        end
    end
    return list
end

-- Collect tất cả token trong field (giống source mẫu CollectAllTokenInField)
local function collectAllTokensInField(fieldName)
    local collectibles = workspace:FindFirstChild("Collectibles")
    if not collectibles then return end

    for _, v in pairs(collectibles:GetChildren()) do
        if isToken(v) and isValidTokenPos(v, fieldName) then
            smartWalk(Vector3.new(v.Position.X, hrp.Position.Y, v.Position.Z))
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- 8.5 SPROUT DETECTION (giống source mẫu IsSprout)
-- ═══════════════════════════════════════════════════════════
local function isSprout()
    local particles = workspace:FindFirstChild("Particles")
    if not particles then return nil end
    local folder2 = particles:FindFirstChild("Folder2")
    if not folder2 then return nil end

    for _, v in pairs(folder2:GetChildren()) do
        if v.Name == "Sprout" then
            return v
        end
    end
    return nil
end

-- Tìm field gần sprout nhất
local function getFieldByObject(obj)
    if not obj or not obj:IsA("BasePart") then return nil end
    local nearest = nil
    local nearestDist = math.huge

    for _, field in pairs(workspace.FlowerZones:GetChildren()) do
        if field:IsA("BasePart") then
            local dist = (obj.Position - field.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = field.Name
            end
        end
    end
    return nearest
end

-- ═══════════════════════════════════════════════════════════
-- 9. MOB DETECTION & AVOID
-- ═══════════════════════════════════════════════════════════
local function getNearbyMobs(pos, range)
    local list = {}

    for _, folderName in ipairs({"Monsters", "FEMonsters"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, mob in pairs(folder:GetChildren()) do
                if mob:IsA("Model") then
                    local mobHum = mob:FindFirstChildOfClass("Humanoid")
                    local part = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")

                    if mobHum and mobHum.Health > 0 and part then
                        if (part.Position - pos).Magnitude < range then
                            table.insert(list, mob)
                        end
                    end
                end
            end
        end
    end
    return list
end

local function avoidMobs()
    local mobs = getNearbyMobs(hrp.Position, 35)
    if #mobs == 0 then return end

    log("⚠️ " .. #mobs .. " mobs nearby, jumping to avoid...")

    local startTime = tick()
    while #mobs > 0 and (tick() - startTime) < 30 and running do
        if hum then
            hum.Jump = true
        end
        task.wait(0.3)
        mobs = getNearbyMobs(hrp.Position, 35)
    end

    log("Mobs cleared")
end

-- ═══════════════════════════════════════════════════════════
-- 10. CHECK IN FIELD
-- ═══════════════════════════════════════════════════════════
local function isInField(field)
    if not hrp or not field then return false end

    local fp = field.Position
    local fs = field.Size
    local hp = hrp.Position

    return math.abs(hp.X - fp.X) < fs.X * 0.6
        and math.abs(hp.Z - fp.Z) < fs.Z * 0.6
        and math.abs(hp.Y - fp.Y) < 30
end

-- ═══════════════════════════════════════════════════════════
-- 11. SMART WALK nang
-- ═══════════════════════════════════════════════════════════
local function smartWalk(targetPos)
    if not hum or not hrp then refreshCharacter() end
    if not hum then return end

    hum.WalkSpeed = FARM_WALK_SPEED
    hum:MoveTo(targetPos)

    local stop = false
    local conn = hum.MoveToFinished:Connect(function()
        stop = true
    end)

    local startTime = tick()
    while not stop do
        task.wait(0.1)
        -- Timeout 5s -> teleport thẳng (giống source mẫu)
        if tick() - startTime >= 5 then
            hum:Move(Vector3.new(0, 0, 0))
            hrp.CFrame = CFrame.new(targetPos)
            stop = true
        end
    end

    if conn then conn:Disconnect() end
end

-- ═══════════════════════════════════════════════════════════
-- 12. SMART FARM FIELD
-- ═══════════════════════════════════════════════════════════
local function smartFarm(fieldName, duration)
    duration = duration or FARM_TIME
    log(">> Smart farm: " .. fieldName)

    local field = workspace.FlowerZones:FindFirstChild(fieldName)
    if not field then
        log("Field not found: " .. fieldName)
        return
    end

    local fieldPos = field.Position
    local fieldSize = field.Size
    local range = field:FindFirstChild("Range") and field.Range.Value or 60

    -- Teleport đến field
    tweenTo(CFrame.new(fieldPos.X, fieldPos.Y + 3, fieldPos.Z))
    task.wait(0.3)

    if hum then
        hum.WalkSpeed = FARM_WALK_SPEED
    end

    local stepX = math.min(fieldSize.X * 0.4, range)
    local stepZ = math.min(fieldSize.Z * 0.4, range)

    local startTime = tick()
    while (tick() - startTime) < duration and running do
        if not hrp or not hrp.Parent then refreshCharacter() end
        if not hrp then break end

        -- Check rơi khỏi field -> tp lại
        if not isInField(field) then
            log("Rơi khỏi field, tp lại...")
            tweenTo(CFrame.new(fieldPos.X, fieldPos.Y + 3, fieldPos.Z))
            task.wait(0.2)
            if hum then hum.WalkSpeed = FARM_WALK_SPEED end
        end

        -- Check mob -> avoid
        avoidMobs()

        -- Check sprout -> farm sprout nếu có
        local sprout = isSprout()
        if sprout then
            local sproutField = getFieldByObject(sprout)
            if sproutField then
                log("Sprout detected at " .. sproutField)
                tweenTo(CFrame.new(sprout.Position.X, sprout.Position.Y + 5, sprout.Position.Z))
                task.wait(0.5)
                local sproutStart = tick()
                while isSprout() and (tick() - sproutStart) < 60 and running do
                    collectAllTokensInField(sproutField)
                    fireEvent("ToolCollect")
                    task.wait(0.3)
                end
                -- Quay lại field chính
                tweenTo(CFrame.new(fieldPos.X, fieldPos.Y + 3, fieldPos.Z))
                task.wait(0.3)
            end
        end

        -- Collect tokens trong field (giống source mẫu)
        collectAllTokensInField(fieldName)

        -- Zigzag pattern + dig
        for row = -2, 2 do
            for col = -2, 2 do
                if (tick() - startTime) >= duration or not running then break end

                avoidMobs()

                local tx = fieldPos.X + (col * 0.5) * stepX
                local tz = fieldPos.Z + (row * 0.5) * stepZ
                smartWalk(Vector3.new(tx, fieldPos.Y + 3, tz))

                -- Dig mỗi step
                fireEvent("ToolCollect")
                task.wait(0.1)

                -- Re-check field
                if not isInField(field) then
                    tweenTo(CFrame.new(fieldPos.X, fieldPos.Y + 3, fieldPos.Z))
                    if hum then hum.WalkSpeed = FARM_WALK_SPEED end
                end

                -- Collect token gần
                collectAllTokensInField(fieldName)
            end
        end

        task.wait(0.1)
    end

    -- Reset speed
    if hum then
        hum.WalkSpeed = NORMAL_WALK_SPEED
    end

    log("Farm done: " .. fieldName)
end

-- ═══════════════════════════════════════════════════════════
-- 13. FARM QUEST FIELDS
-- ═══════════════════════════════════════════════════════════
local function farmQuestFields()
    local fields = getQuestFields()

    if #fields == 0 then
        log("No quest fields, default farm Dandelion")
        smartFarm("Dandelion Field", FARM_TIME)
        return
    end

    log("Farm " .. #fields .. " quest fields")

    for _, fieldName in ipairs(fields) do
        if not running then return end
        smartFarm(fieldName, FARM_TIME)
        task.wait(0.5)
    end
end

-- ═══════════════════════════════════════════════════════════
-- 14. CONVERT HONEY (đúng cách: PlayerHiveCommand ToggleHoneyMaking)
-- ═══════════════════════════════════════════════════════════
local function convertHoney()
    log(">> Convert honey")
    tweenTo(getHivePosition())
    task.wait(0.5)

    -- Bật convert
    fireEvent("PlayerHiveCommand", "ToggleHoneyMaking")
    task.wait(0.5)

    -- Đợi pollen = 0 (max 30s)
    local startTime = tick()
    while running and (tick() - startTime) < 30 do
        local pollen = plr:FindFirstChild("CoreStats") and plr.CoreStats:FindFirstChild("Pollen")
        if pollen and pollen.Value <= 0 then
            break
        end
        task.wait(0.5)
    end

    task.wait(1)
    log("Convert done")
end

-- ═══════════════════════════════════════════════════════════
-- MAIN PIPELINE (5 Phases)
-- ═══════════════════════════════════════════════════════════
log("========== KAITUN v6 START ==========")
task.wait(2)

-- Setup ban đầu
log("=== SETUP ===")
for attempt = 1, 3 do
    if claimHive() then break end
    task.wait(2)
end
task.wait(1)

if running then
    redeemCodes()
    task.wait(1)
end

-- Helper: farm + accept quest cho đến khi đạt target bees
local function farmUntilBees(targetBees)
    while countBees() < targetBees and running do
        -- Accept quests có alert
        acceptAllQuests()
        task.wait(1)

        -- Farm theo quest field
        farmQuestFields()
        task.wait(0.5)

        -- Convert
        convertHoney()
        task.wait(0.5)

        -- Buy basic egg + hatch
        local emptySlots = countEmptySlots()
        if emptySlots > 0 then
            buyBasicEgg(math.min(emptySlots, 3))  -- mua tối đa 3 quả mỗi vòng
            task.wait(0.5)
            hatchAllEggs()
            task.wait(0.5)
        end

        log("=== Bees: " .. countBees() .. "/" .. targetBees .. " ===")
    end
end

-- ─── Phase 1: 0→5 bees ───
if running then
    log("=== PHASE 1: 0→5 bees ===")
    phase1_buy()  -- Clippers + Scissors trước khi mua egg
    task.wait(1)
    farmUntilBees(5)
end

-- ─── Phase 2: 5→10 bees ───
if running then
    log("=== PHASE 2: 5→10 bees ===")
    phase2_buy()  -- Canister + Vacuum + Boots/Belt/Helmet
    task.wait(1)
    farmUntilBees(10)
end

-- ─── Phase 3: 10→15 bees ───
if running then
    log("=== PHASE 3: 10→15 bees ===")
    phase3_buy()  -- Compressor + Pulsar
    task.wait(1)
    farmUntilBees(15)
end

-- ─── Phase 4: 15→20 bees ───
if running then
    log("=== PHASE 4: 15→20 bees ===")
    phase4_buy()  -- Port-O-Hive
    task.wait(1)
    farmUntilBees(20)
end

-- ─── Phase 5: 20→25 bees + Royal Jelly ───
if running then
    log("=== PHASE 5: 20→25 bees ===")
    phase5_buy()  -- Propeller Hat (nếu đủ)
    task.wait(1)

    -- Reroll Blue bees với Royal Jelly
    rerollBasicToBlue()
    task.wait(1)

    farmUntilBees(25)
end

log("========== KAITUN COMPLETE: " .. countBees() .. " bees ==========")
