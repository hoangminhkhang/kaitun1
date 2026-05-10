--[[
    =============================================
    Auto Kaitun Starter - Bee Swarm Simulator
    =============================================
    Chức năng:
      1. Auto mua tất cả Accessories có thể mua (theo thứ tự giá từ thấp -> cao)
      2. Auto mua Hive Slot + đặt Basic Egg cho đến khi đủ 20 con ong
    
    Cách dùng: Chạy script này trong executor (sau khi đã vào game BSS)
    =============================================
]]

-- ============================================
-- SERVICES & VARIABLES
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local plr = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")
local ConstructHiveCellFromEgg = Events:WaitForChild("ConstructHiveCellFromEgg")
local RetrievePlayerStats = Events:WaitForChild("RetrievePlayerStats")
local ClaimHive = Events:WaitForChild("ClaimHive")

-- ============================================
-- CONFIG
-- ============================================
local TARGET_BEE_COUNT = 20
local BUY_DELAY = 0.5          -- Delay giữa mỗi lần mua (tránh rate limit)
local STAT_REFRESH_DELAY = 1   -- Delay refresh stats

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Lấy stat cache từ server
local function GetStatCache()
    local success, result = pcall(function()
        return RetrievePlayerStats:InvokeServer()
    end)
    if success then return result end
    return nil
end

-- Lấy honey hiện tại
local function GetHoney()
    if plr:FindFirstChild("CoreStats") and plr.CoreStats:FindFirstChild("Honey") then
        return plr.CoreStats.Honey.Value
    end
    return 0
end

-- Đếm số ong hiện tại trong hive
local function GetCurrentBeeCount()
    local beeCount = 0
    for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and tostring(hive.Owner.Value) == plr.Name then
            if hive:FindFirstChild("Cells") then
                for _, cell in pairs(hive.Cells:GetChildren()) do
                    if cell:FindFirstChild("CellType") then
                        local cellType = tostring(cell.CellType.Value)
                        if cellType ~= "Empty" and cellType ~= "nil" and cellType ~= "" then
                            beeCount = beeCount + 1
                        end
                    end
                end
            end
        end
    end
    return beeCount
end

-- Lấy số slot đã unlock
local function GetUnlockedSlots()
    local statCache = GetStatCache()
    if statCache then
        return statCache.UnlockedCells or 0
    end
    return 0
end

-- Lấy danh sách hive slot trống (chưa có ong)
local function GetEmptyHiveSlots()
    local emptySlots = {}
    for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and tostring(hive.Owner.Value) == plr.Name then
            if hive:FindFirstChild("Cells") then
                for _, cell in pairs(hive.Cells:GetChildren()) do
                    if cell:FindFirstChild("CellType") then
                        local cellType = tostring(cell.CellType.Value)
                        if cellType == "Empty" or cellType == "nil" or cellType == "" then
                            -- Parse cell name để lấy X, Y (format: "C{x},{y}")
                            local cellName = cell.Name
                            local x, y = cellName:match("C(%d+),(%d+)")
                            if x and y then
                                table.insert(emptySlots, {X = tonumber(x), Y = tonumber(y), Cell = cell})
                            end
                        end
                    end
                end
            end
        end
    end
    return emptySlots
end

-- Mua item qua ItemPackageEvent
local function PurchaseItem(category, itemType, amount)
    local purchaseData = {
        ["Category"] = category,
        ["Type"] = itemType,
    }
    if amount then
        purchaseData["Amount"] = amount
    end
    
    local success, result = pcall(function()
        return ItemPackageEvent:InvokeServer("Purchase", purchaseData)
    end)
    return success and result
end

-- Equip accessory
local function EquipAccessory(accessoryType)
    local success, result = pcall(function()
        return ItemPackageEvent:InvokeServer("Equip", {
            ["Mute"] = true,
            ["Type"] = accessoryType,
            ["Category"] = "Accessory"
        })
    end)
    return success and result
end

