-- ============================================================================
--  THROW FOOD FOR ANIMALS — MAIN FARM SCRIPT (v2.0, TUTORIAL-FIRST + FSM)
--  PlaceId: 120219252362013 | PlaceVersion 1221 (file .rbxl ngay 07/11/2026)
--  Chay bang Delta (LocalScript). Chi tu dong hoa thao tac nguoi choi van lam
--  bang tay (di toi cho, bam nut game ve ra, bam dung luc meter cao).
--
--  v2.0 VIET LAI TOAN BO SAU KHI 22 AGENT NGHIEN CUU (07/11/2026):
--  * Phat hien goc so 0: Brian chay nham ban v1.0 cu (log in "v1.0-gui-first"),
--    nen 3 fix cua v1.0.1 chua bao gio duoc chay. V2.0 in "v2.0" o boot print
--    de nhan dien ngay. HAY CHAC CHAN DANG CHAY FILE NAY (xem dong boot).
--  * Di chuyen: Humanoid:MoveTo chi di thang, tu ngat sau 8 GIAY, va check
--    toi noi bang khoang cach 3D < 3 KHONG BAO GIO dung vi HumanoidRootPart
--    khi dung cao hon mat dat ~3 studs (dich Y=2 -> cach toi thieu 3.5).
--    => Doi sang PathfindingService (tu tim duong vong vat can) + check toi
--    noi chi theo XZ + do ket theo "khoang cach toi dich khong giam" (nhay
--    len xuong theo Y khong con duoc tinh la tien nua).
--  * Dich Sell/FoodShop dung Y cua ZonePad lo lung (~8.5) thay vi vong
--    ActivationCircle tren mat dat (~2.5-2.6) => doi Y ve mat dat.
--  * goThrowLine xoay 180 do lam nhan vat quay lung ve biome (nhin ve +Z,
--    lobby) => BO xoay, dung nhin thang ve -Z (huong biome).
--  * Nem: cu cham dau tien CHINH LA cu nem (meter chay ngay khi vao zone),
--    nen bo cham "bat dau nem"; doi "TAP TO THROW" hien roi moi poll meter.
--    Meter doc bang so TextLabel la sai: meter that la thanh + mui ten chay;
--    so chi hien SAU khi nem ("+17 POWER"). => Doc fill Frame (ti le 0-1),
--    chi tin label so nao THAY DOI theo thoi gian.
--  * Tap luyen: xA KHOA cho toi khi xong tutorial; tap tu dong khi dung tren
--    pad; thoat bang nut STOP do trong UI (khong phai remote); tap bonus chi
--    bam dung nut popup, moi popup 1 lan.
--  * Thu tu game day: NEM (Carrot free, da equip san) -> NHAT -> DAT PLOT
--    -> MUA FOOD -> roi moi TAP XA. Vong cu tap truoc la nguoc game.
--  * Mua do: Shop chi hien 3 mon (1 da co + 2 tiep theo); nut BUY dau tien
--    tim duoc gan nhu chac chan la mon KHAC => mua theo THE (tim the theo
--    ten mon roi bam nut trong dung the do). Carrot gia 0 / da so huu => di
--    nhanh EQUIP, khong di nhanh BUY (vong cu bam BUY cua Apple $30 khi $0
--    roi lap vo han). Khong co hop xac nhan YES khi mua (mua xong bao
--    "Bought Apple!" roi bam EQUIP).
--  * Ban: nut Animals tren HUD la ImageButton icon chan thu KHONG CO TEXT
--    => tim bang Text khong bao gio thay => EQUIP BEST khong chay => ban
--    mat ca thu ngon trong Backpack. => Tim nut theo anh/icon. Sau SELL ALL
--    co hop xac nhan "Sell N animals for $X?" phai bam them 1 lan nua.
--  * Nhat thu: thu spawn trong biome roi DI BO toi cho do an; phai doi the
--    reveal (NEW! / ten loai / $/s) roi moi di; di toi DIEM ROI TINH va doi
--    thu toi, khong duoi theo thu dang di; timeout ti le theo khoang cach.
--  * He so size that (do tu billboard + allthings.how, khop nhau): Big 2.08x,
--    Large 4.31x, Huge 8.94x (cap so nhan ~2.07), KHONG phai bang cu cua PGG
--    (1.5x/2.25x/3.38x). Mutation dung (Gold 1.5x, Diamond 3x, Emerald 5x,
--    Ruby 10x, Rainbow 20x). Stack NHAN, khong cong. Quyet dinh giu/ban chi
--    dung $/s do live.
--  * Gia 42 mon da du (GameRant 06/11 + NerdsChalk 02/11): Shank $6.8T
--    (khong phai $618T), Fillet $57T, Phoenix Fillet $4Sx (khong phai $35Sx),
--    Caramel Apple $250Oc (khong phai $250Qc), Uranium Cake $9Qad (1 nguon).
--  * Plot: OwnerTag moi la tin hieu chinh (TrainingRig chi co khi dang tap);
--    so sanh chinh xac (khong chuoi con); thu lai khi chua load xong.
--  * Remote: BO Plot_SellAll khoi allowlist (recon cam probe no vi ban la
--    hanh dong pha huy; chi mo lai khi co bang chung hook). Them
--    Animations_Get (probe read-only dau tien) va Shop_ClaimFree vao nhom A.
--  * Trung: trung Halloween 80 Robux, event da het 01/11; Ring Rush khong
--    tu dong duoc bang GUI; Gift bo han. AutoEgg/AutoRingRush la config
--    chet o v1.x => XOA.
--  * Giong nguoi: muc tieu meter boc ngau nhien moi lan nem (65% 19-20,
--    25% 17-18, 10% 15-16/ho), tre phan ung 0.08-0.35s, click lech tam nut,
--    delay phan phoi tam giac, gioi han phien 60 phut + nghi 10-20 phut,
--    teleport toi da 3-5 lan/gio. KHONG BAO DAM khong bi ban — chi giam rui ro.
--
--  NGUYEN TAC COT LOI (khong doi): mac dinh KHONG GOI REMOTE NAO co the mat
--  tien hoac gian lan. Moi thao tac farm di qua GUI CUA GAME. Remote chi
--  duoc goi khi thoa: (1) no-arg, (2) nguoi dung bat RemoteCallsEnabled SAU
--  KHI chay recon (tffa_v1_single.lua) va thay server tra ve hop le, (3)
--  nam trong allowlist. Shop_Buy / Stand_Upgrade / Player_SetThrowPower /
--  Dev_Action / AdminAbuse_* KHONG BAO GIO duoc goi qua remote.
--
--  BAI HOC TU KAITUN: top-level locals < 30; moi thu trong bang TFFA; ham
--  goi nhau qua TFFA.*; khong dung `continue` / `+=` / `..=`; strip dau
--  phay khi parse so tien.
--
--  CANH BAO: auto-farm co the vi pham dieu khoan game/Roblox va co nguy co
--  bi kick/ban (thuong toi cham 2-4 tuan sau). Farm o muc giong nguoi, dung
--  chay 24/7, chi chay tren acc phu. Nguoi dung tu chiu trach nhiem.
--
--  CACH CHAY (Delta):
--    1. Tat ban recon truoc neu dang chay (getgenv().__TFFA.Stop()).
--    2. Luu file nay vao thu muc workspace cua Delta, mo file roi EXECUTE.
--       KHONG paste truc tiep vao o EXECUTE - mobile hay bi cat clipboard.
--    3. Nhin console: phai thay "=== TFFA Main boot: v2.0 ===" (neu thay
--       "v1.0" nghia la ban dang chay file cu — xoa file cu di).
--    4. Test tung pha theo huong dan o cuoi file (Pha 0-6), moi pha <= 5 phut.
-- ============================================================================

-- Self-stop ban cu: chay lai file se tat ban cu truoc.
if getgenv and getgenv().__TFFA_MAIN and getgenv().__TFFA_MAIN.Stop then
	pcall(getgenv().__TFFA_MAIN.Stop)
end

-- Top-level locals: CO TINH, giu duoi 30 cai. Moi thu khac nam trong bang TFFA.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local TFFA = {}

TFFA.BUILD = "2026-11-07 v2.0-tutorial-first"
TFFA.PLACE_ID = 120219252362013

-- ============================================================================
--  CONFIG
-- ============================================================================
TFFA.DEFAULT_CONFIG = {
	Enabled = true,
	AutoTrain = true,
	AutoThrow = true,
	AutoEquipBest = true,
	AutoSell = true,
	AutoUpgradeFood = true,   -- chi mua qua nut trong Shop UI, khong goi remote
	AutoUpgradeBar = false,   -- TAT: nang xa qua be vang chua duoc kiem chung live
	AutoClaimOffline = false, -- TAT: chi bat sau khi recon xac nhan Offline_Claim no-arg
	AutoTapBonus = true,
	ProbeMode = true,
	-- Remote: mac dinh TAT HOAN TOAN. Chi bat sau khi chay tffa_v1_single.lua
	-- va thay server tra ve hop le cho tung remote no-arg.
	RemoteCallsEnabled = false,
	RemoteAllow = { Animations_Get = false, Offline_Claim = false,
		Training_Start = false, Training_Stop = false, Plot_EquipBest = false,
		Shop_ClaimFree = false },
	-- Plot_SellAll KHONG co trong allowlist (ban la hanh dong pha huy;
	-- chi mo lai khi hook bat duoc game tu goi no-arg).

	ThrowAt = 19,              -- muc tieu mac dinh; moi lan nem boc ngau nhien (xem pickMeterTarget)
	ThrowsPerDecision = 3,    -- toi da 3 phat nem moi lan DECIDE goi THROW (thay 10)
	TrainMaxMinutes = 10,     -- tran 1 session tap
	TrainSlowSeconds = 180,
	PowerCheckEvery = 5,
	MaxConsecMisses = 3,      -- 3 lan nem truot lien tiep -> nghi power yeu -> TRAIN
	PlotCapacity = 14,        -- slot plot mac dinh, hieu chinh khi thay day
	BackpackSellAt = 20,      -- tui >= 20 thu thi di ban
	TrainMinGainPerMin = 20,  -- tang < 20 power/phut -> xa yeu, dung tap
	IdleRestEveryCycles = 5,  -- nghi giong nguoi sau moi 5 vong DECIDE
	RecoverMaxConsec = 3,     -- 3 lan RECOVER lien tiep -> IDLE 60s
	SessionMinutes = 60,      -- gioi han phien farm roi nghi
	BreakMinutes = 15,
	MaxTeleportsPerHour = 4,  -- gioi han teleport/phien
	PlotNumber = nil,         -- override thu cong: 1-5 neu tu dong tim plot that bai
	ThrowTimeout = 10,        -- cho meter (thay 30: meter chu ky ~1-2s)
	CollectTimeoutBase = 15,
	MinRemoteGap = 0.5,
	ActionDelayMin = 0.3,
	ActionDelayMax = 1.2,
	MaxRemoteFails = 3,
	AntiAfkEvery = 540,
	Food = "",                 -- de trong = tu chon mon tot nhat dang co trong Backpack
}

local UserConfig = nil
if getgenv then UserConfig = getgenv().TFFA_MAIN_CONFIG end
TFFA.Config = {}
for k, v in pairs(TFFA.DEFAULT_CONFIG) do TFFA.Config[k] = v end
if type(UserConfig) == "table" then
	for k, v in pairs(UserConfig) do TFFA.Config[k] = v end
end

