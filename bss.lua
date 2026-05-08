local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- Xóa UI cũ nếu đã tồn tại
if CoreGui:FindFirstChild("PlanterPredictorUI") then
    CoreGui.PlanterPredictorUI:Destroy()
end

-- === KHỞI TẠO UI CHÍNH ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlanterPredictorUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.BorderSizePixel = 0

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BorderSizePixel = 0

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

-- Fix góc dưới của TitleBar để vuông góc với MainFrame
local TitleBottom = Instance.new("Frame")
TitleBottom.Parent = TitleBar
TitleBottom.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleBottom.Position = UDim2.new(0, 0, 1, -5)
TitleBottom.Size = UDim2.new(1, 0, 0, 5)
TitleBottom.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "🌱 Planter Predictor"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Name = "RefreshBtn"
RefreshBtn.Parent = TitleBar
RefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
RefreshBtn.Position = UDim2.new(1, -70, 0, 4)
RefreshBtn.Size = UDim2.new(0, 60, 0, 22)
RefreshBtn.Font = Enum.Font.GothamSemibold
RefreshBtn.Text = "Refresh"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.TextSize = 12
RefreshBtn.AutoButtonColor = true

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 4)
BtnCorner.Parent = RefreshBtn

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Parent = MainFrame
ScrollFrame.Active = true
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.Position = UDim2.new(0, 10, 0, 40)
ScrollFrame.Size = UDim2.new(1, -20, 0, 150) -- Giới hạn chiều cao phần đang trồng
ScrollFrame.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- === PHẦN FIELD ANALYZER (MỚI) ===
local AnalyzerFrame = Instance.new("Frame")
AnalyzerFrame.Name = "AnalyzerFrame"
AnalyzerFrame.Parent = MainFrame
AnalyzerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
AnalyzerFrame.Position = UDim2.new(0, 10, 0, 200)
AnalyzerFrame.Size = UDim2.new(1, -20, 1, -210)
AnalyzerFrame.BorderSizePixel = 0

local AnalyzerCorner = Instance.new("UICorner")
AnalyzerCorner.CornerRadius = UDim.new(0, 4)
AnalyzerCorner.Parent = AnalyzerFrame

local AnalyzerTitle = Instance.new("TextLabel")
AnalyzerTitle.Parent = AnalyzerFrame
AnalyzerTitle.BackgroundTransparency = 1
AnalyzerTitle.Size = UDim2.new(1, 0, 0, 20)
AnalyzerTitle.Font = Enum.Font.GothamBold
AnalyzerTitle.Text = "🔍 Field Scanner & Best Planters"
AnalyzerTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
AnalyzerTitle.TextSize = 12

local AnalyzerScroll = Instance.new("ScrollingFrame")
AnalyzerScroll.Parent = AnalyzerFrame
AnalyzerScroll.Active = true
AnalyzerScroll.BackgroundTransparency = 1
AnalyzerScroll.BorderSizePixel = 0
AnalyzerScroll.Position = UDim2.new(0, 5, 0, 25)
AnalyzerScroll.Size = UDim2.new(1, -10, 1, -30)
AnalyzerScroll.ScrollBarThickness = 2

local AnalyzerList = Instance.new("UIListLayout")
AnalyzerList.Parent = AnalyzerScroll
AnalyzerList.SortOrder = Enum.SortOrder.LayoutOrder
AnalyzerList.Padding = UDim.new(0, 3)

-- Tính năng Draggable cho UI
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === FUNCTION LẤY DỮ LIỆU PLANTER ===
local function AddPlanterEntry(infoText, isReady)
    local EntryFrame = Instance.new("Frame")
    EntryFrame.Parent = ScrollFrame
    EntryFrame.BackgroundColor3 = isReady and Color3.fromRGB(40, 70, 40) or Color3.fromRGB(45, 45, 50)
    -- Tăng Size lên để hiển thị đủ Text cho Rewards
    EntryFrame.Size = UDim2.new(1, 0, 0, 100)
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 4)
    EntryCorner.Parent = EntryFrame
    
    local TextDisplay = Instance.new("TextLabel")
    TextDisplay.Parent = EntryFrame
    TextDisplay.BackgroundTransparency = 1
    TextDisplay.Position = UDim2.new(0, 5, 0, 5)
    TextDisplay.Size = UDim2.new(1, -10, 1, -10)
    TextDisplay.Font = Enum.Font.Code
    TextDisplay.Text = infoText
    TextDisplay.TextColor3 = Color3.fromRGB(220, 220, 220)
    TextDisplay.TextSize = 12
    TextDisplay.TextXAlignment = Enum.TextXAlignment.Left
    TextDisplay.TextYAlignment = Enum.TextYAlignment.Top
    
    -- Tự động điều chỉnh chiều cao
    TextDisplay.TextWrapped = true
