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
-- TWEEN (di chuyển xa)
-- ═══════════════════════════════════════════════════════════
local function tweenTo(targetCFrame, speed)
    speed = speed or TWEEN_SPEED
    if not hrp or not hrp.Parent then refreshCharacter() end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance < 4 then
        hrp.CFrame = targetCFrame
        return
    end

    local tweenTime = distance / speed
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
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
    if not hive then return nil end

    for _, cell in pairs(hive.Cells:GetChildren()) do
        local cellType = cell:FindFirstChild("CellType")
        if cellType and (cellType.Value == "Empty" or cellType.Value == "") then
            local cellID = cell:FindFirstChild("CellID")
            if cellID then
                return cellID.Value
            end
        end
    end
    return nil
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

    tweenTo(CFrame.new(4, 7, 345))
    task.wait(1)

    for _, hive in pairs(workspace.Honeycombs:GetChildren()) do
        if hive:IsA("Model") and hive:FindFirstChild("Owner") and hive.Owner.Value == nil then
            local hiveID = hive:FindFirstChild("HiveID")
            if hiveID then
                fireEvent("ClaimHive", hiveID.Value)
                task.wait(2)

                if hive.Owner.Value == plr then
                    log("Claimed hive " .. hiveID.Value)
                    return true
                end
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

local function buyAccessoriesByMilestone(beeCount)
    log(">> Buy accessories (bees=" .. beeCount .. ")")

    -- Tween đến BasicShop
    tweenTo(CFrame.new(96, 12, 318))
    task.wait(1)

    if beeCount < 5 then
        -- Đầu game: tools cơ bản
        buyItem("Collector", "Scooper")
        task.wait(0.4)
        buyItem("Collector", "Clippers")
        task.wait(0.4)
        buyItem("Collector", "Magnet")
        task.wait(0.4)
        buyItem("Accessory", "Pouch")
        task.wait(0.4)
    elseif beeCount < 10 then
        -- 5-10 bees
        buyItem("Accessory", "Jar")
        task.wait(0.4)
        buyItem("Accessory", "Helmet")
        task.wait(0.4)
        buyItem("Accessory", "Belt Pocket")
        task.wait(0.4)
        buyItem("Accessory", "Basic Boots")
        task.wait(0.4)
    elseif beeCount < 15 then
        -- 10-15 bees
        buyItem("Accessory", "Canister")
        task.wait(0.4)
        buyItem("Collector", "Rake")
        task.wait(0.4)
        buyItem("Collector", "Vacuum")
        task.wait(0.4)
        buyItem("Accessory", "Backpack")
        task.wait(0.4)
    end

    log("Accessories done")
end

-- ═══════════════════════════════════════════════════════════
-- 4. BUY EGG + HATCH
-- ═══════════════════════════════════════════════════════════
local function buyBasicEgg()
    log(">> Buy Basic Egg")
    tweenTo(CFrame.new(-146, 13, 231))
    task.wait(1)
    buyItem("Eggs", "Basic", 1)
    task.wait(0.5)
end

local function hatchEgg()
    log(">> Hatch Egg (tween về hive)")

    -- Tween đến hive trước
    tweenTo(getHivePosition())
    task.wait(1)

    local hive = getMyHive()
    if not hive then
        log("FAIL: no hive")
        return false
    end

    local hiveID = hive.HiveID.Value
    local slot = getEmptyHiveSlot()

    if not slot then
        log("FAIL: no empty slot")
        return false
    end

    log("Hatch hive=" .. hiveID .. " slot=" .. slot)
    local result = invokeEvent("ConstructHiveCellFromEgg", hiveID, slot, "Basic", 1, false)
    task.wait(1)

    log("Hatch result: " .. tostring(result ~= nil))
    return result ~= nil
end

