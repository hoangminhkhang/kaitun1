-- =============================================================================
-- BSS KAITUN UI  (ui.lua)  --  product build: polished, persistent, zero deps
-- =============================================================================
-- CONTRACT TÍCH HỢP (main script) - giữ nguyên từ bản trước:
--   local UI = loadstring(readfile("ui.lua"))()
--   UI.SetStatus(stateText, detailText)
--   UI.SetStats{HoneyPerHour=.., Uptime=.., Bees=.., Honey=.., Capacity=.., ...}
--   UI.SetGear("Pulsar | 42%")
--   UI.SetPlanters{{Name="Paper Planter", Field="Clover", Percent=0.64}}
--   UI.DefineControls{{Tab="Farm", Key="AutoFarm", Kind="Toggle", Label="Auto Farm"}, ...}
--     Kind: Toggle | Slider | Section | Button | Textbox/Input | Dropdown | Keybind
--     Dropdown: Options={...}, Default=..   Keybind: Default="E"   Textbox: Numeric=true
--   UI.OnChange(key, fn) / UI.SetValues(Config) / UI.Toggle(false)
--   UI.Notify(title, message, seconds, "info"|"good"|"warn")   -- toast (auto vào Log)
--   UI.Log(message, "info"|"good"|"warn"|"dim")                -- log panel Status
--   UI.CycleTheme() / UI.SetTheme("Honey"|"Midnight")          -- đổi theme TOÀN CÂY
--
-- BUYER EXPERIENCE:
--  * Bo tròn toàn bộ (window 14px, card 10px, control 8px) + shadow mềm
--  * Gradient title bar + accent, hover trên mọi row/tab, knob toggle nảy
--    (Back easing), slider có núm tròn phóng to khi chạm
--  * Toast notification xếp chồng góc phải, tự biến mất
--  * 2 theme: Honey (mặc định) / Midnight - đổi bằng nút 🎨, repaint TOÀN CÂY
--    (mọi card/stroke/control/hex/toast/pill/scrollbar ăn màu ngay)
--  * Sparkline honey/h (40 cột) + Log panel ngay tab Status
--  * TỰ LƯU: vị trí cửa sổ, trạng thái collapse, theme + toàn bộ Values ra
--    bss_kaitun_ui.json (writefile nếu executor hỗ trợ) - mở lại giữ nguyên
--  * Animation: cửa sổ trượt vào khi load, đổi tab có slide nhẹ
--
-- IDEAS còn lại (chưa làm):
--  [1] Minimap: chấm field + player + mob (Frame-based)
--  [2] Planter countdown mm:ss khi có dữ liệu giờ
--  [3] Boost tracker: field boost đang chạy + giây còn lại
--  [4] Nút "Panic" dừng mọi mover cạnh cửa sổ
-- =============================================================================

local getgenvFn = getgenv or function() return _G end
local ENV = getgenvFn()

if ENV.__BSSKaitunUI_Cleanup and type(ENV.__BSSKaitunUI_Cleanup) == "function" then
    pcall(ENV.__BSSKaitunUI_Cleanup)
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local writefileFn = rawget(ENV, "writefile") or (writefile and writefile)
local readfileFn = rawget(ENV, "readfile") or (readfile and readfile)
local SAVE_NAME = "bss_kaitun_ui.json"

-- =============================================================================
-- Themes
-- =============================================================================
local THEMES = {
    Honey = {
        Accent = Color3.fromRGB(255, 176, 32),
        AccentDim = Color3.fromRGB(196, 132, 25),
        AccentSoft = Color3.fromRGB(255, 208, 120),
        Background = Color3.fromRGB(24, 24, 28),
        Panel = Color3.fromRGB(32, 32, 38),
        PanelHover = Color3.fromRGB(44, 44, 52),
        PanelLight = Color3.fromRGB(48, 48, 57),
        Stroke = Color3.fromRGB(70, 70, 82),
        Text = Color3.fromRGB(240, 240, 240),
        TextDim = Color3.fromRGB(165, 165, 175),
        Good = Color3.fromRGB(96, 205, 125),
        Bad = Color3.fromRGB(235, 95, 95),
    },
    Midnight = {
        Accent = Color3.fromRGB(96, 165, 250),
        AccentDim = Color3.fromRGB(70, 125, 200),
        AccentSoft = Color3.fromRGB(150, 190, 250),
        Background = Color3.fromRGB(16, 18, 26),
        Panel = Color3.fromRGB(22, 25, 35),
        PanelHover = Color3.fromRGB(32, 36, 50),
        PanelLight = Color3.fromRGB(36, 41, 56),
        Stroke = Color3.fromRGB(55, 62, 84),
        Text = Color3.fromRGB(235, 240, 250),
        TextDim = Color3.fromRGB(150, 158, 178),
        Good = Color3.fromRGB(96, 205, 125),
        Bad = Color3.fromRGB(235, 95, 95),
    },
}
local currentThemeName = "Honey"
local T = THEMES.Honey

local WINDOW_SIZE = UDim2.fromOffset(500, 360)
local R_WINDOW, R_CARD, R_CTRL, R_PILL = 14, 10, 8, 999

-- =============================================================================
-- Helpers
-- =============================================================================
local function create(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        if key ~= "Parent" then object[key] = value end
    end
    object.Parent = parent
    return object
end

local function corner(object, radius)
    create("UICorner", {CornerRadius = UDim.new(0, radius or R_CTRL)}, object)
    return object
end

local function strokeOf(object, color, thickness, transparency)
    create("UIStroke", {
        Color = color or T.Stroke, Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, object)
    return object
end

local function vGradient(object, topAlpha, bottomAlpha)
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, topAlpha or 0),
            NumberSequenceKeypoint.new(1, bottomAlpha or 0.25),
        }),
    }, object)
    return object
end

local function pad(object, all)
    create("UIPadding", {
        PaddingTop = UDim.new(0, all), PaddingBottom = UDim.new(0, all),
        PaddingLeft = UDim.new(0, all), PaddingRight = UDim.new(0, all),
    }, object)
    return object
end

local function setText(object, text)
    pcall(function() object.Text = text end)
    return object
end

-- =============================================================================
-- Game image resolver: lấy texture CỦA CHÍNH GAME (client đã load sẵn, không
-- cần download gì) gán vào ImageLabel.Image qua chuỗi rbxassetid từ
-- Decal.Texture. Nguồn chính: ReplicatedStorage.EggTypes.<...>Icon (icon
-- planter/egg/tròng game). Tên lộn xộn ("Plastic Planter" -> "PlasticPlanterIcon",
-- "The Planter Of Plenty" -> "PlentyPlanterIcon") nên so khớp BẰNG CHUẨN HÓA:
-- bỏ mọi ký tự không phải chữ-số, thử full-name rồi từ-cuối + "plantericon".
-- =============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local function normalizeImageName(text)
    return string.lower(tostring(text or "")):gsub("[^%w]", "")
end

local function textureOf(instance)
    if not instance then return nil end
    if instance:IsA("Decal") or instance:IsA("Texture") then
        return instance.Texture ~= "" and instance.Texture or nil
    end
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        return instance.Image ~= "" and instance.Image or nil
    end
    local inner = instance:FindFirstChildWhichIsA("Decal", true)
        or instance:FindFirstChildWhichIsA("Texture", true)
        or instance:FindFirstChildWhichIsA("ImageLabel", true)
    return textureOf(inner)
end

local function resolveGameImage(itemName)
    if type(itemName) ~= "string" or itemName == "" then return nil end
    local eggTypes = ReplicatedStorage:FindFirstChild("EggTypes")
    if not eggTypes then return nil end
    local wantedFull = normalizeImageName(itemName) .. "icon"
    local words = {}
    for word in itemName:gmatch("%S+") do table.insert(words, normalizeImageName(word)) end
    local wantedLast = words[#words] and (words[#words] .. "plantericon") or nil
    local best
    for _, child in ipairs(eggTypes:GetChildren()) do
        local normalized = normalizeImageName(child.Name)
        if normalized == wantedFull
            or (wantedLast and normalized == wantedLast) then
            best = child
            if normalized == wantedFull then break end
        end
    end
    if not best then
        -- Fallback thoải mái hơn: icon chứa nguyên tên chuẩn hóa.
        local stripped = normalizeImageName(itemName)
        for _, child in ipairs(eggTypes:GetChildren()) do
            local normalized = normalizeImageName(child.Name)
            if normalized:sub(1, #stripped) == stripped then
                best = child
                break
            end
        end
    end
    return textureOf(best)
end

-- Texture nền honeycomb (nếu game có sẵn ảnh pattern) - tiled, rất mờ, làm
-- nền chìm cho panel hive. Không tìm thấy thì bỏ qua (panel vẫn có gradient).
local hivePatternCache
local function resolveHivePattern()
    if hivePatternCache ~= nil then return hivePatternCache end
    hivePatternCache = false
    local roots = {
        ReplicatedStorage:FindFirstChild("Assets"),
        ReplicatedStorage:FindFirstChild("UI"),
        ReplicatedStorage:FindFirstChild("Images"),
        ReplicatedStorage,
    }
    for _, root in ipairs(roots) do
        if root then
            for _, child in ipairs(root:GetChildren()) do
                local n = normalizeImageName(child.Name)
                if n:find("honeycomb", 1, true) or n:find("hexpattern", 1, true)
                    or n:find("combpattern", 1, true) then
                    local tex = textureOf(child)
                    if tex then
                        hivePatternCache = tex
                        return tex
                    end
                end
            end
        end
    end
    return false
end

-- Hover theo ROLE (không giữ giá trị màu cũ) để đổi theme là ăn ngay.
local function hoverify(object, baseRole, hoverRole)
    object.MouseEnter:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.12), {BackgroundColor3 = T[hoverRole] or T.PanelHover}):Play()
    end)
    object.MouseLeave:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.18), {BackgroundColor3 = T[baseRole] or T.PanelLight}):Play()
    end)
end

local function themeColor()
    return T
end

-- =============================================================================
-- Root ScreenGui (gethui > CoreGui > PlayerGui)
-- =============================================================================
local rootGui
do
    local candidates = {}
    local gethuiFn = rawget(ENV, "gethui") or (gethui and gethui)
    if type(gethuiFn) == "function" then
        pcall(function() table.insert(candidates, gethuiFn()) end)
    end
    table.insert(candidates, game:GetService("CoreGui"))
    if Player then table.insert(candidates, Player:FindFirstChildOfClass("PlayerGui")) end

    rootGui = create("ScreenGui", {
        Name = "BSSKaitunCard", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9,
    })
    for _, candidate in ipairs(candidates) do
        if candidate then
            local ok = pcall(function() rootGui.Parent = candidate end)
            if ok and rootGui.Parent == candidate then break end
        end
    end
    if not rootGui.Parent then
        rootGui.Parent = Player and Player:FindFirstChildOfClass("PlayerGui")
    end