end

local function UpdatePredictor()
    -- Xóa các kết quả cũ
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local success, err = pcall(function()
        local PlanterModule = require(game:GetService("ReplicatedStorage").LocalPlanters)
        local PlanterTypes = require(game:GetService("ReplicatedStorage").PlanterTypes)

        local loadPlanterFunc = PlanterModule.LoadPlanter
        local PlanterTable = debug.getupvalues(loadPlanterFunc)[4]
        
        if not PlanterTable or #PlanterTable == 0 then
            AddPlanterEntry("⚠️ Bạn chưa trồng Planter nào trên sân!", false)
            return
        end

        for _, planter in pairs(PlanterTable) do
            local pTypeInfo = PlanterTypes.Get(planter.Type)
            if pTypeInfo then
                -- Sửa lỗi Unknown Field: Planter object có thể lưu Field dưới tên Terrain, Field, Zone, ZoneName hoặc Model
                local fieldName = planter.Territory or planter.ZoneName or planter.Field or planter.Zone or "Unknown Field"
                local percent = math.floor((planter.GrowthPercent or 0) * 100)
                
                -- Thời gian
                local maxGrowthTime = pTypeInfo.MaxGrowth or 0
                local growthMultiplier = 1
                if pTypeInfo.GrowthMultipliers and pTypeInfo.GrowthMultipliers.Zones and pTypeInfo.GrowthMultipliers.Zones[fieldName] then
                    growthMultiplier = pTypeInfo.GrowthMultipliers.Zones[fieldName]
                end
                
                local realTotalTime = maxGrowthTime / growthMultiplier
                local timeRemainingSeconds = realTotalTime * (1 - (planter.GrowthPercent or 0))
                
                local hrs = math.floor(timeRemainingSeconds / 3600)
                local mins = math.floor((timeRemainingSeconds % 3600) / 60)
                
                local isReady = (percent >= 100)
                local puffChance = (pTypeInfo.PuffshroomChance or 0) * 100
                
                -- Build Text
                local info = string.format("▶ [%s] tại [%s]\n", pTypeInfo.DisplayName or planter.Type, fieldName)
                info = info .. string.format("  ├ Tiến độ: %d%%\n", percent)
                
                if isReady then
                    info = info .. "  ├ Trạng thái: ✅ SẴN SÀNG THU HOẠCH!\n"
                else
                    info = info .. string.format("  ├ Thời gian đầy (Dự kiến): %d giờ %d phút\n", hrs, mins)
                end
                
                if puffChance > 0 then
                    info = info .. string.format("  ├ Tỷ lệ ra Puffshroom: %.1f%%\n", puffChance)
                end
                
                -- Hiển thị phần thưởng cố định (Guaranteed Rewards)
                if pTypeInfo.EnsureGiveOnFull then
                    local rewardsList = ""
                    for item, amount in pairs(pTypeInfo.EnsureGiveOnFull) do
                        rewardsList = rewardsList .. item .. "(x" .. amount .. ") "
                    end
                    if rewardsList ~= "" then
                        info = info .. "  ├ Quà 100% nhận: " .. rewardsList .. "\n"
                    end
                end
                
                if pTypeInfo.NectarMultipliers then
                    local nectars = ""
                    for nectarName, multi in pairs(pTypeInfo.NectarMultipliers) do
                        nectars = nectars .. nectarName .. "(x" .. multi .. ") "
                    end
                    info = info .. "  └ Bonus Nectar: " .. nectars
                else
                    info = info .. "  └ Bonus Nectar: Không có"
                end
                
                -- Nếu height khung không đủ dài cho thêm dòng, ta tăng height lên 100
                AddPlanterEntry(info, isReady)
            end
        end
    end)
    
    if not success then
        AddPlanterEntry("Lỗi lấy dữ liệu Planter: " .. tostring(err), false)
    end
    
    -- Cập nhật kích thước ScrollFrame
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    
    -- === CẬP NHẬT FIELD ANALYZER ===
    for _, child in pairs(AnalyzerScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    
    local success2, err2 = pcall(function()
        local NectarTypes = require(game:GetService("ReplicatedStorage").NectarTypes)
        local PlanterTypes = require(game:GetService("ReplicatedStorage").PlanterTypes)
        local FlowerZones = game:GetService("Workspace").FlowerZones:GetChildren()
        
        -- Lấy field hiện tại player đang đứng
        local char = Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local currentField = "Chưa xác định"
        
        if root then
            for _, zone in pairs(FlowerZones) do
                local pos = zone.Position
                local size = zone.Size
                local p = root.Position
                if p.X > pos.X - size.X/2 and p.X < pos.X + size.X/2 and p.Z > pos.Z - size.Z/2 and p.Z < pos.Z + size.Z/2 then
                    currentField = zone.Name
                    break
                end
            end
        end
        
        local TitleLab = Instance.new("TextLabel")
        TitleLab.Parent = AnalyzerScroll
        TitleLab.Size = UDim2.new(1, 0, 0, 20)
        TitleLab.BackgroundTransparency = 1
        TitleLab.Font = Enum.Font.GothamBold
        TitleLab.Text = "📍 Đồng hoa hiện tại: " .. currentField
        TitleLab.TextColor3 = Color3.fromRGB(255, 255, 100)
        TitleLab.TextSize = 11

        if currentField ~= "Chưa xác định" then
            -- Check Nectar
            local nectarNames = NectarTypes.TypesForField(currentField)
            local nText = nectarNames and table.concat(nectarNames, ", ") or "Không có"
            
            local NectarLab = Instance.new("TextLabel")
            NectarLab.Parent = AnalyzerScroll
            NectarLab.Size = UDim2.new(1, 0, 0, 15)
            NectarLab.BackgroundTransparency = 1
            NectarLab.Font = Enum.Font.GothamSemibold
            NectarLab.Text = "💧 Loại Nectar cung cấp: " .. nText
            NectarLab.TextColor3 = Color3.fromRGB(150, 200, 255)
            NectarLab.TextSize = 10
            
            -- Check Tốc độ Planter tốt nhất cho field này
            local bestPlanters = {}
            for pName, pData in pairs(PlanterTypes.GetTypes()) do
                local multiplier = 1
                if pData.GrowthMultipliers and pData.GrowthMultipliers.Zones and pData.GrowthMultipliers.Zones[currentField] then
                    multiplier = pData.GrowthMultipliers.Zones[currentField]
                end
                if multiplier > 1 then
                    table.insert(bestPlanters, {Name = pName, Multi = multiplier})
                end
            end
            
            table.sort(bestPlanters, function(a, b) return a.Multi > b.Multi end)
            
            for _, bp in ipairs(bestPlanters) do
                local BPLab = Instance.new("TextLabel")
                BPLab.Parent = AnalyzerScroll
                BPLab.Size = UDim2.new(1, 0, 0, 15)
                BPLab.BackgroundTransparency = 1
                BPLab.Font = Enum.Font.Gotham
                BPLab.Text = string.format("🚀 %s: Tăng tốc x%.2f", bp.Name, bp.Multi)
                BPLab.TextColor3 = Color3.fromRGB(150, 255, 150)
                BPLab.TextSize = 10
            end
        end
    end)
    
    AnalyzerScroll.CanvasSize = UDim2.new(0, 0, 0, AnalyzerList.AbsoluteContentSize.Y + 10)
end

-- Refresh thủ công
RefreshBtn.MouseButton1Click:Connect(UpdatePredictor)

-- Tự động chạy lần đầu
UpdatePredictor()

-- Auto refresh mỗi 60 giây
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(60)
        UpdatePredictor()
    end
end)