-- Thang thuc an DAY DU 42 mon, 17 tier (GameRant 06/11/2026 + NerdsChalk
-- 02/11/2026, doi chieu 4 nguon). Mon nao chi 1 nguon thi ghi chu.
TFFA.FOOD_LADDER = {
	{ Name = "Carrot", Price = 0, Tier = 1 },
	{ Name = "Apple", Price = 30, Tier = 1 },
	{ Name = "Banana", Price = 150, Tier = 1 },
	{ Name = "Toast", Price = 4000, Tier = 2 },
	{ Name = "Orange", Price = 20000, Tier = 2 },
	{ Name = "Pear", Price = 200000, Tier = 3 },
	{ Name = "Cheese", Price = 1000000, Tier = 3 },
	{ Name = "Bread Loaf", Price = 12000000, Tier = 4 },
	{ Name = "WaterMelon", Price = 60000000, Tier = 4 },
	{ Name = "Croissant", Price = 650000000, Tier = 5 },
	{ Name = "Chocolate", Price = 3200000000, Tier = 5 },
	{ Name = "Mushroom", Price = 30000000000, Tier = 6 },
	{ Name = "Bacon", Price = 150000000000, Tier = 6 },
	{ Name = "Burger", Price = 1300000000000, Tier = 7 },
	{ Name = "Shank", Price = 6800000000000, Tier = 7 },
	{ Name = "Fillet", Price = 57000000000000, Tier = 8 },
	{ Name = "Steak", Price = 1500000000000000, Tier = 8 },
	{ Name = "Royal Steak", Price = 50000000000000000, Tier = 9 },
	{ Name = "Golden Apple", Price = 120000000000000000, Tier = 9 },
	{ Name = "Crystal Melon", Price = 4000000000000000000, Tier = 10 },
	{ Name = "Ember Bacon", Price = 18000000000000000000, Tier = 10 },
	{ Name = "Lava Steak", Price = 120000000000000000000, Tier = 11 },
	{ Name = "Elder Strawberry", Price = 700000000000000000000, Tier = 11 },
	{ Name = "Phoenix Fillet", Price = 4000000000000000000000, Tier = 12 },
	{ Name = "Star Jelly", Price = 27000000000000000000000, Tier = 12 },
	{ Name = "Dragon's Apple", Price = 180000000000000000000000, Tier = 13 },
	{ Name = "Starlight Donut", Price = 450000000000000000000000, Tier = 13 },
	{ Name = "Glowshroom", Price = 1400000000000000000000000, Tier = 13 },
	{ Name = "Sundae Tower", Price = 3500000000000000000000000, Tier = 13 },
	{ Name = "Golden Corn", Price = 2500000000000000000000000000, Tier = 14 },
	{ Name = "Roast Turkey", Price = 28000000000000000000000000000, Tier = 14 },
	{ Name = "Caramel Apple", Price = 250000000000000000000000000000, Tier = 14 },
	{ Name = "Candy Corn", Price = 750000000000000000000000000000000, Tier = 15 },
	{ Name = "Hot Cider", Price = 8500000000000000000000000000000000, Tier = 15 },
	{ Name = "Golden Pumpkin", Price = 75000000000000000000000000000000000, Tier = 15 },
	{ Name = "Ghost Chowder", Price = 18000000000000000000000000000000000000, Tier = 16 },
	{ Name = "Calamari Rings", Price = 200000000000000000000000000000000000000, Tier = 16 },
	{ Name = "Phantom Lobster", Price = 1800000000000000000000000000000000000000, Tier = 16 },
	{ Name = "Toxic Donut", Price = 1200000000000000000000000000000000000000000, Tier = 17 },
	{ Name = "Mutant Melon", Price = 20000000000000000000000000000000000000000000, Tier = 17 },
	{ Name = "Atomic Pizza", Price = 400000000000000000000000000000000000000000000, Tier = 17 },
	{ Name = "Uranium Cake", Price = 9000000000000000000000000000000000000000000000, Tier = 17 },
}
-- Xa tap DA XAC MINH (allthings.how). 11 xa trung gian giua Violet va
-- Emerald + xa sau Sapphire CHUA CO NGUON NAO DANG => khong bia, doc live.
TFFA.BAR_LADDER = {
	{ Name = "Wooden Bar", Price = 0, XpPerRep = 1 },
	{ Name = "Steel Bar", Price = 50, XpPerRep = 2 },
	{ Name = "Gold Bar", Price = 2000, XpPerRep = 4 },
	{ Name = "Cyan Bar", Price = 12000, XpPerRep = 8 },
	{ Name = "Violet Bar", Price = 100000, XpPerRep = 16 },
	{ Name = "Emerald Bar", Price = 1200000000000000, XpPerRep = 65536 },
	{ Name = "Sapphire Bar", Price = 7000000000000000, XpPerRep = 131072 },
}
-- He so DA XAC MINH: mutation dung bang PGG; size do tu billboard file
-- v1221 + allthings.how (cap so nhan ~2.07). Stack NHAN, khong cong.
TFFA.MUT_MULT = { Gold = 1.5, Diamond = 3, Emerald = 5, Ruby = 10, Rainbow = 20 }
TFFA.SIZE_MULT = { Big = 2.08, Large = 4.31, Huge = 8.94 }
-- 42 mon an / 154 loai thu trong file .rbxl v1221.
TFFA.ALL_FOODS = { "Pear", "WaterMelon", "Toast", "Croissant", "Apple", "Cheese",
	"Carrot", "Bread Loaf", "Banana", "Golden Apple", "Mushroom", "Orange",
	"Chocolate", "Elder Strawberry", "Bacon", "Burger", "Shank", "Fillet",
	"Star Jelly", "Steak", "Crystal Melon", "Ember Bacon", "Royal Steak",
	"Lava Steak", "Dragon's Apple", "Phoenix Fillet", "Glowshroom",
	"Sundae Tower", "Golden Corn", "Starlight Donut", "Roast Turkey",
	"Caramel Apple", "Candy Corn", "Hot Cider", "Golden Pumpkin",
	"Ghost Chowder", "Calamari Rings", "Phantom Lobster", "Toxic Donut",
	"Mutant Melon", "Atomic Pizza", "Uranium Cake" }
TFFA.FOOD_SET = {}
do
	for _, n in ipairs(TFFA.ALL_FOODS) do TFFA.FOOD_SET[n] = true end
end
TFFA.ANIMAL_SET = {}
do
	local names = { "Aardvark", "Amphiptere", "Anglerfish", "ArcanePhoenix",
		"Archaeopteryx", "Badger", "Banshee", "BarrelBrute", "Bat", "Bear",
		"BlackCat", "Brachiosaurus", "Bull", "Bunny", "Bunyip", "Caladrius",
		"Capybara", "Caracal", "Cerberus", "Chupacabra", "ClassicDragon", "Cobra",
		"Cockatrice", "Cow", "Crab", "Crocodile", "CursedOwl", "CursedRaven",
		"Demon", "Dimetrodon", "Dingo", "Dullahan", "Elephant", "Emu", "FairyFox",
		"Fenrir", "FerroWyrm", "FirePhoenix", "Frog", "Gallimimus", "GargoyleBat",
		"Ghost", "GhostPirate", "GhostlyHorse", "GiantSquid", "Giraffee",
		"GlassbackColossus", "Goat", "GoblinShark", "GoldenRetriver", "Golem",
		"Gorilla", "Griffin", "GuiennaPig", "Hamster", "Hellhound", "HoneyBadger",
		"Horse", "Horseman", "Hydra", "Hyena", "IsotopeAngel", "JackOLantern",
		"Jackal", "Jackalope", "JadeKirin", "Jellyfish", "Kangaroo", "Kitsune",
		"Koala", "Kookaburra", "Kraken", "LeafySeaDragon", "Leviathan", "Lich",
		"Lindworm", "Lion", "LivingPumpkin", "Lizard", "Llama", "Mamoth",
		"Manticore", "MantisShrimp", "Megalodon", "MeltdownIdol", "Microraptor",
		"Minotaur", "Mosasaurus", "Mothman", "MushroomBear", "MysticMandrake",
		"Nightmare", "Ostrich", "Owl", "Parrot", "Pegasus", "PhantomDog",
		"Plesiosaur", "Polar Bear", "Poltergeist", "Pony", "Pterodactyl", "Qilin",
		"Quokka", "RadScarecrow", "Raiju", "RavenHalloween", "ReactorGolem",
		"ReactorHound", "Reaper", "ReaperSteed", "Roc", "SaberToothedTiger",
		"Scarecrow", "Seahorse", "Seal", "ShadowDemon", "ShadowWolf", "Shark",
		"Simurgh", "SirenSpire", "Skeleton", "SkeletonHorse", "SludgeMimic",
		"Snail", "Snake", "Specter", "SpellboundOwl", "Sphinx", "Spinosaurus",
		"StymphalianBird", "Swordfish", "T-Rex", "Tanuki", "Thunderbird", "Tiger",
		"Triceratops", "TripleCobra", "Turtle", "Unicorn", "UraniumStag",
		"Velicoraptor", "WasteHarvester", "Whale", "WingedImp", "Witch",
		"WitchFamiliarCat", "Wolf", "WoollyMammoth", "Wraith", "Wyvern", "Yak",
		"Zebra", "ZombieCrow" }
	for _, n in ipairs(names) do TFFA.ANIMAL_SET[n] = true end
end
-- Thu SS (Robux/egg) KHONG BAO GIO duoc ban (khong mua lai duoc bang tien game).
TFFA.NEVER_SELL = { ["Pumpkin Monster"] = true, Reaper = true, ReaperSteed = true,
	["Giant Squid"] = true, Demon = true, ["Skeleton Horse"] = true,
	WoollyMammoth = true, Skeleton = true }
-- Biome theo truc -Z (do tu file; Luck chi co so lieu toi PrehistoricForest).
TFFA.BIOMES = {
	{ Name = "Forest", WallZ = -45 }, { Name = "Savana", WallZ = -213 },
	{ Name = "Desert", WallZ = -381 }, { Name = "Jungle", WallZ = -549 },
	{ Name = "Ocean", WallZ = -717 }, { Name = "Mountains", WallZ = -885 },
	{ Name = "Taiga", WallZ = -1077 }, { Name = "Winter", WallZ = -1293 },
	{ Name = "PrehistoricForest", WallZ = -1533 }, { Name = "DeepWaters", WallZ = -1797 },
	{ Name = "Hell", WallZ = -2085 }, { Name = "AncientRuins", WallZ = -2421 },
	{ Name = "MythicalParadise", WallZ = -2805 }, { Name = "ShadowRealm", WallZ = -3285 },
	{ Name = "HarvestFields", WallZ = -4000 }, { Name = "PhantomHarbor", WallZ = -5000 },
	{ Name = "NuclearWasteland", WallZ = -6200 },
}
-- Toa do dich: Y VE MAT DAT (vong ActivationCircle), khong dung Y ZonePad
-- lo lung (~8.5). Spawn Y=2.5, ThrowLine Y=3 (dung truoc vach z=-40).
TFFA.ANCHORS = {
	Spawn = Vector3.new(0, 2.5, 0),
	ThrowLine = Vector3.new(0, 3, -38),
	SellCircle = Vector3.new(53.92, 2.61, -28.49),
	TrainingOffset = Vector3.new(-16, 0.5, -30.5),
	FoodShopOffset = Vector3.new(10.5, 0.5, -30.8),
	BarUpgradeOffset = Vector3.new(-16, 0.5, -39),
}
-- Remote CAM TUYET DOI (phong thu 2 lop: BLOCKED + khong co trong allowlist).
TFFA.BLOCKED_REMOTES = { Player_SetThrowPower = true, Dev_Action = true,
	AdminAbuse_Vote = true, AdminAbuse_VoteState = true, AdminAbuse_Gift = true,
	Shop_Buy = true, Shop_Equip = true, Shop_Prompt = true, Stand_Upgrade = true,
	Plot_SellAnimal = true, Plot_PlaceAnimal = true, Plot_EquipAnimal = true,
	Plot_PickUpAnimal = true, Plot_UpgradeFence = true, Plot_SellAll = true,
	Gift_Request = true, Gift_Respond = true, Gift_Cancel = true,
	Throw_Start = true, Throw_Complete = true, Throw_Resolve = true,
	Throw_UseSuper = true, Egg_Place = true, RingRush_Begin = true,
	RingRush_Report = true, RingRush_End = true, Sell_Protected = true,
	Player_SetSetting = true }
-- Remote no-arg CHI DUOC GOI khi RemoteCallsEnabled=true + RemoteAllow[name]=true.
TFFA.REMOTE_ALLOWLIST = { Animations_Get = true, Offline_Claim = true,
	Training_Start = true, Training_Stop = true, Plot_EquipBest = true,
	Shop_ClaimFree = true }

TFFA.State = {
	Running = false, MyPlot = nil, MyPlotCenter = nil, MyPlotNumber = nil,
	Money = nil, ThrowPower = nil, Level = nil, PlotIncomePerSec = nil,
	EquippedFood = nil, Throws = 0, Catches = 0, Misses = 0,
	LastBiome = "?", LastLuck = "?", LastLandZ = nil, Cycles = 0,
	DisabledFeatures = {}, RemoteFails = {}, LastRemoteCall = {},
	ThrowHistory = {}, LearnedPower = {}, LastLevelUpAt = os.clock(),
	Status = "Dang khoi dong...", StopFlag = false, Throwing = false,
	StuckStreak = 0, LastProgressAt = os.clock(), NoProgressCycles = 0,
	RecoveryCount = 0, TeleportsThisHour = 0, TeleportHourStart = os.clock(),
	SessionStartedAt = os.clock(), DecideCycles = 0,
}
TFFA.ReconLog = {}
TFFA.StuckLedger = {}

