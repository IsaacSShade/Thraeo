local player = game.Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("SelectMode")
local firstPlayer = gui.Frame.Frame.Right.FirstPlayer
local secondPlayer = gui.Frame.Frame.Right.SecondPlayer

local function UpdateGui(text1, text2)
	firstPlayer.TextBox.Text = text1
	secondPlayer.TextBox.Text = text2
end

local function DisableGui()
	local gui = player.PlayerGui:FindFirstChild("SelectMode")
	
	if gui then
		gui.Enabled = false
	end
end

local function UpdateMoneyGui(gold)
	local goldGui = player.PlayerGui:FindFirstChild("GoldGui")
	if goldGui then
		goldGui.Frame.Gold.Text = gold
	end
	
end

game.ReplicatedStorage.Events:FindFirstChild("UpdatePlayerGui", true).OnClientEvent:Connect(UpdateGui)
game.ReplicatedStorage.Events:FindFirstChild("UpdateMoneyUI", true).OnClientInvoke = UpdateMoneyGui
player.CharacterAdded:Connect(DisableGui)