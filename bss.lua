-- Inertia Premium UI & Automation Framework (My Restaurant Typology)
-- Fully Client-Side Compatible & Executor Ready
-- Designed to load in-game with dynamic remote resolving and remote logging

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Determine GUI parent (CoreGui for exploits/executors, PlayerGui as fallback)
local TargetParent = nil
local success, err = pcall(function()
    TargetParent = CoreGui
end)
if not success or not TargetParent then
    TargetParent = PlayerGui
end

-- Clean up previous instances
if TargetParent:FindFirstChild("Inertia_UI") then
    TargetParent.Inertia_UI:Destroy()
end

-- =============================================================================
-- THEME & CONFIGURATION
-- =============================================================================
local Theme = {
    BgColor = Color3.fromRGB(15, 15, 18),
    SidebarBg = Color3.fromRGB(10, 10, 12),
    AccentColor = Color3.fromRGB(0, 180, 216),
    AccentHover = Color3.fromRGB(0, 223, 252),
    TextColor = Color3.fromRGB(240, 240, 245),
    MutedTextColor = Color3.fromRGB(140, 140, 150),
    BorderColor = Color3.fromRGB(25, 25, 30),
    ToggleOn = Color3.fromRGB(0, 180, 216),
    ToggleOff = Color3.fromRGB(40, 40, 45),
    FontMain = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

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
-- RUNTIME NETWORK DETECTOR & HELPER
-- =============================================================================
local Network = nil
local RemoteMapping = {} -- Cache for dynamically discovered events
local logOutput = {} -- Status logs displayed in the UI console

local function uiLog(text)
    table.insert(logOutput, "[" .. os.date("%X") .. "] " .. tostring(text))
    if #logOutput > 50 then table.remove(logOutput, 1) end
    local consoleBox = TargetParent:FindFirstChild("Inertia_UI") and TargetParent.Inertia_UI:FindFirstChild("ConsoleScroll", true)
    if consoleBox then
        consoleBox.Text = table.concat(logOutput, "\n")
        consoleBox.CanvasPosition = Vector2.new(0, consoleBox.AbsoluteCanvasSize.Y)
    end
    print("[Inertia Log]:", text)
end

-- Dynamic require of game framework
task.spawn(function()
    uiLog("Initializing game framework client...")
    local fw = ReplicatedStorage:FindFirstChild("Framework")
    if fw then
        local client = fw:FindFirstChild("Client")
        if client then
            local netModule = client:FindFirstChild("Network")
            if netModule then
                local success, result = pcall(function()
                    return require(netModule)
                end)
                if success and type(result) == "table" then
                    Network = result
                    uiLog("Framework Client Network successfully loaded!")
                else
                    uiLog("Framework found, but require failed: " .. tostring(result))
                end
            end
        end
    end
    
    if not Network then
        uiLog("Standard framework require failed. Auto-resolving network events...")
        -- Fallback: Listen to remote firings and build map
        local networkFolder = ReplicatedStorage:FindFirstChild("Network")
        if networkFolder then
            for _, child in ipairs(networkFolder:GetChildren()) do
                if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                    -- Store index reference
                    RemoteMapping[child.Name] = child
                end
            end
            uiLog("Resolved " .. tostring(#networkFolder:GetChildren()) .. " network remotes.")
        end
    end
end)

-- Safe remote trigger wrapper
local function fireServer(eventName, ...)
    if Network then
        local success, err = pcall(function()
            if Network.Fire then
                Network.Fire(eventName, ...)
            elseif Network.fire then
                Network.fire(eventName, ...)
            end
        end)
        if success then return true end
    end
    
    -- Fallback: If we have mapped a remote or we hook event
    local rem = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild(eventName)
    if rem and rem:IsA("RemoteEvent") then
        rem:FireServer(...)
        return true
    end
    return false
end

local function invokeServer(eventName, ...)
    if Network then
        local success, result = pcall(function()
            if Network.Invoke then
                return Network.Invoke(eventName, ...)
            elseif Network.invoke then
                return Network.invoke(eventName, ...)
            end
        end)
        if success then return result end
    end
    
    local rem = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild(eventName)
    if rem and rem:IsA("RemoteFunction") then
        return rem:InvokeServer(...)
    end
    return nil
end

-- =============================================================================
-- BUILT-IN REMOTE HOOK (SPY) FOR IN-GAME DETECTION
-- =============================================================================
task.spawn(function()
    local success, err = pcall(function()
        local mt = getrawmetatable(game)
        if mt and makewriteable then
            makewriteable(mt)
            local oldNamecall = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                if self.ClassName == "RemoteEvent" and (method == "FireServer" or method == "fireServer") then
                    uiLog("RemoteEvent fired: " .. self.Name .. " (" .. self:GetFullName() .. ") with " .. #args .. " args")
                elseif self.ClassName == "RemoteFunction" and (method == "InvokeServer" or method == "invokeServer") then
                    uiLog("RemoteFunction invoked: " .. self.Name .. " (" .. self:GetFullName() .. ") with " .. #args .. " args")
                end
                return oldNamecall(self, ...)
            end)
            uiLog("In-game Remote Hook (Spy) successfully activated!")
        else
            uiLog("Custom exploit metatable functions not supported in this client. Using standard logs.")
        end
    end)
    if not success then
        uiLog("Metatable hook initialization skipped (standard client context).")
    end
end)

-- =============================================================================
-- MAIN INTERFACE CONSTRUCTION
-- =============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Inertia_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = TargetParent

-- Main Frame Container
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
local Dragging, DragInput, DragStart, StartPosition
local function UpdateDrag(input)
    local delta = input.Position - DragStart
    MainFrame.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        UpdateDrag(input)
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

local SidebarPatch = Instance.new("Frame")
SidebarPatch.Name = "SidebarPatch"
SidebarPatch.Size = UDim2.new(0, 10, 1, 0)
SidebarPatch.Position = UDim2.new(1, -10, 0, 0)
SidebarPatch.BackgroundColor3 = Theme.SidebarBg
SidebarPatch.BorderSizePixel = 0
SidebarPatch.ZIndex = 0
SidebarPatch.Parent = Sidebar

-- Logo
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

-- Navigation List
local NavScroll = Instance.new("ScrollingFrame")
NavScroll.Name = "NavScroll"
NavScroll.Size = UDim2.new(1, 0, 1, -130)
NavScroll.Position = UDim2.new(0, 0, 0, 60)
NavScroll.BackgroundTransparency = 1
NavScroll.BorderSizePixel = 0
NavScroll.ScrollBarThickness = 0
NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
NavScroll.Parent = Sidebar

local UIList_Nav = Instance.new("UIListLayout")
UIList_Nav.SortOrder = Enum.SortOrder.LayoutOrder
UIList_Nav.Padding = UDim.new(0, 4)
UIList_Nav.Parent = NavScroll

local UIPadding_Nav = Instance.new("UIPadding")
UIPadding_Nav.PaddingLeft = UDim.new(0, 12)
UIPadding_Nav.PaddingRight = UDim.new(0, 12)
UIPadding_Nav.Parent = NavScroll

-- Bottom Profile Card
local ProfileCard = Instance.new("Frame")
ProfileCard.Name = "ProfileCard"
ProfileCard.Size = UDim2.new(1, -24, 0, 60)
ProfileCard.Position = UDim2.new(0, 12, 1, -70)
ProfileCard.BackgroundTransparency = 1
ProfileCard.Parent = Sidebar

local AvatarFrame = Instance.new("ImageLabel")
AvatarFrame.Name = "AvatarFrame"
AvatarFrame.Size = UDim2.new(0, 40, 0, 40)
AvatarFrame.Position = UDim2.new(0, 8, 0.5, -20)
AvatarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
AvatarFrame.BorderSizePixel = 0
AvatarFrame.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=150&height=150&format=png"
AvatarFrame.Parent = ProfileCard

local UICorner_Avatar = Instance.new("UICorner")
UICorner_Avatar.CornerRadius = UDim.new(0, 20)
UICorner_Avatar.Parent = AvatarFrame

local ProfileInfo = Instance.new("Frame")
ProfileInfo.Name = "ProfileInfo"
ProfileInfo.Size = UDim2.new(1, -56, 1, 0)
ProfileInfo.Position = UDim2.new(0, 56, 0, 0)
ProfileInfo.BackgroundTransparency = 1
ProfileInfo.Parent = ProfileCard

local ProfileName = Instance.new("TextLabel")
ProfileName.Name = "ProfileName"
ProfileName.Size = UDim2.new(1, 0, 0.5, 0)
ProfileName.Position = UDim2.new(0, 0, 0.15, 0)
ProfileName.BackgroundTransparency = 1
ProfileName.Text = LocalPlayer.DisplayName
ProfileName.Font = Theme.FontBold
ProfileName.TextSize = 13
ProfileName.TextColor3 = Theme.TextColor
ProfileName.TextXAlignment = Enum.TextXAlignment.Left
ProfileName.Parent = ProfileName.Parent and ProfileInfo

local ProfileUsername = Instance.new("TextLabel")
ProfileUsername.Name = "ProfileUsername"
ProfileUsername.Size = UDim2.new(1, 0, 0.5, 0)
ProfileUsername.Position = UDim2.new(0, 0, 0.45, 0)
ProfileUsername.BackgroundTransparency = 1
ProfileUsername.Text = "@" .. LocalPlayer.Name
ProfileUsername.Font = Theme.FontMain
ProfileUsername.TextSize = 11
ProfileUsername.TextColor3 = Theme.MutedTextColor
ProfileUsername.TextXAlignment = Enum.TextXAlignment.Left
ProfileUsername.Parent = ProfileInfo

-- Content Panel
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -210, 1, 0)
ContentArea.Position = UDim2.new(0, 210, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Pages = {}
local function CreatePage(name)
    local PageFrame = Instance.new("ScrollingFrame")
    PageFrame.Name = name .. "_Page"
    PageFrame.Size = UDim2.new(1, 0, 1, 0)
    PageFrame.BackgroundTransparency = 1
    PageFrame.BorderSizePixel = 0
    PageFrame.ScrollBarThickness = 4
    PageFrame.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 55)
    PageFrame.Visible = false
    PageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    PageFrame.Parent = ContentArea

    local UIList_Page = Instance.new("UIListLayout")
    UIList_Page.SortOrder = Enum.SortOrder.LayoutOrder
    UIList_Page.Padding = UDim.new(0, 12)
    UIList_Page.Parent = PageFrame

    local UIPadding_Page = Instance.new("UIPadding")
    UIPadding_Page.PaddingLeft = UDim.new(0, 30)
    UIPadding_Page.PaddingRight = UDim.new(0, 30)
    UIPadding_Page.PaddingTop = UDim.new(0, 24)
    UIPadding_Page.PaddingBottom = UDim.new(0, 24)
    UIPadding_Page.Parent = PageFrame
    
    UIList_Page:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        PageFrame.CanvasSize = UDim2.new(0, 0, 0, UIList_Page.AbsoluteContentSize.Y + 40)
    end)

    Pages[name] = PageFrame
    return PageFrame
end

local function SwitchTab(name)
    for pageName, pageFrame in pairs(Pages) do
        pageFrame.Visible = (pageName == name)
    end
end

-- Navigation Sidebar Items
local function CreateCategoryHeader(text)
    local Label = Instance.new("TextLabel")
    Label.Name = text .. "_Header"
    Label.Size = UDim2.new(1, 0, 0, 28)
    Label.BackgroundTransparency = 1
    Label.Text = string.upper(text)
    Label.Font = Theme.FontBold
    Label.TextSize = 11
    Label.TextColor3 = Theme.MutedTextColor
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = NavScroll
end

local function CreateTabButton(text, iconAssetId, pageName)
    local Button = Instance.new("TextButton")
    Button.Name = text .. "_Btn"
    Button.Size = UDim2.new(1, 0, 0, 36)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = NavScroll

    local UICorner_Btn = Instance.new("UICorner")
    UICorner_Btn.CornerRadius = UDim.new(0, 6)
    UICorner_Btn.Parent = Button

    local SelectionIndicator = Instance.new("Frame")
    SelectionIndicator.Name = "Indicator"
    SelectionIndicator.Size = UDim2.new(0, 3, 0, 16)
    SelectionIndicator.Position = UDim2.new(0, 0, 0.5, -8)
    SelectionIndicator.BackgroundColor3 = Theme.AccentColor
    SelectionIndicator.BorderSizePixel = 0
    SelectionIndicator.BackgroundTransparency = 1
    SelectionIndicator.Parent = Button

    local BtnIcon = Instance.new("ImageLabel")
    BtnIcon.Name = "Icon"
    BtnIcon.Size = UDim2.new(0, 18, 0, 18)
    BtnIcon.Position = UDim2.new(0, 12, 0.5, -9)
    BtnIcon.BackgroundTransparency = 1
    BtnIcon.Image = iconAssetId
    BtnIcon.ImageColor3 = Theme.MutedTextColor
    BtnIcon.Parent = Button

    local BtnText = Instance.new("TextLabel")
    BtnText.Name = "Text"
    BtnText.Size = UDim2.new(1, -44, 1, 0)
    BtnText.Position = UDim2.new(0, 38, 0, 0)
    BtnText.BackgroundTransparency = 1
    BtnText.Text = text
    BtnText.Font = Theme.FontMain
    BtnText.TextSize = 13
    BtnText.TextColor3 = Theme.MutedTextColor
    BtnText.TextXAlignment = Enum.TextXAlignment.Left
    BtnText.Parent = Button

    local function updateVisuals(active)
        local targetColor = active and Theme.TextColor or Theme.MutedTextColor
        local targetIconColor = active and Theme.AccentColor or Theme.MutedTextColor
        local targetIndTrans = active and 0 or 1
        local targetBgTrans = active and 0.92 or 1

        TweenService:Create(BtnText, TweenInfo.new(0.2), {TextColor3 = targetColor}):Play()
        TweenService:Create(BtnIcon, TweenInfo.new(0.2), {ImageColor3 = targetIconColor}):Play()
        TweenService:Create(SelectionIndicator, TweenInfo.new(0.2), {BackgroundTransparency = targetIndTrans}):Play()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundTransparency = targetBgTrans, BackgroundColor3 = Theme.TextColor}):Play()
    end

    Button.MouseButton1Click:Connect(function()
        for _, otherBtn in ipairs(NavScroll:GetChildren()) do
            if otherBtn:IsA("TextButton") and otherBtn ~= Button then
                otherBtn.Indicator.BackgroundTransparency = 1
                otherBtn.Text.TextColor3 = Theme.MutedTextColor
                otherBtn.Icon.ImageColor3 = Theme.MutedTextColor
                otherBtn.BackgroundTransparency = 1
            end
        end
        updateVisuals(true)
        SwitchTab(pageName)
    end)

    Button.MouseEnter:Connect(function()
        if SelectionIndicator.BackgroundTransparency == 1 then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundTransparency = 0.95, BackgroundColor3 = Theme.TextColor}):Play()
            TweenService:Create(BtnText, TweenInfo.new(0.2), {TextColor3 = Theme.TextColor}):Play()
        end
    end)

    Button.MouseLeave:Connect(function()
        if SelectionIndicator.BackgroundTransparency == 1 then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(BtnText, TweenInfo.new(0.2), {TextColor3 = Theme.MutedTextColor}):Play()
        end
    end)
