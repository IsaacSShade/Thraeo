-- LocalBuilding Module
-- Handles ghost building creation, placement, and interactions for a Roblox game

local LocalBuilding = {}

-- Required Modules and Constants
local Constants = require(game.ReplicatedStorage:FindFirstChild("Constants", true))

-- Constants
local Z_HEIGHT = 2.5 -- Height for placement level
local VALID_COLOR = Color3.fromRGB(0, 255, 0) -- Color for valid placement
local INVALID_COLOR = Color3.fromRGB(255, 0, 0) -- Color for invalid placement
local BASE_SIZE = 300 -- Size of the player's base

-- Local Variables
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local buildingGhost -- Ghost building model
local buildingName -- Name of the building being placed
local baseFolder -- Folder containing base-related objects
local canPlace = false -- Whether the building can be placed

-- Helper Functions
--- Changes the properties of parts in a model to set transparency, collision, and color
-- @param model Model to modify
-- @param transparency (Optional) Transparency level to apply
local function ChangeModelParts(model, transparency)
	if not transparency then transparency = 0.5 end

	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.Transparency = transparency
			part.CanCollide = false
			part.Color = canPlace and VALID_COLOR or INVALID_COLOR
			part.Material = Enum.Material.Neon
		else
			part:Destroy()
		end
	end
end

-- Public Functions

--- Creates a ghost model for placement
-- @param model Model to clone for ghost representation
function LocalBuilding.CreateGhostModel(model)
	if game.Workspace:FindFirstChild("BuildingGhost") then
		return
	end

	local playerTeam = game.ReplicatedStorage.Events:FindFirstChild("GetTeamFromPlayer", true):InvokeServer()
	
	if not baseFolder then
		baseFolder = playerTeam.base
	end

	buildingName = model.Parent.Name

	if playerTeam.gold < Constants.BUILDING_COSTS[buildingName] then
		return
	end

	buildingGhost = model:Clone()
	buildingGhost.Name = "BuildingGhost"
	ChangeModelParts(buildingGhost)

	buildingGhost.Parent = workspace
end

--- Updates the position of the ghost model based on mouse position
function LocalBuilding.UpdateGhostPosition()
	if not buildingGhost then return end

	mouse.TargetFilter = buildingGhost

	local targetPosition = mouse.Hit.Position
	local collisionBase = buildingGhost.CollisionBase
	local gridPosition = Vector3.new(
		math.floor(targetPosition.X / 10) * 10,
		Z_HEIGHT, -- Keep it at ground level
		math.floor(targetPosition.Z / 10) * 10
	)
	local castleBase = baseFolder:FindFirstChild(Constants.BASE_FOUNDATION_NAME)
	local baseXMax = (BASE_SIZE / 2) - (collisionBase.Size.X / 2)
	local baseZMax = (BASE_SIZE / 2) - (collisionBase.Size.Z / 2)

	local newCFrame = CFrame.new(gridPosition) * buildingGhost.PrimaryPart.CFrame.Rotation
	buildingGhost:SetPrimaryPartCFrame(newCFrame)

	-- Check if within bounds of base
	if math.abs(gridPosition.X - castleBase.Position.X) > baseXMax or math.abs(gridPosition.Z - castleBase.Position.Z) > baseZMax then
		ChangeModelParts(buildingGhost, 1)
		canPlace = false
		return
	end

	-- Check for collisions
	local overlappingParts = workspace:GetPartBoundsInBox(collisionBase.CFrame, collisionBase.Size - Vector3.new(0.01, 0.01, 0.01))
	local overlap = false

	for _, part in overlappingParts do
		if part.Parent:FindFirstChild("Humanoid") then 
			if game.Players:FindFirstChild(part.Parent.Name) then
				overlap = true
				break
			else
				continue
			end
		elseif part.Parent == collisionBase.Parent then continue
		else
			overlap = true
			break
		end
	end

	canPlace = not overlap
	ChangeModelParts(buildingGhost)
end

--- Finalizes the placement of the building
function LocalBuilding.PlaceBuilding()
	if not buildingGhost then return end

	if canPlace then
		game.ReplicatedStorage.Events:FindFirstChild("PlaceBuilding", true):FireServer(buildingName, buildingGhost.PrimaryPart.CFrame, baseFolder.Buildings)
	end

	buildingGhost:Destroy()
	buildingGhost = nil
	buildingName = nil
end

--- Rotates the ghost model 90 degrees around the Y-axis
function LocalBuilding.RotateGhostModel()
	if not buildingGhost then return end

	buildingGhost:PivotTo(buildingGhost.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(90), 0))
end

return LocalBuilding
