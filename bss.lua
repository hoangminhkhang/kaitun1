-- BSS Kaitun v3 | Remote Spy Verified
-- Executor: Synapse/Fluxus/Delta/Arceus/Wave

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

-- ═══ REMOTES (verified spy) ═══
-- ItemPackageEvent: InvokeServer("Purchase", {Category=..., Type=..., Amount=...})
-- ClaimHive: FireServer(hiveID)
-- PromoCodeEvent: FireServer(code)
-- GiveQuest: FireServer(questName)
-- SelectNPCOption: FireServer(optionString)
-- ConstructHiveCellFromEgg: InvokeServer(hiveID, cellSlot, eggType, qty, useRJ)
-- PlayerActivesCommand: FireServer(...)
-- CompleteQuest: FireServer(...)

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

-- ═══ HIVE ═══
local function getMyHive()
    for _, h in pairs(workspace.Honeycombs:GetChildren()) do
        if h:IsA("Model") and h:FindFirstChild("Owner") and h.Owner.Value == plr then return h end
    end
end

local function countBees()
    local h = getMyHive()
    if not h or not h:FindFirstChild("Cells") then return 0 end
    local n = 0
    for _, c in pairs(h.Cells:GetChildren()) do
        if c:IsA("Model") and #c:GetChildren() > 1 then n = n + 1 end
    end
    return n
end

local function getEmptySlot()
    local h = getMyHive()
    if not h or not h:FindFirstChild("Cells") then return nil end
    for _, c in pairs(h.Cells:GetChildren()) do
        if c:IsA("Model") and #c:GetChildren() <= 1 then
            local num = tonumber(c.Name:match("%d+"))
            if num then return num end
        end
    end
    return nil
end

-- ═══ QUEST CHECK ═══
-- Lấy quest hiện tại của player
local function getPlayerQuests()
    local stats = invoke("RetrievePlayerStatsSummary")
    if stats and typeof(stats) == "table" then
        return stats.Quests or stats.quests
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

-- ═══ 2. CODES ═══
local function redeemCodes()
    log(">> Codes")
    local codes = {
        "Wax","Teespring","Bopmaster","Cog","Connoisseur","Roof","Nectar",
        "Troggles","1MLikes","PlushFriday","Millie","Jumpstart","WordFactory",
        "Cubly","Mocito","2MFavorites","Gumaden","Discord100k","Sure",
        "SecretProfileCode","ClubConverters","RebootFriday","FuzzyFriday",
        "Tornado","Leftovers","Luther","Crawlers","Boosted","Wink",
        "ClubBean","Gummy","500mil","1BVisits","2Billion","3Billion",
    }
    for _, c in ipairs(codes) do
        if not running then return end
        fire("PromoCodeEvent", c)
        task.wait(0.6)
    end
    log("OK: codes done")
end

-- ═══ 3. BUY ACCESSORIES ═══
-- Spy: ItemPackageEvent:InvokeServer("Purchase", {Category="Accessory", Type="Jar"})
local function buyAccessories()
    log(">> Buy Accessories")
    tween(CFrame.new(96, 12, 318))
    task.wait(1)
    local items = {
        {Cat = "Collector", Type = "Rake"},
        {Cat = "Collector", Type = "Scooper"},
        {Cat = "Collector", Type = "Magnet"},
        {Cat = "Collector", Type = "Clippers"},
        {Cat = "Collector", Type = "Vacuum"},
        {Cat = "Accessory", Type = "Pouch"},
        {Cat = "Accessory", Type = "Jar"},
        {Cat = "Accessory", Type = "Canister"},
        {Cat = "Accessory", Type = "Backpack"},
        {Cat = "Accessory", Type = "Helmet"},
        {Cat = "Accessory", Type = "Belt Pocket"},
        {Cat = "Accessory", Type = "Basic Boots"},
    }
    for _, item in ipairs(items) do
        if not running then return end
        local res = invoke("ItemPackageEvent", "Purchase", {Category = item.Cat, Type = item.Type})
        log("Buy " .. item.Type .. ": " .. tostring(res ~= nil))
        task.wait(0.5)
    end
    log("OK: accessories done")
end

-- ═══ 4. BUY EGG ═══
-- Spy: ItemPackageEvent:InvokeServer("Purchase", {Type="Basic", Category="Eggs", Amount=1})
local function buyEgg()
    log(">> Buy Egg")
    tween(CFrame.new(-146, 13, 231))
    task.wait(1)
    local res = invoke("ItemPackageEvent", "Purchase", {Type = "Basic", Category = "Eggs", Amount = 1})
    log("Buy egg: " .. tostring(res ~= nil))
    task.wait(0.5)
