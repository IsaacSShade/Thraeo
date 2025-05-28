local Wizard = {}
Wizard.__index = Wizard

-- Constants for Wizard behavior
local HEALTH = 30
local RANGE = 25         -- Detection range for enemies
local COOLDOWN = 5       -- Cooldown time between attacks (in seconds)
local DAMAGE = 50        -- Damage dealt per attack

-- Required modules and services
local King = require(game.ServerScriptService:FindFirstChild("King", true))
local Team = require(game.ServerScriptService:FindFirstChild("Team", true))
local Constants = require(game.ReplicatedStorage:FindFirstChild("Constants", true))
local BuildingPlacement = require(game.ServerScriptService:FindFirstChild("BuildingPlacement", true))
local NPC = require(game.ServerScriptService:FindFirstChild("NPC", true))
local PathfindingService = game:GetService("PathfindingService")

-- Table to track all Wizard instances
Wizard.entities = {}

-- Handles the death of an Wizard
-- Input: wizard (table) - The Wizard instance that died
-- Output: None (cleans up and removes the Wizard from the game)
local function OnDeath(wizard)
	spawn(function()
		wait(COOLDOWN + 1) -- Wait to ensure cleanup after cooldown
		Wizard.entities[wizard.model] = nil -- Remove from the entities table
		if wizard.model then
			wizard.model:Destroy() -- Destroy the Wizard model
		end
		wizard.model = nil -- Clear the reference to the model
		wizard = nil       -- Clear the Wizard instance
	end)
end

local function DetermineBuildingStatus(buildingName, health)
	if health > Constants.BUILDING_HEALTH[buildingName] * 80 / 100 then
		return "100"
	elseif health > Constants.BUILDING_HEALTH[buildingName] * 50 / 100 then
		return "80"
	elseif health > Constants.BUILDING_HEALTH[buildingName] * 20 / 100 then
		return "50"
	elseif health > 0 then
		return "20"
	else
		return "0"
	end
end

-- Creates a new Wizard instance
-- Input: position (Vector3) - Spawn position of the Wizard
--        teamColor (Color3) - The team color of the Wizard
-- Output: Wizard (table) - The newly created Wizard instance
function Wizard.new(position, teamColor)
	local self = setmetatable({}, Wizard)

	-- Clone the Wizard model from ReplicatedStorage and initialize properties
	self.model = game.ReplicatedStorage.NPCs:FindFirstChild("Wizard"):Clone()
	self.teamColor = teamColor
	self.kingGoal = King.GetKingGoal(self.teamColor).model -- Target King for this team
	self.behavior = "Spawning"

	-- Set the Wizard's appearance and spawn position
	self.model["Body Colors"].TorsoColor3 = teamColor
	self.model.PrimaryPart.CFrame = CFrame.new(position)
	self.model.Parent = game.Workspace
	
	self.model.Humanoid.MaxHealth = HEALTH
	self.model.Humanoid.Health = HEALTH

	-- Set up behavior when the Wizard dies
	self.model.Humanoid.Died:Once(function()
		OnDeath(self)
	end)

	-- Start pathfinding
	spawn(function()
		self:FindPath()
	end)

	-- Add the Wizard to the entities table
	Wizard.entities[self.model] = self
	NPC.new(self.model, self.teamColor)
	return self
end

