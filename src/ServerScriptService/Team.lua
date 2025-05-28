local Team = {}
Team.__index = Team

local Constants = require(game.ReplicatedStorage:FindFirstChild("Constants", true))

Team.entities = {}

function Team.GetEntityAmount()
	local count = 0
	for _,_ in Team.entities do
		count += 1
	end
	return count
end

function Team.GetTeamFromPlayer(player)
	local color = player:FindFirstChild("TeamColor")

	for _,baseFolder in game.Workspace.Bases:GetChildren() do
		if Team.entities[baseFolder].color == color.Value then
			return Team.entities[baseFolder]
		end
	end
end

function Team.GetTeamFromColor(color)
	for _,baseFolder in game.Workspace.Bases:GetChildren() do
		if Team.entities[baseFolder].color == color then
			return Team.entities[baseFolder]
		end
	end
end

-- players can be null
function Team.new(color, base, players)
	local self = setmetatable({}, Team)
	
	self.color = color
	self.players = players
	self.gold = 0
	self.base = base
	
	if self.players == nil then
		self.players = {}
	else
		for _,player in players do
			player.RespawnLocation = self.base:FindFirstChild("KingPavillion").SpawnLocation
			player:LoadCharacter()
		end
	end
	
	self:AddGold(Constants.STARTING_GOLD_AMOUNT)
	Team.entities[base] = self
	return self
end

function Team:AddPlayer(player)
	table.insert(self.players, player)
	player.RespawnLocation = self.base:FindFirstChild("KingPavillion").SpawnLocation
	player:LoadCharacter()
end

function Team:SubtractGold(amount)
	self:AddGold(-1 * amount)
	
end

function Team:AddGold(amount)
	self.gold += amount
	for _,player in self.players do
		game.ReplicatedStorage.Events:FindFirstChild("UpdateMoneyUI", true):InvokeClient(player, self.gold)
	end
end

return Team