end

-- Warning Card Banner
local function CreateWarningBox(parent, text)
    local Frame = Instance.new("Frame")
    Frame.Name = "WarningBox"
    Frame.Size = UDim2.new(1, 0, 0, 42)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 20, 15)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Thickness = 1
    UIStroke.Color = Color3.fromRGB(180, 110, 20)
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Frame

    local Icon = Instance.new("ImageLabel")
    Icon.Name = "Icon"
    Icon.Size = UDim2.new(0, 16, 0, 16)
    Icon.Position = UDim2.new(0, 12, 0.5, -8)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://6023426926"
    Icon.ImageColor3 = Color3.fromRGB(240, 160, 40)
    Icon.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -44, 1, 0)
    Label.Position = UDim2.new(0, 36, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Theme.FontMain
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(240, 180, 100)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
end

local function CreateSectionTitle(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Name = text .. "_Section"
    Label.Size = UDim2.new(1, 0, 0, 30)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Theme.FontBold
    Label.TextSize = 14
    Label.TextColor3 = Theme.TextColor
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = parent
end

-- Toggle Button
local function CreateToggle(parent, text, defaultState, callback)
    local Frame = Instance.new("Frame")
    Frame.Name = text .. "_Toggle"
    Frame.Size = UDim2.new(1, 0, 0, 44)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Theme.FontMain
    Label.TextSize = 13
    Label.TextColor3 = Theme.TextColor
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Switch = Instance.new("TextButton")
    Switch.Name = "Switch"
    Switch.Size = UDim2.new(0, 44, 0, 24)
    Switch.Position = UDim2.new(1, -44, 0.5, -12)
    Switch.BackgroundColor3 = defaultState and Theme.ToggleOn or Theme.ToggleOff
    Switch.BorderSizePixel = 0
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = Frame

    local UICorner_Switch = Instance.new("UICorner")
    UICorner_Switch.CornerRadius = UDim.new(1, 0)
    UICorner_Switch.Parent = Switch

    local Knob = Instance.new("Frame")
    Knob.Name = "Knob"
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new(0, defaultState and 23 or 3, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent = Switch

    local UICorner_Knob = Instance.new("UICorner")
    UICorner_Knob.CornerRadius = UDim.new(1, 0)
    UICorner_Knob.Parent = Knob

    local state = defaultState
    local debounce = false
    Switch.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true
        state = not state
        
        local targetPos = state and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local targetColor = state and Theme.ToggleOn or Theme.ToggleOff
        
        TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        
        task.spawn(function()
            callback(state)
        end)
        
        task.wait(0.05)
        debounce = false
    end)
end

-- Slider Input
local function CreateSlider(parent, text, min, max, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Name = text .. "_Slider"
    Frame.Size = UDim2.new(1, 0, 0, 56)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.7, 0, 0, 24)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Theme.FontMain
    Label.TextSize = 13
    Label.TextColor3 = Theme.TextColor
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "Value"
    ValueLabel.Size = UDim2.new(0.3, 0, 0, 24)
    ValueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(defaultVal)
    ValueLabel.Font = Theme.FontBold
    ValueLabel.TextSize = 13
    ValueLabel.TextColor3 = Theme.AccentColor
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Frame

    local Track = Instance.new("TextButton")
    Track.Name = "Track"
    Track.Size = UDim2.new(1, 0, 0, 6)
    Track.Position = UDim2.new(0, 0, 0, 36)
    Track.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Track.BorderSizePixel = 0
    Track.Text = ""
    Track.AutoButtonColor = false
    Track.Parent = Frame

    local UICorner_Track = Instance.new("UICorner")
    UICorner_Track.CornerRadius = UDim.new(0, 3)
    UICorner_Track.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    local fillPercent = (defaultVal - min) / (max - min)
    Fill.Size = UDim2.new(fillPercent, 0, 1, 0)
    Fill.BackgroundColor3 = Theme.AccentColor
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local UICorner_Fill = Instance.new("UICorner")
    UICorner_Fill.CornerRadius = UDim.new(0, 3)
    UICorner_Fill.Parent = Fill

    local Handle = Instance.new("Frame")
    Handle.Name = "Handle"
    Handle.Size = UDim2.new(0, 14, 0, 14)
    Handle.Position = UDim2.new(fillPercent, -7, 0.5, -7)
    Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handle.BorderSizePixel = 0
    Handle.Parent = Track

    local UICorner_Handle = Instance.new("UICorner")
    UICorner_Handle.CornerRadius = UDim.new(1, 0)
    UICorner_Handle.Parent = Handle

    local function updateValue(input)
        local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos + 0.5)
        
        ValueLabel.Text = tostring(value)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        Handle.Position = UDim2.new(pos, -7, 0.5, -7)
        
        callback(value)
    end

    local dragging = false
    Handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateValue(input)
            dragging = true
        end
    end)
