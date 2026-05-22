-- Auto Farm Script for Restaurant Game (MCP Server Model)
-- Features: Auto check table, cook, eat, get money with UI
-- Continuous farming without breaks

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Script State
local isRunning = false
local autoFarmConnection = nil
local speedMultiplier = 1.0
local totalMoney = 0
local totalCycles = 0

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Auto Farm Script"
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Status: Stopped"
statusLabel.BorderSizePixel = 0
statusLabel.Parent = mainFrame

-- Start Button
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0, 130, 0, 35)
startButton.Position = UDim2.new(0, 10, 0, 90)
startButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 14
startButton.Font = Enum.Font.GothamBold
startButton.Text = "START"
startButton.BorderSizePixel = 0
startButton.Parent = mainFrame

-- Stop Button
local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0, 130, 0, 35)
stopButton.Position = UDim2.new(0, 160, 0, 90)
stopButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.Text = "STOP"
stopButton.BorderSizePixel = 0
stopButton.Parent = mainFrame

-- Info Label
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "Info"
infoLabel.Size = UDim2.new(1, -20, 0, 50)
infoLabel.Position = UDim2.new(0, 10, 0, 135)
infoLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.Text = "Cycles: 0\nForce → Cook → Eat → Money"
infoLabel.TextWrapped = true
infoLabel.BorderSizePixel = 0
infoLabel.Parent = mainFrame

-- Expand main frame to accommodate more content
mainFrame.Size = UDim2.new(0, 300, 0, 250)

-- Speed Control Label
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(0, 80, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 200)
speedLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.Gotham
speedLabel.Text = "Speed:"
speedLabel.BorderSizePixel = 0
speedLabel.Parent = mainFrame

-- Speed Slider (simplified as buttons)
local speedDownButton = Instance.new("TextButton")
speedDownButton.Name = "SpeedDown"
speedDownButton.Size = UDim2.new(0, 30, 0, 20)
speedDownButton.Position = UDim2.new(0, 95, 0, 200)
speedDownButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
speedDownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDownButton.TextSize = 12
speedDownButton.Font = Enum.Font.GothamBold
speedDownButton.Text = "-"
speedDownButton.BorderSizePixel = 0
speedDownButton.Parent = mainFrame

local speedValueLabel = Instance.new("TextLabel")
speedValueLabel.Name = "SpeedValue"
speedValueLabel.Size = UDim2.new(0, 40, 0, 20)
speedValueLabel.Position = UDim2.new(0, 130, 0, 200)
speedValueLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedValueLabel.TextSize = 12
speedValueLabel.Font = Enum.Font.GothamBold
speedValueLabel.Text = "1.0x"
speedValueLabel.BorderSizePixel = 0
speedValueLabel.Parent = mainFrame

local speedUpButton = Instance.new("TextButton")
speedUpButton.Name = "SpeedUp"
speedUpButton.Size = UDim2.new(0, 30, 0, 20)
speedUpButton.Position = UDim2.new(0, 175, 0, 200)
speedUpButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
speedUpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedUpButton.TextSize = 12
speedUpButton.Font = Enum.Font.GothamBold
speedUpButton.Text = "+"
speedUpButton.BorderSizePixel = 0
speedUpButton.Parent = mainFrame

-- Speed control connections
speedDownButton.MouseButton1Click:Connect(function()
	speedMultiplier = math.max(0.1, speedMultiplier - 0.1)
	speedValueLabel.Text = string.format("%.1f", speedMultiplier) .. "x"
end)

speedUpButton.MouseButton1Click:Connect(function()
	speedMultiplier = math.min(5.0, speedMultiplier + 0.1)
	speedValueLabel.Text = string.format("%.1f", speedMultiplier) .. "x"
end)

-- Helper function to interact with GUI buttons
local function clickButton(button)
	if not button then return false end
	
	-- Try multiple methods to click button
	if button:IsA("GuiButton") or button:IsA("TextButton") then
		local event = button.MouseButton1Click
		if event then
			event:Fire()
			return true
		end
	end
	
	-- Try firing signal
	if button:FindFirstChild("ClickDetector") then
		button.ClickDetector:Fire()
		return true
	end
	
	return false
end

-- Helper function to move character to position
local function moveToPosition(targetCFrame, offset)
	if not player.Character then return false end
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		offset = offset or Vector3.new(0, 3, 0)
		humanoidRootPart.CFrame = targetCFrame + offset
		return true
	end
	return false
end

-- Helper function to find interactive objects
local function findInteractiveObject(searchNames)
	-- Search in workspace first
	for _, name in ipairs(searchNames) do
		local obj = workspace:FindFirstChild(name)
		if obj then return obj end
		
		-- Search descendants
		obj = workspace:FindFirstDescendant(name)
		if obj then return obj end
	end
	
	-- Search in GUI
	for _, name in ipairs(searchNames) do
		local obj = playerGui:FindFirstDescendant(name)
		if obj then return obj end
	end
	
	return nil
end

-- Helper function to find button by multiple names (enhanced)
local function findButton(names)
	for _, name in ipairs(names) do
		-- Search in GUI first
		local button = playerGui:FindFirstDescendant(name)
		if button then return button end
		
		-- Search in workspace
		button = workspace:FindFirstChild(name)
		if button then return button end
		
		-- Search descendants in workspace
		button = workspace:FindFirstDescendant(name)
		if button then return button end
	end
	return nil
