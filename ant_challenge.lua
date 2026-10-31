-- =============================================================================
-- BSS ANT CHALLENGE BOT  (ant_challenge.lua)  --  standalone test file
-- =============================================================================
-- File RIENG de test Ant Challenge, khong phu thuoc kaitun. Ground truth lay
-- tu place that (MCP probe) + co che atlas:
--   * Toy: workspace.Toys["Ant Challenge"] - Busy(BoolValue) = flag dang choi,
--     CostType="AntPass" x1, Platform @91,30,545 (dung day de activate),
--     Walls.WallLeft/Right.Door1/2/3 @Z=574/593/612 (lane may cay),
--     Obstacles = folder may cay spawn runtime, Meter/TimeBoard = progress.
--   * Activate: ReplicatedStorage.Events.ToyEvent:FireServer("Ant Challenge")
--     (toy khong co ProximityPrompt trong place - ToyEvent la kenh chuan).
--   * Ants: workspace.Monsters, ten chua "Ant" - thuong avoid 15, Giant 25.
--   * FIRE: patch luc chay = "FireParticles" con tren tile hoa trong
--     workspace.Flowers (atlas tracked.antfire) -> avoid tile do ban kinh 8.
--   * Lawnmower: Door color "Really red" -> lane do; + LUON avoid lane Z=612.
--   * Tokens drop vao workspace.Collectibles - nhat trong bounds Ant Field.
--
-- CHAY: execute file trong BSS (place 1537690962). Dung bang:
--   getgenv().__BSS_ANT.Stop()
-- Config nhanh: getgenv().BSS_ANT_CONFIG = { AutoRestart = true, ... }
-- =============================================================================

local ENV = (getgenv and getgenv()) or _G
if ENV.__BSS_ANT and type(ENV.__BSS_ANT.Stop) == "function" then
    pcall(ENV.__BSS_ANT.Stop)
    task.wait(0.2)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BSS_PLACE_ID = 1537690962
if game.PlaceId ~= BSS_PLACE_ID then
    warn("[BSS Ant] Wrong place " .. tostring(game.PlaceId) .. " - chay trong BSS thoi")
    return
end

local Player = Players.LocalPlayer
repeat task.wait() until game:IsLoaded() and Player

local Config = {
    Enabled = true,
    AutoRestart = false,        -- xong quai thi di tiep (can Ant Pass moi lan)
    ChallengeTimeout = 300,     -- atlas cap 300s
    AntRadius = 15,             -- ant thuong (atlas)
    GiantAntRadius = 25,        -- Giant Ant (atlas)
    FireRadius = 8,             -- fire tile (atlas)
    MowerRadius = 14,           -- may cay runtime
    MowerLaneRadius = 20,       -- lane theo door do (atlas: 20)
    AlwaysAvoidLaneZ = 612,     -- atlas: LUON avoid hang Z=612
    EvadeStep = 10,             -- so stud buoc thoat khi danger qua gan
    EvadeStepClose = 15,        -- ant ap sat rát: buoc dai hon
    JumpBiteDistance = 9,       -- chi jump khi ant gan toi muc cam (hop lien tuc lam cham chay)
    ThreatExitMargin = 5,       -- hysteresis: van coi la danger den khi xa them moi nay
    FarmCellSize = 16,          -- kich thuoc o coverage grid khi khong co ant gan
    TokenFarmDistance = 60,     -- token trong tam nay se uu tien tren duong farm
    Tick = 0.2,
    TokenMaxDistance = 90,      -- token xa hon thi bo
}
do
    local overrides = ENV.BSS_ANT_CONFIG
    if type(overrides) == "table" then
        for key, value in pairs(overrides) do Config[key] = value end
    end
end

local State = {
    Running = true,
    Status = "starting",
    Challenges = 0,
}

local function status(text)
    State.Status = text
    print("[BSS Ant] " .. text)
end

-- =============================================================================
-- Character helpers
-- =============================================================================
local function getCharacter(timeout)
    local deadline = os.clock() + (timeout or 2)
    while os.clock() < deadline do
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and root and humanoid.Health > 0 then
            return humanoid, root
        end
        task.wait(0.1)
    end
    return nil, nil