-- Hatch tất cả egg đang có (loop đến khi không hatch được nữa)
local function hatchAllEggs()
    log(">> Hatch ALL eggs")

    -- Tween về hive 1 lần
    tweenTo(getHivePosition())
    task.wait(1)

    local maxAttempts = 50
    local hatched = 0

    for i = 1, maxAttempts do
        if not running then return hatched end

        local hive = getMyHive()
        if not hive then break end

        local slot = getEmptyHiveSlot()
        if not slot then
            log("Hết slot trống")
            break
        end

        local hiveID = hive.HiveID.Value
        local result = invokeEvent("ConstructHiveCellFromEgg", hiveID, slot, "Basic", 1, false)
        task.wait(0.8)

        if result then
            hatched = hatched + 1
            log("Hatched #" .. hatched)
        else
            log("Hết egg hoặc fail, dừng hatch")
            break
        end
    end

    log("Hatch all done: " .. hatched .. " eggs")
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
-- 8. TOKEN DETECTION
-- ═══════════════════════════════════════════════════════════
local function isToken(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    if obj.Orientation.Z ~= 0 then return false end
    if not obj:FindFirstChild("FrontDecal") then return false end
    return true
end

local function getNearbyTokens(pos, range)
    local list = {}
    local collectibles = workspace:FindFirstChild("Collectibles")
    if not collectibles then return list end

    for _, obj in pairs(collectibles:GetChildren()) do
        if isToken(obj) and (obj.Position - pos).Magnitude < range then
            table.insert(list, obj)
        end
    end
    return list
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
-- 11. SMART WALK
-- ═══════════════════════════════════════════════════════════
local function smartWalk(targetPos)
    if not hum or not hrp then refreshCharacter() end
    if not hum then return end

    hum.WalkSpeed = FARM_WALK_SPEED
    hum:MoveTo(targetPos)

    local arrived = false
    local conn = hum.MoveToFinished:Connect(function()
        arrived = true
    end)

    local startTime = tick()
    while not arrived and (tick() - startTime) < 5 do
        task.wait(0.1)
        if (hrp.Position - targetPos).Magnitude < 5 then
            arrived = true
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

    -- Tween đến center field
    tweenTo(CFrame.new(fieldPos.X, fieldPos.Y + 3, fieldPos.Z))
    task.wait(0.3)

    if hum then
        hum.WalkSpeed = FARM_WALK_SPEED
    end

    local stepX = math.min(fieldSize.X * 0.4, range)
    local stepZ = math.min(fieldSize.Z * 0.4, range)

    local startTime = tick()
    while (tick() - startTime) < duration and running do
        -- Check rơi khỏi field -> tween lại
        if not isInField(field) then
            log("Rơi khỏi field, tween lại...")
            tweenTo(CFrame.new(fieldPos.X, fieldPos.Y + 3, fieldPos.Z))
            task.wait(0.2)
            if hum then hum.WalkSpeed = FARM_WALK_SPEED end
        end

        -- Check mob -> avoid
        avoidMobs()

        -- Auto collect tokens trong range
        local tokens = getNearbyTokens(hrp.Position, range)
        for _, tok in ipairs(tokens) do
            if not running then break end
            if tok.Parent and (tok.Position - hrp.Position).Magnitude < range then
                smartWalk(tok.Position + Vector3.new(0, 1, 0))
                if not isInField(field) then break end
            end
        end

        -- Zigzag pattern
        for row = -2, 2 do
            for col = -2, 2 do
                if (tick() - startTime) >= duration or not running then break end

                avoidMobs()

                local tx = fieldPos.X + (col * 0.5) * stepX
                local tz = fieldPos.Z + (row * 0.5) * stepZ
                smartWalk(Vector3.new(tx, fieldPos.Y + 3, tz))

                -- Re-check field
                if not isInField(field) then
                    tweenTo(CFrame.new(fieldPos.X, fieldPos.Y + 3, fieldPos.Z))
                    if hum then hum.WalkSpeed = FARM_WALK_SPEED end
                end

                -- Collect token gần khi đi
                local collectibles = workspace:FindFirstChild("Collectibles")
                if collectibles then
                    for _, tok in pairs(collectibles:GetChildren()) do
                        if isToken(tok) and (tok.Position - hrp.Position).Magnitude < 20 then
                            smartWalk(tok.Position + Vector3.new(0, 1, 0))
                        end
                    end
                end
            end
        end
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
-- 14. CONVERT HONEY
-- ═══════════════════════════════════════════════════════════
local function convertHoney()
    log(">> Convert honey")
    tweenTo(getHivePosition())
    task.wait(6)
    log("Convert done")
end

-- ═══════════════════════════════════════════════════════════
-- MAIN PIPELINE
-- ═══════════════════════════════════════════════════════════
log("========== KAITUN v5 START ==========")
task.wait(2)

-- ─── Phase 1: Setup ───
log("=== PHASE 1: SETUP ===")

-- Claim hive (3 retries)
for attempt = 1, 3 do
    if claimHive() then break end
    task.wait(2)
end
task.wait(1)

-- Redeem codes
if running then
    redeemCodes()
    task.wait(1)
end

-- Buy initial accessories
if running then
    buyAccessoriesByMilestone(countBees())
    task.wait(1)
end

-- ─── Phase 2: Main Loop ───
log("=== PHASE 2: MAIN LOOP ===")

while countBees() < TARGET_BEES and running do
    -- Accept quests từ NPC có alert
    acceptAllQuests()
    task.wait(1)

    -- Farm theo quest field
    farmQuestFields()
    task.wait(0.5)

    -- Convert honey
    convertHoney()
    task.wait(0.5)

    -- Buy egg + hatch
    buyBasicEgg()
    task.wait(0.5)
    hatchAllEggs() -- hatch hết egg đang có
    task.wait(0.5)

    -- Buy accessories milestone tiếp theo
    buyAccessoriesByMilestone(countBees())
    task.wait(0.5)

    log("=== Bees: " .. countBees() .. "/" .. TARGET_BEES .. " ===")
end

log("========== KAITUN COMPLETE: " .. countBees() .. " bees ==========")
