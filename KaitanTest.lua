--[[
    ============================================
    RESTAURANT AUTOMATION SYSTEM
    ============================================
    Scripts:
    1. FORCE CUSTOMER - Spawn & manage customers
    2. INSTANT COOK - Cook food instantly
    3. INSTANT EAT - Customers eat instantly
    4. INSTANT MONEY PAY - Process payments instantly
    ============================================
]]

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- ========== CONFIG ==========
local CONFIG = {
    -- Force Customer
    SPAWN_INTERVAL = 1.5,
    MAX_CUSTOMERS_PER_RESTAURANT = 50,
    EATING_TIME = 3,
    WALK_SPEED = 16,
    SEAT_REACH_DISTANCE = 5,
    TIP_MIN = 5,
    TIP_MAX = 25,
    FORCE_ENABLED = true,
    NPC_CLEANUP_DELAY = 2,
    PATHFIND_TIMEOUT = 15,
    RESPAWN_AFTER_LEAVE = true,
    
    -- Instant Cook
    COOK_ENABLED = true,
    COOK_SPEED_MULTIPLIER = 10,
    
    -- Instant Eat
    EAT_ENABLED = true,
    EAT_DURATION = 1,
    
    -- Instant Money Pay
    PAY_ENABLED = true,
    PAY_SPEED_MULTIPLIER = 5,
    
    CUSTOMER_COLORS = {
        BrickColor.new("Bright red"),
        BrickColor.new("Bright blue"),
        BrickColor.new("Bright green"),
        BrickColor.new("Bright yellow"),
        BrickColor.new("Bright orange"),
        BrickColor.new("Bright violet"),
        BrickColor.new("Hot pink"),
        BrickColor.new("Cyan"),
        BrickColor.new("Lime green"),
        BrickColor.new("Deep orange"),
    },
}

-- ========== REFERENCES ==========
local ThingsFolder = Workspace:FindFirstChild("__THINGS")
local RestaurantsFolder = ThingsFolder and ThingsFolder:FindFirstChild("Restaurants")
local SpotsFolder = ThingsFolder and ThingsFolder:FindFirstChild("Spots")
local DebrisFolder = Workspace:FindFirstChild("__DEBRIS")
local NPCTemplate = ReplicatedStorage:FindFirstChild("Assets") 
    and ReplicatedStorage.Assets:FindFirstChild("NPCs")
    and ReplicatedStorage.Assets.NPCs:FindFirstChild("ShopNPC")

-- ========== REMOTE EVENTS ==========
local ForceCustomerRemote = Instance.new("RemoteEvent")
ForceCustomerRemote.Name = "ForceCustomerToggle"
ForceCustomerRemote.Parent = ReplicatedStorage

local InstantCookRemote = Instance.new("RemoteEvent")
InstantCookRemote.Name = "InstantCookToggle"
InstantCookRemote.Parent = ReplicatedStorage

local InstantEatRemote = Instance.new("RemoteEvent")
InstantEatRemote.Name = "InstantEatToggle"
InstantEatRemote.Parent = ReplicatedStorage

local InstantPayRemote = Instance.new("RemoteEvent")
InstantPayRemote.Name = "InstantPayToggle"
InstantPayRemote.Parent = ReplicatedStorage

local StatusRemote = Instance.new("RemoteEvent")
StatusRemote.Name = "SystemStatusUpdate"
StatusRemote.Parent = ReplicatedStorage

-- ========== STATE ==========
local activeCustomers = {}
local occupiedSeats = {}
local restaurantData = {}
local customerCount = {}
local cookingItems = {}
local eatingCustomers = {}
local payingCustomers = {}

-- ========== UTILITY FUNCTIONS ==========

local function scanRestaurantSeats(restaurant)
    local chairs = {}
    local tables = {}
    
    local entities = restaurant:FindFirstChild("Entities")
    if not entities then return chairs, tables end
    
    for _, entity in ipairs(entities:GetChildren()) do
        if entity:IsA("Model") then
            local name = entity.Name:lower()
            if name:find("chair") or name:find("stool") or name:find("seat") or name:find("bench") then
                table.insert(chairs, entity)
            elseif name:find("table") or name:find("desk") then
                table.insert(tables, entity)
            end
        end
    end
    
    return chairs, tables
