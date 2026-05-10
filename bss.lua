local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ==========================================
-- SCRIPT CONFIGURATION & STATE
-- ==========================================
local Config = {
    -- Auto Farm
    AutoFarm = false,
    TargetField = "Sunflower Field",
    AutoDig = false,
    AutoSprinkler = false,
    FarmRadius = 40,
    CollectTokens = false,
    
    -- Auto Convert
    AutoConvert = false,
    ConvertAt = 100,
    
    -- Dispensers
    AutoHoneyDispenser = false,
    AutoBlueberryDispenser = false,
    AutoStrawberryDispenser = false,
    
    -- Quests
    AutoBlackBear = false,
    AutoBrownBear = false,
    AutoPolarBear = false,
    
    -- Combat
    AutoKillMobs = false,
    AutoViciousBee = false,
    AutoMondoChick = false,
}

local State = {
    IsConverting = false,
    IsQuesting = false,
    CurrentTask = "Idle"
}

local Fields = {
    "Sunflower Field", "Dandelion Field", "Mushroom Field", "Blue Flower Field",
    "Clover Field", "Spider Field", "Strawberry Field", "Bamboo Field",
    "Pineapple Patch", "Stump Field", "Cactus Field", "Pumpkin Patch",
    "Pine Tree Forest", "Rose Field", "Mountain Top Field", "Coconut Field", "Pepper Patch"
}

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local Utils = {}

function Utils:TweenTo(targetCFrame, speed)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    speed = speed or 50
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - targetCFrame.Position).Magnitude
    local time = distance / speed
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

function Utils:GetBackpackPercentage()
    -- BSS specific: getting pollen / capacity
    -- This is a placeholder since we don't have the specific BSS path, usually it's in LocalPlayer.CoreStats
    return 0 
end

function Utils:Click()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- ==========================================
-- CORE MODULES
-- ==========================================
local Farming = {}

function Farming:DoDig()
    if Config.AutoDig then
        Utils:Click()
    end
end

function Farming:PlaceSprinkler()
    if Config.AutoSprinkler then
        -- Logic to place sprinkler in the middle of the field
    end
end

function Farming:CollectFieldTokens()
    if Config.CollectTokens then
        -- Logic to find tokens in workspace matching the field area and tween to them
    end
end

function Farming:ConvertPollen()
    State.IsConverting = true
    State.CurrentTask = "Converting at Hive"
    -- Tween to hive location, trigger convert remote/action
    task.wait(5) -- Mock waiting time for conversion
    State.IsConverting = false
end

function Farming:Process()
    if not Config.AutoFarm or State.IsConverting or State.IsQuesting then return end
    
    if Config.AutoConvert and Utils:GetBackpackPercentage() >= Config.ConvertAt then
        self:ConvertPollen()
    else
        State.CurrentTask = "Farming " .. Config.TargetField
        -- Tween to Config.TargetField if not already there
        self:DoDig()
        self:PlaceSprinkler()
        self:CollectFieldTokens()
    end
end

local Dispensers = {}
function Dispensers:Process()
    if Config.AutoHoneyDispenser then
        -- Teleport to Honey Dispenser and claim
    end
    if Config.AutoBlueberryDispenser then
        -- Teleport to Blueberry Dispenser and claim
    end
    if Config.AutoStrawberryDispenser then
        -- Teleport to Strawberry Dispenser and claim
    end
end

local Quests = {}
function Quests:Process()
    if Config.AutoBlackBear then
        -- Talk to Black Bear
    end
    if Config.AutoBrownBear then
        -- Talk to Brown Bear
    end
end

local Combat = {}
function Combat:Process()
    if Config.AutoKillMobs then
        -- Scan field for ladybugs, rhino beetles, spiders, etc.
    end
    if Config.AutoViciousBee then
        -- Detect vicious bee spikes and attack
    end
    if Config.AutoMondoChick then
        -- Go to mountain top when Mondo is spawning
    end
end

-- ==========================================
-- UI LIBRARY INITIALIZATION (Rayfield)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "BSS Automation Hub",
   LoadingTitle = "Loading BSS Hub...",
   LoadingSubtitle = "by Antigravity",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "BSS_Hub",
      FileName = "BSS_Hub_Config"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

-- UI TABS
local TabFarm = Window:CreateTab("Auto Farm", 4483362458)
local TabItems = Window:CreateTab("Items & Dispenser", 4483362458)
local TabQuests = Window:CreateTab("Quests", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)

-- ==========================================
-- UI ELEMENTS: AUTO FARM
-- ==========================================
local FarmSection = TabFarm:CreateSection("Farming Options")

