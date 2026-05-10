--[[
    Kaitun BSS Auto v3.0 - Delta X Executor
    Auto Buy Accessories + Auto Hatch Egg + UI
]]

-- ═══════════════ CONFIG ═══════════════
local CONFIG = {
    PREFIX = "[Kaitun]",
    BUY_DELAY = 0.6,
    HATCH_DELAY = 1.5,
    TARGET_BEES = 20,
    FARM_FIELD = "Sunflower Field",
    CONVERT_AT = 95,
    AUTO_BUY = false,
    AUTO_HATCH = false,
    AUTO_FARM = false,
    AUTO_QUEST = false,
    RUNNING = true,
}

-- ═══════════════ SERVICES ═══════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local plr = Players.LocalPlayer

-- ═══════════════ REMOTES ═══════════════
local Events = RS:WaitForChild("Events")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")
local HiveCellEgg = Events:WaitForChild("ConstructHiveCellFromEgg")
local StatsRemote = Events:WaitForChild("RetrievePlayerStats")
local ClaimHiveRemote = Events:WaitForChild("ClaimHive")
local HiveCmd = Events:WaitForChild("PlayerHiveCommand")
local ToolCollect = Events:WaitForChild("ToolCollect")

-- ═══════════════ DATA ═══════════════
local ACCESSORIES = {
    {name="Helmet",cost=30000},{name="Brave Guard",cost=300000},
    {name="Hasty Guard",cost=300000},{name="Bomber Guard",cost=300000},
    {name="Looker Guard",cost=300000},{name="Basic Boots",cost=50000},
    {name="Belt Pocket",cost=50000},{name="Blue Guard",cost=1e6},
    {name="Red Guard",cost=1e6},{name="Propeller Hat",cost=2.5e6},
    {name="Elite Blue Guard",cost=3e6},{name="Elite Red Guard",cost=3e6},
    {name="Hiking Boots",cost=2.5e6},{name="Mondo Belt Bag",cost=1.5e6},
    {name="Parachute",cost=5e5},{name="Glider",cost=5e6},
    {name="Beekeeper's Boots",cost=1.5e7},
    {name="Beekeeper's Mask",cost=2e7},
}

local FIELDS = {
    "Sunflower Field","Dandelion Field","Mushroom Field","Blue Flower Field",
    "Clover Field","Spider Field","Strawberry Field","Bamboo Field",
    "Pineapple Patch","Stump Field","Cactus Field","Pumpkin Patch",
    "Pine Tree Forest","Rose Field","Mountain Top Field","Coconut Field",
}

-- ═══════════════ 1. log(msg) ═══════════════
-- In thông báo có prefix và gửi notification
local function log(msg)
    print(CONFIG.PREFIX .. " " .. msg)
    pcall(function()
        game.StarterGui:SetCore("SendNotification",{Title="Kaitun",Text=msg,Duration=3})
    end)
end

-- ═══════════════ 2. getRemote(name) ═══════════════
-- Tìm remote trong ReplicatedStorage.Events
-- @param name: tên remote
-- @return: remote object hoặc nil
local function getRemote(name)
    local s, r = pcall(function() return Events:FindFirstChild(name) end)
    return s and r or nil
end

-- ═══════════════ 3. teleportTo(cf) ═══════════════
-- Dịch chuyển nhân vật đến CFrame
-- @param cf: CFrame đích
local function teleportTo(cf)
    pcall(function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = cf
        end
    end)
end

-- ═══════════════ 4. findNPCShop(name) ═══════════════
-- Tìm NPC/shop theo tên trong Workspace.NPCs
-- @param name: tên NPC
-- @return: NPC model hoặc nil
local function findNPCShop(name)
    local s, r = pcall(function() return WS.NPCs:FindFirstChild(name) end)
    return s and r or nil
end

-- ═══════════════ 5. getPlayerHoney() ═══════════════
-- Lấy số honey hiện tại của player
-- @return: number
local function getPlayerHoney()
    local s, r = pcall(function() return plr.CoreStats.Honey.Value end)
    return s and r or 0
end

-- ═══════════════ 6. canAfford(cost) ═══════════════
-- Kiểm tra đủ honey không
-- @param cost: số honey cần
-- @return: boolean
local function canAfford(cost)
    return getPlayerHoney() >= cost
end

-- ═══════════════ HELPER: getPollen/getCapacity ═══════════════
local function getPollen()
    local s,r = pcall(function() return plr.CoreStats.Pollen.Value end)
    return s and r or 0