end

-- =============================================================================
-- UI table
-- =============================================================================
local UI = {
    Values = {}, _tabs = {}, _pages = {}, _callbacks = {}, _refs = {},
    _built = {}, _themeListeners = {},
}

-- =============================================================================
-- THEME REPAINT TOÀN CÂY: đổi theme phải ăn MỌI phần tử (card, stroke, control,
-- hex, toast, pill, scrollbar...) chứ không chỉ vài phần tĩnh. Cách chắc chắn
-- mà không phải bind từng create(): dựng map màu-cũ -> màu-mới theo ROLE rồi
-- quét rootGui, hễ thuộc tính màu nào khớp màu palette cũ thì thay màu mới.
-- Màu tự do (rarity, GOLD, trắng/đen...) không nằm trong palette nên giữ nguyên.
-- Color3 là userdata nên KHÔNG dùng làm key table được (hash theo identity) ->
-- key bằng chuỗi "R,G,B" làm tròn.
-- =============================================================================
local function colorKey(c)
    return string.format("%d,%d,%d",
        math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function repaintTheme(oldPalette, newPalette)
    local map = {}
    for role, oldColor in pairs(oldPalette) do
        local newColor = newPalette[role]
        if newColor then map[colorKey(oldColor)] = newColor end
    end
    local function swap(color)
        local replacement = map[colorKey(color)]
        return replacement or color
    end
    for _, obj in ipairs(rootGui:GetDescendants()) do
        pcall(function()
            if obj:IsA("GuiObject") then
                obj.BackgroundColor3 = swap(obj.BackgroundColor3)
            end
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.TextColor3 = swap(obj.TextColor3)
            end
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                obj.ImageColor3 = swap(obj.ImageColor3)
            end
            if obj:IsA("ScrollingFrame") then
                obj.ScrollBarImageColor3 = swap(obj.ScrollBarImageColor3)
            end
            if obj:IsA("UIStroke") then
                obj.Color = swap(obj.Color)
            end
        end)
    end
end

-- =============================================================================
-- Window + shadow + title bar
-- =============================================================================
local shadow = corner(create("Frame", {
    Name = "Shadow",
    Size = WINDOW_SIZE + UDim2.fromOffset(10, 12),
    Position = UDim2.new(1, -WINDOW_SIZE.X.Offset - 24, 0, 58),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.82,
    BorderSizePixel = 0,
}, rootGui), 18)

local window = corner(create("Frame", {
    Name = "Window",
    Size = WINDOW_SIZE,
    Position = UDim2.new(1, -WINDOW_SIZE.X.Offset - 20, 0, 60),
    BackgroundColor3 = T.Background,
    Active = true,
    ClipsDescendants = false,
}, rootGui), R_WINDOW)
strokeOf(window, T.Stroke, 1, 0.25)
vGradient(window, 0, 0.06)

local titleBar = create("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = T.Panel,
}, window)
corner(titleBar, R_WINDOW)
-- Phủ đáy titleBar để chỉ bo TRÊN (UICorner không bo được nửa góc).
create("Frame", {
    Name = "SquarePatch",
    Size = UDim2.new(1, 0, 0.5, 0),
    Position = UDim2.new(0, 0, 0.5, 0),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
}, titleBar)
vGradient(titleBar, 0, 0.18)

-- Chấm accent nhấp nhô trước tiêu đề.
local statusDot = create("Frame", {
    Name = "Dot",
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.fromOffset(14, 16),
    BackgroundColor3 = T.Good,
}, titleBar)
corner(statusDot, R_PILL)

local titleLabel = create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -170, 1, 0),
    Position = UDim2.fromOffset(30, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "BSS Kaitun",
    TextColor3 = T.Accent,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

local themeButton = corner(create("TextButton", {
    Name = "Theme",
    Size = UDim2.fromOffset(30, 26),
    Position = UDim2.new(1, -100, 0.5, -13),
    BackgroundColor3 = T.PanelLight,
    Font = Enum.Font.GothamBold,
    Text = "🎨",
    TextColor3 = T.Text,
    TextSize = 13,
}, titleBar), R_CTRL)
hoverify(themeButton, "PanelLight", "PanelHover")

local collapseButton = corner(create("TextButton", {
    Name = "Collapse",
    Size = UDim2.fromOffset(34, 26),
    Position = UDim2.new(1, -60, 0.5, -13),
    BackgroundColor3 = T.PanelLight,
    Font = Enum.Font.GothamBold,
    Text = "—",
    TextColor3 = T.Text,
    TextSize = 13,
}, titleBar), R_CTRL)
hoverify(collapseButton, "PanelLight", "PanelHover")
local collapsed = false

-- Drag (freeze Scale->Offset trước khi kéo + release toàn cục + clamp theo viewport)
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            pcall(function()
                window.Position = UDim2.fromOffset(
                    window.AbsolutePosition.X - rootGui.AbsolutePosition.X,
                    window.AbsolutePosition.Y - rootGui.AbsolutePosition.Y)
                shadow.Position = UDim2.fromOffset(
                    window.Position.X.Offset - 5, window.Position.Y.Offset - 6)
            end)
            startPos = window.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then UI._saveSoon() end
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local maxX = math.max(80, rootGui.AbsoluteSize.X - 80)
            local maxY = math.max(40, rootGui.AbsoluteSize.Y - 40)
            local x = math.clamp(startPos.X.Offset + delta.X,
                -WINDOW_SIZE.X.Offset + 80, maxX)
            local y = math.clamp(startPos.Y.Offset + delta.Y, 0, maxY)
            window.Position = UDim2.fromOffset(x, y)
            shadow.Position = UDim2.fromOffset(x - 5, y - 6)
        end
    end)
end

local bodyHolder = create("Frame", {
    Name = "Body",
    Size = UDim2.new(1, 0, 1, -40),
    Position = UDim2.fromOffset(0, 40),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, window)

-- =============================================================================
-- Tab system (icon + label + underline active)
-- =============================================================================
local tabBar = create("Frame", {
    Name = "Tabs",
    Size = UDim2.new(1, -20, 0, 34),
    Position = UDim2.fromOffset(10, 6),
    BackgroundColor3 = T.Panel,
}, bodyHolder)
corner(tabBar, R_CARD)

local pageHolder = create("Frame", {
    Name = "Pages",
    Size = UDim2.new(1, -20, 1, -76),
    Position = UDim2.fromOffset(10, 48),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, bodyHolder)

local TAB_DEFS = {
    {Name = "Status", Icon = "📊"},
    {Name = "Farm", Icon = "🏡"},
    {Name = "Move", Icon = "👟"},
    {Name = "Hive", Icon = "🍯"},
    {Name = "Lag", Icon = "⚡"},
    {Name = "Planter", Icon = "🪴"},
}

do
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, tabBar)
    pad(tabBar, 4)

    for index, def in ipairs(TAB_DEFS) do
        local button = corner(create("TextButton", {
            Name = def.Name,
            LayoutOrder = index,
            Size = UDim2.new(0, 72, 1, 0),
            BackgroundColor3 = T.PanelLight,
            Font = Enum.Font.GothamMedium,
            Text = def.Icon .. " " .. def.Name,
            TextColor3 = T.TextDim,
            TextSize = 11,
        }, tabBar), R_CTRL)
        local underline = corner(create("Frame", {
            Name = "Underline",
            Size = UDim2.new(0, 0, 0, 3),
            Position = UDim2.new(0.5, 0, 1, -3),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = T.Accent,
        }, button), R_PILL)

        local page = create("ScrollingFrame", {
            Name = def.Name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = T.AccentDim,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = index == 1,
        }, pageHolder)
        create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)
        pad(page, 4)

        button.MouseEnter:Connect(function()
            if not page.Visible then
                TweenService:Create(button, TweenInfo.new(0.12),
                    {BackgroundColor3 = T.PanelHover}):Play()
            end
        end)
        button.MouseLeave:Connect(function()
            if not page.Visible then
                TweenService:Create(button, TweenInfo.new(0.18),
                    {BackgroundColor3 = T.PanelLight}):Play()
            end
        end)
        button.MouseButton1Click:Connect(function()
            for name, other in pairs(UI._pages) do
                other.Visible = (name == def.Name)
            end
            for name, other in pairs(UI._tabs) do
                local active = (name == def.Name)
                other.BackgroundColor3 = active and T.Accent or T.PanelLight
                pcall(function()
                    other.TextColor3 = active and T.Background or T.TextDim
                end)
                local bar = other:FindFirstChild("Underline")
                if bar then
                    TweenService:Create(bar, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Size = active and UDim2.new(0.6, 0, 0, 3) or UDim2.new(0, 0, 0, 3),
                    }):Play()
                end
            end
            -- Slide nhẹ khi đổi tab.
            page.Position = UDim2.fromOffset(10, 0)
            TweenService:Create(page, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                Position = UDim2.fromOffset(0, 0),
            }):Play()
        end)
        UI._tabs[def.Name] = button
        UI._pages[def.Name] = page
    end
    UI._tabs.Status.BackgroundColor3 = T.Accent
    UI._tabs.Status.TextColor3 = T.Background
    local firstBar = UI._tabs.Status:FindFirstChild("Underline")
    if firstBar then firstBar.Size = UDim2.new(0.6, 0, 0, 3) end
end

-- =============================================================================
-- Components
-- =============================================================================
local function applyValue(key, value)
    UI.Values[key] = value
    UI._saveSoon()
    local callback = UI._callbacks[key]
    if type(callback) == "function" then
        task.spawn(function() pcall(callback, value) end)
    end
end