end

-- =============================================================================
-- INTERFACE POPULATION
-- =============================================================================
CreateCategoryHeader("Main")
CreateTabButton("Restaurant", "rbxassetid://6023426915", "Restaurant")
CreateTabButton("Ingredients", "rbxassetid://6022668955", "Ingredients")
CreateTabButton("Quests", "rbxassetid://6026568240", "Quests")
CreateTabButton("Webhook", "rbxassetid://6034287525", "Webhook")

CreateCategoryHeader("Settings")
CreateTabButton("UI", "rbxassetid://6031289138", "Settings")

local RestaurantPage = CreatePage("Restaurant")
local IngredientsPage = CreatePage("Ingredients")
local QuestsPage = CreatePage("Quests")
local WebhookPage = CreatePage("Webhook")
local SettingsPage = CreatePage("Settings")

-- "Restaurant" Tab Layout
CreateSectionTitle(RestaurantPage, "Important")
CreateWarningBox(RestaurantPage, "If Something Doesnt Work Change Your Language To English in Settings! 👆")

CreateToggle(RestaurantPage, "Auto Assign Seat", false, function(state)
    AutoSettings.AutoAssignSeat = state
    uiLog("Auto Assign Seat toggle set to: " .. tostring(state))
end)

CreateToggle(RestaurantPage, "Auto Take Orders", false, function(state)
    AutoSettings.AutoTakeOrders = state
    uiLog("Auto Take Orders toggle set to: " .. tostring(state))
end)

