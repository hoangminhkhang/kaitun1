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
		Config.Save()
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

local Config = {}

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
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			applyFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
			applyFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

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
	UserInputService.InputChanged:Connect(function(input)
		if dragging and dragStart
			and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

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