end

local function antFieldZone()
    local zones = workspace:FindFirstChild("FlowerZones")
    local zone = zones and zones:FindFirstChild("Ant Field")
    if zone and zone:IsA("BasePart") then
        return zone.CFrame, zone.Size
    end
    return nil, nil
end

local function inAntField(position, margin)
    local cf, size = antFieldZone()
    if not cf or not size then return false end
    local localPoint = cf:PointToObjectSpace(position)
    local extra = margin or 0
    return math.abs(localPoint.X) <= size.X * 0.5 + extra
        and math.abs(localPoint.Z) <= size.Z * 0.5 + extra
end

-- =============================================================================
-- Threat sources: ants + fire tiles + mower
-- =============================================================================
local fireTiles = {}          -- [tile] = true (FireParticles con ton tai)
local watchingFire = false

local function watchFireTiles()
    if watchingFire then return end
    watchingFire = true
    task.spawn(function()
        while State.Running do
            local flowers = workspace:FindFirstChild("Flowers")
            if flowers then
                local added = flowers.DescendantAdded:Connect(function(descendant)
                    if descendant.Name == "FireParticles" and descendant.Parent then
                        fireTiles[descendant.Parent] = true
                    end
                end)
                local removed = flowers.DescendantRemoving:Connect(function(descendant)
                    if descendant.Name == "FireParticles" then
                        fireTiles[descendant.Parent] = nil
                    end
                end)
                -- bat fire da ton tai san + quet lai moi 5s (mower moi round)
                while State.Running and flowers.Parent do
                    for _, descendant in ipairs(flowers:GetDescendants()) do
                        if descendant.Name == "FireParticles" and descendant.Parent then
                            fireTiles[descendant.Parent] = true
                        end
                    end
                    task.wait(5)
                end
                added:Disconnect()
                removed:Disconnect()
            end
            task.wait(2)
        end
    end)
end

-- avoid list: {position, radius} - gom ant/giant/fire/mower/lane
local function buildAvoidList(rootPosition)
    local list = {}
    -- Ants spawn ở Monsters (server) HOẶC FEMonsters (client-side spawns -
    -- folder riêng cho mob replication-filtered, có trong place thật).
    for _, folderName in ipairs({"Monsters", "FEMonsters"}) do
        local monsters = workspace:FindFirstChild(folderName)
        if monsters then
            for _, mob in ipairs(monsters:GetChildren()) do
                local humanoid = mob:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local name = mob.Name
                    if name:find("Ant", 1, true) then
                        local antRoot = mob:FindFirstChild("HumanoidRootPart")
                            or mob:FindFirstChildWhichIsA("BasePart", true)
                        if antRoot then
                            local radius = name:find("Giant", 1, true)
                                and Config.GiantAntRadius or Config.AntRadius
                            table.insert(list, {Position = antRoot.Position, Radius = radius, Kind = "ant"})
                        end
                    end
                end
            end
        end
    end
    for tile in pairs(fireTiles) do
        if tile.Parent then
            local position = tile:IsA("BasePart") and tile.Position
                or (tile:IsA("Model") and tile:GetPivot().Position or nil)
            if position then
                table.insert(list, {Position = position, Radius = Config.FireRadius, Kind = "fire"})
            end
        else
            fireTiles[tile] = nil
        end
    end
    local toy = workspace:FindFirstChild("Toys") and workspace.Toys:FindFirstChild("Ant Challenge")
    if toy then
        -- lane may cay: door mau "Really red" = lane dang chay + lane hang dinh
        local walls = toy:FindFirstChild("Walls")
        if walls then
            local lanes = {}
            for _, wallName in ipairs({"WallLeft", "WallRight"}) do
                local wall = walls:FindFirstChild(wallName)
                if wall then
                    for _, door in ipairs(wall:GetChildren()) do
                        if door:IsA("BasePart") and door.BrickColor.Name == "Really red" then
                            lanes[door.Position.Z] = true
                        end
                    end
                end
            end
            lanes[Config.AlwaysAvoidLaneZ] = true
            for z in pairs(lanes) do
                table.insert(list, {Position = Vector3.new(rootPosition.X, 0, z), Radius = Config.MowerLaneRadius, Kind = "lane", Flat = true})
            end
        end
        -- may cay runtime (Obstacles)
        local obstacles = toy:FindFirstChild("Obstacles")
        if obstacles then
            for _, mower in ipairs(obstacles:GetChildren()) do
                local part = mower:IsA("BasePart") and mower
                    or mower:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    table.insert(list, {Position = part.Position, Radius = Config.MowerRadius, Kind = "mower"})
                end
            end
        end
    end
    return list