CreateToggle(RestaurantPage, "Auto Serve", false, function(state)
    AutoSettings.AutoServe = state
    uiLog("Auto Serve toggle set to: " .. tostring(state))
end)

CreateToggle(RestaurantPage, "Auto Order Stand", false, function(state)
    AutoSettings.AutoOrderStand = state
    uiLog("Auto Order Stand toggle set to: " .. tostring(state))
end)

CreateToggle(RestaurantPage, "Auto Stove", false, function(state)
    AutoSettings.AutoStove = state
    uiLog("Auto Stove toggle set to: " .. tostring(state))
end)

CreateToggle(RestaurantPage, "Auto Clean Dish", false, function(state)
    AutoSettings.AutoCleanDish = state
    uiLog("Auto Clean Dish toggle set to: " .. tostring(state))
end)

CreateToggle(RestaurantPage, "Auto Claim Cash", false, function(state)
    AutoSettings.AutoClaimCash = state
    uiLog("Auto Claim Cash toggle set to: " .. tostring(state))
end)

CreateSlider(RestaurantPage, "Claim Cash Interval (s)", 5, 60, 15, function(val)
    AutoSettings.ClaimCashInterval = val
    uiLog("Cash collection interval set to " .. tostring(val) .. "s")
end)

-- Status Console Tab (Inside UI Settings / Debug Panel)
CreateSectionTitle(SettingsPage, "Inertia Console Output")
local ConsoleContainer = Instance.new("Frame")
ConsoleContainer.Name = "ConsoleContainer"
ConsoleContainer.Size = UDim2.new(1, 0, 0, 260)
ConsoleContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
ConsoleContainer.BorderSizePixel = 0
ConsoleContainer.Parent = SettingsPage

