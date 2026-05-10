--[[
    =============================================
    Auto Kaitun Starter v2.0 - Bee Swarm Simulator
    =============================================
    Features:
      0. Auto Claim Hive
      1. Auto Buy Accessories
      2. Auto Buy Hive Slot + Place Bees (target: 20)
      3. Auto Farm (field farming + sell honey)
      4. Auto Quest (talk to NPCs, accept & complete)
      5. Full UI Control Panel
    =============================================
]]

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local Events = RS:WaitForChild("Events")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")
local ConstructHiveCellFromEgg = Events:WaitForChild("ConstructHiveCellFromEgg")
local RetrievePlayerStats = Events:WaitForChild("RetrievePlayerStats")
local ClaimHive = Events:WaitForChild("ClaimHive")
local ToolCollect = Events:WaitForChild("ToolCollect")
local PlayerHiveCommand = Events:WaitForChild("PlayerHiveCommand")

-- ============================================
-- CONFIG & STATE
-- ============================================
local Config = {
    TargetBees = 20,
    FarmField = "Sunflower Field",
    ConvertAt = 95, -- % backpack full to sell
    AutoFarm = false,
    AutoQuest = false,
    AutoBuyAcc = false,
    AutoBees = false,
    Running = true,
    FarmDelay = 0.3,
}

local FieldList = {
    "Sunflower Field", "Dandelion Field", "Mushroom Field", "Blue Flower Field",
    "Clover Field", "Spider Field", "Strawberry Field", "Bamboo Field",
    "Pineapple Patch", "Stump Field", "Cactus Field", "Pumpkin Patch",
    "Pine Tree Forest", "Rose Field", "Mountain Top Field", "Coconut Field",
    "Pepper Patch", "Hub Field"
}

local NPCList = {
    {Name = "Black Bear", Pos = CFrame.new(-250, 4, 336)},
    {Name = "Brown Bear", Pos = CFrame.new(-4, 58, 332)},
    {Name = "Mother Bear", Pos = CFrame.new(-266, 28, 452)},
    {Name = "Polar Bear", Pos = CFrame.new(265, 68, 449)},
    {Name = "Science Bear", Pos = CFrame.new(265, 68, 525)},
}

local AccessoryBuyOrder = {
    {Type = "Helmet", Cost = 30000},
    {Type = "Brave Guard", Cost = 300000},
    {Type = "Hasty Guard", Cost = 300000},
    {Type = "Bomber Guard", Cost = 300000},
    {Type = "Looker Guard", Cost = 300000},
    {Type = "Blue Guard", Cost = 1000000},
    {Type = "Red Guard", Cost = 1000000},
    {Type = "Basic Boots", Cost = 50000},
    {Type = "Belt Pocket", Cost = 50000},
    {Type = "Propeller Hat", Cost = 2500000},
    {Type = "Elite Blue Guard", Cost = 3000000},
    {Type = "Elite Red Guard", Cost = 3000000},
    {Type = "Hiking Boots", Cost = 2500000},
    {Type = "Mondo Belt Bag", Cost = 1500000},
    {Type = "Parachute", Cost = 500000},
    {Type = "Glider", Cost = 5000000},
    {Type = "Beekeeper's Boots", Cost = 15000000},
    {Type = "Beekeeper's Mask", Cost = 20000000},
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
local function GetHoney()
    if plr:FindFirstChild("CoreStats") and plr.CoreStats:FindFirstChild("Honey") then
        return plr.CoreStats.Honey.Value
    end
    return 0
end

local function GetPollen()
    if plr:FindFirstChild("CoreStats") and plr.CoreStats:FindFirstChild("Pollen") then
        return plr.CoreStats.Pollen.Value
    end
    return 0
end

local function GetCapacity()
    if plr:FindFirstChild("CoreStats") and plr.CoreStats:FindFirstChild("Capacity") then
        return plr.CoreStats.Capacity.Value
    end
    return 100
end

local function IsBackpackFull()
    return GetPollen() >= (GetCapacity() * Config.ConvertAt) / 100
end

local function FormatNum(n)
    if n >= 1e9 then return string.format("%.1fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(math.floor(n)) end
end

local function Notify(msg)
    print("[Kaitun] " .. msg)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title="Kaitun",Text=msg,Duration=3})
    end)
end

local function TpTo(cf)
    pcall(function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = cf
        end
    end)
end