-- Đặt egg vào slot
local function PlaceEgg(x, y, eggType)
    local success, result = pcall(function()
        return ConstructHiveCellFromEgg:InvokeServer(x, y, eggType or "BasicEgg", 1, false)
    end)
    return success and result
end

-- Format số cho dễ đọc
local function FormatNumber(n)
    if n >= 1e12 then return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.2fK", n / 1e3)
    else return tostring(n) end
end

-- Thông báo
local function Notify(msg)
    print("[Auto Kaitun] " .. msg)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Auto Kaitun",
            Text = msg,
            Duration = 3
        })
    end)
end

-- ============================================
-- ACCESSORIES DATA (theo thứ tự giá từ thấp -> cao)
-- ============================================
local AccessoryBuyOrder = {
    -- Giá rẻ (starter)
    {Type = "Helmet",           Category = "Accessory", Cost = 30000},
    {Type = "Brave Guard",      Category = "Accessory", Cost = 300000},
    {Type = "Hasty Guard",      Category = "Accessory", Cost = 300000},
    {Type = "Bomber Guard",     Category = "Accessory", Cost = 300000},
    {Type = "Looker Guard",     Category = "Accessory", Cost = 300000},
    
    -- Giá trung bình
    {Type = "Blue Guard",       Category = "Accessory", Cost = 1000000},
    {Type = "Red Guard",        Category = "Accessory", Cost = 1000000},
    {Type = "Elite Blue Guard", Category = "Accessory", Cost = 3000000},
    {Type = "Elite Red Guard",  Category = "Accessory", Cost = 3000000},
    {Type = "Propeller Hat",    Category = "Accessory", Cost = 2500000},
    
    -- Boots
    {Type = "Basic Boots",      Category = "Accessory", Cost = 50000},
    {Type = "Hiking Boots",     Category = "Accessory", Cost = 2500000},
    {Type = "Beekeeper's Boots",Category = "Accessory", Cost = 15000000},
    
    -- Belt
    {Type = "Belt Pocket",      Category = "Accessory", Cost = 50000},
    {Type = "Mondo Belt Bag",   Category = "Accessory", Cost = 1500000},
    
    -- Wings
    {Type = "Parachute",        Category = "Accessory", Cost = 500000},
    {Type = "Glider",           Category = "Accessory", Cost = 5000000},

    -- High tier
    {Type = "Beekeeper's Mask", Category = "Accessory", Cost = 20000000},
    {Type = "Honey Mask",       Category = "Accessory", Cost = 100000000},
    {Type = "Fire Mask",        Category = "Accessory", Cost = 100000000},
    {Type = "Bubble Mask",      Category = "Accessory", Cost = 100000000},
}

-- ============================================
-- AUTO BUY ACCESSORIES
-- ============================================
local function AutoBuyAccessories()
    Notify("Bắt đầu Auto Mua Accessories...")
    
    local statCache = GetStatCache()
    if not statCache then
        Notify("Không thể lấy stat cache!")
        return
    end
    
    local boughtCount = 0
    
    for _, accessory in ipairs(AccessoryBuyOrder) do
        local itemType = accessory.Type
        
        -- Kiểm tra xem đã mua chưa
        local alreadyOwned = false
        pcall(function()
            local ItemPackages = require(ReplicatedStorage.ItemPackages)
            local ClientStatCache = require(ReplicatedStorage.ClientStatCache)
            local stats = ClientStatCache:Get()
            local itemData = {
                Category = "Accessory",
                Type = itemType
            }
            -- Nếu CanGive trả về false => đã sở hữu
            alreadyOwned = not ItemPackages.CanGive(itemData, stats)
        end)
        
        if alreadyOwned then
            -- Đã sở hữu, bỏ qua
        else
            -- Thử mua
            local honey = GetHoney()
            if honey >= accessory.Cost then
                Notify("Đang mua: " .. itemType .. " (" .. FormatNumber(accessory.Cost) .. " Honey)")
                
                local bought = PurchaseItem("Accessory", itemType)
                if bought then
                    boughtCount = boughtCount + 1
                    Notify("✅ Đã mua: " .. itemType)
                    task.wait(BUY_DELAY)
                else
                    Notify("❌ Không thể mua: " .. itemType .. " (thiếu nguyên liệu hoặc chưa đủ điều kiện)")
                end
            else
                Notify("⏭️ Bỏ qua " .. itemType .. " (thiếu " .. FormatNumber(accessory.Cost - honey) .. " Honey)")
            end
        end
        
        task.wait(0.2)
    end
    
    Notify("Hoàn tất Auto Mua Accessories! Đã mua " .. boughtCount .. " items.")