local UICorner_Console = Instance.new("UICorner")
UICorner_Console.CornerRadius = UDim.new(0, 6)
UICorner_Console.Parent = ConsoleContainer

local UIStroke_Console = Instance.new("UIStroke")
UIStroke_Console.Thickness = 1
UIStroke_Console.Color = Theme.BorderColor
UIStroke_Console.Parent = ConsoleContainer

local ConsoleScroll = Instance.new("ScrollingFrame")
ConsoleScroll.Name = "ConsoleScroll"
ConsoleScroll.Size = UDim2.new(1, -24, 1, -24)
ConsoleScroll.Position = UDim2.new(0, 12, 0, 12)
ConsoleScroll.BackgroundTransparency = 1
ConsoleScroll.BorderSizePixel = 0
ConsoleScroll.ScrollBarThickness = 3
ConsoleScroll.Parent = ConsoleContainer

local ConsoleText = Instance.new("TextLabel")
ConsoleText.Name = "ConsoleText"
ConsoleText.Size = UDim2.new(1, 0, 1, 0)
ConsoleText.BackgroundTransparency = 1
ConsoleText.Text = "Inertia Console Initialized..."
ConsoleText.Font = Enum.Font.Code
ConsoleText.TextSize = 11
ConsoleText.TextColor3 = Theme.AccentColor
ConsoleText.TextXAlignment = Enum.TextXAlignment.Left
ConsoleText.TextYAlignment = Enum.TextYAlignment.Top
ConsoleText.TextWrapped = true
ConsoleText.Parent = ConsoleScroll