local function buildToggle(page, def, order)
    local row = corner(create("Frame", {
        Name = "Ctrl_" .. tostring(def.Key),
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.Panel,
    }, page), R_CTRL)
    strokeOf(row, T.Stroke, 1, 0.55)
    create("TextLabel", {
        Size = UDim2.new(1, -76, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = def.Label or def.Key,
        TextColor3 = def.Danger and T.Bad or T.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = corner(create("TextButton", {
        Size = UDim2.fromOffset(48, 26),
        Position = UDim2.new(1, -60, 0.5, -13),
        BackgroundColor3 = T.PanelLight,
        Text = "",
    }, row), R_PILL)
    strokeOf(track, T.Stroke, 1, 0.4)
    local knob = corner(create("Frame", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = T.TextDim,
    }, track), R_PILL)

    local function render(state)
        TweenService:Create(track, TweenInfo.new(0.18), {
            BackgroundColor3 = state and T.Accent or T.PanelLight,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = state and T.Background or T.TextDim,
        }):Play()
    end
    local current = UI.Values[def.Key] and true or false
    render(current)
    track.MouseButton1Click:Connect(function()
        current = not current
        render(current)
        applyValue(def.Key, current)
    end)
    UI._refs[def.Key] = {Render = function(value) render(value and true or false) end}
    return row
end

local function buildSlider(page, def, order)
    local min = tonumber(def.Min) or 0
    local max = tonumber(def.Max) or 100
    local step = math.max(0.01, tonumber(def.Step) or 1)
    local row = corner(create("Frame", {
        Name = "Ctrl_" .. tostring(def.Key),
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = T.Panel,
    }, page), R_CTRL)
    strokeOf(row, T.Stroke, 1, 0.55)
    create("TextLabel", {
        Size = UDim2.new(1, -96, 0, 20),
        Position = UDim2.fromOffset(14, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = def.Label or def.Key,
        TextColor3 = T.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local valueLabel = create("TextLabel", {
        Size = UDim2.fromOffset(78, 20),
        Position = UDim2.new(1, -90, 0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "-",
        TextColor3 = T.Accent,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local bar = corner(create("Frame", {
        Size = UDim2.new(1, -28, 0, 8),
        Position = UDim2.new(0, 14, 1, -16),
        BackgroundColor3 = T.PanelLight,
    }, row), R_PILL)
    local fill = corner(create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.Accent,
    }, bar), R_PILL)
    vGradient(fill, 0, 0.3)
    local handle = corner(create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = T.Text,
        ZIndex = 2,
    }, fill), R_PILL)
    strokeOf(handle, T.Accent, 2, 0)

    local function snap(value)
        return math.clamp(math.floor(value / step + 0.5) * step, min, max)
    end
    local function render(value)
        value = snap(tonumber(value) or min)
        local alpha = math.clamp((value - min) / math.max(0.001, max - min), 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        setText(valueLabel, tostring(value))
    end
    render(tonumber(UI.Values[def.Key]) or min)

    local draggingSlider = false
    local function setFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local value = snap(min + (max - min) * alpha)
        render(value)
        applyValue(def.Key, value)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            TweenService:Create(handle, TweenInfo.new(0.12), {Size = UDim2.fromOffset(18, 18)}):Play()
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) and draggingSlider then
            draggingSlider = false
            TweenService:Create(handle, TweenInfo.new(0.15), {Size = UDim2.fromOffset(14, 14)}):Play()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UI._refs[def.Key] = {Render = function(value) render(tonumber(value) or min) end}
    return row
end

-- =============================================================================
-- Control kinds MỚI: Section / Button / Textbox / Dropdown / Keybind.
-- Cùng pattern buildX(page, def, order) -> row, đăng ký UI._refs[Key].Render
-- để SetValues repaint được. Màu dùng T.* nên đổi theme là ăn (repaintTheme).
-- =============================================================================
local dropdownPopups = {}

local function buildSection(page, def, order)
    local row = create("Frame", {
        Name = "Section_" .. tostring(def.Label or order),
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
    }, page)
    create("TextLabel", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.fromOffset(4, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = string.upper(tostring(def.Label or "")),
        TextColor3 = T.AccentDim,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    create("Frame", {
        Size = UDim2.new(1, -8, 0, 1),
        Position = UDim2.new(0, 4, 1, -2),
        BackgroundColor3 = T.Stroke,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, row)
    return row
end

local function buildButton(page, def, order)
    local row = corner(create("TextButton", {
        Name = "Ctrl_" .. tostring(def.Key),
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = T.Panel,
        Font = Enum.Font.GothamMedium,
        Text = def.Label or def.Key,
        TextColor3 = def.Danger and T.Bad or T.Text,
        TextSize = 14,
        AutoButtonColor = false,
    }, page), R_CTRL)
    strokeOf(row, T.Stroke, 1, 0.55)
    hoverify(row, "Panel", "PanelHover")
    row.MouseButton1Click:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.08), {BackgroundColor3 = T.AccentDim}):Play()
        task.delay(0.12, function()
            TweenService:Create(row, TweenInfo.new(0.16), {BackgroundColor3 = T.Panel}):Play()
        end)
        local callback = UI._callbacks[def.Key]
        if type(callback) == "function" then
            task.spawn(function() pcall(callback) end)
        end
    end)
    UI._refs[def.Key] = {Render = function() end}
    return row
end

local function buildTextbox(page, def, order)
    local row = corner(create("Frame", {
        Name = "Ctrl_" .. tostring(def.Key),
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.Panel,
    }, page), R_CTRL)
    strokeOf(row, T.Stroke, 1, 0.55)
    create("TextLabel", {
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = def.Label or def.Key,
        TextColor3 = T.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local box = corner(create("TextBox", {
        Size = UDim2.new(0, 130, 0, 26),
        Position = UDim2.new(1, -142, 0.5, -13),
        BackgroundColor3 = T.PanelLight,
        Font = Enum.Font.Gotham,
        Text = tostring(UI.Values[def.Key] or def.Default or ""),
        PlaceholderText = def.Placeholder or "...",
        TextColor3 = T.Text,
        PlaceholderColor3 = T.TextDim,
        TextSize = 13,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row), R_CTRL)
    strokeOf(box, T.Stroke, 1, 0.4)
    pad(box, 5)
    local function commit()
        local value = box.Text
        if def.Numeric then
            value = tonumber(value) or tonumber(def.Default) or 0
        end
        applyValue(def.Key, value)
    end
    box.FocusLost:Connect(function() commit() end)
    UI._refs[def.Key] = {Render = function(v) box.Text = tostring(v == nil and "" or v) end}
    return row
end

local function buildDropdown(page, def, order)
    local options = type(def.Options) == "table" and def.Options or {}
    local row = corner(create("Frame", {
        Name = "Ctrl_" .. tostring(def.Key),
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.Panel,
    }, page), R_CTRL)
    strokeOf(row, T.Stroke, 1, 0.55)
    create("TextLabel", {
        Size = UDim2.new(1, -180, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = def.Label or def.Key,
        TextColor3 = T.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local btn = corner(create("TextButton", {
        Size = UDim2.new(0, 160, 0, 26),
        Position = UDim2.new(1, -172, 0.5, -13),
        BackgroundColor3 = T.PanelLight,
        Text = "",
        AutoButtonColor = false,
    }, row), R_CTRL)
    strokeOf(btn, T.Stroke, 1, 0.4)
    local btnLabel = create("TextLabel", {
        Size = UDim2.new(1, -26, 1, 0),
        Position = UDim2.fromOffset(9, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "-",
        TextColor3 = T.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, btn)
    create("TextLabel", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, -20, 0.5, -8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "▾",
        TextColor3 = T.TextDim,
        TextSize = 12,
    }, btn)
    local current = UI.Values[def.Key]
    if current == nil then current = def.Default or options[1] end
    local function render(v) btnLabel.Text = tostring(v == nil and "-" or v) end
    render(current)

    local popup
    local function closePopup()
        if popup then pcall(function() popup:Destroy() end) popup = nil end
        dropdownPopups[def.Key] = nil
    end
    local function openPopup()
        closePopup()
        local abs = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local height = math.min(190, math.max(30, #options * 28 + 8))
        popup = corner(create("Frame", {
            Name = "DropdownPopup",
            Size = UDim2.fromOffset(size.X, height),
            Position = UDim2.fromOffset(abs.X - rootGui.AbsolutePosition.X,
                abs.Y - rootGui.AbsolutePosition.Y + size.Y + 4),
            BackgroundColor3 = T.Panel,
            ZIndex = 60,
            ClipsDescendants = true,
        }, rootGui), R_CTRL)
        strokeOf(popup, T.Accent, 1, 0.25)
        dropdownPopups[def.Key] = closePopup
        local scroll = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.AccentDim,
            CanvasSize = UDim2.fromOffset(0, #options * 28 + 8),
            ZIndex = 61,
        }, popup)
        create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
        pad(scroll, 4)
        for i, opt in ipairs(options) do
            local optBtn = corner(create("TextButton", {
                LayoutOrder = i,
                Size = UDim2.new(1, -8, 0, 26),
                BackgroundColor3 = (opt == current) and T.AccentDim or T.PanelLight,
                Font = Enum.Font.Gotham,
                Text = tostring(opt),
                TextColor3 = T.Text,
                TextSize = 13,
                AutoButtonColor = false,
                ZIndex = 62,
            }, scroll), R_CTRL)
            optBtn.MouseEnter:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = T.PanelHover}):Play()
            end)
            optBtn.MouseLeave:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.12), {
                    BackgroundColor3 = (opt == current) and T.AccentDim or T.PanelLight,
                }):Play()
            end)
            optBtn.MouseButton1Click:Connect(function()
                current = opt
                render(opt)
                applyValue(def.Key, opt)
                closePopup()
            end)
        end
    end
    btn.MouseButton1Click:Connect(function()
        if popup then closePopup() else openPopup() end
    end)
    UserInputService.InputBegan:Connect(function(input)
        if not popup or not popup.Parent or not btn.Parent then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = input.Position
        local pa, ps = popup.AbsolutePosition, popup.AbsoluteSize
        local ba, bs = btn.AbsolutePosition, btn.AbsoluteSize
        local inPopup = p.X >= pa.X and p.X <= pa.X + ps.X and p.Y >= pa.Y and p.Y <= pa.Y + ps.Y
        local inBtn = p.X >= ba.X and p.X <= ba.X + bs.X and p.Y >= ba.Y and p.Y <= ba.Y + bs.Y
        if not inPopup and not inBtn then closePopup() end
    end)
    UI._refs[def.Key] = {Render = function(v) current = v; render(v) end}
    return row
end

local function buildKeybind(page, def, order)
    local row = corner(create("Frame", {
        Name = "Ctrl_" .. tostring(def.Key),
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.Panel,
    }, page), R_CTRL)
    strokeOf(row, T.Stroke, 1, 0.55)
    create("TextLabel", {
        Size = UDim2.new(1, -130, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = def.Label or def.Key,
        TextColor3 = T.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local btn = corner(create("TextButton", {
        Size = UDim2.new(0, 110, 0, 26),
        Position = UDim2.new(1, -122, 0.5, -13),
        BackgroundColor3 = T.PanelLight,
        Text = "",
        AutoButtonColor = false,
    }, row), R_CTRL)
    strokeOf(btn, T.Stroke, 1, 0.4)
    local btnLabel = create("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "None",
        TextColor3 = T.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, btn)
    local current = UI.Values[def.Key] or def.Default or "None"
    local listening = false
    local capture
    local function render(v)
        btnLabel.Text = listening and "press key..." or tostring(v or "None")
        btnLabel.TextColor3 = listening and T.Accent or T.Text
    end
    render(current)
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        render(current)
        capture = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if capture then capture:Disconnect() capture = nil end
            listening = false
            if input.KeyCode == Enum.KeyCode.Escape then
                render(current)
                return
            end
            current = input.KeyCode.Name
            render(current)
            applyValue(def.Key, current)
        end)
    end)
    UI._refs[def.Key] = {Render = function(v) current = v; render(v) end}
    return row
end

-- =============================================================================
-- Status page
-- =============================================================================
local statusLabel, statusCard, statCells, gearLine, bagFill, bagFillText, planterCells
local renderHoneyGraph, logAppend
local honeyHistory = {}
do
    local page = UI._pages.Status
    local order = 0
    local function nextOrder() order += 1 return order end

    statusCard = corner(create("Frame", {
        Name = "StatusCard",
        LayoutOrder = nextOrder(),
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = T.Panel,
    }, page), R_CARD)
    strokeOf(statusCard, T.AccentDim, 1, 0.6)
    vGradient(statusCard, 0, 0.22)
    statusLabel = create("TextLabel", {
        Size = UDim2.new(1, -18, 1, 0),
        Position = UDim2.fromOffset(9, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "booting...",
        TextColor3 = T.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, statusCard)

    statCells = {}
    local statKeys = {
        {"HoneyPerHour", "HONEY / H"},
        {"Uptime", "UPTIME"},
        {"Bees", "BEES"},
        {"Tokens", "TOKENS"},
        {"Honey", "HONEY"},
        {"Capacity", "BAG SIZE"},
        {"SproutsFarmed", "SPROUTS"},
        {"PlanterHarvests", "HARVESTS"},
    }
    for index, entry in ipairs(statKeys) do
        local rowIndex = math.ceil(index / 2)
        local rowFrame = statCells["Row" .. rowIndex]
        if not rowFrame then
            rowFrame = create("Frame", {
                Name = "Row" .. rowIndex,
                LayoutOrder = nextOrder(),
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundTransparency = 1,
            }, page)
            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6),
            }, rowFrame)
            statCells["Row" .. rowIndex] = rowFrame
        end
        local cell = corner(create("Frame", {
            Name = "Cell_" .. entry[1],
            Size = UDim2.new(0.5, -3, 1, 0),
            BackgroundColor3 = T.Panel,
        }, rowFrame), R_CTRL)
        strokeOf(cell, T.Stroke, 1, 0.6)
        create("TextLabel", {
            Size = UDim2.new(1, -14, 0, 13),
            Position = UDim2.fromOffset(8, 4),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = entry[2],
            TextColor3 = T.TextDim,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, cell)
        local valueLabel = create("TextLabel", {
            Size = UDim2.new(1, -14, 0, 19),
            Position = UDim2.fromOffset(8, 17),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "-",
            TextColor3 = T.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, cell)
        statCells[entry[1]] = valueLabel
    end

    gearLine = create("TextLabel", {
        LayoutOrder = nextOrder(),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "next gear: -",
        TextColor3 = T.AccentSoft,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, page)

    local bagFrame = corner(create("Frame", {
        Name = "Bag",
        LayoutOrder = nextOrder(),
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = T.Panel,
    }, page), R_CTRL)
    strokeOf(bagFrame, T.Stroke, 1, 0.6)
    local bagTrack = corner(create("Frame", {
        Size = UDim2.new(1, -8, 0, 12),
        Position = UDim2.new(0, 4, 0.5, -6),
        BackgroundColor3 = T.PanelLight,
        ZIndex = 1,
    }, bagFrame), R_PILL)
    bagFill = corner(create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.Good,
        ZIndex = 2,
    }, bagTrack), R_PILL)
    vGradient(bagFill, 0, 0.35)
    bagFillText = create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "bag -",
        TextColor3 = T.Text,
        TextSize = 12,
        ZIndex = 3,
    }, bagFrame)

    local planterFrame = corner(create("Frame", {
        Name = "Planters",
        LayoutOrder = nextOrder(),
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = T.Panel,
    }, page), R_CARD)
    strokeOf(planterFrame, T.Stroke, 1, 0.6)
    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.fromOffset(9, 3),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "PLANTERS",
        TextColor3 = T.TextDim,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, planterFrame)
    do
        local slots = create("Frame", {
            Size = UDim2.new(1, -14, 0, 50),
            Position = UDim2.fromOffset(7, 22),
            BackgroundTransparency = 1,
        }, planterFrame)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
        }, slots)
        planterCells = {}
        for slot = 1, 3 do
            local cell = corner(create("Frame", {
                Size = UDim2.new(0.333, -4, 1, 0),
                BackgroundColor3 = T.PanelLight,
            }, slots), R_CTRL)
            -- Icon THẬT của planter lấy từ EggTypes của game (rbxassetid trực
            -- tiếp - client đã có texture, không download gì cả).
            local iconImage = create("ImageLabel", {
                Name = "Icon",
                Size = UDim2.fromOffset(22, 22),
                Position = UDim2.fromOffset(4, 3),
                BackgroundTransparency = 1,
                Image = "",
                ScaleType = Enum.ScaleType.Fit,
            }, cell)
            local nameLabel = create("TextLabel", {
                Size = UDim2.new(1, -32, 0, 14),
                Position = UDim2.fromOffset(28, 4),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Text = "-",
                TextColor3 = T.Text,
                TextSize = 11,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, cell)
            local fieldLabel = create("TextLabel", {
                Size = UDim2.new(1, -32, 0, 12),
                Position = UDim2.fromOffset(28, 18),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = "",
                TextColor3 = T.TextDim,
                TextSize = 10,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, cell)
            local fillTrack = corner(create("Frame", {
                Size = UDim2.new(1, -12, 0, 7),
                Position = UDim2.new(0, 6, 1, -13),
                BackgroundColor3 = T.Background,
            }, cell), R_PILL)
            local fillBar = corner(create("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = T.Accent,
            }, fillTrack), R_PILL)
            planterCells[slot] = {Name = nameLabel, Field = fieldLabel, Fill = fillBar, Icon = iconImage}
        end
    end

    -- SPARKLINE honey/h: 40 cột Frame, mẫu mới nhất bên phải + tô accent.
    -- Dữ liệu lấy từ SetStats.HoneyPerHour (main đã đẩy sẵn mỗi nhịp).
    local GRAPH_N = 40
    local graphFrame = corner(create("Frame", {
        Name = "HoneyGraph",
        LayoutOrder = nextOrder(),
        Size = UDim2.new(1, 0, 0, 78),
        BackgroundColor3 = T.Panel,
    }, page), R_CARD)
    strokeOf(graphFrame, T.Stroke, 1, 0.6)
    create("TextLabel", {
        Size = UDim2.new(1, -14, 0, 16),
        Position = UDim2.fromOffset(9, 3),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "HONEY / H  ·  LAST 40",
        TextColor3 = T.TextDim,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, graphFrame)
    local chart = create("Frame", {
        Size = UDim2.new(1, -16, 0, 46),
        Position = UDim2.fromOffset(8, 24),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, graphFrame)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 1),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    }, chart)
    local graphBars = {}
    for i = 1, GRAPH_N do
        graphBars[i] = corner(create("Frame", {
            LayoutOrder = i,
            Size = UDim2.new(1 / GRAPH_N, -1, 0, 0),
            BackgroundColor3 = T.AccentDim,
            BackgroundTransparency = 0.6,
        }, chart), 2)
    end
    function renderHoneyGraph()
        local maxValue = 1
        for _, v in ipairs(honeyHistory) do
            if v > maxValue then maxValue = v end
        end
        local n = #honeyHistory
        for i = 1, GRAPH_N do
            local bar = graphBars[i]
            local idx = n - GRAPH_N + i
            local v = idx >= 1 and honeyHistory[idx] or nil
            if v then
                local ratio = math.clamp(v / maxValue, 0.05, 1)
                bar.Size = UDim2.new(1 / GRAPH_N, -1, ratio, 0)
                bar.BackgroundColor3 = (idx == n) and T.Accent or T.AccentDim
                bar.BackgroundTransparency = (idx == n) and 0 or 0.3
            else
                bar.Size = UDim2.new(1 / GRAPH_N, -1, 0, 0)
                bar.BackgroundTransparency = 0.6
            end
        end
    end

    -- LOG PANEL: dòng console gần nhất trong UI (UI.Log). Tự cuộn xuống đáy.
    local logFrame = corner(create("Frame", {
        Name = "Log",
        LayoutOrder = nextOrder(),
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = T.Panel,
    }, page), R_CARD)
    strokeOf(logFrame, T.Stroke, 1, 0.6)
    create("TextLabel", {
        Size = UDim2.new(1, -14, 0, 16),
        Position = UDim2.fromOffset(9, 3),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "LOG",
        TextColor3 = T.TextDim,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, logFrame)
    local logScroll = create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -22),
        Position = UDim2.fromOffset(6, 18),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.AccentDim,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, logFrame)
    create("UIListLayout", {Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder}, logScroll)
    local logLines, logOrder = {}, 0
    function logAppend(message, kind)
        local color = T.Text
        if kind == "good" then color = T.Good
        elseif kind == "warn" then color = T.Bad
        elseif kind == "dim" then color = T.TextDim end
        logOrder = logOrder + 1
        local line = create("TextLabel", {
            LayoutOrder = logOrder,
            Size = UDim2.new(1, -4, 0, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            Text = os.date("%H:%M:%S") .. "  " .. tostring(message),
            TextColor3 = color,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, logScroll)
        table.insert(logLines, line)
        if #logLines > 40 then
            local old = table.remove(logLines, 1)
            pcall(function() old:Destroy() end)
        end
        task.defer(function()
            pcall(function()
                logScroll.CanvasPosition = Vector2.new(0,
                    math.max(0, logScroll.AbsoluteCanvasSize.Y - logScroll.AbsoluteSize.Y))
            end)
        end)
    end

    -- Footer version line.
    create("TextLabel", {
        LayoutOrder = nextOrder(),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "BSS Kaitun • ui v2",
        TextColor3 = T.TextDim,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTransparency = 0.35,
    }, page)
end

-- =============================================================================
-- =============================================================================
-- Hive page (tab 🍯): tổng quan tổ ong - cấp độ trung bình, gifted, màu.
-- Main đẩy dữ liệu qua UI.SetHive{...} và UI.SetHiveGrid{{Type=,Gifted=,Level=,X=,Y=}}.
-- =============================================================================
-- Phân loại màu ô ong (file-level để SetHiveGrid dùng được - local trong
-- do-block dưới kia sẽ không thấy).
local HIVE_EVENT_MARKS = {
    bear = true, cobalt = true, crimson = true, digital = true,
    festive = true, gummy = true, photon = true, puppy = true,
    tabby = true, vicious = true, windy = true,
}
-- =============================================================================
-- RARITY -> MÀU Ô (giống ảnh mẫu hive của game):
--   Common trắng, Rare xanh lá, Epic xanh dương, Legendary đỏ,
--   Mythic tím, Event cyan. Gifted = viền VÀNG + tint kim nhẹ.
-- =============================================================================
local GOLD = Color3.fromRGB(255, 210, 63)
local RARITY_COLORS = {
    Common = Color3.fromRGB(232, 230, 223),
    Rare = Color3.fromRGB(155, 214, 90),
    Epic = Color3.fromRGB(91, 155, 239),
    Legendary = Color3.fromRGB(239, 106, 90),
    Mythic = Color3.fromRGB(185, 166, 236),
    Event = Color3.fromRGB(111, 227, 214),
}
local BEE_RARITY = {
    basic = "Common",
    bomber = "Rare", brave = "Rare", bumble = "Rare", cool = "Rare", hasty = "Rare",
    looker = "Rare", rad = "Rare", rascal = "Rare", stubborn = "Rare",
    baby = "Epic", carpenter = "Epic", commander = "Epic", demon = "Epic",
    exhausted = "Epic", fire = "Epic", frosty = "Epic", honey = "Epic",
    rage = "Epic", riley = "Epic", shy = "Epic",
    bucko = "Legendary", diamond = "Legendary", lion = "Legendary", music = "Legendary",
    ninja = "Legendary", shimmer = "Legendary", shocked = "Legendary",
    buoyant = "Mythic", fuzzy = "Mythic", precise = "Mythic", spicy = "Mythic",
    tadpole = "Mythic", vector = "Mythic",
    bear = "Event", cobalt = "Event", crimson = "Event", digital = "Event",
    festive = "Event", gummy = "Event", photon = "Event", puppy = "Event",
    tabby = "Event", vicious = "Event", windy = "Event",
}
local function rarityOf(beeType)
    local n = normalizeImageName(beeType)
    local bare = n:gsub("bee$", "")
    return BEE_RARITY[bare] or BEE_RARITY[n]
        or (HIVE_EVENT_MARKS[n] or HIVE_EVENT_MARKS[bare]) and "Event" or "Common"
end

-- =============================================================================
-- HEXAGON bằng Frame: flat-top = kim cương trái (45°) + chữ nhật giữa + kim
-- cương phải. Các ô khớp cạnh nhau khi COL_PITCH = HEX_W - HEX_H/2 (tổ ong
-- liền mạch, không hở/không chồng). Cột chẵn/lẻ lệch nhau nửa ô theo chiều dọc.
-- =============================================================================
local HEX_W, HEX_H = 88, 62
local COL_PITCH = HEX_W - HEX_H / 2          -- 57: cạnh phải ô trước = cạnh trái ô sau
local ROW_PITCH = HEX_H
local COL_OFFSET = HEX_H / 2                 -- cột chẵn (1,3,5) đẩy xuống nửa ô
local GRID_COLS, GRID_ROWS = 5, 10
local GRID_W = (GRID_COLS - 1) * COL_PITCH + HEX_W
local GRID_H = (GRID_ROWS - 1) * ROW_PITCH + HEX_H + COL_OFFSET

local function makeHex(parent, zIndex)
    local holder = create("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = zIndex,
        Size = UDim2.fromOffset(1, 1),
    }, parent)
    local left = create("Frame", {
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 45, ZIndex = zIndex,
    }, holder)
    local right = create("Frame", {
        BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 45, ZIndex = zIndex,
    }, holder)
    local mid = create("Frame", {BorderSizePixel = 0, ZIndex = zIndex}, holder)
    return {Frame = holder, Left = left, Right = right, Mid = mid}
end

local function layoutHex(hex, w, h, x, y, color)
    hex.Frame.Position = UDim2.fromOffset(x, y)
    hex.Frame.Size = UDim2.fromOffset(w, h)
    local side = h / math.sqrt(2)
    hex.Left.Size = UDim2.fromOffset(side, side)
    hex.Left.Position = UDim2.fromOffset(h / 2, h / 2)
    hex.Left.BackgroundColor3 = color
    hex.Right.Size = UDim2.fromOffset(side, side)
    hex.Right.Position = UDim2.fromOffset(w - h / 2, h / 2)
    hex.Right.BackgroundColor3 = color
    hex.Mid.Position = UDim2.fromOffset(h / 2, 0)
    hex.Mid.Size = UDim2.fromOffset(math.max(0, w - h), h)
    hex.Mid.BackgroundColor3 = color
end

-- =============================================================================
-- MERGE BEE: mặt ong ghép KÍN ô hex (clip theo silhouette lục giác như tổ trong
-- game). Hex = kim cương trái (45°) + chữ nhật giữa + kim cương phải (45°). Mỗi
-- mảnh là Frame ClipsDescendants xoay theo hex, chứa CÙNG một ảnh ong xoay NGƯỢC
-- lại (-45°) để ảnh luôn thẳng đứng và căn giữa ô hex. Ba mảnh ghép lại = ảnh ong
-- bị cắt đúng hình lục giác. ScaleType.Fit nên không méo; phần mũi hex ngoài ảnh
-- hở ra nền màu rarity bên dưới. Không cần biết kích thước pixel ảnh nguồn.
-- =============================================================================
local function makeHexFace(parent, zIndex)
    local w, h = HEX_W, HEX_H
    local side = h / math.sqrt(2)
    local s2 = math.sqrt(2)
    local C = Vector2.new(0.5, 0.5)
    local O = Vector2.new(0, 0)
    local images = {}
    local function piece(fw, fh, fx, fy, frot, fanchor, ix, iy, irot, ianchor)
        local clip = create("Frame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ClipsDescendants = true, ZIndex = zIndex,
            AnchorPoint = fanchor, Rotation = frot,
            Size = UDim2.fromOffset(fw, fh),
            Position = UDim2.fromOffset(fx, fy),
        }, parent)
        local img = create("ImageLabel", {
            BackgroundTransparency = 1, ZIndex = zIndex,
            AnchorPoint = ianchor, Rotation = irot,
            Size = UDim2.fromOffset(w, h),
            Position = UDim2.fromOffset(ix, iy),
            Image = "", ScaleType = Enum.ScaleType.Fit,
        }, clip)
        images[#images + 1] = img
    end
    -- Giữa: clip chữ nhật (không xoay), ảnh phủ kín ô hex, căn trái về (0,0).
    piece(w - h, h, h / 2, 0, 0, O, -h / 2, 0, 0, O)
    -- Trái: kim cương 45°, ảnh -45° căn giữa ô (toạ độ suy từ hình học hex).
    piece(side, side, h / 2, h / 2, 45, C, w / (2 * s2), (2 * h - w) / (2 * s2), -45, C)
    -- Phải: đối xứng trái.
    piece(side, side, w - h / 2, h / 2, 45, C, (2 * h - w) / (2 * s2), w / (2 * s2), -45, C)
    return {Images = images}
end

local function setBeeFace(face, image)
    if type(face) ~= "table" or type(face.Images) ~= "table" then return end
    local img = image or ""
    for _, label in ipairs(face.Images) do
        label.Image = img
    end
end

-- MẶT ONG THẬT: nguồn chuẩn = BeeTypes.Thumbnails/<Tên> ( GiftedThumbnails
-- cho ong gifted - đúng bộ asset UI hive của game tự dùng). Fallback:
-- TopDecals rồi GiftedBeeModels.FaceTexture. Cache theo loại + gifted.
local beeFaceCache = {}
local function beeFaceTexture(beeType, gifted)
    local key = tostring(beeType or "") .. (gifted and "|g" or "")
    if beeFaceCache[key] ~= nil then return beeFaceCache[key] end
    local texture
    local firstName = tostring(beeType or ""):match("^(%S+)")
    if firstName and firstName ~= "" then
        local beeTypes = ReplicatedStorage:FindFirstChild("BeeTypes")
        if beeTypes then
            local folder = beeTypes:FindFirstChild(gifted and "GiftedThumbnails" or "Thumbnails")
            texture = textureOf(folder and folder:FindFirstChild(firstName))
            if not texture and folder then
                -- Khớp CHUẨN HÓA (tránh lệch "Basic Bee" / "BasicBee"):
                -- so tên loại (bỏ đuôi "bee") với tên child đã chuẩn hóa.
                local wanted = normalizeImageName(beeType)
                local wantedBare = wanted:gsub("bee$", "")
                for _, child in ipairs(folder:GetChildren()) do
                    local n = normalizeImageName(child.Name)
                    if n == wanted or n == wantedBare then
                        texture = textureOf(child)
                        break
                    end
                end
            end
            if not texture then
                local decals = beeTypes:FindFirstChild("TopDecals")
                texture = textureOf(decals and decals:FindFirstChild(firstName))
            end
        end
        if not texture then
            local models = ReplicatedStorage:FindFirstChild("GiftedBeeModels")
            texture = textureOf(models and models:FindFirstChild(firstName))
        end
    end
    beeFaceCache[key] = texture or false
    if not texture then
        print("[BSS UI] bee icon not found for: " .. tostring(beeType) .. " (gifted=" .. tostring(gifted and true or false) .. ")")
    end
    return texture
end
local hiveCells
do
    local page = UI._pages.Hive
    if page then
        create("TextLabel", {
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = "HIVE OVERVIEW",
            TextColor3 = T.AccentDim,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, page)
        hiveCells = {}
        local hiveKeys = {
            {"Bees", "BEES"},
            {"Gifted", "GIFTED"},
            {"AverageLevel", "AVG LEVEL"},
            {"Blue", "BLUE"},
            {"Red", "RED"},
            {"Event", "EVENT"},
        }
        for index, entry in ipairs(hiveKeys) do
            local rowIndex = math.ceil(index / 2)
            local rowFrame = hiveCells["Row" .. rowIndex]
            if not rowFrame then
                rowFrame = create("Frame", {
                    Name = "Row" .. rowIndex,
                    LayoutOrder = 10 + rowIndex,
                    Size = UDim2.new(1, 0, 0, 46),
                    BackgroundTransparency = 1,
                }, page)
                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 6),
                }, rowFrame)
                hiveCells["Row" .. rowIndex] = rowFrame
            end
            local cell = corner(create("Frame", {
                Name = "Cell_" .. entry[1],
                Size = UDim2.new(0.5, -3, 1, 0),
                BackgroundColor3 = T.Panel,
            }, rowFrame), R_CTRL)
            strokeOf(cell, T.Stroke, 1, 0.6)
            create("TextLabel", {
                Size = UDim2.new(1, -14, 0, 14),
                Position = UDim2.fromOffset(8, 6),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = entry[2],
                TextColor3 = T.TextDim,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, cell)
            local valueLabel = create("TextLabel", {
                Size = UDim2.new(1, -14, 0, 20),
                Position = UDim2.fromOffset(8, 21),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "-",
                TextColor3 = T.Text,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, cell)
            hiveCells[entry[1]] = valueLabel
        end
        -- SHOW HIVE toggle: comb ẩn mặc định, bấm mới hiện tổ ong (bấm lại ẩn).
        local hiveShown = false
        local toggleRow = corner(create("Frame", {
            Name = "ShowHiveToggle",
            LayoutOrder = 15,
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = T.Panel,
        }, page), R_CTRL)
        strokeOf(toggleRow, T.Stroke, 1, 0.55)
        create("TextLabel", {
            Size = UDim2.new(1, -76, 1, 0),
            Position = UDim2.fromOffset(14, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = "🍯  Show Hive",
            TextColor3 = T.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, toggleRow)
        local hiveTrack = corner(create("TextButton", {
            Name = "Track",
            Size = UDim2.fromOffset(48, 26),
            Position = UDim2.new(1, -60, 0.5, -13),
            BackgroundColor3 = T.PanelLight,
            Text = "",
            AutoButtonColor = false,
        }, toggleRow), R_PILL)
        strokeOf(hiveTrack, T.Stroke, 1, 0.4)
        local hiveKnob = corner(create("Frame", {
            Name = "Knob",
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.fromOffset(3, 3),
            BackgroundColor3 = T.TextDim,
        }, hiveTrack), R_PILL)
        -- SHOW HIVE: tổ ong lục giác 50 slot giống ảnh mẫu - flat-top, cột
        -- chẵn/lẻ lệch nửa ô, màu theo rarity, GIFTED viền vàng + ✦, mặt ong
        -- thật ở giữa, level góc dưới-trái có viền đen. Page tự scroll.
        local gridFrame = corner(create("Frame", {
            Name = "HiveGrid",
            LayoutOrder = 20,
            Size = UDim2.new(1, 0, 0, 21 + GRID_H + 12),
            BackgroundColor3 = T.Panel,
            Visible = false,
        }, page), R_CARD)
        strokeOf(gridFrame, T.Stroke, 1, 0.6)
        vGradient(gridFrame, 0, 0.12)
        local hivePattern = resolveHivePattern()
        if hivePattern then
            create("ImageLabel", {
                Name = "Pattern",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = hivePattern,
                ImageColor3 = T.Accent,
                ImageTransparency = 0.9,
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.fromOffset(58, 58),
                ZIndex = 0,
            }, gridFrame)
        end
        local gridCountLabel = create("TextLabel", {
            Size = UDim2.new(1, -14, 0, 16),
            Position = UDim2.fromOffset(8, 3),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "HONEYCOMB  -/50",
            TextColor3 = T.TextDim,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, gridFrame)
        hiveCells.GridCount = gridCountLabel
        local gridHolder = create("Frame", {
            Name = "Comb",
            Size = UDim2.fromOffset(GRID_W, GRID_H),
            Position = UDim2.new(0.5, -GRID_W / 2, 0, 21),
            BackgroundTransparency = 1,
        }, gridFrame)
        hiveCells.GridSlot = {}
        for slot = 1, 50 do
            local col = (slot - 1) % GRID_COLS        -- X 1..5
            local row = math.floor((slot - 1) / GRID_COLS) -- Y 1..10
            local cx = col * COL_PITCH
            local cy = row * ROW_PITCH + (col % 2 == 0 and COL_OFFSET or 0)
            local cell = create("Frame", {
                Name = "Slot" .. slot,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(cx, cy),
                Size = UDim2.fromOffset(HEX_W, HEX_H),
                Visible = false,
            }, gridHolder)
            -- Viền (hex ngoài) + ruột (hex trong nhỏ hơn) = viền theo silhouette.
            local border = makeHex(cell, 1)
            local fill = makeHex(cell, 2)
            layoutHex(border, HEX_W, HEX_H, 0, 0, T.Background)
            layoutHex(fill, HEX_W - 4, HEX_H - 4, 2, 2, T.PanelLight)
            local face = makeHexFace(cell, 3)
            local levelText = create("TextLabel", {
                Name = "Level",
                Size = UDim2.fromOffset(36, 16),
                Position = UDim2.fromOffset(8, HEX_H - 20),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = Color3.new(0, 0, 0),
                ZIndex = 4,
            }, cell)
            local star = create("TextLabel", {
                Name = "Star",
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.fromOffset(HEX_W - 22, 5),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "✦",
                TextColor3 = GOLD,
                TextSize = 13,
                TextStrokeTransparency = 0.4,
                TextStrokeColor3 = Color3.new(0, 0, 0),
                Visible = false,
                ZIndex = 4,
            }, cell)
            hiveCells.GridSlot[slot] = {
                Frame = cell, Border = border, Fill = fill,
                Level = levelText, Face = face, Star = star,
            }
        end
        -- Nối dây Show Hive: bật/tắt comb, nảy knob, đổi màu track theo trạng thái.
        hiveCells.GridFrame = gridFrame
        local function renderHiveToggle()
            hiveTrack.BackgroundColor3 = hiveShown and T.Accent or T.PanelLight
            hiveKnob.BackgroundColor3 = hiveShown and T.Background or T.TextDim
            TweenService:Create(hiveKnob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
                Position = hiveShown and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
            }):Play()
        end
        hiveTrack.MouseButton1Click:Connect(function()
            hiveShown = not hiveShown
            gridFrame.Visible = hiveShown
            renderHiveToggle()
        end)
        renderHiveToggle()
    end
end

-- Toasts (góc phải trên, xếp chồng, tự biến mất)
-- =============================================================================
local toastHolder = create("Frame", {
    Name = "Toasts",
    Size = UDim2.fromOffset(300, 400),
    Position = UDim2.new(1, -320, 0, 8),
    BackgroundTransparency = 1,
}, rootGui)
create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
}, toastHolder)

function UI.Notify(title, message, seconds, kind)
    local palette = {
        info = {Bar = T.Accent, Icon = "ℹ️"},
        good = {Bar = T.Good, Icon = "✅"},
        warn = {Bar = T.Bad, Icon = "⚠️"},
    }
    local skin = palette[kind] or palette.info
    local card = corner(create("Frame", {
        Name = "Toast",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = T.Panel,
        Position = UDim2.new(1, 60, 0, 0),
    }, toastHolder), R_CARD)
    strokeOf(card, skin.Bar, 1, 0.2)
    create("Frame", {
        Size = UDim2.new(0, 4, 1, -10),
        Position = UDim2.fromOffset(4, 5),
        BackgroundColor3 = skin.Bar,
        BorderSizePixel = 0,
    }, card)
    create("TextLabel", {
        Size = UDim2.new(1, -44, 0, 18),
        Position = UDim2.fromOffset(16, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(title or ""),
        TextColor3 = T.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)
    create("TextLabel", {
        Size = UDim2.new(1, -44, 0, 26),
        Position = UDim2.fromOffset(16, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = tostring(message or ""),
        TextColor3 = T.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextWrapped = true,
    }, card)
    card.Position = UDim2.new(1, 60, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()
    if UI.Log then UI.Log(tostring(title or "") .. ": " .. tostring(message or ""), kind) end
    task.delay(math.max(1.5, tonumber(seconds) or 4), function()
        local out = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 60, 0, 0), BackgroundTransparency = 1,
        })
        out:Play()
        out.Completed:Wait()
        pcall(function() card:Destroy() end)
    end)
end

-- =============================================================================
-- Floating toggle pill (mặc định góc dưới-phải): ẩn/hiện cửa sổ, kéo được.
-- =============================================================================
local togglePill = corner(create("TextButton", {
    Name = "TogglePill",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16),
    Size = UDim2.fromOffset(48, 48),
    BackgroundColor3 = T.Panel,
    Text = "🐝",
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    AutoButtonColor = false,
}, rootGui), 14)
strokeOf(togglePill, T.Accent, 1.5, 0.25)
vGradient(togglePill, 0, 0.25)
hoverify(togglePill, "Panel", "PanelHover")
local pillMoved = false -- kéo pill rồi thả = KHÔNG toggle (chỉ click-thật mới)

do
    local pillDragging, pillDragStart, pillStart
    togglePill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            pillDragging = true
            pillMoved = false
            pillDragStart = input.Position
            pillStart = togglePill.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if pillDragging then UI._saveSoon() end
                    pillDragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if pillDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - pillDragStart
            if delta.Magnitude > 6 then pillMoved = true end
            -- Kéo theo Anchor(1,1): offset âm kể từ mép phải/dưới.
            local x = math.clamp(pillStart.X.Offset - delta.X, 8, rootGui.AbsoluteSize.X - 8)
            local y = math.clamp(pillStart.Y.Offset - delta.Y, 8, rootGui.AbsoluteSize.Y - 8)
            togglePill.Position = UDim2.new(1, -x, 1, -y)
        end
    end)
end

-- =============================================================================
-- Persistence (bss_kaitun_ui.json): vị trí + collapse + theme + Values
-- =============================================================================
local saveQueued = false
function UI._saveSoon()
    if saveQueued or type(writefileFn) ~= "function" then return end
    saveQueued = true
    task.delay(0.5, function()
        saveQueued = false
        local payload = {
            X = window.Position.X.Offset, Y = window.Position.Y.Offset,
            Collapsed = collapsed or nil, Theme = currentThemeName,
            PillX = -togglePill.Position.X.Offset, PillY = -togglePill.Position.Y.Offset,
            Values = UI.Values,
        }
        local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
        if ok and encoded then pcall(writefileFn, SAVE_NAME, encoded) end
    end)
end

local function loadSaved()
    if type(readfileFn) ~= "function" then return nil end
    local ok, content = pcall(readfileFn, SAVE_NAME)
    if not ok or type(content) ~= "string" or content == "" then return nil end
    local okDecode, data = pcall(function() return HttpService:JSONDecode(content) end)
    if okDecode and type(data) == "table" then return data end
    return nil
end

-- =============================================================================
-- Public API
-- =============================================================================
local function formatCount(number)
    number = tonumber(number) or 0
    local abs = math.abs(number)
    if abs >= 1e9 then return string.format("%.2fB", number / 1e9) end
    if abs >= 1e6 then return string.format("%.2fM", number / 1e6) end
    if abs >= 1e3 then return string.format("%.1fK", number / 1e3) end
    return tostring(math.floor(number + 0.5))
end

function UI.SetStatus(stateText, detailText)
    local combined = tostring(stateText or "")
        .. (detailText and detailText ~= "" and (" | " .. tostring(detailText)) or "")
    pcall(function() statusLabel.Text = combined end)
    -- Dot màu theo trạng thái: đang farm = xanh, meteor/warn = đỏ.
    local lower = string.lower(combined)
    local color = T.Good
    if string.find(lower, "meteor", 1, true) or string.find(lower, "avoid", 1, true) then
        color = T.Bad
    elseif string.find(lower, "convert", 1, true) or string.find(lower, "buy", 1, true) then
        color = T.Accent
    end
    pcall(function()
        TweenService:Create(statusDot, TweenInfo.new(0.3), {BackgroundColor3 = color}):Play()
    end)
end

function UI.SetStats(stats)
    if type(stats) ~= "table" then return end
    for key, value in pairs(stats) do
        local label = statCells[tostring(key)]
        if label then
            local rendered
            if key == "Uptime" then
                local seconds = math.max(0, math.floor(tonumber(value) or 0))
                rendered = string.format("%02d:%02d:%02d",
                    math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
            elseif key == "Honey" or key == "Capacity" or key == "HoneyPerHour" then
                rendered = formatCount(value)
            else
                rendered = tostring(value)
            end
            pcall(function() label.Text = rendered end)
        end
    end
    local honey = tonumber(stats.Honey)
    local capacity = tonumber(stats.Capacity)
    if honey and capacity and capacity > 0 then
        local ratio = math.clamp(honey / capacity, 0, 1)
        pcall(function()
            bagFill.Size = UDim2.new(ratio, 0, 1, 0)
            bagFill.BackgroundColor3 = ratio > 0.85 and T.Bad or T.Good
            bagFillText.Text = string.format("bag %s / %s (%d%%)",
                formatCount(honey), formatCount(capacity), math.floor(ratio * 100 + 0.5))
        end)
    end
    -- Sparkline: ghi mẫu honey/h mới rồi vẽ lại (giữ tối đa 40 mẫu).
    local hph = tonumber(stats.HoneyPerHour)
    if hph and renderHoneyGraph then
        table.insert(honeyHistory, hph)
        if #honeyHistory > 40 then table.remove(honeyHistory, 1) end
        pcall(renderHoneyGraph)
    end
end

function UI.SetGear(text)
    pcall(function() gearLine.Text = "next gear: " .. tostring(text or "-") end)
end

-- Log panel (Status): UI.Log("message", "info"|"good"|"warn"|"dim"). Giữ 40 dòng.
function UI.Log(message, kind)
    if logAppend then pcall(logAppend, message, kind) end
end

-- Hive tab: main đẩy {Bees, Gifted, AverageLevel, Blue, Red, Event}.
function UI.SetHive(stats)
    if type(stats) ~= "table" or type(hiveCells) ~= "table" then return end
    for key, value in pairs(stats) do
        local label = hiveCells[tostring(key)]
        if label then
            local rendered
            if key == "AverageLevel" then
                rendered = string.format("%.1f", tonumber(value) or 0)
            else
                rendered = tostring(value)
            end
            pcall(function() label.Text = rendered end)
        end
    end
end

-- SHOW HIVE: vẽ tổ ong lục giác 50 slot. entries = mảng {
--   Type = "Basic Bee", Gifted = true/false, Level = 7,
--   X = col 1-5, Y = row 1-10 (tuỳ chọn - thiếu thì điền tuần tự)}.
-- Màu theo rarity, gifted = viền vàng dày + ✦ + tint kim, mặt ong thật ở giữa.
function UI.SetHiveGrid(entries, existingSlots)
    if type(hiveCells) ~= "table" or type(hiveCells.GridSlot) ~= "table" then return end
    local darkBorder = T.Background
    local emptyFill = T.PanelLight
    -- Reset: ẩn hết, chỉ hiện slot đã MỞ trong hive (tổ thật chỉ có ô đã
    -- unlock). existingSlots = mảng {X=,Y=} các ô tồn tại; nil = hiện đủ 50.
    for slot = 1, 50 do
        local cell = hiveCells.GridSlot[slot]
        pcall(function()
            cell.Frame.Visible = false
            layoutHex(cell.Border, HEX_W, HEX_H, 0, 0, darkBorder)
            layoutHex(cell.Fill, HEX_W - 4, HEX_H - 4, 2, 2, emptyFill)
            setBeeFace(cell.Face, "")
            cell.Level.Text = ""
            cell.Star.Visible = false
        end)
    end
    if type(existingSlots) == "table" then
        for _, slot in ipairs(existingSlots) do
            if type(slot) == "table" and type(slot.X) == "number" and type(slot.Y) == "number" then
                -- 5 cột × 10 hàng: index = (Y-1)*5 + X.
                local index = math.clamp(math.floor((slot.Y - 1) * 5 + slot.X + 0.5), 1, 50)
                local cell = hiveCells.GridSlot[index]
                if cell then pcall(function() cell.Frame.Visible = true end) end
            end
        end
    else
        for slot = 1, 50 do
            local cell = hiveCells.GridSlot[slot]
            pcall(function() cell.Frame.Visible = true end)
        end
    end
    local list = type(entries) == "table" and entries or {}
    local filled = 0
    for index, entry in ipairs(list) do
        if type(entry) == "table" and entry.Type then
            filled += 1
            local slot = index
            if type(entry.X) == "number" and type(entry.Y) == "number" then
                slot = math.clamp(math.floor((entry.Y - 1) * 5 + entry.X + 0.5), 1, 50)
            end
            local cell = hiveCells.GridSlot[slot]
            if cell then
                local gifted = entry.Gifted and true or false
                local base = RARITY_COLORS[rarityOf(entry.Type)] or RARITY_COLORS.Common
                local fillC = gifted and base:Lerp(GOLD, 0.28) or base
                local borderC = gifted and GOLD or darkBorder
                local b = gifted and 4 or 2
                -- Mặt ong thật: bản gifted riêng (nền vàng) khi có ✦.
                local face = beeFaceTexture(entry.Type, gifted)
                pcall(function()
                    cell.Frame.Visible = true
                    layoutHex(cell.Border, HEX_W, HEX_H, 0, 0, borderC)
                    layoutHex(cell.Fill, HEX_W - 2 * b, HEX_H - 2 * b, b, b, fillC)
                    setBeeFace(cell.Face, face)
                    cell.Level.Text = tostring(tonumber(entry.Level) or "")
                    cell.Star.Visible = gifted
                end)
            end
        end
    end
    if hiveCells.GridCount then
        pcall(function() hiveCells.GridCount.Text = string.format("HONEYCOMB  %d/50", filled) end)
    end
end

-- =============================================================================
-- AUTO HIVE: đọc TRỰC TIẾP hive thật trong game (không cần main đẩy gì).
-- Công thức giống hệt hiveBeeCells của script chính: cell tên "C<x>,<y>",
-- loại ở CellType/BeeType, gifted = có con "GiftedCell", level ở
-- Level/BeeLevel/CellLevel (fallback qua ObjectValue "Bee"). Poll nhẹ mỗi
-- 2.5s và tự cập nhật cả 6 ô stat + comb 50 slot.
-- =============================================================================
-- Level fallback: module stats của game - stats.Honeycomb["x,y"].Level
-- (công thức hiveCellData của script chính). Lazy require, không yield.
local statCacheModule
local function getStatCache()
    if statCacheModule ~= nil then return statCacheModule end
    local module = ReplicatedStorage:FindFirstChild("ClientStatCache")
    if not module then return nil end
    local ok, result = pcall(require, module)
    statCacheModule = (ok and type(result) == "table") and result or false
    return statCacheModule
end

local statCacheLastUpdate = 0
local function statHiveLevel(x, y)
    local cache = getStatCache()
    if type(cache) ~= "table" then return nil end
    -- Get trước; nếu chưa có bảng Honeycomb (cache lạnh) thì Update một
    -- nhịp rồi Get lại - đúng vòng getStats của script chính.
    local ok, stats = pcall(cache.Get, cache)
    if not ok or type(stats) ~= "table" or type(stats.Honeycomb) ~= "table" then
        if type(cache.Update) == "function" and os.clock() - statCacheLastUpdate > 2 then
            statCacheLastUpdate = os.clock()
            pcall(cache.Update, cache)
            ok, stats = pcall(cache.Get, cache)
        end
    end
    if not ok or type(stats) ~= "table" then return nil end
    local honeycomb = stats.Honeycomb
    if type(honeycomb) ~= "table" then return nil end
    -- Dạng THẬT của bảng (khám phá từ atlas): Honeycomb["x<col>"]["y<row>"],
    -- level field tên "Lvl". Thử đủ các biến thể key cho chắc.
    local column = honeycomb["x" .. tostring(x)]
        or honeycomb[x] or honeycomb[tostring(x)]
        or honeycomb[tostring(x) .. "," .. tostring(y)]
    local cell = nil
    if type(column) == "table" then
        cell = column["y" .. tostring(y)]
            or column[y] or column[tostring(y)]
    end
    if type(cell) ~= "table" and type(column) == "table" then
        cell = column -- dạng phẳng "x,y" trả thẳng cell
    end
    if type(cell) ~= "table" then
        local row = honeycomb[x] or honeycomb[tostring(x)]
        if type(row) == "table" then
            cell = row[y] or row[tostring(y)]
        end
    end
    if type(cell) ~= "table" then
        for _, entry in pairs(honeycomb) do
            if type(entry) == "table" then
                local cx = tonumber(entry.CellX or entry.X or entry.Column)
                local cy = tonumber(entry.CellY or entry.Y or entry.Row)
                if cx == x and cy == y then
                    cell = entry
                    break
                end
            end
        end
    end
    if type(cell) == "table" then
        return tonumber(cell.Lvl or cell.Level or cell.BeeLevel or cell.CellLevel)
    end
    return nil
end

local function readHiveCell(cell)
    local x, y = cell.Name:match("^C(%d+),(%d+)$")
    if not x or not y then return nil end
    local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
    if not (cellType and cellType:IsA("ValueBase")) then return nil end
    local beeType = tostring(cellType.Value)
    -- Cell trống của game ghi "Empty" - phải lọc đủ cả 4 dạng (v1.2
    -- beeTypePresent) kẻo 50 ô "Empty" + COMB 50/50 như bản trước.
    local normalizedType = normalizeImageName(beeType)
    if normalizedType == "" or normalizedType == "none"
        or normalizedType == "empty" or normalizedType == "nil" then
        return nil
    end
    local level
    for _, name in ipairs({"Level", "BeeLevel", "CellLevel"}) do
        local value = cell:FindFirstChild(name)
        if value and value:IsA("ValueBase") and tonumber(value.Value) then
            level = tonumber(value.Value)
            break
        end
    end
    if not level then
        local bee = cell:FindFirstChild("Bee")
        if bee and bee:IsA("ObjectValue") and bee.Value then
            for _, name in ipairs({"Level", "BeeLevel"}) do
                local value = bee.Value:FindFirstChild(name)
                if value and value:IsA("ValueBase") and tonumber(value.Value) then
                    level = tonumber(value.Value)
                    break
                end
            end
        end
    end
    if not level then
        level = statHiveLevel(tonumber(x), tonumber(y))
    end
    return {
        X = tonumber(x), Y = tonumber(y),
        Type = beeType,
        Gifted = cell:FindFirstChild("GiftedCell") ~= nil,
        Level = level,
    }
end

local autoHiveRunning = false
function UI.AutoHive(intervalSeconds)
    if autoHiveRunning then return end
    autoHiveRunning = true
    task.spawn(function()
        while rootGui.Parent do
            local reference = Player and Player:FindFirstChild("Honeycomb")
            local hive = reference and reference:IsA("ObjectValue") and reference.Value
            local cellsFolder = hive and hive:FindFirstChild("Cells")
            if cellsFolder then
                local entries = {}
                local slotList = {}
                local bees, giftedCount = 0, 0
                local blueCount, redCount, eventCount = 0, 0, 0
                local levelTotal, levelCount = 0, 0
                for _, cell in ipairs(cellsFolder:GetChildren()) do
                    local entry = readHiveCell(cell)
                    if entry then
                        table.insert(entries, entry)
                        table.insert(slotList, {X = entry.X, Y = entry.Y})
                        bees += 1
                        if entry.Gifted then giftedCount += 1 end
                        if entry.Level then
                            levelTotal += entry.Level
                            levelCount += 1
                        end
                        local n = normalizeImageName(entry.Type)
                        local bare = n:gsub("bee$", "")
                        if HIVE_EVENT_MARKS[n] or HIVE_EVENT_MARKS[bare] then
                            eventCount += 1
                        elseif n:find("blue", 1, true) then
                            blueCount += 1
                        elseif n:find("red", 1, true) then
                            redCount += 1
                        end
                    else
                        -- Ô đã mở nhưng trống: vẫn vẽ placeholder cho đúng
                        -- hình dáng tổ thật.
                        local ex, ey = cell.Name:match("^C(%d+),(%d+)$")
                        if ex and ey then
                            table.insert(slotList, {X = tonumber(ex), Y = tonumber(ey)})
                        end
                    end
                end
                UI.SetHiveGrid(entries, slotList)
                UI.SetHive{
                    Bees = bees,
                    Gifted = giftedCount,
                    AverageLevel = levelCount > 0 and (levelTotal / levelCount) or 0,
                    Blue = blueCount,
                    Red = redCount,
                    Event = eventCount,
                }
            end
            task.wait(math.max(1, tonumber(intervalSeconds) or 2.5))
        end
        autoHiveRunning = false
    end)
end

function UI.SetPlanters(entries)
    for slot = 1, 3 do
        local entry = type(entries) == "table" and entries[slot] or nil
        local cell = planterCells[slot]
        if cell then
            pcall(function()
                if entry then
                    cell.Name.Text = tostring(entry.Name or "Planter")
                    cell.Field.Text = tostring(entry.Field or "")
                    cell.Fill.Size = UDim2.new(math.clamp(tonumber(entry.Percent) or 0, 0, 1), 0, 1, 0)
                    cell.Icon.Image = resolveGameImage(tostring(entry.Name or "")) or ""
                else
                    cell.Name.Text = "-"
                    cell.Field.Text = ""
                    cell.Fill.Size = UDim2.new(0, 0, 1, 0)
                    cell.Icon.Image = ""
                end
            end)
        end
    end
end

-- Public: lấy asset string (rbxassetid://...) của icon item trong game - gán
-- trực tiếp vào bất kỳ ImageLabel.Image nào, không cần tải file.
function UI.GetGameImage(itemName)
    return resolveGameImage(itemName)
end

function UI.DefineControls(definitions)
    if type(definitions) ~= "table" then return end
    -- Đóng popup dropdown đang mở (parent = rootGui, không nằm trong row).
    for _, closer in pairs(dropdownPopups) do pcall(closer) end
    dropdownPopups = {}
    for _, rows in pairs(UI._built) do
        for _, row in ipairs(rows) do pcall(function() row:Destroy() end) end
    end
    UI._built = {}
    local builders = {
        Toggle = buildToggle, Slider = buildSlider, Section = buildSection,
        Button = buildButton, Textbox = buildTextbox, Input = buildTextbox,
        Dropdown = buildDropdown, Keybind = buildKeybind,
    }
    for index, def in ipairs(definitions) do
        local page = UI._pages[tostring(def.Tab)]
        local kind = tostring(def.Kind or "Toggle")
        local build = builders[kind] or buildToggle
        -- Section chỉ cần Label; các kind khác cần Key.
        if page and def.Tab ~= "Status" and (def.Key or kind == "Section") then
            local row = build(page, def, 100 + index)
            local list = UI._built[tostring(def.Tab)] or {}
            table.insert(list, row)
            UI._built[tostring(def.Tab)] = list
        end
    end
end

function UI.OnChange(key, callback)
    if type(key) == "string" and type(callback) == "function" then
        UI._callbacks[key] = callback
        task.spawn(function() pcall(callback, UI.Values[key]) end)
    end
end

function UI.SetValues(values)
    if type(values) ~= "table" then return end
    for key, value in pairs(values) do
        UI.Values[key] = value
        local ref = UI._refs[tostring(key)]
        if ref and ref.Render then pcall(ref.Render, value) end
    end
end

local uiVisible = true
local windowHome = nil -- vị trí thật của window (trước khi slide-out ẩn đi)
function UI.Toggle(visible)
    pcall(function()
        if visible == nil then visible = not uiVisible end
        visible = visible and true or false
        if visible == uiVisible then return end
        uiVisible = visible
        if visible then
            local home = windowHome or window.Position
            windowHome = nil
            window.Position = home
            window.Visible = true
            shadow.Visible = true
            window.Position = UDim2.new(home.X.Scale, home.X.Offset + 70,
                home.Y.Scale, home.Y.Offset)
            TweenService:Create(window, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = home,
            }):Play()
            TweenService:Create(shadow, TweenInfo.new(0.35), {BackgroundTransparency = 0.82}):Play()
        else
            -- Nhớ vị trí thật trước khi trượt ra ngoài màn hình.
            windowHome = window.Position
            local slideOut = UDim2.new(windowHome.X.Scale, windowHome.X.Offset + 70,
                windowHome.Y.Scale, windowHome.Y.Offset)
            TweenService:Create(window, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = slideOut,
            }):Play()
            TweenService:Create(shadow, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
            task.delay(0.32, function()
                if not uiVisible then
                    window.Visible = false
                    shadow.Visible = false
                end
            end)
        end
    end)
end

togglePill.MouseButton1Click:Connect(function()
    -- Kéo-để-di-chuyển không được tính là click toggle.
    if pillMoved then pillMoved = false return end
    -- Feedback nảy nhẹ rồi toggle.
    TweenService:Create(togglePill, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = UDim2.fromOffset(42, 42),
    }):Play()
    task.delay(0.1, function()
        TweenService:Create(togglePill, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(48, 48),
        }):Play()
    end)
    UI.Toggle()
end)

