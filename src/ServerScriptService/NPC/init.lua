local NPC = {}
NPC.__index = NPC

local Team = require(game.ServerScriptService:FindFirstChild("Team", true))

NPC.entities = {}

function NPC.new(model, teamColor)
	local self = setmetatable({}, NPC)
	self.model = model
	self.teamColor = teamColor
	
	NPC.entities[self.model] = self
	return self
end

return NPC
