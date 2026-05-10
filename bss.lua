--[[
    Kaitun BSS Auto v4.0 - Delta X
    All features auto-enabled on start
    Auto: Claim Hive → Redeem Codes → Buy Acc → Hatch Eggs → Quest ALL NPCs → Farm
]]

-- ═══════════════ SERVICES ═══════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local plr = Players.LocalPlayer
local Events = RS:WaitForChild("Events")
local ItemPkg = Events:WaitForChild("ItemPackageEvent")
local HiveCellEgg = Events:WaitForChild("ConstructHiveCellFromEgg")
local StatsRemote = Events:WaitForChild("RetrievePlayerStats")
local ClaimHiveR = Events:WaitForChild("ClaimHive")
local HiveCmd = Events:WaitForChild("PlayerHiveCommand")
local ToolCollect = Events:WaitForChild("ToolCollect")

-- ═══════════════ CONFIG ═══════════════
local CFG = {
    TARGET_BEES = 20,
    FIELD = "Sunflower Field",
    CONVERT_AT = 95,
    RUNNING = true,
}

-- ═══════════════ DATA ═══════════════
local ACCESSORIES = {
    {n="Helmet",c=3e4},{n="Basic Boots",c=5e4},{n="Belt Pocket",c=5e4},
    {n="Brave Guard",c=3e5},{n="Hasty Guard",c=3e5},{n="Bomber Guard",c=3e5},
    {n="Looker Guard",c=3e5},{n="Parachute",c=5e5},
    {n="Blue Guard",c=1e6},{n="Red Guard",c=1e6},{n="Mondo Belt Bag",c=1.5e6},
    {n="Propeller Hat",c=2.5e6},{n="Hiking Boots",c=2.5e6},
    {n="Elite Blue Guard",c=3e6},{n="Elite Red Guard",c=3e6},
    {n="Glider",c=5e6},{n="Beekeeper's Boots",c=1.5e7},
    {n="Beekeeper's Mask",c=2e7},
}

local FIELDS = {
    "Sunflower Field","Dandelion Field","Mushroom Field","Blue Flower Field",
    "Clover Field","Spider Field","Strawberry Field","Bamboo Field",
    "Pineapple Patch","Stump Field","Cactus Field","Pumpkin Patch",
    "Pine Tree Forest","Rose Field","Mountain Top Field","Coconut Field",
}

local QUEST_NPCS = {
    "Black Bear","Brown Bear","Mother Bear","Polar Bear","Science Bear",
    "Dapper Bear","Panda Bear","Riley Bee","Bucko Bee","Stick Bug",
}

local PROMO_CODES = {
    "Wax","Teespring","Bopmaster","CogsBees","Luther","Millie","Troggles",
    "WordFactory","Connoisseur","Jumpstart","Cubly","FuzzyReboot","Mocito100T",
    "1MLikes","PlushFriday","ByeByeBackpack","SugarRush","Gumaden",
    "ClubConverters","SecretProfileCode","Roof","Crab","Crawlers",
    "Buzz","Nectar","Soup","Valentine","RebootFriday","AccentMaster",
    "FourYearFiesta","BeesBuzz123","Discord100k","Sure","Xmas",
}

-- ═══════════════ CORE HELPERS ═══════════════
local function log(msg)
    print("[Kaitun] " .. msg)
    pcall(function() game.StarterGui:SetCore("SendNotification",{Title="Kaitun",Text=msg,Duration=3}) end)
end

local function tp(cf)
    pcall(function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = cf
        end
    end)
end

local function getHoney()
    local s,r=pcall(function() return plr.CoreStats.Honey.Value end); return s and r or 0
end
local function getPollen()
    local s,r=pcall(function() return plr.CoreStats.Pollen.Value end); return s and r or 0
end
local function getCap()
    local s,r=pcall(function() return plr.CoreStats.Capacity.Value end); return s and r or 100
end
local function fmt(n)
    if n>=1e9 then return ("%.1fB"):format(n/1e9) elseif n>=1e6 then return ("%.1fM"):format(n/1e6)
    elseif n>=1e3 then return ("%.1fK"):format(n/1e3) else return tostring(math.floor(n)) end
end

