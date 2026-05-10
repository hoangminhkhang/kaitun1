local Library = loadstring([
	if getgenv().Tvk then 
		if game.CoreGui:FindFirstChild("Sea Hub GUI") then for i, v in ipairs(game.CoreGui:GetChildren()) do if v.Name == "Sea Hub GUI" then v:Destroy() end end end
	end
	getgenv().Tvk = true
	
	local IndexUIColor = {
		["Border Color"] = Color3.fromRGB(131, 181, 255),
		["Click Effect Color"] = Color3.fromRGB(230, 230, 230),
		["Setting Icon Color"] = Color3.fromRGB(230, 230, 230),
		["Logo Image"] = "rbxassetid://6248942117",
		["Search Icon Color"] = Color3.fromRGB(255, 255, 255),
		["Search Icon Highlight Color"] = Color3.fromRGB(131, 181, 255),
		["GUI Text Color"] = Color3.fromRGB(230, 230, 230),
		["Text Color"] = Color3.fromRGB(230, 230, 230),
		["Placeholder Text Color"] = Color3.fromRGB(178, 178, 178),
		["Title Text Color"] = Color3.fromRGB(131, 181, 255),
		["Background 1 Color"] = Color3.fromRGB(43, 43, 43),
		["Background 1 Transparency"] = 0,
		["Background 2 Color"] = Color3.fromRGB(90, 90, 90),
		["Background 3 Color"] = Color3.fromRGB(53, 53, 53),
		["Background Image"] = "",
		["Page Selected Color"] = Color3.fromRGB(131, 181, 255),
		["Section Text Color"] = Color3.fromRGB(131, 181, 255),
		["Section Underline Color"] = Color3.fromRGB(131, 181, 255),
		["Toggle Border Color"] = Color3.fromRGB(131, 181, 255),
		["Toggle Checked Color"] = Color3.fromRGB(230, 230, 230),
		["Toggle Desc Color"] = Color3.fromRGB(185, 185, 185),
		["Button Color"] = Color3.fromRGB(131, 181, 255),
		["Label Color"] = Color3.fromRGB(101, 152, 220),
		["Dropdown Icon Color"] = Color3.fromRGB(230, 230, 230),
		["Dropdown Selected Color"] = Color3.fromRGB(131, 181, 255),
		["Textbox Highlight Color"] = Color3.fromRGB(131, 181, 255),
		["Box Highlight Color"] = Color3.fromRGB(131, 181, 255),
		["Slider Line Color"] = Color3.fromRGB(75, 75, 75),
		["Slider Highlight Color"] = Color3.fromRGB(59, 82, 115),
		["Tween Animation 1 Speed"] = 0.25,
		["Tween Animation 2 Speed"] = 0.5,
		["Tween Animation 3 Speed"] = 0.1,
	}
	local UpdateCallBack = {}
	for k,v in pairs(IndexUIColor) do 
		UpdateCallBack[k] = {}
	end
	local SettingsRac = {}
	for k,v in pairs(IndexUIColor) do 
		SettingsRac[k] = {
			Color = v,
			Rainbow = false,
			Breathing = {
				Toggle = false,
				Color1 = Color3.new(),
				Color2 = Color3.new()
			}
		}
	end
	local function Rac(color)
		return {math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255), "ColorMarker"}
	end
	function CorrectTable(tabl)
		local ret = {}
		for k, v in pairs(tabl) do 
			if typeof(v) == "Color3" then 
				ret[k] = Rac(v)
			elseif type(v) == "table" then
				ret[k] = CorrectTable(v)
			else
				ret[k] = v
			end
		end
		return ret
	end
	function DCorrectTable(tabl)
		local ret = {}
		for k,v in pairs(tabl) do 
			if type(v) == "table" and v[4] == "ColorMarker" then 
				ret[k] = Color3.fromRGB(unpack(v))
			elseif type(v) == "table" then
				ret[k] = DCorrectTable(v)
			else
				ret[k] = v
			end
		end
		return ret
	end
	local HttpService = game:GetService("HttpService")
	local SaveCustomFileName = "!CustomUI.json"
	 
	
	function SaveCustomUISettings()
		local HttpService = game:GetService("HttpService")
		if not isfolder("Sea Hub") then
			makefolder("Sea Hub")
		end
		writefile("Sea Hub/" .. SaveCustomFileName, HttpService:JSONEncode(CorrectTable(SettingsRac)))
	end
	
	function ReadCustomUISetting() 
		local s,e = pcall(function() 
			local HttpService = game:GetService("HttpService")
			if not isfolder("Sea Hub") then
				makefolder("Sea Hub")
			end
			return HttpService:JSONDecode(readfile("Sea Hub/" .. SaveCustomFileName))
		end)
		if s then return e 
		else
			SaveCustomUISettings()
			return ReadCustomUISetting()
		end
	end
	SettingsRac=DCorrectTable(ReadCustomUISetting())
	for k,v in pairs(SettingsRac) do 
		IndexUIColor[k]=v.Color
	end
	if not getgenv().ractvkretarddumb then
		task.spawn(function() 
			while task.wait(1) do
				SaveCustomUISettings()
			end
		end)
		getgenv().ractvkretarddumb = true
	end
	getgenv().UIColor=setmetatable({},{
		__newindex=function(Self, Key, Value) 
			if UpdateCallBack[Key] then 
				for k, v in pairs(UpdateCallBack[Key]) do 
					v()
				end
			end
			rawset(IndexUIColor,Key,Value)
			SettingsRac[Key].Color = Value
		end,
		__index = IndexUIColor
	})
	
	local currcolor = {}
	local Library = {};
	local Library_Function = {}
	local TweenService = game:GetService('TweenService')
	local uis = game:GetService("UserInputService")
	
	--Button Effect
	function Library_Function.ButtonEffect()
		local mouse = game:GetService("Players").LocalPlayer:GetMouse();
		local buttoneffect = Drawing.new("Circle")
		buttoneffect.Visible = true
		buttoneffect.Radius = 10
		buttoneffect.Filled = true
		buttoneffect.Color = getgenv().UIColor["Click Effect Color"]
		
		buttoneffect.Position = Vector2.new(mouse.X, mouse.Y + 35)
	
	
		local EffectFolder = Instance.new('Folder')
		EffectFolder.Parent = Library_Function.Gui
		EffectFolder.Name = 'ButtonEffectFolder'
	
		local a = Instance.new('NumberValue')
		a.Value = 10
		a.Parent = EffectFolder
		a.Name = 'RadiusValue'
	
		local b = Instance.new('NumberValue')
		b.Value = 1
		b.Parent = EffectFolder
		b.Name = 'TransparencyValue'
	
		TweenService:Create(a,TweenInfo.new(.25),{Value = 25}):Play()
		TweenService:Create(b,TweenInfo.new(.25),{Value = 0}):Play()
	
	
		a:GetPropertyChangedSignal('Value'):Connect(function()
			buttoneffect.Radius = a.Value
		end)
	
	
		b:GetPropertyChangedSignal('Value'):Connect(function()
			buttoneffect.Transparency = b.Value
		end)
	
		task.wait(.5)
		EffectFolder:Destroy()
	end
	
	Library_Function.GetIMG = function(url)
		local File = 'SynAsset ['
		local returnimage = ""
		if string.find(url, "rbxassetid://") then
			returnimage = url
		else
			pcall(function()
				if url and type(url) == 'string' and tostring(game:HttpGet(url)):find('PNG') then
					for i = 1, 5 do
						File = tostring(File..string.char(math.random(65, 122)))
					end
					File = File..'].png'
					writefile(File, game:HttpGet(url))
					task.spawn(function()
						task.wait(5)
						delfile(File)
					end)
					returnimage = getsynasset(File)
				end
			end)
		end
		return returnimage
	end
	
	
	Library_Function.Gui = Instance.new('ScreenGui')
	Library_Function.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Library_Function.Gui.Name = 'Sea Hub GUI'
	
	getgenv().ReadyForGuiLoaded = false
	task.spawn(function()
		Library_Function.Gui.Enabled = false
		repeat task.wait()
		until getgenv().ReadyForGuiLoaded
		Library_Function.Gui.Enabled = true
	end)
	
	Library_Function.NotiGui = Instance.new('ScreenGui')
	Library_Function.NotiGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Library_Function.NotiGui.Name = 'Sea Hub Notification'
	
	
	local NotiContainer = Instance.new("Frame")
	local NotiList = Instance.new("UIListLayout")
	
	
	NotiContainer.Name = "NotiContainer"
	NotiContainer.Parent = Library_Function.NotiGui
	NotiContainer.AnchorPoint = Vector2.new(1, 1)
	NotiContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	NotiContainer.BackgroundTransparency = 1.000
	NotiContainer.Position = UDim2.new(1, -5, 1, -5)
	NotiContainer.Size = UDim2.new(0, 350, 1, -10)
	
	NotiList.Name = "NotiList"
	NotiList.Parent = NotiContainer
	NotiList.SortOrder = Enum.SortOrder.LayoutOrder
	NotiList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	NotiList.Padding = UDim.new(0, 5)
	
	
	Library_Function.Gui.Parent = game:GetService('CoreGui')
	Library_Function.NotiGui.Parent = game:GetService('CoreGui')
	
	
	
	function Library_Function.Getcolor(color)
		return {math.floor(color.r*255),math.floor(color.g*255),math.floor(color.b*255)}
	end
	
	function Library.CreateNoti(Setting)
		getgenv().TitleNameNoti = Setting.Title or ""; 
		local Desc = Setting.Desc; 
		local Timeshow = Setting.ShowTime or 10;
	
		local NotiFrame = Instance.new("Frame")
		local Noticontainer = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local Topnoti = Instance.new("Frame")
		local Ruafimg = Instance.new("ImageLabel")
		local RuafimgCorner = Instance.new("UICorner")
		local TextLabelNoti = Instance.new("TextLabel")
		local CloseContainer = Instance.new("Frame")
		local CloseImage = Instance.new("ImageLabel")
		local TextButton = Instance.new("TextButton")
		local TextLabelNoti2 = Instance.new("TextLabel")
	
		NotiFrame.Name = "NotiFrame"
		NotiFrame.Parent = NotiContainer
		NotiFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		NotiFrame.BackgroundTransparency = 1.000
		NotiFrame.ClipsDescendants = true
		NotiFrame.Position = UDim2.new(0, 0, 0, 0)
		NotiFrame.Size = UDim2.new(1, 0, 0, 0)
		NotiFrame.AutomaticSize = Enum.AutomaticSize.Y
	
		Noticontainer.Name = "Noticontainer"
		Noticontainer.Parent = NotiFrame
		Noticontainer.Position = UDim2.new(1, 0, 0, 0)
		Noticontainer.Size = UDim2.new(1, 0, 1, 6)
		Noticontainer.AutomaticSize = Enum.AutomaticSize.Y
		Noticontainer.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
		table.insert(UpdateCallBack["Background 3 Color"],function() 
			Noticontainer.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
		end)
	
		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = Noticontainer
	
		Topnoti.Name = "Topnoti"
		Topnoti.Parent = Noticontainer
		Topnoti.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		Topnoti.BackgroundTransparency = 1.000
		Topnoti.Position = UDim2.new(0, 0, 0, 5)
		Topnoti.Size = UDim2.new(1, 0, 0, 25)
	
		Ruafimg.Name = "Ruafimg"
		Ruafimg.Parent = Topnoti
		Ruafimg.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		Ruafimg.BackgroundTransparency = 1.000
		Ruafimg.Position = UDim2.new(0, 10, 0, 0)
		Ruafimg.Size = UDim2.new(0, 25, 0, 25)
		Ruafimg.Image = getgenv().UIColor["Logo Image"]
		table.insert(UpdateCallBack["Logo Image"], function() 
			Ruafimg.Image = Library_Function.GetIMG(getgenv().UIColor["Logo Image"])
		end)
		
	
		RuafimgCorner.CornerRadius = UDim.new(1, 0)
		RuafimgCorner.Name = "RuafimgCorner"
		RuafimgCorner.Parent = Ruafimg
		
		local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
		local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
		local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
		local color = colorR .. ',' .. colorG .. ',' .. colorB
		TextLabelNoti.Text = "<font color=\"rgb(" .. color .. ")\">Sea Hub</font> "..getgenv().TitleNameNoti
	
		table.insert(UpdateCallBack["Title Text Color"],function() 
			local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
			local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
			local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
			local color = colorR .. ',' .. colorG .. ',' .. colorB
			TextLabelNoti.Text = "<font color=\"rgb(" .. color .. ")\">Sea Hub</font> "..getgenv().TitleNameNoti
		end)
		
		TextLabelNoti.Name = "TextLabelNoti"
		TextLabelNoti.Parent = Topnoti
		TextLabelNoti.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		TextLabelNoti.BackgroundTransparency = 1.000
		TextLabelNoti.Position = UDim2.new(0, 40, 0, 0)
		TextLabelNoti.Size = UDim2.new(1, -40, 1, 0)
		TextLabelNoti.Font = Enum.Font.GothamBold
		TextLabelNoti.TextSize = 14.000
		TextLabelNoti.TextWrapped = true
		TextLabelNoti.TextXAlignment = Enum.TextXAlignment.Left
		TextLabelNoti.RichText = true
		TextLabelNoti.TextColor3 = getgenv().UIColor["GUI Text Color"]
		table.insert(UpdateCallBack["GUI Text Color"], function() 
			TextLabelNoti.TextColor3 = getgenv().UIColor["GUI Text Color"]
		end)
	
		CloseContainer.Name = "CloseContainer"
		CloseContainer.Parent = Topnoti
		CloseContainer.AnchorPoint = Vector2.new(1, 0.5)
		CloseContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		CloseContainer.BackgroundTransparency = 1.000
		CloseContainer.Position = UDim2.new(1, -4, 0.5, 0)
		CloseContainer.Size = UDim2.new(0, 22, 0, 22)
	
		CloseImage.Name = "CloseImage"
		CloseImage.Parent = CloseContainer
		CloseImage.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		CloseImage.BackgroundTransparency = 1.000
		CloseImage.Size = UDim2.new(1, 0, 1, 0)
		CloseImage.Image = "rbxassetid://3926305904"
		CloseImage.ImageRectOffset = Vector2.new(284, 4)
		CloseImage.ImageRectSize = Vector2.new(24, 24)
		CloseImage.ImageColor3 = getgenv().UIColor["Search Icon Color"]
		table.insert(UpdateCallBack["Search Icon Color"],function() 
			CloseImage.ImageColor3 = getgenv().UIColor["Search Icon Color"]
		end)
	
		TextButton.Parent = CloseContainer
		TextButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		TextButton.BackgroundTransparency = 1.000
		TextButton.Size = UDim2.new(1, 0, 1, 0)
		TextButton.Font = Enum.Font.SourceSans
		TextButton.Text = ""
		TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		TextButton.TextSize = 14.000
	
		if Desc then
			TextLabelNoti2.Name = 'TextColor'
			TextLabelNoti2.Parent = Noticontainer
			TextLabelNoti2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			TextLabelNoti2.BackgroundTransparency = 1.000
			TextLabelNoti2.Position = UDim2.new(0, 10, 0, 35)
			TextLabelNoti2.Size = UDim2.new(1, -15, 0, 0)
			TextLabelNoti2.Font = Enum.Font.GothamBold
			TextLabelNoti2.Text = Desc
			TextLabelNoti2.TextSize = 14.000
			TextLabelNoti2.TextXAlignment = Enum.TextXAlignment.Left
			TextLabelNoti2.RichText = true
			TextLabelNoti2.TextColor3 = getgenv().UIColor["Text Color"]
			TextLabelNoti2.AutomaticSize = Enum.AutomaticSize.Y
			TextLabelNoti2.TextWrapped = true
			table.insert(UpdateCallBack["Text Color"],function() 
				TextLabelNoti2.TextColor3 = getgenv().UIColor["Text Color"]
			end)
		end
	
		local function remove()
			TweenService:Create(Noticontainer,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Position = UDim2.new(1,0,0,0)}):Play()
			task.wait(.25)
			NotiFrame:Destroy()
		end
	
		TweenService:Create(Noticontainer,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Position = UDim2.new(0,0,0,0)}):Play()
	
		TextButton.MouseEnter:Connect(function()
			TweenService:Create(CloseImage, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{ImageColor3 = getgenv().UIColor["Search Icon Highlight Color"]}):Play()
		end)
	
		TextButton.MouseLeave:Connect(function()
			TweenService:Create(CloseImage, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{ImageColor3 = getgenv().UIColor["Search Icon Color"]}):Play()
		end)
	
		TextButton.MouseButton1Click:Connect(function()
			task.spawn(function() Library_Function.ButtonEffect() end)
			task.wait(.25)
			remove()
		end)
	
		task.spawn(function()
			task.wait(Timeshow)
			remove()
		end)
	
	
	end
	
	function Library.CreateMain(Setting)
	
		local TitleNameMain = tostring(Setting.Title) or "Sea Hub"
		getgenv().MainDesc = Setting.Desc or ""
	
		local isDragging = false
		tempVar = false
	
		local function makeDraggable(topBarObject, object)
			local dragging = nil
			local dragInput = nil
			local dragStart = nil
			local startPosition = nil
			topBarObject.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPosition = object.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
						end
					end)
				end
			end)
			topBarObject.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					dragInput = input
				end
			end)
			uis.InputChanged:Connect(function(input)
				if input == dragInput and dragging then
					local delta = input.Position - dragStart
					if not isDragging and tempVar then
						TweenService:Create(object, TweenInfo.new(0.35,Enum.EasingStyle.Linear,Enum.EasingDirection.Out), {
							Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
						}):Play()
					elseif not isDragging and not tempVar then
						object.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
					end
				end
			end)
		end
	
		local Main = Instance.new("Frame")
		local maingui = Instance.new("ImageLabel")
		local MainCorner = Instance.new("UICorner")
		local TopMain = Instance.new("Frame")
		local Ruafimg = Instance.new("ImageLabel")
		local TextLabelMain = Instance.new("TextLabel")
		local PageControl = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local ControlList = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local ControlTitle = Instance.new("TextLabel")
		local MainPage = Instance.new("Frame")
		local UIPage = Instance.new("UIPageLayout")
		local SettionMain = Instance.new("Frame")
		local SettionButton = Instance.new("TextButton")
		local SettingIcon = Instance.new("ImageLabel")
		local ContentContainer = Instance.new("Frame")
		local ContentMain = Instance.new("Frame")
		local ContentBackground = Instance.new("Frame")
		local ContentPageLayout = Instance.new("UIPageLayout")
	
		local MainContainer
	
		Main.Name = "Main"
		Main.Parent = Library_Function.Gui
		Main.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		Main.BackgroundTransparency = 1.000
		Main.Position = UDim2.new(0.5, 0, 0.5, 0)
		Main.AnchorPoint = Vector2.new(0.5, 0.5)
		Main.Size = UDim2.new(0, 629, 0, 359)
	
		makeDraggable(Main, Main)
	
		maingui.Name = "maingui"
		maingui.Parent = Main
		maingui.AnchorPoint = Vector2.new(0.5, 0.5)
		maingui.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		maingui.BackgroundTransparency = 1.000
		maingui.Position = UDim2.new(0.5, 0, 0.5, 0)
		maingui.Selectable = true
		maingui.Size = UDim2.new(1, 30, 1, 30)
		maingui.Image = "rbxassetid://8068653048"
		maingui.ScaleType = Enum.ScaleType.Slice
		maingui.SliceCenter = Rect.new(15, 15, 175, 175)
		maingui.SliceScale = 1.300
		maingui.ImageColor3 = getgenv().UIColor["Border Color"]
		table.insert(UpdateCallBack["Border Color"],function() 
			maingui.ImageColor3 = getgenv().UIColor["Border Color"]
		end)
	
		function Library_Function.ReloadMain(v)
			maingui.ImageColor3 = getgenv().UIColor['Title Text Color']
			local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
			local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
			local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
			local color = colorR .. ',' .. colorG .. ',' .. colorB
			TextLabelMain.Text = "<font color=\"rgb("..color..")\">Sea Hub</font> " .. getgenv().MainDesc
			table.insert(UpdateCallBack["Title Text Color"],function() 
				maingui.ImageColor3 = getgenv().UIColor['Title Text Color']
				local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
				local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
				local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
				local color = colorR .. ',' .. colorG .. ',' .. colorB
				TextLabelMain.Text = "<font color=\"rgb("..color..")\">Sea Hub</font> " .. getgenv().MainDesc
			end)
			local MainContainer_
			if v ~= ""
			and type(v) == 'string'
			and string.find(v:lower(), ".webm")
			and pcall(function() writefile("seahub.webm", http_request({Url=v}).Body) end) then
				task.wait(.25)
				local sus = isfile("seahub.webm")
				task.wait(.25)
				if sus then
					MainContainer_ = Instance.new("VideoFrame")  
					MainContainer_.Name = "MainContainer"
					MainContainer_.Parent = Main
					MainContainer_.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
					MainContainer_.Size = UDim2.new(1, 0, 1, 0)
					MainContainer_.Video = getsynasset("seahub.webm")
					MainContainer_.Looped = true
					MainContainer_:Play()
					task.wait(.5)
					delfile('seahub.webm')
				end
			else
				MainContainer_ = Instance.new("ImageLabel")
				MainContainer_.Name = "MainContainer"
				MainContainer_.Parent = Main
				MainContainer_.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
				MainContainer_.Size = UDim2.new(1, 0, 1, 0)
				MainContainer_.Image = Library_Function.GetIMG(v)
			end
			MainCorner_ = Instance.new("UICorner")
			MainCorner_.CornerRadius = UDim.new(0, 4)
			MainCorner_.Name = "MainCorner"
			MainCorner_.Parent = MainContainer_
			for i,e in next, Main:GetChildren() do 
				if e.Name == "MainContainer" then
					for i,v in next, e:GetChildren() do
						v.Parent = MainContainer_
					end
					task.wait()
					e:Destroy()
					break
				end
			end
			table.insert(UpdateCallBack["Background 3 Color"],function() 
				MainContainer_.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
			end)
		end
	
		maingui.ImageColor3 = getgenv().UIColor['Title Text Color']
		local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
		local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
		local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
		local color = colorR .. ',' .. colorG .. ',' .. colorB
		TextLabelMain.Text = "<font color=\"rgb("..color..")\">Sea Hub</font> " .. getgenv().MainDesc
		table.insert(UpdateCallBack["Title Text Color"],function() 
			maingui.ImageColor3 = getgenv().UIColor['Title Text Color']
			local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
			local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
			local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
			local color = colorR .. ',' .. colorG .. ',' .. colorB
			TextLabelMain.Text = "<font color=\"rgb("..color..")\">Sea Hub</font> " .. getgenv().MainDesc
		end)
		local MainContainer
		local defurl = getgenv().UIColor["Background Image"]
		if defurl ~= ""
		and type(defurl) == 'string'
		and string.find(defurl:lower(), ".webm")
		and pcall(function() writefile("seahub.webm", http_request({Url=defurl}).Body) end) then
			task.wait(.25)
			local sus = isfile("seahub.webm")
			task.wait(.25)
			if sus then
				MainContainer = Instance.new("VideoFrame")  
				MainContainer.Name = "MainContainer"
				MainContainer.Parent = Main
				MainContainer.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
				MainContainer.Size = UDim2.new(1, 0, 1, 0)
				MainContainer.Video = getsynasset("seahub.webm")
				MainContainer.Looped = true
				MainContainer:Play()
				task.wait(.5)
				delfile('seahub.webm')
			end
		else
			MainContainer = Instance.new("ImageLabel")
			MainContainer.Name = "MainContainer"
			MainContainer.Parent = Main
			MainContainer.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
			MainContainer.Size = UDim2.new(1, 0, 1, 0)
			MainContainer.Image = Library_Function.GetIMG(defurl)
		end
		table.insert(UpdateCallBack["Background 3 Color"],function() 
			MainContainer.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
		end)
		getgenv().ReadyForGuiLoaded = true
		
		MainCorner.CornerRadius = UDim.new(0, 4)
		MainCorner.Name = "MainCorner"
		MainCorner.Parent = MainContainer
	
		ContentContainer.Name = "ContentContainer"
		ContentContainer.Parent = MainContainer
		ContentContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ContentContainer.BackgroundTransparency = 1.000
		ContentContainer.ClipsDescendants = true
		ContentContainer.Position = UDim2.new(0, 0, 0, 30)
		ContentContainer.Size = UDim2.new(1, 0, 1, -30)
		
		ContentMain.Name = "ContentMain"
		ContentMain.Parent = ContentContainer
		ContentMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ContentMain.BackgroundTransparency = 1.000
		ContentMain.Selectable = true
		ContentMain.Size = UDim2.new(1, 0, 1, 0)
		
		ContentBackground.Name = "Background1"
		ContentBackground.Parent = ContentContainer
		ContentBackground.LayoutOrder = 1
		ContentBackground.Selectable = true
		ContentBackground.Size = UDim2.new(1, 0, 1, 0)
		ContentBackground.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
		table.insert(UpdateCallBack["Background 1 Transparency"],function() 
			ContentBackground.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
		end)
		ContentBackground.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
		table.insert(UpdateCallBack["Background 1 Color"],function() 
			ContentBackground.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
		end)
		
		ContentPageLayout.Name = "ContentPageLayout"
		ContentPageLayout.Parent = ContentContainer
		ContentPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ContentPageLayout.EasingDirection = Enum.EasingDirection.InOut
		ContentPageLayout.EasingStyle = Enum.EasingStyle.Quad
		ContentPageLayout.TweenTime = getgenv().UIColor["Tween Animation 1 Speed"]
		table.insert(UpdateCallBack["Tween Animation 1 Speed"], function() 
			ContentPageLayout.TweenTime = getgenv().UIColor["Tween Animation 1 Speed"]
		end)
		
		TopMain.Name = "TopMain"
		TopMain.Parent = MainContainer
		TopMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TopMain.BackgroundTransparency = 1.000
		TopMain.Size = UDim2.new(1, 0, 0, 25)
		
		Ruafimg.Name = "Ruafimg"
		Ruafimg.Parent = TopMain
		Ruafimg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Ruafimg.BackgroundTransparency = 1.000
		Ruafimg.Position = UDim2.new(0, 5, 0, 0)
		Ruafimg.Size = UDim2.new(0, 25, 0, 25)
		Ruafimg.Image = getgenv().UIColor["Logo Image"]
		table.insert(UpdateCallBack["Logo Image"],function() 
			Ruafimg.Image = getgenv().UIColor["Logo Image"]
		end)
		
		TextLabelMain.Name = "TextLabelMain"
		TextLabelMain.Parent = TopMain
		TextLabelMain.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		TextLabelMain.BackgroundTransparency = 1.000
		TextLabelMain.Position = UDim2.new(0, 35, 0, 0)
		TextLabelMain.Size = UDim2.new(1, -35, 1, 0)
		TextLabelMain.Font = Enum.Font.GothamBold
		TextLabelMain.RichText = true
		TextLabelMain.TextSize = 16.000
		TextLabelMain.TextWrapped = true
		TextLabelMain.TextXAlignment = Enum.TextXAlignment.Left
		TextLabelMain.TextColor3 = getgenv().UIColor["GUI Text Color"]
		table.insert(UpdateCallBack["GUI Text Color"],function() 
			TextLabelMain.TextColor3 = getgenv().UIColor["GUI Text Color"]
		end)
		local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
		local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
		local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
		local color = colorR .. ',' .. colorG .. ',' .. colorB
		TextLabelMain.Text = "<font color=\"rgb("..color..")\">Sea Hub</font> " .. getgenv().MainDesc
		table.insert(UpdateCallBack["Title Text Color"],function() 
			local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
			local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
			local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
			local color = colorR .. ',' .. colorG .. ',' .. colorB
			TextLabelMain.Text = "<font color=\"rgb("..color..")\">Sea Hub</font> " .. getgenv().MainDesc
		end)
		
		SettionMain.Name = "SettionMain"
		SettionMain.Parent = TopMain
		SettionMain.AnchorPoint = Vector2.new(1, 0)
		SettionMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SettionMain.BackgroundTransparency = 1.000
		SettionMain.Position = UDim2.new(1, 0, 0, 0)
		SettionMain.Size = UDim2.new(0, 30, 0, 30)
		
		SettionButton.Name = "SettionButton"
		SettionButton.Parent = SettionMain
		SettionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SettionButton.BackgroundTransparency = 1.000
		SettionButton.BorderColor3 = Color3.fromRGB(27, 42, 53)
		SettionButton.Size = UDim2.new(1, 0, 1, 0)
		SettionButton.Font = Enum.Font.SourceSans
		SettionButton.Text = ""
		SettionButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		SettionButton.TextSize = 14.000
		SettionButton.Visible = true
		
		SettingIcon.Name = "SettingIcon"
		SettingIcon.Parent = SettionMain
		SettingIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		SettingIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SettingIcon.BackgroundTransparency = 1.000
		SettingIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		SettingIcon.Size = UDim2.new(1, -10, 1, -10)
		SettingIcon.Image = "rbxassetid://7397332215"
		SettingIcon.Visible = true
		SettingIcon.ImageColor3 = getgenv().UIColor["Setting Icon Color"]
		table.insert(UpdateCallBack["Setting Icon Color"],function() 
			SettingIcon.ImageColor3 = getgenv().UIColor["Setting Icon Color"]
		end)
	
		PageControl.Name = "Background1"
		PageControl.Parent = ContentMain
		PageControl.Position = UDim2.new(0, 5, 0, 0)
		PageControl.Size = UDim2.new(0, 180, 0, 325)
		PageControl.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
		table.insert(UpdateCallBack["Background 1 Transparency"],function() 
			PageControl.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
		end)
		PageControl.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
		table.insert(UpdateCallBack["Background 1 Color"],function() 
			PageControl.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
		end)
	
		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = PageControl
	
		ControlList.Name = "ControlList"
		ControlList.Parent = PageControl
		ControlList.Active = true
		ControlList.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		ControlList.BackgroundTransparency = 1.000
		ControlList.BorderColor3 = Color3.fromRGB(27, 42, 53)
		ControlList.BorderSizePixel = 0
		ControlList.Position = UDim2.new(0, 0, 0, 30)
		ControlList.Size = UDim2.new(1, -5, 1, -30)
		ControlList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		ControlList.CanvasSize = UDim2.new(0, 0, 0, 0)
		ControlList.ScrollBarThickness = 5
		ControlList.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	
		UIListLayout.Parent = ControlList
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 5)
	
		ControlTitle.Name = "GUITextColor"
		ControlTitle.Parent = PageControl
		ControlTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		ControlTitle.BackgroundTransparency = 1.000
		ControlTitle.Position = UDim2.new(0, 5, 0, 0)
		ControlTitle.Size = UDim2.new(1, 0, 0, 25)
		ControlTitle.Font = Enum.Font.GothamBold
		ControlTitle.Text = TitleNameMain
		ControlTitle.TextSize = 14.000
		ControlTitle.TextXAlignment = Enum.TextXAlignment.Left
		ControlTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]
		table.insert(UpdateCallBack["GUI Text Color"], function() 
			ControlTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]
		end)
	
		MainPage.Name = "MainPage"
		MainPage.Parent = ContentMain
		MainPage.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		MainPage.BackgroundTransparency = 1.000
		MainPage.ClipsDescendants = true
		MainPage.Position = UDim2.new(0, 190, 0, 0)
		MainPage.Size = UDim2.new(0, 435, 0, 325)
	
		UIPage.Name = "UIPage"
		UIPage.Parent = MainPage
		UIPage.FillDirection = Enum.FillDirection.Vertical
		UIPage.SortOrder = Enum.SortOrder.LayoutOrder
		UIPage.EasingDirection = Enum.EasingDirection.InOut
		UIPage.EasingStyle = Enum.EasingStyle.Quart
		UIPage.Padding = UDim.new(0, 10)
		UIPage.TweenTime = getgenv().UIColor["Tween Animation 1 Speed"]
		table.insert(UpdateCallBack["Tween Animation 1 Speed"], function() 
			UIPage.TweenTime = getgenv().UIColor["Tween Animation 1 Speed"]
		end)
	
		UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ControlList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 5)
		end)
	
	
		local cummm = false 
	
		SettionButton.MouseButton1Click:Connect(function() Library_Function.ButtonEffect() end)
	
		SettionButton.MouseButton1Click:Connect(function()
			cummm = not cummm
			pa = cummm and 1 or 0 
			ro = cummm and 180 or 0 
			ContentPageLayout:JumpToIndex(pa)
			game.TweenService:Create(SettingIcon,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Rotation = ro}):Play()
		end)
	
		local CustomList = Instance.new("ScrollingFrame")
		local CustomListLayout = Instance.new("UIListLayout")
	
	
		CustomList.Name = "CustomList"
		CustomList.Parent = ContentBackground
		CustomList.Active = true
		CustomList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		CustomList.BackgroundTransparency = 1.000
		CustomList.BorderColor3 = Color3.fromRGB(27, 42, 53)
		CustomList.BorderSizePixel = 0
		CustomList.Position = UDim2.new(0, 5, 0, 30)
		CustomList.Size = UDim2.new(1, -10, 1, -30)
		CustomList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		CustomList.ScrollBarThickness = 5
		CustomList.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	
		CustomListLayout.Name = "CustomListLayout"
		CustomListLayout.Parent = CustomList
		CustomListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		CustomListLayout.Padding = UDim.new(0, 5)
	
		CustomListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			CustomList.CanvasSize = UDim2.new(0, 0, 0, CustomListLayout.AbsoluteContentSize.Y + 5)
		end)
	
		local CustomTitle = Instance.new("TextLabel")
	
		CustomTitle.Name = "GUITextColor"
		CustomTitle.Parent = ContentBackground
		CustomTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		CustomTitle.BackgroundTransparency = 1.000
		CustomTitle.Position = UDim2.new(0, 15, 0, 0)
		CustomTitle.Size = UDim2.new(1, -15, 0, 25)
		CustomTitle.Font = Enum.Font.GothamBold
		CustomTitle.Text = ''
		CustomTitle.TextSize = 16.000
		CustomTitle.TextXAlignment = Enum.TextXAlignment.Left
		CustomTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]
		table.insert(UpdateCallBack["GUI Text Color"],function() 
			CustomTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]
		end)
	
		local CustomSearch = Instance.new("Frame")
		local PageSearchCorner = Instance.new("UICorner")
		local SearchFrame = Instance.new("Frame")
		local SearchIcon = Instance.new("ImageLabel")
		local active = Instance.new("TextButton")
		local SearchBucu = Instance.new("TextBox")
	
		CustomSearch.Name = "Background2"
		CustomSearch.Parent = ContentBackground
		CustomSearch.AnchorPoint = Vector2.new(1, 0)
		CustomSearch.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
		CustomSearch.ClipsDescendants = true
		CustomSearch.Position = UDim2.new(1, -5, 0, 5)
		CustomSearch.Size = UDim2.new(0, 20, 0, 20)
		CustomSearch.ClipsDescendants = true
		table.insert(UpdateCallBack["Background 2 Color"],function() 
			CustomSearch.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
		end)
	
		PageSearchCorner.CornerRadius = UDim.new(0, 2)
		PageSearchCorner.Name = "PageSearchCorner"
		PageSearchCorner.Parent = CustomSearch
	
		SearchFrame.Name = "SearchFrame"
		SearchFrame.Parent = CustomSearch
		SearchFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SearchFrame.BackgroundTransparency = 1.000
		SearchFrame.Size = UDim2.new(0, 20, 0, 20)
	
		SearchIcon.Name = "SearchIcon"
		SearchIcon.Parent = SearchFrame
		SearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		SearchIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SearchIcon.BackgroundTransparency = 1.000
		SearchIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		SearchIcon.Size = UDim2.new(0, 16, 0, 16)
		SearchIcon.Image = "rbxassetid://8154282545"
		SearchIcon.ImageColor3 = getgenv().UIColor["Search Icon Color"]
		table.insert(UpdateCallBack["Search Icon Color"],function() 
			SearchIcon.ImageColor3 = getgenv().UIColor["Search Icon Color"]
		end)
	
		active.Name = "active"
		active.Parent = SearchFrame
		active.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		active.BackgroundTransparency = 1.000
		active.Size = UDim2.new(1, 0, 1, 0)
		active.Font = Enum.Font.SourceSans
		active.Text = ""
		active.TextColor3 = Color3.fromRGB(0, 0, 0)
		active.TextSize = 14.000
	
		SearchBucu.Name = "TextColorPlaceholder"
		SearchBucu.Parent = CustomSearch
		SearchBucu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SearchBucu.BackgroundTransparency = 1.000
		SearchBucu.Position = UDim2.new(0, 30, 0, 0)
		SearchBucu.Size = UDim2.new(1, -30, 1, 0)
		SearchBucu.Font = Enum.Font.GothamBold
		SearchBucu.Text = ''
		SearchBucu.TextSize = 14.000
		SearchBucu.TextXAlignment = Enum.TextXAlignment.Left
		SearchBucu.PlaceholderText =  "Search Section name"
		SearchBucu.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
		SearchBucu.TextColor3 = getgenv().UIColor["Text Color"]
		table.insert(UpdateCallBack["Placeholder Text Color"],function() 
			SearchBucu.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
		end)
		table.insert(UpdateCallBack["Text Color"],function() 
			SearchBucu.TextColor3 = getgenv().UIColor["Text Color"]
		end)
	
		local cummmed_ = false 
	
			active.MouseEnter:Connect(function()
				TweenService:Create(SearchIcon,TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]),{ImageColor3 = getgenv().UIColor["Search Icon Highlight Color"]}):Play()
			end)
	
			active.MouseLeave:Connect(function()
				TweenService:Create(SearchIcon,TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]),{ImageColor3 = getgenv().UIColor["Search Icon Color"]}):Play()
			end)
	
			active.MouseButton1Click:Connect(function()
				Library_Function.ButtonEffect()
			end)
	
			SearchBucu.Focused:Connect(function()
				Library_Function.ButtonEffect()
			end)
	
			active.MouseButton1Click:Connect(function()
				cummmed_ = not cummmed_
				local size = cummmed_ and UDim2.new(0,175,0,20) or  UDim2.new(0,20,0,20)
				game.TweenService:Create(CustomSearch,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Size = size}):Play()
			end)
	
			local function succac_()
				for i,v in next, CustomList:GetChildren() do 
					if not v:IsA('UIListLayout') then 
						v.Visible = false
					end
				end
			end
			
			local function ra_()
				for a, b in pairs(CustomList:GetChildren()) do
					if not b:IsA('UIListLayout') then 
						if string.find(string.lower(b.Name),string.lower(SearchBucu.Text)) then 
							b.Visible = true
						end
					end
				end
			end
			
			SearchBucu:GetPropertyChangedSignal("Text"):Connect(function()
				succac_()
				ra_()
			end)
	
		function Library.CreateCustomColor(Name)
	
			CustomTitle.Text = Name or 'Custom GUI'
	
	
			local Setting_Function = {}
	
			function Setting_Function.CreateSection(Section_Name)
	
				local Section = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local Topsec = Instance.new("Frame")
				local Sectiontitle = Instance.new("TextLabel")
				local Linesec = Instance.new("Frame")
				local UIGradient = Instance.new("UIGradient")
				local SectionList = Instance.new("UIListLayout")
				local SectionName = Section_Name or "Section"
	
				Section.Name = Section_Name.."Section"
				Section.Parent = CustomList
				Section.Size = UDim2.new(1, 0, 0, 285)
				Section.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
				table.insert(UpdateCallBack["Background 3 Color"],function() 
					Section.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
				end)
				Section.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
				table.insert(UpdateCallBack["Background 1 Transparency"],function() 
					Section.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
				end)
	
				UICorner.CornerRadius = UDim.new(0, 4)
				UICorner.Parent = Section
	
				Topsec.Name = "Topsec"
				Topsec.Parent = Section
				Topsec.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Topsec.BackgroundTransparency = 1.000
				Topsec.Size = UDim2.new(1, 0, 0, 27)
	
				Sectiontitle.Name = "Sectiontitle"
				Sectiontitle.Parent = Topsec
				Sectiontitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Sectiontitle.BackgroundTransparency = 1.000
				Sectiontitle.Size = UDim2.new(1, 0, 1, 0)
				Sectiontitle.Font = Enum.Font.GothamBold
				Sectiontitle.Text = Section_Name
				Sectiontitle.TextSize = 14.000
				Sectiontitle.TextColor3 = getgenv().UIColor["Section Text Color"]
				table.insert(UpdateCallBack["Section Text Color"],function() 
					Sectiontitle.TextColor3 = getgenv().UIColor["Section Text Color"]
				end)
	
				Linesec.Name = "Linesec"
				Linesec.Parent = Topsec
				Linesec.AnchorPoint = Vector2.new(0.5, 1)
				Linesec.BorderSizePixel = 0
				Linesec.Position = UDim2.new(0.5, 0, 1, -2)
				Linesec.Size = UDim2.new(1, -10, 0, 2)
				Linesec.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
				table.insert(UpdateCallBack["Section Underline Color"],function() 
					Linesec.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
				end)
	
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.50, 0.00), NumberSequenceKeypoint.new(0.51, 0.02), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = Linesec
	
				SectionList.Name = "SectionList"
				SectionList.Parent = Section
				SectionList.SortOrder = Enum.SortOrder.LayoutOrder
				SectionList.Padding = UDim.new(0, 5)
	
				SectionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					Section.Size = UDim2.new(1, 0, 0, SectionList.AbsoluteContentSize.Y + 5)
				end)
	
				local Setting_Section_Function = {}
	
					function Setting_Section_Function.CreateColorPicker(Setting)
						local _G=setmetatable({},{
							__index=function(Self,Key) 
								if Key=="Cungroi" then 
									return SettingsRac[Setting.Type].Rainbow
								end
							end,
							__newindex=function(Self,Key,Value) 
								if Key=="Cungroi" then 
									SettingsRac[Setting.Type].Rainbow=Value
								end
							end
						})
						local H,S,V
						local Title = Setting.Title or "Color Picker"
						local Default = SettingsRac[Setting.Type].Color or Color3.fromRGB(255, 255, 255)
						local Type = Setting.Type
						local ColorPick = Instance.new("Frame")
						local ColorPickCorner = Instance.new("UICorner")
						local ColorPickBg = Instance.new("Frame")
						local ColorpickBGCorner = Instance.new("UICorner")
						local ColorpickTitle = Instance.new("TextLabel")
						local ColorVal = Instance.new("Frame")
						local ColorValCorner = Instance.new("UICorner")
						local ColorValButton = Instance.new("TextButton")
						local Hue = Instance.new("Frame")
						local HueGra = Instance.new("UIGradient")
						local Frame = Instance.new("Frame")
						local UICorner = Instance.new("UICorner")
						local Concac = Instance.new("Frame")
						local RFrame = Instance.new("Frame")
						local RText = Instance.new("TextLabel")
						local RBox = Instance.new("TextBox")
						local GFrame = Instance.new("Frame")
						local GText = Instance.new("TextLabel")
						local GBox = Instance.new("TextBox")
						local BFrame = Instance.new("Frame")
						local BText = Instance.new("TextLabel")
						local BBox = Instance.new("TextBox")
						local UIListLayout = Instance.new("UIListLayout")
						local HexFrame = Instance.new("Frame")
						local HexText = Instance.new("TextLabel")
						local HexBox = Instance.new("TextBox")
						local Linesec = Instance.new("Frame")
						local UIGradient = Instance.new("UIGradient")
						local CungroiF = Instance.new("Frame")
						local CungroiFF = Instance.new("Frame")
						local cungroitext = Instance.new("TextLabel")
						local checkbox = Instance.new("ImageLabel")
						local check = Instance.new("ImageLabel")
						local Cungroitog = Instance.new("TextButton")
						local Color = Instance.new("ImageLabel")
						local SelectorColor = Instance.new("Frame")
						local UICorner_2 = Instance.new("UICorner")
						local HoithoF = Instance.new("Frame")
						local HoithoF_2 = Instance.new("Frame")
						local hoithotext = Instance.new("TextLabel")
						local checkbox_2 = Instance.new("ImageLabel")
						local check_2 = Instance.new("ImageLabel")
						local Hoithoitog = Instance.new("TextButton")
						local Frame_2 = Instance.new("Frame")
						local UIListLayout_2 = Instance.new("UIListLayout")
						local Cor1 = Instance.new("Frame")
						local UICorner_3 = Instance.new("UICorner")
						local BCor1 = Instance.new("TextButton")
						local Cor2 = Instance.new("Frame")
						local UICorner_4 = Instance.new("UICorner")
						local BCor2 = Instance.new("TextButton")
	
						ColorPick.Name = "ColorPick"
						ColorPick.Parent = Section
						ColorPick.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
						ColorPick.BackgroundTransparency = 1.000
						ColorPick.ClipsDescendants = true
						ColorPick.Position = UDim2.new(0, 0, 0.112280704, 0)
						ColorPick.Size = UDim2.new(1, 0, 0, 35)
	
						ColorPickCorner.CornerRadius = UDim.new(0, 4)
						ColorPickCorner.Name = "ColorPickCorner"
						ColorPickCorner.Parent = ColorPick
	
						ColorPickBg.Name = "Background1"
						ColorPickBg.Parent = ColorPick
						ColorPickBg.AnchorPoint = Vector2.new(0.5, 0.5)
						ColorPickBg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
						ColorPickBg.Position = UDim2.new(0.5, 0, 0.5, 0)
						ColorPickBg.Size = UDim2.new(1, -10, 1, 0)
						table.insert(UpdateCallBack["Background 1 Color"],function() 
							ColorPickBg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
						end)
						ColorPickBg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
						table.insert(UpdateCallBack["Background 1 Transparency"],function() 
							ColorPickBg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
						end)
	
						ColorpickBGCorner.CornerRadius = UDim.new(0, 4)
						ColorpickBGCorner.Name = "ColorpickBGCorner"
						ColorpickBGCorner.Parent = ColorPickBg
	
						ColorpickTitle.Name = "TextColor"
						ColorpickTitle.Parent = ColorPickBg
						ColorpickTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						ColorpickTitle.BackgroundTransparency = 1.000
						ColorpickTitle.Position = UDim2.new(0, 10, 0, 0)
						ColorpickTitle.Size = UDim2.new(1, -10, 0, 35)
						ColorpickTitle.Font = Enum.Font.GothamBlack
						ColorpickTitle.Text = Title
						ColorpickTitle.TextSize = 14.000
						ColorpickTitle.TextXAlignment = Enum.TextXAlignment.Left
						ColorpickTitle.TextColor3 = getgenv().UIColor["Text Color"]
						table.insert(UpdateCallBack["Text Color"],function() 
							ColorpickTitle.TextColor3 = getgenv().UIColor["Text Color"]
						end)
	
						ColorVal.Name = "ColorVal"
						ColorVal.Parent = ColorPick
						ColorVal.AnchorPoint = Vector2.new(1, 0)
						ColorVal.BackgroundColor3 = SettingsRac[Type].Color
						ColorVal.Position = UDim2.new(1, -10, 0, 5)
						ColorVal.Size = UDim2.new(0, 150, 0, 25)
	
						ColorValCorner.CornerRadius = UDim.new(0, 4)
						ColorValCorner.Name = "ColorValCorner"
						ColorValCorner.Parent = ColorVal
	
						ColorValButton.Name = "ColorValButton"
						ColorValButton.Parent = ColorVal
						ColorValButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						ColorValButton.BackgroundTransparency = 1.000
						ColorValButton.Size = UDim2.new(1, 0, 1, 0)
						ColorValButton.Font = Enum.Font.SourceSans
						ColorValButton.Text = ""
						ColorValButton.TextColor3 = Color3.fromRGB(0, 0, 0)
						ColorValButton.TextSize = 14.000
	
						Hue.Name = "Hue"
						Hue.Parent = ColorPick
						Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Hue.BorderSizePixel = 0
						Hue.Position = UDim2.new(0, 460, 0, 40)
						Hue.Size = UDim2.new(0, 25, 0, 200)
	
						HueGra.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(235, 7, 255)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 9, 189)), ColorSequenceKeypoint.new(0.49, Color3.fromRGB(0, 193, 196)), ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 247, 0)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))}
						HueGra.Rotation = 90
						HueGra.Name = "HueGra"
						HueGra.Parent = Hue
	
						Frame.Parent = Hue
						Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Frame.Position = UDim2.new(0, 0, 1, 0)
						Frame.Size = UDim2.new(1, 0, 0, 2)
	
						UICorner.CornerRadius = UDim.new(0, 4)
						UICorner.Parent = Hue
	
						Concac.Name = "Concac"
						Concac.Parent = ColorPick
						Concac.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Concac.BackgroundTransparency = 1.000
						Concac.Position = UDim2.new(0, 495, 0, 40)
						Concac.Size = UDim2.new(0, 115, 0, 100)
	
						RFrame.Name = "RFrame"
						RFrame.Parent = Concac
						RFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						RFrame.BackgroundTransparency = 1.000
						RFrame.Size = UDim2.new(1, 0, 0, 25)
						RFrame.LayoutOrder = 0
	
						RText.Name = "RText"
						RText.Parent = RFrame
						RText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						RText.BackgroundTransparency = 1.000
						RText.Size = UDim2.new(0, 25, 0, 25)
						RText.Font = Enum.Font.GothamBold
						RText.Text = "R:"
						RText.TextColor3 = Color3.fromRGB(115, 115, 115)
						RText.TextSize = 14.000
						RText.TextXAlignment = Enum.TextXAlignment.Left
	
						RBox.Name = "RBox"
						RBox.Parent = RFrame
						RBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						RBox.BackgroundTransparency = 1.000
						RBox.Position = UDim2.new(0, 25, 0, 0)
						RBox.Size = UDim2.new(1, -25, 1, 0)
						RBox.ClearTextOnFocus = false
						RBox.Font = Enum.Font.GothamBold
						RBox.Text = "255"
						RBox.TextColor3 = Color3.fromRGB(255, 255, 255)
						RBox.TextSize = 14.000
						RBox.TextXAlignment = Enum.TextXAlignment.Left
	
						GFrame.Name = "GFrame"
						GFrame.Parent = Concac
						GFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						GFrame.BackgroundTransparency = 1.000
						GFrame.Size = UDim2.new(1, 0, 0, 25)
						GFrame.LayoutOrder = 1
	
						GText.Name = "GText"
						GText.Parent = GFrame
						GText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						GText.BackgroundTransparency = 1.000
						GText.Size = UDim2.new(0, 25, 0, 25)
						GText.Font = Enum.Font.GothamBold
						GText.Text = "G:"
						GText.TextColor3 = Color3.fromRGB(115, 115, 115)
						GText.TextSize = 14.000
						GText.TextXAlignment = Enum.TextXAlignment.Left
	
						GBox.Name = "GBox"
						GBox.Parent = GFrame
						GBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						GBox.BackgroundTransparency = 1.000
						GBox.Position = UDim2.new(0, 25, 0, 0)
						GBox.Size = UDim2.new(1, -25, 1, 0)
						GBox.ClearTextOnFocus = false
						GBox.Font = Enum.Font.GothamBold
						GBox.Text = "255"
						GBox.TextColor3 = Color3.fromRGB(255, 255, 255)
						GBox.TextSize = 14.000
						GBox.TextXAlignment = Enum.TextXAlignment.Left
	
						BFrame.Name = "BFrame"
						BFrame.Parent = Concac
						BFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						BFrame.BackgroundTransparency = 1.000
						BFrame.Size = UDim2.new(1, 0, 0, 25)
						BFrame.LayoutOrder = 2
	
						BText.Name = "BText"
						BText.Parent = BFrame
						BText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						BText.BackgroundTransparency = 1.000
						BText.Size = UDim2.new(0, 25, 0, 25)
						BText.Font = Enum.Font.GothamBold
						BText.Text = "B:"
						BText.TextColor3 = Color3.fromRGB(115, 115, 115)
						BText.TextSize = 14.000
						BText.TextXAlignment = Enum.TextXAlignment.Left
	
						BBox.Name = "BBox"
						BBox.Parent = BFrame
						BBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						BBox.BackgroundTransparency = 1.000
						BBox.Position = UDim2.new(0, 25, 0, 0)
						BBox.Size = UDim2.new(1, -25, 1, 0)
						BBox.ClearTextOnFocus = false
						BBox.Font = Enum.Font.GothamBold
						BBox.Text = "255"
						BBox.TextColor3 = Color3.fromRGB(255, 255, 255)
						BBox.TextSize = 14.000
						BBox.TextXAlignment = Enum.TextXAlignment.Left
	
						UIListLayout.Parent = Concac
						UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	
						HexFrame.Name = "HexFrame"
						HexFrame.Parent = Concac
						HexFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						HexFrame.BackgroundTransparency = 1.000
						HexFrame.Size = UDim2.new(1, 0, 0, 25)
						HexFrame.LayoutOrder = 3
	
						HexText.Name = "HexText"
						HexText.Parent = HexFrame
						HexText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						HexText.BackgroundTransparency = 1.000
						HexText.Size = UDim2.new(0, 25, 0, 25)
						HexText.Font = Enum.Font.GothamBold
						HexText.Text = "#"
						HexText.TextColor3 = Color3.fromRGB(115, 115, 115)
						HexText.TextSize = 14.000
						HexText.TextXAlignment = Enum.TextXAlignment.Left
	
						HexBox.Name = "HexBox"
						HexBox.Parent = HexFrame
						HexBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						HexBox.BackgroundTransparency = 1.000
						HexBox.Position = UDim2.new(0, 25, 0, 0)
						HexBox.Size = UDim2.new(1, -25, 1, 0)
						HexBox.ClearTextOnFocus = false
						HexBox.Font = Enum.Font.GothamBold
						HexBox.Text = "FFFFFF"
						HexBox.TextColor3 = Color3.fromRGB(255, 255, 255)
						HexBox.TextSize = 14.000
						HexBox.TextXAlignment = Enum.TextXAlignment.Left
	
						Linesec.Name = "Linesec"
						Linesec.Parent = Concac
						Linesec.AnchorPoint = Vector2.new(0.5, 1)
						Linesec.BorderSizePixel = 0
						Linesec.Position = UDim2.new(0.5, 0, 1, -2)
						Linesec.Size = UDim2.new(1, -10, 0, 2)
						Linesec.LayoutOrder = 4
						Linesec.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
						table.insert(UpdateCallBack["Section Underline Color"],function() 
							Linesec.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
						end)
	
						UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.30, 0.25), NumberSequenceKeypoint.new(0.70, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
						UIGradient.Parent = Linesec
	
						CungroiF.Name = "CungroiF"
						CungroiF.Parent = ColorPick
						CungroiF.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						CungroiF.BackgroundTransparency = 1.000
						CungroiF.Position = UDim2.new(0, 495, 0, 145)
						CungroiF.Size = UDim2.new(0, 115, 0, 25)
	
						CungroiFF.Name = "CungroiFF"
						CungroiFF.Parent = CungroiF
						CungroiFF.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						CungroiFF.BackgroundTransparency = 1.000
						CungroiFF.Size = UDim2.new(1, 0, 0, 25)
						CungroiFF.LayoutOrder = 4
	
						cungroitext.Name = "TextColor"
						cungroitext.Parent = CungroiFF
						cungroitext.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						cungroitext.BackgroundTransparency = 1.000
						cungroitext.Size = UDim2.new(0, 85, 0, 25)
						cungroitext.Font = Enum.Font.GothamBold
						cungroitext.Text = "Rainbow"
						cungroitext.TextSize = 14.000
						cungroitext.TextXAlignment = Enum.TextXAlignment.Left
						cungroitext.TextColor3 = getgenv().UIColor["Text Color"]
						table.insert(UpdateCallBack["Text Color"],function() 
							cungroitext.TextColor3 = getgenv().UIColor["Text Color"]
						end)
	
						checkbox.Name = "Setting_checkbox"
						checkbox.Parent = CungroiFF
						checkbox.AnchorPoint = Vector2.new(1, 0.5)
						checkbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						checkbox.BackgroundTransparency = 1.000
						checkbox.Position = UDim2.new(1, -5, 0.5, 0)
						checkbox.Size = UDim2.new(0, 25, 0, 25)
						checkbox.Image = "rbxassetid://4552505888"
						checkbox.ImageColor3 = getgenv().UIColor["Toggle Border Color"]
						table.insert(UpdateCallBack["Toggle Border Color"],function() 
							checkbox.ImageColor3 = getgenv().UIColor["Toggle Border Color"]
						end)
	
						check.Name = "Setting_check"
						check.Parent = checkbox
						check.AnchorPoint = Vector2.new(0, 1)
						check.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						check.BackgroundTransparency = 1.000
						check.Position = UDim2.new(0, 0, 1, 0)
						check.Image = "rbxassetid://4555411759"
						check.ImageColor3 = getgenv().UIColor["Toggle Checked Color"]
						table.insert(UpdateCallBack["Toggle Checked Color"],function() 
							check.ImageColor3 = getgenv().UIColor["Toggle Checked Color"]
						end)
	
						Cungroitog.Name = "Cungroitog"
						Cungroitog.Parent = CungroiFF
						Cungroitog.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Cungroitog.BackgroundTransparency = 1.000
						Cungroitog.Size = UDim2.new(1, 0, 1, 0)
						Cungroitog.Font = Enum.Font.SourceSans
						Cungroitog.Text = ""
						Cungroitog.TextColor3 = Color3.fromRGB(0, 0, 0)
						Cungroitog.TextSize = 14.000
						
						Color.Name = "Color"
						Color.Parent = ColorPick
						Color.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
						Color.BorderSizePixel = 0
						Color.Position = UDim2.new(0, 10, 0, 40)
						Color.Size = UDim2.new(0, 440, 0, 200)
						Color.Image = "rbxassetid://4155801252"
	
						SelectorColor.Name = "SelectorColor"
						SelectorColor.Parent = Color
						SelectorColor.AnchorPoint = Vector2.new(0.5, 0.5)
						SelectorColor.BackgroundColor3 = Color3.fromRGB(203, 203, 203)
						SelectorColor.BorderColor3 = Color3.fromRGB(70, 70, 70)
						SelectorColor.Position = UDim2.new(1, 0, 0, 0)
						SelectorColor.Size = UDim2.new(0, 4, 0, 4)
	
						UICorner_2.CornerRadius = UDim.new(0, 4)
						UICorner_2.Parent = Color
	
						HoithoF.Name = "HoithoF"
						HoithoF.Parent = ColorPick
						HoithoF.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						HoithoF.BackgroundTransparency = 1.000
						HoithoF.Position = UDim2.new(0, 495, 0, 175)
						HoithoF.Size = UDim2.new(0, 115, 0, 25)
						HoithoF.LayoutOrder = 5
	
						HoithoF_2.Name = "HoithoF"
						HoithoF_2.Parent = HoithoF
						HoithoF_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						HoithoF_2.BackgroundTransparency = 1.000
						HoithoF_2.Size = UDim2.new(1, 0, 1, 25)
	
						hoithotext.Name = "TextColor"
						hoithotext.Parent = HoithoF_2
						hoithotext.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						hoithotext.BackgroundTransparency = 1.000
						hoithotext.Size = UDim2.new(0, 85, 0, 25)
						hoithotext.Font = Enum.Font.GothamBold
						hoithotext.Text = "Breathing"
						hoithotext.TextSize = 14.000
						hoithotext.TextXAlignment = Enum.TextXAlignment.Left
						hoithotext.TextColor3 = getgenv().UIColor["Text Color"]
						table.insert(UpdateCallBack["Text Color"],function() 
							hoithotext.TextColor3 = getgenv().UIColor["Text Color"]
						end)
	
						checkbox_2.Name = "setting_checkbox"
						checkbox_2.Parent = HoithoF_2
						checkbox_2.AnchorPoint = Vector2.new(1, 0)
						checkbox_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						checkbox_2.BackgroundTransparency = 1.000
						checkbox_2.Position = UDim2.new(1, -5, 0, 0)
						checkbox_2.Size = UDim2.new(0, 25, 0, 25)
						checkbox_2.Image = "rbxassetid://4552505888"
						checkbox_2.ImageColor3 = Color3.fromRGB(131, 181, 255)
						checkbox_2.ImageColor3 = getgenv().UIColor["Toggle Border Color"]
						table.insert(UpdateCallBack["Toggle Border Color"],function() 
							checkbox_2.ImageColor3 = getgenv().UIColor["Toggle Border Color"]
						end)
	
						check_2.Name = "setting_check"
						check_2.Parent = checkbox_2
						check_2.AnchorPoint = Vector2.new(0, 1)
						check_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						check_2.BackgroundTransparency = 1.000
						check_2.Position = UDim2.new(0, 0, 1, 0)
						check_2.Image = "rbxassetid://4555411759"
						check_2.ImageColor3 = getgenv().UIColor["Toggle Checked Color"]
						table.insert(UpdateCallBack["Toggle Checked Color"],function() 
							check_2.ImageColor3 = getgenv().UIColor["Toggle Checked Color"]
						end)
	
						Hoithoitog.Name = "Hoithoitog"
						Hoithoitog.Parent = HoithoF_2
						Hoithoitog.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Hoithoitog.BackgroundTransparency = 1.000
						Hoithoitog.Size = UDim2.new(1, 0, 0, 25)
						Hoithoitog.Font = Enum.Font.SourceSans
						Hoithoitog.Text = ""
						Hoithoitog.TextColor3 = Color3.fromRGB(0, 0, 0)
						Hoithoitog.TextSize = 14.000
	
						Frame_2.Parent = HoithoF_2
						Frame_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Frame_2.BackgroundTransparency = 1.000
						Frame_2.Position = UDim2.new(0, 0, 0, 30)
						Frame_2.Size = UDim2.new(1, 0, 0, 25)
	
						UIListLayout_2.Parent = Frame_2
						UIListLayout_2.FillDirection = Enum.FillDirection.Horizontal
						UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
						UIListLayout_2.Padding = UDim.new(0, 5)
	
						Cor1.Name = "Cor1"
						Cor1.Parent = Frame_2
						Cor1.BackgroundColor3 =SettingsRac[Type].Breathing.Color1
						Cor1.Selectable = true
						Cor1.Size = UDim2.new(0, 25, 0, 25)
	
						UICorner_3.CornerRadius = UDim.new(1, 0)
						UICorner_3.Parent = Cor1
	
						BCor1.Name = "BCor1"
						BCor1.Parent = Cor1
						BCor1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						BCor1.BackgroundTransparency = 1.000
						BCor1.Size = UDim2.new(1, 0, 1, 0)
						BCor1.Font = Enum.Font.SourceSans
						BCor1.Text = ""
						BCor1.TextColor3 = Color3.fromRGB(0, 0, 0)
						BCor1.TextSize = 14.000
	
						Cor2.Name = "Cor2"
						Cor2.Parent = Frame_2
						Cor2.BackgroundColor3 = SettingsRac[Type].Breathing.Color2
						Cor2.Selectable = true
						Cor2.Size = UDim2.new(0, 25, 0, 25)
	
						UICorner_4.CornerRadius = UDim.new(1, 0)
						UICorner_4.Parent = Cor2
	
						BCor2.Name = "BCor2"
						BCor2.Parent = Cor2
						BCor2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						BCor2.BackgroundTransparency = 1.000
						BCor2.Size = UDim2.new(1, 0, 1, 0)
						BCor2.Font = Enum.Font.SourceSans
						BCor2.Text = ""
						BCor2.TextColor3 = Color3.fromRGB(0, 0, 0)
						BCor2.TextSize = 14.000
	
						local vandogbucu = false
						ColorValButton.MouseButton1Click:Connect(function()
							vandogbucu = not vandogbucu
							local CSize = vandogbucu and UDim2.new(1, 0, 0, 255) or UDim2.new(1, 0, 0, 35)
							TweenService:Create(ColorPick, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {Size = CSize}):Play()
						end)
	
						ColorValButton.MouseButton1Click:Connect(function()
							Library_Function.ButtonEffect()
						end)
	
						local userInputService = game:GetService("UserInputService")
						local runService = game:GetService("RunService")
	
						local plr = game.Players.LocalPlayer
						local mouse = plr:GetMouse()
	
						local colorInput, hueInput = nil,nil
						local nguvail = true
						local cungroival = 0
						local function cum(...)
							if nguvail then
								return task.wait(...)
							else
								task.wait()
								return false
							end
						end
	
						local function RBGToText(color)
							return {math.floor(color.r*255),math.floor(color.g*255),math.floor(color.b*255)}
						end
	
						local function Color3FromHex(hex)
							hex = hex:gsub("#", ""):upper():gsub("0X", "")
							return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
						end
						local function Color3ToHex(color)
							local r, g, b = string.format("%X", math.floor(color.R * 255)), string.format("%X", math.floor(color.G * 255)), string.format("%X", math.floor(color.B * 255))
							if #r < 2 then
								r = "0" .. r
							end
							if #g < 2 then
								g = "0" .. g
							end
							if #b < 2 then
								b = "0" .. b
							end
							return string.format("%s%s%s", r, g, b)
						end
						H, S, V = 1,1,1
						local function LayCaiLonHon(a,b) 
							if a>b then return a,b else return b,a end
						end
						local function Cong(a,b) 
							if (a+b)>255 then 
								local lon,be = LayCaiLonHon(a,b)
								local delta = 255-lon
								local lon2,be2 = LayCaiLonHon(delta,be)
	
								return (lon2-be2)
							else
								return (a+b)
							end
						end
						function CongColor(a,b) 
							local Color1,Color2=a,b
							local SQRT = math.sqrt
							local NewColor={}
							NewColor.R = 255 - SQRT(((255-Color1.R)^2 + (255-Color2.R)^2)/2)
							NewColor.G = 255 - SQRT(((255-Color1.G)^2 + (255-Color2.G)^2)/2)
							NewColor.B = 255 - SQRT(((255-Color1.B)^2 + (255-Color2.B)^2)/2)
							return Color3.new(NewColor.R,NewColor.G,NewColor.B)
						end
						local function UpdateColor(concac)
							local NewColor = concac or Color3.fromHSV(H, S, V)
							if not NewColor then S, H, V = concac:ToHSV() end
							HexBox.Text = Color3ToHex(NewColor)
							Color.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
							if concac then
								Color.BackgroundColor3 = concac
								SelectorColor.Position = UDim2.new(concac and select(3, Color3.toHSV(concac)))
							end
							local pos = 1 - (Color3.toHSV(NewColor))
							local scaley = Hue.Frame.Position.Y.Scale
							if scaley ~= pos and not ((pos == 0 or pos == 1) and (scaley == 1 or scaley == 0)) then
								Hue.Frame.Position = UDim2.fromScale(0,pos)
							end
							RBox.Text, GBox.Text, BBox.Text = RBGToText(NewColor)[1],RBGToText(NewColor)[2],RBGToText(NewColor)[3]
							ColorVal.BackgroundColor3 = NewColor
							local Types = {}
							getgenv().UIColor[Type] = NewColor
						end
						UpdateColor(SettingsRac[Type].Color)
						local function setcungroi(stage)
							if colorInput then
								colorInput = (colorInput:Disconnect() and nil) or nil
							end
							if hueInput then
								hueInput = (hueInput:Disconnect() and nil) or nil
							end
							
							if stage then 
								pcall(function()
									local kietthongminh = 1 / 255
									while cum() and _G.Cungroi do
										cungroival = kietthongminh + cungroival
										if cungroival > 1 then
											cungroival = 0
										end
										H = cungroival
										UpdateColor(Color3.fromHSV(cungroival, 1, 1))
									end
								end)
							end
							
						end
						local csize = _G.Cungroi and UDim2.new(1,-4,1,-4) or UDim2.new(0,0,0,0)
						local  pos = _G.Cungroi and UDim2.new(.5,0,.5,0) or UDim2.new(0,0,1,0)
						local apos = _G.Cungroi and Vector2.new(.5,.5) or Vector2.new(0,1)
						check.Size=csize
						check.Position=pos
						check.AnchorPoint = apos
						task.spawn(function() 
							setcungroi(_G.Cungroi)
						end)
						
						
	
						Cungroitog.MouseButton1Click:Connect(function() Library_Function.ButtonEffect() end)
	
						Cungroitog.MouseButton1Click:Connect(function()
							_G.Cungroi = not _G.Cungroi
							csize = _G.Cungroi and UDim2.new(1,-4,1,-4) or UDim2.new(0,0,0,0)
							pos = _G.Cungroi and UDim2.new(.5,0,.5,0) or UDim2.new(0,0,1,0)
							apos = _G.Cungroi and Vector2.new(.5,.5) or Vector2.new(0,1)
							game.TweenService:Create(check,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Size = csize, Position = pos, AnchorPoint = apos}):Play()
							setcungroi(_G.Cungroi)
						end)
	
						HexBox.FocusLost:Connect(function()
							if #HexBox.Text > 5 then
								local occho, rac = pcall(Color3FromHex, HexBox.Text)
								UpdateColor((occho and rac))
							end
						end)
	
						RBox.FocusLost:Connect(function()
							if tonumber(RBox.Text) > 255 then 
								RBox.Text = 255
							elseif tonumber(RBox.Text) < 0 then
								RBox.Text = 0
							end
							local occho, rac = pcall(Color3.fromRGB, tonumber(RBox.Text),tonumber(BBox.Text),tonumber(GBox.Text))
							UpdateColor((occho and rac))
						end)
	
						GBox.FocusLost:Connect(function()
							if tonumber(GBox.Text) > 255 then 
								GBox.Text = 255
							elseif tonumber(GBox.Text) < 0 then
								GBox.Text = 0
							end
							local occho, rac = pcall(Color3.fromRGB, tonumber(RBox.Text),tonumber(BBox.Text),tonumber(GBox.Text))
							UpdateColor((occho and rac))
						end)
						BBox.FocusLost:Connect(function()
							if tonumber(BBox.Text) > 255 then 
								BBox.Text = 255
							elseif tonumber(BBox.Text) < 0 then
								BBox.Text = 0
							end
							local occho, rac = pcall(Color3.fromRGB, tonumber(RBox.Text),tonumber(BBox.Text),tonumber(GBox.Text))
							UpdateColor((occho and rac))
						end)
	
						H = 1 - (math.clamp(Hue.Frame.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
						S = (math.clamp(Color.SelectorColor.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
						V = 1 - (math.clamp(Color.SelectorColor.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
	
						Color.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								if colorInput then
									colorInput:Disconnect()
								end
								isDragging = true
								colorInput = runService.RenderStepped:Connect(function()
									local colorX = (math.clamp(mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
									local colorY = (math.clamp(mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
									SelectorColor.Position = UDim2.fromScale(colorX, colorY)
									S = colorX
									V = 1 - colorY
									UpdateColor()
								end)
							end
						end)
	
						Color.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								if colorInput then
									isDragging = false
									colorInput:Disconnect()
								end
							end
						end)
	
						Hue.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								if hueInput then
									hueInput:Disconnect()
								end
								isDragging = true
								hueInput = runService.RenderStepped:Connect(function()
									local hueY = math.clamp(mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y
									Hue.Frame.Position = UDim2.fromScale(0,hueY)
									H = 1 - hueY
									UpdateColor()
								end)
							end
						end)
	
						Hue.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								if hueInput then
									isDragging = false
									hueInput:Disconnect()
								end
							end
						end)
	
						BCor1.MouseButton1Click:Connect(function()
							Library_Function.ButtonEffect()
						end)
	
						BCor2.MouseButton1Click:Connect(function()
							Library_Function.ButtonEffect()
						end)
	
						BCor1.MouseButton1Click:Connect(function()
							Cor1.BackgroundColor3 = ColorVal.BackgroundColor3
							SettingsRac[Type].Breathing.Color1=ColorVal.BackgroundColor3
						end)
	
						BCor2.MouseButton1Click:Connect(function()
							Cor2.BackgroundColor3 = ColorVal.BackgroundColor3
							SettingsRac[Type].Breathing.Color2=ColorVal.BackgroundColor3
						end)
					   
						Hoithoitog.MouseButton1Click:Connect(function() Library_Function.ButtonEffect() end)
						local vanmeo = false
						task.spawn(function() 
							while task.wait() do 
								if SettingsRac[Type].Breathing.Toggle then 
									UpdateColor(ColorVal.BackgroundColor3)
								end
							end
						end)
						local function cacrac() 
							local co2, co1 = Cor2.BackgroundColor3, Cor1.BackgroundColor3
							local csize = SettingsRac[Type].Breathing.Toggle and UDim2.new(1,-4,1,-4) or UDim2.new(0,0,0,0)
							local pos = SettingsRac[Type].Breathing.Toggle and UDim2.new(.5,0,.5,0) or UDim2.new(0,0,1,0)
							local apos = SettingsRac[Type].Breathing.Toggle and Vector2.new(.5,.5) or Vector2.new(0,1)
							game.TweenService:Create(check_2,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Size = csize, Position = pos, AnchorPoint = apos}):Play()
							if SettingsRac[Type].Breathing.Toggle then 
							   local ab = game.TweenService:Create(ColorVal,TweenInfo.new(2),{BackgroundColor3 = co1})
							   local ab1 = game.TweenService:Create(Color,TweenInfo.new(2),{BackgroundColor3 = co1})
								ab:Play()
								ab1:Play()
								ab.Completed:Connect(function()
									if SettingsRac[Type].Breathing.Toggle then 
									  local  ac = game.TweenService:Create(ColorVal,TweenInfo.new(2),{BackgroundColor3 = co2})
									   local ac1 = game.TweenService:Create(Color,TweenInfo.new(2),{BackgroundColor3 = co2})
										ac:Play()
										ac1:Play()
										if SettingsRac[Type].Breathing.Toggle then 
											ac.Completed:Connect(function()
												ab:Play()
												ab1:Play()
											end)
										end
									end
								end)
								
							end
						end
						task.spawn(function() 
							cacrac()
						end)
						Hoithoitog.MouseButton1Click:Connect(function()
							SettingsRac[Type].Breathing.Toggle = not SettingsRac[Type].Breathing.Toggle 
							cacrac()
						end)
	
					end
	
					function Setting_Section_Function.CreateBox(Setting)
	
						local TitleText = tostring(Setting.Title) or ""
						local Placeholder = tostring(Setting.Placeholder) or ""
						local Default = getgenv().UIColor[Setting.Type] or ""
	
						local BoxFrame = Instance.new("Frame")
						local BoxCorner = Instance.new("UICorner")
						local BoxBG = Instance.new("Frame")
						local ButtonCorner = Instance.new("UICorner")
						local Boxtitle = Instance.new("TextLabel")
						local BoxCor = Instance.new("Frame")
						local ButtonCorner_2 = Instance.new("UICorner")
						local Boxxxx = Instance.new("TextBox")
						local Lineeeee = Instance.new("Frame")
	
						BoxFrame.Name = "BoxFrame"
						BoxFrame.Parent = Section
						BoxFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
						BoxFrame.BackgroundTransparency = 1.000
						BoxFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
						BoxFrame.Size = UDim2.new(1, 0, 0, 60)
	
						BoxCorner.CornerRadius = UDim.new(0, 4)
						BoxCorner.Name = "BoxCorner"
						BoxCorner.Parent = BoxFrame
	
						BoxBG.Name = "Background1"
						BoxBG.Parent = BoxFrame
						BoxBG.AnchorPoint = Vector2.new(0.5, 0.5)
						BoxBG.Position = UDim2.new(0.5, 0, 0.5, 0)
						BoxBG.Size = UDim2.new(1, -10, 1, 0)
						BoxBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
						table.insert(UpdateCallBack["Background 1 Color"],function() 
							BoxBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
						end)
						BoxBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
						table.insert(UpdateCallBack["Background 1 Transparency"],function() 
							BoxBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
						end)
	
						ButtonCorner.CornerRadius = UDim.new(0, 4)
						ButtonCorner.Name = "ButtonCorner"
						ButtonCorner.Parent = BoxBG
	
						Boxtitle.Name = "TextColor"
						Boxtitle.Parent = BoxBG
						Boxtitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Boxtitle.BackgroundTransparency = 1.000
						Boxtitle.Position = UDim2.new(0, 10, 0, 0)
						Boxtitle.Size = UDim2.new(1, -10, 0.5, 0)
						Boxtitle.Font = Enum.Font.GothamBlack
						Boxtitle.Text = TitleText
						Boxtitle.TextSize = 14.000
						Boxtitle.TextXAlignment = Enum.TextXAlignment.Left
						Boxtitle.TextColor3 = getgenv().UIColor["Text Color"]
						table.insert(UpdateCallBack["Text Color"],function() 
							Boxtitle.TextColor3 = getgenv().UIColor["Text Color"]
						end)
	
						BoxCor.Name = "Background2"
						BoxCor.Parent = BoxBG
						BoxCor.AnchorPoint = Vector2.new(1, 0.5)
						BoxCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
						BoxCor.ClipsDescendants = true
						BoxCor.Position = UDim2.new(1, -5, 0, 40)
						BoxCor.Size = UDim2.new(1, -10, 0, 25)
						table.insert(UpdateCallBack["Text Color"],function() 
							BoxCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
						end)
	
						ButtonCorner_2.CornerRadius = UDim.new(0, 4)
						ButtonCorner_2.Name = "ButtonCorner"
						ButtonCorner_2.Parent = BoxCor
	
						Boxxxx.Name = "TextColorPlaceholder"
						Boxxxx.Parent = BoxCor
						Boxxxx.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Boxxxx.BackgroundTransparency = 1.000
						Boxxxx.Position = UDim2.new(0, 5, 0, 0)
						Boxxxx.Size = UDim2.new(1, -5, 1, 0)
						Boxxxx.Font = Enum.Font.GothamBold
						Boxxxx.PlaceholderText = Placeholder
						Boxxxx.Text = ""
						Boxxxx.TextSize = 14.000
						Boxxxx.TextXAlignment = Enum.TextXAlignment.Left
						Boxxxx.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
						Boxxxx.TextColor3 = getgenv().UIColor["Text Color"]
						table.insert(UpdateCallBack["Placeholder Text Color"],function() 
							Boxxxx.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
						end)
						table.insert(UpdateCallBack["Text Color"],function() 
							Boxxxx.TextColor3 = getgenv().UIColor["Text Color"]
						end)
	
						Lineeeee.Name = "Setting_Lineeeee"
						Lineeeee.Parent = BoxCor
						Lineeeee.BackgroundTransparency = 1.000
						Lineeeee.Position = UDim2.new(0, 0, 1, -2)
						Lineeeee.Size = UDim2.new(1, 0, 0, 6)
						Lineeeee.BackgroundColor3 = getgenv().UIColor["Textbox Highlight Color"]
						table.insert(UpdateCallBack["Textbox Highlight Color"],function() 
							Lineeeee.BackgroundColor3 = getgenv().UIColor["Textbox Highlight Color"]
						end)
	
						Boxxxx.Focused:Connect(function() 
							TweenService:Create(Lineeeee,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundTransparency = 0}):Play()
						end)
	
						Boxxxx.Focused:Connect(function() 
							Library_Function.ButtonEffect()
						end)
	
						Boxxxx.FocusLost:Connect(function()
							TweenService:Create(Lineeeee,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundTransparency = 1}):Play()
							if Boxxxx.Text ~= '' then
								getgenv().UIColor[Setting.Type] = Boxxxx.Text
								if Setting.Type == "Background Image" then
									Library_Function.ReloadMain(Boxxxx.Text)
								end
							end
						end)
	
						local textbox_function = {}
	
						if Default then
							Boxxxx.Text = Default
							getgenv().UIColor[Setting.Type] = Default
						end
	
						function textbox_function.SetValue(Value)
							Boxxxx.Text = Value
							getgenv().UIColor[Setting.Type]=Value
						end 
	
						return textbox_function;
	
	
					end
	
					function Setting_Section_Function.CreateSlider(Setting)
							
						local TitleText = tostring(Setting.Title) or ""
						local Min_Value = tonumber(Setting.Min) or 0
						local Max_Value = tonumber(Setting.Max) or 100
						local Precise = Setting.Precise or false
						local DefaultValue = getgenv().UIColor[Setting.Type] or 0
						local Callback = function(v) getgenv().UIColor[Setting.Type]=v end
	
						local SizeChia = 600;
	
						local SliderFrame = Instance.new("Frame")
						local SliderCorner = Instance.new("UICorner")
						local SliderBG = Instance.new("Frame")
						local SliderBGCorner = Instance.new("UICorner")
						local SliderTitle = Instance.new("TextLabel")
						local SliderBar = Instance.new("Frame")
						local SliderButton = Instance.new("TextButton")
						local SliderBarCorner = Instance.new("UICorner")
						local Bar = Instance.new("Frame")
						local BarCorner = Instance.new("UICorner")
						local Sliderboxframe = Instance.new("Frame")
						local Sliderbox = Instance.new("UICorner")
						local Sliderbox_2 = Instance.new("TextBox")
	
						SliderFrame.Name = TitleText..'buda'
						SliderFrame.Parent = Section
						SliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
						SliderFrame.BackgroundTransparency = 1.000
						SliderFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
						SliderFrame.Size = UDim2.new(1, 0, 0, 50)
	
						SliderCorner.CornerRadius = UDim.new(0, 4)
						SliderCorner.Name = "SliderCorner"
						SliderCorner.Parent = SliderFrame
	
						SliderBG.Name = "Background1"
						SliderBG.Parent = SliderFrame
						SliderBG.AnchorPoint = Vector2.new(0.5, 0.5)
						SliderBG.Position = UDim2.new(0.5, 0, 0.5, 0)
						SliderBG.Size = UDim2.new(1, -10, 1, 0)
						SliderBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
						table.insert(UpdateCallBack["Background 1 Color"],function() 
							SliderBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
						end)
						SliderBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
						table.insert(UpdateCallBack["Background 1 Transparency"],function() 
							SliderBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
						end)
	
						SliderBGCorner.CornerRadius = UDim.new(0, 4)
						SliderBGCorner.Name = "SliderBGCorner"
						SliderBGCorner.Parent = SliderBG
	
						SliderTitle.Name = "TextColor"
						SliderTitle.Parent = SliderBG
						SliderTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
						SliderTitle.BackgroundTransparency = 1.000
						SliderTitle.Position = UDim2.new(0, 10, 0, 0)
						SliderTitle.Size = UDim2.new(1, -10, 0, 25)
						SliderTitle.Font = Enum.Font.GothamBlack
						SliderTitle.Text = TitleText
						SliderTitle.TextSize = 14.000
						SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
						SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]
						table.insert(UpdateCallBack["Text Color"],function() 
							SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]
						end)
	
						SliderBar.Name = "SliderBar"
						SliderBar.Parent = SliderFrame
						SliderBar.AnchorPoint = Vector2.new(.5, 0.5)
						SliderBar.Position = UDim2.new(.5, 0, 0.5, 14)
						SliderBar.Size = UDim2.new(0, 600, 0, 6)
						SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
						table.insert(UpdateCallBack["Background 2 Color"],function() 
							SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
						end)
	
						SliderButton.Name = "SliderButton "
						SliderButton.Parent = SliderBar
						SliderButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
						SliderButton.BackgroundTransparency = 1.000
						SliderButton.Size = UDim2.new(1, 0, 1, 0)
						SliderButton.Font = Enum.Font.GothamBold
						SliderButton.Text = ""
						SliderButton.TextColor3 = Color3.fromRGB(230, 230, 230)
						SliderButton.TextSize = 14.000
	
						SliderBarCorner.CornerRadius = UDim.new(1, 0)
						SliderBarCorner.Name = "SliderBarCorner"
						SliderBarCorner.Parent = SliderBar
	
						Bar.Name = "Bar"
						Bar.BorderSizePixel = 0
						Bar.Parent = SliderBar
						Bar.Size = UDim2.new(0, 0, 1, 0)
						Bar.BackgroundColor3 = getgenv().UIColor["Slider Line Color"]
						table.insert(UpdateCallBack["Slider Line Color"],function() 
							Bar.BackgroundColor3 = getgenv().UIColor["Slider Line Color"]
						end)
	
	
						BarCorner.CornerRadius = UDim.new(1, 0)
						BarCorner.Name = "BarCorner"
						BarCorner.Parent = Bar
	
						Sliderboxframe.Name = "Background2"
						Sliderboxframe.Parent = SliderFrame
						Sliderboxframe.AnchorPoint = Vector2.new(1, 0)
						Sliderboxframe.Position = UDim2.new(1, -10, 0, 5)
						Sliderboxframe.Size = UDim2.new(0, 150, 0, 25)
						Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
						table.insert(UpdateCallBack["Background 2 Color"],function() 
							Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
						end)
	
						Sliderbox.CornerRadius = UDim.new(0, 4)
						Sliderbox.Name = "Sliderbox"
						Sliderbox.Parent = Sliderboxframe
	
						Sliderbox_2.Name = "TextColor"
						Sliderbox_2.Parent = Sliderboxframe
						Sliderbox_2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
						Sliderbox_2.BackgroundTransparency = 1.000
						Sliderbox_2.Size = UDim2.new(1, 0, 1, 0)
						Sliderbox_2.Font = Enum.Font.GothamBold
						Sliderbox_2.Text = ""
						Sliderbox_2.TextSize = 14.000
						Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]
						table.insert(UpdateCallBack["Text Color"],function() 
							Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]
						end)
	
						SliderButton.MouseEnter:Connect(function()
							TweenService:Create(Bar,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundColor3 = getgenv().UIColor["Slider Highlight Color"]}):Play()
						end)
	
						SliderButton.MouseLeave:Connect(function()
							TweenService:Create(Bar,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundColor3 = getgenv().UIColor["Slider Line Color"]}):Play()
						end)
	
						local mouse = game.Players.LocalPlayer:GetMouse()
	
						if DefaultValue then 
							if DefaultValue <= Min_Value then DefaultValue = Min_Value elseif DefaultValue >= Max_Value then DefaultValue = Max_Value end
							Bar.Size = UDim2.new(1 - ((Max_Value - DefaultValue) / (Max_Value - Min_Value)),0, 0, 6)
							Sliderbox_2.Text = DefaultValue
							Callback(DefaultValue)
						end
	
						SliderButton.MouseButton1Down:Connect(function()
							local value = Precise and  tonumber(string.format("%.1f",(((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))) or math.floor((((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))
	
							pcall(function()
								Callback(value)
								Sliderbox_2.Text = value
							end)
							Bar.Size = UDim2.new(0, math.clamp(mouse.X - Bar.AbsolutePosition.X, 0, SizeChia), 0, 6)
							moveconnection = mouse.Move:Connect(function()   
								local value = Precise and  tonumber(string.format("%.1f",(((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))) or math.floor((((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))
								pcall(function()
									Callback(value)
									Sliderbox_2.Text = value
								end)
								Bar.Size = UDim2.new(0, math.clamp(mouse.X - Bar.AbsolutePosition.X, 0, SizeChia), 0, 6)
							end)
							releaseconnection = uis.InputEnded:Connect(function(Mouse)
								if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
									local value = Precise and  tonumber(string.format("%.1f",(((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))) or math.floor((((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))
	
									pcall(function()
										Callback(value)
										Sliderbox_2.Text = value
									end)
									Bar.Size = UDim2.new(0, math.clamp(mouse.X - Bar.AbsolutePosition.X, 0, SizeChia), 0, 6)
									moveconnection:Disconnect()
									releaseconnection:Disconnect()
								end
							end)
						end)
	
						local function GetSliderValue(Value)
							if tonumber(Value) <= Min_Value then
								Bar.Size = UDim2.new(0,(0 * SizeChia), 0, 6)
								Sliderbox_2.Text = Min_Value
								Callback(tonumber(Min_Value))
	
							elseif tonumber(Value) >= Max_Value then
								Bar.Size = UDim2.new(0,(Max_Value  /  Max_Value * SizeChia), 0, 6)
								Sliderbox_2.Text = Max_Value
								Callback(tonumber(Max_Value))
							else
								Bar.Size = UDim2.new(1 - ((Max_Value - Value) / (Max_Value - Min_Value)),0, 0, 6)
								Callback(tonumber(Value))
							end
						end
	
	
						Sliderbox_2.FocusLost:Connect(function()
							GetSliderValue(Sliderbox_2.Text)
						end)
	
	
						local slider_function = {}
	
						function slider_function.SetValue(Value)
							GetSliderValue(Value)
						end
	
						return slider_function
	
	
					end
	
				return Setting_Section_Function
	
			end
	
			return Setting_Function
	
	
		end
	
		local CustomColorUI = Library.CreateCustomColor()
	
		local CCMain = CustomColorUI.CreateSection("Main")
		CCMain.CreateColorPicker({Title = "Border Color", Type = "Border Color"})
		CCMain.CreateColorPicker({Title = "Click Effect Color", Type = "Click Effect Color"})
		CCMain.CreateColorPicker({Title = "Setting Icon Color", Type = "Setting Icon Color"})
		CCMain.CreateBox({Title = 'Logo Image', Placeholder = 'URL Here (PNG only), Recommended 128x128', Type = "Logo Image"})
		
		local CCSearch = CustomColorUI.CreateSection("Search")
		CCSearch.CreateColorPicker({Title = "Search Icon Color", Type = "Search Icon Color"})
		CCSearch.CreateColorPicker({Title = "Search Icon Highlight Color", Type = "Search Icon Highlight Color"})
		
		local CCText = CustomColorUI.CreateSection("Text")
		CCText.CreateColorPicker({Title = "GUI Text Color", Type = "GUI Text Color"})
		CCText.CreateColorPicker({Title = "Text Color", Type = "Text Color"})
		CCText.CreateColorPicker({Title = "Placeholder Text Color", Type = "Placeholder Text Color"})
		CCText.CreateColorPicker({Title = "Title Text Color", Type = "Title Text Color"})
		
		local CCBackground = CustomColorUI.CreateSection("Background")
		CCBackground.CreateColorPicker({Title = "Background 1 Color", Type = "Background 1 Color"})
		CCBackground.CreateSlider({Title = 'Background 1 Transparency', Type = "Background 1 Transparency", Min = 0, Max = 1, Default = 0, Precise = true})
		CCBackground.CreateColorPicker({Title = "Background 2 Color", Type = "Background 2 Color"})
		CCBackground.CreateColorPicker({Title = "Background 3 Color", Type = "Background 3 Color"})
		CCBackground.CreateBox({Title = 'Background Image', Placeholder = 'URL Here (WEBM / PNG only), Recommended 1280x720', Type = "Background Image"})
		
		local CCPage = CustomColorUI.CreateSection("Page")
		CCPage.CreateColorPicker({Title = "Page Selected Color", Type = "Page Selected Color"})
		
		local CCSection = CustomColorUI.CreateSection("Section")
		CCSection.CreateColorPicker({Title = "Section Text Color", Type = "Section Text Color"})
		CCSection.CreateColorPicker({Title = "Section Underline Color", Type = "Section Underline Color"})
		
		local CCToggle = CustomColorUI.CreateSection("Toggle")
		CCToggle.CreateColorPicker({Title = "Toggle Border Color", Type = "Toggle Border Color"})
		CCToggle.CreateColorPicker({Title = "Toggle Checked Color", Type = "Toggle Checked Color"})
		CCToggle.CreateColorPicker({Title = "Toggle Desc Color", Type = "Toggle Desc Color"})
		
		local CCButton = CustomColorUI.CreateSection("Button")
		CCButton.CreateColorPicker({Title = "Button Color", Type = "Button Color"})
		
		local CCButton = CustomColorUI.CreateSection("Label")
		CCButton.CreateColorPicker({Title = "Label Color", Type = "Label Color"})
		
		local CCDropdown = CustomColorUI.CreateSection("Dropdown")
		CCDropdown.CreateColorPicker({Title = "Dropdown Icon Color", Type = "Dropdown Icon Color"})
		CCDropdown.CreateColorPicker({Title = "Dropdown Selected Color", Type = "Dropdown Selected Color"})
		
		local CCTextbox = CustomColorUI.CreateSection("Textbox")
		CCTextbox.CreateColorPicker({Title = "Textbox Highlight Color", Type = "Textbox Highlight Color"})
		
		local CCBox = CustomColorUI.CreateSection("Box")
		CCBox.CreateColorPicker({Title = "Box Highlight Color", Type = "Box Highlight Color"})
		
		local CCSlider = CustomColorUI.CreateSection("Slider")
		CCSlider.CreateColorPicker({Title = "Slider Line Color", Type = "Slider Line Color"})
		CCSlider.CreateColorPicker({Title = "Slider Highlight Color", Type = "Slider Highlight Color"})
		
		local CCAnimation = CustomColorUI.CreateSection("Animation")
		CCAnimation.CreateSlider({Title = 'Tween Animation 1 Speed', Type = "Tween Animation 1 Speed", Min = 0, Max = 0.75, Default = 0.25, Precise = true})
		CCAnimation.CreateSlider({Title = 'Tween Animation 2 Speed', Type = "Tween Animation 2 Speed", Min = 0, Max = 1, Default = 0.5, Precise = true})
		CCAnimation.CreateSlider({Title = 'Tween Animation 3 Speed', Type = "Tween Animation 3 Speed", Min = 0, Max = 0.5, Default = 0.1, Precise = true})
	
		local Main_Function = {}
	
		local LayoutOrderBut = -1
		local LayoutOrder = -1
		local PageCounter = 1
	
		function Main_Function.CreatePage(Setting)
	
			local Page_Name = tostring(Setting.Page_Name) 
			local Page_Title = tostring(Setting.Page_Title)
	
			LayoutOrder = LayoutOrder + 1
			LayoutOrderBut = LayoutOrderBut + 1
	
			--Control 
			local PageName = Instance.new("Frame")
			local Frame = Instance.new("Frame")
			local TabNameCorner = Instance.new("UICorner")
			local Line = Instance.new("Frame")
			local InLine = Instance.new("Frame")
			local LineCorner = Instance.new("UICorner")
			local TabTitleContainer = Instance.new("Frame")
			local TabTitle = Instance.new("TextLabel")
			local PageButton = Instance.new("TextButton")
	
	
			PageName.Name = Page_Name.."_Control"
			PageName.Parent = ControlList
			PageName.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			PageName.BackgroundTransparency = 1.000
			PageName.Size = UDim2.new(1, -10, 0, 25)
			PageName.LayoutOrder = LayoutOrderBut
	
			Frame.Parent = PageName
			Frame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			Frame.BackgroundTransparency = 1.000
			Frame.Position = UDim2.new(0, 5, 0, 0)
			Frame.Size = UDim2.new(1, -5, 1, 0)
	
			TabNameCorner.CornerRadius = UDim.new(0, 4)
			TabNameCorner.Name = "TabNameCorner"
			TabNameCorner.Parent = Frame
	
			Line.Name = "Line"
			Line.Parent = Frame
			Line.AnchorPoint = Vector2.new(0, 0.5)
			Line.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			Line.BackgroundTransparency = 1.000
			Line.Position = UDim2.new(0, 0, 0.5, 0)
			Line.Size = UDim2.new(0, 14, 1, 0)
	
			InLine.Name = "PageInLine"
			InLine.Parent = Line
			InLine.AnchorPoint = Vector2.new(0.5, 0.5)
			InLine.BorderSizePixel = 0
			InLine.Position = UDim2.new(0.5, 0, 0.5, 0)
			InLine.Size = UDim2.new(1, -10, 0, 0)
			InLine.BackgroundColor3 = getgenv().UIColor["Page Selected Color"]
			table.insert(UpdateCallBack["Page Selected Color"],function() 
				InLine.BackgroundColor3 = getgenv().UIColor["Page Selected Color"]
			end)
	
			LineCorner.Name = "LineCorner"
			LineCorner.Parent = InLine
	
			TabTitleContainer.Name = "TabTitleContainer"
			TabTitleContainer.Parent = Frame
			TabTitleContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			TabTitleContainer.BackgroundTransparency = 1.000
			TabTitleContainer.Position = UDim2.new(0, 15, 0, 0)
			TabTitleContainer.Size = UDim2.new(1, -15, 1, 0)
	
			TabTitle.Name = "GUITextColor"
			TabTitle.Parent = TabTitleContainer
			TabTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			TabTitle.BackgroundTransparency = 1.000
			TabTitle.Size = UDim2.new(1, 0, 1, 0)
			TabTitle.Font = Enum.Font.GothamBold
			TabTitle.Text = Page_Name
			TabTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
			TabTitle.TextSize = 14.000
			TabTitle.TextXAlignment = Enum.TextXAlignment.Left
			TabTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]
			table.insert(UpdateCallBack["GUI Text Color"],function() 
				TabTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]
			end)
	
			PageButton.Name = "PageButton"
			PageButton.Parent = PageName
			PageButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			PageButton.BackgroundTransparency = 1.000
			PageButton.Size = UDim2.new(1, 0, 1, 0)
			PageButton.Font = Enum.Font.SourceSans
			PageButton.Text = ""
			PageButton.TextColor3 = Color3.fromRGB(0, 0, 0)
			PageButton.TextSize = 14.000
	
			-- Container
	
			local PageContainer = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local PageTitle = Instance.new("TextLabel")
			local PageList = Instance.new("ScrollingFrame")
			local Pagelistlayout = Instance.new("UIListLayout")
	
			local CurrentPage = PageCounter
			PageCounter = PageCounter + 1
			PageContainer.Name = "Page" .. CurrentPage
			PageContainer.Parent = MainPage
			PageContainer.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
			PageContainer.Position = UDim2.new(0, 190, 0, 30)
			PageContainer.Size = UDim2.new(0, 435, 0, 325)
			PageContainer.LayoutOrder = LayoutOrder
			table.insert(UpdateCallBack["Background 1 Color"],function() 
				PageContainer.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
			end)
			PageContainer.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
			table.insert(UpdateCallBack["Background 1 Transparency"],function() 
				PageContainer.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
			end)
	
			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = PageContainer
	
			PageTitle.Name = "GUITextColor"
			PageTitle.Parent = PageContainer
			PageTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			PageTitle.BackgroundTransparency = 1.000
			PageTitle.Position = UDim2.new(0, 5, 0, 0)
			PageTitle.Size = UDim2.new(1, 0, 0, 25)
			PageTitle.Font = Enum.Font.GothamBold
			PageTitle.Text = Page_Title
			PageTitle.TextSize = 16.000
			PageTitle.TextXAlignment = Enum.TextXAlignment.Left
			PageTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]
			table.insert(UpdateCallBack["GUI Text Color"],function() 
				PageTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]
			end)
	
			PageList.Name = "PageList"
			PageList.Parent = PageContainer
			PageList.Active = true
			PageList.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			PageList.BackgroundTransparency = 1.000
			PageList.BorderColor3 = Color3.fromRGB(27, 42, 53)
			PageList.BorderSizePixel = 0
			PageList.Position = UDim2.new(0, 5, 0, 30)
			PageList.Size = UDim2.new(1, -10, 1, -30)
			PageList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
			PageList.ScrollBarThickness = 5
			PageList.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	
			Pagelistlayout.Name = "Pagelistlayout"
			Pagelistlayout.Parent = PageList
			Pagelistlayout.SortOrder = Enum.SortOrder.LayoutOrder
			Pagelistlayout.Padding = UDim.new(0, 5)
			Pagelistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				PageList.CanvasSize = UDim2.new(0, 0, 0, Pagelistlayout.AbsoluteContentSize.Y + 5)
			end)
	
			local PageSearch = Instance.new("Frame")
			local PageSearchCorner = Instance.new("UICorner")
			local SearchFrame = Instance.new("Frame")
			local SearchIcon = Instance.new("ImageLabel")
			local active = Instance.new("TextButton")
			local Bucu = Instance.new("TextBox")
	
			PageSearch.Name = "Background2"
			PageSearch.Parent = PageContainer
			PageSearch.AnchorPoint = Vector2.new(1, 0)
			PageSearch.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
			PageSearch.Position = UDim2.new(1, -5, 0, 5)
			PageSearch.Size = UDim2.new(0, 20, 0, 20)
			PageSearch.ClipsDescendants = true
			table.insert(UpdateCallBack["Background 2 Color"],function() 
				PageSearch.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
			end)
	
			PageSearchCorner.CornerRadius = UDim.new(0, 2)
			PageSearchCorner.Name = "PageSearchCorner"
			PageSearchCorner.Parent = PageSearch
	
			SearchFrame.Name = "SearchFrame"
			SearchFrame.Parent = PageSearch
			SearchFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			SearchFrame.BackgroundTransparency = 1.000
			SearchFrame.Size = UDim2.new(0, 20, 0, 20)
	
			SearchIcon.Name = "SearchIcon"
			SearchIcon.Parent = SearchFrame
			SearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			SearchIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			SearchIcon.BackgroundTransparency = 1.000
			SearchIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			SearchIcon.Size = UDim2.new(0, 16, 0, 16)
			SearchIcon.Image = "rbxassetid://8154282545"
			SearchIcon.ImageColor3 = getgenv().UIColor["Search Icon Color"]
			table.insert(UpdateCallBack["Search Icon Color"],function() 
				SearchIcon.ImageColor3 = getgenv().UIColor["Search Icon Color"]
			end)
	
			active.Name = "active"
			active.Parent = SearchFrame
			active.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			active.BackgroundTransparency = 1.000
			active.Size = UDim2.new(1, 0, 1, 0)
			active.Font = Enum.Font.SourceSans
			active.Text = ""
			active.TextColor3 = Color3.fromRGB(0, 0, 0)
			active.TextSize = 14.000
	
			Bucu.Name = "TextColorPlaceholder"
			Bucu.Parent = PageSearch
			Bucu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Bucu.BackgroundTransparency = 1.000
			Bucu.Position = UDim2.new(0, 30, 0, 0)
			Bucu.Size = UDim2.new(1, -30, 1, 0)
			Bucu.Font = Enum.Font.GothamBold
			Bucu.Text = ""
			Bucu.TextSize = 14.000
			Bucu.TextXAlignment = Enum.TextXAlignment.Left
			Bucu.PlaceholderText = "Search Section name"
			Bucu.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
			Bucu.TextColor3 = getgenv().UIColor["Text Color"]
			table.insert(UpdateCallBack["Placeholder Text Color"],function() 
				Bucu.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
			end)
			table.insert(UpdateCallBack["Text Color"],function() 
				Bucu.TextColor3 = getgenv().UIColor["Text Color"]
			end)
			
			local cummmed = false 
	
			active.MouseEnter:Connect(function()
				TweenService:Create(SearchIcon,TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]),{ImageColor3 = getgenv().UIColor["Search Icon Highlight Color"]}):Play()
			end)
	
			active.MouseLeave:Connect(function()
				TweenService:Create(SearchIcon,TweenInfo.new(getgenv().UIColor["Tween Animation 3 Speed"]),{ImageColor3 = getgenv().UIColor["Search Icon Color"]}):Play()
			end)
	
			active.MouseButton1Click:Connect(function()
				Library_Function.ButtonEffect()
			end)
	
			Bucu.Focused:Connect(function()
				Library_Function.ButtonEffect()
			end)
	
			active.MouseButton1Click:Connect(function()
				cummmed = not cummmed
				local size = cummmed and UDim2.new(0,175,0,20) or  UDim2.new(0,20,0,20)
				game.TweenService:Create(PageSearch,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Size = size}):Play()
			end)
	
			local function succac()
				for i,v in next, PageList:GetChildren() do 
					if not v:IsA('UIListLayout') then 
						v.Visible = false
					end
				end
			end
			
			local function ra()
				for a, b in pairs(PageList:GetChildren()) do
					if not b:IsA('UIListLayout') then 
						if string.find(string.lower(b.Name),string.lower(Bucu.Text)) then 
							b.Visible = true
						end
					end
				end
			end
			
			Bucu:GetPropertyChangedSignal("Text"):Connect(function()
				succac()
				ra()
			end)
	
			for i,v in pairs(ControlList:GetChildren()) do
				if not (v:IsA('UIListLayout')) then
					if i == 2 then 
						v.Frame.Line.PageInLine.Size = UDim2.new(1, -10, 1, -10)
						oldlay = v.LayoutOrder
						oldobj = v
					end
				end
			end
	
			PageButton.MouseButton1Click:Connect(function()
				task.spawn(function()
					Library_Function.ButtonEffect()
				end)
		  
				if tostring(UIPage.CurrentPage) == PageContainer.Name then 
					return
				end
	
				for i,v in pairs(MainPage:GetChildren()) do
					if not (v:IsA('UIPageLayout')) and not (v:IsA('UICorner')) then
						v.Visible = false
					end
				end
	
				PageContainer.Visible = true 
				UIPage:JumpTo(PageContainer)
	
				for i,v in next, ControlList:GetChildren() do
					if not (v:IsA('UIListLayout')) then
						if v.Name == Page_Name.."_Control" then 
							if v.LayoutOrder > oldlay  then 
								oldobj.Active = false 
								TweenService:Create(oldobj.Frame.Line.PageInLine,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Size = UDim2.new(1,-10,0,0),Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(.5,1)}):Play()
								v.Frame.Line.PageInLine.Position = UDim2.new(0.5, 0, 0, 0)
								v.Frame.Line.PageInLine.AnchorPoint = Vector2.new(.5,0)
								task.wait(getgenv().UIColor["Tween Animation 1 Speed"])
								TweenService:Create(v.Frame.Line.PageInLine,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Size = UDim2.new(1,-10,1,-10),Position = UDim2.new(0.5, 0, .5, 0), AnchorPoint = Vector2.new(.5,.5)}):Play()
								v.Active = true
								oldobj = v
								oldlay = v.LayoutOrder
							else
								oldobj.Active = false 
								TweenService:Create(oldobj.Frame.Line.PageInLine,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Size = UDim2.new(1,-10,0,0),Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(.5,0)}):Play()
								v.Frame.Line.PageInLine.Position = UDim2.new(0.5, 0, 1, 0)
								v.Frame.Line.PageInLine.AnchorPoint = Vector2.new(.5,1)
								task.wait(getgenv().UIColor["Tween Animation 1 Speed"])
								TweenService:Create(v.Frame.Line.PageInLine,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Size = UDim2.new(1,-10,1,-10),Position = UDim2.new(0.5, 0, .5, 0), AnchorPoint = Vector2.new(.5,.5)}):Play()
								v.Active = true
								oldobj = v
								oldlay = v.LayoutOrder
							end
	
						end
					end
				end
			end)
	
			local Page_Function = {}
	
				function Page_Function.CreateSection(Section_Name)
	
					local Section = Instance.new("Frame")
					local UICorner = Instance.new("UICorner")
					local Topsec = Instance.new("Frame")
					local Sectiontitle = Instance.new("TextLabel")
					local Linesec = Instance.new("Frame")
					local UIGradient = Instance.new("UIGradient")
					local SectionList = Instance.new("UIListLayout")
	
	
					Section.Name = Section_Name.."_Dot"
					Section.Parent = PageList
					Section.Size = UDim2.new(0, 415, 0, 100)
					Section.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
					table.insert(UpdateCallBack["Background 3 Color"],function() 
						Section.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
					end)
					Section.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
					table.insert(UpdateCallBack["Background 1 Transparency"],function() 
						Section.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
					end)
	
					UICorner.CornerRadius = UDim.new(0, 4)
					UICorner.Parent = Section
	
					Topsec.Name = "Topsec"
					Topsec.Parent = Section
					Topsec.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
					Topsec.BackgroundTransparency = 1.000
					Topsec.Size = UDim2.new(0, 415, 0, 30)
	
					Sectiontitle.Name = "Sectiontitle"
					Sectiontitle.Parent = Topsec
					Sectiontitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
					Sectiontitle.BackgroundTransparency = 1.000
					Sectiontitle.Size = UDim2.new(1, 0, 1, 0)
					Sectiontitle.Font = Enum.Font.GothamBold
					Sectiontitle.Text = Section_Name
					Sectiontitle.TextSize = 14.000
					Sectiontitle.TextColor3 = getgenv().UIColor["Section Text Color"]
					table.insert(UpdateCallBack["Section Text Color"],function() 
						Sectiontitle.TextColor3 = getgenv().UIColor["Section Text Color"]
					end)
	
					Linesec.Name = "Linesec"
					Linesec.Parent = Topsec
					Linesec.AnchorPoint = Vector2.new(0.5, 1)
					Linesec.BorderSizePixel = 0
					Linesec.Position = UDim2.new(0.5, 0, 1, -2)
					Linesec.Size = UDim2.new(1, -10, 0, 2)
					Linesec.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
					table.insert(UpdateCallBack["Section Underline Color"],function() 
						Linesec.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]
					end)
	
					UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.50, 0.00), NumberSequenceKeypoint.new(0.51, 0.02), NumberSequenceKeypoint.new(1.00, 1.00)}
					UIGradient.Parent = Linesec
	
					SectionList.Name = "SectionList"
					SectionList.Parent = Section
					SectionList.SortOrder = Enum.SortOrder.LayoutOrder
					SectionList.Padding = UDim.new(0, 5)
	
					SectionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						Section.Size = UDim2.new(1, -5, 0, SectionList.AbsoluteContentSize.Y + 5)
					end)
	
					local Section_Function = {}
	
					   function Section_Function.CreateToggle(Setting, Callback)
	
							local Title = tostring(Setting.Title)
							local Desc = Setting.Desc
							local Default = Setting.Default
							if Default == nil then Default = false end
							local Callback = Callback or function() end
	
							local ToggleFrame = Instance.new("Frame")
							local TogFrame1 = Instance.new("Frame")
							local checkbox = Instance.new("ImageLabel")
							local check = Instance.new("ImageLabel")
							local ToggleDesc = Instance.new("TextLabel")
							local ToggleTitle = Instance.new("TextLabel")
							local ToggleBg = Instance.new("Frame")
							local ToggleCorner = Instance.new("UICorner")
							local ToggleButton = Instance.new("TextButton")
							local ToggleList = Instance.new("UIListLayout")
	
							ToggleFrame.Name = "ToggleFrame"
							ToggleFrame.Parent = Section
							ToggleFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							ToggleFrame.BackgroundTransparency = 1.000
							ToggleFrame.Position = UDim2.new(0, 0, 0.300000012, 0)
							ToggleFrame.Size = UDim2.new(1, 0, 0, 0)
							ToggleFrame.AutomaticSize = Enum.AutomaticSize.Y
	
							TogFrame1.Name = "TogFrame1"
							TogFrame1.Parent = ToggleFrame
							TogFrame1.AnchorPoint = Vector2.new(0.5, 0.5)
							TogFrame1.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							TogFrame1.BackgroundTransparency = 1.000
							TogFrame1.Position = UDim2.new(0.5, 0, 0.5, 0)
							TogFrame1.Size = UDim2.new(1, -10, 0, 0)
							TogFrame1.AutomaticSize = Enum.AutomaticSize.Y
	
							checkbox.Name = "checkbox"
							checkbox.Parent = TogFrame1
							checkbox.AnchorPoint = Vector2.new(1, 0.5)
							checkbox.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							checkbox.BackgroundTransparency = 1.000
							checkbox.Position = UDim2.new(1, -5, 0.5, 3)
							checkbox.Size = UDim2.new(0, 25, 0, 25)
							checkbox.Image = "rbxassetid://4552505888"
							checkbox.ImageColor3 = getgenv().UIColor["Toggle Border Color"]
							table.insert(UpdateCallBack["Toggle Border Color"],function() 
								checkbox.ImageColor3 = getgenv().UIColor["Toggle Border Color"]
							end)
	
							check.Name = "check"
							check.Parent = checkbox
							check.AnchorPoint = Vector2.new(0, 1)
							check.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							check.BackgroundTransparency = 1.000
							check.Position = UDim2.new(0, 0, 1, 0)
							check.Image = "rbxassetid://4555411759"
							check.ImageColor3 = getgenv().UIColor["Toggle Checked Color"]
							table.insert(UpdateCallBack["Toggle Checked Color"],function() 
								check.ImageColor3 = getgenv().UIColor["Toggle Checked Color"]
							end)
	
							local tempVar = 5
							if Desc then
								tempVar = 0
								ToggleDesc.Name = "ToggleDesc"
								ToggleDesc.Parent = TogFrame1
								ToggleDesc.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
								ToggleDesc.BackgroundTransparency = 1.000
								ToggleDesc.Position = UDim2.new(0, 15, 0, 20)
								ToggleDesc.Size = UDim2.new(1, -50, 0, 0)
								ToggleDesc.Font = Enum.Font.GothamBlack
								ToggleDesc.Text = Desc
								ToggleDesc.TextSize = 13.000
								ToggleDesc.TextWrapped = true
								ToggleDesc.TextXAlignment = Enum.TextXAlignment.Left
								ToggleDesc.RichText = true
								ToggleDesc.AutomaticSize = Enum.AutomaticSize.Y
								ToggleDesc.TextColor3 = getgenv().UIColor["Toggle Desc Color"]
								table.insert(UpdateCallBack["Toggle Desc Color"],function() 
									ToggleDesc.TextColor3 = getgenv().UIColor["Toggle Desc Color"]
								end)
							else
								ToggleDesc.Text = ''
							end
	
							ToggleTitle.Name = "TextColor"
							ToggleTitle.Parent = TogFrame1
							ToggleTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							ToggleTitle.BackgroundTransparency = 1.000
							ToggleTitle.Position = UDim2.new(0, 10, 0, tempVar)
							ToggleTitle.Size = UDim2.new(1, -10, 0, 20)
							ToggleTitle.Font = Enum.Font.GothamBlack
							ToggleTitle.Text = Title
							ToggleTitle.TextSize = 14.000
							ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
							ToggleTitle.TextYAlignment = Enum.TextYAlignment.Center
							ToggleTitle.RichText = true
							ToggleTitle.AutomaticSize = Enum.AutomaticSize.Y
							ToggleTitle.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								ToggleTitle.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							ToggleBg.Name = "Background1"
							ToggleBg.Parent = TogFrame1
							ToggleBg.Size = UDim2.new(1, 0, 1, 6)
							ToggleBg.ZIndex = 0
							ToggleBg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							table.insert(UpdateCallBack["Background 1 Color"],function() 
								ToggleBg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							end)
							ToggleBg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							table.insert(UpdateCallBack["Background 1 Transparency"],function() 
								ToggleBg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							end)
	
							ToggleCorner.CornerRadius = UDim.new(0, 4)
							ToggleCorner.Name = "ToggleCorner"
							ToggleCorner.Parent = ToggleBg
	
							ToggleButton.Name = "ToggleButton"
							ToggleButton.Parent = TogFrame1
							ToggleButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							ToggleButton.BackgroundTransparency = 1.000
							ToggleButton.Size = UDim2.new(1, 0, 1, 6)
							ToggleButton.Font = Enum.Font.SourceSans
							ToggleButton.Text = ""
							ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
							ToggleButton.TextSize = 14.000
	
							ToggleList.Name = "ToggleList"
							ToggleList.Parent = ToggleFrame
							ToggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
							ToggleList.SortOrder = Enum.SortOrder.LayoutOrder
							ToggleList.VerticalAlignment = Enum.VerticalAlignment.Center
							ToggleList.Padding = UDim.new(0, 5)
	
							local function ChangeStage(val)
	
								local csize = val and UDim2.new(1,-4,1,-4) or UDim2.new(0,0,0,0)
								local pos = val and UDim2.new(.5,0,.5,0) or UDim2.new(0,0,1,0)
								local apos = val and Vector2.new(.5,.5) or Vector2.new(0,1)
	
								game.TweenService:Create(check,TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]),{Size = csize, Position = pos, AnchorPoint = apos}):Play()
	
								Callback(val)
	
							end
	
							if Callback then ChangeStage(Default) end 
	
							ToggleButton.MouseButton1Click:Connect(function()
								Library_Function.ButtonEffect()
							end)
							local function ButtonClick() 
								Default = not Default
								ChangeStage(Default)
							end
							ToggleButton.MouseButton1Down:Connect(function()
								ButtonClick()
							end)
	
							local tog_func = {}
	
									function tog_func.SetStage(value)
										if value ~= Default then 
											ButtonClick()
										end
									end
	
							return tog_func
	
	
						end
	
						function Section_Function.CreateButton(Setting, Callback)
	
							local Title = Setting.Title
							local Callback = Callback or function() end
	
							local ButtonFrame = Instance.new("Frame")
							local ButtonBG = Instance.new("Frame")
							local ButtonCorner = Instance.new("UICorner")
							local ButtonTitle = Instance.new("TextLabel")
							local Button = Instance.new("TextButton")
	
							ButtonFrame.Name = Title..'dot'
							ButtonFrame.Parent = Section
							ButtonFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							ButtonFrame.BackgroundTransparency = 1.000
							ButtonFrame.Position = UDim2.new(0, 0, 0.300000012, 0)
							ButtonFrame.Size = UDim2.new(1, 0, 0, 25)
	
							ButtonBG.Name = "ButtonBG"
							ButtonBG.Parent = ButtonFrame
							ButtonBG.AnchorPoint = Vector2.new(0.5, 0.5)
							ButtonBG.Position = UDim2.new(0.5, 0, 0.5, 0)
							ButtonBG.Size = UDim2.new(1, -10, 1, 0)
							ButtonBG.BackgroundColor3 = getgenv().UIColor["Button Color"]
							table.insert(UpdateCallBack["Button Color"],function() 
								ButtonBG.BackgroundColor3 = getgenv().UIColor["Button Color"]
							end)
							ButtonBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							table.insert(UpdateCallBack["Background 1 Transparency"],function() 
								ButtonBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							end)
	
							ButtonCorner.CornerRadius = UDim.new(0, 4)
							ButtonCorner.Name = "ButtonCorner"
							ButtonCorner.Parent = ButtonBG
	
							ButtonTitle.Name = "TextColor"
							ButtonTitle.Parent = ButtonBG
							ButtonTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							ButtonTitle.BackgroundTransparency = 1.000
							ButtonTitle.Position = UDim2.new(0, 10, 0, 0)
							ButtonTitle.Size = UDim2.new(1, -10, 1, 0)
							ButtonTitle.Font = Enum.Font.GothamBlack
							ButtonTitle.Text = Title
							ButtonTitle.TextSize = 14.000
							ButtonTitle.TextXAlignment = Enum.TextXAlignment.Left
							ButtonTitle.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								ButtonTitle.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
	
							Button.Name = "Button"
							Button.Parent = ButtonBG
							Button.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							Button.BackgroundTransparency = 1.000
							Button.Size = UDim2.new(1, 0, 1, 0)
							Button.Font = Enum.Font.SourceSans
							Button.Text = ""
							Button.TextColor3 = Color3.fromRGB(0, 0, 0)
							Button.TextSize = 14.000
	
							Button.MouseButton1Click:Connect(function()
								Library_Function.ButtonEffect()
							end)
	
							Button.MouseButton1Down:Connect(function()
								Callback()
							end)
	
						end
	
						function Section_Function.CreateLabel(Setting)
	
							local Title = tostring(Setting.Title)
	
							local LabelFrame = Instance.new("Frame")
							local LabelBG = Instance.new("Frame")
							local LabelCorner = Instance.new("UICorner")
							local LabelTitle = Instance.new("TextLabel")
	
							LabelFrame.Name = "LabelFrame"
							LabelFrame.Parent = Section
							LabelFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							LabelFrame.BackgroundTransparency = 1.000
							LabelFrame.Position = UDim2.new(0, 0, 0, 0)
							LabelFrame.Size = UDim2.new(1, 0, 0, 0)
							LabelFrame.AutomaticSize = Enum.AutomaticSize.Y
	
							LabelBG.Name = "LabelBG"
							LabelBG.Parent = LabelFrame
							LabelBG.AnchorPoint = Vector2.new(0.5, 0)
							LabelBG.Position = UDim2.new(0.5, 0, 0, 0)
							LabelBG.Size = UDim2.new(1, -10, 0, -10)
							LabelBG.BackgroundColor3 = getgenv().UIColor["Label Color"]
							LabelBG.AutomaticSize = Enum.AutomaticSize.Y
							table.insert(UpdateCallBack["Label Color"],function() 
								LabelBG.BackgroundColor3 = getgenv().UIColor["Label Color"]
							end)
							LabelBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							table.insert(UpdateCallBack["Background 1 Transparency"],function() 
								LabelBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							end)
	
							LabelCorner.CornerRadius = UDim.new(0, 4)
							LabelCorner.Name = "LabelCorner"
							LabelCorner.Parent = LabelBG
	
							LabelTitle.Name = "TextColor"
							LabelTitle.Parent = LabelBG
							LabelTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							LabelTitle.BackgroundTransparency = 1.000
							LabelTitle.Position = UDim2.new(0, 10, 0, 3)
							LabelTitle.Size = UDim2.new(1, -20, 1, 0)
							LabelTitle.Font = Enum.Font.GothamBlack
							LabelTitle.Text = Title
							LabelTitle.TextSize = 14.000
							LabelTitle.TextXAlignment = Enum.TextXAlignment.Left
							LabelTitle.AutomaticSize = Enum.AutomaticSize.Y
							LabelTitle.TextWrapped = true
							LabelTitle.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								LabelTitle.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							local label_func = {}
	
								function label_func.SetText(text)
									LabelTitle.Text = text
								end
	
								function label_func.SetColor(color)
									LabelTitle.TextColor3 = color
								end
	
							return label_func
						end
	
						function Section_Function.CreateDropdown(Setting, Callback)
	
							local Title = tostring(Setting.Title)
							local List = Setting.List
							local Search = Setting.Search or false
							local Selected = Setting.Selected or false
							local Default = Setting.Default
							local Callback = Callback or function() end
							local IndexTable = Setting.IndexTable
							local pairs = Setting.SortPairs or pairs

							local DropdownFrame = Instance.new("Frame")
							local Dropdownbg = Instance.new("Frame")
							local Dropdowncorner = Instance.new("UICorner")
							local Topdrop = Instance.new("Frame")
							local UICorner = Instance.new("UICorner")
							local ImgDrop = Instance.new("ImageLabel")
							local DropdownButton = Instance.new("TextButton")
							local Dropdownlisttt = Instance.new("Frame")
							local DropdownScroll = Instance.new("ScrollingFrame")
							local ScrollContainer = Instance.new("Frame")
							local ScrollContainerList = Instance.new("UIListLayout")
	
	
							local Dropdowntitle; 
							if Search then 
								Dropdowntitle = Instance.new("TextBox")
								DropdownButton.Visible = false
							else
								Dropdowntitle = Instance.new("TextLabel")
							end
	
	
							DropdownFrame.Name = Title.."DropdownFrame"
							DropdownFrame.Parent = Section
							DropdownFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							DropdownFrame.BackgroundTransparency = 1.000
							DropdownFrame.Position = UDim2.new(0, 0, 0.473684222, 0)
							DropdownFrame.Size = UDim2.new(1, 0, 0, 25)
	
							Dropdownbg.Name = "Background1"
							Dropdownbg.Parent = DropdownFrame
							Dropdownbg.AnchorPoint = Vector2.new(0.5, 0.5)
							Dropdownbg.Position = UDim2.new(0.5, 0, 0.5, 0)
							Dropdownbg.Size = UDim2.new(1, -10, 1, 0)
							Dropdownbg.ClipsDescendants = true
							Dropdownbg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							table.insert(UpdateCallBack["Background 1 Color"],function() 
								Dropdownbg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							end)
							Dropdownbg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							table.insert(UpdateCallBack["Background 1 Transparency"],function() 
								Dropdownbg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							end)
	
							Dropdowncorner.CornerRadius = UDim.new(0, 4)
							Dropdowncorner.Name = "Dropdowncorner"
							Dropdowncorner.Parent = Dropdownbg
	
							Topdrop.Name = "Background2"
							Topdrop.Parent = Dropdownbg
							Topdrop.Size = UDim2.new(1, 0, 0, 25)
							Topdrop.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							table.insert(UpdateCallBack["Background 2 Color"],function() 
								Topdrop.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							end)
							Topdrop.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							table.insert(UpdateCallBack["Background 1 Transparency"],function() 
								Topdrop.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							end)
	
	
							UICorner.CornerRadius = UDim.new(0, 4)
							UICorner.Parent = Topdrop
	
							Dropdowntitle.Name = "TextColorPlaceholder"
							Dropdowntitle.Parent = Topdrop
							Dropdowntitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							Dropdowntitle.BackgroundTransparency = 1.000
							Dropdowntitle.Position = UDim2.new(0, 10, 0, 0)
							Dropdowntitle.Size = UDim2.new(1, -40, 1, 0)
							Dropdowntitle.Font = Enum.Font.GothamBlack
							Dropdowntitle.Text = ''
							Dropdowntitle.TextSize = 14.000
							Dropdowntitle.TextXAlignment = Enum.TextXAlignment.Left
							Dropdowntitle.ClipsDescendants = true
							local Sel = Instance.new("IntValue",Dropdowntitle)
							Sel.Value=-1
							if Default and table.find(List,Default) then 
								Sel.Value=table.find(List,Default)
							end
							if not Selected then
								if Search then
									Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
									Dropdowntitle.PlaceholderText = Title..': '..tostring(Default); 
									table.insert(UpdateCallBack["Placeholder Text Color"],function() 
										Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
									end)
								else
									Dropdowntitle.Text = Title..': '..tostring(Default); 
								end
							else
								if Search then
									Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
									Dropdowntitle.PlaceholderText = Title..': '..tostring(Default); 
									table.insert(UpdateCallBack["Placeholder Text Color"],function() 
										Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
									end)
								else
									Dropdowntitle.Text = Title..': '..tostring(Default); 
								end
							end
							Dropdowntitle.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								Dropdowntitle.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							ImgDrop.Name = "ImgDrop"
							ImgDrop.Parent = Topdrop
							ImgDrop.AnchorPoint = Vector2.new(1, 0.5)
							ImgDrop.BackgroundTransparency = 1.000
							ImgDrop.BorderColor3 = Color3.fromRGB(27, 42, 53)
							ImgDrop.Position = UDim2.new(1, -6, 0.5, 0)
							ImgDrop.Size = UDim2.new(0, 15, 0, 15)
							ImgDrop.Image = "rbxassetid://6954383209"
							ImgDrop.ImageColor3 = getgenv().UIColor["Dropdown Icon Color"]
							table.insert(UpdateCallBack["Dropdown Icon Color"],function() 
								ImgDrop.ImageColor3 = getgenv().UIColor["Dropdown Icon Color"]
							end)
	
							DropdownButton.Name = "DropdownButton"
							DropdownButton.Parent = Topdrop
							DropdownButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							DropdownButton.BackgroundTransparency = 1.000
							DropdownButton.Size = UDim2.new(1, 0, 1, 0)
							DropdownButton.Font = Enum.Font.GothamBold
							DropdownButton.Text = ""
							DropdownButton.TextColor3 = Color3.fromRGB(230, 230, 230)
							DropdownButton.TextSize = 14.000
	
							Dropdownlisttt.Name = "Dropdownlisttt"
							Dropdownlisttt.Parent = Dropdownbg
							Dropdownlisttt.BackgroundTransparency = 1.000
							Dropdownlisttt.BorderSizePixel = 0
							Dropdownlisttt.Position = UDim2.new(0, 0, 0, 25)
							Dropdownlisttt.Size = UDim2.new(1, 0, 0, 25)
							Dropdownlisttt.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	
							DropdownScroll.Name = "DropdownScroll"
							DropdownScroll.Parent = Dropdownlisttt
							DropdownScroll.Active = true
							DropdownScroll.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							DropdownScroll.BackgroundTransparency = 1.000
							DropdownScroll.BorderSizePixel = 0
							DropdownScroll.Size = UDim2.new(1, 0, 1, 0)
							DropdownScroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
							DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
							DropdownScroll.ScrollBarThickness = 5
							DropdownScroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	
							ScrollContainer.Name = "ScrollContainer"
							ScrollContainer.Parent = DropdownScroll
							ScrollContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							ScrollContainer.BackgroundTransparency = 1.000
							ScrollContainer.Position = UDim2.new(0, 5, 0, 5)
							ScrollContainer.Size = UDim2.new(1, -15, 1, -5)
	
							ScrollContainerList.Name = "ScrollContainerList"
							ScrollContainerList.Parent = ScrollContainer
							ScrollContainerList.SortOrder = Enum.SortOrder.LayoutOrder
	
							ScrollContainerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
								DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 10 + ScrollContainerList.AbsoluteContentSize.Y + 5)
							end)
	
							local isbusy = false
	
							local found = {}
	
							local searchtable = {}
							
							local function edit()
								for i in pairs(found) do
									found[i] = nil
								end
								for h, l in pairs(ScrollContainer:GetChildren()) do
									if not l:IsA("UIListLayout") and not l:IsA("UIPadding") and not l:IsA('UIGridLayout') then
										l.Visible = false
									end
								end
								Dropdowntitle.Text = string.lower(Dropdowntitle.Text)
							end
	
							local function SearchDropdown()
								local Results = {}
								for i, v in pairs(searchtable) do
									if string.find(v, Dropdowntitle.Text) then
										table.insert(found, v)
									end
								end
								for a, b in pairs(ScrollContainer:GetChildren()) do
									for c, d in pairs(found) do
										if d == b.Name then
											b.Visible = true
										end
									end
								end
							end
	
							local function clear_object_in_list()
								for i,v in next, ScrollContainer:GetChildren() do 
									if v:IsA('Frame') then 
										v:Destroy()
									end
								end
							end
	
							local ListNew = List
							
							local function refreshlist()
								clear_object_in_list()
	
								searchtable = {}
								
								for i, v in pairs(ListNew) do
									if not Selected then 
									table.insert(searchtable, string.lower(v))
									else 
										table.insert(searchtable, string.lower(i))
									end 
								end
	
								if not Selected then 
									for i,v in pairs (ListNew) do
										local Dropval = Instance.new("Frame")
										local DropvalCorner = Instance.new("UICorner")
										local Line = Instance.new("Frame")
										local InLine = Instance.new("Frame")
										local LineCorner = Instance.new("UICorner")
										local Dropvalcontainer = Instance.new("Frame")
										local Dropvalbutton = Instance.new("TextButton")
	
										Dropval.Name = string.lower(v)
										Dropval.Parent = ScrollContainer
										Dropval.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
										Dropval.BackgroundTransparency = 1.000
										Dropval.Size = UDim2.new(1, 0, 0, 25)
	
										DropvalCorner.CornerRadius = UDim.new(0, 4)
										DropvalCorner.Name = "DropvalCorner"
										DropvalCorner.Parent = Dropval
	
										Line.Name = "Line"
										Line.Parent = Dropval
										Line.AnchorPoint = Vector2.new(0, 0.5)
										Line.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
										Line.BackgroundTransparency = 1.000
										Line.Position = UDim2.new(0, 0, 0.5, 0)
										Line.Size = UDim2.new(0, 14, 1, 0)
	
										InLine.Name = "InLine"
										InLine.Parent = Line
										InLine.AnchorPoint = Vector2.new(0.5, 0.5)
										InLine.BorderSizePixel = 0
										InLine.Position = UDim2.new(0.5, 0, 0.5, 0)
										InLine.Size = UDim2.new(1, -10, 1, -10)
										InLine.BackgroundTransparency = 1
										InLine.BackgroundColor3 = getgenv().UIColor["Dropdown Selected Color"]
										table.insert(UpdateCallBack["Dropdown Selected Color"],function() 
											InLine.BackgroundColor3 = getgenv().UIColor["Dropdown Selected Color"]
										end)
	
										LineCorner.Name = "LineCorner"
										LineCorner.Parent = InLine
	
										Dropvalcontainer.Name = "Dropvalcontainer"
										Dropvalcontainer.Parent = Dropval
										Dropvalcontainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
										Dropvalcontainer.BackgroundTransparency = 1.000
										Dropvalcontainer.Position = UDim2.new(0, 15, 0, 0)
										Dropvalcontainer.Size = UDim2.new(1, -15, 1, 0)
	
										Dropvalbutton.Name = "TextColor"
										Dropvalbutton.Parent = Dropvalcontainer
										Dropvalbutton.Active = false
										Dropvalbutton.BackgroundTransparency = 1.000
										Dropvalbutton.Selectable = false
										Dropvalbutton.Size = UDim2.new(1, 0, 1, 0)
										Dropvalbutton.Font = Enum.Font.GothamBold
										Dropvalbutton.Text = v
										Dropvalbutton.TextSize = 14.000
										Dropvalbutton.TextWrapped = true
										Dropvalbutton.TextXAlignment = Enum.TextXAlignment.Left
										Dropvalbutton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
										Dropvalbutton.TextColor3 = getgenv().UIColor["Text Color"]
										table.insert(UpdateCallBack["Text Color"],function() 
											Dropvalbutton.TextColor3 = getgenv().UIColor["Text Color"]
										end)
										
										if Search then
											if Sel.Value == i then
												InLine.BackgroundTransparency = 0;
											end
										else
											if Sel.Value == i then
												InLine.BackgroundTransparency = 0;
											end
										end
	
										Dropvalbutton.MouseButton1Click:Connect(function()
					
											if Search then
												Dropdowntitle.PlaceholderText = Title..': '..v
												Sel.Value=i
											   
											else
												Dropdowntitle.Text = Title..': '..v
												Sel.Value=i
											  
											end
	
	
											refreshlist()
											if Callback then 
												Callback(v,i)
											end
	
										end)
	
										Dropvalbutton.MouseButton1Click:Connect(function()
											Library_Function.ButtonEffect()
										end)
	
									end
	
								else
	
									for i,v in pairs (ListNew) do
												
										local linetran = v and 0 or 1
	
										local Dropval = Instance.new("Frame")
										local DropvalCorner = Instance.new("UICorner")
										local Line = Instance.new("Frame")
										local InLine = Instance.new("Frame")
										local LineCorner = Instance.new("UICorner")
										local Dropvalcontainer = Instance.new("Frame")
										local Dropvalbutton = Instance.new("TextButton")
	
										Dropval.Name = string.lower(i)
										Dropval.Parent = ScrollContainer
										Dropval.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
										Dropval.BackgroundTransparency = 1.000
										Dropval.Size = UDim2.new(1, 0, 0, 25)
	
										DropvalCorner.CornerRadius = UDim.new(0, 4)
										DropvalCorner.Name = "DropvalCorner"
										DropvalCorner.Parent = Dropval
	
										Line.Name = "Line"
										Line.Parent = Dropval
										Line.AnchorPoint = Vector2.new(0, 0.5)
										Line.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
										Line.BackgroundTransparency = 1
										Line.Position = UDim2.new(0, 0, 0.5, 0)
										Line.Size = UDim2.new(0, 14, 1, 0)
	
										InLine.Name = "InLine"
										InLine.Parent = Line
										InLine.AnchorPoint = Vector2.new(0.5, 0.5)
										InLine.BorderSizePixel = 0
										InLine.Position = UDim2.new(0.5, 0, 0.5, 0)
										InLine.Size = UDim2.new(1, -10, 1, -10)
										InLine.BackgroundTransparency = linetran
										InLine.BackgroundColor3 = getgenv().UIColor["Dropdown Selected Color"]
										table.insert(UpdateCallBack["Dropdown Selected Color"],function() 
											InLine.BackgroundColor3 = getgenv().UIColor["Dropdown Selected Color"]
										end)
	
										LineCorner.Name = "LineCorner"
										LineCorner.Parent = InLine
	
										Dropvalcontainer.Name = "Dropvalcontainer"
										Dropvalcontainer.Parent = Dropval
										Dropvalcontainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
										Dropvalcontainer.BackgroundTransparency = 1.000
										Dropvalcontainer.Position = UDim2.new(0, 15, 0, 0)
										Dropvalcontainer.Size = UDim2.new(1, -15, 1, 0)
	
										Dropvalbutton.Name = "TextColor"
										Dropvalbutton.Parent = Dropvalcontainer
										Dropvalbutton.Active = false
										Dropvalbutton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
										Dropvalbutton.BackgroundTransparency = 1.000
										Dropvalbutton.Selectable = false
										Dropvalbutton.Size = UDim2.new(1, 0, 1, 0)
										Dropvalbutton.Font = Enum.Font.GothamBold
										Dropvalbutton.Text = i
										Dropvalbutton.TextSize = 14.000
										Dropvalbutton.TextWrapped = true
										Dropvalbutton.TextXAlignment = Enum.TextXAlignment.Left
										Dropvalbutton.TextColor3 = getgenv().UIColor["Text Color"]
										table.insert(UpdateCallBack["Text Color"],function() 
											Dropvalbutton.TextColor3 = getgenv().UIColor["Text Color"]
										end)
	
										Dropvalbutton.MouseButton1Click:Connect(function()
											Library_Function.ButtonEffect()
										end)
										
										Dropvalbutton.MouseButton1Click:Connect(function()
											v = not v 
	
											local linetran = v and 0 or 1
	
											TweenService:Create(InLine,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundTransparency = linetran}):Play()
	
											if Callback then
												Callback(i,v)
												ListNew[i] = v
											end
										end)
	
									end
	
	
								end
	
							end
	
							if Search then
								Dropdowntitle.Changed:Connect(function()
									edit()
									SearchDropdown()
								end)
							end
	
							if typeof(Default) ~= 'table' then
								Callback(Default)
								if Search then
									Dropdowntitle.PlaceholderText = Title..': '..tostring(Default)
								else
									Dropdowntitle.Text = Title..': '..tostring(Default)
								end
							elseif Selected then
								for i,v in next, Default do
									ListNew[i] = v
									Callback(i,v)
								end
								Dropdowntitle.Text = ''
								Dropdowntitle.PlaceholderText = Title..': '
							end
	
							DropdownButton.MouseButton1Click:Connect(function()
								refreshlist()
								isbusy = not isbusy
								local listsize = isbusy and UDim2.new(1, 0,0, 170) or UDim2.new(1, 0,0, 0)
								local mainsize = isbusy and UDim2.new(1, 0,0, 200) or UDim2.new(1, 0,0, 25)
								local DropCRotation = isbusy and 90 or 0
	
								TweenService:Create(Dropdownlisttt,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Size = listsize}):Play()
								TweenService:Create(DropdownFrame,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Size = mainsize}):Play()
								TweenService:Create(ImgDrop,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Rotation = DropCRotation}):Play()
	
							end)
	
							DropdownButton.MouseButton1Click:Connect(function()
								Library_Function.ButtonEffect()
							end)
	
							if Search then
								Dropdowntitle.Focused:Connect(function()
									refreshlist()
									isbusy = not isbusy
									local listsize = isbusy and UDim2.new(1, 0,0, 170) or UDim2.new(1, 0,0, 0)
									local mainsize = isbusy and UDim2.new(1, 0,0, 200) or UDim2.new(1, 0,0, 25)
									local DropCRotation = isbusy and 90 or 0
		
									TweenService:Create(Dropdownlisttt,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Size = listsize}):Play()
									TweenService:Create(DropdownFrame,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Size = mainsize}):Play()
									TweenService:Create(ImgDrop,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Rotation = DropCRotation}):Play()
		
								end)
		
								Dropdowntitle.Focused:Connect(function()
									Library_Function.ButtonEffect()
								end)
							end
	
							local dropdown_function = {rf=refreshlist}
	
							function dropdown_function:ClearText()
								if not Selected then
									if Search then
										Dropdowntitle.PlaceholderText = Title..': '
									else
										Dropdowntitle.Text = Title..': ' 
									end
								else
									Dropdowntitle.Text = Title..': '
								end
							end
	
							function dropdown_function:GetNewList(List)
								refreshlist()
								isbusy = false
								local listsize = isbusy and UDim2.new(1, 0,0, 170) or UDim2.new(1, 0,0, 0)
								local mainsize = isbusy and UDim2.new(1, 0,0, 200) or UDim2.new(1, 0,0, 25)
								local DropCRotation = isbusy and 90 or 0
	
								TweenService:Create(Dropdownlisttt,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Size = listsize}):Play()
								TweenService:Create(DropdownFrame,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Size = mainsize}):Play()
								TweenService:Create(ImgDrop,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{Rotation = DropCRotation}):Play()
								
								ListNew = {}
								ListNew = List
	
								for i,v in next, ListNew do
									if Selected then
										Callback(i,v)
									end
								end
	
							end
							
							return dropdown_function
	
						end
	
						function Section_Function.CreateBind(Setting, Callback)
	
							local TitleText = tostring(Setting.Title) or ""
							local KeyCode = Setting.Key
							local Default = Setting.Default or Setting.Key
							local Type = tostring(Default):match("UserInputType") and "UserInputType" or "KeyCode"
							local Callback = Callback or function() end
							
							KeyCode = tostring(KeyCode):gsub("Enum.UserInputType.", "")
							KeyCode = tostring(KeyCode):gsub("Enum.KeyCode.", "")
	
							local BindFrame = Instance.new("Frame")
							local BindCorner = Instance.new("UICorner")
							local BindBG = Instance.new("Frame")
							local ButtonCorner = Instance.new("UICorner")
							local BindButtonTitle = Instance.new("TextLabel")
							local Button = Instance.new("TextButton")
							local BindCor = Instance.new("Frame")
							local ButtonCorner_2 = Instance.new("UICorner")
							local Bindkey = Instance.new("TextButton")
	
							BindFrame.Name = TitleText.."bguvl"
							BindFrame.Parent = Section
							BindFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
							BindFrame.BackgroundTransparency = 1.000
							BindFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
							BindFrame.Size = UDim2.new(1, 0, 0, 35)
	
							BindCorner.CornerRadius = UDim.new(0, 4)
							BindCorner.Name = "BindCorner"
							BindCorner.Parent = BindFrame
	
							BindBG.Name = "Background1"
							BindBG.Parent = BindFrame
							BindBG.AnchorPoint = Vector2.new(0.5, 0.5)
							BindBG.Position = UDim2.new(0.5, 0, 0.5, 0)
							BindBG.Size = UDim2.new(1, -10, 1, 0)
							BindBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							table.insert(UpdateCallBack["Background 1 Color"],function() 
								BindBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							end)
							BindBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							table.insert(UpdateCallBack["Background 1 Transparency"],function() 
								BindBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							end)
	
							ButtonCorner.CornerRadius = UDim.new(0, 4)
							ButtonCorner.Name = "ButtonCorner"
							ButtonCorner.Parent = BindBG
	
							BindButtonTitle.Name = "TextColor"
							BindButtonTitle.Parent = BindBG
							BindButtonTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							BindButtonTitle.BackgroundTransparency = 1.000
							BindButtonTitle.Position = UDim2.new(0, 10, 0, 0)
							BindButtonTitle.Size = UDim2.new(1, -10, 1, 0)
							BindButtonTitle.Font = Enum.Font.GothamBlack
							BindButtonTitle.Text = TitleText
							BindButtonTitle.TextSize = 14.000
							BindButtonTitle.TextXAlignment = Enum.TextXAlignment.Left
							BindButtonTitle.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								BindButtonTitle.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							BindCor.Name = "Background2"
							BindCor.Parent = BindBG
							BindCor.AnchorPoint = Vector2.new(1, 0.5)
							BindCor.Position = UDim2.new(1, -5, 0.5, 0)
							BindCor.Size = UDim2.new(0, 150, 0, 25)
							BindCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							table.insert(UpdateCallBack["Background 2 Color"],function() 
								BindCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							end)
	
							ButtonCorner_2.CornerRadius = UDim.new(0, 4)
							ButtonCorner_2.Name = "ButtonCorner"
							ButtonCorner_2.Parent = BindCor
	
							Bindkey.Name = "Bindkey"
							Bindkey.Parent = BindCor
							Bindkey.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							Bindkey.BackgroundTransparency = 1.000
							Bindkey.Size = UDim2.new(1, 0, 1, 0)
							Bindkey.Font = Enum.Font.GothamBold
							Bindkey.Text = tostring(Default):gsub("Enum.KeyCode.", "");
							Bindkey.TextSize = 14.000
							Bindkey.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								Bindkey.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							local WhitelistedType = {
								[Enum.UserInputType.MouseButton1] = "Mouse1";
								[Enum.UserInputType.MouseButton2] = "Mouse2";
								[Enum.UserInputType.MouseButton3] = "Mouse3";
							};
	
							Bindkey.MouseButton1Click:Connect(function()
								Library_Function.ButtonEffect()
							end)
			
							Bindkey.MouseButton1Click:Connect(function()
								local Connection;
			
								Bindkey.Text = "...";
			
								Connection = game:GetService("UserInputService").InputBegan:Connect(function(i)
									if WhitelistedType[i.UserInputType] then
										Bindkey.Text = WhitelistedType[i.UserInputType];
										task.spawn(function()
											task.wait(0.1)
											Default = i.UserInputType;
											Type = "UserInputType";
										end);
									elseif i.KeyCode ~= Enum.KeyCode.Unknown then
										Bindkey.Text = tostring(i.KeyCode):gsub("Enum.KeyCode.", "");
										task.spawn(function()
											task.wait(0.1)
											Default = i.KeyCode;
											Type = "KeyCode";
										end);
									end;
			
			
									Connection:Disconnect();
								end);
							end);
			
							game:GetService("UserInputService").InputBegan:Connect(function(i)
								if (Default == i.UserInputType or Default == i.KeyCode) then
									Callback(Default);
								end;
							end);
							
						end
	
						function Section_Function.CreateBox(Setting, Callback)
	
							local TitleText = tostring(Setting.Title) or ""
							local Placeholder = tostring(Setting.Placeholder) or ""
							local Default = Setting.Default or false
							local Number_Only = Setting.Number or false 
							local Callback = Callback or function() end
	
							local BoxFrame = Instance.new("Frame")
							local BoxCorner = Instance.new("UICorner")
							local BoxBG = Instance.new("Frame")
							local ButtonCorner = Instance.new("UICorner")
							local Boxtitle = Instance.new("TextLabel")
							local BoxCor = Instance.new("Frame")
							local ButtonCorner_2 = Instance.new("UICorner")
							local Boxxx = Instance.new("TextBox")
							local Lineeeee = Instance.new("Frame")
							local UICorner = Instance.new("UICorner")
	
							BoxFrame.Name = "BoxFrame"
							BoxFrame.Parent = Section
							BoxFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
							BoxFrame.BackgroundTransparency = 1.000
							BoxFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
							BoxFrame.Size = UDim2.new(1, 0, 0, 60)
	
							BoxCorner.CornerRadius = UDim.new(0, 4)
							BoxCorner.Name = "BoxCorner"
							BoxCorner.Parent = BoxFrame
	
							BoxBG.Name = "Background1"
							BoxBG.Parent = BoxFrame
							BoxBG.AnchorPoint = Vector2.new(0.5, 0.5)
							BoxBG.Position = UDim2.new(0.5, 0, 0.5, 0)
							BoxBG.Size = UDim2.new(1, -10, 1, 0)
							BoxBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							table.insert(UpdateCallBack["Background 1 Color"],function() 
								BoxBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							end)
							BoxBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							table.insert(UpdateCallBack["Background 1 Transparency"],function() 
								BoxBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							end)
	
							ButtonCorner.CornerRadius = UDim.new(0, 4)
							ButtonCorner.Name = "ButtonCorner"
							ButtonCorner.Parent = BoxBG
	
							Boxtitle.Name = "TextColor"
							Boxtitle.Parent = BoxBG
							Boxtitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							Boxtitle.BackgroundTransparency = 1.000
							Boxtitle.Position = UDim2.new(0, 10, 0, 0)
							Boxtitle.Size = UDim2.new(1, -10, 0.5, 0)
							Boxtitle.Font = Enum.Font.GothamBlack
							Boxtitle.Text = TitleText
							Boxtitle.TextSize = 14.000
							Boxtitle.TextXAlignment = Enum.TextXAlignment.Left
							Boxtitle.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								Boxtitle.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							BoxCor.Name = "Background2"
							BoxCor.Parent = BoxBG
							BoxCor.AnchorPoint = Vector2.new(1, 0.5)
							BoxCor.ClipsDescendants = true
							BoxCor.Position = UDim2.new(1, -5, 0, 40)
							BoxCor.Size = UDim2.new(1, -10, 0, 25)
							BoxCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							table.insert(UpdateCallBack["Background 2 Color"],function() 
								BoxCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							end)
	
							ButtonCorner_2.CornerRadius = UDim.new(0, 4)
							ButtonCorner_2.Name = "ButtonCorner"
							ButtonCorner_2.Parent = BoxCor
	
							Boxxx.Name = "TextColorPlaceholder"
							Boxxx.Parent = BoxCor
							Boxxx.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							Boxxx.BackgroundTransparency = 1.000
							Boxxx.Position = UDim2.new(0, 5, 0, 0)
							Boxxx.Size = UDim2.new(1, -5, 1, 0)
							Boxxx.Font = Enum.Font.GothamBold
							Boxxx.PlaceholderText = Placeholder
							Boxxx.Text = ""
							Boxxx.TextSize = 14.000
							Boxxx.TextXAlignment = Enum.TextXAlignment.Left
							Boxxx.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
							Boxxx.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Placeholder Text Color"],function() 
								Boxxx.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
							end)
							table.insert(UpdateCallBack["Text Color"],function() 
								Boxxx.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							Lineeeee.Name = "TextNSBoxLineeeee"
							Lineeeee.Parent = BoxCor
							Lineeeee.BackgroundTransparency = 1.000
							Lineeeee.Position = UDim2.new(0, 0, 1, -2)
							Lineeeee.Size = UDim2.new(1, 0, 0, 6)
							Lineeeee.BackgroundColor3 = getgenv().UIColor["Box Highlight Color"]
							table.insert(UpdateCallBack["Box Highlight Color"],function() 
								Lineeeee.BackgroundColor3 = getgenv().UIColor["Box Highlight Color"]
							end)
							
	
							UICorner.CornerRadius = UDim.new(1, 0)
							UICorner.Parent = Lineeeee
	
							Boxxx.Focused:Connect(function() 
								TweenService:Create(Lineeeee,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundTransparency = 0}):Play()
							end)
	
							Boxxx.Focused:Connect(function() 
						
								Library_Function.ButtonEffect()
	
							end)
	
							if Number_Only then 
								Boxxx:GetPropertyChangedSignal("Text"):Connect(function()
									if tonumber(Boxxx.Text) then 
									else 
										Boxxx.PlaceholderText = Placeholder
										Boxxx.Text = ''
									end
								end)
							end
	
							Boxxx.FocusLost:Connect(function()
								TweenService:Create(Lineeeee,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundTransparency = 1}):Play()
								if Boxxx.Text ~= '' then
									Callback(Boxxx.Text)
								end
							end)
	
							local textbox_function = {}
	
							if Default then
								Boxxx.Text = Default
								Callback(Default)
							end
	
							function textbox_function.SetValue(Value)
								Boxxx.Text = Value
								Callback(Value)
							end 
	
							return textbox_function;
	
	
						end
	
						function Section_Function.CreateSlider(Setting, Callback)
							
							local TitleText = tostring(Setting.Title) or ""
							local Min_Value = tonumber(Setting.Min) or 0
							local Max_Value = tonumber(Setting.Max) or 100
							local Precise = Setting.Precise or false
							local DefaultValue = tonumber(Setting.Default) or 0
							local Callback = Callback or function() end
	
							local SizeChia = 400;
	
							local Callback = Callback or function() end
	
							local SliderFrame = Instance.new("Frame")
							local SliderCorner = Instance.new("UICorner")
							local SliderBG = Instance.new("Frame")
							local SliderBGCorner = Instance.new("UICorner")
							local SliderTitle = Instance.new("TextLabel")
							local SliderBar = Instance.new("Frame")
							local SliderButton = Instance.new("TextButton")
							local SliderBarCorner = Instance.new("UICorner")
							local Bar = Instance.new("Frame")
							local BarCorner = Instance.new("UICorner")
							local Sliderboxframe = Instance.new("Frame")
							local Sliderbox = Instance.new("UICorner")
							local Sliderbox_2 = Instance.new("TextBox")
	
							SliderFrame.Name = TitleText..'buda'
							SliderFrame.Parent = Section
							SliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
							SliderFrame.BackgroundTransparency = 1.000
							SliderFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
							SliderFrame.Size = UDim2.new(1, 0, 0, 50)
	
							SliderCorner.CornerRadius = UDim.new(0, 4)
							SliderCorner.Name = "SliderCorner"
							SliderCorner.Parent = SliderFrame
	
							SliderBG.Name = "Background1"
							SliderBG.Parent = SliderFrame
							SliderBG.AnchorPoint = Vector2.new(0.5, 0.5)
							SliderBG.Position = UDim2.new(0.5, 0, 0.5, 0)
							SliderBG.Size = UDim2.new(1, -10, 1, 0)
							SliderBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							table.insert(UpdateCallBack["Background 1 Color"],function() 
								SliderBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
							end)
							SliderBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							table.insert(UpdateCallBack["Background 1 Transparency"],function() 
								SliderBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
							end)
	
	
							SliderBGCorner.CornerRadius = UDim.new(0, 4)
							SliderBGCorner.Name = "SliderBGCorner"
							SliderBGCorner.Parent = SliderBG
	
							SliderTitle.Name = "TextColor"
							SliderTitle.Parent = SliderBG
							SliderTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							SliderTitle.BackgroundTransparency = 1.000
							SliderTitle.Position = UDim2.new(0, 10, 0, 0)
							SliderTitle.Size = UDim2.new(1, -10, 0, 25)
							SliderTitle.Font = Enum.Font.GothamBlack
							SliderTitle.Text = TitleText
							SliderTitle.TextSize = 14.000
							SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
							SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							SliderBar.Name = "SliderBar"
							SliderBar.Parent = SliderFrame
							SliderBar.AnchorPoint = Vector2.new(.5, 0.5)
							SliderBar.Position = UDim2.new(.5, 0, 0.5, 14)
							SliderBar.Size = UDim2.new(0, 400, 0, 6)
							SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							table.insert(UpdateCallBack["Background 2 Color"],function() 
								SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							end)
	
							SliderButton.Name = "SliderButton "
							SliderButton.Parent = SliderBar
							SliderButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							SliderButton.BackgroundTransparency = 1.000
							SliderButton.Size = UDim2.new(1, 0, 1, 0)
							SliderButton.Font = Enum.Font.GothamBold
							SliderButton.Text = ""
							SliderButton.TextColor3 = Color3.fromRGB(230, 230, 230)
							SliderButton.TextSize = 14.000
	
							SliderBarCorner.CornerRadius = UDim.new(1, 0)
							SliderBarCorner.Name = "SliderBarCorner"
							SliderBarCorner.Parent = SliderBar
	
							Bar.Name = "Bar"
							Bar.BorderSizePixel = 0
							Bar.Parent = SliderBar
							Bar.Size = UDim2.new(0, 0, 1, 0)
							Bar.BackgroundColor3 = getgenv().UIColor["Slider Line Color"]
							table.insert(UpdateCallBack["Slider Line Color"],function() 
								Bar.BackgroundColor3 = getgenv().UIColor["Slider Line Color"]
							end)
	
	
							BarCorner.CornerRadius = UDim.new(1, 0)
							BarCorner.Name = "BarCorner"
							BarCorner.Parent = Bar
	
							Sliderboxframe.Name = "Background2"
							Sliderboxframe.Parent = SliderFrame
							Sliderboxframe.AnchorPoint = Vector2.new(1, 0)
							Sliderboxframe.Position = UDim2.new(1, -10, 0, 5)
							Sliderboxframe.Size = UDim2.new(0, 150, 0, 25)
							Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							table.insert(UpdateCallBack["Background 2 Color"],function() 
								Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
							end)
	
							Sliderbox.CornerRadius = UDim.new(0, 4)
							Sliderbox.Name = "Sliderbox"
							Sliderbox.Parent = Sliderboxframe
	
							Sliderbox_2.Name = "TextColor"
							Sliderbox_2.Parent = Sliderboxframe
							Sliderbox_2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
							Sliderbox_2.BackgroundTransparency = 1.000
							Sliderbox_2.Size = UDim2.new(1, 0, 1, 0)
							Sliderbox_2.Font = Enum.Font.GothamBold
							Sliderbox_2.Text = ""
							Sliderbox_2.TextSize = 14.000
							Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]
							table.insert(UpdateCallBack["Text Color"],function() 
								Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]
							end)
	
							SliderButton.MouseEnter:Connect(function()
								TweenService:Create(Bar,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundColor3 = getgenv().UIColor["Slider Highlight Color"]}):Play()
							end)
	
							SliderButton.MouseLeave:Connect(function()
								TweenService:Create(Bar,TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]),{BackgroundColor3 = getgenv().UIColor["Slider Line Color"]}):Play()
							end)
	
							local mouse = game.Players.LocalPlayer:GetMouse()
	
							if DefaultValue then 
								if DefaultValue <= Min_Value then DefaultValue = Min_Value elseif DefaultValue >= Max_Value then DefaultValue = Max_Value end
								Bar.Size = UDim2.new(1 - ((Max_Value - DefaultValue) / (Max_Value - Min_Value)),0, 0, 6)
								Sliderbox_2.Text = DefaultValue
								Callback(DefaultValue)
							end
	
							SliderButton.MouseButton1Down:Connect(function()
								local value = Precise and  tonumber(string.format("%.1f",(((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))) or math.floor((((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))
	
								pcall(function()
									Callback(value)
									Sliderbox_2.Text = value
								end)
								Bar.Size = UDim2.new(0, math.clamp(mouse.X - Bar.AbsolutePosition.X, 0, SizeChia), 0, 6)
								moveconnection = mouse.Move:Connect(function()   
									local value = Precise and  tonumber(string.format("%.1f",(((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))) or math.floor((((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))
									pcall(function()
										Callback(value)
										Sliderbox_2.Text = value
									end)
									Bar.Size = UDim2.new(0, math.clamp(mouse.X - Bar.AbsolutePosition.X, 0, SizeChia), 0, 6)
								end)
								releaseconnection = uis.InputEnded:Connect(function(Mouse)
									if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
										local value = Precise and  tonumber(string.format("%.1f",(((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))) or math.floor((((tonumber(Max_Value) - tonumber(Min_Value)) / SizeChia) * Bar.AbsoluteSize.X) + tonumber(Min_Value))
	
										pcall(function()
											Callback(value)
											Sliderbox_2.Text = value
										end)
										Bar.Size = UDim2.new(0, math.clamp(mouse.X - Bar.AbsolutePosition.X, 0, SizeChia), 0, 6)
										moveconnection:Disconnect()
										releaseconnection:Disconnect()
									end
								end)
							end)
	
							local function GetSliderValue(Value)
								if tonumber(Value) <= Min_Value then
									Bar.Size = UDim2.new(0,(0 * SizeChia), 0, 6)
									Sliderbox_2.Text = Min_Value
									Callback(tonumber(Min_Value))
	
								elseif tonumber(Value) >= Max_Value then
									Bar.Size = UDim2.new(0,(Max_Value  /  Max_Value * SizeChia), 0, 6)
									Sliderbox_2.Text = Max_Value
									Callback(tonumber(Max_Value))
								else
									Bar.Size = UDim2.new(1 - ((Max_Value - Value) / (Max_Value - Min_Value)),0, 0, 6)
									Callback(tonumber(Value))
								end
							end
	
	
							Sliderbox_2.FocusLost:Connect(function()
								GetSliderValue(Sliderbox_2.Text)
							end)
	
	
							local slider_function = {}
	
							function slider_function.SetValue(Value)
								GetSliderValue(Value)
							end
	
							return slider_function
	
	
						end
	
	
					return Section_Function
	
				end
	
			return Page_Function
	
		end
	
		return Main_Function
	
	end
	
	return Library
]])()
print("\nTai sao Vo Hoang lai nang den muc vay\nWhy Vo Hoang can be that tard")
print("Sucvat123")
local rnd = tostring(math.random(1,100000))

-- (function() 
--     local concac

--     if isfile("uilib.lua") then 
--         concac = readfile("uilib.lua")
--         Library=loadstring(concac)()
--         --print(Library)
--     else
--         concac = game:HttpGet("https://raw.githubusercontent.com/7bgqRy0CC2wCjblo9W4kmWBejs72uKCNqI7XqUL/SeaUILib/main/UI/Logo")
--     end
--     if not Library then 
--         Library =loadstring(syn.crypt.decrypt(concac,"tempVar"))() end
-- end)()
local keylist = {"af298fe2fe0361c","e69327320bfcb7e","66036fb2f36e983","f27c0d2a3bee5a6","","ad4f5fc1ec8dd0a","2341aff65def585"} --,"d96d10a1b806168"
local key = getgenv().Key or ""
--setclipboard(syn.crypt.decrypt(concac,"tempVar"))
--local Library=loadstring(concac)()

task.wait()
local FieldFarmPos = {
    -- SunflowerField = {
    --     Listpos = {},
    --     Range = {}
    -- }
}
local Cache = {}
local plr = game.Players.LocalPlayer
local Settings = {mothaiba=true}

function formatNumber(v)
    return tostring(v):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end
function vToK(tabl)
    local out = {}
    for k, v in pairs(tabl) do
        out[v] = k
    end
    return out
end
function RemoveVal(tb,val) 
    for k,v in pairs(tb) do 
        if v==val then 
            table.remove(tb,k)
            break;
        end    
    end
end
function DienTichTamGiac(x,y,z)
    x=Vector3.new(x.X,0,x.Z)
    y=Vector3.new(y.X,0,y.Z)
    z=Vector3.new(z.X,0,z.Z)
    
    local a = (x-y).magnitude
    local b = (y-z).magnitude
    local c = (x-z).magnitude
    local cv = a+b+c
    local p = cv/2
    local S =(p*(p-a)*(p-b)*(p-c))
    return S
end 

-- function IsInTriagule(Point,a,b,c) 
--     print(DienTichTamGiac(a,b,Point)+DienTichTamGiac(a,Point,c) + DienTichTamGiac(Point,b,c)-DienTichTamGiac(a,b,c))
--     return DienTichTamGiac(a,b,Point)+DienTichTamGiac(a,Point,c) + DienTichTamGiac(Point,b,c) == DienTichTamGiac(a,b,c)
-- end
function IsInTriagule(point, a,b,c)
    a=Vector3.new(a.X,0,a.Z)
    b=Vector3.new(b.X,0,b.Z)
    c=Vector3.new(c.X,0,c.Z)
    local triangle = {a,b,c}
    local v0 = triangle[3] - triangle[1]
    local v1 = triangle[2] - triangle[1]
    local v2 = point - triangle[1]
  
    local dot00 = v0:Dot(v0)
    local dot01 = v0:Dot(v1)
    local dot02 = v0:Dot(v2)
    local dot11 = v1:Dot(v1)
    local dot12 = v1:Dot(v2)
  
    local invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
    local u = (dot11 * dot02 - dot01 * dot12) * invDenom
    local v = (dot00 * dot12 - dot01 * dot02) * invDenom
  
    return (u >= 0) and (v >= 0) and (u + v < 1)
  end

function ToTrueFalse(tabl, f)
    local out = {}
    for k, v in pairs(tabl) do
        if f then
            out[k] = f
        else
            out[k] = false
        end
    end

    return out
end
function ToST(tabl, s)
    local out = {}
    for k, v in pairs(tabl) do
       out[k]=s
    end
    return out
end


repeat task.wait() until game:IsLoaded()
local plr = game.Players.LocalPlayer
-- repeat task.wait() until plr
-- repeat task.wait() until plr.Character
-- repeat task.wait() until plr.Character:FindFirstChild("HumanoidRootPart")
-- repeat task.wait() until plr.PlayerGui:FindFirstChild("ScreenGui")
-- repeat task.wait() until plr.PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("Menus")
-- repeat task.wait() until plr.PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("LoadingMessage")
-- repeat task.wait() until plr.PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("LoadingMessage").Visible==false
local connect
local funcwrap
local ret
local ListFunc = {}
local old
local connect2
old = hookmetamethod(game,"__index",function(...) 
    if checkcaller() then return old(...) end
    if not connect then 
        connect=Instance.new("IntValue")
        connect.Changed:Connect(function(val)
            if val==100 then 
                for k,v in pairs(ListFunc) do 
                    if not v.Done then 
                        task.spawn(function() 
                            local s,e = pcall(function() 
                                v.Res = k()
                            end)
                            if e then print(e) end
                            v.tvk = true
                            connect2.Value=100
                            connect2.Value=0
                        end)
                        v.Done=true
                    end
                end
            end 
        end)
    end
    return old(...)
end)
repeat task.wait() until connect
print("Connected")
function warpF2(f) 
    if not connect2 then 
        connect2=Instance.new("IntValue")
    end
    ListFunc[f] = {}


    connect.Value=100
    connect.Value=0
    
    while not ListFunc[f].tvk do 
        connect2.Changed:Wait()
    end
    local res = ListFunc[f].Res
    ListFunc[f] = nil
    return res
end
-- local old = require
-- local hash = {}
-- local require = function(x) 
--     if hash[x] then 
--         return hash[x]
--     end
--     hash[x] = warpF2(function() return old(x) end)
--     return hash[x]
-- end
local u1 = require(game.ReplicatedStorage.ClientStatCache);
local Killing

local name = plr.Name
function hup()
    local old
    old = hookmetamethod(game,"__namecall",function(...) 
        if checkcaller() then 
            if getnamecallmethod() == "WaitForChild" then 
                if plr.Character then 
                    local Self,Key,Time = ...
                    if Self == plr.Character then 
                        if plr.Character:FindFirstChild(Key) then 
                            return plr.Character:FindFirstChild(Key)
                        else
                            repeat task.wait() until plr.Character and plr.Character:FindFirstChild(Key)
                            return plr.Character:FindFirstChild(Key)
                        end
                    end
                end
            end
        end
        return old(...)
    end)

    local old
    old = hookmetamethod(game,"__index",function(...) 
        local self,key = ...
        if checkcaller() then 
            if tostring(self) == name and key == "HumanoidRootPart" then 
                return self:WaitForChild("HumanoidRootPart")
            end
        end
        return old(...)
    end)
end
hup()



function DisableGlider() 
    local uis = game:GetService("UserInputService")
    for k,v in pairs(getconnections(uis.JumpRequest)) do 
        v:Disable()    
    end
end
function EnableGlider() 
    local uis = game:GetService("UserInputService")
    for k,v in pairs(getconnections(uis.JumpRequest)) do 
        v:Enable()    
    end
end
local ListTileGrid = {}
for k,v in pairs(plr.PlayerGui.ScreenGui:GetChildren()) do 
    if v.Name=="TileGrid" then 
        table.insert(ListTileGrid,v)
    end
end
local SaveFileName = getgenv().SaveFileName or plr.Name.."_BeeSwarmSimulator.json"

function SaveSettings()
    local HttpService = game:GetService("HttpService")
    if not isfolder("Sea Hub") then
        makefolder("Sea Hub")
    end
    writefile("Sea Hub/" .. SaveFileName, HttpService:JSONEncode(Settings))
end

function ReadSetting() 
    local s,e = pcall(function() 
        local HttpService = game:GetService("HttpService")
        if not isfolder("Sea Hub") then
            makefolder("Sea Hub")
        end
        return HttpService:JSONDecode(readfile("Sea Hub/" .. SaveFileName))
    end)
    if s then return e 
    else
        SaveSettings()
        return ReadSetting()
    end
end
Settings = ReadSetting()

if getgenv().WebHookLink then 
    Settings.WebHookUrl = getgenv().WebHookLink
end
if getgenv().DisableConvert then Settings.DisableConvert = true end
if getgenv().CustomSetting then 
    for k,v in pairs(getgenv().CustomSetting) do 
        Settings[k] = v
    end
end

function GetPlrHive() 
    for _, v in pairs(game.Workspace.Honeycombs:GetChildren()) do
        if tostring(v.Owner.Value) == plr.Name then
            return v
        end
    end
end

task.wait(1)
for k,v in pairs(game:GetService("Workspace").Gates:GetChildren()) do 
	for k,v in pairs(v:GetChildren()) do 
		pcall(function() 
			v.CanCollide=false
		end)
	end
end
local LevelFarm = {"CurrentField","QuestPollen","QuestField","FieldBoost","QuestMob","Guiding","Sprout","Pushroom","StickBug","Metor","Mob"}
local ListAllToken = {}
local ListAllDupedToken = {}
local StopFarm = {"Farm","SetHeight", "FTPrio", "Snail","Metor","Kill","Stocking","Snowflake","Rare","Leaf","Firefly","Donate","Planter","Stick","Ant","Dispenser","Craft","Memory","FieldBoost","tuoidz","StopMoreOne"}

local listjelly = {"Crimson","Cobalt","Festive","Gummy","Photon","Puppy","Tabby","Vicious","Windy"}
for k,v in pairs(listjelly) do 
    listjelly[k]=listjelly[k].."BeeJelly"    
end
table.insert(listjelly,"RoyalJelly")
function Tele(cf) 
    if plr.Character:FindFirstChild("HumanoidRootPart") then 
        plr.Character.HumanoidRootPart.CFrame=cf
    end
end

function GetHumanoidRootPart() 
    if plr.Character then 
        return plr.Character:FindFirstChild("HumanoidRootPart")
    end
end

function GetHop() 
local PlaceID = game.PlaceId
local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local Deleted = false
local File = pcall(function()
    AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
end
function TPReturner()
    local Site;
    if foundAnything == "" then
        Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
    else
        Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
    end
    local ID = ""
    if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    end
    local num = 0;
    for i,v in pairs(Site.data) do
        local Possible = true
        ID = tostring(v.id)
        if tonumber(v.maxPlayers) > tonumber(v.playing) then
            for _,Existing in pairs(AllIDs) do
                if num ~= 0 then
                    if ID == tostring(Existing) then
                        Possible = false
                    end
                else
                    if tonumber(actualHour) ~= tonumber(Existing) then
                        local delFile = pcall(function()
                            delfile("NotSameServers.json")
                            AllIDs = {}
                            table.insert(AllIDs, actualHour)
                        end)
                    end
                end
                num = num + 1
            end
            if Possible == true then
                table.insert(AllIDs, ID)
                task.wait()
                pcall(function()
                    writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                    task.wait()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, plr)
                end)
                task.wait(4)
            end
        end
    end
end
function GetMemoListName()
    local tab = {}
    for k, v in pairs(game.Workspace.Toys:GetChildren()) do
        if string.match(v.Name, "Memory Match") then
            table.insert(tab, v.Name)
        end
    end
    return tab
end
 function Teleport()
    while task.wait() do
        pcall(function()
            TPReturner()
            if foundAnything ~= "" then
                TPReturner()
            end
        end)
    end
end
return Teleport
end
Hop = GetHop()

local SpawnTable = {}

pcall(function() 
    game:GetService("Workspace").Decorations["30BeeZone"].Pit.TouchInterest:Destroy()
end)
for k,v in pairs(game:GetService("Workspace")["Invisible Walls"]:GetChildren()) do v:Destroy() end
for k,v in pairs(game:GetService("Workspace").Territories:GetChildren()) do v:Destroy() end
-- for k,v in pairs(game:GetService("Workspace").MonsterBarriers:GetChildren()) do v:Destroy() end

-- for k,v in pairs(game:GetService("Workspace").Map.OuterInvisWalls:GetChildren()) do v:Destroy() end
local TvkStatCache = game:GetService("ReplicatedStorage").Events.RetrievePlayerStats:InvokeServer()
task.spawn(function() 
    while task.wait(1) do 
        TvkStatCache =game:GetService("ReplicatedStorage").Events.RetrievePlayerStats:InvokeServer()
        getfenv().TvkStatCache = TvkStatCache
    end
end)
getfenv().TvkStatCache = TvkStatCache

Exploit = "Synapse X"
if http_request and secure_load then
    Exploit = "Sentinel"
    if syn then
        setreadonly(syn, false)
        syn.request = http_request
    else
        syn = {}
        syn.request = http_request
    end
end
function fspawn(f) 
    return coroutine.wrap(f)()
end
function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end
local FieldXYJSON = [[{"Mountain Top Field":{"Y":27,"X":23},"Bamboo Field":{"Y":17,"X":38},"Dandelion Field":{"Y":17,"X":35},"Pumpkin Patch":{"Y":16,"X":32},"Sunflower Field":{"Y":32,"X":19},"Mushroom Field":{"Y":22,"X":31},"Blue Flower Field":{"Y":16,"X":42},"Pine Tree Forest":{"Y":30,"X":22},"Strawberry Field":{"Y":25,"X":21},"Coconut Field":{"Y":20,"X":29},"Stump Field":{"Y":0,"X":0},"Spider Field":{"Y":25,"X":27},"Rose Field":{"Y":19,"X":30},"Ant Field":{"Y":12,"X":31},"Clover Field":{"Y":28,"X":25},"Pineapple Patch":{"Y":22,"X":32},"Cactus Field":{"Y":17,"X":32},"Pepper Patch":{"Y":26,"X":20}}]]
local FieldXY = game:GetService("HttpService"):JSONDecode(FieldXYJSON)

local FieldPart = {}
for k,v in pairs(game.Workspace.Flowers:GetChildren()) do 
    for k,v2 in pairs(game.Workspace.FlowerZones:GetChildren()) do 
        if v2:FindFirstChild("ID") then 
            local id = v2.ID.Value
            if mysplit(v.Name,"-")[1] == "FP"..id then 
                if not FieldPart[v2.Name] then 
                    FieldPart[v2.Name] = {}
                end
                table.insert(FieldPart[v2.Name],v)
            end
        end
    end    
end

function CountMark(Field,a,b,c) 
    -- local OverlapParams = Instance.new("OverlapParams")
    -- OverlapParams.FilterDescendantsInstances = {}
    local count = 0
    for k, v in ipairs(game.Workspace.Particles:GetChildren()) do
        if v:IsA("Part")
        and v.Name == "AreaRing"
        and getgenv().IsValidTokenPos(v, Field) then
            if IsInTriagule(v.Position,a,b,c) then 
                count = count+1
            end
        end
    end
    return count 
end


function triangle_area(x1, y1, x2, y2, x3, y3)
    return math.abs((x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) / 2)
  end
  function barycentric_coordinates(x, y, ax, ay, bx, by, cx, cy)
    local u = ((by - cy) * (x - cx) + (cx - bx) * (y - cy)) / ((by - cy) * (ax - cx) + (cx - bx) * (ay - cy))
    local v = ((cy - ay) * (x - cx) + (ax - cx) * (y - cy)) / ((bx - cx) * (ay - cy) - (ax - cx) * (by - cy))
    local w = 1 - u - v
    return u, v, w
  end
  
  function is_point_in_triangle(x, y, ax, ay, bx, by, cx, cy)
    local u, v, w = barycentric_coordinates(x, y, ax, ay, bx, by, cx, cy)
    return u >= 0 and v >= 0 and w >= 0
  end
  -- Function to build a k-d tree
  local function build_kd_tree(points, depth)
    local axis = depth % 2
    if #points <= 1 then
      return points[1]
    end
    local xory
    if axis == 0 then xory = "x" else xory="y" end
    table.sort(points, function(a, b)
      return a[xory] < b[xory]
    end)
    local median = #points / 2
    local left_points = {}
    for i = 1, median do
      left_points[i] = points[i]
    end
    local right_points = {}
    for i = median + 1, #points do
      right_points[i - median] = points[i]
    end
    local node = {}
    node.point = points[median]
    node.left = build_kd_tree(left_points, depth + 1)
    node.right = build_kd_tree(right_points, depth + 1)
    return node
  end
  
  -- Function to search for the point C with maximum number of points inside the triangle ABC
  function search_point_c(node, a, b, c)
    if node == nil then return 0 end
    --print(node.point)
    if not node.point then return 0 end
    local count = 0
    if is_point_in_triangle(node.point.x, node.point.y,a.x, a.y, b.x, b.y, c.x, c.y) then
      count = count + 1
    end
    local left_count = search_point_c(node.left, a, b, c)
    local right_count = search_point_c(node.right, a, b, c)
    
    return count + left_count + right_count
  end
  
  -- Function to find the point C with maximum number of points inside the triangle ABC
  function find_point_c(kd_tree, points, a, b)
    local max_points, max_point = 0, nil
    for _, c in ipairs(points) do
      local count = search_point_c(kd_tree, a, b, c)
      if count > max_points then
        max_points = count
        max_point = c
      end
    end
    return max_point, max_points
  end
function GetBestTriagulatePoint(Field,a,b) 
    local points = {}
    if FieldPart[Field] then 
        for k,v in pairs(FieldPart[Field]) do 
            table.insert(points,{x=v.Position.X,y=v.Position.Z})
        end
    end
    local listmark = {}
    for k, v in ipairs(game.Workspace.Particles:GetChildren()) do
        if v:IsA("Part")
        and v.Name == "AreaRing"
        and getgenv().IsValidTokenPos(v, Field) then
            table.insert(listmark,{x=v.Position.X,y=v.Position.Z})
        end
    end
    local tree = build_kd_tree(listmark,0)
    return find_point_c(tree,points,{x=a.X,y=a.Z},{x=b.X,y=b.Z})
end


local Con = {}
local Selling = false
function GetListField(a)
    local tablee = {}
    for _, v in pairs(game.Workspace.FlowerZones:GetChildren()) do
        table.insert(tablee, v.Name)
    end
    if a then 
        table.insert(tablee,a)
    end
    return tablee
end
function ListToOb(tabl, tf)
    local out = {}
    for k, v in pairs(tabl) do
        if tf then
            out[v] = true
        else
            out[v] = false
        end
    end
    return out
end

local StopFarmVK = vToK(StopFarm)
local StopFarmList = ToST(StopFarmVK,false)
local SupportedList = {
    "Polar Bear",
    "Brown Bear",
    "Black Bear",
    "Science Bear",
    "Bucko Bee",
    "Riley Bee",
    "Panda Bear",
    "Spirit Bear",
    "Onett"
}
local UnSupported = {
    'Mother Bear','Bubble Bee Man 2','Stick Bug','Gummy Bear',
}
local UnSupportedR = {}
for k,v in pairs(UnSupported) do 
    table.insert(UnSupportedR,v.." (Not fully supported)")
end

local QuestList = {}
for k,v in pairs(SupportedList) do 
    table.insert(QuestList,v)
end
-- for k,v in pairs(UnSupported) do 
--     table.insert(QuestList,v.." (Not fully supported)")
-- end
local BadgeRank = {
    "Cadet","Hotshot","Ace","Master","Grandmaster"
}

local BadgeRankTF = ListToOb(BadgeRank, false)
if not Settings.BadgeRankTF then Settings.BadgeRankTF = BadgeRankTF else  for k,v in pairs(Settings.BadgeRankTF) do 
    BadgeRankTF[k]=v 
end
Settings.BadgeRankTF=BadgeRankTF
end

local BadgeRankTF2 = ListToOb(BadgeRank, false)
if not Settings.BadgeRankTF2 then Settings.BadgeRankTF2 = BadgeRankTF2 else  for k,v in pairs(Settings.BadgeRankTF2) do 
    BadgeRankTF2[k]=v
end
Settings.BadgeRankTF2=BadgeRankTF2
end


local FieldListT = GetListField()
local FieldListTFBadge = ListToOb(FieldListT, false)

if not Settings.FieldListTFBadge then Settings.FieldListTFBadge = FieldListTFBadge else  for k,v in pairs(Settings.FieldListTFBadge) do 
    FieldListTFBadge[k]=v
end
Settings.FieldListTFBadge=FieldListTFBadge
end


local QuestTF = ListToOb(QuestList, true)

if not Settings.QuestTF then Settings.QuestTF = QuestTF else  for k,v in pairs(Settings.QuestTF) do 
    QuestTF[k]=v
end
Settings.QuestTF=QuestTF
end

local QuestTFFast = ListToOb({"Polar Bear","Riley Bee","Bucko Bee"}, false)

if not Settings.QuestTFFast then Settings.QuestTFFast = QuestTFFast else  for k,v in pairs(Settings.QuestTFFast) do 
    QuestTFFast[k]=v
end
Settings.QuestTFFast=QuestTFFast
end

local ColorL = {
    "Red","Blue","White"
}
local ColorLTF = ListToOb(ColorL, true)
if not Settings.ColorLTF then Settings.ColorLTF = ColorLTF else  for k,v in pairs(Settings.ColorLTF) do 
    ColorLTF[k]=v
end
Settings.ColorLTF=ColorLTF
end


local PuffRaity = {
    "Mythic","Legendary","Epic","Rare","Normal"
}
local PuffRaityTF = ListToOb(PuffRaity, true)

if not Settings.PuffRaityTF then Settings.PuffRaityTF = PuffRaityTF else  for k,v in pairs(Settings.PuffRaityTF) do 
    PuffRaityTF[k]=v
end
Settings.PuffRaityTF=PuffRaityTF
end


local TPuffRaityTF = ListToOb(PuffRaity, false)
if not Settings.TPuffRaityTF then Settings.TPuffRaityTF = TPuffRaityTF else  for k,v in pairs(Settings.TPuffRaityTF) do 
    TPuffRaityTF[k]=v
end
Settings.TPuffRaityTF=TPuffRaityTF
end

local PFieldTF = ListToOb(GetListField(), true)
if not Settings.PFieldTF then Settings.PFieldTF = PFieldTF else  for k,v in pairs(Settings.PFieldTF) do 
    PFieldTF[k]=v
end
Settings.PFieldTF=PFieldTF
end



local MemoList = GetMemoListName()
local MemoTF = ListToOb(MemoList,false)

if not Settings.MemoTF then 
    Settings.MemoTF=MemoTF
else
    MemoTF=Settings.MemoTF
end


local AntMethod = ""



function CheckFarm(name) 
    local index = StopFarmVK[name]
    if index then 
        for i=index+1,#StopFarm do 
            if StopFarmList[StopFarm[i]] then 
                return false
            end
        end
        return true
    end
    return false
end

local TokenId = {
    ["Ticket"] = "rbxassetid://1674871631",
    ["Glue"] = "rbxassetid://2504978518",
    ["Pineapple"] = "rbxassetid://1952796032",
    ["Strawberry"] = "1952740625",
    ["Blueberry"] = "rbxassetid://2028453802",
    ["SunflowerSeed"] = "rbxassetid://1952682401",
    ["Treat"] = "rbxassetid://2028574353",
    ["Gumdrop"] = "rbxassetid://1838129169",
    ["Red Extract"] = "2495935291",
    ["Blue Extract"] = "rbxassetid://2495936060",
    ["Oil"] = "2545746569",
    ["Glitter"] = "rbxassetid://2542899798",
    ["Enzymes"] = "rbxassetid://2584584968",
    ["TropicalDrink"] = "3835877932",
    ["Diamond Egg"] = "rbxassetid://1471850677",
    ["Gold Egg"] = "rbxassetid://1471849394",
    ["Mythic Egg"] = "4520739302",
    ["Star Treat"] = "rbxassetid://2028603146",
    ["Royal Jelly"] = "rbxassetid://1471882621",
    ["Star Jelly"] = "rbxassetid://2319943273",
    ["Moon Charm"] = "rbxassetid://2306224708",
    ["Super Smoothie"] = "5144657109",
    ["Bitterberry"] = "4483236276",
    ["Festive Bean"] = "4483230719",
    ["Ginger Bread"] = "6077173317",
    ["Aged Ginger Bread"] = "6077173317",
    ["Honey Token"] = "1472135114",
    ["Purple Poition"] = "4935580111",
    ["Snowflake"] = "6087969886",
    ["Magic Bean"] = "2529092020",
    ["Neonberry"] = "4483267595",
    ["Swirled Wax"] = "8277783113",
    ["Soft Wax"] = "8277778300",
    ["Hard Wax"] = "8277780065",
    ["Caustic Wax"] = "827778166",
}
local TokenId2 = {
    ["Bitterberry2"] = "4483230719"
}

local PrioritizeList = {
    ["Token Link"] = "1629547638",
    ["Inspire"] = "2000457501",
    ["Bear Morph"] = "177997841",
    ["Polen Bomb"] = "1442725244",
    ["Fuzz Bomb"] = "4889322534",
    ["Polen Haze"] = "4889470194",
    ["Triangulate"] = "4519523935",
    ["Inferno"] = "4519549299",
    ["Summon Frog"] = "4528414666",
    ["Tornado"] = "3582519526",
    ["Cross Hair"] = "rbxassetid://8173559749",
    ["Red Boost"] = "1442859163",
    ["Inflate Ballon"] = "8083437090"
}
local ItemDonateList = {
    "Ticket",
    "Gumdrops",
    "Coconut",
    "Stinger",
    "Micro-Converter",
    "FieldDice",
    "JellyBeans",
    "RedExtract",
    "BlueExtract",
    "Glitter",
    "Glue",
    "Oil",
    "Enzymes",
    "TropicalDrink",
    "MagicBean",
    "CloudVial",
    "Box-O-Frogs",
    "AntPass",
    "Treat",
    "SunflowerSeed",
    "Strawberry",
    "Pineapple",
    "Blueberry",
    "Bitterberry",
    "Neonberry",
    "Moon Charm",
    "BasicEgg",
    "SilverEgg",
    "DiamondEgg",
    "RoyalJelly",
    "Gold",
    "PurplePotion"
}
for k, v in pairs(TokenId) do
    PrioritizeList[k] = v
end
function CheckToyCD(toy) 
    local cd = game.Workspace.Toys[toy].Cooldown.Value
        if not TvkStatCache.ToyTimes[toy] then return true end
        return os.time()-TvkStatCache.ToyTimes[toy] > cd
end

local PrioritizeListTF = ToTrueFalse(PrioritizeList)
PrioritizeListTF["Token Link"] = true
if not Settings.PrioritizeListTF then
    Settings.PrioritizeListTF = PrioritizeListTF
else
    for k,v in pairs(Settings.PrioritizeListTF) do 
        PrioritizeListTF[k]=v
    end
    Settings.PrioritizeListTF = PrioritizeListTF
end

local IgnoreListTF = ToTrueFalse(PrioritizeList)
if not Settings.IgnoreListTF then
    Settings.IgnoreListTF = IgnoreListTF
else
    for k,v in pairs(Settings.IgnoreListTF) do 
        IgnoreListTF[k]=v
    end
    Settings.IgnoreListTF = IgnoreListTF
end

function SetupTF(TF,Name) 
    local ListTF = ListToOb(TF)
    
    if not Settings[Name] then Settings[Name] = ListTF else  for k,v in pairs(Settings[Name]) do 
        ListTF[k]=v
    end Settings[Name] = ListTF end
    return ListTF
end
function SetupTFNor(ListTF,Name)     
    if not Settings[Name] then Settings[Name] = ListTF else  for k,v in pairs(Settings[Name]) do 
        ListTF[k]=v
    end Settings[Name] = ListTF end
    return ListTF
end
local NoSell = false

local AutoGum = false
local AutoCoco = false
local TypeFarming = "Walk"
local AutoDig = false

local StopMoreOne = false
local Valid = true
local InsValid = 26110

local AutoRare = false
local TokenIdByK = vToK(TokenId)
local TokenTrueFakse = ToTrueFalse(TokenId)
local TokenTrueFakse2 = ToTrueFalse(TokenId)
local PlantMagic = false
local HoneyPolen = {
    ["Honey"] = true,
    ["Pollen"] = true
}
local BarId = {
    ["Glue"] = "rbxassetid://2504978518",
    ["Oil"] = "rbxassetid://2545746569",
    ["Enzymes"] = "rbxassetid://2584584968",
    ["Tropical Drink"] = "3835877932",
    ["Blue Extract"] = "rbxassetid://2495936060",
    ["Red Extract"] = "rbxassetid://2495935291",
    ["Stinger"] = "2314214749",
    ["Gumdrop"] = "rbxassetid://1838129169"
}
local FieldIconID = {
    ["Sunflower Field"] = "rbxassetid://2908769405",
    ["Dandelion Field"] = "rbxassetid://2908769047",
    ["Strawberry Field"] = "rbxassetid://2908769330",
    ["Blue Flower Field"] = "rbxassetid://2908768899",
    ["Clover Field"] = "rbxassetid://2908768973",
    ["Mushroom Field"] = "rbxassetid://2908769124",
    ["Spider Field"] = "rbxassetid://2908769301",
    ["Bamboo Field"] = "rbxassetid://2908768829",
    ["Pineapple Patch"] = "rbxassetid://2908769153",
    ["Stump Field"] = "rbxassetid://2908769372",
    ["Cactus Field"] = "rbxassetid://2908768937",
    ["Pumpkin Patch"] = "rbxassetid://2908769220",
    ["Pine Tree Forest"] = "rbxassetid://2908769190",
    ["Rose Field"] = "rbxassetid://2908818982",
    ["Coconut Field"] = "rbxassetid://2908769010",
    ["Mountain Top Field"] = "rbxassetid://2908769086",
    ["Ant Field"] = "rbxassetid://2908768728",
    ["Pepper Patch"] = "3835712489"
}
local Sprinklers = {
    ["The Supreme Saturator"] = 1,
    ["Basic Sprinkler"] = 1,
    ["Silver Soakers"] = 2,
    ["Golden Gushers"] = 3,
    ["Diamond Drenchers"] = 4
}
local TimerMob = {
    ["Rhino Beetle"] = {"Rhino Bush", "Rhino Cave 1", "Rhino Cave 2", "Rhino Cave 3", "PineappleBeetle"},
    ["Spider"] = {"Spider Cave"},
    ["Werewolf"] = {"WerewolfCave"},
    ["Scorpion"] = {"RoseBush", "RoseBush2"},
    ["Mantis"] = {"ForestMantis1", "ForestMantis2", "PineappleMantis1"},
    ["Ladybug"] = {"MushroomBush", "Ladybug Bush", "Ladybug Bush 2", "Ladybug Bush 3"}
}
local TimerKiet = ToTrueFalse(TimerMob, true)

if not Settings.TimerKiet then 
    Settings.TimerKiet=TimerKiet
else
    TimerKiet=Settings.TimerKiet
end
local fieldlistpolar = {
    "Spider Field",
    "Mushroom Field",
    "Rose Field",
    "Strawberry Field",
    "Bamboo Field",
    "Pumpkin Patch",
    "Sunflower Field",
    "Cactus Field",
    "Blue Flower Field",
    "Clover Field",
    "Pineapple Patch",
    "Dandelion Field",
    "Pine Tree Forest"
}
local moblistpolar = {
    "Spider",
    "Scorpion",
    "Werewol",
    "Mantises",
    "Ladybug",
    "Rhino Beetles"
}
local MaskField = {
    ["White"] = {
        "Sunflower Field",
        "Dandelion Field",
        "Spider Field",
        "Pineapple Patch",
        "Pumpkin Patch",
        "Coconut Field"
    },
    ["Blue"] = {
        "Blue Flower Field",
        "Bamboo Field",
        "Pine Tree Forest",
        "Stump Field"
    },
    ["Red"] = {
        "Mushroom Field",
        "Clover Field",
        "Strawberry Field",
        "Cactus Field",
        "Rose Field",
        "Pepper Patch",
        "Mountain Top Field",
        "Ant Field"
    }
}
local ShopList = {
}
for _,v in pairs(game.Workspace.Shops:GetChildren()) do 
    table.insert(ShopList,v.Name)
end
for _, v in pairs(game.Workspace.Collectibles:GetChildren()) do
    local Black = Instance.new("IntValue")
    Black.Parent = v
    Black.Name = "Blacklisted"
end
local AutoSprout = false
local times = 0.2
local Running = true
local Invisible = false
local Particles = game.Workspace.Particles
--local Folder2 = Particles.Folder2
local x = 0
local y = 0
local QuestF = plr.PlayerGui.ScreenGui.Menus.Children.Quests.Content
local MaskF = {
    ["White"] = "Gummy Mask",
    ["Red"] = "Demon Mask",
    ["Blue"] = "Diamond Mask"
}
MaskF = SetupTFNor(MaskF,"MaskF")
local vu = game:GetService("VirtualUser")

plr.Idled:connect(
    function()
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
)
for i, v in pairs(workspace.FieldDecos:GetChildren()) do
    v:Destroy()
end
function GetFieldByName(name)
    return game.Workspace.FlowerZones:FindFirstChild(name)
end
function GetFieldId(name)
    return GetFieldByName(name).ID.Value
end


local maxx = 31
local maxy = 12

function GetFlower(field, x, y)
    local part = game.Workspace.Flowers:FindFirstChild(tostring(field) .. "-" .. tostring(x) .. "-" .. tostring(y))
    return part
end
function GetXY(part)
    local name = mysplit(part.name, "-")
    return unpack(name)
end
function Conv2LayerTable(tab)
    local tabl = {}
    for k, v in pairs(tab) do
        for f, s in pairs(v) do
            tabl[s] = k
        end
    end
    return tabl
end
local MaskField2 = Conv2LayerTable(MaskField)
local ValidTB={}
function ValidFarm()
    return CheckFarm("Farm")
end
for _, v in pairs(game.Workspace.Decorations.Misc:GetChildren()) do
    if string.match(v.Name, "Mushroom") or string.match(v.Name, "Blue Flower") then
        if v:IsA("Model") and #v:GetChildren() ~= 6 then
            for _, v in pairs(v:GetChildren()) do
                if v:IsA("Part") then
                    v.Transparency = 0.5
                    v.CanCollide = false
                end
            end
        end
    end
end
function GetFieldByFP(name) 
    local dit = name
    for k,v in pairs(GetListField()) do 
        local id = GetFieldId(v)
        if dit=="FP"..id then 
            return v
        end
    end
end
getgenv().IsValidTokenPos = function(token, Field,infield,sucvatruabithieunangvathanhtuoicungbithieunangvandokhongbithieunangttdbithieunangbrosabithieunangtvkkhongbithieunang)
    local pos
    if type(token) == "vector" then 
        pos = token
    else
        pos = token.Position
    end

    local kc = 60
    local Field = GetFieldByName(Field)
    if Field:FindFirstChild("Range") then kc=Field.Range.Value end
    local bool = false
    local Character = plr.Character
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    if not infield and Field.Name~="PuffField" then 
        local ray = Ray.new(pos+Vector3.new(0,5,0), Vector3.new(0, -1000, 0))

        local thieutvknang = workspace:FindPartOnRayWithWhitelist(ray, {game.Workspace.Flowers})
        if thieutvknang then 
            local curr,x,y = GetXY(thieutvknang)
            local CurrentField = GetFieldByFP(curr)
            if CurrentField == Field.Name then 
               return math.abs(pos.Y-thieutvknang.Position.Y) 
            end
        end
    else
        
        if (pos - Field.Position).magnitude < kc then
            if infield then 
                for k,v in pairs(infield.List) do
                    if (pos-v.p).magnitude>infield.Range then return false end
                end
            end
            return math.abs(pos.Y-Field.Position.Y) 
        end
    end
end
function IsValidCharactPos(Field)
    local bool = false
    local Character = plr.Character
    
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    if not IsValidTokenPos(Character.HumanoidRootPart,Field) then return false end
    local Field = GetFieldByName(Field)
    local kc = 100
    if Field:FindFirstChild("Range") then kc=Field.Range.Value end
    if (Field.Position - HumanoidRootPart.Position).magnitude < kc then
        bool = true
    end
    
    
    return bool
end

    getgenv().IsTokenBlacklist = function(token)
    if token:FindFirstChild("Blacklisted") then
        return true
    end
    return false
end

getgenv().IsToken = function(token)
    if token == nil then
        return false
    end
    if not token.Parent then return false end
    if token then
        if token.Orientation.Z ~= 0 then
            return false
        end
        if token:FindFirstChild("FrontDecal") then
        else
            return false
        end
        if not token.Name == "C" then
            return false
        end
        if not token:IsA("Part") then
            return false
        end
        return true
    else
        return false
    end
end
function CountSprink(name,pos) 
    local cc = 0
    for k,v in ipairs(game:GetService("Workspace").Gadgets:GetChildren()) do 
        if v.Name==name and v:FindFirstChild("Base") then 
            if (v.Base.Position-pos).magnitude<30 then 
                cc=cc+1
            end
        end
    end
    return cc
end
function CountTab(tab)
    local c = 0
    for k, v in pairs(tab) do
        c = c + 1
    end
    return c
end
function GetCurrentFieldBoost()
    local tab = {}
    for k,v in pairs(ListTileGrid) do 
        local GUI = v
        for _, v in pairs(GUI:GetChildren()) do
            if v.Name == "IconTile" and v:FindFirstChild("BG") then
                for f, s in pairs(FieldIconID) do
                    if
                        v.BG:FindFirstChild("Icon") and v.BG:FindFirstChild("Text") and v.BG:FindFirstChild("Bar") and
                            v.BG.Icon.Image == s and
                            v.BG.Bar.BackgroundColor3 == Color3.fromRGB(255, 228, 81)
                     then
                        tab[f] = v.BG.Text.Text
                    end
                end
            end
        end
    end
    
    return tab
end
function IsAnyBoost()
    local t = GetCurrentFieldBoost()
    for k, v in pairs(t) do
        return true
    end
    return false
end
function IsBoostEnd(Field)
    for k,v in pairs(ListTileGrid) do 
        local GUI = v
    for _, v in pairs(GUI:GetChildren()) do
        if v.Name == "IconTile" and v:FindFirstChild("BG") then
            for f, s in pairs(FieldIconID) do
                if
                    v.BG:FindFirstChild("Icon") and v.BG:FindFirstChild("Text") and v.BG:FindFirstChild("Bar") and
                        v.BG.Icon.Image == s and
                        v.BG.Bar.BackgroundColor3 == Color3.fromRGB(255, 228, 81)
                 then
                    if f == Field then
                        return false
                    end
                end
            end
        end
    end
    end
    
    return true
end

-- Get Mob Function

local AttackTokens = {
    "rbxassetid://1629547638",
    "rbxassetid://2319083910",
    "rbxassetid://1442700745",
    "rbxassetid://1629649299"
}
function CollectAttackTokens(x,all,IgnoreY)
    local sucvat =  plr.Character:WaitForChild("HumanoidRootPart").CFrame

    x = x or 50
    for k, v in pairs(game.workspace.Collectibles:GetChildren()) do
        local pass = true
        if not all then 
            if v:FindFirstChild("FrontDecal") then 
                pass = table.find(AttackTokens, v.FrontDecal.Texture) 
            end
        end
        if v.Name == "C"
        and not v:FindFirstChild("Ignored")
        and v:FindFirstChild("FrontDecal")
        and pass
        and (v.Position - plr.Character:WaitForChild("HumanoidRootPart").CFrame.Position).magnitude <= x then
            local tempVar
            if IgnoreY then 
                if (v.Position.Y - sucvat.Position.Y +3) > 0 then 
                    tempVar=true 
                end
            end
            if not tempVar then 
                plr.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(v.Position) + Vector3.new(0, 3, 0)
                task.wait(.2)
                local ractvk = Instance.new("IntValue", v)
                ractvk.Name = "Ignored"
            end
           
        end
    end
end

function CollectTokenThanhTuoi(Field,TokenList)
    local collected = false
    for k, v in pairs(game.workspace.Collectibles:GetChildren()) do
        local pass = false
        if v:FindFirstChild("FrontDecal") then 
            for k,v2 in pairs(TokenList) do 
                if string.match(v.FrontDecal.Texture,v2) then pass = true break end
            end
            --pass = table.find(TokenList, v.FrontDecal.Texture) 
        end
        if v.Name == "C"
        and not v:FindFirstChild("Ignored")
        and v:FindFirstChild("FrontDecal")
        and pass then
            if IsToken(v) and IsValidTokenPos(v,Field) and not v:FindFirstChild("Ignored") then 
                local tempVar
                if not tempVar then 
                    StopFarmList["Firefly"] = true
                    Walkk(v.CFrame)
                    local ractvk = Instance.new("IntValue", v)
                    ractvk.Name = "Ignored"
                    game.Debris:AddItem(ractvk,2)
                end
            end
        end
    end
    return collected
end

function GetTunnel()
    for _, v in ipairs(game.Workspace.Monsters:GetChildren()) do
        if string.match(v.Name, "Tunnel") then
            if v:FindFirstChild("Config") then
                if v:FindFirstChild("Hunter") then
                    if v.Hunter.Value == plr.UserId then
                        return v
                    end
                end
            end
        end
    end
end

function GetKing()
    for _, v in ipairs(game.Workspace.Monsters:GetChildren()) do
        if v.Name=="King Beetle (Lvl 7)" then
            if v:FindFirstChild("Config") then
                if v:FindFirstChild("Hunter") then
                    if v.Hunter.Value == plr.UserId then
                        return v
                    end
                end
            end
        end
    end
end

local ccsnail = false



function GetMobIns(Mob)
    return game.Workspace.MonsterSpawners:FindFirstChild(Mob)
end
function GetAttach(Mob)
    local Att = Mob:FindFirstChild("Attachment")
    if Att then
        return Att
    else
        return Mob:FindFirstChild("TimerAttachment")
    end
end

local MonsterTypeMD = require(game.ReplicatedStorage.MonsterTypes)

function CheckMob(Mob)
    if TimerMob[Mob]==nil then return end
    for k, v in pairs(TimerMob[Mob]) do
        local t = GetMobIns(v)
        if t then 
            local data = TvkStatCache.MonsterTimes
            local rac2 = data[v]
            if rac2 then 
                local Reduce = 0
                pcall(function() 
                    Reduce = TvkStatCache.ModifierCaches.Value.MonsterCooldownReduction._
                end)
                Reduce=1-Reduce
                local tempVar = os.time()-rac2
                local rac = MonsterTypeMD.Get(t.MonsterType.Value).Stats.RespawnCooldown
                if tempVar>rac*Reduce+(Settings.MobDelay or 30) then 
                    return {
                        Part = t,
                        Status = function()
                            local data = TvkStatCache.MonsterTimes
                            local rac2 = data[v]
                            local tempVar = os.time()-rac2
                            local rac = MonsterTypeMD.Get(t.MonsterType.Value).Stats.RespawnCooldown
                            return tempVar>rac*Reduce+(Settings.MobDelay or 30)
                        end
                    }
                end
            end
        end
    end
end
local a = require(game.ReplicatedStorage.Activatables.Toys)

local check1 = debug.getupvalue(a.ButtonEffect,1)
local check2 = debug.getupvalue(a.ButtonEffect,2)
function CheckToy(toy) 
    return warpF2(function() 
        return check1(a,toy) and check2(a,toy)   
    end)
end
function CheckCoco()
    local k = "CoconutCrab"
    local t = GetMobIns(k)
    if t then 
        if GetAttach(t).TimerGui.TimerLabel.Visible == false then
            return t
        end
    end
    
end
function CheckSnail()
    local k = "StumpSnail"
    local t = GetMobIns(k)
    if t then 
    if GetAttach(t).TimerGui.TimerLabel.Visible == false then
        return t
    end
end
end
function CheckTunnel()
    local k = "TunnelBear"
    local t = GetMobIns(k)
    if t then 
        if GetAttach(t).TimerGui.TimerLabel.Visible == false then
            return t
        end
    end
    
end
function reverse(t)
    local n = #t
    local i = 1
    while i < n do
      t[i],t[n] = t[n],t[i]
      i = i + 1
      n = n - 1
    end
    return t
  end
function CheckKing()
    local k = "King Beetle Cave"
    local t = GetMobIns(k)
    if t then 
        if GetAttach(t).TimerGui.TimerLabel.Visible == false then
            return t
        end
    end
    
end
function CheckComando()
    local k = "Commando Chick"
    local t = GetMobIns(k)
    if t then 
        if GetAttach(t).TimerGui.TimerLabel.Visible == false then
            return t
        end
    end
    
end

function GetCurrentAmountOfBee()
    local bee = 0
    for _, v in pairs(game.Workspace.Honeycombs:GetChildren()) do
        if tostring(v.Owner.Value) == plr.Name then
            for l, s in pairs(v.Cells:GetChildren()) do
                if s.CellType.Value ~= "Empty" and tostring(s.CellType.Value) ~= "nil" then
                    bee = bee + 1
                end
            end
        end
    end
    return bee
end
local sanghuman = require(game:GetService("ReplicatedStorage").BeeTypes).GetTypes()
function tuoidz(func) 
    task.spawn(function() 
        local Voiddz = 0
        local act6temp = 0
        local jimmy2 = game:GetService("ReplicatedStorage").Events.RetrieveCachedPlayerStat:InvokeServer("MaxBeeEnergy")
        local sangzboi = game:GetService("ReplicatedStorage").Events.RetrievePlayerStat:InvokeServer({"Honeycomb"})
        for k,v in pairs(sangzboi) do 
            for k,v in pairs(v) do 
                if v.Type and sanghuman[v.Type] then 
                    local act5 = 20
                    local thanhtuoi = sanghuman[v.Type].Bonuses
                    if thanhtuoi and thanhtuoi.MaxEnergy then 
                        for k,v in pairs(thanhtuoi.MaxEnergy) do 
                            if k=="Add" then act5=act5+v end
                            if k=="Mul" then act5=act5*v end
                        end
                    end
                    act5=act5*(1+0.05*(v.Lvl-1))
                    if jimmy2 then 
                        act5 = act5*jimmy2
                    end
                    if v.Mutas then 
                        if v.Mutas.Energy then 
                            act5 = act5*v.Mutas.Energy
                        end
                    end
                    if v.Energy==0 then v.Energy = act5 end
                    if v.Energy > 10^5 then v.Energy = act5 end
                    Voiddz=Voiddz+(v.Energy/act5)
                    act6temp = act6temp+1
                end
            end
        end
        func(Voiddz/act6temp)
    end)
end

function CountTabTF(tb) 
    local c = 0
    for k,v in pairs(tb) do 
    
    end
end
function SendHook()
    local HttpService = game:GetService("HttpService")
    local tb = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "Bee Swarm Simulator",
            ["description"] = "",
            ["type"] = "rich",
            ["color"] = tonumber(0xbdce44),
            ["fields"] = ListToField(),
            ["footer"] = {
                ["icon_url"] = "https://cdn.discordapp.com/attachments/832985237638086660/843786018892939284/turtle.png",
                ["text"] = "Sea Hub (" .. os.date("%X") .. ")"
            }
        }}
    }
    
    local a =
        request(
        {
            Url = Settings.WebHookUrl,
            Method = "POST",
            Body = HttpService:JSONEncode(tb),
            Headers = {
                ["Content-Type"] = "application/json"
            }
        }
    )
    return a.Body
end
function SendHookCT(ct,content)
    local HttpService = game:GetService("HttpService")
    local tb = {
        ["content"] = content or "",
        ["embeds"] = {{
            ["title"] = "Bee Swarm Simulator",
            ["description"] = "",
            ["type"] = "rich",
            ["color"] = tonumber(0xbdce44),
            ["fields"] = ct,
            ["footer"] = {
                ["icon_url"] = "https://cdn.discordapp.com/attachments/832985237638086660/843786018892939284/turtle.png",
                ["text"] = "Sea Hub (" .. os.date("%X") .. ")"
            }
        }}
    }
    
    local a =
        request(
        {
            Url = Settings.WebHookUrl,
            Method = "POST",
            Body = HttpService:JSONEncode(tb),
            Headers = {
                ["Content-Type"] = "application/json"
            }
        }
    )
    return a.Body
end
function SendHookContent(content)
    local HttpService = game:GetService("HttpService")
    local tb = {
        ["content"] = content or ""
    }
    
    local a =
        request(
        {
            Url = Settings.WebHookUrl,
            Method = "POST",
            Body = HttpService:JSONEncode(tb),
            Headers = {
                ["Content-Type"] = "application/json"
            }
        }
    )
    return a.Body
end
local NPCLV = {
    [0] = {
        "Black Bear",
        "Mother Bear",
        "Brown Bear",
        "Riley Bee",
        "Bucko Bee",
        "Bee Bear 4"
    },
    [5] = {
        "Panda Bear"
    },
    [10] = {
        "Science Bear"
    },
    [15] = {
        "Polar Bear",
        "Honey Bee"
    },
    [30] = {
        "Onett"
    },
    [35] = {
        "Spirit Bear"
    }
}
local FieldLV = {
    [0] = {
        "Mushroom Field",
        "Blue Flower Field",
        "Sunflower Field",
        "Dandelion Field",
        "Clover Field",
        "PuffField"
    },
    [5]={
        "Strawberry Field",
        "Bamboo Field",
        "Spider Field"
    },
    [10] = {
        "Pineapple Patch",
        "Stump Field"
    },
    [15] = {
        "Rose Field",
        "Pine Tree Forest",
        "Pumpkin Patch",
        "Cactus Field"
    },
    [25] = {
        "Mountain Top Field"
    },
    [35] = {
        "Coconut Field",
        "Pepper Patch"
    }
}
function RedBlueWhite(bee)
    local FieldColor = {
        ["Red"] = "Strawberry Field",
        ["Blue"] = "Pine Tree Forest",
        ["White"] = "Pineapple Patch"
    }
    if bee < 5 then
        FieldColor["Red"] = "Mushroom Field"
        FieldColor["Blue"] = "Blue Flower Field"
        FieldColor["White"] = "Sunflower Field"
    else
        if bee >= 5 and bee < 15 then
            FieldColor["Red"] = "Strawberry Field"
            FieldColor["Blue"] = "Bamboo Field"
            FieldColor["White"] = "Spider Field"
        else
            if bee >= 15 then
                FieldColor["Red"] = "Rose Field"
                FieldColor["Blue"] = "Pine Tree Forest"
                FieldColor["White"] = "Pumpkin Patch"
                if bee >= 35 then
                    if not CheckCoco() then
                        FieldColor["White"] = "Coconut Field"
                    end
                    FieldColor["Red"] = "Pepper Patch"
                end
            end
        end
    end
    return FieldColor
end
local col = {"Red", "Blue", "White"}
local FieldColor = {
    ["Red"] = "Strawberry Field",
    ["Blue"] = "Pine Tree Forest",
    ["White"] = "Pineapple Patch"
}
function CheckQuestReq(Field) 
    local curr = GetCurrentAmountOfBee()
    for k,v in pairs(NPCLV) do 
        if table.find(v,Field) then 
            return curr>=k
        end
    end
   return false
end
function CheckFieldReq(Field) 
    local curr = GetCurrentAmountOfBee()
    for k,v in pairs(FieldLV) do 
        if table.find(v,Field) then 
            return curr>=k
        end
    end
   return false
end
--local secure_call = syn.secure_call



function newsclosure(f) 
    return function()
        local ret
        secure_call(function() 
            ret=f()
         end,game:GetService("Players").LocalPlayer.PlayerScripts.Listeners)
         return ret
    end
end

function GetQuestListMD()
    local v1 = require(game.ReplicatedStorage.Quests)

    local v5 = require(game.ReplicatedStorage.NPCs)
    local ListQuest = {}
    warpF2(function() 
        local v91 = TvkStatCache
        for v96, v97 in pairs(v91.Quests.Active) do
            local l__Name__98 = v97.Name
            local v99 = v1:Get(l__Name__98)
            
            if
                v99.NPC and v99.Theme ~= "Xmas" and not v99.Hidden and
                    (not v99.Expiration or require(game.ReplicatedStorage.OsTime)() < v99.Expiration)
             then
                local v101 = v1:Progress(l__Name__98, v91)
                local v102 = true
                local ListTask = {}
                for v103, v104 in ipairs(v99.Tasks) do
                    local v58 = v104.Description
                    if type(v58) ~= "string" then
                        v58 = v58(TvkStatCache)
                    end
                    local Task = {
                        Description = v58,
                        IsCompleted = function()
                            return warpF2(function() 
                                local v102 = true
                                local v91 = TvkStatCache
                                local v101 = v1:Progress(l__Name__98, v91)
                                if v101 and v101[v103] and v101[v103][1] < 1 then
                                    return false
                                end
                                return true
                            end)
                        end,
                        Type = v104.Type,
                        Zone = v104.Zone,
                        Item = v104.Item,
                        MonsterType = v104.MonsterType,
                        Tag = v104.Tag,
                        Color = v104.Color,
                        Toy = v104.Toy,
                        Name = v99.Name
                    }
                    table.insert(ListTask, Task)
                end
                ListQuest[v99.NPC] = ListTask
            end
        end
    end)
    return ListQuest
end

function GetQuestNPC(npc)
    local ListQuest = GetQuestListMD()
    for k, v in pairs(ListQuest) do
        if k == npc then
            return v
        end
    end
end

function GetQuestName(npc) 
    local ListQuest = GetQuestNPC(npc)
    if ListQuest then 
        for k,v in pairs(ListQuest) do 
            if v.Name then 
                return v.Name
            end
        end
    end
end

function GetQuestType(quest)
    local type = ""
    if quest.Type == "Collect Pollen" then
        if quest.Zone then
            type = "Zone"
        elseif quest.Color then
            type = "Color"
        else
            tpye = "Pollen"
        end
    elseif quest.Type == "Defeat Monsters" then
        type = "Kill"
    elseif quest.Type == "Use Items" then
        type = "Use"
    elseif quest.Type == "Use Toy" then
        type = "Toy"
    elseif quest.Type == "Collect Tokens" then
        type = "Token"
    elseif quest.Type == "Collect Goo" then
        if quest.Zone then
            type = "Zone"
        elseif quest.Tag then
            type = "Color"
        else
            type = "Goo"
        end
    end
    return type
end

function GetQuestTable(quest)
    local questtb = {}
    for k, v in pairs(quest) do
        local type = GetQuestType(v)
        if not questtb[type] then
            questtb[type] = {}
        end
        table.insert(questtb[type], v)
    end
    return questtb
end

function GetAntQuest(QuestTF)
    for k, v in pairs(QuestTF) do
        if v then
            local QuestNPC = GetQuestNPC(k)
            if QuestNPC then
                local QuestTb = GetQuestTable(QuestNPC)
                if QuestTb["Kill"] then
                    for k, v in pairs(QuestTb["Kill"]) do
                        if not v.IsCompleted() then
                            if v.MonsterType then
                                if string.match(v.MonsterType, "Ant") then
                                    return v
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function IsTestRealmMegaBoost() 
    local ListTileGrid = {}
    for k,v in pairs(plr.PlayerGui.ScreenGui:GetChildren()) do 
        if v.Name=="TileGrid" then 
            table.insert(ListTileGrid,v)
        end
    end
    local mg = "rbxassetid://2659216738"
    for k,v in pairs(ListTileGrid) do 
        local PlGui = v
        for _,v in pairs(PlGui:GetChildren()) do 
            if v:FindFirstChild("BG") then 
                  if v.BG:FindFirstChild("Icon") then 
                        if string.match(v.BG.Icon.Image,mg) then return true end
                  end
            end
        end
    end
    return false
end

local PopStarAura = "5101328809"
function IsPopStar()
    for k,v in pairs(ListTileGrid) do 
        local PlGui = v
        for _,v in pairs(PlGui:GetChildren()) do 
            if v:FindFirstChild("BG") then 
                  if v.BG:FindFirstChild("Icon") then 
                        if string.match(v.BG.Icon.Image,PopStarAura) then return true end
                  end
            end
      
      end
    end
    
    return false
end
function IsScrochStarEquip()
    local tempVar = "5101327864"
    for k,v in pairs(ListTileGrid) do 
        local PlGui = v
        for _,v in pairs(PlGui:GetChildren()) do 
            if v:FindFirstChild("BG") then 
                  if v.BG:FindFirstChild("Icon") and not string.match(v.BG.Text.Text,"s") then 
                        if string.match(v.BG.Icon.Image,tempVar) then return true end
                  end
            end
        end
    end
    
    return false
end
function IsScrochStar() 
    local tempVar = "5101329167"
    for k,v in pairs(ListTileGrid) do 
        local PlGui = v
        for _,v in pairs(PlGui:GetChildren()) do 
            if v:FindFirstChild("BG") then 
                  if v.BG:FindFirstChild("Icon")  then 
                        if string.match(v.BG.Icon.Image,tempVar) then return true end
                  end
            end
        end
    end
    
    return false
end

function IsPrecise() 
    local tempVar = "rbxassetid://8172818074"
    for k,v in pairs(ListTileGrid) do 
        local PlGui = v
        for _,v in pairs(PlGui:GetChildren()) do 
            if v:FindFirstChild("BG") then 
                  if v.BG:FindFirstChild("Icon") then 
                        if string.match(v.BG.Icon.Image,tempVar) then return {Text = v.BG.Text.Text, Percent = v.BG.Bar.Size.Y.Scale} end
                  end
            end
        end
    end
    return false
end
function NearestCross(a) 
    local Gan
    local GanNhat
    for k,v in pairs(a) do 
        if #v == 3 then 
            local Nearest
            local c = 0

            local c2 = 0
            for k,v in pairs(v) do
                if not v.Part.Parent then 
                    c2=c2+1
                end 
                if not Nearest then Nearest = v end
                if v.Activated then c = c+1 end
                if (plr.Character.HumanoidRootPart.Position-v.Part.Position).magnitude < (plr.Character.HumanoidRootPart.Position-Nearest.Part.Position).magnitude then 
                    Nearest = v
                end
            end
            if c==3 then Nearest = nil end
            if c2== 3 then 
                Nearest = nil
            end
            if Nearest then 
                if not Gan then Gan = Nearest GanNhat = v end
                if (plr.Character.HumanoidRootPart.Position-Nearest.Part.Position).magnitude < (plr.Character.HumanoidRootPart.Position-Gan.Part.Position).magnitude then 
                    Gan = Nearest
                    GanNhat = v
                end
            end
        end
        
    end
    if GanNhat then return GanNhat end
end

local nll = require(game:GetService("ReplicatedStorage").BlenderRecipes)
local HttpService = game:GetService("HttpService")
function GetItemListWithValue()
    local StatCache = TvkStatCache
    local data = StatCache
    return data.Eggs
end
function CheckNguyenLieu(ng)
    local ind = nll.Get(ng)
    local k = false
    for k, v in pairs(ind.Ingredients) do
        local t = GetItemListWithValue()
        if t[v.Type] and (t[v.Type] >= v.Amount) then
        else
            k = true
            break
        end
    end
    if not k then
        return true
    else
        return false
    end
end


local cls = require(game.ReplicatedStorage.ClientStatCache)
local StatCache = require(game.ReplicatedStorage.ClientStatCache)
local ostime=require(game.ReplicatedStorage.OsTime)

local oldhoney = StatCache.Get().Totals.Honey
getgenv().HoneyMade = 0
task.spawn(function()
    while task.wait(4) do
        getgenv().HoneyMade = StatCache.Get().Totals.Honey - oldhoney
    end
end)

function GetCraftingStatus() 
local data = game:GetService("ReplicatedStorage").Events.RetrievePlayerStats:InvokeServer()
local blender = data.BlenderState

if not blender then return 0 end
local n = blender.Count
local Start = blender.StartTime

local v32 = data.PlaytimeAtLoad;
local v33 = data.LoadTime;
local v29 = blender

local v34 = v32 + (ostime() - v33) - v29.StartTime;
local f = (60*n*5-v34)/60
if f<=0 then return 1,blender end
return 2,blender
end
function FireTouch(part) 
    if plr.Character:FindFirstChild("HumanoidRootPart") then 
        firetouchinterest(plr.Character:WaitForChild("HumanoidRootPart"), part, 0)
        firetouchinterest(plr.Character:WaitForChild("HumanoidRootPart"), part, 1)    
    end
end
function God()
    Instance.new("BoolValue",plr.Character).Name="Godded"
    local cam = workspace.CurrentCamera
    local cf = cam.CFrame
    local me = plr
    local c, h =
        (me.Character or workspace:FindFirstChild(me.Name)),
        me.Character:FindFirstChildOfClass("Humanoid")
    local nh = h:Clone()
    nh.Health = nh.MaxHealth
    me.Character = nil
    nh:SetStateEnabled(15, false)
    nh:SetStateEnabled(1, false)
    nh:SetStateEnabled(0, false)
    nh.Parent = c
    h:Destroy()
    me.Character, cam.CameraSubject = c, nh
    task.wait()
    cam.CFrame = cf
    local s = c:FindFirstChild("Animate")
    if s then
        s.Disabled = true
        task.wait()
        s.Disabled = false
    end
    delay(
        1,
        function()
            if nh then
                nh.Health = 256
            end
        end
    )
    for i=1,10 do 
        FireTouch(game:GetService("Workspace").Map.Ground.Campsite.Lava)
    end
end
function GetItemListWithValue()
    local HttpService = game:GetService("HttpService")
    local StatCache = TvkStatCache
    local data = StatCache
    return data.Eggs
end
function GetItemList()
    local ks = GetItemListWithValue()
    local tb = {}
    for k, v in pairs(ks) do
        table.insert(tb, k)
    end
    return tb
end
function IsInstantValid(Instant)
    local replicatedstorage = game:GetService("ReplicatedStorage")
    local rep = replicatedstorage
    local r = require
    local player = plr

    local function getTimeSinceToyActivation(name)
        return r(rep.OsTime)() - r(rep.ClientStatCache):Get("ToyTimes")[name]
    end

    local function getTimeUntilToyAvailable(n)
        return workspace.Toys[n].Cooldown.Value - getTimeSinceToyActivation(n)
    end
    local StatCache = require(game.ReplicatedStorage.ClientStatCache)
    local gt = StatCache.Get()
    local toy = gt["ToyTimes"]
    if toy[Instant] then
        return getTimeUntilToyAvailable(Instant) <= 0
    else
        return false
    end
end

function UseInstant(Instant)
    game.ReplicatedStorage.Events.ToyEvent:FireServer(Instant)
end

function IsAnyInstantValid()
    local Lis = GetInstantList()
    for k, v in pairs(Lis) do
        if IsInstantValid(v.Name) then
            return true
        end
    end
    return false
end
function UnGod()
    if not plr.Character:FindFirstChild("Godded") then return end
    local cam = workspace.CurrentCamera
    local cf = cam.CFrame
    local me = plr
    local c, h =
        (me.Character or workspace:FindFirstChild(me.Name)),
        me.Character:FindFirstChildOfClass("Humanoid")
    local nh = h:Clone()
    nh.Health = nh.MaxHealth
    me.Character = nil
    nh:SetStateEnabled(15, true)
    nh:SetStateEnabled(1, true)
    nh:SetStateEnabled(0, true)
    nh.Parent = c
    h:Destroy()
    me.Character, cam.CameraSubject = c, nh
    task.wait()
    cam.CFrame = cf
    local s = c:FindFirstChild("Animate")
    if s then
        s.Disabled = false
        task.wait()
        s.Disabled = true
    end
    delay(
        1,
        function()
            if nh then
                nh.Health = 0
            end
        end
    )
end
function GetEquipSrinkler()
    local StatCache = require(game.ReplicatedStorage.ClientStatCache)
    return StatCache["Get"]()["EquippedSprinkler"]
end


loadstring([[
    function GetFieldByText(text) 
        for k,v in pairs(GetListField()) do 
            if string.match(text,v) then return v end
        end
    end
    function GetNerestFieldByObject(Obj)
        local lis = GetListField()
        local old = "Sunflower Field"
        for k, v in pairs(lis) do
            if v and v~="PuffField" then
                if
                    (Obj.Position - GetFieldByName(v).Position).magnitude <
                        (Obj.Position - GetFieldByName(old).Position).magnitude
                 then
                    old = v
                end
            end
        end
        return old
    end

]])()
function GetCurrentField() 
    if not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    return GetNerestFieldByObject(plr.Character.HumanoidRootPart)
end


local ValidPos = {}

local Whitelist = {}

local ksf = nil




local HoneyTokenId="1472135114"




-- TVK LIB

    function GetTokenNearPos(pos,field,mag) 
        local FieldTokens = ListAllToken[field]
        if not FieldTokens then return end
        for k, ss in pairs(FieldTokens) do
            for k,v in ipairs(ss) do 
                if getgenv().IsToken(v) and getgenv().IsValidTokenPos(v, field,FieldPosIn,(Whitelist and #Whitelist>0)) and getgenv().isActiveTokens(v) and not getgenv().IsTokenBlacklist(v) then
                    local vthang = false 
                    if Whitelist and #Whitelist>0 then 
                        for k,v2 in pairs(Whitelist) do 
                            if string.find(v.FrontDecal.Texture,v2) then 
                                vthang = true
                            end
                        end
                    else
                        vthang = true
                    end
                    if vthang then 
                        if kc(v.Position) < mag then return v,true end
                    end
                end
            end
        end
    end
    function IsAnyPiro(Field,t,ListAllToken,FieldPosIn,Whitelist) 
        if not ListAllToken[Field] then return false end

        if Settings.GatherFlame then 
            local rac = GetListFire(Field)
            for k,v in pairs(rac) do 
                local nr = GetTokenNearPos(v.Position,Field,30)
                if nr then return true end
            end
        end
        for k,v in pairs(ListAllToken[Field]) do 
            if k~="None" then 
                for k,v  in pairs(v) do 
                    if getgenv().IsToken(v) and getgenv().IsValidTokenPos(v, Field,FieldPosIn,(Whitelist and #Whitelist>0)) and getgenv().isActiveTokens(v) and not getgenv().IsTokenBlacklist(v) then 
                        return true
                    end
                end
            end
        end
        return false
    end
    function GetNerestToken(Field,t,ListAllToken,FieldPosIn,Whitelist)
        local token
        local Character = plr.Character
        local HumanoidRootPart = t or Character:FindFirstChild("HumanoidRootPart")
        if not HumanoidRootPart then return end
        local h = HumanoidRootPart.Position
        local Piro = {}

        -- Mat cuoi dupe nha cmm
        if Settings.CollectDupe then 
            for k, v in pairs(game:GetService("Workspace").Camera.DupedTokens:GetChildren()) do
                if IsToken(v) and getgenv().IsValidTokenPos(v,Field) and not IsTokenBlacklist(v) then
                    if string.match(v.FrontDecal.Texture,"5877939956") then return v,true end
                end
            end
            for k, v in pairs(game:GetService("Workspace").Camera.DupedTokens:GetChildren()) do
                if IsToken(v) and getgenv().IsValidTokenPos(v,Field) and not IsTokenBlacklist(v) then
                    local BearMorphs = {"1472425802","1472580249","1472532912","1472491940"}
                    for k, v2 in pairs(BearMorphs) do 
                        if string.match(v.FrontDecal.Texture,v2) then return v,true end
                    end
                end
            end
            
        end
        
        local function SucVat(ListAllToken) 
            if not ListAllToken or not ListAllToken[Field] then return end

            local FieldTokens = ListAllToken[Field]
            for k, ss in pairs(FieldTokens) do
                if k~="None" then 
                    local tok
                    local ditme = k
                    for k,v in ipairs(ss) do 
                        if getgenv().IsToken(v) and getgenv().IsValidTokenPos(v, Field,FieldPosIn,(Whitelist and #Whitelist>0)) and getgenv().isActiveTokens(v) and not getgenv().IsTokenBlacklist(v) then
                            if ditme == "Token Link" then 
                                return v,true
                            end
                            local huhu = false 
                            if Whitelist and #Whitelist>0 then 
                                for k,v2 in pairs(Whitelist) do 
                                    if string.find(v.FrontDecal.Texture,v2) then 
                                        huhu = true
                                    end
                                end
                            else
                                huhu = true
                            end
                            if huhu then 
                                if (v.Position-h).magnitude < 3 then return v,true end
                                if not tok then tok=v end
                                if (v.Position-h).magnitude < (tok.Position-h).magnitude then 
                                    tok=v
                                end
                            end
                        end
                    end
                    if tok then 
                        Piro[tok]=(tok.Position-h).magnitude
                    end
                end
            end
            local sml
            for k,v in pairs(Piro) do 
                if not sml then sml=k end
                if v<Piro[sml] then sml=k end
            end
            if sml then return sml end
        end

        local tok

        local sucvat = SucVat(ListAllToken)
        if sucvat then return sucvat,true end

        if Settings.CollectDupe then 
            local ruabithieunang = SucVat(ListAllDupedToken)
            if ruabithieunang then return ruabithieunang,true end
        end
        if Settings.GatherFlame then 
            local rac = GetSortedFire(Field)
            for k,v in pairs(rac) do 
                local nr = GetTokenNearPos(v.Position,Field,30)
                if nr then  return nr,true end
            end
        end
        
        -- Piro token
        if ListAllToken[Field] then 
            --Normal token
            if ListAllToken[Field].None then 
                for _,v in ipairs(ListAllToken[Field].None) do 
                    if getgenv().IsToken(v) and getgenv().IsValidTokenPos(v, Field,FieldPosIn,(Whitelist and #Whitelist>0)) and getgenv().isActiveTokens(v) and not getgenv().IsTokenBlacklist(v) then 
                        local huhu = false 
                        if Whitelist and #Whitelist>0 then 
                            for k,v2 in pairs(Whitelist) do 
                                if string.find(v.FrontDecal.Texture,v2) then 
                                    huhu = true
                                end
                            end
                        else
                            huhu = true
                        end
                        if huhu then 
                            if not tok then tok=v end
                            if (v.Position-h).magnitude < (tok.Position-h).magnitude then 
                                tok=v
                            end
                        end 
                    end
                end
            end
            if tok then return tok end
        end
        if Settings.CollectDupe then 
            return GetNearestDupe(Field)
        end
    end


function NoFire(token) 
    local ray = Ray.new(token.Position+Vector3.new(0,1,0), Vector3.new(0, -5, 0))
    local t = workspace:FindPartOnRayWithIgnoreList(ray, {token,game.Workspace.Bees,plr.Character})
    if t and t:FindFirstChild("FireParticles") then 
        return false
    end

end
function CheckPollenValid(pollen) 
    local name,x,y=GetXY(pollen)
    if not name or not x or not y then return end
    x=tonumber(x)
    y=tonumber(y)
    local token = pollen
    
    if token then 
        if not NoFire(token) then return false end
    end

    local token = GetFlower(name,x,y+1)
    if token then 
        if not NoFire(token) then return false end
    end
    

    local token = GetFlower(name,x,y-1)

    if token then 
        if not NoFire(token) then return false end
    end

    local token = GetFlower(name,x+1,y)

    if token then 
        if not NoFire(token) then return false end
    end

    local token = GetFlower(name,x-1,y)

    if token then 
        if not NoFire(token) then return false end
    end
    return true
end
function GetComandoMob()
    for k, v in pairs(game.Workspace.Monsters:GetChildren()) do
        if string.match(v.Name, "Commando") then
            if v:FindFirstChild("Target")
            and v:FindFirstChild("Humanoid")
            and v:FindFirstChild("HumanoidRootPart") then
                if tostring(v.Target.Value) == plr.Name then
                    return v
                end
            end
        end
    end
end
local Temp = {
    Noclip = {}
}
function CheckEN(str)
    local tempVar = Temp[str]
    for k, v in pairs(tempVar) do
        if v then
            return true
        end
    end
    return false
end
function SetEN(str, tempVar, rac)
    Temp[str][tempVar] = rac
end
--setfflag("HumanoidParallelRemoveNoPhysics", "False")
--setfflag("HumanoidParallelRemoveNoPhysicsNoSimulate2", "False")
game:GetService('RunService').Stepped:Connect(function()
    -- if CheckEN("Noclip") then plr.Character.Humanoid:ChangeState(11)
    -- end
end)
function kc(a,huhu)
    local nang = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
    if huhu then 
        a = Vector3.new(a.X,0,a.Z)
        nang = Vector3.new(nang.X,0,nang.Z)
    end 
    return (nang-a).magnitude
end
local Last
function tpT(t, k, dieukien, disableinstanttp,instanttp)
    
    if true then 
        pcall(function() 
            task.wait()
            plr.Character.HumanoidRootPart.CFrame=t
        end)
        return
    end
    if Last then Last() Last=nil end
    if not plr.Character:FindFirstChild("HumanoidRootPart")  or not plr.Character:FindFirstChild("UpperTorso") then return end
    if instanttp then 
        plr.Character.HumanoidRootPart.CFrame=t
        return
    end
    if kc(t.p) > 2000 then 
        plr.Character.HumanoidRootPart.CFrame=t
        return
    end
    if plr.Character:FindFirstChild("HumanoidRootPart") and not disableinstanttp
    and (plr.Character.HumanoidRootPart.Position-t.p).magnitude < 80 then 
        plr.Character.HumanoidRootPart.CFrame=t
    else
        if not k then
            k = 100
        end
        local tween_s = game:service "TweenService"
        local info =
            TweenInfo.new(
            (plr.Character:WaitForChild("HumanoidRootPart").Position - t.p).magnitude / k,
            Enum.EasingStyle.Linear
        )
        local breakdk = false
        local tic_k = tick()
        local cframe
        if plr.Character.UpperTorso:FindFirstChild(rnd) then 
            cframe= CFrame.lookAt(t.Position, plr.Character.UpperTorso[rnd].CFrame.lookVector)
        else
            cframe = CFrame.lookAt(t.Position, plr.Character.HumanoidRootPart.CFrame.lookVector)
        end
        local tween, err =
            pcall(
            function()
                local tween =
                    tween_s:Create(plr.Character:WaitForChild("HumanoidRootPart"), info, {CFrame = cframe})
                local done = false
                local Stop = function() done=true end
                Last=Stop
                tween.Completed:Connect(
                    function()
                        done = true
                    end
                )
                SetEN("Noclip", "Tween", true)
                tween:Play()
                while not done do
                    if not plr.Character:FindFirstChild("HumanoidRootPart") then return end
                    SetEN("Noclip", "Tween", true)
                    if (plr.Character.HumanoidRootPart.Position - Vector3.new(30.017883300781, 68.458869934082, -146.99607849121)).magnitude <= 130
                    and plr.Character.HumanoidRootPart.Position.Y >= 60
                    and plr.Character.HumanoidRootPart.Position.Y < 80 then 
                        tween:Cancel()
                        done=true
                        plr.Character.HumanoidRootPart.CFrame = t
                        break
                    end
                    if  ((plr.Character.HumanoidRootPart.Position-t.p).magnitude < 80 or instanttp) and not disableinstanttp then 
                        tween:Cancel()
                        done=true
                        plr.Character.HumanoidRootPart.CFrame = t
                        break
                    end
                    if dieukien and type(dieukien)=="function" then 
                        if not dieukien() then 
                            tween:Cancel()
                            done=true
                            breakdk=true
                            break;
                        end
                    end
                    task.wait()
                end
                tween:Cancel()
                SetEN("Noclip", "Tween", false)
            end
        )
        SetEN("Noclip", "Tween", false)
        return breakdk;
    end
end

if not getgenv().DisableClaimHive then 
    while not GetPlrHive() do 
        for _, v in pairs(reverse(game.Workspace.Honeycombs:GetChildren())) do
            if tostring(v.Owner.Value) == "nil" then
                tpT(v.LightHolder.CFrame)
                task.wait(1)
                game.ReplicatedStorage.Events.ClaimHive:FireServer(v.HiveID.Value)
                break;
            end
        end
    end
end
getfenv().Settings=Settings
function Walkk(t, token,dieukien,spamwalk)
    local Character = plr.Character
    local Humanoid = Character:WaitForChild("Humanoid")
    local stop = false
    Character:WaitForChild("Humanoid"):MoveTo(t.p)
    local vohoangnang = Character:WaitForChild("Humanoid").MoveToFinished:Connect(
        function()
            stop = true
        end
    )
    local a = tick()
    while (stop == false) do
        if Call then
            Call()
        end
        task.wait()
        if spamwalk then 
            Character:WaitForChild("Humanoid"):MoveTo(t.p)
        end
        if (token and not getgenv().IsToken(token)) then
            Character:WaitForChild("Humanoid"):Move(Vector3.new(0, 0, 0))
            stop=true
            vohoangnang:Disconnect()
            return
        end
        if dieukien and not dieukien() then 
            Character:WaitForChild("Humanoid"):Move(Vector3.new(0, 0, 0))
            stop=true
            vohoangnang:Disconnect()
            return
        end
        if tick() - a >= 5  then
            Character:WaitForChild("Humanoid"):Move(Vector3.new(0, 0, 0))
            plr.Character:WaitForChild("HumanoidRootPart").CFrame = t
            stop = true
        end
    end
    vohoangnang:Disconnect()
end
function WalkPathFind(destination,limittime,CallWhenWalk) 
    --print("Walked Path Find")
    if kc(destination.p,true)<7 then return end
    local PathfindingService = game:GetService("PathfindingService")
    local Players = game:GetService("Players")

    local RunService = game:GetService("RunService")
    
    local path = PathfindingService:CreatePath()
    
    local player = Players.LocalPlayer
    local character = player.Character
    local humanoid = character:WaitForChild("Humanoid")
    
    local TEST_DESTINATION = Vector3.new(100, 0, 100)
    
    local waypoints
    local nextWaypointIndex
    local reachedConnection
    local blockedConnection
    
    local stopeed = false
    local called = false
    local function followPath(destination)
        if stopeed then return end
        -- Compute the path
        local success, errorMessage = pcall(function()
            path:ComputeAsync(character.PrimaryPart.Position, destination.p)
        end)
        
        if success and path.Status == Enum.PathStatus.Success and not stopeed then
            -- Get the path waypoints
            waypoints = path:GetWaypoints()
            -- Detect if path becomes blocked
            blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
                -- Check if the obstacle is further down the path
                if blockedWaypointIndex >= nextWaypointIndex then
                    -- Stop detecting path blockage until path is re-computed
                    blockedConnection:Disconnect()
                    -- Call function to re-compute new path
                    if not stopeed then 
                        followPath(destination)
                    end
                end
            end)
    
            -- Detect when movement to next waypoint is complete
            if not reachedConnection then
                reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
                    if nextWaypointIndex and reached and nextWaypointIndex < #waypoints and not stopeed then
                        -- Increase waypoint index and move to next waypoint
                        nextWaypointIndex = nextWaypointIndex+1
                        local oldwaypoint = nextWaypointIndex
                        -- if CallWhenWalk then 
                        --     CallWhenWalk()
                        -- end
                        local c = tick()
                        while oldwaypoint == nextWaypointIndex and nextWaypointIndex < #waypoints and tick()-c < 10 and not stopeed do
                            humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
                            task.wait(1)
                        end
                    else
                        stopeed = true
                        reachedConnection:Disconnect()
                        blockedConnection:Disconnect()
                    end
                end)
            end
    
            -- Initially move to second waypoint (first waypoint is path start; skip it)

            nextWaypointIndex = 2
            if CallWhenWalk and not stopeed and not called then 
                CallWhenWalk()
                called = true
            end
            humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
        else
            warn("Path not computed!", errorMessage)
        end
    end
    followPath(destination)
    if waypoints then 
        if not limittime then limittime = math.huge end
        local VoHoangNang = tick()
        repeat task.wait() until nextWaypointIndex>=#waypoints or tick() - VoHoangNang > limittime or stopeed or kc(destination.p,true)<3
        if reachedConnection then reachedConnection:Disconnect()
            end
            if blockedConnection then blockedConnection:Disconnect() end
    end
    stopeed = true
end
function WalkPathFind2(destination,sucvatruabithieunang,CallWhenWalk) 
    print("Walked Path Find")
    local PathfindingService = game:GetService("PathfindingService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    
    local path = PathfindingService:CreatePath()
    
    local player = Players.LocalPlayer
    local character = player.Character
    local humanoid = character:WaitForChild("Humanoid")
    
    local TEST_DESTINATION = Vector3.new(100, 0, 100)
    
    local waypoints
    local nextWaypointIndex
    local reachedConnection
    local blockedConnection
   
    local function followPath(destination)
        -- Compute the path
        local success, errorMessage = pcall(function()
            path:ComputeAsync(character.PrimaryPart.Position, destination.p)
        end)
    
        if success and path.Status == Enum.PathStatus.Success then
            -- Get the path waypoints
            waypoints = path:GetWaypoints()
    
            -- Detect if path becomes blocked
            for k,v in pairs(waypoints) do
                if CallWhenWalk then 
                    CallWhenWalk()
                end
                Walkk(CFrame.new(v.Position),nil,nil,true) end
        else
            warn("Path not computed!", errorMessage)
        end
    end
    followPath(destination)
   -- repeat task.wait() until nextWaypointIndex>=#waypoints
end
function TpToHive()
    pcall(function() 
        local sp = plr.SpawnPos.Value.p
        local p = CFrame.new(sp.X, sp.Y, sp.Z, -0.996, 0, 0.02, 0, 1, 0, -0.02, 0, -0.9) + Vector3.new(0, 0, 8)
        Going = true
        tpT(p, 100)
        Going = false
    end)
end
function TpToField(Field,dk)
    local p = GetFieldByName(Field).CFrame * CFrame.new(0, 0, 0) + Vector3.new(0, 8, 0)
    return tpT(p, 100,dk)
end
function IsBackPackFull(a)
    if Settings.BaloonMethod ~= "Convert on sell" then 
        if GetHiveBallon(Settings.ConvertAtB or 0) then 
            return true
        end
    end
    
    local bool = false
    local Player = plr
    local Character = Player.Character
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    if not a then a = 100 end
    if Player.CoreStats.Pollen.Value >= (Player.CoreStats.Capacity.Value*a)/100 then
        bool = true
    end
    return bool
end
local choithuoc = tick()

function Dig()
    pcall(
        function()
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ToolCollect"):FireServer()
            task.wait(.2)
            -- local s, e =
            --     pcall(
            --     function()
            --         if tool and getsenv and not is_sirhurt_closure and not PROTOSMASHER_LOADED then -- Sirhurt and proto argggg
            --             local t = getsenv(tool.ClientScriptMouse).collectStart
            --             t()

            --         else
            --             if tool then
            --                 tool.ClickEvent:FireServer()
            --             end
            --         end
            --     end
            -- )
            -- if e then
            --     pcall(
            --         function()
            --             if tool then
            --             tool.ClickEvent:FireServer()
            --             end
            --         end
            --     )
            -- end
        end
    )
    -- pcall(
    --     function()
    --         if tick()-choithuoc<0.2 then 
    --             workspace.NPCs.Onett.Onett["Porcelain Dipper"].ClickEvent:FireServer()
    --             choithuoc=tick()
    --         end            
    --         --DigOther()
    --     end
    -- )
end

loadstring([[
    function IsSprout()
        local Particles = game.Workspace.Particles
        local Folder2 = Particles.Folder2
        for k, v in pairs(Folder2:GetChildren()) do
            if v.Name == "Sprout" then
                return v
            end
        end
        return nil
    end
]])()

function GetNearestFirefly() 
    local gancmnnhat
    for k,v in pairs(game.Workspace.NPCBees:GetChildren()) do 
        if v.Name == "Firefly" then 
            if v:FindFirstChild("BodyVelocity") and v.BodyVelocity.Velocity == Vector3.new(0,0,0) then 
                local tuoidz = GetNerestFieldByObject(v)
                if tuoidz then 
                    local sanghuman = IsValidTokenPos(v,tuoidz)
                    if sanghuman then 
                        if sanghuman < 4 then 
                            if not gancmnnhat then 
                                gancmnnhat = v
                            end
                            if (plr.Character.HumanoidRootPart.Position-v.Position).magnitude < (plr.Character.HumanoidRootPart.Position-gancmnnhat.Position).magnitude then 
                                gancmnnhat = v
                            end
                        end
                    end
                end
            end
        end
    end
    return gancmnnhat
end

function GetCurrenItem(Item)
    local StatCache = TvkStatCache
    local a = StatCache["Eggs"][Item]
    if a then return a else return 0 end
end
function GetCurrenMicro()
    local StatCache = TvkStatCache
    return StatCache["Eggs"]["Micro-Converter"]
end

function IsBuffOn(Buff)
    for k,v in pairs(ListTileGrid) do 
        local PlGui = v
        for k, v in pairs(PlGui:GetChildren()) do
            if v:FindFirstChild("BG") then
                if v.BG:FindFirstChild("Icon") then
                    if string.match(v.BG.Icon.Image, BarId[Buff]) then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end
function GetMemoList()
    local tab = {}
    for k, v in pairs(game.Workspace.Toys:GetChildren()) do
        if string.match(v.Name, "Memory Match") then
            table.insert(tab, v)
        end
    end
    return tab
end

function GetInstantList()
    local tab = {}
    for k, v in pairs(game.Workspace.Toys:GetChildren()) do
        if string.match(v.Name, "Instant Converter") then
            table.insert(tab, v)
        end
    end
    return tab
end
function ObjListTostring(tabl)
    local Tab = {}
    for k, v in pairs(tabl) do
        table.insert(Tab, v.Name)
    end
    return Tab
end
local TFItemHook = ListToOb(GetItemList())

if not Settings.TFItemHook then Settings.TFItemHook=TFItemHook else TFItemHook=Settings.TFItemHook end
function ListToField()
    local ListAll = GetItemListWithValue()
    local fields = {}

    if Settings.WHShowHoney then
        table.insert(
            fields,
            {
                name = "Stats",
                value = "Honey: " .. tostring(formatNumber(plr.CoreStats.Honey.Value))
                .. "\nHoney Made: " .. formatNumber(getgenv().HoneyMade),
                inline = false
            }
        )
    end
    local ItemsValue = ""
    for k, v in pairs(TFItemHook) do
        if v then
            ItemsValue = ItemsValue .. k .. ": " .. tostring(ListAll[k]) .. "\n"
        end
    end
    if ItemsValue~="" then 
        table.insert(
            fields,
            {
                name = "Items",
                value = ItemsValue,
                inline = false
            }
        )
    end
    return fields
end
function CollectAllTokenInField()
    for k, v in pairs(game.Workspace.Collectibles:GetChildren()) do
        if
            getgenv().IsToken(v) and
                getgenv().IsValidTokenPos(v, GetNerestFieldByObject(plr.Character:WaitForChild("HumanoidRootPart")))
         then
            Walkk(
                CFrame.new(
                    v.Position.X,
                    plr.Character:WaitForChild("HumanoidRootPart").Position.Y,
                    v.Position.Z
                )
            )
        end
    end
end
function UseAnt()
    game.ReplicatedStorage.Events.ToyEvent:FireServer("Ant Challenge")
end
function NormalSell()
    local old = TvkStatCache.SessionAccessories.Hat
    if Settings.EquipHoneySell then 
        game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Equip", {
            ["Mute"] = true,
            ["Type"] = "Honey Mask",
            ["Category"] = "Accessory"
        })
    end
    local Player = plr
    local Character = Player.Character
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    local sangzboi = HumanoidRootPart.CFrame
    TpToHive()
    task.wait(.2)
    game:GetService("ReplicatedStorage").Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
    task.wait(.5)
    repeat
        local tpos = plr.PlayerGui.ScreenGui.ActivateButton
        if tpos.AbsolutePosition.Y ~= 4 then
            game:GetService("ReplicatedStorage").Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
            TpToHive()
            task.wait(.5)
        end
        if string.match(tpos.TextBox.Text, "Stop") then
        else
            if string.match(tpos.TextBox.Text, "Collect") then
            else
                if string.match(tpos.TextBox.Text, "Talk") then
                else
                    game:GetService("ReplicatedStorage").Events.PlayerHiveCommand:FireServer(
                        "ToggleHoneyMaking"
                    )
                    task.wait(.5)
                end
            end
        end
        task.wait()
    until (function() if Settings.ConvertBallon then 
    if GetHiveBallon(Settings.ConvertAtB or 0) then return false end
    end 
    if Player.CoreStats.Pollen.Value <= 0 then return true end
end)() or not Settings.Farm or not Running or not ValidFarm()
    task.wait(3)
    game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Equip", {
        ["Mute"] = true,
        ["Type"] = old,
        ["Category"] = "Accessory"
    })
end

function GetValidAntPos() 
    local mid=CFrame.new(93.422752380371, 31.946582794189, 553.12829589844)
    local left=CFrame.new(93.422752380371, 31.946582794189, 553.12829589844)
    local right = CFrame.new(92.35001373291, 31.946582794189, 532.30163574219)

    local tb = {
        mid=CFrame.new(93.422752380371, 31.946582794189, 553.12829589844),
        left=CFrame.new(89.871429443359, 31.946582794189, 571.10089111328),
        right= CFrame.new(86.353813171387, 31.946582794189, 527.67553710938)
    }
    local fk = {}
    for k,v in pairs(tb) do fk[k]=false end
    local has = false
    for i,v in pairs(workspace.Toys["Ant Challenge"].Obstacles:GetChildren()) do
        if v:FindFirstChild("Root") then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then 
                if true  then
                    has=true
                    local vpos = v.Root.Position
                    local near,ractvk = nil
                    for k,v in pairs(tb) do 
                        if not ractvk then ractvk = k end
                        if (v.p-vpos).magnitude< (tb[ractvk].p-vpos).magnitude then 
                            --near=v
                            ractvk=k
                        end
                    end
                    if ractvk then 
                        fk[ractvk]=true
                    end
                end
            end
        end
    end
    if has then 
        for k,v in pairs(fk) do 
            if not v then return tb[k] end
        end
    end
    
    return tb["mid"]

end
function CheckNear(pos,mob) 
    for k,v in pairs(game.Workspace.Monsters:GetChildren()) do 
        if string.match(v.Name,mob) then 
            if v:FindFirstChild("Torso") or v:FindFirstChild("HumanoidRootPart") then 
                if ((v:FindFirstChild("Torso") or v:FindFirstChild("HumanoidRootPart")).Position-pos.p).magnitude<20 then 
                    return true
                end
            end
        end
    end
    return false
end
function GetPuffRoomLevel(v) 
--    game:GetService("Workspace").Happenings.Puffshrooms.PuffballMushroomModelCommon["Puffball Top"].Attachment.Gui.NameRow.TextLabel
    local level = 25
    if v:FindFirstChild("Puffball Top") and v["Puffball Top"]:FindFirstChild("Attachment") and  v["Puffball Top"].Attachment:FindFirstChild("Gui") and  v["Puffball Top"].Attachment.Gui:FindFirstChild("NameRow") and v["Puffball Top"].Attachment.Gui:FindFirstChild("NameRow"):FindFirstChild("TextLabel") then 
        while level>0 do 
            if v["Puffball Top"].Attachment.Gui.NameRow.TextLabel.Text:find(tostring(level)) then 
                return level
            end
            level=level-1
        end
    end
    return 0
end

function PiroField(v,f) 

    local Field = Settings.PuffField
    local FieldTf=Field
    for k,v in pairs(v) do 
        if v:FindFirstChild("Puffball Stem") and FieldTf[GetNerestFieldByObject(v["Puffball Stem"])] then 
            return v
        end
    end
    if f then return end

    local Nearest
    for k,v in pairs(v) do 
        if not Nearest and v:FindFirstChild("Puffball Stem") then Nearest=v end
        if plr.Character:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Puffball Stem") then 
            if (plr.Character.HumanoidRootPart.Position-v["Puffball Stem"].Position).magnitude<(plr.Character.HumanoidRootPart.Position-Nearest["Puffball Stem"].Position).magnitude then 
                Nearest=v
            end
        end
    end
    return Nearest
end
function GetCurrentHive() 
    for k,v in ipairs(game:GetService("Workspace").Honeycombs:GetChildren()) do 
        if tostring(v.Owner.Value)==plr.Name then 
            return v
        end
    end
end
loadstring([[
    function GetBallonLevel(v,max) 
        if pcall(function() return v.BalloonBody.GuiAttach.Gui.BlessingBar.TextLabel end) then 
            local text =v.BalloonBody.GuiAttach.Gui.BlessingBar.TextLabel.Text
            for i=1,200 do 
                if text=="🎈 Blessing x"..i then 
                    return i
                end
            end
        end
    end
]])()
function GetHiveBallon(bl)
    local Hive = GetCurrentHive()
    if Hive then 
        for k,v in ipairs(game:GetService("Workspace").Balloons.HiveBalloons:GetChildren()) do 
            if v:FindFirstChild("BalloonRoot") and  pcall(function() return v.BalloonBody.GuiAttach.Gui.BlessingBar.TextLabel end)  then 
                if (v.BalloonRoot.Position - Hive.SpawnPos.Value.p).magnitude<30 then 
                    local lv = (v:FindFirstChild("Level") and v.Level.Value) or GetBallonLevel(v)
                    if lv then 
                        if not v:FindFirstChild("Level") then 
                            local levl = Instance.new("IntValue",v)
                            levl.Name="Level"
                            levl.Value=lv
                        end
                        if v.BalloonBody.GuiAttach.Gui.BlessingBar.TextLabel.Text~="🎈 Blessing x"..v.Level.Value then 
                            v.Level.Value=GetBallonLevel(v)
                        end
                        if lv>=bl then return v end
                    end
                end
            end
        end
    end
end
function GetRaity(puff) 
    for k,v in pairs(PuffRaity) do 
        if string.match(puff.Name,v) then 
            return v
        end
    end
    return "Normal"
end
function GetNearestPushroom(Field)
    local FieldTf = PFieldTF

    -- Mythic > Legendary > Epic > Level 10+ > Rare > Highest Level
    local ListPuff = {}
    for k,v in pairs(game:GetService("Workspace").Happenings.Puffshrooms:GetChildren()) do
        if v:FindFirstChild("Puffball Stem") then 
            local a = GetRaity(v)
            if PuffRaityTF[a] then 
                local lv = GetPuffRoomLevel(v)
                if lv>=Settings.MinPuff and lv<=Settings.MaxPuff then 
                    if FieldTf[GetNerestFieldByObject(v["Puffball Stem"])] then 
                        table.insert(ListPuff,v)
                    end
                end
            end
        end
    end
    table.sort(ListPuff,function(a,b) 
        return a["Puffball Stem"].Position.magnitude < b["Puffball Stem"].Position.magnitude
    end)
    -- Mythic > Legendary > Epic
    local BestRaity = {}
    for k,v in pairs(PuffRaity) do 
        table.insert(BestRaity,v)
    end
    if Settings.PuffRMethod=="Normal > Mythic" then 
        reverse(BestRaity)
    end

    local Check=false
    local ReturnList = {}
    for k,v in pairs(BestRaity) do 
        if TPuffRaityTF[v] then 
            for k2,v2 in pairs(ListPuff) do 
                if string.match(v2.Name,v) then table.insert(ReturnList,v2) Check=true end
            end
            if Check then break end
        end
    end
    if Check then 
        return PiroField(ReturnList)
    end
    -- Piro Field
    local piro = PiroField(ListPuff,true)
    if piro then 
        return piro
    end

    -- Highest
    local Highest
    for k,v in pairs(ListPuff) do 
        if v:FindFirstChild("Puffball Stem") then 
            if not Highest then Highest=v end
            if Settings.LevelMethod == "Priority High Level" then 
                if GetPuffRoomLevel(v)>GetPuffRoomLevel(Highest) then Highest=v end
            else
                if GetPuffRoomLevel(v)<GetPuffRoomLevel(Highest) then Highest=v end
            end
        end
    end
    return Highest
end
function GetSortedBubble(Field)
    local token = {}
    local sortedtoken = {}
    for k, v in pairs(game.Workspace.Particles:GetChildren()) do
        if v:IsA("Part") then
            if v.Name == "Bubble" then
                if getgenv().IsValidTokenPos(v, Field) and ValidFarm() and Settings.Farm then
                    table.insert(token,v)
                end
            end
        end
    end
    

    local function Por(p)
        local nr
        local kk = 0
        for k, v in pairs(token) do
            if not nr then
                nr = v
                kk = k
            end
            
            if (v.Position - p.Position).magnitude < (nr.Position - p.Position).magnitude then
                nr = v
                kk = k
            end
        
        end
        if nr then
            table.insert(sortedtoken, nr)
            table.remove(token, kk)
            Por(nr)
        end
    end
    Por(plr.Character:WaitForChild("HumanoidRootPart"))
    
    return sortedtoken
end
function IsAnyCrosshair(Field) 
    for k, v in pairs(game.Workspace.Particles:GetChildren()) do
        if v:IsA("MeshPart") then
            if v.Name == "Crosshair" then
                if getgenv().IsValidTokenPos(v, Field) and (v.Color==Color3.fromRGB(144,119,87) or v.Color==Color3.fromRGB(119, 85, 255)) then
                    return true
                end
            end
        end
    end
end
function GetSortedCrossHair(Field)
    local token = {}
    local sortedtoken = {}

    -- local SortedFire
    -- if  Settings.GatherFlame then SortedFire = GetSortedFire(Field) end 
    for k, v in pairs(game.Workspace.Particles:GetChildren()) do
        if v:IsA("MeshPart") then
            if v.Name == "Crosshair" then
                if getgenv().IsValidTokenPos(v, Field) and (v.Color~=Color3.fromRGB(17, 134, 19)) then
                    if false and Settings.GatherFlame then 
                        local tuoidz
                        for k,v2 in pairs(SortedFire) do 
                            if (v2.Position-v.Position).magnitude < 20 then 
                                tuoidz= true
                                break;
                            end
                        end
                        if tuoidz then 
                            if not v:FindFirstChild("Dit me m rua") then 
                                Instance.new("BoolValue",v).Name = "Dit me m rua"
                            end
                            table.insert(sortedtoken,v)
                        else
                            table.insert(token,v)
                        end
                    else
                        table.insert(token,v)
                    end
                end
            end
        end
    end
    

    local function Por(p)
        local nr
        local kk = 0
        for k, v in pairs(token) do
            if not nr then
                nr = v
                kk = k
            end
            
            if (v.Position - p.Position).magnitude < (nr.Position - p.Position).magnitude then
                nr = v
                kk = k
            end
        
        end
        if nr then
            table.insert(sortedtoken, nr)
            table.remove(token, kk)
            Por(nr)
        end
    end
    Por(plr.Character:WaitForChild("HumanoidRootPart"))
    
    return sortedtoken
end
function GetSortedItem(tab,Field)
    if not tab then return end
    local token = {}
    local sortedtoken = {}
    for k, v in pairs(tab) do
        if not v.Activated then 
            v = v.Part
            if v:IsA("MeshPart") then
                if v.Name == "Crosshair" then
                    if getgenv().IsValidTokenPos(v, Field) and ValidFarm() and Settings.Farm then
                        table.insert(token,v)
                    end
                end
            end
        end
        
    end
    

    local function Por(p)
        local nr
        local kk = 0
        for k, v in pairs(token) do
            if not nr then
                nr = v
                kk = k
            end
            
            if (v.Position - p.Position).magnitude < (nr.Position - p.Position).magnitude then
                nr = v
                kk = k
            end
        
        end
        if nr then
            table.insert(sortedtoken, nr)
            table.remove(token, kk)
            Por(nr)
        end
    end
    Por(plr.Character:WaitForChild("HumanoidRootPart"))
    
    return sortedtoken
end
local ListFlames = {}
local ListFlamesNoDark = {}
function AddFlameToList(ListFlames,tvk,k) 
    for k,v in pairs(ListFlames) do 
        if (tvk.Position-k).magnitude < 15 then 
            table.insert(ListFlames[k],tvk)
            return
        end
    end
    ListFlames[tvk.Position] = {v}
end
function RemoveFlameInList(ListFlames,c) 
    for k,v in pairs(ListFlames) do 
        for k,v2 in pairs(v) do 
            if v2==c or not v2.Parent then 
                table.remove(v,table.find(v,v2))
            end
        end
        if #v==0 then ListFlames[k] = nil end
    end
end
game.Workspace.PlayerFlames.ChildAdded:Connect(function(tvk) 
    delay(0,function() 
        if getgenv().TempField and Settings.Farm and Settings.GatherFlame then 
            if IsValidTokenPos(tvk,getgenv().TempField) then 
                AddFlameToList(ListFlames,tvk,k)
            end
        end
        if getgenv().TempField and Settings.Farm then 
            if IsValidTokenPos(tvk,getgenv().TempField) then 
                AddFlameToList(ListFlamesNoDark,tvk,k)
            end
        end
    end)
end)
game.Workspace.PlayerFlames.ChildRemoved:Connect(function(c) 
    RemoveFlameInList(ListFlames,c)
    RemoveFlameInList(ListFlamesNoDark,c)
end)
function GetNearestFlameGroup(ListFlames,DieuKien) 
    local gancmnnhatK
    local gancmnnhatV
    for k,v in pairs(ListFlames) do
        local pass = true
        if DieuKien then 
            for k,v in pairs(v) do 
                if not DieuKien(v) then 
                    table.remove(ListFlames,table.find(ListFlames,v))
                end
            end 
        end
        if #v < 3 then pass = false ListFlames[k] = nil end
        if pass then 
            if not gancmnnhatK or not gancmnnhatV then 
                gancmnnhatK = k
                gancmnnhatV = v
            end
            if kc(k)<kc(gancmnnhatK) then 
                gancmnnhatK = k
                gancmnnhatV = v
            end 
        end
    end
    --if gancmnnhatV then print(#gancmnnhatV) end
    return gancmnnhatV
end
function GetNearestFire(Field,ruabitheiunang)
    local nr
    if plr.Character:FindFirstChild("HumanoidRootPart") then 
        if ruabitheiunang then 
            local nrGroup = GetNearestFlameGroup(ListFlamesNoDark,function(v) 
                if not v:FindFirstChild("PF") then return false end
                if not v.Parent then return false end
                if v.PF.Color == game:GetService("ReplicatedStorage").LocalFX.LocalFlames.DarkFlame.PF then
                    return false 
                end
                return true
            end)
            if nrGroup and nrGroup[1] then 
                return nrGroup[1] 
            end
        else
            if Field then 
                local nrGroup = GetNearestFlameGroup(ListFlames,function(v) 
                    if not v:FindFirstChild("PF") then return false end
                    if not v.Parent then return false end
                    if not IsValidTokenPos(v,Field) then return false end
                    return true
                end)
                if nrGroup and nrGroup[1] then 
                    return nrGroup[1] 
                end
            else
                for k, v in pairs(game.Workspace.PlayerFlames:GetChildren()) do
                    if v:FindFirstChild("PF") then
                        local tuoidz
                        if Field then 
                            if IsValidTokenPos(v,Field) then 
                                if ruabitheiunang then 
                                    if v.PF.Color ~= game:GetService("ReplicatedStorage").LocalFX.LocalFlames.DarkFlame.PF then 
                                        tuoidz = true
                                    end
                                else
                                    tuoidz=true
                                end
                            end
                        else
                            if ruabitheiunang then 
                                if v.PF.Color ~= game:GetService("ReplicatedStorage").LocalFX.LocalFlames.DarkFlame.PF then 
                                    tuoidz = true
                                end
                            else
                                tuoidz=true
                            end
                        end
                        if tuoidz then
                            if not nr then 
                                nr=v
                            end
                            if (plr.Character.HumanoidRootPart.Position-v.Position).magnitude < (plr.Character.HumanoidRootPart.Position-nr.Position).magnitude then 
                                nr=v
                            end
                        end
                    end
                end
            end
        end
    end
    return nr
end
function GetListFire(Field) 
    local ListFire = {}
    -- for k, v in pairs(game.Workspace.PlayerFlames:GetChildren()) do
    --     if v:FindFirstChild("PF") then
    --         local tuoidz
    --         if Field then 
    --             if IsValidTokenPos(v,Field) then tuoidz = true end
    --         else
    --             tuoidz=true
    --         end
    --         if tuoidz then
    --             table.insert(ListFire,v)
    --         end
    --     end
    -- end
    for k,v in pairs(ListFlames) do 
        table.insert(ListFire,{Position = k})
    end
    return ListFire
end
function GetSortedFire(Field) 
    local ListFire = {}
    -- for k, v in pairs(game.Workspace.PlayerFlames:GetChildren()) do
    --     if v:FindFirstChild("PF") then
    --         local tuoidz
    --         if Field then 
    --             if IsValidTokenPos(v,Field) then tuoidz = true end
    --         else
    --             tuoidz=true
    --         end
    --         if tuoidz then
    --             table.insert(ListFire,v)
    --         end
    --     end
    -- end
    for k,v in pairs(ListFlames) do 
        table.insert(ListFire,{Position = k})
    end
    table.sort(ListFire,function(a,b) 
        return kc(a.Position)<kc(b.Position)
    end)
    return ListFire
end
function GetNearestDupe(Field) 
    local nr
    if plr.Character:FindFirstChild("HumanoidRootPart") then 
        for k, v in pairs(game:GetService("Workspace").Camera.DupedTokens:GetChildren()) do
            if IsToken(v) and getgenv().IsValidTokenPos(v,Field) and not IsTokenBlacklist(v) then
                if string.match(v.FrontDecal.Texture,"5877939956") then return v end
                if not nr then 
                    nr=v
                end
                if (plr.Character.HumanoidRootPart.Position-v.Position).magnitude < (plr.Character.HumanoidRootPart.Position-nr.Position).magnitude then 
                    nr=v
                end
            end
        end
    end
    return nr
end
function GetSortedFlame(Field)
    local token = {}
    local sortedtoken = {}
    for k, v in pairs(game.Workspace.Particles:GetChildren()) do
        if v:IsA("Part") then
            if v.Name == "FlamePart" then
                if
                    getgenv().IsValidTokenPos(v, Field) and ValidFarm() and
                        v:FindFirstChild("Fire") and
                        Settings.Farm
                 then
                  table.insert(token,v)
                end
            end
        end
    end
    

    local function Por(p)
        local nr
        local kk = 0
        for k, v in pairs(token) do
            if not nr then
                nr = v
                kk = k
            end
            
            if (v.Position - p.Position).magnitude < (nr.Position - p.Position).magnitude then
                nr = v
                kk = k
            end
        
        end
        if nr then
            table.insert(sortedtoken, nr)
            table.remove(token, kk)
            Por(nr)
        end
    end
    Por(plr.Character:WaitForChild("HumanoidRootPart"))

    return sortedtoken
end

function GetLowestTrans(x)
    local low = math.huge
    local index
    for i, v in pairs(x) do
        if v.Transparency < low then
            low = v.Transparency
            index = i
        end
    end
    return index
end
function GetNearestCoco(x)
    local dist = math.huge
    local index
    for i, v in pairs(x) do
        local magnitude = (v.Position - plr.Character.HumanoidRootPart.Position).magnitude
        if magnitude < dist then
            dist = magnitude
            index = v
        end
    end
    return index
end
local CollectThings = {
    Shower = {},
    Coco = {},
    Metor = {}
}
local ListTr = {}

local rac = game:GetService("ReplicatedStorage").Events.LocalFX
rac.OnClientEvent:Connect(function(...) 
    if Settings.SmartTr then 
        local tempVar,rac = ...
        if tempVar=="Triangulate" then
            if plr.Character:FindFirstChild("HumanoidRootPart") then 
                if rac.Part1==plr.Character.HumanoidRootPart then 
                    table.insert(ListTr,{Start = tick(),Obj = rac})
                end
            end
        end
    else
        while #ListTr>0 do 
            table.remove(ListTr,1)
        end
    end

    if Settings.AutoFarmMetor then 
        local suc,vat,rua,thieu,nang = ...
        if suc == "MythicMeteor" then 
            table.insert(CollectThings.Metor,{Start=tick(),Obj = vat})
        end
    end
    for k,v in pairs(CollectThings.Metor) do 
        local delay = v.Obj.Delay or 2.5     
        local tuoidz = v.Obj.Dur or 0.8
        if (tick() > (tuoidz+v.Start+delay)) then 
            table.remove(CollectThings.Metor,table.find(CollectThings.Metor,v))
        end
    end

end)


game.Workspace.Particles.ChildAdded:Connect(function(v) 
    if v.Name=="WarningDisk" then 
        if v.Size.X==30 then 
            table.insert(CollectThings.Coco,v) 
        elseif v.Size.X==8 then
            table.insert(CollectThings.Shower,v) 
        end    
    end
end)

game.Workspace.Particles.ChildRemoved:Connect(function(v) 
    local type
    if v.Name=="WarningDisk" then 
        if v.Size.X==30 then 
            type="Coco"
        elseif v.Size.X==8 then
            type="Shower"
        end    
    end
    if type then 
        for k,val in pairs(CollectThings[type]) do 
            if val==v then table.remove(CollectThings[type],k) end
        end
    end
end)

function GetSortedCoconut(Field, IsShower)
    local type="Coco"
    if IsShower then 
        type="Shower"
    end
    local coco = {}
    local tempVar = 1
    if Settings.ShowerTP then tempVar = 0.5 end
    for k,v in pairs(CollectThings[type]) do 
        if plr.Character:FindFirstChild("HumanoidRootPart") and (v.Position-plr.Character.HumanoidRootPart.Position).magnitude<80
        and v:FindFirstChild("Mesh")
        then
            table.insert(coco,v)
        end
    end
    return coco;
end

function GetNearestBalloon(Field) 
    local nrs 
    for k,v in pairs(game:GetService("Workspace").Balloons.FieldBalloons:GetChildren()) do 
        if v:FindFirstChild("PlayerName") then 
            if v.PlayerName.Value==plr.Name then 
                if v:FindFirstChild("BalloonRoot") then 
                    if IsValidTokenPos(v.BalloonRoot,Field) then
                        if plr.Character:FindFirstChild("HumanoidRootPart") then 
                            if not nrs then 
                                nrs = v
                            end
                            if (plr.Character.HumanoidRootPart.Position-v.BalloonRoot.Position).magnitude<(plr.Character.HumanoidRootPart.Position-nrs.BalloonRoot.Position).magnitude then 
                                nrs = v
                            end
                        end
                    end
                end 
            end
        end
    end
    return nrs
end

function GetMark(Field)
    local dist = math.huge
    local mark
    for k, v in ipairs(game.Workspace.Particles:GetChildren()) do
        if v:IsA("Part")
        and v.Name == "AreaRing"
        and getgenv().IsValidTokenPos(v, Field) then
            if ValidFarm()
            and Settings.Farm then
                local magnitude = (v.Position - plr.Character.HumanoidRootPart.Position).magnitude
                if magnitude < dist then
                    dist = magnitude
                    mark = v
                end
            end
        end
    end
    return mark
end




function GetBallon()
    for k, v in ipairs(game.Workspace.Particles:GetChildren()) do
        if v:IsA("Part")
        and v.Name == "AreaRing" then
            if ValidFarm()
            and Settings.Farm then
                return v
            end
        end
    end
end
getgenv().PrioritizeList = PrioritizeList
getgenv().IgnoreListTF = IgnoreListTF
function SetupHookIgnore() 
    local cache = {}

    local rm = game:GetService("ReplicatedStorage").Events.CollectibleEvent
    for k,v in pairs(getconnections(rm.OnClientEvent)) do
        local oldHookIgnore
        oldHookIgnore = hookfunction(v.Function,function(...) 
            local a,p = ...
            if a=="Spawn" and p and p.Icon then 
                -- for k,val in pairs(getgenv().PrioritizeList) do
                --     if getgenv().IgnoreListTF[k] and string.match(p.Icon, val) then
                --         return
                --     end
                -- end
                if string.match(p.Icon, "rbxassetid://2028574353")
                or string.match(p.Icon, "rbxassetid://1471882621")
                or string.match(p.Icon, "1472135114") then return end
            end
            return oldHookIgnore(...)
        end)
    end
end
--SetupHookIgnore()
function SetupTokenFolder(TokenFolder,ListAllToken) 
    local TokenIdCache = {}

    TokenFolder.ChildAdded:Connect(function(v)
        local field = GetNerestFieldByObject(v)
        if not ListAllToken[field] then 
            ListAllToken[field]={}
        end
        local Token
        if v:FindFirstChild("FrontDecal") then
            local Piro = TokenIdCache[v.FrontDecal.Texture]
            if not Piro then 
                for k,val in pairs(PrioritizeList) do
                    if string.match(v.FrontDecal.Texture,val) then
                        TokenIdCache[v.FrontDecal.Texture] = k
                        if PrioritizeListTF[k] then
                            Token=k
                            break; 
                        end
                        if IgnoreListTF[k] and string.match(v.FrontDecal.Texture, val) then
                            --delay(0,function() v:Destroy() end)
                            return
                        end
                    end
                end
            else
                if PrioritizeListTF[Piro] then Token = v end
                if IgnoreListTF[Piro] then return end
            end
            
        end
        if Token then 
            if not ListAllToken[field][Token] then 
                ListAllToken[field][Token]={}
            end
            table.insert(ListAllToken[field][Token],v)     
        else
            if not ListAllToken[field]["None"] then 
                ListAllToken[field]["None"]={}
            end
            table.insert(ListAllToken[field]["None"],v)    
        end
    end)

    TokenFolder.ChildRemoved:Connect(function(v) 
        local field = GetNerestFieldByObject(v)
        if not ListAllToken[field] then 
            ListAllToken[field]={}
        end
        local index=0
        for k,val in pairs(ListAllToken[field]) do 
            for k,val2 in pairs(val) do 
                if val2==v then 
                    table.remove(val,k)
                    break;
                end
            end
        end
    end)
end

SetupTokenFolder(game.Workspace.Collectibles,ListAllToken)
SetupTokenFolder(game:GetService("Workspace").Camera.DupedTokens,ListAllDupedToken)

-- function CountTabT(ListAllToken) 
--     local c = 0
--     for k,val in pairs(ListAllToken) do
--         for k,val in pairs(val) do 
--             for k,val2 in pairs(val) do 
--                 c=c+1
--             end
--         end
--     end
--     return c
-- end

local ks = {}
for k, v in pairs(GetInstantList()) do
    ks[v.Name] = v.Platform.CFrame
end

local ListBuff = {"Blue Extract", "Red Extract", "Oil", "Enzymes", "Glue", "Tropical Drink", "Stinger","Glitter", "Magic Bean"}
local ListFieldBoost = {"Red Field Booster", "Blue Field Booster", "Field Booster", "Coconut Dispenser"}
local TFListFieldBoost = ListToOb(ListFieldBoost, false)
TFListFieldBoost["[Setting] Only enable when theres no boost"] = false
local FarmBuffList = {
    ["Blue Extract"] = false,
    ["Red Extract"] = false,
    ["Oil"] = false,
    ["Enzymes"] = false,
    ["Glue"] = false,
    ["Tropical Drink"] = false,
    ["Stinger"] = false,
    ["Glitter"] = false,
    ["Magic Bean"] = false
}

FarmBuffList = SetupTFNor(FarmBuffList,"FarmBuffList")
if not Settings.TFListFieldBoost then Settings.TFListFieldBoost = TFListFieldBoost else TFListFieldBoost=Settings.TFListFieldBoost end



local CurrentField = "Sunflower Field"
local Field = CurrentField
local TempField = Field

local LevelFarmVK = vToK(LevelFarm)
local FarmFieldList = setmetatable({},{
    __index = function(self,index)
        if LevelFarmVK[index]==0 then return end
        return self[LevelFarm[LevelFarmVK[index]-1]]
    end
}) 
FarmFieldList["CurrentField"] = Settings.CurrentField or "Sunflower Field"


getgenv().isActiveTokens = function(v)
    if v and v:IsA("Part") then
        return not ((v.Transparency + 0.05) > 0.7 and (v.Transparency - 0.05) < 0.7)
    end
end
local ChangeGlider=false
Settings.Glider="Glider"
local t = require(game:GetService("ReplicatedStorage").Parachutes)
local old = t.Get
t.Get = function(a)
    if Settings.ChangeGlider then
        return old(Settings.Glider)
    end
    return old(a)
end



-- UI LIB --
print("ccc")
local Main = Library.CreateMain({Title = 'Sea Hub - Main Farm', Desc = 'Custom Auto Farm System'})

_G.MainCFG = {
    Farm = false,
    Field = "Sunflower Field",
    ConvertAt = 95,
    AutoQuest = false,
    Speed = 40,
    SmartToken = true,
    Dig = true
}

local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local TS = game:GetService("TweenService")

local function log(msg)
    print("[Main Hub] " .. msg)
end

-- ===========================
-- CORE LOGIC
-- ===========================
local function alive()
    return plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0
end

local function tween(targetCFrame)
    if not alive() then return end
    local hrp = plr.Character.HumanoidRootPart
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    local time = dist / _G.MainCFG.Speed
    local ti = TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tw = TS:Create(hrp, ti, {CFrame = targetCFrame})
    tw:Play()
    tw.Completed:Wait()
end

local function getHoney()
    local s,r=pcall(function() return plr.CoreStats.Honey.Value end); return s and r or 0
end
local function getPollen()
    local s,r=pcall(function() return plr.CoreStats.Pollen.Value end); return s and r or 0
end
local function getCap()
    local s,r=pcall(function() return plr.CoreStats.Capacity.Value end); return s and r or 100
end
local function getHive()
    for _,h in pairs(WS.Honeycombs:GetChildren()) do
        if h:FindFirstChild("Owner") and tostring(h.Owner.Value)==plr.Name then return h end
    end
end
local function getField(name)
    local s,r=pcall(function() return WS.FlowerZones:FindFirstChild(name) end)
    return s and r or nil
end

local function getNearestToken(fieldPos)
    local hrp = plr.Character.HumanoidRootPart
    local nearest, minDist = nil, 60
    for _, token in pairs(WS.Collectibles:GetChildren()) do
        if token:IsA("Part") and token.Transparency == 0 then
            local distHrp = (token.Position - hrp.Position).Magnitude
            local distField = (token.Position - fieldPos).Magnitude
            if distField < 50 and distHrp < minDist then
                minDist = distHrp
                nearest = token
            end
        end
    end
    return nearest
end

-- ===========================
-- UI SETUP
-- ===========================
local Page1 = Main.CreatePage({Page_Name = 'Auto Farm', Page_Title = 'Farm Operations'})

local Sec1 = Page1.CreateSection('Settings')
Sec1.CreateToggle({Title = 'Enable Auto Farm', Default = false}, function(v) _G.MainCFG.Farm = v end)

local fields = {"Sunflower Field","Dandelion Field","Mushroom Field","Blue Flower Field","Clover Field","Spider Field","Strawberry Field","Bamboo Field","Pineapple Patch","Stump Field","Cactus Field","Pumpkin Patch","Pine Tree Forest","Rose Field","Mountain Top Field","Coconut Field","Pepper Patch"}
Sec1.CreateDropdown({Title = 'Select Field', List = fields, Search = true, Selected = true}, function(i, v) 
    if v then _G.MainCFG.Field = v end 
end)

Sec1.CreateSlider({Title = 'Convert At %', Min = 1, Max = 100, Default = 95, Precise = false}, function(v) _G.MainCFG.ConvertAt = v end)
Sec1.CreateSlider({Title = 'Tween Speed', Min = 10, Max = 150, Default = 40, Precise = false}, function(v) _G.MainCFG.Speed = v end)

local Sec2 = Page1.CreateSection('Farm Config')
Sec2.CreateToggle({Title = 'Smart Token Collection', Default = true}, function(v) _G.MainCFG.SmartToken = v end)
Sec2.CreateToggle({Title = 'Auto Dig', Default = true}, function(v) _G.MainCFG.Dig = v end)

local Page2 = Main.CreatePage({Page_Name = 'Quests & Progression', Page_Title = 'Auto NPC'})
local Sec3 = Page2.CreateSection('NPC Quests')
Sec3.CreateToggle({Title = 'Auto All NPC Quests', Default = false}, function(v) _G.MainCFG.AutoQuest = v end)

-- ===========================
-- BACKGROUND LOOPS
-- ===========================
task.spawn(function()
    while task.wait(0.1) do
        if _G.MainCFG.Farm and alive() then
            -- 1. Check Backpack
            if getPollen() >= (getCap() * _G.MainCFG.ConvertAt) / 100 then
                log("Backpack Full, Selling...")
                local h = getHive()
                if h then tween(h.SpawnPos.Value + Vector3.new(0, 5, 0)) end
                task.wait(0.5)
                RS.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                local t = tick()
                repeat task.wait(0.5) until getPollen() <= 0 or tick()-t > 40 or not _G.MainCFG.Farm
                task.wait(0.5)
            end
            
            -- 2. Farm Field
            local fp = getField(_G.MainCFG.Field)
            if fp and alive() and _G.MainCFG.Farm and getPollen() < (getCap() * _G.MainCFG.ConvertAt) / 100 then
                local hrp = plr.Character.HumanoidRootPart
                if (hrp.Position - fp.Position).Magnitude > 45 then
                    tween(fp.CFrame * CFrame.new(0, 5, 0))
                    task.wait(0.2)
                end
                
                if _G.MainCFG.Dig then
                    pcall(function() RS.Events.ToolCollect:FireServer() end)
                end
                
                if _G.MainCFG.SmartToken then
                    local token = getNearestToken(fp.Position)
                    if token then
                        plr.Character.Humanoid:MoveTo(token.Position)
                    else
                        plr.Character.Humanoid:MoveTo(fp.Position + Vector3.new(math.random(-20,20), 0, math.random(-20,20)))
                    end
                else
                    plr.Character.Humanoid:MoveTo(fp.Position + Vector3.new(math.random(-20,20), 0, math.random(-20,20)))
                end
            end
        end
    end
end)

task.spawn(function()
    local npcs = {"Black Bear","Brown Bear","Mother Bear","Polar Bear","Science Bear","Dapper Bear","Panda Bear"}
    while task.wait(1) do
        if _G.MainCFG.AutoQuest and alive() then
            for _, name in ipairs(npcs) do
                if not _G.MainCFG.AutoQuest then break end
                pcall(function()
                    local npc = WS.NPCs:FindFirstChild(name)
                    if npc then
                        local part = npc:FindFirstChild("Head") or npc:FindFirstChild("Torso")
                        if part then
                            tween(CFrame.new(part.Position + Vector3.new(0, 3, -4)))
                            task.wait(1)
                            for i = 1, 6 do
                                RS.Events.SelectNPCOption:FireServer("AdvanceDialog")
                                task.wait(0.3)
                            end
                        end
                    end
                end)
            end
            task.wait(60)
        end
    end
end)

print("[Main Hub] Fully loaded!")
