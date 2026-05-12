-- BSS Kaitun | functest: Auto Quest theo bee count
-- Mỗi lần hatch xong gọi checkAndDoQuests()
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer

local E = RS:WaitForChild("Events")
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
plr.CharacterAdded:Connect(function(c) char = c hrp = c:WaitForChild("HumanoidRootPart") end)

local function log(m) print("[functest] " .. m) end
local function fire(name, ...)
    local r = E:FindFirstChild(name)
    if not r then return end
    pcall(r.FireServer, r, ...)
end

-- ═══ NPC CONFIG: tên, vị trí circle, yêu cầu bee tối thiểu ═══
local NPC_QUESTS = {
    {name = "Black Bear",   pos = Vector3.new(-255.79, 4, 296.78),  minBees = 0},
    {name = "Mother Bear",  pos = Vector3.new(-179.00, 4, 87.75),   minBees = 0},
    {name = "Panda Bear",   pos = Vector3.new(104.29,  34, 48.47),  minBees = 5},
    {name = "Brown Bear",   pos = Vector3.new(281.35,  44, 236.98), minBees = 10},
    {name = "Polar Bear",   pos = Vector3.new(-106.61, 118, -77.14),minBees = 15},
    {name = "Science Bear", pos = Vector3.new(268.63,  102, 19.67), minBees = 20},
}

-- ═══ NOCLIP ═══
local noclip = true
game:GetService("RunService").Stepped:Connect(function()
    if noclip and char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
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

-- ═══ CHECK QUEST UI ═══
local function hasActiveQuest()
    local sg = plr.PlayerGui:FindFirstChild("ScreenGui")
    if not sg then return false end
    local menus = sg:FindFirstChild("Menus")
    if not menus then return false end
    -- Mở quest tab
    local childTabs = menus:FindFirstChild("ChildTabs")
    local questTab = childTabs and childTabs:FindFirstChild("Quests Tab")
    if questTab then
        pcall(function() questTab:Activate() end)
        task.wait(0.5)
    end
    -- Đọc title
    local frame = menus:FindFirstChild("Children")
    frame = frame and frame:FindFirstChild("Quests")
    frame = frame and frame:FindFirstChild("Content")
    frame = frame and frame:FindFirstChild("Frame")
    if not frame then return false end
    local qbox = frame:FindFirstChild("QuestBox")
    local title = qbox and qbox:FindFirstChild("TitleBarBG")
    title = title and title:FindFirstChild("TitleBar")
    if title and title.Text ~= "" and not title.Text:lower():find("no quest") then
        log("Active quest: " .. title.Text)
        return true
    end
    return false
end

-- ═══ CLICK ACTIVATE BUTTON ═══
local function clickActivate()
    local sg = plr.PlayerGui:FindFirstChild("ScreenGui")
    local btn = sg and sg:FindFirstChild("ActivateButton")
    if not btn or not btn.Visible then return false end
    pcall(function() btn:Activate() end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local p = btn.AbsolutePosition
        local s = btn.AbsoluteSize
        vim:SendMouseButtonEvent(p.X + s.X/2, p.Y + s.Y/2, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(p.X + s.X/2, p.Y + s.Y/2, 0, false, game, 1)
    end)
    task.wait(0.5)
    return true
end

-- ═══ TALK NPC + SKIP DIALOG ═══
local function talkNPC(npcName, pos)
    log("Talk: " .. npcName)

    local npc = workspace.NPCs:FindFirstChild(npcName)
    local circle = npc and npc:FindFirstChild("Circle")

    -- Dùng MoveTo để walk vào circle (trigger touch detection)
    local hum = char:FindFirstChild("Humanoid")
    if hum and circle then
        hum:MoveTo(circle.Position)
        hum.MoveToFinished:Wait()
        task.wait(0.5)
    else
        tween(CFrame.new(pos))
        task.wait(0.5)
    end

    -- Đợi ActivateButton hiện
    local sg = plr.PlayerGui:FindFirstChild("ScreenGui")
    local btn = sg and sg:FindFirstChild("ActivateButton")
    local t = 0
    while btn and not btn.Visible and t < 5 do
        task.wait(0.2); t += 0.2
    end

    if btn and btn.Visible then
        log("Clicking ActivateButton...")
        clickActivate()
        task.wait(0.5)
        -- Spam skip dialog để nhận quest
        for i = 1, 12 do
            fire("SelectNPCOption", 1)
            task.wait(0.25)
        end
        log("OK: " .. npcName)
        return true
    else
        log("FAIL: ActivateButton not visible after 5s")
        return false
    end
end

-- ═══ MAIN: CHECK VÀ NHẬN QUEST THEO BEE COUNT ═══
function checkAndDoQuests()
    local bees = countBees()
    log("Bees: " .. bees)

    -- Nếu đã có quest active thì skip
    if hasActiveQuest() then
        log("Already has quest, skip")
        return
    end

    -- Tìm NPC phù hợp nhất (bee đủ điều kiện, ưu tiên NPC cao nhất)
    local bestNPC = nil
    for _, npc in ipairs(NPC_QUESTS) do
        if bees >= npc.minBees then
            bestNPC = npc
        end
    end

    if bestNPC then
        log("Best NPC: " .. bestNPC.name .. " (min " .. bestNPC.minBees .. " bees)")
        talkNPC(bestNPC.name, bestNPC.pos)
    else
        log("No NPC available for " .. bees .. " bees")
    end
end

-- TEST CHẠY THỬ
log("=== FUNCTEST START ===")
checkAndDoQuests()
log("=== FUNCTEST END ===")
