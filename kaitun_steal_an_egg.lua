--[[
    atlas.lua - Atlas BSS v1.2 (ban tai tao tu Dumped.json, Luraph deobfuscated)
    Build: atlas_api.lua (module game) + atlas_gui.lua (GUI + config 410 key) + glue
    Chay: dan ca file vao executor trong game Bee Swarm Simulator.
]]

local API = (function()
-- ==========================================================================
-- atlas_api.lua  -  Atlas BSS v1.2 : lop API game (ban viet moi hoan toan)
-- Moi truong: executor Roblox (Synapse-style): game, workspace, task, pcall...
-- Nguyen tac: MOI ham defensive (pcall + FindFirstChild), khong crash khi
-- object game thieu; tra ve nil / false / {} an toan.
--
-- Bang chung duong dan (chuoi trong proto_analysis.md / trace2_*.txt / probe):
--   * workspace.FlowerZones ........ recon task; proto 663: 'Position','Size','X','Y','Z'
--   * Player.CoreStats (ValueBase) . probe_small_out.txt L148 'CoreStats'; proto 380 'Honey','Value'
--   * workspace.Collectibles ....... recon task: folder chua token
--   * ReplicatedStorage.Events ..... recon task: hub remote
--   * ClientStatCache .............. recon task
--   * 'ScreenGui' > 'MeterHUD' > 'HoneyMeter'/'PollenMeter' > 'PerSecLabel'
--       ............................ trace2_380 L210-212, L251-253, L600, L5
--   * 'Capacity' .................... trace2_380 L89
--   * 17 field + 'ColorGroup' ....... proto 663 (blue / white / red)
--   * 'GrowthPercent','MaxGrowth','IsMine','PotModel' ... proto 507 (planter)
--   * 'Rhino Cave 1'..'WerewolfCave', 'MonsterType' ..... proto 572 (mob spawn)
--   * 'Robo Pass Dispenser' ......... proto 150
-- ==========================================================================

local API = {}

-- ---------------------------------------------------------------------------
-- Services + helper chung
-- ---------------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- pcall mot getter, tra ve nil khi loi (defensive read)
local function tryGet(fn)
	local ok, res = pcall(fn)
	if ok then
		return res
	end
	return nil
end

local function getLocalPlayer()
	return tryGet(function() return Players.LocalPlayer end)
end

local function getCharacter()
	local plr = getLocalPlayer()
	if not plr then
		return nil
	end
	local char = tryGet(function() return plr.Character end)
	if typeof(char) == "Instance" then
		return char
	end
	return nil
end

local function getRootPart()
	local char = getCharacter()
	if not char then
		return nil
	end
	local hrp = tryGet(function()
		return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	end)
	if typeof(hrp) == "Instance" then
		return hrp
	end
	return nil
end

local function getHumanoid()
	local char = getCharacter()
	if not char then
		return nil
	end
	local hum = tryGet(function() return char:FindFirstChildOfClass("Humanoid") end)
	if typeof(hum) == "Instance" then
		return hum
	end
	return nil
end

local function getInstancePosition(inst)
	return tryGet(function()
		if inst:IsA("BasePart") then
			return inst.Position
		end
		if inst:IsA("Model") then
			local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
			if pp then
				return pp.Position
			end
			return inst:GetPivot().Position
		end
		return nil
	end)
end

-- ---------------------------------------------------------------------------
-- API.Player
-- ---------------------------------------------------------------------------
API.Player = {}

function API.Player.LocalPlayer()
	return getLocalPlayer()
end

function API.Player.Character()
	return getCharacter()
end

function API.Player.RootPart()
	return getRootPart()
end

function API.Player.Humanoid()
	return getHumanoid()
end

function API.Player.Position()
	local root = getRootPart()
	if root then
		return tryGet(function() return root.Position end)
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- API.Field  (proto 663: database 17 field + ColorGroup blue/red/white)
-- ---------------------------------------------------------------------------
local FIELD_DB = {
	-- blue (5)
	{ Name = "Blue Flower Field",  Color = "blue"  },
	{ Name = "Clover Field",       Color = "blue"  },
	{ Name = "Dandelion Field",    Color = "blue"  },
	{ Name = "Sunflower Field",    Color = "blue"  },
	{ Name = "Mushroom Field",     Color = "blue"  },
	-- white (8)
	{ Name = "Bamboo Field",       Color = "white" },
	{ Name = "Pine Tree Forest",   Color = "white" },
	{ Name = "Pineapple Patch",    Color = "white" },
	{ Name = "Mountain Top Field", Color = "white" },
	{ Name = "Pumpkin Patch",      Color = "white" },
	{ Name = "Cactus Field",       Color = "white" },
	{ Name = "Coconut Field",      Color = "white" },
	{ Name = "Stump Field",        Color = "white" },
	-- red (4)
	{ Name = "Spider Field",       Color = "red"   },
	{ Name = "Strawberry Field",   Color = "red"   },
	{ Name = "Rose Field",         Color = "red"   },
	{ Name = "Pepper Patch",       Color = "red"   },
}

API.Field = {}

function API.Field.List()
	local out = {}
	for i, entry in ipairs(FIELD_DB) do
		out[i] = { Name = entry.Name, Color = entry.Color }
	end
	return out
end

function API.Field.Names()
	local out = {}
	for i, entry in ipairs(FIELD_DB) do
		out[i] = entry.Name
	end
	return out
end

function API.Field.ColorGroups()
	local groups = { blue = {}, red = {}, white = {} }
	for _, entry in ipairs(FIELD_DB) do
		local bucket = groups[entry.Color]
		if bucket then
			bucket[#bucket + 1] = entry.Name
		end
	end
	return groups
end

function API.Field.GetColor(fieldName)
	for _, entry in ipairs(FIELD_DB) do
		if entry.Name == fieldName then
			return entry.Color
		end
	end
	return nil
end

function API.Field.GetByName(fieldName)
	for _, entry in ipairs(FIELD_DB) do
		if entry.Name == fieldName then
			return entry.Name, entry.Color
		end
	end
	return nil
end

function API.Field.GetZone(fieldName)
	return tryGet(function()
		local zones = workspace:FindFirstChild("FlowerZones") -- recon task
		if zones then
			return zones:FindFirstChild(fieldName)
		end
		return nil
	end)
end

-- tra ve (center:Vector3, size:Vector3) cua zone, nil khi khong doc duoc
-- (dung pcall truc tiep de giu duoc 2 gia tri tra ve)
function API.Field.ZoneBounds(zone)
	if typeof(zone) ~= "Instance" then
		return nil, nil
	end
	local ok, center, size = pcall(function()
		if zone:IsA("BasePart") then
			return zone.Position, zone.Size
		end
		if zone:IsA("Model") then
			local pp = zone.PrimaryPart or zone:FindFirstChildWhichIsA("BasePart", true)
			if pp then
				return pp.Position, pp.Size
			end
		end
		return nil, nil
	end)
	if ok and center and size then
		return center, size
	end
	return nil, nil
end

-- fix: cache bounds cac zone trong 5s. API.Tokens.Scan goi ContainsPosition
-- cho TUNG token; moi lan goi la quet GetChildren + pcall bounds cua ca folder
-- FlowerZones -> O(tokens x zones) pcall moi lan quet, gap dan CPU khi field
-- dong token. Zone it khi doi nen cache TTL la du an toan.
local zoneBoundsCache = nil
local zoneCacheTime = 0
local ZONE_CACHE_TTL = 5

local function getZoneBoundsList()
	local now = os.clock()
	if zoneBoundsCache and (now - zoneCacheTime) < ZONE_CACHE_TTL then
		return zoneBoundsCache
	end
	local zones = tryGet(function() return workspace:FindFirstChild("FlowerZones") end)
	if not zones then
		return nil
	end
	local children = tryGet(function() return zones:GetChildren() end)
	if not children then
		return nil
	end
	local list = {}
	for _, zone in ipairs(children) do
		local center, size = API.Field.ZoneBounds(zone)
		if center and size then
			list[#list + 1] = { Name = zone.Name, Center = center, Size = size }
		end
	end
	zoneBoundsCache = list
	zoneCacheTime = now
	return list
end

-- kiem tra 1 toa do co nam trong zone field nao khong; tra ve TEN ZONE (giong
-- ten field trong DB) hoac nil. proto 663 dung 'Position'/'Size' theo zone.
function API.Field.ContainsPosition(position)
	if typeof(position) ~= "Vector3" then
		return nil
	end
	local list = getZoneBoundsList() -- fix: dung cache thay vi quet lai moi goi
	if not list then
		return nil
	end
	for _, z in ipairs(list) do
		local dx = math.abs(position.X - z.Center.X)
		local dz = math.abs(position.Z - z.Center.Z)
		-- le 4 stud de tru cap dat canh bien; chi canh theo X/Z (field phang)
		if dx <= z.Size.X * 0.5 + 4 and dz <= z.Size.Z * 0.5 + 4 then
			return z.Name
		end
	end
	return nil
end

function API.Field.CurrentField()
	local root = getRootPart()
	if not root then
		return nil
	end
	return API.Field.ContainsPosition(root.Position)
end

function API.Field.GetPosition(fieldName)
	local zone = API.Field.GetZone(fieldName)
	if not zone then
		return nil
	end
	local center = select(1, API.Field.ZoneBounds(zone))
	return center
end

-- ---------------------------------------------------------------------------
-- API.Stats  (Player.CoreStats - ValueBase; bang chung 'CoreStats' + 'Honey'/'Value')
-- ---------------------------------------------------------------------------
API.Stats = {}

function API.Stats.Get(statName)
	local plr = getLocalPlayer()
	if not plr then
		return nil
	end
	return tryGet(function()
		local core = plr:FindFirstChild("CoreStats")
		if not core then
			return nil
		end
		local obj = core:FindFirstChild(statName)
		if obj then
			return obj.Value
		end
		return nil
	end)
end

function API.Stats.Honey()
	return API.Stats.Get("Honey")
end

function API.Stats.Pollen()
	return API.Stats.Get("Pollen")
end

function API.Stats.Capacity()
	return API.Stats.Get("Capacity")
end

function API.Stats.IsFull()
	local pollen = API.Stats.Pollen()
	local capacity = API.Stats.Capacity()
	if pollen and capacity and capacity > 0 then
		return pollen >= capacity
	end
	return false
end

-- doc du phong tu ClientStatCache (recon task); cau truc cham ho tro ca
-- value object va folder
function API.Stats.GetCached(statName)
	return tryGet(function()
		local cache = ReplicatedStorage:FindFirstChild("ClientStatCache")
			or Players:FindFirstChild("ClientStatCache")
		if not cache then
			return nil
		end
		local obj = cache:FindFirstChild(statName)
		if not obj then
			obj = cache:FindFirstChild(statName, true)
		end
		if obj then
			local ok, value = pcall(function() return obj.Value end)
			if ok then
				return value
			end
		end
		return nil
	end)
end

-- ---------------------------------------------------------------------------
-- API.Tokens  (workspace.Collectibles; 'IsMine' xuat hien o proto 380/507)
-- ---------------------------------------------------------------------------
API.Tokens = {}

function API.Tokens.GetFolder()
	return tryGet(function() return workspace:FindFirstChild("Collectibles") end)
end

-- quet token: fieldName = ten field loc (nil = field hien tai, false = tat ca)
-- tra ve mang { { Instance, Name, Position, IsMine }, ... }
function API.Tokens.Scan(fieldName)
	local folder = API.Tokens.GetFolder()
	if not folder then
		return {}
	end
	local children = tryGet(function() return folder:GetChildren() end)
	if not children then
		return {}
	end
	local targetField = fieldName
	if targetField == nil then
		targetField = API.Field.CurrentField()
	end
	local out = {}
	for _, inst in ipairs(children) do
		local pos = getInstancePosition(inst)
		if pos then
			local ok = true
			if targetField then
				ok = (API.Field.ContainsPosition(pos) == targetField)
			end
			if ok then
				local isMine = tryGet(function()
					return inst:GetAttribute("IsMine") == true
				end)
				out[#out + 1] = {
					Instance = inst,
					Name = inst.Name,
					Position = pos,
					IsMine = isMine == true,
				}
			end
		end
	end
	return out
end

function API.Tokens.InCurrentField()
	return API.Tokens.Scan(nil)
end

function API.Tokens.Count(fieldName)
	local list = API.Tokens.Scan(fieldName)
	return #list
end

-- ---------------------------------------------------------------------------
-- API.Remotes  (ReplicatedStorage.Events; goi an toan qua pcall)
-- Luu y: dump khong chua chuoi 'FireServer'/'RemoteEvent' du dang - cac lenh
-- goi nam trong VMOP chua dich (ghi chu cuoi moi proto trong proto_analysis.md).
-- ---------------------------------------------------------------------------
API.Remotes = {}

-- chuoi object duoc proto tham chieu lam duong dan tra cuu (khong phai ten
-- remote xac nhan): proto 674 'Eggs','RoyalJelly','GetCost','Purchasing';
-- proto 150 'RoboChallenges','ActiveChallenge','RoundState'; proto 514
-- 'PlayerActiveTimes'; proto 507 'GrowthPercent','PotModel'.
API.Remotes.Notes = {
	Events = "ReplicatedStorage.Events - hub remote chinh (recon task)",
	Eggs = "proto 674 - Basic Egg Shop",
	RoyalJelly = "proto 674 - Royal Jelly Shop",
	RoboChallenges = "proto 150 - folder trang thai RBC",
	PlayerActiveTimes = "proto 514 - du lieu nguoi choi",
}

function API.Remotes.GetEvents()
	return tryGet(function() return ReplicatedStorage:FindFirstChild("Events") end)
end

-- tra ve Instance tu duong dan cham, vd "Events.PlayerActs.X"
function API.Remotes.Get(path)
	if type(path) ~= "string" or path == "" then
		return nil
	end
	return tryGet(function()
		local current = ReplicatedStorage
		for token in string.gmatch(path, "[^.]+") do
			if not current then
				return nil
			end
			current = current:FindFirstChild(token)
		end
		return current
	end)
end

-- goi FireServer/InvokeServer tuy loai remote; tra ve (ok, err)
function API.Remotes.Fire(path, ...)
	local remote = API.Remotes.Get(path)
	if typeof(remote) ~= "Instance" then
		return false, "remote not found: " .. tostring(path)
	end
	local args = { ... }
	if remote:IsA("RemoteFunction") then
		local ok, err = pcall(function()
			remote:InvokeServer(table.unpack(args))
		end)
		return ok, err
	end
	local ok, err = pcall(function()
		remote:FireServer(table.unpack(args))
	end)
	return ok, err
end

-- chi dung cho RemoteFunction; tra ve gia tri hoac nil (khong bao crash)
function API.Remotes.Invoke(path, ...)
	local remote = API.Remotes.Get(path)
	if typeof(remote) ~= "Instance" or not remote:IsA("RemoteFunction") then
		return nil
	end
	local args = { ... }
	return tryGet(function()
		return remote:InvokeServer(table.unpack(args))
	end)
end

-- ---------------------------------------------------------------------------
-- API.Mobs  (proto 572: spawn point + 'MonsterType')
-- ---------------------------------------------------------------------------
-- Anh xa spawn -> mob la best-effort tu ten chuoi trong proto 572; tai runtime
-- uu tien doc thuoc tinh 'MonsterType' (API.Mobs.GetType).
local MOB_DB = {
	{ Name = "Rhino Cave 1",     Mob = "Rhino"      },
	{ Name = "Rhino Cave 2",     Mob = "Rhino"      },
	{ Name = "Rhino Bush",       Mob = "Rhino"      },
	{ Name = "RoseBush",         Mob = "Rhino"      },
	{ Name = "RoseBush2",        Mob = "Rhino"      },
	{ Name = "Ladybug Bush",     Mob = "Ladybug"    },
	{ Name = "Ladybug Bush 2",   Mob = "Ladybug"    },
	{ Name = "Ladybug Bush 3",   Mob = "Ladybug"    },
	{ Name = "MushroomBush",     Mob = "Ladybug"    },
	{ Name = "ForestMantis1",    Mob = "Mantis"     },
	{ Name = "ForestMantis2",    Mob = "Mantis"     },
	{ Name = "PineappleMantis1", Mob = "Mantis"     },
	{ Name = "PineappleBeetle",  Mob = "Beetle"     },
	{ Name = "Spider Cave",      Mob = "Spider"     },
	{ Name = "WerewolfCave",     Mob = "Werewolf"   },
	{ Name = "Stump Snail",      Mob = "Stump Snail" },
}

API.Mobs = {}

function API.Mobs.List()
	local out = {}
	for i, entry in ipairs(MOB_DB) do
		out[i] = { Name = entry.Name, Mob = entry.Mob }
	end
	return out
end

function API.Mobs.GetInfo(spawnName)
	for _, entry in ipairs(MOB_DB) do
		if entry.Name == spawnName then
			return entry.Name, entry.Mob
		end
	end
	return nil
end

function API.Mobs.FindSpawn(spawnName)
	if type(spawnName) ~= "string" then
		return nil
	end
	return tryGet(function()
		local direct = workspace:FindFirstChild(spawnName)
		if direct then
			return direct
		end
		for _, containerName in ipairs({ "Mobs", "Monsters", "MobSpawns", "Spawns" }) do
			local container = workspace:FindFirstChild(containerName)
			if container then
				local found = container:FindFirstChild(spawnName, true)
				if found then
					return found
				end
			end
		end
		-- cuoi cung: quet de quy toan workspace (ton tai nhung chinh xac)
		return workspace:FindFirstChild(spawnName, true)
	end)
end

-- doc loai mob that tai runtime tu 'MonsterType' (attribute hoac value object)
function API.Mobs.GetType(spawn)
	if typeof(spawn) ~= "Instance" then
		return nil
	end
	local attr = tryGet(function() return spawn:GetAttribute("MonsterType") end)
	if type(attr) == "string" and attr ~= "" then
		return attr
	end
	return tryGet(function()
		local v = spawn:FindFirstChild("MonsterType")
		if v then
			return v.Value
		end
		return nil
	end)
end

function API.Mobs.GetPosition(spawnName)
	local spawn = API.Mobs.FindSpawn(spawnName)
	if not spawn then
		return nil
	end
	return getInstancePosition(spawn)
end

-- ---------------------------------------------------------------------------
-- API.Dispensers  (config_schema: 'Blueberry Dispenser', 'Free Ant Pass
-- Dispenser', 'Free Robo Pass Dispenser', 'Free Royal Jelly Dispenser',
-- 'Glue Dispenser'; proto 150: 'Robo Pass Dispenser')
-- ---------------------------------------------------------------------------
local DISPENSER_DB = {
	"Blueberry Dispenser",
	"Honey Dispenser",
	"Strawberry Dispenser",
	"Treat Dispenser",
	"Coconut Dispenser",
	"Ant Pass Dispenser",
	"Robo Pass Dispenser",
	"Royal Jelly Dispenser",
	"Glue Dispenser",
}

API.Dispensers = {}

function API.Dispensers.List()
	local out = {}
	for i, name in ipairs(DISPENSER_DB) do
		out[i] = name
	end
	return out
end

function API.Dispensers.Find(name)
	if type(name) ~= "string" then
		return nil
	end
	return tryGet(function()
		local direct = workspace:FindFirstChild(name)
		if direct then
			return direct
		end
		return workspace:FindFirstChild(name, true)
	end)
end

function API.Dispensers.GetPosition(name)
	local inst = API.Dispensers.Find(name)
	if not inst then
		return nil
	end
	return getInstancePosition(inst)
end

-- tim ProximityPrompt gan voi dispenser (dung de kich hoat tu dong)
function API.Dispensers.GetPrompt(inst)
	if typeof(inst) ~= "Instance" then
		return nil
	end
	return tryGet(function()
		return inst:FindFirstChildWhichIsA("ProximityPrompt", true)
	end)
end

-- ---------------------------------------------------------------------------
-- API.HUD  (proto 380: 'ScreenGui' > 'MeterHUD' > 'HoneyMeter'/'PollenMeter'
-- > 'PerSecLabel' - doc toc do honey; 'Capacity' o trace2_380 L89)
-- ---------------------------------------------------------------------------
API.HUD = {}

local SUFFIX_MULT = { K = 1e3, M = 1e6, B = 1e9, T = 1e12 }

-- parser so the he thong game: "1,234,567", "12.5k", "3.2M"...
function API.HUD.ParseNumber(text)
	if type(text) ~= "string" then
		return nil
	end
	local chunk = text:match("[%d%.%s,KMBTkmbt]+") or ""
	chunk = chunk:gsub("[,%s]", "")
	local numStr = chunk:match("^%d*%.?%d*")
	if numStr == nil or numStr == "" or numStr == "." then
		return nil
	end
	local num = tonumber(numStr)
	if not num then
		return nil
	end
	local suffix = chunk:sub(#numStr + 1, #numStr + 1):upper()
	local mult = SUFFIX_MULT[suffix] or 1
	return num * mult
end

local function guiRoots()
	local roots = {}
	local plr = getLocalPlayer()
	if plr then
		local pg = tryGet(function() return plr:FindFirstChildOfClass("PlayerGui") end)
		if pg then
			roots[#roots + 1] = pg
		end
	end
	local cg = tryGet(function() return game:GetService("CoreGui") end)
	if cg then
		roots[#roots + 1] = cg
	end
	local hidden = tryGet(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if typeof(hidden) == "Instance" then
		roots[#roots + 1] = hidden
	end
	return roots
end

-- tim ScreenGui HUD chua 'MeterHUD' (chuoi 'ScreenGui' o trace2_380 L210/L251)
function API.HUD.FindScreenGui()
	for _, root in ipairs(guiRoots()) do
		local children = tryGet(function() return root:GetChildren() end)
		if children then
			for _, gui in ipairs(children) do
				if typeof(gui) == "Instance" and gui:IsA("ScreenGui") then
					local hasHud = tryGet(function()
						return gui:FindFirstChild("MeterHUD", true)
					end)
					if hasHud then
						return gui
					end
				end
			end
		end
	end
	return nil
end

-- tra ve meter con (HoneyMeter / PollenMeter / ...) trong MeterHUD
function API.HUD.GetMeter(meterName)
	local gui = API.HUD.FindScreenGui()
	if not gui then
		return nil
	end
	return tryGet(function()
		local hud = gui:FindFirstChild("MeterHUD", true)
		if hud then
			return hud:FindFirstChild(meterName, true)
		end
		return nil
	end)
end

-- doc honey/hour tu HoneyMeter.PerSecLabel; tra ve { Text, Value, Unit, PerHour }
function API.HUD.GetHoneyPerHour()
	local meter = API.HUD.GetMeter("HoneyMeter")
	if not meter then
		return nil
	end
	local label = tryGet(function() return meter:FindFirstChild("PerSecLabel", true) end)
	if not label then
		return nil
	end
	local text = tryGet(function() return label.Text end)
	if type(text) ~= "string" then
		return nil
	end
	local value = API.HUD.ParseNumber(text)
	local low = string.lower(text)
	local unit = nil
	if string.find(low, "sec", 1, true) then
		unit = "second"
	elseif string.find(low, "hour", 1, true) or string.find(low, "/hr", 1, true) then
		unit = "hour"
	end
	local perHour = nil
	if value then
		if unit == "second" then
			perHour = value * 3600
		else
			perHour = value
		end
	end
	return { Text = text, Value = value, Unit = unit, PerHour = perHour }
end

-- doc toc do pollen tu PollenMeter.PerSecLabel; tra ve { Text, Value }
function API.HUD.GetPollenPerSec()
	local meter = API.HUD.GetMeter("PollenMeter")
	if not meter then
		return nil
	end
	local label = tryGet(function() return meter:FindFirstChild("PerSecLabel", true) end)
	if not label then
		return nil
	end
	local text = tryGet(function() return label.Text end)
	if type(text) ~= "string" then
		return nil
	end
	return { Text = text, Value = API.HUD.ParseNumber(text) }
end

return API

end)()

local AtlasGUI = (function()
-- ==========================================================================
-- atlas_gui.lua  -  Atlas BSS v1.2 : UI framework + config (viet moi hoan toan)
-- Moi truong: executor Roblox (Synapse-style): game, task, writefile/readfile,
-- HttpService, gethui (neu co). Giao dien toi gian: Frame + UICorner + TextButton.
--
-- Bang chung (config_schema.md / proto_analysis.md):
--   * Window title 'Atlas v1.2' ......... p1 pc=52805, 612 pc=777
--   * Config file 'atlas1/default.json' . p1 pc=773/1536; 612pc752-761 settingsfolder
--   * Ten method UI goc: 'ToggleSwitch' / 'SetDropdown' / 'SetSlider' /
--     'SetTextBox' / 'AddDropdownItem' .. S1 - UI registry (proto 612, 422 elements)
--   * 11 tab: Misc, Assist, Detected, RBC, Webhook, Autofarm, Planters,
--     Puffshrooms, Quests, Bears, Movement .. dump key theo section (410 key)
--   * Nectar dropdown: Comforting/Motivating/Satisfying/Refreshing/Invigorating .. 612pc736-746
--   * RJ rarity: Common/Rare/Epic/Legendary/Mythic .. p1 pc=7572+
--   * 17 field dropdown: proto 663
-- ==========================================================================

local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local WINDOW_TITLE    = "Atlas v1.2"          -- 612 pc=777
local SETTINGS_FOLDER = "atlas1"              -- 612pc752-754 config/settingsfolder
local CONFIG_FILE     = "atlas1/default.json" -- p1 pc=773/1536

-- ---------------------------------------------------------------------------
-- Wrapper file API cua executor (khong co thi bo qua, khong crash)
-- ---------------------------------------------------------------------------
local function fsWrite(path, data)
	local ok = pcall(function() writefile(path, data) end)
	return ok
end

local function fsRead(path)
	local ok, data = pcall(function() return readfile(path) end)
	if ok then
		return data
	end
	return nil
end

local function fsExists(path)
	local ok, res = pcall(function() return isfile(path) end)
	if ok and res then
		return true
	end
	local ok2, res2 = pcall(function() return isfolder(path) end)
	if ok2 and res2 then
		return true
	end
	return false
end

local function fsMakeFolder(path)
	pcall(function() makefolder(path) end)
end

-- ---------------------------------------------------------------------------
-- DEFAULT_CONFIG - 410 key, copy nguyen tu config_defaults.lua (thu tu goc)
-- ---------------------------------------------------------------------------
local DEFAULT_CONFIG = {
    Anonymous = false, -- [Misc] dump: anonymous -> anonymous
    Multiplefields = false, -- [Misc] dump: multiplefields -> multiplefields
    Mobiletoggle = false, -- [Misc] dump: mobiletoggle -> mobiletoggle
    MiscConsole = true, -- [Misc] dump: console -> console
    Autorejoin = true, -- [Misc] dump: autorejoin -> autorejoin
    Questdone = false, -- [Misc] dump: questdone -> questdone
    Tokens = false, -- [Misc] dump: tokens -> tokens
    Honeytokens = false, -- [Misc] dump: honeytokens -> honeytokens
    Particles = false, -- [Misc] dump: particles -> particles
    MiscPrecise = false, -- [Misc] dump: precise -> precise
    MiscDupedtokens = false, -- [Misc] dump: dupedtokens -> dupedtokens
    MiscBlooms = false, -- [Misc] dump: blooms -> blooms
    MiscMarks = false, -- [Misc] dump: marks -> marks
    Bees = false, -- [Misc] dump: bees -> bees
    Flowers = false, -- [Misc] dump: flowers -> flowers
    MiscBalloons = false, -- [Misc] dump: balloons -> balloons
    Decorations = false, -- [Misc] dump: decorations -> decorations
    Textures = false, -- [Misc] dump: textures -> textures
    Norender = false, -- [Misc] dump: rendering -> norender
    Players = false, -- [Misc] dump: players -> players
    Bssui = false, -- [Misc] dump: bssui -> bssui
    Main = false, -- [Misc] dump: main -> main
    Fastshower = true, -- [Assist] dump: fastshower -> fastshower
    Fastcoconut = true, -- [Assist] dump: fastcoconut -> fastcoconut
    Fastcombococonut = true, -- [Assist] dump: fastcombococonut -> fastcombococonut
    Tprare = true, -- [Assist] dump: tprare -> tprare
    Rares = "", -- TODO: default chua xac nhan; gia tri an toan -- [Assist] dump: rares -> rares
    AssistCombococonuts = false, -- [Assist] dump: combococonuts -> combococonuts
    AssistShowers = false, -- [Assist] dump: showers -> showers
    DetectedStopEverything = true, -- [Detected] dump: home -> stop_everything
    DetectedTweenspeed = 12, -- [Detected] dump: tweenspeed_panic -> tweenspeed
    Disconnectid = "", -- [Detected] dump: disconnectid -> disconnectid
    Disconnect = false, -- [Detected] dump: disconnect -> disconnect
    RBCEnabled = true, -- [RBC] dump: rbc_enabled -> enabled
    RBCPreset = "", -- TODO: default chua xac nhan; gia tri an toan -- [RBC] dump: preset -> preset
    Buydrives = "", -- TODO: default chua xac nhan; gia tri an toan -- [RBC] dump: buydrives -> buydrives
    RBCMaterials = false, -- [RBC] dump: materials -> materials
    Quitround = false, -- [RBC] dump: quitround -> quitround
    Disableround = false, -- [RBC] dump: disableround -> disableround
    Minround = 15, -- [RBC] dump: minround -> minround
    Buypass = false, -- [RBC] dump: buypass -> buypass
    Passcooldown = 0, -- [RBC] dump: passcooldown -> passcooldown
    RBCPrecise = false, -- [RBC] dump: precise_rbc -> precise
    Precisemin = 5, -- [RBC] dump: precisemin -> precisemin
    Rerollbees = false, -- [RBC] dump: rerollbees -> rerollbees
    Rerollbeesmax = 2, -- [RBC] dump: rerollbeesmax -> rerollbeesmax
    Goldcog = true, -- [RBC] dump: goldcog -> goldcog
    Goldcogmax = 6, -- [RBC] dump: goldcogmax -> goldcogmax
    Boosters = false, -- [RBC] dump: boosters -> boosters
    Boostersrbc = false, -- [RBC] dump: boostersrbc -> boostersrbc
    Boostersround = 20, -- [RBC] dump: boostersround -> boostersround
    RBCStacker = false, -- [RBC] dump: stacker -> stacker
    Stackerrbc = false, -- [RBC] dump: stackerrbc -> stackerrbc
    Stackerround = 20, -- [RBC] dump: stackerround -> stackerround
    RBCBestbluefield = "", -- TODO: default chua xac nhan; gia tri an toan -- [RBC] dump: bestbluefield -> bestbluefield
    RBCBestredfield = "", -- TODO: default chua xac nhan; gia tri an toan -- [RBC] dump: bestredfield -> bestredfield
    RBCBestwhitefield = "", -- TODO: default chua xac nhan; gia tri an toan -- [RBC] dump: bestwhitefield -> bestwhitefield
    RBCGoomethod = "Gumdrops", -- [RBC] dump: goomethod -> goomethod
    Homepage = false, -- [RBC] dump: homepage -> homepage
    Homepagemin = 1, -- [RBC] dump: homepagemin -> homepagemin
    Highestcog = false, -- [RBC] dump: highestcog -> highestcog
    Cogconvert = false, -- [RBC] dump: cogconvert -> cogconvert
    Highestcogmax = 9, -- [RBC] dump: highestcogmax -> highestcogmax
    Rerollquests = false, -- [RBC] dump: rerollquests -> rerollquests
    Rerollquestsmin = 10, -- [RBC] dump: rerollquestsmin -> rerollquestsmin
    Cogupgrades = true, -- [RBC] dump: cogupgrades -> cogupgrades
    Rerollupgrades = false, -- [RBC] dump: rerollupgrades -> rerollupgrades
    Rerollupgradesmax = 2, -- [RBC] dump: rerollupgradesmax -> rerollupgradesmax
    Upgrades = false, -- [RBC] dump: upgrades -> upgrades
    Mask = false, -- [RBC] dump: mask -> mask
    Maskmin = 5, -- [RBC] dump: maskmin -> maskmin
    Bluemask = "Diamond Mask", -- [RBC] dump: bluemask -> bluemask
    Redmask = "", -- TODO: default chua xac nhan; gia tri an toan -- [RBC] dump: redmask -> redmask
    Whitemask = "", -- TODO: default chua xac nhan; gia tri an toan -- [RBC] dump: whitemask -> whitemask
    Tool = false, -- [RBC] dump: tool -> tool
    Toolmin = 4, -- [RBC] dump: toolmin -> toolmin
    Bluetool = "Tide Popper", -- [RBC] dump: bluetool -> bluetool
    Redtool = "Dark Scythe", -- [RBC] dump: redtool -> redtool
    Whitetool = "Gummyballer", -- [RBC] dump: whitetool -> whitetool
    Cog = false, -- [RBC] dump: amulet -> cog
    Cogold = false, -- [RBC] dump: amuletold -> cogold
    Webhook = false, -- [Webhook] dump: webhook -> webhook
    Inventory = false, -- [Webhook] dump: getinventory -> inventory
    WebhookEnabled = false, -- [Webhook] dump: webhook_enabled -> enabled
    Interval = 5, -- [Webhook] dump: interval -> interval
    Url = "", -- [Webhook] dump: url -> url
    WebhookBalloon = true, -- [Webhook] dump: balloon -> balloon
    WebhookNectars = true, -- [Webhook] dump: nectars -> nectars
    WebhookPlanters = true, -- [Webhook] dump: planters -> planters
    WebhookItems = false, -- [Webhook] dump: items -> items
    WebhookConsole = false, -- [Webhook] dump: webhook_console -> console
    Stickers = false, -- [Webhook] dump: stickers -> stickers
    Beequips = false, -- [Webhook] dump: beequips -> beequips
    Drives = true, -- [Webhook] dump: drives -> drives
    Dappershop = true, -- [Webhook] dump: dappershop -> dappershop
    Graph = false, -- [Webhook] dump: graphenabled -> graph
    Graphurl = "", -- [Webhook] dump: graphurl -> graphurl
    Dashboard = false, -- [Webhook] dump: dashboard -> dashboard
    Key = "", -- [Webhook] dump: key -> key
    AutofarmEnabled = false, -- [Autofarm] dump: autofarm_enabled -> enabled
    Field1 = "Dandelion Field", -- [Autofarm] dump: field1 -> field1
    Field2 = "None", -- [Autofarm] dump: field2 -> field2
    Field3 = "None", -- [Autofarm] dump: field3 -> field3
    Fieldinterval = 10, -- [Autofarm] dump: fieldinterval -> fieldinterval
    Sprinklers = false, -- [Autofarm] dump: sprinklers -> sprinklers
    Autodig = false, -- [Autofarm] dump: autodig -> autodig
    Scorching = true, -- [Autofarm] dump: scorching -> scorching
    Scorchingscore = 0, -- [Autofarm] dump: scorchingscore -> scorchingscore
    Xflame = false, -- [Autofarm] dump: xflame -> xflame
    Xflametokens = 25, -- [Autofarm] dump: xflametokens -> xflametokens
    Pop = true, -- [Autofarm] dump: pop -> pop
    Gummy = true, -- [Autofarm] dump: gummy -> gummy
    AutofarmBlooms = false, -- [Autofarm] dump: blooms_farm -> blooms
    AutofarmPetals = true, -- [Autofarm] dump: petals -> petals
    AutofarmBubbles = false, -- [Autofarm] dump: bubbles -> bubbles
    Coconuts = true, -- [Autofarm] dump: coconuts -> coconuts
    AutofarmCombococonuts = true, -- [Autofarm] dump: combococonuts_farm -> combococonuts
    Comboamount = 100, -- [Autofarm] dump: comboamount -> comboamount
    Combofield = false, -- [Autofarm] dump: combofield -> combofield
    AutofarmDupedtokens = false, -- [Autofarm] dump: dupedtokens_farm -> dupedtokens
    Smileyboosts = false, -- [Autofarm] dump: smileyboosts -> smileyboosts
    Flames = false, -- [Autofarm] dump: flames -> flames
    Fuzzbombs = false, -- [Autofarm] dump: fuzzbombs -> fuzzbombs
    Leaves = false, -- [Autofarm] dump: leaves -> leaves
    AutofarmMarks = false, -- [Autofarm] dump: marks_farm -> marks
    AutofarmPrecise = false, -- [Autofarm] dump: precise_farm -> precise
    Precisemark = true, -- [Autofarm] dump: precisemark -> precisemark
    Precisemarkstand = false, -- [Autofarm] dump: precisemarkstand -> precisemarkstand
    AutofarmShowers = true, -- [Autofarm] dump: showers_farm -> showers
    Clouds = true, -- [Autofarm] dump: clouds -> clouds
    AutofarmBalloons = false, -- [Autofarm] dump: balloons_farm -> balloons
    Ignorehoney = true, -- [Autofarm] dump: ignorehoney -> ignorehoney
    Priority = "", -- TODO: default chua xac nhan; gia tri an toan -- [Autofarm] dump: priority -> priority
    Dupedtokens2 = "", -- TODO: default chua xac nhan; gia tri an toan -- [Autofarm] dump: dupedtokens2 -> dupedtokens2
    Sprinklerpos = "Center", -- [Autofarm] dump: sprinklerpos -> sprinklerpos
    AutofarmHoney = true, -- [Autofarm] dump: honey -> honey
    Honeyat = 100, -- [Autofarm] dump: honeyat -> honeyat
    AutofarmBalloon = false, -- [Autofarm] dump: balloon_convert -> balloon
    Balloonat = 30, -- [Autofarm] dump: balloonat -> balloonat
    Wait = false, -- [Autofarm] dump: wait -> wait
    Waittime = 15, -- [Autofarm] dump: waittime -> waittime
    Precisestand = true, -- [Autofarm] dump: precisestand -> precisestand
    Precisestandat = 75, -- [Autofarm] dump: precisestandat -> precisestandat
    AutofarmCoconut = false, -- [Autofarm] dump: coconut_convert -> coconut
    Coconutat = 85, -- [Autofarm] dump: coconutat -> coconutat
    Instant = false, -- [Autofarm] dump: instant -> instant
    Instants = "", -- TODO: default chua xac nhan; gia tri an toan -- [Autofarm] dump: instants -> instants
    Honeymask = false, -- [Autofarm] dump: honeymask -> honeymask
    Defaultmask = "Diamond Mask", -- [Autofarm] dump: defaultmask -> defaultmask
    Festivegift = false, -- [Autofarm] dump: festivegift -> festivegift
    Convertfield = false, -- [Autofarm] dump: convertfield -> convertfield
    Balloonbag = false, -- [Autofarm] dump: balloonbag -> balloonbag
    Balloonbloat = false, -- [Autofarm] dump: balloonbloat -> balloonbloat
    Enzymes = false, -- [Autofarm] dump: enzymes -> enzymes
    Resetconvert = false, -- [Autofarm] dump: resetconvert -> resetconvert
    Guiding = false, -- [Autofarm] dump: guiding -> guiding
    Guidingfieldsbl = "", -- TODO: default chua xac nhan; gia tri an toan -- [Autofarm] dump: guidingfieldsbl -> guidingfieldsbl
    AutofarmEnabled_ = false, -- [Autofarm] dump: sprouts_enabled -> enabled
    Fieldsbl2 = "", -- TODO: default chua xac nhan; gia tri an toan -- [Autofarm] dump: fieldsbl2 -> fieldsbl2
    Raritybl = "", -- TODO: default chua xac nhan; gia tri an toan -- [Autofarm] dump: raritybl -> raritybl
    AutofarmPlant = false, -- [Autofarm] dump: plant -> plant
    Collect = true, -- [Autofarm] dump: collect -> collect
    Plantday = false, -- [Autofarm] dump: plantday -> plantday
    Plantnight = false, -- [Autofarm] dump: plantnight -> plantnight
    Amount = "", -- TODO: default chua xac nhan; gia tri an toan -- [Autofarm] dump: amount -> amount
    PlantersFarmfield = false, -- [Planters] dump: farmfield -> farmfield
    PlantersIgnoresmoking = false, -- [Planters] dump: ignoresmoking -> ignoresmoking
    Ignorefielddeg = false, -- [Planters] dump: ignorefielddeg -> ignorefielddeg
    PlantersPreset = "atlas1/default.json", -- [Planters] dump: planterpreset -> preset
    PlantersAllowedplanters = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: allowedplanters -> allowedplanters
    Blacklistedfields = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: blacklistedfields -> blacklistedfields
    PlantersHarvestatpercentage = false, -- [Planters] dump: harvestatpercentage -> harvestatpercentage
    PlantersHarvestat = 0, -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: harvestat -> harvestat
    PlantersHarvestaftertime = false, -- [Planters] dump: harvestaftertime -> harvestaftertime
    PlantersTimetoharvest = 0, -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: timetoharvest -> timetoharvest
    PlantersWindshrine = false, -- [Planters] dump: windshrine -> windshrine
    Farmwinds = false, -- [Planters] dump: farmwinds -> farmwinds
    Windsfieldsbl = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: windsfieldsbl -> windsfieldsbl
    Shrineitem = "Gumdrops", -- [Planters] dump: shrineitem -> shrineitem
    Shrineamount = 1, -- [Planters] dump: shrineamount -> shrineamount
    PlantersMaterials = false, -- [Planters] dump: materials_planter -> materials
    PlantersStacker = false, -- [Planters] dump: stacker_planter -> stacker
    Tickets = true, -- [Planters] dump: tickets -> tickets
    Discard = false, -- [Planters] dump: discard -> discard
    Printer = false, -- [Planters] dump: printer -> printer
    Printereggs = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: printereggs -> printereggs
    Hiddenstickers = true, -- [Planters] dump: hiddenstickers -> hiddenstickers
    Prog = false, -- [Planters] dump: prog -> prog
    Bqbuy = false, -- [Planters] dump: bqbuy -> bqbuy
    Dapperslots = 5, -- [Planters] dump: dapperslots -> dapperslots
    Bqdel = false, -- [Planters] dump: bqdel -> bqdel
    Realpot = false, -- [Planters] dump: realpot -> realpot
    Waxpredictor = false, -- [Planters] dump: waxpredictor -> waxpredictor
    Condenser = false, -- [Planters] dump: condenser -> condenser
    PlantersNectars = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: nectars_planter -> nectars
    Moon = false, -- [Planters] dump: moonamulet -> moon
    Star = false, -- [Planters] dump: staramulet -> star
    Rolldouble = false, -- [Planters] dump: rolldouble -> rolldouble
    Giftedbasic = false, -- [Planters] dump: giftedbasic -> giftedbasic
    Buyeggs = true, -- [Planters] dump: buyeggs -> buyeggs
    Eggsamount = 10, -- [Planters] dump: eggsamount -> eggsamount
    Buyrj = true, -- [Planters] dump: buyrj -> buyrj
    Rjamount = 100, -- [Planters] dump: rjamount -> rjamount
    PlantersRj = false, -- [Planters] dump: rj -> rj
    Rjstopgifted = false, -- [Planters] dump: rjstopgifted -> rjstopgifted
    Rjbeetypes = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: rjbeetypes -> rjbeetypes
    Rjrarity = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: rjrarity -> rjrarity
    Mutations = false, -- [Planters] dump: mutations -> mutations
    Neonberry = true, -- [Planters] dump: neonberry -> neonberry
    Feedtype = "Bitterberry", -- [Planters] dump: feedtype -> feedtype
    Feedamount = 50, -- [Planters] dump: feedamount -> feedamount
    Beetypes = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: beetypes -> beetypes
    Lvlup = false, -- [Planters] dump: lvlup -> lvlup
    Buytreats = false, -- [Planters] dump: buytreats -> buytreats
    Targetlvl = 10, -- [Planters] dump: targetlvl -> targetlvl
    PlantersEnabled = false, -- [Planters] dump: hive_enabled -> enabled
    Interrupt = true, -- [Planters] dump: interrupt -> interrupt
    Intwhitelist = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: intwhitelist -> intwhitelist
    Snowflake = false, -- [Planters] dump: snowflake -> snowflake
    Snowflakeat = 95, -- [Planters] dump: snowflakeat -> snowflakeat
    Honeymaskwreath = false, -- [Planters] dump: honeymaskwreath -> honeymaskwreath
    Coolbreeze = false, -- [Planters] dump: coolbreeze -> coolbreeze
    Beesmasfeast = false, -- [Planters] dump: beesmasfeast -> beesmasfeast
    Candles = false, -- [Planters] dump: candles -> candles
    Gingerbreadhouse = false, -- [Planters] dump: gingerbreadhouse -> gingerbreadhouse
    Onettlidart = false, -- [Planters] dump: onettlidart -> onettlidart
    Samovar = false, -- [Planters] dump: samovar -> samovar
    Stockings = false, -- [Planters] dump: stockings -> stockings
    Snowmachine = false, -- [Planters] dump: snowmachine -> snowmachine
    Gummybeacon = false, -- [Planters] dump: gummybeacon -> gummybeacon
    Gummybeacon2 = false, -- [Planters] dump: gummybeacon2 -> gummybeacon2
    Gummybeacon3 = "", -- TODO: default chua xac nhan; gia tri an toan -- [Planters] dump: gummybeacon3 -> gummybeacon3
    Beebear = false, -- [Planters] dump: beebear -> beebear
    Gummybear = false, -- [Planters] dump: gummybear -> gummybear
    Stickbug = false, -- [Planters] dump: stickbug -> stickbug
    PlantersBalloons = false, -- [Planters] dump: balloons2 -> balloons
    Gballoons = false, -- [Planters] dump: gballoons -> gballoons
    PlantersBubbles = false, -- [Planters] dump: bubbles2 -> bubbles
    Gbubbles = false, -- [Planters] dump: gbubbles -> gbubbles
    PlantersBlooms = false, -- [Planters] dump: blooms2 -> blooms
    Center = false, -- [Planters] dump: center -> center
    Fires = false, -- [Planters] dump: fires -> fires
    Refresh = false, -- [Planters] dump: refresh -> refresh
    Shiftlock = false, -- [Planters] dump: shiftlock -> shiftlock
    PlantersMethod = "Manual", -- [Planters] dump: plantermethod -> method
    Direction = "South", -- [Planters] dump: direction -> direction
    PuffshroomsEnabled = false, -- [Puffshrooms] dump: puffshrooms_enabled -> enabled
    Highlvlpriority = false, -- [Puffshrooms] dump: highlvlpriority -> highlvlpriority
    Maintain = false, -- [Puffshrooms] dump: maintain -> maintain
    PuffshroomsMin = 1, -- [Puffshrooms] dump: puffmin -> min
    Max = 15, -- [Puffshrooms] dump: puffmax -> max
    Mintime = 30, -- [Puffshrooms] dump: mintime -> mintime
    Rarity = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: puffrarity -> rarity
    PuffshroomsFieldsbl = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: pufffieldsbl -> fieldsbl
    Priorityfields = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: priorityfields -> priorityfields
    Follow = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: follow -> follow
    Followfieldsbl = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: followfieldsbl -> followfieldsbl
    Sprinkleronly = false, -- [Puffshrooms] dump: sprinkleronly -> sprinkleronly
    Badges = false, -- [Puffshrooms] dump: badges -> badges
    Badgesbl = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: badgesbl -> badgesbl
    Badgesp = "Lowest Pollen Needed", -- [Puffshrooms] dump: badgesp -> badgesp
    Badgesclaim = false, -- [Puffshrooms] dump: badgesclaim -> badgesclaim
    Demonmask = false, -- [Puffshrooms] dump: demonmask -> demonmask
    Dmwhitelist = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: dmwhitelist -> dmwhitelist
    Stingers = false, -- [Puffshrooms] dump: stingers -> stingers
    Stingers2 = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: stingers2 -> stingers2
    Starsaw = false, -- [Puffshrooms] dump: starsaw -> starsaw
    Starsaw2 = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: starsaw2 -> starsaw2
    Babylove = false, -- [Puffshrooms] dump: babylove -> babylove
    Tunnelbear = false, -- [Puffshrooms] dump: tunnelbear -> tunnelbear
    Kingbeetle = false, -- [Puffshrooms] dump: kingbeetle -> kingbeetle
    Kb = false, -- [Puffshrooms] dump: kbamulet -> kb
    Kbold = false, -- [Puffshrooms] dump: kbamuletold -> kbold
    Avoidmobs = true, -- [Puffshrooms] dump: avoidmobs -> avoidmobs
    Aphid = true, -- [Puffshrooms] dump: aphid -> aphid
    Ladybug = false, -- [Puffshrooms] dump: ladybug -> ladybug
    Beetle = false, -- [Puffshrooms] dump: beetle -> beetle
    Spider = false, -- [Puffshrooms] dump: spider -> spider
    Mantis = false, -- [Puffshrooms] dump: mantis -> mantis
    Scorpion = false, -- [Puffshrooms] dump: scorpion -> scorpion
    Werewolf = false, -- [Puffshrooms] dump: werewolf -> werewolf
    Vicious = false, -- [Puffshrooms] dump: vicious -> vicious
    Viciousdaily = false, -- [Puffshrooms] dump: viciousdaily -> viciousdaily
    Viciousgifted = false, -- [Puffshrooms] dump: viciousgifted -> viciousgifted
    Viciousignore = false, -- [Puffshrooms] dump: viciousignore -> viciousignore
    Viciousmin = 1, -- [Puffshrooms] dump: viciousmin -> viciousmin
    Viciousmax = 12, -- [Puffshrooms] dump: viciousmax -> viciousmax
    Windy = false, -- [Puffshrooms] dump: windy -> windy
    Windymin = 1, -- [Puffshrooms] dump: windymin -> windymin
    Windymax = 25, -- [Puffshrooms] dump: windymax -> windymax
    Windydegrade = false, -- [Puffshrooms] dump: windydegrade -> windydegrade
    Windymaxkills = 5, -- [Puffshrooms] dump: windymaxkills -> windymaxkills
    Vialsdonate = false, -- [Puffshrooms] dump: vialsdonate -> vialsdonate
    Vialsmin = 5, -- [Puffshrooms] dump: vialsmin -> vialsmin
    Crab = false, -- [Puffshrooms] dump: crab -> crab
    Crabmethod = "Walk", -- [Puffshrooms] dump: crabmethod -> crabmethod
    Craboil = false, -- [Puffshrooms] dump: craboil -> craboil
    Mondo = false, -- [Puffshrooms] dump: mondo -> mondo
    Lootmondo = false, -- [Puffshrooms] dump: lootmondo -> lootmondo
    Mondotime = 15, -- [Puffshrooms] dump: mondotime -> mondotime
    Mondoprep = false, -- [Puffshrooms] dump: mondoprep -> mondoprep
    Mondopreptime = 20, -- [Puffshrooms] dump: mondopreptime -> mondopreptime
    PuffshroomsAnt = false, -- [Puffshrooms] dump: ant -> ant
    PuffshroomsAntpass = false, -- [Puffshrooms] dump: antpass -> antpass
    PuffshroomsAnt_ = false, -- [Puffshrooms] dump: antamulet -> ant
    Antold = false, -- [Puffshrooms] dump: antamuletold -> antold
    PuffshroomsSnail = false, -- [Puffshrooms] dump: snail -> snail
    PuffshroomsSnail_ = false, -- [Puffshrooms] dump: snailamulet -> snail
    Snailold = false, -- [Puffshrooms] dump: snailold -> snailold
    PuffshroomsEnabled_ = true, -- [Puffshrooms] dump: autoquest_enabled -> enabled
    PuffshroomsBestbluefield = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: quest_bestbluefield -> bestbluefield
    PuffshroomsBestredfield = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: quest_bestredfield -> bestredfield
    PuffshroomsBestwhitefield = "", -- TODO: default chua xac nhan; gia tri an toan -- [Puffshrooms] dump: quest_bestwhitefield -> bestwhitefield
    PuffshroomsGoomethod = "Gumdrops", -- [Puffshrooms] dump: quest_goomethod -> goomethod
    QuestsEnabled = false, -- [Quests] dump: quest2_enabled -> enabled
    Swirled = false, -- [Quests] dump: swirled -> swirled
    Swirledp = "", -- TODO: default chua xac nhan; gia tri an toan -- [Quests] dump: swirledp -> swirledp
    Caustic = false, -- [Quests] dump: caustic -> caustic
    Causticp = "", -- TODO: default chua xac nhan; gia tri an toan -- [Quests] dump: causticp -> causticp
    Xmas = false, -- [Quests] dump: xmas -> xmas
    Xmasprio = true, -- [Quests] dump: xmasprio -> xmasprio
    Pollen = true, -- [Quests] dump: pollen -> pollen
    Goo = true, -- [Quests] dump: goo -> goo
    Mobs = true, -- [Quests] dump: mobs -> mobs
    Ants = false, -- [Quests] dump: ants -> ants
    Ragetokens = true, -- [Quests] dump: ragetokens -> ragetokens
    Puffshrooms = true, -- [Quests] dump: quest_puffshrooms -> puffshrooms
    QuestsPetals = false, -- [Quests] dump: quest_petals -> petals
    Nearblooms = false, -- [Quests] dump: nearblooms -> nearblooms
    QuestsDupedtokens = false, -- [Quests] dump: quest_dupedtokens -> dupedtokens
    QuestsWindshrine = false, -- [Quests] dump: quest_windshrine -> windshrine
    Memorymatch = true, -- [Quests] dump: quest_memorymatch -> memorymatch
    Sharebeans = false, -- [Quests] dump: sharebeans -> sharebeans
    Craft = false, -- [Quests] dump: craft -> craft
    QuestsItems = false, -- [Quests] dump: quest_items -> items
    Toys = false, -- [Quests] dump: toys -> toys
    Tools = false, -- [Quests] dump: tools -> tools
    QuestsPlanters = false, -- [Quests] dump: quest_planters -> planters
    QuestsAllowedplanters = "", -- TODO: default chua xac nhan; gia tri an toan -- [Quests] dump: quest_allowedplanters -> allowedplanters
    Bearpriority = false, -- [Quests] dump: bearpriority -> bearpriority
    QuestsHarvestatpercentage = false, -- [Quests] dump: q_harvestatpercentage -> harvestatpercentage
    QuestsHarvestat = 0, -- TODO: default chua xac nhan; gia tri an toan -- [Quests] dump: q_harvestat -> harvestat
    QuestsHarvestaftertime = false, -- [Quests] dump: q_harvestaftertime -> harvestaftertime
    QuestsTimetoharvest = 0, -- TODO: default chua xac nhan; gia tri an toan -- [Quests] dump: q_timetoharvest -> timetoharvest
    QuestsIgnoresmoking = false, -- [Quests] dump: q_ignoresmoking -> ignoresmoking
    Wintermm = false, -- [Bears] dump: wintermm -> wintermm
    Blackbear = false, -- [Bears] dump: blackbear -> blackbear
    Motherbear = false, -- [Bears] dump: motherbear -> motherbear
    Pandabear = false, -- [Bears] dump: pandabear -> pandabear
    Sciencebear = false, -- [Bears] dump: sciencebear -> sciencebear
    Dapperbear = false, -- [Bears] dump: dapperbear -> dapperbear
    Onett = false, -- [Bears] dump: onett -> onett
    Spiritbear = false, -- [Bears] dump: spiritbear -> spiritbear
    Blackbear2 = false, -- [Bears] dump: blackbear2 -> blackbear2
    Brownbear = false, -- [Bears] dump: brownbear -> brownbear
    Buckobee = false, -- [Bears] dump: buckobee -> buckobee
    Rileybee = false, -- [Bears] dump: rileybee -> rileybee
    Honeybee = false, -- [Bears] dump: honeybee -> honeybee
    Polarbear = false, -- [Bears] dump: polarbear -> polarbear
    Feedbees = false, -- [Bears] dump: feedbees -> feedbees
    Levelbees = false, -- [Bears] dump: levelbees -> levelbees
    Treats = false, -- [Bears] dump: treats -> treats
    BearsRj = false, -- [Bears] dump: rj_bears -> rj
    Rjbl = "", -- TODO: default chua xac nhan; gia tri an toan -- [Bears] dump: rjbl -> rjbl
    BearsEnabled = false, -- [Bears] dump: claim_enabled -> enabled
    Claim = "", -- TODO: default chua xac nhan; gia tri an toan -- [Bears] dump: claim -> claim
    BearsEnabled_ = false, -- [Bears] dump: questclaim_enabled -> enabled
    BearsMethod = "Manual", -- [Bears] dump: questclaim_method -> method
    BearsFarmfield = false, -- [Bears] dump: farmfield_manual -> farmfield
    BearsStopEverything = true, -- [Bears] dump: home_detected -> stop_everything
    Harvest = false, -- [Bears] dump: harvest -> harvest
    BearsPlant = false, -- [Bears] dump: plant -> plant
    BearsIgnoresmoking = false, -- [Bears] dump: planter_ignoresmoking -> ignoresmoking
    Planter = "", -- TODO: default chua xac nhan; gia tri an toan -- [Bears] dump: planterdropdown -> planter
    Honeystorm = false, -- [Bears] dump: honeystorm -> honeystorm
    Wealthclock = false, -- [Bears] dump: wealthclock -> wealthclock
    Sproutsummoner = false, -- [Bears] dump: sproutsummoner -> sproutsummoner
    Meteor = false, -- [Bears] dump: meteor -> meteor
    BearsEnabled__ = false, -- [Bears] dump: boosters_enabled -> enabled
    Allowed = "", -- TODO: default chua xac nhan; gia tri an toan -- [Bears] dump: boosters_allowed -> allowed
    BearsFieldsbl = "", -- TODO: default chua xac nhan; gia tri an toan -- [Bears] dump: boosters_fieldsbl -> fieldsbl
    Required = false, -- [Bears] dump: boosters_required -> required
    BearsMin = 1, -- [Bears] dump: boosters_min -> min
    Wanted = 1, -- [Bears] dump: wanted -> wanted
    Dicetime = 90, -- [Bears] dump: dicetime -> dicetime
    Blueberry = false, -- [Bears] dump: blueberry -> blueberry
    BearsHoney = false, -- [Bears] dump: honey_dispenser -> honey
    Strawberry = false, -- [Bears] dump: strawberry -> strawberry
    Treat = false, -- [Bears] dump: treat -> treat
    BearsCoconut = false, -- [Bears] dump: coconut_dispenser -> coconut
    BearsAntpass = false, -- [Bears] dump: antpass_buy -> antpass
    Robopass = false, -- [Bears] dump: robopass -> robopass
    Royaljelly = false, -- [Bears] dump: royaljelly -> royaljelly
    Glue = false, -- [Bears] dump: glue -> glue
    Blacklist = "", -- TODO: default chua xac nhan; gia tri an toan -- [Bears] dump: blacklist -> blacklist
    Basic = false, -- [Bears] dump: mm_basic -> basic
    Mega = false, -- [Bears] dump: mm_mega -> mega
    Night = false, -- [Bears] dump: mm_night -> night
    Extreme = false, -- [Bears] dump: mm_extreme -> extreme
    Cannon = false, -- [Movement] dump: cannon -> cannon
    Jumpshortcuts = false, -- [Movement] dump: jumpshortcuts -> jumpshortcuts
    Movement = "Walk", -- [Movement] dump: movement -> movement
    Wsenabled = false, -- [Movement] dump: wsenabled -> wsenabled
    Smartws = false, -- [Movement] dump: smartws -> smartws
    Smartcombo = true, -- [Movement] dump: smartcombo -> smartcombo
    Smartcoconut = true, -- [Movement] dump: smartcoconut -> smartcoconut
    Smartshower = true, -- [Movement] dump: smartshower -> smartshower
    Walkspeed = 45, -- [Movement] dump: walkspeed -> walkspeed
    Walkspeed2 = 90, -- [Movement] dump: walkspeed2 -> walkspeed2
    MovementTweenspeed = 6, -- [Movement] dump: tweenspeed -> tweenspeed
}

-- ban sao goc de Config.Reset
local function shallowCopy(src)
	local out = {}
	for k, v in pairs(src) do
		out[k] = v
	end
	return out
end

local PRISTINE = shallowCopy(DEFAULT_CONFIG)

-- ---------------------------------------------------------------------------
-- Config namespace: Get / Set / Save / Load / Reset (Kiwi-lite JSON)
-- ---------------------------------------------------------------------------
local Registry = {}  -- key -> { Set = fn, Kind = string, AddItem = fn? }

local Config = {}  -- khai bao truoc queueSave de closure tham chieu local, khong global

local saveQueued = false
local function queueSave()
	if saveQueued then
		return
	end
	saveQueued = true
	task.delay(0.75, function()
		saveQueued = false
		pcall(function() Config.Save() end) -- fix: chan loi lan truyen trong task
	end)
end

-- ep kieu gia tri theo default: number / boolean / string
local function coerceValue(key, value)
	local def = DEFAULT_CONFIG[key]
	if def == nil then
		return value
	end
	if type(def) == "number" then
		if type(value) == "number" then
			return value
		end
		local n = tonumber(value)
		if n then
			return n
		end
		return def
	elseif type(def) == "boolean" then
		if type(value) == "boolean" then
			return value
		end
		if value == "true" then
			return true
		end
		if value == "false" then
			return false
		end
		return def
	else
		if type(value) == "string" then
			return value
		end
		return tostring(value)
	end
end

-- fix: bo 'local Config = {}' trung lap o day. Truoc do no tao bang thu hai
-- lam queueSave (closure tham chieu bang thu nhat rong) goi Config.Save -> nil
-- call, crash ngay lan dau Config.Set kich hoat debounce. Dung dung bang
-- Config khai bao phia tren (cung scope, truoc queueSave).

function Config.Get(key)
	return DEFAULT_CONFIG[key]
end

function Config.Set(key, value, skipSave)
	if DEFAULT_CONFIG[key] == nil then
		return false, "unknown key: " .. tostring(key)
	end
	DEFAULT_CONFIG[key] = coerceValue(key, value)
	local entry = Registry[key]
	if entry and entry.Set then
		pcall(entry.Set, DEFAULT_CONFIG[key])
	end
	if not skipSave then
		queueSave()
	end
	return true
end

function Config.Save()
	local ok, data = pcall(function() return HttpService:JSONEncode(DEFAULT_CONFIG) end)
	if not ok then
		return false, "JSONEncode failed"
	end
	if not fsExists(SETTINGS_FOLDER) then
		fsMakeFolder(SETTINGS_FOLDER)
	end
	local okWrite = fsWrite(CONFIG_FILE, data)
	if not okWrite then
		return false, "writefile failed: " .. CONFIG_FILE
	end
	return true
end

-- merge config tu file; chi nhan key da ton tai trong DEFAULT_CONFIG (van hoa)
function Config.Load()
	local raw = fsRead(CONFIG_FILE)
	if not raw then
		return false, "no config file: " .. CONFIG_FILE
	end
	local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok or type(decoded) ~= "table" then
		return false, "bad json in " .. CONFIG_FILE
	end
	local count = 0
	for key, value in pairs(decoded) do
		if DEFAULT_CONFIG[key] ~= nil then
			DEFAULT_CONFIG[key] = coerceValue(key, value)
			count = count + 1
		end
	end
	for key, entry in pairs(Registry) do
		if entry and entry.Set then
			pcall(entry.Set, DEFAULT_CONFIG[key])
		end
	end
	return true, count
end

function Config.Reset()
	for key, value in pairs(PRISTINE) do
		DEFAULT_CONFIG[key] = value
	end
	for key, entry in pairs(Registry) do
		if entry and entry.Set then
			pcall(entry.Set, DEFAULT_CONFIG[key])
		end
	end
	queueSave()
	return true
end

function Config.Keys()
	local out = {}
	for key in pairs(PRISTINE) do
		out[#out + 1] = key
	end
	return out
end

function Config.File()
	return CONFIG_FILE
end

-- ---------------------------------------------------------------------------
-- Theme + helper tao Instance
-- ---------------------------------------------------------------------------
local THEME = {
	Background   = Color3.fromRGB(24, 24, 28),
	Side         = Color3.fromRGB(18, 18, 22),
	Element      = Color3.fromRGB(32, 32, 38),
	ElementHover = Color3.fromRGB(42, 42, 50),
	Text         = Color3.fromRGB(235, 235, 240),
	Dim          = Color3.fromRGB(150, 150, 160),
	Accent       = Color3.fromRGB(255, 170, 0),
	On           = Color3.fromRGB(70, 200, 120),
	Off          = Color3.fromRGB(70, 70, 80),
	Stroke       = Color3.fromRGB(45, 45, 52),
	InnerText    = Color3.fromRGB(20, 20, 20),
}

local function New(className, props)
	local inst = Instance.new(className)
	local parent = nil
	for k, v in pairs(props) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function getGuiParent()
	local okHidden, hidden = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if okHidden and hidden and typeof(hidden) == "Instance" then
		return hidden
	end
	local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if okCore and coreGui then
		return coreGui
	end
	local plr = game:GetService("Players").LocalPlayer
	local pg = plr and plr:FindFirstChildOfClass("PlayerGui")
	if pg then
		return pg
	end
	return coreGui
end

-- ---------------------------------------------------------------------------
-- Element builders (ten ham theo method UI goc cua Atlas)
-- ---------------------------------------------------------------------------
-- fix: cac connection tren UserInputService (keo slider / keo window) la
-- GLOBAL - neu khong track thi khi BuildGUI duoc goi lai (GuiRef:Destroy())
-- connection cu con song, closure van cam widget da destroy (leak + keo slider
-- tac dong len slider cu da mat). Gom lai va Disconnect khi rebuild/destroy.
local TrackedConnections = {}

local function trackConnection(conn)
	if conn then
		TrackedConnections[#TrackedConnections + 1] = conn
	end
	return conn
end

local function disconnectTrackedConnections()
	for _, conn in ipairs(TrackedConnections) do
		pcall(function() conn:Disconnect() end)
	end
	TrackedConnections = {}
end

local orderCounters = {}

local function nextOrder(container)
	local n = (orderCounters[container] or 0) + 1
	orderCounters[container] = n
	return n
end

local function newRow(container, height)
	local row = New("Frame", {
		Size = UDim2.new(1, -8, 0, height),
		BackgroundColor3 = THEME.Element,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(container),
		Parent = container,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = row })
	return row
end

local function rowLabel(row, text, rightReserve)
	return New("TextLabel", {
		Size = UDim2.new(1, -(rightReserve or 180), 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Parent = row,
	})
end

-- ToggleSwitch(key, label, default)
local function ToggleSwitch(container, key, label, default)
	if default ~= nil and DEFAULT_CONFIG[key] == nil then
		DEFAULT_CONFIG[key] = default
	end
	local row = newRow(container, 30)
	rowLabel(row, label or key, 80)
	local btn = New("TextButton", {
		Size = UDim2.new(0, 46, 1, -10),
		Position = UDim2.new(1, -54, 0, 5),
		BackgroundColor3 = THEME.Off,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.InnerText,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = btn })
	local function refresh(value)
		local on = (value == true)
		btn.Text = on and "ON" or "OFF"
		btn.BackgroundColor3 = on and THEME.On or THEME.Off
	end
	refresh(DEFAULT_CONFIG[key])
	btn.MouseButton1Click:Connect(function()
		Config.Set(key, not (DEFAULT_CONFIG[key] == true))
	end)
	Registry[key] = { Set = refresh, Kind = "ToggleSwitch" }
	return row
end

-- SetSlider(key, label, min, max, default) - buoc 1, keo thanh bar
local function SetSlider(container, key, label, min, max, default)
	min = tonumber(min) or 0
	max = tonumber(max) or 100
	if max < min then
		min, max = max, min
	end
	if default ~= nil and DEFAULT_CONFIG[key] == nil then
		DEFAULT_CONFIG[key] = default
	end
	local row = newRow(container, 40)
	local lbl = rowLabel(row, label or key, 100)
	lbl.Size = UDim2.new(1, -100, 0, 16)
	local valueLabel = New("TextLabel", {
		Size = UDim2.new(0, 90, 0, 16),
		Position = UDim2.new(1, -98, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(DEFAULT_CONFIG[key]),
		Parent = row,
	})
	local bar = New("TextButton", {
		Size = UDim2.new(1, -20, 0, 8),
		Position = UDim2.new(0, 10, 0, 24),
		BackgroundColor3 = THEME.Off,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = THEME.Accent,
		BorderSizePixel = 0,
		Parent = bar,
	})
	New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	local function refresh(value)
		local v = tonumber(value) or min
		v = math.clamp(v, min, max)
		valueLabel.Text = string.format("%d / %d", v, max)
		local alpha = (v - min) / math.max(max - min, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
	end
	refresh(DEFAULT_CONFIG[key])

	local function setVal(v)
		local n = tonumber(v) or min
		n = math.floor(n + 0.5)
		n = math.clamp(n, min, max)
		Config.Set(key, n)
	end

	local dragging = false
	local function applyFromX(x)
		local absPos = bar.AbsolutePosition.X
		local absSize = bar.AbsoluteSize.X
		if absSize <= 0 then
			return
		end
		local alpha = math.clamp((x - absPos) / absSize, 0, 1)
		setVal(min + alpha * (max - min))
	end
	trackConnection(bar.InputBegan:Connect(function(input) -- fix: track de disconnect khi rebuild
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			applyFromX(input.Position.X)
		end
	end))
	trackConnection(UserInputService.InputChanged:Connect(function(input) -- fix: track connection global
		if dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
			applyFromX(input.Position.X)
		end
	end))
	trackConnection(UserInputService.InputEnded:Connect(function(input) -- fix: track connection global
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	Registry[key] = { Set = refresh, Kind = "SetSlider" }
	return row
end

-- SetTextBox(key, label, default)
local function SetTextBox(container, key, label, default)
	if default ~= nil and DEFAULT_CONFIG[key] == nil then
		DEFAULT_CONFIG[key] = default
	end
	local row = newRow(container, 30)
	rowLabel(row, label or key, 190)
	local box = New("TextBox", {
		Size = UDim2.new(0, 160, 1, -10),
		Position = UDim2.new(1, -168, 0, 5),
		BackgroundColor3 = THEME.Background,
		Text = tostring(DEFAULT_CONFIG[key]),
		PlaceholderText = label or key,
		PlaceholderColor3 = THEME.Dim,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = THEME.Text,
		ClipsDescendants = true,
		Parent = row,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })
	box.FocusLost:Connect(function(enter)
		if enter then
			Config.Set(key, box.Text)
			box.Text = tostring(DEFAULT_CONFIG[key])
		else
			box.Text = tostring(DEFAULT_CONFIG[key]) -- fix: tra lai text theo config khi khong enter (UI khong lech gia tri)
		end
	end)
	local function refresh(value)
		box.Text = tostring(value)
	end
	Registry[key] = { Set = refresh, Kind = "SetTextBox" }
	return row
end

-- SetDropdown(key, label, items, default) + AddDropdownItem (ten method goc)
local function SetDropdown(container, key, label, items, default)
	items = items or {}
	if default ~= nil and DEFAULT_CONFIG[key] == nil then
		DEFAULT_CONFIG[key] = default
	end
	local row = newRow(container, 30)
	rowLabel(row, label or key, 200)
	local valueBtn = New("TextButton", {
		Size = UDim2.new(0, 170, 1, -10),
		Position = UDim2.new(1, -178, 0, 5),
		BackgroundColor3 = THEME.Background,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = THEME.Accent,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = tostring(DEFAULT_CONFIG[key]),
		AutoButtonColor = false,
		Parent = row,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = valueBtn })

	local list = New("Frame", {
		Size = UDim2.new(1, -8, 0, 0),
		BackgroundColor3 = THEME.Side,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5, -- fix: list phai ve TREN cac row tao sau no (ZIndexBehavior.Sibling)
		LayoutOrder = nextOrder(container),
		Parent = container,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = list })
	New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	New("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		Parent = list,
	})

	local open = false
	local function refreshListSize()
		local visibleCount = 0
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") and c.Visible then
				visibleCount = visibleCount + 1
			end
		end
		list.Size = UDim2.new(1, -8, 0, math.min(visibleCount * 24 + 10, 160))
	end

	local function AddDropdownItem(itemText)
		if type(itemText) ~= "string" or itemText == "" then
			return nil
		end
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") and c.Text == itemText then
				return c  -- da co item nay
			end
		end
		local itemBtn = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = THEME.Element,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = THEME.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = itemText,
			AutoButtonColor = false,
			Parent = list,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = itemBtn })
		itemBtn.MouseButton1Click:Connect(function()
			Config.Set(key, itemText)
			valueBtn.Text = itemText
			open = false
			list.Visible = false
		end)
		refreshListSize()
		return itemBtn
	end

	for _, item in ipairs(items) do
		AddDropdownItem(item)
	end

	valueBtn.MouseButton1Click:Connect(function()
		open = not open
		list.Visible = open
	end)

	local function refresh(value)
		valueBtn.Text = tostring(value)
	end
	Registry[key] = { Set = refresh, Kind = "SetDropdown", AddItem = AddDropdownItem }
	return { Row = row, List = list, AddDropdownItem = AddDropdownItem }
end

-- alias ten element theo giao dien de dung: Toggle / Dropdown / Slider / TextBox
local Toggle   = ToggleSwitch
local Dropdown = SetDropdown
local Slider   = SetSlider
local TextBox  = SetTextBox

-- AddDropdownItem muc module: them item cho dropdown da tao theo key config
local function AddDropdownItem(key, itemText)
	local entry = Registry[key]
	if entry and entry.AddItem then
		return entry.AddItem(itemText)
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- Danh muc item dropdown (du lieu co bang chung)
-- ---------------------------------------------------------------------------
local FIELD_ITEMS = {  -- proto 663: 17 field
	"Blue Flower Field", "Clover Field", "Dandelion Field", "Sunflower Field",
	"Mushroom Field", "Bamboo Field", "Pine Tree Forest", "Pineapple Patch",
	"Mountain Top Field", "Pumpkin Patch", "Cactus Field", "Coconut Field",
	"Stump Field", "Spider Field", "Strawberry Field", "Rose Field", "Pepper Patch",
}
local FIELD_ITEMS_NONE = { "None" }
for _, f in ipairs(FIELD_ITEMS) do
	FIELD_ITEMS_NONE[#FIELD_ITEMS_NONE + 1] = f
end
local NECTAR_ITEMS = { "Comforting", "Motivating", "Satisfying", "Refreshing", "Invigorating" } -- 612pc736-746
local RARITY_ITEMS = { "Common", "Rare", "Epic", "Legendary", "Mythic" } -- p1 pc=7572+
local MASK_ITEMS = { "Demon Mask", "Diamond Mask", "Crimson Mask", "Gummy Mask" }
local TOOL_ITEMS = { "Tide Popper", "Dark Scythe", "Gummyballer" }
local GOO_ITEMS = { "Gumdrops", "Spray" }
local METHOD_ITEMS = { "Manual", "Harvest" } -- p1 pc=1745-1749
local DIRECTION_ITEMS = { "North", "South", "East", "West" }
local SPRINKLERPOS_ITEMS = { "Center", "North", "South", "East", "West" }
local MOVE_ITEMS = { "Walk", "Tween" }

-- ---------------------------------------------------------------------------
-- Schema 11 tab (thu tu + key trung khop config_defaults.lua / config_schema.md)
-- Helper: T = ToggleSwitch, S = SetSlider, D = SetDropdown, TX = SetTextBox
-- ---------------------------------------------------------------------------
local function T(key, label)
	return { Type = "ToggleSwitch", Key = key, Label = label or key }
end
local function S(key, label, mn, mx)
	return { Type = "SetSlider", Key = key, Label = label or key, Min = mn or 0, Max = mx or 100 }
end
local function D(key, label, items)
	return { Type = "SetDropdown", Key = key, Label = label or key, Items = items or {} }
end
local function TX(key, label)
	return { Type = "SetTextBox", Key = key, Label = label or key }
end

local TABS = {
	{ Name = "Misc", Elements = {
		T("Anonymous", "Anonymous Mode"),
		T("Multiplefields", "Multiple Fields"),
		T("Mobiletoggle", "Mobile Toggle"),
		T("MiscConsole", "Console"),
		T("Autorejoin", "Auto Rejoin"),
		T("Questdone", "Stop On Quest Done"),
		T("Tokens", "Hide Tokens"),
		T("Honeytokens", "Only Hide Honey Tokens"),
		T("Particles", "Hide Particles"),
		T("MiscPrecise", "Hide Precise Tokens"),
		T("MiscDupedtokens", "Hide Duped Tokens"),
		T("MiscBlooms", "Face Blooms"),
		T("MiscMarks", "Hide Marks"),
		T("Bees", "Hide Bees"),
		T("Flowers", "Hide Flowers"),
		T("MiscBalloons", "Hide Balloons"),
		T("Decorations", "Hide Decorations"),
		T("Textures", "Remove Textures"),
		T("Norender", "No Render"),
		T("Players", "Hide Players"),
		T("Bssui", "Hide BSS UI"),
		T("Main", "Hide Main GUI"),
	}},
	{ Name = "Assist", Elements = {
		T("Fastshower", "Fast Shower"),
		T("Fastcoconut", "Fast Coconut"),
		T("Fastcombococonut", "Fast Combo Coconut"),
		T("Tprare", "TP To Rare Tokens"),
		D("Rares", "Rare Tokens"),
		T("AssistCombococonuts", "Combo Coconuts"),
		T("AssistShowers", "Showers"),
	}},
	{ Name = "Detected", Elements = {
		T("DetectedStopEverything", "Stop Everything On Home"),
		S("DetectedTweenspeed", "Panic Tween Speed", 1, 50),
		TX("Disconnectid", "Disconnect Place ID"),
		T("Disconnect", "Auto Disconnect"),
	}},
	{ Name = "RBC", Elements = {
		T("RBCEnabled", "Enable RBC"),
		D("RBCPreset", "Drive Preset"),
		D("Buydrives", "Buy Drives"),
		T("RBCMaterials", "Materials"),
		T("Quitround", "Quit Round"),
		T("Disableround", "Disable Round"),
		S("Minround", "Minimum Round", 1, 25),
		T("Buypass", "Auto Buy Robo Pass"),
		S("Passcooldown", "Pass Cooldown (s)", 0, 30),
		T("RBCPrecise", "Use Precision"),
		S("Precisemin", "Maintain 10x Precision", 1, 10),
		T("Rerollbees", "Reroll Bees"),
		S("Rerollbeesmax", "Reroll Bees Max", 1, 10),
		T("Goldcog", "Gold Cog"),
		S("Goldcogmax", "Gold Cog Max", 1, 10),
		T("Boosters", "Boosters"),
		T("Boostersrbc", "Boosters In RBC"),
		S("Boostersround", "Boosters Round", 1, 30),
		T("RBCStacker", "Stacker"),
		T("Stackerrbc", "Stacker In RBC"),
		S("Stackerround", "Stacker Round", 1, 30),
		D("RBCBestbluefield", "Best Blue Field", FIELD_ITEMS),
		D("RBCBestredfield", "Best Red Field", FIELD_ITEMS),
		D("RBCBestwhitefield", "Best White Field", FIELD_ITEMS),
		D("RBCGoomethod", "Goo Method", GOO_ITEMS),
		T("Homepage", "Auto Homepage"),
		S("Homepagemin", "Homepage Min Round", 1, 10),
		T("Highestcog", "Highest Cog"),
		T("Cogconvert", "Convert Cogs"),
		S("Highestcogmax", "Highest Cog Max", 1, 10),
		T("Rerollquests", "Reroll Quests"),
		S("Rerollquestsmin", "Reroll Quests Min", 1, 25),
		T("Cogupgrades", "Cog Upgrades"),
		T("Rerollupgrades", "Reroll Upgrades"),
		S("Rerollupgradesmax", "Reroll Upgrades Max", 1, 10),
		T("Upgrades", "Upgrades"),
		T("Mask", "Auto Mask"),
		S("Maskmin", "Mask Min Round", 1, 10),
		D("Bluemask", "Blue Mask", MASK_ITEMS),
		D("Redmask", "Red Mask", MASK_ITEMS),
		D("Whitemask", "White Mask", MASK_ITEMS),
		T("Tool", "Auto Tool"),
		S("Toolmin", "Tool Min Round", 1, 10),
		D("Bluetool", "Blue Tool", TOOL_ITEMS),
		D("Redtool", "Red Tool", TOOL_ITEMS),
		D("Whitetool", "White Tool", TOOL_ITEMS),
		T("Cog", "Auto Cog Amulet"),
		T("Cogold", "Auto Cog Amulet (Old)"),
	}},
	{ Name = "Webhook", Elements = {
		T("Webhook", "Main Webhook"),
		T("Inventory", "Send Inventory"),
		T("WebhookEnabled", "Enable Webhook"),
		S("Interval", "Interval (minutes)", 1, 120),
		TX("Url", "Webhook URL"),
		T("WebhookBalloon", "Send Balloon"),
		T("WebhookNectars", "Send Nectars"),
		T("WebhookPlanters", "Send Planters"),
		T("WebhookItems", "Send Items"),
		T("WebhookConsole", "Send Console"),
		T("Stickers", "Send Stickers"),
		T("Beequips", "Send Beequips"),
		T("Drives", "Send Drives"),
		T("Dappershop", "Send Dapper Shop"),
		T("Graph", "Enable Graph"),
		TX("Graphurl", "Graph URL"),
		T("Dashboard", "Enable Dashboard"),
		TX("Key", "Key"),
	}},
	{ Name = "Autofarm", Elements = {
		T("AutofarmEnabled", "Enable Autofarm"),
		D("Field1", "Field 1", FIELD_ITEMS_NONE),
		D("Field2", "Field 2", FIELD_ITEMS_NONE),
		D("Field3", "Field 3", FIELD_ITEMS_NONE),
		S("Fieldinterval", "Field Interval (min)", 1, 60),
		T("Sprinklers", "Use Sprinklers"),
		T("Autodig", "Auto Dig"),
		T("Scorching", "Scorching Star"),
		S("Scorchingscore", "Scorching Score", 0, 100),
		T("Xflame", "Minimum Scorching Tokens To Line Up"),
		S("Xflametokens", "X-Flame Tokens", 0, 50),
		T("Pop", "Pop Star"),
		T("Gummy", "Gummy Star"),
		T("AutofarmBlooms", "Farm Blooms"),
		T("AutofarmPetals", "Farm Petals"),
		T("AutofarmBubbles", "Farm Bubbles"),
		T("Coconuts", "Farm Coconuts"),
		T("AutofarmCombococonuts", "Combo Coconuts"),
		S("Comboamount", "Combo Amount", 1, 200),
		T("Combofield", "Combo In Field"),
		T("AutofarmDupedtokens", "Farm Duped Tokens"),
		T("Smileyboosts", "Smiley Boosts"),
		T("Flames", "Farm Flames"),
		T("Fuzzbombs", "Farm Fuzzbombs"),
		T("Leaves", "Farm Leaves"),
		T("AutofarmMarks", "Farm Marks"),
		T("AutofarmPrecise", "Farm Precise"),
		T("Precisemark", "Precise Mark"),
		T("Precisemarkstand", "Precise Mark Stand"),
		T("AutofarmShowers", "Farm Showers"),
		T("Clouds", "Farm Clouds"),
		T("AutofarmBalloons", "Farm Balloons"),
		T("Ignorehoney", "Ignore Honey Tokens"),
		D("Priority", "Token Priority"),
		D("Dupedtokens2", "Duped Tokens Filter"),
		D("Sprinklerpos", "Sprinkler Position", SPRINKLERPOS_ITEMS),
		T("AutofarmHoney", "Convert Honey At"),
		S("Honeyat", "Convert Honey At %", 0, 100),
		T("AutofarmBalloon", "Convert With Balloon"),
		S("Balloonat", "Balloon Convert At %", 0, 100),
		T("Wait", "Wait Before Convert"),
		S("Waittime", "Wait Time (s)", 0, 60),
		T("Precisestand", "Precise Stand"),
		S("Precisestandat", "Precise Stand At %", 0, 100),
		T("AutofarmCoconut", "Use Coconut To Convert"),
		S("Coconutat", "Use Coconut At Percentage", 0, 100),
		T("Instant", "Instant Conversion"),
		D("Instants", "Instants Filter"),
		T("Honeymask", "Honey Mask"),
		D("Defaultmask", "Default Mask", MASK_ITEMS),
		T("Festivegift", "Festive Gift"),
		T("Convertfield", "Convert In Field"),
		T("Balloonbag", "Require Balloon Bag"),
		T("Balloonbloat", "Require Max Bubble Bloat"),
		T("Enzymes", "Use Enzymes"),
		T("Resetconvert", "Reset When Converting"),
		T("Guiding", "Guiding Star Settings"),
		D("Guidingfieldsbl", "Guiding Fields Blacklist", FIELD_ITEMS),
		T("AutofarmEnabled_", "Enable Sprouts"),
		D("Fieldsbl2", "Sprout Fields Blacklist", FIELD_ITEMS),
		D("Raritybl", "Sprout Rarity Blacklist", RARITY_ITEMS),
		T("AutofarmPlant", "Auto Plant Sprouts"),
		T("Collect", "Auto Collect Sprouts"),
		T("Plantday", "Plant Day Only"),
		T("Plantnight", "Plant Night Only"),
		TX("Amount", "Sprout Amount"),
	}},
	{ Name = "Planters", Elements = {
		T("PlantersFarmfield", "Farm In Field"),
		T("PlantersIgnoresmoking", "Don't Harvest Smoking"),
		T("Ignorefielddeg", "Ignore Field Degradation"),
		D("PlantersPreset", "Planter Preset", { "atlas1/default.json" }),
		D("PlantersAllowedplanters", "Allowed Planters"),
		D("Blacklistedfields", "Blacklisted Fields", FIELD_ITEMS),
		T("PlantersHarvestatpercentage", "Harvest At Percentage"),
		S("PlantersHarvestat", "Harvest At %", 0, 100),
		T("PlantersHarvestaftertime", "Harvest After Time"),
		S("PlantersTimetoharvest", "Time To Harvest (hours)", 0, 24),
		T("PlantersWindshrine", "Do Wind Shrine"),
		T("Farmwinds", "Farm Winds"),
		D("Windsfieldsbl", "Winds Fields Blacklist", FIELD_ITEMS),
		TX("Shrineitem", "Shrine Item"),
		TX("Shrineamount", "Shrine Amount"),
		T("PlantersMaterials", "Materials"),
		T("PlantersStacker", "Stacker"),
		T("Tickets", "Tickets"),
		T("Discard", "Discard"),
		T("Printer", "Printer"),
		D("Printereggs", "Printer Eggs"),
		T("Hiddenstickers", "Hidden Stickers"),
		T("Prog", "Progress"),
		T("Bqbuy", "BQ Buy"),
		S("Dapperslots", "Dapper Slots", 1, 10),
		T("Bqdel", "BQ Delete"),
		T("Realpot", "Real Pot"),
		T("Waxpredictor", "Show Wax Predictor"),
		T("Condenser", "Condenser"),
		D("PlantersNectars", "Nectars", NECTAR_ITEMS),
		T("Moon", "Auto Moon Amulet"),
		T("Star", "Configure Amulet/Star Amulet"),
		T("Rolldouble", "Roll Double"),
		T("Giftedbasic", "Auto Gifted Basic Bee"),
		T("Buyeggs", "Buy Eggs"),
		S("Eggsamount", "Eggs Amount", 1, 50),
		T("Buyrj", "Buy Royal Jelly"),
		S("Rjamount", "RJ Amount", 1, 250),
		T("PlantersRj", "Use Royal Jelly"),
		T("Rjstopgifted", "Stop On Any Gifted"),
		D("Rjbeetypes", "Allowed Bees To RJ"),
		D("Rjrarity", "RJ Rarity", RARITY_ITEMS),
		T("Mutations", "Mutations"),
		T("Neonberry", "Neonberry"),
		D("Feedtype", "Feed Type"),
		S("Feedamount", "Feed Amount", 1, 100),
		D("Beetypes", "Bee Types"),
		T("Lvlup", "Auto Level Up Hive"),
		T("Buytreats", "Buy Treats"),
		S("Targetlvl", "Target Level", 1, 25),
		T("PlantersEnabled", "Enable Hive Helpers"),
		T("Interrupt", "Interrupt Farming"),
		D("Intwhitelist", "Interrupt Whitelist"),
		T("Snowflake", "Use Snowflake"),
		S("Snowflakeat", "Use Snowflake At Percentage", 0, 100),
		T("Honeymaskwreath", "Honey Mask Wreath"),
		T("Coolbreeze", "Cool Breeze"),
		T("Beesmasfeast", "Auto Beesmas Feast"),
		T("Candles", "Auto Candles"),
		T("Gingerbreadhouse", "Auto Gingerbread House"),
		T("Onettlidart", "Onett Lid Art"),
		T("Samovar", "Samovar"),
		T("Stockings", "Auto Stockings"),
		T("Snowmachine", "Snow Machine"),
		T("Gummybeacon", "Gummy Beacon"),
		T("Gummybeacon2", "Gummy Beacon 2"),
		D("Gummybeacon3", "Gummy Beacon 3"),
		T("Beebear", "Auto Bee Bear"),
		T("Gummybear", "Auto Gummy Bear"),
		T("Stickbug", "Auto Stick Bug"),
		T("PlantersBalloons", "Farm Balloons"),
		T("Gballoons", "Farm Gifted Balloons"),
		T("PlantersBubbles", "Farm Bubbles"),
		T("Gbubbles", "Farm Gifted Bubbles"),
		T("PlantersBlooms", "Farm Blooms"),
		T("Center", "Center"),
		T("Fires", "Farm Fires"),
		T("Refresh", "Refresh"),
		T("Shiftlock", "Shiftlock"),
		D("PlantersMethod", "Planter Method", METHOD_ITEMS),
		D("Direction", "Direction", DIRECTION_ITEMS),
	}},
	{ Name = "Puffshrooms", Elements = {
		T("PuffshroomsEnabled", "Enable Puffshrooms"),
		T("Highlvlpriority", "High Level Priority"),
		T("Maintain", "Maintain Puffshrooms"),
		S("PuffshroomsMin", "Min Level", 1, 15),
		S("Max", "Max Level", 1, 15),
		S("Mintime", "Min Time (s)", 0, 120),
		D("Rarity", "Rarity"),
		D("PuffshroomsFieldsbl", "Fields Blacklist", FIELD_ITEMS),
		D("Priorityfields", "Priority Fields", FIELD_ITEMS),
		D("Follow", "Follow"),
		D("Followfieldsbl", "Follow Fields Blacklist", FIELD_ITEMS),
		T("Sprinkleronly", "Sprinkler Only"),
		T("Badges", "Farm Badges"),
		D("Badgesbl", "Badges Blacklist", FIELD_ITEMS),
		D("Badgesp", "Badges Priority", { "Lowest Pollen Needed" }),
		T("Badgesclaim", "Auto Claim Badges"),
		T("Demonmask", "Demon Mask"),
		D("Dmwhitelist", "Demon Mask Whitelist", FIELD_ITEMS),
		T("Stingers", "Stingers"),
		D("Stingers2", "Stingers Filter"),
		T("Starsaw", "Star Saw"),
		D("Starsaw2", "Star Saw Filter"),
		T("Babylove", "Baby Love"),
		T("Tunnelbear", "Auto Tunnel Bear"),
		T("Kingbeetle", "Auto King Beetle"),
		T("Kb", "King Beetle Amulet"),
		T("Kbold", "King Beetle Amulet (Old)"),
		T("Avoidmobs", "Avoid Mobs"),
		T("Aphid", "Auto Kill Aphid"),
		T("Ladybug", "Auto Kill Ladybug"),
		T("Beetle", "Auto Kill Beetle"),
		T("Spider", "Auto Kill Spider"),
		T("Mantis", "Auto Kill Mantis"),
		T("Scorpion", "Auto Kill Scorpion"),
		T("Werewolf", "Auto Kill Werewolf"),
		T("Vicious", "Auto Vicious Bee"),
		T("Viciousdaily", "Vicious Daily"),
		T("Viciousgifted", "Vicious Gifted Only"),
		T("Viciousignore", "Vicious Ignore Windy"),
		S("Viciousmin", "Vicious Min Level", 1, 12),
		S("Viciousmax", "Vicious Max Level", 1, 12),
		T("Windy", "Auto Windy Bee"),
		S("Windymin", "Windy Min Level", 1, 25),
		S("Windymax", "Windy Max Level", 1, 25),
		T("Windydegrade", "Windy Degrade"),
		S("Windymaxkills", "Windy Max Kills", 1, 10),
		T("Vialsdonate", "Donate Vials"),
		S("Vialsmin", "Vials Min", 1, 20),
		T("Crab", "Auto Crab"),
		D("Crabmethod", "Crab Method", MOVE_ITEMS),
		T("Craboil", "Crab With Oil"),
		T("Mondo", "Auto Mondo"),
		T("Lootmondo", "Loot Mondo"),
		S("Mondotime", "Mondo Time (s)", 0, 60),
		T("Mondoprep", "Mondo Prep"),
		S("Mondopreptime", "Mondo Prep Time (s)", 0, 60),
		T("PuffshroomsAnt", "Auto Ant Challenge"),
		T("PuffshroomsAntpass", "Auto Ant Pass"),
		T("PuffshroomsAnt_", "Ant Amulet"),
		T("Antold", "Ant Amulet (Old)"),
		T("PuffshroomsSnail", "Auto Stump Snail"),
		T("PuffshroomsSnail_", "Snail Amulet"),
		T("Snailold", "Snail Amulet (Old)"),
		T("PuffshroomsEnabled_", "Enable Auto Quest"),
		D("PuffshroomsBestbluefield", "Best Blue Field", FIELD_ITEMS),
		D("PuffshroomsBestredfield", "Best Red Field", FIELD_ITEMS),
		D("PuffshroomsBestwhitefield", "Best White Field", FIELD_ITEMS),
		D("PuffshroomsGoomethod", "Goo Method", GOO_ITEMS),
	}},
	{ Name = "Quests", Elements = {
		T("QuestsEnabled", "Enable Quests"),
		T("Swirled", "Swirled Wax"),
		D("Swirledp", "Swirled Planter"),
		T("Caustic", "Caustic Wax"),
		D("Causticp", "Caustic Planter"),
		T("Xmas", "Do Xmas Quests"),
		T("Xmasprio", "Prioritise Xmas Quests"),
		T("Pollen", "Pollen Objectives"),
		T("Goo", "Goo Objectives"),
		T("Mobs", "Mob Objectives"),
		T("Ants", "Farm Ants"),
		T("Ragetokens", "Rage Tokens"),
		T("Puffshrooms", "Puffshroom Objectives"),
		T("QuestsPetals", "Petal Objectives"),
		T("Nearblooms", "Near Blooms"),
		T("QuestsDupedtokens", "Duped Token Objectives"),
		T("QuestsWindshrine", "Wind Shrine Objectives"),
		T("Memorymatch", "Memory Match Objectives"),
		T("Sharebeans", "Share Beans"),
		T("Craft", "Craft Objectives"),
		T("QuestsItems", "Item Objectives"),
		T("Toys", "Toy Objectives"),
		T("Tools", "Tool Objectives"),
		T("QuestsPlanters", "Planter Objectives"),
		D("QuestsAllowedplanters", "Allowed Planters"),
		T("Bearpriority", "Prioritise Bears"),
		T("QuestsHarvestatpercentage", "Harvest At Percentage"),
		S("QuestsHarvestat", "Harvest At %", 0, 100),
		T("QuestsHarvestaftertime", "Harvest After Time"),
		S("QuestsTimetoharvest", "Time To Harvest (hours)", 0, 24),
		T("QuestsIgnoresmoking", "Don't Harvest Smoking"),
	}},
	{ Name = "Bears", Elements = {
		T("Wintermm", "Winter Memory Match"),
		T("Blackbear", "Auto Black Bear"),
		T("Motherbear", "Auto Mother Bear"),
		T("Pandabear", "Auto Panda Bear"),
		T("Sciencebear", "Auto Science Bear"),
		T("Dapperbear", "Auto Dapper Bear"),
		T("Onett", "Auto Onett"),
		T("Spiritbear", "Auto Spirit Bear"),
		T("Blackbear2", "Auto Black Bear 2"),
		T("Brownbear", "Auto Brown Bear"),
		T("Buckobee", "Auto Bucko Bee"),
		T("Rileybee", "Auto Riley Bee"),
		T("Honeybee", "Auto Honey Bee"),
		T("Polarbear", "Auto Polar Bear"),
		T("Feedbees", "Feed Bees"),
		T("Levelbees", "Level Bees"),
		T("Treats", "Buy Treats"),
		T("BearsRj", "Use Royal Jelly"),
		D("Rjbl", "RJ Blacklist"),
		T("BearsEnabled", "Enable Claim Rewards"),
		D("Claim", "Claim"),
		T("BearsEnabled_", "Enable Quest Claim"),
		D("BearsMethod", "Claim Method", METHOD_ITEMS),
		T("BearsFarmfield", "Farm In Field"),
		T("BearsStopEverything", "Stop Everything On Home"),
		T("Harvest", "Auto Harvest"),
		T("BearsPlant", "Auto Plant"),
		T("BearsIgnoresmoking", "Don't Harvest Smoking"),
		D("Planter", "Planter"),
		T("Honeystorm", "Auto Honeystorm"),
		T("Wealthclock", "Auto Wealth Clock"),
		T("Sproutsummoner", "Sprout Summoner"),
		T("Meteor", "Mythic Meteor Shower"),
		T("BearsEnabled__", "Auto Boosters"),
		D("Allowed", "Allowed Boosters"),
		D("BearsFieldsbl", "Boosters Fields Blacklist", FIELD_ITEMS),
		T("Required", "Require Boosts"),
		S("BearsMin", "Boosts Required For Smiley", 1, 10),
		S("Wanted", "Wanted Boosts", 1, 10),
		S("Dicetime", "Dice Time (s)", 10, 300),
		T("Blueberry", "Blueberry Dispenser"),
		T("BearsHoney", "Honey Dispenser"),
		T("Strawberry", "Strawberry Dispenser"),
		T("Treat", "Treat Dispenser"),
		T("BearsCoconut", "Coconut Dispenser"),
		T("BearsAntpass", "Free Ant Pass Dispenser"),
		T("Robopass", "Free Robo Pass Dispenser"),
		T("Royaljelly", "Free Royal Jelly Dispenser"),
		T("Glue", "Glue Dispenser"),
		D("Blacklist", "Hive Blacklist", FIELD_ITEMS),
		T("Basic", "Basic Memory Match"),
		T("Mega", "Mega Memory Match"),
		T("Night", "Night Memory Match"),
		T("Extreme", "Extreme Memory Match"),
	}},
	{ Name = "Movement", Elements = {
		T("Cannon", "Auto Cannon"),
		T("Jumpshortcuts", "Jump Shortcuts"),
		D("Movement", "Movement Method", MOVE_ITEMS),
		T("Wsenabled", "Custom Walk Speed"),
		T("Smartws", "Smart Walk Speed"),
		T("Smartcombo", "Smart Combo"),
		T("Smartcoconut", "Smart Coconut"),
		T("Smartshower", "Smart Shower"),
		S("Walkspeed", "Walk Speed", 1, 200),
		S("Walkspeed2", "Walk Speed 2", 1, 200),
		S("MovementTweenspeed", "Tween Speed", 1, 50),
	}},
}

-- ---------------------------------------------------------------------------
-- Build tab + window
-- ---------------------------------------------------------------------------
local function buildElement(container, desc)
	local key = desc.Key
	if DEFAULT_CONFIG[key] == nil then
		return nil  -- key khong ton tai trong defaults -> bo qua
	end
	if desc.Type == "ToggleSwitch" then
		return ToggleSwitch(container, key, desc.Label)
	elseif desc.Type == "SetSlider" then
		return SetSlider(container, key, desc.Label, desc.Min, desc.Max)
	elseif desc.Type == "SetDropdown" then
		return SetDropdown(container, key, desc.Label, desc.Items)
	elseif desc.Type == "SetTextBox" then
		return SetTextBox(container, key, desc.Label)
	end
	return nil
end

local function buildTabContent(tabDef, parent)
	local scroll = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		Visible = false,
		Parent = parent,
	})
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	New("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 8),
		Parent = scroll,
	})
	for _, desc in ipairs(tabDef.Elements) do
		pcall(buildElement, scroll, desc)
	end
	return scroll
end

local GuiRef = nil

local function BuildGUI()
	if GuiRef then
		disconnectTrackedConnections() -- fix: ngat connection UIS cua lan build truoc
		pcall(function() GuiRef:Destroy() end)
		GuiRef = nil
	end
	-- nap config luu truoc khi dung UI (element doc gia tri khi build)
	pcall(function() Config.Load() end)

	local gui = New("ScreenGui", {
		Name = WINDOW_TITLE,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		IgnoreGuiInset = true,
		Parent = getGuiParent(),
	})
	GuiRef = gui
	trackConnection(gui.Destroying:Connect(disconnectTrackedConnections)) -- fix: gui bi destroy tu ben ngoai cung ngat connection

	-- nut thu nho / mo
	local toggleBtn = New("TextButton", {
		Size = UDim2.new(0, 70, 0, 26),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = THEME.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = THEME.InnerText,
		Text = "Atlas",
		AutoButtonColor = false,
		Parent = gui,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = toggleBtn })

	-- cua so chinh
	local main = New("Frame", {
		Size = UDim2.new(0, 640, 0, 440),
		Position = UDim2.new(0.5, -320, 0.5, -220),
		BackgroundColor3 = THEME.Background,
		BorderSizePixel = 0,
		Active = true,
		Parent = gui,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = main })
	New("UIStroke", { Color = THEME.Stroke, Thickness = 1, Parent = main })

	-- title bar + keo di
	local titleBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Side,
		BorderSizePixel = 0,
		Parent = main,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = titleBar })
	New("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = THEME.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = WINDOW_TITLE,
		Parent = titleBar,
	})
	local closeBtn = New("TextButton", {
		Size = UDim2.new(0, 26, 0, 26),
		Position = UDim2.new(1, -32, 0, 3),
		BackgroundColor3 = THEME.Element,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = THEME.Text,
		Text = "X",
		AutoButtonColor = false,
		Parent = titleBar,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = closeBtn })
	closeBtn.MouseButton1Click:Connect(function()
		main.Visible = false
	end)

	local dragging = false
	local dragStart = nil
	local startPos = nil
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	trackConnection(UserInputService.InputChanged:Connect(function(input) -- fix: track connection global
		if dragging and dragStart
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))
	trackConnection(UserInputService.InputEnded:Connect(function(input) -- fix: track connection global
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	-- cot tab ben trai
	local side = New("Frame", {
		Position = UDim2.new(0, 0, 0, 32),
		Size = UDim2.new(0, 150, 1, -62),
		BackgroundColor3 = THEME.Side,
		BorderSizePixel = 0,
		Parent = main,
	})
	New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side })
	New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 4), Parent = side })

	-- vung content ben phai
	local contentHolder = New("Frame", {
		Position = UDim2.new(0, 150, 0, 32),
		Size = UDim2.new(1, -150, 1, -62),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = main,
	})

	-- footer: trang thai + Save/Load/Reset
	local footer = New("Frame", {
		Position = UDim2.new(0, 0, 1, -30),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = THEME.Side,
		BorderSizePixel = 0,
		Parent = main,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = footer })
	local statusLabel = New("TextLabel", {
		Size = UDim2.new(1, -250, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = THEME.Dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = CONFIG_FILE,
		Parent = footer,
	})
	local function footerButton(text, xoff, width)
		local btn = New("TextButton", {
			Position = UDim2.new(0, xoff, 0, 4),
			Size = UDim2.new(0, width, 0, 22),
			BackgroundColor3 = THEME.Element,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = THEME.Text,
			Text = text,
			AutoButtonColor = false,
			Parent = footer,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })
		return btn
	end
	local saveBtn = footerButton("Save", 410, 66)
	local loadBtn = footerButton("Load", 482, 66)
	local resetBtn = footerButton("Reset", 554, 66)
	saveBtn.MouseButton1Click:Connect(function()
		local ok = Config.Save()
		statusLabel.Text = ok and ("Saved: " .. CONFIG_FILE) or "Save FAILED"
	end)
	loadBtn.MouseButton1Click:Connect(function()
		local ok, count = Config.Load()
		statusLabel.Text = ok and ("Loaded " .. tostring(count) .. " keys") or "Load FAILED"
	end)
	resetBtn.MouseButton1Click:Connect(function()
		Config.Reset()
		statusLabel.Text = "Config reset to defaults"
	end)

	-- nut tab
	local tabButtons = {}
	local tabFrames = {}
	for _, tabDef in ipairs(TABS) do
		local btn = New("TextButton", {
			Size = UDim2.new(1, -8, 0, 28),
			BackgroundColor3 = THEME.Element,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = THEME.Text,
			Text = tabDef.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			Parent = side,
		})
		New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
		New("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = btn })
		tabButtons[tabDef.Name] = btn
		btn.MouseButton1Click:Connect(function()
			if not tabFrames[tabDef.Name] then
				tabFrames[tabDef.Name] = buildTabContent(tabDef, contentHolder)
			end
			for name, b in pairs(tabButtons) do
				local active = (name == tabDef.Name)
				b.BackgroundColor3 = active and THEME.Accent or THEME.Element
				b.TextColor3 = active and THEME.InnerText or THEME.Text
			end
			for name, f in pairs(tabFrames) do
				f.Visible = (name == tabDef.Name)
			end
		end)
	end

	toggleBtn.MouseButton1Click:Connect(function()
		main.Visible = not main.Visible
	end)

	-- mo tab dau tien
	local firstTab = TABS[1]
	if firstTab then
		tabFrames[firstTab.Name] = buildTabContent(firstTab, contentHolder)
		local btn = tabButtons[firstTab.Name]
		if btn then
			btn.BackgroundColor3 = THEME.Accent
			btn.TextColor3 = THEME.InnerText
		end
		tabFrames[firstTab.Name].Visible = true
	end

	return gui
end

-- ---------------------------------------------------------------------------
-- Module export
-- ---------------------------------------------------------------------------
return {
	Config = Config,
	Build = BuildGUI,
	TABS = TABS,
	Registry = Registry,
	DEFAULT_CONFIG = PRISTINE,
	Toggle = Toggle,
	Dropdown = Dropdown,
	Slider = Slider,
	TextBox = TextBox,
	ToggleSwitch = ToggleSwitch,
	SetDropdown = SetDropdown,
	SetSlider = SetSlider,
	SetTextBox = SetTextBox,
	AddDropdownItem = AddDropdownItem,
}

end)()

-- ================= MAIN ENTRY =================
if game.PlaceId ~= 1537690962 then
    warn("[Atlas] Sai game - PlaceId=" .. tostring(game.PlaceId) .. ", can Bee Swarm Simulator (1537690962)")
    return
end
_G.AtlasAPI = API
local ok, err = pcall(function()
    AtlasGUI.Build()
end)
if ok then
    print("[Atlas v1.2] GUI da khoi tao thanh cong. Config: atlas1/default.json")
else
    warn("[Atlas] Loi khoi tao GUI: " .. tostring(err))
end
