if getgenv().AimbotConnection then
    getgenv().AimbotConnection:Disconnect()
    getgenv().AimbotInputBegan:Disconnect()
    getgenv().AimbotInputEnded:Disconnect()
    if getgenv().AimbotFOVCircle then
        getgenv().AimbotFOVCircle.FOVCircle:Remove()
        getgenv().AimbotFOVCircle.FOVCircleOutline:Remove()
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    Bind1 = Enum.KeyCode.LeftShift,
    Bind2 = Enum.KeyCode.LeftControl,
    UseBothBinds = false,
    AimPart = "Head",
    Smoothness = 2,
    FOV = 80,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVOutlineColor = Color3.fromRGB(0, 0, 0),
    FOVTransparency = 0.5,
    FOVThickness = 1,
    IgnoreTeam = true,
    VisibilityCheck = false,
    Prediction = false
}

local Thickness = Settings.FOVThickness
local FOV = Settings.FOV
local Color = Settings.FOVColor
local OutlineColor = Settings.FOVOutlineColor
local Transparency = Settings.FOVTransparency

local FOVCircleOutline = Drawing.new("Circle")
FOVCircleOutline.Visible = true
FOVCircleOutline.Color = OutlineColor
FOVCircleOutline.Thickness = Thickness + 2
FOVCircleOutline.Radius = FOV
FOVCircleOutline.Filled = false
FOVCircleOutline.NumSides = 100
FOVCircleOutline.Transparency = Transparency

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Color = Color
FOVCircle.Thickness = Thickness
FOVCircle.Radius = FOV
FOVCircle.Filled = false
FOVCircle.NumSides = 100
FOVCircle.Transparency = Transparency

getgenv().AimbotFOVCircle = {FOVCircle = FOVCircle, FOVCircleOutline = FOVCircleOutline}

local aiming = false
local lockedTarget = nil

getgenv().AimbotInputBegan = UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.Bind1 or input.KeyCode == Settings.Bind2 then
        aiming = true
        lockedTarget = nil
    end
end)

getgenv().AimbotInputEnded = UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Settings.Bind1 or input.KeyCode == Settings.Bind2 then
        aiming = false
        lockedTarget = nil
    end
end)

local function isValidTarget(player)
    if not player or not player.Character or not player.Character:FindFirstChild(Settings.AimPart) then return false end
    if Settings.IgnoreTeam and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    return true
end

local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isValidTarget(player) then
            local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character[Settings.AimPart].Position)
            if onScreen then
                local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

getgenv().AimbotConnection = RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircleOutline.Position = mousePos
    FOVCircle.Position = mousePos

    if aiming then
        if not lockedTarget or not isValidTarget(lockedTarget) then
            lockedTarget = getClosestPlayer()
        end

        if lockedTarget and isValidTarget(lockedTarget) then
            local targetPos = lockedTarget.Character[Settings.AimPart].Position
            local screenPos = Camera:WorldToViewportPoint(targetPos)
            local moveX = (screenPos.X - mousePos.X) / Settings.Smoothness
            local moveY = (screenPos.Y - mousePos.Y) / Settings.Smoothness
            mousemoverel(moveX, moveY)
        end
    else
        lockedTarget = nil
    end
end)