end

local function blockedByAvoid(from, to, list, margin)
    local flatFrom = Vector3.new(from.X, 0, from.Z)
    local flatTo = Vector3.new(to.X, 0, to.Z)
    local length = (flatTo - flatFrom).Magnitude
    if length < 2 then return nil end
    local steps = math.max(1, math.ceil(length / 4))
    for _, threat in ipairs(list) do
        local flatThreat = Vector3.new(threat.Position.X, 0, threat.Position.Z)
        for step = 0, steps do
            local point = flatFrom:Lerp(flatTo, step / steps)
            if (point - flatThreat).Magnitude <= threat.Radius + (margin or 0) then
                return threat
            end
        end
    end
    return nil
end

local function nearestThreat(rootPosition, list, extraMargin)
    local best, bestDistance, bestKind
    for _, threat in ipairs(list) do
        local flat = (Vector3.new(rootPosition.X, 0, rootPosition.Z)
            - Vector3.new(threat.Position.X, 0, threat.Position.Z)).Magnitude
        if flat <= threat.Radius + (extraMargin or 0)
            and (not bestDistance or flat < bestDistance) then
            best, bestDistance, bestKind = threat, flat, threat.Kind
        end
    end
    return best, bestDistance, bestKind
end

-- =============================================================================
-- COVERAGE FARM: het ant gan -> chay quanh field theo grid xao tron (kieu
-- kaitun farmCoveragePoint), duong di co DETOUR arc quanh threat (midpoint
-- vuong goc, verify 2 chan) - token tren duong duoc uu tien.
-- =============================================================================
local coverageQueue = {}

local function rebuildCoverage()
    coverageQueue = {}
    local cf, size = antFieldZone()
    if not cf or not size then return end
    local cols = math.clamp(math.floor(size.X / Config.FarmCellSize + 0.5), 2, 8)
    local rows = math.clamp(math.floor(size.Z / Config.FarmCellSize + 0.5), 2, 5)
    for row = 1, rows do
        for col = 1, cols do
            table.insert(coverageQueue, {Col = col, Row = row, Cols = cols, Rows = rows})
        end
    end
    for index = #coverageQueue, 2, -1 do
        local swap = math.random(index)
        coverageQueue[index], coverageQueue[swap] = coverageQueue[swap], coverageQueue[index]
    end
end

local function cellCenter(entry)
    local cf, size = antFieldZone()
    if not cf or not size then return nil end
    local x = (entry.Col - 0.5) / entry.Cols * size.X - size.X * 0.5
    local z = (entry.Row - 0.5) / entry.Rows * size.Z - size.Z * 0.5
    local jitterX = (math.random() - 0.5) * (size.X / entry.Cols) * 0.5
    local jitterZ = (math.random() - 0.5) * (size.Z / entry.Rows) * 0.5
    return cf:PointToWorldSpace(Vector3.new(x + jitterX, 0, z + jitterZ))
end

