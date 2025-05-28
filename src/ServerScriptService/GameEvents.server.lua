-- Server-side Game Script
-- Handles team setup, game modes, events, and building placement

local Archer = require(game.ServerScriptService:FindFirstChild("Archer", true))
local King = require(game.ServerScriptService:FindFirstChild("King", true))
local Wizard = require(game.ServerScriptService:FindFirstChild("Wizard", true))
local Team = require(game.ServerScriptService:FindFirstChild("Team", true))
local Constants = require(game.ReplicatedStorage:FindFirstChild("Constants", true))
local NPC = require(game.ServerScriptService:FindFirstChild("NPC", true))
local BuildingPlacement = require(game.ServerScriptService:FindFirstChild("BuildingPlacement", true))

-- Constants
local SPAWN_TIME = 6 -- Time between spawns in seconds
local ARCHER_BUILDING_NAME = "ArcherTower" -- Name of the building that spawns archers

local gameRunning = false
-- Helper Functions

--- Reduces the health of a target by a specified damage amount
-- @param player The player dealing the damage
-- @param target The target being damaged
-- @param damage Amount of damage to deal
local function Damage(player, target, damage)
	target:FindFirstChild("Humanoid").Health -= damage
	
	if game.Players:FindFirstChild(target.Name) then
		print("Dealt damage to player!")
		if target.Humanoid.Health <= 0 then
			local enemyTeam = Team.GetTeamFromPlayer(game.Players:FindFirstChild(target.Name))
			local alliedTeam = Team.GetTeamFromPlayer(player)
			
			local amountChanged = enemyTeam.gold / 2
			enemyTeam:SubtractGold(amountChanged)
			alliedTeam:AddGold(amountChanged)
		end
	end
end

local function ParseSpawnedObject(building, baseFolder)
	local spawner = building:FindFirstChild("SpawnLocation")
	local teamColor = Team.entities[baseFolder].color

	if building.Name == Constants.ARCHER_BUILDING_NAME then
		Archer.new(spawner.Position + Vector3.new(0, 5, 0), teamColor)
	elseif building.Name == Constants.WIZARD_BUILDING_NAME then
		Wizard.new(spawner.Position + Vector3.new(0, 5, 0), teamColor)
	end
end


--- Generates a random Color3 value
-- @return A randomly generated Color3 value
local function GetRandomColor()
	return Color3.new(math.random(255), math.random(255), math.random(255))
end

--- Sets up Kings for each base in the game
local function SetUpKings()
	for _, baseFolder in game.Workspace.Bases:GetChildren() do
		King.new(baseFolder, Team.entities[baseFolder].color)
	end
end

--- Sets up a player versus AI game mode
-- @param player The player to set up
-- @param bases The folder containing base objects
local function SetupPlayerVsAi(player, bases)
	for i, base in bases:GetChildren() do
		local newTeam = Team.new(GetRandomColor(), base, nil)

		if i == 1 then
			newTeam:AddPlayer(player)

			local colorValue = Instance.new("Color3Value")
			colorValue.Name = "TeamColor"
			colorValue.Parent = player
			colorValue.Value = newTeam.color
		end
	end
end

--- Sets up a player versus player game mode
-- @param players A list of players
-- @param bases The folder containing base objects
local function SetupPlayerVsPlayer(players, bases)
	for i, base in bases:GetChildren() do
		local newTeam = Team.new(GetRandomColor(), base, nil)
		newTeam:AddPlayer(players[i])

		local colorValue = Instance.new("Color3Value")
		colorValue.Name = "TeamColor"
		colorValue.Parent = players[i]
		colorValue.Value = newTeam.color
	end
end

-- Game Loop

--- Main game loop for spawning archers and managing game logic
local function GameLoop()
	game.ReplicatedStorage.Guis.SelectMode.Frame.Frame.Left.PlayerVsAi.Interactable = false
	game.ReplicatedStorage.Guis.SelectMode.Frame.Frame.Left.JoinTeam.Interactable = true
	game.ReplicatedStorage.Guis.SelectMode.Frame.Frame.Right.PlayerVsPlayer.Interactable = false

	SetUpKings()

	while gameRunning do
		wait(SPAWN_TIME)
		for _, baseFolder in game.Workspace.Bases:GetChildren() do
			for _, building in baseFolder.Buildings:GetChildren(true) do
				if building:FindFirstChild("SpawnLocation") then
					ParseSpawnedObject(building, baseFolder)
				end
			end
		end
	end
end

-- Event Handlers

--- Starts the game with the specified mode
-- @param player The player starting the game
-- @param mode The game mode (0 for PvE, 1 for PvP, 2 for join game)
-- @param players (Optional) List of players for PvP mode
local function StartGame(player, mode, players)
	if mode == 2 then
		if Team.GetEntityAmount() ~= 0 then
			for _, team in Team.entities do
				local colorValue = Instance.new("Color3Value")
				colorValue.Name = "TeamColor"
				colorValue.Parent = player
				colorValue.Value = team.color

				team.AddPlayer(player)
				break
			end
		end
	end

	local level = game.ReplicatedStorage.Bases:Clone()
	level.Parent = game.Workspace
	gameRunning = true

	if mode == 0 then
		SetupPlayerVsAi(player, level)
		GameLoop()
	elseif mode == 1 then
		SetupPlayerVsPlayer(players, level)
		GameLoop()
	end
end

local function EndGame(winningTeam)
	
end

--- Updates the player's GUI with specified text
-- @param player The player whose GUI to update
-- @param textbox1 Text for the first textbox
-- @param textbox2 Text for the second textbox
local function UpdatePlayerGui(player, textbox1, textbox2)
	game.ReplicatedStorage.Events:FindFirstChild("UpdatePlayerGui", true):FireAllClients(textbox1, textbox2)
end

local function GetNpcTeamColor(player, model)
	local npc = NPC.entities[model]
	return npc.teamColor
end

-- Event Connections

-- Connect damage event
game.ReplicatedStorage.Events:FindFirstChild("Damage", true).OnServerEvent:Connect(Damage)

-- Connect start game event
game.ReplicatedStorage.Events:FindFirstChild("StartGame", true).OnServerEvent:Connect(StartGame)

-- Connect update player GUI event
game.ReplicatedStorage.Events:FindFirstChild("UpdatePlayerGui", true).OnServerEvent:Connect(UpdatePlayerGui)

-- Connect place building event
game.ReplicatedStorage.Events:FindFirstChild("PlaceBuilding", true).OnServerEvent:Connect(BuildingPlacement.PlaceBuildingEvent)

-- Setup team retrieval
game.ReplicatedStorage.Events:FindFirstChild("GetTeamFromPlayer", true).OnServerInvoke = Team.GetTeamFromPlayer

game.ReplicatedStorage.Events:FindFirstChild("GetNpcTeamColor", true).OnServerInvoke = GetNpcTeamColor