end

-- ═══ 5. HATCH EGG ═══
-- Spy: ConstructHiveCellFromEgg:InvokeServer(hiveID, cellSlot, "Basic", 1, false)
local function hatchEgg()
    log(">> Hatch Egg")
    tween(CFrame.new(4, 7, 345))
    task.wait(1)
    local h = getMyHive()
    if not h then log("FAIL: no hive") return false end
    local hiveID = h:FindFirstChild("HiveID") and h.HiveID.Value
    local slot = getEmptySlot()
    if not slot then log("FAIL: no empty slot") return false end
    log("Hatch: hive=" .. tostring(hiveID) .. " slot=" .. tostring(slot))
    local res = invoke("ConstructHiveCellFromEgg", hiveID, slot, "Basic", 1, false)
    task.wait(1)
    log("Hatch result: " .. tostring(res))
    return res ~= nil
end

-- ═══ 6. QUEST ═══
-- Spy: GiveQuest:FireServer("Sunflower Start")
-- Black Bear quest names (thứ tự đầu game)
local BB_QUESTS = {
    "Sunflower Start", "Making Honey", "Mushroom Mission",
    "Dandelion Disaster", "Blue Flower Bonanza", "Clover Clearing",
    "Spider Scare", "Strawberry Shortcake", "Bamboo Boogie",
    "Pine Tree Pursuit", "Rose Rampage", "Cactus Craze",
    "Mountain Madness", "Pumpkin Plan", "Stump Stomp",
}

local MB_QUESTS = {
    "A Gifted Occasion", "Bee Cub", "Royal Jelly Jubilee",
    "Honey Wreath", "Star Journey", "Petal Planter",
}

local function doQuest(npcName, questList)
    log(">> Quest: " .. npcName)
    local cf = npcName == "Black Bear" and CFrame.new(-256, 5, 297) or CFrame.new(-179, 5, 87)
    tween(cf)
    task.wait(1.5)

    -- Nói chuyện NPC
    fire("PlayerActivesCommand", "npc talk", npcName)
    task.wait(1)

    -- Thử nhận quest theo danh sách
    for _, qName in ipairs(questList) do
        fire("GiveQuest", qName)
        task.wait(0.3)
    end
    task.wait(0.5)

    -- Chọn option
    fire("SelectNPCOption", 1)
    task.wait(0.5)
    log("OK: quest " .. npcName)
end

-- Check quest progress (dùng RetrievePlayerStatsSummary)
local function checkQuests()
    log(">> Check Quests")
    local quests = getPlayerQuests()
    if quests and typeof(quests) == "table" then
        for k, v in pairs(quests) do
            if typeof(v) == "table" then
                local name = v.Name or v.name or k
                local progress = v.Progress or v.progress or "?"
                log("Quest: " .. tostring(name) .. " | Progress: " .. tostring(progress))
            else
                log("Quest: " .. tostring(k) .. " = " .. tostring(v))
            end
        end
    else
        log("No quest data (may need to accept quest first)")
    end
end

-- ═══ 7. FARM FIELD ═══
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

-- ═══ 8. CONVERT ═══
local function convert()
    log(">> Convert")
    tween(CFrame.new(4, 7, 345))
    task.wait(6)
end

-- ═══ 9. FARM LOOP ═══
local function farmLoop()
    log(">> Farm loop -> " .. TARGET_BEES .. " bees")
    local fields = {"Dandelion Field", "Sunflower Field", "Mushroom Field"}
    local idx = 1
    local bees = countBees()
    log("Bees: " .. bees)

    while bees < TARGET_BEES and running do
        farmField(fields[idx])
        convert()
        buyEgg()
        task.wait(0.5)
        hatchEgg()
        task.wait(0.5)
        bees = countBees()
        log("Bees: " .. bees .. "/" .. TARGET_BEES)
        idx = (idx % #fields) + 1

        -- Check quest progress mỗi vòng
        checkQuests()
    end
    log("DONE: " .. bees .. " bees")
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
log("========== KAITUN v3 START ==========")
task.wait(2)

for i = 1, 3 do if claimHive() then break end task.wait(2) end
task.wait(1)

if running then redeemCodes() task.wait(1) end
if running then buyAccessories() task.wait(1) end
if running then doQuest("Black Bear", BB_QUESTS) task.wait(1) end
if running then doQuest("Mother Bear", MB_QUESTS) task.wait(1) end
if running then checkQuests() task.wait(1) end
if running then farmLoop() end

log("========== KAITUN COMPLETE ==========")
