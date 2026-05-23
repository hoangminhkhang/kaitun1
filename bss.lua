-- Inertia Premium UI & Automation Framework
-- Modern Dark Theme Restaurant Management System
-- Created with example functions for automation

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Clean up previous instances
if PlayerGui:FindFirstChild("Inertia_UI") then
    PlayerGui.Inertia_UI:Destroy()
end

-- =============================================================================
-- THEME CONFIGURATION
-- =============================================================================
local Theme = {
    BgColor = Color3.fromRGB(15, 15, 18),
    SidebarBg = Color3.fromRGB(10, 10, 12),
    AccentColor = Color3.fromRGB(0, 180, 216),
    TextColor = Color3.fromRGB(240, 240, 245),
    MutedTextColor = Color3.fromRGB(140, 140, 150),
    BorderColor = Color3.fromRGB(25, 25, 30),
    ToggleOn = Color3.fromRGB(0, 180, 216),
    ToggleOff = Color3.fromRGB(40, 40, 45),
    FontMain = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

-- =============================================================================
-- SETTINGS STATE
-- =============================================================================
local AutoSettings = {
    AutoAssignSeat = false,
    AutoTakeOrders = false,
    AutoServe = false,
    AutoOrderStand = false,
    AutoStove = false,
    AutoCleanDish = false,
    AutoClaimCash = false,
    ClaimCashInterval = 15,
}

-- =============================================================================
-- EXAMPLE AUTOMATION FUNCTIONS
-- =============================================================================

-- Example function that demonstrates automation logic
local function exampleAutoFunction(functionName, enabled)
    if enabled then
        print("[Inertia] " .. functionName .. " is now ENABLED")
        -- Add your automation logic here
        return true
    else
        print("[Inertia] " .. functionName .. " is now DISABLED")
        return false
    end
end

-- Auto Assign Seat Handler
local function handleAutoAssignSeat(state)
    AutoSettings.AutoAssignSeat = state
    exampleAutoFunction("Auto Assign Seat", state)
    
    if state then
        -- Example: Find and assign customers to empty seats
        task.spawn(function()
            while AutoSettings.AutoAssignSeat do
                -- Your seat assignment logic here
                print("[Inertia] Checking for customers to seat...")
                task.wait(2)
            end
        end)
    end
end

-- Auto Take Orders Handler
local function handleAutoTakeOrders(state)
    AutoSettings.AutoTakeOrders = state
    exampleAutoFunction("Auto Take Orders", state)
    
    if state then
        task.spawn(function()
            while AutoSettings.AutoTakeOrders do
                -- Your order taking logic here
                print("[Inertia] Taking orders from customers...")
                task.wait(1.5)
            end
        end)
    end
end

-- Auto Serve Handler
local function handleAutoServe(state)
    AutoSettings.AutoServe = state
    exampleAutoFunction("Auto Serve", state)
    
    if state then
        task.spawn(function()
            while AutoSettings.AutoServe do
                -- Your serving logic here
                print("[Inertia] Serving food to customers...")
                task.wait(1.5)
            end
        end)
    end
end

-- Auto Order Stand Handler
local function handleAutoOrderStand(state)
    AutoSettings.AutoOrderStand = state
    exampleAutoFunction("Auto Order Stand", state)
    
    if state then
        task.spawn(function()
            while AutoSettings.AutoOrderStand do
                -- Your order stand logic here
                print("[Inertia] Managing order stand...")
                task.wait(2)
            end
        end)
    end
end

-- Auto Stove Handler
local function handleAutoStove(state)
    AutoSettings.AutoStove = state
    exampleAutoFunction("Auto Stove", state)
    
    if state then
        task.spawn(function()
            while AutoSettings.AutoStove do
                -- Your stove/cooking logic here
                print("[Inertia] Cooking food on stove...")
                task.wait(1)
            end
        end)
    end
end

-- Auto Clean Dish Handler
local function handleAutoCleanDish(state)
    AutoSettings.AutoCleanDish = state
    exampleAutoFunction("Auto Clean Dish", state)
    
    if state then
        task.spawn(function()
            while AutoSettings.AutoCleanDish do
                -- Your dish cleaning logic here
                print("[Inertia] Cleaning dishes...")
                task.wait(2)
            end
        end)
    end
end

-- Auto Claim Cash Handler
local function handleAutoClaimCash(state)
    AutoSettings.AutoClaimCash = state
    exampleAutoFunction("Auto Claim Cash", state)
    
    if state then
        task.spawn(function()
            while AutoSettings.AutoClaimCash do
                -- Your cash claiming logic here
                print("[Inertia] Claiming cash from register...")
                task.wait(AutoSettings.ClaimCashInterval)
            end
        end)
    end
end

-- Claim Cash Interval Handler
local function handleClaimCashInterval(value)
    AutoSettings.ClaimCashInterval = value
    print("[Inertia] Claim Cash Interval set to " .. value .. " seconds")
end

-- =============================================================================
-- UI CONSTRUCTION
-- =============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Inertia_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 750, 0, 480)
MainFrame.Position = UDim2.new(0.5, -375, 0.5, -240)
MainFrame.BackgroundColor3 = Theme.BgColor
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner_Main = Instance.new("UICorner")
UICorner_Main.CornerRadius = UDim.new(0, 8)
UICorner_Main.Parent = MainFrame

local UIBorder_Main = Instance.new("UIStroke")
UIBorder_Main.Thickness = 1
UIBorder_Main.Color = Theme.BorderColor
UIBorder_Main.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIBorder_Main.Parent = MainFrame

-- Dragging Logic
local Dragging, DragStart, StartPosition
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPosition = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(
            StartPosition.X.Scale, StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 210, 1, 0)
Sidebar.BackgroundColor3 = Theme.SidebarBg
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local UICorner_Sidebar = Instance.new("UICorner")
UICorner_Sidebar.CornerRadius = UDim.new(0, 8)
UICorner_Sidebar.Parent = Sidebar

-- Logo Container
local LogoContainer = Instance.new("Frame")
LogoContainer.Name = "LogoContainer"
LogoContainer.Size = UDim2.new(1, 0, 0, 60)
LogoContainer.BackgroundTransparency = 1
LogoContainer.Parent = Sidebar

local LogoIcon = Instance.new("ImageLabel")
LogoIcon.Name = "LogoIcon"
LogoIcon.Size = UDim2.new(0, 24, 0, 24)
LogoIcon.Position = UDim2.new(0, 20, 0.5, -12)
LogoIcon.BackgroundTransparency = 1
LogoIcon.Image = "rbxassetid://6031087244"
LogoIcon.ImageColor3 = Theme.AccentColor
LogoIcon.Parent = LogoContainer

local LogoText = Instance.new("TextLabel")
LogoText.Name = "LogoText"
LogoText.Size = UDim2.new(1, -60, 1, 0)
LogoText.Position = UDim2.new(0, 52, 0, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "Inertia"
LogoText.Font = Theme.FontBold
LogoText.TextSize = 18
LogoText.TextColor3 = Theme.TextColor
LogoText.TextXAlignment = Enum.TextXAlignment.Left
LogoText.Parent = LogoContainer

-- Navigation Scroll
local NavScroll = Instance.new("ScrollingFrame")
NavScroll.Name = "NavScroll"
NavScroll.Size = UDim2.new(1, 0, 1, -130)
NavScroll.Position = UDim2.new(0, 0, 0, 60)
NavScroll.BackgroundTransparency = 1
NavScroll.BorderSizePixel = 0
NavScroll.ScrollBarThickness = 0
NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
NavScroll.Parent = Sidebar
