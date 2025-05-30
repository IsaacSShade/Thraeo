local Team = {}
Team.__index = Team

local Config = require(game.ReplicatedStorage:FindFirstChild("Config", true))

Team.entities = {}
Team.byPlayer = {}
Team.byColor  = {}

Team.TeamJoined = Instance.new("BindableEvent")
Team.TeamLeft   = Instance.new("BindableEvent")

function Team.GetEntityAmount()
	local count = 0
	for _,_ in Team.entities do
		count += 1
	end
	return count
end

function Team.GetTeamFromPlayer(player)
	return Team.byPlayer[player]
end

function Team.GetTeamFromColor(color)
	return Team.byColor[color]
end

-- players can be null
function Team.new(color, base, players)
	local self   = setmetatable({}, Team)
	self.color   = color
	self.base    = base
	self.gold    = 0
	self.players = {}

	-- register color lookup
	Team.entities[base] = self
	Team.byColor[color] = self

	-- add initial players
	if players then
		for _, p in ipairs(players) do
			self:AddPlayer(p)
		end
	end

	-- starting gold
	self:AddGold(Config.STARTING_GOLD_AMOUNT)

	return self
end

function Team:AddPlayer(player)
	assert(player and typeof(player) == "Instance" and player:IsA("Player"), "Team:AddPlayer — expected a Player instance")
	assert(not Team.byPlayer[player], ("Team:AddPlayer — player %s is already on a team"):format(player.Name))
	
	table.insert(self.players, player)
	Team.byPlayer[player] = self

	-- set spawn location
	local spawnBuilding = self.base:FindFirstChild(Config.KING_BUILDING_NAME)
	assert(spawnBuilding and spawnBuilding:FindFirstChild("SpawnLocation"), ("Team:AddPlayer — missing %s.SpawnLocation in base"):format(Config.KING_BUILDING_NAME))
	if spawnBuilding and spawnBuilding:FindFirstChild("SpawnLocation") then
		player.RespawnLocation = spawnBuilding.SpawnLocation
	end
	player:LoadCharacter()

	-- fire event
	Team.TeamJoined:Fire(player, self)
end

function Team:RemovePlayer(player)
	assert(player and Team.byPlayer[player] == self, "Team:RemovePlayer — player is not on this team")
	for i, p in ipairs(self.players) do
		if p == player then
			table.remove(self.players, i)
			Team.byPlayer[player] = nil
			Team.TeamLeft:Fire(player, self)
			break
		end
	end
end

function Team:SubtractGold(amount)
	self:AddGold(-amount)
end
function Team:AddGold(amount)
    self.gold += amount
    for _, p in ipairs(self.players) do
        game.ReplicatedStorage.Events:FindFirstChild("UpdateMoneyUI", true)
            :InvokeClient(p, self.gold)
    end
end

return Team

