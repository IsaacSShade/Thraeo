local Replicated       = game:GetService("ReplicatedStorage")
local ServerScripts    = game:GetService("ServerScriptService")

-- require and initialize your module
local GameEventsModule = require(ServerScripts:WaitForChild("GameEvents"))
GameEventsModule.Init()