end
local function getCapacity()
    local s,r = pcall(function() return plr.CoreStats.Capacity.Value end)
    return s and r or 100
end
local function formatNum(n)
    if n>=1e9 then return ("%.1fB"):format(n/1e9)
    elseif n>=1e6 then return ("%.1fM"):format(n/1e6)
    elseif n>=1e3 then return ("%.1fK"):format(n/1e3)
    else return tostring(math.floor(n)) end
end

-- ═══════════════ HELPER: getPlayerHive ═══════════════
local function getPlayerHive()
    for _,h in pairs(WS.Honeycombs:GetChildren()) do
        if h:FindFirstChild("Owner") and tostring(h.Owner.Value)==plr.Name then return h end
    end
end

-- ═══════════════ HELPER: getBeeCount ═══════════════
local function getBeeCount()
    local c=0
    local h=getPlayerHive()
    if h and h:FindFirstChild("Cells") then
        for _,cell in pairs(h.Cells:GetChildren()) do
            if cell:FindFirstChild("CellType") then
                local t=tostring(cell.CellType.Value)
                if t~="Empty" and t~="nil" and t~="" then c=c+1 end
            end
        end
    end
    return c
end

-- ═══════════════ HELPER: getEmptySlot ═══════════════
local function getEmptySlot()
    local h=getPlayerHive()
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

-- ═══════════════ HELPER: getEggCount ═══════════════
local function getEggCount(eggName)
    local c=0
    pcall(function()
        local stats=StatsRemote:InvokeServer()
        if stats and stats.Eggs and stats.Eggs[eggName] then c=stats.Eggs[eggName] end
    end)
    return c
end

-- ═══════════════ HELPER: getFieldPart ═══════════════
local function getFieldPart(name)
    local s,r=pcall(function() return WS.FlowerZones:FindFirstChild(name) end)
    return s and r or nil
end

-- ═══════════════ 7. buyAccessory(item) ═══════════════
-- Mua một accessory qua ItemPackageEvent
-- @param item: {name=string, cost=number}
-- @return: boolean (thành công/thất bại)
local function buyAccessory(item)
    if not canAfford(item.cost) then
        log("⏭️ Skip "..item.name.." (need "..formatNum(item.cost)..")")
        return false
    end
    local s,r = pcall(function()
        return ItemPackageEvent:InvokeServer("Purchase",{
            Category="Accessory", Type=item.name
        })
    end)
    if s and r then
        log("✅ Bought: "..item.name)
        return true
    else
        log("❌ Failed: "..item.name)
        return false
    end
end

-- ═══════════════ 8. autoBuyLoop() ═══════════════
-- Vòng lặp mua accessories theo danh sách
-- Duyệt từ giá thấp đến cao, skip nếu đã sở hữu
local function autoBuyLoop()
    log("🛒 Auto Buy Accessories started...")
    local bought = 0
    for _,acc in ipairs(ACCESSORIES) do
        if not CONFIG.AUTO_BUY then break end
        if buyAccessory(acc) then
            bought = bought + 1
        end
        task.wait(CONFIG.BUY_DELAY)
    end
    log("🛒 Done! Bought "..bought.." items.")
end

-- ═══════════════ 9. hatchEgg(eggName) ═══════════════
-- Thực hiện một lần hatch egg vào hive slot trống
-- @param eggName: tên egg (vd: "BasicEgg")
-- @return: boolean (thành công/thất bại)
local function hatchEgg(eggName)
    local x, y = getEmptySlot()
    if not x then
        -- Mua thêm slot
        local ok = pcall(function()
            return ItemPackageEvent:InvokeServer("Purchase",{
                Category="HiveSlot", Type="HiveSlot", Amount=1
            })
        end)
        if ok then log("🔓 Bought hive slot!") end
        task.wait(1)
        x, y = getEmptySlot()
        if not x then return false end
    end

    -- Check egg trong inventory
    local eggCount = getEggCount(eggName)
    if eggCount <= 0 then
        -- Mua egg
        pcall(function()
            ItemPackageEvent:InvokeServer("Purchase",{
                Category="Egg", Type=eggName, Amount=1
            })
        end)
        task.wait(0.5)
        eggCount = getEggCount(eggName)
        if eggCount <= 0 then
            log("❌ No "..eggName.." & can't buy")
            return false
        end
        log("🛒 Bought "..eggName)
    end

    -- Hatch
    local oldBees = getBeeCount()
    local s,r = pcall(function()
        return HiveCellEgg:InvokeServer(x, y, eggName, 1, false)
    end)
    task.wait(1)
    local newBees = getBeeCount()

    if newBees > oldBees then
        log("🐝 Hatched! ("..x..","..y..") ["..newBees.."/"..CONFIG.TARGET_BEES.."]")
        return true
    else
        log("⚠️ Hatch failed at ("..x..","..y.."), retrying...")
        return false
    end