local function getHive()
    for _,h in pairs(WS.Honeycombs:GetChildren()) do
        if h:FindFirstChild("Owner") and tostring(h.Owner.Value)==plr.Name then return h end
    end
end

local function getBees()
    local c=0; local h=getHive()
    if h and h:FindFirstChild("Cells") then
        for _,cell in pairs(h.Cells:GetChildren()) do
            if cell:FindFirstChild("CellType") then
                local t=tostring(cell.CellType.Value)
                if t~="Empty" and t~="nil" and t~="" then c=c+1 end
            end
        end
    end; return c
end

local function getEmptySlot()
    local h=getHive()
    if h and h:FindFirstChild("Cells") then
        for _,cell in pairs(h.Cells:GetChildren()) do
            if cell:FindFirstChild("CellType") then
                local t=tostring(cell.CellType.Value)
                if t=="Empty" or t=="nil" or t=="" then
                    local x,y=cell.Name:match("C(%d+),(%d+)")
                    if x and y then return tonumber(x),tonumber(y) end
                end
            end
        end
    end
end

local function getEggs(name)
    local c=0
    pcall(function()
        local s=StatsRemote:InvokeServer()
        if s and s.Eggs and s.Eggs[name] then c=s.Eggs[name] end
    end); return c
end

local function purchase(cat,typ,amt)
    local d={Category=cat,Type=typ}; if amt then d.Amount=amt end
    local s,r=pcall(function() return ItemPkg:InvokeServer("Purchase",d) end)
    return s and r
end

local function getField(name)
    local s,r=pcall(function() return WS.FlowerZones:FindFirstChild(name) end)
    return s and r or nil
end

local function alive()
    return plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        and plr.Character:FindFirstChild("Humanoid")
        and plr.Character.Humanoid.Health > 0
end

-- ═══════════════ STEP 0: CLAIM HIVE ═══════════════
local function claimHive()
    if getHive() then log("✅ Hive OK") return true end
    log("🏠 Claiming hive...")
    local combs=WS.Honeycombs:GetChildren()
    for att=1,20 do
        for i=#combs,1,-1 do
            local h=combs[i]
            if h:FindFirstChild("Owner") and tostring(h.Owner.Value)=="nil" then
                pcall(function()
                    if h:FindFirstChild("LightHolder") then tp(h.LightHolder.CFrame) end
                end)
                task.wait(1)
                pcall(function()
                    if h:FindFirstChild("HiveID") then ClaimHiveR:FireServer(h.HiveID.Value) end
                end)
                task.wait(2)
                if getHive() then log("🎉 Hive claimed!") return true end
                break
            end
        end
        task.wait(2)
    end
    log("❌ Claim hive failed"); return false
end

