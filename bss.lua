-- BSS Kaitun v4 | Verified Remotes + Fixed Bee Count + Guide Progression
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local plr = game:GetService("Players").LocalPlayer

local TARGET_BEES = 25
local TWEEN_SPEED = 130
local FARM_TIME = 30
local running = true

local E = RS:WaitForChild("Events", 10)
local char, hrp

local function refresh()
    char = plr.Character or plr.CharacterAdded:Wait()
    hrp = char:WaitForChild("HumanoidRootPart")
end
refresh()
plr.CharacterAdded:Connect(refresh)

local function log(m) print("[Kaitun] " .. m) end

-- ═══ TWEEN ═══
local function tween(cf)
    if not hrp or not hrp.Parent then refresh() end
    local d = (hrp.Position - cf.Position).Magnitude
    if d < 4 then hrp.CFrame = cf return end
    local tw = TS:Create(hrp, TweenInfo.new(d / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = cf})
    tw:Play()
    tw.Completed:Wait()
    task.wait(0.2)
end

-- ═══ REMOTES ═══
local function fire(name, ...)
    local r = E:FindFirstChild(name)
    if not r then log("MISS: " .. name) return false end
    local ok, err = pcall(r.FireServer, r, ...)
    if not ok then log("ERR " .. name .. ": " .. tostring(err)) end
    return ok
end

local function invoke(name, ...)
    local r = E:FindFirstChild(name)
    if not r then log("MISS: " .. name) return nil end
    local ok, res = pcall(r.InvokeServer, r, ...)
    if not ok then log("ERR " .. name .. ": " .. tostring(res)) return nil end
    return res
end

-- ═══ HIVE & BEE COUNT ═══
local function getMyHive()
    for _, h in pairs(workspace.Honeycombs:GetChildren()) do
        if h:IsA("Model") and h:FindFirstChild("Owner") and h.Owner.Value == plr then return h end
    end
end

-- FIX: đếm bee bằng CellType ~= "Empty"
local function countBees()
    local h = getMyHive()
    if not h or not h:FindFirstChild("Cells") then return 0 end
    local n = 0
    for _, cell in pairs(h.Cells:GetChildren()) do
        local ct = cell:FindFirstChild("CellType")
        if ct and ct.Value ~= "Empty" and ct.Value ~= "" then
            n = n + 1
        end
    end
    return n
end

local function getEmptySlot()
    local h = getMyHive()
    if not h or not h:FindFirstChild("Cells") then return nil end
    for _, cell in pairs(h.Cells:GetChildren()) do
        local ct = cell:FindFirstChild("CellType")
        if ct and (ct.Value == "Empty" or ct.Value == "") then
            local id = cell:FindFirstChild("CellID")
            if id then return id.Value end
        end
    end
    return nil
end

-- ═══ 1. CLAIM HIVE ═══
local function claimHive()
    log(">> Claim Hive")
    if getMyHive() then log("OK: da co hive") return true end
    tween(CFrame.new(4, 7, 345))
    task.wait(1)
    for _, h in pairs(workspace.Honeycombs:GetChildren()) do
        if h:IsA("Model") and h:FindFirstChild("Owner") and h.Owner.Value == nil then
            local id = h:FindFirstChild("HiveID")
            if id then
                fire("ClaimHive", id.Value)
                task.wait(2)
                if h.Owner.Value == plr then
                    log("OK: claimed hive " .. id.Value)
                    return true
                end
            end
        end
    end
    log("FAIL: claim hive")
    return false
end

