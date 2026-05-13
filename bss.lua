-- BSS Kaitun | functest v3: Auto Quest + Smart Farm + Token Collect + GUI
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local plr = game:GetService("Players").LocalPlayer

local E = RS:WaitForChild("Events")
local char, hum, hrp
local function refresh()
    char = plr.Character or plr.CharacterAdded:Wait()
    hum = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end
refresh()
plr.CharacterAdded:Connect(function() task.wait(0.5) refresh() end)

local function log(m) print("[functest] " .. m) end

-- ═══ NPC CONFIG (theo zone) ═══
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

-- ═══ FIELD MAP ═══
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

-- ═══ STATE ═══
local State = {
    Running = false,
    NormalSpeed = 16,
    FarmSpeed = 90,
    SelectedQuest = "Auto",
    AutoCollect = true,
    CollectRange = 30,
}

-- ═══ NOCLIP ═══
RunService.Stepped:Connect(function()
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ═══ AUTO SKIP DIALOG ═══
RunService.Stepped:Connect(function()
    if plr.PlayerGui:FindFirstChild("ScreenGui") and plr.PlayerGui.ScreenGui:FindFirstChild("NPC") and plr.PlayerGui.ScreenGui.NPC.Visible then
        pcall(function()
            plr.PlayerGui.Camera.Controllers.NPC.IncrementDialogue:Invoke()
        end)
    end
end)

-- ═══ TWEEN ═══
local function tween(cf, speed)
    speed = speed or 130
    if not hrp or not hrp.Parent then refresh() end
    local d = (hrp.Position - cf.Position).Magnitude
    if d < 4 then hrp.CFrame = cf return end
    local tw = TS:Create(hrp, TweenInfo.new(d / speed, Enum.EasingStyle.Linear), {CFrame = cf})
    tw:Play(); tw.Completed:Wait(); task.wait(0.15)
end

-- ═══ HIVE & BEE COUNT ═══
local function getMyHive()
    for _, h in pairs(workspace.Honeycombs:GetChildren()) do
        if h:IsA("Model") and h:FindFirstChild("Owner") and h.Owner.Value == plr then return h end
    end
end

local function countBees()
    local h = getMyHive()
    if not h or not h:FindFirstChild("Cells") then return 0 end
    local n = 0
    for _, cell in pairs(h.Cells:GetChildren()) do
        local ct = cell:FindFirstChild("CellType")
        if ct and ct.Value ~= "Empty" and ct.Value ~= "" then n += 1 end
    end
    return n
end

-- ═══ NPC ALERT CHECK ═══
local function npcHasAlert(npcName)
    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then return false end
    local platform = npc:FindFirstChild("Platform")
    if not platform then return false end
    local alertPos = platform:FindFirstChild("AlertPos")
    if not alertPos then return false end
    local alertGui = alertPos:FindFirstChild("AlertGui")
    if not alertGui then return false end
    for _, c in pairs(alertGui:GetDescendants()) do
        if c:IsA("ImageLabel") and c.ImageTransparency == 0 then return true end
    end
    return false
end

-- ═══ TALK NPC ═══
local function talkNPC(npcName, pos)
    log("Talk: " .. npcName)
    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then return false end

    tween(CFrame.new(pos))
    task.wait(0.3)
    hrp.CFrame = CFrame.new(pos)
    task.wait(0.3)

    -- Gọi 2 lần để nhận cả quest thường + Beesmas
    for i = 1, 2 do
        pcall(function()
            local cac = require(RS.Activatables.NPCs)
            cac.ButtonEffect(plr, npc)
        end)
        local npcGui = plr.PlayerGui.ScreenGui.NPC
        local t = 0
        while not npcGui.Visible and t < 3 do task.wait(0.2); t += 0.2 end
        if npcGui.Visible then
            local t2 = 0
            while npcGui.Visible and t2 < 10 do task.wait(0.2); t2 += 0.2 end
            task.wait(0.5)
        end
    end
    log("OK: " .. npcName)
    return true
end

-- ═══ MỞ QUEST UI ═══
local function openQuestTab()
    local ok = pcall(function()
        local sg = plr.PlayerGui.ScreenGui
        local menus = sg:FindFirstChild("Menus")
        if not menus then return end

        -- Set Menus visible
        if menus:IsA("GuiObject") then menus.Visible = true end

        -- Tìm Quests Tab
        local childTabs = menus:FindFirstChild("ChildTabs")
        local questTab = childTabs and childTabs:FindFirstChild("Quests Tab")

        -- Force show Quests frame
        local children = menus:FindFirstChild("Children")
        local questsFrame = children and children:FindFirstChild("Quests")
        if questsFrame and questsFrame:IsA("GuiObject") then
            questsFrame.Visible = true
        end

        -- Activate tab button
        if questTab then
            pcall(function() questTab:Activate() end)
            -- VirtualInputManager click backup
            local vim = game:GetService("VirtualInputManager")
            local p = questTab.AbsolutePosition
            local sz = questTab.AbsoluteSize
            vim:SendMouseButtonEvent(p.X + sz.X/2, p.Y + sz.Y/2, 0, true, game, 1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(p.X + sz.X/2, p.Y + sz.Y/2, 0, false, game, 1)
        end
    end)
    log("Open quest tab: " .. tostring(ok))
    task.wait(0.8)
end

-- ═══ READ QUEST TASKS (chỉ NPC đủ bee req) ═══
local function getQuestTasks()
    -- Mở quest UI trước
    openQuestTab()

    local bees = countBees()
    local tasks = {}
    local allowedNPCs = {}
    for _, n in ipairs(NPC_QUESTS) do
        if bees >= n.minBees then
            allowedNPCs[n.name] = true
            local short = n.name:gsub(" Bear", ""):gsub(" Bee", "")
            allowedNPCs[short] = true
        end
    end

    pcall(function()
        local QuestF = plr.PlayerGui.ScreenGui.Menus.Children.Quests.Content
        for _, frame in pairs(QuestF:GetDescendants()) do
            if frame:IsA("Frame") and frame.Name == "QuestBox" then
                local titleBar = frame:FindFirstChild("TitleBarBG")
                local titleLabel = titleBar and titleBar:FindFirstChild("TitleBar")
                if titleLabel then
                    local title = titleLabel.Text
                    local isAllowed = false
                    for npcName in pairs(allowedNPCs) do
                        if title:find(npcName) then isAllowed = true break end
                    end
                    if isAllowed then
                        local taskBar = frame:FindFirstChild("TaskBar")
                        if taskBar then
                            for _, desc in pairs(taskBar:GetChildren()) do
                                if desc:IsA("TextLabel") and desc.Name == "Description" and desc.Text ~= "" then
                                    table.insert(tasks, {title = title, desc = desc.Text})
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

-- ═══ PARSE FIELDS FROM QUEST ═══
local function getQuestFields(questFilter)
    local tasks = getQuestTasks()
    local fields = {}
    local seen = {}
    for _, t in ipairs(tasks) do
        -- Filter theo quest title nếu có
        if questFilter and questFilter ~= "Auto" and not t.title:find(questFilter) then
            continue
        end
        local lower = t.desc:lower()
        if lower:find("collect") and lower:find("pollen") then
            for keyword, fieldName in pairs(FIELD_MAP) do
                if lower:find(keyword) and not seen[fieldName] then
                    seen[fieldName] = true
                    table.insert(fields, fieldName)
                end
            end
        end
    end
    return fields
end

-- ═══ TOKEN COLLECT (smart walk) ═══
local function isToken(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    if obj.Orientation.Z ~= 0 then return false end
    if not obj:FindFirstChild("FrontDecal") then return false end
    return true
end

local function getNearbyTokens(pos, range)
    range = range or State.CollectRange
    local list = {}
    if not workspace:FindFirstChild("Collectibles") then return list end
    for _, t in pairs(workspace.Collectibles:GetChildren()) do
        if isToken(t) and (t.Position - pos).Magnitude < range then
            table.insert(list, t)
        end
    end
    return list
end

-- ═══ MOB DETECTION ═══
local function getNearbyMobs(pos, range)
    range = range or 30
    local list = {}
    local folders = {workspace:FindFirstChild("Monsters"), workspace:FindFirstChild("FEMonsters")}
    for _, folder in ipairs(folders) do
        if folder then
            for _, mob in pairs(folder:GetChildren()) do
                if mob:IsA("Model") then
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    local part = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
                    if hum and hum.Health > 0 and part then
                        if (part.Position - pos).Magnitude < range then
                            table.insert(list, {model = mob, hum = hum, part = part})
                        end
                    end
                end
            end
        end
    end
    return list
end

-- ═══ AVOID MOB (spam nhảy đứng yên đợi mob chết) ═══
local function avoidMobs(pos)
    local mobs = getNearbyMobs(pos, 35)
    if #mobs == 0 then return false end

    log("⚠️ " .. #mobs .. " mobs detected, avoiding...")
    local startTime = tick()
    while #mobs > 0 and (tick() - startTime) < 30 and State.Running do
        -- Spam nhảy
        if hum then hum.Jump = true end
        task.wait(0.3)
        -- Re-check mobs
        mobs = getNearbyMobs(hrp.Position, 35)
    end
    log("Mobs cleared, resume farm")
    return true
end

-- ═══ CHECK IN FIELD ═══
local function isInField(field)
    if not hrp or not field then return false end
    local fp = field.Position
    local fs = field.Size
    local hp = hrp.Position
    return math.abs(hp.X - fp.X) < fs.X * 0.6
        and math.abs(hp.Z - fp.Z) < fs.Z * 0.6
        and math.abs(hp.Y - fp.Y) < 30
end

-- ═══ SMART WALK ═══
local function smartWalk(targetPos)
    if not hum or not hrp then refresh() end
    if not hum then return end
    hum.WalkSpeed = State.FarmSpeed
    hum:MoveTo(targetPos)
    local conn
    local arrived = false
    conn = hum.MoveToFinished:Connect(function() arrived = true end)
    local t0 = tick()
    while not arrived and (tick() - t0) < 5 do
        task.wait(0.1)
        if (hrp.Position - targetPos).Magnitude < 5 then arrived = true end
    end
    if conn then conn:Disconnect() end
end

-- ═══ SMART FARM FIELD ═══
local function smartFarm(fieldName, duration)
    duration = duration or 30
    log("Smart farm: " .. fieldName)
    local f = workspace.FlowerZones:FindFirstChild(fieldName)
    if not f then log("Field not found: " .. fieldName) return end

    local p = f.Position
    local s = f.Size
    local range = f:FindFirstChild("Range") and f.Range.Value or 60

    -- Tween đến field
    tween(CFrame.new(p.X, p.Y + 3, p.Z))
    task.wait(0.3)

    if hum then hum.WalkSpeed = State.FarmSpeed end

    local stepX = math.min(s.X * 0.4, range)
    local stepZ = math.min(s.Z * 0.4, range)

    local t0 = tick()
    while (tick() - t0) < duration and State.Running do
        -- ✅ Check rơi khỏi field -> tween lại
        if not isInField(f) then
            log("Rơi khỏi field, tween lại...")
            tween(CFrame.new(p.X, p.Y + 3, p.Z))
            task.wait(0.3)
            if hum then hum.WalkSpeed = State.FarmSpeed end
        end

        -- ✅ Check mob -> avoid
        avoidMobs(hrp.Position)

        -- Auto collect tokens
        if State.AutoCollect and workspace:FindFirstChild("Collectibles") then
            local tokens = getNearbyTokens(hrp.Position, range)
            for _, tok in ipairs(tokens) do
                if not State.Running then break end
                if tok.Parent and (tok.Position - hrp.Position).Magnitude < range then
                    smartWalk(tok.Position + Vector3.new(0, 1, 0))
                    -- Re-check field & mob
                    if not isInField(f) then break end
                end
            end
        end

        -- Zigzag pattern
        for row = -2, 2 do
            for col = -2, 2 do
                if (tick() - t0) >= duration or not State.Running then break end
                -- Check mob trước mỗi step
                avoidMobs(hrp.Position)

                local tx = p.X + (col * 0.5) * stepX
                local tz = p.Z + (row * 0.5) * stepZ
                smartWalk(Vector3.new(tx, p.Y + 3, tz))

                -- Re-check field
                if not isInField(f) then
                    tween(CFrame.new(p.X, p.Y + 3, p.Z))
                    if hum then hum.WalkSpeed = State.FarmSpeed end
                end

                -- Collect token gần
                if State.AutoCollect and workspace:FindFirstChild("Collectibles") then
                    for _, tok in pairs(workspace.Collectibles:GetChildren()) do
                        if isToken(tok) and (tok.Position - hrp.Position).Magnitude < 20 then
                            smartWalk(tok.Position + Vector3.new(0, 1, 0))
                        end
                    end
                end
            end
        end
    end

    if hum then hum.WalkSpeed = State.NormalSpeed end
end

-- ═══ MAIN ACTIONS ═══
function doAcceptQuests()
    local bees = countBees()
    log("Accept quests | Bees: " .. bees)
    for _, info in ipairs(NPC_QUESTS) do
        if bees >= info.minBees then
            if npcHasAlert(info.name) then
                log("Alert: " .. info.name)
                talkNPC(info.name, info.pos)
                task.wait(1)
            else
                log("Skip " .. info.name)
            end
        end
        if not State.Running then return end
    end
end

function doFarmQuest()
    local fields = getQuestFields(State.SelectedQuest)
    if #fields == 0 then
        log("No quest fields, default Dandelion")
        smartFarm("Dandelion Field", 30)
        return
    end
    log("Farm quest fields: " .. #fields)
    for _, f in ipairs(fields) do
        if not State.Running then return end
        smartFarm(f, 30)
        task.wait(0.5)
    end
end

function getQuestList()
    local list = {"Auto"}
    local tasks = getQuestTasks()
    local seen = {Auto = true}
    for _, t in ipairs(tasks) do
        if not seen[t.title] then
            seen[t.title] = true
            table.insert(list, t.title)
        end
    end
    return list
end

-- ═══ GUI ═══
local function createGUI()
    local g = Instance.new("ScreenGui")
    g.Name = "FunctestUI"
    g.ResetOnSpawn = false
    g.Parent = plr:WaitForChild("PlayerGui")

    local main = Instance.new("Frame", g)
    main.Size = UDim2.new(0, 250, 0, 280)
    main.Position = UDim2.new(0, 10, 0, 100)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    title.Text = "🐝 BSS Functest"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.BorderSizePixel = 0
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

    -- Quest selector dropdown
    local qLabel = Instance.new("TextLabel", main)
    qLabel.Size = UDim2.new(1, -10, 0, 20)
    qLabel.Position = UDim2.new(0, 5, 0, 35)
    qLabel.Text = "Quest:"
    qLabel.TextColor3 = Color3.new(1, 1, 1)
    qLabel.BackgroundTransparency = 1
    qLabel.Font = Enum.Font.Gotham
    qLabel.TextSize = 12
    qLabel.TextXAlignment = Enum.TextXAlignment.Left

    local qBox = Instance.new("TextButton", main)
    qBox.Size = UDim2.new(1, -10, 0, 30)
    qBox.Position = UDim2.new(0, 5, 0, 55)
    qBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    qBox.Text = "Auto (all)"
    qBox.TextColor3 = Color3.new(1, 1, 1)
    qBox.Font = Enum.Font.Gotham
    qBox.TextSize = 12
    qBox.BorderSizePixel = 0
    Instance.new("UICorner", qBox).CornerRadius = UDim.new(0, 4)

    local dropdown = Instance.new("ScrollingFrame", main)
    dropdown.Size = UDim2.new(1, -10, 0, 120)
    dropdown.Position = UDim2.new(0, 5, 0, 88)
    dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dropdown.Visible = false
    dropdown.ScrollBarThickness = 4
    dropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
    dropdown.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 4)
    local layout = Instance.new("UIListLayout", dropdown)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    qBox.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
        if dropdown.Visible then
            -- Refresh list
            for _, c in pairs(dropdown:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, q in ipairs(getQuestList()) do
                local b = Instance.new("TextButton", dropdown)
                b.Size = UDim2.new(1, 0, 0, 25)
                b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                b.TextColor3 = Color3.new(1, 1, 1)
                b.Text = q
                b.Font = Enum.Font.Gotham
                b.TextSize = 11
                b.BorderSizePixel = 0
                b.MouseButton1Click:Connect(function()
                    State.SelectedQuest = q
                    qBox.Text = q:sub(1, 30)
                    dropdown.Visible = false
                end)
            end
        end
    end)

    -- Buttons
    local function btn(text, y, color, onClick)
        local b = Instance.new("TextButton", main)
        b.Size = UDim2.new(1, -10, 0, 32)
        b.Position = UDim2.new(0, 5, 0, y)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    btn("📋 Accept Quests", 95, Color3.fromRGB(70, 130, 200), function()
        State.Running = true
        task.spawn(doAcceptQuests)
    end)

    btn("🌻 Farm Quest", 132, Color3.fromRGB(70, 180, 70), function()
        State.Running = true
        task.spawn(doFarmQuest)
    end)

    btn("🔄 Loop (Accept + Farm)", 169, Color3.fromRGB(180, 130, 70), function()
        State.Running = true
        task.spawn(function()
            while State.Running do
                doAcceptQuests()
                task.wait(1)
                doFarmQuest()
                task.wait(1)
            end
        end)
    end)

    btn("⏹ STOP", 206, Color3.fromRGB(200, 50, 50), function()
        State.Running = false
        if hum then hum.WalkSpeed = State.NormalSpeed end
        log("STOPPED")
    end)

    local status = Instance.new("TextLabel", main)
    status.Size = UDim2.new(1, -10, 0, 30)
    status.Position = UDim2.new(0, 5, 0, 243)
    status.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    status.Text = "Ready"
    status.TextColor3 = Color3.fromRGB(150, 255, 150)
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.BorderSizePixel = 0
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 4)

    -- Update status
    task.spawn(function()
        while g.Parent do
            status.Text = string.format("Bees: %d | %s | Speed: %d",
                countBees(),
                State.Running and "RUNNING" or "Idle",
                hum and hum.WalkSpeed or 16)
            task.wait(1)
        end
    end)
end

createGUI()
log("=== FUNCTEST READY ===")
