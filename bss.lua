--[[
    BSS MACRO - FULL AUTOMATION SCRIPT
    Style: MCP Sever
    Features: Auto Farm, Auto Convert, Token Collect, Quest Auto,
              Dispenser Claim, Vicious Bee, Mondo Chick, Mob Kill,
              Auto Sprinkler, Field Boost, Ant Challenge, etc.
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================
-- WAIT FOR CHARACTER
-- ============================================================
local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ============================================================
-- FIELD POSITIONS (CFrame data for all BSS fields)
-- ============================================================
local FieldPositions = {
    ["Sunflower Field"] = CFrame.new(-173.5, 4, 78),
    ["Dandelion Field"] = CFrame.new(-249, 4, 78),
    ["Mushroom Field"] = CFrame.new(-121, 4, 78),
    ["Blue Flower Field"] = CFrame.new(-321, 4, 15),
    ["Clover Field"] = CFrame.new(-245, 20, -22),
    ["Spider Field"] = CFrame.new(-72, 20, -2),
    ["Strawberry Field"] = CFrame.new(-320, 20, -108),
    ["Bamboo Field"] = CFrame.new(-245, 20, -108),
    ["Pineapple Patch"] = CFrame.new(-170, 36, -135),
    ["Stump Field"] = CFrame.new(-170, 36, -65),
    ["Cactus Field"] = CFrame.new(-170, 68, -178),
    ["Pumpkin Patch"] = CFrame.new(-245, 68, -178),
    ["Pine Tree Forest"] = CFrame.new(-72, 68, -178),
    ["Rose Field"] = CFrame.new(-321, 68, -108),
    ["Mountain Top Field"] = CFrame.new(-170, 100, -178),
    ["Coconut Field"] = CFrame.new(-321, 100, -178),
    ["Pepper Patch"] = CFrame.new(-72, 100, -178),
}

-- ============================================================
-- IMPORTANT LOCATIONS
-- ============================================================
local Locations = {
    Hive = CFrame.new(-285, 12, 467),
    HoneyDispenser = CFrame.new(-269, 12, 413),
    TreatDispenser = CFrame.new(-269, 12, 420),
    BlueberryDispenser = CFrame.new(-340, 6, 150),
    StrawberryDispenser = CFrame.new(-105, 6, 150),
    RoyalJellyDispenser = CFrame.new(-269, 12, 427),
    GlueDispenser = CFrame.new(-170, 100, -100),
    BlackBear = CFrame.new(-218, 4, 163),
    BrownBear = CFrame.new(-218, 4, 130),
    PolarBear = CFrame.new(-170, 68, -100),
    ScienceBear = CFrame.new(-321, 36, -65),
    MotherBear = CFrame.new(-245, 36, -65),
    PandaBear = CFrame.new(-170, 36, -100),
    SpiritBear = CFrame.new(-72, 100, -100),
    BeeShop = CFrame.new(-269, 12, 440),
    AntChallenge = CFrame.new(-500, 4, 78),
    KingBeetleLair = CFrame.new(-72, 36, -135),
    TunnelBear = CFrame.new(-321, 20, -65),
    MondoChick = CFrame.new(-170, 100, -178),
    WindShrine = CFrame.new(-170, 68, -100),
    StickBug = CFrame.new(-170, 36, -178),
}

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    -- Farm
    AutoFarm = false,
    TargetField = "Sunflower Field",
    FarmSpeed = 60,
    FarmPattern = "Zigzag",
    AutoDig = true,
    
    -- Tokens
    CollectTokens = false,
    TokenRadius = 40,
    PriorityTokens = true,
    
    -- Convert
    AutoConvert = false,
    ConvertAt = 95,
    ConvertMethod = "Hive",
    
    -- Sprinkler
    AutoSprinkler = false,
    SprinklerInterval = 30,
    
    -- Dispensers
    AutoHoneyDispenser = false,
    AutoTreatDispenser = false,
    AutoBlueberryDispenser = false,
    AutoStrawberryDispenser = false,
    AutoRoyalJelly = false,
    AutoGlueDispenser = false,
    DispenserInterval = 3600,
    
    -- Quests
    AutoBlackBear = false,
    AutoBrownBear = false,
    AutoPolarBear = false,
    AutoScienceBear = false,
    AutoMotherBear = false,
    
    -- Combat
    AutoKillMobs = false,
    AutoViciousBee = false,
    AutoMondoChick = false,
    AutoStickBug = false,
    AutoKingBeetle = false,
    AutoTunnelBear = false,
    AutoAntChallenge = false,
    
    -- Boost
    AutoFieldBoost = false,
    AutoGlitter = false,
    AutoStarJelly = false,
    
    -- Misc
    AntiAFK = true,
    AutoRejoin = true,
    FPS_Boost = false,
    HideHive = false,
    NoClip = false,
    InfiniteJump = false,
    WalkSpeed = 16,
    JumpPower = 50,
}

-- ============================================================
-- STATE MANAGEMENT
-- ============================================================
local State = {
    Running = true,
    CurrentTask = "Idle",
    IsConverting = false,
    IsTweening = false,
    IsDoingQuest = false,
    IsInCombat = false,
    LastDispenserClaim = {},
    LastSprinklerPlace = 0,
    BackpackPollen = 0,
    BackpackCapacity = 0,
    CurrentField = nil,
    PollenCollected = 0,
    HoneyEarned = 0,
    SessionStart = tick(),
}

local Fields = {
    "Sunflower Field", "Dandelion Field", "Mushroom Field", "Blue Flower Field",
    "Clover Field", "Spider Field", "Strawberry Field", "Bamboo Field",
    "Pineapple Patch", "Stump Field", "Cactus Field", "Pumpkin Patch",
    "Pine Tree Forest", "Rose Field", "Mountain Top Field", "Coconut Field", "Pepper Patch"
}

-- ============================================================
-- UTILITY MODULE
-- ============================================================
local Utils = {}

function Utils:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[BSS Macro] Error: " .. tostring(result))
    end
    return success, result
end

function Utils:TweenTo(targetCFrame, speed, callback)
    local hrp = GetHRP()
    if not hrp then return end
    
    speed = speed or Config.FarmSpeed
    State.IsTweening = true
    
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local tweenTime = distance / speed
    
    if tweenTime < 0.1 then tweenTime = 0.1 end
    if tweenTime > 30 then tweenTime = 30 end
    
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()
    
    State.IsTweening = false
    if callback then callback() end
end

function Utils:TweenToWithTimeout(targetCFrame, speed, timeout)
    local hrp = GetHRP()
    if not hrp then return false end
    
    speed = speed or Config.FarmSpeed
    timeout = timeout or 15
    State.IsTweening = true
    
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local tweenTime = math.min(distance / speed, timeout)
    if tweenTime < 0.1 then tweenTime = 0.1 end
    
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    
    local startTime = tick()
    repeat task.wait(0.1) until not State.IsTweening or (tick() - startTime) > timeout or
        (hrp.Position - targetCFrame.Position).Magnitude < 5
    
    tween:Cancel()
    State.IsTweening = false
    
    return (hrp.Position - targetCFrame.Position).Magnitude < 10
end

function Utils:Teleport(targetCFrame)
    local hrp = GetHRP()
    if not hrp then return end
    hrp.CFrame = targetCFrame
    task.wait(0.5)
end

function Utils:Click()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

function Utils:GetBackpackInfo()
    -- Read pollen from PlayerGui stats
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return 0, 100 end
    
    -- Try to find the pollen display in GUI
    local statsGui = playerGui:FindFirstChild("StatGui") or playerGui:FindFirstChild("ScreenGui")
    
    -- Alternative: read from leaderstats or CoreStats
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local pollen = leaderstats:FindFirstChild("Pollen")
        if pollen then
            State.BackpackPollen = pollen.Value
        end
    end
    
    -- Try reading from the game's internal system
    local coreStats = LocalPlayer:FindFirstChild("CoreStats")
    if coreStats then
        local capacity = coreStats:FindFirstChild("Capacity")
        local pollen = coreStats:FindFirstChild("Pollen")
        if capacity then State.BackpackCapacity = capacity.Value end
        if pollen then State.BackpackPollen = pollen.Value end
    end
    
    return State.BackpackPollen, State.BackpackCapacity
end

function Utils:GetBackpackPercentage()
    local pollen, capacity = self:GetBackpackInfo()
    if capacity == 0 then
        -- Fallback: try to read from GUI text
        pcall(function()
            local gui = LocalPlayer.PlayerGui
            for _, v in pairs(gui:GetDescendants()) do
                if v:IsA("TextLabel") and v.Text:find("/") and v.Text:find(",") then
                    local text = v.Text:gsub(",", "")
                    local current, max = text:match("(%d+)/(%d+)")
                    if current and max then
                        pollen = tonumber(current) or 0
                        capacity = tonumber(max) or 1
                    end
                end
            end
        end)
    end
    if capacity == 0 then capacity = 1 end
    return math.floor((pollen / capacity) * 100)
end

function Utils:IsInField(fieldName)
    local hrp = GetHRP()
    if not hrp then return false end
    local fieldPos = FieldPositions[fieldName]
    if not fieldPos then return false end
    return (hrp.Position - fieldPos.Position).Magnitude < Config.TokenRadius + 10
end

function Utils:GetFieldFlowers(fieldName)
    local flowers = {}
    local flowerFolder = Workspace:FindFirstChild("Flowers")
    if not flowerFolder then
        -- Try alternative paths
        for _, child in pairs(Workspace:GetChildren()) do
            if child.Name:find("Flower") or child.Name:find("flower") then
                flowerFolder = child
                break
            end
        end
    end
    
    if flowerFolder then
        local fieldPos = FieldPositions[fieldName]
        if not fieldPos then return flowers end
        
        for _, flower in pairs(flowerFolder:GetDescendants()) do
            if flower:IsA("BasePart") then
                local dist = (flower.Position - fieldPos.Position).Magnitude
                if dist < Config.TokenRadius + 20 then
                    table.insert(flowers, flower)
                end
            end
        end
    end
    return flowers
end

function Utils:FindNearbyTokens(radius)
    local hrp = GetHRP()
    if not hrp then return {} end
    
    radius = radius or Config.TokenRadius
    local tokens = {}
    
    -- Tokens are usually in Workspace or a specific folder
    local tokenFolders = {
        Workspace:FindFirstChild("Collectibles"),
        Workspace:FindFirstChild("Tokens"),
        Workspace:FindFirstChild("PackageTokens"),
    }
    
    -- Also search direct workspace children
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and (obj.Name:find("Token") or obj.Name:find("token") or obj.Name:find("Collect")) then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist < radius then
                table.insert(tokens, {Part = obj, Distance = dist, Priority = self:GetTokenPriority(obj)})
            end
        end
    end
    
    for _, folder in pairs(tokenFolders) do
        if folder then
            for _, token in pairs(folder:GetDescendants()) do
                if token:IsA("BasePart") then
                    local dist = (token.Position - hrp.Position).Magnitude
                    if dist < radius then
                        table.insert(tokens, {Part = token, Distance = dist, Priority = self:GetTokenPriority(token)})
                    end
                end
            end
        end
    end
    
    -- Sort by priority then distance
    table.sort(tokens, function(a, b)
        if Config.PriorityTokens then
            if a.Priority ~= b.Priority then
                return a.Priority > b.Priority
            end
        end
        return a.Distance < b.Distance
    end)
    
    return tokens
end

function Utils:GetTokenPriority(token)
    local name = token.Name:lower()
    -- Higher priority for rare tokens
    if name:find("star") or name:find("mythic") then return 10 end
    if name:find("diamond") or name:find("glitter") then return 9 end
    if name:find("gold") or name:find("royal") then return 8 end
    if name:find("silver") or name:find("ticket") then return 7 end
    if name:find("gumdrops") or name:find("treat") then return 6 end
    if name:find("honey") then return 5 end
    if name:find("blue") or name:find("red") or name:find("white") then return 4 end
    if name:find("pollen") then return 3 end
    return 1
end

function Utils:FireRemote(remoteName, ...)
    local remote = ReplicatedStorage:FindFirstChild(remoteName)
    if not remote then
        -- Search deeper
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == remoteName then
                remote = v
                break
            end
        end
    end
    
    if remote then
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        end
    end
end

function Utils:GetMobs(fieldName)
    local mobs = {}
    local hrp = GetHRP()
    if not hrp then return mobs end
    
    local mobFolder = Workspace:FindFirstChild("Mobs") or Workspace:FindFirstChild("Monsters")
    if not mobFolder then
        -- Search for mobs in workspace
        for _, child in pairs(Workspace:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChild("Humanoid") and child ~= GetCharacter() then
                local mobHRP = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
                if mobHRP then
                    local dist = (mobHRP.Position - hrp.Position).Magnitude
                    if dist < Config.TokenRadius + 30 then
                        local humanoid = child:FindFirstChild("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            table.insert(mobs, {Model = child, Part = mobHRP, Distance = dist, Health = humanoid.Health})
                        end
                    end
                end
            end
        end
    else
        for _, mob in pairs(mobFolder:GetDescendants()) do
            if mob:IsA("Model") and mob:FindFirstChild("Humanoid") then
                local mobHRP = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
                if mobHRP then
                    local dist = (mobHRP.Position - hrp.Position).Magnitude
                    if dist < Config.TokenRadius + 30 then
                        local humanoid = mob:FindFirstChild("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            table.insert(mobs, {Model = mob, Part = mobHRP, Distance = dist, Health = humanoid.Health})
                        end
                    end
                end
            end
        end
    end
    
    table.sort(mobs, function(a, b) return a.Distance < b.Distance end)
    return mobs
end

function Utils:FindViciousBee()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Vicious Bee" or (obj:IsA("Model") and obj.Name:find("Vicious")) then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or (obj:IsA("BasePart") and obj)
            if part then
                return part
            end
        end
    end
    return nil
end

function Utils:FindMondoChick()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Mondo Chick" or (obj:IsA("Model") and obj.Name:find("Mondo")) then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
            if part then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    return part, humanoid
                end
            end
        end
    end
    return nil
end

-- ============================================================
-- FARMING MODULE
-- ============================================================
local Farming = {}

Farming.PatternIndex = 0
Farming.ZigzagDirection = 1

function Farming:GetFarmPositions(fieldName)
    local basePos = FieldPositions[fieldName]
    if not basePos then return {} end
    
    local positions = {}
    local radius = Config.TokenRadius
    local step = 8
    
    if Config.FarmPattern == "Zigzag" then
        for z = -radius, radius, step do
            if self.ZigzagDirection == 1 then
                for x = -radius, radius, step do
                    table.insert(positions, basePos * CFrame.new(x, 0, z))
                end
            else
                for x = radius, -radius, -step do
                    table.insert(positions, basePos * CFrame.new(x, 0, z))
                end
            end
            self.ZigzagDirection = self.ZigzagDirection * -1
        end
    elseif Config.FarmPattern == "Spiral" then
        local angle = 0
        local r = 5
        while r < radius do
            local x = math.cos(angle) * r
            local z = math.sin(angle) * r
            table.insert(positions, basePos * CFrame.new(x, 0, z))
            angle = angle + 0.5
            r = r + 0.3
        end
    elseif Config.FarmPattern == "Circle" then
        for r = 5, radius, step do
            local circumference = 2 * math.pi * r
            local numPoints = math.max(6, math.floor(circumference / step))
            for i = 1, numPoints do
                local angle = (i / numPoints) * 2 * math.pi
                local x = math.cos(angle) * r
                local z = math.sin(angle) * r
                table.insert(positions, basePos * CFrame.new(x, 0, z))
            end
        end
    else
        -- Default grid
        for x = -radius, radius, step do
            for z = -radius, radius, step do
                table.insert(positions, basePos * CFrame.new(x, 0, z))
            end
        end
    end
    
    return positions
end

function Farming:GoToField(fieldName)
    local fieldCFrame = FieldPositions[fieldName]
    if not fieldCFrame then return false end
    
    State.CurrentTask = "Going to " .. fieldName
    local reached = Utils:TweenToWithTimeout(fieldCFrame + Vector3.new(0, 3, 0), Config.FarmSpeed, 20)
    
    if not reached then
        -- Fallback: direct teleport
        Utils:Teleport(fieldCFrame + Vector3.new(0, 3, 0))
    end
    
    State.CurrentField = fieldName
    task.wait(0.5)
    return true
end

function Farming:FarmField()
    if not Config.AutoFarm then return end
    if State.IsConverting or State.IsDoingQuest then return end
    
    -- Check if need to convert
    local percentage = Utils:GetBackpackPercentage()
    if Config.AutoConvert and percentage >= Config.ConvertAt then
        self:ConvertPollen()
        return
    end
    
    -- Go to field if not there
    if not Utils:IsInField(Config.TargetField) then
        self:GoToField(Config.TargetField)
    end
    
    State.CurrentTask = "Farming " .. Config.TargetField
    
    -- Get farm positions
    local positions = self:GetFarmPositions(Config.TargetField)
    if #positions == 0 then return end
    
    -- Move through pattern
    self.PatternIndex = self.PatternIndex + 1
    if self.PatternIndex > #positions then
        self.PatternIndex = 1
    end
    
    local targetPos = positions[self.PatternIndex]
    Utils:TweenToWithTimeout(targetPos + Vector3.new(0, 2, 0), Config.FarmSpeed, 3)
    
    -- Auto dig while moving
    if Config.AutoDig then
        Utils:Click()
    end
end

function Farming:ConvertPollen()
    if State.IsConverting then return end
    State.IsConverting = true
    State.CurrentTask = "Converting Pollen at Hive"
    
    -- Go to hive
    Utils:TweenToWithTimeout(Locations.Hive + Vector3.new(0, 5, 0), Config.FarmSpeed, 20)
    task.wait(1)
    
    -- Stand on hive slot and wait for conversion
    local hrp = GetHRP()
    if hrp then
        -- Find player's hive slot
        local hiveSlot = self:FindPlayerHive()
        if hiveSlot then
            Utils:TweenToWithTimeout(hiveSlot.CFrame + Vector3.new(0, 2, 0), Config.FarmSpeed, 5)
        end
    end
    
    -- Wait until pollen is 0 or timeout
    local convertStart = tick()
    local maxConvertTime = 60
    
    repeat
        task.wait(0.5)
        -- Keep clicking to speed up conversion
        Utils:Click()
        local pct = Utils:GetBackpackPercentage()
    until pct <= 2 or (tick() - convertStart) > maxConvertTime or not Config.AutoConvert
    
    task.wait(1)
    State.IsConverting = false
    State.CurrentTask = "Idle"
end

function Farming:FindPlayerHive()
    -- Try to find the player's hive in workspace
    local hives = Workspace:FindFirstChild("Hives")
    if not hives then return nil end
    
    for _, hive in pairs(hives:GetChildren()) do
        -- Check if this hive belongs to the player
        local owner = hive:FindFirstChild("Owner") or hive:GetAttribute("Owner")
        if owner then
            local ownerName = (typeof(owner) == "Instance" and owner.Value) or owner
            if ownerName == LocalPlayer.Name or ownerName == LocalPlayer.UserId then
                return hive:FindFirstChild("Platform") or hive:FindFirstChildOfClass("BasePart") or hive
            end
        end
    end
    
    return nil
end

function Farming:PlaceSprinkler()
    if not Config.AutoSprinkler then return end
    if (tick() - State.LastSprinklerPlace) < Config.SprinklerInterval then return end
    
    State.LastSprinklerPlace = tick()
    
    -- Fire the sprinkler placement remote
    pcall(function()
        -- Try common remote names for sprinkler
        Utils:FireRemote("PlaceSprinkler")
        -- Alternative: use tool
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool.Name:find("Sprinkler") then
                    local char = GetCharacter()
                    if char then
                        tool.Parent = char
                        task.wait(0.3)
                        tool:Activate()
                        task.wait(0.3)
                        tool.Parent = backpack
                    end
                    break
                end
            end
        end
    end)
end

-- ============================================================
-- TOKEN COLLECTION MODULE
-- ============================================================
local TokenCollector = {}

function TokenCollector:Process()
    if not Config.CollectTokens then return end
    if State.IsConverting or State.IsTweening then return end
    
    local tokens = Utils:FindNearbyTokens(Config.TokenRadius)
    
    for i, tokenData in ipairs(tokens) do
        if i > 5 then break end -- Collect max 5 tokens per cycle
        if not Config.CollectTokens then break end
        
        local token = tokenData.Part
        if token and token.Parent then
            local hrp = GetHRP()
            if hrp then
                -- Quick tween to token
                Utils:TweenToWithTimeout(token.CFrame, Config.FarmSpeed + 20, 2)
                task.wait(0.1)
            end
        end
    end
end

-- ============================================================
-- DISPENSER MODULE
-- ============================================================
local Dispensers = {}

function Dispensers:CanClaim(dispenserName)
    local lastClaim = State.LastDispenserClaim[dispenserName] or 0
    return (tick() - lastClaim) >= Config.DispenserInterval
end

function Dispensers:ClaimDispenser(dispenserName, location)
    if not self:CanClaim(dispenserName) then return end
    
    State.CurrentTask = "Claiming " .. dispenserName
    
    -- Tween to dispenser
    local reached = Utils:TweenToWithTimeout(location + Vector3.new(0, 3, 0), Config.FarmSpeed, 15)
    if not reached then
        Utils:Teleport(location + Vector3.new(0, 3, 0))
    end
    
    task.wait(1)
    
    -- Interact with dispenser (touch or click)
    local hrp = GetHRP()
    if hrp then
        -- Try to find the dispenser part and touch it
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:find(dispenserName) and obj:IsA("BasePart") then
                firetouchinterest(hrp, obj, 0)
                task.wait(0.2)
                firetouchinterest(hrp, obj, 1)
                break
            end
        end
        
        -- Also try clicking
        Utils:Click()
    end
    
    State.LastDispenserClaim[dispenserName] = tick()
    task.wait(1)
    State.CurrentTask = "Idle"
end

function Dispensers:Process()
    if State.IsConverting or State.IsDoingQuest then return end
    
    if Config.AutoHoneyDispenser and self:CanClaim("Honey") then
        self:ClaimDispenser("Honey", Locations.HoneyDispenser)
    end
    
    if Config.AutoTreatDispenser and self:CanClaim("Treat") then
        self:ClaimDispenser("Treat", Locations.TreatDispenser)
    end
    
    if Config.AutoBlueberryDispenser and self:CanClaim("Blueberry") then
        self:ClaimDispenser("Blueberry", Locations.BlueberryDispenser)
    end
    
    if Config.AutoStrawberryDispenser and self:CanClaim("Strawberry") then
        self:ClaimDispenser("Strawberry", Locations.StrawberryDispenser)
    end
    
    if Config.AutoRoyalJelly and self:CanClaim("RoyalJelly") then
        self:ClaimDispenser("RoyalJelly", Locations.RoyalJellyDispenser)
    end
    
    if Config.AutoGlueDispenser and self:CanClaim("Glue") then
        self:ClaimDispenser("Glue", Locations.GlueDispenser)
    end
end

-- ============================================================
-- QUEST MODULE
-- ============================================================
local Quests = {}

function Quests:TalkToNPC(npcName, location)
    State.IsDoingQuest = true
    State.CurrentTask = "Talking to " .. npcName
    
    -- Go to NPC
    local reached = Utils:TweenToWithTimeout(location + Vector3.new(0, 3, 0), Config.FarmSpeed, 15)
    if not reached then
        Utils:Teleport(location + Vector3.new(0, 3, 0))
    end
    
    task.wait(1)
    
    -- Interact with NPC
    local hrp = GetHRP()
    if hrp then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ClickDetector") then
                local parent = obj.Parent
                if parent and parent.Name:find(npcName:gsub(" ", "")) then
                    fireclickdetector(obj)
                    task.wait(1)
                    break
                end
            end
        end
        
        -- Also try proximity prompt
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local parent = obj.Parent
                if parent and (parent.Name:find(npcName) or (parent.Parent and parent.Parent.Name:find(npcName))) then
                    fireproximityprompt(obj)
                    task.wait(1)
                    break
                end
            end
        end
        
        -- Try touching NPC
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Parent and obj.Parent.Name:find(npcName:gsub(" ", "")) then
                firetouchinterest(hrp, obj, 0)
                task.wait(0.2)
                firetouchinterest(hrp, obj, 1)
                break
            end
        end
    end
    
    task.wait(2)
    
    -- Click through dialogue
    for i = 1, 5 do
        Utils:Click()
        task.wait(0.5)
    end
    
    State.IsDoingQuest = false
    State.CurrentTask = "Idle"
end

function Quests:GetCurrentQuest(bearName)
    -- Try to read quest info from player data
    local questData = nil
    pcall(function()
        local playerData = LocalPlayer:FindFirstChild("PlayerData")
        if playerData then
            local quests = playerData:FindFirstChild("Quests")
            if quests then
                questData = quests:FindFirstChild(bearName)
            end
        end
    end)
    return questData
end

function Quests:CompleteQuestRequirement(questType, fieldName)
    -- Based on quest type, perform the required action
    if questType == "collect" or questType == "pollen" then
        -- Farm the specified field
        if fieldName and FieldPositions[fieldName] then
            Config.TargetField = fieldName
        end
        Farming:FarmField()
    elseif questType == "defeat" then
        -- Kill mobs
        Combat:KillFieldMobs()
    elseif questType == "use" then
        -- Use items (stingers, glitter, etc.)
    end
end

function Quests:Process()
    if State.IsConverting then return end
    
    if Config.AutoBlackBear then
        self:TalkToNPC("Black Bear", Locations.BlackBear)
    end
    
    if Config.AutoBrownBear then
        self:TalkToNPC("Brown Bear", Locations.BrownBear)
    end
    
    if Config.AutoPolarBear then
        self:TalkToNPC("Polar Bear", Locations.PolarBear)
    end
    
    if Config.AutoScienceBear then
        self:TalkToNPC("Science Bear", Locations.ScienceBear)
    end
    
    if Config.AutoMotherBear then
        self:TalkToNPC("Mother Bear", Locations.MotherBear)
    end
end

-- ============================================================
-- COMBAT MODULE
-- ============================================================
local Combat = {}

function Combat:AttackMob(mobData)
    if not mobData or not mobData.Part or not mobData.Part.Parent then return end
    
    State.IsInCombat = true
    State.CurrentTask = "Attacking " .. mobData.Model.Name
    
    local humanoid = mobData.Model:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        State.IsInCombat = false
        return
    end
    
    -- Move to mob and attack
    local startTime = tick()
    while humanoid and humanoid.Health > 0 and (tick() - startTime) < 30 do
        if not Config.AutoKillMobs then break end
        
        local mobPart = mobData.Part
        if not mobPart or not mobPart.Parent then break end
        
        local hrp = GetHRP()
        if not hrp then break end
        
        -- Stay near mob
        if (hrp.Position - mobPart.Position).Magnitude > 10 then
            Utils:TweenToWithTimeout(mobPart.CFrame + Vector3.new(0, 2, 0), Config.FarmSpeed + 20, 2)
        end
        
        -- Attack
        Utils:Click()
        task.wait(0.2)
    end
    
    State.IsInCombat = false
end

function Combat:KillFieldMobs()
    if not Config.AutoKillMobs then return end
    
    local mobs = Utils:GetMobs(Config.TargetField)
    for _, mob in ipairs(mobs) do
        if not Config.AutoKillMobs then break end
        self:AttackMob(mob)
        task.wait(0.3)
    end
end

function Combat:HandleViciousBee()
    if not Config.AutoViciousBee then return end
    
    local vicious = Utils:FindViciousBee()
    if not vicious then return end
    
    State.CurrentTask = "Attacking Vicious Bee"
    State.IsInCombat = true
    
    local startTime = tick()
    while vicious and vicious.Parent and (tick() - startTime) < 120 do
        if not Config.AutoViciousBee then break end
        
        local hrp = GetHRP()
        if not hrp then break end
        
        -- Move to vicious bee
        Utils:TweenToWithTimeout(vicious.CFrame + Vector3.new(0, -2, 0), Config.FarmSpeed + 30, 2)
        Utils:Click()
        task.wait(0.2)
        
        -- Re-find in case it moved
        vicious = Utils:FindViciousBee()
    end
    
    State.IsInCombat = false
    State.CurrentTask = "Idle"
end

function Combat:HandleMondoChick()
    if not Config.AutoMondoChick then return end
    
    local mondoPart, mondoHumanoid = Utils:FindMondoChick()
    if not mondoPart then return end
    
    State.CurrentTask = "Attacking Mondo Chick"
    State.IsInCombat = true
    
    -- Go to mountain top
    Utils:TweenToWithTimeout(Locations.MondoChick + Vector3.new(0, 5, 0), Config.FarmSpeed, 20)
    
    local startTime = tick()
    while mondoHumanoid and mondoHumanoid.Health > 0 and (tick() - startTime) < 300 do
        if not Config.AutoMondoChick then break end
        
        local hrp = GetHRP()
        if not hrp then break end
        
        mondoPart, mondoHumanoid = Utils:FindMondoChick()
        if not mondoPart then break end
        
        -- Stay near and attack
        if (hrp.Position - mondoPart.Position).Magnitude > 15 then
            Utils:TweenToWithTimeout(mondoPart.CFrame + Vector3.new(0, -3, 0), Config.FarmSpeed + 20, 3)
        end
        
        Utils:Click()
        task.wait(0.15)
    end
    
    State.IsInCombat = false
    State.CurrentTask = "Idle"
end

function Combat:HandleStickBug()
    if not Config.AutoStickBug then return end
    
    -- Find stick bug
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:find("Stick Bug") or obj.Name:find("StickBug") then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChild("HumanoidRootPart")
            if part then
                State.CurrentTask = "Fighting Stick Bug"
                Utils:TweenToWithTimeout(part.CFrame + Vector3.new(0, 2, 0), Config.FarmSpeed, 10)
                
                -- Attack loop
                local startTime = tick()
                while (tick() - startTime) < 180 and Config.AutoStickBug do
                    Utils:Click()
                    task.wait(0.2)
                    
                    -- Check if still alive
                    if not part.Parent then break end
                end
                break
            end
        end
    end
end

function Combat:HandleAntChallenge()
    if not Config.AutoAntChallenge then return end
    
    State.CurrentTask = "Doing Ant Challenge"
    
    -- Go to ant challenge
    Utils:TweenToWithTimeout(Locations.AntChallenge + Vector3.new(0, 3, 0), Config.FarmSpeed, 20)
    task.wait(2)
    
    -- Enter and fight ants
    local startTime = tick()
    while (tick() - startTime) < 300 and Config.AutoAntChallenge do
        -- Find and kill ants
        local mobs = Utils:GetMobs("Ant Challenge")
        for _, mob in ipairs(mobs) do
            if not Config.AutoAntChallenge then break end
            self:AttackMob(mob)
        end
        
        -- Collect tokens
        TokenCollector:Process()
        task.wait(0.3)
    end
    
    State.CurrentTask = "Idle"
end

function Combat:Process()
    if State.IsConverting or State.IsDoingQuest then return end
    
    -- Priority: Vicious Bee > Mondo Chick > Field Mobs
    if Config.AutoViciousBee then
        local vicious = Utils:FindViciousBee()
        if vicious then
            self:HandleViciousBee()
            return
        end
    end
    
    if Config.AutoMondoChick then
        local mondo = Utils:FindMondoChick()
        if mondo then
            self:HandleMondoChick()
            return
        end
    end
    
    if Config.AutoKillMobs then
        self:KillFieldMobs()
    end
end

-- ============================================================
-- BOOST MODULE
-- ============================================================
local Boosts = {}

function Boosts:UseFieldBooster()
    if not Config.AutoFieldBoost then return end
    
    -- Find field booster in backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool.Name:find("Booster") or tool.Name:find("Field Boost") then
            local char = GetCharacter()
            if char then
                tool.Parent = char
                task.wait(0.5)
                tool:Activate()
                task.wait(0.5)
                tool.Parent = backpack
            end
            break
        end
    end
end

function Boosts:UseGlitter()
    if not Config.AutoGlitter then return end
    
    pcall(function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool.Name:find("Glitter") then
                    local char = GetCharacter()
                    if char then
                        tool.Parent = char
                        task.wait(0.3)
                        tool:Activate()
                        task.wait(0.3)
                        tool.Parent = backpack
                    end
                    break
                end
            end
        end
    end)
end

-- ============================================================
-- MISC MODULE
-- ============================================================
local Misc = {}

function Misc:AntiAFK()
    if not Config.AntiAFK then return end
    
    -- Override idle detection
    local VirtualUser = game:GetService("VirtualUser")
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

function Misc:AutoRejoin()
    if not Config.AutoRejoin then return end
    
    -- Detect disconnect and rejoin
    pcall(function()
        game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" and Config.AutoRejoin then
                task.wait(5)
                game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
            end
        end)
    end)
end

function Misc:FPSBoost()
    if not Config.FPS_Boost then return end
    
    pcall(function()
        -- Reduce visual quality for performance
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.FogEnd = 9e9
        
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        
        -- Remove unnecessary visual effects
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
            if v:IsA("Decal") and v.Parent and v.Parent.Name ~= "Head" then
                v.Transparency = 1
            end
        end
        
        -- Reduce terrain detail
        pcall(function()
            Workspace.Terrain.WaterWaveSize = 0
            Workspace.Terrain.WaterWaveSpeed = 0
            Workspace.Terrain.WaterReflectance = 0
            Workspace.Terrain.WaterTransparency = 0
        end)
    end)
end

function Misc:NoClip()
    if not Config.NoClip then return end
    
    RunService.Stepped:Connect(function()
        if Config.NoClip then
            local char = GetCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

function Misc:InfiniteJump()
    if not Config.InfiniteJump then return end
    
    UserInputService.JumpRequest:Connect(function()
        if Config.InfiniteJump then
            local humanoid = GetHumanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

function Misc:SetWalkSpeed()
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = Config.WalkSpeed
        humanoid.JumpPower = Config.JumpPower
    end
end

-- ============================================================
-- UI LIBRARY (Rayfield)
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "BSS Macro | MCP Style",
    LoadingTitle = "BSS Macro Loading...",
    LoadingSubtitle = "Full Automation Suite",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BSS_Macro_MCP",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- ============================================================
-- TAB: AUTO FARM
-- ============================================================
local TabFarm = Window:CreateTab("Auto Farm", 4483362458)

TabFarm:CreateSection("Main Farming")

TabFarm:CreateToggle({
    Name = "Enable Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v) Config.AutoFarm = v end,
})

TabFarm:CreateDropdown({
    Name = "Target Field",
    Options = Fields,
    CurrentOption = {"Sunflower Field"},
    Flag = "TargetField",
    Callback = function(v) Config.TargetField = v end,
})

TabFarm:CreateDropdown({
    Name = "Farm Pattern",
    Options = {"Zigzag", "Spiral", "Circle", "Grid"},
    CurrentOption = {"Zigzag"},
    Flag = "FarmPattern",
    Callback = function(v) Config.FarmPattern = v end,
})

TabFarm:CreateSlider({
    Name = "Farm Speed",
    Range = {20, 150},
    Increment = 5,
    CurrentValue = 60,
    Flag = "FarmSpeed",
    Callback = function(v) Config.FarmSpeed = v end,
})

TabFarm:CreateSlider({
    Name = "Farm Radius",
    Range = {10, 80},
    Increment = 5,
    CurrentValue = 40,
    Flag = "FarmRadius",
    Callback = function(v) Config.TokenRadius = v end,
})

TabFarm:CreateToggle({
    Name = "Auto Dig (Click)",
    CurrentValue = true,
    Flag = "AutoDig",
    Callback = function(v) Config.AutoDig = v end,
})

TabFarm:CreateSection("Token Collection")

TabFarm:CreateToggle({
    Name = "Collect Tokens",
    CurrentValue = false,
    Flag = "CollectTokens",
    Callback = function(v) Config.CollectTokens = v end,
})

TabFarm:CreateToggle({
    Name = "Priority Rare Tokens",
    CurrentValue = true,
    Flag = "PriorityTokens",
    Callback = function(v) Config.PriorityTokens = v end,
})

TabFarm:CreateSection("Conversion")

TabFarm:CreateToggle({
    Name = "Auto Convert at Hive",
    CurrentValue = false,
    Flag = "AutoConvert",
    Callback = function(v) Config.AutoConvert = v end,
})

TabFarm:CreateSlider({
    Name = "Convert at % Full",
    Range = {50, 100},
    Increment = 5,
    CurrentValue = 95,
    Flag = "ConvertAt",
    Callback = function(v) Config.ConvertAt = v end,
})

TabFarm:CreateSection("Sprinkler")

TabFarm:CreateToggle({
    Name = "Auto Place Sprinkler",
    CurrentValue = false,
    Flag = "AutoSprinkler",
    Callback = function(v) Config.AutoSprinkler = v end,
})

TabFarm:CreateSlider({
    Name = "Sprinkler Interval (sec)",
    Range = {10, 120},
    Increment = 5,
    CurrentValue = 30,
    Flag = "SprinklerInterval",
    Callback = function(v) Config.SprinklerInterval = v end,
})

-- ============================================================
-- TAB: DISPENSERS
-- ============================================================
local TabDispenser = Window:CreateTab("Dispensers", 4483362458)

TabDispenser:CreateSection("Auto Claim Dispensers")

TabDispenser:CreateToggle({
    Name = "Honey Dispenser",
    CurrentValue = false,
    Flag = "HoneyDispenser",
    Callback = function(v) Config.AutoHoneyDispenser = v end,
})

TabDispenser:CreateToggle({
    Name = "Treat Dispenser",
    CurrentValue = false,
    Flag = "TreatDispenser",
    Callback = function(v) Config.AutoTreatDispenser = v end,
})

TabDispenser:CreateToggle({
    Name = "Blueberry Dispenser",
    CurrentValue = false,
    Flag = "BlueberryDispenser",
    Callback = function(v) Config.AutoBlueberryDispenser = v end,
})

TabDispenser:CreateToggle({
    Name = "Strawberry Dispenser",
    CurrentValue = false,
    Flag = "StrawberryDispenser",
    Callback = function(v) Config.AutoStrawberryDispenser = v end,
})

TabDispenser:CreateToggle({
    Name = "Royal Jelly Dispenser",
    CurrentValue = false,
    Flag = "RoyalJellyDispenser",
    Callback = function(v) Config.AutoRoyalJelly = v end,
})

TabDispenser:CreateToggle({
    Name = "Glue Dispenser",
    CurrentValue = false,
    Flag = "GlueDispenser",
    Callback = function(v) Config.AutoGlueDispenser = v end,
})

TabDispenser:CreateSlider({
    Name = "Claim Interval (seconds)",
    Range = {60, 7200},
    Increment = 60,
    CurrentValue = 3600,
    Flag = "DispenserInterval",
    Callback = function(v) Config.DispenserInterval = v end,
})

-- ============================================================
-- TAB: QUESTS
-- ============================================================
local TabQuests = Window:CreateTab("Quests", 4483362458)

TabQuests:CreateSection("Auto Bear Quests")

TabQuests:CreateToggle({
    Name = "Auto Black Bear",
    CurrentValue = false,
    Flag = "BlackBear",
    Callback = function(v) Config.AutoBlackBear = v end,
})

TabQuests:CreateToggle({
    Name = "Auto Brown Bear",
    CurrentValue = false,
    Flag = "BrownBear",
    Callback = function(v) Config.AutoBrownBear = v end,
})

TabQuests:CreateToggle({
    Name = "Auto Polar Bear",
    CurrentValue = false,
    Flag = "PolarBear",
    Callback = function(v) Config.AutoPolarBear = v end,
})

TabQuests:CreateToggle({
    Name = "Auto Science Bear",
    CurrentValue = false,
    Flag = "ScienceBear",
    Callback = function(v) Config.AutoScienceBear = v end,
})

TabQuests:CreateToggle({
    Name = "Auto Mother Bear",
    CurrentValue = false,
    Flag = "MotherBear",
    Callback = function(v) Config.AutoMotherBear = v end,
})

-- ============================================================
-- TAB: COMBAT
-- ============================================================
local TabCombat = Window:CreateTab("Combat", 4483362458)

TabCombat:CreateSection("Field Mobs")

TabCombat:CreateToggle({
    Name = "Auto Kill Field Mobs",
    CurrentValue = false,
    Flag = "KillMobs",
    Callback = function(v) Config.AutoKillMobs = v end,
})

TabCombat:CreateSection("Bosses")

TabCombat:CreateToggle({
    Name = "Auto Vicious Bee",
    CurrentValue = false,
    Flag = "ViciousBee",
    Callback = function(v) Config.AutoViciousBee = v end,
})

TabCombat:CreateToggle({
    Name = "Auto Mondo Chick",
    CurrentValue = false,
    Flag = "MondoChick",
    Callback = function(v) Config.AutoMondoChick = v end,
})

TabCombat:CreateToggle({
    Name = "Auto Stick Bug",
    CurrentValue = false,
    Flag = "StickBug",
    Callback = function(v) Config.AutoStickBug = v end,
})

TabCombat:CreateToggle({
    Name = "Auto King Beetle",
    CurrentValue = false,
    Flag = "KingBeetle",
    Callback = function(v) Config.AutoKingBeetle = v end,
})

TabCombat:CreateToggle({
    Name = "Auto Tunnel Bear",
    CurrentValue = false,
    Flag = "TunnelBear",
    Callback = function(v) Config.AutoTunnelBear = v end,
})

TabCombat:CreateSection("Challenges")

TabCombat:CreateToggle({
    Name = "Auto Ant Challenge",
    CurrentValue = false,
    Flag = "AntChallenge",
    Callback = function(v) Config.AutoAntChallenge = v end,
})

-- ============================================================
-- TAB: BOOSTS
-- ============================================================
local TabBoost = Window:CreateTab("Boosts", 4483362458)

TabBoost:CreateSection("Field Boosts")

TabBoost:CreateToggle({
    Name = "Auto Field Booster",
    CurrentValue = false,
    Flag = "FieldBoost",
    Callback = function(v) Config.AutoFieldBoost = v end,
})

TabBoost:CreateToggle({
    Name = "Auto Glitter",
    CurrentValue = false,
    Flag = "AutoGlitter",
    Callback = function(v) Config.AutoGlitter = v end,
})

-- ============================================================
-- TAB: MISC
-- ============================================================
local TabMisc = Window:CreateTab("Misc", 4483362458)

TabMisc:CreateSection("Anti-Detection")

TabMisc:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v)
        Config.AntiAFK = v
        if v then Misc:AntiAFK() end
    end,
})

TabMisc:CreateToggle({
    Name = "Auto Rejoin on Disconnect",
    CurrentValue = true,
    Flag = "AutoRejoin",
    Callback = function(v)
        Config.AutoRejoin = v
        if v then Misc:AutoRejoin() end
    end,
})

TabMisc:CreateSection("Performance")

TabMisc:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(v)
        Config.FPS_Boost = v
        if v then Misc:FPSBoost() end
    end,
})