end

local function getSeatPosition(chairModel)
    if chairModel.PrimaryPart then
        return chairModel.PrimaryPart.Position + Vector3.new(0, 2, 0)
    end
    
    for _, part in ipairs(chairModel:GetDescendants()) do
        if part:IsA("BasePart") then
            return part.Position + Vector3.new(0, 2, 0)
        end
    end
    
    return nil
end

local function getSeatCFrame(chairModel, allTables)
    local seatPos = getSeatPosition(chairModel)
    if not seatPos then return nil end
    
    local nearestTable = nil
    local nearestDist = math.huge
    
    for _, tbl in ipairs(allTables) do
        local tblPos = nil
        if tbl.PrimaryPart then
            tblPos = tbl.PrimaryPart.Position
        else
            for _, p in ipairs(tbl:GetDescendants()) do
                if p:IsA("BasePart") then
                    tblPos = p.Position
                    break
                end
            end
        end
        
        if tblPos then
            local dist = (tblPos - seatPos).Magnitude
            if dist < nearestDist and dist < 15 then
                nearestDist = dist
                nearestTable = tblPos
            end
        end
    end
    
    if nearestTable then
        return CFrame.new(seatPos, Vector3.new(nearestTable.X, seatPos.Y, nearestTable.Z))
    end
    
    return CFrame.new(seatPos)
end

