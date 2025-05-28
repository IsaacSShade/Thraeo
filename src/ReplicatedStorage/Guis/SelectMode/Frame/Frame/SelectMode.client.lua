local player = game.Players.LocalPlayer
local gui = script.Parent.Parent.Parent
local playerVsAiButton = script.Parent.Left.PlayerVsAi
local joinTeamButton = script.Parent.Left.JoinTeam
local playerVsPlayerButton = script.Parent.Right.PlayerVsPlayer
local firstPlayer = script.Parent.Right.FirstPlayer
local secondPlayer = script.Parent.Right.SecondPlayer

-- 0 for player vs ai
-- 1 for player vs player
-- 2 for joining current game
local function startGame(twoPlayer, players)
	gui.Enabled = false
	game.ReplicatedStorage.Events.StartGame:FireServer(twoPlayer, players)
end

--TODO: Make this a server bindable function event thing.

local function checkPlayerConfirmation()
	local firstName = firstPlayer.TextBox.Text
	local secondName = secondPlayer.TextBox.Text
	task.wait(3)
	if firstPlayer.TextBox.Text == firstName and secondPlayer.TextBox.Text == secondName then
		local players = {game.Players:FindFirstChild(firstName), game.Players:FindFirstChild(secondName)}
		startGame(1, players)
	end
end

local function PlayerVsPlayerClick()
		
	if firstPlayer.TextBox.Text == ""  then
		firstPlayer.TextBox.Text = player.Name
		
	elseif secondPlayer.TextBox.Text == player.Name then
		secondPlayer.TextBox.Text = ""
		
	elseif firstPlayer.TextBox.Text == player.Name then
		firstPlayer.TextBox.Text = ""
		
		if secondPlayer.TextBox.Text ~= "" then
			firstPlayer.TextBox.Text = secondPlayer.TextBox.Text
			secondPlayer.TextBox.Text = ""
		end

		
	elseif firstPlayer.TextBox.Text ~= player.Name then
		secondPlayer.TextBox.Text = player.Name
		
		spawn(checkPlayerConfirmation)
	else
		return
	end
	
	game.ReplicatedStorage.Events.UpdatePlayerGui:FireServer(firstPlayer.TextBox.Text, secondPlayer.TextBox.Text)
end

playerVsAiButton.MouseButton1Click:Connect(function()
	startGame(0)
end)

joinTeamButton.MouseButton1Click:Connect(function()
	startGame(2)
end)

playerVsPlayerButton.MouseButton1Click:Connect(PlayerVsPlayerClick)