TabFarm:CreateToggle({
    Name = "Enable Auto Farm",
    CurrentValue = false,
    Flag = "Toggle_AutoFarm",
    Callback = function(Value)
        Config.AutoFarm = Value
    end,
})

TabFarm:CreateDropdown({
    Name = "Select Field",
    Options = Fields,
    CurrentOption = "Sunflower Field",
    Flag = "Dropdown_TargetField",
    Callback = function(Option)
        Config.TargetField = Option
    end,
})

TabFarm:CreateToggle({
    Name = "Auto Dig",
    CurrentValue = false,
    Flag = "Toggle_AutoDig",
    Callback = function(Value)
        Config.AutoDig = Value
    end,
})

TabFarm:CreateToggle({
    Name = "Auto Sprinkler",
    CurrentValue = false,
    Flag = "Toggle_AutoSprinkler",
    Callback = function(Value)
        Config.AutoSprinkler = Value
    end,
})

TabFarm:CreateToggle({
    Name = "Collect Tokens",
    CurrentValue = false,
    Flag = "Toggle_CollectTokens",
    Callback = function(Value)
        Config.CollectTokens = Value
    end,
})

local ConvertSection = TabFarm:CreateSection("Conversion Settings")

TabFarm:CreateToggle({
    Name = "Auto Convert at Hive",
    CurrentValue = false,
    Flag = "Toggle_AutoConvert",
    Callback = function(Value)
        Config.AutoConvert = Value
    end,
})

TabFarm:CreateSlider({
    Name = "Convert When Backpack %",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 100,
    Flag = "Slider_ConvertAt",
    Callback = function(Value)
        Config.ConvertAt = Value
    end,
})

-- ==========================================
-- UI ELEMENTS: ITEMS & DISPENSERS
-- ==========================================
TabItems:CreateSection("Auto Claim Dispensers")

TabItems:CreateToggle({
    Name = "Honey Dispenser",
    CurrentValue = false,
    Flag = "Toggle_HoneyDispenser",
    Callback = function(Value) Config.AutoHoneyDispenser = Value end,
})

TabItems:CreateToggle({
    Name = "Blueberry Dispenser",
    CurrentValue = false,
    Flag = "Toggle_BlueberryDispenser",
    Callback = function(Value) Config.AutoBlueberryDispenser = Value end,
})

TabItems:CreateToggle({
    Name = "Strawberry Dispenser",
    CurrentValue = false,
    Flag = "Toggle_StrawberryDispenser",
    Callback = function(Value) Config.AutoStrawberryDispenser = Value end,
})

-- ==========================================
-- UI ELEMENTS: QUESTS
-- ==========================================
TabQuests:CreateSection("Auto Bear Quests")

TabQuests:CreateToggle({
    Name = "Black Bear",
    CurrentValue = false,
    Flag = "Toggle_BlackBear",
    Callback = function(Value) Config.AutoBlackBear = Value end,
})

TabQuests:CreateToggle({
    Name = "Brown Bear",
    CurrentValue = false,
    Flag = "Toggle_BrownBear",
    Callback = function(Value) Config.AutoBrownBear = Value end,
})

-- ==========================================
-- UI ELEMENTS: COMBAT
-- ==========================================
TabCombat:CreateSection("Combat Settings")

TabCombat:CreateToggle({
    Name = "Auto Kill Field Mobs",
    CurrentValue = false,
    Flag = "Toggle_KillMobs",
    Callback = function(Value) Config.AutoKillMobs = Value end,
})

TabCombat:CreateToggle({
    Name = "Auto Vicious Bee",
    CurrentValue = false,
    Flag = "Toggle_ViciousBee",
    Callback = function(Value) Config.AutoViciousBee = Value end,
})

TabCombat:CreateToggle({
    Name = "Auto Mondo Chick",
    CurrentValue = false,
    Flag = "Toggle_MondoChick",
    Callback = function(Value) Config.AutoMondoChick = Value end,
})

-- ==========================================
-- MAIN EXECUTION LOOP
-- ==========================================
local function MainLoop()
    while task.wait(0.1) do
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            continue
        end

        -- Execute core systems safely
        pcall(function()
            Farming:Process()
            Dispensers:Process()
            Quests:Process()
            Combat:Process()
        end)
    end
end

-- Start Main Thread
task.spawn(MainLoop)

-- Notify User
Rayfield:Notify({
    Title = "BSS Hub Loaded",
    Content = "Successfully injected and started execution loop.",
    Duration = 5,
    Image = 4483362458,
})
