print("[Kaitun] ===== SCRIPT LOADED =====")
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
    -- ✅ Improve: retry 3 lần nếu fail (lag mạng)
    for attempt = 1, 3 do
        local ok, err = pcall(r.FireServer, r, ...)
        if ok then return true end
        warn("[Kaitun] Fire error " .. name .. " (attempt " .. attempt .. "): " .. tostring(err))
        if attempt < 3 then task.wait(0.5) end
    end
    return false
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
    tryBuy("Collector", "Scissors", SHOPS.Basic)  -- ✅ Fix: Scissors ở Basic shop, không phải Pro
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
-- List Blue bee mục tiêu khi reroll
local TARGET_BLUE_BEES = {
    BumbleBee = true, CoolBee = true, BubbleBee = true,
    BuckoBee = true,  FrostyBee = true, DiamondBee = true,
    NinjaBee = true,  BuoyantBee = true, TadpoleBee = true,
}
local REROLL_TARGETS = { BasicBee = true, BraveBee = true }

local function isBlueBee(beeType)
    return TARGET_BLUE_BEES[beeType] == true
end

-- Tìm cell Basic/Brave để reroll (bảo vệ Gifted)
local function findCellToReroll()
    local hive = getMyHive()
    if not hive or not hive:FindFirstChild("Cells") then return nil end
    for _, cell in pairs(hive.Cells:GetChildren()) do
        local ct     = cell:FindFirstChild("CellType")
        local locked = cell:FindFirstChild("CellLocked")
        local gifted = cell:FindFirstChild("CellGifted")
        if ct and (locked == nil or not locked.Value) and REROLL_TARGETS[ct.Value] then
            if gifted and gifted.Value == true then
                log("Skip Gifted " .. ct.Value)
                continue
            end
            local cx = cell:FindFirstChild("CellX")
            local cy = cell:FindFirstChild("CellY")
            if cx and cy then
                return {x = cx.Value, y = cy.Value, cell = cell, original = ct.Value}
            end
        end
    end
    return nil
end

-- Reroll 1 cell đến khi ra Blue bee
local function rerollCellToBlue(cellInfo, maxAttempts)
    maxAttempts = maxAttempts or 100
    log(">> Reroll C" .. cellInfo.x .. "," .. cellInfo.y .. " (" .. cellInfo.original .. ") → Blue")
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

-- ═══════════════════════════════════════════════════════════
-- EGG COUNT + HATCH
-- ═══════════════════════════════════════════════════════════
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

-- ✅ NEW: Đếm số Basic Egg đang có trong inventory
local function countBasicEggs()
    -- BSS lưu egg count trong DataFolder hoặc Inventory
    local paths = {
        function() return plr.DataFolder.Inventory.BasicEgg.Value end,
        function() return plr.PlayerData.Inventory.BasicEgg.Value end,
        function() return plr.Inventory.BasicEgg.Value end,
        function() return plr.CoreStats.BasicEgg.Value end,
        function() return plr.Stats.BasicEgg.Value end,
    }
    for _, getter in ipairs(paths) do
        local ok, val = pcall(getter)
        if ok and type(val) == "number" then
            return math.floor(val)
        end
    end
    -- Fallback: không đọc được → trả về nil (hatchAllEggs sẽ dùng result từ server)
    return nil
end