-- Diem coverage tiep theo: bo o bi threat chiem (giu lai queue de thu lai),
-- duong thang bi chan thi tra ve {Mid, Goal} detour 2 chan da verify.
local function nextCoveragePoint(rootPosition, avoid)
    if #coverageQueue == 0 then rebuildCoverage() end
    local attempts = math.min(#coverageQueue, 4)
    for _ = 1, attempts do
        local entry = table.remove(coverageQueue, 1)
        local point = cellCenter(entry)
        if point then
            local threat = blockedByAvoid(rootPosition, point, avoid, 2)
            if not threat then
                return {point}
            end
            -- DETOUR arc: midpoint vuong goc, phia xa threat, offset tam ve
            -- trong field; ca 2 chan phai sach moi nhan.
            local flatFrom = Vector3.new(rootPosition.X, 0, rootPosition.Z)
            local flatTo = Vector3.new(point.X, 0, point.Z)
            local direction = flatTo - flatFrom
            local length = direction.Magnitude
            if length >= 8 then
                direction = direction / length
                local mid = flatFrom:Lerp(flatTo, 0.5)
                local perp = Vector3.new(-direction.Z, 0, direction.X)
                local flatThreat = Vector3.new(threat.Position.X, 0, threat.Position.Z)
                local side = (mid + perp * 8 - flatThreat).Magnitude
                    >= (mid - perp * 8 - flatThreat).Magnitude and 1 or -1
                local midPoint = mid + perp * (side * (threat.Radius + 8))
                local cf, size = antFieldZone()
                if cf and size then
                    local localMid = cf:PointToObjectSpace(midPoint)
                    midPoint = cf:PointToWorldSpace(Vector3.new(
                        math.clamp(localMid.X, -size.X * 0.5 + 4, size.X * 0.5 - 4), localMid.Y,
                        math.clamp(localMid.Z, -size.Z * 0.5 + 4, size.Z * 0.5 - 4)))
                end
                if not blockedByAvoid(rootPosition, midPoint, avoid, 2)
                    and not blockedByAvoid(midPoint, point, avoid, 2) then
                    return {midPoint, point}
                end
            end
            -- Detour that bai: day o ve cuoi queue (thu lai sau), thu o khac
            table.insert(coverageQueue, entry)
        end
    end
    return nil
end

-- ESCAPE FAN: thử 7 hướng quạt quanh hướng thoát, clamp điểm vào trong
-- field (lane sát tường không còn trượt dọc lane), CHỈ nhận hướng mà cả
-- đoạn đi lẫn điểm đích đều ngoài MỌI threat - hết oscillate giữa đàn ant.
local function findEscape(root, threat, avoid, step)
    step = step or Config.EvadeStep
    local away = Vector3.new(root.X - threat.Position.X, 0, root.Z - threat.Position.Z)
    if away.Magnitude < 0.5 then away = Vector3.new(1, 0, 0) end
    local baseAngle = math.atan2(away.Z, away.X)
    local cf, size = antFieldZone()
    for _, deltaDeg in ipairs({0, 40, -40, 80, -80, 120, -120, 180}) do
        local angle = baseAngle + math.rad(deltaDeg)
        local point = root + Vector3.new(math.cos(angle), 0, math.sin(angle)) * step
        if cf and size then
            local localPoint = cf:PointToObjectSpace(point)
            localPoint = Vector3.new(
                math.clamp(localPoint.X, -size.X * 0.5 + 4, size.X * 0.5 - 4), localPoint.Y,
                math.clamp(localPoint.Z, -size.Z * 0.5 + 4, size.Z * 0.5 - 4))
            point = cf:PointToWorldSpace(localPoint)
        end
        if not blockedByAvoid(root, point, avoid, 1) then
            return point
        end
    end
    -- Mọi hướng bị chặn: điểm xa threat nhất có thể (clamp phía đối diện).
    if cf and size then
        local localPoint = cf:PointToObjectSpace(root + away.Unit * Config.EvadeStep)
        localPoint = Vector3.new(
            math.clamp(localPoint.X, -size.X * 0.5 + 4, size.X * 0.5 - 4), localPoint.Y,
            math.clamp(localPoint.Z, -size.Z * 0.5 + 4, size.Z * 0.5 - 4))
        return cf:PointToWorldSpace(localPoint)
    end
    return root + away.Unit * step
end

-- =============================================================================
-- Movement: MoveTo thuan (arena dong, khong tween khong flight)
-- =============================================================================
local function walkTo(position, timeout)
    local deadline = os.clock() + (timeout or 10)
    local nextIssue = 0
    while os.clock() < deadline do
        local humanoid, root = getCharacter(1)
        if not humanoid then return false end
        local flat = Vector3.new(position.X, 0, position.Z)
        local here = Vector3.new(root.Position.X, 0, root.Position.Z)
        if (flat - here).Magnitude <= 4 then return true end
        if os.clock() >= nextIssue then
            nextIssue = os.clock() + 0.4
            humanoid:MoveTo(position)
        end
        task.wait(0.1)
    end
    return false
end

-- Tween cho CHUYEN DAI (platform/dispenser xa): anchored glide nhanh, giu
-- huong character. Trong arena van dung MoveTo (dodge can physics that).
local TweenService = game:GetService("TweenService")
local function tweenTo(position, speed)
    local humanoid, root = getCharacter(2)
    if not root then return false end
    local distance = (position - root.Position).Magnitude
    if distance < 6 then return true end
    local duration = math.clamp(distance / math.max(20, speed or 100), 0.1, 25)
    local rotation = root.CFrame - root.CFrame.Position
    local wasAnchored = root.Anchored
    root.Anchored = true
    root.AssemblyLinearVelocity = Vector3.zero
    local tween = TweenService:Create(root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position) * rotation})
    tween:Play()
    tween.Completed:Wait()
    root.Anchored = wasAnchored
    return true
