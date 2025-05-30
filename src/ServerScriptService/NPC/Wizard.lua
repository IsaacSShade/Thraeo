-- Wizard.lua
local Wizard = {}
Wizard.__index = Wizard

Wizard.entities = {}

local King              = require(game.ServerScriptService:FindFirstChild("King", true))
local Team              = require(game.ServerScriptService:FindFirstChild("Team", true))
local Config            = require(game.ReplicatedStorage:FindFirstChild("Config", true))
local BuildingPlacement = require(game.ServerScriptService:FindFirstChild("BuildingPlacement", true))
local NPC               = require(game.ServerScriptService:FindFirstChild("NPC", true))
local PathfindingService = game:GetService("PathfindingService")

-- grab all wizard stats from Config
local stats = Config.UNIT_STATS[Config.WIZARD_NAME]

-- Handles the death of a Wizard
local function OnDeath(self)
	spawn(function()
		-- ensure cleanup after cooldown period
		wait(stats.Cooldown + 1)
		Wizard.entities[self.model] = nil
		if self.model then
			self.model:Destroy()
		end
	end)
end

local function DetermineBuildingStatus(buildingName, health)
	local maxHealth = Config.BUILDING_HEALTH[buildingName]
	if health > maxHealth * 0.8 then
		return "100"
	elseif health > maxHealth * 0.5 then
		return "80"
	elseif health > maxHealth * 0.2 then
		return "50"
	elseif health > 0 then
		return "20"
	else
		return "0"
	end
end

-- Creates a new Wizard instance
function Wizard.new(position, teamColor)
	local self = setmetatable({}, Wizard)

	-- Clone & initialize model
	self.model = game.ReplicatedStorage.NPCs:FindFirstChild(Config.WIZARD_NAME):Clone()
	self.teamColor = teamColor
	self.kingGoal  = King.GetKingGoal(teamColor).model
	self.behavior  = "Spawning"

	self.model["Body Colors"].TorsoColor3 = teamColor
	self.model.PrimaryPart.CFrame = CFrame.new(position)
	self.model.Parent = workspace

	-- apply stats
	self.model.Humanoid.MaxHealth = stats.Health
	self.model.Humanoid.Health    = stats.Health

	-- hook death
	self.model.Humanoid.Died:Once(function()
		OnDeath(self)
	end)

	-- begin pathfinding
	spawn(function()
		self:FindPath()
	end)

	Wizard.entities[self.model] = self
	NPC.new(self.model, teamColor)
	return self
end

function Wizard:FindPath()
	if not self.kingGoal then
		self.kingGoal = King.GetKingGoal(self.teamColor).model
	end

	self.behavior = "Moving"

	local path = PathfindingService:CreatePath()
	path:ComputeAsync(self.model.PrimaryPart.Position, self.kingGoal.PrimaryPart.Position)

	if path.Status ~= Enum.PathStatus.Success then
		warn("Pathing failed for Wizard team "..tostring(self.teamColor))
		return
	end

	for _, waypoint in ipairs(path:GetWaypoints()) do
		self.model.Humanoid:MoveTo(waypoint.Position + Vector3.new(math.random(2),0,math.random(2)))
		self.model.Humanoid.MoveToFinished:Wait(1)

		-- scan for enemies
		local parts = workspace:GetPartBoundsInRadius(self.model.PrimaryPart.Position, stats.Range)
		for _, part in ipairs(parts) do
			-- building target
			if game.ReplicatedStorage.Buildings:FindFirstChild(part.Parent.Name) then
				local building = part.Parent
				local myTeam = Team.GetTeamFromColor(self.teamColor)
				if building.Parent.Parent ~= myTeam.base then
					spawn(function() self:FightBuilding(building) end)
					return
				end
			end

			-- player target
			if game.Players:FindFirstChild(part.Parent.Name) then
				local char = part.Parent
				local myTeam = Team.GetTeamFromColor(self.teamColor)
				if Team.GetTeamFromPlayer(game.Players:FindFirstChild(char.Name)) ~= myTeam then
					spawn(function() self:FightPlayer(char) end)
					return
				end
			end

			-- NPC target
			local npc = NPC.entities[part.Parent]
			if npc and npc.teamColor ~= self.teamColor and npc.model.Humanoid.Health > 0 then
				spawn(function() self:FightEnemy(part.Parent) end)
				return
			end
		end

		-- if dead, award killer
		if not self.model or self.model.Humanoid.Health <= 0 then
			local partsNear = workspace:GetPartBoundsInRadius(self.model.PrimaryPart.Position, stats.Range)
			for _, p in ipairs(partsNear) do
				if p.Parent:FindFirstChild("Humanoid") and p.Parent.Humanoid.Health > 0 then
					local killerTeam
					if game.Players:FindFirstChild(p.Parent.Name) then
						killerTeam = Team.GetTeamFromPlayer(game.Players:FindFirstChild(p.Parent.Name))
					else
						killerTeam = Team.GetTeamFromColor(NPC.entities[p.Parent].teamColor)
					end
					if killerTeam then
						killerTeam:AddGold(Config.KILL_REWARDS[Config.WIZARD_NAME])
					end
					break
				end
			end
		end
	end
