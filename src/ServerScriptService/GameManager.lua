local RunService = game:GetService("RunService")

local Archer     = require(game.ServerScriptService:FindFirstChild("Archer", true))
local Team       = require(script.Parent:WaitForChild("Team"))
local Constants  = require(game.ReplicatedStorage:WaitForChild("Constants"))
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

	if name == Constants.ARCHER_BUILDING_NAME then
		Archer.new(spawner.Position + Vector3.new(0,5,0), teamColor)
	elseif name == Constants.WIZARD_BUILDING_NAME then
		Wizard.new(spawner.Position + Vector3.new(0,5,0), teamColor)
	end
end

--- Initialize the heartbeat listener (call once on server startup)
function GameManager:Init()
	self._spawnTimer = 0
	
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
	self._spawnTimer += dt
	if self._spawnTimer >= Constants.SPAWN_TIME then
		self._spawnTimer -= Constants.SPAWN_TIME
		for _, baseFolder in ipairs(workspace.Bases:GetChildren()) do
			for _, building in ipairs(baseFolder.Buildings:GetChildren(true)) do
				if building:FindFirstChild("SpawnLocation") then
					ParseSpawnedObject(building, baseFolder)
				end
			end
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