end

-- =============================================================================
-- ANT PASS: dem tu ClientStatCache (scan de quy nhu kaitun) + claim dispenser
-- =============================================================================
local function statCount(key)
    local module = ReplicatedStorage:FindFirstChild("ClientStatCache")
    if not module then return nil end
    local ok, cache = pcall(require, module)
    if not ok or type(cache) ~= "table" or type(cache.Get) ~= "function" then return nil end
    local okGet, stats = pcall(cache.Get, cache)
    if not okGet or type(stats) ~= "table" then return nil end
    local found
    local visited = {}
    local function scan(value, depth)
        if found or type(value) ~= "table" or visited[value] or depth > 4 then return end
        visited[value] = true
        for k, child in pairs(value) do
            if k == key and tonumber(child) then found = tonumber(child) return end
            if type(child) == "table" then scan(child, depth + 1) end
        end
    end
    scan(stats, 0)
    return found
end

-- Claim Ant Pass tu dispenser (10 tickets/1 pass, cooldown server 5 phut)
local function ensureAntPass()
    local have = statCount("AntPass")
    if have and have >= 1 then return true end
    local tickets = statCount("Tickets") or statCount("Ticket")
    if tickets and tickets < 10 then
        status(string.format("Khong du dieu kien: AntPass=%s Tickets=%s (can 1 pass hoac 10 tickets)",
            tostring(have), tostring(tickets)))
        return false
    end
    local dispenser = workspace:FindFirstChild("Toys")
        and workspace.Toys:FindFirstChild("Ant Pass Dispenser")
    if not dispenser then
        status("Khong thay Ant Pass Dispenser")
        return false
    end
    local platform = dispenser:FindFirstChild("Platform")
        or dispenser:FindFirstChildWhichIsA("BasePart", true)
    if platform then
        status("Tween den Ant Pass Dispenser - claim pass")
        tweenTo(platform.Position + Vector3.new(0, 3, 0), 100)
        task.wait(0.4)
    end
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        local toyEvent = events and events:FindFirstChild("ToyEvent")
        toyEvent:FireServer("Ant Pass Dispenser")
    end)
    task.wait(2)
    local after = statCount("AntPass")
    status(string.format("Claim xong - AntPass: %s -> %s", tostring(have), tostring(after)))
    return (after or 1) >= 1
end