-- ═══ 2. CODES (theo guide) ═══
local function redeemCodes()
    log(">> Codes")
    local codes = {
        -- Guide codes (dùng ngay khi bắt đầu)
        "BeesBuzz123", "38217", "BopMaster", "Connoisseur",
        "Crawlers", "Nectar", "Roof", "Wax",
        -- Thêm codes khác
        "Teespring", "Cog", "Troggles", "1MLikes", "PlushFriday",
        "Millie", "Jumpstart", "WordFactory", "Cubly", "Mocito",
        "2MFavorites", "Gumaden", "Discord100k", "Sure",
        "SecretProfileCode", "ClubConverters", "RebootFriday",
        "FuzzyFriday", "Tornado", "Leftovers", "Luther",
        "Boosted", "Wink", "ClubBean", "Gummy",
        "500mil", "1BVisits", "2Billion", "3Billion",
    }
    for _, c in ipairs(codes) do
        if not running then return end
        fire("PromoCodeEvent", c)
        task.wait(0.6)
    end
    log("OK: codes done (" .. #codes .. ")")
end

-- ═══ 3. BUY (ItemPackageEvent) ═══
-- Spy: InvokeServer("Purchase", {Category=..., Type=..., Amount=...})
local function buy(category, itemType, amount)
    local args = {Category = category, Type = itemType}
    if amount then args.Amount = amount end
    local res = invoke("ItemPackageEvent", "Purchase", args)
    log("Buy " .. itemType .. ": " .. tostring(res ~= nil))
    return res ~= nil
end

-- ═══ 4. BUY PROGRESSION (theo guide) ═══
-- Guide order:
-- Start -> Scooper(1) -> Clippers(2) -> Magnet -> Pouch -> 5 bees
-- 5 bees -> Jar -> Helmet -> Belt Pocket -> Basic Boots -> 10 bees
-- 10 bees -> Canister -> Rake -> Vacuum -> Backpack -> 15 bees -> 20 bees -> 25 bees
local function buyProgression(bees)
    log(">> Buy progression (bees=" .. bees .. ")")

    if bees < 5 then
        -- Đầu game: tool cơ bản
        tween(CFrame.new(96, 12, 318)) -- BasicShop
        task.wait(1)
        buy("Collector", "Scooper")
        task.wait(0.5)
        buy("Collector", "Clippers")
        task.wait(0.5)
        buy("Collector", "Magnet")
        task.wait(0.5)
        buy("Accessory", "Pouch")
        task.wait(0.5)
    elseif bees >= 5 and bees < 10 then
        tween(CFrame.new(96, 12, 318))
        task.wait(1)
        buy("Accessory", "Jar")
        task.wait(0.5)
        buy("Accessory", "Helmet")
        task.wait(0.5)
        buy("Accessory", "Belt Pocket")
        task.wait(0.5)
        buy("Accessory", "Basic Boots")
        task.wait(0.5)
    elseif bees >= 10 and bees < 15 then
        tween(CFrame.new(96, 12, 318))
        task.wait(1)
        buy("Accessory", "Canister")
        task.wait(0.5)
        buy("Collector", "Rake")
        task.wait(0.5)
        buy("Collector", "Vacuum")
        task.wait(0.5)
        buy("Accessory", "Backpack")
        task.wait(0.5)
    end
    log("OK: progression buy done")
end

-- ═══ 5. BUY EGG ═══
local function buyEgg()
    tween(CFrame.new(-146, 13, 231))
    task.wait(1)
    buy("Eggs", "Basic", 1)
    task.wait(0.5)
end

-- ═══ 6. HATCH EGG ═══
-- Spy: ConstructHiveCellFromEgg:InvokeServer(hiveID, cellSlot, "Basic", 1, false)
local function hatchEgg()
    log(">> Hatch")
    tween(CFrame.new(4, 7, 345))
    task.wait(1)
    local h = getMyHive()
    if not h then log("FAIL: no hive") return false end
    local hiveID = h:FindFirstChild("HiveID") and h.HiveID.Value
    local slot = getEmptySlot()
    if not slot then log("FAIL: no empty slot") return false end
    log("Hatch: hive=" .. hiveID .. " slot=" .. slot)
    local res = invoke("ConstructHiveCellFromEgg", hiveID, slot, "Basic", 1, false)
    task.wait(1)
    log("Hatch: " .. tostring(res))
    return res ~= nil
end

-- ═══ 7. QUEST ═══
local function doQuest(npcName)
    log(">> Quest: " .. npcName)

    -- Tween đến Circle part (trigger .Touched)
    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then log("FAIL: NPC not found") return end

    local circle = npc:FindFirstChild("Circle")
    local platform = npc:FindFirstChild("Platform")
    local targetPos

    if circle then
        targetPos = circle.Position + Vector3.new(0, 3, 0)
    elseif platform then
        targetPos = platform.Position + Vector3.new(0, 3, 0)
    else
        targetPos = npcName == "Black Bear" and Vector3.new(-256, 5, 297) or Vector3.new(-179, 5, 87)
    end

    tween(CFrame.new(targetPos))
    task.wait(1)

    -- Đặt character trực tiếp lên circle để trigger touch
    if circle and hrp then
        hrp.CFrame = CFrame.new(circle.Position + Vector3.new(0, 3, 0))
    end
    task.wait(1)

    -- Fire touch manually nếu cần
    if circle then
        pcall(function() firetouchinterest(hrp, circle, 0) task.wait(0.1) firetouchinterest(hrp, circle, 1) end)
    end
    task.wait(1)

    -- Thử cả platform
    if platform then
        pcall(function() firetouchinterest(hrp, platform, 0) task.wait(0.1) firetouchinterest(hrp, platform, 1) end)
    end
    task.wait(1.5)

    -- Chọn option (nhận quest)
    fire("SelectNPCOption", 1)
    task.wait(0.5)
    fire("SelectNPCOption", 1)
    task.wait(0.5)

    log("OK: quest " .. npcName)
end

-- ═══ QUEST READER ═══
-- Path: PlayerGui.ScreenGui.Menus.Children.Quests.Content.Frame.QuestBox.TaskBar.Description
-- Text: "Collect 5,000 Pollen.\n0/5,000" | "Collect 5 Tokens from Leaves In the Dandelion Field. 0/5"

-- Map keyword trong quest text -> field name
local QUEST_FIELD_MAP = {
    ["Sunflower"]    = "Sunflower Field",
    ["Mushroom"]     = "Mushroom Field",
    ["Dandelion"]    = "Dandelion Field",
    ["Blue Flower"]  = "Blue Flower Field",
    ["Clover"]       = "Clover Field",
    ["Strawberry"]   = "Strawberry Field",
    ["Spider"]       = "Spider Field",
    ["Bamboo"]       = "Bamboo Field",
    ["Pine Tree"]    = "Pine Tree Forest",
    ["Rose"]         = "Rose Field",
    ["Cactus"]       = "Cactus Field",
    ["Pumpkin"]      = "Pumpkin Patch",
    ["Stump"]        = "Stump Field",
    ["Mountain"]     = "Mountain Top Field",
    ["Pepper"]       = "Pepper Patch",
    ["Coconut"]      = "Coconut Field",
}

local function getQuestTasks()
    local tasks = {}
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return tasks end
    local sg = pg:FindFirstChild("ScreenGui")
    if not sg then return tasks end
    local menus = sg:FindFirstChild("Menus")
    if not menus then return tasks end

    -- Tìm QuestBox trong Quests frame
    local function findQuestBoxes(obj, depth)
        if depth > 8 then return end
        for _, v in pairs(obj:GetChildren()) do
            if v.Name == "QuestBox" then
                local taskBar = v:FindFirstChild("TaskBar")
                if taskBar then
                    for _, desc in pairs(taskBar:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Name == "Description" and desc.Text ~= "" then
                            table.insert(tasks, desc.Text)
                        end
                    end
                end
            end
            findQuestBoxes(v, depth + 1)
        end
    end
    findQuestBoxes(menus, 0)
    return tasks
end

local function getQuestTitle()
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local function findTitle(obj, depth)
        if depth > 10 then return nil end
        for _, v in pairs(obj:GetChildren()) do
            if v.Name == "TitleBar" and v:IsA("TextLabel") and v.Text ~= "" then
                return v.Text
            end
            local res = findTitle(v, depth + 1)
            if res then return res end
        end
    end
    return findTitle(pg, 0)
end

-- Parse task text -> field cần farm
local function parseTaskField(taskText)
    for keyword, fieldName in pairs(QUEST_FIELD_MAP) do
        if taskText:find(keyword) then
            return fieldName
        end
    end
    return nil
end

-- Check progress: "0/5,000" -> current=0, target=5000
local function parseProgress(taskText)
    local current, target = taskText:match("(%d[%d,]*)/(%d[%d,]*)")
    if current and target then
        current = tonumber(current:gsub(",", "")) or 0
        target = tonumber(target:gsub(",", "")) or 1
        return current, target
    end
    return 0, 1
end

-- Kiểm tra task đã hoàn thành chưa
local function isTaskDone(taskText)
    local cur, tgt = parseProgress(taskText)
    return cur >= tgt
end

-- ═══ QUEST FARMER ═══
local function doQuestTasks()
    local tasks = getQuestTasks()
    if #tasks == 0 then
        log("No quest tasks found (open quest UI first)")
        return
    end

    local title = getQuestTitle() or "Unknown Quest"
    log("Quest: " .. title .. " | Tasks: " .. #tasks)

    for _, taskText in ipairs(tasks) do
        if not running then return end

        -- Bỏ qua task đã xong
        if isTaskDone(taskText) then
            log("DONE task: " .. taskText:sub(1, 50))
        else
            log("TODO task: " .. taskText:sub(1, 60))

            -- Tìm field cần farm
            local field = parseTaskField(taskText)

            if taskText:lower():find("convert") or taskText:lower():find("at the hive") then
                -- Convert honey task
                log("  -> Convert at hive")
                convert()

            elseif taskText:lower():find("collect") and field then
                -- Farm field task
                local cur, tgt = parseProgress(taskText)
                local needed = tgt - cur
                log("  -> Farm " .. field .. " (need " .. needed .. ")")
                -- Farm cho đến khi đủ (estimate time)
                local farmRounds = math.ceil(needed / 5000) -- rough estimate
                farmRounds = math.clamp(farmRounds, 1, 10)
                for i = 1, farmRounds do
                    if not running then return end
                    farmField(field)
                    convert()
                    -- Re-check progress
                    local newTasks = getQuestTasks()
                    for _, nt in ipairs(newTasks) do
                        if nt:find(taskText:sub(1, 20)) then
                            if isTaskDone(nt) then
                                log("  -> Task complete!")
                                break
                            end
                        end
                    end
                end

            elseif taskText:lower():find("collect") and taskText:lower():find("pollen") then
                -- Generic pollen collect - farm Dandelion
                log("  -> Farm Dandelion (generic pollen)")
                farmField("Dandelion Field")
                convert()

            elseif taskText:lower():find("token") then
                -- Token task - farm field có token
                log("  -> Farm for tokens (Dandelion)")
                farmField("Dandelion Field")
                convert()

            else
                log("  -> Unknown task type, skip: " .. taskText:sub(1, 50))
            end
        end
    end
    log("Quest tasks processed!")
end

-- ═══ QUEST UI READER ═══
-- Map keyword trong Description -> field name thật
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

-- Mở Quest UI bằng cách click tab button
local function openQuestUI()
    local tab = plr.PlayerGui:FindFirstChild("ScreenGui")
    if not tab then return false end
    local menus = tab:FindFirstChild("Menus")
    if not menus then return false end
    local childTabs = menus:FindFirstChild("ChildTabs")
    if not childTabs then return false end
    local questTab = childTabs:FindFirstChild("Quests Tab")
    if not questTab then return false end
    -- Fire click
    pcall(function() questTab:Activate() end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(questTab.AbsolutePosition.X + 5, questTab.AbsolutePosition.Y + 5, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(questTab.AbsolutePosition.X + 5, questTab.AbsolutePosition.Y + 5, 0, false, game, 1)
    end)
    task.wait(0.5)
    return true
end

-- Đọc tất cả Description text từ quest UI
local function getQuestDescriptions()
    local result = {}
    local sg = plr.PlayerGui:FindFirstChild("ScreenGui")
    if not sg then return result end
    local menus = sg:FindFirstChild("Menus")
    if not menus then return result end
    -- Path: Menus.Children.Quests.Content.Frame.QuestBox.TaskBar.Description
    local children = menus:FindFirstChild("Children")
    if not children then return result end
    local questsFrame = children:FindFirstChild("Quests")
    if not questsFrame then return result end
    local content = questsFrame:FindFirstChild("Content")
    if not content then return result end
    local frame = content:FindFirstChild("Frame")
    if not frame then return result end

    -- Lấy quest title
    local titleBar = frame:FindFirstChild("QuestBox")
    if titleBar then
        local title = titleBar:FindFirstChild("TitleBarBG")
        if title then
            local tb = title:FindFirstChild("TitleBar")
            if tb then result.title = tb.Text end
        end
        -- Lấy tất cả task descriptions
        local taskBar = titleBar:FindFirstChild("TaskBar")
        if taskBar then
            result.tasks = {}
            for _, desc in pairs(taskBar:GetChildren()) do
                if desc:IsA("TextLabel") and desc.Name == "Description" and desc.Text ~= "" then
                    table.insert(result.tasks, desc.Text)
                end
            end
        end
    end
    return result
end

-- Parse description text -> field names cần farm
local function parseQuestFields(descriptions)
    local fields = {}
    local seen = {}
    for _, desc in ipairs(descriptions) do
        local lower = desc:lower()
        for keyword, fieldName in pairs(FIELD_MAP) do
            if lower:find(keyword) and not seen[fieldName] then
                -- Chỉ lấy nếu là collect pollen task (không phải convert/honey token)
                if lower:find("collect") and lower:find("pollen") then
                    seen[fieldName] = true
                    table.insert(fields, fieldName)
                    log("Quest needs: " .. fieldName)
                end
            end
        end
    end
    return fields
end

-- Check quest và farm theo yêu cầu
local function doQuestFarm()
    log(">> Quest Farm Check")

    -- Mở quest UI
    openQuestUI()
    task.wait(1)

    -- Đọc quest data
    local questData = getQuestDescriptions()
    if questData.title then
        log("Active quest: " .. questData.title)
    end

    if not questData.tasks or #questData.tasks == 0 then
        log("No quest tasks found")
        return false
    end

    -- Parse fields cần farm
    local fieldsToFarm = parseQuestFields(questData.tasks)

    if #fieldsToFarm == 0 then
        log("No pollen fields needed (maybe convert/token task)")
        -- Nếu task là convert thì về hive
        for _, desc in ipairs(questData.tasks) do
            if desc:lower():find("convert") then
                log("Convert task -> going to hive")
                convert()
            end
        end
        return false
    end

    -- Farm từng field theo quest
    for _, fieldName in ipairs(fieldsToFarm) do
        if not running then return false end
        log("Quest farm: " .. fieldName)
        farmField(fieldName)
        task.wait(0.5)
    end

    -- Convert sau khi farm
    convert()
    return true
end

-- ═══ 8. FARM FIELD ═══
local function farmField(name)
    log(">> Farm: " .. name)
    local f = workspace.FlowerZones:FindFirstChild(name)
    if not f then log("Field not found: " .. name) return end
    local p = f.Position
    local s = f.Size
    tween(CFrame.new(p.X, p.Y + 3, p.Z))
    task.wait(0.5)
    local t0 = tick()
    while (tick() - t0) < FARM_TIME and running do
        for row = -2, 2 do
            for col = -2, 2 do
                if (tick() - t0) >= FARM_TIME or not running then return end
                tween(CFrame.new(p.X + col * s.X * 0.18, p.Y + 3, p.Z + row * s.Z * 0.18))
                task.wait(0.15)
            end
        end
    end
end

-- ═══ 9. CONVERT ═══
local function convert()
    log(">> Convert")
    tween(CFrame.new(4, 7, 345))
    task.wait(6)
end

-- ═══ 10. MAIN FARM LOOP ═══
local function farmLoop()
    local fields = {"Dandelion Field", "Sunflower Field", "Mushroom Field"}
    local idx = 1
    local bees = countBees()
    log(">> Farm loop | Bees: " .. bees .. "/" .. TARGET_BEES)

    while bees < TARGET_BEES and running do
        -- Buy progression items khi đạt milestone
        buyProgression(bees)
        task.wait(1)

        -- Thử farm theo quest trước, nếu không có thì farm field mặc định
        local questDone = doQuestFarm()
        if not questDone then
            farmField(fields[idx])
            convert()
            idx = (idx % #fields) + 1
        end

        -- Buy + Hatch
        buyEgg()
        task.wait(0.5)
        hatchEgg()
        task.wait(0.5)

        -- Update
        bees = countBees()
        log("Bees: " .. bees .. "/" .. TARGET_BEES)
    end
    log("DONE: " .. bees .. " bees!")
end

-- ═══ ANTI-AFK ═══
pcall(function()
    local vu = game:GetService("VirtualUser")
    plr.Idled:Connect(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end)
end)

-- ═══ STOP UI ═══
pcall(function()
    local g = Instance.new("ScreenGui")
    g.Name = "KaitunUI"; g.ResetOnSpawn = false
    g.Parent = plr:WaitForChild("PlayerGui")
    local b = Instance.new("TextButton", g)
    b.Size = UDim2.new(0, 120, 0, 32)
    b.Position = UDim2.new(0, 8, 0, 180)
    b.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = "STOP KAITUN"; b.Font = Enum.Font.GothamBold; b.TextSize = 13
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() running = false; b.Text = "STOPPED"; log("STOPPED") end)
end)

-- ═══ MAIN ═══
log("========== KAITUN v4 START ==========")
task.wait(2)

-- Check bees trước
local startBees = countBees()
log("Current bees in hive: " .. startBees)

-- Step 1: Claim Hive
for i = 1, 3 do if claimHive() then break end task.wait(2) end
task.wait(1)

-- Re-check bees sau claim
startBees = countBees()
log("Bees after claim: " .. startBees)

-- Step 2: Codes
if running then redeemCodes() task.wait(1) end

-- Step 3: Initial buy (dựa vào số bees hiện tại)
if running then buyProgression(startBees) task.wait(1) end

-- Step 4: Quests
if running then doQuest("Black Bear") task.wait(1) end
if running then doQuest("Mother Bear") task.wait(1) end

-- Step 5: Farm loop
if running then farmLoop() end

log("========== KAITUN v4 COMPLETE ==========")