end

-- ============================================
-- AUTO BUY HIVE SLOTS + PLACE BEES
-- ============================================
local function AutoBuyHiveSlotsAndPlaceBees()
    Notify("Bắt đầu Auto Đặt Ong (mục tiêu: " .. TARGET_BEE_COUNT .. " con)...")
    
    while true do
        local currentBees = GetCurrentBeeCount()
        
        if currentBees >= TARGET_BEE_COUNT then
            Notify("🎉 Đã đạt " .. currentBees .. "/" .. TARGET_BEE_COUNT .. " con ong! Hoàn tất!")
            break
        end
        
        Notify("Hiện tại: " .. currentBees .. "/" .. TARGET_BEE_COUNT .. " con ong")
        
        -- Kiểm tra slot trống
        local emptySlots = GetEmptyHiveSlots()
        
        if #emptySlots > 0 then
            -- Có slot trống -> đặt Basic Egg
            local slot = emptySlots[1]
            Notify("Đặt Basic Egg vào slot (" .. slot.X .. ", " .. slot.Y .. ")...")
            
            local placed = PlaceEgg(slot.X, slot.Y, "BasicEgg")
            if placed then
                Notify("✅ Đã đặt ong vào slot (" .. slot.X .. ", " .. slot.Y .. ")")
            else
                -- Thử mua BasicEgg trước rồi đặt
                Notify("Thử mua Basic Egg...")
                PurchaseItem("Egg", "BasicEgg")
                task.wait(BUY_DELAY)
                placed = PlaceEgg(slot.X, slot.Y, "BasicEgg")
                if placed then
                    Notify("✅ Đã mua và đặt ong!")
                else
                    Notify("❌ Không thể đặt ong (có thể thiếu egg hoặc lỗi)")
                end
            end
        else
            -- Không có slot trống -> mua thêm Hive Slot
            local honey = GetHoney()
            Notify("Không có slot trống. Đang mua Hive Slot... (Honey: " .. FormatNumber(honey) .. ")")
            
            local bought = PurchaseItem("HiveSlot", "HiveSlot", 1)
            if bought then
                Notify("✅ Đã mua thêm 1 Hive Slot!")
            else
                Notify("❌ Không đủ Honey để mua Hive Slot! Chờ 10 giây...")
                task.wait(10)
            end
        end
        
        task.wait(STAT_REFRESH_DELAY)
    end
end

-- ============================================
-- TELEPORT FUNCTIONS (từ main_kaitun.lua)
-- ============================================
local function TpToHive()
    pcall(function()
        for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
            if hive:FindFirstChild("Owner") and tostring(hive.Owner.Value) == plr.Name then
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    plr.Character.HumanoidRootPart.CFrame = hive.SpawnPos.Value + Vector3.new(0, 5, 0)
                end
                break
            end
        end
    end)
end

-- ============================================
-- AUTO CLAIM HIVE
-- ============================================
local function GetPlayerHive()
    for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and tostring(hive.Owner.Value) == plr.Name then
            return hive
        end
    end
    return nil
end

