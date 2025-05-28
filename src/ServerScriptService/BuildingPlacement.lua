local BuildingPlacement = {}

-- Server-side Game Script
-- Handles team setup, game modes, events, and building placement

local Team = require(game.ServerScriptService:FindFirstChild("Team", true))
local Constants = require(game.ReplicatedStorage:FindFirstChild("Constants", true))

-- This function exists because it doesn't need the player argument but that's what's automatically passed
function BuildingPlacement.PlaceBuildingEvent(player, modelName, primaryCFrame, buildingFolder, status, health)
	BuildingPlacement.PlaceBuilding(modelName, primaryCFrame, buildingFolder, status)
end

local function CreateBuilding(buildingName, primaryCFrame, buildingFolder, status, healthValue)
	local building = game.ReplicatedStorage.Buildings:FindFirstChild(buildingName, true):FindFirstChild(status):Clone()
	building.Name = buildingName
	building:PivotTo(primaryCFrame)
	building.Parent = buildingFolder

	local health = Instance.new("IntValue")
	health.Name = "Health"
	health.Parent = building
	health.Value = healthValue
end

--- Places a building at a specified location
-- @param player The player placing the building
-- @param modelName The name of the building model
-- @param primaryCFrame The CFrame for placement
-- @param buildingFolder The folder to place the building in
function BuildingPlacement.PlaceBuilding(modelName, primaryCFrame, buildingFolder)
	local team = Team.entities[buildingFolder.Parent]
	local status = "100"
	local healthValue = Constants.BUILDING_HEALTH[modelName] * tonumber(status) / 100

	if team.gold >= Constants.BUILDING_COSTS[modelName] then
		team:SubtractGold(Constants.BUILDING_COSTS[modelName])

		CreateBuilding(modelName, primaryCFrame, buildingFolder, status, healthValue)
	end
end



function BuildingPlacement.ChangeBuildingAppearance(building, status, teamColor)
	if not building:FindFirstChild("Health") then return end
	
	print(building.Name .. " | Changing Appearance | >" .. status)
	if status == "0" then 
		local archerTeam = Team.GetTeamFromColor(teamColor)
		archerTeam:AddGold(Constants.KILL_REWARDS[building.Name])
		building:Destroy() 
		building = nil
		return
	end
	
	CreateBuilding(building.Name, building.PrimaryPart.CFrame, building.Parent, status, building:FindFirstChild("Health").Value)

	building:Destroy()
	building = nil
end



return BuildingPlacement