TabMisc:CreateSection("Movement")

TabMisc:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(v)
        Config.NoClip = v
        if v then Misc:NoClip() end
    end,
})

TabMisc:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v)
        Config.InfiniteJump = v
        if v then Misc:InfiniteJump() end
    end,
})

TabMisc:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        Config.WalkSpeed = v
        Misc:SetWalkSpeed()
    end,
})

TabMisc:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        Config.JumpPower = v
        Misc:SetWalkSpeed()
    end,
})

TabMisc:CreateSection("Teleports")

TabMisc:CreateButton({
    Name = "Teleport to Hive",
    Callback = function()
        Utils:TweenToWithTimeout(Locations.Hive + Vector3.new(0, 5, 0), Config.FarmSpeed, 15)
    end,
})

TabMisc:CreateButton({
    Name = "Teleport to Black Bear",
    Callback = function()
        Utils:TweenToWithTimeout(Locations.BlackBear + Vector3.new(0, 3, 0), Config.FarmSpeed, 15)
    end,
})

TabMisc:CreateButton({
    Name = "Teleport to Brown Bear",
    Callback = function()
        Utils:TweenToWithTimeout(Locations.BrownBear + Vector3.new(0, 3, 0), Config.FarmSpeed, 15)
    end,
})

TabMisc:CreateButton({
    Name = "Teleport to Polar Bear",
    Callback = function()
        Utils:TweenToWithTimeout(Locations.PolarBear + Vector3.new(0, 3, 0), Config.FarmSpeed, 15)
    end,
})

