-- Global Environment / Global Environment Variables 
_G.Kukri = {
	Binds =  {
		FOV = Enum.UserInputType.MouseButton1,
		Tween = Enum.UserInputType.MouseButton2,
		Rotate = Enum.KeyCode.C
	},

	Tween = {
		Time = 0,
		EasingStyle = Enum.EasingStyle.Linear,
		EasingDirection = Enum.EasingDirection.Out,
		RepeatCount = 0,
		Reverses = false,
		DelayTime = 0,

		Exceptions = {
			Team = true,
			Death = true,
			Group = true,
			Client = true,
			Downed = true,
			Friend = true,
			Radius = true,
			Surface = true
		}
	},

	Visuals = {
		FOV = {
			Color = Color3.fromRGB(0, 255, 255),
			Filled = false,
			Radius = 150,
			Visible = true,
			Thickness = 1,
			Transparency = 1
		}
	},

	Miscellaneous = {
		Rotate = {
			Speed = 0,
			Degrees = 0
		}
	}
}

local GlobalEnvironment = _G.Kukri
local Binds = GlobalEnvironment.Binds

local Tween = GlobalEnvironment.Tween
local Exceptions = Tween.Exceptions

local Visuals = GlobalEnvironment.Visuals
local FOV = Visuals.FOV
FOV.Circle = Drawing.new("Circle")

local Miscellaneous = GlobalEnvironment.Miscellaneous
local Rotate = Miscellaneous.Rotate

GlobalEnvironment.Part = nil 
GlobalEnvironment.Found = false
GlobalEnvironment.Target = nil 

-- Services / Service Variables

local Players = game:GetService("Players") 
local LocalPlayer = Players.LocalPlayer
local GetMouse = LocalPlayer:GetMouse()

local Workspace = game:GetService("Workspace")
local CurrentCamera = Workspace.CurrentCamera

local GuiService = game:GetService("GuiService")
local GetGuiInset = GuiService:GetGuiInset()

local RunService = game:GetService("RunService")
local RenderStepped = RunService.RenderStepped

local TweenService = game:GetService("TweenService")

local UserInputService = game:GetService("UserInputService")
local InputBegan = UserInputService.InputBegan
local InputEnded = UserInputService.InputEnded

-- Global Environment Functions

function GlobalEnvironment.GetMouseLocationV2()
	local GetMouseLocationDefault = Vector2.new(GetMouse.X, GetMouse.Y) + Vector2.new(GetGuiInset.X, GetGuiInset.Y)
	local UserInputServiceGetMouseLocation = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
	return GetMouseLocationDefault or UserInputServiceGetMouseLocation
end

function GlobalEnvironment.GetTarget()    
	local closestPart, closestTarget = nil, nil
	local closestPartDelta, closestTargetDelta = math.huge, math.huge

	for _, Target in pairs(Players:GetPlayers()) do
		local function exceptClient()
			return Exceptions.Client and Target == LocalPlayer
		end

		if not exceptClient() and Target.Character then 
			local Character = Target.Character 
			local PrimaryPart = Character.PrimaryPart

			if PrimaryPart then
				local PartPosition, InViewport = CurrentCamera:WorldToViewportPoint(PrimaryPart.Position)

				if InViewport then 
					local Delta = (Vector2.new(PartPosition.X, PartPosition.Y) - GlobalEnvironment.GetMouseLocationV2()).Magnitude

					local function exceptRadius()
						return Exceptions.Radius and Delta > FOV.Radius
					end

					if Delta < closestTargetDelta and not exceptRadius() then 
						closestTargetDelta = Delta 
						closestTarget = Target
					end
				end
			end
		end
	end

	if GlobalEnvironment.Target and GlobalEnvironment.Target.Character then 
		local Character = GlobalEnvironment.Target.Character 

		for _, Part in pairs(Character:GetChildren()) do 
			if Part:IsA("BasePart") then 
				local PartPosition, InViewport = CurrentCamera:WorldToViewportPoint(Part.Position)

				if InViewport then 
					local Delta = (Vector2.new(PartPosition.X, PartPosition.Y) - GlobalEnvironment.GetMouseLocationV2()).Magnitude 

					if Delta < closestPartDelta then 
						closestPartDelta = Delta
						closestPart = Part 
					end
				end
			end
		end
	end

	return closestPart, closestTarget