end

-- Helper function to force customer to spawn/come
local function forceCustomer()
	-- Try to find customer spawn button or trigger
	local customerNames = {"Customer", "SpawnCustomer", "CallCustomer", "CustomerSpawn", "Guest", "SpawnGuest"}
	local customerButton = findButton(customerNames)
	
	if customerButton then
		clickButton(customerButton)
		return true
	end
	
	-- Try to find customer NPCs and force them to interact
	local customers = workspace:FindFirstChild("Customers") or workspace:FindFirstChild("NPCs")
	if customers then
		for _, customer in ipairs(customers:GetChildren()) do
			if customer:IsA("Model") and customer:FindFirstChild("Humanoid") then
				-- Force customer to move to table
				local tableNames = {"Table", "Chair", "Seat", "Stool"}
				local tableObj = findInteractiveObject(tableNames)
				if tableObj and customer:FindFirstChild("HumanoidRootPart") then
					customer.HumanoidRootPart.CFrame = tableObj.CFrame + Vector3.new(2, 0, 0)
				end
			end
		end
		return true
	end
	
	return false
end

-- Auto Farm Function (Continuous, No Breaks)
local function autoFarm()
	totalCycles = 0
	
	while isRunning do
		totalCycles = totalCycles + 1
		
		-- Step 0: Force customer to spawn/come
		forceCustomer()
		task.wait(0.3 / speedMultiplier)
		
		-- Step 1: Check and interact with table/chair
		local tableNames = {"Table", "Chair", "Seat", "Stool", "CheckTable", "SitChair"}
		local tableObj = findInteractiveObject(tableNames)
		
		if tableObj then
			if tableObj:IsA("BasePart") then
				moveToPosition(tableObj.CFrame)
				task.wait(0.3 / speedMultiplier)
			end
			clickButton(tableObj)
			task.wait(0.2 / speedMultiplier)
		end
		
		-- Step 2: Cook (Instant Cook)
		local cookNames = {"Cook", "CookButton", "Cooking", "Cook Food", "InstantCook", "PrepareFood"}
		local cookButton = findButton(cookNames)
		if cookButton then
			if cookButton:IsA("BasePart") then
				moveToPosition(cookButton.CFrame)
				task.wait(0.2 / speedMultiplier)
			end
			clickButton(cookButton)
			task.wait(0.5 / speedMultiplier)
		end
		
		-- Step 3: Eat
		local eatNames = {"Eat", "EatButton", "Eating", "Eat Food", "EatMeal", "Consume"}
		local eatButton = findButton(eatNames)
		if eatButton then
			if eatButton:IsA("BasePart") then
				moveToPosition(eatButton.CFrame)
				task.wait(0.2 / speedMultiplier)
			end
			clickButton(eatButton)
			task.wait(0.5 / speedMultiplier)
		end
		
		-- Step 4: Get Money/Payment
		local moneyNames = {"Money", "MoneyButton", "Pay", "PayButton", "Payment", "Collect", "Reward", "GetMoney", "Cashier"}
		local moneyButton = findButton(moneyNames)
		if moneyButton then
			if moneyButton:IsA("BasePart") then
				moveToPosition(moneyButton.CFrame)
				task.wait(0.2 / speedMultiplier)
			end
			clickButton(moneyButton)
			task.wait(0.5 / speedMultiplier)
		end
		
		-- Update UI with cycle count (continuous, no breaks)
		infoLabel.Text = "Cycles: " .. totalCycles .. "\nSpeed: " .. string.format("%.1f", speedMultiplier) .. "x\nForce → Cook → Eat → Money"
		
		-- Minimal delay for continuous farming
		task.wait(0.05 / speedMultiplier)
	end
end

-- Start Button Click
startButton.MouseButton1Click:Connect(function()
	if not isRunning then
		isRunning = true
		statusLabel.Text = "Status: Running ✓"
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		autoFarmConnection = task.spawn(autoFarm)
	end
end)

-- Stop Button Click
stopButton.MouseButton1Click:Connect(function()
	if isRunning then
		isRunning = false
		statusLabel.Text = "Status: Stopped"
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	end
end)

-- Keyboard Shortcut (F6 to toggle)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.F6 then
		if isRunning then
			isRunning = false
			statusLabel.Text = "Status: Stopped"
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			isRunning = true
			statusLabel.Text = "Status: Running ✓"
			statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
			task.spawn(autoFarm)
		end
	end
end)

-- MCP Server Model Integration
local mcpServerActive = true
local function mcpServerHeartbeat()
	while mcpServerActive do
		-- Send status updates to MCP server
		if isRunning then
			-- Log farming status
			if totalCycles % 10 == 0 then
				print("[MCP] Farming Status - Cycles: " .. totalCycles .. ", Speed: " .. string.format("%.1f", speedMultiplier) .. "x")
			end
		end
		task.wait(1)
	end
end

-- Start MCP heartbeat
task.spawn(mcpServerHeartbeat)

print("Auto Farm Script Loaded! (MCP Server Model)")
print("Press F6 to toggle or use the UI buttons")
print("Speed Control: Use +/- buttons to adjust farming speed (0.1x - 5.0x)")
print("Continuous farming without breaks - Cycles: " .. totalCycles)