-- =============================================================================
-- Token sweep (Collectibles trong bounds Ant Field)
-- =============================================================================
local function nearestToken(rootPosition)
    local folder = workspace:FindFirstChild("Collectibles")
    if not folder then return nil end
    local best, bestDistance
    for _, token in ipairs(folder:GetChildren()) do
        local position = token:IsA("BasePart") and token.Position
            or (token:IsA("Model") and token:GetPivot().Position or nil)
        if position and inAntField(position, 8) then
            local distance = (position - rootPosition).Magnitude
            if distance <= Config.TokenMaxDistance and (not bestDistance or distance < bestDistance) then
                best, bestDistance = token, distance
            end
        end
    end
    return best, bestDistance
end

-- =============================================================================
-- CHALLENGE LOOP
-- =============================================================================
local function challengeLoop()
    local deadline = os.clock() + Config.ChallengeTimeout
    while State.Running and os.clock() < deadline do
        local toy = workspace:FindFirstChild("Toys") and workspace.Toys:FindFirstChild("Ant Challenge")
        local stillActive = toy and toy:FindFirstChild("Busy") and toy.Busy.Value
        local _, rootNow = getCharacter(1)
        -- Xong khi: flag tat HOAC bi teleport ra khoi arena (ket thuc that su)
        if not stillActive or (rootNow and not inAntField(rootNow.Position, 40)) then
            break
        end
        local humanoid, root = getCharacter(1)
        if not humanoid then task.wait(0.5) continue end

        local avoid = buildAvoidList(root.Position)
        local flatRoot = Vector3.new(root.Position.X, 0, root.Position.Z)

        -- 1) DANGER (hysteresis: giu nen them ThreatExitMargin de khong flicker)
        local threat, threatDistance, kind = nearestThreat(flatRoot, avoid, Config.ThreatExitMargin)
        if threat then
            -- Step scale theo muc nguy cap: ap sat rat -> buoc dai (khong
            -- mutate Config - truyen param)
            local step = threatDistance <= threat.Radius * 0.5
                and Config.EvadeStepClose or Config.EvadeStep
            local escape = findEscape(flatRoot, threat, avoid, step)
            humanoid:MoveTo(escape)
            -- Jump CHI khi ant gan muc cam (hop lien tuc lam cham di chuyen);
            -- lane/fire/mower la tinh da: di ra khoi, khong can nhay.
            if kind == "ant" and threatDistance <= Config.JumpBiteDistance
                and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
            end
            if os.clock() - (State.LastEvadeLog or 0) > 1 then
                State.LastEvadeLog = os.clock()
                status("Evading " .. tostring(kind))
            end
        else
            -- 2) FARM MODE: token tren duong uu tien, khong thi coverage grid
            --    co detour. Target dang di: doi khi den noi hoac moi tick moi.
            local target = State.FarmTarget
            local arrived = true
            if target then
                arrived = (Vector3.new(target.X, 0, target.Z) - flatRoot).Magnitude <= 5
            end
            if arrived then
                State.FarmTarget = nil
                State.FarmPath = nil
                -- Token gan nhat, duong di sach -> uu tien bat
                local token = nearestToken(root.Position)
                if token then
                    local position = token:IsA("BasePart") and token.Position or token:GetPivot().Position
                    if (position - root.Position).Magnitude <= Config.TokenFarmDistance
                        and not blockedByAvoid(flatRoot, position, avoid, 2) then
                        State.FarmTarget = position
                    end
                end
                -- Khong token: o coverage kep theo (detour arc neu can)
                if not State.FarmTarget then
                    local path = nextCoveragePoint(flatRoot, avoid)
                    if path then
                        State.FarmPath = path
                        State.FarmTarget = path[1]
                    end
                end
            elseif State.FarmPath and #State.FarmPath > 1
                and (Vector3.new(State.FarmPath[1].X, 0, State.FarmPath[1].Z) - flatRoot).Magnitude <= 5 then
                -- Detour 2 chan: leg 1 xong -> chuyen leg 2
                table.remove(State.FarmPath, 1)
                State.FarmTarget = State.FarmPath[1]
            end
            if State.FarmTarget then
                humanoid:MoveTo(Vector3.new(State.FarmTarget.X, root.Position.Y, State.FarmTarget.Z))
            end
        end
        task.wait(Config.Tick)
    end
    State.FarmTarget = nil
    State.FarmPath = nil
