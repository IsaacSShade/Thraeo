-- King.lua
local King = {}
King.__index = King

King.entities = {}

local Team   = require(game.ServerScriptService:FindFirstChild("Team", true))
local NPC    = require(game.ServerScriptService:FindFirstChild("NPC", true))
local Config = require(game.ReplicatedStorage:FindFirstChild("Config", true))

-- grab all king stats from Config
local stats = Config.UNIT_STATS[Config.KING_NAME]

-- count how many kings are alive
local function GetEntityAmount()
	local count = 0
	for _, _ in pairs(King.entities) do
		count += 1
	end
	return count
end

-- cleanup & destroy after death
local function OnDeath(self)
	spawn(function()
		-- ensure cleanup after the king's own cooldown
		wait(stats.Cooldown + 1)
		King.entities[self.model] = nil
		if self.model then
			self.model:Destroy()
		end
	end)
end

function King.new(base, teamColor)
	local self = setmetatable({}, King)

	-- find the King spawner part
	local kingSpawner = base:FindFirstChild(Config.KING_BUILDING_NAME).KingSpawner

	-- clone & colorize model
	self.model = game.ReplicatedStorage.NPCs:FindFirstChild(Config.KING_NAME):Clone()
	self.teamColor = teamColor
	self.model["Body Colors"].TorsoColor3 = teamColor

	-- position it 5 studs above the spawner
	self.model.PrimaryPart.CFrame =
		CFrame.new(kingSpawner.Position + Vector3.new(0, 5, 0))
		* CFrame.Angles(0, math.rad(90), 0)
		* kingSpawner.CFrame.Rotation

	self.model.Parent = workspace

	-- apply health from Config
	self.model.Humanoid.MaxHealth = stats.Health
	self.model.Humanoid.Health    = stats.Health

	-- hook death
	self.model.Humanoid.Died:Once(function()
		OnDeath(self)
	end)

	King.entities[self.model] = self
	NPC.new(self.model, self.teamColor)

	-- start the watch loop
	spawn(function()
		self:StandWatch()
	end)

	return self
end

function King.GetKingGoal(alliedTeamColor)
	local num = GetEntityAmount()
	if num == 2 then
		for _, king in pairs(King.entities) do
			if king.teamColor ~= alliedTeamColor then
				return king
			end
		end
	elseif num > 2 then
		warn("!! MORE THAN 2 KINGS !!")
	end
end

function King:StandWatch()
	while true do
		wait(stats.WatchInterval)
		local parts = workspace:GetPartBoundsInRadius(self.model.PrimaryPart.Position, stats.Range)
		for _, part in ipairs(parts) do
			local building, npc

			-- attack buildings
			if game.ReplicatedStorage.Buildings:FindFirstChild(part.Parent.Name) then
				building = part.Parent
				local myTeam = Team.GetTeamFromColor(self.teamColor)
				if building.Parent.Parent ~= myTeam.base then
					spawn(function() self:FightBuilding(building) end)
					return
				end
			end

			-- attack players
			if game.Players:FindFirstChild(part.Parent.Name) then
				local char = part.Parent
				local myTeam = Team.GetTeamFromColor(self.teamColor)
				if Team.GetTeamFromPlayer(game.Players:FindFirstChild(char.Name)) ~= myTeam then
					spawn(function() self:FightPlayer(char) end)
					return
				end
			end

			-- attack other NPCs / kings
			npc = NPC.entities[part.Parent]
			if npc and npc.teamColor ~= self.teamColor and npc.model.Humanoid.Health > 0 then
				spawn(function() self:FightEnemy(part.Parent) end)
				return
			end
		end
	end
end

function King:Fight(enemy)
	self.behavior = "Attacking"
	local kingName = Config.KING_NAME
	local enemyTeam = Team.GetTeamFromColor(NPC.entities[enemy].teamColor)

	while enemy.Humanoid.Health > 0 and self.model.Humanoid.Health > 0 do
		wait(stats.Cooldown)
		enemy.Humanoid.Health -= stats.Damage
	end

	if self.model.Humanoid.Health > 0 then
		spawn(function() self:StandWatch() end)
	else
		enemyTeam:AddGold(Config.KILL_REWARDS[kingName])
	end
end

function King:FightPlayer(character)
	self.behavior = "Attacking"
	local kingName = Config.KING_NAME
	local enemyTeam = Team.GetTeamFromPlayer(game.Players:FindFirstChild(character.Name))
	local inRange = true

	while inRange and character.Humanoid.Health > 0 and self.model.Humanoid.Health > 0 do
		character.Humanoid.Health -= stats.Damage
		wait(stats.Cooldown)

		inRange = false
		local parts = workspace:GetPartBoundsInRadius(self.model.PrimaryPart.Position, stats.Range)
		for _, part in ipairs(parts) do
			if part.Parent.Name == character.Name then
				inRange = true
				break
			end
		end
	end

	if self.model.Humanoid.Health > 0 then
		spawn(function() self:StandWatch() end)
	else
		enemyTeam:AddGold(Config.KILL_REWARDS[kingName])
	end
end

return King