local function AutoClaimHive()
    if GetPlayerHive() then
        Notify("✅ Đã có hive rồi, bỏ qua claim.")
        return true
    end
    
    Notify("🏠 Chưa có hive! Đang tìm hive trống để claim...")
    
    -- Lấy danh sách hive từ cuối (thường hive cuối trống)
    local honeycombs = Workspace.Honeycombs:GetChildren()
    
    -- Đảo ngược danh sách (ưu tiên hive phía sau)
    local reversed = {}
    for i = #honeycombs, 1, -1 do
        table.insert(reversed, honeycombs[i])
    end
    
    local maxAttempts = 30
    local attempt = 0
    
    while not GetPlayerHive() and attempt < maxAttempts do
        attempt = attempt + 1
        Notify("Lần thử claim #" .. attempt .. "...")
        
        for _, hive in pairs(reversed) do
            if hive:FindFirstChild("Owner") and tostring(hive.Owner.Value) == "nil" then
                -- Tìm thấy hive trống!
                Notify("Tìm thấy hive trống: " .. hive.Name .. " (ID: " .. tostring(hive:FindFirstChild("HiveID") and hive.HiveID.Value or "?") .. ")")
                
                -- TP đến hive
                pcall(function()
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        if hive:FindFirstChild("LightHolder") then
                            plr.Character.HumanoidRootPart.CFrame = hive.LightHolder.CFrame
                        elseif hive:FindFirstChild("SpawnPos") then
                            plr.Character.HumanoidRootPart.CFrame = hive.SpawnPos.Value + Vector3.new(0, 5, 0)
                        end
                    end
                end)
                
                task.wait(1)
                
                -- Gửi claim request
                pcall(function()
                    if hive:FindFirstChild("HiveID") then
                        ClaimHive:FireServer(hive.HiveID.Value)
                        Notify("📨 Đã gửi claim hive ID: " .. tostring(hive.HiveID.Value))
                    end
                end)
                
                task.wait(2)
                
                -- Kiểm tra đã claim thành công chưa
                if GetPlayerHive() then
                    Notify("🎉 Claim hive thành công!")
                    return true
                end
                
                break -- Thử lại từ đầu nếu chưa thành công
            end
        end
        
        task.wait(2)
    end
    
    if GetPlayerHive() then
        Notify("🎉 Claim hive thành công!")
        return true
    else
        Notify("❌ Không thể claim hive sau " .. maxAttempts .. " lần thử!")
        return false
    end
end

-- ============================================
-- MAIN EXECUTION
-- ============================================
Notify("=== Auto Kaitun Starter v1.1 ===")
Notify("Đang chờ game load đầy đủ...")

-- Chờ character load
repeat task.wait(1) until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

-- Chờ Honeycombs load
repeat task.wait(1) until Workspace:FindFirstChild("Honeycombs") and #Workspace.Honeycombs:GetChildren() > 0

task.wait(3)
Notify("Game đã load xong! Bắt đầu auto...")

-- Xóa tường chắn gate
pcall(function()
    for _, gate in pairs(Workspace.Gates:GetChildren()) do
        for _, part in pairs(gate:GetChildren()) do
            pcall(function() part.CanCollide = false end)
        end
    end
end)

-- Xóa invisible walls
pcall(function()
    for _, v in pairs(Workspace["Invisible Walls"]:GetChildren()) do v:Destroy() end
end)

-- Xóa territories
pcall(function()
    for _, v in pairs(Workspace.Territories:GetChildren()) do v:Destroy() end
end)

-- ========== Bước 0: Auto Claim Hive ==========
Notify("📋 Bước 0: Kiểm tra & Claim Hive...")
local hiveOk = AutoClaimHive()

if not hiveOk then
    Notify("⚠️ Không claim được hive! Script sẽ vẫn thử tiếp...")
    task.wait(3)
end

-- TP về hive sau khi claim
if GetPlayerHive() then
    TpToHive()
    task.wait(1)
end

-- ========== Bước 1: Auto mua Accessories ==========
Notify("📋 Bước 1: Auto Mua Accessories...")
task.spawn(function()
    pcall(AutoBuyAccessories)
end)

task.wait(3)

-- ========== Bước 2: Auto mua Hive Slot + đặt ong ==========
Notify("📋 Bước 2: Auto Đặt Ong đến " .. TARGET_BEE_COUNT .. " con...")
task.spawn(function()
    pcall(AutoBuyHiveSlotsAndPlaceBees)
end)

Notify("✅ Script đang chạy... Kiểm tra console để xem tiến trình.")
