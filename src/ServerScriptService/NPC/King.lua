local King = {}
King.__index = King

King.entities = {}

local Team = require(game.ServerScriptService:FindFirstChild("Team", true))
local Constants = require(game.ReplicatedStorage:FindFirstChild("Constants", true))
local NPC = require(game.ServerScriptService:FindFirstChild("NPC", true))

local KING_BUILDING_NAME = "KingPavillion"
local KING_HEALTH = 10000
local WATCH_COOLDOWN = 2
local RANGE = 30         -- Detection range for enemies
local COOLDOWN = 4       -- Cooldown time between attacks (in seconds)
local DAMAGE = 50        -- Damage dealt per attack

local function GetEntityAmount()
	local count = 0
	for _,_ in King.entities do
		count += 1
	end
	return count
end

local function OnDeath(king)
	spawn(function()
		wait(COOLDOWN + 1) -- Wait to ensure cleanup after cooldown
		King.entities[king.model] = nil -- Remove from the entities table
		if king.model then
			king.model:Destroy() -- Destroy the King model
		end
		king.model = nil -- Clear the reference to the model
		king = nil       -- Clear the King instance
	end)
end

function King.new(base, teamColor)
	local self = setmetatable({}, King)
	local kingSpawner = base:FindFirstChild(KING_BUILDING_NAME).KingSpawner

	self.model = game.ReplicatedStorage.NPCs:FindFirstChild("King"):Clone()
	self.teamColor = teamColor

	self.model["Body Colors"].TorsoColor3 = teamColor
	self.model.PrimaryPart.CFrame = CFrame.new(kingSpawner.Position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, math.rad(90), 0) * kingSpawner.CFrame.Rotation
	self.model.Parent = game.Workspace
	self.model.Humanoid.MaxHealth = KING_HEALTH
	self.model.Humanoid.Health = KING_HEALTH
	
	self.model.Humanoid.Died:Once(function()
		OnDeath(self)
	end)
	
	King.entities[self.model] = self
	NPC.new(self.model, self.teamColor)
	
	spawn(function()
		self:StandWatch()
	end)
	return self
end

function King.GetKingGoal(alliedTeamColor)
	local numEntities = GetEntityAmount()
	
	if numEntities == 2 then
		
		for _,king in King.entities do
			if king.teamColor ~= alliedTeamColor then
				return king
			end
		end
		
	elseif numEntities > 2 then
		print("!! MORE THAN 2 KINGS !!")
		return
	end
end

function King:StandWatch()
	while true do
		wait(WATCH_COOLDOWN)
		local PartsInRegion = workspace:GetPartBoundsInRadius(self.model.PrimaryPart.CFrame.Position, RANGE)
		for _, part in ipairs(PartsInRegion) do
			local npc = nil
			local building = nil

			if game.ReplicatedStorage.Buildings:FindFirstChild(part.Parent.Name) then
				building = part.Parent
				local npcTeam = Team.GetTeamFromColor(self.teamColor)

				if building.Parent.Parent == npcTeam.base then
					continue
				end

				spawn(function()
					self:FightBuilding(building)
				end)

				return
			end
			
			if game.Players:FindFirstChild(part.Parent.Name) then
				local playerCharacter = part.Parent
				local kingTeam = Team.GetTeamFromColor(self.teamColor)

				if Team.GetTeamFromPlayer(game.Players:FindFirstChild(playerCharacter.Name)) == kingTeam then
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
	end
	
end

function King:Fight(enemy)
	self.behavior = "Attacking"

	local kingName = self.model.Name
	local enemyTeam = Team.GetTeamFromColor(NPC.entities[enemy].teamColor)

	-- Continue attacking until either the King or the enemy is dead
	while enemy.Humanoid.Health > 0 and self.model.Humanoid.Health > 0 do
		wait(COOLDOWN) -- Wait for the cooldown period
		enemy.Humanoid.Health -= DAMAGE -- Deal damage to the enemy
	end

	-- If the King survives, continue pathfinding
	if self.model.Humanoid.Health > 0 then
		spawn(function()
			self:StandWatch()
		end)
	else
		enemyTeam:AddGold(Constants.KILL_REWARDS[kingName])
	end
end

function King:FightPlayer(character)
	self.behavior = "Attacking"

	local kingName = self.model.Name
	local enemyTeam = Team.GetTeamFromPlayer(game.Players:FindFirstChild(character.Name))
	local enemyName = character.Name
	local inRange = true

	-- Continue attacking until either the King or the enemy is dead
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

	-- If the King survives, continue watching
	if self.model.Humanoid.Health > 0 then
		spawn(function()
			self:StandWatch()
		end)
	else
		enemyTeam:AddGold(Constants.KILL_REWARDS[kingName])
	end
end

return King
