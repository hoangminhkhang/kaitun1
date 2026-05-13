-- BSS Kaitun | functest: Auto Quest theo bee count
-- Cách đúng từ script mẫu: require(Activatables.NPCs).ButtonEffect + IncrementDialogue
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local plr = game:GetService("Players").LocalPlayer

local E = RS:WaitForChild("Events")
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
plr.CharacterAdded:Connect(function(c) char = c hrp = c:WaitForChild("HumanoidRootPart") end)

local function log(m) print("[functest] " .. m) end

-- ═══ NPC CONFIG (theo zone đúng) ═══
local NPC_QUESTS = {
    -- 0 bees (Hub)
    {name = "Black Bear",   pos = Vector3.new(-256, 6, 297),    minBees = 0},
    {name = "Mother Bear",  pos = Vector3.new(-179, 6, 87),     minBees = 0},
    {name = "Brown Bear",   pos = Vector3.new(281, 46, 237),    minBees = 0},
    -- 5 bees
    {name = "Panda Bear",   pos = Vector3.new(104, 36, 48),     minBees = 5},
    -- 10 bees
    {name = "Science Bear", pos = Vector3.new(269, 104, 20),    minBees = 10},
    -- 15 bees
    {name = "Honey Bee",    pos = Vector3.new(-387, 90, -220),  minBees = 15},
    {name = "Polar Bear",   pos = Vector3.new(-107, 120, -77),  minBees = 15},
    -- 35 bees
    {name = "Spirit Bear",  pos = Vector3.new(-365, 98, 479),   minBees = 35},
}

