-- Destroy old stuff if exists
if getgenv().AimbotConnection then
    getgenv().AimbotConnection:Disconnect()
    getgenv().AimbotInputBegan:Disconnect()
    getgenv().AimbotInputEnded:Disconnect()
    if getgenv().AimbotFOVCircle then
        getgenv().AimbotFOVCircle:Remove()
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- SETTINGS TABLE
local Settings = {
    Bind1 = Enum.KeyCode.LeftShift,
    Bind2 = Enum.KeyCode.LeftControl,
    UseBothBinds = false, -- if true, either bind works
    AimPart = "Head",
    Smoothness = 2,
    FOV = 80,
    FOVColor = Color3.fromRGB(255, 0, 0),
    FOVTransparency = 0.5,
    FOVThickness = 2,
    IgnoreTeam = true,
    VisibilityCheck = true
}

local fovCircle = Drawing.new("Circle")
fovCircle.Color = Settings.FOVColor
fovCircle.Thickness = Settings.FOVThickness
fovCircle.Transparency = Settings.FOVTransparency
fovCircle.Filled = false
fovCircle.Visible = true
fovCircle.Radius = Settings.FOV

getgenv().AimbotFOVCircle = fovCircle

local aiming = false
local lockedTarget = nil

getgenv().AimbotInputBegan = UserInputService.InputBegan:Connect(function(input)
    if (input.KeyCode == Settings.Bind1 or input.KeyCode == Settings.Bind2) and Settings.UseBothBinds then
        aiming = true
        lockedTarget = nil
    elseif input.KeyCode == Settings.Bind1 and not Settings.UseBothBinds then
        aiming = true
        lockedTarget = nil
    elseif input.KeyCode == Settings.Bind2 and not Settings.UseBothBinds then
        aiming = true
        lockedTarget = nil
    end
end)

getgenv().AimbotInputEnded = UserInputService.InputEnded:Connect(function(input)
    if (input.KeyCode == Settings.Bind1 or input.KeyCode == Settings.Bind2) and Settings.UseBothBinds then
        aiming = false
        lockedTarget = nil
    elseif input.KeyCode == Settings.Bind1 and not Settings.UseBothBinds then
        aiming = false
        lockedTarget = nil
    elseif input.KeyCode == Settings.Bind2 and not Settings.UseBothBinds then
        aiming = false
        lockedTarget = nil
    end
end)

local function isVisible(targetPart)
    if not Settings.VisibilityCheck then return true end
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin).Unit * (targetPart.Position - rayOrigin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if rayResult then
        if rayResult.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        else
            return false
        end
    end
    return true
end

local function isValidTarget(player)
    if not player or not player.Character or not player.Character:FindFirstChild(Settings.AimPart) then
        return false
    end
    if Settings.IgnoreTeam and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    if Settings.VisibilityCheck and not isVisible(player.Character[Settings.AimPart]) then
        return false
    end
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
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)

    if aiming then
        if not lockedTarget or not isValidTarget(lockedTarget) then
            lockedTarget = getClosestPlayer()
        end

        if lockedTarget and isValidTarget(lockedTarget) then
            local targetPos = Camera:WorldToViewportPoint(lockedTarget.Character[Settings.AimPart].Position)
            local moveX = (targetPos.X - mousePos.X) / Settings.Smoothness
            local moveY = (targetPos.Y - mousePos.Y) / Settings.Smoothness
            mousemoverel(moveX, moveY)
        end
    else
        lockedTarget = nil
    end
end)
