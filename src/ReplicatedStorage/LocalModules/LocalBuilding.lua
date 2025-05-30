-- LocalBuilding.lua
-- Handles ghost building creation, placement, and interactions

local LocalBuilding = {}

local Config = require(game.ReplicatedStorage:FindFirstChild("Config", true))
local Players = game:GetService("Players")

-- Local Variables
local player       = Players.LocalPlayer
local mouse        = player:GetMouse()
local buildingGhost
local buildingName
local baseFolder
local canPlace = false

-- Helper: color & transparency based on validity
local function ChangeModelParts(model, transparency)
	transparency = transparency or 0.5
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			part.Transparency = transparency
			part.CanCollide  = false
			part.Color       = canPlace
				and Config.PLACEMENT_VALID_COLOR
				or Config.PLACEMENT_INVALID_COLOR
			part.Material    = Enum.Material.Neon
		else
			part:Destroy()
		end
	end
end

--- Creates a ghost model for placement
function LocalBuilding.CreateGhostModel(model)
	if workspace:FindFirstChild("BuildingGhost") then return end

	local playerTeam = game.ReplicatedStorage.Events
		:FindFirstChild("GetTeamFromPlayer", true)
		:InvokeServer()

	if not baseFolder then
		baseFolder = playerTeam.base
	end

	buildingName = model.Parent.Name
	if playerTeam.gold < Config.BUILDING_COSTS[buildingName] then
		return
	end

	buildingGhost = model:Clone()
	buildingGhost.Name = "BuildingGhost"
	ChangeModelParts(buildingGhost)
	buildingGhost.Parent = workspace
end

--- Updates the ghost’s position based on the mouse
function LocalBuilding.UpdateGhostPosition()
	if not buildingGhost then return end

	mouse.TargetFilter = buildingGhost

	local targetPos    = mouse.Hit.Position
	local collisionBase = buildingGhost.CollisionBase
	local gridPos      = Vector3.new(
		math.floor(targetPos.X/10)*10,
		Config.BUILDING_Z_HEIGHT,
		math.floor(targetPos.Z/10)*10
	)

	local castleBase = baseFolder:FindFirstChild(Config.BASE_FOUNDATION_NAME)
	local halfSize   = Config.BASE_SIZE/2
	local baseXMax   = halfSize - (collisionBase.Size.X/2)
	local baseZMax   = halfSize - (collisionBase.Size.Z/2)

	buildingGhost:SetPrimaryPartCFrame(
		CFrame.new(gridPos) * buildingGhost.PrimaryPart.CFrame.Rotation
	)

	-- out-of-bounds?
	if math.abs(gridPos.X - castleBase.Position.X) > baseXMax
		or  math.abs(gridPos.Z - castleBase.Position.Z) > baseZMax then
		ChangeModelParts(buildingGhost, 1)
		canPlace = false
		return
	end

	-- collision check
	local overlap = false
	for _, part in ipairs(
		workspace:GetPartBoundsInBox(
			collisionBase.CFrame,
			collisionBase.Size - Vector3.new(0.01,0.01,0.01)
		)
		) do
		if part.Parent:FindFirstChild("Humanoid") then
			if Players:FindFirstChild(part.Parent.Name) then
				overlap = true
				break
			end
		elseif part.Parent ~= collisionBase.Parent then
			overlap = true
			break
		end
	end

	canPlace = not overlap
	ChangeModelParts(buildingGhost)
end

--- Finalizes placement
function LocalBuilding.PlaceBuilding()
	if not buildingGhost then return end

	if canPlace then
		game.ReplicatedStorage.Events
			:FindFirstChild("PlaceBuilding", true)
			:FireServer(
				buildingName,
				buildingGhost.PrimaryPart.CFrame,
				baseFolder.Buildings
			)
	end

	buildingGhost:Destroy()
	buildingGhost = nil
	buildingName = nil
end

--- Rotates the ghost 90° around Y
function LocalBuilding.RotateGhostModel()
	if not buildingGhost then return end
	buildingGhost:PivotTo(
		buildingGhost.PrimaryPart.CFrame
			* CFrame.Angles(0, math.rad(90), 0)
	)
end

return LocalBuilding