local function GetFieldPart(fieldName)
    for _,v in pairs(WS.FlowerZones:GetChildren()) do
        if v.Name == fieldName then return v end
    end
end

local function GetPlayerHive()
    for _, hive in pairs(WS.Honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and tostring(hive.Owner.Value) == plr.Name then
            return hive
        end
    end
end

local function GetBeeCount()
    local count = 0
    local hive = GetPlayerHive()
    if hive and hive:FindFirstChild("Cells") then
        for _, cell in pairs(hive.Cells:GetChildren()) do
            if cell:FindFirstChild("CellType") then
                local ct = tostring(cell.CellType.Value)
                if ct ~= "Empty" and ct ~= "nil" and ct ~= "" then
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function GetEmptySlot()
    local hive = GetPlayerHive()
    if hive and hive:FindFirstChild("Cells") then
        for _, cell in pairs(hive.Cells:GetChildren()) do
            if cell:FindFirstChild("CellType") then
                local ct = tostring(cell.CellType.Value)
                if ct == "Empty" or ct == "nil" or ct == "" then
                    local x, y = cell.Name:match("C(%d+),(%d+)")
                    if x and y then return tonumber(x), tonumber(y) end
                end
            end
        end
    end
end

local function PurchaseItem(cat, itemType, amt)
    local data = {Category=cat, Type=itemType}
    if amt then data.Amount = amt end
    local s, r = pcall(function() return ItemPackageEvent:InvokeServer("Purchase", data) end)
    return s and r
end

-- ============================================
-- UI SYSTEM
-- ============================================
local function CreateUI()
    -- Destroy old UI if exists
    if plr.PlayerGui:FindFirstChild("KaitunUI") then
        plr.PlayerGui.KaitunUI:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "KaitunUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = plr.PlayerGui

    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 320, 0, 440)
    main.Position = UDim2.new(0, 20, 0.5, -220)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    main.BorderSizePixel = 0
    main.Parent = gui
    main.Active = true
    main.Draggable = true

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(255, 180, 50)
    stroke.Thickness = 2

    -- Title
    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
    title.Text = "🐝 Kaitun Starter v2.0"
    title.TextColor3 = Color3.fromRGB(20, 20, 30)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.BorderSizePixel = 0
    local tc = Instance.new("UICorner", title)
    tc.CornerRadius = UDim.new(0, 10)

    -- Scroll container
    local scroll = Instance.new("ScrollingFrame", main)
    scroll.Size = UDim2.new(1, -16, 1, -44)
    scroll.Position = UDim2.new(0, 8, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 180, 50)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 720)
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout", scroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)

    -- Status Label
    local status = Instance.new("TextLabel", scroll)
    status.Name = "Status"
    status.Size = UDim2.new(1, -8, 0, 50)
    status.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    status.TextColor3 = Color3.fromRGB(200, 255, 200)
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 12
    status.TextWrapped = true
    status.Text = "🍯 Honey: 0 | 🐝 Bees: 0\n📦 Pollen: 0/0 | 🌻 Field: None"
    status.LayoutOrder = 0
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)

    -- Helper: Create Section Header
    local function MakeHeader(text, order)
        local h = Instance.new("TextLabel", scroll)
        h.Size = UDim2.new(1, -8, 0, 24)
        h.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
        h.TextColor3 = Color3.fromRGB(20, 20, 30)
        h.Font = Enum.Font.GothamBold
        h.TextSize = 13
        h.Text = "  " .. text
        h.TextXAlignment = Enum.TextXAlignment.Left
        h.LayoutOrder = order
        Instance.new("UICorner", h).CornerRadius = UDim.new(0, 5)
    end

    -- Helper: Create Toggle Button
    local function MakeToggle(text, default, order, callback)
        local btn = Instance.new("TextButton", scroll)
        btn.Size = UDim2.new(1, -8, 0, 32)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BorderSizePixel = 0
        btn.LayoutOrder = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local state = default
        local function update()
            btn.BackgroundColor3 = state and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(60, 60, 80)
            btn.Text = text .. (state and "  ✅" or "  ❌")
        end
        update()

        btn.MouseButton1Click:Connect(function()
            state = not state
            update()
            if callback then callback(state) end
        end)
        return btn
    end

    -- Helper: Create Dropdown
    local function MakeDropdown(text, list, default, order, callback)
        local frame = Instance.new("Frame", scroll)
        frame.Size = UDim2.new(1, -8, 0, 52)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        frame.LayoutOrder = order
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  " .. text
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local idx = table.find(list, default) or 1
        local val = Instance.new("TextButton", frame)
        val.Size = UDim2.new(1, -16, 0, 24)
        val.Position = UDim2.new(0, 8, 0, 22)
        val.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        val.TextColor3 = Color3.fromRGB(255, 220, 100)
        val.Font = Enum.Font.GothamMedium
        val.TextSize = 12
        val.Text = "◀ " .. (list[idx] or "?") .. " ▶"
        val.BorderSizePixel = 0
        Instance.new("UICorner", val).CornerRadius = UDim.new(0, 4)

        val.MouseButton1Click:Connect(function()
            idx = idx % #list + 1
            val.Text = "◀ " .. list[idx] .. " ▶"
            if callback then callback(list[idx]) end
        end)
        if callback then callback(list[idx]) end
    end

    -- Build UI sections
    MakeHeader("📊 Status", 0)
    -- status is already order 0, header above it

    MakeHeader("🏠 Setup", 10)
    MakeToggle("Auto Claim Hive", false, 11, function(v)
        if v then task.spawn(function() AutoClaimHive() end) end
    end)
    MakeToggle("Auto Buy Accessories", false, 12, function(v)
        Config.AutoBuyAcc = v
        if v then task.spawn(function() AutoBuyAccessories() end) end
    end)
    MakeToggle("Auto Place Bees → "..Config.TargetBees, false, 13, function(v)
        Config.AutoBees = v
        if v then task.spawn(function() AutoPlaceBees() end) end
    end)

    MakeHeader("🌻 Farming", 20)
    MakeDropdown("Select Field", FieldList, Config.FarmField, 21, function(v)
        Config.FarmField = v
    end)
    MakeToggle("Auto Farm", false, 22, function(v)
        Config.AutoFarm = v
        if v then task.spawn(function() AutoFarm() end) end
    end)

    MakeHeader("📜 Quests", 30)
    MakeToggle("Auto Quest (Black Bear)", false, 31, function(v)
        Config.AutoQuest = v
        if v then task.spawn(function() AutoQuest() end) end
    end)

    MakeHeader("⚙️ Misc", 40)
    local function MakeButton(text, order, callback)
        local btn = Instance.new("TextButton", scroll)
        btn.Size = UDim2.new(1, -8, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.Text = text
        btn.LayoutOrder = order
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
    end

    MakeButton("🧱 Remove Gates/Walls", 41, function()
        pcall(function()
            for _,g in pairs(WS.Gates:GetChildren()) do
                for _,p in pairs(g:GetChildren()) do pcall(function() p.CanCollide=false end) end
            end
        end)
        pcall(function() for _,v in pairs(WS["Invisible Walls"]:GetChildren()) do v:Destroy() end end)
        pcall(function() for _,v in pairs(WS.Territories:GetChildren()) do v:Destroy() end end)
        Notify("Gates/Walls removed!")
    end)

    MakeButton("🏠 TP to Hive", 42, function()
        local hive = GetPlayerHive()
        if hive and hive:FindFirstChild("SpawnPos") then
            TpTo(hive.SpawnPos.Value + Vector3.new(0,5,0))
            Notify("TP'd to hive!")
        end
    end)

    MakeButton("🌻 TP to Field", 43, function()
        local fp = GetFieldPart(Config.FarmField)
        if fp then
            TpTo(fp.CFrame * CFrame.new(0, 8, 0))
            Notify("TP'd to " .. Config.FarmField)
        end
    end)

    -- Minimize toggle
    local minBtn = Instance.new("TextButton", main)
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -32, 0, 4)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(20, 20, 30)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 18
    minBtn.ZIndex = 10

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        scroll.Visible = not minimized
        if minimized then
            main.Size = UDim2.new(0, 320, 0, 36)
            minBtn.Text = "+"
        else
            main.Size = UDim2.new(0, 320, 0, 440)
            minBtn.Text = "—"
        end
    end)

    -- Update status loop
    task.spawn(function()
        while Config.Running and task.wait(1) do
            pcall(function()
                status.Text = string.format(
                    "🍯 %s | 🐝 %d bees\n📦 %s/%s (%d%%) | 🌻 %s",
                    FormatNum(GetHoney()), GetBeeCount(),
                    FormatNum(GetPollen()), FormatNum(GetCapacity()),
                    math.floor(GetPollen()/math.max(GetCapacity(),1)*100),
                    Config.FarmField
                )
            end)
        end
    end)

    return gui