end

-- ═══════════════ 10. autoHatchLoop() ═══════════════
-- Vòng lặp hatch egg liên tục đến khi đủ TARGET_BEES
local function autoHatchLoop()
    log("🥚 Auto Hatch started (target: "..CONFIG.TARGET_BEES.." bees)")
    while CONFIG.AUTO_HATCH and CONFIG.RUNNING do
        local bees = getBeeCount()
        if bees >= CONFIG.TARGET_BEES then
            log("🎉 Reached "..bees.." bees!")
            CONFIG.AUTO_HATCH = false
            break
        end
        hatchEgg("BasicEgg")
        task.wait(CONFIG.HATCH_DELAY)
    end
    log("🥚 Auto Hatch stopped.")
end

-- ═══════════════ AUTO CLAIM HIVE ═══════════════
local function autoClaimHive()
    if getPlayerHive() then log("✅ Hive exists") return true end
    log("🏠 Claiming hive...")
    local combs = WS.Honeycombs:GetChildren()
    for att=1,15 do
        for i=#combs,1,-1 do
            local h=combs[i]
            if h:FindFirstChild("Owner") and tostring(h.Owner.Value)=="nil" then
                pcall(function()
                    if h:FindFirstChild("LightHolder") then teleportTo(h.LightHolder.CFrame) end
                end)
                task.wait(1)
                pcall(function()
                    if h:FindFirstChild("HiveID") then ClaimHiveRemote:FireServer(h.HiveID.Value) end
                end)
                task.wait(2)
                if getPlayerHive() then log("🎉 Hive claimed!") return true end
                break
            end
        end
        task.wait(2)
    end
    log("❌ Could not claim hive")
    return false
end

-- ═══════════════ AUTO FARM ═══════════════
local function autoFarmLoop()
    log("🌻 Farming: "..CONFIG.FARM_FIELD)
    while CONFIG.AUTO_FARM and CONFIG.RUNNING do
        pcall(function()
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
                task.wait(3) return
            end
            -- Sell if full
            if getPollen() >= (getCapacity()*CONFIG.CONVERT_AT)/100 then
                log("📦 Selling...")
                local h=getPlayerHive()
                if h and h:FindFirstChild("SpawnPos") then
                    teleportTo(h.SpawnPos.Value+Vector3.new(0,5,0))
                    task.wait(1)
                    HiveCmd:FireServer("ToggleHoneyMaking")
                    local t=tick()
                    repeat task.wait(0.5) until getPollen()<=0 or tick()-t>30
                    task.wait(1)
                end
            end
            -- Go to field
            local fp=getFieldPart(CONFIG.FARM_FIELD)
            if fp then
                local hrp=plr.Character.HumanoidRootPart
                if (hrp.Position-fp.Position).Magnitude>40 then
                    teleportTo(fp.CFrame*CFrame.new(0,8,0))
                    task.wait(1)
                end
                pcall(function() ToolCollect:FireServer() end)
                local rx,rz=math.random(-15,15),math.random(-15,15)
                pcall(function()
                    plr.Character.Humanoid:MoveTo(fp.Position+Vector3.new(rx,3,rz))
                end)
            end
        end)
        task.wait(0.3)
    end
end

-- ═══════════════ AUTO QUEST ═══════════════
local function autoQuestLoop()
    log("📜 Auto Quest started...")
    while CONFIG.AUTO_QUEST and CONFIG.RUNNING do
        pcall(function()
            local npc=findNPCShop("Black Bear")
            if npc then
                local part=npc:FindFirstChild("Head") or npc:FindFirstChild("Torso")
                if part then
                    teleportTo(CFrame.new(part.Position+Vector3.new(0,3,-5)))
                    task.wait(1)
                    pcall(function() Events.SelectNPCOption:FireServer("AdvanceDialog") end)
                end
            end
        end)
        task.wait(5)
    end
end