-- Default Tab Styling Initialization
SwitchTab("Restaurant")
NavScroll.Restaurant_Btn.Indicator.BackgroundTransparency = 0
NavScroll.Restaurant_Btn.Text.TextColor3 = Theme.TextColor
NavScroll.Restaurant_Btn.Icon.ImageColor3 = Theme.AccentColor
NavScroll.Restaurant_Btn.BackgroundTransparency = 0.92

-- =============================================================================
-- GAME MODEL RESOLVER & AUTOMATION CORE
-- =============================================================================
local MyRestaurant = nil

local function getMyRestaurant()
    if MyRestaurant and MyRestaurant.Parent then
        return MyRestaurant
    end
    
    local restaurants = workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Restaurants")
    if restaurants then
        -- Find a restaurant belonging to the local player.
        -- Typically there is an Owner child with Value matching LocalPlayer, or we find it by Player ID
        for _, r in ipairs(restaurants:GetChildren()) do
            local ownerVal = r:FindFirstChild("Owner") or r:FindFirstChild("Player")
            if ownerVal and ownerVal.Value == LocalPlayer then
                MyRestaurant = r
                return r
            end
        end
        
        -- Fallback: Use the restaurant with Id attribute or matching player index
        -- In this place layout, we can find the closest or default to the first folder
        local defaultRest = restaurants:FindFirstChild("Restaurant_1") or restaurants:GetChildren()[1]
        MyRestaurant = defaultRest
        return defaultRest
    end
    return nil