end

-- ============================================
-- AUTO CLAIM HIVE
-- ============================================
function AutoClaimHive()
    if GetPlayerHive() then
        Notify("✅ Already have a hive!")
        return true
    end
    Notify("🏠 Finding empty hive to claim...")
    local combs = WS.Honeycombs:GetChildren()
    for attempt = 1, 20 do
        for i = #combs, 1, -1 do
            local hive = combs[i]
            if hive:FindFirstChild("Owner") and tostring(hive.Owner.Value) == "nil" then
                pcall(function()
                    if hive:FindFirstChild("LightHolder") then
                        TpTo(hive.LightHolder.CFrame)
                    end
                end)
                task.wait(1)
                pcall(function()
                    if hive:FindFirstChild("HiveID") then
                        ClaimHive:FireServer(hive.HiveID.Value)
                    end
                end)
                task.wait(2)
                if GetPlayerHive() then
                    Notify("🎉 Hive claimed!")
                    return true
                end
                break
            end
        end
        task.wait(2)
    end
    Notify("❌ Could not claim hive")
    return false
end

-- ============================================
-- AUTO BUY ACCESSORIES
-- ============================================
function AutoBuyAccessories()
    Notify("🛒 Auto buying accessories...")
    for _, acc in ipairs(AccessoryBuyOrder) do
        if not Config.AutoBuyAcc then break end
        local honey = GetHoney()
        if honey >= acc.Cost then
            local ok = PurchaseItem("Accessory", acc.Type)
            if ok then
                Notify("✅ Bought: " .. acc.Type)
            end
        end
        task.wait(0.5)
    end
    Notify("🛒 Accessories done!")