local function createCustomerNPC(spawnPosition)
    local npc = nil
    
    if NPCTemplate then
        npc = NPCTemplate:Clone()
    else
        npc = Instance.new("Model")
        npc.Name = "Customer"
        
        local humanoidRootPart = Instance.new("Part")
        humanoidRootPart.Name = "HumanoidRootPart"
        humanoidRootPart.Size = Vector3.new(2, 2, 1)
        humanoidRootPart.Anchored = false
        humanoidRootPart.CanCollide = false
        humanoidRootPart.Transparency = 1
        humanoidRootPart.Parent = npc
        
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Shape = Enum.PartType.Ball
        head.Size = Vector3.new(1.2, 1.2, 1.2)
        head.BrickColor = BrickColor.new("Bright yellow")
        head.Material = Enum.Material.SmoothPlastic
        head.Parent = npc
        
        local face = Instance.new("Decal")
        face.Name = "face"
        face.Texture = "rbxasset://textures/face.png"
        face.Face = Enum.NormalId.Front
        face.Parent = head
        
        local torso = Instance.new("Part")
        torso.Name = "Torso"
        torso.Size = Vector3.new(2, 2, 1)
        torso.Material = Enum.Material.SmoothPlastic
        torso.BrickColor = CONFIG.CUSTOMER_COLORS[math.random(#CONFIG.CUSTOMER_COLORS)]
        torso.Parent = npc
        
        local leftLeg = Instance.new("Part")
        leftLeg.Name = "Left Leg"
        leftLeg.Size = Vector3.new(1, 2, 1)
        leftLeg.BrickColor = BrickColor.new("Dark blue")
        leftLeg.Material = Enum.Material.SmoothPlastic
        leftLeg.Parent = npc
        
        local rightLeg = Instance.new("Part")
        rightLeg.Name = "Right Leg"
        rightLeg.Size = Vector3.new(1, 2, 1)
        rightLeg.BrickColor = BrickColor.new("Dark blue")
        rightLeg.Material = Enum.Material.SmoothPlastic
        rightLeg.Parent = npc
        
        local leftArm = Instance.new("Part")
        leftArm.Name = "Left Arm"
        leftArm.Size = Vector3.new(1, 2, 1)
        leftArm.BrickColor = BrickColor.new("Bright yellow")
        leftArm.Material = Enum.Material.SmoothPlastic
        leftArm.Parent = npc
        
        local rightArm = Instance.new("Part")
        rightArm.Name = "Right Arm"
        rightArm.Size = Vector3.new(1, 2, 1)
        rightArm.BrickColor = BrickColor.new("Bright yellow")
        rightArm.Material = Enum.Material.SmoothPlastic
        rightArm.Parent = npc
        
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = npc
        
        npc.PrimaryPart = humanoidRootPart
        
        local neck = Instance.new("Motor6D")
        neck.Name = "Neck"
        neck.Part0 = torso
        neck.Part1 = head
        neck.C0 = CFrame.new(0, 1, 0)
        neck.C1 = CFrame.new(0, -0.6, 0)
        neck.Parent = torso
        
        local rootJoint = Instance.new("Motor6D")
        rootJoint.Name = "RootJoint"
        rootJoint.Part0 = humanoidRootPart
        rootJoint.Part1 = torso
        rootJoint.Parent = humanoidRootPart
        
        local leftHip = Instance.new("Motor6D")
        leftHip.Name = "Left Hip"
        leftHip.Part0 = torso
        leftHip.Part1 = leftLeg
        leftHip.C0 = CFrame.new(-0.5, -1, 0)
        leftHip.C1 = CFrame.new(0, 1, 0)
        leftHip.Parent = torso
        
        local rightHip = Instance.new("Motor6D")
        rightHip.Name = "Right Hip"
        rightHip.Part0 = torso
        rightHip.Part1 = rightLeg
        rightHip.C0 = CFrame.new(0.5, -1, 0)
        rightHip.C1 = CFrame.new(0, 1, 0)
        rightHip.Parent = torso
        
        local leftShoulder = Instance.new("Motor6D")
        leftShoulder.Name = "Left Shoulder"
        leftShoulder.Part0 = torso
        leftShoulder.Part1 = leftArm
        leftShoulder.C0 = CFrame.new(-1.5, 0.5, 0)
        leftShoulder.C1 = CFrame.new(0, 0.5, 0)
        leftShoulder.Parent = torso
        
        local rightShoulder = Instance.new("Motor6D")
        rightShoulder.Name = "Right Shoulder"
        rightShoulder.Part0 = torso
        rightShoulder.Part1 = rightArm
        rightShoulder.C0 = CFrame.new(1.5, 0.5, 0)
        rightShoulder.C1 = CFrame.new(0, 0.5, 0)
        rightShoulder.Parent = torso
    end
    
    npc.Name = "Customer_" .. tostring(math.random(10000, 99999))
    
    if npc.PrimaryPart then
        npc:PivotTo(CFrame.new(spawnPosition))
    end
    
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = CONFIG.WALK_SPEED
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    
    return npc
end

local function createStatusBillboard(npc, text, color)
    local head = npc:FindFirstChild("Head")
    if not head then return end
    
    local oldBB = head:FindFirstChild("StatusBillboard")
    if oldBB then oldBB:Destroy() end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "StatusBillboard"
    billboard.Size = UDim2.new(4, 0, 1.5, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.3, 0)
    corner.Parent = bg
    
    local label = Instance.new("TextLabel")
    label.Name = "StatusText"
    label.Size = UDim2.new(1, -8, 1, -4)
    label.Position = UDim2.new(0, 4, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = bg
    
    return billboard
end

local function updateStatusBillboard(npc, text, color)
    local head = npc:FindFirstChild("Head")
    if not head then return end
    
    local billboard = head:FindFirstChild("StatusBillboard")
    if billboard then
        local bg = billboard:FindFirstChildOfClass("Frame")
        if bg then
            local label = bg:FindFirstChild("StatusText")
            if label then
                label.Text = text
                if color then label.TextColor3 = color end
            end
        end
    else
        createStatusBillboard(npc, text, color)
    end
end

local function moveNPCToPosition(npc, targetPosition)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    local rootPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
    
    if not humanoid or not rootPart then return false end
    
    local success, errorMsg = pcall(function()
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentCanClimb = false,
        })
        
        path:ComputeAsync(rootPart.Position, targetPosition)
        
        if path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            for i, waypoint in ipairs(waypoints) do
                if not npc.Parent then return end
                humanoid:MoveTo(waypoint.Position)
                
                local reached = humanoid.MoveToFinished:Wait()
                if not reached then break end
            end
        else
            humanoid:MoveTo(targetPosition)
            humanoid.MoveToFinished:Wait()
        end
    end)
    
    if not success then
        pcall(function()
            humanoid:MoveTo(targetPosition)
            humanoid.MoveToFinished:Wait()
        end)
    end
    
    if rootPart and rootPart.Parent then
        local dist = (rootPart.Position - targetPosition).Magnitude
        return dist < CONFIG.SEAT_REACH_DISTANCE
    end
    
    return false
end

local function sitNPCAtChair(npc, chairModel, allTables)
    local seatCF = getSeatCFrame(chairModel, allTables)
    if not seatCF then return false end
    
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
    end
    
    if npc.PrimaryPart then
        npc:PivotTo(seatCF)
    end
    
    for _, part in ipairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
    
    if humanoid then
        humanoid.Sit = true
    end
    
    return true
end

local function unanchorNPC(npc)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    
    for _, part in ipairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end
    
    if humanoid then
        humanoid.Sit = false
        humanoid.WalkSpeed = CONFIG.WALK_SPEED
    end
end

local function getSpawnPosition(restaurant)
    local tiles = restaurant:FindFirstChild("Tiles")
    if tiles then
        local front = tiles:FindFirstChild("Front")
        if front and front.PrimaryPart then
            return front.PrimaryPart.Position + Vector3.new(0, 3, 8)
        end
    end
    
    local primaryPart = restaurant:FindFirstChild("PrimaryPart")
    if primaryPart then
        return primaryPart.Position + Vector3.new(0, 5, 20)
    end
    
    return Vector3.new(0, 10, 0)
end

local function getLeavePosition(restaurant)
    local spawnPos = getSpawnPosition(restaurant)
    return spawnPos + Vector3.new(math.random(-30, 30), 0, 30)
end

-- ========== FORCE CUSTOMER LOGIC ==========

local function handleCustomerLifecycle(npc, chairModel, restaurant, data)
    local allTables = data.tables
    local customerData = {
        npc = npc,
        chair = chairModel,
        restaurant = restaurant,
        state = "walking",
    }
    activeCustomers[npc] = customerData
    
    createStatusBillboard(npc, "🚶 Đang đi...", Color3.fromRGB(150, 200, 255))
    
    local seatPos = getSeatPosition(chairModel)
    if seatPos then
        local reached = moveNPCToPosition(npc, seatPos)
        if not npc.Parent then return end
        if not reached then
            if npc.PrimaryPart then
                npc:PivotTo(CFrame.new(seatPos))
            end
        end
    end
    
    if not npc.Parent then return end
    
    customerData.state = "sitting"
    sitNPCAtChair(npc, chairModel, allTables)
    updateStatusBillboard(npc, "🪑 Đã ngồi", Color3.fromRGB(100, 255, 100))
    task.wait(1)
    
    if not npc.Parent then return end
    
    customerData.state = "waiting_order"
    local menuItems = {"🍔", "🍕", "🍝", "🥗", "🥩", "🍲", "🍣", "🍜", "🥪", "🍰"}
    local orderIcon = menuItems[math.random(#menuItems)]
    updateStatusBillboard(npc, orderIcon .. " Chờ order...", Color3.fromRGB(255, 200, 50))
    task.wait(math.random(2, 4))
    
    if not npc.Parent then return end
    
    customerData.state = "waiting_food"
    updateStatusBillboard(npc, orderIcon .. " Chờ đồ ăn...", Color3.fromRGB(255, 165, 0))
    
    -- INSTANT COOK: Nếu bật thì nấu nhanh
    if CONFIG.COOK_ENABLED then
        task.wait(1 / CONFIG.COOK_SPEED_MULTIPLIER)
    else
        task.wait(math.random(4, 8))
    end
    
    if not npc.Parent then return end
    
    customerData.state = "eating"
    eatingCustomers[npc] = true
    updateStatusBillboard(npc, orderIcon .. " Đang ăn~ 😋", Color3.fromRGB(100, 255, 100))
    
    -- INSTANT EAT: Nếu bật thì ăn nhanh
    if CONFIG.EAT_ENABLED then
        task.wait(CONFIG.EAT_DURATION)
    else
        task.wait(CONFIG.EATING_TIME)
    end
    
    eatingCustomers[npc] = nil
    
    if not npc.Parent then return end
    
    customerData.state = "paying"
    payingCustomers[npc] = true
    local tip = math.random(CONFIG.TIP_MIN, CONFIG.TIP_MAX)
    updateStatusBillboard(npc, "💰 +$" .. tostring(tip), Color3.fromRGB(255, 215, 0))
    
    -- INSTANT PAY: Nếu bật thì trả tiền nhanh
    if CONFIG.PAY_ENABLED then
        task.wait(0.5 / CONFIG.PAY_SPEED_MULTIPLIER)
    else
        task.wait(2)
    end
    
    payingCustomers[npc] = nil
    
    if not npc.Parent then return end
    
    customerData.state = "leaving"
    updateStatusBillboard(npc, "👋 Tạm biệt!", Color3.fromRGB(200, 200, 200))
    
    unanchorNPC(npc)
    occupiedSeats[chairModel] = nil
    
    local leavePos = getLeavePosition(restaurant)
    moveNPCToPosition(npc, leavePos)
    
    task.wait(CONFIG.NPC_CLEANUP_DELAY)
    
    activeCustomers[npc] = nil
    customerCount[restaurant.Name] = math.max(0, (customerCount[restaurant.Name] or 1) - 1)
    
    if npc.Parent then
        npc:Destroy()
    end
end

local function forceCustomerToChair(chairModel, restaurant, data)
    if occupiedSeats[chairModel] then
        return false
    end
    
    local count = customerCount[restaurant.Name] or 0
    if count >= CONFIG.MAX_CUSTOMERS_PER_RESTAURANT then
        return false
    end
    
    occupiedSeats[chairModel] = true
    customerCount[restaurant.Name] = count + 1
    
    local spawnPos = getSpawnPosition(restaurant)
    local npc = createCustomerNPC(spawnPos)
    
    if not npc then
        occupiedSeats[chairModel] = nil
        customerCount[restaurant.Name] = count
        return false
    end
    
    local parentFolder = DebrisFolder or Workspace
    npc.Parent = parentFolder
    
    occupiedSeats[chairModel] = npc
    
    task.spawn(function()
        handleCustomerLifecycle(npc, chairModel, restaurant, data)
        
        if CONFIG.RESPAWN_AFTER_LEAVE and CONFIG.FORCE_ENABLED then
            task.wait(CONFIG.SPAWN_INTERVAL)
            forceCustomerToChair(chairModel, restaurant, data)
        end
    end)
    
    return true
end

local function scanAllRestaurants()
    restaurantData = {}
    
    if not RestaurantsFolder then
        warn("[System] Không tìm thấy folder Restaurants!")
        return
    end
    
    for _, restaurant in ipairs(RestaurantsFolder:GetChildren()) do
        if restaurant:IsA("Model") then
            local chairs, tables = scanRestaurantSeats(restaurant)
            restaurantData[restaurant] = {
                chairs = chairs,
                tables = tables,
                name = restaurant.Name,
            }
            customerCount[restaurant.Name] = customerCount[restaurant.Name] or 0
            
            print(string.format(
                "[ForceCustomer] %s: %d ghế, %d bàn",
                restaurant.Name, #chairs, #tables
            ))
        end
    end
end

local function forceAllCustomers()
    print("[ForceCustomer] ===== BẮT ĐẦU FORCE CUSTOMERS =====")
    
    local totalForced = 0
    
    for restaurant, data in pairs(restaurantData) do
        for _, chair in ipairs(data.chairs) do
            if not occupiedSeats[chair] then
                local success = forceCustomerToChair(chair, restaurant, data)
                if success then
                    totalForced = totalForced + 1
                end
                task.wait(CONFIG.SPAWN_INTERVAL)
            end
        end
    end
    
    print(string.format("[ForceCustomer] Đã force %d customers!", totalForced))
end

local function stopAllCustomers()
    print("[ForceCustomer] ===== DỪNG TẤT CẢ CUSTOMERS =====")
    
    CONFIG.FORCE_ENABLED = false
    CONFIG.RESPAWN_AFTER_LEAVE = false
    
    for npc, data in pairs(activeCustomers) do
        if npc and npc.Parent then
            npc:Destroy()
        end
    end
    
    activeCustomers = {}
    occupiedSeats = {}
    
    for name, _ in pairs(customerCount) do
        customerCount[name] = 0
    end
    
    print("[ForceCustomer] Đã dừng tất cả customers!")
end

-- ========== INSTANT COOK LOGIC ==========

local function enableInstantCook()
    CONFIG.COOK_ENABLED = true
    print("[InstantCook] ✅ BẬT - Nấu ăn x" .. CONFIG.COOK_SPEED_MULTIPLIER .. " nhanh hơn")
end

local function disableInstantCook()
    CONFIG.COOK_ENABLED = false
    print("[InstantCook] ❌ TẮT - Nấu ăn tốc độ bình thường")
end

-- ========== INSTANT EAT LOGIC ==========

local function enableInstantEat()
    CONFIG.EAT_ENABLED = true
    print("[InstantEat] ✅ BẬT - Ăn trong " .. CONFIG.EAT_DURATION .. " giây")
end

local function disableInstantEat()
    CONFIG.EAT_ENABLED = false
    print("[InstantEat] ❌ TẮT - Ăn tốc độ bình thường")
end

-- ========== INSTANT MONEY PAY LOGIC ==========

local function enableInstantPay()
    CONFIG.PAY_ENABLED = true
    print("[InstantPay] ✅ BẬT - Trả tiền x" .. CONFIG.PAY_SPEED_MULTIPLIER .. " nhanh hơn")
end

local function disableInstantPay()
    CONFIG.PAY_ENABLED = false
    print("[InstantPay] ❌ TẮT - Trả tiền tốc độ bình thường")
end

-- ========== CHAT COMMANDS ==========

local function onPlayerChatted(player, message)
    local msg = message:lower()
    
    -- Force Customer Commands
    if msg == "/force" or msg == "/forcecustomer" or msg == "/fc" then
        CONFIG.FORCE_ENABLED = true
        CONFIG.RESPAWN_AFTER_LEAVE = true
        scanAllRestaurants()
        forceAllCustomers()
        StatusRemote:FireClient(player, "enabled", "Force Customer: BẬT ✅")
        
    elseif msg == "/stopforce" or msg == "/sf" or msg == "/stop" then
        stopAllCustomers()
        StatusRemote:FireClient(player, "disabled", "Force Customer: TẮT ❌")
        
    elseif msg == "/rescan" then
        scanAllRestaurants()
        local totalChairs = 0
        local totalTables = 0
        for _, data in pairs(restaurantData) do
            totalChairs = totalChairs + #data.chairs
            totalTables = totalTables + #data.tables
        end
        StatusRemote:FireClient(player, "info", 
            string.format("Rescan: %d ghế, %d bàn", totalChairs, totalTables))
        
    elseif msg == "/customercount" or msg == "/cc" then
        local total = 0
        for _, count in pairs(customerCount) do
            total = total + count
        end
        StatusRemote:FireClient(player, "info",
            string.format("Customers: %d", total))
    
    -- Instant Cook Commands
    elseif msg == "/cook" or msg == "/instantcook" or msg == "/ic" then
        enableInstantCook()
        StatusRemote:FireClient(player, "enabled", "Instant Cook: BẬT ✅")
        
    elseif msg == "/stopcook" or msg == "/sc" then
        disableInstantCook()
        StatusRemote:FireClient(player, "disabled", "Instant Cook: TẮT ❌")
    
    -- Instant Eat Commands
    elseif msg == "/eat" or msg == "/instanteat" or msg == "/ie" then
        enableInstantEat()
        StatusRemote:FireClient(player, "enabled", "Instant Eat: BẬT ✅")
        
    elseif msg == "/stopeat" or msg == "/se" then
        disableInstantEat()
        StatusRemote:FireClient(player, "disabled", "Instant Eat: TẮT ❌")
    
    -- Instant Pay Commands
    elseif msg == "/pay" or msg == "/instantpay" or msg == "/ip" then
        enableInstantPay()
        StatusRemote:FireClient(player, "enabled", "Instant Pay: BẬT ✅")
        
    elseif msg == "/stoppay" or msg == "/sp" then
        disableInstantPay()
        StatusRemote:FireClient(player, "disabled", "Instant Pay: TẮT ❌")
    
    -- All Systems
    elseif msg == "/all" or msg == "/enableall" then
        CONFIG.FORCE_ENABLED = true
        CONFIG.RESPAWN_AFTER_LEAVE = true
        CONFIG.COOK_ENABLED = true
        CONFIG.EAT_ENABLED = true
        CONFIG.PAY_ENABLED = true
        scanAllRestaurants()
        forceAllCustomers()
        StatusRemote:FireClient(player, "enabled", "TẤT CẢ HỆ THỐNG: BẬT ✅")
        
    elseif msg == "/stopall" or msg == "/disableall" then
        stopAllCustomers()
        CONFIG.COOK_ENABLED = false
        CONFIG.EAT_ENABLED = false
        CONFIG.PAY_ENABLED = false
        StatusRemote:FireClient(player, "disabled", "TẤT CẢ HỆ THỐNG: TẮT ❌")
    
    -- Config Commands
    elseif msg:find("/setspawn") then
        local num = tonumber(msg:match("/setspawn%s+(%S+)"))
        if num and num > 0 then
            CONFIG.SPAWN_INTERVAL = num
            StatusRemote:FireClient(player, "info",
                string.format("Spawn interval: %.1fs", num))
        end
        
    elseif msg:find("/setmax") then
        local num = tonumber(msg:match("/setmax%s+(%S+)"))
        if num and num > 0 then
            CONFIG.MAX_CUSTOMERS_PER_RESTAURANT = math.floor(num)
            StatusRemote:FireClient(player, "info",
                string.format("Max customers: %d", math.floor(num)))
        end
        
    elseif msg:find("/setcookspeed") then
        local num = tonumber(msg:match("/setcookspeed%s+(%S+)"))
        if num and num > 0 then
            CONFIG.COOK_SPEED_MULTIPLIER = num
            StatusRemote:FireClient(player, "info",
                string.format("Cook speed: x%.1f", num))
        end
        
    elseif msg:find("/seteattime") then
        local num = tonumber(msg:match("/seteattime%s+(%S+)"))
        if num and num > 0 then
            CONFIG.EAT_DURATION = num
            StatusRemote:FireClient(player, "info",
                string.format("Eat time: %.1fs", num))
        end
        
    elseif msg:find("/setpayspeed") then
        local num = tonumber(msg:match("/setpayspeed%s+(%S+)"))
        if num and num > 0 then
            CONFIG.PAY_SPEED_MULTIPLIER = num
            StatusRemote:FireClient(player, "info",
                string.format("Pay speed: x%.1f", num))
        end
        
    elseif msg == "/help" or msg == "/h" then
        StatusRemote:FireClient(player, "help", table.concat({
            "=== RESTAURANT AUTOMATION COMMANDS ===",
            "",
            "FORCE CUSTOMER:",
            "/force, /fc - Bật force customer",
            "/stop, /sf - Tắt force customer",
            "/rescan - Scan lại restaurants",
            "/cc - Đếm customers",
            "",
            "INSTANT COOK:",
            "/cook, /ic - Bật instant cook",
            "/stopcook, /sc - Tắt instant cook",
            "",
            "INSTANT EAT:",
            "/eat, /ie - Bật instant eat",
            "/stopeat, /se - Tắt instant eat",
            "",
            "INSTANT PAY:",
            "/pay, /ip - Bật instant pay",
            "/stoppay, /sp - Tắt instant pay",
            "",
            "ALL SYSTEMS:",
            "/all - Bật tất cả",
            "/stopall - Tắt tất cả",
            "",
            "CONFIG:",
            "/setspawn [số] - Set spawn interval",
            "/setmax [số] - Set max customers",
            "/setcookspeed [số] - Set cook speed",
            "/seteattime [số] - Set eat time",
            "/setpayspeed [số] - Set pay speed",
        }, "\n"))
    end
end

-- ========== REMOTE EVENT HANDLERS ==========

ForceCustomerRemote.OnServerEvent:Connect(function(player, action)
    if action == "toggle" then
        if CONFIG.FORCE_ENABLED then
            stopAllCustomers()
            StatusRemote:FireClient(player, "disabled", "Force Customer: TẮT ❌")
        else
            CONFIG.FORCE_ENABLED = true
            CONFIG.RESPAWN_AFTER_LEAVE = true
            scanAllRestaurants()
            forceAllCustomers()
            StatusRemote:FireClient(player, "enabled", "Force Customer: BẬT ✅")
        end
    end
end)

InstantCookRemote.OnServerEvent:Connect(function(player, action)
    if action == "toggle" then
        if CONFIG.COOK_ENABLED then
            disableInstantCook()
            StatusRemote:FireClient(player, "disabled", "Instant Cook: TẮT ❌")
        else
            enableInstantCook()
            StatusRemote:FireClient(player, "enabled", "Instant Cook: BẬT ✅")
        end
    end
end)

InstantEatRemote.OnServerEvent:Connect(function(player, action)
    if action == "toggle" then
        if CONFIG.EAT_ENABLED then
            disableInstantEat()
            StatusRemote:FireClient(player, "disabled", "Instant Eat: TẮT ❌")
        else
            enableInstantEat()
            StatusRemote:FireClient(player, "enabled", "Instant Eat: BẬT ✅")
        end
    end
end)

InstantPayRemote.OnServerEvent:Connect(function(player, action)
    if action == "toggle" then
        if CONFIG.PAY_ENABLED then
            disableInstantPay()
            StatusRemote:FireClient(player, "disabled", "Instant Pay: TẮT ❌")
        else
            enableInstantPay()
            StatusRemote:FireClient(player, "enabled", "Instant Pay: BẬT ✅")
        end
    end
end)

-- ========== PLAYER CONNECTIONS ==========

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end

-- ========== INITIALIZATION ==========

print("[System] ============================================")
print("[System]   RESTAURANT AUTOMATION SYSTEM")
print("[System] ============================================")
print("[System] Đang khởi động...")

task.wait(2)

scanAllRestaurants()

local totalChairs = 0
local totalTables = 0
for _, data in pairs(restaurantData) do
    totalChairs = totalChairs + #data.chairs
    totalTables = totalTables + #data.tables
end

print(string.format("[System] Scan: %d ghế, %d bàn", totalChairs, totalTables))
print("[System] Force Customer: " .. (CONFIG.FORCE_ENABLED and "BẬT ✅" or "TẮT ❌"))
print("[System] Instant Cook: " .. (CONFIG.COOK_ENABLED and "BẬT ✅" or "TẮT ❌"))
print("[System] Instant Eat: " .. (CONFIG.EAT_ENABLED and "BẬT ✅" or "TẮT ❌"))
print("[System] Instant Pay: " .. (CONFIG.PAY_ENABLED and "BẬT ✅" or "TẮT ❌"))
print("[System] Chat /help để xem commands")
print("[System] ============================================")

if CONFIG.FORCE_ENABLED then
    task.wait(1)
    forceAllCustomers()
end
