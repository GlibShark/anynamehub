local player = game.Players.LocalPlayer
local flySpeed = 390.45
local flyDuration = 21
local centerPosition = Vector3.new(0, 100, 0)
local chestPosition = Vector3.new(15, -5, 9495)
local totalCoins = 0
local autoFarming = false
local bodyVelocity
local gui
local dragging, dragInput, dragStart, startPos

local function makeDraggable(frame)
	frame.Active = true
	frame.Draggable = false

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

gui = Instance.new("ScreenGui")
gui.Name = "BABFTGui"
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Name = "AutoFarmFrame"
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.02, 0, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = gui
makeDraggable(frame)

local uicorner = Instance.new("UICorner", frame)
uicorner.CornerRadius = UDim.new(0, 10)

local padding = Instance.new("UIPadding", frame)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)

local coinsLabel = Instance.new("TextLabel", frame)
coinsLabel.Size = UDim2.new(1, 0, 0.4, 0)
coinsLabel.Position = UDim2.new(0, 0, 0, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "Coins: 0"
coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 16
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Size = UDim2.new(1, 0, 0.4, 0)
toggleButton.Position = UDim2.new(0, 0, 0.45, 0)
toggleButton.Text = "Start Auto Farm"
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14

local uicornerBtn = Instance.new("UICorner", toggleButton)
uicornerBtn.CornerRadius = UDim.new(0, 8)

coinsLabel.Parent = frame
toggleButton.Parent = frame

local function enableNoclip(character)
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function stopFlying()
	if bodyVelocity then
		bodyVelocity:Destroy()
	end
end

local function teleportToTeamBase()
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(Vector3.new(0, 10, 0))
	end
end

local function startAutoFarm()
	spawn(function()
		while autoFarming do
			local character = player.Character or player.CharacterAdded:Wait()
			local hrp = character:FindFirstChild("HumanoidRootPart")

			if hrp then
				hrp.CFrame = CFrame.new(centerPosition)
				enableNoclip(character)

				bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
				bodyVelocity.Velocity = Vector3.new(0, 0, flySpeed)
				bodyVelocity.Parent = hrp

				wait(flyDuration)

				stopFlying()
				hrp.CFrame = CFrame.new(chestPosition)

				character:BreakJoints()

				if totalCoins < 10000000 then
					totalCoins += 80
					coinsLabel.Text = "Coins: " .. totalCoins
				end

				wait(9)
			end
		end
	end)
end

toggleButton.MouseButton1Click:Connect(function()
	autoFarming = not autoFarming
	toggleButton.Text = autoFarming and "Stop Auto Farm" or "Start Auto Farm"
	if autoFarming then
		startAutoFarm()
	else
		stopFlying()
		teleportToTeamBase()
	end
end)
