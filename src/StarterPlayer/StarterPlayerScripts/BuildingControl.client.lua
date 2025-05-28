local LocalBuilding = require(game.ReplicatedStorage.LocalModules:FindFirstChild("LocalBuilding", true))
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local function onInputEnded(inputObject, processedEvent)
	-- First check if the "processedEvent" is true
	-- This indicates that another script had already processed the input, so this one is ignored.
	if processedEvent then return end

	-- Next, check that the input was a keyboard event
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		if inputObject.KeyCode == Enum.KeyCode.C then
			LocalBuilding.CreateGhostModel(game.ReplicatedStorage.Buildings:FindFirstChild("ArcherTower"):FindFirstChild("100"))
		elseif inputObject.KeyCode == Enum.KeyCode.Z then
			LocalBuilding.CreateGhostModel(game.ReplicatedStorage.Buildings:FindFirstChild("WizardTower"):FindFirstChild("100"))
		elseif inputObject.KeyCode == Enum.KeyCode.R then
			LocalBuilding.RotateGhostModel()
		end
	end
end

mouse.Move:Connect(function()
	LocalBuilding.UpdateGhostPosition()
end)
mouse.Button1Down:Connect(function()
	LocalBuilding.PlaceBuilding()
end)


UserInputService.InputEnded:Connect(onInputEnded)