end

-- ============================================
-- AUTO PLACE BEES (with egg check & buy)
-- ============================================
local function GetEggCount(eggName)
    local count = 0
    pcall(function()
        local stats = RetrievePlayerStats:InvokeServer()
        if stats and stats.Eggs and stats.Eggs[eggName] then
            count = stats.Eggs[eggName]
        end
    end)
    return count
end

local function BuyBasicEgg()
    -- Mua BasicEgg từ shop (Category = Egg)
    local ok = PurchaseItem("Egg", "BasicEgg")
    if ok then
        Notify("🛒 Bought a Basic Egg!")
        return true
    end
    -- Thử cách khác: mua trực tiếp từ Basic Egg Shop
    pcall(function()
        ItemPackageEvent:InvokeServer("Purchase", {
            Category = "Egg",
            Type = "BasicEgg",
            Amount = 1
        })
    end)
    task.wait(0.5)
    return GetEggCount("BasicEgg") > 0
end

function AutoPlaceBees()
    Notify("🐝 Auto placing bees to " .. Config.TargetBees .. "...")
    while Config.AutoBees and Config.Running do
        local bees = GetBeeCount()
        if bees >= Config.TargetBees then
            Notify("🎉 Reached " .. bees .. " bees!")
            break
        end
        
        local x, y = GetEmptySlot()
        if x and y then
            -- Check nếu có BasicEgg trong inventory
            local eggCount = GetEggCount("BasicEgg")
            if eggCount <= 0 then
                Notify("🛒 No Basic Egg! Buying...")
                BuyBasicEgg()
                task.wait(1)
                eggCount = GetEggCount("BasicEgg")
            end
            
            if eggCount > 0 then
                -- Hatch egg vào slot
                local success = false
                pcall(function()
                    local result = ConstructHiveCellFromEgg:InvokeServer(x, y, "BasicEgg", 1, false)
                    if result then success = true end
                end)
                
                task.wait(1)
                local newBees = GetBeeCount()
                if newBees > bees then
                    Notify("🐝 Hatched bee at (" .. x .. "," .. y .. ") [" .. newBees .. "/" .. Config.TargetBees .. "]")
                else
                    Notify("⚠️ Egg didn't hatch, retrying...")
                end
            else
                Notify("❌ Can't buy Basic Egg (need more honey?)")
                task.wait(5)
            end
        else
            -- Không có slot trống -> mua Hive Slot
            Notify("🔓 No empty slot, buying Hive Slot...")
            local ok = PurchaseItem("HiveSlot", "HiveSlot", 1)
            if ok then
                Notify("✅ Bought hive slot!")
            else
                Notify("⏳ Need more honey for slot...")
                task.wait(5)
            end
        end
        task.wait(1.5)
    end
