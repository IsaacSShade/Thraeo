-- ServerScriptService/GameEvents.server
-- ModuleScript handling team setup, game modes, events, and building placement

local GameEvents    = {}
local RunService    = game:GetService("RunService")
local Replicated    = game.ReplicatedStorage
local ServerScripts = game:GetService("ServerScriptService")

-- dependencies

local King              = require(ServerScripts:FindFirstChild("King", true))
local Team              = require(ServerScripts:FindFirstChild("Team", true))
local NPC               = require(ServerScripts:FindFirstChild("NPC", true))
local BuildingPlacement = require(ServerScripts:FindFirstChild("BuildingPlacement", true))
local Config            = require(Replicated:FindFirstChild("Config", true))
local GameManager       = require(ServerScripts:WaitForChild("GameManager"))

-- internal state
local gameRunning = false

--── HELPER FUNCTIONS ───────────────────────────────────────────────────────────

local function Damage(player, target, damage)
	local humanoid = target:FindFirstChild("Humanoid")
	if not humanoid then return end

	humanoid.Health = humanoid.Health - damage

	-- if it was a player
	if game.Players:FindFirstChild(target.Name) and humanoid.Health <= 0 then
		local enemyTeam  = Team.GetTeamFromPlayer(target)
		local alliedTeam = Team.GetTeamFromPlayer(player)
		local halfGold   = enemyTeam.gold / 2

		enemyTeam:SubtractGold(halfGold)
		alliedTeam:AddGold(halfGold)
	end
end

local function GetRandomColor()
	return Color3.new(math.random(), math.random(), math.random())
end

local function SetUpKings()
	for _, baseFolder in ipairs(workspace:WaitForChild("Bases"):GetChildren()) do
		King.new(baseFolder, Team.entities[baseFolder].color)
	end
end

local function SetupPlayerVsAi(player, basesFolder)
	for i, base in ipairs(basesFolder:GetChildren()) do
		local newTeam = Team.new(GetRandomColor(), base)
		if i == 1 then
			newTeam:AddPlayer(player)
			local cv = Instance.new("Color3Value")
			cv.Name   = "TeamColor"
			cv.Value  = newTeam.color
			cv.Parent = player
		end
	end
end

local function SetupPlayerVsPlayer(players, basesFolder)
	for i, base in ipairs(basesFolder:GetChildren()) do
		local newTeam = Team.new(GetRandomColor(), base)
		local plr     = players[i]
		newTeam:AddPlayer(plr)
		local cv = Instance.new("Color3Value")
		cv.Name   = "TeamColor"
		cv.Value  = newTeam.color
		cv.Parent = plr
	end
end

--── EVENT HANDLERS ─────────────────────────────────────────────────────────────

function GameEvents.StartGame(player, mode, players)
	-- join existing team (mode==2)
	if mode == 2 and Team.GetEntityAmount() > 0 then
		for _, team in pairs(Team.entities) do
			team:AddPlayer(player)
			local cv = Instance.new("Color3Value")
			cv.Name   = "TeamColor"
			cv.Value  = team.color
			cv.Parent = player
			break
		end
	end

	-- clone level
	local level = Replicated.Bases:Clone()
	level.Parent = game.Workspace

	-- set up teams
	if mode == 0 then
		SetupPlayerVsAi(player, level)
	elseif mode == 1 then
		SetupPlayerVsPlayer(players, level)
	end
	
	-- initial king setup
	SetUpKings()

	-- toggle GUI buttons
	local gui = Replicated.Guis.SelectMode.Frame.Frame
	gui.Left.PlayerVsAi.Interactable      = false
	gui.Left.JoinTeam.Interactable       = true
	gui.Right.PlayerVsPlayer.Interactable = false

	-- start game loop
	gameRunning = true
	GameManager:Start()
end

function GameEvents.EndGame(winningTeam)
	gameRunning = false
	GameManager:Stop()
end

function GameEvents.UpdatePlayerGui(player, text1, text2)
	Replicated.Events.UpdatePlayerGui:FireAllClients(text1, text2)
end

function GameEvents.GetNpcTeamColor(_, model)
	return NPC.entities[model].teamColor
end

--── MODULE INITIALIZER ─────────────────────────────────────────────────────────

function GameEvents.Init()
	-- kick off heartbeat tick manager
	GameManager:Init()

	-- hook up remotes / events
	local evts = Replicated.Events
	evts.Damage.OnServerEvent:Connect(Damage)
	evts.StartGame.OnServerEvent:Connect(GameEvents.StartGame)
	evts.PlaceBuilding.OnServerEvent:Connect(BuildingPlacement.PlaceBuildingEvent)
	evts.UpdatePlayerGui.OnServerEvent:Connect(GameEvents.UpdatePlayerGui)
	evts.GetTeamFromPlayer.OnServerInvoke    = Team.GetTeamFromPlayer
	evts.GetNpcTeamColor.OnServerInvoke     = GameEvents.GetNpcTeamColor
end

return GameEvents
