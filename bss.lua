--[[
    Kaitun BSS Auto v4.0 - Delta X
    Auto: Claim Hive → Codes → Accessories → Hatch Eggs → Quest → Farm
    Nếu thiếu honey → farm trước, retry hatch mỗi lần sell
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

-- ═══════════════ HELPERS ═══════════════
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

local function getAllEmptySlots()
    local slots = {}
    local h = getHive()
    if h and h:FindFirstChild("Cells") then
        for _, cell in pairs(h.Cells:GetChildren()) do
            if cell:FindFirstChild("CellType") then
                local t = tostring(cell.CellType.Value)
                if t == "Empty" or t == "nil" or t == "" then
                    local x, y = cell.Name:match("C(%d+),(%d+)")
                    if x and y then
                        table.insert(slots, {x = tonumber(x), y = tonumber(y)})
                    end
                end
            end
        end
    end
    return slots
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

local function tpToHive()
    local h = getHive()
    if h and h:FindFirstChild("SpawnPos") then
        tp(h.SpawnPos.Value + Vector3.new(0, 5, 0))
        task.wait(1.5)
    end
end

-- ═══════════════ CLAIM HIVE ═══════════════
local function claimHive()
    if getHive() then log("✅ Hive OK") return true end
    log("🏠 Claiming hive...")
    for att=1,20 do
        for _,h in pairs(WS.Honeycombs:GetChildren()) do
            if h:FindFirstChild("Owner") and tostring(h.Owner.Value)=="nil" then
                pcall(function() if h:FindFirstChild("LightHolder") then tp(h.LightHolder.CFrame) end end)
                task.wait(1)
                pcall(function() if h:FindFirstChild("HiveID") then ClaimHiveR:FireServer(h.HiveID.Value) end end)
                task.wait(2)
                if getHive() then log("🎉 Hive claimed!") return true end
            end
        end
        task.wait(2)
    end
    log("❌ Claim failed"); return false
end

-- ═══════════════ REDEEM CODES ═══════════════
local function redeemCodes()
    log("🎟️ Redeeming " .. #PROMO_CODES .. " codes...")
    for i,code in ipairs(PROMO_CODES) do
        pcall(function() require(RS.PromoCodes).Redeem(code) end)
        pcall(function() require(RS.Events).ClientCall("PromoCodeEvent", code) end)
        if i % 5 == 0 then log("🎟️ " .. i .. "/" .. #PROMO_CODES) end
        task.wait(0.8)
    end
    log("🎟️ Done!")
end

-- ═══════════════ BUY ACCESSORIES ═══════════════
local function buyAccessories()
    for _,a in ipairs(ACCESSORIES) do
        if getHoney() >= a.c then
            if purchase("Accessory", a.n) then log("✅ " .. a.n) end
            task.wait(0.5)
        end
    end
end

-- ═══════════════ HATCH EGGS ═══════════════
local EGG_SHOP_POS = CFrame.new(-139.14, 8, 243.48)

-- Mua egg, return true nếu thành công
local function buyEggAtShop(amount)
    amount = amount or 1
    log("🏪 Mua " .. amount .. " egg...")
    tp(EGG_SHOP_POS)
    task.wait(2)
    local honeyBefore = getHoney()
    for i = 1, amount do
        pcall(function()
            ItemPkg:InvokeServer("Purchase", {Type="Basic", Category="Eggs", Amount=1})
        end)
        task.wait(0.3)
    end
    if getHoney() < honeyBefore then
        log("✅ Mua egg OK")
        return true
    end
    log("❌ Thiếu honey!")
    return false
end

-- return true=đủ bees, false=thiếu honey cần farm
local function hatchAllEggs()
    local bees = getBees()
    if bees >= CFG.TARGET_BEES then return true end
    log("🥚 Cần " .. (CFG.TARGET_BEES - bees) .. " bees nữa")

    -- Check slot trống
    local slots = getAllEmptySlots()
    if #slots == 0 then
        purchase("HiveSlot", "HiveSlot", 1)
        task.wait(1)
        slots = getAllEmptySlots()
        if #slots == 0 then
            log("💰 Thiếu honey mua slot → farm")
            return false
        end
    end

    -- Mua egg → nếu fail thì đi farm
    local need = math.min(#slots, CFG.TARGET_BEES - bees)
    if not buyEggAtShop(need) then
        return false
    end

    -- Hatch
    tpToHive()
    task.wait(1)
    for i = 1, need do
        if not CFG.RUNNING then break end
        local s = slots[i]
        if s then
            log("🥚 Hatch (" .. s.x .. "," .. s.y .. ")...")
            pcall(function() HiveCellEgg:InvokeServer(s.x, s.y, "Basic", 1, false) end)
            task.wait(1.5)
        end
    end

    local newBees = getBees()
    log("🐝 " .. newBees .. "/" .. CFG.TARGET_BEES .. " bees")
    return newBees >= CFG.TARGET_BEES
end

-- ═══════════════ QUEST ALL NPCS ═══════════════
local function questAllNPCs()
    log("📜 Quest " .. #QUEST_NPCS .. " NPCs...")
    for _,name in ipairs(QUEST_NPCS) do
        if not CFG.RUNNING then break end
        pcall(function()
            local npc = WS.NPCs:FindFirstChild(name)
            if npc then
                local part = npc:FindFirstChild("Head") or npc:FindFirstChild("Torso")
                if part then
                    tp(CFrame.new(part.Position + Vector3.new(0, 3, -4)))
                    task.wait(1.5)
                    for i = 1, 15 do
                        pcall(function() Events.SelectNPCOption:FireServer("AdvanceDialog") end)
                        task.wait(0.4)
                    end
                    log("📜 " .. name .. " ✓")
                end
            end
        end)
        task.wait(1)
    end
end

-- ═══════════════ FARM LOOP ═══════════════
local function farmLoop()
    log("🌻 Farm: " .. CFG.FIELD)
    while CFG.RUNNING do
        if not alive() then task.wait(5) end
        pcall(function()
            -- Sell khi đầy
            if getPollen() >= (getCap() * CFG.CONVERT_AT) / 100 then
                log("📦 Bán honey...")
                tpToHive()
                HiveCmd:FireServer("ToggleHoneyMaking")
                local t = tick()
                repeat task.wait(0.5) until getPollen() <= 0 or tick()-t > 30
                task.wait(1)
                -- Sau sell: mua acc + thử hatch
                pcall(buyAccessories)
                if getBees() < CFG.TARGET_BEES then
                    hatchAllEggs()
                end
            end
            -- Farm field
            local fp = getField(CFG.FIELD)
            if fp and alive() then
                local hrp = plr.Character.HumanoidRootPart
                if (hrp.Position - fp.Position).Magnitude > 40 then
                    tp(fp.CFrame * CFrame.new(0, 8, 0))
                    task.wait(1)
                end
                pcall(function() ToolCollect:FireServer() end)
                pcall(function()
                    plr.Character.Humanoid:MoveTo(fp.Position + Vector3.new(math.random(-15,15), 3, math.random(-15,15)))
                end)
            end
        end)
        task.wait(0.3)
    end
end

-- ═══════════════ MAIN ═══════════════
log("═══ Kaitun BSS v4.0 ═══")
repeat task.wait(1) until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
repeat task.wait(1) until WS:FindFirstChild("Honeycombs") and #WS.Honeycombs:GetChildren() > 0
task.wait(3)

-- Remove gates
pcall(function() for _,g in pairs(WS.Gates:GetChildren()) do
    for _,p in pairs(g:GetChildren()) do pcall(function() p.CanCollide=false end) end
end end)
pcall(function() for _,v in pairs(WS["Invisible Walls"]:GetChildren()) do v:Destroy() end end)
pcall(function() for _,v in pairs(WS.Territories:GetChildren()) do v:Destroy() end end)
log("🧱 Gates removed")

-- Auto sequence
claimHive()
task.spawn(function() pcall(redeemCodes) end)
task.wait(2)
pcall(questAllNPCs)
task.spawn(function() while CFG.RUNNING do task.wait(120); pcall(questAllNPCs) end end)

-- ═══ MAIN LOOP: đan xen mua acc + hatch + farm ═══
log("🔄 Bắt đầu loop chính...")
while CFG.RUNNING do
    local bees = getBees()
    local beesOk = bees >= CFG.TARGET_BEES

    -- 1. Thử mua 1 accessory (cái rẻ nhất chưa có)
    for _,a in ipairs(ACCESSORIES) do
        if getHoney() >= a.c then
            if purchase("Accessory", a.n) then
                log("✅ Acc: " .. a.n)
            end
            task.wait(0.3)
            break -- mua 1 cái rồi chuyển sang hatch
        end
    end

    -- 2. Thử hatch 1 egg (nếu chưa đủ bees)
    if not beesOk then
        local slots = getAllEmptySlots()
        if #slots == 0 then
            purchase("HiveSlot", "HiveSlot", 1)
            task.wait(1)
            slots = getAllEmptySlots()
        end
        if #slots > 0 then
            local s = slots[1]
            -- Mua 1 egg
            local honeyBefore = getHoney()
            tp(EGG_SHOP_POS)
            task.wait(1.5)
            pcall(function()
                ItemPkg:InvokeServer("Purchase", {Type="Basic", Category="Eggs", Amount=1})
            end)
            task.wait(0.3)

            if getHoney() < honeyBefore then
                -- Mua OK → hatch
                tpToHive()
                task.wait(1)
                log("🥚 Hatch (" .. s.x .. "," .. s.y .. ")")
                pcall(function() HiveCellEgg:InvokeServer(s.x, s.y, "Basic", 1, false) end)
                task.wait(1.5)
                log("🐝 Bees: " .. getBees() .. "/" .. CFG.TARGET_BEES)
            else
                log("💰 Thiếu honey, farm thêm...")
            end
        end
    end

    -- 3. Farm để kiếm honey
    local fp = getField(CFG.FIELD)
    if fp and alive() then
        local hrp = plr.Character.HumanoidRootPart
        if (hrp.Position - fp.Position).Magnitude > 40 then
            tp(fp.CFrame * CFrame.new(0, 8, 0))
            task.wait(1)
        end
        -- Farm 1 vòng ngắn
        for i = 1, 30 do
            if not CFG.RUNNING then break end
            pcall(function() ToolCollect:FireServer() end)
            pcall(function()
                plr.Character.Humanoid:MoveTo(fp.Position + Vector3.new(math.random(-15,15), 3, math.random(-15,15)))
            end)
            task.wait(0.3)
        end
    end

    -- 4. Sell nếu đầy
    if getPollen() >= (getCap() * CFG.CONVERT_AT) / 100 then
        log("📦 Bán honey...")
        tpToHive()
        HiveCmd:FireServer("ToggleHoneyMaking")
        local t = tick()
        repeat task.wait(0.5) until getPollen() <= 0 or tick()-t > 30
        task.wait(1)
        log("🍯 Honey: " .. getHoney())
    end

    -- 5. Check xong chưa
    if getBees() >= CFG.TARGET_BEES then
        log("🎉 Đủ " .. CFG.TARGET_BEES .. " bees!")
        -- Tiếp tục farm vô hạn
    end
end