end

function GlobalEnvironment.onRenderStepped()
	if GlobalEnvironment.Part and GlobalEnvironment.Target then
		print("Part: " .. tostring(GlobalEnvironment.Part))
		print("Target: " .. GlobalEnvironment.Target.Name)
	end
end

-- FOV Functions

function FOV.onRenderStepped()
	local Circle = FOV.Circle

	Circle.Color = FOV.Color 
	Circle.Filled = FOV.Filled
	Circle.Radius = FOV.Radius 
	Circle.Visible = FOV.Visible 
	Circle.Thickness = FOV.Thickness
	Circle.Transparency = FOV.Transparency
	Circle.Position = GlobalEnvironment.GetMouseLocationV2()
end

-- Tween / Tween.Exceptions Functions 

function Exceptions.exceptSurface()
	if game.PlaceId == 286090429 then 
		if GlobalEnvironment.Target and GlobalEnvironment.Target.Character then 
			local Character = GlobalEnvironment.Target.Character
			local PrimaryPart = Character.PrimaryPart 

			if PrimaryPart and Exceptions.Surface and PrimaryPart.Position.Y < -10 then 
				return true 
			end
		end
	end

	return false 
end

function Exceptions.exceptTeam()
	if game.PlaceId == 286090429 then 
		if GlobalEnvironment.Target then 
			if Exceptions.Team and LocalPlayer.Team == GlobalEnvironment.Target.Team then 
				return true 
			end
		end
	end

	return false 
end

function Exceptions.exceptDeath()
	if GlobalEnvironment.Target and GlobalEnvironment.Target.Character then 
		local Character = GlobalEnvironment.Target.Character 
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")

		if Humanoid then 
			local function GetMin()
				if game.PlaceId == 286090429 then 
					return 0
				else
					return 40
				end
			end

			if Exceptions.Death and Humanoid.Health < GetMin() then
				return true 
			end
		end
	end

	return false 
end

function Tween.Create()
	local tweenInfo = TweenInfo.new(Tween.Time, Tween.EasingStyle, Tween.EasingDirection, Tween.RepeatCount, Tween.Reverses, Tween.DelayTime)
	return TweenService:Create(CurrentCamera, tweenInfo, {CFrame = CFrame.new(CurrentCamera.CFrame.Position, GlobalEnvironment.Part.Position)})
end

function Tween.onRenderStepped()
	if GlobalEnvironment.Found and GlobalEnvironment.Part and GlobalEnvironment.Target then 
		if not Exceptions.exceptTeam() and not Exceptions.exceptDeath() and not Exceptions.exceptSurface() then 
			local TweenAnimation = Tween.Create()
			TweenAnimation:Play()
		else
			GlobalEnvironment.Found = false
			GlobalEnvironment.Part = nil 
		end 
	end
end

-- Events

InputBegan:Connect(function(InputObject, gameProcessedEvent)
	local function Check(Bind)
		if (InputObject.KeyCode == Bind or InputObject.UserInputType == Bind) and Bind ~= "None" then 
			return true 
		else 
			return false
		end
	end

	if Check(Binds.FOV) then 
		FOV.Visible = not FOV.Visible 
	elseif Check(Binds.Tween) then 
		GlobalEnvironment.Found = true 
		GlobalEnvironment.Part, GlobalEnvironment.Target = GlobalEnvironment.GetTarget()
	end
end)

InputEnded:Connect(function(InputObject, gameProcessedEvent)
	local function Check(Bind)
		if (InputObject.KeyCode == Bind or InputObject.UserInputType == Bind) and Bind ~= "None" then 
			return true 
		else 
			return false
		end
	end

	if Check(Binds.Tween) then 
		GlobalEnvironment.Found = false
		GlobalEnvironment.Part = nil
	end
end)

RenderStepped:Connect(function() 
	FOV.onRenderStepped()
	Tween.onRenderStepped()
	GlobalEnvironment.onRenderStepped()
end)
