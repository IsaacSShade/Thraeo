-- Centralized configuration for gameplay constants

local Config = {}

-- Names
Config.ARCHER_NAME             = "Archer"
Config.WIZARD_NAME             = "Wizard"
Config.KING_NAME               = "King"

Config.ARCHER_BUILDING_NAME    = "ArcherTower"
Config.WIZARD_BUILDING_NAME    = "WizardTower"
Config.KING_BUILDING_NAME      = "KingPavillion"

Config.BASE_FOUNDATION_NAME = "CastleBase"

-- 🪙 Economy
Config.STARTING_GOLD_AMOUNT = 200

Config.BUILDING_COSTS = {
	[Config.ARCHER_BUILDING_NAME] = 100,
	[Config.WIZARD_BUILDING_NAME] = 200,
}

Config.KILL_REWARDS = {
	[Config.ARCHER_NAME]          = 10,
	[Config.WIZARD_NAME]          = 15,
	[Config.ARCHER_BUILDING_NAME] = 100,
	[Config.WIZARD_BUILDING_NAME] = 150,
	[Config.KING_NAME]            = 500,
}

-- 🏰 Buildings
Config.BUILDING_HEALTH = {
	[Config.ARCHER_BUILDING_NAME] = 400,
	[Config.WIZARD_BUILDING_NAME] = 300,
}

Config.BASE_SIZE = 300
Config.BUILDING_Z_HEIGHT = 2.5 -- ground level Y-position for ghost placement

-- 🎨 Placement UI colors
Config.PLACEMENT_VALID_COLOR   = Color3.fromRGB(0, 255, 0)
Config.PLACEMENT_INVALID_COLOR = Color3.fromRGB(255, 0, 0)

-- 🧍 Unit Stats
Config.UNIT_STATS = {
	Archer = { Health = 50, Range = 30, Cooldown = 2, Damage = 10 },
	Wizard = { Health = 30, Range = 25, Cooldown = 5, Damage = 50 },
	King   = { Health = 10000, Range = 30, Cooldown = 4, Damage = 50, WatchInterval = 2 },
}

-- ⏱ Spawning / Loop Timing
Config.UNIT_SPAWN_INTERVALS = {
	[Config.ARCHER_NAME] = 5,
	[Config.WIZARD_NAME] = 8,
	-- Add other unit types here later
}
Config.PATH_RECOMPUTE_INTERVAL = 2 -- For pathfinding throttling (future)

-- 🧪 Runtime Validation
if game:GetService("RunService"):IsServer() then
	for k,v in pairs(Config.BUILDING_COSTS)    do assert(v>=0, k.." cost≥0")    end
	for k,v in pairs(Config.BUILDING_HEALTH)   do assert(v>0,  k.." health>0")  end
	for name, stats in pairs(Config.UNIT_STATS) do
		assert(stats.Health>0, name.." Health>0")
		assert(stats.Cooldown>0, name.." Cooldown>0")
	end
end

return Config