local tool = script.Parent
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local cooldown = false

local DAMAGE = 10
local DELAY = 0.2

mouse.Button1Down:Connect(function()
	if tool.Parent == player.Character and cooldown == false then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {player.Character, tool}

		local origin = player.Character.PrimaryPart.Position
		local direction = (mouse.Hit.Position - origin)

		local result = workspace:Raycast(origin, direction, raycastParams)
		
		if result and result.Instance.Parent:FindFirstChild("Humanoid") then
			local character = result.Instance.Parent
			local getTeamFunction = game.ReplicatedStorage:FindFirstChild("GetTeamFromPlayer", true)
			
			if game.Players:FindFirstChild(character.Name) then
				if getTeamFunction:InvokeServer(game.Players:FindFirstChild(character.Name)).color == getTeamFunction:InvokeServer(player).color then
					return
				end
			elseif game.ReplicatedStorage.Events:FindFirstChild("GetNpcTeamColor"):InvokeServer(character) == getTeamFunction:InvokeServer(player).color  then
				return
			end
			
			cooldown = true
			game.ReplicatedStorage.Events.Damage:FireServer(result.Instance.Parent, DAMAGE)
			task.wait(DELAY)
			cooldown = false
		end
	end
end)