function UI.CycleTheme()
    local names = {}
    for name in pairs(THEMES) do table.insert(names, name) end
    table.sort(names)
    local index = table.find(names, currentThemeName) or 1
    UI.SetTheme(names[index % #names + 1])
end

function UI.SetTheme(name)
    local palette = THEMES[name] or THEMES.Honey
    local oldPalette = T
    currentThemeName = name
    T = palette
    -- Repaint TOÀN CÂY (mọi card/stroke/control/hex/toast/pill/scrollbar).
    repaintTheme(oldPalette, palette)
    for _, listener in ipairs(UI._themeListeners) do
        pcall(listener, palette)
    end
    UI.Notify("Theme", "Switched to " .. currentThemeName, 2, "info")
    UI._saveSoon()
end

function UI.Destroy()
    pcall(function() rootGui:Destroy() end)
    if ENV.BSSKaitunUI == UI then ENV.BSSKaitunUI = nil end
end

-- =============================================================================
-- Boot
-- =============================================================================
-- 1) Config từ main (nếu đặt trước) rồi file lưu đè lên các khóa đã lưu.
if type(ENV.BSS_KAITUN_CONFIG) == "table" then
    for key, value in pairs(ENV.BSS_KAITUN_CONFIG) do UI.Values[key] = value end
end
local saved = loadSaved()
if saved then
    if type(saved.Values) == "table" then
        for key, value in pairs(saved.Values) do UI.Values[key] = value end
    end
    if type(saved.X) == "number" and type(saved.Y) == "number" then
        local maxX = math.max(80, rootGui.AbsoluteSize.X - 80)
        local maxY = math.max(40, rootGui.AbsoluteSize.Y - 40)
        local x = math.clamp(saved.X, -WINDOW_SIZE.X.Offset + 80, maxX)
        local y = math.clamp(saved.Y, 0, maxY)
        window.Position = UDim2.fromOffset(x, y)
        shadow.Position = UDim2.fromOffset(x - 5, y - 6)
    end
    if type(saved.PillX) == "number" and type(saved.PillY) == "number" then
        local px = math.clamp(saved.PillX, 8, math.max(8, rootGui.AbsoluteSize.X - 8))
        local py = math.clamp(saved.PillY, 8, math.max(8, rootGui.AbsoluteSize.Y - 8))
        togglePill.Position = UDim2.new(1, -px, 1, -py)
    end
    if saved.Theme and THEMES[saved.Theme] then
        currentThemeName = saved.Theme
        T = THEMES[saved.Theme]
    end
end

-- Collapse (sau khi restore vị trí, áp trạng thái lưu).
themeButton.MouseButton1Click:Connect(function() UI.CycleTheme() end)
collapseButton.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    setText(collapseButton, collapsed and "+" or "—")
    TweenService:Create(bodyHolder, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
        Size = collapsed and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 1, -40),
    }):Play()
    TweenService:Create(window, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
        Size = collapsed and UDim2.fromOffset(WINDOW_SIZE.X.Offset, 40) or WINDOW_SIZE,
    }):Play()
    TweenService:Create(shadow, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
        Size = collapsed and UDim2.fromOffset(WINDOW_SIZE.X.Offset + 10, 46)
            or WINDOW_SIZE + UDim2.fromOffset(10, 12),
    }):Play()
    UI._saveSoon()