-- ═══════════════ STEP 1: REDEEM CODES ═══════════════
local function redeemCodes()
    log("🎟️ Redeeming " .. #PROMO_CODES .. " codes...")
    for i,code in ipairs(PROMO_CODES) do
        pcall(function() require(RS.PromoCodes).Redeem(code) end)
        pcall(function() require(RS.Events).ClientCall("PromoCodeEvent", code) end)
        if i % 5 == 0 then log("🎟️ " .. i .. "/" .. #PROMO_CODES) end
        task.wait(0.8)
    end
    log("🎟️ All codes done!")
end

-- ═══════════════ STEP 2: BUY ACCESSORIES ═══════════════
local function buyAccessories()
    log("🛒 Buying accessories...")
    local bought=0
    for _,a in ipairs(ACCESSORIES) do
        if getHoney() >= a.c then
            if purchase("Accessory", a.n) then
                bought=bought+1
                log("✅ " .. a.n)
            end
            task.wait(0.5)
        end
    end
    log("🛒 Bought " .. bought .. " items")
end

-- ═══════════════ STEP 3: HATCH EGGS ═══════════════
local function hatchAllEggs()
    log("🥚 Hatching to " .. CFG.TARGET_BEES .. " bees...")
    while CFG.RUNNING do
        local bees = getBees()
        if bees >= CFG.TARGET_BEES then
            log("🎉 " .. bees .. " bees reached!")
            break
        end

        local x,y = getEmptySlot()
        if not x then
            -- Buy slot
            purchase("HiveSlot","HiveSlot",1)
            log("🔓 Buying hive slot...")
            task.wait(1)
            x,y = getEmptySlot()
            if not x then
                log("⏳ Need honey for slot...")
                task.wait(5)
            end
        end

        if x and y then
            -- Check & buy egg
            if getEggs("BasicEgg") <= 0 then
                purchase("Egg","BasicEgg",1)
                task.wait(0.5)
            end
            -- Hatch
            local old = getBees()
            pcall(function() HiveCellEgg:InvokeServer(x, y, "Basic", 1, false) end)
            task.wait(1.5)
            local new = getBees()
            if new > old then
                log("🐝 Hatched! (" .. x .. "," .. y .. ") [" .. new .. "/" .. CFG.TARGET_BEES .. "]")
            else
                log("⚠️ Retry hatch...")
                task.wait(1)
            end
        end
        task.wait(0.5)
    end
end

-- ═══════════════ STEP 4: QUEST ALL NPCS ═══════════════
local function questAllNPCs()
    log("📜 Claiming quests from " .. #QUEST_NPCS .. " NPCs...")
    for _,npcName in ipairs(QUEST_NPCS) do
        if not CFG.RUNNING then break end
        pcall(function()
            local npc = WS.NPCs:FindFirstChild(npcName)
            if npc then
                local part = npc:FindFirstChild("Head") or npc:FindFirstChild("Torso")
                    or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Platform")
                if part then
                    tp(CFrame.new(part.Position + Vector3.new(0, 3, -4)))
                    task.wait(1.5)
                    -- Spam advance dialog to accept/complete quest
                    for i = 1, 15 do
                        pcall(function()
                            Events.SelectNPCOption:FireServer("AdvanceDialog")
                        end)
                        task.wait(0.4)
                    end
                    log("📜 " .. npcName .. " ✓")
                end
            else
                log("⚠️ " .. npcName .. " not found")
            end
        end)
        task.wait(1)
    end
    log("📜 All NPCs done!")
end

-- ═══════════════ STEP 5: AUTO FARM LOOP ═══════════════
local function farmLoop()
    log("🌻 Farming: " .. CFG.FIELD)
    while CFG.RUNNING do
        if not alive() then task.wait(5) end

        pcall(function()
            -- Sell if backpack full
            if getPollen() >= (getCap() * CFG.CONVERT_AT) / 100 then
                log("📦 Selling honey...")
                local h = getHive()
                if h and h:FindFirstChild("SpawnPos") then
                    tp(h.SpawnPos.Value + Vector3.new(0, 5, 0))
                    task.wait(1)
                    HiveCmd:FireServer("ToggleHoneyMaking")
                    local t = tick()
                    repeat task.wait(0.5) until getPollen() <= 0 or tick()-t > 30
                    task.wait(1)
                end
                -- After sell: try buy more accessories & hatch
                if getBees() < CFG.TARGET_BEES then
                    pcall(hatchAllEggs)
                end
                pcall(buyAccessories)
            end

            -- Go to field & farm
            local fp = getField(CFG.FIELD)
            if fp and alive() then
                local hrp = plr.Character.HumanoidRootPart
                if (hrp.Position - fp.Position).Magnitude > 40 then
                    tp(fp.CFrame * CFrame.new(0, 8, 0))
                    task.wait(1)
                end
                -- Dig
                pcall(function() ToolCollect:FireServer() end)
                -- Walk randomly on field
                local rx, rz = math.random(-15, 15), math.random(-15, 15)
                pcall(function()
                    plr.Character.Humanoid:MoveTo(fp.Position + Vector3.new(rx, 3, rz))
                end)
            end
        end)
        task.wait(0.3)
    end
end

-- ═══════════════ QUEST LOOP (periodic) ═══════════════
local function questLoop()
    while CFG.RUNNING do
        task.wait(120) -- Every 2 minutes
        pcall(questAllNPCs)
    end
end

-- ═══════════════ UI ═══════════════
local function buildUI()
    if plr.PlayerGui:FindFirstChild("KaitunUI") then plr.PlayerGui.KaitunUI:Destroy() end
    local gui=Instance.new("ScreenGui"); gui.Name="KaitunUI"; gui.ResetOnSpawn=false; gui.Parent=plr.PlayerGui

    local main=Instance.new("Frame",gui)
    main.Size=UDim2.new(0,280,0,360) main.Position=UDim2.new(0,16,0.5,-180)
    main.BackgroundColor3=Color3.fromRGB(16,16,26) main.BorderSizePixel=0
    main.Active=true main.Draggable=true
    Instance.new("UICorner",main).CornerRadius=UDim.new(0,10)
    Instance.new("UIStroke",main).Color=Color3.fromRGB(255,180,50)

    local t=Instance.new("TextLabel",main)
    t.Size=UDim2.new(1,0,0,32) t.BackgroundColor3=Color3.fromRGB(255,180,50)
    t.Text="🐝 Kaitun v4.0 [AUTO]" t.TextColor3=Color3.fromRGB(16,16,26)
    t.Font=Enum.Font.GothamBold t.TextSize=14 t.BorderSizePixel=0
    Instance.new("UICorner",t).CornerRadius=UDim.new(0,10)

    local scroll=Instance.new("ScrollingFrame",main)
    scroll.Size=UDim2.new(1,-10,1,-38) scroll.Position=UDim2.new(0,5,0,36)
    scroll.BackgroundTransparency=1 scroll.ScrollBarThickness=3
    scroll.ScrollBarImageColor3=Color3.fromRGB(255,180,50)
    scroll.CanvasSize=UDim2.new(0,0,0,500) scroll.BorderSizePixel=0
    Instance.new("UIListLayout",scroll).Padding=UDim.new(0,4)

    -- Minimize
    local mb=Instance.new("TextButton",main)
    mb.Size=UDim2.new(0,24,0,24) mb.Position=UDim2.new(1,-28,0,4)
    mb.BackgroundTransparency=1 mb.Text="—" mb.TextColor3=Color3.fromRGB(16,16,26)
    mb.Font=Enum.Font.GothamBold mb.TextSize=15 mb.ZIndex=10
    local mini=false
    mb.MouseButton1Click:Connect(function()
        mini=not mini; scroll.Visible=not mini
        main.Size=mini and UDim2.new(0,280,0,32) or UDim2.new(0,280,0,360)
        mb.Text=mini and "+" or "—"
    end)

    -- Status
    local stat=Instance.new("TextLabel",scroll)
    stat.Size=UDim2.new(1,-4,0,56) stat.BackgroundColor3=Color3.fromRGB(26,26,40)
    stat.TextColor3=Color3.fromRGB(160,255,160) stat.Font=Enum.Font.GothamMedium
    stat.TextSize=11 stat.TextWrapped=true stat.Text="Loading..."
    Instance.new("UICorner",stat).CornerRadius=UDim.new(0,6)

    -- Log box
    local logBox=Instance.new("TextLabel",scroll)
    logBox.Name="LogBox" logBox.Size=UDim2.new(1,-4,0,120)
    logBox.BackgroundColor3=Color3.fromRGB(22,22,34) logBox.TextColor3=Color3.fromRGB(200,200,200)
    logBox.Font=Enum.Font.Code logBox.TextSize=10 logBox.TextWrapped=true
    logBox.TextYAlignment=Enum.TextYAlignment.Top logBox.Text="[Log]"
    Instance.new("UICorner",logBox).CornerRadius=UDim.new(0,6)
    Instance.new("UIPadding",logBox).PaddingLeft=UDim.new(0,4)

    -- Field selector
    local ff=Instance.new("Frame",scroll)
    ff.Size=UDim2.new(1,-4,0,44) ff.BackgroundColor3=Color3.fromRGB(30,30,46) ff.BorderSizePixel=0
    Instance.new("UICorner",ff).CornerRadius=UDim.new(0,6)
    local fl=Instance.new("TextLabel",ff)
    fl.Size=UDim2.new(1,0,0,16) fl.BackgroundTransparency=1 fl.Text="  🌻 Farm Field"
    fl.TextColor3=Color3.fromRGB(180,180,180) fl.Font=Enum.Font.GothamMedium fl.TextSize=10
    fl.TextXAlignment=Enum.TextXAlignment.Left
    local fidx=1
    local fv=Instance.new("TextButton",ff)
    fv.Size=UDim2.new(1,-10,0,22) fv.Position=UDim2.new(0,5,0,18)
    fv.BackgroundColor3=Color3.fromRGB(45,45,65) fv.TextColor3=Color3.fromRGB(255,220,100)
    fv.Font=Enum.Font.GothamMedium fv.TextSize=11 fv.Text="◀ "..FIELDS[1].." ▶"
    fv.BorderSizePixel=0
    Instance.new("UICorner",fv).CornerRadius=UDim.new(0,4)
    fv.MouseButton1Click:Connect(function()
        fidx=fidx%#FIELDS+1; fv.Text="◀ "..FIELDS[fidx].." ▶"; CFG.FIELD=FIELDS[fidx]
    end)

    -- Buttons
    local function btn(txt,cb)
        local b=Instance.new("TextButton",scroll)
        b.Size=UDim2.new(1,-4,0,28) b.BackgroundColor3=Color3.fromRGB(50,50,70)
        b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.GothamMedium b.TextSize=12
        b.Text=txt b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
        b.MouseButton1Click:Connect(cb)
    end

    btn("🏠 TP to Hive",function()
        local h=getHive()
        if h and h:FindFirstChild("SpawnPos") then tp(h.SpawnPos.Value+Vector3.new(0,5,0)) end
    end)
    btn("🌻 TP to Field",function()
        local fp=getField(CFG.FIELD)
        if fp then tp(fp.CFrame*CFrame.new(0,8,0)) end
    end)
    btn("📜 Quest All NPCs Now",function() task.spawn(questAllNPCs) end)
    btn("🎟️ Redeem Codes",function() task.spawn(redeemCodes) end)
    btn("🛑 Stop All",function() CFG.RUNNING=false; log("⛔ Stopped!") end)

    -- Update loops
    local logLines = {}
    local origLog = log
    log = function(msg) -- Override log to also write to UI
        origLog(msg)
        table.insert(logLines, os.date("%H:%M:%S") .. " " .. msg)
        if #logLines > 12 then table.remove(logLines, 1) end
        pcall(function() logBox.Text = table.concat(logLines, "\n") end)
    end

    task.spawn(function()
        while CFG.RUNNING and task.wait(1) do
            pcall(function()
                stat.Text = ("🍯 %s | 🐝 %d/%d\n📦 %s/%s (%d%%)\n🌻 %s | ⏱️ Running"):format(
                    fmt(getHoney()), getBees(), CFG.TARGET_BEES,
                    fmt(getPollen()), fmt(getCap()),
                    math.floor(getPollen()/math.max(getCap(),1)*100),
                    CFG.FIELD)
            end)
        end
    end)
end

-- ═══════════════ MAIN - ALL AUTO ═══════════════
log("═══ Kaitun BSS v4.0 ═══")
log("⏳ Waiting for game...")

repeat task.wait(1) until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
repeat task.wait(1) until WS:FindFirstChild("Honeycombs") and #WS.Honeycombs:GetChildren() > 0
task.wait(3)

-- Remove gates/walls
pcall(function() for _,g in pairs(WS.Gates:GetChildren()) do
    for _,p in pairs(g:GetChildren()) do pcall(function() p.CanCollide=false end) end
end end)
pcall(function() for _,v in pairs(WS["Invisible Walls"]:GetChildren()) do v:Destroy() end end)
pcall(function() for _,v in pairs(WS.Territories:GetChildren()) do v:Destroy() end end)
log("🧱 Gates removed")

-- Build UI first
buildUI()

-- ═══ AUTO SEQUENCE (all enabled) ═══
-- Step 0: Claim hive
claimHive()

-- Step 1: Redeem all codes
task.spawn(function() pcall(redeemCodes) end)
task.wait(2)

-- Step 2: Buy accessories
pcall(buyAccessories)

-- Step 3: Hatch eggs to target
pcall(hatchAllEggs)

-- Step 4: Quest all NPCs
pcall(questAllNPCs)

-- Step 5: Start continuous farm loop + periodic quest loop
log("🌻 Starting farm loop...")
task.spawn(function() pcall(questLoop) end)
farmLoop() -- Main thread = farm