-- ═══ NOCLIP ═══
RunService.Stepped:Connect(function()
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ═══ AUTO SKIP DIALOG (RunService loop) ═══
-- Script mẫu dùng: plr.PlayerGui.Camera.Controllers.NPC.IncrementDialogue:Invoke()
RunService.Stepped:Connect(function()
    if plr.PlayerGui.ScreenGui.NPC.Visible then
        pcall(function()
            plr.PlayerGui.Camera.Controllers.NPC.IncrementDialogue:Invoke()
        end)
    end
end)

-- ═══ TWEEN ═══
local function tween(cf)
    local d = (hrp.Position - cf.Position).Magnitude
    if d < 4 then hrp.CFrame = cf return end
    local tw = TS:Create(hrp, TweenInfo.new(d/130, Enum.EasingStyle.Linear), {CFrame = cf})
    tw:Play(); tw.Completed:Wait(); task.wait(0.2)
end

-- ═══ COUNT BEES ═══
local function countBees()
    for _, h in pairs(workspace.Honeycombs:GetChildren()) do
        if h:IsA("Model") and h:FindFirstChild("Owner") and h.Owner.Value == plr then
            if not h:FindFirstChild("Cells") then return 0 end
            local n = 0
            for _, cell in pairs(h.Cells:GetChildren()) do
                local ct = cell:FindFirstChild("CellType")
                if ct and ct.Value ~= "Empty" and ct.Value ~= "" then n += 1 end
            end
            return n
        end
    end
    return 0
end

-- ═══ CHECK QUEST ACTIVE ═══
local function getQuestName(npcName)
    -- Đọc từ quest UI
    local ok, result = pcall(function()
        local QuestF = plr.PlayerGui.ScreenGui.Menus.Children.Quests.Content
        for _, v in pairs(QuestF:GetChildren()) do
            if v:FindFirstChild("QuestBox") then
                local title = v.QuestBox:FindFirstChild("TitleBarBG")
                if title and title:FindFirstChild("TitleBar") then
                    local t = title.TitleBar.Text
                    if npcName and t:find(npcName:gsub(" Bear",""):gsub(" Bee","")) then
                        return t
                    elseif not npcName then
                        return t
                    end
                end
            end
        end
    end)
    return ok and result or nil
end

local function hasActiveQuest()
    local q = getQuestName(nil)
    if q and q ~= "" then
        log("Active quest: " .. q)
        return true
    end
    return false
end

-- ═══ TALK NPC (gọi 2 lần để nhận cả quest thường + Beesmas) ═══
local function talkNPC(npcName, pos)
    log("Talk: " .. npcName)

    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then log("FAIL: NPC not found") return false end

    -- Tween đến platform
    tween(CFrame.new(pos))
    task.wait(0.5)
    hrp.CFrame = CFrame.new(pos)
    task.wait(0.5)

    -- Gọi ButtonEffect 2 lần (lần 1 nhận quest thường, lần 2 nhận Beesmas/Give Present)
    for i = 1, 2 do
        local ok = pcall(function()
            local cac = require(RS:WaitForChild("Activatables"):WaitForChild("NPCs"))
            cac.ButtonEffect(plr, npc)
        end)
        log("ButtonEffect " .. i .. ": " .. tostring(ok))

        -- Đợi dialog hiện
        local npcGui = plr.PlayerGui.ScreenGui.NPC
        local t = 0
        while not npcGui.Visible and t < 5 do
            task.wait(0.2); t += 0.2
        end

        if npcGui.Visible then
            -- Đợi dialog đóng (IncrementDialogue tự skip)
            local t2 = 0
            while npcGui.Visible and t2 < 12 do
                task.wait(0.2); t2 += 0.2
            end
            task.wait(1)
        end
    end
    log("OK: " .. npcName)
    return true
end

-- ═══ FIELD MAP (parse quest description -> field name) ═══
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

-- ═══ ĐỌC QUEST TASKS TỪ UI (chỉ NPC đủ bee req) ═══
local function getQuestTasks()
    local bees = countBees()
    local tasks = {}

    -- Tạo set NPC đủ điều kiện
    local allowedNPCs = {}
    for _, n in ipairs(NPC_QUESTS) do
        if bees >= n.minBees then
            allowedNPCs[n.name] = true
            -- Cho cả tên rút gọn (bỏ "Bear"/"Bee")
            local short = n.name:gsub(" Bear", ""):gsub(" Bee", "")
            allowedNPCs[short] = true
        end
    end

    pcall(function()
        local QuestF = plr.PlayerGui.ScreenGui.Menus.Children.Quests.Content
        -- Mỗi quest box có TitleBar (tên NPC) + TaskBar (descriptions)
        for _, frame in pairs(QuestF:GetDescendants()) do
            if frame:IsA("Frame") and frame.Name == "QuestBox" then
                -- Đọc title NPC
                local titleBar = frame:FindFirstChild("TitleBarBG")
                local titleLabel = titleBar and titleBar:FindFirstChild("TitleBar")
                if not titleLabel then continue end
                local title = titleLabel.Text -- VD: "Black Bear's Honey Wreath"

                -- Check NPC có trong allowed list không
                local isAllowed = false
                for npcName in pairs(allowedNPCs) do
                    if title:find(npcName) then
                        isAllowed = true
                        break
                    end
                end

                if isAllowed then
                    -- Lấy tất cả Description từ quest này
                    local taskBar = frame:FindFirstChild("TaskBar")
                    if taskBar then
                        for _, desc in pairs(taskBar:GetChildren()) do
                            if desc:IsA("TextLabel") and desc.Name == "Description" and desc.Text ~= "" then
                                table.insert(tasks, desc.Text)
                                log("Task[" .. title .. "]: " .. desc.Text:sub(1, 40))
                            end
                        end
                    end
                else
                    log("Skip quest: " .. title .. " (NPC out of bee req)")
                end
            end
        end
    end)
    return tasks
end

-- ═══ PARSE FIELDS CẦN FARM ═══
local function getQuestFields()
    local tasks = getQuestTasks()
    log("Quest tasks: " .. #tasks)
    local fields = {}
    local seen = {}
    for _, desc in ipairs(tasks) do
        local lower = desc:lower()
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

-- ═══ FARM FIELD ═══
local function farmField(fieldName, duration)
    duration = duration or 30
    log("Farm: " .. fieldName)
    local f = workspace.FlowerZones:FindFirstChild(fieldName)
    if not f then log("Field not found: " .. fieldName) return end
    local p = f.Position
    local s = f.Size
    tween(CFrame.new(p.X, p.Y + 3, p.Z))
    task.wait(0.5)
    local t0 = tick()
    while (tick() - t0) < duration do
        for row = -2, 2 do
            for col = -2, 2 do
                if (tick() - t0) >= duration then return end
                tween(CFrame.new(p.X + col * s.X * 0.18, p.Y + 3, p.Z + row * s.Z * 0.18))
                task.wait(0.15)
            end
        end
    end
end

-- ═══ FARM THEO QUEST ═══
function farmQuestFields()
    local fields = getQuestFields()
    if #fields == 0 then
        log("No quest fields, default farm Dandelion")
        farmField("Dandelion Field", 30)
        return
    end
    for _, fieldName in ipairs(fields) do
        farmField(fieldName, 30)
        task.wait(0.5)
    end
end

-- ═══ TÌM TẤT CẢ NPC QUEST BEARS ═══
local function getAllQuestNPCs()
    local list = {}
    -- Blacklist NPC không nhận quest từ
    local blacklist = {
        ["Ant Challenge Info"] = true,
        ["Wind Shrine"] = true,
        ["Bubble Bee Man 2"] = true,
        ["Stick Bug"] = true,
        ["Onett"] = true,
        ["Gummy Bear"] = true,
    }
    for _, npc in pairs(workspace.NPCs:GetChildren()) do
        if npc:IsA("Model") and not blacklist[npc.Name] then
            local platform = npc:FindFirstChild("Platform")
            local circle = npc:FindFirstChild("Circle")
            if platform and platform:IsA("BasePart") and circle then
                table.insert(list, {
                    name = npc.Name,
                    pos = platform.Position + Vector3.new(0, 5, 0),
                    npc = npc,
                })
            end
        end
    end
    return list
end

-- ═══ CHECK NPC CÓ QUEST AVAILABLE ═══
-- Game hiện AlertGui (chấm than vàng) trên NPC khi có quest sẵn
local function npcHasAlert(npcName)
    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then return false end
    local platform = npc:FindFirstChild("Platform")
    if not platform then return false end
    local alertPos = platform:FindFirstChild("AlertPos")
    if not alertPos then return false end
    local alertGui = alertPos:FindFirstChild("AlertGui")
    if not alertGui then return false end
    -- Có ImageLabel với ImageTransparency = 0 nghĩa là alert visible
    for _, child in pairs(alertGui:GetDescendants()) do
        if child:IsA("ImageLabel") and child.ImageTransparency == 0 then
            return true
        end
    end
    return false
end

-- ═══ MAIN ═══
function checkAndDoQuests()
    local bees = countBees()
    log("Bees: " .. bees)

    for _, info in ipairs(NPC_QUESTS) do
        if bees >= info.minBees then
            -- Check NPC có alert (chấm than vàng) - chỉ talk khi có quest available
            if npcHasAlert(info.name) then
                log("Alert ON: " .. info.name)
                talkNPC(info.name, info.pos)
                task.wait(1)
            else
                log("Skip " .. info.name .. " (no alert - already has quest)")
            end
        end
    end
    log("All quests checked")
end

log("=== FUNCTEST START ===")
checkAndDoQuests()
log("=== FUNCTEST END ===")