local function hatchAllEggs()
    log(">> Hatch ALL eggs")
    tweenTo(getHivePosition())
    task.wait(1)

    local remote = Events:FindFirstChild("ConstructHiveCellFromEgg")
    if not remote then log("FAIL: ConstructHiveCellFromEgg not found") return 0 end

    -- ✅ Fix: check inventory trước để biết tối đa bao nhiêu lần cần hatch
    local eggCount = countBasicEggs()
    local emptySlots = countEmptySlots()

    if eggCount ~= nil then
        log(string.format("Inv: %d Basic Egg(s) | Empty slots: %d", eggCount, emptySlots))
        if eggCount == 0 then
            log("No eggs in inventory")
            return 0
        end
    else
        log(string.format("Empty slots: %d (egg count unknown, rely on server)", emptySlots))
    end

    -- Số lần hatch tối đa = min(egg, slot) nếu biết egg count
    local maxHatch = eggCount ~= nil and math.min(eggCount, emptySlots) or emptySlots

    -- ✅ Fix: track slot đã dùng trong session này để không pick lại cùng 1 slot
    local usedSlots = {}

    local function getNextEmptySlot()
        local hive = getMyHive()
        if not hive or not hive:FindFirstChild("Cells") then return nil, nil end
        for _, cell in pairs(hive.Cells:GetChildren()) do
            local ct = cell:FindFirstChild("CellType")
            local cellX = cell:FindFirstChild("CellX")
            local cellY = cell:FindFirstChild("CellY")
            if ct and cellX and cellY then
                local key = cellX.Value .. "," .. cellY.Value
                if (ct.Value == "Empty" or ct.Value == "") and not usedSlots[key] then
                    return cellX.Value, cellY.Value, key
                end
            end
        end
        return nil, nil, nil
    end

    local hatched = 0
    for i = 1, maxHatch do
        if not running then break end

        local x, y, key = getNextEmptySlot()
        if not x then
            log("No empty slot left")
            break
        end

        -- Đánh dấu slot này đã dùng NGAY để lần sau không pick lại
        usedSlots[key] = true

        local ok, result = pcall(function()
            return remote:InvokeServer(x, y, "Basic", 1, false)
        end)
        task.wait(0.8)

        if ok and result then
            hatched = hatched + 1
            log(string.format("Hatched #%d C%s,%s", hatched, x, y))
        else
            -- Server báo fail = hết egg
            log("No more eggs (server) at C" .. x .. "," .. y)
            break
        end
    end

    log("Hatch done: " .. hatched .. "/" .. (eggCount or "?"))
    return hatched
end

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
        return true  -- ✅ Fix: trả về true thay vì số (0 = falsy bug)
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

-- ═══════════════════════════════════════════════════════════
-- 11. SMART WALK
-- ═══════════════════════════════════════════════════════════
local function smartWalk(targetPos)
    if not hum or not hrp then refreshCharacter() end
    if not hum then return end

    hum.WalkSpeed = FARM_WALK_SPEED

    -- ✅ Fix race condition: connect TRƯỚC khi MoveTo
    local stop = false
    local conn = hum.MoveToFinished:Connect(function()
        stop = true
    end)

    hum:MoveTo(targetPos)

    local startTime = tick()
    while not stop do
        task.wait(0.1)
        -- Timeout 5s -> teleport thẳng
        if tick() - startTime >= 5 then
            hum:Move(Vector3.new(0, 0, 0))
            hrp.CFrame = CFrame.new(targetPos)
            stop = true
        end
    end

    conn:Disconnect()
end