end

-- =============================================================================
-- START: Platform -> ToyEvent -> confirm Busy
-- =============================================================================
local function startChallenge()
    local toy = workspace:FindFirstChild("Toys") and workspace.Toys:FindFirstChild("Ant Challenge")
    if not toy or not toy:FindFirstChild("Busy") then
        status("Khong thay toy Ant Challenge")
        return false
    end
    -- Busy la flag CHUNG ca server: Busy=true co the la NGUOI KHAC dang choi.
    -- Khong duoc tin Busy khi chua activate - xac nhan bang teleport vao arena.
    if toy.Busy.Value then
        status("Co nguoi khac dang lam challenge - cho luot")
        return false
    end

    -- Can 1 Ant Pass: dem tu stats, het thi claim dispenser (10 tickets).
    if not ensureAntPass() then
        task.wait(30)
        return false
    end

    local humanoid, root = getCharacter(3)
    if not humanoid then return false end
    local platform = toy:FindFirstChild("Platform")
    if platform then
        status("Tween den Platform de activate")
        tweenTo(Vector3.new(platform.Position.X, platform.Position.Y + 3, platform.Position.Z), 100)
        walkTo(Vector3.new(platform.Position.X, root.Position.Y, platform.Position.Z), 8)
    end
    task.wait(0.3)

    -- Activate: ToyEvent voi ten toy (kenh chuan cua BSS toy, place khong co prompt)
    local ok = pcall(function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        local toyEvent = events and events:FindFirstChild("ToyEvent")
        toyEvent:FireServer("Ant Challenge")
    end)
    if not ok then
        status("Fire ToyEvent that bai")
        return false
    end

    -- Confirm THUC SU bat dau: Busy flip true + minh duoc teleport vao arena
    -- (activation thanh cong dua player vao khu Ant Field/Hill). Neu co nguoi
    -- khác chiem luot trong khoang nay, minh khong duoc teleport -> fail.
    local deadline = os.clock() + 5
    while os.clock() < deadline do
        local _, nowRoot = getCharacter(1)
        if nowRoot and toy.Busy.Value and inAntField(nowRoot.Position, 40) then
            status("Challenge ACTIVE (da vao arena)")
            return true
        end
        task.wait(0.2)
    end
    status("Activate khong xac nhan duoc (het Ant Pass / co nguoi tranh luot?) - cho")
    return false
end

-- =============================================================================
-- MAIN
-- =============================================================================
watchFireTiles()

task.spawn(function()
    while State.Running do
        if not Config.Enabled then
            task.wait(0.5)
        else
            State.Challenges += 1
            status(string.format("Lan %d - bat dau", State.Challenges))
            local started = false
            local okStart, errStart = xpcall(startChallenge, debug.traceback)
            if not okStart then
                status("startChallenge error: " .. tostring(errStart))
                task.wait(5)
            else
                started = errStart -- startChallenge tra true/false
            end
            if started then
                local okLoop, errLoop = xpcall(challengeLoop, debug.traceback)
                if not okLoop then
                    status("challengeLoop error: " .. tostring(errLoop))
                end
                -- hut not token con lai sau khi xong (tween nhanh)
                local _, root = getCharacter(2)
                if root then
                    local endTime = os.clock() + 6
                    while os.clock() < endTime do
                        local token = nearestToken(root.Position)
                        if not token then break end
                        local position = token:IsA("BasePart") and token.Position or token:GetPivot().Position
                        tweenTo(position, 120)
                        task.wait(0.15)
                    end
                end
                status(string.format("Lan %d xong", State.Challenges))
                if not Config.AutoRestart then
                    State.Running = false
                    break
                end
                task.wait(3)
            else
                task.wait(10) -- cooldown / chua du dieu kien
            end
        end
    end
    status("Da dung")
end)

ENV.__BSS_ANT = {
    Stop = function()
        State.Running = false
        status("Stop requested")
    end,
    State = State,
    Config = Config,
}

status("Loaded - AutoRestart=" .. tostring(Config.AutoRestart))
return ENV.__BSS_ANT