function TFFA.log(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
	local line = "[TFFA-Main] " .. table.concat(parts, " ")
	print(line)
	table.insert(TFFA.ReconLog, line)
	if #TFFA.ReconLog > 400 then table.remove(TFFA.ReconLog, 1) end
end

-- Log ket thong nhat: [TFFA-KET] hanh_dong | dau_hieu | pos -> dich dist | HP/Sit/State | streak | cap -> ket qua
function TFFA.logStuck(action, sign, target, level, result)
	local root = TFFA.getRootPart()
	local pos = root and root.Position or Vector3.new(0, 0, 0)
	local _, humanoid = TFFA.getCharacter()
	local hp = humanoid and humanoid.Health or -1
	local sit = humanoid and tostring(humanoid.Sit) or "?"
	local state = "?"
	if humanoid then
		local ok, st = pcall(function() return humanoid:GetState() end)
		if ok then state = tostring(st):gsub("Enum.HumanoidStateType.", "") end
	end
	local dist = target and (Vector2.new(pos.X - target.X, pos.Z - target.Z).Magnitude) or -1
	local line = string.format("[TFFA-KET] %s | %s | pos=(%.1f,%.1f,%.1f) -> dich=(%.1f,%.1f,%.1f) distXZ=%.1f | HP=%.0f Sit=%s State=%s | streak=%d | %s -> %s",
		action, sign, pos.X, pos.Y, pos.Z,
		target and target.X or 0, target and target.Y or 0, target and target.Z or 0,
		dist, hp, sit, state, TFFA.State.StuckStreak, level, result)
	print(line)
	table.insert(TFFA.StuckLedger, line)
	if #TFFA.StuckLedger > 20 then table.remove(TFFA.StuckLedger, 1) end
end

function TFFA.noteProgress()
	TFFA.State.StuckStreak = 0
	TFFA.State.NoProgressCycles = 0
	TFFA.State.LastProgressAt = os.clock()
end

function TFFA.randRange(a, b)
	return a + math.random() * (b - a)
end

-- Delay phan phoi tam giac (tap trung quanh giua, khong deu nhu uniform).
function TFFA.triDelay(a, b)
	local mid = (a + b) / 2
	local r = (math.random() + math.random()) / 2
	return a + (b - a) * r
end

function TFFA.randDelay()
	task.wait(TFFA.triDelay(TFFA.Config.ActionDelayMin, TFFA.Config.ActionDelayMax))
end

-- Muc tieu meter moi lan nem: 65% 19-20 (PERFECT), 25% 17-18 (GREAT),
-- 10% 15-16 hoac de troi (nem hong) — giong nguoi, khong PERFECT 100%.
function TFFA.pickMeterTarget()
	local roll = math.random()
	if roll < 0.65 then return TFFA.randRange(19, 20) end
	if roll < 0.90 then return TFFA.randRange(17, 18.5) end
	return TFFA.randRange(15, 16.5)
end


-- ============================================================================
--  Util
-- ============================================================================
TFFA.SUFFIXES = { K = 1e3, M = 1e6, B = 1e9, T = 1e12, Qa = 1e15, Qi = 1e18,
	Sx = 1e21, Sp = 1e24, Oc = 1e27, No = 1e30, Dc = 1e33, Ud = 1e36,
	Dd = 1e39, Td = 1e42, Qad = 1e45 }

-- Trich so tien tu BAT CU cho nao trong chuoi (vd "Cash: $1.2K" hay
-- "Swordfish\n$500T/s"). Tra ve nil neu khong thay so.
function TFFA.parseMoney(text)
	if type(text) ~= "string" then return nil end
	local chunk = text:match("%$%s*([%d%.,]+%s*[A-Za-z]*)")
	if not chunk then
		chunk = text:match("([%d%.,]+%s*[A-Za-z]*)")
	end
	if not chunk then return nil end
	local clean = chunk:gsub(",", ""):gsub("%s+", "")
	local num, suf = clean:match("^([%d%.]+)([A-Za-z]*)$")
	if not num then return nil end
	local value = tonumber(num)
	if not value then return nil end
	if suf ~= "" then value = value * (TFFA.SUFFIXES[suf] or 1) end
	return value
end

function TFFA.formatMoney(value)
	if not value then return "?" end
	local order = { { "Qad", 1e45 }, { "Td", 1e42 }, { "Dd", 1e39 }, { "Ud", 1e36 },
		{ "Dc", 1e33 }, { "No", 1e30 }, { "Oc", 1e27 }, { "Sp", 1e24 },
		{ "Sx", 1e21 }, { "Qi", 1e18 }, { "Qa", 1e15 }, { "T", 1e12 },
		{ "B", 1e9 }, { "M", 1e6 }, { "K", 1e3 } }
	for _, pair in ipairs(order) do
		if value >= pair[2] then
			return string.format("$%.2f%s", value / pair[2], pair[1])
		end
	end
	return string.format("$%d", math.floor(value))
end

function TFFA.biomeFromZ(z)
	if not z then return "?" end
	local best = "Lobby"
	for _, b in ipairs(TFFA.BIOMES) do
		if z <= b.WallZ then best = b.Name end
	end
	return best
end

function TFFA.distXZ(a, b)
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

-- ============================================================================
--  GUI helpers
-- ============================================================================
function TFFA.getPlayerGui()
	local gui = LocalPlayer:FindFirstChild("PlayerGui")
	if gui then return gui end
	return LocalPlayer:WaitForChild("PlayerGui", 10)
end

function TFFA.isVisible(inst)
	local cur = inst
	while cur do
		if cur:IsA("GuiObject") and not cur.Visible then return false end
		if cur:IsA("ScreenGui") and not cur.Enabled then return false end
		cur = cur.Parent
	end
	return true
end

function TFFA.findGuiTexts(needle, classFilter)
	local found = {}
	local gui = TFFA.getPlayerGui()
	if not gui then return found end
	local lowerNeedle = string.lower(needle)
	for _, inst in ipairs(gui:GetDescendants()) do
		if inst:IsA("GuiObject") then
			if not classFilter or inst:IsA(classFilter) then
				local ok, text = pcall(function() return inst.Text end)
				if ok and type(text) == "string" and text ~= "" then
					if string.find(string.lower(text), lowerNeedle, 1, true) then
						table.insert(found, inst)
					end
				end
			end
		end
	end
	return found
end

-- Tim nut theo text CHINH XAC (sau trim/lowercase), chi nut dang hien.
-- Tra ve nil thay vi nut sai — an toan hon bam nham.
function TFFA.findButtonByText(needle, ancestor)
	local gui = TFFA.getPlayerGui()
	if not gui then return nil end
	local lowerNeedle = string.lower(needle)
	local root = ancestor or gui
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("TextButton") or inst:IsA("ImageButton") then
			if TFFA.isVisible(inst) and inst.Active and inst.AbsoluteSize.X > 0 then
				local ok, text = pcall(function() return inst.Text end)
				if ok and type(text) == "string" then
					local trimmed = string.lower(text:gsub("^%s+", ""):gsub("%s+$", ""))
					if trimmed == lowerNeedle then return inst end
				end
			end
		end
	end
	-- Fallback: chuoi con, nhung van chi nut dang hien.
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("TextButton") or inst:IsA("ImageButton") then
			if TFFA.isVisible(inst) and inst.Active and inst.AbsoluteSize.X > 0 then
				local ok, text = pcall(function() return inst.Text end)
				if ok and type(text) == "string" and text ~= "" then
					if string.find(string.lower(text), lowerNeedle, 1, true) then
						return inst
					end
				end
			end
		end
	end
	return nil
end

-- Tim nut anh (khong co Text) theo ten/icon: vd nut Animals (chan thu).
function TFFA.findImageButton(namePart)
	local gui = TFFA.getPlayerGui()
	if not gui then return nil end
	local lowerPart = string.lower(namePart)
	for _, inst in ipairs(gui:GetDescendants()) do
		if inst:IsA("ImageButton") and TFFA.isVisible(inst) and inst.Active then
			local hay = string.lower(inst.Name)
			if string.find(hay, lowerPart, 1, true) then return inst end
		end
	end
	return nil
end

-- Tim the (card) trong Shop/panel theo ten mon: tra ve card (tien to chung).
function TFFA.findCardByName(name, ancestor)
	local gui = TFFA.getPlayerGui()
	if not gui then return nil end
	local root = ancestor or gui
	local lowerName = string.lower(name)
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("TextLabel") then
			local ok, text = pcall(function() return inst.Text end)
			if ok and type(text) == "string" then
				if string.lower(text:gsub("^%s+", ""):gsub("%s+$", "")) == lowerName then
					-- Leo len 3 cap de lay card chua ca ten + gia + nut.
					local card = inst.Parent
					if card and card.Parent then card = card.Parent end
					if card and card.Parent then card = card.Parent end
					return card
				end
			end
		end
	end
	return nil
end

-- Doc gia tri meter: uu tien fill Frame (ti le 0-1), fallback label so
-- CHI TIN khi gia tri THAY DOI theo thoi gian (label tinh loai).
-- Tra ve (value 0-20, source) hoac (nil, nil).
function TFFA.findMeterValue()
	local gui = TFFA.getPlayerGui()
	if not gui then return nil, nil end
	-- Cach 1: fill Frame trong khung meter — Size.X.Scale chay 0->1.
	for _, inst in ipairs(gui:GetDescendants()) do
		if inst:IsA("Frame") and inst.Name ~= "" then
			local hay = string.lower(inst.Name .. " " .. (inst.Parent and inst.Parent.Name or ""))
			if (string.find(hay, "meter") or string.find(hay, "throw"))
				and (string.find(hay, "fill") or string.find(hay, "bar") or string.find(hay, "arrow")) then
				local ok, scale = pcall(function() return inst.Size.X.Scale end)
				if ok and scale and scale > 0 and scale <= 1 then
					return scale * 20, "fill:" .. inst.Name
				end
			end
		end
	end
	-- Cach 2: label so, chi tin neu thay doi trong 0.3s.
	local candidates = {}
	for _, inst in ipairs(gui:GetDescendants()) do
		if inst:IsA("TextLabel") and TFFA.isVisible(inst) then
			local ok, text = pcall(function() return inst.Text end)
			if ok and type(text) == "string" then
				local num = tonumber(text)
				if num and num >= 0 and num <= 20 then
					local parentName = inst.Parent and inst.Parent.Name or ""
					local grandName = (inst.Parent and inst.Parent.Parent and inst.Parent.Parent.Name) or ""
					local hay = string.lower(inst.Name .. " " .. parentName .. " " .. grandName)
					if string.find(hay, "throw") or string.find(hay, "meter")
						or string.find(hay, "power") or string.find(hay, "slider") then
						table.insert(candidates, inst)
					end
				end
			end
		end
	end
	for _, inst in ipairs(candidates) do
		local ok1, t1 = pcall(function() return inst.Text end)
		task.wait(0.15)
		local ok2, t2 = pcall(function() return inst.Text end)
		if ok1 and ok2 and t1 ~= t2 then
			local num = tonumber(t2)
			if num then return num, "label:" .. inst.Name end
		end
	end
	return nil, nil
end

-- Bam nut: thu tu tren mobile Delta — firesignal truoc, touch sau, chuot
-- cuoi. Ham verify (neu co) phai tra true thi moi tinh la bam thanh cong.
-- Tra ve true/false that, khong phai "pcall khong loi".
function TFFA.clickButton(btn, verifyFn)
	if not btn then return false end
	local tried = {}
	-- 1. firesignal (dang tin nhat tren mobile, khong phu thuoc toa do).
	if firesignal then
		local ok = pcall(function() firesignal(btn.MouseButton1Click) end)
		if ok then table.insert(tried, "firesignal") end
	end
	if verifyFn then
		task.wait(0.4)
		local ok, good = pcall(verifyFn)
		if ok and good then return true end
	elseif #tried > 0 then
		return true
	end
	-- 2. Touch tap tai toa do nut (dung loai input cua mobile).
	local pos = btn.AbsolutePosition
	local size = btn.AbsoluteSize
	local jx = TFFA.randRange(-0.35, 0.35) * size.X
	local jy = TFFA.randRange(-0.35, 0.35) * size.Y
	local x = pos.X + size.X / 2 + jx
	local y = pos.Y + size.Y / 2 + jy
	local holdTime = TFFA.randRange(0.06, 0.18)
	local okTouch = pcall(function()
		if VirtualInputManager.SendTouchEvent then
			VirtualInputManager:SendTouchEvent(x, y, 0, true, game, 0)
			task.wait(holdTime)
			VirtualInputManager:SendTouchEvent(x, y, 0, false, game, 0)
		else
			error("no SendTouchEvent")
		end
	end)
	if okTouch then table.insert(tried, "touch") end
	if verifyFn then
		task.wait(0.4)
		local ok, good = pcall(verifyFn)
		if ok and good then return true end
	elseif okTouch then
		return true
	end
	-- 3. Chuot (phuong an cuoi).
	local okMouse = pcall(function()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
		task.wait(holdTime)
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
	end)
	if verifyFn then
		task.wait(0.4)
		local ok, good = pcall(verifyFn)
		if ok and good then return true end
	elseif okMouse then
		return true
	end
	TFFA.log("CLICK_FAIL:", btn.Name, "da thu:", table.concat(tried, ","))
	return false
end

-- ============================================================================
--  Remote — CHI GOI KHI DUOC PHEP (xem dau file). Mac dinh TAT HOAN TOAN.
-- ============================================================================
function TFFA.getRemotesFolder()
	return ReplicatedStorage:FindFirstChild("Remotes")
end

function TFFA.getRemote(name)
	local folder = TFFA.getRemotesFolder()
	if not folder then return nil end
	return folder:FindFirstChild(name)
end

function TFFA.safeInvokeNoArg(name)
	if TFFA.BLOCKED_REMOTES[name] then
		TFFA.log("BLOCKED remote khong bao gio goi:", name)
		return false, "blocked"
	end
	if not TFFA.Config.RemoteCallsEnabled then
		return false, "remote calls disabled (chay recon truoc)"
	end
	if not TFFA.Config.RemoteAllow[name] then
		return false, "remote chua duoc bat trong RemoteAllow"
	end
	if not TFFA.REMOTE_ALLOWLIST[name] then
		return false, "remote khong nam trong allowlist no-arg"
	end
	if TFFA.State.DisabledFeatures[name] then
		return false, "disabled after failures"
	end
	local remote = TFFA.getRemote(name)
	if not remote then return false, "khong tim thay remote" end
	local last = TFFA.State.LastRemoteCall[name] or 0
	local gap = os.clock() - last
	if gap < TFFA.Config.MinRemoteGap then task.wait(TFFA.Config.MinRemoteGap - gap) end
	TFFA.State.LastRemoteCall[name] = os.clock()
	local done = false
	local ok, res = false, nil
	task.spawn(function()
		ok, res = pcall(function() return remote:InvokeServer() end)
		done = true
	end)
	local t0 = os.clock()
	while not done and os.clock() - t0 < 8 do task.wait(0.1) end
	if not done then
		TFFA.log("TIMEOUT remote:", name)
		return false, "timeout"
	end
	if ok then
		TFFA.State.RemoteFails[name] = 0
		if TFFA.Config.ProbeMode then
			TFFA.log("REMOTE OK:", name, "->", tostring(res))
		end
		return true, res
	end
	local fails = (TFFA.State.RemoteFails[name] or 0) + 1
	TFFA.State.RemoteFails[name] = fails
	TFFA.log("REMOTE FAIL:", name, "lan", fails, "->", tostring(res))
	if fails >= TFFA.Config.MaxRemoteFails then
		TFFA.State.DisabledFeatures[name] = true
		TFFA.log("TAT remote do loi lien tiep:", name)
	end
	return false, res
end

-- ============================================================================
--  Data — doc tu GUI/Workspace luc chay, khong hardcode
-- ============================================================================
function TFFA.getCharacter()
	local char = LocalPlayer.Character
	if not char then return nil, nil end
	return char, char:FindFirstChildOfClass("Humanoid")
end

function TFFA.getRootPart()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

-- Tim plot cua minh. Thu tu uu tien (da kiem chung tu file):
--  1. OwnerTag.BillboardGui.Name.Text == username (khop CHINH XAC)
--  2. ... == DisplayName
--  3. Server:FindFirstChild("TrainingRig_" .. username) (chi co khi dang tap)
--  4. Chuoi con (do tin cay thap, log canh bao)
--  5. Config.PlotNumber (override thu cong 1-5)
function TFFA.findMyPlot()
	local plotsFolder = Workspace:FindFirstChild("Plots")
	if not plotsFolder then
		plotsFolder = Workspace:WaitForChild("Plots", 30)
	end
	if not plotsFolder then
		TFFA.log("UNKNOWN: khong tim thay Workspace.Plots")
		return nil, nil
	end
	if TFFA.Config.PlotNumber then
		local plot = plotsFolder:FindFirstChild("Plot " .. tostring(TFFA.Config.PlotNumber))
		if plot then
			TFFA.log("Plot ep thu cong:", plot.Name, "(qua Config.PlotNumber)")
			return plot, plot.Position
		end
		TFFA.log("Config.PlotNumber =", tostring(TFFA.Config.PlotNumber), "nhung khong thay plot do.")
	end
	local myName = LocalPlayer.Name
	local myDisplay = LocalPlayer.DisplayName
	local function ownerText(plot)
		local tag = plot:FindFirstChild("OwnerTag")
		if not tag then return nil end
		local board = tag:FindFirstChildOfClass("BillboardGui")
		if not board then return nil end
		local nameLabel = board:FindFirstChild("Name")
		if not nameLabel then return nil end
		local ok, text = pcall(function() return nameLabel.Text end)
		if ok and type(text) == "string" then return text end
		return nil
	end
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:IsA("BasePart") then
			local text = ownerText(plot)
			if text == myName then
				TFFA.log("Plot cua ban:", plot.Name, "(qua OwnerTag == username)")
				return plot, plot.Position
			end
		end
	end
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:IsA("BasePart") then
			local text = ownerText(plot)
			if text == myDisplay then
				TFFA.log("Plot cua ban:", plot.Name, "(qua OwnerTag == DisplayName)")
				return plot, plot.Position
			end
		end
	end
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:IsA("BasePart") then
			local server = plot:FindFirstChild("Server")
			if server and server:FindFirstChild("TrainingRig_" .. myName) then
				TFFA.log("Plot cua ban:", plot.Name, "(qua TrainingRig)")
				return plot, plot.Position
			end
		end
	end
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:IsA("BasePart") then
			local text = ownerText(plot)
			if text and (string.find(text, myName, 1, true)
				or string.find(text, myDisplay, 1, true)) then
				TFFA.log("CANH BAO: plot doan theo chuoi con (do tin cay thap):", plot.Name)
				return plot, plot.Position
			end
		end
	end
	TFFA.log("UNKNOWN: khong xac dinh duoc plot cua minh (OwnerTag/TrainingRig).")
	TFFA.log("  Hay dung yen o plot cua ban roi chay lai, hoac set Config.PlotNumber = so plot (1-5).")
	return nil, nil
end

-- Doc tien: trich so $ tu giua chuoi; doc 2 lan cach nhau 0.5s, chi tin
-- khi on dinh (tranh doc trung luc label dang tween). Luu nguon label.
function TFFA.readMoney()
	local gui = TFFA.getPlayerGui()
	if not gui then return nil end
	local function scanOnce()
		local best, bestSrc = nil, nil
		for _, inst in ipairs(gui:GetDescendants()) do
			if inst:IsA("TextLabel") and TFFA.isVisible(inst) then
				local ok, text = pcall(function() return inst.Text end)
				if ok and type(text) == "string" and string.find(text, "%$") then
					local value = TFFA.parseMoney(text)
					if value and value >= 0 then
						local parentName = inst.Parent and inst.Parent.Name or ""
						local hay = string.lower(inst.Name .. " " .. parentName)
						if string.find(hay, "cash") or string.find(hay, "money")
							or string.find(hay, "hud") or string.find(hay, "top") then
							return value, inst.Name .. "=\"" .. text .. "\""
						end
						if not best then
							best = value
							bestSrc = inst.Name .. "=\"" .. text .. "\""
						end
					end
				end
			end
		end
		return best, bestSrc
	end
	local v1, src1 = scanOnce()
	task.wait(0.5)
	local v2, src2 = scanOnce()
	if v1 and v2 and v1 == v2 then
		TFFA.MoneySource = src1
		return v1
	end
	TFFA.MoneySource = src2 or src1
	return v2 or v1
end

-- Doc Throw Power / Level: tim label/frame co ten chua "power"/"level" roi
-- doc so trong chinh no HOAC trong TextLabel con/chau cung parent (chu co
-- the nam o label anh em ben canh). Power co the chi hien trong panel Power
-- hoac luc dang tap/nem — UNKNOWN luc dung o Lobby la binh thuong.
function TFFA.readPowerLevel()
	local gui = TFFA.getPlayerGui()
	if not gui then return nil, nil end
	local power, level = nil, nil
	local function numbersIn(inst)
		local out = {}
		local function collect(node)
			if node:IsA("TextLabel") then
				local ok, text = pcall(function() return node.Text end)
				if ok and type(text) == "string" then
					local v = TFFA.parseMoney(text)
					if v then table.insert(out, v) end
				end
			end
			for _, child in ipairs(node:GetChildren()) do collect(child) end
		end
		collect(inst)
		return out
	end
	for _, inst in ipairs(gui:GetDescendants()) do
		if inst:IsA("GuiObject") then
			local low = string.lower(inst.Name)
			if not power and string.find(low, "power") then
				local nums = numbersIn(inst.Parent or inst)
				if #nums > 0 then power = nums[1] end
			end
			if not level and (string.find(low, "level") or string.find(low, "lvl")) then
				local nums = numbersIn(inst.Parent or inst)
				if #nums > 0 then level = nums[1] end
			end
		end
		if inst:IsA("TextLabel") then
			local ok, text = pcall(function() return inst.Text end)
			if ok and type(text) == "string" and text ~= "" then
				local low = string.lower(text)
				if not power and string.find(low, "throw power") then
					power = TFFA.parseMoney(text)
				end
				if not level then
					local lv = text:match("[Ll][Ee][Vv][Ee][Ll]%s*%:?%s*(%d+)")
						or text:match("[Ll][Vv][Ll]%s*%.?%s*(%d+)")
						or text:match("[Ll][Vv]%s*%.?%s*(%d+)")
					if lv then level = tonumber(lv) end
				end
			end
		end
	end
	return power, level
end

-- Doc tong $/s cua plot: cong $/s tren cac InfoBillboard cua thu trong plot.
-- Text billboard co the la "Swordfish\n$500T/s" nen trich so tu giua chuoi.
function TFFA.readPlotIncome()
	local plot = TFFA.State.MyPlot
	if not plot then return nil end
	local animalsFolder = plot:FindFirstChild("Animals")
	if not animalsFolder then return nil end
	local total = 0
	local found = 0
	for _, desc in ipairs(animalsFolder:GetDescendants()) do
		if desc:IsA("TextLabel") then
			local ok, text = pcall(function() return desc.Text end)
			if ok and type(text) == "string" and string.find(text, "%$/s") then
				local value = TFFA.parseMoney(text)
				if value then total = total + value; found = found + 1 end
			end
		end
	end
	if found == 0 then return nil end
	return total
end

-- Doc tung con tren plot: {species, income, mutation, size, instance}.
-- Dung cho quyet dinh giu/ban theo $/s do live (khong theo ten/tier).
function TFFA.readPlotAnimals()
	local plot = TFFA.State.MyPlot
	if not plot then return {} end
	local animalsFolder = plot:FindFirstChild("Animals")
	if not animalsFolder then return {} end
	local out = {}
	for _, model in ipairs(animalsFolder:GetChildren()) do
		if model:IsA("Model") then
			local income = nil
			local mutation, size = nil, nil
			for _, desc in ipairs(model:GetDescendants()) do
				if desc:IsA("TextLabel") then
					local ok, text = pcall(function() return desc.Text end)
					if ok and type(text) == "string" then
						if string.find(text, "%$/s") then
							income = TFFA.parseMoney(text)
						end
						for mut in pairs(TFFA.MUT_MULT) do
							if string.find(string.upper(text), string.upper(mut), 1, true) then
								mutation = mut
							end
						end
						for sz in pairs(TFFA.SIZE_MULT) do
							if string.find(string.upper(text), string.upper(sz), 1, true) then
								size = sz
							end
						end
					end
				end
			end
			table.insert(out, { species = model.Name, income = income,
				mutation = mutation, size = size, instance = model })
		end
	end
	return out
end

function TFFA.countAnimalsOnPlot()
	return #TFFA.readPlotAnimals()
end

function TFFA.countBackpackAnimals()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return 0 end
	local n = 0
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and TFFA.ANIMAL_SET[tool.Name] then n = n + 1 end
	end
	return n
end

function TFFA.countBackpackFoods()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return 0 end
	local n = 0
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and TFFA.FOOD_SET[tool.Name] then n = n + 1 end
	end
	return n
end

-- Mon an tot nhat dang co trong Backpack (theo FOOD_LADDER, cao nhat thang).
function TFFA.bestOwnedFood()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return nil end
	local owned = {}
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then owned[tool.Name] = true end
	end
	local char = LocalPlayer.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") then owned[tool.Name] = true end
		end
	end
	local best = nil
	local bestIdx = 0
	for idx, entry in ipairs(TFFA.FOOD_LADDER) do
		if owned[entry.Name] and idx > bestIdx then best = entry.Name; bestIdx = idx end
	end
	if not best then
		for _, name in ipairs(TFFA.ALL_FOODS) do
			if owned[name] then best = name; break end
		end
	end
	return best
end

function TFFA.equipFood(foodName)
	if not foodName or foodName == "" then return false end
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local char, humanoid = TFFA.getCharacter()
	if not backpack or not humanoid then return false end
	local tool = backpack:FindFirstChild(foodName)
	if tool then
		humanoid:EquipTool(tool)
		TFFA.State.EquippedFood = foodName
		return true
	end
	if char then
		local held = char:FindFirstChild(foodName)
		if held then TFFA.State.EquippedFood = foodName; return true end
	end
	return false
end

-- Mon an dang cam tren tay (Tool trong Character).
function TFFA.heldFood()
	local char = LocalPlayer.Character
	if not char then return nil end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and TFFA.FOOD_SET[tool.Name] then return tool.Name end
	end
	return nil
end


-- ============================================================================
--  Move — PathfindingService + MoveTo tung waypoint
--  Quy tac: check toi noi chi theo XZ (root khi dung cao hon dat ~3 studs,
--  check 3D < 3 khong bao gio dung); do ket theo "khoang cach toi dich
--  khong giam" (nhay len/xuong khong tinh la tien); goi lai MoveTo moi
--  3-5s de reset timeout 8s noi bo cua engine; chia leg dai thanh chang
--  <= 70 studs (pathfinding tu chia waypoint).
-- ============================================================================
function TFFA.canTeleport()
	local now = os.clock()
	if now - TFFA.State.TeleportHourStart > 3600 then
		TFFA.State.TeleportHourStart = now
		TFFA.State.TeleportsThisHour = 0
	end
	return TFFA.State.TeleportsThisHour < TFFA.Config.MaxTeleportsPerHour
end

function TFFA.teleportTo(pos, reason)
	if not TFFA.canTeleport() then
		TFFA.log("Het luot teleport trong gio nay (toi da "
			.. tostring(TFFA.Config.MaxTeleportsPerHour) .. ") — khong teleport:", reason)
		return false
	end
	local root = TFFA.getRootPart()
	if not root then return false end
	TFFA.State.TeleportsThisHour = TFFA.State.TeleportsThisHour + 1
	pcall(function()
		root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	end)
	task.wait(0.5)
	TFFA.log("Teleport (" .. reason .. ") toi", tostring(pos),
		"(lan " .. tostring(TFFA.State.TeleportsThisHour) .. " trong gio nay)")
	return true
end

-- Di chuyen toi CFrame dich. Tra ve true khi toi noi (XZ < 3), false khi het
-- timeout/het luot cuu ho. Moi leg: pathfinding -> waypoint; ket -> nhay ->
-- tinh lai path -> teleport (toi da 2 lan/leg) -> bo cuoc.
function TFFA.moveTo(cf, timeout)
	local root = TFFA.getRootPart()
	local _, humanoid = TFFA.getCharacter()
	if not root or not humanoid or humanoid.Health <= 0 then return false end
	timeout = timeout or 20
	local target = cf.Position
	-- Kiem tra nhan vat con hop le moi tick; chet/respawn thi dung ngay.
	local function stillValid()
		local r = TFFA.getRootPart()
		local _, h = TFFA.getCharacter()
		return r ~= nil and h ~= nil and h.Health > 0 and r.Parent ~= nil
	end
	-- Dung day khoi ghe truoc khi di (dang ngoi tren xa tap thi MoveTo vo hieu).
	if humanoid.Sit then
		pcall(function()
			humanoid.Sit = false
			humanoid.Jump = true
		end)
		task.wait(0.7)
	end
	local t0 = os.clock()
	local teleports = 0
	local lastDist = TFFA.distXZ(root.Position, target)
	local lastImprove = os.clock()
	local lastReissue = 0
	local path = nil
	local waypoints = nil
	local wpIndex = 1
	local function computePath()
		local ok, p = pcall(function()
			return PathfindingService:CreatePath({
				AgentRadius = 2, AgentHeight = 5, AgentCanJump = true,
				AgentCanClimb = false, WaypointSpacing = 4,
				Costs = { Water = math.huge },
			})
		end)
		if not ok or not p then return false end
		local ok2 = pcall(function()
			p:ComputeAsync(root.Position, target)
		end)
		if not ok2 then return false end
		if p.Status ~= Enum.PathStatus.Success then
			TFFA.log("Pathfinding khong tim duoc duong toi", tostring(target),
				"status:", tostring(p.Status), "- dung MoveTo truc tiep.")
			return false
		end
		path = p
		waypoints = p:GetWaypoints()
		wpIndex = 1
		return true
	end
	local usePath = computePath()
	if not usePath then
		humanoid:MoveTo(target)
		lastReissue = os.clock()
	end
	while os.clock() - t0 < timeout do
		if not stillValid() then
			TFFA.logStuck("moveTo", "nhan vat chet/respawn giua duong", target, "L5", "dung leg")
			return false
		end
		local dist = TFFA.distXZ(root.Position, target)
		if dist < 3 then
			TFFA.noteProgress()
			return true
		end
		-- Tien do = khoang cach toi dich giam (khong phai vi tri co doi).
		if dist < lastDist - 0.5 then
			lastDist = dist
			lastImprove = os.clock()
		end
		if usePath and waypoints then
			local wp = waypoints[wpIndex]
			if wp then
				local wpDist = TFFA.distXZ(root.Position, wp.Position)
				if wpDist < 4 then
					wpIndex = wpIndex + 1
					wp = waypoints[wpIndex]
				end
				if wp then
					if wp.Action == Enum.PathWaypointAction.Jump then
						pcall(function() humanoid.Jump = true end)
					end
					if os.clock() - lastReissue > 3 then
						humanoid:MoveTo(wp.Position)
						lastReissue = os.clock()
					end
				else
					humanoid:MoveTo(target)
					lastReissue = os.clock()
				end
			else
				humanoid:MoveTo(target)
				lastReissue = os.clock()
			end
		else
			-- Khong co path: goi lai MoveTo moi 3-5s de reset timeout 8s cua engine.
			if os.clock() - lastReissue > 3 then
				humanoid:MoveTo(target)
				lastReissue = os.clock()
			end
		end
		-- Ket: khoang cach toi dich khong giam trong 3s.
		if os.clock() - lastImprove > 3 then
			TFFA.logStuck("moveTo", "khong tien ve dich 3s", target, "L1", "nhay + tinh lai path")
			pcall(function() humanoid.Jump = true end)
			task.wait(0.8)
			if TFFA.distXZ(root.Position, target) < lastDist - 0.5 then
				lastDist = TFFA.distXZ(root.Position, target)
				lastImprove = os.clock()
			else
				teleports = teleports + 1
				if teleports > 2 then
					TFFA.logStuck("moveTo", "het 2 luot teleport", target, "L3", "bo leg")
					return false
				end
				if TFFA.teleportTo(target, "ket khi di chuyen") then
					if TFFA.distXZ(root.Position, target) < 5 then
						TFFA.noteProgress()
						return true
					end
				end
				lastDist = TFFA.distXZ(root.Position, target)
				lastImprove = os.clock()
				usePath = computePath()
				if not usePath then
					humanoid:MoveTo(target)
					lastReissue = os.clock()
				end
			end
		end
		task.wait(0.2)
	end
	TFFA.logStuck("moveTo", "TIMEOUT", target, "L3", "het gio")
	return false
end

function TFFA.goThrowLine()
	-- KHONG xoay 180 do nua: CFrame.new mac dinh nhin ve -Z (huong biome).
	-- Ban cu xoay 180 lam nhan vat quay lung ve biome (nhin ve lobby).
	return TFFA.moveTo(CFrame.new(TFFA.ANCHORS.ThrowLine), 20)
end

function TFFA.goTrainingSpot()
	if not TFFA.State.MyPlotCenter then return false end
	local target = TFFA.State.MyPlotCenter + TFFA.ANCHORS.TrainingOffset
	return TFFA.moveTo(CFrame.new(target), 25)
end

function TFFA.goFoodShop()
	if not TFFA.State.MyPlotCenter then return false end
	local target = TFFA.State.MyPlotCenter + TFFA.ANCHORS.FoodShopOffset
	return TFFA.moveTo(CFrame.new(target), 25)
end

function TFFA.goSell()
	return TFFA.moveTo(CFrame.new(TFFA.ANCHORS.SellCircle), 25)
end

function TFFA.goSpawn()
	return TFFA.moveTo(CFrame.new(TFFA.ANCHORS.Spawn), 15)
end

function TFFA.goBarUpgradePad()
	if not TFFA.State.MyPlotCenter then return false end
	local target = TFFA.State.MyPlotCenter + TFFA.ANCHORS.BarUpgradeOffset
	return TFFA.moveTo(CFrame.new(target), 25)
end

-- ============================================================================
--  Throw — KHONG cham "bat dau nem" (cu cham do CHINH LA cu nem).
--  Cho "TAP TO THROW" hien -> poll meter (fill Frame, hoac label so thay
--  doi) -> bam theo rising edge o muc tieu ngau nhien -> xac minh
--  PERFECT!/GREAT!/+N POWER.
-- ============================================================================
function TFFA.waitForThrowUI(timeout)
	local t0 = os.clock()
	while os.clock() - t0 < (timeout or 10) do
		if #TFFA.findGuiTexts("TAP TO THROW") > 0 then return true end
		task.wait(0.3)
	end
	return false
end

function TFFA.waitForResultText(timeout)
	local t0 = os.clock()
	while os.clock() - t0 < (timeout or 5) do
		if #TFFA.findGuiTexts("PERFECT") > 0 then return "PERFECT" end
		if #TFFA.findGuiTexts("GREAT") > 0 then return "GREAT" end
		local found = TFFA.findGuiTexts("+")
		for _, inst in ipairs(found) do
			local ok, text = pcall(function() return inst.Text end)
			if ok and type(text) == "string" and string.find(text, "POWER") then
				return text
			end
		end
		task.wait(0.2)
	end
	return nil
end

function TFFA.doOneThrow()
	-- Moi lan nem: equip lai mon an + kiem tra con tren tay (food co the
	-- bi tieu thu sau moi lan nem). Het food thi dung, khong poll vo ich.
	local food = TFFA.Config.Food
	if food == "" or food == nil then food = TFFA.bestOwnedFood() end
	if not food then
		TFFA.log("Khong co mon an nao trong Backpack - can mua/equip Carrot truoc.")
		return false
	end
	if not TFFA.equipFood(food) then
		TFFA.log("Khong equip duoc mon an:", tostring(food))
		return false
	end
	task.wait(0.5)
	if TFFA.heldFood() ~= food then
		TFFA.log("Mon an khong nam tren tay sau khi equip:", tostring(food))
		return false
	end
	if not TFFA.goThrowLine() then
		TFFA.log("Khong toi duoc vach nem - bo qua luot nay")
		return false
	end
	TFFA.State.Throwing = true
	-- Cho UI nem san sang, KHONG cham man hinh truoc (cham la nem luon).
	if not TFFA.waitForThrowUI(10) then
		TFFA.log("Khong thay UI nem (TAP TO THROW) sau 10s - bo qua luot nay.")
		TFFA.log("  Hay nem tay 1 lan va gui anh GUI nem cho Muse de chinh do tim meter.")
		TFFA.State.Throwing = false
		return false
	end
	local target = TFFA.pickMeterTarget()
	TFFA.log("Nem voi mon:", food, "| muc tieu meter:", string.format("%.1f", target))
	local t0 = os.clock()
	local clicked = false
	local prev = nil
	while os.clock() - t0 < TFFA.Config.ThrowTimeout do
		local meter = TFFA.findMeterValue()
		if meter then
			-- Rising edge: thay gia tri dang TANG qua muc tieu thi bam ngay,
			-- tru hao do tre input ~0.1s (bam o ~target-0.5 de roi vao target).
			if prev and meter >= prev and meter >= target - 0.5 then
				task.wait(TFFA.randRange(0.08, 0.35))
				local btn = TFFA.findButtonByText("TAP TO THROW")
					or TFFA.findButtonByText("TAP TO THROW!")
				if btn then
					TFFA.clickButton(btn)
				else
					-- Nut bat dau nem co the la vung cham toan man hinh:
					-- tap giua man hinh 1 lan (day moi la cu nem that).
					pcall(function()
						local cam = Workspace.CurrentCamera
						if cam then
							local vs = cam.ViewportSize
							VirtualInputManager:SendMouseButtonEvent(vs.X / 2, vs.Y / 2, 0, true, game, 0)
							task.wait(TFFA.randRange(0.06, 0.18))
							VirtualInputManager:SendMouseButtonEvent(vs.X / 2, vs.Y / 2, 0, false, game, 0)
						end
					end)
				end
				clicked = true
				break
			end
			prev = meter
		end
		task.wait(TFFA.randRange(0.02, 0.03))
	end
	TFFA.State.Throwing = false
	if not clicked then
		TFFA.log("Khong thay meter len toi muc tieu trong "
			.. tostring(TFFA.Config.ThrowTimeout) .. "s - bo qua luot nay.")
		TFFA.State.Misses = TFFA.State.Misses + 1
		return false
	end
	TFFA.State.Throws = TFFA.State.Throws + 1
	TFFA.noteProgress()
	-- Xac minh nem thanh cong bang chu ket qua, khong cho cung 1.5s + 1.5s.
	local result = TFFA.waitForResultText(5)
	if result then
		TFFA.log("Ket qua nem:", tostring(result))
	else
		TFFA.log("Khong thay chu PERFECT/GREAT sau khi nem - co the nem hong hoac UI khac.")
	end
	-- Cho cua so reveal: neu co nut SKIP thi bam de rut ngan.
	local skipBtn = TFFA.findButtonByText("SKIP")
	if skipBtn then TFFA.clickButton(skipBtn) end
	return true
end

-- Nhat thu: doi the reveal (NEW! / ten loai / $/s) -> tim dung con do trong
-- Workspace (khong duoi Plots, khong co InfoBillboard) -> di toi DIEM ROI
-- TINH va doi thu toi (thu tu di toi cho do an) -> xac minh model bien mat.
function TFFA.collectCaughtAnimal()
	local t0 = os.clock()
	local species = nil
	-- 1. Doi the reveal toi da 20s — khong thay the = khong co catch.
	while os.clock() - t0 < 20 do
		local found = TFFA.findGuiTexts("NEW!")
		if #found > 0 then break end
		-- The reveal co the chi hien ten loai + $/s ma khong co chu NEW!.
		task.wait(0.5)
		if os.clock() - t0 > 20 then break end
	end
	-- 2. Doc ten loai tu the reveal: TextLabel lon nhat vua xuat hien ma
	-- ten thuoc ANIMAL_SET.
	local gui = TFFA.getPlayerGui()
	if gui then
		for _, inst in ipairs(gui:GetDescendants()) do
			if inst:IsA("TextLabel") and TFFA.isVisible(inst) then
				local ok, text = pcall(function() return inst.Text end)
				if ok and type(text) == "string" and TFFA.ANIMAL_SET[text] then
					species = text
					break
				end
			end
		end
	end
	if not species then
		TFFA.log("Khong doc duoc the reveal (khong thay ten loai) - co the nem truot.")
		TFFA.State.Misses = TFFA.State.Misses + 1
		return false
	end
	TFFA.log("The reveal: vua bat duoc", species)
	-- 3. Poll Workspace moi 1-2s tim dung con do (khong duoi Plots, khong
	-- InfoBillboard = khong phai thu tren plot). Thu dang di toi cho do an.
	local target = nil
	local targetModel = nil
	local pollEnd = os.clock() + 60
	while os.clock() < pollEnd do
		for _, child in ipairs(Workspace:GetDescendants()) do
			if child:IsA("Model") and child.Name == species then
				local underPlots = false
				local cur = child.Parent
				while cur do
					if cur.Name == "Plots" then underPlots = true; break end
					cur = cur.Parent
				end
				if not underPlots then
					local hasBillboard = false
					for _, desc in ipairs(child:GetDescendants()) do
						if desc:IsA("BillboardGui") then hasBillboard = true; break end
					end
					if not hasBillboard then
						local primary = child.PrimaryPart
						if primary then
							target = primary.Position
							targetModel = child
							break
						end
					end
				end
			end
		end
		if target then break end
		task.wait(1.5)
	end
	if not target or not targetModel then
		TFFA.log("Khong thay model", species, "ngoai san sau 60s - bo qua.")
		TFFA.State.Misses = TFFA.State.Misses + 1
		return false
	end
	local landZ = target.Z
	TFFA.State.LastLandZ = landZ
	TFFA.State.LastBiome = TFFA.biomeFromZ(landZ)
	TFFA.log("Thu roi tai Z=" .. string.format("%.0f", landZ)
		.. " biome=" .. TFFA.State.LastBiome .. " loai=" .. species)
	-- Ghi bang hoc duoc: power nho nhat tung toi duoc moi biome.
	local power = TFFA.State.ThrowPower
	if power then
		local known = TFFA.State.LearnedPower[TFFA.State.LastBiome]
		if not known or power < known then
			TFFA.State.LearnedPower[TFFA.State.LastBiome] = power
		end
	end
	table.insert(TFFA.State.ThrowHistory, { biome = TFFA.State.LastBiome, z = landZ })
	if #TFFA.State.ThrowHistory > 50 then table.remove(TFFA.State.ThrowHistory, 1) end
	-- 4. Di toi DIEM ROI (tinh), timeout ti le theo khoang cach:
	-- |landZ|/16*1.5 + 15s. Neu diem roi qua xa (>800) thi teleport ho tro.
	local dist = math.abs(landZ) + 40
	local timeout = dist / 16 * 1.5 + TFFA.Config.CollectTimeoutBase
	local root = TFFA.getRootPart()
	if root and math.abs(landZ) > 800 and TFFA.canTeleport() then
		TFFA.log("Diem roi xa (|Z| > 800) - teleport ho tro toi gan diem roi.")
		TFFA.teleportTo(Vector3.new(0, 3, landZ + 20), "diem roi xa")
	end
	local ok = TFFA.moveTo(CFrame.new(target), timeout)
	if not ok then
		-- Thu co the da di toi gan hon trong luc minh di: thu lai 1 lan
		-- voi vi tri moi nhat cua no.
		local primary = targetModel.PrimaryPart
		if primary then
			ok = TFFA.moveTo(CFrame.new(primary.Position), 20)
		end
	end
	task.wait(1.5)
	-- 5. Xac minh: model bien mat khoi Workspace moi tinh la da nhat.
	local gone = not targetModel:IsDescendantOf(Workspace)
	if ok and gone then
		TFFA.State.Catches = TFFA.State.Catches + 1
		TFFA.noteProgress()
		TFFA.log("Da nhat duoc", species)
		return true
	end
	TFFA.log("Chua xac minh duoc da nhat", species, "(moveTo:", tostring(ok), ", model bien mat:", tostring(gone), ")")
	return false
end

-- ============================================================================
--  Train — tap tu dong khi dung tren pad; thoat bang nut STOP do.
--  Xac minh da vao tap trong 30s dau (nut STOP hien hoac Power/Level tang).
-- ============================================================================
function TFFA.trainCycle()
	if not TFFA.goTrainingSpot() then
		TFFA.log("Khong toi duoc TrainingSpot - bo qua vong tap")
		return false
	end
	-- Reset moc thoi gian: tranh break "tap cham" oan do di duong lau.
	TFFA.State.LastLevelUpAt = os.clock()
	local power0, level0 = TFFA.readPowerLevel()
	local powerStart = power0
	local lastPowerCheck = os.clock()
	local lastPower = power0
	local lastGainCheck = os.clock()
	-- 1. Xac minh da vao tap trong 30s: nut STOP xuat hien hoac Power tang.
	local started = false
	local tStart = os.clock()
	while os.clock() - tStart < 30 do
		if TFFA.findButtonByText("STOP") then started = true; break end
		local p = TFFA.readPowerLevel()
		if p and powerStart and p > powerStart then started = true; break end
		if p and not powerStart then started = true; break end
		task.wait(1)
	end
	if not started then
		TFFA.log("KHONG VAO DUOC CHE DO TAP sau 30s (khong thay nut STOP, Power khong tang).")
		TFFA.log("  Co the xa van khoa (chua xong tutorial) hoac dung lech pad - bo vong tap.")
		return false
	end
	TFFA.log("Da vao che do tap.")
	local duration = TFFA.Config.TrainMaxMinutes * 60
	local t0 = os.clock()
	local lastBonusTap = 0
	while os.clock() - t0 < duration do
		if not TFFA.Config.Enabled or TFFA.State.StopFlag then break end
		-- Kiem tra con trong zone 10x10 khong; ra ngoai thi ket thuc vong tap.
		local root = TFFA.getRootPart()
		local center = TFFA.State.MyPlotCenter
		if root and center then
			local spot = center + TFFA.ANCHORS.TrainingOffset
			if TFFA.distXZ(root.Position, spot) > 10 then
				TFFA.log("Nhan vat roi khoi vung tap - ket thuc vong tap.")
				break
			end
		end
		-- Tap bonus: tim dung nut popup (khong dung chuoi con "TAP" vi trung
		-- "TAP TO THROW"), poll 0.2-0.3s, moi popup chi bam 1 lan.
		if TFFA.Config.AutoTapBonus and os.clock() - lastBonusTap > 2 then
			local bonusBtn = TFFA.findButtonByText("TAP!")
				or TFFA.findButtonByText("BONUS")
				or TFFA.findButtonByText("x2!")
			if bonusBtn then
				lastBonusTap = os.clock()
				TFFA.clickButton(bonusBtn)
			end
		end
		if os.clock() - lastPowerCheck > TFFA.Config.PowerCheckEvery then
			lastPowerCheck = os.clock()
			local power, level = TFFA.readPowerLevel()
			if level and level0 and level > level0 then
				TFFA.State.LastLevelUpAt = os.clock()
				TFFA.log("Len level:", tostring(level), "power:", tostring(power))
			end
			if level then level0 = level end
			if power then
				TFFA.State.ThrowPower = power
				if lastPower and power > lastPower then
					TFFA.State.LastLevelUpAt = os.clock()
				end
				lastPower = power
			end
			-- Thoat som: du Power toi biome tiep theo (muc tieu hoc duoc).
			local targetPower = TFFA.targetPower()
			if targetPower and power and power >= targetPower then
				TFFA.log("Du Power toi biome tiep theo (", tostring(power), " >= ", tostring(targetPower), ") - dung tap.")
				break
			end
			-- Thoat som: toc do tang Power qua cham 2 lan check lien tiep.
			if os.clock() - lastGainCheck > 60 then
				lastGainCheck = os.clock()
				if powerStart and power then
					local mins = (os.clock() - t0) / 60
					if mins > 1 then
						local rate = (power - powerStart) / mins
						if rate < TFFA.Config.TrainMinGainPerMin then
							TFFA.log("Toc do tang Power cham (", string.format("%.0f", rate),
								"/phut) - xa hien tai yeu, dung tap de xem xet nang xa.")
							break
						end
					end
				end
			end
			if os.clock() - TFFA.State.LastLevelUpAt > TFFA.Config.TrainSlowSeconds then
				TFFA.log("Tap cham qua (khong len level/Power > 3 phut) - doi sang nem.")
				break
			end
		end
		task.wait(TFFA.triDelay(0.8, 1.6))
	end
	-- Thoat xa: bam nut STOP do trong UI (cach game day), khong dung remote.
	local stopBtn = TFFA.findButtonByText("STOP")
	if stopBtn then
		TFFA.clickButton(stopBtn, function()
			return TFFA.findButtonByText("STOP") == nil
		end)
		task.wait(1)
	end
	-- Dam bao dung day khoi ghe truoc khi di tiep.
	local _, humanoid = TFFA.getCharacter()
	if humanoid and humanoid.Sit then
		pcall(function()
			humanoid.Sit = false
			humanoid.Jump = true
		end)
		task.wait(0.7)
	end
	return true
end

-- Power can de toi biome tiep theo sau biome tot nhat tung dat (bang hoc
-- duoc). Chua co du lieu thi tra nil (DECIDE se nem calibration 1 phat).
function TFFA.targetPower()
	local best = nil
	local bestIdx = 0
	for i, b in ipairs(TFFA.BIOMES) do
		if TFFA.State.LearnedPower[b.Name] then
			if i > bestIdx then bestIdx = i; best = b.Name end
		end
	end
	if not best then return nil end
	local nextBiome = TFFA.BIOMES[bestIdx + 1]
	if not nextBiome then return nil end
	local known = TFFA.State.LearnedPower[nextBiome.Name]
	if known then return known end
	-- Chua biet biome tiep theo can bao nhieu: muc tieu tam = power hien
	-- tai + 100 (tap them 1 chut roi nem thu).
	local power = TFFA.State.ThrowPower
	if power then return power + 100 end
	return nil
end


-- ============================================================================
--  Quan ly plot / ban / mua — di qua GUI CUA GAME.
-- ============================================================================
-- Mo panel My Animals: nut Animals tren HUD la ImageButton icon chan thu
-- KHONG CO TEXT (tim bang Text khong bao gio thay). Poll toi da 8s cho
-- nut EQUIP BEST xuat hien trong dung panel.
function TFFA.equipBest()
	local incomeBefore = TFFA.readPlotIncome()
	local btn = TFFA.findImageButton("Animal") or TFFA.findImageButton("Paw")
		or TFFA.findButtonByText("Animals")
	if not btn then
		TFFA.log("Khong tim thay nut Animals tren HUD (icon chan thu) - khong mo duoc panel.")
		return false
	end
	local opened = TFFA.clickButton(btn, function()
		return TFFA.findButtonByText("EQUIP BEST") ~= nil
	end)
	if not opened then
		-- Panel co the mo nhung nut EQUIP BEST o trang thai khac: poll them.
		local t0 = os.clock()
		while os.clock() - t0 < 8 do
			if TFFA.findButtonByText("EQUIP BEST") then opened = true; break end
			task.wait(0.3)
		end
	end
	if not opened then
		TFFA.log("Mo panel Animals nhung khong thay nut EQUIP BEST sau 8s - bo qua.")
		return false
	end
	local equipBtn = TFFA.findButtonByText("EQUIP BEST")
	local clicked = TFFA.clickButton(equipBtn, function()
		-- Xac minh: thu nhap plot khong giam sau khi equip.
		task.wait(1)
		local incomeAfter = TFFA.readPlotIncome()
		if incomeBefore and incomeAfter then return incomeAfter >= incomeBefore end
		return true
	end)
	task.wait(1)
	local incomeAfter = TFFA.readPlotIncome()
	if incomeBefore and incomeAfter and incomeAfter < incomeBefore then
		TFFA.log("CANH BAO: thu nhap plot GIAM sau EQUIP BEST ("
			.. TFFA.formatMoney(incomeBefore) .. " -> "
			.. TFFA.formatMoney(incomeAfter) .. ") - kiem tra lai bang tay.")
		return false
	end
	TFFA.log("Da bam EQUIP BEST (plot: "
		.. (incomeAfter and TFFA.formatMoney(incomeAfter) .. "/s" or "?") .. ")")
	TFFA.noteProgress()
	return clicked
end

-- Ban: di toi vong do ActivationCircle (Y=2.61) -> menu Sell Animals tu mo
-- -> bam SELL ALL -> bam nut XAC NHAN ("Sell N animals for $X?") ->
-- xac minh tien tang hoac menu bao "NO ANIMALS IN BACKPACK".
function TFFA.sellAll()
	local backpackBefore = TFFA.countBackpackAnimals()
	if backpackBefore == 0 then
		TFFA.log("Backpack trong - khong co gi de ban.")
		return true
	end
	-- BAT BUOC: EQUIP BEST truoc roi moi ban (khong thi ban mat thu ngon).
	if TFFA.Config.AutoEquipBest then
		if not TFFA.equipBest() then
			TFFA.log("EQUIP BEST that bai - KHONG BAN de khoi mat thu ngon.")
			return false
		end
	end
	local moneyBefore = TFFA.readMoney()
	if not TFFA.goSell() then
		TFFA.log("Khong toi duoc quai SELL - bo qua ban.")
		return false
	end
	-- Poll toi da 8s cho menu Sell + nut SELL ALL (khong cho cung 2s).
	local sellBtn = nil
	local t0 = os.clock()
	while os.clock() - t0 < 8 do
		sellBtn = TFFA.findButtonByText("SELL ALL")
		if sellBtn then break end
		task.wait(0.3)
	end
	if not sellBtn then
		TFFA.log("Khong thay nut SELL ALL sau 8s - bo qua ban.")
		return false
	end
	local clicked = TFFA.clickButton(sellBtn)
	if not clicked then
		TFFA.log("Khong bam duoc SELL ALL.")
		return false
	end
	-- Hop xac nhan xuat hien: bam YES/CONFIRM/SELL (poll 5s).
	local confirmBtn = nil
	local t1 = os.clock()
	while os.clock() - t1 < 5 do
		confirmBtn = TFFA.findButtonByText("YES")
			or TFFA.findButtonByText("CONFIRM")
			or TFFA.findButtonByText("SELL")
		if confirmBtn then break end
		task.wait(0.3)
	end
	if confirmBtn then
		TFFA.clickButton(confirmBtn)
	else
		TFFA.log("Khong thay hop xac nhan sau SELL ALL (co the game khong hoi) - kiem tra tien.")
	end
	task.wait(1.5)
	local moneyAfter = TFFA.readMoney()
	local backpackAfter = TFFA.countBackpackAnimals()
	if moneyBefore and moneyAfter and moneyAfter > moneyBefore then
		TFFA.log("Da ban", tostring(backpackBefore - backpackAfter), "thu, +",
			TFFA.formatMoney(moneyAfter - moneyBefore))
		TFFA.noteProgress()
		return true
	end
	if backpackAfter < backpackBefore then
		TFFA.log("Da ban", tostring(backpackBefore - backpackAfter), "thu (tien doc khong on dinh).")
		TFFA.noteProgress()
		return true
	end
	TFFA.log("Chua xac minh duoc da ban xong (tien/backpack khong doi) - kiem tra bang tay.")
	return false
end

-- Quet gia LIVE tu Shop UI: moi the co ten mon + gia $ + nut (BUY/EQUIP/
-- EQUIPPED). Tra ve map ten -> {price, button, status}. FOOD_LADDER chi la
-- fallback khi scan that bai.
function TFFA.scanShopPrices()
	local gui = TFFA.getPlayerGui()
	if not gui then return {} end
	local out = {}
	for _, inst in ipairs(gui:GetDescendants()) do
		if inst:IsA("TextLabel") then
			local ok, text = pcall(function() return inst.Text end)
			if ok and type(text) == "string" and TFFA.FOOD_SET[text] then
				local card = TFFA.findCardByName(text)
				if card then
					local price = nil
					local button = nil
					local status = "?"
					for _, desc in ipairs(card:GetDescendants()) do
						if desc:IsA("TextLabel") then
							local ok2, t2 = pcall(function() return desc.Text end)
							if ok2 and type(t2) == "string" and string.find(t2, "%$") then
								local v = TFFA.parseMoney(t2)
								if v and v >= 0 then price = v end
							end
						end
						if desc:IsA("TextButton") or desc:IsA("ImageButton") then
							local ok3, t3 = pcall(function() return desc.Text end)
							if ok3 and type(t3) == "string" and t3 ~= "" then
								local up = string.upper(t3)
								if string.find(up, "BUY") or string.find(up, "EQUIP") then
									button = desc
									status = t3
								end
							end
						end
					end
					out[text] = { price = price, button = button, status = status }
				end
			end
		end
	end
	return out
end

-- Mua/equip mon an theo THE (khong bam nut BUY dau tien tim duoc).
--  - Mon gia 0 hoac da so huu -> nhanh EQUIP (khong phai BUY).
--  - Mon chua mua -> chi bam nut trong dung the cua mon do; xac minh kep:
--    tien tru DUNG bang gia live VA mon xuat hien trong Backpack.
function TFFA.tryBuyFood(name)
	if not name or name == "" then return false end
	local entry = nil
	for _, e in ipairs(TFFA.FOOD_LADDER) do
		if e.Name == name then entry = e; break end
	end
	local ladderPrice = entry and entry.Price or nil
	if not TFFA.goFoodShop() then
		TFFA.log("Khong toi duoc Food Shop - bo qua mua", name)
		return false
	end
	-- Poll toi khi Shop mo (thay label ten mon trong PlayerGui), toi da 10s.
	local shopOpen = false
	local t0 = os.clock()
	while os.clock() - t0 < 10 do
		if #TFFA.findGuiTexts(name) > 0 then shopOpen = true; break end
		for _, food in ipairs(TFFA.ALL_FOODS) do
			if #TFFA.findGuiTexts(food) > 0 then shopOpen = true; break end
		end
		if shopOpen then break end
		task.wait(0.3)
	end
	if not shopOpen then
		TFFA.log("Shop khong mo sau 10s (khong thay ten mon an nao) - bo qua mua.")
		return false
	end
	local scan = TFFA.scanShopPrices()
	local cardInfo = scan[name]
	if not cardInfo then
		TFFA.log("Mon", name, "khong hien trong Shop luc nay (Shop chi hien 3 mon).")
		TFFA.log("  Hay mua mon tiep theo dung thu tu game thay vi mon nay.")
		return false
	end
	local status = string.upper(cardInfo.status or "")
	-- Nhanh EQUIP: mon da so huu hoac gia 0 (Carrot free, da equip san).
	if string.find(status, "EQUIP") or (ladderPrice == 0) then
		local btn = cardInfo.button
		if not btn then
			TFFA.log("The cua", name, "khong co nut EQUIP - bo qua.")
			return false
		end
		local ok = TFFA.clickButton(btn, function()
			return TFFA.heldFood() == name or TFFA.equipFood(name)
		end)
		if ok then
			TFFA.log("Da EQUIP", name)
			TFFA.noteProgress()
			return true
		end
		TFFA.log("Khong bam duoc nut EQUIP cua", name)
		return false
	end
	-- Nhanh BUY: chi mua khi tien >= 1.5x gia live (uu tien gia live).
	local price = cardInfo.price or ladderPrice
	if not price then
		TFFA.log("Khong doc duoc gia live cua", name, "- khong doan gia, bo qua.")
		return false
	end
	local money = TFFA.readMoney()
	if not money then
		TFFA.log("Khong doc duoc tien - khong mua", name, "(so mua nham).")
		return false
	end
	if money < price * 1.5 then
		TFFA.log("Chua du tien mua", name, "(", TFFA.formatMoney(price),
			" can >= ", TFFA.formatMoney(price * 1.5), ", dang co ",
			TFFA.formatMoney(money), ")")
		return false
	end
	local btn = cardInfo.button
	if not btn then
		TFFA.log("The cua", name, "khong co nut BUY - bo qua.")
		return false
	end
	local moneyBefore = money
	local clicked = TFFA.clickButton(btn)
	if not clicked then
		TFFA.log("Khong bam duoc nut BUY cua", name)
		return false
	end
	-- KHONG bam them lan 2 (khong co hop YES nao duoc xac nhan; lan 2 co
	-- the mua luon mon tiep theo sau khi Shop render lai).
	task.wait(1.5)
	-- Xac minh kep: tien tru dung bang gia live VA mon vao Backpack.
	local moneyAfter = TFFA.readMoney()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local hasItem = backpack and backpack:FindFirstChild(name) ~= nil
	if moneyAfter and moneyBefore and (moneyBefore - moneyAfter) >= price * 0.9
		and (moneyBefore - moneyAfter) <= price * 1.1 and hasItem then
		TFFA.log("Da mua", name, "gia", TFFA.formatMoney(price))
		TFFA.noteProgress()
		-- Mua xong phai bam EQUIP trong the moi dung duoc mon.
		local scan2 = TFFA.scanShopPrices()
		local info2 = scan2[name]
		if info2 and info2.button and string.find(string.upper(info2.status or ""), "EQUIP") then
			TFFA.clickButton(info2.button)
		end
		return true
	end
	TFFA.log("Mua", name, "chua xac minh duoc (tien tru:", tostring(moneyBefore),
		"->", tostring(moneyAfter), ", trong Backpack:", tostring(hasItem), ")")
	return false
end

-- Nang xa: dung len be vang canh xa (khong phai trong Shop). Chi chay khi
-- AutoUpgradeBar=true (mac dinh TAT — chua kiem chung live banner).
function TFFA.upgradeBar()
	if not TFFA.Config.AutoUpgradeBar then return false end
	if not TFFA.goBarUpgradePad() then return false end
	task.wait(2)
	-- Banner "Upgraded to ... Bar!" hoac "NEW EQUIPMENT!" la tin hieu thanh cong.
	if #TFFA.findGuiTexts("Upgraded to") > 0 or #TFFA.findGuiTexts("NEW EQUIPMENT") > 0 then
		TFFA.log("Da nang xa (thay banner).")
		TFFA.noteProgress()
		return true
	end
	TFFA.log("Khong thay banner nang xa - co the chua du tien hoac be vang o vi tri khac.")
	return false
end

-- Hoan doi plot: ban con yeu nhat tren plot chi khi con moi >= 1.5x no
-- (tru hao phi ban). Ban le qua nut SELL trong panel Animals (chua kiem
-- chung live) nen chi log de xuat, khong tu ban.
function TFFA.maybeSwapPlot()
	local plotAnimals = TFFA.readPlotAnimals()
	if #plotAnimals < TFFA.Config.PlotCapacity then return false end
	local weakest = nil
	for _, a in ipairs(plotAnimals) do
		if a.income and (not weakest or a.income < weakest.income) then weakest = a end
	end
	if not weakest then return false end
	TFFA.log("Plot day (", tostring(#plotAnimals), " con). Yeu nhat:",
		weakest.species, TFFA.formatMoney(weakest.income or 0) .. "/s")
	TFFA.log("  De xuat: giu lai thu moi nao >= "
		.. TFFA.formatMoney((weakest.income or 0) * 1.5)
		.. "/s roi dung EQUIP BEST de thay the tu dong. KHONG ban tay con yeu.")
	return false
end

-- Claim offline earnings + qua free khi vao game (chi khi remote duoc bat).
function TFFA.claimOffline()
	if not TFFA.Config.AutoClaimOffline then
		TFFA.log("AutoClaimOffline TAT (bat sau khi recon xac nhan Offline_Claim).")
		return false
	end
	local ok, res = TFFA.safeInvokeNoArg("Offline_Claim")
	if ok then
		TFFA.log("Da claim offline earnings:", tostring(res))
		return true
	end
	return false
end

-- Mon tiep theo nen mua: mon re nhat chua co ma co the mua (tien >= 1.5x).
-- Uu tien nhay tier (mon dau tier moi) hon mua moi mon trong tier.
function TFFA.nextFoodToBuy()
	local owned = {}
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then owned[tool.Name] = true end
		end
	end
	local money = TFFA.readMoney() or 0
	local best = nil
	local bestTier = -1
	for _, e in ipairs(TFFA.FOOD_LADDER) do
		if not owned[e.Name] and e.Price > 0 and money >= e.Price * 1.5 then
			if e.Tier > bestTier then best = e; bestTier = e.Tier end
		end
	end
	return best
end


-- ============================================================================
--  FSM — DECIDE la "nao", moi state chi lam 1 viec roi quay ve DECIDE.
--  Thu tu uu tien (theo thu tu game day, khong phai thu tu code cu):
--   1. Chua co mon an nao -> BUY_FIRST_FOOD (equip Carrot free)
--   2. Co thu trong Backpack chua len plot + con slot -> PLACE (EQUIP BEST)
--   3. Backpack >= BackpackSellAt hoac plot day -> EQUIP roi SELL
--   4. TRAIN vs THROW theo bang LearnedPower (du lieu do duoc, khong theo
--      cam tinh): chua co du lieu -> 1 phat nem hieu chuan; du power -> nem
--      toi da ThrowsPerDecision phat; thieu power -> tap; 3 lan truot lien
--      tiep -> tap ngan roi IDLE hoi nguoi dung.
--   5. UPGRADE uu tien thap nhat, 1 mon moi lan DECIDE.
--   6. Ca 2 toggle TAT -> IDLE, log ro rang.
--  RECOVER khong teleport ve Spawn mac dinh (chi khi that su ket hoac mat
--  plot) — teleport ve Spawn roi di bo lai la 1 phan cua cam giac "di tum lum".
-- ============================================================================
TFFA.States = {}

function TFFA.States.BOOT()
	TFFA.log("=== TFFA Main boot:", TFFA.BUILD, "===")
	TFFA.log("GUI-first | Remote mac dinh TAT | Ban nay choi theo thu tu game day (nem -> nhat -> dat plot -> mua food -> tap xa).")
	if getgenv and getgenv().__TFFA then
		TFFA.log("CANH BAO: ban recon van dang chay (getgenv().__TFFA) — AFK nudge cua no se danh nhau voi Main.")
		TFFA.log("  Hay tat recon truoc: getgenv().__TFFA.Stop()")
	end
	local gui = TFFA.getPlayerGui()
	if not gui then
		TFFA.log("PlayerGui chua load xong - doi 5s roi thu lai.")
		task.wait(5)
	end
	local plot, center = TFFA.findMyPlot()
	TFFA.State.MyPlot = plot
	TFFA.State.MyPlotCenter = center
	if plot then
		TFFA.State.MyPlotNumber = tonumber(plot.Name:match("Plot%s*(%d+)"))
	end
	local money = TFFA.readMoney()
	local power, level = TFFA.readPowerLevel()
	local income = TFFA.readPlotIncome()
	local remotes = TFFA.getRemotesFolder()
	local remoteCount = 0
	if remotes then
		for _ in ipairs(remotes:GetChildren()) do remoteCount = remoteCount + 1 end
	end
	TFFA.log("PROBE | Plot:", plot and plot.Name or "?",
		"| Tien:", money and TFFA.formatMoney(money) or "?",
		"| Power:", power and tostring(power) or "UNKNOWN (binh thuong neu dang o Lobby - Power chi hien trong panel Power/luc tap/nem)",
		"| Level:", level and tostring(level) or "?",
		"| Thu nhap plot:", income and TFFA.formatMoney(income) .. "/s" or "?",
		"| Remotes:", tostring(remoteCount),
		"| Remote calls:", TFFA.Config.RemoteCallsEnabled and "BAT" or "TAT")
	if TFFA.Config.RemoteCallsEnabled then
		-- Probe read-only dau tien de kiem tra pipeline remote.
		TFFA.safeInvokeNoArg("Animations_Get")
	end
	TFFA.State.Status = "Dang chay"
	return "DECIDE"
end

function TFFA.States.DECIDE()
	TFFA.State.DecideCycles = TFFA.State.DecideCycles + 1
	-- Gioi han phien: chay SessionMinutes phut roi nghi BreakMinutes phut.
	if os.clock() - TFFA.State.SessionStartedAt > TFFA.Config.SessionMinutes * 60 then
		TFFA.log("Het phien farm ", tostring(TFFA.Config.SessionMinutes),
			" phut - nghi ", tostring(TFFA.Config.BreakMinutes), " phut roi chay tiep.")
		TFFA.State.SessionStartedAt = os.clock()
		return "IDLE"
	end
	if not TFFA.Config.Enabled or TFFA.State.StopFlag then return "STOPPED" end
	if not TFFA.Config.AutoTrain and not TFFA.Config.AutoThrow then
		TFFA.log("Ca 2 toggle (luyen + nem) deu TAT - dung yen cho lenh.")
		return "IDLE"
	end
	-- Snapshot moi (doc lai GUI moi lan, khong dung gia tri cu).
	local money = TFFA.readMoney()
	local power, level = TFFA.readPowerLevel()
	if money then TFFA.State.Money = money end
	if power then TFFA.State.ThrowPower = power end
	if level then TFFA.State.Level = level end
	TFFA.State.PlotIncomePerSec = TFFA.readPlotIncome()
	local plotAnimals = TFFA.readPlotAnimals()
	local backpackAnimals = TFFA.countBackpackAnimals()
	local backpackFoods = TFFA.countBackpackFoods()
	local bestFood = TFFA.bestOwnedFood()
	-- 1. Chua co mon an nao -> EQUIP Carrot free (truong hop cua Brian: $0, tui trong).
	if not bestFood and backpackFoods == 0 then
		return "BUY_FIRST_FOOD"
	end
	-- 2. Co thu trong Backpack + con slot tren plot -> dat len plot truoc.
	if backpackAnimals > 0 and #plotAnimals < TFFA.Config.PlotCapacity then
		return "PLACE"
	end
	-- 3. Backpack day hoac plot day -> EQUIP roi SELL.
	if backpackAnimals >= TFFA.Config.BackpackSellAt or #plotAnimals >= TFFA.Config.PlotCapacity then
		return "SELL"
	end
	-- 4. TRAIN vs THROW.
	if TFFA.Config.AutoThrow and TFFA.Config.AutoTrain then
		local targetPower = TFFA.targetPower()
		if targetPower == nil then
			-- Chua co du lieu biome nao: 1 phat nem hieu chuan.
			if TFFA.State.Throws == 0 then return "THROW" end
			-- Sau phat hieu chuan van chua co du lieu -> tap 1 vong ngan.
			return "TRAIN"
		end
		if TFFA.State.ThrowPower and TFFA.State.ThrowPower >= targetPower then
			return "THROW"
		end
		if TFFA.State.Misses >= TFFA.Config.MaxConsecMisses then
			TFFA.log("Nem truot ", tostring(TFFA.State.Misses),
				" lan lien tiep - co the Power chua du, di tap.")
			TFFA.State.Misses = 0
			return "TRAIN"
		end
		return "TRAIN"
	end
	if TFFA.Config.AutoThrow then return "THROW" end
	if TFFA.Config.AutoTrain then return "TRAIN" end
	return "IDLE"
end

function TFFA.States.BUY_FIRST_FOOD()
	-- Carrot free, da equip san tu dau game: viec can lam la EQUIP, khong
	-- phai mua. tryBuyFood se tu di nhanh EQUIP khi gia 0/da so huu.
	if TFFA.tryBuyFood("Carrot") then
		TFFA.noteProgress()
		return "DECIDE"
	end
	-- Thu truc tiep qua Backpack neu Shop that bai.
	if TFFA.equipFood("Carrot") then
		TFFA.log("Da equip Carrot truc tiep tu Backpack.")
		TFFA.noteProgress()
		return "DECIDE"
	end
	TFFA.log("Khong equip duoc Carrot. Hay mo Shop bang tay, bam EQUIP tren the Carrot, roi chay lai.")
	return "IDLE"
end

function TFFA.States.PLACE()
	if TFFA.equipBest() then
		TFFA.noteProgress()
	else
		TFFA.log("PLACE that bai - quay ve DECIDE (khong ban gi het).")
	end
	return "DECIDE"
end

function TFFA.States.SELL()
	if TFFA.sellAll() then TFFA.noteProgress() end
	return "DECIDE"
end

function TFFA.States.TRAIN()
	if TFFA.trainCycle() then TFFA.noteProgress() end
	return "DECIDE"
end

function TFFA.States.THROW()
	local throws = 0
	local done = false
	while throws < TFFA.Config.ThrowsPerDecision do
		if not TFFA.Config.Enabled or TFFA.State.StopFlag then break end
		local ok = TFFA.doOneThrow()
		if ok then
			throws = throws + 1
			local caught = TFFA.collectCaughtAnimal()
			if caught then
				TFFA.State.Misses = 0
				done = true
			end
			TFFA.randDelay()
		else
			break
		end
	end
	if not done and throws == 0 then
		TFFA.State.NoProgressCycles = TFFA.State.NoProgressCycles + 1
	end
	return "DECIDE"
end

function TFFA.States.UPGRADE()
	-- Uu tien thap nhat, 1 mon moi lan DECIDE.
	local nextFood = TFFA.nextFoodToBuy()
	if nextFood then
		TFFA.log("Mua nang cap:", nextFood.Name, TFFA.formatMoney(nextFood.Price))
		TFFA.tryBuyFood(nextFood.Name)
	else
		TFFA.log("Chua du tien mua mon tiep theo - tiep tuc farm.")
	end
	if TFFA.Config.AutoUpgradeBar then TFFA.upgradeBar() end
	return "DECIDE"
end

function TFFA.States.IDLE()
	-- Nghi giong nguoi giua cac vong (3-9s), lau hon sau moi 5 vong.
	local rest = TFFA.triDelay(3, 9)
	if TFFA.State.DecideCycles % TFFA.Config.IdleRestEveryCycles == 0 then
		rest = TFFA.triDelay(10, 20)
	end
	TFFA.log("Nghi", string.format("%.0f", rest), "s (vong DECIDE #",
		tostring(TFFA.State.DecideCycles), ")")
	task.wait(rest)
	return "DECIDE"
end

function TFFA.States.RECOVER()
	TFFA.State.RecoveryCount = TFFA.State.RecoveryCount + 1
	if TFFA.State.RecoveryCount > TFFA.Config.RecoverMaxConsec then
		TFFA.log("RECOVER that bai ", tostring(TFFA.Config.RecoverMaxConsec),
			" lan lien tiep - DUNG AN TOAN, gui log cho Muse.")
		return "STOPPED"
	end
	-- Ladder phuc hoi: L0 thu lai -> L1 dung + nhay -> L2 teleport toi dich
	-- gan nhat (khong phai Spawn) -> L3 teleport Spawn + probe mini ->
	-- L4 respawn -> L5 dung an toan. O day lam L2/L3 toi thieu:
	--  - Neu mat plot: tim lai plot.
	--  - Neu nhan vat ket: teleport toi Spawn roi quay ve DECIDE.
	local plot, center = TFFA.findMyPlot()
	if plot then
		TFFA.State.MyPlot = plot
		TFFA.State.MyPlotCenter = center
	end
	local root = TFFA.getRootPart()
	local _, humanoid = TFFA.getCharacter()
	if root and humanoid and humanoid.Health > 0 then
		TFFA.log("RECOVER: teleport ve Spawn roi quay ve DECIDE.")
		TFFA.teleportTo(TFFA.ANCHORS.Spawn, "recover")
	else
		TFFA.log("RECOVER: nhan vat khong hop le - doi respawn 10s.")
		task.wait(10)
	end
	task.wait(2)
	return "DECIDE"
end

function TFFA.States.STOPPED()
	TFFA.log("=== TFFA Main da dung. ===")
	TFFA.log("Thong ke: nem", tostring(TFFA.State.Throws), "lan, nhat",
		tostring(TFFA.State.Catches), "con, thu nhap plot",
		TFFA.State.PlotIncomePerSec and TFFA.formatMoney(TFFA.State.PlotIncomePerSec) .. "/s" or "?")
	return "STOPPED"
end

-- Dispatcher: moi state chay trong pcall rieng — 1 loi chi lam hong 1
-- state, khong giet ca vong farm (v1.x: 1 loi trong trainCycle giet ca vong).
function TFFA.step()
	local current = TFFA.CurrentState or "BOOT"
	local fn = TFFA.States[current]
	if not fn then
		TFFA.log("State khong ton tai:", tostring(current), "- ve DECIDE.")
		TFFA.CurrentState = "DECIDE"
		return true
	end
	local ok, next = pcall(fn)
	if not ok then
		TFFA.log("LOI o state", current, ":", tostring(next), "- chuyen sang RECOVER.")
		TFFA.State.StuckStreak = TFFA.State.StuckStreak + 1
		if TFFA.State.StuckStreak >= 5 then
			TFFA.log("StuckStreak >= 5 - DUNG AN TOAN.")
			TFFA.CurrentState = "STOPPED"
			return false
		end
		TFFA.CurrentState = "RECOVER"
		return true
	end
	TFFA.CurrentState = next
	if next == "STOPPED" then return false end
	return true
end

function TFFA.mainLoop()
	TFFA.State.Running = true
	TFFA.CurrentState = "BOOT"
	while TFFA.Config.Enabled and not TFFA.State.StopFlag do
		local ok = TFFA.step()
		if not ok then break end
		-- Watchdog: khong co tien bo that su trong 600s -> dung an toan.
		if os.clock() - TFFA.State.LastProgressAt > 600 then
			TFFA.log("WATCHDOG: khong co tien bo that su trong 600s - DUNG AN TOAN.")
			break
		end
		task.wait(0.2)
	end
	TFFA.State.Running = false
	TFFA.log("Farm da dung. Neu can chay lai, mo file va EXECUTE lai.")
end

-- ============================================================================
--  UI — 2 nut rieng (luyen / nem) + hien thi state + session timer.
-- ============================================================================
function TFFA.buildUI()
	local gui = TFFA.getPlayerGui()
	if not gui then return end
	local old = gui:FindFirstChild("TFFA_UI")
	if old then old:Destroy() end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TFFA_UI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = gui
	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.new(0, 220, 0, 280)
	frame.Position = UDim2.new(0, 10, 0, 60)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	local function makeLabel(name, text, y)
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.Size = UDim2.new(1, -10, 0, 20)
		lbl.Position = UDim2.new(0, 5, 0, y)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextSize = 13
		lbl.Font = Enum.Font.SourceSans
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = text
		lbl.Parent = frame
		return lbl
	end
	makeLabel("Title", "TFFA Main v2.0", 5)
	local statusLabel = makeLabel("Status", "Trang thai: " .. TFFA.State.Status, 25)
	local trainBtn = Instance.new("TextButton")
	trainBtn.Name = "TrainBtn"
	trainBtn.Size = UDim2.new(1, -10, 0, 34)
	trainBtn.Position = UDim2.new(0, 5, 0, 50)
	trainBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
	trainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	trainBtn.TextSize = 15
	trainBtn.Text = "Tap: " .. (TFFA.Config.AutoTrain and "BAT" or "TAT")
	trainBtn.Parent = frame
	local throwBtn = Instance.new("TextButton")
	throwBtn.Name = "ThrowBtn"
	throwBtn.Size = UDim2.new(1, -10, 0, 34)
	throwBtn.Position = UDim2.new(0, 5, 0, 90)
	throwBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
	throwBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	throwBtn.TextSize = 15
	throwBtn.Text = "Nem: " .. (TFFA.Config.AutoThrow and "BAT" or "TAT")
	throwBtn.Parent = frame
	local statsLabel = makeLabel("Stats", "Nem: 0 | Nhat: 0", 130)
	local sessionLabel = makeLabel("Session", "Phien: 0 phut", 150)
	local note = makeLabel("Note", "Tat recon truoc khi chay Main!", 175)
	note.TextColor3 = Color3.fromRGB(255, 200, 100)
	local stopBtn = Instance.new("TextButton")
	stopBtn.Name = "StopBtn"
	stopBtn.Size = UDim2.new(1, -10, 0, 30)
	stopBtn.Position = UDim2.new(0, 5, 0, 200)
	stopBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
	stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopBtn.TextSize = 14
	stopBtn.Text = "DUNG"
	stopBtn.Parent = frame
	trainBtn.MouseButton1Click:Connect(function()
		TFFA.Config.AutoTrain = not TFFA.Config.AutoTrain
		trainBtn.Text = "Tap: " .. (TFFA.Config.AutoTrain and "BAT" or "TAT")
		TFFA.log("Tap luyen:", TFFA.Config.AutoTrain and "BAT" or "TAT")
	end)
	throwBtn.MouseButton1Click:Connect(function()
		TFFA.Config.AutoThrow = not TFFA.Config.AutoThrow
		throwBtn.Text = "Nem: " .. (TFFA.Config.AutoThrow and "BAT" or "TAT")
		TFFA.log("Nem:", TFFA.Config.AutoThrow and "BAT" or "TAT")
	end)
	stopBtn.MouseButton1Click:Connect(function()
		TFFA.State.StopFlag = true
		TFFA.log("Nguoi dung bam DUNG.")
	end)
	task.spawn(function()
		while screenGui.Parent do
			task.wait(1)
			pcall(function()
				statusLabel.Text = "Trang thai: " .. (TFFA.CurrentState or "?")
				statsLabel.Text = "Nem: " .. tostring(TFFA.State.Throws)
					.. " | Nhat: " .. tostring(TFFA.State.Catches)
					.. " | Plot: " .. (TFFA.State.PlotIncomePerSec and TFFA.formatMoney(TFFA.State.PlotIncomePerSec) .. "/s" or "?")
				local mins = math.floor((os.clock() - TFFA.State.SessionStartedAt) / 60)
				sessionLabel.Text = "Phien: " .. tostring(mins) .. " phut / "
					.. tostring(TFFA.Config.SessionMinutes) .. " phut"
			end)
		end
	end)
end

-- ============================================================================
--  Anti-AFK — nhich nho 2-4 studs (khong click (0,0) de tranh bam nham UI),
--  bo qua khi dang ngoi tap, hoan lai khi dang nem. Jitter 420-660s.
-- ============================================================================
function TFFA.startAntiAfk()
	task.spawn(function()
		while not TFFA.State.StopFlag do
			task.wait(TFFA.randRange(420, 660))
			if TFFA.State.StopFlag then break end
			local _, humanoid = TFFA.getCharacter()
			if humanoid and not humanoid.Sit and not TFFA.State.Throwing then
				local ok = pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new(0, 0))
				end)
				if not ok then
					-- Fallback: nhich nho 2-4 studs thay vi click.
					local root = TFFA.getRootPart()
					if root then
						pcall(function()
							root.CFrame = root.CFrame + Vector3.new(
								TFFA.randRange(-2, 2), 0, TFFA.randRange(-2, 2))
						end)
					end
				end
				TFFA.log("[TFFA afk] Chong AFK (1 hanh dong).")
			end
		end
	end)
