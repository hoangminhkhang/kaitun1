-- AOTR Auto Join Utgard (Utaga) - Best Reward Mode
-- Tự động tạo mission Utgard với mode reward cao nhất và join

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local POST = ReplicatedStorage.Assets.Remotes.POST
local GET = ReplicatedStorage.Assets.Remotes.GET

-- Config
local CONFIG = {
    MAP_NAME = "Utgard",
    DIFFICULTY = "Nightmare",      -- Mode reward cao nhất
    OBJECTIVE = "Skirmish",
    AUTO_RETRY = true,
    RETRY_DELAY = 3,
    MAX_RETRIES = 10,
}

local function log(msg)
    print("[Kaitun] " .. msg)
end

-- Di chuyển đến Bell zone
local function moveToBell()
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bellZone = workspace:FindFirstChild("Zones")
    if bellZone then
        bellZone = bellZone:FindFirstChild("Bell")
        if bellZone then
            local hitbox = bellZone:FindFirstChild("Hitbox")
            if hitbox then
                hrp.CFrame = hitbox.CFrame
                task.wait(0.5)
            end
        end
    end
end

-- Tạo mission mới
local function createMission()
    log("Tạo mission " .. CONFIG.MAP_NAME .. " - " .. CONFIG.DIFFICULTY)

    pcall(function()
        POST:FireServer("Create_Mission", {
            Map = CONFIG.MAP_NAME,
            Difficulty = CONFIG.DIFFICULTY,
            Objective = CONFIG.OBJECTIVE,
        })
    end)

    task.wait(1)
end

-- Start mission
local function startMission()
    log("Start mission...")
    pcall(function()
        POST:FireServer("Start_Mission")
    end)
end

-- Main
local function main()
    log("=== Auto Utgard - " .. CONFIG.DIFFICULTY .. " ===")

    local retries = 0
    while CONFIG.AUTO_RETRY and retries < CONFIG.MAX_RETRIES do
        retries = retries + 1
        log("Lần #" .. retries)

        -- Chờ character
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            player.CharacterAdded:Wait()
            task.wait(2)
        end

        -- Tp đến Bell
        moveToBell()

        -- Tạo mission
        createMission()

        -- Start
        startMission()
        task.wait(5)

        -- Check teleport
        if not workspace:FindFirstChild("Zones") then
            log("Teleport thành công!")
            break
        end

        log("Chưa teleport, thử lại...")
        task.wait(CONFIG.RETRY_DELAY)
    end
end

task.spawn(main)