TabMisc:CreateButton({
    Name = "Teleport to Wind Shrine",
    Callback = function()
        Utils:TweenToWithTimeout(Locations.WindShrine + Vector3.new(0, 3, 0), Config.FarmSpeed, 15)
    end,
})

-- ============================================================
-- TAB: STATUS
-- ============================================================
local TabStatus = Window:CreateTab("Status", 4483362458)

TabStatus:CreateSection("Session Info")

local StatusLabel = TabStatus:CreateLabel("Status: Idle")
local FieldLabel = TabStatus:CreateLabel("Field: None")
local BackpackLabel = TabStatus:CreateLabel("Backpack: 0%")
local UptimeLabel = TabStatus:CreateLabel("Uptime: 0m")

-- Update status labels periodically
task.spawn(function()
    while State.Running do
        task.wait(2)
        pcall(function()
            local uptime = math.floor((tick() - State.SessionStart) / 60)
            StatusLabel:Set("Status: " .. State.CurrentTask)
            FieldLabel:Set("Field: " .. (State.CurrentField or "None"))
            BackpackLabel:Set("Backpack: " .. Utils:GetBackpackPercentage() .. "%")
            UptimeLabel:Set("Uptime: " .. uptime .. "m")
        end)
    end
end)

-- ============================================================
-- MAIN EXECUTION LOOP
-- ============================================================
local function MainLoop()
    -- Initialize misc features
    Misc:AntiAFK()
    Misc:AutoRejoin()
    
    while State.Running do
        task.wait(0.15)
        
        -- Ensure character exists
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            task.wait(1)
            continue
        end
        
        pcall(function()
            -- Priority system (highest to lowest):
            -- 1. Vicious Bee (rare spawn, high value)
            -- 2. Mondo Chick (timed boss)
            -- 3. Convert pollen when full
            -- 4. Dispensers (on cooldown)
            -- 5. Quests
            -- 6. Farm field
            -- 7. Collect tokens
            -- 8. Kill mobs
            -- 9. Place sprinkler
            
            -- Check for Vicious Bee (always priority)
            if Config.AutoViciousBee then
                local vicious = Utils:FindViciousBee()
                if vicious then
                    Combat:HandleViciousBee()
                    return
                end
            end
            
            -- Check for Mondo Chick
            if Config.AutoMondoChick then
                local mondo = Utils:FindMondoChick()
                if mondo then
                    Combat:HandleMondoChick()
                    return
                end
            end
            
            -- Auto Convert check
            if Config.AutoConvert and not State.IsConverting then
                local pct = Utils:GetBackpackPercentage()
                if pct >= Config.ConvertAt then
                    Farming:ConvertPollen()
                    return
                end
            end
            
            -- Skip other tasks if converting
            if State.IsConverting then return end
            
            -- Dispensers (check cooldowns)
            Dispensers:Process()
            
            -- Auto Farm
            if Config.AutoFarm then
                Farming:FarmField()
                
                -- Place sprinkler while farming
                Farming:PlaceSprinkler()
            end
            
            -- Token collection
            if Config.CollectTokens then
                TokenCollector:Process()
            end
            
            -- Combat (field mobs)
            if Config.AutoKillMobs and not State.IsInCombat then
                Combat:KillFieldMobs()
            end
            
            -- Stick Bug
            if Config.AutoStickBug then
                Combat:HandleStickBug()
            end
            
            -- Ant Challenge
            if Config.AutoAntChallenge then
                Combat:HandleAntChallenge()
            end
        end)
    end
