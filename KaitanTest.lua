--[[
    ============================================
    FORCE CUSTOMER - Run A Restaurant
    ============================================
    Script: ServerScriptService (Script)
    
    - Scan tất cả restaurant tìm Chair/Table
    - Force customer NPC vào tất cả ghế trống
    - Không phân biệt loại ghế/bàn
    - Tự động spawn, pathfind, ngồi, ăn, rời đi
    ============================================
]]

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- ========== CONFIG ==========
local CONFIG = {
    SPAWN_INTERVAL = 1.5,          -- Thời gian giữa mỗi lần spawn (giây)
    MAX_CUSTOMERS_PER_RESTAURANT = 50, -- Max customer mỗi restaurant
    EATING_TIME = 12,              -- Thời gian ăn (giây)
    WALK_SPEED = 16,               -- Tốc độ đi
    SEAT_REACH_DISTANCE = 5,       -- Khoảng cách tới ghế = đã tới
    TIP_MIN = 5,                   -- Tip tối thiểu
    TIP_MAX = 25,                  -- Tip tối đa
    FORCE_ENABLED = true,          -- Bật force mặc định
    NPC_CLEANUP_DELAY = 2,         -- Delay trước khi xóa NPC sau khi rời
    PATHFIND_TIMEOUT = 15,         -- Timeout pathfinding (giây)
    RESPAWN_AFTER_LEAVE = true,    -- Tự động spawn lại sau khi customer rời
    CUSTOMER_COLORS = {            -- Màu áo random cho NPC
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
local Workspace = game:GetService("Workspace")
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

local CustomerStatusRemote = Instance.new("RemoteEvent")
CustomerStatusRemote.Name = "CustomerStatusUpdate"
CustomerStatusRemote.Parent = ReplicatedStorage

-- ========== STATE ==========
local activeCustomers = {}       -- {[npcModel] = customerData}
local occupiedSeats = {}         -- {[seatPart] = npcModel}
local restaurantData = {}        -- {[restaurantModel] = {chairs = {}, tables = {}}}
local forceEnabledPlayers = {}   -- {[player] = true/false}
local customerCount = {}         -- {[restaurantName] = count}

-- ========== UTILITY FUNCTIONS ==========

-- Tìm tất cả Chair và Table trong 1 restaurant
local function scanRestaurantSeats(restaurant)
    local chairs = {}
    local tables = {}
    
    local entities = restaurant:FindFirstChild("Entities")
    if not entities then return chairs, tables end
    
    for _, entity in ipairs(entities:GetChildren()) do
        if entity:IsA("Model") then
            local name = entity.Name:lower()
            -- Check tên có chứa "chair" hoặc "stool" -> ghế
            if name:find("chair") or name:find("stool") or name:find("seat") or name:find("bench") then
                table.insert(chairs, entity)
            -- Check tên có chứa "table" -> bàn
            elseif name:find("table") or name:find("desk") then
                table.insert(tables, entity)
            end
        end
    end
    
    return chairs, tables
end

-- Lấy vị trí ngồi của một ghế (PrimaryPart hoặc first BasePart)
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

-- Lấy CFrame ngồi (hướng về phía bàn gần nhất)
local function getSeatCFrame(chairModel, allTables)
    local seatPos = getSeatPosition(chairModel)
    if not seatPos then return nil end
    
    -- Tìm bàn gần nhất để quay mặt về phía bàn
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
            if dist < nearestDist and dist < 15 then -- Bàn trong phạm vi 15 studs
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

-- Tạo NPC Customer
local function createCustomerNPC(spawnPosition)
    local npc = nil
    
    -- Thử clone từ template ShopNPC
    if NPCTemplate then
        npc = NPCTemplate:Clone()
    else
        -- Fallback: Tạo NPC đơn giản bằng rig cơ bản
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
        
        -- Build character joints
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
    
    -- Đặt tên
    npc.Name = "Customer_" .. tostring(math.random(10000, 99999))
    
    -- Set position
    if npc.PrimaryPart then
        npc:PivotTo(CFrame.new(spawnPosition))
    end
    
    -- Set humanoid
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = CONFIG.WALK_SPEED
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    
    return npc
end

-- Tạo BillboardGui hiển thị trạng thái trên đầu NPC
local function createStatusBillboard(npc, text, color)
    -- Xóa billboard cũ nếu có
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

-- Update billboard text
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

-- Pathfind NPC tới vị trí
local function moveNPCToPosition(npc, targetPosition)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    local rootPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
    
    if not humanoid or not rootPart then return false end
    
    -- Thử pathfinding trước
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
                if not npc.Parent then return end -- NPC đã bị xóa
                humanoid:MoveTo(waypoint.Position)
                
                local reached = humanoid.MoveToFinished:Wait()
                if not reached then break end
            end
        else
            -- Fallback: đi thẳng tới
            humanoid:MoveTo(targetPosition)
            humanoid.MoveToFinished:Wait()
        end
    end)
    
    if not success then
        -- Fallback nếu pathfinding lỗi: MoveTo trực tiếp
        pcall(function()
            humanoid:MoveTo(targetPosition)
            humanoid.MoveToFinished:Wait()
        end)
    end
    
    -- Check đã tới chưa
    if rootPart and rootPart.Parent then
        local dist = (rootPart.Position - targetPosition).Magnitude
        return dist < CONFIG.SEAT_REACH_DISTANCE
    end
    
    return false
end

-- Force NPC ngồi xuống ghế (teleport + anchor)
local function sitNPCAtChair(npc, chairModel, allTables)
    local seatCF = getSeatCFrame(chairModel, allTables)
    if not seatCF then return false end
    
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 0
    end
    
    -- Teleport NPC tới ghế
    if npc.PrimaryPart then
        npc:PivotTo(seatCF)
    end
    
    -- Anchor tất cả parts để NPC không rớt
    for _, part in ipairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
    
    -- Play sit animation nếu có Humanoid
    if humanoid then
        humanoid.Sit = true
    end
    
    return true
end

-- Unanchor NPC để đi lại
local function unanchorNPC(npc)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    
    for _, part in ipairs(npc:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Name == "HumanoidRootPart" then
                part.Anchored = false
            else
                part.Anchored = false
            end
        end
    end
    
    if humanoid then
        humanoid.Sit = false
        humanoid.WalkSpeed = CONFIG.WALK_SPEED
    end
end

-- ========== MAIN FORCE CUSTOMER LOGIC ==========

-- Scan tất cả restaurants và lưu data
local function scanAllRestaurants()
    restaurantData = {}
    
    if not RestaurantsFolder then
        warn("[ForceCustomer] Không tìm thấy folder Restaurants!")
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
                "[ForceCustomer] %s: Tìm thấy %d ghế, %d bàn",
                restaurant.Name, #chairs, #tables
            ))
        end
    end