end

function TFFA.Stop()
	TFFA.State.StopFlag = true
	TFFA.Config.Enabled = false
	TFFA.log("TFFA Main da nhan lenh dung.")
end

-- ============================================================================
--  BOOT
-- ============================================================================
if getgenv then
	getgenv().__TFFA_MAIN = TFFA
end
TFFA.buildUI()
TFFA.startAntiAfk()
TFFA.mainLoop()

-- ============================================================================
--  K? HO?CH TEST TUNG PHA (dat getgenv().TFFA_MAIN_CONFIG truoc khi chay file;
--  DUNG va doc log sau moi pha; <= 5 phut/pha; pha nao that bai 2 lan lien
--  tiep thi dung va gui log + anh man hinh cho Muse):
--   Pha 0 Probe: mac dinh, dung tren plot cua minh.
--     PASS: log in "v2.0", plot dung, tien dung so voi HUD, Level dung,
--     meter hien khi nem tay 1 lan.
--   Pha 1 Buy Carrot: chi AutoUpgradeFood=true (tat cac toggle khac).
--     PASS: Carrot trong Backpack, tien khong doi.
--   Pha 2 Train 1 phut: chi AutoTrain=true, TrainMaxMinutes=1.
--     PASS: toi TrainingSpot, len xa, level/power tang, khong "Loi vong farm".
--   Pha 3 Throw 1 lan: chi AutoThrow=true, ThrowsPerDecision=1.
--     PASS: toi vach nem, thay meter, click >= 17, log "Thu roi tai Z=...
--     biome=...", di toi nhat.
--   Pha 4 Collect + place: AutoThrow + AutoEquipBest.
--     PASS: so thu tren plot +1, thu nhap plot thanh so $/s.
--   Pha 5 Sell: chi AutoSell=true, can >= 1 thu thua trong Backpack.
--     PASS: tien tang, thu tren plot khong bi ban.
--   Pha 6 Long farm: mac dinh, 15 phut, log "Nghi..." deu dan.
--     Chi chay dai hon khi Pha 6 pass. KHONG BAO GIO chay 24/7.
--  KHI BAO LOI, gui kem 3 thu:
--   1. Toan bo log console tu dong boot (gom khoi PROBE + MoneySource).
--   2. Anh man hinh game (trang thai 2 nut Tap/Nem, vi tri nhan vat, GUI nao dang mo).
--   3. 1 dong: dung o pha nao + thoi gian trong log.
-- ============================================================================
