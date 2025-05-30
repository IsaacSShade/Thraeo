local RunService = game:GetService("RunService")

local Archer     = require(game.ServerScriptService:FindFirstChild("Archer", true))
local Team       = require(script.Parent:WaitForChild("Team"))
local Config  = require(game.ReplicatedStorage:WaitForChild("Config"))
local Wizard     = require(game.ServerScriptService:FindFirstChild("Wizard", true))

local GameManager = {}
GameManager.__index = GameManager

-- Configurable debug flag
GameManager.debug = false
GameManager.running = false

-- Local functions

local function ParseSpawnedObject(building, baseFolder)
	local spawner   = building:FindFirstChild("SpawnLocation")
	if not spawner then return end

	local teamColor = Team.entities[baseFolder].color
	local name      = building.Name

	if name == Config.ARCHER_BUILDING_NAME then
		Archer.new(spawner.Position + Vector3.new(0,5,0), teamColor)
	elseif name == Config.WIZARD_BUILDING_NAME then
		Wizard.new(spawner.Position + Vector3.new(0,5,0), teamColor)
	end
end

--- Initialize the heartbeat listener (call once on server startup)
function GameManager:Init()
	self._spawnTimer = 0
	self._spawnTimestamps = {} -- [building] = lastSpawnTime
	
	RunService.Heartbeat:Connect(function(dt)
		if self.running then
			if self.debug then
				warn(("[GameManager] dt=%.4f"):format(dt))
			end
			self:Step(dt)
		end
	end)
end

--- Called every frame when running
-- @param dt number delta time since last tick
function GameManager:Step(dt)
	for _, baseFolder in ipairs(workspace.Bases:GetChildren()) do
		for _, building in ipairs(baseFolder.Buildings:GetChildren(true)) do
			if building:FindFirstChild("SpawnLocation") then
				local unitType
				if building.Name == Config.ARCHER_BUILDING_NAME then
					unitType = "Archer"
				elseif building.Name == Config.WIZARD_BUILDING_NAME then
					unitType = "Wizard"
				end

				if unitType then
					local lastSpawn = self._spawnTimestamps[building] or 0
					local now = os.clock()

					if now - lastSpawn >= Config.UNIT_SPAWN_INTERVALS[unitType] then
						self._spawnTimestamps[building] = now
						ParseSpawnedObject(building, baseFolder)
					end
				end
			end
		end
	end
	
	for building, _ in pairs(self._spawnTimestamps) do
		if not building:IsDescendantOf(game) then
			self._spawnTimestamps[building] = nil
		end
	end
end

function GameManager:Start()
	self.running = true
	self._spawnTimer = 0
end

function GameManager:Stop()
	self.running = false
end

return setmetatable({}, GameManager)
