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

-- ═══ NPC CONFIG ═══
local NPC_QUESTS = {
    {name = "Black Bear",   pos = Vector3.new(-255.79, 6, 296.78),  minBees = 0},
    {name = "Mother Bear",  pos = Vector3.new(-179.00, 6, 87.75),   minBees = 0},
    {name = "Panda Bear",   pos = Vector3.new(104.29,  36, 48.47),  minBees = 5},
    {name = "Brown Bear",   pos = Vector3.new(281.35,  46, 236.98), minBees = 10},
    {name = "Polar Bear",   pos = Vector3.new(-106.61, 120, -77.14),minBees = 15},
    {name = "Science Bear", pos = Vector3.new(268.63,  104, 19.67), minBees = 20},
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

-- ═══ TALK NPC (cách đúng từ script mẫu) ═══
local function talkNPC(npcName, pos)
    log("Talk: " .. npcName)

    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then log("FAIL: NPC not found") return false end

    -- Tween đến platform
    tween(CFrame.new(pos))
    task.wait(0.5)
    hrp.CFrame = CFrame.new(pos)
    task.wait(0.5)

    -- Dùng Activatables.NPCs.ButtonEffect (cách script mẫu dùng)
    local ok = pcall(function()
        local cac = require(RS:WaitForChild("Activatables"):WaitForChild("NPCs"))
        cac.ButtonEffect(plr, npc)
    end)
    log("ButtonEffect ok: " .. tostring(ok))

    -- Đợi NPC dialog hiện rồi tự skip (RunService loop đã handle)
    local npcGui = plr.PlayerGui.ScreenGui.NPC
    local t = 0
    while not npcGui.Visible and t < 5 do
        task.wait(0.2); t += 0.2
    end

    if npcGui.Visible then
        log("Dialog open, waiting for close...")
        -- Đợi dialog đóng (IncrementDialogue loop tự skip)
        local t2 = 0
        while npcGui.Visible and t2 < 15 do
            task.wait(0.2); t2 += 0.2
        end
        task.wait(1)
        log("OK: " .. npcName)
        return true
    else
        log("FAIL: dialog not visible")
        return false
    end
end

-- ═══ MAIN ═══
function checkAndDoQuests()
    local bees = countBees()
    log("Bees: " .. bees)

    if hasActiveQuest() then
        log("Already has quest, skip")
        return
    end

    local bestNPC = nil
    for _, npc in ipairs(NPC_QUESTS) do
        if bees >= npc.minBees then bestNPC = npc end
    end

    if bestNPC then
        log("Best NPC: " .. bestNPC.name)
        talkNPC(bestNPC.name, bestNPC.pos)
    else
        log("No NPC for " .. bees .. " bees")
    end
end

log("=== FUNCTEST START ===")
checkAndDoQuests()
log("=== FUNCTEST END ===")