end)

-- Animation mở cửa sổ lần đầu: trượt từ phải + fade shadow.
if not (saved and saved.Collapsed) then
    local finalX = window.Position
    window.Position = UDim2.new(finalX.X.Scale, finalX.X.Offset + 60, finalX.Y.Scale, finalX.Y.Offset)
    shadow.BackgroundTransparency = 1
    TweenService:Create(window, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = finalX,
    }):Play()
    TweenService:Create(shadow, TweenInfo.new(0.45), {BackgroundTransparency = 0.82}):Play()
else
    collapsed = true
    setText(collapseButton, "+")
    bodyHolder.Size = UDim2.new(1, 0, 0, 0)
    window.Size = UDim2.fromOffset(WINDOW_SIZE.X.Offset, 40)
    shadow.Size = UDim2.fromOffset(WINDOW_SIZE.X.Offset + 10, 46)
end

-- Auto hive data: đọc comb thật mỗi 2.5s ngay khi UI load (main vẫn có thể
-- đè bằng SetHiveGrid/SetHive riêng nếu muốn).
UI.AutoHive()

ENV.BSSKaitunUI = UI
ENV.__BSSKaitunUI_Cleanup = function()
    pcall(function() rootGui:Destroy() end)
    if ENV.BSSKaitunUI == UI then ENV.BSSKaitunUI = nil end
    ENV.__BSSKaitunUI_Cleanup = nil
end

return UI