end

-- Lấy vị trí spawn (trước cửa restaurant)
local function getSpawnPosition(restaurant)
    -- Thử tìm Front tile
    local tiles = restaurant:FindFirstChild("Tiles")
    if tiles then
        local front = tiles:FindFirstChild("Front")
        if front and front.PrimaryPart then
            return front.PrimaryPart.Position + Vector3.new(0, 3, 8)
        end
    end
    
    -- Fallback: dùng PrimaryPart của restaurant + offset
    local primaryPart = restaurant:FindFirstChild("PrimaryPart")
    if primaryPart then
        return primaryPart.Position + Vector3.new(0, 5, 20)
    end
    
    return Vector3.new(0, 10, 0)
end

-- Lấy vị trí rời đi (xa khỏi restaurant)
local function getLeavePosition(restaurant)
    local spawnPos = getSpawnPosition(restaurant)
    return spawnPos + Vector3.new(math.random(-30, 30), 0, 30)
end

-- Xử lý 1 customer lifecycle
local function handleCustomerLifecycle(npc, chairModel, restaurant, data)
    local allTables = data.tables
    local customerData = {
        npc = npc,
        chair = chairModel,
        restaurant = restaurant,
        state = "walking",
    }
    activeCustomers[npc] = customerData
    
    -- PHASE 1: Đi tới ghế
    customerData.state = "walking"
    createStatusBillboard(npc, "🚶 Đang đi...", Color3.fromRGB(150, 200, 255))
    
    local seatPos = getSeatPosition(chairModel)
    if seatPos then
        local reached = moveNPCToPosition(npc, seatPos)
        
        if not npc.Parent then return end -- NPC bị xóa
        
        -- Nếu không tới được, teleport thẳng
        if not reached then
            if npc.PrimaryPart then
                npc:PivotTo(CFrame.new(seatPos))
            end
        end
    end
    
    if not npc.Parent then return end
    
    -- PHASE 2: Ngồi xuống
    customerData.state = "sitting"
    sitNPCAtChair(npc, chairModel, allTables)
    updateStatusBillboard(npc, "🪑 Đã ngồi", Color3.fromRGB(100, 255, 100))
    task.wait(1)
    
    if not npc.Parent then return end
    
    -- PHASE 3: Chờ order
    customerData.state = "waiting_order"
    local menuItems = {"🍔", "🍕", "🍝", "🥗", "🥩", "🍲", "🍣", "🍜", "🥪", "🍰"}
    local orderIcon = menuItems[math.random(#menuItems)]
    updateStatusBillboard(npc, orderIcon .. " Đang chờ order...", Color3.fromRGB(255, 200, 50))
    task.wait(math.random(3, 6))
    
    if not npc.Parent then return end
    
    -- PHASE 4: Đã order, chờ đồ ăn
    customerData.state = "waiting_food"
    updateStatusBillboard(npc, orderIcon .. " Chờ đồ ăn...", Color3.fromRGB(255, 165, 0))
    task.wait(math.random(4, 8))
    
    if not npc.Parent then return end
    
    -- PHASE 5: Ăn
    customerData.state = "eating"
    updateStatusBillboard(npc, orderIcon .. " Đang ăn~ 😋", Color3.fromRGB(100, 255, 100))
    task.wait(CONFIG.EATING_TIME)
    
    if not npc.Parent then return end
    
    -- PHASE 6: Trả tiền
    customerData.state = "paying"
    local tip = math.random(CONFIG.TIP_MIN, CONFIG.TIP_MAX)
    updateStatusBillboard(npc, "💰 +$" .. tostring(tip), Color3.fromRGB(255, 215, 0))
    task.wait(2)
    
    if not npc.Parent then return end
    
    -- PHASE 7: Rời đi
    customerData.state = "leaving"
    updateStatusBillboard(npc, "👋 Tạm biệt!", Color3.fromRGB(200, 200, 200))
    
    -- Unanchor để đi
    unanchorNPC(npc)
    
    -- Giải phóng ghế
    occupiedSeats[chairModel] = nil
    
    -- Đi ra
    local leavePos = getLeavePosition(restaurant)
    moveNPCToPosition(npc, leavePos)
    
    task.wait(CONFIG.NPC_CLEANUP_DELAY)
    
    -- Cleanup
    activeCustomers[npc] = nil
    customerCount[restaurant.Name] = math.max(0, (customerCount[restaurant.Name] or 1) - 1)
    
    if npc.Parent then
        npc:Destroy()
    end
end

-- Force customer vào 1 ghế cụ thể
local function forceCustomerToChair(chairModel, restaurant, data)
    -- Check ghế đã có người chưa
    if occupiedSeats[chairModel] then
        return false
    end
    
    -- Check max customers
    local count = customerCount[restaurant.Name] or 0
    if count >= CONFIG.MAX_CUSTOMERS_PER_RESTAURANT then
        return false
    end
    
    -- Đánh dấu ghế đã chiếm
    occupiedSeats[chairModel] = true
    customerCount[restaurant.Name] = count + 1
    
    -- Spawn NPC
    local spawnPos = getSpawnPosition(restaurant)
    local npc = createCustomerNPC(spawnPos)
    
    if not npc then
        occupiedSeats[chairModel] = nil
        customerCount[restaurant.Name] = count
        return false
    end
    
    -- Đặt NPC vào game
    local parentFolder = DebrisFolder or Workspace
    npc.Parent = parentFolder
    
    -- Cập nhật ghế đang chiếm bởi NPC nào
    occupiedSeats[chairModel] = npc
    
    -- Chạy lifecycle trong thread riêng
    task.spawn(function()
        handleCustomerLifecycle(npc, chairModel, restaurant, data)
        
        -- Sau khi customer rời, nếu RESPAWN thì force lại
        if CONFIG.RESPAWN_AFTER_LEAVE and CONFIG.FORCE_ENABLED then
            task.wait(CONFIG.SPAWN_INTERVAL)
            forceCustomerToChair(chairModel, restaurant, data)
        end
    end)
    
    return true
end

-- ========== FORCE ALL CUSTOMERS ==========

-- Force customer vào TẤT CẢ ghế trống của TẤT CẢ restaurants
local function forceAllCustomers()
    print("[ForceCustomer] ===== BẮT ĐẦU FORCE TẤT CẢ CUSTOMERS =====")
    
    local totalForced = 0
    
    for restaurant, data in pairs(restaurantData) do
        for _, chair in ipairs(data.chairs) do
            if not occupiedSeats[chair] then
                local success = forceCustomerToChair(chair, restaurant, data)
                if success then
                    totalForced = totalForced + 1
                end
                -- Delay nhỏ giữa mỗi spawn để không lag
                task.wait(CONFIG.SPAWN_INTERVAL)
            end
        end
    end
    
    print(string.format("[ForceCustomer] Đã force %d customers!", totalForced))
end

-- Dừng tất cả customers
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

-- ========== PLAYER COMMANDS ==========

-- Xử lý chat commands
local function onPlayerChatted(player, message)
    local msg = message:lower()
    
    if msg == "/force" or msg == "/forcecustomer" or msg == "/fc" then
        CONFIG.FORCE_ENABLED = true
        CONFIG.RESPAWN_AFTER_LEAVE = true
        -- Re-scan và force
        scanAllRestaurants()
        forceAllCustomers()
        -- Thông báo cho player
        CustomerStatusRemote:FireClient(player, "enabled", "Force Customer: BẬT ✅")
        
    elseif msg == "/stopforce" or msg == "/sf" or msg == "/stop" then
        stopAllCustomers()
        CustomerStatusRemote:FireClient(player, "disabled", "Force Customer: TẮT ❌")
        
    elseif msg == "/rescan" then
        scanAllRestaurants()
        local totalChairs = 0
        local totalTables = 0
        for _, data in pairs(restaurantData) do
            totalChairs = totalChairs + #data.chairs
            totalTables = totalTables + #data.tables
        end
        CustomerStatusRemote:FireClient(player, "info", 
            string.format("Rescan: %d ghế, %d bàn", totalChairs, totalTables))
        
    elseif msg == "/customercount" or msg == "/cc" then
        local total = 0
        for _, count in pairs(customerCount) do
            total = total + count
        end
        CustomerStatusRemote:FireClient(player, "info",
            string.format("Customers hiện tại: %d", total))
            
    elseif msg:find("/setspawn") then
        -- /setspawn 0.5 -> set spawn interval = 0.5 giây
        local num = tonumber(msg:match("/setspawn%s+(%S+)"))
        if num and num > 0 then
            CONFIG.SPAWN_INTERVAL = num
            CustomerStatusRemote:FireClient(player, "info",
                string.format("Spawn interval: %.1f giây", num))
        end
        
    elseif msg:find("/setmax") then
        -- /setmax 30 -> set max customers = 30
        local num = tonumber(msg:match("/setmax%s+(%S+)"))
        if num and num > 0 then
            CONFIG.MAX_CUSTOMERS_PER_RESTAURANT = math.floor(num)
            CustomerStatusRemote:FireClient(player, "info",
                string.format("Max customers/restaurant: %d", math.floor(num)))
        end
        
    elseif msg:find("/seteat") then
        -- /seteat 5 -> set eating time = 5 giây
        local num = tonumber(msg:match("/seteat%s+(%S+)"))
        if num and num > 0 then
            CONFIG.EATING_TIME = num
            CustomerStatusRemote:FireClient(player, "info",
                string.format("Eating time: %.1f giây", num))
        end
        
    elseif msg == "/forcehelp" or msg == "/fh" then
        CustomerStatusRemote:FireClient(player, "help", table.concat({
            "=== FORCE CUSTOMER COMMANDS ===",
            "/force hoặc /fc - Bật force customer",
            "/stop hoặc /sf - Tắt force customer",
            "/rescan - Scan lại restaurants",
            "/cc - Đếm customers hiện tại",
            "/setspawn [số] - Set spawn interval",
            "/setmax [số] - Set max customers",
            "/seteat [số] - Set eating time",
            "/forcehelp - Hiện help",
        }, "\n"))
    end
end

-- ========== REMOTE EVENT HANDLER ==========
ForceCustomerRemote.OnServerEvent:Connect(function(player, action, ...)
    if action == "toggle" then
        if CONFIG.FORCE_ENABLED then
            stopAllCustomers()
            CustomerStatusRemote:FireClient(player, "disabled", "Force Customer: TẮT ❌")
        else
            CONFIG.FORCE_ENABLED = true
            CONFIG.RESPAWN_AFTER_LEAVE = true
            scanAllRestaurants()
            forceAllCustomers()
            CustomerStatusRemote:FireClient(player, "enabled", "Force Customer: BẬT ✅")
        end
        
    elseif action == "forceAll" then
        CONFIG.FORCE_ENABLED = true
        CONFIG.RESPAWN_AFTER_LEAVE = true
        scanAllRestaurants()
        forceAllCustomers()
        CustomerStatusRemote:FireClient(player, "enabled", "Force Customer: BẬT ✅")
        
    elseif action == "stopAll" then
        stopAllCustomers()
        CustomerStatusRemote:FireClient(player, "disabled", "Force Customer: TẮT ❌")
    end
end)

-- ========== PLAYER CONNECTIONS ==========
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end)

-- Kết nối cho players đã trong game
for _, player in ipairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        onPlayerChatted(player, message)
    end)
end

-- ========== INITIALIZATION ==========
print("[ForceCustomer] ============================================")
print("[ForceCustomer]   FORCE CUSTOMER SYSTEM - Run A Restaurant  ")
print("[ForceCustomer] ============================================")
print("[ForceCustomer] Đang scan restaurants...")

task.wait(2) -- Đợi game load

scanAllRestaurants()

local totalChairs = 0
local totalTables = 0
for _, data in pairs(restaurantData) do
    totalChairs = totalChairs + #data.chairs
    totalTables = totalTables + #data.tables
end

print(string.format("[ForceCustomer] Scan hoàn tất: %d ghế, %d bàn", totalChairs, totalTables))
print("[ForceCustomer] Chat /force để bật, /stop để tắt")
print("[ForceCustomer] Chat /forcehelp để xem tất cả commands")

-- Auto-force nếu config mặc định bật
if CONFIG.FORCE_ENABLED then
    task.wait(1)
    forceAllCustomers()
end
