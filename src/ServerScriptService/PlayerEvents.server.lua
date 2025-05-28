local Players = game:GetService("Players")

local Team = require(game.ServerScriptService:FindFirstChild("Team", true))
local NPC = require(game.ServerScriptService:FindFirstChild("NPC", true))


local function OnCharacterAdded(character, player)
	local playerTeam = Team.GetTeamFromPlayer(player)
	character.Humanoid.WalkSpeed = 20
	playerTeam:AddGold(0)
	
	character.Humanoid.Died:Connect(function()
		-- award money to killer
		local PartsInRegion = workspace:GetPartBoundsInRadius(character.PrimaryPart.CFrame.Position, 50)
		for _,part in PartsInRegion do
			if part.Parent:FindFirstChild("Humanoid") and part.Parent.Humanoid.Health ~= 0 then
				local killer = part.Parent
				local enemyTeam
				
				if game.Players:FindFirstChild(killer.Name) then
					enemyTeam = Team.GetTeamFromPlayer(game.Players:FindFirstChild(killer.Name))
				else
					enemyTeam = Team.GetTeamFromColor(NPC.entities[killer].teamColor)
				end
				
				if enemyTeam == playerTeam then
					continue
				end
				
				local amountChanged = math.floor(playerTeam.gold / 2)

				playerTeam:SubtractGold(amountChanged)
				enemyTeam:AddGold(amountChanged)
				break
			end
		end
		-- respawn player
		player:LoadCharacter()
	end)
end

local function OnPlayerJoin(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = game.ReplicatedStorage.Guis.SelectMode:Clone()
	gui.Parent = playerGui
	
	player.CharacterAdded:Connect(function(character)
		OnCharacterAdded(character, player)
	end)
end

game.Players.PlayerAdded:Connect(OnPlayerJoin)