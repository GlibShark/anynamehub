local RoleAimbot = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local Enabled = false
local AimRange = 100
local AimSpeed = 5

local roles = {}
local Murder, Sheriff, Hero

local function IsAlive(player)
	local data = roles[player.Name]
	return data and not data.Dead and not data.Killed
end

local function UpdateRoles()
	local data = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
	if not data then return end
	roles = data
	Murder, Sheriff, Hero = nil, nil, nil
	for name, info in pairs(data) do
		if info.Role == "Murderer" then
			Murder = name
		elseif info.Role == "Sheriff" then
			Sheriff = name
		elseif info.Role == "Hero" then
			Hero = name
		end
	end
end

local function GetTarget()
	if not roles then return end
	local myRole = roles[LP.Name] and roles[LP.Name].Role
	if not myRole then return end

	local closestPlayer = nil
	local closestDist = AimRange

	local function isPriorityTarget(player)
		return player.Name == Sheriff or player.Name == Hero
	end

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LP and player.Character and IsAlive(player) then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
				if distance <= closestDist then
					if myRole == "Murderer" then
						if isPriorityTarget(player) then
							closestPlayer = player
							closestDist = distance
						elseif not closestPlayer or not isPriorityTarget(closestPlayer) then
							closestPlayer = player
							closestDist = distance
						end
					elseif (myRole == "Sheriff" or myRole == "Hero") and player.Name == Murder then
						closestPlayer = player
						closestDist = distance
					end
				end
			end
		end
	end

	return closestPlayer
end

local function AimAt(target)
	if not target or not target.Character then return end
	local hrp = target.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local targetPos = hrp.Position
	local cameraPos = Camera.CFrame.Position
	local direction = (targetPos - cameraPos).Unit
	local targetCF = CFrame.new(cameraPos, cameraPos + direction)

	local currentCF = Camera.CFrame
	local alpha = math.clamp(AimSpeed * RunService.RenderStepped:Wait(), 0, 1)
	Camera.CFrame = currentCF:Lerp(targetCF, alpha)
end

RunService.RenderStepped:Connect(function()
	if not Enabled then return end
	UpdateRoles()
	local target = GetTarget()
	if target then
		AimAt(target)
	end
end)

function RoleAimbot:SetEnabled(state)
	Enabled = state
end

function RoleAimbot:SetRange(val)
	AimRange = val
end

function RoleAimbot:SetSpeed(val)
	AimSpeed = val
end

return RoleAimbot
