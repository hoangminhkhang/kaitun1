-- ╔══════════════════════════════════════════════════════════════════╗
-- ║          🐝  KAITUN AGENT — BEE SWARM SIMULATOR  🐝            ║
-- ║       AI tự động chơi hoàn toàn từ 0 → 50 slot ong            ║
-- ║                                                                 ║
-- ║  STEP 0  💎  Diamond Mask + Pre-craft Glitter & Oil            ║
-- ║  STEP 1  🍹  Craft items (Wax, Enzymes, Tropical Drink...)     ║
-- ║  STEP 2  🥚  Đặt egg vào slot trống                            ║
-- ║  STEP 3  🛒  Mua egg theo ưu tiên                              ║
-- ║  STEP 4  💍  Mua beequip cho ong                               ║
-- ║  STEP 5  🌻  Farm pollen + collect Blue Extract                 ║
-- ║  STEP 6  ⚡  Boost (Glitter / Oil / Diamond Mask)              ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

local Char, HRP, Hum
local function BindChar(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
end
BindChar(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(BindChar)

-- ════════════════════════════════════════════════════
--  FIELD DATA (BeeTypes Tastes)
-- ════════════════════════════════════════════════════
local FIELDS = {
    { n="Sunflower Field",    p=Vector3.new(-92,   4,-100), c="White", r=55 },
    { n="Dandelion Field",    p=Vector3.new(-67,   4,-228), c="White", r=55 },
    { n="Clover Field",       p=Vector3.new(-100,  4,-350), c="White", r=60 },
    { n="Pineapple Patch",    p=Vector3.new(-200,  4,-150), c="White", r=55 },
    { n="Mountain Top Field", p=Vector3.new(-50, 200,-450), c="White", r=65 },
    { n="Stump Field",        p=Vector3.new(155,   4, -50), c="White", r=50 },
    { n="Ant Field",          p=Vector3.new(100,   4,-420), c="White", r=55 },
    { n="Mushroom Field",     p=Vector3.new(155,   4,-115), c="Red",   r=55 },
    { n="Strawberry Field",   p=Vector3.new(50,    4,-300), c="Red",   r=55 },
    { n="Rose Field",         p=Vector3.new(-220,  4,-280), c="Red",   r=55 },
    { n="Pepper Patch",       p=Vector3.new(280,   4,-200), c="Red",   r=50 },
    { n="Pumpkin Patch",      p=Vector3.new(120,   4,-380), c="Red",   r=55 },
    { n="Cactus Field",       p=Vector3.new(230,   4,-350), c="Red",   r=55 },
    { n="Blue Flower Field",  p=Vector3.new(-149,  4,-200), c="Blue",  r=55 },
    { n="Spider Field",       p=Vector3.new(200,   4,-280), c="Blue",  r=60 },
    { n="Bamboo Field",       p=Vector3.new(182,   4,-180), c="Blue",  r=55 },
    { n="Pine Tree Forest",   p=Vector3.new(-180, 20,-350), c="Blue",  r=65 },
    { n="Coconut Field",      p=Vector3.new(250,   4,-100), c="Blue",  r=55 },
}
local FMAP = {}; for _,f in ipairs(FIELDS) do FMAP[f.n]=f end

-- ════════════════════════════════════════════════════
--  NPC DATA
-- ════════════════════════════════════════════════════
local NPCS = {
    ["Black Bear"]   = Vector3.new(-66,   4,  -13),
    ["Brown Bear"]   = Vector3.new(-110,  4,  -35),
    ["Bee Bear"]     = Vector3.new(-160,  4,  -60),
    ["Polar Bear"]   = Vector3.new(-155, 50, -235),
    ["Mother Bear"]  = Vector3.new(225,   4, -145),
    ["Panda Bear"]   = Vector3.new(145,   4, -195),
    ["Science Bear"] = Vector3.new(-165,  4, -285),
    ["Dapper Bear"]  = Vector3.new(-140,  4, -310),
    ["Spirit Bear"]  = Vector3.new(0,     4, -460),
    ["Gummy Bear"]   = Vector3.new(185,   4,  -55),
    ["Onett"]        = Vector3.new(-66,   4,  -13),
    ["Robo Bear"]    = Vector3.new(70,    4, -390),
}

-- Blender location
local BLENDER_POS = Vector3.new(-60, 4, -80)
-- Hive area default
local HIVE_POS    = Vector3.new(-65, 4, 38)

-- ════════════════════════════════════════════════════
--  EGG PRICES (honey) — từ Brown Bear shop
-- ════════════════════════════════════════════════════
local EGG_PRICES = {
    Basic        = 100,
    Silver       = 1000,
    Gold         = 10000,
    Diamond      = 100000,
    Mythic       = 1000000,
    Gifted_Mythic= 10000000,
}
local EGG_PRIORITY = { "Gifted_Mythic","Mythic","Diamond","Gold","Silver","Basic" }

-- ════════════════════════════════════════════════════
--  STATE — toàn bộ trạng thái agent
-- ════════════════════════════════════════════════════
local CONFIG_CHECK_INTERVAL = 1.5  -- giây giữa mỗi vòng lặp chính
local State = {
    -- hive
    total_slots   = 0,
    filled_slots  = 0,
    bees          = {},   -- { name, rarity, color, gifted }

    -- inventory (đọc từ game)
    honey         = 0,
    pollen        = 0,
    blue_extract  = 0,
    red_extract   = 0,
    eggs          = {},
    items         = {},   -- Glitter, Oil, Blender, Wax...

    -- flags
    diamond_mask_crafted = false,
    pre_glitter_done     = false,
    pre_oil_done         = false,
    mask_buff_active     = false,
    oil_buff_active      = false,

    -- runtime
    current_action = "Khởi động...",
    next_action    = "",
    start_time     = tick(),
    total_honey_farmed = 0,
    glitter_used   = 0,
    oil_used       = 0,
    mask_used      = 0,
    stuck_timer    = 0,
    last_honey     = 0,
    last_slots     = 0,
    running        = true,
}

-- ════════════════════════════════════════════════════
--  UTILS
-- ════════════════════════════════════════════════════
local function Log(icon, msg)
    print(string.format("[%s KAITUN] %s", icon, msg))
end

local function SafeTP(pos)
    if not (HRP and pos) then return end
    HRP.CFrame = CFrame.new(pos + Vector3.new(0, 4.5, 0))
    task.wait(0.2)
end

local function MoveTo(pos, timeout)
    if not (Hum and pos) then return end
    Hum:MoveTo(pos)
    local t, done = 0, false
    local c = Hum.MoveToFinished:Connect(function() done = true end)
    while not done and t < (timeout or 8) do task.wait(0.1); t += 0.1 end
    c:Disconnect()
end

local function FireRE(name, ...)
    local re = ReplicatedStorage:FindFirstChild("Events")
    if not re then return false end
    local args = {...}
    local child = re:FindFirstChild(name)
    if child and child:IsA("RemoteEvent") then
        pcall(function() child:FireServer(table.unpack(args)) end)
        return true
    end
    return false
end

local function FireAny(patterns, ...)
    local re = ReplicatedStorage:FindFirstChild("Events")
    if not re then return false end
    local args = {...}
    for _, pat in ipairs(patterns) do
        for _, child in ipairs(re:GetChildren()) do
            if child.Name:lower():find(pat:lower(), 1, true) then
                if child:IsA("RemoteEvent") then
                    pcall(function() child:FireServer(table.unpack(args)) end)
                    return true
                end
            end
        end
    end
    return false
end

local function Retry(fn, times)
    for i = 1, times or 3 do
        local ok, err = pcall(fn)
        if ok then return true end
        Log("⚠️", "Retry "..i.."/"..times..": "..tostring(err))
        task.wait(1)
    end
    return false
end

-- ════════════════════════════════════════════════════
--  READ STATE từ ClientStatCache hoặc GUI
-- ════════════════════════════════════════════════════
local function ReadState()
    -- Đọc từ ClientStatCache nếu có
    local ok, cache = pcall(require, ReplicatedStorage:FindFirstChild("ClientStatCache"))
    if ok and cache then
        local ok2, stats = pcall(function() return cache:Get() end)
        if ok2 and stats then
            State.honey       = stats.Honey       or stats.honey       or State.honey
            State.pollen      = stats.Pollen      or stats.pollen      or State.pollen
            State.blue_extract= (stats.Inventory and (stats.Inventory.BlueExtract or stats.Inventory["Blue Extract"])) or State.blue_extract
            State.red_extract = (stats.Inventory and (stats.Inventory.RedExtract  or stats.Inventory["Red Extract"]))  or State.red_extract

            -- Eggs
            if stats.Inventory then
                for _, etype in ipairs(EGG_PRIORITY) do
                    State.eggs[etype] = stats.Inventory[etype] or stats.Inventory[etype.."Egg"] or 0
                end
                -- Items
                for _, item in ipairs({"Glitter","Oil","Blender","HardWax","SoftWax","SwirledWax","CausticWax","Enzymes","Coconut","MagicBean"}) do
                    State.items[item] = stats.Inventory[item] or 0
                end
                State.diamond_mask_crafted = (stats.Inventory["DiamondMask"] or stats.Inventory["Diamond Mask"] or 0) > 0
            end

            -- Hive slots
            if stats.HiveSlots then
                State.total_slots  = stats.HiveSlots.Total  or State.total_slots
                State.filled_slots = stats.HiveSlots.Filled or State.filled_slots
            end

            -- Bees
            if stats.Bees then
                State.bees = {}
                local ok3, _ = pcall(function()
                    for _, b in pairs(stats.Bees) do
                        if type(b) == "table" then
                            table.insert(State.bees, {
                                name   = b.Name or b.Type or "?",
                                rarity = b.Rarity or "Common",
                                color  = b.ColorType or b.Color or "None",
                                gifted = b.Gifted or false,
                            })
                        end
                    end
                end)
                if not ok3 then State.bees = {} end
            end
        end
    end

    -- Fallback: đọc honey từ ValueBase objects
    local honeyVal = workspace:FindFirstChild("HoneyDisplay")
        or (LP:FindFirstChild("leaderstats") and LP.leaderstats:FindFirstChild("Honey"))
    if honeyVal and honeyVal:IsA("NumberValue") then
        State.honey = honeyVal.Value
    end
end

-- ════════════════════════════════════════════════════
--  DETECT FIELD ĐANG ĐỨNG
-- ════════════════════════════════════════════════════
local function GetCurrentField()
    if not HRP then return nil end
    local myPos = HRP.Position
    for _, f in ipairs(FIELDS) do
        local flat = Vector3.new(myPos.X, f.p.Y, myPos.Z)
        if (flat - f.p).Magnitude <= f.r then return f.n end
    end
    return nil
end

-- ════════════════════════════════════════════════════
--  DETECT BOOST TIMER
-- ════════════════════════════════════════════════════
local function ParseTime(txt)
    if not txt or txt == "" then return nil end
    txt = txt:match("^%s*(.-)%s*$")
    local m,s = txt:match("^(%d+):(%d+)$")
    if m and s then return tonumber(m)*60+tonumber(s) end
    local sec = txt:match("^(%d+)$")
    if sec then return tonumber(sec) end
    return nil
end

local function GetBoostTimeLeft()
    for _, gui in ipairs(PGui:GetChildren()) do
        for _, obj in ipairs(gui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextBox")) then
                local txt = obj.Text or ""
                if txt:match("^%d+:%d%d$") then
                    local t = ParseTime(txt)
                    if t and t > 0 and t <= 1200 then return t end
                end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") and obj.Name:find("Boost") then
            for _, lbl in ipairs(obj:GetDescendants()) do
                if lbl:IsA("TextLabel") then
                    local t = ParseTime(lbl.Text)
                    if t and t > 0 and t <= 1200 then return t end
                end
            end
        end
    end
    return nil
end

-- ════════════════════════════════════════════════════
--  FARM GRID PATTERN
-- ════════════════════════════════════════════════════
local GRID_OFFSETS = {}
do
    for x = -12, 12, 6 do
        for z = -12, 12, 6 do
            table.insert(GRID_OFFSETS, Vector3.new(x, 0, z))
        end
    end
end

local function FarmField(fieldName)
    local fd = FMAP[fieldName]
    if not fd then return end
    State.current_action = "🌻 Farm: "..fieldName
    SafeTP(fd.p)
    for _, off in ipairs(GRID_OFFSETS) do
        if not State.running then break end
        MoveTo(fd.p + off, 3)
        task.wait(0.12)
        -- Collect items trong range
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:find("Blue Extract") or obj.Name:find("BlueExtract") then
                local p = obj:IsA("BasePart") and obj.Position or nil
                if p and HRP and (p - HRP.Position).Magnitude < 20 then
                    MoveTo(p, 2)
                end
            end
        end
    end
end

local function ConvertHoney()
    State.current_action = "🍯 Convert honey"
    local hivePos = HIVE_POS
    local hives = workspace:FindFirstChild("PlayerHives")
    if hives and hives:FindFirstChild(LP.Name) then
        local h = hives:FindFirstChild(LP.Name)
        if h and h.PrimaryPart then hivePos = h.PrimaryPart.Position end
    end
    SafeTP(hivePos)
    task.wait(0.5)
    FireAny({"MakeHoney","ConvertPollen","Honey"})
    local prev = State.honey
    task.wait(1)
    ReadState()
    if State.honey > prev then
        State.total_honey_farmed += (State.honey - prev)
    end
    Log("🍯", string.format("Convert xong → Honey: %d", State.honey))
end

-- ════════════════════════════════════════════════════
--  CHOOSE BEST FIELD (dựa theo màu ong)
-- ════════════════════════════════════════════════════
local function ChooseBestField()
    local red, blue, total = 0, 0, #State.bees
    for _, b in ipairs(State.bees) do
        if b.color == "Red"  then red  += 1 end
        if b.color == "Blue" then blue += 1 end
    end

    local candidates
    if total > 0 and red/total > 0.6 then
        candidates = {"Rose Field","Mushroom Field","Strawberry Field","Pepper Patch"}
    elseif total > 0 and blue/total > 0.6 then
        candidates = {"Bamboo Field","Pine Tree Forest","Blue Flower Field","Spider Field"}
    else
        candidates = {"Clover Field","Sunflower Field","Mountain Top Field"}
    end

    -- Ưu tiên Blue Flower Field nếu cần Blue Extract
    if not State.diamond_mask_crafted and State.blue_extract < 250 then
        table.insert(candidates, 1, "Blue Flower Field")
    end

    return candidates[1]
end

-- ════════════════════════════════════════════════════
--  USE ITEM
-- ════════════════════════════════════════════════════
local function UseItem(itemName)
    FireAny({"UseItemEvent","UseItem","ItemEvent","ActivatableEvent"}, itemName)
    FireAny({"UseItemEvent","UseItem"}, {Type=itemName, Category="Eggs"})
    Log("⚡", "Dùng item: "..itemName)
end

-- ════════════════════════════════════════════════════
--  CRAFT VIA BLENDER
-- ════════════════════════════════════════════════════
local function GoBlender()
    -- Tìm Blender trong workspace
    local blender = workspace:FindFirstChild("Blender")
    if blender then
        local pos = nil
        if blender:IsA("BasePart") then
            pos = blender.Position
        elseif blender:IsA("Model") and blender.PrimaryPart then
            pos = blender.PrimaryPart.Position
        elseif blender:IsA("Model") then
            local p = blender:FindFirstChildWhichIsA("BasePart")
            if p then pos = p.Position end
        end
        if pos then SafeTP(pos); task.wait(0.5); return end
    end
    SafeTP(BLENDER_POS)
    task.wait(0.5)
end

local function CraftItem(recipe, resultName)
    State.current_action = "🍹 Craft: "..resultName
    GoBlender()
    -- Fire craft remote
    local fired = FireAny({"CraftEvent","BlenderEvent","Craft","Blender"}, recipe)
    if not fired then
        FireAny({"CraftEvent","BlenderEvent"}, {Recipe=recipe, Result=resultName})
    end
    task.wait(0.8)
    Log("🍹", "Craft: "..resultName)
end

-- ════════════════════════════════════════════════════
--  STEP 0 — DIAMOND MASK & PRE-CRAFT
-- ════════════════════════════════════════════════════
local function Step0_DiamondMask()
    if State.diamond_mask_crafted then return end

    local blue = State.blue_extract
    Log("💎", string.format("Blue Extract: %d/250 (%.0f%%)", blue, blue/250*100))

    if blue >= 250 then
        -- Craft Diamond Mask
        State.current_action = "💎 Craft Diamond Mask"
        Retry(function()
            CraftItem("DiamondMask", "Diamond Mask")
        end, 3)
        State.diamond_mask_crafted = true
        Log("💎", "Diamond Mask ✅ CRAFTED!")

        -- Dùng combo ngay
        task.wait(0.3)
        if (State.items["Glitter"] or 0) > 0 then
            UseItem("Glitter")
            State.glitter_used += 1
        end
        if (State.items["Oil"] or 0) > 0 then
            UseItem("Oil")
            State.oil_used += 1
        end
        UseItem("DiamondMask")
        State.mask_used += 1

    elseif blue >= 200 then
        -- Pre-craft Glitter + Oil từ nguyên liệu khác
        if not State.pre_glitter_done then
            State.current_action = "⚡ Pre-craft Glitter"
            Retry(function() CraftItem("Glitter", "Glitter") end, 2)
            State.pre_glitter_done = true
            Log("⚡", string.format("PRE-CRAFT Glitter ✅ (Blue Extract %d/250)", blue))
        end
        if not State.pre_oil_done then
            State.current_action = "⚡ Pre-craft Oil"
            Retry(function() CraftItem("Oil", "Oil") end, 2)
            State.pre_oil_done = true
            Log("⚡", string.format("PRE-CRAFT Oil ✅ (Blue Extract %d/250)", blue))
        end
        State.next_action = string.format("Còn %d Blue Extract nữa → craft Diamond Mask", 250-blue)

    else
        State.next_action = string.format("Cần thêm %d Blue Extract (hiện %d/250)", 250-blue, blue)
    end
end

-- ════════════════════════════════════════════════════
--  STEP 1 — CRAFT ITEMS KHÁC
-- ════════════════════════════════════════════════════
local function Step1_CraftOthers()
    -- Glitter nếu hết (sau khi đã có Diamond Mask)
    if State.diamond_mask_crafted and (State.items["Glitter"] or 0) == 0 then
        State.current_action = "🍬 Craft Glitter"
        Retry(function() CraftItem("Glitter","Glitter") end, 2)
    end
    -- Oil nếu hết
    if State.diamond_mask_crafted and (State.items["Oil"] or 0) == 0 then
        State.current_action = "🛢️ Craft Oil"
        Retry(function() CraftItem("Oil","Oil") end, 2)
    end
    -- Tropical Drink
    if (State.items["Coconut"] or 0) >= 10 and (State.items["MagicBean"] or 0) >= 1 then
        State.current_action = "🍹 Craft Tropical Drink"
        Retry(function() CraftItem("TropicalDrink","Tropical Drink") end, 2)
    end
    -- Wax (bất kỳ loại nào có nguyên liệu)
    for _, wax in ipairs({"SwirledWax","HardWax","SoftWax","CausticWax"}) do
        -- craft nếu có nguyên liệu (logic đơn giản: thử craft)
        -- game sẽ validate nguyên liệu server-side
    end
    -- Enzymes / Micro-Converter
    for _, item in ipairs({"Enzymes","MicroConverter"}) do
        -- tương tự
    end
end

-- ════════════════════════════════════════════════════
--  STEP 2 — ĐẶT EGG VÀO SLOT
-- ════════════════════════════════════════════════════
local function Step2_PlaceEgg()
    local empty = State.total_slots - State.filled_slots
    if empty <= 0 then return end

    -- Tìm egg tốt nhất trong inventory
    local bestEgg = nil
    for _, etype in ipairs(EGG_PRIORITY) do
        if (State.eggs[etype] or 0) > 0 then
            bestEgg = etype; break
        end
    end

    if not bestEgg then return end

    State.current_action = "🥚 Đặt "..bestEgg.." Egg → slot "..State.filled_slots+1
    Log("🥚", string.format("Đặt %s Egg → slot %d", bestEgg, State.filled_slots+1))

    -- Teleport đến hive
    local hivePos = HIVE_POS
    local hives = workspace:FindFirstChild("PlayerHives")
    if hives and hives:FindFirstChild(LP.Name) then
        local h = hives:FindFirstChild(LP.Name)
        if h and h.PrimaryPart then hivePos = h.PrimaryPart.Position end
    end
    SafeTP(hivePos)
    task.wait(0.5)

    Retry(function()
        FireAny({"PlaceEgg","HatchEgg","EggEvent","UseEgg"}, bestEgg)
        FireAny({"PlaceEgg","HatchEgg"}, {Type=bestEgg, Category="Eggs"})
    end, 3)

    task.wait(2) -- chờ egg nở
    ReadState()
    Log("🥚", string.format("→ Slot %d/%d", State.filled_slots, State.total_slots))
end

-- ════════════════════════════════════════════════════
--  STEP 3 — MUA EGG
-- ════════════════════════════════════════════════════
local function Step3_BuyEgg()
    local empty = State.total_slots - State.filled_slots
    if empty <= 0 then return end

    -- Có egg rồi thì thôi
    for _, etype in ipairs(EGG_PRIORITY) do
        if (State.eggs[etype] or 0) > 0 then return end
    end

    -- Chọn egg tốt nhất có thể mua
    local chosen = nil
    for _, etype in ipairs(EGG_PRIORITY) do
        local ePrice = EGG_PRICES[etype] or math.huge
    if State.honey >= ePrice and ePrice < math.huge then
            chosen = etype; break
        end
    end

    if not chosen then
        State.next_action = string.format("Farm thêm honey (cần %d để mua Basic Egg)", EGG_PRICES.Basic)
        return
    end

    State.current_action = "🛒 Mua "..chosen.." Egg"
    Log("🛒", string.format("Mua %s Egg (honey: %d)", chosen, State.honey))

    -- Đến shop (Brown Bear hoặc NPC bán egg)
    SafeTP(NPCS["Brown Bear"] or HIVE_POS)
    task.wait(0.5)

    Retry(function()
        FireAny({"BuyEgg","PurchaseEgg","ShopEvent"}, chosen)
        FireAny({"BuyEgg","PurchaseEgg"}, {Type=chosen, Category="Eggs"})
    end, 3)

    task.wait(0.5)
    ReadState()
end

-- ════════════════════════════════════════════════════
--  STEP 4 — MUA SLOT HIVE
-- ════════════════════════════════════════════════════
local function Step4_BuySlot()
    if State.total_slots >= 50 then return end
    -- Giá slot tăng dần, ước tính đơn giản
    local slotExp = math.min(math.floor(State.total_slots / 5) + 2, 7)
    local slotCost = math.pow(10, slotExp)

    if State.honey < slotCost then
        State.next_action = string.format("Cần %d honey để mua slot %d", slotCost, State.total_slots+1)
        return
    end

    State.current_action = "🏠 Mua slot hive "..State.total_slots+1
    Log("🏠", string.format("Mua slot %d (chi %d honey)", State.total_slots+1, slotCost))

    SafeTP(HIVE_POS)
    task.wait(0.5)
    Retry(function()
        FireAny({"BuySlot","HiveSlot","SlotEvent"})
        FireAny({"BuySlot"}, {Action="BuySlot"})
    end, 3)
    task.wait(0.5)
    ReadState()
end

-- ════════════════════════════════════════════════════
--  STEP 5 — MUA BEEQUIP
-- ════════════════════════════════════════════════════
local function Step5_BuyBeequip()
    -- Chỉ mua nếu honey rất dư
    local slotExp = math.min(math.floor(State.total_slots / 5) + 2, 7)
    local slotCost = math.pow(10, slotExp)
    if State.honey < slotCost * 1.5 then return end

    -- Ưu tiên beequip theo vị trí slot
    local idx = State.filled_slots
    local beequipType
    if idx <= 10 then
        beequipType = "GatherBeequip"   -- buff GatherAmount
    elseif idx <= 25 then
        beequipType = "AttackBeequip"   -- buff Attack
    else
        beequipType = "EventBeequip"    -- Snow Tiara, Reindeer Antlers...
    end

    State.current_action = "💍 Mua beequip: "..beequipType
    Log("💍", "Mua beequip cho slot "..idx)

    Retry(function()
        FireAny({"BuyBeequip","BeequipEvent","ShopEvent"}, beequipType)
    end, 2)
    task.wait(0.5)
end

-- ════════════════════════════════════════════════════
--  STEP 6 — FARM POLLEN
-- ════════════════════════════════════════════════════
local function Step6_Farm()
    local fieldName = ChooseBestField()
    State.current_action = "🌻 Farm: "..fieldName

    local red, blue, total = 0, 0, #State.bees
    for _, b in ipairs(State.bees) do
        if b.color == "Red"  then red  += 1 end
        if b.color == "Blue" then blue += 1 end
    end
    local white = total - red - blue
    Log("🌻", string.format("Farm %s | Ong: %dR/%dB/%dW", fieldName,
        red, blue, white))

    -- 3 rounds farm → convert
    for round = 1, 3 do
        if not State.running then break end
        FarmField(fieldName)
        ConvertHoney()
        ReadState()
        Log("📊", string.format("Round %d | Honey: %d | BlueExtract: %d/250",
            round, State.honey, State.blue_extract))
    end
end

-- ════════════════════════════════════════════════════
--  STEP 7 — BOOST MANAGEMENT
-- ════════════════════════════════════════════════════
local function Step7_Boost()
    local curField = GetCurrentField()
    local boostTime = GetBoostTimeLeft()

    -- Glitter khi boost sắp hết và đang trong field
    if curField and boostTime and boostTime <= 10 and (State.items["Glitter"] or 0) > 0 then
        UseItem("Glitter")
        State.glitter_used += 1
        Log("🍬", string.format("Dùng Glitter (boost còn %ds)", math.floor(boostTime)))
    end

    -- Oil khi bắt đầu farm
    if not State.oil_buff_active and (State.items["Oil"] or 0) > 0 then
        UseItem("Oil")
        State.oil_used += 1
        State.oil_buff_active = true
        Log("🛢️", "Dùng Oil")
    end

    -- Diamond Mask khi có
    if State.diamond_mask_crafted and not State.mask_buff_active then
        UseItem("DiamondMask")
        State.mask_used += 1
        State.mask_buff_active = true
        Log("💎", "Dùng Diamond Mask")
    end
end

-- ════════════════════════════════════════════════════
--  LOG TIẾN ĐỘ
-- ════════════════════════════════════════════════════
local function PrintProgress()
    local elapsed = math.floor(tick() - State.start_time)
    local h = math.floor(elapsed/3600)
    local m = math.floor((elapsed%3600)/60)
    local s = elapsed % 60
    local pct = State.total_slots > 0 and math.floor(State.filled_slots/50*100) or 0
    local blue = State.blue_extract

    print("╔══════════════════════════════════════════════════╗")
    print(string.format("║ [🐝 KAITUN]  Tiến độ: %d/50 slot (%d%%)       ║",
        State.filled_slots, pct))
    print(string.format("║  🕐 Thời gian : %02dh %02dm %02ds", h, m, s))
    print(string.format("║  🍯 Honey     : %d  (+%d farmed)",
        State.honey, State.total_honey_farmed))
    if not State.diamond_mask_crafted then
        print(string.format("║  💎 Dia Mask  : ❌  %d/250 Blue Extract (%.0f%%)",
            blue, blue/250*100))
        print(string.format("║  ⚡ Pre-craft : Glitter %s | Oil %s",
            State.pre_glitter_done and "✅" or "❌",
            State.pre_oil_done and "✅" or "❌"))
    else
        print("║  💎 Dia Mask  : ✅ đã có")
    end
    print(string.format("║  🍬 Glitter   : x%d  | 🛢️  Oil: x%d",
        State.items["Glitter"] or 0, State.items["Oil"] or 0))
    -- Eggs
    local eggStr = ""
    for _, et in ipairs(EGG_PRIORITY) do
        local cnt = State.eggs[et] or 0
        if cnt > 0 then eggStr = eggStr..et.."x"..cnt.." " end
    end
    print("║  🥚 Eggs      : "..(eggStr == "" and "không có" or eggStr))
    print("║  ▶ Action    : "..State.current_action)
    print("║  ▷ Tiếp theo : "..State.next_action)
    print("╚══════════════════════════════════════════════════╝")
end

-- ════════════════════════════════════════════════════
--  STUCK DETECTION
-- ════════════════════════════════════════════════════
local function CheckStuck()
    -- Honey không tăng sau 60s
    if State.honey == State.last_honey then
        State.stuck_timer += CONFIG_CHECK_INTERVAL
        if State.stuck_timer >= 60 then
            Log("⚠️", "Farm stuck → đổi field")
            State.stuck_timer = 0
        end
    else
        State.stuck_timer = 0
        State.last_honey = State.honey
    end

    -- Slots không tăng sau 5 phút
    if State.filled_slots == State.last_slots then
        -- không làm gì, chỉ log
    else
        State.last_slots = State.filled_slots
    end
end

-- ════════════════════════════════════════════════════
--  KHAI BÁO BIẾN GUI SỚM (dùng trong loop)
-- ════════════════════════════════════════════════════
local ProgressLbl, HoneyLbl, DiaMaskLbl, PreCraftLbl
local GlitLbl, FieldLbl, ActionLbl, NextLbl, TimeLbl

-- ════════════════════════════════════════════════════
--  GUI UPDATE
-- ════════════════════════════════════════════════════
local function UpdateGUI()
    local pct = math.floor(State.filled_slots/50*100)
    if ProgressLbl then
        ProgressLbl.Text = string.format("🐝  %d / 50 slot  (%d%%)", State.filled_slots, pct)
    end
    if HoneyLbl then
        HoneyLbl.Text = string.format("🍯 Honey: %d", State.honey)
    end
    if DiaMaskLbl then
        if State.diamond_mask_crafted then
            DiaMaskLbl.Text = "💎 Diamond Mask: ✅"
            DiaMaskLbl.TextColor3 = Color3.fromRGB(70,210,110)
        else
            DiaMaskLbl.Text = string.format("💎 Blue Extract: %d/250 (%.0f%%)",
                State.blue_extract, State.blue_extract/250*100)
            DiaMaskLbl.TextColor3 = State.blue_extract >= 200
                and Color3.fromRGB(255,175,0)
                or  Color3.fromRGB(90,90,120)
        end
    end
    if PreCraftLbl then
        PreCraftLbl.Text = string.format("⚡ Pre-craft: Glitter %s | Oil %s",
            State.pre_glitter_done and "✅" or "❌",
            State.pre_oil_done and "✅" or "❌")
    end
    if GlitLbl then
        GlitLbl.Text = string.format("🍬 x%d  🛢️ x%d  💎Used:%d",
            State.items["Glitter"] or 0,
            State.items["Oil"] or 0,
            State.mask_used)
    end
    if ActionLbl then ActionLbl.Text = "▶ "..State.current_action end
    if NextLbl   then NextLbl.Text   = "▷ "..State.next_action   end
    if TimeLbl   then
        local e = math.floor(tick()-State.start_time)
        TimeLbl.Text = string.format("⏱ %02dh %02dm %02ds",
            math.floor(e/3600), math.floor(e%3600/60), e%60)
    end
end

-- ════════════════════════════════════════════════════
--  GUI BUILD
-- ════════════════════════════════════════════════════
local CLR = {
    BG     = Color3.fromRGB(9,9,16),
    PANEL  = Color3.fromRGB(18,18,30),
    ACCENT = Color3.fromRGB(255,175,0),
    TEXT   = Color3.fromRGB(215,215,225),
    DIM    = Color3.fromRGB(90,90,120),
    GREEN  = Color3.fromRGB(70,210,110),
    RED    = Color3.fromRGB(215,70,70),
}

local SG = Instance.new("ScreenGui")
SG.Name="KaitunAgent"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.Parent=PGui

local W = Instance.new("Frame",SG)
W.Size=UDim2.new(0,300,0,310); W.Position=UDim2.new(0,14,0.5,-155)
W.BackgroundColor3=CLR.BG; W.BorderSizePixel=0
Instance.new("UICorner",W).CornerRadius=UDim.new(0,14)
local wS=Instance.new("UIStroke",W); wS.Color=CLR.ACCENT; wS.Thickness=1.5

-- Title
local TB=Instance.new("Frame",W)
TB.Size=UDim2.new(1,0,0,40); TB.BackgroundColor3=CLR.ACCENT; TB.BorderSizePixel=0
Instance.new("UICorner",TB).CornerRadius=UDim.new(0,14)
local TBF=Instance.new("Frame",TB); TBF.Size=UDim2.new(1,0,0.5,0); TBF.Position=UDim2.new(0,0,0.5,0)
TBF.BackgroundColor3=CLR.ACCENT; TBF.BorderSizePixel=0
local TL=Instance.new("TextLabel",TB)
TL.Size=UDim2.new(1,0,1,0); TL.BackgroundTransparency=1
TL.Text="🐝  KAITUN AGENT"; TL.TextColor3=CLR.BG
TL.Font=Enum.Font.GothamBold; TL.TextScaled=true

-- Stop button
local StopBtn=Instance.new("TextButton",TB)
StopBtn.Size=UDim2.new(0,36,0,26); StopBtn.Position=UDim2.new(1,-40,0.5,-13)
StopBtn.BackgroundColor3=CLR.RED; StopBtn.Text="■ STOP"
StopBtn.TextColor3=Color3.new(1,1,1); StopBtn.Font=Enum.Font.GothamBold
StopBtn.TextSize=10; StopBtn.BorderSizePixel=0
Instance.new("UICorner",StopBtn).CornerRadius=UDim.new(0,6)
StopBtn.MouseButton1Click:Connect(function()
    State.running = false
    Log("■", "KAITUN dừng bởi người dùng")
end)

-- Progress bar bg
local PBG=Instance.new("Frame",W)
PBG.Size=UDim2.new(1,-16,0,12); PBG.Position=UDim2.new(0,8,0,46)
PBG.BackgroundColor3=Color3.fromRGB(25,25,40); PBG.BorderSizePixel=0
Instance.new("UICorner",PBG).CornerRadius=UDim.new(0,6)
local PBar=Instance.new("Frame",PBG)
PBar.Size=UDim2.new(0,0,1,0); PBar.BackgroundColor3=CLR.ACCENT; PBar.BorderSizePixel=0
Instance.new("UICorner",PBar).CornerRadius=UDim.new(0,6)

-- Labels helper
local function MkLbl(posY, h, size, bold)
    local l=Instance.new("TextLabel",W)
    l.Size=UDim2.new(1,-12,0,h); l.Position=UDim2.new(0,6,0,posY)
    l.BackgroundTransparency=1; l.Text=""; l.TextColor3=CLR.TEXT
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=size or 12; l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

ProgressLbl = MkLbl(62,  22, 14, true)
HoneyLbl    = MkLbl(84,  18, 12, false)
DiaMaskLbl  = MkLbl(103, 18, 12, false)
PreCraftLbl = MkLbl(122, 16, 11, false)
GlitLbl     = MkLbl(139, 16, 11, false)

-- Divider
local div=Instance.new("Frame",W)
div.Size=UDim2.new(1,-12,0,1); div.Position=UDim2.new(0,6,0,158)
div.BackgroundColor3=Color3.fromRGB(30,30,50); div.BorderSizePixel=0

ActionLbl = MkLbl(163, 20, 12, true)
NextLbl   = MkLbl(184, 18, 11, false)
TimeLbl   = MkLbl(204, 16, 11, false)

-- Drag
do
    local drag,ds,fp=false,nil,nil
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; ds=i.Position; fp={X={Scale=W.Position.X.Scale,Offset=W.Position.X.Offset},Y={Scale=W.Position.Y.Scale,Offset=W.Position.Y.Offset}} end
    end)
    TB.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            W.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
        end
    end)
end

-- GUI update loop
task.spawn(function()
    while true do
        task.wait(0.5)
        UpdateGUI()
        -- Update progress bar
        local pct = math.clamp(State.filled_slots / 50, 0, 1)
        TweenService:Create(PBar, TweenInfo.new(0.4), {
            Size = UDim2.new(pct, 0, 1, 0)
        }):Play()
    end
end)

-- ════════════════════════════════════════════════════
--  MAIN AGENT LOOP
-- ════════════════════════════════════════════════════
task.spawn(function()
    Log("🐝", "KAITUN AGENT khởi động! Mục tiêu: 50/50 slot ong")

    -- Đọc trạng thái ban đầu
    ReadState()
    State.last_honey = State.honey
    State.last_slots = State.filled_slots

    while State.running and State.filled_slots < 50 do
        local ok, err = pcall(function()

            -- Đọc state mới nhất
            ReadState()
            CheckStuck()

            -- ── STEP 0: Diamond Mask + Pre-craft ──
            Step0_DiamondMask()

            -- ── STEP 1: Craft items khác ──
            Step1_CraftOthers()

            -- ── Kiểm tra slot còn trống không ──
            local empty = State.total_slots - State.filled_slots

            if empty > 0 then
                -- ── STEP 2: Đặt egg vào slot ──
                Step2_PlaceEgg()
            else
                -- Hive đầy → mua thêm slot
                Step4_BuySlot()
            end

            -- ── STEP 3: Mua egg nếu cần ──
            Step3_BuyEgg()

            -- ── STEP 4: Mua beequip ──
            Step5_BuyBeequip()

            -- ── STEP 5: Farm pollen ──
            Step6_Farm()

            -- ── STEP 6: Boost management ──
            Step7_Boost()

            -- ── Log tiến độ mỗi 10 vòng ──
            PrintProgress()

        end)

        if not ok then
            Log("❌", "Loop error: "..tostring(err))
            task.wait(3)
        end

        task.wait(1.5)
    end

    -- ════ KẾT THÚC ════
    if State.filled_slots >= 50 then
        local elapsed = math.floor(tick() - State.start_time)
        print("╔════════════════════════════════════════════════════╗")
        print("║  🎉  HOÀN THÀNH! 50/50 slot ong đã đầy!          ║")
        print(string.format("║  ⏱  Thời gian: %02dh %02dm %02ds",
            math.floor(elapsed/3600), math.floor(elapsed%3600/60), elapsed%60))
        print(string.format("║  🍯  Tổng honey farmed: %d", State.total_honey_farmed))
        print(string.format("║  🍬  Glitter dùng: %d | 🛢️ Oil: %d | 💎 Mask: %d",
            State.glitter_used, State.oil_used, State.mask_used))
        print("║  📋  Danh sách 50 ong:")
        for i, b in ipairs(State.bees) do
            print(string.format("║    %02d. %s%s [%s]",
                i, b.gifted and "⭐ " or "", b.name, b.rarity))
        end
        print("╚════════════════════════════════════════════════════╝")
        if ActionLbl then ActionLbl.Text = "🎉 HOÀN THÀNH 50/50!" end
    end
end)

Log("🐝", "Script loaded! KAITUN đang chạy...")