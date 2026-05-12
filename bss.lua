-- BSS Kaitun | functest: tween đến NPC + nhận quest
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer

local E = RS:WaitForChild("Events")
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local function log(m) print("[functest] " .. m) end

local function fire(name, ...)
    local r = E:FindFirstChild(name)
    if not r then log("MISS: " .. name) return end
    pcall(r.FireServer, r, ...)
end

local function tween(cf)
    local d = (hrp.Position - cf.Position).Magnitude
    if d < 4 then hrp.CFrame = cf return end
    local tw = TS:Create(hrp, TweenInfo.new(d/130, Enum.EasingStyle.Linear), {CFrame = cf})
    tw:Play(); tw.Completed:Wait(); task.wait(0.2)
end

local function clickActivateButton()
    local sg = plr.PlayerGui:FindFirstChild("ScreenGui")
    local btn = sg and sg:FindFirstChild("ActivateButton")
    if not btn or not btn.Visible then return false end
    pcall(function() btn:Activate() end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local pos = btn.AbsolutePosition
        vim:SendMouseButtonEvent(pos.X + btn.AbsoluteSize.X/2, pos.Y + btn.AbsoluteSize.Y/2, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(pos.X + btn.AbsoluteSize.X/2, pos.Y + btn.AbsoluteSize.Y/2, 0, false, game, 1)
    end)
    task.wait(0.5)
    return true
end

local function doQuest(npcName)
    log("Quest: " .. npcName)

    -- Tween đến circle NPC
    local npc = workspace.NPCs:FindFirstChild(npcName)
    if not npc then log("FAIL: NPC not found") return end

    local circle = npc:FindFirstChild("Circle")
    local targetPos = circle
        and (circle.Position + Vector3.new(0, 3, 0))
        or (npcName == "Black Bear" and Vector3.new(-256, 5, 297) or Vector3.new(-179, 5, 87))

    tween(CFrame.new(targetPos))
    task.wait(0.5)

    if circle and hrp then
        hrp.CFrame = CFrame.new(circle.Position + Vector3.new(0, 3, 0))
    end
    task.wait(0.5)

    -- Fire touch
    if circle then
        pcall(function() firetouchinterest(hrp, circle, 0) task.wait(0.1) firetouchinterest(hrp, circle, 1) end)
    end

    -- Đợi ActivateButton hiện
    local sg = plr.PlayerGui:FindFirstChild("ScreenGui")
    local btn = sg and sg:FindFirstChild("ActivateButton")
    local waited = 0
    while btn and not btn.Visible and waited < 5 do
        task.wait(0.2); waited += 0.2
    end

    if btn and btn.Visible then
        log("ActivateButton visible! Text: " .. (btn:FindFirstChild("TextBox") and btn.TextBox.Text or "?"))
        clickActivateButton()
        task.wait(0.5)
        -- Spam skip dialog
        for i = 1, 10 do
            fire("SelectNPCOption", 1)
            task.wait(0.3)
        end
        log("OK: quest " .. npcName)
    else
        log("FAIL: ActivateButton not visible after 5s")
    end
end

-- TEST
log("=== START FUNCTEST ===")
doQuest("Black Bear")
task.wait(2)
doQuest("Mother Bear")
log("=== END FUNCTEST ===")