-- ═══════════════ UI ═══════════════
local function buildUI()
    if plr.PlayerGui:FindFirstChild("KaitunUI") then plr.PlayerGui.KaitunUI:Destroy() end

    local gui=Instance.new("ScreenGui")
    gui.Name="KaitunUI" gui.ResetOnSpawn=false gui.Parent=plr.PlayerGui

    local main=Instance.new("Frame",gui)
    main.Size=UDim2.new(0,300,0,420) main.Position=UDim2.new(0,20,0.5,-210)
    main.BackgroundColor3=Color3.fromRGB(18,18,28) main.BorderSizePixel=0
    main.Active=true main.Draggable=true
    Instance.new("UICorner",main).CornerRadius=UDim.new(0,10)
    local s=Instance.new("UIStroke",main) s.Color=Color3.fromRGB(255,180,50) s.Thickness=2

    -- Title
    local t=Instance.new("TextLabel",main)
    t.Size=UDim2.new(1,0,0,34) t.BackgroundColor3=Color3.fromRGB(255,180,50)
    t.Text="🐝 Kaitun BSS v3.0" t.TextColor3=Color3.fromRGB(18,18,28)
    t.Font=Enum.Font.GothamBold t.TextSize=15 t.BorderSizePixel=0
    Instance.new("UICorner",t).CornerRadius=UDim.new(0,10)

    -- Minimize
    local minB=Instance.new("TextButton",main)
    minB.Size=UDim2.new(0,26,0,26) minB.Position=UDim2.new(1,-30,0,4)
    minB.BackgroundTransparency=1 minB.Text="—" minB.TextColor3=Color3.fromRGB(18,18,28)
    minB.Font=Enum.Font.GothamBold minB.TextSize=16 minB.ZIndex=10

    local scroll=Instance.new("ScrollingFrame",main)
    scroll.Size=UDim2.new(1,-12,1,-42) scroll.Position=UDim2.new(0,6,0,38)
    scroll.BackgroundTransparency=1 scroll.ScrollBarThickness=3
    scroll.ScrollBarImageColor3=Color3.fromRGB(255,180,50)
    scroll.CanvasSize=UDim2.new(0,0,0,600) scroll.BorderSizePixel=0
    Instance.new("UIListLayout",scroll).Padding=UDim.new(0,5)

    local mini=false
    minB.MouseButton1Click:Connect(function()
        mini=not mini; scroll.Visible=not mini
        main.Size=mini and UDim2.new(0,300,0,34) or UDim2.new(0,300,0,420)
        minB.Text=mini and "+" or "—"
    end)

    -- Status
    local stat=Instance.new("TextLabel",scroll)
    stat.Name="Stat" stat.Size=UDim2.new(1,-6,0,44)
    stat.BackgroundColor3=Color3.fromRGB(28,28,42) stat.TextColor3=Color3.fromRGB(180,255,180)
    stat.Font=Enum.Font.GothamMedium stat.TextSize=11 stat.TextWrapped=true
    stat.Text="Loading..." stat.LayoutOrder=0
    Instance.new("UICorner",stat).CornerRadius=UDim.new(0,6)

    task.spawn(function()
        while CONFIG.RUNNING and task.wait(1) do
            pcall(function()
                stat.Text=("🍯 %s | 🐝 %d\n📦 %s/%s (%d%%) | 🌻 %s"):format(
                    formatNum(getPlayerHoney()),getBeeCount(),
                    formatNum(getPollen()),formatNum(getCapacity()),
                    math.floor(getPollen()/math.max(getCapacity(),1)*100),
                    CONFIG.FARM_FIELD)
            end)
        end
    end)

    local function header(txt,ord)
        local h=Instance.new("TextLabel",scroll)
        h.Size=UDim2.new(1,-6,0,22) h.BackgroundColor3=Color3.fromRGB(255,180,50)
        h.TextColor3=Color3.fromRGB(18,18,28) h.Font=Enum.Font.GothamBold
        h.TextSize=12 h.Text="  "..txt h.TextXAlignment=Enum.TextXAlignment.Left
        h.LayoutOrder=ord Instance.new("UICorner",h).CornerRadius=UDim.new(0,5)
    end

    local function toggle(txt,ord,cb)
        local b=Instance.new("TextButton",scroll)
        b.Size=UDim2.new(1,-6,0,30) b.Font=Enum.Font.GothamMedium b.TextSize=12
        b.TextColor3=Color3.new(1,1,1) b.BorderSizePixel=0 b.LayoutOrder=ord
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
        local on=false
        local function upd()
            b.BackgroundColor3=on and Color3.fromRGB(40,150,40) or Color3.fromRGB(55,55,75)
            b.Text=txt..(on and " ✅" or " ❌")
        end
        upd()
        b.MouseButton1Click:Connect(function() on=not on; upd(); if cb then cb(on) end end)
    end

    local function dropdown(txt,list,ord,cb)
        local f=Instance.new("Frame",scroll)
        f.Size=UDim2.new(1,-6,0,48) f.BackgroundColor3=Color3.fromRGB(32,32,48)
        f.LayoutOrder=ord f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
        local l=Instance.new("TextLabel",f)
        l.Size=UDim2.new(1,0,0,18) l.BackgroundTransparency=1
        l.Text="  "..txt l.TextColor3=Color3.fromRGB(190,190,190)
        l.Font=Enum.Font.GothamMedium l.TextSize=11 l.TextXAlignment=Enum.TextXAlignment.Left
        local idx=1
        local v=Instance.new("TextButton",f)
        v.Size=UDim2.new(1,-12,0,22) v.Position=UDim2.new(0,6,0,20)
        v.BackgroundColor3=Color3.fromRGB(48,48,68) v.TextColor3=Color3.fromRGB(255,220,100)
        v.Font=Enum.Font.GothamMedium v.TextSize=11 v.Text="◀ "..list[1].." ▶"
        v.BorderSizePixel=0
        Instance.new("UICorner",v).CornerRadius=UDim.new(0,4)
        v.MouseButton1Click:Connect(function()
            idx=idx%#list+1; v.Text="◀ "..list[idx].." ▶"
            if cb then cb(list[idx]) end
        end)
        if cb then cb(list[1]) end
    end

    local function button(txt,ord,cb)
        local b=Instance.new("TextButton",scroll)
        b.Size=UDim2.new(1,-6,0,28) b.BackgroundColor3=Color3.fromRGB(55,55,75)
        b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.GothamMedium b.TextSize=12
        b.Text=txt b.LayoutOrder=ord b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
        b.MouseButton1Click:Connect(cb)
    end

    -- BUILD SECTIONS
    header("🏠 Setup",10)
    button("Claim Hive",11,function() task.spawn(autoClaimHive) end)
    toggle("Auto Buy Accessories",12,function(v)
        CONFIG.AUTO_BUY=v; if v then task.spawn(autoBuyLoop) end
    end)
    toggle("Auto Hatch Eggs → "..CONFIG.TARGET_BEES,13,function(v)
        CONFIG.AUTO_HATCH=v; if v then task.spawn(autoHatchLoop) end
    end)

    header("🌻 Farming",20)
    dropdown("Field",FIELDS,21,function(v) CONFIG.FARM_FIELD=v end)
    toggle("Auto Farm",22,function(v)
        CONFIG.AUTO_FARM=v; if v then task.spawn(autoFarmLoop) end
    end)

    header("📜 Quests",30)
    toggle("Auto Quest (Black Bear)",31,function(v)
        CONFIG.AUTO_QUEST=v; if v then task.spawn(autoQuestLoop) end
    end)

    header("⚡ Tools",40)
    button("🧱 Remove Gates",41,function()
        pcall(function() for _,g in pairs(WS.Gates:GetChildren()) do
            for _,p in pairs(g:GetChildren()) do pcall(function() p.CanCollide=false end) end
        end end)
        pcall(function() for _,v in pairs(WS["Invisible Walls"]:GetChildren()) do v:Destroy() end end)
        pcall(function() for _,v in pairs(WS.Territories:GetChildren()) do v:Destroy() end end)
        log("Gates removed!")
    end)
    button("🏠 TP to Hive",42,function()
        local h=getPlayerHive()
        if h and h:FindFirstChild("SpawnPos") then teleportTo(h.SpawnPos.Value+Vector3.new(0,5,0)) end
    end)
    button("🌻 TP to Field",43,function()
        local fp=getFieldPart(CONFIG.FARM_FIELD)
        if fp then teleportTo(fp.CFrame*CFrame.new(0,8,0)) end
    end)
end

-- ═══════════════ MAIN ═══════════════
log("=== Kaitun BSS v3.0 ===")
repeat task.wait(1) until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
repeat task.wait(1) until WS:FindFirstChild("Honeycombs") and #WS.Honeycombs:GetChildren()>0
task.wait(2)

-- Remove gates on start
pcall(function() for _,g in pairs(WS.Gates:GetChildren()) do
    for _,p in pairs(g:GetChildren()) do pcall(function() p.CanCollide=false end) end
end end)
pcall(function() for _,v in pairs(WS["Invisible Walls"]:GetChildren()) do v:Destroy() end end)
pcall(function() for _,v in pairs(WS.Territories:GetChildren()) do v:Destroy() end end)

-- Auto claim hive
if not getPlayerHive() then autoClaimHive() end

-- Build UI
buildUI()
log("✅ Ready! Use the panel.")