-- Finds a path to the King's goal and moves the Wizard along it
-- Input: None (uses Wizard's internal properties)
-- Output: None (moves the Wizard or engages in combat if enemies are found)
function Wizard:FindPath()
	if not self.kingGoal then
		self.kingGoal = King.GetKingGoal(self.teamColor).model -- Update King goal if missing
	end

	self.behavior = "Moving"

	-- Create a path to the King's position
	local path = PathfindingService:CreatePath()
	path:ComputeAsync(self.model.PrimaryPart.Position, self.kingGoal.PrimaryPart.Position)

	if path.Status ~= Enum.PathStatus.Success then
		print("Pathing failed for Wizard in the " .. tostring(self.teamColor) .. " team.")
		return
	end

	-- Move through the path waypoints
	local waypoints = path:GetWaypoints()
	for _, waypoint in ipairs(waypoints) do
		self.model.Humanoid:MoveTo(waypoint.Position + Vector3.new(math.random(2), 0, math.random(2)))
		self.model.Humanoid.MoveToFinished:Wait(1)

		-- Check for nearby enemies within the detection range
		local PartsInRegion = workspace:GetPartBoundsInRadius(self.model.PrimaryPart.CFrame.Position, RANGE)
		for _, part in ipairs(PartsInRegion) do
			local npc = nil
			local building = nil
			
			if game.ReplicatedStorage.Buildings:FindFirstChild(part.Parent.Name) then
				building = part.Parent
				local wizardTeam = Team.GetTeamFromColor(self.teamColor)
				
				if building.Parent.Parent == wizardTeam.base then
					continue
				end
				
				spawn(function()
					self:FightBuilding(building)
				end)
				
				return
			end
			
			if game.Players:FindFirstChild(part.Parent.Name) then
				local playerCharacter = part.Parent
				local wizardTeam = Team.GetTeamFromColor(self.teamColor)
				
				if Team.GetTeamFromPlayer(game.Players:FindFirstChild(playerCharacter.Name)) == wizardTeam then
					continue
				end
				
				spawn(function()
					self:FightPlayer(playerCharacter)
				end)
				return
			end

			-- Determine if the part belongs to another NPC or a King
			npc = NPC.entities[part.Parent]
			if not npc then
				continue
			end
			
			-- Engage in combat if an enemy is found
			if npc and npc.teamColor ~= self.teamColor and npc.model.Humanoid.Health > 0 then
				spawn(function()
					self:FightEnemy(part.Parent)
				end)
				
				return
			end
		end

		-- Exit if the Wizard is dead
		if not self.model or self.model.Humanoid.Health <= 0 then
			local PartsInRegion = workspace:GetPartBoundsInRadius(self.model.PrimaryPart.CFrame.Position, 50)

			for _,part in PartsInRegion do
				if part.Parent:FindFirstChild("Humanoid") and part.Parent.Humanoid.Health ~= 0 then
					local killer = part.Parent
					local enemyTeam

					if game.Players:FindFirstChild(killer.Name) then
						enemyTeam = Team.GetTeamFromPlayer(game.Players:FindFirstChild(killer.Name))
					else
						enemyTeam = Team.GetTeamFromColor(NPC.entities[killer].teamColor)
					end

					if enemyTeam == Team.GetTeamFromColor(self.teamColor) then
						continue
					end

					enemyTeam:AddGold(Constants.KILL_REWARDS[self.model.Name])
					break
				end
			end
		end
	end
end

-- Engages the Wizard in combat with an enemy
-- Input: enemy (Model) - The enemy to Fight
-- Output: None (handles attacking the enemy and continues pathfinding if victorious)
function Wizard:FightEnemy(enemy)
	self.behavior = "Attacking"
	
	local wizardName = self.model.Name
	local enemyTeam = Team.GetTeamFromColor(NPC.entities[enemy].teamColor)

	-- Continue attacking until either the Wizard or the enemy is dead
	while enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and self.model.Humanoid.Health > 0 do
		enemy.Humanoid.Health -= DAMAGE -- Deal damage to the enemy
		wait(COOLDOWN) -- Wait for the cooldown period
	end

	-- If the Wizard survives, continue pathfinding
	if self.model.Humanoid.Health > 0 then
		spawn(function()
			self:FindPath()
		end)
	else
		enemyTeam:AddGold(Constants.KILL_REWARDS[wizardName])
	end
end

function Wizard:FightBuilding(building)
	self.behavior = "Attacking"
	--TODO: Building behavior isn't working

	local wizardName = self.model.Name
	local buildingName = building.Name
	local buildingHealth = building:FindFirstChild("Health")
	local buildingStatus = nil
	local buildingCFrame = building.PrimaryPart.CFrame

	-- Continue attacking until either the Wizard or the building is destroyed
	
	while building:FindFirstChild("Health") and self.model.Humanoid.Health > 0 do
		local preStatus = DetermineBuildingStatus(buildingName, buildingHealth.Value)
		buildingHealth.Value -= DAMAGE -- Deal damage to the enemy
		local postStatus = DetermineBuildingStatus(buildingName, buildingHealth.Value)
		
		if preStatus ~= postStatus then
			BuildingPlacement.ChangeBuildingAppearance(building, postStatus, self.teamColor)
		end

		wait(COOLDOWN) -- Wait for the cooldown period
		
		if not building:FindFirstChild("Health") then
			local PartsInRegion = workspace:GetPartBoundsInRadius(buildingCFrame.Position, 1)
			for _,part in PartsInRegion do
				if part.Parent.Name == buildingName then
					building = part.Parent
				end
			end
		end
		
	end

	-- If the Wizard survives, continue pathfinding
	if self.model.Humanoid.Health > 0 then
		spawn(function()
			self:FindPath()
		end)
	else
		Team.entities[building.Parent.Parent]:AddGold(Constants.KILL_REWARDS[wizardName])
	end
end

function Wizard:FightPlayer(character)
	self.behavior = "Attacking"

	local wizardName = self.model.Name
	local enemyTeam = Team.GetTeamFromPlayer(game.Players:FindFirstChild(character.Name))
	local enemyName = character.Name
	local inRange = true
	
	-- Continue attacking until either the Wizard or the enemy is dead
	while inRange and character.Humanoid.Health > 0 and self.model.Humanoid.Health > 0 do
		character.Humanoid.Health -= DAMAGE -- Deal damage to the enemy
		wait(COOLDOWN) -- Wait for the cooldown period
		
		inRange = false
		local partsInRegion = workspace:GetPartBoundsInRadius(self.model.PrimaryPart.CFrame.Position, RANGE)
		for _,part in partsInRegion do
			if part.Parent.Name == enemyName then
				inRange = true
				break
			end
		end
	end

	-- If the Wizard survives, continue pathfinding
	if self.model.Humanoid.Health > 0 then		
		spawn(function()
			self:FindPath()
		end)
	else
		enemyTeam:AddGold(Constants.KILL_REWARDS[wizardName])
	end
end

return Wizard