end

-- ============================================
-- AUTO FARM
-- ============================================
function AutoFarm()
    Notify("🌻 Auto farming: " .. Config.FarmField)
    while Config.AutoFarm and Config.Running do
        pcall(function()
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
                task.wait(3)
                return
            end

            -- Check if backpack is full -> sell
            if IsBackpackFull() then
                Notify("📦 Backpack full! Selling...")
                -- TP to hive to sell
                local hive = GetPlayerHive()
                if hive and hive:FindFirstChild("SpawnPos") then
                    TpTo(hive.SpawnPos.Value + Vector3.new(0, 5, 0))
                    task.wait(1)
                    PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                    -- Wait until pollen is empty
                    local sellStart = tick()
                    repeat task.wait(0.5)
                    until GetPollen() <= 0 or tick() - sellStart > 30 or not Config.AutoFarm
                    task.wait(1)
                end
            end

            -- TP to field if not there
            local fp = GetFieldPart(Config.FarmField)
            if fp then
                local hrp = plr.Character.HumanoidRootPart
                if (hrp.Position - fp.Position).Magnitude > 40 then
                    TpTo(fp.CFrame * CFrame.new(0, 8, 0))
                    task.wait(1)
                end

                -- Dig (collect pollen)
                pcall(function()
                    ToolCollect:FireServer()
                end)

                -- Random walk on field
                local rx = math.random(-15, 15)
                local rz = math.random(-15, 15)
                local walkPos = fp.Position + Vector3.new(rx, 3, rz)
                if plr.Character:FindFirstChild("Humanoid") then
                    plr.Character.Humanoid:MoveTo(walkPos)
                end
            end
        end)
        task.wait(Config.FarmDelay)
    end
    Notify("🌻 Farm stopped.")
end

-- ============================================
-- AUTO QUEST
-- ============================================
function AutoQuest()
    Notify("📜 Auto Quest started (Black Bear)...")
    while Config.AutoQuest and Config.Running do
        pcall(function()
            -- Find Black Bear NPC
            local npc = WS.NPCs:FindFirstChild("Black Bear")
            if npc then
                local npcPart = npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart")
                    or npc:FindFirstChild("Torso")
                if npcPart then
                    -- TP to NPC
                    TpTo(CFrame.new(npcPart.Position + Vector3.new(0, 3, -5)))
                    task.wait(1)

                    -- Trigger NPC dialog via Activatables
                    pcall(function()
                        local Activatables = require(RS.Activatables)
                        -- Try to talk
                        local target = Activatables.GetTarget()
                        if target then
                            -- Auto advance dialog
                            for i = 1, 20 do
                                pcall(function()
                                    local ab = plr.PlayerGui.ScreenGui:FindFirstChild("ActivateButton")
                                    if ab and ab.Visible then
                                        for _, conn in pairs(getconnections(ab.MouseButton1Click)) do
                                            conn:Fire()
                                        end
                                    end
                                end)
                                task.wait(0.3)
                            end
                        end
                    end)

                    -- Fallback: fire dialog event directly
                    pcall(function()
                        Events.SelectNPCOption:FireServer("AdvanceDialog")
                    end)
                end
            end
        end)
        task.wait(5)
    end
    Notify("📜 Auto Quest stopped.")
end

-- ============================================
-- MAIN EXECUTION
-- ============================================
Notify("=== Kaitun Starter v2.0 ===")

-- Wait for game to load
repeat task.wait(1) until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
repeat task.wait(1) until WS:FindFirstChild("Honeycombs") and #WS.Honeycombs:GetChildren() > 0
task.wait(2)

-- Remove gates
pcall(function()
    for _,g in pairs(WS.Gates:GetChildren()) do
        for _,p in pairs(g:GetChildren()) do pcall(function() p.CanCollide=false end) end
    end
end)
pcall(function() for _,v in pairs(WS["Invisible Walls"]:GetChildren()) do v:Destroy() end end)
pcall(function() for _,v in pairs(WS.Territories:GetChildren()) do v:Destroy() end end)

-- Auto claim hive if needed
if not GetPlayerHive() then
    AutoClaimHive()
end

-- Create UI
CreateUI()
Notify("✅ UI loaded! Use the panel to control features.")