end

-- Quest loop (separate thread, less frequent)
local function QuestLoop()
    while State.Running do
        task.wait(300) -- Check quests every 5 minutes
        
        if not State.IsConverting and not State.IsInCombat then
            pcall(function()
                Quests:Process()
            end)
        end
    end
end

-- Dispenser loop (separate thread)
local function DispenserLoop()
    while State.Running do
        task.wait(60) -- Check dispensers every minute
        
        if not State.IsConverting and not State.IsInCombat and not State.IsDoingQuest then
            pcall(function()
                Dispensers:Process()
            end)
        end
    end
end

-- Boost loop
local function BoostLoop()
    while State.Running do
        task.wait(600) -- Check boosts every 10 minutes
        
        pcall(function()
            Boosts:UseFieldBooster()
            Boosts:UseGlitter()
        end)
    end
end

-- ============================================================
-- CHARACTER RESPAWN HANDLER
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(3)
    -- Re-apply settings after respawn
    pcall(function()
        Misc:SetWalkSpeed()
        if Config.NoClip then Misc:NoClip() end
    end)
end)

-- ============================================================
-- START ALL THREADS
-- ============================================================
task.spawn(MainLoop)
task.spawn(QuestLoop)
task.spawn(DispenserLoop)
task.spawn(BoostLoop)

-- ============================================================
-- NOTIFICATION
-- ============================================================
Rayfield:Notify({
    Title = "BSS Macro Loaded",
    Content = "Full automation suite active. Use tabs to configure.",
    Duration = 6,
    Image = 4483362458,
})

print("[BSS Macro] Script loaded successfully!")
print("[BSS Macro] Session started at: " .. os.date("%H:%M:%S"))
