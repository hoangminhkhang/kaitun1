--[[
    Bee Swarm Kaitun - guide-aware progression
    Place: Bee Swarm Simulator (1537690962)

    Main flow:
      Tele reward map -> Claim hive -> redeem material codes -> buy gear per bee milestone
      -> buy hive slot -> buy/hatch Basic Egg -> farm/convert -> repeat until target.

    Parallel: auto-buy event bees at the Ticket Shop in order Tabby -> Photon ->
    Cobalt -> Crimson as soon as tickets suffice (see EventBeeSequence + EventBeeShop loop).

    Early-game build leans blue per BSS Game Guide: prioritize sprinkler,
    Bubble Wand when macroing, Bubble Mask and endgame material preservation.
]]

if game.PlaceId ~= 1537690962 then
    warn("[BSS Kaitun] Wrong game. Current PlaceId: " .. tostring(game.PlaceId))
    return
end

repeat task.wait() until game:IsLoaded()

local ENV = (getgenv and getgenv()) or _G
local SYN = rawget(ENV, "syn")
local GetThreadIdentity = rawget(ENV, "getthreadidentity")
    or rawget(ENV, "get_thread_identity")
    or (type(SYN) == "table" and SYN.get_thread_identity)
local SetThreadIdentity = rawget(ENV, "setthreadidentity")
    or rawget(ENV, "set_thread_identity")
    or (type(SYN) == "table" and SYN.set_thread_identity)
if ENV.__BSS_KAITUN and type(ENV.__BSS_KAITUN.Shutdown) == "function" then
    pcall(ENV.__BSS_KAITUN.Shutdown)
    task.wait(0.25)
end
if ENV.__BSS_BEAR_QUEST and type(ENV.__BSS_BEAR_QUEST.Shutdown) == "function" then
    pcall(ENV.__BSS_BEAR_QUEST.Shutdown)
    task.wait(0.2)
end

local DEFAULT_CONFIG = {
    Enabled = true,
    FarmField = "Sunflower Field",
    ConvertPercent = 1,
    ConvertFinishPercent = 0.01,
    TweenSpeed = 85,
    TokenTweenSpeed = 145,
    SmartMove = true,
    FieldMoveSpeed = 120,
    SmartWalkDistance = 10,
    SmartArrivalDistance = 6,
    SmartFieldWalkTimeout = 12,
    -- SmartMove stuck recovery: after ~1.2s without progress inside a field
    -- (tree/rock/hedge), compute ONE PathfindingService route around the
    -- obstacle, walk its waypoints, then resume direct walking. Zero cost
    -- while walking freely; cooldown caps the ComputeAsync spend.
    SmartFieldPathfind = true,
    FieldPathfindCooldown = 6,
    FarmStepDelay = 0.25,
    DigInterval = 0.22,
    TokenMaxChaseDistance = 115,
    TokenFieldPadding = 4,
    TokenMinHeightFromField = -3,
    TokenMaxHeightFromField = 8,
    TokenAttemptCooldown = 1.5,
    TokenSweepDuration = 1.4,
    TokenMaxPerSweep = 4,
    TokenSearchDepth = 3,
    TokenSearchBreadth = 8,
    TokenDefaultLifetime = 20,
    TokenCollectDelay = 0.15,
    TokenLookaheadDiscount = 0.84,
    TokenTravelPenalty = 0.22,
    TokenUrgencyBonus = 0.45,
    AutoFarm = true,
    AutoConvert = true,
    AutoTokens = true,
    AutoMeteor = true,
    AutoTriggerMeteor = true,
    MeteorPartFallback = false,
    MeteorRequiredMythicTypes = 3,
    MeteorSummonerCooldown = 79200,
    MythicBeeTypes = {"Buoyant", "Fuzzy", "Precise", "Spicy", "Tadpole", "Vector"},
    AutoQuest = true,
    QuestNPCs = {"Mother Bear", "Black Bear", "Science Bear", "Polar Bear"},
    QuestFarmPriority = {"Mother Bear", "Black Bear", "Science Bear", "Polar Bear"},
    QuestNPCBeeRequirements = {["Science Bear"] = 10, ["Polar Bear"] = 25},
    -- Stop Black Bear right after the Diamond Egg quest ("Quest Of Legends").
    -- The line is strictly sequential, so an ACTIVE quest past that point proves
    -- the Diamond Egg was already claimed - detection works even for accounts
    -- that finished it long before running this script (no script history needed).
    BlackBearStopAfterQuest = "Quest Of Legends",
    -- Compact list of quests AFTER the Diamond Egg quest (Star Jelly + Mythic
    -- lines). Any of these active - or a repeatable "Black Bear: ..." quest -
    -- proves the Diamond Egg is already claimed. Parsed into a lookup set once.
    BlackBearPastQuests = "High Altitude|Blissfully Blue|Rouge Round-up|White As Snow"
        .. "|Solo On The Stump|Colorful Craving|Pumpkins, Please!|Smorgasbord"
        .. "|Pollen Fetcher 5|White Clover Redux|Strawberry Field Forever|Tasting The Sky"
        .. "|Whispy and Crispy|Walk Through The Woods|Get Red-y|One Stop On The Tip Top"
        .. "|Blue Mushrooms 2|Pretty Pumpkins|Black Bear, Why?|Bee A Star"
        .. "|Bamboo Boogie 2: Bamboo Boogaloo|Rocky Red Mountain|Can't Without Ants"
        .. "|The 15 Bee Zone|Bubble Trouble|Sweet And Sour|Rare Red Clover|Low Tier Treck"
        .. "|Okey-Pokey|Pollen Fetcher 6|Capsaicin Collector|Mountain Mix|You Blue It"
        .. "|Variety Fetcher 2|Getting Stumped|Weed Wacker 3|All-Whitey Then"
        .. "|Red Delicacy|Boss Battles|Myth In The Making",
    AutoQuestFeedTasks = true,
    AutoQuestJellyTasks = true,
    -- Auto treat: spend 10% of earned honey on treats and feed the lowest-level
    -- bee until the whole hive shares one level.
    AutoTreatBees = true,
    TreatBudgetPercent = 10,
    TreatCycleHours = 1,
    TreatHoneyCost = 10,
    TreatBuyChunk = 100,
    TreatWorkerInterval = 5,
    -- GIFTED RULES (wiki-verified, for the future gifted hunter):
    -- Only SPECIFIC treats can roll gifted, and only when fed to a bee whose
    -- favorite it is: Strawberries / Blueberries / Sunflower Seeds / Pineapples
    -- (bond 25, x2 = 50 when favorite; gifted odds 1/8000 rare, 1/10000 epic,
    -- 1/12000 common+legendary, 1/24000 mythic). Event bees only via Star Treat
    -- (100%). The generic "Treat" (bond 10, what this leveling system buys) is
    -- NO bee's favorite and can NEVER trigger gifted.
    -- Auto amulet: compares EACH STAT against the equipped amulet of the same type.
    -- Only replace when no stat is worse and at least one is better (strict win);
    -- otherwise (mixed or identical) -> keep. No made-up weights.
    AutoCompareAmulets = true,
    QuestJellyBatchMax = 5,
    -- Jelly quests only target non-gifted common bees so event/mythics stay safe.
    CommonBeeTypes = {"Basic", "Bumble", "Cool", "Hasty", "Rascal", "Stubborn"},
    QuestCheckInterval = 3,
    -- Quest snapshot TTL shared by every background system (feed worker, quest
    -- router, mob planner). Quest turn-ins always re-scan immediately.
    QuestScanInterval = 5,
    -- Mother Bear tasks run LIGHTLY in the background: at most one feed/jelly
    -- use per this many seconds, so field quests and farming stay the focus.
    MotherFeedInterval = 10,
    QuestInteractTimeout = 12,
    QuestFarmSeconds = 8,
    -- Farm burst length between quest/purchase checks: shorter bursts let quest
    -- turn-ins and affordable-gear purchases interleave sooner while farming.
    FarmBurstSeconds = 5,
    ScienceQuestConfirmTimeout = 6,
    AutoQuestMobs = true,
    QuestMobFightTimeout = 24,
    QuestMobSpawnWait = 12,
    QuestMobSpawnGrace = 15,
    QuestMobRecheckInterval = 20,
    AutoClaimBadges = true,
    BadgeClaimInterval = 1.25,
    AutoWealthClock = true,
    -- Free toys: only tap Free Ant Pass + Blue Field Booster (no Royal Jelly
    -- dispenser and no Red/Top booster by request). When a Blue boost is active,
    -- kaitun farms the boosted field.
    AutoFreeToys = true,
    AutoToys = {
        {Name = "Free Ant Pass Dispenser", Cooldown = 7200},
        {Name = "Blue Field Booster", Cooldown = 7200, FieldBoost = "Blue"},
    },
    -- Boosts only count for the 3 main blue fields; boosts on other fields are ignored.
    BoostedFieldWhitelist = {"Pine Tree Forest", "Blue Flower Field", "Bamboo Field"},
    -- RJ Gifted Farmer (tested standalone as rj_gifted_farm_test.lua v4): rolls
    -- Royal Jelly on one sacrifice cell with ONE request per roll - the exact
    -- call the game's auto-jelly spams (no Settings/toggle clicking needed).
    -- Gated on full Mountain Top gear + Bubble Mask, honey budget capped,
    -- quest reserve kept, stops at the gifted-type target.
    AutoRJGiftedFarm = true,
    RJShopHoneyBudget = 5000000000,
    RJQuestReserve = 5,
    RJTargetGiftedTypes = 15,
    RJBuyChunk = 100,
    RJMinStock = 20,
    RJRollDelay = 0.03,
    RJStockResyncEvery = 25,
    -- Auto RJ on NON-GIFTED BASIC bees only: Royal Jelly never rolls commons
    -- (0%), so every use upgrades a Basic into a Rare+ roll (1/250 gifts it).
    -- Basics are targeted exclusively because they carry no useful token; the
    -- other commons keep theirs, and quest jelly keeps RJQuestReserve. When
    -- stock is short the worker stands down and re-checks every 60s. Once the
    -- RJ Gifted Farmer's gate passes, it owns all RJ spending instead.
    AutoRJUpgradeBasic = true,
    -- Star Treat: 100% gifts a bee; event bees can ONLY be gifted this way.
    -- Used on the first non-gifted event bee in this order, keep going until
    -- every one of them is gifted (never stops early). When the stock is empty
    -- the script BUYS one from the Ticket Tent with tickets - but only after
    -- the whole event-bee egg queue is done (bees outrank gifting for tickets).
    AutoStarTreat = true,
    AutoBuyStarTreat = true,
    StarTreatTicketCost = 1000,
    StarTreatOrder = {"Tabby", "Photon", "Cobalt", "Crimson"},
    -- Mondo Chick: spawns hourly on Mountain Top, drops Bitterberry/Neonberry.
    AutoFarmMondoChick = true,
    MondoChickFightTimeout = 120,
    WealthClockInterval = 3600,
    WealthClockCheckInterval = 15,
    WealthClockRetryInterval = 60,
    BadgeNames = {
        "Pepper", "Coconut", "Playtime", "Honey", "Quest", "Battle", "Ability", "Goo",
        "Sunflower", "Dandelion", "Mushroom", "Blue Flower", "Clover", "Spider",
        "Bamboo", "Strawberry", "Pineapple", "Pumpkin", "Cactus", "Rose", "Pine Tree", "Stump",
    },
    AutoFarmLeaves = true,
    AutoFarmSparkles = true,
    SpecialEffectScanInterval = 1,
    SpecialEffectPriorityInterval = 20,
    SpecialEffectMaxDistance = 180,
    AvoidMob = true,
    MobScanRadius = 55,
    MobJumpInterval = 0.12,
    AvoidMobDamageThreshold = 0.5,
    AvoidMobRelocateCooldown = 2.5,
    AvoidMobRelocateDistance = 14,
    AvoidMobArrivalDistance = 5,
    AvoidMobRelocateTimeout = 4,
    -- Mob THREAT zone: only mobs closer than this pause farming and trigger the
    -- retreat/hold. Farming resumes once no mob sits inside the radius.
    MobThreatRadius = 16,
    MobThreatHoldSeconds = 4,
    AutoMaterials = true,
    AutoBlender = true,
    AutoFarmFireflies = true,
    FireflyScanInterval = 0.25,
    FireflyLandingVelocity = 0.15,
    FireflyMaxFieldHeight = 4,
    -- 8 fireflies/formation: nudging all 8 + collecting the center reward needs a
    -- bigger budget than the old 9s.
    FireflyFarmBudget = 18,
    FireflyTouchTimeout = 2.5,
    FireflyTokenWindow = 3,
    FireflyRetryCooldown = 1.25,
    AutoFarmSprouts = true,
    SproutScanInterval = 0.25,
    SproutFarmSlice = 3,
    SproutMaxFarmSeconds = 180,
    SproutDropWindow = 20,
    AutoFarmVicious = true,
    -- Damage-avoid strategy: fly above the Vicious (its spikes come from the ground)
    -- and hover there while bees attack.
    ViciousHoverHeight = 14,
    -- Always farm Vicious whenever one spawns (night), without waiting for the
    -- material planner. Only fight vic whose level is BELOW the hive average.
    AutoFarmViciousAlways = true,
    ViciousRespectHiveLevel = true,
    AutoMaterialPlanters = true,
    AutoNectarCondenser = true,
    MaterialFarmSeconds = 10,
    MaterialCombatSeconds = 18,
    MaterialStatsInterval = 2,
    MaterialPlanterHarvestPercent = 0.98,
    MaterialPlanterActionCooldown = 5,
    NectarCondenserCooldown = 10,
    BlenderCheckInterval = 2,
    BlenderMovePosition = Vector3.new(-431.53, 68.78, 41.02),
    AutoProgression = true,
    ProgressionTargetBees = 45,
    AutoBuyHiveSlots = true,
    AutoBuyBasicEggs = true,
    AutoBuyEventBees = true,
    AutoHatchEventBees = true,
    EventBeeCheckInterval = 0.5,
    EventBeeStatsRefreshInterval = 2,
    EventBeeRetryCooldown = 12,
    EventBeeSequence = {
        -- Package Types verified directly from Workspace.Shops.TicketShop.Items
        -- from the BSS place: {Category = "Eggs", Type = "TabbyBee"} ... Verified name
        -- first so executors that cannot require ItemPackages still buy correctly.
        {Shop = "Ticket Tent", Item = "Tabby Bee Egg", Category = "Eggs", Type = "Tabby", TicketCost = 500,
            PackageTypes = {"TabbyBee", "Tabby Bee", "Tabby"}},
        {Shop = "Ticket Tent", Item = "Photon Bee Egg", Category = "Eggs", Type = "Photon", TicketCost = 500,
            PackageTypes = {"PhotonBee", "Photon Bee", "Photon"}},
        {Shop = "Ticket Tent", Item = "Cobalt Bee Egg", Category = "Eggs", Type = "Cobalt", TicketCost = 250,
            PackageTypes = {"CobaltBee", "Cobalt Bee", "Cobalt"}},
        {Shop = "Ticket Tent", Item = "Crimson Bee Egg", Category = "Eggs", Type = "Crimson", TicketCost = 250,
            PackageTypes = {"CrimsonBee", "Crimson Bee", "Crimson"}},
    },
    -- Tele rewards (from telebss rewards.txt): on game entry, instantly teleport
    -- to each map reward point before claiming hive/hatching. Coordinates hand-tested.
    AutoTeleRewards = true,
    TeleRewardDwellSeconds = 2,
    TeleRewardSpots = {
        {Label = "Diamond Egg", CFrame = CFrame.new(42, 149, -531)},
        {Label = "Star Jelly", CFrame = CFrame.new(-413.77, 17.17, 467.18)},
        {Label = "Gold Egg", CFrame = CFrame.new(83.94, 68.01, -142.12)},
        {Label = "Star Jelly", CFrame = CFrame.new(-435.52, 93.26, 48.78)},
        {Label = "Star Jelly", CFrame = CFrame.new(-480.57, 69.39, -0.42)},
        {Label = "Ticket", CFrame = CFrame.new(5.215, 174.664, -96.96)},
        {Label = "Enzymes", CFrame = CFrame.new(-105.185, 71.711, 557.967)},
        {Label = "Enzymes", CFrame = CFrame.new(-115.21, 71.747, 558.186)},
        {Label = "Enzymes", CFrame = CFrame.new(-124.223, 71.747, 558.221)},
        {Label = "Jelly", CFrame = CFrame.new(87.597, 310.219, -294.334)},
        {Label = "Star Jelly", CFrame = CFrame.new(524.506, 151.902, -411.876)},
        {Label = "Glue", CFrame = CFrame.new(369.314, 84.816, -237.077)},
        {Label = "Jelly", CFrame = CFrame.new(110.861, 63.718, -59.578)},
        {Label = "Jelly", CFrame = CFrame.new(218.618, 35.427, -29.126)},
        {Label = "Jelly", CFrame = CFrame.new(263.946, 57.138, 108.369)},
        {Label = "Jelly", CFrame = CFrame.new(314.312, 61.638, 213.964)},
        {Label = "Jelly", CFrame = CFrame.new(34.864, 57.965, 190.511)},
        {Label = "Jelly", CFrame = CFrame.new(-64.232, 37.717, 113.388)},
        {Label = "Jelly", CFrame = CFrame.new(146.351, 37.496, 266.086)},
        {Label = "Bear Cookie", CFrame = CFrame.new(47.836, 52.594, 398.93)},
        {Label = "Enzymes", CFrame = CFrame.new(226.929, 25252.527, -716.011)},
        {Label = "Glitter", CFrame = CFrame.new(301.8563537597656, 25283.02734375, -807.7046508789062)},
        {Label = "Star Jelly", CFrame = CFrame.new(271.973, 25294.129, -871.085)},
        {Label = "Jelly", CFrame = CFrame.new(-189.317, 64.263, 367.295)},
        {Label = "Enzymes", CFrame = CFrame.new(3.3575220108032227, 304.2304992675781, -266.304931640625)},
        {Label = "Bloom Sake", CFrame = CFrame.new(329.359, 193.14, -234.35)},
        {Label = "Glitter", CFrame = CFrame.new(-336.5309143066406, 132.36778259277344, -384.9282531738281)},
        {Label = "Jelly", CFrame = CFrame.new(-357.5382080078125, 129.8998565673828, -227.21456909179688)},
        {Label = "Ticket", CFrame = CFrame.new(-232.84506225585938, 184.9242706298828, -249.955322265625)},
        {Label = "Bear Cookie", CFrame = CFrame.new(-465.8412780761719, 109.4454116821289, -175.78443908691406)},
        {Label = "Ticket", CFrame = CFrame.new(98.66006469726562, 35.20281219482422, 355.489013671875)},
        {Label = "Ticket", CFrame = CFrame.new(-374.18780517578125, 19.293209075927734, 494.7056884767185)},
        {Label = "Ticket", CFrame = CFrame.new(14.022793769836426, 4.5928144454956055, 68.14900207519531)},
        {Label = "Ticket", CFrame = CFrame.new(-54.35238265991211, 19.424358367919922, -62.27788543701172)},
        {Label = "Ticket", CFrame = CFrame.new(-380.6947021484375, 54.6801872253418, 206.6320037841797)},
        {Label = "Ticket", CFrame = CFrame.new(131.64907836914062, 117.50926208496094, -63.04363250732422)},
        {Label = "Ticket", CFrame = CFrame.new(338.76171875, 130.92079162597656, -233.84364318847656)},
        {Label = "Pine Tree", CFrame = CFrame.new(23.648874282836914, 17.36900520324707, 390.58270263671875)},
        {Label = "Gumdrop", CFrame = CFrame.new(32.6508674621582, 13.400006294250488, 405.8634033203125)},
        {Label = "Pine Tree", CFrame = CFrame.new(43.54356384277344, 13.86900520324707, 373.79779052734375)},
    },
    AutoUnlockBlueHQ = true,
    BlueHQRequiredDiscoveries = 4,
    BlueBeeTypes = {
        "Bumble", "Cool", "Bubble", "Bucko", "Frosty", "Ninja", "Diamond",
        "Tadpole", "Buoyant", "Cobalt",
    },
    BlueJellyRollsPerPass = 8,
    BlueJellyRollDelay = 0.2,
    BlueJellyCheckInterval = 1,
    AutoBuySprinklers = true,
    AutoPlaceSprinkler = true,
    MinSprinklerBees = 25,
    DynamicField = true,
    MacroMode = true,
    SafeMaterialMode = true,
    -- Lag fix never Destroys token/bee/field logic; Atlas preset only removes visual-only
    -- SurfaceAppearance and decorations are filtered, so scanners keep working.
    -- Black screen UI: false = start without the dark overlay (F7 can still enable it).
    -- BlackScreenTransparency: 0 = opaque black, 0.3 = dimmed night-mode veil
    -- (default), up to 0.85 = very faint.
    BlackScreen = true,
    BlackScreenTransparency = 0.3,
    LowGraphics = true,
    FixLagAtlasMode = true,
    FixLagHideBees = true,
    FixLagHideTokens = true,
    FixLagHideFlowers = true,
    FixLagHideHives = true,
    FixLagHideParticles = true,
    FixLagHideDecorations = true,
    FixLagDeleteDecorations = true,
    FixLagHidePlayers = true,
    FixLagHideWeather = true,
    FixLagRemoveTextures = true,
    FixLagPlasticMaterials = true,
    FixLagDisableLights = true,
    FixLagStopBeeAnimations = true,
    FixLagScanBatch = 350,
    FixLagHideSky = true,
    FixLagBrightness = 0.65,
    RedeemCodes = true,
    PromoCodes = {
        -- Material codes the progression guide recommends using right at the start.
        -- Boost/event codes are not redeemed early to avoid wasting field boosts.
        "BeesBuzz123", "38217", "BopMaster", "Connoisseur",
        "Crawlers", "Nectar", "Roof", "Wax",
    },
    BoostCodes = {
        "FOURtunate",
    },
    UseBoostCodesEarly = false,
    ProtectedMaterials = {
        StarEgg = true, Diamond = true, StarJelly = true, Gumdrops = true,
        Stinger = true, Glitter = true, MoonCharm = true,
    },
    FieldByBees = {
        {Bees = 1, Field = "Sunflower Field"},
        {Bees = 5, Field = "Bamboo Field"},
        {Bees = 15, Field = "Pine Tree Forest"},
    },
    BestColorFields = {
        White = {"Pumpkin Patch", "Cactus Field", "Clover Field", "Spider Field", "Dandelion Field", "Sunflower Field"},
        Red = {"Rose Field", "Strawberry Field", "Mushroom Field"},
        Blue = {"Pine Tree Forest", "Bamboo Field", "Blue Flower Field"},
    },
    ProgressionMilestones = {
        {TargetBees = 5, Items = {
            -- These two prices are fixed in the Basic Shop. Keep them here so a fresh
            -- account never stalls when executor ItemPackages/GetCost returns an empty cache.
            {Shop = "BasicShop", Item = "Clippers", Category = "Collector", Type = "Clippers", HoneyCost = 2200},
            {Shop = "BasicShop", Item = "Backpack", Category = "Accessory", Type = "Backpack", HoneyCost = 5500},
        }},
        {TargetBees = 10, Items = {
            -- Numbers 1 and 2 on the slide: capacity first, collector second.
            {Shop = "BasicShop", Item = "Canister", Category = "Accessory", Type = "Canister", HoneyCost = 22000},
            {Shop = "BasicShop", Item = "Vacuum", Category = "Collector", Type = "Vacuum", HoneyCost = 14000},
            {Shop = "BasicShop", Item = "Basic Boots", Category = "Accessory", Type = "Basic Boots", HoneyCost = 4400, RequiresMaterials = true, SupersededBy = {"Hiking Boots", "Beekeeper's Boots", "Coconut Clogs"}},
            {Shop = "BasicShop", Item = "Belt Pocket", Category = "Accessory", Type = "Belt Pocket", HoneyCost = 14000, RequiresMaterials = true, SupersededBy = {"Belt Bag", "Mondo Belt Bag", "Honeycomb Belt", "Petal Belt", "Coconut Belt"}},
            {Shop = "BasicShop", Item = "Helmet", Category = "Accessory", Type = "Helmet", HoneyCost = 30000, RequiresMaterials = true, SupersededBy = {"Propeller Hat", "Beekeeper's Mask", "Bubble Mask", "Diamond Mask"}},
        }},
        {TargetBees = 15, Items = {
            -- Pulsar is #1; the Pro Shop container set is #2 on the slide.
            {Shop = "ProShop", Item = "Pulsar", Category = "Collector", Type = "Pulsar", HoneyCost = 125000},
            {Shop = "ProShop", Item = "Mega-Jug", Category = "Accessory", Type = "Mega-Jug", HoneyCost = 50000},
            {Shop = "ProShop", Item = "Compressor", Category = "Accessory", Type = "Compressor", HoneyCost = 160000},
            {Shop = "ProShop", Item = "Elite Barrel", Category = "Accessory", Type = "Elite Barrel", HoneyCost = 650000},
        }},
        {TargetBees = 20, EggRushAfter = true, Items = {
            -- After Port-O-Hive, finish this order then freeze side gear
            -- to save all honey for Basic Egg/Hive Slot up to 25 bees.
            {Shop = "ProShop", Item = "Port-O-Hive", Category = "Accessory", Type = "Port-O-Hive", HoneyCost = 1250000},
            {Shop = "ProShop", Item = "Propeller Hat", Category = "Accessory", Type = "Propeller Hat", HoneyCost = 2500000, RequiresMaterials = true, SupersededBy = {"Beekeeper's Mask", "Bubble Mask", "Diamond Mask"}},
            {Shop = "BlueHQ", Item = "Bubble Wand", Category = "Collector", Type = "Bubble Wand", HoneyCost = 3500000, SupersededBy = {"Porcelain Dipper", "Petal Wand", "Tide Popper"}},
            -- Pro Shop guards (prices per BSS wiki): Looker 300K + 25 Sunflower Seed,
            -- Brave 300K + 3 Stinger.
            {Shop = "ProShop", Item = "Looker Guard", Category = "Accessory", Type = "Looker Guard", HoneyCost = 300000, RequiresMaterials = true,
                SupersededBy = {"Elite Blue Guard", "Elite Red Guard", "Cobalt Guard", "Crimson Guard"}},
            {Shop = "ProShop", Item = "Brave Guard", Category = "Accessory", Type = "Brave Guard", HoneyCost = 300000, RequiresMaterials = true,
                SupersededBy = {"Elite Blue Guard", "Elite Red Guard", "Cobalt Guard", "Crimson Guard"}},
        }},
        {TargetBees = 25, EggRushAfter = true, Items = {
            -- Retry Bubble Wand while hatching: if Blue HQ just opened after one
            -- Royal Jelly roll, buy immediately; if still locked continue the egg rush.
            {Shop = "BlueHQ", Item = "Bubble Wand", Category = "Collector", Type = "Bubble Wand", HoneyCost = 3500000, SupersededBy = {"Porcelain Dipper", "Petal Wand", "Tide Popper"}},
            -- Elite Guards moved from the 33-bee milestone to 25 bees by request.
            {Shop = "BlueHQ", Item = "Elite Blue Guard", Category = "Accessory", Type = "Elite Blue Guard", HoneyCost = 5000000, RequiresMaterials = true, SupersededBy = {"Cobalt Guard"}},
            {Shop = "RedHQ", Item = "Elite Red Guard", Category = "Accessory", Type = "Elite Red Guard", HoneyCost = 5000000, RequiresMaterials = true, SupersededBy = {"Crimson Guard"}},
        }},
        {TargetBees = 30, Items = {
            {Shop = "BlueHQ", Item = "Blue Port-O-Hive", Category = "Accessory", Type = "Blue Port-O-Hive", HoneyCost = 12500000, RequiresMaterials = true},
            {Shop = "Mountaintop", Item = "Beekeeper's Mask", Category = "Accessory", Type = "Beekeeper's Mask", HoneyCost = 20000000, RequiresMaterials = true, SupersededBy = {"Bubble Mask", "Diamond Mask"}},
            {Shop = "Mountaintop", Item = "Mondo Belt Bag", Category = "Accessory", Type = "Mondo Belt Bag", HoneyCost = 12400000, RequiresMaterials = true, SupersededBy = {"Honeycomb Belt", "Petal Belt", "Coconut Belt"}},
            {Shop = "Mountaintop", Item = "Beekeeper's Boots", Category = "Accessory", Type = "Beekeeper's Boots", HoneyCost = 15000000, RequiresMaterials = true, SupersededBy = {"Coconut Clogs", "Gummy Boots"}},
        }},
        {TargetBees = 34, Items = {
            {Shop = "Mountaintop", Item = "Porcelain Dipper", Category = "Collector", Type = "Porcelain Dipper", HoneyCost = 150000000},
        }},
        {TargetBees = 35, Items = {
            {Shop = "Mountaintop", Item = "Porcelain Port-O-Hive", Category = "Accessory", Type = "Porcelain Port-O-Hive", HoneyCost = 250000000, RequiresMaterials = true},
        }},
        {TargetBees = 40, Items = {
            -- 40-bee milestone: farm materials and buy in exact order blue guard,
            -- red guard, then Diamond Mask. All three are mandatory.
            {Shop = "MasterRoomShop", Item = "Cobalt Guard", Category = "Accessory", Type = "Cobalt Guard", HoneyCost = 200000000, RequiresMaterials = true},
            {Shop = "MasterRoomShop", Item = "Crimson Guard", Category = "Accessory", Type = "Crimson Guard", HoneyCost = 200000000, RequiresMaterials = true},
            {Shop = "DiamondMaskShop", Item = "Diamond Mask", Category = "Accessory", Type = "Diamond Mask", HoneyCost = 5000000000, RequiresMaterials = true},
        }},
        {TargetBees = 45, Items = {
            -- Parallel goals after finishing the 40-bee set.
            {Shop = "Petal Shop", Item = "Petal Belt", Category = "Accessory", Type = "Petal Belt", HoneyCost = 15000000000, RequiresMaterials = true, Optional = true},
            {Shop = "Coconut Cave", Item = "Coconut Canister", Category = "Accessory", Type = "Coconut Canister", HoneyCost = 25000000000, RequiresMaterials = true, Optional = true},
        }},
    },
    SprinklerSequence = {
        {Shop = "BadgeBearersGuild", Item = "Basic Sprinkler", Category = "Sprinkler", Type = "Basic Sprinkler"},
        {Shop = "BadgeBearersGuild", Item = "Silver Soakers", Category = "Sprinkler", Type = "Silver Soakers"},
        {Shop = "BadgeBearersGuild", Item = "Golden Gushers", Category = "Sprinkler", Type = "Golden Gushers"},
        {Shop = "BadgeBearersGuild", Item = "Diamond Drenchers", Category = "Sprinkler", Type = "Diamond Drenchers"},
        {Shop = "BadgeBearersGuild", Item = "The Supreme Saturator", Category = "Sprinkler", Type = "The Supreme Saturator"},
    },
    BasicEgg = {Shop = "EggDispenser", Item = "BasicEgg", Category = "Eggs", Type = "Basic", Amount = 1},
    RetryDelay = 2,
    RemoteTimeout = 5,
    StatsRefreshTimeout = 0.35,
    StatsRefreshMinInterval = 0.75,
    LocalStateHoldDuration = 15,
    PurchaseRetryCooldown = 20,
    DeniedPurchaseRetryCooldown = 45,
    UnknownPurchaseRetryCooldown = 5,
    StarterPurchaseRetryCooldown = 2,
    StarterDataRetryCooldown = 1,
    DeferredRetryInterval = 30,
    ConvertTimeout = 180,
    MeteorStayTime = 9,
    MeteorFieldGraceTime = 1.25,
    MeteorImpactLeadFraction = 0.6,
    MeteorFallbackLifetime = 5,
    MeteorTriggerInterval = 60,
    SprinklerPlaceInterval = 8,
    MaxDeferredPurchasesPerPass = 1,
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = deepCopy(child)
    end
    return copy
end

local function merge(target, source)
    if type(source) ~= "table" then
        return target
    end
    for key, value in pairs(source) do
        local replaceTable = key == "PromoCodes" or key == "BoostCodes" or key == "FieldByBees"
            or key == "ProgressionMilestones" or key == "SprinklerSequence"
            or key == "QuestNPCs" or key == "QuestFarmPriority" or key == "BadgeNames"
            or key == "BlueBeeTypes" or key == "MythicBeeTypes" or key == "BestColorFields"
            or key == "EventBeeSequence" or key == "TeleRewardSpots" or key == "CommonBeeTypes"
            or key == "AutoToys" or key == "BoostedFieldWhitelist" or key == "BlackBearPastQuests"
        if type(value) == "table" and type(target[key]) == "table" and not replaceTable then
            merge(target[key], value)
        else
            target[key] = deepCopy(value)
        end
    end
    return target
end

local Config = merge(deepCopy(DEFAULT_CONFIG), ENV.BSS_KAITUN_CONFIG or {})
-- Mother Bear returns to the kaitun: "Feed Treats" and "Use Royal Jelly" tasks now have
-- automatic handlers; pollen/mob tasks go through the quest router like other bears.
-- Polar Bear joined last: run when the other bears have nothing to do.
Config.QuestNPCs = {"Mother Bear", "Black Bear", "Science Bear", "Polar Bear"}
Config.QuestFarmPriority = {"Mother Bear", "Black Bear", "Science Bear", "Polar Bear"}
if Config.FixLagAtlasMode then
    -- Atlas preset: old configs must not accidentally re-enable heavy visuals.
    Config.LowGraphics = true
    Config.FixLagHideBees = true
    Config.FixLagHideTokens = true
    Config.FixLagHideFlowers = true
    Config.FixLagHideHives = true
    Config.FixLagHideParticles = true
    Config.FixLagHideDecorations = true
    Config.FixLagDeleteDecorations = true
    Config.FixLagHideWeather = true
    Config.FixLagRemoveTextures = true
    Config.FixLagPlasticMaterials = true
    Config.FixLagDisableLights = true
    Config.FixLagStopBeeAnimations = true
    Config.FixLagHidePlayers = true
end

-- Requirements are kept in one table so the purchase scheduler, material UI and
-- Blender planner all use the same target. Keys match PlayerStats.Eggs and the
-- recipe names exposed by ReplicatedStorage.BlenderRecipes. Helpers are methods
-- instead of top-level locals so executor Luau compilers stay below 200 registers.
local MaterialSystem = {}
MaterialSystem.Gear = {
    ["Basic Boots"] = {SunflowerSeed = 3, Blueberry = 3},
    ["Belt Pocket"] = {SunflowerSeed = 10},
    Helmet = {Pineapple = 5, MoonCharm = 1},
    ["Propeller Hat"] = {Gumdrops = 25, Pineapple = 100, MoonCharm = 5},
    ["Blue Port-O-Hive"] = {BlueExtract = 2, SoftWax = 2},
    ["Beekeeper's Mask"] = {Enzymes = 5, Glue = 3, Glitter = 1},
    ["Mondo Belt Bag"] = {SoftWax = 1, Pineapple = 150, SunflowerSeed = 150, Stinger = 10},
    ["Beekeeper's Boots"] = {Oil = 5, BlueExtract = 3, RedExtract = 3},
    ["Elite Blue Guard"] = {BlueExtract = 3, Blueberry = 50, RoyalJelly = 5, MoonCharm = 15},
    ["Elite Red Guard"] = {RedExtract = 3, Strawberry = 50, RoyalJelly = 5, Stinger = 5},
    ["Looker Guard"] = {SunflowerSeed = 25},
    ["Brave Guard"] = {Stinger = 3},
    ["Porcelain Port-O-Hive"] = {Glitter = 3, SoftWax = 3, MoonCharm = 10},
    ["Bubble Mask"] = {Blueberry = 500, BlueExtract = 50, Oil = 25, Glitter = 15},
    ["Cobalt Guard"] = {BlueExtract = 100, Stinger = 100, Enzymes = 50, Glitter = 25},
    ["Diamond Mask"] = {BlueExtract = 250, Oil = 150, Glitter = 100, DiamondEgg = 5, ComfortingVial = 1},
    ["Petal Belt"] = {SpiritPetal = 1, StarJelly = 25, Glitter = 50, Glue = 100},
    ["Crimson Guard"] = {RedExtract = 100, Stinger = 100, Oil = 50, Glitter = 25},
    ["Coconut Canister"] = {
        Coconut = 250, TropicalDrink = 150, RedExtract = 150,
        BlueExtract = 150, RefreshingVial = 2,
    },
}

MaterialSystem.Recipes = {
    RedExtract = {Recipe = "RedExtract", Yield = 1, Ingredients = {Strawberry = 50, RoyalJelly = 10}},
    BlueExtract = {Recipe = "BlueExtract", Yield = 1, Ingredients = {Blueberry = 50, RoyalJelly = 10}},
    Enzymes = {Recipe = "Enzymes", Yield = 1, Ingredients = {Pineapple = 50, RoyalJelly = 10}},
    Oil = {Recipe = "Oil", Yield = 1, Ingredients = {SunflowerSeed = 50, RoyalJelly = 10}},
    Glue = {Recipe = "Glue", Yield = 1, Ingredients = {Gumdrops = 50, RoyalJelly = 10}},
    TropicalDrink = {Recipe = "TropicalDrink", Yield = 1, Ingredients = {Coconut = 10, Enzymes = 2, Oil = 2}},
    Gumdrops = {Recipe = "Gumdrops", Yield = 1, Ingredients = {Strawberry = 3, Blueberry = 3, Pineapple = 3}},
    MoonCharm = {Recipe = "MoonCharm", Yield = 1, Ingredients = {Pineapple = 5, Gumdrops = 5, RoyalJelly = 1}},
    Glitter = {Recipe = "Glitter", Yield = 1, Ingredients = {MoonCharm = 25, MagicBean = 1}},
    StarJelly = {Recipe = "StarJelly", Yield = 1, Ingredients = {RoyalJelly = 100, Glitter = 3}},
    SoftWax = {Recipe = "SoftWax", Yield = 1, Ingredients = {Honeysuckle = 5, Oil = 1, Enzymes = 1, RoyalJelly = 10}},
    PurplePotion = {Recipe = "PurplePotion", Yield = 1, Ingredients = {Neonberry = 3, RedExtract = 3, BlueExtract = 3, Glue = 3}},
    SuperSmoothie = {Recipe = "SuperSmoothie", Yield = 1, Ingredients = {Neonberry = 3, StarJelly = 3, PurplePotion = 3, TropicalDrink = 6}},
    HardWax = {Recipe = "HardWax", Yield = 1, Ingredients = {SoftWax = 3, Enzymes = 3, Bitterberry = 33, RoyalJelly = 33}},
    CausticWax = {Recipe = "CausticWax", Yield = 1, Ingredients = {HardWax = 5, Enzymes = 5, Neonberry = 25, RoyalJelly = 5252}},
    SwirledWax = {Recipe = "SwirledWax", Yield = 1, Ingredients = {HardWax = 3, SoftWax = 9, PurplePotion = 6, RoyalJelly = 3333}},
    Turpentine = {Recipe = "Turpentine", Yield = 1, Ingredients = {Honeysuckle = 1000, SuperSmoothie = 10, CausticWax = 10, StarJelly = 100}},
}

MaterialSystem.Aliases = {
    SunflowerSeed = {"SunflowerSeed", "Sunflower Seed", "Sunflower Seeds"},
    Strawberry = {"Strawberry", "Strawberries"},
    Blueberry = {"Blueberry", "Blueberries"},
    Pineapple = {"Pineapple", "Pineapples"},
    Coconut = {"Coconut", "Coconuts"},
    Honeysuckle = {"Honeysuckle", "Honeysuckles"},
    Stinger = {"Stinger", "Stingers"},
    Gumdrops = {"Gumdrops", "Gumdrop"},
    Glitter = {"Glitter", "Glitters"},
    Glue = {"Glue", "Glues"},
    Oil = {"Oil", "Oils"},
    Enzymes = {"Enzymes", "Enzyme"},
    StarJelly = {"StarJelly", "Star Jelly", "Star Jellies"},
    SoftWax = {"SoftWax", "Soft Wax", "Soft Waxes"},
    RoyalJelly = {"RoyalJelly", "Royal Jelly", "Royal Jellies"},
    RedExtract = {"RedExtract", "Red Extract", "Red Extracts"},
    BlueExtract = {"BlueExtract", "Blue Extract", "Blue Extracts"},
    TropicalDrink = {"TropicalDrink", "Tropical Drink", "Tropical Drinks"},
    MoonCharm = {"MoonCharm", "Moon Charm", "Moon Charms"},
    MagicBean = {"MagicBean", "Magic Bean", "Magic Beans"},
    DiamondEgg = {"Diamond", "DiamondEgg", "Diamond Egg", "Diamond Eggs"},
    ComfortingVial = {"ComfortingVial", "Comforting Vial"},
    RefreshingVial = {"RefreshingVial", "Refreshing Vial"},
    SpiritPetal = {"SpiritPetal", "Spirit Petal"},
    PurplePotion = {"PurplePotion", "Purple Potion", "Purple Potions"},
    SuperSmoothie = {"SuperSmoothie", "Super Smoothie", "Super Smoothies"},
    HardWax = {"HardWax", "Hard Wax", "Hard Waxes"},
    CausticWax = {"CausticWax", "Caustic Wax", "Caustic Waxes"},
    SwirledWax = {"SwirledWax", "Swirled Wax", "Swirled Waxes"},
    Turpentine = {"Turpentine", "Turpentines"},
    Neonberry = {"Neonberry", "Neonberries"},
    Bitterberry = {"Bitterberry", "Bitterberries"},
}

MaterialSystem.Priority = {
    "Honeysuckle", "Coconut", "MagicBean", "RoyalJelly", "SunflowerSeed",
    "Strawberry", "Blueberry", "Pineapple", "Gumdrops", "MoonCharm", "Oil",
    "Enzymes", "Glue", "RedExtract", "BlueExtract", "SoftWax", "Glitter",
    "StarJelly", "TropicalDrink", "Neonberry", "Bitterberry", "PurplePotion",
    "HardWax", "CausticWax", "SwirledWax", "SuperSmoothie", "Turpentine",
    "Stinger", "DiamondEgg", "SpiritPetal", "ComfortingVial", "RefreshingVial",
}

for _, milestone in ipairs(Config.ProgressionMilestones or {}) do
    for _, entry in ipairs(milestone.Items or {}) do
        if not entry.Materials and MaterialSystem.Gear[entry.Type] then
            entry.Materials = deepCopy(MaterialSystem.Gear[entry.Type])
        end
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
repeat task.wait() until Player

local Events = ReplicatedStorage:WaitForChild("Events", 30)
if not Events then
    warn("[BSS Kaitun] ReplicatedStorage.Events not found")
    return
end

local okStat, StatCache = pcall(require, ReplicatedStorage:WaitForChild("ClientStatCache"))
local okPackages, ItemPackages = pcall(require, ReplicatedStorage:WaitForChild("ItemPackages"))
local okQuests, Quests = pcall(require, ReplicatedStorage:WaitForChild("Quests", 30))
do
    local ok, value = pcall(require, ReplicatedStorage:FindFirstChild("BlenderRecipes"))
    MaterialSystem.BlenderRecipes = ok and value or nil
    ok, value = pcall(require, ReplicatedStorage:FindFirstChild("OsTime"))
    MaterialSystem.OsTime = ok and value or nil
    ok, value = pcall(require, ReplicatedStorage:FindFirstChild("LocalPlanters"))
    MaterialSystem.LocalPlanters = ok and value or nil
end

local Runtime = {
    Running = true,
    State = "Starting",
    Detail = "Waiting for character",
    StartedAt = os.clock(),
    Connections = {},
    ActiveTween = nil,
    MovementOwner = nil,
    TweenRoot = nil,
    TweenRootWasAnchored = false,
    TweenGeneration = 0,
    MeteorQueue = {},
    MeteorPriorityActive = false,
    MeteorHandling = false,
    MeteorLockedField = "",
    RedeemedThisRun = {},
    RedeemedCodes = {},      -- persistent per-account set (file-backed)
    RedeemedCodesLoaded = false,
    TeleRewardsDone = false,
    TeleRewardsCollected = 0,
    CompletedGear = {},
    ProgressStage = "Bootstrap",
    BootstrapComplete = false,
    CurrentField = "",
    DeferredItems = {},
    LastSprinklerPlace = -math.huge,
    LastSprinklerField = "",
    LastProgressMaintenance = -math.huge,
    LastMeteorTrigger = -math.huge,
    NextMeteorTriggerCheck = 0,
    LastError = "",
    StatsRefreshInFlight = false,
    LastStats = nil,
    LastStatsRefresh = -math.huge,
    TokenCooldowns = setmetatable({}, {__mode = "k"}),
    TokenFirstSeen = setmetatable({}, {__mode = "k"}),
    TokensCollected = 0,
    LastTokenPlan = "",
    LastTokenScore = 0,
    WaitingForEggFunds = false,
    HiveCapacityFloor = 25,
    ReservedHiveCells = {},
    BasicEggShadow = nil,
    BasicEggShadowUntil = -math.huge,
    PurchaseRetryAt = {},
    EventBeePending = false,
    EventBeeBusy = false,
    EventBeePurchased = {},
    EventBeesPurchased = 0,
    EventBeesHatched = 0,
    LastEventBeeCheck = -math.huge,
    LastEventBeeStatsRefresh = -math.huge,
    LastDeferredRetry = -math.huge,
    NextGearTarget = nil,
    LastQuestCheck = -math.huge,
    LastBadgeClaim = -math.huge,
    BadgeClaimCursor = 1,
    BadgeChecks = 0,
    LastBadgeName = "",
    LastWealthClockAttempt = -math.huge,
    TweenRoot = nil,
    TweenRootWasAnchored = false,
    TweenRootReleaseAt = nil,
    Glide = nil,
    GlideRunnerConnection = nil,
    ToyRetryAt = {},
    ToyConsecutiveBusy = {},
    ToysClaimed = 0,
    RJGiftedTypes = {},
    RJGiftedCount = 0,
    RJHoneySpent = 0,
    RJStock = 0,
    RJRollsSinceSync = 0,
    RJRollsTotal = 0,
    RJRollsThisCell = 0,
    RHSacrificeKey = nil,
    RJStopReason = "",
    RJLastWork = -math.huge,
    StarTreatsUsed = 0,
    BoostedField = nil,
    BoostedFieldUntil = 0,
    MondoChickPending = false,
    MondoChickRetryAt = 0,
    ViciousPending = false,
    ViciousBusy = false,
    ViciousRetryAt = 0,
    BlackBearStopped = false,
    BlackBearPastSet = nil,
    NextWealthClockCheck = 0,
    WealthClockClaims = 0,
    ServerNowFunction = nil,
    BlueJellyBusy = false,
    BlueJellyCell = nil,
    BlueJellyRolls = 0,
    LastBlueJellyCheck = -math.huge,
    LastSpecialEffectScan = -math.huge,
    LastSpecialEffectFarm = os.clock(),
    CurrentQuest = "",
    QuestFarming = false,
    QuestCurrentField = "",
    CurrentQuestMob = "",
    QuestMobRetryAt = {},
    MonsterTypes = nil,
    NPCModuleError = "",
    FlowerEffectCooldown = setmetatable({}, {__mode = "k"}),
    Digging = false,
    AvoidingMob = false,
    MobHoldPosition = false,
    MobRelocating = false,
    MobRelocateTarget = false,
    MobRelocateUntil = 0,
    MobThreatUntil = 0,
    MobLastHumanoid = false,
    MobLastHealth = false,
    MobLastDamageAt = -math.huge,
    MaterialCombat = false,
    MaterialTarget = "",
    MaterialName = "",
    MaterialStats = nil,
    LastMaterialStats = -math.huge,
    BlenderStartedAt = -math.huge,
    BlenderRecipe = "",
    BlenderCount = 0,
    LastBlenderCheck = -math.huge,
    LastMaterialPlanterAction = -math.huge,
    LastNectarCondenserAction = -math.huge,
    NectarCondenserObject = nil,
    MaterialRequirements = {},
    FireflyPending = false,
    FireflyBusy = false,
    FireflyCenter = nil,
    FireflyCenterAt = 0,
    FireflyCooldowns = setmetatable({}, {__mode = "k"}),
    FirefliesCollected = 0,
    LastFireflySeen = -math.huge,
    SproutPending = false,
    SproutBusy = false,
    SproutMarker = false,
    SproutField = "",
    SproutsFarmed = 0,
    LowGraphicsBound = false,
    LowGraphicsWatched = setmetatable({}, {__mode = "k"}),
    HoneyRateSamples = {},
    HoneyRateTotal = 0,
    TreatCycleStart = nil,
    TreatCycleBase = 0,
    TreatCycleBudget = 0,
    TreatCycleBoughtHoney = 0,
    TreatFocusKey = nil,
    TreatFocusLevel = nil,
    TreatBusy = false,
    UI = {},
}

ENV.__BSS_KAITUN = Runtime

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Runtime.Connections, connection)
    return connection
end

local function setStatus(state, detail)
    if Runtime.MeteorPriorityActive and Runtime.MeteorHandling and state ~= "Auto meteor" then return end
    Runtime.State = state or Runtime.State
    Runtime.Detail = detail or ""
end

local function reportError(scope, err)
    Runtime.LastError = tostring(scope) .. ": " .. tostring(err)
    warn("[BSS Kaitun] " .. Runtime.LastError)
end

local function getCharacter(timeout)
    local deadline = os.clock() + (timeout or 20)
    repeat
        local character = Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if character and humanoid and root and humanoid.Health > 0 then
            return character, humanoid, root
        end
        task.wait(0.2)
    until not Runtime.Running or os.clock() >= deadline
    return nil
end

local function liveCoreValue(name)
    local coreStats = Player:FindFirstChild("CoreStats")
    local value = coreStats and coreStats:FindFirstChild(name)
    if value and value:IsA("ValueBase") then
        return tonumber(value.Value)
    end
    return nil
end

local function coreValue(name, fallback)
    local value = liveCoreValue(name)
    if value ~= nil then return value end
    return fallback or 0
end

-- Tracks honey/h over a 10-minute sliding window: only increases count (buying
-- lowers Honey but is not counted negative). Samples every 10s, keeps 10 minutes max.
function Runtime.UpdateHoneyRate()
    local now = os.clock()
    local samples = Runtime.HoneyRateSamples
    if samples[#samples] and now - samples[#samples][1] < 10 then return end
    local honey = liveCoreValue("Honey")
    if honey == nil then return end
    if Runtime.HoneyRateLast ~= nil and honey > Runtime.HoneyRateLast then
        Runtime.HoneyRateTotal += honey - Runtime.HoneyRateLast
    end
    Runtime.HoneyRateLast = honey
    table.insert(samples, {now, Runtime.HoneyRateTotal})
    while #samples > 1 and now - samples[1][1] > 600 do table.remove(samples, 1) end
end

function Runtime.HoneyPerHour()
    Runtime.UpdateHoneyRate()
    local samples = Runtime.HoneyRateSamples
    if #samples < 2 then return 0 end
    local first, last = samples[1], samples[#samples]
    local window = last[1] - first[1]
    if window < 30 then return 0 end
    return (last[2] - first[2]) / window * 3600
end

local function getStats(refresh)
    if not okStat or not StatCache then
        return Runtime.LastStats
    end
    local refreshDue = os.clock() - Runtime.LastStatsRefresh >= Config.StatsRefreshMinInterval
    if refresh and refreshDue and not Runtime.StatsRefreshInFlight then
        Runtime.LastStatsRefresh = os.clock()
        Runtime.StatsRefreshInFlight = true
        task.spawn(function()
            local ok, result = pcall(StatCache.Update, StatCache)
            if ok and type(result) == "table" then Runtime.LastStats = result end
            Runtime.StatsRefreshInFlight = false
        end)
        local deadline = os.clock() + Config.StatsRefreshTimeout
        while Runtime.Running and Runtime.StatsRefreshInFlight and os.clock() < deadline do task.wait(0.05) end
    end
    local ok, result = pcall(StatCache.Get, StatCache)
    if ok and type(result) == "table" then
        Runtime.LastStats = result
        return result
    end
    return Runtime.LastStats
end

local function pollenRatio()
    local pollen = tonumber(coreValue("Pollen", 0)) or 0
    local capacity = tonumber(coreValue("Capacity", 0)) or 0
    if capacity <= 0 then
        return 0, pollen, capacity
    end
    return pollen / capacity, pollen, capacity
end

local function formatNumber(number)
    number = tonumber(number) or 0
    local abs = math.abs(number)
    if abs >= 1e12 then return string.format("%.2fT", number / 1e12) end
    if abs >= 1e9 then return string.format("%.2fB", number / 1e9) end
    if abs >= 1e6 then return string.format("%.2fM", number / 1e6) end
    if abs >= 1e3 then return string.format("%.1fK", number / 1e3) end
    return tostring(math.floor(number + 0.5))
end

local function remoteCall(name, ...)
    local remote = Events:FindFirstChild(name)
    if not remote then
        return false, "missing remote " .. name
    end
    if remote:IsA("RemoteFunction") then
        local arguments = table.pack(...)
        local packed, completed
        task.spawn(function()
            packed = table.pack(pcall(remote.InvokeServer, remote, table.unpack(arguments, 1, arguments.n)))
            completed = true
        end)
        local deadline = os.clock() + Config.RemoteTimeout
        while Runtime.Running and not completed and os.clock() < deadline do task.wait(0.05) end
        if not completed then return false, "remote timeout: " .. name end
        if not packed[1] then
            return false, packed[2]
        end
        return true, table.unpack(packed, 2, packed.n)
    end
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        local ok, err = pcall(remote.FireServer, remote, ...)
        return ok, err
    end
    return false, "invalid remote class " .. remote.ClassName
end

function Runtime.ClaimNextBadge()
    local interval = math.max(0.5, tonumber(Config.BadgeClaimInterval) or 1.25)
    if not Config.AutoClaimBadges
        or os.clock() - Runtime.LastBadgeClaim < interval then return false end
    local badges = Config.BadgeNames or {}
    if #badges <= 0 then return false end
    local cursor = math.clamp(tonumber(Runtime.BadgeClaimCursor) or 1, 1, #badges)
    local badgeName = badges[cursor]
    Runtime.LastBadgeClaim = os.clock()
    Runtime.LastBadgeName = badgeName
    Runtime.BadgeChecks += 1
    Runtime.BadgeClaimCursor = cursor >= #badges and 1 or cursor + 1
    local ok = remoteCall("BadgeEvent", "Collect", badgeName)
    if Runtime.BadgeClaimCursor == 1 then task.defer(function() getStats(true) end) end
    return ok
end

function MaterialSystem.Stats(force)
    local now = os.clock()
    if not force and Runtime.MaterialStats
        and now - Runtime.LastMaterialStats < Config.MaterialStatsInterval then
        return Runtime.MaterialStats
    end

    local stats = getStats(force == true)
    if type(stats) == "table" and type(stats.Eggs) == "table" then
        Runtime.MaterialStats = stats
    end

    -- ClientStatCache is delayed or blocked on several mobile executors. This
    -- server snapshot is also the authoritative source for BlenderState.
    if force or not Runtime.MaterialStats or type(Runtime.MaterialStats.Eggs) ~= "table" then
        local ok, serverStats = remoteCall("RetrievePlayerStats")
        if ok and type(serverStats) == "table" then
            Runtime.MaterialStats = serverStats
            Runtime.LastStats = serverStats
        end
    end
    Runtime.LastMaterialStats = now
    return Runtime.MaterialStats or stats or {}
end

function MaterialSystem.Amount(material, stats)
    stats = stats or MaterialSystem.Stats(false)
    local inventory = type(stats) == "table" and stats.Eggs or nil
    if type(inventory) ~= "table" then return 0 end
    local aliases = MaterialSystem.Aliases[material] or {material}
    local best = tonumber(inventory[material]) or 0
    for _, alias in ipairs(aliases) do
        best = math.max(best, tonumber(inventory[alias]) or 0)
    end
    return best
end

function MaterialSystem.Canonical(name)
    local normalized = string.lower(tostring(name or "")):gsub("[^%w]", "")
    for canonical, aliases in pairs(MaterialSystem.Aliases) do
        if string.lower(canonical):gsub("[^%w]", "") == normalized then return canonical end
        for _, alias in ipairs(aliases) do
            if string.lower(alias):gsub("[^%w]", "") == normalized then return canonical end
        end
    end
    for canonical in pairs(MaterialSystem.Recipes) do
        if string.lower(canonical):gsub("[^%w]", "") == normalized then return canonical end
    end
    return tostring(name)
end

function MaterialSystem.Recipe(material)
    local fallback = MaterialSystem.Recipes[material]
    local recipes = MaterialSystem.BlenderRecipes
    if type(recipes) == "table" and type(recipes.Get) == "function" then
        local recipeName = fallback and fallback.Recipe or material
        local ok, result = pcall(recipes.Get, recipeName)
        if ok and type(result) == "table" and type(result.Ingredients) == "table" then
            local ingredients = {}
            for _, ingredient in pairs(result.Ingredients) do
                if type(ingredient) == "table" and ingredient.Type and tonumber(ingredient.Amount) then
                    ingredients[MaterialSystem.Canonical(ingredient.Type)] = tonumber(ingredient.Amount)
                end
            end
            if next(ingredients) then
                return {
                    Recipe = recipeName,
                    Yield = tonumber(result.Yield or result.Amount) or (fallback and fallback.Yield) or 1,
                    Ingredients = ingredients,
                }
            end
        end
    end
    return fallback
end

function MaterialSystem.Display(material)
    return tostring(material):gsub("(%l)(%u)", "%1 %2")
end

local function objectPosition(object)
    if not object then return nil end
    if object:IsA("BasePart") then return object.Position end
    if object:IsA("Attachment") then return object.WorldPosition end
    if object:IsA("Model") then return object:GetPivot().Position end
    local part = object:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function fieldContainsPosition(field, position, padding)
    if not field or not position then return false end
    local boundsCFrame, boundsSize
    if field:IsA("BasePart") then
        boundsCFrame, boundsSize = field.CFrame, field.Size
    elseif field:IsA("Model") then
        boundsCFrame, boundsSize = field:GetBoundingBox()
    else
        local part = field:FindFirstChildWhichIsA("BasePart", true)
        if part then boundsCFrame, boundsSize = part.CFrame, part.Size end
    end
    if not boundsCFrame or not boundsSize then return false end
    local localPoint = boundsCFrame:PointToObjectSpace(position)
    local extra = tonumber(padding) or 0
    return math.abs(localPoint.X) <= boundsSize.X * 0.5 + extra
        and math.abs(localPoint.Z) <= boundsSize.Z * 0.5 + extra
end

local function flowerFieldAtPosition(position, padding)
    local zones = workspace:FindFirstChild("FlowerZones")
    if not zones or not position then return nil end
    for _, field in ipairs(zones:GetChildren()) do
        if fieldContainsPosition(field, position, padding) then return field end
    end
    return nil
end

local function releaseTweenRoot()
    local root = Runtime.TweenRoot
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.Anchored = Runtime.TweenRootWasAnchored
        end)
    end
    Runtime.TweenRoot = nil
    Runtime.TweenRootWasAnchored = false
end

local function restoreFieldMoveSpeed(expectedGeneration)
    if expectedGeneration ~= nil and Runtime.FieldSpeedGeneration ~= expectedGeneration then return end
    local humanoid = Runtime.FieldSpeedHumanoid
    local original = Runtime.FieldSpeedOriginal
    if humanoid and humanoid.Parent and original ~= nil then
        pcall(function()
            -- If the game changed speed via buff/debuff, do not overwrite the new value.
            if humanoid.WalkSpeed == Config.FieldMoveSpeed then humanoid.WalkSpeed = original end
        end)
    end
    Runtime.FieldSpeedHumanoid = nil
    Runtime.FieldSpeedOriginal = nil
    Runtime.FieldSpeedGeneration = nil
end

local function applyFieldMoveSpeed(humanoid, generation)
    restoreFieldMoveSpeed()
    Runtime.FieldSpeedHumanoid = humanoid
    Runtime.FieldSpeedOriginal = humanoid.WalkSpeed
    Runtime.FieldSpeedGeneration = generation
    pcall(function() humanoid.WalkSpeed = Config.FieldMoveSpeed end)
end

-- Glide engine ----------------------------------------------------------------
-- One persistent Heartbeat runner interpolates the anchored root every frame.
-- Per-frame lerp instead of TweenService removes tween spin-up jitter, and
-- consecutive moves retarget without re-anchoring, so chained hops (farm steps,
-- token routes, vicious follow) no longer freeze between steps.
local GLIDE_ANCHOR_GRACE = 0.45

local function glideRunnerStep(deltaTime)
    local root = Runtime.TweenRoot
    if not root or not root.Parent then
        Runtime.Glide = nil
        Runtime.TweenRootReleaseAt = nil
        releaseTweenRoot()
        return
    end
    local glide = Runtime.Glide
    if glide then
        local current = root.CFrame
        local target = glide.CFrame
        local remaining = (target.Position - current.Position).Magnitude
        if remaining <= 0.35 then
            root.CFrame = target
            Runtime.Glide = nil
            Runtime.TweenRootReleaseAt = os.clock() + GLIDE_ANCHOR_GRACE
            return
        end
        local step = math.min(glide.Speed * deltaTime, remaining)
        root.CFrame = current:Lerp(target, step / remaining)
        return
    end
    local releaseAt = Runtime.TweenRootReleaseAt
    if releaseAt and os.clock() >= releaseAt then
        Runtime.TweenRootReleaseAt = nil
        releaseTweenRoot()
    end
end

local function ensureGlideRunner()
    if Runtime.GlideRunnerConnection then return end
    Runtime.GlideRunnerConnection = connect(RunService.Heartbeat, glideRunnerStep)
end

-- Field pathfinding (SmartMove stuck recovery): computes ONE route around
-- obstacles and walks its waypoints. Engaged only by the stuck watchdog inside
-- tweenTo, so free-walking never pays the ComputeAsync cost.
local function walkFieldPath(humanoid, root, position, generation)
    local ok, path = pcall(function()
        local pathObject = PathfindingService:CreatePath({
            AgentRadius = 2.5,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 4,
        })
        pathObject:ComputeAsync(root.Position, position)
        return pathObject
    end)
    if not ok or not path or path.Status ~= Enum.PathStatus.Success then return false end
    local okWaypoints, waypoints = pcall(path.GetWaypoints, path)
    if not okWaypoints or #waypoints < 2 then return false end
    for index = 2, #waypoints do
        local waypoint = waypoints[index]
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        humanoid:MoveTo(waypoint.Position)
        local waypointDeadline = os.clock() + 2.5
        while Runtime.Running and Runtime.TweenGeneration == generation
            and humanoid.Health > 0 and not Runtime.AvoidingMob
            and (root.Position - waypoint.Position).Magnitude > 3.5
            and os.clock() < waypointDeadline do
            task.wait(0.05)
        end
        if Runtime.TweenGeneration ~= generation then return false end
        -- A mob engaged mid-path: hand control back to the walk loop (it holds
        -- position while threatened and resumes direct walking afterwards).
        if Runtime.AvoidingMob then return false end
    end
    return (root.Position - position).Magnitude <= math.max(4, Config.SmartArrivalDistance + 2)
end

local function tweenTo(target, speed, owner, forceWalk)
    local position
    local targetCFrame
    if typeof(target) == "CFrame" then
        targetCFrame = target
        position = target.Position
    elseif typeof(target) == "Vector3" then
        position = target
        targetCFrame = CFrame.new(target)
    elseif typeof(target) == "Instance" then
        position = objectPosition(target)
        targetCFrame = position and CFrame.new(position)
    end
    if not targetCFrame then return false, "invalid target" end

    -- Meteor owns the shared mover as soon as it is detected. This prevents a
    -- farm/quest/shop loop that was already running from immediately replacing
    -- the emergency move with its own destination.
    local movementOwner = tostring(owner or "SmartMove")
    local meteorOwner = string.find(movementOwner, "Meteor", 1, true) == 1
    if Config.AutoMeteor and Runtime.MeteorPriorityActive and not meteorOwner then
        return false, "meteor priority"
    end

    local _, humanoid, root = getCharacter()
    if not root then return false, "character unavailable" end

    -- Supersede any older move before choosing the new route.
    Runtime.TweenGeneration += 1
    local generation = Runtime.TweenGeneration
    Runtime.Glide = nil
    restoreFieldMoveSpeed()
    releaseTweenRoot()
    Runtime.MovementOwner = movementOwner

    local moveSpeed = math.max(tonumber(speed) or Config.TweenSpeed, 1)
    local distance = (root.Position - position).Magnitude
    local startField = flowerFieldAtPosition(root.Position, Config.TokenFieldPadding)
    local targetField = flowerFieldAtPosition(position, 0)
    local walkingInsideField = startField ~= nil and targetField == startField

    -- Always walk when both points are inside the same FlowerZone, exactly like a
    -- normal player. Short non-field moves also walk. Obstruction falls back to tween.
    -- Meteor tokens always walk. If a token is no longer in the current field,
    -- cancel the target instead of tweening the player across fields.
    if forceWalk and not walkingInsideField then
        Runtime.MovementOwner = nil
        return false, "walk target outside current field"
    end
    if forceWalk or (Config.SmartMove and (walkingInsideField or distance <= Config.SmartWalkDistance)) then
        -- Walking needs physics: release a still-anchored root left over from the
        -- previous glide's grace window, otherwise MoveTo silently stalls.
        if Runtime.TweenRoot == root then releaseTweenRoot() end
        if walkingInsideField then applyFieldMoveSpeed(humanoid, generation) end
        humanoid:MoveTo(position)
        local maxWalkTime = forceWalk and math.min(4, Config.SmartFieldWalkTimeout)
            or (walkingInsideField and Config.SmartFieldWalkTimeout or 4)
        local walkDeadline = os.clock() + math.clamp(
            distance / math.max(humanoid.WalkSpeed, 1) + 1.5,
            1,
            maxWalkTime
        )
        local mobPaused = false
        local lastWalkTick = os.clock()
        local lastWalkDistance = (root.Position - position).Magnitude
        local stuckTicks = 0
        while Runtime.Running and Runtime.TweenGeneration == generation and humanoid.Health > 0
            and (root.Position - position).Magnitude > Config.SmartArrivalDistance and os.clock() < walkDeadline do
            local now = os.clock()
            if walkingInsideField and Runtime.AvoidingMob then
                -- Time spent jump-dodging mobs does not count toward the MoveTo timeout.
                walkDeadline += now - lastWalkTick
                mobPaused = true
                if Runtime.MobRelocating and typeof(Runtime.MobRelocateTarget) == "Vector3" then
                    -- Avoid-Mob worker and Smart Move issue the same destination, preventing
                    -- a token/field route MoveTo from dragging the player back into danger.
                    humanoid:MoveTo(Runtime.MobRelocateTarget)
                else
                    Runtime.MobHoldPosition = Runtime.MobHoldPosition or root.Position
                    humanoid:Move(Vector3.zero, false)
                    humanoid:MoveTo(Runtime.MobHoldPosition)
                end
            elseif mobPaused then
                mobPaused = false
                Runtime.MobHoldPosition = nil
                humanoid:MoveTo(position)
            end
            -- Stuck watchdog: walking against a tree/rock/hedge makes no progress.
            -- One pathfinding detour is computed (cooldown-gated), then SmartMove
            -- resumes straight at the target.
            if Config.SmartFieldPathfind and walkingInsideField
                and not mobPaused and not Runtime.AvoidingMob then
                local distanceNow = (root.Position - position).Magnitude
                if distanceNow < lastWalkDistance - 0.5 then
                    lastWalkDistance = distanceNow
                    stuckTicks = 0
                else
                    stuckTicks += 1
                end
                if stuckTicks >= 24 and os.clock() >= (Runtime.LastFieldPathfindAt or 0)
                    + math.max(2, tonumber(Config.FieldPathfindCooldown) or 6) then
                    Runtime.LastFieldPathfindAt = os.clock()
                    stuckTicks = 0
                    setStatus("Smart move", "Stuck - pathfinding around obstacle")
                    local pathStartedAt = os.clock()
                    walkFieldPath(humanoid, root, position, generation)
                    -- Detour time does not burn the walk timeout (same rule as
                    -- mob dodging); otherwise a good path still ends in a glide.
                    walkDeadline += os.clock() - pathStartedAt
                    lastWalkDistance = (root.Position - position).Magnitude
                    humanoid:MoveTo(position)
                end
            end
            lastWalkTick = now
            task.wait(0.05)
        end
        if Runtime.TweenGeneration ~= generation then
            restoreFieldMoveSpeed(generation)
            return false, "move superseded"
        end
        if (root.Position - position).Magnitude <= Config.SmartArrivalDistance then
            restoreFieldMoveSpeed(generation)
            Runtime.MovementOwner = nil
            return true
        end
        restoreFieldMoveSpeed(generation)
        if forceWalk then
            Runtime.MovementOwner = nil
            return false, "walk timeout"
        end
    end

    -- Reuse the root still anchored by the previous glide when its grace window
    -- has not expired: chained hops (farm steps, token routes, vicious follow)
    -- retarget without toggling Anchored, which is what caused the visible hitch.
    if Runtime.TweenRoot ~= root then
        releaseTweenRoot()
        Runtime.TweenRoot = root
        Runtime.TweenRootWasAnchored = root.Anchored
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.Anchored = true
        end)
    end
    Runtime.TweenRootReleaseAt = nil

    -- Direct route: frame-synced glide via the Heartbeat runner (no TweenService
    -- object churn, no tween spin-up, smooth chained moves).
    local routeSucceeded = Runtime.Running and Runtime.TweenGeneration == generation
        and humanoid.Health > 0 and root.Parent ~= nil
    if routeSucceeded and distance > Config.SmartArrivalDistance then
        Runtime.Glide = {CFrame = targetCFrame, Speed = moveSpeed, Generation = generation}
        ensureGlideRunner()
        local duration = math.clamp(distance / moveSpeed, 0.05, 30)
        local deadline = os.clock() + duration + 1
        while Runtime.Running and Runtime.TweenGeneration == generation and humanoid.Health > 0
            and Runtime.Glide ~= nil and Runtime.Glide.Generation == generation
            and os.clock() < deadline do task.wait(0.05) end
        if Runtime.Glide ~= nil and Runtime.Glide.Generation == generation then
            Runtime.Glide = nil -- timed out; the runner's grace release unanchors later
        end
        routeSucceeded = (root.Position - position).Magnitude <= Config.SmartArrivalDistance
    end

    local arrived = routeSucceeded and (root.Position - position).Magnitude <= Config.SmartArrivalDistance
    if arrived and root.Parent then
        pcall(function()
            root.CFrame = targetCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    if Runtime.TweenGeneration == generation then
        Runtime.MovementOwner = nil
        restoreFieldMoveSpeed(generation)
        -- Deferred release: keep the root anchored briefly so the next chained
        -- move reuses it. The runner unanchors automatically if nothing follows.
        Runtime.TweenRootReleaseAt = os.clock() + GLIDE_ANCHOR_GRACE
    end
    return arrived
end

local function cancelMovement()
    Runtime.TweenGeneration += 1
    Runtime.Glide = nil
    Runtime.TweenRootReleaseAt = nil
    Runtime.MovementOwner = nil
    Runtime.Digging = false
    Runtime.QuestFarming = false
    Runtime.AvoidingMob = false
    Runtime.MaterialCombat = false
    Runtime.MobHoldPosition = nil
    Runtime.MobRelocating = false
    Runtime.MobRelocateTarget = nil
    Runtime.MobRelocateUntil = 0
    Runtime.MobLastHumanoid = nil
    Runtime.MobLastHealth = nil
    Runtime.MobLastDamageAt = -math.huge
    Runtime.FireflyBusy = false
    Runtime.FireflyPending = false
    Runtime.SproutBusy = false
    Runtime.SproutPending = false
    Runtime.SproutMarker = false
    Runtime.SproutField = ""
    restoreFieldMoveSpeed()
    releaseTweenRoot()
end

-- Register Shutdown early so re-running the script still cleans the old instance,
-- even when that instance is mid-progression and has not reached the main loop.
function Runtime.Shutdown()
    if not Runtime.Running then return end
    Runtime.Running = false
    cancelMovement()
    for _, connection in ipairs(Runtime.Connections) do pcall(connection.Disconnect, connection) end
    Runtime.Connections = {}
    if Runtime.UI.Screen then pcall(Runtime.UI.Screen.Destroy, Runtime.UI.Screen) end
    if Runtime.UI.TopScreen then pcall(Runtime.UI.TopScreen.Destroy, Runtime.UI.TopScreen) end
    if ENV.__BSS_KAITUN == Runtime then ENV.__BSS_KAITUN = nil end
end

local function getPackage(entry)
    return {Category = entry.Category, Type = entry.Type, Amount = entry.Amount}
end

local function beeTypePresent(value)
    if value == nil then return false end
    local normalized = string.lower(tostring(value))
    return normalized ~= "" and normalized ~= "none" and normalized ~= "empty" and normalized ~= "nil"
end

local function workspaceBeeCount()
    local reference = Player:FindFirstChild("Honeycomb")
    local hive = reference and reference:IsA("ObjectValue") and reference.Value
    local cells = hive and hive:FindFirstChild("Cells")
    if not cells then return 0 end
    local count = 0
    for _, cell in ipairs(cells:GetChildren()) do
        local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
        local value = cellType and cellType:IsA("ValueBase") and tostring(cellType.Value) or ""
        if beeTypePresent(value) then count += 1 end
    end
    return count
end

local function beeCount()
    local stats = getStats(false)
    local honeycomb = stats and stats.Honeycomb
    local count = 0
    if type(honeycomb) == "table" then
        for _, row in pairs(honeycomb) do
            if type(row) == "table" and beeTypePresent(row.Type or row.BeeType) then
                count += 1
            elseif type(row) == "table" then
                for _, cell in pairs(row) do
                    if type(cell) == "table" and beeTypePresent(cell.Type or cell.BeeType) then count += 1 end
                end
            end
        end
    end
    -- Only count replicated evidence. Never invent a local floor after a remote call.
    return math.max(count, workspaceBeeCount())
end

local function hiveCapacity()
    local stats = getStats(false)
    local purchases = stats and stats.Totals and stats.Totals.Purchases
    local capacity = 25 + (tonumber(purchases and purchases.HiveSlots) or 0)
    if capacity >= Runtime.HiveCapacityFloor then Runtime.HiveCapacityFloor = capacity end
    return math.max(capacity, Runtime.HiveCapacityFloor)
end

local function rawPackageHas(package, stats)
    if not (okPackages and ItemPackages and stats) then return false end
    local ok, result = pcall(ItemPackages.PlayerHas, package, stats)
    return ok and result == true
end

local function currentGearAtLeast(entry, stats)
    if not stats then return false end
    if entry.ForceOwn then return false end
    if entry.Category == "Collector" then
        -- Ranks follow the guide route, not the game's declaration order. Rake at 800
        -- honey must not make the script skip Clippers/Vacuum.
        local ranks = {None = 0, Scooper = 0, Rake = 1, Clippers = 2, Magnet = 2,
            Vacuum = 3, ["Super-Scooper"] = 4, Pulsar = 5, Scissors = 6,
            ["Electro-Magnet"] = 7, ["Honey Dipper"] = 8, ["Bubble Wand"] = 9,
            Scythe = 9, ["Golden Rake"] = 10, ["Spark Staff"] = 11,
            ["Porcelain Dipper"] = 12, ["Petal Wand"] = 13, ["Tide Popper"] = 14,
            ["Dark Scythe"] = 14, Gummyballer = 14}
        local targetRank = ranks[entry.Type]
        return targetRank ~= nil and (ranks[stats.EquippedCollector or "None"] or 0) >= targetRank
    end
    if entry.Category == "Accessory" then
        local ranks = {None = 0, Pouch = 0, Jar = 1, Backpack = 2, Canister = 3,
            ["Mega-Jug"] = 5, Compressor = 6, ["Elite Barrel"] = 7,
            ["Port-O-Hive"] = 8, ["Blue Port-O-Hive"] = 9, ["Red Port-O-Hive"] = 9,
            ["Porcelain Port-O-Hive"] = 10, ["Coconut Canister"] = 11}
        local targetRank = ranks[entry.Type]
        if targetRank then
            local equipped = stats.EquippedBackpack or stats.EquippedContainer or "None"
            return (ranks[equipped] or 0) >= targetRank
        end
    end
    return false
end

local function livePlayerHas(entry)
    -- ClientStatCache updates slowly after Purchase on some mobile executors.
    -- Character/Backpack replicate faster than stats as proof for collectors/accessories.
    local containers = {Player.Character, Player:FindFirstChildOfClass("Backpack")}
    for _, container in ipairs(containers) do
        if container then
            local exact = container:FindFirstChild(tostring(entry.Type), true)
            if exact and (exact:IsA("Tool") or exact:IsA("Accessory") or exact:IsA("Model")) then return true end
        end
    end
    return false
end

local function playerHas(entry, refresh)
    -- Local proof is required on executors where ItemPackages cannot be required.
    -- Without this, a confirmed purchase is forgotten on the next scheduler pass.
    if Runtime.CompletedGear[entry.Type] then return true end
    local stats = getStats(refresh)
    if currentGearAtLeast(entry, stats) then return true end
    if rawPackageHas(getPackage(entry), stats) then return true end
    if livePlayerHas(entry) then return true end
    if type(entry.SupersededBy) == "table" then
        for _, itemType in ipairs(entry.SupersededBy) do
            if rawPackageHas({Category = entry.Category, Type = itemType}, stats) then return true end
        end
    end
    if entry.Category == "Eggs" and stats and stats.Eggs then
        return (tonumber(stats.Eggs[entry.Type]) or 0) > 0
    end
    return false
end

local function packageReadiness(entry)
    local stats = getStats(false)
    local liveHoney = liveCoreValue("Honey")
    local knownHoneyCost = tonumber(entry.HoneyCost)
    if knownHoneyCost and liveHoney ~= nil and liveHoney < knownHoneyCost then return "honey" end
    if not (okPackages and ItemPackages and stats) then
        -- Mobile executors may forbid requiring ItemPackages. Honey-only items can
        -- still be bought safely from their verified fixed cost. Crafted gear gets
        -- one controlled remote probe and is deferred if the server rejects it.
        if knownHoneyCost then return entry.RequiresMaterials and "probe" or "ready" end
        return "unknown"
    end
    local package = getPackage(entry)
    local okReq, unlocked = pcall(ItemPackages.CanPurchase, package, stats)
    local okCost, cost = pcall(ItemPackages.GetCost, package, stats)
    if not okCost or cost == nil then
        -- ItemPackages.GetCost is commonly blocked or returns nil on mobile
        -- executors even though the purchase remote still works. Do not leave a
        -- fresh account parked at its hive when this route already supplies the
        -- verified fixed honey price (Clippers, Backpack, Basic Egg, etc.).
        if knownHoneyCost then return entry.RequiresMaterials and "probe" or "ready" end
        return "unknown"
    end
    local missingHoney, missingMaterial = false, false
    local function checkHoney(amount)
        amount = tonumber(amount)
        if amount ~= nil and liveHoney ~= nil and liveHoney < amount then missingHoney = true end
    end

    if type(cost) == "number" then
        checkHoney(cost)
    elseif type(cost) ~= "table" then
        if knownHoneyCost then return entry.RequiresMaterials and "probe" or "ready" end
        return "unknown"
    elseif tonumber(cost.Honey) then
        checkHoney(cost.Honey)
    end

    local costs = type(cost) == "table" and (cost[1] and cost or {cost}) or {}
    for _, requirement in ipairs(costs) do
        if type(requirement) == "number" then
            checkHoney(requirement)
        elseif type(requirement) == "table" then
            if requirement == cost and tonumber(requirement.Honey) then
                checkHoney(requirement.Honey)
                continue
            end
            local requirementType = tostring(requirement.Category or requirement.Type or requirement.Name or "")
            if string.lower(requirementType) == "honey" then
            -- CoreStats updates faster than ClientStatCache. This prevents a stale
            -- cache from sending the player back to a shop before they can pay.
            local amount = tonumber(requirement.Amount or requirement.Value or requirement.Cost
                or requirement.Price or requirement.Quantity)
                if amount ~= nil then checkHoney(amount)
                elseif not rawPackageHas(requirement, stats) then missingHoney = true end
            elseif not rawPackageHas(requirement, stats) then
                missingMaterial = true
            end
        end
    end
    if missingMaterial then return "material" end
    if missingHoney then return "honey" end
    if okReq and unlocked == false then return "locked" end
    return "ready"
end

-- Next-gear target tracking: which accessory the script is saving honey for
-- right now, with its honey cost. Powers the dedicated UI line and the farm
-- status suffix so the goal stays visible while farming.
local function entryCostHoney(entry)
    if okPackages and ItemPackages and type(ItemPackages.GetCost) == "function" then
        local ok, cost = pcall(ItemPackages.GetCost, getPackage(entry), getStats(false))
        if ok then
            if type(cost) == "number" then return cost end
            if type(cost) == "table" then
                if tonumber(cost.Honey) then return tonumber(cost.Honey) end
                local first = cost[1]
                if type(first) == "table" and tonumber(first.Honey) then return tonumber(first.Honey) end
            end
        end
    end
    return tonumber(entry.HoneyCost)
end

function Runtime.SetNextGearTarget(entry)
    if type(entry) ~= "table" then return end
    Runtime.NextGearTarget = {
        Item = tostring(entry.Item or entry.Type or "?"),
        Cost = entryCostHoney(entry),
        At = os.clock(),
    }
end

function Runtime.ClearNextGearTarget()
    Runtime.NextGearTarget = nil
end

function Runtime.GearStatusText()
    local target = Runtime.NextGearTarget
    if type(target) ~= "table" then return "" end
    local cost = tonumber(target.Cost)
    if not cost or cost <= 0 then
        return "Next gear: " .. tostring(target.Item) .. " | saving honey"
    end
    local honey = liveCoreValue("Honey") or 0
    local percent = math.min(100, math.floor(honey / cost * 100 + 0.5))
    return string.format("Next gear: %s | %s / %s honey (%d%%)",
        tostring(target.Item), formatNumber(honey), formatNumber(cost), percent)
end

local function findShopItem(entry)
    local shops = workspace:FindFirstChild("Shops")
    local shop = shops and shops:FindFirstChild(entry.Shop, true)
    local items = shop and shop:FindFirstChild("Items")
    local item = items and items:FindFirstChild(entry.Item, true)
    if not item and shop then item = shop:FindFirstChild(entry.Item, true) end
    return item, shop
end

local function moveToShopItem(entry)
    local item, shop = findShopItem(entry)
    if not item then return false end
    setStatus("Buying gear", entry.Item .. " @ " .. entry.Shop)
    local position = objectPosition(item)
    if not position and shop then position = objectPosition(shop) end
    return position and tweenTo(CFrame.new(position + Vector3.new(0, 3, 0)), Config.TweenSpeed, "Shop") or false
end

local function purchaseAndEquip(entry, fastRetry)
    if Runtime.MeteorPriorityActive then return false, "meteor" end
    if Runtime.CompletedGear[entry.Type] then return true, "owned" end
    if playerHas(entry, false) then
        if entry.Category ~= "Eggs" then
            task.spawn(function() remoteCall("ItemPackageEvent", "Equip", getPackage(entry)) end)
        end
        Runtime.CompletedGear[entry.Type] = true
        return true, "owned"
    end

    local purchaseKey = tostring(entry.Category) .. ":" .. tostring(entry.Type)
    local now = os.clock()
    local retryAt = Runtime.PurchaseRetryAt[purchaseKey] or 0
    if retryAt > now then return false, "cooldown", retryAt - now end
    local readiness = packageReadiness(entry)
    if readiness == "unknown" then
        Runtime.PurchaseRetryAt[purchaseKey] = now
            + (fastRetry and Config.StarterDataRetryCooldown or Config.UnknownPurchaseRetryCooldown)
        setStatus("Waiting for shop data", entry.Item)
        task.defer(function() getStats(true) end)
        return false, "unknown"
    elseif readiness ~= "ready" and readiness ~= "probe" then
        return false, readiness
    end
    Runtime.PurchaseRetryAt[purchaseKey] = now + Config.PurchaseRetryCooldown

    local moved = moveToShopItem(entry)
    if moved then
        task.wait(0.3)
    else
        -- Shop model may be renamed/streamed out while the purchase remote is still
        -- valid. Attempt once instead of freezing progression at the missing model.
        setStatus("Buying gear", "Remote fallback: " .. entry.Item)
    end
    if Runtime.MeteorPriorityActive then
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        return false, "meteor"
    end
    local honeyBefore = liveCoreValue("Honey")
    local ok, purchased = remoteCall("ItemPackageEvent", "Purchase", getPackage(entry))
    local remoteConfirmed = ok and purchased == true
    -- Purchase often returns nil even when the server accepted. Equipping immediately
    -- applies the item on success and makes inventory/equipped stats replicate faster.
    if ok and entry.Category ~= "Eggs" then
        remoteCall("ItemPackageEvent", "Equip", getPackage(entry))
    end
    if remoteConfirmed then
        Runtime.CompletedGear[entry.Type] = true
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        task.defer(function() getStats(true) end)
        return true, "purchased"
    end
    task.wait(0.8)
    getStats(true)
    local honeyAfter = liveCoreValue("Honey")
    local honeySpent = honeyBefore ~= nil and honeyAfter ~= nil and honeyAfter < honeyBefore
    local acquired = playerHas(entry, false) or (ok and honeySpent)
    if acquired then
        Runtime.CompletedGear[entry.Type] = true
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        if entry.Category ~= "Eggs" then
            task.spawn(function() remoteCall("ItemPackageEvent", "Equip", getPackage(entry)) end)
        end
        return true, "verified"
    else
        Runtime.PurchaseRetryAt[purchaseKey] = os.clock()
            + (fastRetry and Config.StarterPurchaseRetryCooldown or Config.DeniedPurchaseRetryCooldown)
        local reason = ok and ("server result=" .. tostring(purchased)) or tostring(purchased)
        setStatus("Waiting to buy", entry.Item .. " | " .. reason)
    end
    return false, "purchase_failed"
end

local function resolveHiveFromPlatform(platform)
    local value = platform and platform:FindFirstChild("Hive")
    if value and value:IsA("ObjectValue") then return value.Value end
    return nil
end

local function findOwnedHive()
    local honeycombRef = Player:FindFirstChild("Honeycomb")
    if honeycombRef and honeycombRef:IsA("ObjectValue") and honeycombRef.Value then
        local hive = honeycombRef.Value
        for _, platform in ipairs((workspace:FindFirstChild("HivePlatforms") or workspace):GetChildren()) do
            if resolveHiveFromPlatform(platform) == hive then return hive, platform end
        end
        return hive, nil
    end
    local platforms = workspace:FindFirstChild("HivePlatforms")
    if platforms then
        for _, platform in ipairs(platforms:GetChildren()) do
            local ref = platform:FindFirstChild("PlayerRef")
            if ref and ref:IsA("ObjectValue") and ref.Value == Player then
                return resolveHiveFromPlatform(platform), platform
            end
        end
    end
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if honeycombs then
        for _, hive in ipairs(honeycombs:GetChildren()) do
            local owner = hive:FindFirstChild("Owner") or hive:FindFirstChild("PlayerRef")
            if owner and owner:IsA("ObjectValue") and owner.Value == Player then return hive, nil end
        end
    end
    return nil
end

local function findFreeHive()
    local platforms = workspace:FindFirstChild("HivePlatforms")
    if platforms then
        for _, platform in ipairs(platforms:GetChildren()) do
            local ref = platform:FindFirstChild("PlayerRef")
            local hive = resolveHiveFromPlatform(platform)
            local owner = hive and (hive:FindFirstChild("Owner") or hive:FindFirstChild("PlayerRef"))
            local free = (not ref or ref.Value == nil) and (not owner or owner.Value == nil)
            local id = hive and hive:FindFirstChild("HiveID")
            if free and id and id:IsA("ValueBase") then return hive, platform, id.Value end
        end
    end
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if honeycombs then
        for _, hive in ipairs(honeycombs:GetChildren()) do
            local owner = hive:FindFirstChild("Owner") or hive:FindFirstChild("PlayerRef")
            local id = hive:FindFirstChild("HiveID")
            if (not owner or owner.Value == nil) and id and id:IsA("ValueBase") then
                return hive, nil, id.Value
            end
        end
    end
    return nil
end

local function claimHive()
    if findOwnedHive() then return true end
    setStatus("Init", "Claiming hive")
    for attempt = 1, 12 do
        if not Runtime.Running then return false end
        while Runtime.Running and Runtime.MeteorPriorityActive do task.wait(0.05) end
        local hive, platform, hiveId = findFreeHive()
        if hiveId ~= nil then
            local target = platform and (platform:FindFirstChild("Platform") or platform) or hive
            local position = objectPosition(target)
            if position then tweenTo(CFrame.new(position + Vector3.new(0, 3, 0)), Config.TweenSpeed, "ClaimHive") end
            remoteCall("ClaimHive", hiveId)
            task.wait(1)
            if findOwnedHive() then return true end
        else
            setStatus("Init", "Waiting for free hive (" .. attempt .. "/12)")
            task.wait(Config.RetryDelay)
        end
    end
    return false
end

local function redeemCodes()
    if not Config.RedeemCodes then return end
    -- Codes are ONE-TIME per account: the redeemed set is persisted to an
    -- executor file per UserId, so rejoining or re-running never re-fires
    -- already-used codes (each one costs ~0.5s of remote + wait time).
    if not Runtime.RedeemedCodesLoaded then
        Runtime.RedeemedCodesLoaded = true
        local readfileFn = rawget(ENV, "readfile") or (type(readfile) == "function" and readfile)
        if type(readfileFn) == "function" then
            local ok, content = pcall(readfileFn,
                "bss_kaitun_codes_" .. tostring(Player.UserId) .. ".txt")
            if ok and type(content) == "string" then
                for code in string.gmatch(content, "[^\r\n]+") do
                    local trimmed = code:match("^%s*(.-)%s*$")
                    if trimmed ~= "" then Runtime.RedeemedCodes[trimmed] = true end
                end
            end
        end
    end
    local function persistCode(code)
        Runtime.RedeemedCodes[code] = true
        local readfileFn = rawget(ENV, "readfile") or (type(readfile) == "function" and readfile)
        local writefileFn = rawget(ENV, "writefile") or (type(writefile) == "function" and writefile)
        if type(writefileFn) ~= "function" then return end
        local existing = ""
        if type(readfileFn) == "function" then
            local okRead, content = pcall(readfileFn,
                "bss_kaitun_codes_" .. tostring(Player.UserId) .. ".txt")
            if okRead and type(content) == "string" then existing = content end
        end
        pcall(writefileFn, "bss_kaitun_codes_" .. tostring(Player.UserId) .. ".txt",
            existing .. code .. "\n")
    end
    local function redeemList(codes, label)
        for index, code in ipairs(codes) do
            if not Runtime.Running then return end
            while Runtime.Running and Runtime.MeteorPriorityActive do task.wait(0.05) end
            if type(code) == "string" and code ~= ""
                and not Runtime.RedeemedCodes[code]
                and not Runtime.RedeemedThisRun[code] then
                setStatus("Redeem code", string.format("%s %d/%d - %s", label, index, #codes, code))
                local ok = remoteCall("PromoCodeEvent", code)
                Runtime.RedeemedThisRun[code] = true
                -- Only persist on a successful fire: a failed send must retry
                -- next run; a server-side "already used" answer is impossible
                -- to distinguish from success, but firing a used code once more
                -- is harmless and still gets marked done.
                if ok ~= false then persistCode(code) end
                task.wait(0.45)
            end
        end
    end
    redeemList(Config.PromoCodes, "material")
    if Config.UseBoostCodesEarly then redeemList(Config.BoostCodes, "boost") end
    getStats(true)
end

-- Cross-server memory for tele rewards: world pickups are ONE-TIME per account,
-- so a single permanent marker file per UserId (executor file storage) skips the
-- 40-spot sweep on every later execution or server, forever. Delete the file to
-- force one re-sweep (e.g. after adding new spots to TeleRewardSpots).
function Runtime.TeleRewardsClaimed()
    local readfileFn = rawget(ENV, "readfile") or (type(readfile) == "function" and readfile)
    if type(readfileFn) ~= "function" then return false end
    local ok, content = pcall(readfileFn,
        "bss_kaitun_rewards_" .. tostring(Player.UserId) .. ".txt")
    return ok and type(content) == "string" and content:find("done", 1, true) ~= nil
end

function Runtime.MarkTeleRewardsDone()
    local writefileFn = rawget(ENV, "writefile") or (type(writefile) == "function" and writefile)
    if type(writefileFn) ~= "function" then return end
    pcall(writefileFn, "bss_kaitun_rewards_" .. tostring(Player.UserId) .. ".txt", "done")
end

-- Tele reward phase (from telebss rewards.txt): instantly teleport to each
-- map reward point on game entry, BEFORE claiming hive/hatching. Each point: set
-- CFrame directly onto the reward, stand still + nudge up/down via CFrame
-- to trigger the touch pickup. No tweening, no flying up. Meteor stays top priority.
--
-- AUTO-DETECTION: the Collectibles folder spawns ON DEMAND (absent until the
-- first pickup exists - verified in-game), so each spot re-scans it instead of
-- using one upfront snapshot. A spot is only visited when a live collectible
-- actually sits within 8 studs of its coordinates: seasonal rewards removed
-- after Beesmas cost nothing (no tele, no dwell). Teleports to the instance's
-- real position and deduplicates shared instances; if the folder never appears
-- the sweep falls back to the legacy blind pass.
function Runtime.CollectWorldRewards()
    if not Config.AutoTeleRewards or Runtime.TeleRewardsDone then return false end
    local spots = Config.TeleRewardSpots or {}
    -- Mark done on entry: the progression recovery loop never
    -- re-runs this phase within a single execution.
    Runtime.TeleRewardsDone = true
    if #spots <= 0 then return false end
    -- Skip forever once this account swept the one-time rewards (persisted file).
    if Runtime.TeleRewardsClaimed() then
        setStatus("Tele reward", "One-time rewards already collected - skipping")
        warn("[BSS Kaitun] Tele rewards already collected (one-time) - skipping phase")
        return false
    end
    local dwell = math.max(0.3, tonumber(Config.TeleRewardDwellSeconds) or 2)

    local function pin(root, cframe)
        pcall(function()
            root.CFrame = cframe
            root.AssemblyLinearVelocity = Vector3.zero
        end)
    end

    -- Short grace window: the folder spawns once the first reward replicates.
    local collectiblesFolder = workspace:FindFirstChild("Collectibles")
    local graceDeadline = os.clock() + 3
    while not collectiblesFolder and Runtime.Running
        and not Runtime.MeteorPriorityActive and os.clock() < graceDeadline do
        task.wait(0.25)
        collectiblesFolder = workspace:FindFirstChild("Collectibles")
    end

    local visitedInstances = {}
    local skipped = 0
    for index, spot in ipairs(spots) do
        if not Runtime.Running then break end
        while Runtime.Running and Runtime.MeteorPriorityActive do task.wait(0.1) end
        if not Runtime.Running then break end
        local _, _, root = getCharacter(8)
        if not root then continue end
        local targetCFrame = spot.CFrame
        if collectiblesFolder then
            -- Nearest live collectible within 8 studs of the known coordinates.
            local best, bestPosition, bestDistance
            for _, object in ipairs(collectiblesFolder:GetChildren()) do
                if not visitedInstances[object] then
                    local position = objectPosition(object)
                    if position then
                        local distance = (position - spot.CFrame.Position).Magnitude
                        if distance <= 8 and (not bestDistance or distance < bestDistance) then
                            best, bestPosition, bestDistance = object, position, distance
                        end
                    end
                end
            end
            if not best then
                skipped += 1
                continue -- reward removed (e.g. Beesmas ended) - zero time spent
            end
            visitedInstances[best] = true
            targetCFrame = CFrame.new(bestPosition)
        end
        setStatus("Tele reward", string.format("%d/%d %s", index, #spots, tostring(spot.Label or "reward")))
        pin(root, targetCFrame)
        -- Stand on the reward point, nudging up/down to trigger the touch pickup.
        local deadline = os.clock() + dwell
        while Runtime.Running and not Runtime.MeteorPriorityActive and os.clock() < deadline do
            local _, _, currentRoot = getCharacter(2)
            if not currentRoot then break end
            pin(currentRoot, targetCFrame + Vector3.new(0, 1, 0))
            task.wait(0.12)
            pin(currentRoot, targetCFrame)
            task.wait(0.12)
        end
        Runtime.TeleRewardsCollected += 1
    end
    setStatus("Tele reward", string.format("Done %d/%d spots (%d empty) - moving to hive claim",
        Runtime.TeleRewardsCollected, #spots, skipped))
    Runtime.MarkTeleRewardsDone()
    task.wait(0.2)
    return true
end

local function hasAnyBee()
    return beeCount() > 0
end

local function rawEggCount(eggType)
    local stats = getStats(false)
    return tonumber(stats and stats.Eggs and stats.Eggs[eggType]) or 0
end

local function eggCount(eggType)
    if eggType == "Basic" and Runtime.BasicEggShadow ~= nil
        and os.clock() < Runtime.BasicEggShadowUntil then
        return Runtime.BasicEggShadow
    end
    return rawEggCount(eggType)
end

local function setBasicEggShadow(count)
    Runtime.BasicEggShadow = math.max(0, tonumber(count) or 0)
    Runtime.BasicEggShadowUntil = os.clock() + Config.LocalStateHoldDuration
end

local function creditBasicEgg()
    setBasicEggShadow(eggCount("Basic") + 1)
end

local function consumeBasicEgg()
    setBasicEggShadow(math.max(0, eggCount("Basic") - 1))
end

local function buyBasicEgg()
    if Runtime.MeteorPriorityActive then return false end
    if eggCount("Basic") > 0 then
        Runtime.WaitingForEggFunds = false
        return true
    end
    if not Config.AutoBuyBasicEggs then return false end
    local purchaseKey = "Eggs:Basic"
    if (Runtime.PurchaseRetryAt[purchaseKey] or 0) > os.clock() then return false end
    local readiness = packageReadiness(Config.BasicEgg)
    local fallbackProbe = readiness == "unknown"
    if readiness == "honey" then
        Runtime.WaitingForEggFunds = true
        Runtime.ProgressStage = "Saving honey for Basic Egg"
        setStatus("Farm egg money", "Not enough honey - no Purchase call")
        return false
    elseif readiness == "locked" or readiness == "material" then
        setStatus("Basic Egg locked", readiness)
        return false
    elseif readiness == "unknown" then
        -- The user-confirmed ItemPackageEvent remote works globally. On executors
        -- that cannot require ItemPackages, probe it directly instead of repeatedly
        -- tweening to Basic Shop merely to check the price.
        setStatus("Buying Basic Egg", "Remote fallback - skip the dispenser")
    end
    Runtime.WaitingForEggFunds = false
    Runtime.PurchaseRetryAt[purchaseKey] = os.clock() + Config.PurchaseRetryCooldown
    setStatus("Buying Basic Egg", "Buying eggs for the hive")
    local before = eggCount("Basic")
    local beforeRaw = rawEggCount("Basic")
    local honeyBefore = liveCoreValue("Honey")
    if Runtime.MeteorPriorityActive then
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        return false
    end
    local ok, result = remoteCall("ItemPackageEvent", "Purchase", getPackage(Config.BasicEgg))
    local remoteConfirmed = ok and result == true
    if remoteConfirmed then
        creditBasicEgg()
        Runtime.WaitingForEggFunds = false
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        task.defer(function() getStats(true) end)
        return true
    end
    task.wait(0.8)
    getStats(true)
    local afterRaw = rawEggCount("Basic")
    local honeyAfter = liveCoreValue("Honey")
    local honeySpent = honeyBefore ~= nil and honeyAfter ~= nil and honeyAfter < honeyBefore
    local acquired = afterRaw > beforeRaw or (ok and honeySpent)
    if not acquired then
        Runtime.PurchaseRetryAt[purchaseKey] = os.clock()
            + (fallbackProbe and Config.UnknownPurchaseRetryCooldown or Config.DeniedPurchaseRetryCooldown)
        if packageReadiness(Config.BasicEgg) == "honey" then Runtime.WaitingForEggFunds = true end
        setStatus("Waiting for Basic Egg", ok and ("server result=" .. tostring(result)) or tostring(result))
    else
        setBasicEggShadow(math.max(before + 1, afterRaw))
        Runtime.WaitingForEggFunds = false
    end
    if acquired then Runtime.PurchaseRetryAt[purchaseKey] = nil end
    return acquired
end

local function eggFundingBlocked()
    if not Runtime.WaitingForEggFunds then return false end
    if eggCount("Basic") > 0 then
        Runtime.WaitingForEggFunds = false
        return false
    end
    local readiness = packageReadiness(Config.BasicEgg)
    if readiness == "honey" then return true end
    Runtime.WaitingForEggFunds = false
    return false
end

local function hatchResponseAccepted(ok, beforeEggs, remaining, success)
    if not ok then return false end
    if success == true or remaining == true then return true end
    for _, result in pairs({remaining, success}) do
        if type(result) == "table" and (result.Success == true or result.Succeeded == true or result.Ok == true) then
            return true
        end
    end
    local remainingEggs = tonumber(remaining)
    if remainingEggs ~= nil then
        return beforeEggs > 0 and remainingEggs < beforeEggs
    end
    return false
end

local function applyHatchResponse(eggType, remaining, success, honeycomb, discoveredBees, eggUses)
    if success ~= true or not okStat or type(StatCache) ~= "table" or type(StatCache.Set) ~= "function" then return end
    pcall(StatCache.Set, StatCache, {"Eggs", eggType}, remaining)
    if type(honeycomb) == "table" then pcall(StatCache.Set, StatCache, "Honeycomb", honeycomb) end
    if discoveredBees ~= nil then pcall(StatCache.Set, StatCache, "DiscoveredBees", discoveredBees) end
    if eggUses ~= nil then pcall(StatCache.Set, StatCache, {"Totals", "EggUses"}, eggUses) end
    local ok, refreshed = pcall(StatCache.Get, StatCache)
    if ok and type(refreshed) == "table" then Runtime.LastStats = refreshed end
end

local function hiveCellKey(x, y)
    return tostring(x) .. ":" .. tostring(y)
end

local function hiveCellData(x, y)
    local stats = getStats(false)
    local honeycomb = stats and stats.Honeycomb
    if type(honeycomb) ~= "table" then return nil end
    local direct = honeycomb[tostring(x) .. "," .. tostring(y)]
        or honeycomb[tostring(x) .. ":" .. tostring(y)]
    if type(direct) == "table" then return direct end
    local row = honeycomb[x] or honeycomb[tostring(x)]
    if type(row) == "table" then
        local cell = row[y] or row[tostring(y)]
        if type(cell) == "table" then return cell end
    end
    for _, cell in pairs(honeycomb) do
        if type(cell) == "table" then
            local cellX = tonumber(cell.CellX or cell.X or cell.Column)
            local cellY = tonumber(cell.CellY or cell.Y or cell.Row)
            if cellX == x and cellY == y then return cell end
        end
    end
    return nil
end

local function workspaceHiveCellOccupied(x, y)
    local reference = Player:FindFirstChild("Honeycomb")
    local hive = reference and reference:IsA("ObjectValue") and reference.Value
    local cells = hive and hive:FindFirstChild("Cells")
    if not cells then return false end
    local cell = cells:FindFirstChild("C" .. tostring(x) .. "," .. tostring(y))
        or cells:FindFirstChild(tostring(x) .. "," .. tostring(y))
    if not cell then return false end
    local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
    local value = cellType and cellType:IsA("ValueBase") and tostring(cellType.Value) or ""
    return beeTypePresent(value)
end

local function hiveCellOccupied(x, y)
    if workspaceHiveCellOccupied(x, y) then return true end
    if Runtime.ReservedHiveCells[hiveCellKey(x, y)] then return true end
    local cell = hiveCellData(x, y)
    return type(cell) == "table" and beeTypePresent(cell.Type or cell.BeeType)
end

local function waitForHatchConfirmation(beforeBees, x, y, timeout)
    local deadline = os.clock() + (timeout or 2)
    -- StatCache.Update may yield for hundreds of milliseconds on mobile. Refresh
    -- it off-thread and let the fast replicated hive check drive progression.
    task.defer(function() getStats(true) end)
    repeat
        if workspaceHiveCellOccupied(x, y) or beeCount() > beforeBees then return true end
        task.wait(0.05)
    until not Runtime.Running or os.clock() >= deadline
    return workspaceHiveCellOccupied(x, y) or beeCount() > beforeBees
end

local function markBeeHatched(x, y)
    Runtime.ReservedHiveCells[hiveCellKey(x, y)] = true
    consumeBasicEgg()
    Runtime.WaitingForEggFunds = false
    -- The next main-loop iteration may skip its blocking stats refresh: the
    -- authoritative hatch response already proves the new bee.
    Runtime.SkipStatsBlockUntil = os.clock() + 2
    task.defer(function() getStats(true) end)
end

local function hatchOneBasicEgg()
    if Runtime.MeteorPriorityActive then return false end
    local beforeBees = beeCount()
    setStatus("Hatching Basic Egg", string.format("Hive %d/%d bee", beforeBees, hiveCapacity()))

    -- ClaimHive grants a free Basic Egg, but ClientStatCache can arrive late. Try
    -- the center cell first before walking to the dispenser or spending honey.
    if eggCount("Basic") <= 0 and beforeBees <= 0 then
        local beforeEggs = eggCount("Basic")
        if Runtime.MeteorPriorityActive then return false end
        local ok, remaining, success, honeycomb, discoveredBees, eggUses = remoteCall("ConstructHiveCellFromEgg", 3, 3, "Basic", 1)
        applyHatchResponse("Basic", remaining, success, honeycomb, discoveredBees, eggUses)
        local accepted = hatchResponseAccepted(ok, beforeEggs, remaining, success)
        -- A successful RemoteFunction response carrying the updated Honeycomb is
        -- authoritative. Do not wait for the same change to replicate a second time.
        if (ok and success == true and type(honeycomb) == "table")
            or waitForHatchConfirmation(beforeBees, 3, 3, accepted and 0.5 or 0.45) then
            markBeeHatched(3, 3)
            return true
        end
        task.defer(function() getStats(true) end)
    end
    if eggCount("Basic") <= 0 and not buyBasicEgg() then return false end

    local order = {{3, 3}, {3, 4}, {3, 5}, {2, 3}, {4, 3}}
    -- The game's HoneycombTools iterates CellX 1..5 and CellY 1..10.
    for x = 1, 5 do
        for y = 1, 10 do table.insert(order, {x, y}) end
    end
    local seen = {}
    for _, cell in ipairs(order) do
        if Runtime.MeteorPriorityActive then return false end
        local key = cell[1] .. ":" .. cell[2]
        if not seen[key] and not hiveCellOccupied(cell[1], cell[2]) then
            seen[key] = true
            local beforeEggs = eggCount("Basic")
            local ok, remaining, success, honeycomb, discoveredBees, eggUses = remoteCall(
                "ConstructHiveCellFromEgg", cell[1], cell[2], "Basic", 1
            )
            applyHatchResponse("Basic", remaining, success, honeycomb, discoveredBees, eggUses)
            local accepted = hatchResponseAccepted(ok, beforeEggs, remaining, success)
            if (ok and success == true and type(honeycomb) == "table")
                or waitForHatchConfirmation(beforeBees, cell[1], cell[2], accepted and 0.5 or 0.45) then
                markBeeHatched(cell[1], cell[2])
                return true
            end
        end
    end
    task.defer(function() getStats(true) end)
    return beeCount() > beforeBees
end

function Runtime.NormalizeEventBeeName(value)
    local normalized = string.lower(tostring(value or "")):gsub("[^%w]", "")
    normalized = normalized:gsub("jelly$", ""):gsub("egg$", ""):gsub("bee$", "")
    return normalized
end

function Runtime.EventBeeInventory(entry, stats)
    stats = stats or MaterialSystem.Stats(false)
    local inventory = type(stats) == "table" and stats.Eggs or nil
    if type(inventory) ~= "table" then return 0, nil end
    local wanted = Runtime.NormalizeEventBeeName(entry.Type)
    for key, value in pairs(inventory) do
        local rawName = string.lower(tostring(key)):gsub("[^%w]", "")
        local amount = tonumber(value) or 0
        -- Permanent Event Jelly proves ownership but is not an egg and must not
        -- be sent to an empty hive cell as if it were one.
        if amount > 0 and not rawName:find("jelly", 1, true)
            and Runtime.NormalizeEventBeeName(key) == wanted then
            return amount, tostring(key)
        end
    end
    return 0, nil
end

function Runtime.EventBeeInHive(entry, stats)
    local wanted = Runtime.NormalizeEventBeeName(entry.Type)
    local reference = Player:FindFirstChild("Honeycomb")
    local hive = reference and reference:IsA("ObjectValue") and reference.Value
    local cells = hive and hive:FindFirstChild("Cells")
    if cells then
        for _, cell in ipairs(cells:GetChildren()) do
            local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
            if cellType and cellType:IsA("ValueBase")
                and Runtime.NormalizeEventBeeName(cellType.Value) == wanted then return true end
        end
    end

    stats = stats or MaterialSystem.Stats(false)
    local honeycomb = type(stats) == "table" and stats.Honeycomb or nil
    local visited = {}
    local function scan(value)
        if type(value) == "string" then return Runtime.NormalizeEventBeeName(value) == wanted end
        if type(value) ~= "table" or visited[value] then return false end
        visited[value] = true
        if scan(value.Type) or scan(value.BeeType) then return true end
        for _, child in pairs(value) do if scan(child) then return true end end
        return false
    end
    return scan(honeycomb)
end

function Runtime.EventBeeDiscovered(entry, stats)
    stats = stats or MaterialSystem.Stats(false)
    local discovered = type(stats) == "table" and stats.DiscoveredBees or nil
    if type(discovered) ~= "table" then return false end
    local wanted, visited = Runtime.NormalizeEventBeeName(entry.Type), {}
    local function scan(key, value)
        if type(key) == "string" and value ~= false and value ~= 0
            and Runtime.NormalizeEventBeeName(key) == wanted then return true end
        if type(value) == "string" then return Runtime.NormalizeEventBeeName(value) == wanted end
        if type(value) ~= "table" or visited[value] then return false end
        visited[value] = true
        for childKey, child in pairs(value) do if scan(childKey, child) then return true end end
        return false
    end
    return scan(nil, discovered)
end

function Runtime.EventBeePackages(entry)
    local result = {}
    for _, packageType in ipairs(entry.PackageTypes or {entry.Type}) do
        table.insert(result, {Category = entry.Category or "Eggs", Type = packageType, Amount = 1})
    end
    return result
end

function Runtime.EventBeeOwned(entry, stats)
    if Runtime.EventBeePurchased[entry.Type] then return true end
    stats = stats or MaterialSystem.Stats(false)
    if Runtime.EventBeeInHive(entry, stats) or Runtime.EventBeeDiscovered(entry, stats) then return true end
    if Runtime.EventBeeInventory(entry, stats) > 0 then return true end
    for _, package in ipairs(Runtime.EventBeePackages(entry)) do
        if rawPackageHas(package, stats) then return true end
    end
    return false
end

function Runtime.TicketCount(stats)
    stats = stats or MaterialSystem.Stats(false)
    local inventory = type(stats) == "table" and stats.Eggs or nil
    return math.max(0, math.floor(tonumber(inventory and (inventory.Ticket or inventory.Tickets)) or 0))
end

function Runtime.EventBeePackage(entry, stats)
    local candidates = Runtime.EventBeePackages(entry)
    if okPackages and ItemPackages and stats then
        for _, package in ipairs(candidates) do
            local ok, cost = pcall(ItemPackages.GetCost, package, stats)
            if ok and cost ~= nil then return package end
        end
    end
    -- Egg system names event eggs by bee type (Basic uses Type="Basic").
    return candidates[1] or {Category = "Eggs", Type = entry.Type, Amount = 1}
end

function Runtime.NextEventBee(refresh)
    -- The buy loop runs every 0.5s but must not force RetrievePlayerStats/StatCache
    -- every tick: only refresh when EventBeeStatsRefreshInterval is due; between
    -- checks use cached stats. At this rate tickets are still bought within ~2s of
    -- becoming affordable.
    if refresh and os.clock() - Runtime.LastEventBeeStatsRefresh
        < math.max(0.5, tonumber(Config.EventBeeStatsRefreshInterval) or 2) then
        refresh = false
    elseif refresh then
        Runtime.LastEventBeeStatsRefresh = os.clock()
    end
    local stats = MaterialSystem.Stats(refresh == true)
    local tickets = Runtime.TicketCount(stats)
    for _, entry in ipairs(Config.EventBeeSequence or {}) do
        if not Runtime.EventBeeOwned(entry, stats) then return entry, tickets, stats end
    end
    return nil, tickets, stats
end

function Runtime.BuyNextEventBee()
    if not Config.AutoBuyEventBees or not Config.Enabled or Runtime.EventBeeBusy
        or Runtime.MeteorPriorityActive then return false end
    local now = os.clock()
    if now - Runtime.LastEventBeeCheck < math.max(0.2, tonumber(Config.EventBeeCheckInterval) or 0.5) then
        return false
    end
    Runtime.LastEventBeeCheck = now
    local entry, tickets, stats = Runtime.NextEventBee(true)
    Runtime.EventBeePending = entry or false
    if not entry then return false end

    local required = math.max(0, math.floor(tonumber(entry.TicketCost) or 0))
    -- Strict order: below 500 for Tabby/Photon keep the tickets; do not skip ahead
    -- to buy the 250-cost Cobalt/Crimson first.
    if tickets < required then return false end
    local purchaseKey = "EventBee:" .. tostring(entry.Type)
    if (Runtime.PurchaseRetryAt[purchaseKey] or 0) > now then return false end

    Runtime.EventBeeBusy = true
    Runtime.PurchaseRetryAt[purchaseKey] = now + math.max(2, tonumber(Config.EventBeeRetryCooldown) or 12)
    setStatus("Buying Event Bee", string.format("%s | %d/%d tickets", entry.Item, tickets, required))
    local package = Runtime.EventBeePackage(entry, stats)
    if Runtime.MeteorPriorityActive then
        Runtime.EventBeeBusy = false
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        return false
    end
    local ok, result = remoteCall("ItemPackageEvent", "Purchase", package)
    task.wait(0.8)
    local refreshed = MaterialSystem.Stats(true)
    local ticketsAfter = Runtime.TicketCount(refreshed)
    local acquired = Runtime.EventBeeOwned(entry, refreshed)
        or (ok and result == true) or ticketsAfter <= tickets - required
    if acquired then
        Runtime.EventBeePurchased[entry.Type] = true
        Runtime.EventBeesPurchased += 1
        Runtime.EventBeePending = false
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        setStatus("Bought Event Bee", entry.Item .. " | " .. tostring(ticketsAfter) .. " tickets left")
    else
        setStatus("Waiting for Event Bee", entry.Item .. " | server result=" .. tostring(result))
    end
    Runtime.EventBeeBusy = false
    return acquired
end

function Runtime.HatchNextEventBee()
    if not Config.AutoHatchEventBees or Runtime.MeteorPriorityActive then return false end
    local stats = MaterialSystem.Stats(false)
    for _, entry in ipairs(Config.EventBeeSequence or {}) do
        local amount, eggType = Runtime.EventBeeInventory(entry, stats)
        if amount > 0 and eggType and not Runtime.EventBeeInHive(entry, stats) then
            local order = {{3, 3}, {3, 4}, {3, 5}, {2, 3}, {4, 3}}
            for x = 1, 5 do for y = 1, 10 do table.insert(order, {x, y}) end end
            local seen = {}
            for _, cell in ipairs(order) do
                local key = hiveCellKey(cell[1], cell[2])
                if not seen[key] and not hiveCellOccupied(cell[1], cell[2]) then
                    seen[key] = true
                    local beforeBees = beeCount()
                    setStatus("Hatch Event Bee", entry.Item)
                    local ok, remaining, success, honeycomb, discoveredBees, eggUses = remoteCall(
                        "ConstructHiveCellFromEgg", cell[1], cell[2], eggType, 1
                    )
                    applyHatchResponse(eggType, remaining, success, honeycomb, discoveredBees, eggUses)
                    local accepted = hatchResponseAccepted(ok, amount, remaining, success)
                    if (ok and success == true and type(honeycomb) == "table")
                        or waitForHatchConfirmation(beforeBees, cell[1], cell[2], accepted and 0.8 or 0.6) then
                        Runtime.ReservedHiveCells[key] = true
                        Runtime.EventBeePurchased[entry.Type] = true
                        Runtime.EventBeesHatched += 1
                        Runtime.SkipStatsBlockUntil = os.clock() + 2
                        task.defer(function() MaterialSystem.Stats(true) end)
                        return true
                    end
                    return false
                end
            end
        end
    end
    return false
end

local HIVE_SLOT = {Shop = "Mountaintop", Item = "Hive Slot", Category = "HiveSlot", Type = "Hive Slot", Amount = 1}

local function buyHiveSlot()
    if not Config.AutoBuyHiveSlots then return false end
    if Runtime.MeteorPriorityActive then return false end
    local before = hiveCapacity()
    local purchaseKey = "HiveSlot:Hive Slot"
    if (Runtime.PurchaseRetryAt[purchaseKey] or 0) > os.clock() then return false end
    local readiness = packageReadiness(HIVE_SLOT)
    local fallbackProbe = readiness == "unknown"
    if readiness == "honey" then
        setStatus("Farm hive money", "Not enough honey - skip the shop")
        return false
    elseif readiness == "locked" or readiness == "material" then
        setStatus("Hive Slot locked", readiness)
        return false
    elseif readiness == "unknown" then
        -- Cost scales with slot count; when ItemPackages is unavailable the server
        -- remains the source of truth. Probe once under the normal purchase cooldown.
        setStatus("Opening hive slot", "Remote fallback")
    end
    Runtime.PurchaseRetryAt[purchaseKey] = os.clock() + Config.PurchaseRetryCooldown
    setStatus("Opening hive slot", string.format("Hive capacity: %d", before))
    local moved = fallbackProbe or moveToShopItem(HIVE_SLOT)
    if not moved then setStatus("Opening hive slot", "Remote fallback") end
    if Runtime.MeteorPriorityActive then
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        return false
    end
    local ok, result = remoteCall("ItemPackageEvent", "Purchase", getPackage(HIVE_SLOT))
    local remoteConfirmed = ok and result == true
    if remoteConfirmed then
        Runtime.HiveCapacityFloor = math.max(Runtime.HiveCapacityFloor, before + 1)
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        task.defer(function() getStats(true) end)
        return true
    end
    task.wait(0.8)
    getStats(true)
    local acquired = hiveCapacity() > before
    if not acquired then
        Runtime.PurchaseRetryAt[purchaseKey] = os.clock()
            + (fallbackProbe and Config.UnknownPurchaseRetryCooldown or Config.DeniedPurchaseRetryCooldown)
        setStatus("Waiting for Hive Slot", ok and ("server result=" .. tostring(result)) or tostring(result))
    else
        Runtime.PurchaseRetryAt[purchaseKey] = nil
    end
    return acquired
end

local function growHiveOneBee()
    if Runtime.MeteorPriorityActive then return false end
    local count = beeCount()
    if count >= Config.ProgressionTargetBees then return true end
    if count >= hiveCapacity() and not buyHiveSlot() then return false end
    if Runtime.HatchNextEventBee() then return true end
    return hatchOneBasicEgg()
end

-- Wealth Clock is a ToyEvent instant. Prefer the game's replicated ToyTimes and
-- Cooldown values so re-executing the kaitun does not reset its one-hour timer.
function Runtime.ClaimWealthClock()
    if not Config.AutoWealthClock or not Config.Enabled or Runtime.MeteorPriorityActive then return false end
    local now = os.clock()
    if now < (Runtime.NextWealthClockCheck or 0) then return false end

    local interval = math.max(60, tonumber(Config.WealthClockInterval) or 3600)
    local toy = workspace:FindFirstChild("Toys")
    toy = toy and toy:FindFirstChild("Wealth Clock")
    local cooldown = toy and toy:FindFirstChild("Cooldown")
    if cooldown and cooldown:IsA("ValueBase") then interval = math.max(60, tonumber(cooldown.Value) or interval) end

    local serverNow = os.time()
    if type(Runtime.ServerNowFunction) ~= "function" then
        local module = ReplicatedStorage:FindFirstChild("OsTime")
        if module and module:IsA("ModuleScript") then
            local ok, value = pcall(require, module)
            if ok and type(value) == "function" then Runtime.ServerNowFunction = value end
        end
    end
    if type(Runtime.ServerNowFunction) == "function" then
        local ok, value = pcall(Runtime.ServerNowFunction)
        if ok and tonumber(value) then serverNow = tonumber(value) end
    end

    local stats = getStats(false)
    local toyTimes = type(stats) == "table" and stats.ToyTimes or nil
    local lastActivation = type(toyTimes) == "table" and tonumber(toyTimes["Wealth Clock"]) or nil
    if lastActivation then
        local remaining = interval - (serverNow - lastActivation)
        if remaining > 0 then
            Runtime.NextWealthClockCheck = now + math.max(1, math.min(remaining, tonumber(Config.WealthClockCheckInterval) or 15))
            return false
        end
    elseif now - Runtime.LastWealthClockAttempt < interval then
        Runtime.NextWealthClockCheck = Runtime.LastWealthClockAttempt + interval
        return false
    end

    Runtime.LastWealthClockAttempt = now
    setStatus("Wealth Clock", "Auto claim reward every hour")
    -- Walk to the clock like a real player (quest-NPC style), then claim.
    -- Falls back to the pure remote claim if the toy is not replicated.
    local clockToy = workspace:FindFirstChild("Toys")
    clockToy = clockToy and clockToy:FindFirstChild("Wealth Clock")
    local anchor = clockToy and (clockToy:FindFirstChild("Platform", true) or clockToy)
    local clockPosition = anchor and objectPosition(anchor)
    if clockPosition and not Runtime.MeteorPriorityActive then
        setStatus("Wealth Clock", "Walking to the clock")
        tweenTo(CFrame.new(clockPosition + Vector3.new(0, 3, 0)), Config.TweenSpeed, "WealthClock")
        task.wait(0.3)
    end
    if Runtime.MeteorPriorityActive then
        Runtime.LastWealthClockAttempt = 0 -- retried as soon as the meteor ends
        return false
    end
    local ok = remoteCall("ToyEvent", "Wealth Clock")
    if ok then
        Runtime.WealthClockClaims += 1
        Runtime.NextWealthClockCheck = now + interval
        task.delay(2, function()
            -- Confirm via ToyTimes so the hourly claim is visible in the log.
            local fresh = getStats(true)
            local toyTimes = type(fresh) == "table" and fresh.ToyTimes or nil
            if type(toyTimes) == "table" and tonumber(toyTimes["Wealth Clock"]) then
                warn(string.format("[BSS Kaitun] Wealth Clock claimed (%d total)",
                    Runtime.WealthClockClaims))
            else
                warn("[BSS Kaitun] Wealth Clock claim unconfirmed - retrying in 90s")
                Runtime.NextWealthClockCheck = os.clock() + 90
            end
        end)
        task.defer(function() getStats(true) end)
        return true
    end
    Runtime.NextWealthClockCheck = now + math.max(5, tonumber(Config.WealthClockRetryInterval) or 60)
    return false
end

local FIELD_REQUIREMENTS = {
    ["Mushroom Field"] = 0, ["Blue Flower Field"] = 0, ["Sunflower Field"] = 0,
    ["Dandelion Field"] = 0, ["Clover Field"] = 0, ["PuffField"] = 0,
    ["Strawberry Field"] = 5, ["Bamboo Field"] = 5, ["Spider Field"] = 5,
    ["Pineapple Patch"] = 10, ["Stump Field"] = 10,
    ["Rose Field"] = 15, ["Pine Tree Forest"] = 15, ["Pumpkin Patch"] = 15,
    ["Cactus Field"] = 15, ["Mountain Top Field"] = 25,
    ["Coconut Field"] = 35, ["Pepper Patch"] = 35,
}

local function findField(name)
    local zones = workspace:FindFirstChild("FlowerZones")
    return zones and name and zones:FindFirstChild(name) or nil
end

local function fieldUnlocked(name)
    if not name or not findField(name) then return false end
    return beeCount() >= (FIELD_REQUIREMENTS[name] or math.huge)
end

local function selectedFieldName()
    -- A booster-buffed field (x2+ pollen) always wins: farm exactly that field
    -- until the buff expires.
    if Runtime.BoostedField and os.clock() < (Runtime.BoostedFieldUntil or 0)
        and fieldUnlocked(Runtime.BoostedField) then
        return Runtime.BoostedField
    end
    if not Config.DynamicField then return Config.FarmField end
    local count = beeCount()
    local selected = Config.FarmField
    local bestRequirement = -math.huge
    for _, rule in ipairs(Config.FieldByBees) do
        local requirement = tonumber(rule.Bees) or 0
        if requirement <= count and requirement >= bestRequirement then
            selected = rule.Field
            bestRequirement = requirement
        end
    end
    return selected
end

local function getField()
    local zones = workspace:FindFirstChild("FlowerZones")
    if not zones then return nil end
    local fieldName = selectedFieldName()
    local field = zones:FindFirstChild(fieldName) or zones:FindFirstChild(Config.FarmField) or zones:FindFirstChildWhichIsA("BasePart")
    Runtime.CurrentField = field and field.Name or fieldName
    return field
end

local function fieldPoint(field)
    local position = objectPosition(field)
    if not position then return nil end
    if field:IsA("BasePart") then
        local x = (math.random() - 0.5) * math.max(2, field.Size.X * 0.72)
        local z = (math.random() - 0.5) * math.max(2, field.Size.Z * 0.72)
        return (field.CFrame * CFrame.new(x, field.Size.Y / 2 + 3, z)).Position
    end
    return position + Vector3.new(math.random(-12, 12), 3, math.random(-12, 12))
end

local function fieldSurfaceOffset(field, position)
    if not field or not position then return nil end
    local boundsCFrame, boundsSize
    if field:IsA("BasePart") then
        boundsCFrame, boundsSize = field.CFrame, field.Size
    elseif field:IsA("Model") then
        boundsCFrame, boundsSize = field:GetBoundingBox()
    else
        local part = field:FindFirstChildWhichIsA("BasePart", true)
        if part then boundsCFrame, boundsSize = part.CFrame, part.Size end
    end
    if not boundsCFrame or not boundsSize then return nil end
    local localPoint = boundsCFrame:PointToObjectSpace(position)
    return localPoint.Y - boundsSize.Y * 0.5
end

local function tokenNearFieldSurface(field, position)
    local offset = fieldSurfaceOffset(field, position)
    return offset ~= nil
        and offset >= Config.TokenMinHeightFromField
        and offset <= Config.TokenMaxHeightFromField
end

local function tokenAllowed(token)
    if not token or not token.Parent then return false end
    local cooldownUntil = Runtime.TokenCooldowns[token]
    if cooldownUntil and cooldownUntil > os.clock() then return false end
    if cooldownUntil then Runtime.TokenCooldowns[token] = nil end
    local owner = token:FindFirstChild("PlayerName") or token:FindFirstChild("Owner")
    if owner and owner:IsA("StringValue") and owner.Value ~= "" and owner.Value ~= Player.Name then return false end
    if owner and owner:IsA("ObjectValue") and owner.Value and owner.Value ~= Player then return false end
    return objectPosition(token) ~= nil
end

local TOKEN_UTILITY = {
    ticket = 18, mythic = 18, star = 16, jelly = 16, diamond = 15,
    link = 14, boost = 13, inspire = 12, precision = 11, baby = 10,
    focus = 9, haste = 9, rage = 8, bomb = 7, pollen = 6, honey = 5,
}

local function tokenDescriptor(token)
    local descriptor = string.lower(token.Name)
    local value = token:FindFirstChild("TokenType") or token:FindFirstChild("Type")
    if value and value:IsA("StringValue") then descriptor ..= " " .. string.lower(value.Value) end
    return descriptor
end

local function tokenNumber(token, names)
    for _, name in ipairs(names) do
        local ok, attribute = pcall(token.GetAttribute, token, name)
        if ok and tonumber(attribute) then return tonumber(attribute) end
        local value = token:FindFirstChild(name)
        if value and value:IsA("ValueBase") and tonumber(value.Value) then return tonumber(value.Value) end
    end
    return nil
end

local function tokenUtility(token, descriptor)
    local utility = 3
    for keyword, weight in pairs(TOKEN_UTILITY) do
        if descriptor:find(keyword, 1, true) then utility = math.max(utility, weight) end
    end
    local reward = tokenNumber(token, {"Honey", "HoneyValue", "Pollen", "PollenValue", "Reward", "RewardValue", "Value"})
    if reward and reward > 0 then utility += math.log(1 + reward) * 0.7 end
    return utility
end

local function tokenLifetime(token, now)
    local firstSeen = Runtime.TokenFirstSeen[token]
    if not firstSeen then
        firstSeen = now
        Runtime.TokenFirstSeen[token] = now
    end
    local absoluteExpiry = tokenNumber(token, {"ExpiresAt", "ExpirationTime", "ExpireTime"})
    local explicitRemaining = tokenNumber(token, {"TimeLeft", "Remaining", "RemainingTime"})
    local lifetime = tokenNumber(token, {"Lifetime", "Duration", "LifeTime"}) or Config.TokenDefaultLifetime
    local remaining = explicitRemaining
    if not remaining and absoluteExpiry then
        if absoluteExpiry > 100000000 then
            local ok, serverNow = pcall(workspace.GetServerTimeNow, workspace)
            if ok then remaining = absoluteExpiry - serverNow end
        else
            remaining = absoluteExpiry - now
        end
    end
    remaining = remaining or (lifetime - (now - firstSeen))
    return math.max(0, remaining), math.max(0.1, lifetime)
end

local function tokenEffects(descriptor)
    local speedMultiplier = descriptor:find("haste", 1, true) and 1.25 or 1
    local rewardMultiplier = 1
    for _, keyword in ipairs({"boost", "focus", "inspire", "precision", "rage", "baby", "link"}) do
        if descriptor:find(keyword, 1, true) then
            rewardMultiplier = 1.1
            break
        end
    end
    return speedMultiplier, rewardMultiplier
end

local function standingField()
    local _, _, root = getCharacter(1)
    if not root then return nil end
    local field = flowerFieldAtPosition(root.Position, Config.TokenFieldPadding)
    if field then Runtime.CurrentField = field.Name end
    return field
end

local function scanTokenNodesInStandingField()
    local folder = workspace:FindFirstChild("Collectibles")
    local _, humanoid, root = getCharacter(1)
    local field = standingField()
    if not folder or not humanoid or not root or not field then return {}, nil, nil end
    local now = os.clock()
    local nodes = {}
    for _, token in ipairs(folder:GetChildren()) do
        if tokenAllowed(token) then
            local position = objectPosition(token)
            if fieldContainsPosition(field, position, 0) and tokenNearFieldSurface(field, position) then
                local distance = (position - root.Position).Magnitude
                if distance <= Config.TokenMaxChaseDistance then
                    local descriptor = tokenDescriptor(token)
                    local remaining, lifetime = tokenLifetime(token, now)
                    if remaining > 0 then
                        local utility = tokenUtility(token, descriptor)
                        table.insert(nodes, {
                            Token = token,
                            Position = position,
                            Descriptor = descriptor,
                            Utility = utility,
                            Remaining = remaining,
                            Lifetime = lifetime,
                            Greedy = utility / math.max(0.1, distance / math.max(humanoid.WalkSpeed, 1) + Config.TokenCollectDelay),
                        })
                    end
                end
            end
        end
    end
    table.sort(nodes, function(a, b) return a.Greedy > b.Greedy end)
    while #nodes > Config.TokenSearchBreadth do table.remove(nodes) end
    return nodes, root, humanoid
end

local function searchTokenRoute(nodes, fromPosition, elapsed, depth, used, speedMultiplier, rewardMultiplier)
    if depth <= 0 then return 0, {} end
    local bestScore, bestRoute = 0, {}
    for index, node in ipairs(nodes) do
        if not used[index] and node.Token.Parent then
            local travelTime = (node.Position - fromPosition).Magnitude
                / math.max(1, 16 * speedMultiplier)
            local arrival = elapsed + travelTime + Config.TokenCollectDelay
            if arrival < node.Remaining then
                local timeLeftAtArrival = node.Remaining - arrival
                local urgency = 1 + Config.TokenUrgencyBonus
                    * math.clamp(1 - timeLeftAtArrival / node.Lifetime, 0, 1)
                local immediate = node.Utility * rewardMultiplier * urgency
                    - travelTime * Config.TokenTravelPenalty
                local effectSpeed, effectReward = tokenEffects(node.Descriptor)
                used[index] = true
                local futureScore, futureRoute = searchTokenRoute(
                    nodes,
                    node.Position,
                    arrival,
                    depth - 1,
                    used,
                    math.min(2, speedMultiplier * effectSpeed),
                    math.min(1.5, rewardMultiplier * effectReward)
                )
                used[index] = nil
                local total = immediate + futureScore * Config.TokenLookaheadDiscount
                if total > bestScore then
                    bestScore = total
                    bestRoute = {index}
                    for _, futureIndex in ipairs(futureRoute) do table.insert(bestRoute, futureIndex) end
                end
            end
        end
    end
    return bestScore, bestRoute
end

local function findBestTokenInStandingField()
    local nodes, root, humanoid = scanTokenNodesInStandingField()
    if not root or not humanoid or #nodes == 0 then
        Runtime.LastTokenPlan = ""
        Runtime.LastTokenScore = 0
        return nil, 0, {}
    end
    local score, route = searchTokenRoute(
        nodes,
        root.Position,
        0,
        math.max(1, Config.TokenSearchDepth),
        {},
        math.max(0.25, humanoid.WalkSpeed / 16),
        1
    )
    local planNames = {}
    for _, index in ipairs(route) do table.insert(planNames, nodes[index].Descriptor) end
    Runtime.LastTokenPlan = table.concat(planNames, " -> ")
    Runtime.LastTokenScore = score
    local first = route[1] and nodes[route[1]]
    return first and first.Token or nil, score, route
end

Runtime.FindBestToken = function()
    local token, score = findBestTokenInStandingField()
    return token, score, Runtime.LastTokenPlan
end

local function collectToken(token, owner)
    if not tokenAllowed(token) then return false end
    local position = objectPosition(token)
    if not position then return false end
    local field = standingField()
    if not field or not fieldContainsPosition(field, position, 0)
        or not tokenNearFieldSurface(field, position) then return false end
    Runtime.TokenCooldowns[token] = os.clock() + Config.TokenAttemptCooldown
    local movementOwner = owner or "Token"
    local meteorWalk = string.find(tostring(movementOwner), "Meteor", 1, true) == 1
    local ok = tweenTo(CFrame.new(position + Vector3.new(0, 1.5, 0)),
        Config.TokenTweenSpeed, movementOwner, meteorWalk)
    if ok then task.wait(0.12) end
    local _, _, root = getCharacter(1)
    local collected = ok and (not token.Parent or (root and (root.Position - position).Magnitude <= 7))
    if collected then
        Runtime.TokensCollected += 1
        Runtime.TokenCooldowns[token] = os.clock() + 0.45
    else
        Runtime.TokenCooldowns[token] = os.clock() + Config.TokenAttemptCooldown * 2
    end
    return collected
end

local function sweepTokens(duration, owner)
    if not Config.AutoTokens then return 0 end
    local deadline = os.clock() + math.max(0, duration or Config.TokenSweepDuration)
    local collected, attempts = 0, 0
    local meteorOwner = string.find(tostring(owner or ""), "Meteor", 1, true) == 1
    while Runtime.Running and Config.Enabled and os.clock() < deadline
        and (not Runtime.MeteorPriorityActive or meteorOwner)
        and collected < Config.TokenMaxPerSweep and attempts < Config.TokenMaxPerSweep * 2 do
        local token = findBestTokenInStandingField()
        if not token then break end
        attempts += 1
        if collectToken(token, owner or "TokenSweep") then collected += 1 end
    end
    return collected
end

local function placeSprinklerIfNeeded(field)
    if not Config.AutoPlaceSprinkler or not field then return false end
    if beeCount() < Config.MinSprinklerBees then return false end
    local fieldName = field.Name
    local due = os.clock() - Runtime.LastSprinklerPlace >= Config.SprinklerPlaceInterval
    if not due and Runtime.LastSprinklerField == fieldName then return false end
    local ok = remoteCall("PlayerActivesCommand", {Name = "Sprinkler Builder"})
    if ok then
        Runtime.LastSprinklerPlace = os.clock()
        Runtime.LastSprinklerField = fieldName
    end
    return ok
end

local function farmStep(seconds, overrideField, state, detail)
    if Runtime.MeteorPriorityActive then return false end
    local field = overrideField or getField()
    if not field then
        setStatus("Farm", "Field not found: " .. tostring(selectedFieldName()))
        task.wait(1)
        return false
    end
    if not fieldUnlocked(field.Name) then
        setStatus("Field locked", string.format("%s | needs %d bees", field.Name, FIELD_REQUIREMENTS[field.Name] or -1))
        return false
    end
    Runtime.CurrentField = field.Name
    local deadline = os.clock() + (seconds or 2)
    -- Surface the gear being saved for while farming: "Bamboo Field | next: Pouch 42%".
    local detailText = detail or Runtime.CurrentField
    if not detail then
        local target = Runtime.NextGearTarget
        if type(target) == "table" then
            local cost = tonumber(target.Cost)
            if cost and cost > 0 then
                local honey = liveCoreValue("Honey") or 0
                detailText = string.format("%s | next: %s %d%%",
                    Runtime.CurrentField, tostring(target.Item),
                    math.min(100, math.floor(honey / cost * 100 + 0.5)))
            else
                detailText = Runtime.CurrentField .. " | next: " .. tostring(target.Item)
            end
        end
    end
    setStatus(state or "Farm pollen", detailText)
    Runtime.Digging = true
    if standingField() ~= field then
        local openingPoint = fieldPoint(field)
        if openingPoint then tweenTo(CFrame.new(openingPoint), Config.TweenSpeed, "Farm") end
    end
    if Runtime.MeteorPriorityActive then Runtime.Digging = false return false end
    placeSprinklerIfNeeded(field)
    while Runtime.Running and Config.Enabled and not Runtime.MeteorPriorityActive and os.clock() < deadline do
        if Runtime.BootstrapComplete and Config.AutoFarmFireflies
            and Runtime.FireflyPending and not Runtime.FireflyBusy then
            Runtime.Digging = false
            return true
        end
        if Runtime.BootstrapComplete and Config.AutoFarmSprouts
            and Runtime.SproutPending and not Runtime.SproutBusy then
            Runtime.Digging = false
            return true
        end
        local ratio = pollenRatio()
        if Config.AutoConvert and ratio >= Config.ConvertPercent then Runtime.Digging = false return true end
        -- Mob threat active: the avoid worker owns the character (retreat/hold).
        -- Issuing farm moves now would drag the character back through the mob.
        if os.clock() < (Runtime.MobThreatUntil or 0) then
            task.wait(0.15)
            continue
        end
        if Config.AutoTokens then
            local remaining = math.max(0, deadline - os.clock())
            if sweepTokens(math.min(Config.TokenSweepDuration, remaining), "FarmToken") > 0 then continue end
        end
        local point = fieldPoint(field)
        if point then
            local startedAt = os.clock()
            tweenTo(CFrame.new(point), Config.TweenSpeed, "Farm")
            placeSprinklerIfNeeded(field)
            -- Only idle for the REMAINDER of the step delay: travel time already
            -- served as the per-spot dig pause, so the character flows between
            -- points instead of move - full stop - move.
            local idle = Config.FarmStepDelay - (os.clock() - startedAt)
            if idle > 0 then task.wait(idle) end
        else
            task.wait(Config.FarmStepDelay)
        end
    end
    Runtime.Digging = false
    return true
end

-- Quest router ---------------------------------------------------------------
local QUEST_NPC_SET = {}
for _, npcName in ipairs(Config.QuestNPCs) do QUEST_NPC_SET[npcName] = true end

local FIELD_COLORS = {
    ["Sunflower Field"] = "White", ["Dandelion Field"] = "White", ["Clover Field"] = "White",
    ["Spider Field"] = "White", ["Cactus Field"] = "White", ["Pumpkin Patch"] = "White",
    ["Pineapple Patch"] = "White", ["Coconut Field"] = "White",
    ["Mushroom Field"] = "Red", ["Strawberry Field"] = "Red", ["Rose Field"] = "Red",
    ["Pepper Patch"] = "Red", ["Blue Flower Field"] = "Blue", ["Bamboo Field"] = "Blue",
    ["Pine Tree Forest"] = "Blue", ["Stump Field"] = "Blue",
}

-- Free toys (Ant Pass, Blue Field Booster...): same pattern as Wealth Clock - reads
-- ToyTimes + the toy instance's Cooldown. Shared pads get a confirm + 90s retry
-- loop because the server silently drops fires while globally busy.
function Runtime.ClaimFreeToys()
    if not Config.AutoFreeToys or not Config.Enabled or Runtime.MeteorPriorityActive then return false end
    local now = os.clock()
    if now < (Runtime.NextFreeToyCheck or 0) then return false end
    Runtime.NextFreeToyCheck = now + 5
    local stats = getStats(false)
    local serverNow = MaterialSystem.Clock()
    local toysFolder = workspace:FindFirstChild("Toys")
    if not Runtime.ToyDiagnosticsShown then
        Runtime.ToyDiagnosticsShown = true
        for _, toyEntry in ipairs(Config.AutoToys or {}) do
            local toyName = tostring(toyEntry.Name or "")
            local instance = toysFolder and toysFolder:FindFirstChild(toyName)
            warn(string.format("[BSS Kaitun] Toy '%s': %s",
                toyName, instance and "found in workspace.Toys" or "not in workspace.Toys (remote still fired)"))
        end
    end
    for _, toyEntry in ipairs(Config.AutoToys or {}) do
        local toyName = tostring(toyEntry.Name or "")
        if toyName ~= "" and (Runtime.ToyRetryAt[toyName] or 0) <= now then
            local cooldown = math.max(60, tonumber(toyEntry.Cooldown) or 7200)
            local toyInstance = toysFolder and toysFolder:FindFirstChild(toyName)
            if toyInstance then
                local cooldownValue = toyInstance:FindFirstChild("Cooldown")
                if cooldownValue and cooldownValue:IsA("ValueBase") then
                    cooldown = math.max(60, tonumber(cooldownValue.Value) or cooldown)
                end
            end
            local toyTimes = type(stats) == "table" and stats.ToyTimes or nil
            local lastUse = type(toyTimes) == "table" and tonumber(toyTimes[toyName]) or nil
            local remaining = lastUse and math.max(0, cooldown - (serverNow - lastUse)) or 0
            if remaining > 0 then
                Runtime.ToyRetryAt[toyName] = now + math.clamp(remaining, 5, 300)
            else
                -- Shared pads (field boosters) can be globally busy: the server
                -- silently drops the fire and our ToyTimes stays empty. So do NOT
                -- park for the full cooldown - fire, confirm via a fresh stats
                -- read, and retry every 90s until the server accepts the tap.
                Runtime.ToyRetryAt[toyName] = now + 90
                setStatus("Free toy", toyName)
                if remoteCall("ToyEvent", toyName) then
                    task.delay(2, function()
                        -- Two-chance confirmation: the stats refresh is async and
                        -- can still be stale 2s after the tap.
                        local function confirmed()
                            local fresh = MaterialSystem.Stats(true)
                            local freshTimes = type(fresh) == "table" and fresh.ToyTimes or nil
                            if type(freshTimes) == "table" then
                                return tonumber(freshTimes[toyName])
                            end
                            return nil
                        end
                        local recorded = confirmed()
                        if not recorded then
                            task.wait(6)
                            recorded = confirmed()
                        end
                        if recorded then
                            Runtime.ToyConsecutiveBusy[toyName] = nil
                            Runtime.ToysClaimed += 1
                            Runtime.ToyRetryAt[toyName] = os.clock() + cooldown
                            warn(string.format("[BSS Kaitun] %s tapped (next in %.0f min)",
                                toyName, cooldown / 60))
                            if toyEntry.FieldBoost then
                                Runtime.DetectFieldBoost(MaterialSystem.Stats(false), toyEntry.FieldBoost)
                            end
                        else
                            -- Unconfirmed taps: the server may be busy OR the
                            -- ToyTimes key may not match. Either way it gates
                            -- duplicate taps itself, so after 3 tries park for
                            -- the full cooldown and warn only every 3rd attempt.
                            local busy = (Runtime.ToyConsecutiveBusy[toyName] or 0) + 1
                            Runtime.ToyConsecutiveBusy[toyName] = busy
                            if busy >= 3 then
                                Runtime.ToyRetryAt[toyName] = os.clock() + cooldown
                                if busy % 3 == 0 then
                                    warn(string.format(
                                        "[BSS Kaitun] %s unconfirmed after %d taps - parking %.0f min",
                                        toyName, busy, cooldown / 60))
                                end
                            else
                                Runtime.ToyRetryAt[toyName] = os.clock() + 90
                                warn(string.format("[BSS Kaitun] %s busy on server - retrying in 90s (%d/3)",
                                    toyName, busy))
                            end
                        end
                    end)
                end
            end
        end
    end
    return true
end

-- Find the buffed field in stats (field name -> multiplier/expire map).
-- Only fields in BoostedFieldWhitelist (the 3 main blue fields) are accepted;
-- preferring the field matching the tapped booster color (Blue).
function Runtime.DetectFieldBoost(stats, colorHint)
    if type(stats) ~= "table" then return false end
    local whitelist = Config.BoostedFieldWhitelist
    local function allowed(fieldName)
        if type(whitelist) ~= "table" or #whitelist <= 0 then return true end
        for _, name in ipairs(whitelist) do
            if name == fieldName then return true end
        end
        return false
    end
    local visited = {}
    local best, bestIsHinted
    local function scan(value)
        if type(value) ~= "table" or visited[value] then return end
        visited[value] = true
        for key, child in pairs(value) do
            if type(key) == "string" and FIELD_COLORS[key] ~= nil and allowed(key) then
                local multiplier = tonumber(child)
                if type(child) == "table" then
                    multiplier = tonumber(child.Value or child.Mult or child.Boost or child.Amount or child.Multiplier)
                end
                if multiplier and multiplier > 1 then
                    local hinted = colorHint ~= nil and FIELD_COLORS[key] == colorHint
                    if not best or (hinted and not bestIsHinted) then
                        best = key
                        bestIsHinted = hinted
                    end
                end
            elseif type(child) == "table" then
                scan(child)
            end
        end
    end
    scan(stats)
    if best and fieldUnlocked(best) then
        Runtime.BoostedField = best
        Runtime.BoostedFieldUntil = os.clock() + 900
        setStatus("Field boost", string.format("%s | farm this field for %d min", best, 15))
        return true
    end
    return false
end

local function questCall(method, ...)
    if not okQuests or type(Quests) ~= "table" or type(Quests[method]) ~= "function" then return nil end
    local oldIdentity
    if type(GetThreadIdentity) == "function" then pcall(function() oldIdentity = GetThreadIdentity() end) end
    if type(SetThreadIdentity) == "function" then pcall(SetThreadIdentity, 2) end
    local packed = table.pack(pcall(Quests[method], Quests, ...))
    if type(SetThreadIdentity) == "function" and oldIdentity ~= nil then pcall(SetThreadIdentity, oldIdentity) end
    if not packed[1] then return nil end
    return table.unpack(packed, 2, packed.n)
end

local function activeBearQuests(refresh)
    -- TTL cache: each scan invokes the quest module twice PER QUEST through an
    -- identity-2 call - not cheap. All background systems share one snapshot;
    -- only quest turn-ins (refresh=true) bypass it to see the new quest fast.
    local now = os.clock()
    local cache = Runtime.QuestScanCache
    if not refresh and cache and now - cache.At < (tonumber(Config.QuestScanInterval) or 5) then
        return cache.List
    end
    local stats = getStats(refresh)
    local active = stats and stats.Quests and stats.Quests.Active
    local result = {}
    if type(active) == "table" then
        for _, entry in pairs(active) do
            local questName = type(entry) == "table" and entry.Name or entry
            if type(questName) == "string" then
                local info = questCall("Get", questName)
                if type(info) == "table" and QUEST_NPC_SET[info.NPC] and not info.Hidden then
                    local progress = questCall("Progress", questName, stats)
                    table.insert(result, {
                        Name = questName,
                        NPC = info.NPC,
                        Info = info,
                        Progress = type(progress) == "table" and progress or {},
                    })
                end
            end
        end
    end
    Runtime.QuestScanCache = {At = now, List = result}
    return result
end

-- Black Bear Diamond Egg stop rule. The quest line is strictly sequential, so
-- the account's ACTIVE quest alone reveals progress - no script history needed:
--   "past"   = active quest is after "Quest Of Legends" (Star/Mythic line or a
--              repeatable "Black Bear: ...") -> Diamond Egg already claimed.
--   "at"     = active quest IS the Diamond Egg quest -> complete it, then stop.
--   "before" = earlier quest -> keep going. "none" = no Black Bear quest yet.
local function normalizedQuestName(value)
    return string.lower(tostring(value or "")):gsub("[^%w]", "")
end

function Runtime.BlackBearStopState()
    if Runtime.BlackBearStopped then return "past" end
    if not Config.BlackBearStopAfterQuest then return "before" end
    if not Runtime.BlackBearPastSet then
        Runtime.BlackBearPastSet = {}
        for name in string.gmatch(tostring(Config.BlackBearPastQuests or ""), "[^|]+") do
            Runtime.BlackBearPastSet[normalizedQuestName(name)] = true
        end
    end
    local stopQuest = normalizedQuestName(Config.BlackBearStopAfterQuest)
    for _, quest in ipairs(activeBearQuests(false)) do
        if quest.NPC == "Black Bear" then
            local name = normalizedQuestName(quest.Name)
            if name == stopQuest then return "at" end
            if Runtime.BlackBearPastSet[name] then return "past" end
            -- Repeatable quests ("Black Bear: ...") only unlock after the full line.
            if string.sub(name, 1, 9) == "blackbear" then return "past" end
            return "before"
        end
    end
    return "none"
end

local function questTaskDescription(taskData, stats)    if type(taskData.Description) == "string" then return taskData.Description end
    if type(taskData.Description) == "function" then
        local ok, value = pcall(taskData.Description, stats)
        if ok then return tostring(value) end
    end
    return tostring(taskData.Type or "Quest task")
end

local function incompleteQuestObjectives(refresh)
    local stats = getStats(refresh)
    local objectives = {}
    for _, quest in ipairs(activeBearQuests(false)) do
        for index, taskData in ipairs(quest.Info.Tasks or {}) do
            local progress = quest.Progress[index] or {}
            if (tonumber(progress[1]) or 0) < 1 then
                table.insert(objectives, {
                    Quest = quest.Name,
                    NPC = quest.NPC,
                    Task = taskData,
                    Progress = progress,
                    Description = questTaskDescription(taskData, stats),
                })
            end
        end
    end
    return objectives
end

Runtime.WaitForScienceQuest = function(previousQuest)
    local deadline = os.clock() + math.max(2, tonumber(Config.ScienceQuestConfirmTimeout) or 6)
    repeat
        local scienceQuest
        for _, quest in ipairs(activeBearQuests(true)) do
            if quest.NPC == "Science Bear" then
                scienceQuest = quest
                if not previousQuest or quest.Name ~= previousQuest then break end
            end
        end
        if scienceQuest and (not previousQuest or scienceQuest.Name ~= previousQuest) then
            Runtime.CurrentQuest = scienceQuest.Name
            local objectives = incompleteQuestObjectives(false)
            local count = 0
            for _, objective in ipairs(objectives) do
                if objective.NPC == "Science Bear" and objective.Quest == scienceQuest.Name then count += 1 end
            end
            setStatus("Science quest", string.format("%s | scan %d objective", scienceQuest.Name, count))
            return scienceQuest
        end
        task.wait(0.25)
    until not Runtime.Running or Runtime.MeteorPriorityActive or os.clock() >= deadline
    return nil
end

local function bestUnlockedColorField(color)
    local wanted = tostring(color)
    local configured = Config.BestColorFields[wanted] or {}
    for _, name in ipairs(configured) do
        if FIELD_COLORS[name] == wanted and fieldUnlocked(name) then return name end
    end
    local current = standingField()
    if current and FIELD_COLORS[current.Name] == wanted and fieldUnlocked(current.Name) then return current.Name end
    for name, fieldColor in pairs(FIELD_COLORS) do
        if fieldColor == wanted and fieldUnlocked(name) then return name end
    end
    return nil
end

-- Spawner names come from Workspace.MonsterSpawners (same source used by the
-- game's timer UI). Cooldowns are fallbacks only; MonsterTypes is authoritative.
Runtime.MobRoutes = {
    ["Ladybug"] = {
        Fields = {"Mushroom Field", "Clover Field", "Strawberry Field"},
        Spawners = {"MushroomBush", "Ladybug Bush", "Ladybug Bush 2", "Ladybug Bush 3"}, Cooldown = 300,
    },
    ["Rhino Beetle"] = {
        Fields = {"Blue Flower Field", "Clover Field", "Bamboo Field", "Pineapple Patch"},
        Spawners = {"Rhino Bush", "Rhino Cave 1", "Rhino Cave 2", "Rhino Cave 3", "PineappleBeetle"}, Cooldown = 300,
    },
    ["Spider"] = {Fields = {"Spider Field"}, Spawners = {"Spider Cave"}, Cooldown = 1800},
    ["Mantis"] = {
        Fields = {"Pineapple Patch", "Pine Tree Forest"},
        Spawners = {"ForestMantis1", "ForestMantis2", "PineappleMantis1"}, Cooldown = 1200,
    },
    ["Scorpion"] = {Fields = {"Rose Field"}, Spawners = {"RoseBush", "RoseBush2"}, Cooldown = 1200},
    ["Werewolf"] = {
        Fields = {"Cactus Field", "Pumpkin Patch", "Pine Tree Forest"},
        Spawners = {"WerewolfCave"}, Cooldown = 3600,
    },
    ["King Beetle"] = {Fields = {"Clover Field"}, Spawners = {"King Beetle Cave"}, Cooldown = 86400},
    ["Tunnel Bear"] = {Fields = {}, Spawners = {"TunnelBear"}, Cooldown = 172800, AllowNoField = true},
    ["Stump Snail"] = {Fields = {"Stump Field"}, Spawners = {"StumpSnail"}, Cooldown = 345600},
}

Runtime.NormalizeMobType = function(value)
    local normalized = string.lower(tostring(value or "")):gsub("[^%w]", "")
    normalized = normalized:gsub("ladybugs$", "ladybug"):gsub("spiders$", "spider")
        :gsub("mantises$", "mantis"):gsub("scorpions$", "scorpion")
        :gsub("werewolves$", "werewolf"):gsub("rhinobeetles$", "rhinobeetle")
    return normalized
end

Runtime.QuestMobRoute = function(value)
    local wanted = Runtime.NormalizeMobType(value)
    for name, route in pairs(Runtime.MobRoutes) do
        if Runtime.NormalizeMobType(name) == wanted then return name, route end
    end
    return nil
end

Runtime.FindLiveQuestMob = function(mobType)
    local canonical = Runtime.QuestMobRoute(mobType)
    local monsters = workspace:FindFirstChild("Monsters")
    if not canonical or not monsters then return nil end
    local wanted = Runtime.NormalizeMobType(canonical)
    for _, mob in ipairs(monsters:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and objectPosition(mob)
            and string.find(Runtime.NormalizeMobType(mob.Name), wanted, 1, true) then return mob end
    end
    return nil
end

Runtime.NearestMobField = function(position, route)
    local best, bestDistance
    for _, fieldName in ipairs(route.Fields or {}) do
        if fieldUnlocked(fieldName) then
            local field = findField(fieldName)
            local point = field and objectPosition(field)
            local distance = position and point and (point - position).Magnitude or math.huge
            if field and (not best or distance < bestDistance) then
                best, bestDistance = field, distance
            end
        end
    end
    return best
end

Runtime.QuestMobSpawnerReady = function(spawner, route, stats)
    if not spawner then return false, math.huge end
    local attachment = spawner:FindFirstChild("Attachment") or spawner:FindFirstChild("TimerAttachment")
    local timerGui = attachment and attachment:FindFirstChild("TimerGui")
    local timerLabel = timerGui and timerGui:FindFirstChild("TimerLabel")
    if timerLabel and timerLabel:IsA("GuiObject") and timerLabel.Visible == false then return true, 0 end

    if Runtime.MonsterTypes == nil then
        local module = ReplicatedStorage:FindFirstChild("MonsterTypes")
        local ok, value = false, nil
        if module then ok, value = pcall(require, module) end
        if ok and type(value) == "table" then Runtime.MonsterTypes = value else Runtime.MonsterTypes = false end
    end
    local cooldown = tonumber(route.Cooldown) or 300
    local typeValue = spawner:FindFirstChild("MonsterType")
    if type(Runtime.MonsterTypes) == "table" and type(Runtime.MonsterTypes.Get) == "function" and typeValue then
        local ok, definition = pcall(Runtime.MonsterTypes.Get, typeValue.Value)
        local moduleCooldown = ok and type(definition) == "table" and definition.Stats
            and tonumber(definition.Stats.RespawnCooldown) or nil
        if moduleCooldown then cooldown = moduleCooldown end
    end
    local reduction = 0
    pcall(function() reduction = tonumber(stats.ModifierCaches.Value.MonsterCooldownReduction._) or 0 end)
    cooldown *= math.clamp(1 - reduction, 0.05, 1)
    local monsterTimes = type(stats) == "table" and stats.MonsterTimes or nil
    local lastKill = type(monsterTimes) == "table" and tonumber(monsterTimes[spawner.Name]) or nil
    if not lastKill then return timerLabel == nil or not timerLabel.Visible, 0 end
    local remaining = cooldown + math.max(0, tonumber(Config.QuestMobSpawnGrace) or 15) - (os.time() - lastKill)
    return remaining <= 0, math.max(0, remaining)
end

Runtime.FindQuestMobJob = function(mobType)
    if not Config.AutoQuestMobs or Runtime.MeteorPriorityActive then return nil end
    local canonical, route = Runtime.QuestMobRoute(mobType)
    if not canonical then
        -- Some quest definitions use a generic "Monsters" target. In that case,
        -- pick the first currently available route instead of farming a random field.
        local generic = Runtime.NormalizeMobType(mobType)
        if generic ~= "" and generic ~= "monster" and generic ~= "monsters" and generic ~= "any" then return nil end
        for routeName in pairs(Runtime.MobRoutes) do
            local job = Runtime.FindQuestMobJob(routeName)
            if job then return job end
        end
        return nil
    end
    local live = Runtime.FindLiveQuestMob(canonical)
    local livePosition = live and objectPosition(live)
    if live then
        local field = Runtime.NearestMobField(livePosition, route)
        if field or route.AllowNoField then return {Name = canonical, Route = route, Live = live, Field = field} end
    end
    if (Runtime.QuestMobRetryAt[canonical] or 0) > os.clock() then return nil end

    local spawners = workspace:FindFirstChild("MonsterSpawners")
    local stats = getStats(false) or {}
    local shortest = math.huge
    for _, spawnerName in ipairs(route.Spawners or {}) do
        local spawner = spawners and spawners:FindFirstChild(spawnerName)
        if spawner then
            local ready, remaining = Runtime.QuestMobSpawnerReady(spawner, route, stats)
            shortest = math.min(shortest, remaining or math.huge)
            if ready then
                local field = Runtime.NearestMobField(objectPosition(spawner), route)
                if field or route.AllowNoField then
                    return {Name = canonical, Route = route, Spawner = spawner, Field = field}
                end
            end
        end
    end
    local retry = shortest < math.huge and shortest or (tonumber(Config.QuestMobRecheckInterval) or 20)
    Runtime.QuestMobRetryAt[canonical] = os.clock() + math.clamp(retry, 3, 60)
    return nil
end

Runtime.FarmQuestMob = function(objective, seconds)
    local taskData = objective and objective.Task or nil
    local job = taskData and Runtime.FindQuestMobJob(taskData.MonsterType) or nil
    if not job then return false, false end
    Runtime.CurrentQuest = objective.Quest
    Runtime.CurrentQuestMob = job.Name
    Runtime.CurrentField = job.Field and job.Field.Name or ""
    Runtime.QuestCurrentField = Runtime.CurrentField
    Runtime.QuestFarming = true
    Runtime.Digging = true
    setStatus("Kill quest mob", string.format("%s | %s", objective.Quest, job.Name))

    local destination = job.Field and fieldPoint(job.Field) or objectPosition(job.Spawner or job.Live)
    if destination and not tweenTo(CFrame.new(destination + Vector3.new(0, 3, 0)), Config.TweenSpeed, "QuestMob") then
        Runtime.Digging, Runtime.QuestFarming = false, false
        return false, true
    end
    local deadline = os.clock() + math.max(6, tonumber(seconds) or tonumber(Config.QuestMobFightTimeout) or 24)
    local spawnDeadline = os.clock() + math.max(2, tonumber(Config.QuestMobSpawnWait) or 12)
    local sawLive = false
    while Runtime.Running and Config.Enabled and not Runtime.MeteorPriorityActive and os.clock() < deadline do
        local live = Runtime.FindLiveQuestMob(job.Name)
        if live then
            sawLive = true
            local position = objectPosition(live)
            local _, humanoid, root = getCharacter(1)
            if position and humanoid and root and (root.Position - position).Magnitude > Config.MobScanRadius then
                tweenTo(CFrame.new(position + Vector3.new(0, 2, 8)), Config.TweenSpeed, "QuestMob")
            elseif humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
            end
            remoteCall("ToolCollect")
        elseif sawLive or os.clock() >= spawnDeadline then
            break
        end
        task.wait(0.2)
    end
    Runtime.Digging = false
    Runtime.QuestFarming = false
    Runtime.CurrentQuestMob = ""
    Runtime.QuestMobRetryAt[job.Name] = os.clock() + (sawLive and 2 or math.max(5, tonumber(Config.QuestMobRecheckInterval) or 20))
    if sawLive and Config.AutoTokens then sweepTokens(2, "QuestMobDrop") end
    task.defer(function() getStats(true) end)
    return sawLive, true
end

local function objectiveField(objective)
    local taskData = objective.Task
    if taskData.Zone then
        if fieldUnlocked(taskData.Zone) then return taskData.Zone, true end
        -- Farming an alternate field does not advance objectives requiring a specific Zone.
        -- Skip locked objectives so the planner can move to Science Bear.
        return nil, true
    end
    local color = taskData.Color or taskData.Tag
    if color and Config.BestColorFields[tostring(color)] then return bestUnlockedColorField(color), false end
    local kind = tostring(taskData.Type or "")
    if kind == "Defeat Monsters" then
        -- Kill objectives are handled by the cooldown-aware mob scheduler only.
        return nil, true
    end
    if kind == "Collect Pollen" or kind == "Collect Goo" then
        return bestUnlockedColorField("White") or selectedFieldName(), false
    end
    return nil, false
end

local function fieldAdvancesObjective(fieldName, objective)
    local taskData = objective.Task
    if taskData.Zone then
        return taskData.Zone == fieldName and fieldUnlocked(taskData.Zone)
    end
    local color = taskData.Color or taskData.Tag
    if color and Config.BestColorFields[tostring(color)] then return FIELD_COLORS[fieldName] == tostring(color) end
    if taskData.Type == "Defeat Monsters" then return false end
    return taskData.Type == "Collect Pollen" or taskData.Type == "Collect Goo"
end

local function chooseQuestField(objectives)
    local candidates = {}
    local npcRanks = {}
    for index, npcName in ipairs(Config.QuestFarmPriority or Config.QuestNPCs or {}) do
        npcRanks[npcName] = index
    end
    for _, objective in ipairs(objectives) do
        local name, explicit = objectiveField(objective)
        if name and fieldUnlocked(name) then
            candidates[name] = candidates[name] or {
                Name = name, Score = 0, Objectives = {}, Explicit = false,
                NPCRank = math.huge, PrimaryObjective = nil,
            }
            candidates[name].Explicit = candidates[name].Explicit or explicit
        end
    end
    for _, candidate in pairs(candidates) do
        for _, objective in ipairs(objectives) do
            if fieldAdvancesObjective(candidate.Name, objective) then
                table.insert(candidate.Objectives, objective)
                candidate.Score += 10 + (objective.Task.Zone and 5 or 0)
                local rank = npcRanks[objective.NPC] or 999
                if rank < candidate.NPCRank then
                    candidate.NPCRank = rank
                    candidate.PrimaryObjective = objective
                end
            end
        end
    end
    local current = standingField()
    local best
    for _, candidate in pairs(candidates) do
        if current and current.Name == candidate.Name then candidate.Score += 8 end
        if not best or candidate.NPCRank < best.NPCRank
            or (candidate.NPCRank == best.NPCRank and candidate.Score > best.Score) then
            best = candidate
        end
    end
    return best
end

local function findQuestNPC(name)
    local folder = workspace:FindFirstChild("NPCs")
    return folder and (folder:FindFirstChild(name) or folder:FindFirstChild(name, true)) or nil
end

local function npcDialogueVisible()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
    local npcGui = screenGui and screenGui:FindFirstChild("NPC")
    return npcGui ~= nil and npcGui.Visible == true, npcGui
end

local function incrementNPCDialogue()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    local cameraGui = playerGui and playerGui:FindFirstChild("Camera")
    local controllers = cameraGui and cameraGui:FindFirstChild("Controllers")
    local npcController = controllers and controllers:FindFirstChild("NPC")
    local increment = npcController and npcController:FindFirstChild("IncrementDialogue")
    if increment then return pcall(function() increment:Invoke() end) end
    local visible, npcGui = npcDialogueVisible()
    local overlay = visible and npcGui:FindFirstChild("ButtonOverlay", true)
    if overlay and overlay:IsA("GuiButton") and overlay.Visible then
        if firesignal then return pcall(firesignal, overlay.MouseButton1Click) end
        return pcall(function() overlay:Activate() end)
    end
    return false
end

local function interactQuestNPC(name)
    local npc = findQuestNPC(name)
    local platform = npc and npc:FindFirstChild("Platform", true)
    if not npc or not platform or not platform:IsA("BasePart") then
        Runtime.NPCModuleError = "NPC.Platform not found"
        return false
    end
    setStatus("Going to NPC", name)
    if not tweenTo(CFrame.new(platform.Position + Vector3.new(0, 5, 0)), Config.TweenSpeed, "QuestNPC") then return false end
    -- Short settle only: the arrival check below gates the interaction anyway.
    task.wait(0.3)
    if Runtime.MeteorPriorityActive then return false end
    local _, _, root = getCharacter(1)
    local distance = root and (root.Position - platform.Position).Magnitude or math.huge
    if distance > 25 then
        Runtime.NPCModuleError = string.format("out of range %.1f studs", distance)
        return false
    end

    local activatables = ReplicatedStorage:FindFirstChild("Activatables")
    local moduleScript = activatables and activatables:FindFirstChild("NPCs")
    local okRequire, npcModule = false, nil
    if moduleScript then okRequire, npcModule = pcall(require, moduleScript) end
    if not okRequire or type(npcModule) ~= "table" or type(npcModule.ButtonEffect) ~= "function" then
        Runtime.NPCModuleError = okRequire and "ButtonEffect missing" or tostring(npcModule)
        return false
    end

    local opened = false
    for attempt = 1, 3 do
        if Runtime.MeteorPriorityActive then return false end
        setStatus("Turn in/accept quest", string.format("%s | attempt %d/3", name, attempt))
        local oldIdentity
        if type(GetThreadIdentity) == "function" then pcall(function() oldIdentity = GetThreadIdentity() end) end
        if type(SetThreadIdentity) == "function" then pcall(SetThreadIdentity, 2) end
        local invoked, invokeError = pcall(npcModule.ButtonEffect, Player, npc)
        if type(SetThreadIdentity) == "function" and oldIdentity ~= nil then pcall(SetThreadIdentity, oldIdentity) end
        if not invoked then Runtime.NPCModuleError = tostring(invokeError) end
        local deadline = os.clock() + 1.5
        repeat
            opened = npcDialogueVisible()
            if opened then break end
            task.wait(0.05)
        until os.clock() >= deadline or not Runtime.Running or Runtime.MeteorPriorityActive
        if opened then break end
    end
    if not opened then return false end

    local deadline = os.clock() + Config.QuestInteractTimeout
    while Runtime.Running and not Runtime.MeteorPriorityActive and os.clock() < deadline do
        local visible = npcDialogueVisible()
        if not visible then break end
        incrementNPCDialogue()
        RunService.Stepped:Wait()
    end
    task.wait(0.2)
    getStats(true)
    Runtime.NPCModuleError = ""
    return true
end

local function maintainBearQuests()
    if not Config.AutoQuest or os.clock() - Runtime.LastQuestCheck < Config.QuestCheckInterval then return false end
    Runtime.LastQuestCheck = os.clock()
    local active = activeBearQuests(true)
    local currentBees = beeCount()
    for _, npcName in ipairs(Config.QuestNPCs) do
        local requiredBees = tonumber((Config.QuestNPCBeeRequirements or {})[npcName]) or 0
        if currentBees < requiredBees then continue end
        local hasQuest, allDone, previousQuest = false, true, nil
        for _, quest in ipairs(active) do
            if quest.NPC == npcName then
                hasQuest = true
                previousQuest = previousQuest or quest.Name
                if next(quest.Progress) == nil and #(quest.Info.Tasks or {}) > 0 then allDone = false end
                for _, progress in pairs(quest.Progress) do
                    if (tonumber(progress[1]) or 0) < 1 then allDone = false break end
                end
            end
        end
        -- Diamond Egg stop rule: never interact with Black Bear again once the
        -- Diamond Egg quest is done or provably already claimed on this account.
        if npcName == "Black Bear" and Config.BlackBearStopAfterQuest
            and Runtime.BlackBearStopState() == "past" then
            continue
        end
        if not hasQuest or allDone then
            local stopAfterTurnIn = npcName == "Black Bear" and hasQuest
                and Runtime.BlackBearStopState() == "at"
            local ok = interactQuestNPC(npcName)
            if not ok then
                setStatus("Quest NPC error", npcName .. " | " .. Runtime.NPCModuleError)
            elseif stopAfterTurnIn then
                Runtime.BlackBearStopped = true
                setStatus("Black Bear done", "Diamond Egg claimed - stopping Black Bear quests")
            elseif npcName == "Science Bear" then
                local confirmed = Runtime.WaitForScienceQuest(previousQuest)
                if not confirmed then
                    Runtime.LastQuestCheck = -math.huge
                    Runtime.NPCModuleError = "Science quest not replicated - will rescan"
                    setStatus("Waiting for Science quest", Runtime.NPCModuleError)
                end
            end
            return true
        end
    end
    return false
end

-- Mother Bear quest engine: auto-completes "Feed X Treats" and "Use X Royal
-- Jelly" tasks. Both share the ConstructHiveCellFromEgg remote (like Basic Egg
-- and Unlock Blue HQ): eggType = "Treat" or "RoyalJelly". Jelly only targets
-- non-gifted common bees so event/mythic bees stay untouched.
local function hiveBeeCells()
    local reference = Player:FindFirstChild("Honeycomb")
    local hive = reference and reference:IsA("ObjectValue") and reference.Value
    local cells = hive and hive:FindFirstChild("Cells")
    if not cells then return {} end
    local result = {}
    for _, cell in ipairs(cells:GetChildren()) do
        local x, y = cell.Name:match("^C(%d+),(%d+)$")
        local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
        if x and y and cellType and cellType:IsA("ValueBase") then
            local locked = cell:FindFirstChild("CellLocked")
            table.insert(result, {
                Instance = cell,
                X = tonumber(x),
                Y = tonumber(y),
                Type = tostring(cellType.Value),
                Gifted = cell:FindFirstChild("GiftedCell") ~= nil,
                Locked = locked and locked:IsA("ValueBase") and locked.Value == true or false,
            })
        end
    end
    return result
end

function Runtime.IsCommonBeeType(value)
    local normalized = string.lower(tostring(value or "")):gsub("[^%w]", ""):gsub("bee$", "")
    for _, beeName in ipairs(Config.CommonBeeTypes or {}) do
        local wanted = string.lower(tostring(beeName)):gsub("[^%w]", ""):gsub("bee$", "")
        if normalized == wanted then return true end
    end
    return false
end

-- Safe target bee: non-gifted common is always safe; when not
-- commonOnly, fall back to the first unlocked bee (feed only).
function Runtime.FindQuestTargetBee(commonOnly)
    local fallback
    for _, entry in ipairs(hiveBeeCells()) do
        if beeTypePresent(entry.Type) and not entry.Locked then
            if Runtime.IsCommonBeeType(entry.Type) and not entry.Gifted then
                return entry
            end
            fallback = fallback or entry
        end
    end
    if commonOnly then return nil end
    return fallback
end

-- Task classification by Type + Description: "jelly" = use royal jelly,
-- "treat" = feed treat, nil = other. Case-insensitive matching toler
-- differences between quest module versions.
function Runtime.QuestTaskKind(objective)
    local taskData = type(objective) == "table" and objective.Task or {}
    local text = string.lower(tostring(taskData.Type or "") .. " " .. tostring(objective and objective.Description or ""))
    if text:find("collect", 1, true) then return nil end
    local jelly = text:find("jelly", 1, true) ~= nil or text:find("jelli", 1, true) ~= nil
    local feed = text:find("feed", 1, true) ~= nil
    local use = text:find("use", 1, true) ~= nil
    -- Treat-family tasks include the SPECIFIC foods Mother Bear asks for
    -- ("Feed X Strawberries/Blueberries/Pineapples/Sunflower Seeds"), not just
    -- the generic word "treat".
    local treat = text:find("treat", 1, true) ~= nil
        or text:find("strawberr", 1, true) ~= nil
        or text:find("blueberr", 1, true) ~= nil
        or text:find("pineapple", 1, true) ~= nil
        or text:find("sunflower seed", 1, true) ~= nil
    if jelly and (use or feed) then return "jelly" end
    if treat and (feed or use) then return "treat" end
    return nil
end

function Runtime.QuestTaskStillIncomplete(objective)
    for _, other in ipairs(incompleteQuestObjectives(true)) do
        if other.Quest == objective.Quest
            and (other.Task == objective.Task
                or tostring(other.Description) == tostring(objective.Description)) then
            return true
        end
    end
    return false
end

-- Quest treat identification: Mother Bear tasks can require SPECIFIC foods
-- ("Feed X Strawberries/Blueberries/Pineapples/Sunflower Seeds"). The specific
-- food is parsed from the task text and matched to its inventory key; generic
-- "Treats" fall back to "Treat". Checked longest-first so "Sunflower Seeds"
-- never matches the shorter words inside other names.
local QUEST_TREAT_KEYS = {
    {Pattern = "sunflowerseed", Key = "SunflowerSeed", Label = "Sunflower Seeds"},
    {Pattern = "strawberry", Key = "Strawberry", Label = "Strawberries"},
    {Pattern = "blueberry", Key = "Blueberry", Label = "Blueberries"},
    {Pattern = "pineapple", Key = "Pineapple", Label = "Pineapples"},
    {Pattern = "treat", Key = "Treat", Label = "Treats"},
}

local function questTreatInfo(objective)
    local taskData = type(objective) == "table" and objective.Task or {}
    local text = string.lower(tostring(taskData.Type or "") .. " " .. tostring(objective and objective.Description or ""))
        :gsub("[^%w]", "")
    for _, entry in ipairs(QUEST_TREAT_KEYS) do
        if text:find(entry.Pattern, 1, true) then
            return entry.Key, entry.Label
        end
    end
    return "Treat", "Treats"
end

local function questTreatStock(key, stats)
    -- Treats live in stats.Treats on live builds; scan defensively because the
    -- exact table name has varied across game versions.
    if type(stats) ~= "table" then return 0 end
    local direct = type(stats.Treats) == "table" and tonumber(stats.Treats[key]) or nil
    if direct then return math.floor(direct) end
    local found
    local visited = {}
    local function scan(value, depth)
        if found or type(value) ~= "table" or visited[value] or depth > 4 then return end
        visited[value] = true
        for k, child in pairs(value) do
            if k == key and tonumber(child) then found = tonumber(child) return end
            if type(child) == "table" then scan(child, depth + 1) end
        end
    end
    scan(stats, 0)
    return math.floor(found or 0)
end

-- Out-of-stock quest tasks stand down for a while (go farm/do other work)
-- but are REMEMBERED: after the cooldown they retry automatically, so rewards
-- or sprout drops resume the feed as soon as food appears.
local function markQuestTaskCooldown(objective, seconds)
    Runtime.QuestFeedRetryAt = Runtime.QuestFeedRetryAt or {}
    Runtime.QuestFeedRetryAt[tostring(objective and objective.Quest)
        .. "|" .. tostring(objective and objective.Description)] = os.clock()
        + (seconds or 90)
end

function Runtime.FeedQuestTreats(objective)
    if not Config.AutoQuestFeedTasks or Runtime.MeteorPriorityActive then return false end
    -- Cached stats only: this runs off-thread while the farm moves; the server
    -- caps the consumption to the real stock, so a stale read is harmless.
    local stats = MaterialSystem.Stats(false)
    local treatKey, treatLabel = questTreatInfo(objective)
    local treats = questTreatStock(treatKey, stats)
    if treats <= 0 and treatKey == "Treat" then
        -- Generic "feed X treats" quests count EVERY treat-family food. When
        -- plain Treats are out, fall back to whatever food is actually in
        -- stock instead of standing idle waiting for rewards.
        local bestKey, bestLabel, bestStock
        for _, entry in ipairs(QUEST_TREAT_KEYS) do
            if entry.Key ~= "Treat" then
                local count = questTreatStock(entry.Key, stats)
                if count > 0 and (not bestStock or count > bestStock) then
                    bestKey, bestLabel, bestStock = entry.Key, entry.Label, count
                end
            end
        end
        if bestKey then
            treatKey, treatLabel, treats = bestKey, bestLabel, bestStock
        end
    end
    -- Goal + remaining computed UP FRONT so shortages are remembered exactly.
    local taskText = string.lower(tostring(objective and objective.Description or ""))
    local goal = tonumber(string.match(taskText, "feed%s+(%d+)"))
    local ratio = tonumber(type(objective.Progress) == "table" and objective.Progress[1]) or 0
    local remaining
    if goal and goal >= 1 then
        remaining = math.max(1, math.ceil(goal * (1 - math.clamp(ratio, 0, 0.99))))
    end
    Runtime.QuestFeedDeficit = Runtime.QuestFeedDeficit or {}
    local taskKey = tostring(objective.Quest) .. "|" .. tostring(objective.Description)
    if treats <= 0 then
        markQuestTaskCooldown(objective, 90)
        if remaining then
            -- Remember EXACTLY how many are missing: the worker auto-feeds the
            -- moment this much food arrives from farming.
            Runtime.QuestFeedDeficit[taskKey] =
                {TreatKey = treatKey, Label = treatLabel, Missing = remaining}
            setStatus("Quest feed", string.format("Missing %d %s - farming, auto-feed when it arrives",
                remaining, treatLabel))
        else
            setStatus("Quest feed", string.format("Out of %s - doing other work, retry in 90s", treatLabel))
        end
        return false
    end
    local bee = Runtime.FindQuestTargetBee(false)
    if not bee then
        setStatus("Quest feed", "No bee found to feed")
        return false
    end
    -- Feed only what the quest still NEEDS: a 1-seed task never burns the
    -- whole stock, and a partially-fed task tops up just the remainder.
    local batch = treats -- unknown goal: keep the feed-everything behaviour
    if remaining then
        batch = math.min(treats, remaining)
        if batch < remaining then
            Runtime.QuestFeedDeficit[taskKey] =
                {TreatKey = treatKey, Label = treatLabel, Missing = remaining - batch}
        else
            Runtime.QuestFeedDeficit[taskKey] = nil -- fully covered
        end
    end
    Runtime.CurrentQuest = objective.Quest
    setStatus("Quest feed", string.format("Feed %d %s | %s (%d,%d)",
        batch, treatLabel, bee.Type, bee.X, bee.Y))
    local ok, remoteRemaining, success, honeycomb, discoveredBees, eggUses = remoteCall(
        "ConstructHiveCellFromEgg", bee.X, bee.Y, treatKey, batch)
    applyHatchResponse(treatKey, remoteRemaining, success, honeycomb, discoveredBees, eggUses)
    task.wait(0.4)
    task.defer(function() MaterialSystem.Stats(true) end)
    return ok
end

function Runtime.UseQuestRoyalJelly(objective)
    if not Config.AutoQuestJellyTasks or Runtime.MeteorPriorityActive then return false end
    local used = 0
    local maxUses = math.max(1, math.floor(tonumber(Config.QuestJellyBatchMax) or 5))
    while used < maxUses and Runtime.Running and not Runtime.MeteorPriorityActive do
        local stats = MaterialSystem.Stats(false) -- cached; server caps real use
        if math.floor(MaterialSystem.Amount("RoyalJelly", stats)) <= 0 then
            markQuestTaskCooldown(objective, 90)
            setStatus("Quest jelly", "Out of Royal Jelly - doing other work, retry in 90s")
            break
        end
        local bee = Runtime.FindQuestTargetBee(true)
        if not bee then
            setStatus("Quest jelly", "No non-gifted common bee left for jelly")
            break
        end
        Runtime.CurrentQuest = objective.Quest
        setStatus("Quest jelly", string.format("Using Royal Jelly on %s (%d,%d)", bee.Type, bee.X, bee.Y))
        local ok, remaining, success, honeycomb, discoveredBees, eggUses = remoteCall(
            "ConstructHiveCellFromEgg", bee.X, bee.Y, "RoyalJelly", 1)
        applyHatchResponse("RoyalJelly", remaining, success, honeycomb, discoveredBees, eggUses)
        used += 1
        task.wait(0.3)
        if not Runtime.QuestTaskStillIncomplete(objective) then break end
    end
    if used > 0 then task.defer(function() MaterialSystem.Stats(true) end) end
    return used > 0
end

-- Auto treat (independent of quests): HOURLY CYCLE. Every 1h, take 10% of the
-- honey earned in the past hour to buy treats, then feed ALL treats in stock
-- to the lowest-level bee until the whole hive is equal. When the budget runs
-- out, wait for the next hourly cycle.
function Runtime.HiveBeeLevel(entry)
    local cell = entry.Instance
    if not cell then return nil end
    for _, name in ipairs({"Level", "BeeLevel", "CellLevel"}) do
        local value = cell:FindFirstChild(name)
        if value and value:IsA("ValueBase") and tonumber(value.Value) then
            return tonumber(value.Value)
        end
    end
    local bee = cell:FindFirstChild("Bee")
    if bee and bee:IsA("ObjectValue") and bee.Value then
        for _, name in ipairs({"Level", "BeeLevel"}) do
            local value = bee.Value:FindFirstChild(name)
            if value and value:IsA("ValueBase") and tonumber(value.Value) then
                return tonumber(value.Value)
            end
        end
    end
    local data = hiveCellData(entry.X, entry.Y)
    if type(data) == "table" then
        local level = tonumber(data.Level or data.BeeLevel or data.CellLevel)
        if level then return level end
    end
    return nil
end

function Runtime.TreatCycleRollover()
    local now = os.clock()
    local cycleSeconds = math.max(60, (tonumber(Config.TreatCycleHours) or 1) * 3600)
    if Runtime.TreatCycleStart == nil then
        -- First hour has no budget yet: start measuring honey from script start.
        Runtime.TreatCycleStart = now
        Runtime.TreatCycleBase = Runtime.HoneyRateTotal
        return
    end
    if now - Runtime.TreatCycleStart < cycleSeconds then return end
    local earned = math.max(0, Runtime.HoneyRateTotal - (Runtime.TreatCycleBase or 0))
    local percent = math.clamp(tonumber(Config.TreatBudgetPercent) or 10, 0, 100)
    Runtime.TreatCycleBudget = earned * percent / 100
    Runtime.TreatCycleBoughtHoney = 0
    Runtime.TreatCycleBase = Runtime.HoneyRateTotal
    Runtime.TreatCycleStart = now
    setStatus("Treat bee", string.format("New cycle: budget %s honey (%d%% of earned honey)",
        formatNumber(Runtime.TreatCycleBudget), percent))
end

function Runtime.BuyTreatsForCycle()
    local unitCost = math.max(1, tonumber(Config.TreatHoneyCost) or 10)
    local budget = Runtime.TreatCycleBudget or 0
    local boughtHoney = Runtime.TreatCycleBoughtHoney or 0
    local remainingHoney = budget - boughtHoney
    if remainingHoney < unitCost then
        setStatus("Treat bee", string.format("Hourly budget used (%s/%s honey) - wait for next hour",
            formatNumber(boughtHoney), formatNumber(budget)))
        return 0
    end
    local purchaseKey = "Eggs:Treat"
    if (Runtime.PurchaseRetryAt[purchaseKey] or 0) > os.clock() then return 0 end
    Runtime.PurchaseRetryAt[purchaseKey] = os.clock() + 2
    -- Buy in big chunks (package Amount - same mechanism as shop "Treat x100"
    -- items) to spend the budget fast instead of trickling one by one.
    local affordable = math.floor(remainingHoney / unitCost)
    local chunk = math.min(affordable, math.max(1, math.floor(tonumber(Config.TreatBuyChunk) or 100)))
    setStatus("Treat bee", string.format("Buy %d treats | budget %s/%s honey",
        chunk, formatNumber(boughtHoney), formatNumber(budget)))
    local treatsBefore = math.floor(MaterialSystem.Amount("Treat"))
    local ok, result = remoteCall("ItemPackageEvent", "Purchase",
        {Category = "Eggs", Type = "Treat", Amount = chunk})
    task.wait(0.5)
    local treatsAfter = math.floor(MaterialSystem.Amount("Treat", MaterialSystem.Stats(true)))
    local gained = treatsAfter - treatsBefore
    if (ok and result ~= false) or gained > 0 then
        local bought = gained > 0 and gained or chunk
        Runtime.TreatCycleBoughtHoney = boughtHoney + bought * unitCost
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        task.defer(function() MaterialSystem.Stats(true) end)
        return bought
    end
    -- Server rejected the chunk purchase: fall back to single buys (max 10/pass).
    local bought = 0
    for _ = 1, math.min(chunk, 10) do
        local okOne, resultOne = remoteCall("ItemPackageEvent", "Purchase",
            {Category = "Eggs", Type = "Treat", Amount = 1})
        if okOne and resultOne ~= false then
            bought += 1
            Runtime.TreatCycleBoughtHoney = boughtHoney + bought * unitCost
        else
            break
        end
    end
    if bought > 0 then
        Runtime.PurchaseRetryAt[purchaseKey] = nil
        task.defer(function() MaterialSystem.Stats(true) end)
    end
    return bought
end

function Runtime.TreatLowestBee()
    if Runtime.TreatBusy or Runtime.MeteorPriorityActive then return false end
    Runtime.UpdateHoneyRate()
    Runtime.TreatCycleRollover()

    -- Scan the hive: read each bee's level, sort ascending.
    local cells = {}
    for _, entry in ipairs(hiveBeeCells()) do
        if beeTypePresent(entry.Type) and not entry.Locked then
            local level = Runtime.HiveBeeLevel(entry)
            if level then table.insert(cells, {Cell = entry, Level = level}) end
        end
    end
    if #cells < 2 then return false end
    table.sort(cells, function(a, b) return a.Level < b.Level end)
    local lowest = cells[1]
    local highest = cells[#cells]

    local target, targetLevel, focusMode
    if lowest.Level < highest.Level then
        -- A lowest bee exists: feed it (classic mode), clear any stale focus.
        Runtime.TreatFocusKey = nil
        target, targetLevel, focusMode = lowest.Cell, lowest.Level, false
    else
        -- Hive fully equal: focus one random bee and keep it until it LEVELS
        -- UP, then switch - the system never idles. After the focused bee
        -- levels up, the hive is uneven again and later passes equalize it.
        focusMode = true
        local focus
        if Runtime.TreatFocusKey then
            for _, item in ipairs(cells) do
                if hiveCellKey(item.Cell.X, item.Cell.Y) == Runtime.TreatFocusKey then
                    focus = item
                    break
                end
            end
        end
        if focus and focus.Level > (Runtime.TreatFocusLevel or focus.Level) then
            -- Focused bee just leveled: hand control back to equalize mode.
            Runtime.TreatFocusKey = nil
            return false
        end
        if not focus then
            focus = cells[math.random(1, #cells)]
            Runtime.TreatFocusKey = hiveCellKey(focus.Cell.X, focus.Cell.Y)
            Runtime.TreatFocusLevel = focus.Level
        end
        target, targetLevel = focus.Cell, focus.Level
    end

    Runtime.TreatBusy = true
    local handled = false
    -- Feed all treats in stock; only buy more within the hour's budget when empty.
    local treats = math.floor(MaterialSystem.Amount("Treat"))
    if treats <= 0 then treats = Runtime.BuyTreatsForCycle() end
    if treats > 0 then
        -- Feed EVERY treat in stock in a single remote call.
        local batch = treats
        setStatus("Treat bee", focusMode
            and string.format("Focus feed %d treats | %s lv.%d | hive equal, keep until level up",
                batch, target.Type, targetLevel)
            or string.format("Feed %d treats | %s lv.%d | lowest in hive",
                batch, target.Type, targetLevel))
        local ok, remaining, success, honeycomb, discoveredBees, eggUses = remoteCall(
            "ConstructHiveCellFromEgg", target.X, target.Y, "Treat", batch)
        applyHatchResponse("Treat", remaining, success, honeycomb, discoveredBees, eggUses)
        task.wait(0.4)
        task.defer(function() MaterialSystem.Stats(true) end)
        handled = ok
    end
    Runtime.TreatBusy = false
    return handled
end

-- Read a mob's level (Vicious/Werewolf...): a Level value on the model, or
-- "Lv. X" in the name / health-bar BillboardGui.
function Runtime.MobLevel(mob)
    if not mob then return nil end
    for _, name in ipairs({"Level", "MobLevel", "MonsterLevel"}) do
        local value = mob:FindFirstChild(name)
        if value and value:IsA("ValueBase") and tonumber(value.Value) then
            return tonumber(value.Value)
        end
    end
    local levelInName = tostring(mob.Name):match("[Ll][Vv]%.?%s*(%d+)")
    if levelInName then return tonumber(levelInName) end
    for _, descendant in ipairs(mob:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            local level = tostring(descendant.Text):match("[Ll][Vv]%.?%s*(%d+)")
            if level then return tonumber(level) end
        end
    end
    return nil
end

-- Average level of every bee in the hive (reuses the treat level reader).
function Runtime.HiveAverageLevel()
    local total, count = 0, 0
    for _, entry in ipairs(hiveBeeCells()) do
        if beeTypePresent(entry.Type) then
            local level = Runtime.HiveBeeLevel(entry)
            if level then
                total += level
                count += 1
            end
        end
    end
    if count <= 0 then return nil end
    return total / count
end

-- Amulet engine ---------------------------------------------------------------
-- The server offers new amulets via LocalAmuletEvent. The Accept signature was
-- verified from a real remote: ClientAcceptAmulet:FireServer(type, name, statsString)
-- with statsString like "\n+48% Convert Rate\n+1% Critical Chance...". Compare
-- EACH STAT against the equipped amulet of the same type (no made-up weights):
-- replace only on a strict win - no stat worse and at least one
-- stat better; otherwise (mixed or identical) -> keep.
function Runtime.ParseAmuletStats(text)
    local stats = {}
    for value, percent, name in tostring(text or ""):gmatch("%+([%d%.]+)(%%?)%s*([^\n\r]+)") do
        local label = name:gsub("^%s+", ""):gsub("%s+$", "")
        local key = string.lower(label)
        stats[key] = {Value = tonumber(value) or 0, Percent = percent == "%", Name = label}
    end
    return stats
end

-- Compare stat by stat: returns (betterCount, worseCount, notes). A new stat the
-- old one lacks = better; an old stat missing from the new one = worse.
function Runtime.CompareAmuletStats(newText, oldText)
    local newStats = Runtime.ParseAmuletStats(newText)
    local oldStats = Runtime.ParseAmuletStats(oldText)
    local better, worse = 0, 0
    local notes = {}
    for key, stat in pairs(newStats) do
        local oldValue = oldStats[key] and oldStats[key].Value or 0
        if stat.Value > oldValue then
            better += 1
            table.insert(notes, string.format("+%s%s %s (old %s)", tostring(stat.Value),
                stat.Percent and "%" or "", stat.Name, tostring(oldValue)))
        elseif stat.Value < oldValue then
            worse += 1
            table.insert(notes, string.format("-%s%s %s (old %s)", tostring(stat.Value),
                stat.Percent and "%" or "", stat.Name, tostring(oldValue)))
        end
    end
    for key in pairs(oldStats) do
        if not newStats[key] then worse += 1 end
    end
    return better, worse, notes
end

-- Find the equipped same-type amulet stats inside PlayerStats. The layout is
-- unverified, so scan defensively: Amulets[type] = {Name, Stats},
-- entries with Type/Name containing "Amulet", or an amulet key holding raw stats text.
function Runtime.EquippedAmuletStatsText(amuletType)
    local stats = MaterialSystem.Stats(false)
    local wanted = string.lower(tostring(amuletType or "")):gsub("[^%w]", "")
    local visited = {}
    local function scanEntry(entry)
        if type(entry) ~= "table" then return nil end
        local text = entry.Stats or entry.Text or entry.Description or entry.StatsText
        if type(text) == "string" and text:find("+", 1, true) then
            local name = tostring(entry.Name or entry.AmuletName or "")
            local entryType = string.lower(tostring(entry.Type or entry.AmuletType or "")):gsub("[^%w]", "")
            if wanted == "" or entryType == wanted or name:lower():find(wanted, 1, true) then
                return text
            end
        end
        return nil
    end
    local function scan(value)
        if type(value) ~= "table" or visited[value] then return nil end
        visited[value] = true
        for key, child in pairs(value) do
            local normalizedKey = string.lower(tostring(key)):gsub("[^%w]", "")
            -- key matching the amulet type (e.g. Amulets.Ant) or a key containing "amulet"
            if type(child) == "table" then
                if wanted ~= "" and (normalizedKey == wanted or tostring(key):lower():find(wanted, 1, true)) then
                    local direct = scanEntry(child)
                    if direct then return direct end
                end
                if normalizedKey:find("amulet", 1, true) then
                    local direct = scanEntry(child)
                    if direct then return direct end
                end
                local nested = scan(child)
                if nested then return nested end
            elseif type(child) == "string" and normalizedKey:find("amulet", 1, true)
                and child:find("+", 1, true) then
                return child
            end
        end
        return nil
    end
    return scan(stats)
end

function Runtime.HandleAmuletOffer(...)
    if not Config.AutoCompareAmulets then return end
    local args = table.pack(...)

    -- Parse the offer: 3 strings (type, name, stats) or a table payload.
    local amuletType, amuletName, statsText
    local strings = {}
    for i = 1, args.n do
        if type(args[i]) == "string" then table.insert(strings, args[i]) end
    end
    for _, text in ipairs(strings) do
        if text:find("+", 1, true) and not statsText then statsText = text end
    end
    for _, text in ipairs(strings) do
        if text ~= statsText then
            if string.lower(text):find("amulet", 1, true) and not amuletName then
                amuletName = text
            elseif not amuletType then
                amuletType = text
            end
        end
    end
    if not statsText then
        for i = 1, args.n do
            if type(args[i]) == "table" then
                local payload = args[i]
                amuletType = amuletType or payload.Type or payload.AmuletType or payload.Category
                amuletName = amuletName or payload.Name or payload.AmuletName
                statsText = statsText or payload.Stats or payload.Text or payload.Description
            end
        end
    end
    if not statsText then return end

    local currentText = Runtime.EquippedAmuletStatsText(amuletType)
    local accept = true
    local detail = "no amulet of this type yet"
    if currentText then
        local better, worse, notes = Runtime.CompareAmuletStats(statsText, currentText)
        accept = worse <= 0 and better > 0
        detail = string.format("%d stat(s) better, %d worse%s", better, worse,
            #notes > 0 and (" | " .. table.concat(notes, ", ")) or "")
    end
    setStatus("Amulet", string.format("%s %s | %s",
        accept and "REPLACE" or "KEEP", tostring(amuletName or "?"), detail))
    Runtime.AmuletRemoteAt = os.clock()
    task.wait(0.3)
    remoteCall(accept and "ClientAcceptAmulet" or "ClientRejectAmulet",
        amuletType, amuletName, statsText)
    task.defer(function() MaterialSystem.Stats(true) end)
end

local amuletOfferRemote = Events:FindFirstChild("LocalAmuletEvent")
if amuletOfferRemote and amuletOfferRemote:IsA("RemoteEvent") then
    connect(amuletOfferRemote.OnClientEvent, function(...)
        local ok, err = xpcall(Runtime.HandleAmuletOffer, debug.traceback, ...)
        if not ok then reportError("Amulet", err) end
    end)
    warn("[BSS Kaitun] Auto amulet armed (remote listener + GUI fallback)")
else
    warn("[BSS Kaitun] LocalAmuletEvent not found - GUI fallback only")
end

-- GUI fallback: some servers drive the amulet offer purely through the GUI, so
-- also poll PlayerGui for the comparison menu. Reads the game's own green/red
-- stat coloring (green = better, red = worse - zero guesswork) and clicks the
-- game's own Accept/Decline button, which fires the correct remotes itself.
local AMULET_ACCEPT_WORDS = {"accept", "take", "equip", "replace", "confirm"}
local AMULET_DECLINE_WORDS = {"decline", "keep", "cancel", "discard", "current"}

function Runtime.IsAmuletGui(object)
    local cursor, depth = object, 0
    while cursor and cursor ~= Player and depth < 12 do
        if string.lower(cursor.Name):find("amulet", 1, true) then return true end
        cursor = cursor.Parent
        depth += 1
    end
    return false
end

function Runtime.HandleAmuletGui()
    if not Config.AutoCompareAmulets then return false end
    -- Yield while the remote path just answered the same offer.
    if os.clock() - (Runtime.AmuletRemoteAt or 0) < 3 then return false end
    local now = os.clock()
    if now - (Runtime.AmuletGuiAt or 0) < 1.5 then return false end
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return false end

    local statLabels, acceptButton, declineButton, titleText = {}, nil, nil, nil
    for _, object in ipairs(playerGui:GetDescendants()) do
        if Runtime.IsAmuletGui(object) then
            if object:IsA("TextLabel") and MaterialSystem.GuiVisible(object) then
                local text = tostring(object.Text)
                if text:find("+", 1, true) and text:find("%d", 1, true) then
                    table.insert(statLabels, object)
                elseif not titleText and #text > 3 then
                    titleText = text
                end
            elseif object:IsA("TextButton") and MaterialSystem.GuiVisible(object) then
                local label = string.lower(tostring(object.Text)):gsub("[^%w]", "")
                if not acceptButton then
                    for _, word in ipairs(AMULET_ACCEPT_WORDS) do
                        if label:find(word, 1, true) then acceptButton = object break end
                    end
                end
                if not declineButton then
                    for _, word in ipairs(AMULET_DECLINE_WORDS) do
                        if label:find(word, 1, true) then declineButton = object break end
                    end
                end
            end
        end
    end

    if not acceptButton and not declineButton then
        Runtime.AmuletGuiAttempts = 0
        return false
    end

    -- Replace only when nothing is red and at least one stat is green.
    local green, red = 0, 0
    for _, label in ipairs(statLabels) do
        local color = label.TextColor3
        if color then
            if color.G > color.R + 0.2 and color.G > 0.45 then green += 1
            elseif color.R > color.G + 0.2 and color.R > 0.45 then red += 1 end
        end
    end
    local accept
    if red > 0 then
        accept = false
    elseif green > 0 then
        accept = true
    else
        -- No colored stats: accept only when no amulet of that kind is on.
        accept = Runtime.EquippedAmuletStatsText(nil) == nil
    end

    Runtime.AmuletGuiAt = now
    Runtime.AmuletGuiAttempts = (Runtime.AmuletGuiAttempts or 0) + 1
    if Runtime.AmuletGuiAttempts > 6 then return false end
    local button = accept and (acceptButton or declineButton) or (declineButton or acceptButton)
    if not button then return false end
    warn(string.format("[BSS Kaitun] Amulet GUI: %s | green=%d red=%d -> %s",
        tostring(titleText or "?"), green, red, accept and "REPLACE" or "KEEP"))
    setStatus("Amulet", string.format("%s %s | %d green %d red (gui)",
        accept and "REPLACE" or "KEEP", tostring(titleText or "?"), green, red))
    MaterialSystem.ActivateButton(button)
    return true
end

task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and Config.AutoCompareAmulets then
            local ok, err = xpcall(Runtime.HandleAmuletGui, debug.traceback)
            if not ok then reportError("AmuletGui", err) end
        end
        task.wait(1)
    end
end)

local function questWork(seconds)
    if not Config.AutoQuest then return false end
    if maintainBearQuests() then return true end
    local objectives = incompleteQuestObjectives(false) -- shared TTL snapshot
    -- Do not surface the first objective when it is locked; the UI only shows quests
    -- the scheduler is actually working on.
    Runtime.CurrentQuest = ""
    Runtime.QuestCurrentField = ""
    -- Drop Black Bear objectives once the Diamond Egg rule says stop (e.g. an
    -- already-accepted later quest on an account that passed the line before).
    if Config.BlackBearStopAfterQuest
        and (Runtime.BlackBearStopped or Runtime.BlackBearStopState() == "past") then
        local filtered = {}
        for _, objective in ipairs(objectives) do
            if objective.NPC ~= "Black Bear" then table.insert(filtered, objective) end
        end
        objectives = filtered
    end
    -- Feed treat / use Royal Jelly moved to a BACKGROUND worker (remote-only,
    -- no movement needed): questWork no longer blocks on inventory checks, so
    -- the character keeps farm-moving while feeds happen off-thread.
    local plan = chooseQuestField(objectives)
    local planRank = plan and plan.NPCRank or math.huge
    -- Mob objectives also respect NPC order. E.g. when Science has a farmable
    -- objective, out-of-order jobs must not cut in line.
    for rank, npcName in ipairs(Config.QuestFarmPriority or Config.QuestNPCs or {}) do
        if rank > planRank then break end
        for _, objective in ipairs(objectives) do
            if objective.NPC == npcName and objective.Task
                and tostring(objective.Task.Type) == "Defeat Monsters" then
                local _, attempted = Runtime.FarmQuestMob(objective, Config.QuestMobFightTimeout)
                if attempted then return true end
            end
        end
    end
    -- Blocked on a kill-mob cooldown (typical Polar Bear flow): camp Pine Tree
    -- Forest and farm while waiting; FarmQuestMob grabs the mob the moment its
    -- spawner is ready, then maintainBearQuests turns the quest in at the bear.
    -- Only reached when there is no other quest plan left to farm.
    if Config.AutoQuestMobs and fieldUnlocked("Pine Tree Forest") then
        for _, objective in ipairs(objectives) do
            if objective.Task and tostring(objective.Task.Type) == "Defeat Monsters" then
                local campField = findField("Pine Tree Forest")
                if campField then
                    Runtime.CurrentQuest = objective.Quest
                    Runtime.QuestFarming = true
                    local ok = farmStep(seconds or Config.QuestFarmSeconds, campField,
                        "Waiting for mob", "Pine Tree Forest | mob cooldown")
                    Runtime.QuestFarming = false
                    return ok
                end
            end
        end
    end
    if not plan then return false end
    local field = findField(plan.Name)
    if not field or not fieldUnlocked(plan.Name) then return false end
    local first = plan.PrimaryObjective or plan.Objectives[1]
    Runtime.CurrentQuest = first and first.Quest or Runtime.CurrentQuest
    Runtime.QuestCurrentField = plan.Name
    Runtime.QuestFarming = true
    local detail = string.format("%s | %s | %d objective", Runtime.CurrentQuest, plan.Name, #plan.Objectives)
    local ok = farmStep(seconds or Config.QuestFarmSeconds, field, "Farm quest", detail)
    Runtime.QuestFarming = false
    return ok
end

-- Leaves and Sparkles are markers attached to real flower tiles. They are
-- handled as short scheduler jobs so they never fight the quest/farm mover.
local function nearestFlowerEffect()
    if os.clock() - Runtime.LastSpecialEffectScan < Config.SpecialEffectScanInterval then return nil end
    Runtime.LastSpecialEffectScan = os.clock()
    local flowers = workspace:FindFirstChild("Flowers")
    local _, _, root = getCharacter(1)
    if not flowers or not root then return nil end
    -- Leaves are opportunistic field work: never leave the field the player is
    -- currently standing in just because a LeafBurst spawned elsewhere.
    local playerField = flowerFieldAtPosition(root.Position, 0)
    local best, bestDistance, bestKind, bestField
    for _, flower in ipairs(flowers:GetChildren()) do
        local kind
        if Config.AutoFarmSparkles and flower:FindFirstChild("Sparkles") then kind = "Sparkles"
        elseif Config.AutoFarmLeaves and flower:FindFirstChild("LeafBurst") then kind = "Leaves" end
        if kind and (Runtime.FlowerEffectCooldown[flower] or 0) <= os.clock() then
            local position = objectPosition(flower)
            local field = position and flowerFieldAtPosition(position, kind == "Leaves" and 0 or 8)
            local distance = position and (root.Position - position).Magnitude
            local allowedField = kind ~= "Leaves" or (playerField and field == playerField)
            if allowedField and field and fieldUnlocked(field.Name)
                and distance and distance <= Config.SpecialEffectMaxDistance
                and (not bestDistance or distance < bestDistance) then
                best, bestDistance, bestKind, bestField = flower, distance, kind, field
            end
        end
    end
    return best, bestKind, bestField
end

local function farmFlowerEffect()
    local flower, kind, field = nearestFlowerEffect()
    if not flower then return false end
    local position = objectPosition(flower)
    if not position then return false end
    if kind == "Leaves" then
        local _, _, root = getCharacter(1)
        local playerField = root and flowerFieldAtPosition(root.Position, 0)
        if not playerField or playerField ~= field or not fieldContainsPosition(field, position, 0) then
            return false
        end
    end
    Runtime.FlowerEffectCooldown[flower] = os.clock() + 8
    Runtime.CurrentField = field.Name
    Runtime.Digging = true
    setStatus("Farm " .. kind, field.Name)
    local moved = tweenTo(CFrame.new(position + Vector3.new(0, 2.5, 0)), Config.TokenTweenSpeed, "FlowerEffect")
    if moved then
        task.wait(0.25)
        remoteCall("ToolCollect")
        task.wait(0.45)
        remoteCall("ToolCollect")
        if kind == "Sparkles" and Config.AutoTokens then sweepTokens(1.2, "SparklesToken") end
    end
    Runtime.Digging = false
    return moved
end

local function nearbyLiveMobs(field)
    -- ALL live mobs near the character (single pass), not just the first one:
    -- retreat planning must respect every mob, or it runs straight into one.
    local monsters = workspace:FindFirstChild("Monsters")
    local _, _, root = getCharacter(1)
    local list = {}
    if not monsters or not root then return list end
    for _, object in ipairs(monsters:GetChildren()) do
        local humanoid = object:FindFirstChildOfClass("Humanoid")
        local position = objectPosition(object)
        if humanoid and humanoid.Health > 0 and position
            and (root.Position - position).Magnitude <= Config.MobScanRadius
            and (not field or fieldContainsPosition(field, position, 15)) then
            table.insert(list, {Instance = object, Position = position})
        end
    end
    return list
end

local function nearbyLiveMob(field)
    local _, _, root = getCharacter(1)
    if not root then return nil end
    local nearest, nearestDistance
    for _, mob in ipairs(nearbyLiveMobs(field)) do
        local distance = (root.Position - mob.Position).Magnitude
        if not nearestDistance or distance < nearestDistance then
            nearest, nearestDistance = mob.Instance, distance
        end
    end
    return nearest
end

Runtime.GetQuestObjectives = function(refresh)
    return incompleteQuestObjectives(refresh == true)
end
Runtime.GoToNPC = interactQuestNPC
Runtime.IsFieldUnlocked = fieldUnlocked
Runtime.ScanMob = function()
    local field = Runtime.CurrentField ~= "" and findField(Runtime.CurrentField) or standingField()
    return nearbyLiveMob(field)
end

-- When hit, retreat toward the field center if it is safe from EVERY mob.
-- Otherwise pick the candidate point with the largest minimum distance to all
-- mobs; a point inside any mob's danger zone is rejected outright. Returns nil
-- when nothing is safe: the caller then HOLDS POSITION instead of running
-- blindly through mobs (running through them is what caused deaths).
Runtime.FindMobEscapePosition = function(field, rootPosition, mobs)
    if not field or not rootPosition then return nil end
    local center = objectPosition(field)
    if field:IsA("BasePart") then
        center = (field.CFrame * CFrame.new(0, field.Size.Y / 2 + 3, 0)).Position
    end
    if not center then return nil end

    local safeDistance = math.max(8, tonumber(Config.MobThreatRadius) or 16) + 2
    local function minMobDistance(position)
        local best
        for _, mob in ipairs(mobs or {}) do
            local distance = (position - mob.Position).Magnitude
            if not best or distance < best then best = distance end
        end
        return best or math.huge
    end

    if (rootPosition - center).Magnitude > 4 and minMobDistance(center) >= safeDistance then
        return center
    end

    local best, bestScore
    for _ = 1, 10 do
        local candidate = fieldPoint(field)
        if candidate then
            local separation = minMobDistance(candidate)
            if separation >= safeDistance then
                local travel = (candidate - rootPosition).Magnitude
                local score = separation + math.min(travel, 20) * 0.3
                if not bestScore or score > bestScore then
                    best, bestScore = candidate, score
                end
            end
        end
    end
    return best
end

task.spawn(function()
    while Runtime.Running do
        local threatening = false
        if Config.AvoidMob and Runtime.Digging and not Runtime.MeteorPriorityActive
            and not Runtime.MaterialCombat and Runtime.CurrentField ~= "" then
            local field = findField(Runtime.CurrentField)
            local _, humanoid, root = getCharacter(1)
            local damaged = false
            if humanoid then
                if Runtime.MobLastHumanoid ~= humanoid then
                    Runtime.MobLastHumanoid = humanoid
                    Runtime.MobLastHealth = humanoid.Health
                else
                    local previousHealth = tonumber(Runtime.MobLastHealth) or humanoid.Health
                    damaged = previousHealth - humanoid.Health
                        >= math.max(0.1, tonumber(Config.AvoidMobDamageThreshold) or 0.5)
                    Runtime.MobLastHealth = humanoid.Health
                end
            end
            local mobs = nearbyLiveMobs(field)
            -- Jump trigger = ANY mob inside the scan radius (mobs only connect
            -- while the character is grounded, so hopping starts early).
            -- Threat (retreat + farm pause) still requires the mob inside the
            -- small danger radius, so mob-heavy fields keep farming while hopping.
            local threatRadius = math.max(8, tonumber(Config.MobThreatRadius) or 16)
            local mobNear, nearestDistance = false, nil
            if root then
                for _, mob in ipairs(mobs) do
                    local distance = (root.Position - mob.Position).Magnitude
                    if not nearestDistance or distance < nearestDistance then
                        nearestDistance = distance
                    end
                end
                mobNear = nearestDistance ~= nil
                    and nearestDistance <= (tonumber(Config.MobScanRadius) or 55)
            end
            threatening = nearestDistance ~= nil and nearestDistance <= threatRadius
                and humanoid ~= nil and root ~= nil and not root.Anchored
            if threatening then
                -- Renew the hold while danger persists; farmStep pauses meanwhile.
                local now = os.clock()
                Runtime.MobThreatUntil = now + math.max(1, tonumber(Config.MobThreatHoldSeconds) or 4)
                Runtime.AvoidingMob = true
                -- Kill any in-flight glide/farm move: the retreat owns the character.
                if damaged then Runtime.Glide = nil end
                local relocateCooldown = math.max(0.5, tonumber(Config.AvoidMobRelocateCooldown) or 2.5)
                if damaged and now - (Runtime.MobLastDamageAt or -math.huge) >= relocateCooldown then
                    Runtime.MobLastDamageAt = now
                    Runtime.TweenGeneration += 1
                    releaseTweenRoot()
                    local escape = Runtime.FindMobEscapePosition(field, root.Position, mobs)
                    if escape then
                        Runtime.MobRelocating = true
                        Runtime.MobRelocateTarget = escape
                        Runtime.MobRelocateUntil = now
                            + math.max(1.5, tonumber(Config.AvoidMobRelocateTimeout) or 4)
                        Runtime.MobHoldPosition = nil
                        humanoid:MoveTo(escape)
                        setStatus("Avoid mob", "Hit - retreat to safe point in " .. field.Name)
                    else
                        -- Nowhere safe: STAND STILL instead of running through mobs.
                        Runtime.MobRelocating = false
                        Runtime.MobRelocateTarget = nil
                        Runtime.MobHoldPosition = root.Position
                        humanoid:Move(Vector3.zero, false)
                        humanoid:MoveTo(root.Position)
                        setStatus("Avoid mob", "Hit - no safe point, holding still in " .. field.Name)
                    end
                end

                if Runtime.MobRelocating and typeof(Runtime.MobRelocateTarget) == "Vector3" then
                    if (root.Position - Runtime.MobRelocateTarget).Magnitude
                        <= math.max(2, tonumber(Config.AvoidMobArrivalDistance) or 5)
                        or now >= Runtime.MobRelocateUntil then
                        Runtime.MobRelocating = false
                        Runtime.MobRelocateTarget = nil
                        Runtime.MobRelocateUntil = 0
                    else
                        -- Walk to the safe point; airborne hits miss (game mechanic).
                        humanoid:MoveTo(Runtime.MobRelocateTarget)
                    end
                end
                if not Runtime.MobRelocating then
                    -- Hold position while threatened.
                    Runtime.MobHoldPosition = Runtime.MobHoldPosition or root.Position
                    humanoid:Move(Vector3.zero, false)
                    humanoid:MoveTo(Runtime.MobHoldPosition)
                end
            elseif os.clock() >= (Runtime.MobThreatUntil or 0) then
                Runtime.AvoidingMob = false
                Runtime.MobHoldPosition = nil
                Runtime.MobRelocating = false
                Runtime.MobRelocateTarget = nil
                Runtime.MobRelocateUntil = 0
            end
            -- Jump-dodge: mobs only connect while the character is grounded, so
            -- keep hopping whenever ANY mob is around (threat or not).
            if mobNear and humanoid and root and not root.Anchored
                and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
            end
        else
            Runtime.AvoidingMob = false
            Runtime.MobHoldPosition = nil
            Runtime.MobRelocating = false
            Runtime.MobRelocateTarget = nil
            Runtime.MobRelocateUntil = 0
            Runtime.MobLastHumanoid = nil
            Runtime.MobLastHealth = nil
        end
        -- CPU saver: tick at jump cadence while any mob is around, 0.25s otherwise.
        task.wait((threatening or mobNear)
            and math.max(0.08, tonumber(Config.MobJumpInterval) or 0.12) or 0.25)
    end
end)

local function hivePhase(hive)
    local phase = hive and hive:FindFirstChild("Phase")
    return phase and phase:IsA("ValueBase") and tostring(phase.Value) or ""
end

local function convertPollen()
    if not Config.AutoConvert then return false end
    if Runtime.MeteorPriorityActive then return false end
    local hive, platform = findOwnedHive()
    if not hive then return false end
    local target = platform and (platform:FindFirstChild("Platform") or platform) or hive
    local position = objectPosition(target)
    if not position then return false end

    setStatus("Convert honey", "Tween to hive")
    if not tweenTo(CFrame.new(position + Vector3.new(0, 3, 0)), Config.TweenSpeed, "Convert") then return false end
    task.wait(0.25)
    if Runtime.MeteorPriorityActive then return false end
    if hivePhase(hive) == "Idle" or hivePhase(hive) == "" then
        remoteCall("PlayerHiveCommand", "ToggleHoneyMaking")
    end

    local deadline = os.clock() + Config.ConvertTimeout
    local lastPollen = math.huge
    local lastProgress = os.clock()
    while Runtime.Running and Config.Enabled and not Runtime.MeteorPriorityActive and os.clock() < deadline do
        local ratio, pollen = pollenRatio()
        setStatus("Convert honey", formatNumber(pollen) .. " pollen left")
        if ratio <= Config.ConvertFinishPercent or pollen <= 0 then break end
        if pollen < lastPollen then
            lastPollen = pollen
            lastProgress = os.clock()
        elseif os.clock() - lastProgress > 8 and hivePhase(hive) == "Idle" then
            -- Retry only when the server confirms the hive is Idle, avoiding mistaken toggles
            -- that could stall a slow-but-running conversion.
            remoteCall("PlayerHiveCommand", "ToggleHoneyMaking")
            lastProgress = os.clock()
        end
        task.wait(0.5)
    end

    if hivePhase(hive) ~= "" and hivePhase(hive) ~= "Idle" then
        remoteCall("PlayerHiveCommand", "ToggleHoneyMaking")
    end
    return select(1, pollenRatio()) <= Config.ConvertFinishPercent
end

-- Material planner -----------------------------------------------------------
function MaterialSystem.OrderedKeys(map)
    local result, used = {}, {}
    for _, material in ipairs(MaterialSystem.Priority) do
        if map[material] ~= nil then
            table.insert(result, material)
            used[material] = true
        end
    end
    local remainder = {}
    for material in pairs(map) do
        if not used[material] then table.insert(remainder, material) end
    end
    table.sort(remainder)
    for _, material in ipairs(remainder) do table.insert(result, material) end
    return result
end

function MaterialSystem.Requirements(entry, stats)
    local requirements = deepCopy(entry and entry.Materials or {})
    local cached = entry and Runtime.MaterialRequirements[entry.Type]
    if type(cached) == "table" then
        merge(requirements, cached)
        return requirements
    end
    if okPackages and ItemPackages and entry and type(ItemPackages.GetCost) == "function" then
        local ok, cost = pcall(ItemPackages.GetCost, getPackage(entry), stats or MaterialSystem.Stats(false))
        if ok and type(cost) == "table" then
            local visited = {}
            local function scanCost(requirement)
                if type(requirement) ~= "table" or visited[requirement] then return end
                visited[requirement] = true
                local rawName = requirement.Type or requirement.Name or requirement.Item
                local category = string.lower(tostring(requirement.Category or rawName or ""))
                local amount = tonumber(requirement.Amount or requirement.Value or requirement.Cost
                    or requirement.Price or requirement.Quantity)
                if rawName and amount and amount > 0 and category ~= "honey" then
                    local material = MaterialSystem.Canonical(rawName)
                    requirements[material] = math.max(tonumber(requirements[material]) or 0, amount)
                end
                for _, child in pairs(requirement) do
                    if type(child) == "table" then scanCost(child) end
                end
            end
            scanCost(cost)
            Runtime.MaterialRequirements[entry.Type] = deepCopy(requirements)
        end
    end
    return requirements
end

function MaterialSystem.Deficits(entry, stats)
    local requirements = MaterialSystem.Requirements(entry, stats)
    local deficits = {}
    for material, required in pairs(requirements) do
        local canonical = MaterialSystem.Canonical(material)
        required = tonumber(required) or 0
        local owned = MaterialSystem.Amount(canonical, stats)
        if required > owned then
            deficits[canonical] = {Owned = owned, Required = required, Missing = required - owned}
        end
    end
    return deficits, requirements
end

function MaterialSystem.Resolve(material, required, reservations, stats, visiting)
    material = MaterialSystem.Canonical(material)
    required = math.max(0, tonumber(required) or 0)
    local owned = MaterialSystem.Amount(material, stats)
    if owned >= required then return nil end
    visiting = visiting or {}
    if visiting[material] then
        return {Kind = "farm", Material = material, Required = required, Owned = owned}
    end

    local recipe = MaterialSystem.Recipe(material)
    if not recipe then
        return {Kind = "farm", Material = material, Required = required, Owned = owned}
    end

    visiting[material] = true
    local crafts = math.ceil((required - owned) / math.max(1, tonumber(recipe.Yield) or 1))
    for _, ingredient in ipairs(MaterialSystem.OrderedKeys(recipe.Ingredients)) do
        local ingredientNeed = (tonumber(recipe.Ingredients[ingredient]) or 0) * crafts
            + (tonumber(reservations[ingredient]) or 0)
        if MaterialSystem.Amount(ingredient, stats) < ingredientNeed then
            local action = MaterialSystem.Resolve(ingredient, ingredientNeed, reservations, stats, visiting)
            visiting[material] = nil
            if action then return action end
        end
    end
    visiting[material] = nil
    return {
        Kind = "craft", Material = material, Recipe = recipe.Recipe,
        Count = crafts, Required = required, Owned = owned,
    }
end

function MaterialSystem.NextAction(entry, stats, farmOnly)
    local deficits, requirements = MaterialSystem.Deficits(entry, stats)
    for _, material in ipairs(MaterialSystem.OrderedKeys(deficits)) do
        local action = MaterialSystem.Resolve(material, deficits[material].Required, requirements, stats, {})
        if action and (not farmOnly or action.Kind == "farm") then return action, deficits, requirements end
    end
    return nil, deficits, requirements
end

function MaterialSystem.Clock()
    if type(MaterialSystem.OsTime) == "function" then
        local ok, value = pcall(MaterialSystem.OsTime)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return os.time()
end

function MaterialSystem.BlenderStatus(force)
    local stats = MaterialSystem.Stats(force == true)
    local blender = type(stats) == "table" and stats.BlenderState or nil
    if type(blender) ~= "table" or not blender.Recipe or (tonumber(blender.Count) or 0) <= 0 then
        Runtime.BlenderRecipe = ""
        Runtime.BlenderCount = 0
        return "idle", nil, 0
    end

    local count = math.max(1, tonumber(blender.Count) or 1)
    Runtime.BlenderRecipe = tostring(blender.Recipe)
    Runtime.BlenderCount = count
    if Runtime.BlenderStartedAt == -math.huge then Runtime.BlenderStartedAt = os.clock() end

    local elapsed
    if tonumber(stats.PlaytimeAtLoad) and tonumber(stats.LoadTime) and tonumber(blender.StartTime) then
        elapsed = tonumber(stats.PlaytimeAtLoad) + (MaterialSystem.Clock() - tonumber(stats.LoadTime))
            - tonumber(blender.StartTime)
    else
        elapsed = os.clock() - Runtime.BlenderStartedAt
    end
    local remaining = math.max(0, count * 300 - math.max(0, elapsed or 0))
    return remaining <= 0 and "done" or "crafting", blender, remaining
end

function MaterialSystem.MoveToBlender()
    local blenderObject = workspace:FindFirstChild("Blender", true)
    local position = objectPosition(blenderObject) or Config.BlenderMovePosition
    if typeof(position) ~= "Vector3" then return false end
    setStatus("Blender", "Going to the blender")
    return tweenTo(CFrame.new(position + Vector3.new(0, 3, 0)), Config.TweenSpeed, "Blender")
end

function MaterialSystem.StartBlender(action)
    if not Config.AutoBlender or not action or action.Kind ~= "craft" then return false end
    if Runtime.MeteorPriorityActive then return false end
    local state = MaterialSystem.BlenderStatus(true)
    if state ~= "idle" then return false end
    MaterialSystem.MoveToBlender()
    task.wait(0.35)
    if Runtime.MeteorPriorityActive then return false end
    setStatus("Blender", string.format("Craft x%d %s", action.Count, MaterialSystem.Display(action.Material)))
    local ok, result = remoteCall("BlenderCommand", "PlaceOrder", {
        Recipe = action.Recipe,
        Count = math.max(1, math.floor(action.Count)),
    })
    if ok and result ~= false then
        Runtime.BlenderStartedAt = os.clock()
        Runtime.BlenderRecipe = tostring(action.Recipe)
        Runtime.BlenderCount = action.Count
        Runtime.LastMaterialStats = -math.huge
        return true
    end
    setStatus("Blender error", tostring(result or "PlaceOrder rejected"))
    return false
end

function MaterialSystem.ClaimBlender()
    if Runtime.MeteorPriorityActive then return false end
    local state, blender = MaterialSystem.BlenderStatus(true)
    if state ~= "done" then return false end
    MaterialSystem.MoveToBlender()
    task.wait(0.35)
    if Runtime.MeteorPriorityActive then return false end
    setStatus("Blender", "Claim " .. tostring(blender and blender.Recipe or Runtime.BlenderRecipe))
    local ok, result = remoteCall("BlenderCommand", "StopOrder")
    if ok and result ~= false then
        Runtime.BlenderStartedAt = -math.huge
        Runtime.BlenderRecipe = ""
        Runtime.BlenderCount = 0
        Runtime.LastMaterialStats = -math.huge
        MaterialSystem.Stats(true)
        return true
    end
    return false
end

function MaterialSystem.Field(material)
    local candidates = {
        SunflowerSeed = {"Sunflower Field"},
        Strawberry = {"Strawberry Field", "Mushroom Field"},
        Blueberry = {"Bamboo Field", "Blue Flower Field"},
        -- Pineapple tokens exist ONLY in Pineapple Patch; farming elsewhere can
        -- never produce them.
        Pineapple = {"Pineapple Patch"},
        Honeysuckle = {"Sunflower Field", "Blue Flower Field", "Rose Field"},
        Coconut = {"Coconut Field"},
        MagicBean = {"Clover Field", "Sunflower Field"},
        RoyalJelly = {"Pineapple Patch", "Clover Field", "Sunflower Field"},
        Neonberry = {"Cactus Field", "Pineapple Patch", "Clover Field"},
        Bitterberry = {"Cactus Field", "Pineapple Patch", "Clover Field"},
        ComfortingVial = {"Dandelion Field", "Bamboo Field", "Pine Tree Forest"},
        RefreshingVial = {"Blue Flower Field", "Strawberry Field", "Coconut Field"},
        DiamondEgg = {"Pine Tree Forest", "Bamboo Field", "Sunflower Field"},
        SpiritPetal = {"Pine Tree Forest", "Bamboo Field", "Sunflower Field"},
        Stinger = {"Pepper Patch", "Mountain Top Field", "Rose Field", "Cactus Field", "Spider Field", "Clover Field"},
    }
    for _, name in ipairs(candidates[material] or {}) do
        if fieldUnlocked(name) then return findField(name) end
    end
    -- The material HAS known sources but every one of them is still locked at
    -- this hive size: report nil instead of farming a field that can never
    -- drop it (the caller defers the gear instead of blocking hive growth).
    if candidates[material] then return nil end
    local fallback = selectedFieldName()
    return fieldUnlocked(fallback) and findField(fallback) or findField("Sunflower Field")
end

-- TRUE when at least one missing material of a gear entry can be progressed
-- right now: via a special source (mob/sprout/firefly/NPC), a blender recipe,
-- or an unlocked farm field. If FALSE the milestone defers the gear instead of
-- stalling hive growth (eggs) on an impossible material.
function MaterialSystem.HasGatherableMaterial(deficits)
    local special = {
        Stinger = true, MoonCharm = true, MagicBean = true, RoyalJelly = true,
        Neonberry = true, Bitterberry = true, DiamondEgg = true, SpiritPetal = true,
        ComfortingVial = true, RefreshingVial = true,
    }
    for material in pairs(deficits or {}) do
        local canonical = MaterialSystem.Canonical(material) or material
        if special[canonical] or special[material] then return true end
        if MaterialSystem.Recipes[canonical] then return true end -- blender-craftable
        if MaterialSystem.Field(material) ~= nil then return true end
    end
    return false
end

function MaterialSystem.FindSprout()
    local particles = workspace:FindFirstChild("Particles")
    if not particles then return nil end
    -- The game puts real Sprout markers in Particles.Folder2. Only fall back to
    -- descendants on older game builds to avoid confusing visuals also named Sprout.
    local folder = particles:FindFirstChild("Folder2")
    local objects = folder and folder:GetChildren() or particles:GetDescendants()
    local _, _, root = getCharacter(1)
    local best, bestField, bestDistance
    for _, object in ipairs(objects) do
        if object.Name == "Sprout" then
            local position = objectPosition(object)
            local field = position and flowerFieldAtPosition(position, 12) or nil
            if position and field and fieldUnlocked(field.Name) then
                local distance = root and (root.Position - position).Magnitude or 0
                if not bestDistance or distance < bestDistance then
                    best, bestField, bestDistance = object, field, distance
                end
            end
        end
    end
    return best, bestField
end

function MaterialSystem.FarmSprout()
    if not Config.AutoFarmSprouts or Runtime.SproutBusy or Runtime.MeteorPriorityActive then return false end
    -- Fireflies only appear at night with a shorter catch window than Sprouts.
    if Config.AutoFarmFireflies and Runtime.FireflyPending and not Runtime.FireflyBusy then return false end

    local sprout, field = MaterialSystem.FindSprout()
    if not sprout or not field then
        Runtime.SproutPending = false
        Runtime.SproutMarker = false
        Runtime.SproutField = ""
        return false
    end

    Runtime.SproutBusy = true
    Runtime.SproutPending = sprout
    Runtime.SproutMarker = sprout
    Runtime.SproutField = field.Name
    Runtime.CurrentField = field.Name
    local handled, popped = false, false
    local deadline = os.clock() + math.max(15, tonumber(Config.SproutMaxFarmSeconds) or 180)

    while Runtime.Running and Config.Enabled and not Runtime.MeteorPriorityActive
        and os.clock() < deadline do
        if Config.AutoFarmFireflies and Runtime.FireflyPending and not Runtime.FireflyBusy then break end
        local current, currentField = MaterialSystem.FindSprout()
        if current ~= sprout then
            popped = true
            break
        end
        if currentField then field = currentField end

        -- Convert immediately when the bag fills and return if the marker survives. Without
        -- this step, small-bag accounts would stall on the Sprout forever.
        if Config.AutoConvert and pollenRatio() >= Config.ConvertPercent then
            Runtime.Digging = false
            convertPollen()
        else
            local worked = farmStep(math.max(0.5, tonumber(Config.SproutFarmSlice) or 3),
                field, "Auto Sprout", "Breaking Sprout | " .. field.Name)
            handled = worked or handled
        end
        if not sprout.Parent then
            popped = true
            break
        end
        task.wait(0.05)
    end

    if popped and not Runtime.MeteorPriorityActive then
        Runtime.SproutsFarmed += 1
        Runtime.Digging = true
        Runtime.CurrentField = field.Name
        setStatus("Auto Sprout", "Sprout popped | collecting tokens " .. field.Name)
        if standingField() ~= field then
            local point = fieldPoint(field)
            if point then tweenTo(CFrame.new(point), Config.TweenSpeed, "SproutDrop") end
        end
        local dropDeadline = os.clock() + math.max(1, tonumber(Config.SproutDropWindow) or 20)
        while Runtime.Running and Config.Enabled and not Runtime.MeteorPriorityActive
            and os.clock() < dropDeadline do
            if Config.AutoFarmFireflies and Runtime.FireflyPending and not Runtime.FireflyBusy then break end
            local remaining = math.max(0, dropDeadline - os.clock())
            local collected = Config.AutoTokens
                and sweepTokens(math.min(1.5, remaining), "SproutDrop") or 0
            handled = collected > 0 or handled
            if collected == 0 then task.wait(0.15) end
        end
    end

    Runtime.Digging = false
    Runtime.SproutBusy = false
    Runtime.SproutPending = false
    Runtime.SproutMarker = false
    Runtime.SproutField = ""
    return handled or popped
end

Runtime.ScanSprout = MaterialSystem.FindSprout
Runtime.FarmSprout = MaterialSystem.FarmSprout

function MaterialSystem.FindFirefly()
    local folder = workspace:FindFirstChild("NPCBees")
    local _, _, root = getCharacter(1)
    if not folder or not root then return nil end
    local best, bestField, bestDistance
    local now = os.clock()
    local landingSpeed = math.max(0, tonumber(Config.FireflyLandingVelocity) or 0.15)
    local maxHeight = math.max(1, tonumber(Config.FireflyMaxFieldHeight) or 4)
    for _, firefly in ipairs(folder:GetChildren()) do
        if firefly.Name == "Firefly" and (Runtime.FireflyCooldowns[firefly] or 0) <= now then
            local velocity = firefly:FindFirstChild("BodyVelocity", true)
            local linearVelocity = firefly:FindFirstChildWhichIsA("LinearVelocity", true)
            local position = objectPosition(firefly)
            local speed = velocity and velocity.Velocity.Magnitude
                or (linearVelocity and linearVelocity.VectorVelocity.Magnitude)
            -- Fireflies can only be triggered once landed. Do not
            -- chase a flying one; it switches fields before the player can touch it.
            if position and speed and speed <= landingSpeed then
                local field = flowerFieldAtPosition(position, 6)
                local surfaceHeight = field and fieldSurfaceOffset(field, position) or nil
                local distance = (root.Position - position).Magnitude
                if field and fieldUnlocked(field.Name) and surfaceHeight
                    and surfaceHeight >= -2 and surfaceHeight <= maxHeight
                    and (not bestDistance or distance < bestDistance) then
                    best, bestField, bestDistance = firefly, field, distance
                end
            end
        end
    end
    return best, bestField
end

-- Real mechanic (wiki): 8 fireflies land in a circle in one field; after nudging
-- all 8, rewards spawn in the MIDDLE of the formation. This computes the circle
-- center as the average position of the firefly group in the field.
function MaterialSystem.FireflyFormationCenter(field)
    local folder = workspace:FindFirstChild("NPCBees")
    if not folder then return nil end
    local sum, count = Vector3.zero, 0
    for _, firefly in ipairs(folder:GetChildren()) do
        if firefly.Name == "Firefly" then
            local position = objectPosition(firefly)
            if position and (not field or fieldContainsPosition(field, position, 15)) then
                sum += position
                count += 1
            end
        end
    end
    if count >= 2 then return sum / count end
    return nil
end

function MaterialSystem.FindMoonCharmToken(field, origin, radius)
    local collectibles = workspace:FindFirstChild("Collectibles")
    local _, _, root = getCharacter(1)
    if not collectibles or not root then return nil end
    local best, bestDistance
    for _, token in ipairs(collectibles:GetChildren()) do
        local position = objectPosition(token)
        if position and tokenAllowed(token) and (not field or fieldContainsPosition(field, position, 4))
            and (not field or tokenNearFieldSurface(field, position))
            and (not origin or (position - origin).Magnitude <= (radius or 40)) then
            local descriptor = tokenDescriptor(token)
            local decal = token:FindFirstChild("FrontDecal", true) or token:FindFirstChildWhichIsA("Decal", true)
            local texture = decal and tostring(decal.Texture) or ""
            local moonCharm = descriptor:find("moon", 1, true) or texture:find("2306224708", 1, true)
            if moonCharm then
                local distance = (root.Position - position).Magnitude
                if not bestDistance or distance < bestDistance then best, bestDistance = token, distance end
            end
        end
    end
    return best
end

function MaterialSystem.FarmFirefly()
    if not Config.AutoFarmFireflies or Runtime.FireflyBusy or Runtime.MeteorPriorityActive then return false end
    local currentField = standingField()
    local looseMoonCharm = currentField and MaterialSystem.FindMoonCharmToken(currentField, nil, nil) or nil
    if looseMoonCharm then
        Runtime.FireflyBusy = true
        setStatus("Auto Fireflies", "Collecting Moon Charm | " .. currentField.Name)
        local collected = collectToken(looseMoonCharm, "FireflyMoonCharm")
        Runtime.FireflyBusy = false
        Runtime.FireflyPending = false
        return collected
    end
    local firefly, field = MaterialSystem.FindFirefly()
    if not firefly or not field then Runtime.FireflyPending = false return false end

    Runtime.FireflyBusy = true
    local handled = false
    local budgetDeadline = os.clock() + math.max(3, tonumber(Config.FireflyFarmBudget) or 9)
    while Runtime.Running and Config.Enabled and not Runtime.MeteorPriorityActive
        and firefly and field and os.clock() < budgetDeadline do
        local position = objectPosition(firefly)
        if not position or not fieldUnlocked(field.Name) then break end
        -- Update the formation center while the group is still in the field.
        local center = MaterialSystem.FireflyFormationCenter(field)
        if center then
            Runtime.FireflyCenter = center
            Runtime.FireflyCenterAt = os.clock()
        end
        Runtime.CurrentField = field.Name
        Runtime.Digging = true
        setStatus("Auto Fireflies", "Waiting for Firefly to land | " .. field.Name)
        local moved = tweenTo(CFrame.new(position + Vector3.new(0, 1.5, 0)), Config.TokenTweenSpeed, "Firefly")
        Runtime.FireflyCooldowns[firefly] = os.clock()
            + math.max(0.5, tonumber(Config.FireflyRetryCooldown) or 1.25)
        if moved then
            handled = true
            Runtime.FirefliesCollected += 1
            -- Stay on the Firefly until it starts flying again; that signals
            -- the touch registered and a Moon Charm may have spawned.
            local touchDeadline = os.clock() + math.max(0.5, tonumber(Config.FireflyTouchTimeout) or 2.5)
            while firefly.Parent and not Runtime.MeteorPriorityActive and os.clock() < touchDeadline do
                local velocity = firefly:FindFirstChild("BodyVelocity", true)
                local speed = velocity and velocity.Velocity.Magnitude or math.huge
                if speed > math.max(0, tonumber(Config.FireflyLandingVelocity) or 0.15) then break end
                local _, humanoid = getCharacter(1)
                if humanoid then humanoid:MoveTo(position) end
                task.wait(0.08)
            end
            remoteCall("ToolCollect")

            local tokenDeadline = math.min(budgetDeadline,
                os.clock() + math.max(1, tonumber(Config.FireflyTokenWindow) or 3))
            local moonCollected = false
            repeat
                local token = MaterialSystem.FindMoonCharmToken(field, position, 45)
                if token then
                    moonCollected = collectToken(token, "FireflyMoonCharm") or moonCollected
                else
                    task.wait(0.1)
                end
            until not Runtime.Running or Runtime.MeteorPriorityActive or os.clock() >= tokenDeadline
            if not moonCollected and Config.AutoTokens then sweepTokens(1, "FireflyDrop") end
        end
        if Runtime.MeteorPriorityActive then break end
        firefly, field = MaterialSystem.FindFirefly()
    end

    -- The whole group has flown up (no landed fireflies left): rewards spawn at the
    -- CENTER of the formation - fly to the tracked center to collect.
    if handled and not firefly and typeof(Runtime.FireflyCenter) == "Vector3"
        and os.clock() - (Runtime.FireflyCenterAt or 0) <= 30
        and not Runtime.MeteorPriorityActive then
        setStatus("Auto Fireflies", "Collecting formation center reward")
        Runtime.Digging = true
        if tweenTo(CFrame.new(Runtime.FireflyCenter + Vector3.new(0, 2, 0)),
            Config.TokenTweenSpeed, "Firefly") then
            remoteCall("ToolCollect")
            if Config.AutoTokens then sweepTokens(4, "FireflyCenter") end
            local centerDeadline = os.clock() + 3
            repeat
                local token = MaterialSystem.FindMoonCharmToken(nil, Runtime.FireflyCenter, 30)
                if token then collectToken(token, "FireflyMoonCharm") end
                task.wait(0.1)
            until not Runtime.Running or Runtime.MeteorPriorityActive or os.clock() >= centerDeadline
        end
        Runtime.FireflyCenter = nil
        Runtime.Digging = false
    end
    Runtime.Digging = false
    Runtime.FireflyBusy = false
    Runtime.FireflyPending = false
    return handled
end

Runtime.ScanFirefly = MaterialSystem.FindFirefly
Runtime.FarmFirefly = MaterialSystem.FarmFirefly

-- Unified scanner: ONE loop updates Sprout + Firefly/Moon
-- Charm + Mondo Chick - halving workspace traversals versus the two separate
-- loops. Read-only, never owns movement; the scheduler handles each job
-- at the nearest yield point in order Meteor > Firefly > Sprout > Mondo.
task.spawn(function()
    while Runtime.Running do
        local enabled = Config.Enabled and not Runtime.MeteorPriorityActive
        if enabled and Config.AutoFarmSprouts and not Runtime.SproutBusy then
            local sprout, field = MaterialSystem.FindSprout()
            Runtime.SproutPending = sprout or false
            Runtime.SproutMarker = sprout or false
            Runtime.SproutField = field and field.Name or ""
        elseif not Runtime.SproutBusy then
            Runtime.SproutPending = false
            Runtime.SproutMarker = false
            Runtime.SproutField = ""
        end
        if enabled and Config.AutoFarmFireflies and not Runtime.FireflyBusy then
            local npcBees = workspace:FindFirstChild("NPCBees")
            local exists = npcBees and npcBees:FindFirstChild("Firefly")
            if exists then Runtime.LastFireflySeen = os.clock() end
            if exists or os.clock() - Runtime.LastFireflySeen <= 5 then
                local currentField = standingField()
                local moonCharm = currentField and MaterialSystem.FindMoonCharmToken(currentField, nil, nil) or nil
                local firefly = moonCharm and nil or MaterialSystem.FindFirefly()
                Runtime.FireflyPending = moonCharm or firefly or false
            else
                -- During the day, skip scanning all Collectibles every tick.
                Runtime.FireflyPending = false
            end
        elseif not Runtime.FireflyBusy then
            Runtime.FireflyPending = false
        end
        if enabled and Config.AutoFarmMondoChick and type(Runtime.FindMondoChick) == "function" then
            Runtime.MondoChickPending = Runtime.FindMondoChick() ~= nil
        end
        if enabled and Config.AutoFarmViciousAlways and Config.AutoFarmVicious
            and type(MaterialSystem.FindVicious) == "function" then
            Runtime.ViciousPending = MaterialSystem.FindVicious() ~= nil
        end
        task.wait(math.max(0.15, math.min(
            math.max(0.1, tonumber(Config.SproutScanInterval) or 0.25),
            math.max(0.1, tonumber(Config.FireflyScanInterval) or 0.25))))
    end
end)

function MaterialSystem.FindVicious()
    local monsters = workspace:FindFirstChild("Monsters")
    if monsters then
        for _, mob in ipairs(monsters:GetChildren()) do
            local humanoid = mob:FindFirstChildOfClass("Humanoid")
            if string.find(string.lower(mob.Name), "vicious", 1, true)
                and humanoid and humanoid.Health > 0 and objectPosition(mob) then
                return mob, false
            end
        end
    end
    local particles = workspace:FindFirstChild("Particles")
    local waiting = particles and particles:FindFirstChild("WTs")
    waiting = waiting and waiting:FindFirstChild("WaitingThorn")
    return waiting, waiting ~= nil
end

function MaterialSystem.FarmVicious()
    if not Config.AutoFarmVicious then return false end
    if Runtime.MeteorPriorityActive or Runtime.ViciousBusy then return false end
    local target, thorn = MaterialSystem.FindVicious()
    local position = objectPosition(target)
    local field = position and flowerFieldAtPosition(position, 18) or nil
    if not target or not position or not field or not fieldUnlocked(field.Name) then return false end

    Runtime.CurrentField = field.Name
    Runtime.Digging = true
    Runtime.MaterialCombat = true
    Runtime.ViciousBusy = true
    setStatus("Farm material", "Stinger | Vicious @ " .. field.Name)
    -- Phase 1: tween to the field first (a point inside the field near the vic).
    local entryPoint = fieldPoint(field)
    if entryPoint then
        tweenTo(CFrame.new(entryPoint), Config.TweenSpeed, "Vicious")
    end
    if thorn then
        local spawnDeadline = os.clock() + 4
        repeat
            task.wait(0.2)
            target, thorn = MaterialSystem.FindVicious()
        until not Runtime.Running or Runtime.MeteorPriorityActive or not thorn or os.clock() >= spawnDeadline
    end

    -- Phase 2: hover above the Vicious' head - outside ground-spike range, avoiding damage;
    -- bees around the player attack it. Re-tween to the vic whenever it drifts too far.
    local hoverHeight = math.max(6, tonumber(Config.ViciousHoverHeight) or 14)
    local deadline = os.clock() + Config.MaterialCombatSeconds
    while Runtime.Running and Config.Enabled and not Runtime.MeteorPriorityActive and os.clock() < deadline do
        local mob = select(1, MaterialSystem.FindVicious())
        if not mob or not string.find(string.lower(mob.Name), "vicious", 1, true) then break end
        local mobPosition = objectPosition(mob)
        local _, humanoid, root = getCharacter(1)
        if not humanoid or not root or not mobPosition then break end
        local hoverTarget = CFrame.new(mobPosition + Vector3.new(0, hoverHeight, 0))
        if (root.Position - hoverTarget.Position).Magnitude > 5 then
            tweenTo(hoverTarget, Config.TokenTweenSpeed, "Vicious")
        else
            humanoid:Move(Vector3.zero, false)
        end
        remoteCall("ToolCollect")
        task.wait(0.2)
    end
    sweepTokens(3, "ViciousDrop")
    Runtime.MaterialCombat = false
    Runtime.ViciousBusy = false
    Runtime.Digging = false
    return true
end

-- Mondo Chick: spawns hourly on Mountain Top Field, drops Bitterberry/
-- Neonberry for the blender. The scanner sets MondoChickPending; the scheduler
-- calls FarmMondoChick at a safe yield point (like Sprout/Firefly).
function Runtime.FindMondoChick()
    local monsters = workspace:FindFirstChild("Monsters")
    if not monsters then return nil end
    for _, mob in ipairs(monsters:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        local normalized = string.lower(mob.Name):gsub("[^%w]", "")
        if humanoid and humanoid.Health > 0 and objectPosition(mob)
            and string.find(normalized, "mondochick", 1, true) then
            return mob
        end
    end
    return nil
end

function Runtime.FarmMondoChick()
    if not Config.AutoFarmMondoChick or Runtime.MeteorPriorityActive then return false end
    if beeCount() < (FIELD_REQUIREMENTS["Mountain Top Field"] or math.huge) then return false end
    local chick = Runtime.FindMondoChick()
    if not chick then
        Runtime.MondoChickPending = false
        return false
    end

    Runtime.CurrentField = "Mountain Top Field"
    Runtime.Digging = true
    setStatus("Mondo Chick", "Fighting Mondo Chick | Mountain Top Field")
    local deadline = os.clock() + math.max(30, tonumber(Config.MondoChickFightTimeout) or 120)
    while Runtime.Running and Config.Enabled and not Runtime.MeteorPriorityActive and os.clock() < deadline do
        chick = Runtime.FindMondoChick()
        if not chick then break end
        local position = objectPosition(chick)
        local _, humanoid, root = getCharacter(1)
        if not position or not humanoid or not root then break end
        if (root.Position - position).Magnitude > 24 then
            tweenTo(CFrame.new(position + Vector3.new(0, 2, 8)), Config.TweenSpeed, "MondoChick")
        else
            humanoid:Move(Vector3.zero, false)
            if humanoid.FloorMaterial ~= Enum.Material.Air then humanoid.Jump = true end
        end
        remoteCall("ToolCollect")
        task.wait(0.2)
    end
    sweepTokens(3, "MondoDrop")
    Runtime.Digging = false
    Runtime.MondoChickPending = false
    -- Dead or expired: wait 60s before rescanning to avoid retry spam.
    Runtime.MondoChickRetryAt = os.clock() + 60
    task.defer(function() getStats(true) end)
    return true
end

-- Vicious always-on: no material planner needed - whenever a live vic spawns
-- (night), fight it and bank stingers. Level gate: only fight vic whose level
-- is BELOW the hive average (read from the real hive); skip stronger ones.
function Runtime.ViciousLevelAllowed(mob)
    if not Config.ViciousRespectHiveLevel then return true end
    local mobLevel = Runtime.MobLevel(mob)
    local hiveLevel = Runtime.HiveAverageLevel()
    if not mobLevel or not hiveLevel then return true end
    return mobLevel < hiveLevel
end

function Runtime.FarmViciousAlways()
    if not Config.AutoFarmViciousAlways or not Config.AutoFarmVicious then return false end
    if Runtime.MeteorPriorityActive or Runtime.ViciousBusy then return false end
    local mob = MaterialSystem.FindVicious()
    if not mob then
        Runtime.ViciousPending = false
        return false
    end
    if not Runtime.ViciousLevelAllowed(mob) then
        local mobLevel = Runtime.MobLevel(mob) or 0
        local hiveLevel = Runtime.HiveAverageLevel() or 0
        setStatus("Vicious Bee", string.format("Skip: vic lv.%d >= hive avg lv.%.1f", mobLevel, hiveLevel))
        Runtime.ViciousPending = false
        Runtime.ViciousRetryAt = os.clock() + 30
        return false
    end
    return MaterialSystem.FarmVicious()
end

function MaterialSystem.PlanterData()
    local planters = MaterialSystem.LocalPlanters
    if not Config.AutoMaterialPlanters or type(planters) ~= "table"
        or type(planters.LoadPlanter) ~= "function" then return {} end
    local getUpvalues = (debug and debug.getupvalues) or rawget(ENV, "getupvalues")
    if type(getUpvalues) ~= "function" then return {} end
    local ok, upvalues = pcall(getUpvalues, planters.LoadPlanter)
    if not ok or type(upvalues) ~= "table" then return {} end
    local result, seen = {}, {}
    for _, candidate in pairs(upvalues) do
        if type(candidate) == "table" then
            for _, data in pairs(candidate) do
                if type(data) == "table" and data.IsMine and data.ActorID and data.Pos
                    and not seen[data.ActorID] then
                    seen[data.ActorID] = true
                    table.insert(result, data)
                end
            end
        end
    end
    return result
end

function MaterialSystem.PlanterProgress(data)
    local ok, value = pcall(function()
        return data.Gui.Bar.FillBar.Size.X.Scale / math.max(0.001, data.Gui.Bar.Size.X.Scale)
    end)
    return ok and math.clamp(tonumber(value) or 0, 0, 1) or 0
end

function MaterialSystem.PlanterName(data)
    if data and data.PotModel then return tostring(data.PotModel) end
    return ""
end

function MaterialSystem.ChoosePlanter(stats, active)
    local folder = ReplicatedStorage:FindFirstChild("LocalPlanters")
    folder = folder and folder:FindFirstChild("Planter Pots")
    if not folder then return nil end
    local used = {}
    for _, data in ipairs(active) do
        local name = MaterialSystem.PlanterName(data)
        used[name] = (used[name] or 0) + 1
    end
    local priority = {
        "Blue Clay Planter", "Tacky Planter", "Candy Planter", "Plastic Planter",
        "Paper Planter", "Red Clay Planter", "Pesticide Planter", "Heat-Treated Planter",
        "Hydroponic Planter", "Petal Planter", "Planter of Plenty",
    }
    local available = {}
    for _, model in ipairs(folder:GetChildren()) do available[model.Name] = true end
    for _, name in ipairs(priority) do
        if available[name] and MaterialSystem.Amount(name, stats) > (used[name] or 0) then return name end
    end
    for name in pairs(available) do
        if MaterialSystem.Amount(name, stats) > (used[name] or 0) then return name end
    end
    return nil
end

function MaterialSystem.PlanterWork(material, field, stats)
    if not Config.AutoMaterialPlanters or not field
        or os.clock() - Runtime.LastMaterialPlanterAction < Config.MaterialPlanterActionCooldown then return false end
    if material ~= "Honeysuckle" and material ~= "ComfortingVial" and material ~= "RefreshingVial" then
        return false
    end

    local active = MaterialSystem.PlanterData()
    for _, data in ipairs(active) do
        local position = typeof(data.Pos) == "Vector3" and data.Pos or objectPosition(data.PotModel)
        local planterField = position and flowerFieldAtPosition(position + Vector3.new(0, 4, 0), 8) or nil
        if planterField == field and MaterialSystem.PlanterProgress(data) >= Config.MaterialPlanterHarvestPercent then
            Runtime.LastMaterialPlanterAction = os.clock()
            setStatus("Farm material", "Harvest " .. MaterialSystem.PlanterName(data) .. " @ " .. field.Name)
            tweenTo(CFrame.new(position + Vector3.new(0, 3, 0)), Config.TweenSpeed, "MaterialPlanter")
            local ok = remoteCall("PlanterModelCollect", data.ActorID)
            if ok then
                task.wait(1)
                sweepTokens(3, "PlanterDrop")
            end
            return ok
        end
    end

    if #active >= 3 then return false end
    local planterName = MaterialSystem.ChoosePlanter(stats, active)
    local point = planterName and fieldPoint(field) or nil
    if not planterName or not point then return false end
    Runtime.LastMaterialPlanterAction = os.clock()
    setStatus("Farm material", "Plant " .. planterName .. " @ " .. field.Name)
    tweenTo(CFrame.new(point), Config.TweenSpeed, "MaterialPlanter")
    task.wait(0.35)
    return select(1, remoteCall("PlayerActivesCommand", {Name = planterName}))
end

function MaterialSystem.GuiVisible(object)
    local current = object
    while current and current ~= Player do
        if current:IsA("GuiObject") and not current.Visible then return false end
        current = current.Parent
    end
    return true
end

function MaterialSystem.ActivateButton(button)
    if not button or not button:IsA("GuiButton") or not MaterialSystem.GuiVisible(button) then return false end
    local fireSignal = rawget(ENV, "firesignal")
    if type(fireSignal) == "function" then
        local ok = pcall(fireSignal, button.MouseButton1Click)
        if ok then return true end
    end
    return pcall(button.Activate, button)
end

function MaterialSystem.IsNectarMenu(object)
    local current, depth = object, 0
    while current and current ~= Player and depth < 10 do
        local name = string.lower(current.Name):gsub("[^%w]", "")
        if name:find("nectar", 1, true) or name:find("condenser", 1, true) then return true end
        current = current.Parent
        depth += 1
    end
    return false
end

function MaterialSystem.FindCondenser()
    local cached = Runtime.NectarCondenserObject
    if cached and cached.Parent then return cached end
    cached = workspace:FindFirstChild("Nectar Condenser", true)
        or workspace:FindFirstChild("NectarCondenser", true)
    if not cached then
        for _, object in ipairs(workspace:GetDescendants()) do
            local normalized = string.lower(object.Name):gsub("[^%w]", "")
            if normalized:find("nectarcondenser", 1, true) then cached = object break end
        end
    end
    Runtime.NectarCondenserObject = cached
    return cached
end

function MaterialSystem.TryCondenser(material)
    if not Config.AutoNectarCondenser or beeCount() < 35
        or (material ~= "ComfortingVial" and material ~= "RefreshingVial")
        or os.clock() - Runtime.LastNectarCondenserAction < Config.NectarCondenserCooldown then return false end
    local condenser = MaterialSystem.FindCondenser()
    local position = objectPosition(condenser)
    if not condenser or not position then return false end

    Runtime.LastNectarCondenserAction = os.clock()
    setStatus("Farm material", "Nectar Condenser | " .. MaterialSystem.Display(material))
    if not tweenTo(CFrame.new(position + Vector3.new(0, 3, 0)), Config.TweenSpeed, "NectarCondenser") then
        return false
    end

    local opened = false
    local prompt = condenser:FindFirstChildWhichIsA("ProximityPrompt", true)
    local click = condenser:FindFirstChildWhichIsA("ClickDetector", true)
    local firePrompt = rawget(ENV, "fireproximityprompt")
    local fireClick = rawget(ENV, "fireclickdetector")
    if prompt and type(firePrompt) == "function" then opened = pcall(firePrompt, prompt) end
    if not opened and click and type(fireClick) == "function" then opened = pcall(fireClick, click) end
    if not opened then return false end
    task.wait(0.6)

    local wanted = string.lower(material:gsub("Vial", ""))
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    local selected = false
    if playerGui then
        for _, object in ipairs(playerGui:GetDescendants()) do
            if object:IsA("GuiButton") and MaterialSystem.GuiVisible(object) and MaterialSystem.IsNectarMenu(object) then
                local label = object:IsA("TextButton") and object.Text or ""
                local text = string.lower(tostring(label) .. " " .. object.Name)
                if text:find(wanted, 1, true) then
                    selected = MaterialSystem.ActivateButton(object)
                    if selected then break end
                end
            end
        end
    end
    if not selected then return false end
    task.wait(0.25)

    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("GuiButton") and MaterialSystem.GuiVisible(object) and MaterialSystem.IsNectarMenu(object) then
            local label = object:IsA("TextButton") and object.Text or ""
            local text = string.lower(tostring(label) .. " " .. object.Name)
            if text:find("condense", 1, true) or text:find("confirm", 1, true)
                or text:find("create", 1, true) then
                MaterialSystem.ActivateButton(object)
                break
            end
        end
    end
    task.wait(0.75)
    Runtime.LastMaterialStats = -math.huge
    MaterialSystem.Stats(true)
    return true
end

function MaterialSystem.FarmSource(action, entry)
    if Runtime.MeteorPriorityActive then return false end
    local material = MaterialSystem.Canonical(action.Material)
    Runtime.MaterialName = material
    Runtime.MaterialTarget = entry and entry.Type or ""
    Runtime.ProgressStage = string.format("Materials for %s", Runtime.MaterialTarget)
    setStatus("Farm material", string.format("%s %d/%d | %s",
        MaterialSystem.Display(material), action.Owned or 0, action.Required or 0, Runtime.MaterialTarget))

    if select(1, pollenRatio()) >= Config.ConvertPercent and Config.AutoConvert then
        return convertPollen()
    end
    if material == "Stinger" and MaterialSystem.FarmVicious() then return true end
    if material == "MoonCharm" and MaterialSystem.FarmFirefly() then return true end
    if (material == "MagicBean" or material == "RoyalJelly" or material == "MoonCharm"
        or material == "Neonberry" or material == "Bitterberry")
        and MaterialSystem.FarmSprout() then return true end
    if material == "MoonCharm" and farmFlowerEffect() then return true end
    local field = MaterialSystem.Field(material)
    if field == nil then
        -- Every source field for this material is still locked: nothing useful
        -- to do here (the milestone defers the gear until a source unlocks).
        return false
    end
    if MaterialSystem.PlanterWork(material, field, MaterialSystem.Stats(false)) then return true end
    if MaterialSystem.TryCondenser(material) then return true end
    if material == "DiamondEgg" or material == "SpiritPetal"
        or material == "ComfortingVial" or material == "RefreshingVial" then
        local materialNPC = material == "SpiritPetal" and "Spirit Bear"
            or ((material == "ComfortingVial" or material == "RefreshingVial") and "Dapper Bear" or nil)
        if materialNPC and beeCount() >= 35 then
            QUEST_NPC_SET[materialNPC] = true
            local hasMaterialQuest, materialQuestDone = false, true
            for _, quest in ipairs(activeBearQuests(true)) do
                if quest.NPC == materialNPC then
                    hasMaterialQuest = true
                    if next(quest.Progress) == nil and #(quest.Info.Tasks or {}) > 0 then materialQuestDone = false end
                    for _, progress in pairs(quest.Progress) do
                        if (tonumber(progress[1]) or 0) < 1 then materialQuestDone = false break end
                    end
                end
            end
            if (not hasMaterialQuest or materialQuestDone) and interactQuestNPC(materialNPC) then return true end
        end
        if Config.AutoQuest and maintainBearQuests() then return true end
        if Config.AutoQuest and questWork(Config.QuestFarmSeconds) then return true end
    end

    if field then
        return farmStep(Config.MaterialFarmSeconds, field, "Farm material",
            MaterialSystem.Display(material) .. " | " .. field.Name)
    end
    task.wait(1)
    return false
end

function MaterialSystem.Work(entry)
    if not Config.AutoMaterials or not entry or not entry.RequiresMaterials then return false end
    if Runtime.MeteorPriorityActive then return false end
    if Config.AutoFarmFireflies and Runtime.FireflyPending and MaterialSystem.FarmFirefly() then return true end
    if Config.AutoFarmSprouts and Runtime.SproutPending and MaterialSystem.FarmSprout() then return true end
    local force = os.clock() - Runtime.LastBlenderCheck >= Config.BlenderCheckInterval
    if force then Runtime.LastBlenderCheck = os.clock() end
    local stats = MaterialSystem.Stats(force)
    local action, deficits = MaterialSystem.NextAction(entry, stats, false)
    if not next(deficits) then
        Runtime.MaterialName = ""
        Runtime.MaterialTarget = ""
        Runtime.DeferredItems[entry.Type] = nil
        return true
    end

    -- `stats` was refreshed immediately above; do not invoke RetrievePlayerStats
    -- a second time in the same scheduler tick.
    local state, blender, remaining = MaterialSystem.BlenderStatus(false)
    if state == "done" then
        MaterialSystem.ClaimBlender()
        return false
    elseif state == "crafting" then
        Runtime.ProgressStage = string.format("Blender x%d %s", tonumber(blender.Count) or 0, tostring(blender.Recipe))
        setStatus("Blender running", string.format("%s | %.1f min left", tostring(blender.Recipe), remaining / 60))
        -- Blender consumes ingredients as soon as the order starts. Add its
        -- pending output to a virtual inventory so the planner does not farm the
        -- exact same input batch again during the wait.
        local virtualStats = {}
        for key, value in pairs(stats) do virtualStats[key] = value end
        virtualStats.Eggs = {}
        for key, value in pairs(stats.Eggs or {}) do virtualStats.Eggs[key] = value end
        local pendingMaterial = MaterialSystem.Canonical(blender.Recipe)
        local pendingRecipe = MaterialSystem.Recipe(pendingMaterial)
        local pendingYield = pendingRecipe and pendingRecipe.Yield or 1
        virtualStats.Eggs[pendingMaterial] = MaterialSystem.Amount(pendingMaterial, stats)
            + (tonumber(blender.Count) or 0) * (tonumber(pendingYield) or 1)
        local farmAction = MaterialSystem.NextAction(entry, virtualStats, true)
        if farmAction then return MaterialSystem.FarmSource(farmAction, entry) end
        -- Ingredients for the current queue are already consumed. Keep earning
        -- honey/tokens instead of standing beside the Blender.
        return farmStep(math.min(Config.MaterialFarmSeconds, 8), MaterialSystem.Field("RoyalJelly"),
            "Waiting for Blender", string.format("%s | %.1f min", tostring(blender.Recipe), remaining / 60))
    end

    if action and action.Kind == "craft" then
        MaterialSystem.StartBlender(action)
        return false
    elseif action then
        return MaterialSystem.FarmSource(action, entry)
    end
    return false
end

Runtime.GetMaterialDeficits = function(itemType)
    local entry = {Type = itemType, Materials = MaterialSystem.Gear[itemType] or {}}
    return MaterialSystem.Deficits(entry, MaterialSystem.Stats(true))
end
Runtime.GetBlenderStatus = MaterialSystem.BlenderStatus

local function meteorPosition(value)
    if typeof(value) == "Vector3" then return value end
    if typeof(value) == "CFrame" then return value.Position end
    if typeof(value) == "Instance" then return objectPosition(value) end
    return nil
end

local function enqueueMeteor(data)
    if type(data) ~= "table" then return false end
    local position = meteorPosition(data.Position or data.Pos)
    if not position then return false end
    local now = os.clock()
    local readyAt = tonumber(data.ReadyAt) or now
    local expireAt = tonumber(data.ExpireAt) or (now + Config.MeteorFallbackLifetime)
    if expireAt <= now then return false end

    for _, queued in ipairs(Runtime.MeteorQueue) do
        local differentDetector = data.Source ~= queued.Source
        if (queued.Position - position).Magnitude < 3
            and (differentDetector or math.abs(queued.ExpireAt - expireAt) < 2) then
            -- LocalFX timing is authoritative; the white Neon part is fallback.
            if data.Source == "LocalFX" or queued.Source ~= "LocalFX" then
                queued.ReadyAt = readyAt
                queued.ExpireAt = expireAt
                queued.Source = data.Source
            end
            queued.Marker = data.Marker or queued.Marker
            local queuedField = flowerFieldAtPosition(position, 10)
            queued.FieldName = queuedField and queuedField.Name or queued.FieldName
            if Config.AutoMeteor then
                Runtime.MeteorPriorityActive = true
                if not Runtime.MeteorHandling then cancelMovement() end
            end
            return true
        end
    end

    local meteorField = flowerFieldAtPosition(position, 10)
    table.insert(Runtime.MeteorQueue, {
        Position = position,
        ReadyAt = readyAt,
        ExpireAt = expireAt,
        Source = data.Source or "Fallback",
        Marker = data.Marker,
        FieldName = meteorField and meteorField.Name or nil,
    })
    table.sort(Runtime.MeteorQueue, function(a, b) return a.ReadyAt < b.ReadyAt end)
    while #Runtime.MeteorQueue > 30 do table.remove(Runtime.MeteorQueue) end
    if Config.AutoMeteor then
        Runtime.MeteorPriorityActive = true
        if not Runtime.MeteorHandling then cancelMovement() end
    end
    return true
end

local localFX = Events:FindFirstChild("LocalFX")
if localFX and localFX:IsA("RemoteEvent") then
    connect(localFX.OnClientEvent, function(effectName, payload)
        if effectName == "MythicMeteor" and type(payload) == "table" then
            local started = os.clock()
            local total = math.max(0.1, (tonumber(payload.Delay) or 2.5) + (tonumber(payload.Dur) or 0.8))
            enqueueMeteor({
                Position = payload.Pos or payload.Position,
                ReadyAt = started + total * math.clamp(Config.MeteorImpactLeadFraction, 0, 1),
                ExpireAt = started + total,
                Source = "LocalFX",
            })
        end
    end)
end

local function isMeteorMarker(object)
    local particlesFolder = workspace:FindFirstChild("Particles")
    return object and object.Parent == particlesFolder and object:IsA("BasePart") and object.Name == "Part"
        and object.BrickColor == BrickColor.new("Institutional white")
        and object.Material == Enum.Material.Neon
end

local function trackMeteorMarker(object)
    task.defer(function()
        if not Config.MeteorPartFallback or not object or not object.Parent or not isMeteorMarker(object) then return end
        enqueueMeteor({
            Position = object.Position,
            ReadyAt = os.clock(),
            ExpireAt = os.clock() + Config.MeteorFallbackLifetime,
            Source = "NeonPart",
            Marker = object,
        })
    end)
end

local particles = workspace:FindFirstChild("Particles")
if Config.MeteorPartFallback and particles then
    -- Do not scan old white Neon parts at startup: several unrelated effects use
    -- the same generic Part signature and used to create fake meteor jobs.
    connect(particles.ChildAdded, trackMeteorMarker)
end

local function triggerMeteorIfReady()
    if not Config.AutoTriggerMeteor then return end
    local now = os.clock()
    if now < (Runtime.NextMeteorTriggerCheck or 0) then return end
    local checkInterval = math.max(30, tonumber(Config.MeteorTriggerInterval) or 60)
    Runtime.NextMeteorTriggerCheck = now + checkInterval

    -- The machine is locked until 3 distinct Mythic bee types are discovered.
    -- Listening to server-wide showers remains enabled for every account.
    local required = math.max(1, tonumber(Config.MeteorRequiredMythicTypes) or 3)
    if type(Runtime.MythicDiscoveryCount) ~= "function"
        or Runtime.MythicDiscoveryCount(false) < required then return end

    local cooldown = math.max(60, tonumber(Config.MeteorSummonerCooldown) or 79200)
    local toy = workspace:FindFirstChild("Toys")
    toy = toy and toy:FindFirstChild("Mythic Meteor Shower")
    local cooldownValue = toy and toy:FindFirstChild("Cooldown")
    if cooldownValue and cooldownValue:IsA("ValueBase") then
        cooldown = math.max(60, tonumber(cooldownValue.Value) or cooldown)
    end
    local stats = getStats(false)
    local toyTimes = type(stats) == "table" and stats.ToyTimes or nil
    local lastUse = type(toyTimes) == "table" and tonumber(toyTimes["Mythic Meteor Shower"]) or nil
    if lastUse then
        local remaining = cooldown - (os.time() - lastUse)
        if remaining > 0 then
            Runtime.NextMeteorTriggerCheck = now + math.max(30, math.min(remaining, checkInterval))
            return
        end
    elseif now - Runtime.LastMeteorTrigger < cooldown then
        return
    end

    Runtime.LastMeteorTrigger = now
    Runtime.NextMeteorTriggerCheck = now + cooldown
    -- Trying the summoner is not proof that a shower exists. Only the actual
    -- MythicMeteor LocalFX event is allowed to change status/claim movement.
    remoteCall("ToyEvent", "Mythic Meteor Shower")
end

local function handleMeteor()
    if Runtime.MeteorHandling then return false end
    Runtime.MeteorHandling = true
    Runtime.MeteorPriorityActive = true
    local function finish(result)
        Runtime.MeteorHandling = false
        Runtime.MeteorPriorityActive = Config.AutoMeteor and #Runtime.MeteorQueue > 0
        if #Runtime.MeteorQueue == 0 then Runtime.MeteorLockedField = "" end
        return result
    end

    local function meteorField(queued)
        if not queued then return nil end
        local field = queued.FieldName and findField(queued.FieldName)
            or flowerFieldAtPosition(queued.Position, 10)
        if field then queued.FieldName = field.Name end
        return field
    end
    local function removeMeteor(queued)
        for index = #Runtime.MeteorQueue, 1, -1 do
            if Runtime.MeteorQueue[index] == queued then
                table.remove(Runtime.MeteorQueue, index)
                return
            end
        end
    end
    local function pruneQueue()
        local now = os.clock()
        for index = #Runtime.MeteorQueue, 1, -1 do
            local queued = Runtime.MeteorQueue[index]
            local invalidFallback = queued.Source == "NeonPart"
                and (not queued.Marker or not queued.Marker.Parent or not isMeteorMarker(queued.Marker))
            local field = meteorField(queued)
            if queued.ExpireAt <= now or invalidFallback or not field or not fieldUnlocked(field.Name) then
                table.remove(Runtime.MeteorQueue, index)
            end
        end
    end
    local function firstMeteorInField(fieldName)
        local best, bestIndex
        for index, queued in ipairs(Runtime.MeteorQueue) do
            if queued.FieldName == fieldName and (not best or queued.ReadyAt < best.ReadyAt) then
                best, bestIndex = queued, index
            end
        end
        return best, bestIndex
    end

    pruneQueue()
    if #Runtime.MeteorQueue == 0 then return finish(false) end

    -- Keep the field being handled. Without a lock, prefer the player's current field;
    -- if it has no meteor, take the earliest impact's field.
    local lockedName = Runtime.MeteorLockedField
    local meteor = lockedName ~= "" and firstMeteorInField(lockedName) or nil
    if not meteor then
        local currentField = standingField()
        if currentField then
            meteor = firstMeteorInField(currentField.Name)
            if meteor then lockedName = currentField.Name end
        end
    end
    if not meteor then
        meteor = Runtime.MeteorQueue[1]
        local selectedField = meteorField(meteor)
        lockedName = selectedField and selectedField.Name or ""
    end
    local field = meteorField(meteor)
    if not meteor or not field or not fieldUnlocked(field.Name) then
        if meteor then removeMeteor(meteor) end
        Runtime.MeteorLockedField = ""
        return finish(false)
    end
    Runtime.MeteorLockedField = field.Name
    Runtime.CurrentField = field.Name
    Runtime.Digging = true
    setStatus("Auto meteor", string.format("Lock field %s | heading to impact", field.Name))
    local target = meteor.Position + Vector3.new(0, 3, 0)
    -- Tween only once when entering the field. Later impacts in the same field walk.
    local moved = tweenTo(CFrame.new(target), Config.TokenTweenSpeed, "MeteorImpact", standingField() == field)
    if not moved then
        Runtime.Digging = false
        removeMeteor(meteor)
        return finish(false)
    end

    -- Match the source timing: be on the impact point from 60% of Delay+Dur
    -- until the meteor expires. Dig while waiting instead of standing idle.
    while Runtime.Running and Config.Enabled and Config.AutoMeteor and os.clock() < meteor.ReadyAt do
        remoteCall("ToolCollect")
        task.wait(0.08)
    end
    while Runtime.Running and Config.Enabled and Config.AutoMeteor and os.clock() <= meteor.ExpireAt do
        local _, humanoid, root = getCharacter(1)
        if humanoid and root and (root.Position - target).Magnitude > 4 then humanoid:MoveTo(target) end
        remoteCall("ToolCollect")
        RunService.Heartbeat:Wait()
    end
    removeMeteor(meteor)
    pruneQueue()

    -- Meteor remains in the locked field: ignore other fields and handle same-field
    -- impacts on the very next tick instead of tweening by global ReadyAt.
    if firstMeteorInField(field.Name) then
        Runtime.Digging = false
        return finish(true)
    end

    -- No markers left in field: walk-collect tokens. If another field waits, keep only
    -- a short grace window; with an empty queue keep the full MeteorStayTime to
    -- gather tokens and catch late same-field events.
    local otherFieldWaiting = #Runtime.MeteorQueue > 0
    local stayTime = otherFieldWaiting
        and math.max(0.25, tonumber(Config.MeteorFieldGraceTime) or 1.25)
        or math.max(0.5, tonumber(Config.MeteorStayTime) or 9)
    local tokenDeadline = os.clock() + stayTime
    local otherFieldDeadline = otherFieldWaiting and tokenDeadline or nil
    setStatus("Auto meteor", string.format("Lock field %s | walking to collect tokens", field.Name))
    while Runtime.Running and Config.Enabled and Config.AutoMeteor and os.clock() < tokenDeadline do
        pruneQueue()
        if firstMeteorInField(field.Name) then break end
        -- If the queue was empty but another field gets a meteor, do not hold
        -- the old field for 9s: pull the deadline back to the grace window to catch the next.
        if #Runtime.MeteorQueue > 0 and not otherFieldDeadline then
            otherFieldDeadline = os.clock()
                + math.max(0.25, tonumber(Config.MeteorFieldGraceTime) or 1.25)
            tokenDeadline = math.min(tokenDeadline, otherFieldDeadline)
        end
        if standingField() ~= field then break end
        local token = findBestTokenInStandingField()
        if token then
            collectToken(token, "MeteorToken")
        else
            task.wait(0.08)
        end
    end

    -- Only drop the lock when the field truly has no meteors. Events arriving while
    -- collecting tokens keep the lock and outrank every other field.
    pruneQueue()
    if not firstMeteorInField(field.Name) then Runtime.MeteorLockedField = "" end
    Runtime.Digging = false
    return finish(true)
end

-- Event-driven priority supervisor. The normal progression loop may be inside a
-- long quest/material/convert operation, so polling only at the end of that loop
-- can miss an impact. This worker cancels the current mover immediately and is
-- the only worker allowed to acquire MeteorHandling.
task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and Config.AutoMeteor and #Runtime.MeteorQueue > 0 then
            Runtime.MeteorPriorityActive = true
            if not Runtime.MeteorHandling then
                cancelMovement()
                local ok, err = xpcall(handleMeteor, debug.traceback)
                if not ok then
                    Runtime.MeteorHandling = false
                    Runtime.MeteorPriorityActive = #Runtime.MeteorQueue > 0
                    Runtime.MeteorLockedField = ""
                    Runtime.Digging = false
                    cancelMovement()
                    reportError("MeteorPriority", err)
                end
            end
        elseif not Config.AutoMeteor or #Runtime.MeteorQueue == 0 then
            Runtime.MeteorPriorityActive = false
        end
        -- CPU saver: poll fast (0.03s) only with active meteors; with an empty queue
        -- 0.2s suffices since meteors arrive via LocalFX events, not polling.
        task.wait(#Runtime.MeteorQueue > 0 and 0.03 or 0.2)
    end
end)

local function applyLowGraphics(enabled)
    Config.LowGraphics = enabled
    if not enabled then return end

    local beeRoots = {Bees = true, NPCBees = true}
    local tokenRoots = {Collectibles = true}
    local flowerRoots = {Flowers = true}
    local hiveRoots = {Honeycombs = true, HivePlatforms = true}
    local decorationRoots = {Decorations = true, Decor = true, Decoratives = true}
    local decorationPropNames = {pineapple = true, ["giant pineapple"] = true, ["pineapple decoration"] = true}
    local weatherRoots = {Particles = true, Effects = true, Clouds = true, Weather = true}

    local function visualGroups(object)
        local beeVisual, tokenVisual, flowerVisual, hiveVisual = false, false, false, false
        local decorationVisual, weatherVisual = false, false
        local cursor = object
        while cursor and cursor ~= workspace do
            local name = cursor.Name
            if beeRoots[name] then beeVisual = true
            elseif tokenRoots[name] then tokenVisual = true
            elseif flowerRoots[name] then flowerVisual = true
            elseif hiveRoots[name] then hiveVisual = true
            elseif decorationRoots[name] then decorationVisual = true
            elseif weatherRoots[name] then weatherVisual = true end
            cursor = cursor.Parent
        end
        return beeVisual, tokenVisual, flowerVisual, hiveVisual, decorationVisual, weatherVisual
    end

    local function disposableDecoration(object)
        if not Config.FixLagDeleteDecorations then return nil end
        local cursor = object
        local insideDecorations = false
        local namedProp
        while cursor and cursor ~= workspace do
            local parent = cursor.Parent
            if cursor.Name == "Decorations" then insideDecorations = true end
            if parent and parent.Name == "Decorations" then insideDecorations = true end
            if cursor.Name == "Misc" and parent and parent.Name == "Decorations" then return cursor end
            if cursor.Name == "Decor" or cursor.Name == "Decoratives" then return cursor end
            if decorationPropNames[string.lower(cursor.Name)] then namedProp = cursor end
            cursor = parent
        end
        return insideDecorations and namedProp or nil
    end

    local function keepDisabled(object)
        if Runtime.LowGraphicsWatched[object] then return end
        Runtime.LowGraphicsWatched[object] = true
        connect(object:GetPropertyChangedSignal("Enabled"), function()
            if Runtime.Running and Config.LowGraphics and object.Parent and object.Enabled then
                object.Enabled = false
            end
        end)
    end

    local function optimizeObject(object)
        if not object or not object.Parent then return end
        local disposable = disposableDecoration(object)
        if disposable and disposable.Parent then
            -- Remove only identified local-only decor groups; never touch 30BeeZone,
            -- gate, field, shop, NPC, toy, hive or any other gameplay folder.
            disposable:Destroy()
            return
        end
        local underBees, underTokens, underFlowers, underHives, underDecorations, weatherVisual = visualGroups(object)
        local beeVisual = Config.FixLagHideBees and underBees
        local hidden = beeVisual or (Config.FixLagHideTokens and underTokens)
            or (Config.FixLagHideFlowers and underFlowers)
            or (Config.FixLagHideHives and underHives)
            or (Config.FixLagHideDecorations and underDecorations)
            or (Config.FixLagHideWeather and weatherVisual)
        local character = Player.Character
        local playerVisual = character and (object == character or object:IsDescendantOf(character))
        if object:IsA("Model") then
            if not playerVisual then pcall(function() object.LevelOfDetail = Enum.ModelLevelOfDetail.StreamingMesh end) end
        elseif object:IsA("BasePart") then
            pcall(function()
                object.CastShadow = false
                object.Reflectance = 0
                object.MaterialVariant = ""
                -- Keep the meteor marker's material so the fallback detector still
                -- recognizes the Neon part; also keeps the local character from going gray/plastic.
                if Config.FixLagPlasticMaterials and not weatherVisual and not playerVisual then
                    object.Material = Enum.Material.Plastic
                end
                if hidden then
                    -- Transparency is a client-side change; instances still exist so
                    -- token/flower/meteor scanners keep reading Position and attributes normally.
                    object.LocalTransparencyModifier = 1
                    object.Transparency = 1
                end
                if object:IsA("Part") then
                    object.TopSurface = Enum.SurfaceType.Smooth
                    object.BottomSurface = Enum.SurfaceType.Smooth
                end
            end)
            if object:IsA("MeshPart") then
                -- RenderFidelity is EDIT-ONLY: writing it at run-time is blocked
                -- by the engine for MeshParts AND SolidModels alike, printing a
                -- console warning per attempt (that warning spam stalled the
                -- script). Never touch it; texture stripping stays.
                if hidden or (Config.FixLagRemoveTextures and not playerVisual) then
                    pcall(function() object.TextureID = "" end)
                end
            end
        elseif object:IsA("SpecialMesh") then
            if Config.FixLagRemoveTextures and not playerVisual then object.TextureId = "" end
        elseif object:IsA("SurfaceAppearance") then
            if Config.FixLagRemoveTextures and not playerVisual then object:Destroy() end
        elseif object:IsA("Decal") or object:IsA("Texture") then
            if hidden or (Config.FixLagRemoveTextures and not playerVisual) then object.Transparency = 1 end
        elseif object:IsA("ParticleEmitter") then
            if Config.FixLagHideParticles then
                pcall(function()
                    object.Enabled = false
                    object.Rate = 0
                    object.Lifetime = NumberRange.new(0)
                    object:Clear()
                end)
                keepDisabled(object)
            end
        elseif object:IsA("Trail") then
            if Config.FixLagHideParticles then
                pcall(function()
                    object.Enabled = false
                    object.Lifetime = 0
                    object:Clear()
                end)
                keepDisabled(object)
            end
        elseif object:IsA("Beam") or object:IsA("Smoke") or object:IsA("Fire") or object:IsA("Sparkles") then
            if Config.FixLagHideParticles then
                object.Enabled = false
                keepDisabled(object)
            end
        elseif object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
            if Config.FixLagDisableLights then
                object.Enabled = false
                keepDisabled(object)
            end
        elseif object:IsA("Animator") and beeVisual and Config.FixLagStopBeeAnimations then
            pcall(function()
                for _, track in ipairs(object:GetPlayingAnimationTracks()) do track:Stop(0) end
            end)
            if not Runtime.LowGraphicsWatched[object] then
                Runtime.LowGraphicsWatched[object] = true
                connect(object.AnimationPlayed, function(track)
                    if Runtime.Running and Config.LowGraphics then pcall(track.Stop, track, 0) end
                end)
            end
        elseif object:IsA("Explosion") then
            pcall(function()
                object.Visible = false
                object.BlastPressure = 0
                object.BlastRadius = 0
            end)
        elseif object:IsA("BillboardGui") or object:IsA("SurfaceGui") then
            if hidden then object.Enabled = false end
        elseif object:IsA("Highlight") then
            if hidden then object.Enabled = false end
        elseif object:IsA("Sound") and hidden then
            pcall(function()
                object.Volume = 0
                object:Stop()
            end)
        elseif object:IsA("Clouds") then
            object.Enabled = false
        elseif object:IsA("Sky") and Config.FixLagHideSky then
            pcall(function()
                object.SkyboxBk, object.SkyboxDn, object.SkyboxFt = "", "", ""
                object.SkyboxLf, object.SkyboxRt, object.SkyboxUp = "", "", ""
                object.CelestialBodiesShown = false
                object.StarCount = 0
            end)
        elseif object:IsA("Atmosphere") and Config.FixLagHideSky then
            pcall(function()
                object.Color = Color3.fromRGB(120, 120, 120)
                object.Decay = Color3.fromRGB(90, 90, 90)
                object.Density = 0
                object.Glare = 0
                object.Haze = 0
            end)
        elseif object:IsA("BloomEffect") or object:IsA("BlurEffect")
            or object:IsA("DepthOfFieldEffect") or object:IsA("SunRaysEffect") then
            object.Enabled = false
        elseif object:IsA("ColorCorrectionEffect") then
            -- No gray post-processing: it tints the whole viewport and may
            -- make users think PlayerGui is hidden/grayed too.
            object.Enabled = false
        end
    end

    local function applyLightingSettings()
        pcall(function() workspace.GlobalWind = Vector3.zero end)
        pcall(function() settings().Rendering.AntiAliasing = false end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.Brightness = math.clamp(tonumber(Config.FixLagBrightness) or 0.65, 0, 3)
            Lighting.ExposureCompensation = -0.35
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.Ambient = Color3.fromRGB(85, 85, 85)
            Lighting.OutdoorAmbient = Color3.fromRGB(75, 75, 75)
            Lighting.FogColor = Color3.fromRGB(105, 105, 105)
            Lighting.FogStart = 0
            Lighting.FogEnd = 100000
            Lighting.ColorShift_Top = Color3.new(0, 0, 0)
            Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
        end)
        if sethiddenproperty then
            pcall(sethiddenproperty, Lighting, "Technology", Enum.Technology.Compatibility)
        else
            pcall(function() Lighting.Technology = Enum.Technology.Compatibility end)
        end
        if Config.FixLagHideSky then
            local oldGray = Lighting:FindFirstChild("BSSKaitunGray")
            if oldGray and oldGray:IsA("ColorCorrectionEffect") then oldGray.Enabled = false end
            local flatSky = Lighting:FindFirstChild("BSSKaitunSky")
            if not flatSky then
                flatSky = Instance.new("Sky")
                flatSky.Name = "BSSKaitunSky"
                flatSky.Parent = Lighting
            end
            pcall(function()
                flatSky.SkyboxBk, flatSky.SkyboxDn, flatSky.SkyboxFt = "", "", ""
                flatSky.SkyboxLf, flatSky.SkyboxRt, flatSky.SkyboxUp = "", "", ""
                flatSky.CelestialBodiesShown = false
                flatSky.StarCount = 0
            end)
        end
    end

    applyLightingSettings()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        pcall(function()
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.Decoration = false
        end)
        if sethiddenproperty then pcall(sethiddenproperty, terrain, "Decoration", false) end
        for _, object in ipairs(terrain:GetChildren()) do pcall(optimizeObject, object) end
    end
    local scanBatch = math.max(50, tonumber(Config.FixLagScanBatch) or 350)
    for index, object in ipairs(workspace:GetDescendants()) do
        pcall(optimizeObject, object)
        if index % scanBatch == 0 then task.wait() end
    end
    for _, object in ipairs(Lighting:GetDescendants()) do pcall(optimizeObject, object) end

    if Runtime.LowGraphicsBound then return end
    Runtime.LowGraphicsBound = true
    connect(workspace.DescendantAdded, function(object)
        if Runtime.Running and Config.LowGraphics then pcall(optimizeObject, object) end
    end)
    connect(Lighting.DescendantAdded, function(object)
        if Runtime.Running and Config.LowGraphics then pcall(optimizeObject, object) end
    end)
    -- Hide every other player: their characters + accessories + tools are one of
    -- the biggest lag sources on busy servers. Local-only hiding (render), no effect
    -- on gameplay for either side.
    if Config.FixLagHidePlayers then
        local function hideCharacter(character)
            if not character or character == Player.Character then return end
            for _, descendant in ipairs(character:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    pcall(function()
                        descendant.LocalTransparencyModifier = 1
                        descendant.CastShadow = false
                    end)
                elseif descendant:IsA("Decal") then
                    pcall(function() descendant.Transparency = 1 end)
                elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
                    pcall(function()
                        descendant.Enabled = false
                        descendant.Rate = 0
                    end)
                elseif descendant:IsA("Animator") then
                    pcall(function()
                        for _, track in ipairs(descendant:GetPlayingAnimationTracks()) do
                            track:Stop(0)
                        end
                    end)
                end
            end
        end
        local function bindPlayer(otherPlayer)
            if otherPlayer == Player then return end
            if otherPlayer.Character then hideCharacter(otherPlayer.Character) end
            connect(otherPlayer.CharacterAdded, hideCharacter)
        end
        for _, otherPlayer in ipairs(Players:GetPlayers()) do bindPlayer(otherPlayer) end
        connect(Players.PlayerAdded, bindPlayer)
    end
    task.spawn(function()
        while Runtime.Running and Config.LowGraphics do
            applyLightingSettings()
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            -- New objects are handled by DescendantAdded; do not rescan the
            -- whole workspace periodically - that rescan itself spikes on mobile.
            task.wait(12)
        end
    end)
end

-- UI -------------------------------------------------------------------------
local function create(className, properties, parent)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do instance[key] = value end
    instance.Parent = parent
    return instance
end

-- PlayerGui keeps UI callbacks in the same security context as this LocalScript.
-- Parenting to gethui/CoreGui can create "lacking capability Plugin" on button.Text.
local guiParent = Player:WaitForChild("PlayerGui")
if gethui then
    pcall(function()
        local protectedRoot = gethui()
        for _, guiName in ipairs({"BSSKaitunUI", "BSSKaitunUITop"}) do
            local protectedOld = protectedRoot and protectedRoot:FindFirstChild(guiName)
            if protectedOld then protectedOld:Destroy() end
        end
    end)
end
local oldGui = guiParent:FindFirstChild("BSSKaitunUI")
if oldGui then oldGui:Destroy() end
local oldTop = guiParent:FindFirstChild("BSSKaitunUITop")
if oldTop then oldTop:Destroy() end

-- DisplayOrder -100: the black screen sits BELOW every game GUI (menu/shop/hive
-- stay visible and clickable above the dark overlay).
local screen = create("ScreenGui", {Name = "BSSKaitunUI", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = -100}, guiParent)

-- CPU-saver UI: full-screen black overlay + a centered honey-themed card.
-- Every visual element (corners, strokes, row backgrounds, accent bars) is
-- created ONCE - the 0.5s update loop only writes .Text, so the CPU cost is
-- unchanged while the layout looks structured instead of floating text.
local THEME = {
    Accent = Color3.fromRGB(255, 200, 61),  -- honey amber
    Card = Color3.fromRGB(15, 17, 26),
    RowBg = Color3.fromRGB(24, 27, 40),
    BoxBg = Color3.fromRGB(10, 12, 18),
    Muted = Color3.fromRGB(148, 153, 170),
    Value = Color3.fromRGB(235, 238, 245),
}
-- Dimmed veil instead of solid black: a deep navy tint at partial opacity so
-- the world shows through faintly (night-mode look). 0 = opaque, 1 = invisible.
local overlay = create("Frame", {Name = "BlackScreen", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(8, 10, 16),
    BackgroundTransparency = math.clamp(tonumber(Config.BlackScreenTransparency) or 0.3, 0, 0.85),
    BorderSizePixel = 0,
    Visible = Config.BlackScreen ~= false}, screen)

local card = create("Frame", {Name = "Card",
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42),
    Size = UDim2.new(0.5, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = THEME.Card, BorderSizePixel = 0}, overlay)
create("UICorner", {CornerRadius = UDim.new(0, 14)}, card)
create("UIStroke", {Color = THEME.Accent, Thickness = 1.2, Transparency = 0.55}, card)
create("UIPadding", {PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18),
    PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20)}, card)
create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center}, card)

create("TextLabel", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
    LayoutOrder = 1, Text = "BEE KAITUN", Font = Enum.Font.GothamBold, TextSize = 30,
    TextColor3 = THEME.Accent}, card)
create("TextLabel", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
    LayoutOrder = 2, Text = "A U T O   F A R M", Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = THEME.Muted}, card)
create("Frame", {Size = UDim2.new(0.55, 0, 0, 2), BackgroundColor3 = THEME.Accent,
    BackgroundTransparency = 0.45, BorderSizePixel = 0, LayoutOrder = 3}, card)

local function infoRow(order, caption, initialText)
    local row = create("Frame", {Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = THEME.RowBg, BackgroundTransparency = 0.35,
        BorderSizePixel = 0, LayoutOrder = order}, card)
    create("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    create("TextLabel", {Size = UDim2.new(0.4, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = caption, Font = Enum.Font.GothamBold,
        TextSize = 12, TextColor3 = THEME.Muted, TextXAlignment = Enum.TextXAlignment.Left}, row)
    return create("TextLabel", {Size = UDim2.new(0.6, -12, 1, 0), Position = UDim2.new(0.4, 0, 0, 0),
        BackgroundTransparency = 1, Text = initialText, Font = Enum.Font.Gotham,
        TextSize = 14, TextColor3 = THEME.Value, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd}, row)
end

infoRow(4, "PLAYER", Player.Name)
local uptimeLabel = infoRow(5, "UPTIME", "00:00:00")
local honeyRateLabel = infoRow(6, "HONEY", "0/h")
local gearLabel = infoRow(7, "NEXT GEAR", "...")

local statusBox = create("Frame", {Size = UDim2.new(1, 0, 0, 88),
    BackgroundColor3 = THEME.BoxBg, BackgroundTransparency = 0.25,
    BorderSizePixel = 0, LayoutOrder = 8}, card)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, statusBox)
create("Frame", {Size = UDim2.new(0, 3, 1, -20), Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = THEME.Accent, BackgroundTransparency = 0.3, BorderSizePixel = 0}, statusBox)
create("TextLabel", {Size = UDim2.new(1, -34, 0, 14), Position = UDim2.new(0, 22, 0, 10),
    BackgroundTransparency = 1, Text = "STATUS", Font = Enum.Font.GothamBold, TextSize = 11,
    TextColor3 = THEME.Muted, TextXAlignment = Enum.TextXAlignment.Left}, statusBox)
local statusLabel = create("TextLabel", {Size = UDim2.new(1, -34, 1, -34), Position = UDim2.new(0, 22, 0, 26),
    BackgroundTransparency = 1, Text = "...", Font = Enum.Font.Gotham, TextSize = 14,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = THEME.Value}, statusBox)

-- Black screen toggle: on-screen button (mobile/tablet) + F7 (PC).
-- The button lives in its own top DisplayOrder ScreenGui so it is never
-- covered by game GUIs or the black screen.
local overlayVisible = Config.BlackScreen ~= false
local topScreen = create("ScreenGui", {Name = "BSSKaitunUITop", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999}, guiParent)
local toggleButton = create("TextButton", {Name = "ScreenToggle",
    Size = UDim2.fromOffset(132, 32), Position = UDim2.new(1, -144, 0, 8),
    BackgroundColor3 = Color3.fromRGB(24, 27, 40), BorderSizePixel = 0,
    Text = "", TextColor3 = Color3.fromRGB(235, 238, 245), Font = Enum.Font.GothamBold, TextSize = 13,
    AutoButtonColor = true}, topScreen)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, toggleButton)
create("UIStroke", {Color = Color3.fromRGB(255, 200, 61), Thickness = 1, Transparency = 0.5}, toggleButton)
local function setBlackScreen(visible)
    overlayVisible = visible
    Config.BlackScreen = visible
    overlay.Visible = visible
    toggleButton.Text = visible and "Dark screen: ON" or "Dark screen: OFF"
end
setBlackScreen(overlayVisible)
connect(toggleButton.MouseButton1Click, function()
    setBlackScreen(not overlayVisible)
end)
connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F7 then
        setBlackScreen(not overlayVisible)
    end
end)

Runtime.UI.Screen = screen
Runtime.UI.TopScreen = topScreen
Runtime.UI.Overlay = overlay
Runtime.UI.Status = statusLabel
Runtime.UI.Gear = gearLabel
Runtime.UI.HoneyRate = honeyRateLabel
Runtime.UI.Uptime = uptimeLabel

task.spawn(function()
    while Runtime.Running and screen.Parent do
        local elapsed = math.max(0, math.floor(os.clock() - Runtime.StartedAt))
        local ok, err = pcall(function()
            statusLabel.Text = Runtime.State
                .. (Runtime.Detail ~= "" and (" | " .. Runtime.Detail) or "")
            local gearText = Runtime.GearStatusText()
            gearLabel.Text = gearText ~= "" and gearText or "none (stage gear complete)"
            honeyRateLabel.Text = formatNumber(Runtime.HoneyPerHour()) .. "/h"
            uptimeLabel.Text = string.format("%02d:%02d:%02d",
                math.floor(elapsed / 3600), math.floor(elapsed / 60) % 60, elapsed % 60)
        end)
        if not ok then
            reportError("UI", err)
            task.wait(1)
        end
        task.wait(0.5)
    end
end)

if Config.LowGraphics then task.spawn(applyLowGraphics, true) end

-- Anti AFK
connect(Player.Idled, function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- Read-only ticket check + one Purchase remote; never owns the mover so it can
-- buy even mid farm/convert. Meteor remains absolute priority.
task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and Config.AutoBuyEventBees and not Runtime.MeteorPriorityActive then
            local ok, err = xpcall(Runtime.BuyNextEventBee, debug.traceback)
            if not ok then
                Runtime.EventBeeBusy = false
                reportError("EventBeeShop", err)
            end
        end
        task.wait(math.max(0.2, math.min(1, tonumber(Config.EventBeeCheckInterval) or 0.5)))
    end
end)

-- Auto treat worker: quest-independent, remote-only (no movement). Feeds the
-- lowest bee with stock treats (buys more within the 10% honey/h budget).
task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and Config.AutoTreatBees and not Runtime.MeteorPriorityActive then
            local ok, err = xpcall(Runtime.TreatLowestBee, debug.traceback)
            if not ok then
                Runtime.TreatBusy = false
                reportError("TreatWorker", err)
            end
        end
        task.wait(math.max(2, tonumber(Config.TreatWorkerInterval) or 5))
    end
end)

-- RJ Gifted Farmer + Star Treat (ported from the tested standalone v4) --------
-- Mechanic (remote-spy verified): ConstructHiveCellFromEgg(x, y, "RoyalJelly", 1)
-- is exactly what the game's own Auto-Jelly loop spams; one request per roll.
-- Gated on full Mountain Top gear + Bubble Mask, honey budget capped, quest
-- reserve kept. Star Treats (100% gift) go to event bees in config order -
-- event bees can ONLY be gifted that way, and they are NEVER RJ-sacrificed.
local RJ_EVENT_TYPES = {}
for _, eventEntry in ipairs(Config.EventBeeSequence or {}) do
    RJ_EVENT_TYPES[Runtime.NormalizeEventBeeName(eventEntry.Type)] = true
end

local function rjIsEventBeeType(value)
    return RJ_EVENT_TYPES[Runtime.NormalizeEventBeeName(value)] == true
end

function Runtime.RJGatePassed(quiet)
    local owned = {}
    local visited = {}
    local function scan(value, depth)
        if type(value) ~= "table" or visited[value] or depth > 6 then return end
        visited[value] = true
        for key, child in pairs(value) do
            if type(key) == "string" then owned[key] = true end
            if type(child) == "string" then owned[child] = true end
            if type(child) == "table" then scan(child, depth + 1) end
        end
    end
    scan(getStats(false), 0)
    local containers = {Player.Character, Player:FindFirstChildOfClass("Backpack")}
    for _, container in ipairs(containers) do
        if container then
            for _, object in ipairs(container:GetDescendants()) do
                if object:IsA("Tool") or object:IsA("Accessory") then
                    owned[object.Name] = true
                end
            end
        end
    end
    -- Every line needs one owned item: mask, belt, boots, collector, hive.
    local gateLines = {
        {"Bubble Mask", "Diamond Mask"},
        {"Mondo Belt Bag", "Honeycomb Belt", "Petal Belt", "Coconut Belt"},
        {"Beekeeper's Boots", "Coconut Clogs", "Gummy Boots"},
        {"Porcelain Dipper", "Petal Wand", "Tide Popper"},
        {"Porcelain Port-O-Hive", "Coconut Canister"},
    }
    for _, line in ipairs(gateLines) do
        local satisfied = false
        for _, itemName in ipairs(line) do
            if owned[itemName] then satisfied = true break end
        end
        if not satisfied then
            if not quiet and Runtime.RJLastGateReport ~= table.concat(line, "/") then
                Runtime.RJLastGateReport = table.concat(line, "/")
                setStatus("RJ Gifted gate", "Missing one of: " .. table.concat(line, " / "))
            end
            return false
        end
    end
    return true
end

local function rjDiscoverPackage()
    local shops = workspace:FindFirstChild("Shops")
    if shops then
        for _, shop in ipairs(shops:GetDescendants()) do
            if shop:IsA("BasePart") or shop:IsA("Model") then
                local itemName = string.lower(tostring(shop.Name)):gsub("%s", "")
                if itemName == "royaljelly" or itemName == "royaljellyshop" then
                    local itemType = shop:FindFirstChild("ItemType")
                    local itemCategory = shop:FindFirstChild("ItemCategory")
                    if itemType and itemCategory and itemType:IsA("ValueBase") and itemCategory:IsA("ValueBase") then
                        return {Category = tostring(itemCategory.Value), Type = tostring(itemType.Value)}
                    end
                end
            end
        end
    end
    return {Category = "Eggs", Type = "RoyalJelly"}
end

local function rjBuy()
    if Runtime.RJStock >= (tonumber(Config.RJMinStock) or 20) + (tonumber(Config.RJQuestReserve) or 5) then return end
    if Runtime.RJHoneySpent >= (tonumber(Config.RJShopHoneyBudget) or 5e9) then
        if Runtime.RJStopReason == "" then
            Runtime.RJStopReason = "budget"
            setStatus("RJ Gifted", string.format("Honey budget spent (%s) - rolling stops",
                formatNumber(Runtime.RJHoneySpent)))
        end
        return
    end
    local honey = liveCoreValue("Honey")
    if honey and honey <= 1000000 then
        setStatus("RJ Gifted", "Honey too low for RJ purchase - farming")
        return
    end
    local package = rjDiscoverPackage()
    local before = liveCoreValue("Honey") or 0
    local bought = 0
    for _, amount in ipairs({tonumber(Config.RJBuyChunk) or 100, 10, 1}) do
        local ok, result = remoteCall("ItemPackageEvent", "Purchase",
            {Category = package.Category, Type = package.Type, Amount = amount})
        if ok and type(result) ~= "string" then
            bought = amount
            break
        end
        task.wait(0.2)
    end
    task.wait(0.5)
    local after = liveCoreValue("Honey") or before
    Runtime.RJHoneySpent += math.max(0, before - after)
    if bought > 0 then
        Runtime.RJStock += bought
        setStatus("RJ Gifted", string.format("Bought %d RJ | budget %s/%s",
            bought, formatNumber(Runtime.RJHoneySpent), formatNumber(Config.RJShopHoneyBudget or 5e9)))
    else
        setStatus("RJ Gifted", "Purchase failed - retrying later")
        Runtime.RJNextBuy = os.clock() + 30
    end
end

local function rjSeedGiftedTypes()
    for _, cell in ipairs(hiveBeeCells()) do
        if cell.Gifted and not Runtime.RJGiftedTypes[cell.Type] then
            Runtime.RJGiftedTypes[cell.Type] = true
            Runtime.RJGiftedCount += 1
        end
    end
end

local function rjPickSacrifice()
    local cells = hiveBeeCells()
    local byKey = {}
    local commonFallback, anyFallback, duplicateGifted
    for _, cell in ipairs(cells) do
        byKey[cell.X .. "," .. cell.Y] = cell
        -- Event bees are NEVER sacrificed: they are only replaceable with money
        -- (tickets) and are the Star Treat targets.
        if rjIsEventBeeType(cell.Type) then continue end
        if cell.Locked then continue end
        if not cell.Gifted then
            anyFallback = anyFallback or cell
            if Runtime.IsCommonBeeType(cell.Type) then
                commonFallback = commonFallback or cell
            end
        elseif Runtime.RJGiftedTypes[cell.Type] then
            duplicateGifted = duplicateGifted or cell
        end
    end
    if Runtime.RHSacrificeKey and byKey[Runtime.RHSacrificeKey] then
        local current = byKey[Runtime.RHSacrificeKey]
        if not rjIsEventBeeType(current.Type) and not current.Locked
            and (not current.Gifted or Runtime.RJGiftedTypes[current.Type]) then
            return current
        end
    end
    local chosen = commonFallback or anyFallback or duplicateGifted
    if chosen then Runtime.RHSacrificeKey = chosen.X .. "," .. chosen.Y end
    return chosen
end

function Runtime.RJRollStep()
    if Runtime.MeteorPriorityActive then return "yield" end
    local target = tonumber(Config.RJTargetGiftedTypes) or 15
    if Runtime.RJGiftedCount >= target then
        if Runtime.RJStopReason == "" then
            Runtime.RJStopReason = "target"
            setStatus("RJ Gifted", string.format("Target reached: %d gifted types", Runtime.RJGiftedCount))
        end
        return "done"
    end
    if not Runtime.RJGatePassed() then
        task.wait(30)
        return "wait"
    end
    local sacrifice = rjPickSacrifice()
    if not sacrifice then
        setStatus("RJ Gifted", "No sacrifice cell available")
        task.wait(10)
        return "wait"
    end
    if os.clock() >= (Runtime.RJNextBuy or 0)
        and Runtime.RJStock <= (tonumber(Config.RJQuestReserve) or 5) + (tonumber(Config.RJMinStock) or 20) then
        rjBuy()
    end
    if Runtime.RJStock <= (tonumber(Config.RJQuestReserve) or 5) then
        if Runtime.RJStopReason == "budget" then return "done" end
        setStatus("RJ Gifted", "Waiting for honey to buy more RJ")
        task.wait(5)
        return "wait"
    end
    remoteCall("ConstructHiveCellFromEgg", sacrifice.X, sacrifice.Y, "RoyalJelly", 1)
    Runtime.RJStock -= 1
    Runtime.RJRollsSinceSync += 1
    Runtime.RJRollsThisCell += 1
    Runtime.RJRollsTotal += 1
    task.wait(math.max(0.01, tonumber(Config.RJRollDelay) or 0.03))
    for _, cell in ipairs(hiveBeeCells()) do
        if cell.X == sacrifice.X and cell.Y == sacrifice.Y then
            if cell.Gifted then
                if not Runtime.RJGiftedTypes[cell.Type] then
                    Runtime.RJGiftedTypes[cell.Type] = true
                    Runtime.RJGiftedCount += 1
                    Runtime.RHSacrificeKey = nil
                    setStatus("RJ Gifted", string.format("*** NEW GIFTED TYPE: %s (%d/%d) | %d rolls ***",
                        cell.Type, Runtime.RJGiftedCount, target, Runtime.RJRollsThisCell))
                else
                    setStatus("RJ Gifted", string.format("Gifted duplicate %s after %d rolls - same cell",
                        cell.Type, Runtime.RJRollsThisCell))
                end
                Runtime.RJRollsThisCell = 0
            elseif Runtime.RJRollsSinceSync >= (tonumber(Config.RJStockResyncEvery) or 25) then
                Runtime.RJRollsSinceSync = 0
                getStats(true)
                Runtime.RJStock = rawEggCount("RoyalJelly")
            end
            break
        end
    end
    return "rolling"
end

-- Star Treat worker step: first non-gifted event bee in config order gets
-- star treats until gifted; keeps going through the whole list - never stops
-- early while star treats remain and a target is missing.
local function starTreatPendingCount()
    local cells = hiveBeeCells()
    local pending = 0
    for _, beeName in ipairs(Config.StarTreatOrder or {"Tabby", "Photon", "Cobalt", "Crimson"}) do
        local wanted = Runtime.NormalizeEventBeeName(beeName)
        for _, cell in ipairs(cells) do
            if not cell.Locked and Runtime.NormalizeEventBeeName(cell.Type) == wanted and not cell.Gifted then
                pending += 1
                break
            end
        end
    end
    return pending
end

-- Buy one Star Treat from the Ticket Tent with tickets. The package is read
-- from the replicated shop item (ItemType/ItemCategory StringValues, same as
-- every other shop) so the real Category/Type is used instead of a guess.
local function buyStarTreat()
    local package
    local shops = workspace:FindFirstChild("Shops")
    if shops then
        for _, shop in ipairs(shops:GetDescendants()) do
            if shop:IsA("BasePart") or shop:IsA("Model") then
                if Runtime.NormalizeEventBeeName(shop.Name) == "startreat" then
                    local itemType = shop:FindFirstChild("ItemType")
                    local itemCategory = shop:FindFirstChild("ItemCategory")
                    if itemType and itemCategory and itemType:IsA("ValueBase") and itemCategory:IsA("ValueBase") then
                        package = {Category = tostring(itemCategory.Value), Type = tostring(itemType.Value)}
                    end
                    break
                end
            end
        end
    end
    package = package or {Category = "Treats", Type = "StarTreat"}
    local ok = remoteCall("ItemPackageEvent", "Purchase",
        {Category = package.Category, Type = package.Type, Amount = 1})
    if ok then
        task.defer(function() getStats(true) end)
        setStatus("Star Treat", "Bought Star Treat from Ticket Tent")
        return true
    end
    Runtime.StarTreatRetryAt = os.clock() + 60
    setStatus("Star Treat", string.format("Star Treat purchase failed (%s/%s) - retry in 60s",
        tostring(package.Category), tostring(package.Type)))
    return false
end

function Runtime.StarTreatStep()
    if not Config.AutoStarTreat then return "off" end
    if os.clock() < (Runtime.StarTreatRetryAt or 0) then return "cooldown" end
    -- Nothing to gift: stay SILENT so this worker never overwrites the status
    -- of active systems (farm/RJ/treat).
    if starTreatPendingCount() <= 0 then return "done" end
    local stats = getStats(false)
    local starTreats
    local visited = {}
    local function findTreat(value, depth)
        if starTreats or type(value) ~= "table" or visited[value] or depth > 4 then return end
        visited[value] = true
        for key, child in pairs(value) do
            if key == "StarTreat" and tonumber(child) then starTreats = tonumber(child) return end
            if type(child) == "table" then findTreat(child, depth + 1) end
        end
    end
    findTreat(stats, 0)
    starTreats = math.floor(starTreats or 0)
    if starTreats <= 0 then
        -- Empty stock: Mother Bear quests deliver them passively, but spare
        -- tickets can buy one right away once the bee-egg queue is finished
        -- (bees outrank gifting for tickets).
        local pending = starTreatPendingCount()
        if pending > 0 and Config.AutoBuyStarTreat
            and (type(Runtime.NextEventBee) ~= "function" or Runtime.NextEventBee(false) == nil) then
            local tickets = Runtime.TicketCount(stats)
            local cost = math.max(1, tonumber(Config.StarTreatTicketCost) or 1000)
            if tickets >= cost then
                if buyStarTreat() then
                    task.wait(1.5)
                    return "bought"
                end
                return "wait"
            end
            setStatus("Star Treat", string.format("Saving tickets: %s/%s (%d event bee(s) waiting)",
                formatNumber(tickets), formatNumber(cost), pending))
        elseif pending > 0 then
            setStatus("Star Treat", "No Star Treat - waiting for Mother Bear quest rewards")
        end
        return "wait"
    end
    local cells = hiveBeeCells()
    for _, beeName in ipairs(Config.StarTreatOrder or {"Tabby", "Photon", "Cobalt", "Crimson"}) do
        local wanted = Runtime.NormalizeEventBeeName(beeName)
        for _, cell in ipairs(cells) do
            if not cell.Locked and Runtime.NormalizeEventBeeName(cell.Type) == wanted and not cell.Gifted then
                setStatus("Star Treat", string.format("Using on %s (%d,%d) | stock %d",
                    cell.Type, cell.X, cell.Y, starTreats))
                local ok = remoteCall("ConstructHiveCellFromEgg", cell.X, cell.Y, "StarTreat", 1)
                if ok then
                    Runtime.StarTreatsUsed += 1
                    task.wait(1)
                    for _, fresh in ipairs(hiveBeeCells()) do
                        if fresh.X == cell.X and fresh.Y == cell.Y and fresh.Gifted then
                            setStatus("Star Treat", string.format("*** %s is now GIFTED ***", fresh.Type))
                            break
                        end
                    end
                    return "used"
                end
                -- Wrong remote signature or server refusal: back off so the
                -- worker never spams rejected calls.
                Runtime.StarTreatRetryAt = os.clock() + 60
                setStatus("Star Treat", "Remote rejected StarTreat - retry in 60s")
                return "reject"
            end
        end
    end
    return "done" -- all event bees gifted (or none owned): silent
end

-- Auto RJ on NON-GIFTED BASIC bees only: Royal Jelly never rolls commons, so
-- every use upgrades a Basic into a Rare+ roll (1/250 gifts it). Basics carry
-- no useful token, other commons keep theirs. Quest jelly keeps its reserve;
-- when stock runs short the worker stands down (other work continues) and
-- re-checks every 60s; the RJ Gifted Farmer takes over once its gate passes.
function Runtime.RJUpgradeBasicStep()
    if Runtime.MeteorPriorityActive then return end
    -- Hand-off: once the RJ Gifted Farmer is gated in, it owns all RJ spending.
    if Config.AutoRJGiftedFarm and os.clock() >= (Runtime.RJGateCheckAt or 0) then
        Runtime.RJGateCheckAt = os.clock() + 120
        Runtime.RJGateActive = Runtime.RJGatePassed(true)
    end
    if Config.AutoRJGiftedFarm and Runtime.RJGateActive then return end
    local reserve = math.max(1, tonumber(Config.RJQuestReserve) or 5)
    if Runtime.RJUpgradeStock == nil or Runtime.RJUpgradeStock <= reserve
        or (Runtime.RJUpgradeSyncs or 0) >= 20 then
        Runtime.RJUpgradeSyncs = 0
        getStats(true)
        Runtime.RJUpgradeStock = rawEggCount("RoyalJelly")
    end
    if Runtime.RJUpgradeStock <= reserve then
        -- Not enough above the quest reserve: stand down, remember, re-check.
        Runtime.RJUpgradeRetryAt = os.clock() + 60
        return
    end
    for _, cell in ipairs(hiveBeeCells()) do
        if not cell.Locked and not cell.Gifted
            and Runtime.NormalizeEventBeeName(cell.Type) == "basic" then
            remoteCall("ConstructHiveCellFromEgg", cell.X, cell.Y, "RoyalJelly", 1)
            Runtime.RJUpgradeStock -= 1
            Runtime.RJUpgradeSyncs = (Runtime.RJUpgradeSyncs or 0) + 1
            setStatus("RJ upgrade", string.format("Royal Jelly on %s (%d,%d) | stock %d",
                cell.Type, cell.X, cell.Y, Runtime.RJUpgradeStock))
            task.wait(0.3)
            return
        end
    end
    -- No non-gifted Basic left: STOP entirely (per request). A script restart
    -- re-arms the worker.
    Runtime.RJUpgradeExhausted = true
    setStatus("RJ upgrade", "No non-gifted Basic bee left - stopped")
    warn("[BSS Kaitun] RJ upgrade stopped: no non-gifted Basic bees in hive")
end

-- Two dedicated workers: the RJ roll loop keeps the tested standalone pace
-- (one request per roll, tiny yield), while Star Treat fires at most once per
-- 3s pass. Both yield to Meteor immediately and never stop until done.
task.spawn(function()
    task.wait(5) -- let bootstrap stats land first
    rjSeedGiftedTypes()
    while Runtime.Running do
        local result = "off"
        if Config.Enabled and not Runtime.MeteorPriorityActive and Config.AutoRJGiftedFarm then
            local ok, err = xpcall(function() result = Runtime.RJRollStep() end, debug.traceback)
            if not ok then
                reportError("RJGifted", err)
                task.wait(3)
            end
        end
        if result == "done" then
            task.wait(30)
        elseif result ~= "rolling" then
            task.wait(2)
        end
    end
end)

task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and not Runtime.MeteorPriorityActive then
            local ok, err = xpcall(Runtime.StarTreatStep, debug.traceback)
            if not ok then reportError("StarTreat", err) end
        end
        task.wait(3)
    end
end)

-- Quest feed/jelly worker: the instant tasks are remote-only, so they run
-- OFF-THREAD - the farm mover never pauses for inventory checks. Uses cached
-- stats (no blocking remote per pass); over-reading stock is harmless because
-- the server caps consumption to what is actually owned. Remembered deficits
-- (missing food) unlock EARLY the moment enough food arrives from farming.
task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and Config.AutoQuest and not Runtime.MeteorPriorityActive then
            -- Light pacing: at most ONE feed/jelly use per interval, so Mother
            -- progresses steadily while field quests and farming dominate.
            local interval = math.max(3, tonumber(Config.MotherFeedInterval) or 10)
            if os.clock() >= (Runtime.LastMotherFeedAt or 0) + interval then
                local ok, err = xpcall(function()
                    local objectives = incompleteQuestObjectives(false)
                    local retryAt = Runtime.QuestFeedRetryAt or {}
                    local deficitMap = Runtime.QuestFeedDeficit or {}
                    -- Deficits of tasks no longer in the quest list (turned in)
                    -- are pruned.
                    local seen = {}
                    for _, objective in ipairs(objectives) do
                        seen[tostring(objective.Quest) .. "|" .. tostring(objective.Description)] = true
                    end
                    for key in pairs(deficitMap) do
                        if not seen[key] then deficitMap[key] = nil end
                    end
                    local now = os.clock()
                    for _, objective in ipairs(objectives) do
                        local kind = Runtime.QuestTaskKind(objective)
                        local taskKey = tostring(objective.Quest) .. "|" .. tostring(objective.Description)
                        if now >= (retryAt[taskKey] or 0) then
                            if kind == "jelly" and Runtime.UseQuestRoyalJelly(objective) then
                                Runtime.LastMotherFeedAt = os.clock()
                                return
                            end
                            if kind == "treat" and Runtime.FeedQuestTreats(objective) then
                                Runtime.LastMotherFeedAt = os.clock()
                                return
                            end
                        elseif deficitMap[taskKey] then
                            -- Food arrived while farming: clear the cooldown so the
                            -- next pass feeds exactly the missing amount.
                            local deficit = deficitMap[taskKey]
                            if questTreatStock(deficit.TreatKey, MaterialSystem.Stats(false)) > 0 then
                                Runtime.QuestFeedRetryAt[taskKey] = nil
                            end
                        end
                    end
                end, debug.traceback)
                if not ok then reportError("QuestFeed", err) end
            end
        end
        task.wait(5)
    end
end)

-- Auto RJ on Basic bees: one use per pass, stands down politely when the
-- stock is needed for quests or the RJ Gifted Farmer takes over. Stops when
-- the hive has no non-gifted Basic bee left, but a cheap local hive scan
-- every 5s re-arms it the moment a newly hatched Basic appears.
task.spawn(function()
    while Runtime.Running do
        if Runtime.RJUpgradeExhausted then
            -- Cheap detection pass (workspace only, zero remotes).
            for _, cell in ipairs(hiveBeeCells()) do
                if not cell.Locked and not cell.Gifted
                    and Runtime.NormalizeEventBeeName(cell.Type) == "basic" then
                    Runtime.RJUpgradeExhausted = false
                    Runtime.RJUpgradeRetryAt = 0
                    break
                end
            end
        elseif Config.Enabled and Config.AutoRJUpgradeBasic
            and not Runtime.MeteorPriorityActive
            and os.clock() >= (Runtime.RJUpgradeRetryAt or 0) then
            local ok, err = xpcall(Runtime.RJUpgradeBasicStep, debug.traceback)
            if not ok then reportError("RJUpgrade", err) end
        end
        task.wait(0.5)
    end
end)

-- BadgeEvent is a RemoteEvent, so claim one badge per pass. This avoids the
-- invocation-queue spam caused by firing every badge in the same frame.
task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and Config.AutoClaimBadges then Runtime.ClaimNextBadge() end
        -- ClaimNextBadge already rate-limits via BadgeClaimInterval, so polling faster
        -- gains nothing; match it to cut wasted CPU loops.
        task.wait(math.max(0.5, tonumber(Config.BadgeClaimInterval) or 1.25))
    end
end)

-- Low-priority hourly rewards: Wealth Clock + free toys (Ant Pass, Blue Field
-- Booster). Never owns the mover and always yields to the Meteor supervisor.
task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and not Runtime.MeteorPriorityActive then
            if Config.AutoWealthClock then
                local ok, err = xpcall(Runtime.ClaimWealthClock, debug.traceback)
                if not ok then
                    Runtime.NextWealthClockCheck = os.clock() + math.max(5, tonumber(Config.WealthClockRetryInterval) or 60)
                    reportError("WealthClock", err)
                end
            end
            if Config.AutoFreeToys then
                local ok, err = xpcall(Runtime.ClaimFreeToys, debug.traceback)
                if not ok then
                    Runtime.NextFreeToyCheck = os.clock() + 30
                    reportError("FreeToys", err)
                end
            end
        end
        task.wait(math.max(1, math.min(15, tonumber(Config.WealthClockCheckInterval) or 15)))
    end
end)

-- Dig: ToolCollect only does anything while a collector is HELD. After a
-- rejoin the collector sits in the backpack unequipped and the remote no-ops,
-- so keep the best owned collector equipped using the game's own
-- stats.EquippedCollector tracking.
function Runtime.EnsureCollectorEquipped()
    local stats = getStats(false)
    local equipped = type(stats) == "table" and tostring(stats.EquippedCollector or "") or ""
    if equipped ~= "" then return false end
    -- Later milestones hold better collectors: keep the LAST owned match.
    local best
    for _, milestone in ipairs(Config.ProgressionMilestones or {}) do
        for _, entry in ipairs(milestone.Items or {}) do
            if entry.Category == "Collector" and entryEnabled(entry) and playerHas(entry, false) then
                best = entry
            end
        end
    end
    if not best then return false end
    remoteCall("ItemPackageEvent", "Equip",
        {Mute = true, Category = "Collector", Type = best.Type})
    setStatus("Dig", "Equipped collector: " .. tostring(best.Item))
    return true
end

task.spawn(function()
    while Runtime.Running do
        if Config.Enabled and Config.AutoFarm and (Runtime.Digging or Runtime.State == "Auto meteor") then
            if os.clock() >= (Runtime.NextCollectorEquipCheck or 0) then
                Runtime.NextCollectorEquipCheck = os.clock() + 10
                pcall(Runtime.EnsureCollectorEquipped)
            end
            remoteCall("ToolCollect")
        end
        task.wait(math.max(0.08, Config.DigInterval))
    end
end)

function Runtime.IsBlueBeeType(value)
    local normalized = string.lower(tostring(value or "")):gsub("[^%w]", ""):gsub("bee$", "")
    for _, beeName in ipairs(Config.BlueBeeTypes or {}) do
        local wanted = string.lower(tostring(beeName)):gsub("[^%w]", ""):gsub("bee$", "")
        if normalized == wanted then return true end
    end
    return false
end

function Runtime.BlueDiscoveryCount(refresh)
    local stats = getStats(refresh == true)
    local discovered = type(stats) == "table" and stats.DiscoveredBees or nil
    if type(discovered) ~= "table" then return 0, {} end
    local found, visited = {}, {}
    local function normalize(value)
        return string.lower(tostring(value or "")):gsub("[^%w]", ""):gsub("bee$", "")
    end
    local function mark(value)
        if Runtime.IsBlueBeeType(value) then found[normalize(value)] = true end
    end
    local function scan(key, value)
        if type(key) == "string" and value ~= false and value ~= 0 then mark(key) end
        if type(value) == "string" then
            mark(value)
        elseif type(value) == "table" and not visited[value] then
            visited[value] = true
            mark(value.Type or value.BeeType or value.Name)
            for childKey, child in pairs(value) do scan(childKey, child) end
        end
    end
    scan(nil, discovered)
    local count = 0
    for _ in pairs(found) do count += 1 end
    return count, found
end

function Runtime.IsMythicBeeType(value)
    local normalized = string.lower(tostring(value or "")):gsub("[^%w]", ""):gsub("bee$", "")
    for _, beeName in ipairs(Config.MythicBeeTypes or {}) do
        local wanted = string.lower(tostring(beeName)):gsub("[^%w]", ""):gsub("bee$", "")
        if normalized == wanted then return true end
    end
    return false
end

function Runtime.MythicDiscoveryCount(refresh)
    local stats = getStats(refresh == true)
    local discovered = type(stats) == "table" and stats.DiscoveredBees or nil
    if type(discovered) ~= "table" then return 0, {} end
    local found, visited = {}, {}
    local function normalize(value)
        return string.lower(tostring(value or "")):gsub("[^%w]", ""):gsub("bee$", "")
    end
    local function mark(value)
        if Runtime.IsMythicBeeType(value) then found[normalize(value)] = true end
    end
    local function scan(key, value)
        if type(key) == "string" and value ~= false and value ~= 0 then mark(key) end
        if type(value) == "string" then
            mark(value)
        elseif type(value) == "table" and not visited[value] then
            visited[value] = true
            mark(value.Type or value.BeeType or value.Name)
            for childKey, child in pairs(value) do scan(childKey, child) end
        end
    end
    scan(nil, discovered)
    local count = 0
    for _ in pairs(found) do count += 1 end
    return count, found
end

function Runtime.FindSafeBasicBeeCell()
    local reference = Player:FindFirstChild("Honeycomb")
    local hive = reference and reference:IsA("ObjectValue") and reference.Value
    local cells = hive and hive:FindFirstChild("Cells")
    if not cells then return nil end
    for _, cell in ipairs(cells:GetChildren()) do
        local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
        local locked = cell:FindFirstChild("CellLocked")
        local x, y = cell.Name:match("^C(%d+),(%d+)$")
        if x and y and cellType and cellType:IsA("ValueBase")
            and tostring(cellType.Value) == "BasicBee" and not cell:FindFirstChild("GiftedCell")
            and (not locked or not locked:IsA("ValueBase") or locked.Value == false) then
            return cell, tonumber(x), tonumber(y)
        end
    end
    return nil
end

function Runtime.UnlockBlueHQ()
    local required = math.max(1, tonumber(Config.BlueHQRequiredDiscoveries) or 4)
    if not Config.AutoUnlockBlueHQ then return false, "disabled" end
    if Runtime.BlueDiscoveryCount(false) >= required then
        Runtime.BlueJellyCell = nil
        return true, "unlocked"
    end
    local interval = math.max(0.5, tonumber(Config.BlueJellyCheckInterval) or 1)
    if Runtime.BlueJellyBusy or os.clock() - Runtime.LastBlueJellyCheck < interval then
        return false, "cooldown"
    end
    Runtime.LastBlueJellyCheck = os.clock()
    Runtime.BlueJellyBusy = true
    local completed, unlocked, reason = xpcall(function()
        local cell = Runtime.BlueJellyCell
        local x, y
        if cell and cell.Parent then
            x, y = cell.Name:match("^C(%d+),(%d+)$")
            x, y = tonumber(x), tonumber(y)
        end
        if not cell or not cell.Parent or not x or not y then
            cell, x, y = Runtime.FindSafeBasicBeeCell()
            Runtime.BlueJellyCell = cell
        end
        if not cell then
            setStatus("Unlock Blue HQ", "Waiting for a safe Basic Bee for Royal Jelly")
            return false, "no_basic"
        end
        local locked = cell:FindFirstChild("CellLocked")
        if cell:FindFirstChild("GiftedCell")
            or (locked and locked:IsA("ValueBase") and locked.Value == true) then
            Runtime.BlueJellyCell = nil
            return false, "protected_cell"
        end
        local cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
        if cellType and Runtime.IsBlueBeeType(cellType.Value) then
            Runtime.BlueJellyCell = nil
            return true, "blue_found"
        end

        local stats = MaterialSystem.Stats(true)
        local jelly = math.floor(MaterialSystem.Amount("RoyalJelly", stats))
        if jelly <= 0 then
            setStatus("Unlock Blue HQ", "Out of Royal Jelly - wait for token/quest rewards")
            return false, "no_jelly"
        end
        local beforeBlue = Runtime.BlueDiscoveryCount(false)
        local maxRolls = math.min(jelly, math.max(1, tonumber(Config.BlueJellyRollsPerPass) or 8))
        for roll = 1, maxRolls do
            if not Runtime.Running or not cell.Parent then return false, "stopped" end
            if Runtime.MeteorPriorityActive then return false, "meteor" end
            if cell:FindFirstChild("GiftedCell") then
                Runtime.BlueJellyCell = nil
                return false, "gifted_protected"
            end
            cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
            local oldType = cellType and tostring(cellType.Value) or ""
            setStatus("Unlock Blue HQ", string.format("Blue discovered %d/%d | RJ roll %d/%d",
                beforeBlue, required, roll, maxRolls))
            local ok, remaining, success, honeycomb, discoveredBees, eggUses = remoteCall(
                "ConstructHiveCellFromEgg", x, y, "RoyalJelly", 1, false
            )
            if not ok then return false, "remote_failed" end
            applyHatchResponse("RoyalJelly", remaining, success, honeycomb, discoveredBees, eggUses)
            Runtime.BlueJellyRolls += 1
            task.wait(math.max(0.08, tonumber(Config.BlueJellyRollDelay) or 0.2))
            cellType = cell:FindFirstChild("CellType") or cell:FindFirstChild("BeeType")
            local currentType = cellType and tostring(cellType.Value) or ""
            local blueCount = Runtime.BlueDiscoveryCount(false)
            if Runtime.IsBlueBeeType(currentType) or blueCount > beforeBlue or blueCount >= required then
                Runtime.BlueJellyCell = nil
                task.defer(function() getStats(true) end)
                return true, "blue_found"
            end
            if success ~= true and currentType == oldType then return false, "server_rejected" end
        end
        task.defer(function() getStats(true) end)
        return false, "pass_complete"
    end, debug.traceback)
    Runtime.BlueJellyBusy = false
    if not completed then
        reportError("BlueHQJelly", unlocked)
        return false, "error"
    end
    return unlocked, reason
end

local function entryEnabled(entry)
    if entry.NonMacroOnly and Config.MacroMode then return false end
    if entry.MacroOnly and not Config.MacroMode then return false end
    return true
end

local function nextOutstandingMaterialEntry(includeOptional)
    local stats = MaterialSystem.Stats(false)
    for _, milestone in ipairs(Config.ProgressionMilestones or {}) do
        for _, entry in ipairs(milestone.Items or {}) do
            if entryEnabled(entry) and entry.RequiresMaterials
                and (includeOptional or not entry.Optional) and not playerHas(entry, false) then
                local deficits = MaterialSystem.Deficits(entry, stats)
                if next(deficits) then return entry, deficits end
            end
        end
    end
    return nil
end

local function deferItem(entry, reason)
    Runtime.DeferredItems[entry.Type] = reason
end

local function upgradeSprinkler()
    if not Config.AutoBuySprinklers then return false end
    if Runtime.MeteorPriorityActive then return false end
    if beeCount() < Config.MinSprinklerBees then return false end
    local upgraded = false
    for _, entry in ipairs(Config.SprinklerSequence) do
        if playerHas(entry, false) then
            Runtime.DeferredItems[entry.Type] = nil
            if not Runtime.CompletedGear[entry.Type] then
                Runtime.CompletedGear[entry.Type] = true
                task.spawn(function() remoteCall("ItemPackageEvent", "Equip", getPackage(entry)) end)
            end
        else
            local readiness = packageReadiness(entry)
            if readiness == "ready" or readiness == "unknown" then
                setStatus("Upgrading sprinkler", entry.Item)
                if purchaseAndEquip(entry) then
                    Runtime.DeferredItems[entry.Type] = nil
                    upgraded = true
                else
                    deferItem(entry, readiness)
                    return upgraded
                end
            else
                deferItem(entry, readiness)
                return upgraded
            end
        end
    end
    return upgraded
end

local function milestoneHasMissingRequiredGear(milestone)
    for _, entry in ipairs(milestone.Items or {}) do
        if entryEnabled(entry) and not entry.Optional and not playerHas(entry, false) then
            local deferred = Runtime.DeferredItems[entry.Type]
            if deferred ~= "locked" then return true end
        end
    end
    return false
end

local function nextMilestone(count)
    for _, milestone in ipairs(Config.ProgressionMilestones) do
        local target = tonumber(milestone.TargetBees) or math.huge
        -- Accounts that already have many bees must still backfill old mandatory gear in
        -- slide order; higher gear in SupersededBy counts as satisfied.
        if milestoneHasMissingRequiredGear(milestone) or count < target then return milestone end
    end
    return nil
end

local function retryDeferredItems()
    if Runtime.MeteorPriorityActive then return end
    if os.clock() - Runtime.LastDeferredRetry < Config.DeferredRetryInterval then return end
    Runtime.LastDeferredRetry = os.clock()
    local purchaseAttempts = 0
    for _, milestone in ipairs(Config.ProgressionMilestones) do
        for _, entry in ipairs(milestone.Items or {}) do
            if Runtime.DeferredItems[entry.Type] and entryEnabled(entry) then
                if playerHas(entry, false) then
                    Runtime.DeferredItems[entry.Type] = nil
                else
                    local readiness = packageReadiness(entry)
                    if readiness == "ready" or readiness == "probe" then
                        purchaseAttempts += 1
                        setStatus("Retry progression", entry.Item)
                        if purchaseAndEquip(entry) then
                            Runtime.DeferredItems[entry.Type] = nil
                        else
                            local after = packageReadiness(entry)
                            if not okPackages then
                                Runtime.DeferredItems[entry.Type] = entry.RequiresMaterials and "material" or "locked"
                            else
                                Runtime.DeferredItems[entry.Type] = after == "probe" and "material" or after
                            end
                        end
                        if purchaseAttempts >= Config.MaxDeferredPurchasesPerPass then return end
                    else
                        Runtime.DeferredItems[entry.Type] = readiness
                    end
                end
            end
        end
    end
end

local function processMilestone(milestone, fastRetry)
    if Runtime.MeteorPriorityActive then return false, nil, "meteor", 0.05 end
    local count = beeCount()
    local target = tonumber(milestone.TargetBees) or count + 1
    Runtime.ProgressStage = string.format("%d -> %d bees | gear order", count, target)
    for _, entry in ipairs(milestone.Items or {}) do
        if entryEnabled(entry) then
            if playerHas(entry, false) then
                Runtime.DeferredItems[entry.Type] = nil
            else
                if entry.Type == "Bubble Wand" and Config.AutoUnlockBlueHQ
                    and Runtime.BlueDiscoveryCount(false) < (tonumber(Config.BlueHQRequiredDiscoveries) or 4) then
                    Runtime.UnlockBlueHQ()
                end
                if Config.AutoMaterials and entry.RequiresMaterials then
                    local stats = MaterialSystem.Stats(os.clock() - Runtime.LastMaterialStats >= Config.MaterialStatsInterval)
                    local deficits = MaterialSystem.Deficits(entry, stats)
                    if next(deficits) then
                        if not MaterialSystem.HasGatherableMaterial(deficits) then
                            -- Every source is locked at this hive size (e.g.
                            -- Pineapples before 10 bees): defer without blocking
                            -- so hive growth (eggs) continues. Resumed
                            -- automatically once a source field unlocks.
                            deferItem(entry, "locked")
                            continue
                        end
                        deferItem(entry, "material")
                        if not entry.Optional then return false, entry, "material" end
                        continue
                    end
                end
                local readiness = packageReadiness(entry)
                if readiness == "locked" then
                    if fastRetry and not entry.Optional then return false, entry, readiness end
                    deferItem(entry, readiness)
                elseif readiness == "material" then
                    deferItem(entry, readiness)
                    if not entry.Optional then return false, entry, readiness end
                elseif readiness == "honey" and not entry.Optional then
                    Runtime.SetNextGearTarget(entry)
                    return false, entry, "honey"
                elseif readiness == "honey" then
                    Runtime.SetNextGearTarget(entry)
                    deferItem(entry, readiness)
                else
                    setStatus("Progression gear", entry.Item)
                    local purchased, purchaseReason, retryDelay = purchaseAndEquip(entry, fastRetry)
                    if purchased then
                        Runtime.DeferredItems[entry.Type] = nil
                        Runtime.ClearNextGearTarget()
                    else
                        local after = packageReadiness(entry)
                        if fastRetry and not entry.Optional then
                            Runtime.SetNextGearTarget(entry)
                            return false, entry, purchaseReason or after, retryDelay
                        elseif not okPackages then
                            -- Mobile fallback cannot distinguish a server gate from
                            -- missing materials. Defer and continue hive growth.
                            deferItem(entry, entry.RequiresMaterials and "material" or "locked")
                        elseif entry.Optional or after == "locked" or after == "material" or after == "probe" then
                            -- A crafted item probed without ItemPackages must never
                            -- freeze hive growth. Retry it later after more materials.
                            deferItem(entry, after == "probe" and "material" or after)
                        else
                            return false, entry, purchaseReason or after, retryDelay
                        end
                    end
                end
            end
        end
    end
    return true
end

local function progressionWork(reason, allowSideJobs)
    if not Config.Enabled then
        setStatus("Paused", "Set Enabled=true in config")
        task.wait(0.5)
        return
    end
    -- A detected meteor outranks conversion, quests, purchases and farming.
    if Config.AutoMeteor and (Runtime.MeteorPriorityActive or #Runtime.MeteorQueue > 0) then
        task.wait(0.05)
        return
    end
    if allowSideJobs == nil then allowSideJobs = Runtime.BootstrapComplete end
    if allowSideJobs then
        triggerMeteorIfReady()
        if Config.AutoMeteor and (Runtime.MeteorPriorityActive or #Runtime.MeteorQueue > 0) then
            -- The dedicated supervisor owns the mover and handles the queue.
            task.wait(0.05)
            return
        end
        if Config.AutoFarmFireflies and Runtime.FireflyPending and MaterialSystem.FarmFirefly() then return end
        if Config.AutoFarmSprouts and Runtime.SproutPending and MaterialSystem.FarmSprout() then return end
        if Config.AutoFarmMondoChick and Runtime.MondoChickPending
            and os.clock() >= (Runtime.MondoChickRetryAt or 0)
            and Runtime.FarmMondoChick() then return end
        if Config.AutoFarmViciousAlways and Runtime.ViciousPending
            and os.clock() >= (Runtime.ViciousRetryAt or 0) then
            local ok, result = xpcall(Runtime.FarmViciousAlways, debug.traceback)
            if not ok then
                Runtime.ViciousBusy = false
                reportError("ViciousAlways", result)
            elseif result then
                return
            end
        end
    end
    local ratio = pollenRatio()
    if Config.AutoConvert and ratio >= Config.ConvertPercent then
        convertPollen()
        return
    end
    if allowSideJobs then
        if Config.AutoQuest and maintainBearQuests() then return end
        if os.clock() - Runtime.LastSpecialEffectFarm >= Config.SpecialEffectPriorityInterval and farmFlowerEffect() then
            Runtime.LastSpecialEffectFarm = os.clock()
            return
        end
        if Config.AutoQuest and questWork(Config.QuestFarmSeconds) then return end
    end
    if Config.AutoFarm then
        setStatus("Farm progression", reason or "Saving honey for gear/egg/hive slot")
        -- Short bursts: quest turn-ins, conversions and affordable-gear purchases
        -- are re-evaluated between bursts instead of after one long 10s block.
        farmStep(math.max(2, tonumber(Config.FarmBurstSeconds) or 5))
    else
        setStatus("Progression waiting", "Enable Auto Farm or add resources")
        task.wait(1)
    end
end

local function progression()
    -- Map rewards first: sweep the reward spots before claiming hive/hatching.
    -- Rewards are world pickups needing no hive; an error in this phase never
    -- blocks the main progression flow.
    do
        local okReward, errReward = pcall(Runtime.CollectWorldRewards)
        if not okReward then reportError("TeleRewards", errReward) end
    end
    while Runtime.Running and not claimHive() do
        setStatus("Init", "Hive not claimed yet - retrying")
        task.wait(Config.RetryDelay)
    end
    if not Runtime.Running then return false end

    redeemCodes()

    -- A fresh account must have a bee before any gear honey grind is possible.
    -- Required opening order: ClaimHive -> redeem material codes -> hatch now.
    while Runtime.Running and beeCount() <= 0 do
        Runtime.ProgressStage = "First bee"
        if eggFundingBlocked() then
            Runtime.ProgressStage = "Saving honey for first Basic Egg"
            progressionWork("Farm honey for the first Basic Egg", false)
        else
            if Config.AutoProgression and growHiveOneBee() then break end
            setStatus("First bee", "Waiting for Basic Egg from hive or retry purchase")
            task.wait(Config.RetryDelay)
            getStats(true)
        end
    end

    -- Opening order is strict: first real bee, then starter gear. Routine side
    -- jobs stay disabled here; an actually detected meteor still preempts it.
    if Runtime.Running and Config.AutoProgression then
        local starterMilestone = Config.ProgressionMilestones[1]
        while Runtime.Running and starterMilestone do
            Runtime.ProgressStage = "Starter gear after first bee"
            local ready, blockedEntry, blockReason, retryDelay = processMilestone(starterMilestone, true)
            if ready then break end
            if blockReason == "honey" then
                progressionWork("Saving honey for " .. tostring(blockedEntry and blockedEntry.Item or "starter gear"), false)
            else
                setStatus("Retry starter shop", tostring(blockedEntry and blockedEntry.Item or "starter gear")
                    .. " | " .. tostring(blockReason or "waiting for server"))
                task.wait(math.clamp(tonumber(retryDelay) or 1, 0.5, 3))
                getStats(true)
            end
        end
    end
    Runtime.BootstrapComplete = true
    if Runtime.Running and Config.AutoQuest then
        Runtime.ProgressStage = "Starter gear done - claim quests"
        for _ = 1, #Config.QuestNPCs do
            Runtime.LastQuestCheck = -math.huge
            if not maintainBearQuests() then break end
            task.wait(0.15)
        end
    end

    while Runtime.Running do
        if Config.AutoMeteor and (Runtime.MeteorPriorityActive or #Runtime.MeteorQueue > 0) then
            task.wait(0.05)
            continue
        end
        local count = beeCount()
        if count >= Config.ProgressionTargetBees and not nextMilestone(count) then break end
        if not Config.AutoProgression then
            Runtime.ProgressStage = "Paused"
            setStatus("Progression off", "Set AutoProgression=true in config")
            task.wait(0.5)
            continue
        end
        if not Config.Enabled then
            progressionWork()
            continue
        end

        -- Right after a CONFIRMED hatch (authoritative server response) the new
        -- bee is already proven: don't block this iteration on a stats refresh.
        -- The async refresh still lands in the background.
        if os.clock() < (Runtime.SkipStatsBlockUntil or 0) then
            getStats(false)
        else
            getStats(true)
        end
        if eggFundingBlocked() then
            Runtime.ProgressStage = "Saving honey for Basic Egg"
            progressionWork("Farm honey for Basic Egg")
            continue
        end
        local milestone = nextMilestone(beeCount())
        if not milestone then Runtime.ClearNextGearTarget() end
        local ready, blockedEntry, blockReason = true, nil, nil
        if milestone then ready, blockedEntry, blockReason = processMilestone(milestone) end

        if ready then
            -- Current mandatory gear always wins. Parallel guide goals (guards and
            -- sprinklers) are retried only after that order has been satisfied.
            Runtime.ClearNextGearTarget()
            local before = beeCount()
            local eggRush = milestone and milestone.EggRushAfter and before < 25
            if eggRush then
                Runtime.ProgressStage = string.format("Egg rush %d -> 25 bees | skip side gear", before)
                setStatus("Focus Basic Egg", "Side gear paused, prioritize hatching to 25 bees")
            else
                retryDeferredItems()
                upgradeSprinkler()
            end
            if growHiveOneBee() then
                local after = beeCount()
                Runtime.ProgressStage = string.format("Hive %d/%d bees", after, Config.ProgressionTargetBees)
                if after <= before then task.wait(Config.RetryDelay) end
            else
                progressionWork("Saving honey for Basic Egg or Hive Slot")
            end
        else
            if blockReason == "material" and blockedEntry and Config.AutoMaterials then
                MaterialSystem.Work(blockedEntry)
            else
                progressionWork("Saving honey for " .. tostring(blockedEntry and blockedEntry.Item or "gear"))
            end
        end
    end

    if beeCount() >= Config.ProgressionTargetBees then
        Runtime.ProgressStage = string.format("Target reached: %d bees", beeCount())
        upgradeSprinkler()
    end
    return true
end

while Runtime.Running do
    local okProgression, progressionError = xpcall(progression, debug.traceback)
    if okProgression then break end
    reportError("Progression", progressionError)
    setStatus("Recovery progression", "Restarting after error")
    if not Runtime.MeteorHandling then cancelMovement() end
    task.wait(Config.RetryDelay)
end

-- Main state machine ----------------------------------------------------------
task.spawn(function()
    while Runtime.Running do
        local ok, err = xpcall(function()
            if not Config.Enabled then
                setStatus("Paused", "Set Enabled=true in config")
                task.wait(0.5)
                return
            end
            if not getCharacter(5) then
                setStatus("Respawning", "Waiting for character")
                task.wait(1)
                return
            end

            -- Absolute runtime priority: do not start maintenance, materials,
            -- quests or conversion while a meteor is queued/in progress.
            triggerMeteorIfReady()
            if Config.AutoMeteor and (Runtime.MeteorPriorityActive or #Runtime.MeteorQueue > 0) then
                task.wait(0.05)
                return
            end

            if Config.AutoFarmFireflies and Runtime.FireflyPending and MaterialSystem.FarmFirefly() then return end
            if Config.AutoFarmSprouts and Runtime.SproutPending and MaterialSystem.FarmSprout() then return end
            if Config.AutoFarmMondoChick and Runtime.MondoChickPending
                and os.clock() >= (Runtime.MondoChickRetryAt or 0)
                and Runtime.FarmMondoChick() then return end
            if Config.AutoFarmViciousAlways and Runtime.ViciousPending
                and os.clock() >= (Runtime.ViciousRetryAt or 0) then
                local ok, result = xpcall(Runtime.FarmViciousAlways, debug.traceback)
                if not ok then
                    Runtime.ViciousBusy = false
                    reportError("ViciousAlways", result)
                elseif result then
                    return
                end
            end

            if Config.AutoProgression and os.clock() - Runtime.LastProgressMaintenance >= 30 then
                Runtime.LastProgressMaintenance = os.clock()
                retryDeferredItems()
                upgradeSprinkler()
            end

            if Config.AutoMaterials and beeCount() >= Config.ProgressionTargetBees then
                local materialEntry = nextOutstandingMaterialEntry(true)
                if materialEntry then
                    MaterialSystem.Work(materialEntry)
                    return
                end
            end
            if Config.AutoQuest and maintainBearQuests() then return end
            local ratio = pollenRatio()
            if Config.AutoConvert and ratio >= Config.ConvertPercent then
                convertPollen()
            elseif os.clock() - Runtime.LastSpecialEffectFarm >= Config.SpecialEffectPriorityInterval and farmFlowerEffect() then
                Runtime.LastSpecialEffectFarm = os.clock()
            elseif Config.AutoQuest and questWork(Config.QuestFarmSeconds) then
                -- Quest job already used the shared mover/farmer.
            elseif Config.AutoFarm then
                farmStep(3)
            else
                setStatus("Ready", "Set AutoFarm=true in config")
                task.wait(0.5)
            end
        end, debug.traceback)
        if not ok then
            reportError("MainLoop", err)
            setStatus("Self recovery", Runtime.LastError)
            if not Runtime.MeteorHandling then cancelMovement() end
            task.wait(1)
        end
    end
end)

print("[BSS Kaitun] Loaded successfully")