-- Collect tất cả token trong field (giống source mẫu CollectAllTokenInField)
local function collectAllTokensInField(fieldName)
    local collectibles = workspace:FindFirstChild("Collectibles")
    if not collectibles then return end

    -- ✅ Fix: snapshot list trước, check v.Parent trước khi dùng (tránh lỗi khi token bị destroy)
    local tokens = collectibles:GetChildren()
    for _, v in pairs(tokens) do
        if v.Parent and isToken(v) and isValidTokenPos(v, fieldName) then
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

    log("⚠️ " .. #mobs .. " mobs nearby, spam jump until dead...")

    -- Spam jump đến khi bees kill hết mob (Health <= 0 bị filter bởi getNearbyMobs)
    -- Timeout 30s làm safety net phòng mob quá trâu
    local startTime = tick()
    while #mobs > 0 and (tick() - startTime) < 30 and running do
        -- Jump để dodge damage
        if hum then
            hum.Jump = true
        end
        -- Exploit jump fallback (nếu có)
        pcall(function()
            local uis = game:GetService("UserInputService")
            for _, conn in pairs(getconnections(uis.JumpRequest)) do
                conn:Fire()
            end
        end)
        task.wait(0.3)
        -- getNearbyMobs chỉ lấy mob còn Health > 0
        -- → khi bees kill xong thì #mobs = 0, thoát loop
        mobs = getNearbyMobs(hrp.Position, 35)
    end

    if #mobs == 0 then
        log("Mobs killed, resume farming")
    else
        log("Mob timeout (30s), resume anyway")
    end
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

-- (smartWalk đã được định nghĩa phía trên, trước collectAllTokensInField)

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
-- 14. STATS HELPER
-- ═══════════════════════════════════════════════════════════
local function getStats()
    local cs = plr:FindFirstChild("CoreStats")
    if not cs then return 0, 0, 0 end
    local honey  = cs:FindFirstChild("Honey")  and cs.Honey.Value  or 0
    local pollen = cs:FindFirstChild("Pollen") and cs.Pollen.Value or 0
    local honey2 = cs:FindFirstChild("Honey2") and cs.Honey2.Value or 0  -- royal honey
    return honey, pollen, honey2
end

-- ═══════════════════════════════════════════════════════════
-- 15. CONVERT HONEY (smart: chỉ convert khi đủ pollen)
-- ═══════════════════════════════════════════════════════════
local MIN_POLLEN_TO_CONVERT = 500  -- ✅ Improve: không convert trip vô ích khi pollen ít

local function convertHoney()
    local _, pollen, _ = getStats()
    if pollen < MIN_POLLEN_TO_CONVERT then
        log("Skip convert (pollen: " .. pollen .. " < " .. MIN_POLLEN_TO_CONVERT .. ")")
        return
    end

    log(">> Convert honey (pollen: " .. pollen .. ")")

    -- Buoc 1: tp den hive (theo NormalSell cua source mau)
    tweenTo(getHivePosition())
    task.wait(0.3)

    -- Buoc 2: ToggleHoneyMaking lan 1 de bat dau convert
    local hiveEvent = game:GetService("ReplicatedStorage").Events:FindFirstChild("PlayerHiveCommand")
    if not hiveEvent then
        log("FAIL: PlayerHiveCommand not found")
        return
    end
    hiveEvent:FireServer("ToggleHoneyMaking")
    task.wait(0.5)

    -- Buoc 3: Check UI button va re-fire neu can (theo NormalSell)
    -- Neu ActivateButton chua o trang thai dung -> fire them
    pcall(function()
        local tpos = plr.PlayerGui.ScreenGui:FindFirstChild("ActivateButton")
        if tpos and tpos.AbsolutePosition.Y == 4 then
            -- Da dung trang thai, khong can fire them
        else
            hiveEvent:FireServer("ToggleHoneyMaking")
            task.wait(0.3)
        end
    end)

    -- Buoc 4: Doi pollen = 0 (max 60s, theo source mau dung repeat until)
    local startTime = tick()
    repeat
        task.wait(0.5)
        local cs = plr:FindFirstChild("CoreStats")
        local p = cs and cs:FindFirstChild("Pollen")
        if p and p.Value <= 0 then break end

        -- Neu bi stuck (hive chua bat) -> retry fire
        if (tick() - startTime) > 5 then
            pcall(function()
                local tpos = plr.PlayerGui.ScreenGui:FindFirstChild("ActivateButton")
                if tpos then
                    local txt = tpos:FindFirstChild("TextBox")
                    if txt and not string.find(txt.Text or "", "Stop") then
                        hiveEvent:FireServer("ToggleHoneyMaking")
                        tweenTo(getHivePosition())
                        task.wait(0.5)
                    end
                end
            end)
        end
    until not running or (tick() - startTime) >= 60

    task.wait(1)
    local honey, _, _ = getStats()
    log("Convert done | Honey: " .. honey)
end

-- ═══════════════════════════════════════════════════════════
-- 16. TOKEN PRIORITY COLLECT
-- ═══════════════════════════════════════════════════════════
-- Thứ tự ưu tiên collect token (tên FrontDecal texture / item)
local TOKEN_PRIORITY = {
    ["RoyalJelly"]  = 1,
    ["Glue"]        = 2,
    ["MoonCharm"]   = 3,
    ["Tropical"]    = 4,  -- Tropical drink
    ["Gumdrops"]    = 5,
}

local function getTokenPriority(token)
    -- Dùng tên hoặc FrontDecal texture để phân loại
    local decal = token:FindFirstChild("FrontDecal")
    if decal then
        for key, pri in pairs(TOKEN_PRIORITY) do
            if decal.Texture:find(key) then return pri end
        end
    end
    return 99  -- pollen thường = thấp nhất
end

local function collectPriorityTokensInField(fieldName)
    local collectibles = workspace:FindFirstChild("Collectibles")
    if not collectibles then return end

    -- Lấy tất cả token hợp lệ trong field
    local tokens = {}
    for _, v in pairs(collectibles:GetChildren()) do
        if v.Parent and isToken(v) and isValidTokenPos(v, fieldName) then
            table.insert(tokens, v)
        end
    end

    -- ✅ Improve: sort theo priority (RJ > Glue > Moon Charm > pollen)
    table.sort(tokens, function(a, b)
        return getTokenPriority(a) < getTokenPriority(b)
    end)

    for _, v in pairs(tokens) do
        if v.Parent then
            smartWalk(Vector3.new(v.Position.X, hrp.Position.Y, v.Position.Z))
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- HELPER: FARM LOOP
-- ═══════════════════════════════════════════════════════════

-- Farm + accept quest + hatch cho đến khi đạt target bees
local function farmUntilBees(targetBees)
    while countBees() < targetBees and running do
        local bees = countBees()
        local honey, pollen, _ = getStats()
        -- ✅ Improve: log stats mỗi loop để dễ theo dõi
        log(string.format("=== Bees: %d/%d | Honey: %d | Pollen: %d ===", bees, targetBees, honey, pollen))

        -- Accept quests có alert
        acceptAllQuests()
        task.wait(1)
        if not running then break end

        -- Farm theo quest field
        farmQuestFields()
        task.wait(0.5)
        if not running then break end

        -- Convert (smart: chỉ convert khi pollen đủ ngưỡng)
        convertHoney()
        task.wait(0.5)
        if not running then break end

        -- Chỉ mua egg nếu vẫn chưa đủ bees
        -- ✅ Fix: codes đã nhập từ đầu, không nhập lại ở đây
        if countBees() < targetBees then
            local emptySlots = countEmptySlots()
            if emptySlots > 0 then
                -- Mua egg trước, hatch sau (sequential - đảm bảo thứ tự)
                buyBasicEgg(math.min(emptySlots, 3))
                task.wait(0.5)
                hatchAllEggs()
                task.wait(0.5)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- MAIN PIPELINE (5 Phases)
-- ═══════════════════════════════════════════════════════════
log("========== KAITUN v6 START ==========")
task.wait(2)

-- Setup ban đầu
log("=== SETUP ===")

-- Claim hive trước
for attempt = 1, 3 do
    if claimHive() then break end
    task.wait(2)
end
task.wait(1)

-- ✅ Hatch ngay Basic Egg miễn phí được tặng khi claim hive
-- (game tặng 1 Basic Egg lúc claim → hatch ngay để có bee sớm nhất)
if running then
    log(">> Hatch starter egg từ claim hive")
    hatchAllEggs()
    task.wait(1)
end

-- Redeem codes SAU hatch starter egg
if running then
    redeemCodes()
    task.wait(1)
end

-- ─── Phase 1: 0→5 bees ───
if running then
    local cur = countBees()
    log("=== PHASE 1: 0→5 bees === (current: " .. cur .. ")")

    if cur < 5 then
        -- ✅ Improve: ưu tiên mua egg + hatch TRƯỚC, tools mua SAU
        -- Lý do: cần bee vào hive sớm để bắt đầu farm pollen, tools có thể chờ

        -- Bước 1: mua đủ egg để fill slot trống (tối đa 5 egg cho phase 1)
        local emptySlots = countEmptySlots()
        local eggsNeeded = math.max(0, 5 - cur)  -- cần thêm bao nhiêu bee nữa
        local buyCount   = math.min(eggsNeeded, emptySlots)

        if buyCount > 0 then
            log("Bước 1: Mua " .. buyCount .. " egg(s) trước khi mua tools")
            buyBasicEgg(buyCount)
            task.wait(0.5)
        end

        -- Bước 2: hatch nếu có egg trong inv HOẶC có slot trống sau khi mua
        local eggCount = countBasicEggs()
        local hasEggs  = (eggCount ~= nil and eggCount > 0)  -- ✅ Fix: tránh nil ~= 0 = true
                      or (eggCount == nil and countEmptySlots() > 0)  -- fallback: không đọc được inv thì dựa vào slot
        if hasEggs then
            hatchAllEggs()
            task.wait(1)
        else
            log("Bước 2: Không có egg để hatch, bỏ qua")
        end

        -- Bước 3: SAU KHI có bee mới mua tools early
        if countBees() > 0 then
            log("Bước 3: Mua tools early (Clippers + Scissors)")
            phase1_buy()
            task.wait(1)
        end
    end

    -- Tiếp tục farm cho đến đủ 5 bees
    farmUntilBees(5)
end

-- ─── Phase 2: 5→10 bees ───
if running then
    local cur = countBees()
    log("=== PHASE 2: 5→10 bees === (current: " .. cur .. ")")
    if cur < 10 then
        phase2_buy()
        task.wait(1)
    end
    farmUntilBees(10)
end

-- ─── Phase 3: 10→15 bees ───
if running then
    local cur = countBees()
    log("=== PHASE 3: 10→15 bees === (current: " .. cur .. ")")
    if cur < 15 then
        phase3_buy()
        task.wait(1)
    end
    farmUntilBees(15)
end

-- ─── Phase 4: 15→20 bees ───
if running then
    local cur = countBees()
    log("=== PHASE 4: 15→20 bees === (current: " .. cur .. ")")
    if cur < 20 then
        phase4_buy()
        task.wait(1)
    end
    farmUntilBees(20)
end

-- ─── Phase 5: 20→25 bees + Royal Jelly ───
if running then
    local cur = countBees()
    log("=== PHASE 5: 20→25 bees === (current: " .. cur .. ")")
    if cur < 25 then
        phase5_buy()
        task.wait(1)
    end

    -- Farm đến 25 bees trước
    farmUntilBees(25)

    -- Reroll SAU KHI đã đủ 25 bees (hive đầy mới reroll có ý nghĩa)
    task.wait(1)
    rerollBasicToBlue()
end

log("========== KAITUN COMPLETE: " .. countBees() .. " bees ==========")

-- ═══════════════════════════════════════════════════════════
-- NIGHT: COLLECT FIREFLIES
-- ═══════════════════════════════════════════════════════════
local Lighting = game:GetService("Lighting")

-- Kiểm tra có đang ban đêm không (ClockTime: 19:00 → 06:00)
local function isNight()
    local t = Lighting.ClockTime  -- range 0..24
    return t >= 19 or t < 6
end

-- Tìm tất cả Firefly trong workspace
local function getFireflies()
    local list = {}
    -- BSS lưu firefly trong workspace trực tiếp hoặc trong folder
    local folders = {
        workspace:FindFirstChild("Fireflies"),
        workspace:FindFirstChild("Particles"),
        workspace,
    }
    for _, folder in ipairs(folders) do
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                -- Firefly là Part hoặc Model tên "Firefly"
                if obj.Name == "Firefly" and obj.Parent then
                    local part = obj:IsA("BasePart") and obj
                        or obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        table.insert(list, {obj = obj, part = part})
                    end
                end
            end
        end
    end
    return list
end

-- Collect fireflies: đi đến từng con, sort theo distance để tối ưu path
local function collectFireflies()
    if not isNight() then
        log(string.format("[Firefly] Skip - not night (ClockTime: %.1f)", Lighting.ClockTime))
        return
    end

    local flies = getFireflies()
    if #flies == 0 then
        log("[Firefly] No fireflies found")
        return
    end

    log("[Firefly] Found " .. #flies .. " fireflies, collecting...")

    -- Sort theo distance từ char hiện tại (nearest first)
    table.sort(flies, function(a, b)
        local da = (a.part.Position - hrp.Position).Magnitude
        local db = (b.part.Position - hrp.Position).Magnitude
        return da < db
    end)

    local collected = 0
    for _, entry in ipairs(flies) do
        if not running then break end
        -- Check còn tồn tại không (có thể bị collect bởi script trước)
        if not entry.obj.Parent then continue end
        if not isNight() then
            log("[Firefly] Daytime - stop collecting")
            break
        end

        -- ✅ Fix: Tween đến đúng Y của firefly (bay trên không)
        local tp = entry.part.Position
        -- Tween nhanh đến gần firefly
        tweenTo(CFrame.new(tp.X, tp.Y, tp.Z), TWEEN_SPEED)
        task.wait(0.1)
        -- Teleport thẳng vào để trigger collect (touch detection)
        if entry.obj.Parent then
            hrp.CFrame = CFrame.new(tp.X, tp.Y, tp.Z)
            task.wait(0.15)
        end
        collected = collected + 1
    end

    log("[Firefly] Collected " .. collected)
end

-- ═══════════════════════════════════════════════════════════
-- SPARKLES COLLECTOR
-- Cơ chế: workspace.Flowers có flower nào mang child "Sparkles"
-- → teleport vào flower đó → Dig → collect tokens xung quanh
-- ═══════════════════════════════════════════════════════════

-- Tìm flower gần nhất đang có Sparkles (chưa bị đánh dấu Ignored)
local function getNearestSparklesFlower()
    local flowers = workspace:FindFirstChild("Flowers")
    if not flowers then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, v in pairs(flowers:GetChildren()) do
        if v:IsA("BasePart")
        and v:FindFirstChild("Sparkles")
        and not v:FindFirstChild("_KaitunIgnored") then
            local dist = (v.Position - hrp.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = v
            end
        end
    end
    return nearest
end

-- Thu hoạch tất cả Sparkles flowers hiện tại
local function farmSparkles()
    if not hrp then return end

    local count = 0
    -- Loop lấy từng flower có Sparkles
    while running do
        local flower = getNearestSparklesFlower()
        if not flower then break end

        log("[Sparkles] Found flower at " .. tostring(flower.Position))

        -- Bước 1: Teleport thẳng đến flower
        tweenTo(CFrame.new(flower.Position), 200)
        task.wait(0.3)
        hrp.CFrame = CFrame.new(flower.Position)
        task.wait(0.3)

        -- Bước 2: Dig để collect sparkle
        fireEvent("ToolCollect")
        task.wait(0.3)
        fireEvent("ToolCollect")
        task.wait(0.3)

        -- Bước 3: Đánh dấu đã xử lý (tránh loop lại)
        pcall(function()
            local tag = Instance.new("BoolValue")
            tag.Name = "_KaitunIgnored"
            tag.Parent = flower
            game:GetService("Debris"):AddItem(tag, 10)  -- tự xóa sau 10s
        end)

        -- Bước 4: Collect tokens xung quanh radius 20
        local collectibles = workspace:FindFirstChild("Collectibles")
        if collectibles then
            for _, token in pairs(collectibles:GetChildren()) do
                if token.Parent
                and isToken(token)
                and (token.Position - hrp.Position).Magnitude < 20 then
                    smartWalk(Vector3.new(
                        token.Position.X,
                        hrp.Position.Y,
                        token.Position.Z
                    ))
                end
            end
        end

        count = count + 1
        task.wait(0.2)
    end

    if count > 0 then
        log("[Sparkles] Done - collected from " .. count .. " flowers")
    end
end

-- ═══════════════════════════════════════════════════════════
-- ✅ Improve: PERSISTENT LOOP - tiếp tục farm vô hạn sau khi đủ 25 bees
-- ═══════════════════════════════════════════════════════════
log("=== ENTERING PERSISTENT FARM LOOP ===")
while running do
    local honey, pollen, _ = getStats()
    local bees = countBees()
    log(string.format("[Loop] Bees: %d | Honey: %d | Pollen: %d | Night: %s",
        bees, honey, pollen, tostring(isNight())))

    -- Nếu ban đêm → ưu tiên collect fireflies trước
    if isNight() then
        collectFireflies()
        task.wait(0.5)
    end

    -- Thu hoạch Sparkles flowers nếu có
    farmSparkles()
    task.wait(0.5)

    -- Accept quest nếu có alert
    acceptAllQuests()
    task.wait(1)

    -- Farm quest fields
    farmQuestFields()
    task.wait(0.5)

    -- Convert khi đủ pollen
    convertHoney()
    task.wait(0.5)

    -- Reroll bất kỳ Basic/Brave còn sót
    rerollBasicToBlue()
    task.wait(0.5)
end