end

-- 1. Auto Seat Customers
task.spawn(function()
    while task.wait(1.5) do
        if not AutoSettings.AutoAssignSeat then continue end
        local r = getMyRestaurant()
        if not r then continue end
        
        local entities = r:FindFirstChild("Entities")
        if not entities then continue end
        
        -- Find customers waiting
        local customers = {}
        for _, child in ipairs(entities:GetChildren()) do
            if child:IsA("Model") and string.find(child.Name, "Customer") then
                -- Check if not already seated
                local isSeated = false
                local hum = child:FindFirstChildOfClass("Humanoid")
                if hum and hum.SeatPart then
                    isSeated = true
                end
                if not isSeated then
                    table.insert(customers, child)
                end
            end
        end
        
        if #customers > 0 then
            -- Find empty chairs
            local emptyChairs = {}
            for _, child in ipairs(entities:GetChildren()) do
                if string.find(child.Name, "Chair") then
                    local seat = child:FindFirstChildOfClass("Seat")
                    if seat and not seat.Occupant then
                        table.insert(emptyChairs, child)
                    end
                end
            end
            
            -- Pair them
            for i = 1, math.min(#customers, #emptyChairs) do
                local customer = customers[i]
                local chair = emptyChairs[i]
                
                local customerId = customer:GetAttribute("EntityId")
                local chairId = chair:GetAttribute("EntityId")
                
                if customerId and chairId then
                    -- Firing the seating event
                    local success = fireServer("SeatCustomer", customerId, chairId)
                    if success then
                        uiLog("Seated Customer " .. tostring(customerId) .. " to Chair " .. tostring(chairId))
                    end
                end
            end
        end
    end
end)

-- 2. Auto Take Orders
task.spawn(function()
    while task.wait(1) do
        if not AutoSettings.AutoTakeOrders then continue end
        local r = getMyRestaurant()
        if not r then continue end
        
        local entities = r:FindFirstChild("Entities")
        if not entities then continue end
        
        for _, child in ipairs(entities:GetChildren()) do
            if child:IsA("Model") and string.find(child.Name, "Customer") then
                -- Check if customer is ready to order
                local customerId = child:GetAttribute("EntityId")
                if customerId then
                    -- Usually the game uses a specific RemoteEvent to take order
                    fireServer("TakeOrder", customerId)
                end
            end
        end
    end
end)

-- 3. Auto Stove (Cooking)
task.spawn(function()
    while task.wait(1) do
        if not AutoSettings.AutoStove then continue end
        local r = getMyRestaurant()
        if not r then continue end
        
        local entities = r:FindFirstChild("Entities")
        if not entities then continue end
        
        for _, child in ipairs(entities:GetChildren()) do
            if string.find(child.Name, "Stove") then
                local stoveId = child:GetAttribute("EntityId")
                if stoveId then
                    -- Trigger stove to cook food
                    fireServer("CookFood", stoveId)
                end
            end
        end
    end
end)

-- 4. Auto Serve Customers
task.spawn(function()
    while task.wait(1) do
        if not AutoSettings.AutoServe then continue end
        local r = getMyRestaurant()
        if not r then continue end
        
        local entities = r:FindFirstChild("Entities")
        if not entities then continue end
        
        -- Look for food ready on stoves or order stands
        -- We fire serve events to customers
        for _, child in ipairs(entities:GetChildren()) do
            if child:IsA("Model") and string.find(child.Name, "Customer") then
                local customerId = child:GetAttribute("EntityId")
                if customerId then
                    fireServer("ServeFood", customerId)
                end
            end
        end
    end
end)

-- 5. Auto Clean Dirty Dishes
task.spawn(function()
    while task.wait(1.5) do
        if not AutoSettings.AutoCleanDish then continue end
        local r = getMyRestaurant()
        if not r then continue end
        
        local entities = r:FindFirstChild("Entities")
        if not entities then continue end
        
        -- Search for dishes on tables or tables that need cleaning
        for _, child in ipairs(entities:GetChildren()) do
            if string.find(child.Name, "Table") then
                local tableId = child:GetAttribute("EntityId")
                if tableId then
                    fireServer("CleanTable", tableId)
                end
            end
        end
    end
end)

-- 6. Auto Claim Cash
task.spawn(function()
    while true do
        task.wait(AutoSettings.ClaimCashInterval)
        if not AutoSettings.AutoClaimCash then continue end
        local r = getMyRestaurant()
        if not r then continue end
        
        local entities = r:FindFirstChild("Entities")
        if not entities then continue end
        
        -- Claim cash from all registers
        for _, child in ipairs(entities:GetChildren()) do
            if string.find(child.Name, "Register") then
                local registerId = child:GetAttribute("EntityId")
                if registerId then
                    fireServer("ClaimCash", registerId)
                end
            end
        end
    end
end)

uiLog("Inertia UI and Client Automation successfully initialized!")