end

function Wizard:FightEnemy(enemy)
	self.behavior = "Attacking"
	local enemyTeam = Team.GetTeamFromColor(NPC.entities[enemy].teamColor)

	while enemy.Humanoid.Health > 0 and self.model.Humanoid.Health > 0 do
		wait(stats.Cooldown)
		enemy.Humanoid.Health -= stats.Damage
	end

	if self.model.Humanoid.Health > 0 then
		spawn(function() self:FindPath() end)
	else
		enemyTeam:AddGold(Config.KILL_REWARDS[Config.WIZARD_NAME])
	end
end

function Wizard:FightBuilding(building)
	self.behavior = "Attacking"
	local buildingName  = building.Name
	local buildingHealth = building:FindFirstChild("Health")
	local buildingCFrame  = building.PrimaryPart.CFrame

	while building:FindFirstChild("Health") and self.model.Humanoid.Health > 0 do
		local pre = DetermineBuildingStatus(buildingName, buildingHealth.Value)
		buildingHealth.Value -= stats.Damage
		local post = DetermineBuildingStatus(buildingName, buildingHealth.Value)

		if pre ~= post then
			BuildingPlacement.ChangeBuildingAppearance(building, post, self.teamColor)
		end

		wait(stats.Cooldown)

		if not building:FindFirstChild("Health") then
			for _, p in ipairs(workspace:GetPartBoundsInRadius(buildingCFrame.Position, 1)) do
				if p.Parent.Name == buildingName then
					building = p.Parent
				end
			end
		end
	end

	if self.model.Humanoid.Health > 0 then
		spawn(function() self:FindPath() end)
	else
		Team.entities[building.Parent.Parent]:AddGold(Config.KILL_REWARDS[Config.WIZARD_NAME])
	end
end

function Wizard:FightPlayer(character)
	self.behavior = "Attacking"
	local enemyTeam = Team.GetTeamFromPlayer(game.Players:FindFirstChild(character.Name))
	local inRange = true

	while inRange and character.Humanoid.Health > 0 and self.model.Humanoid.Health > 0 do
		character.Humanoid.Health -= stats.Damage
		wait(stats.Cooldown)

		inRange = false
		for _, part in ipairs(workspace:GetPartBoundsInRadius(self.model.PrimaryPart.CFrame.Position, stats.Range)) do
			if part.Parent.Name == character.Name then
				inRange = true
				break
			end
		end
	end

	if self.model.Humanoid.Health > 0 then
		spawn(function() self:FindPath() end)
	else
		enemyTeam:AddGold(Config.KILL_REWARDS[Config.WIZARD_NAME])
	end
end

return Wizard
