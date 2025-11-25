-- Destroy old stuff if exists
if getgenv().AimbotConnection then
    pcall(function()
        getgenv().AimbotConnection:Disconnect()
        getgenv().AimbotInputBegan:Disconnect()
        getgenv().AimbotInputEnded:Disconnect()
        if getgenv().AimbotFOVCircle then
            getgenv().AimbotFOVCircle:Remove()
            getgenv().AimbotFOVCircleOutline:Remove()
        end
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    Bind1 = Enum.KeyCode.LeftShift,
    Bind2 = Enum.KeyCode.E,
    UseBothBinds = false,

    AimPart = "Head",
    Smoothness = 2,

    FOV = 80,
    FOVColor = Color3.fromRGB(255,255,255),
    FOVOutlineColor = Color3.fromRGB(0,0,0),
    FOVTransparency = 1,
    FOVThickness = 1,

    IgnoreTeam = false,
    IgnoreDead = false,
    VisibilityCheck = false,

    Prediction = false,
    PredictionFactor = 0.15
}

local FOVCircleOutline = Drawing.new("Circle")
FOVCircleOutline.Visible = true
FOVCircleOutline.Color = Settings.FOVOutlineColor
FOVCircleOutline.Thickness = Settings.FOVThickness + 2
FOVCircleOutline.Radius = Settings.FOV
FOVCircleOutline.Filled = false
FOVCircleOutline.NumSides = 100
FOVCircleOutline.Transparency = Settings.FOVTransparency

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Color = Settings.FOVColor
FOVCircle.Thickness = Settings.FOVThickness
FOVCircle.Radius = Settings.FOV
FOVCircle.Filled = false
FOVCircle.NumSides = 100
FOVCircle.Transparency = Settings.FOVTransparency

getgenv().AimbotFOVCircle = FOVCircle
getgenv().AimbotFOVCircleOutline = FOVCircleOutline

local aiming = false
local lockedTarget = nil

getgenv().AimbotInputBegan = UserInputService.InputBegan:Connect(function(input)
    if Settings.UseBothBinds then
        if input.KeyCode == Settings.Bind1 or input.KeyCode == Settings.Bind2 then
            aiming = true
            lockedTarget = nil
        end
    else
        if input.KeyCode == Settings.Bind1 then
            aiming = true
            lockedTarget = nil
        end
    end
end)

getgenv().AimbotInputEnded = UserInputService.InputEnded:Connect(function(input)
    if Settings.UseBothBinds then
        if input.KeyCode == Settings.Bind1 or input.KeyCode == Settings.Bind2 then
            aiming = false
            lockedTarget = nil
        end
    else
        if input.KeyCode == Settings.Bind1 then
            aiming = false
            lockedTarget = nil
        end
    end
end)

local function alive(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function visible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return hit == part
end

local function valid(player)
    if not player or player == LocalPlayer then return false end
    if Settings.IgnoreTeam and player.Team == LocalPlayer.Team then return false end
    if not player.Character then return false end
    if Settings.IgnoreDead and not alive(player.Character) then return false end
    if not player.Character:FindFirstChild(Settings.AimPart) then return false end
    if Settings.VisibilityCheck and not visible(player.Character[Settings.AimPart]) then return false end
    return true
end

local function getClosest()
    local closest = nil
    local shortest = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if valid(plr) then
            local head = plr.Character[Settings.AimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

getgenv().AimbotConnection = RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()

    FOVCircle.Position = mousePos
    FOVCircleOutline.Position = mousePos

    if aiming then
        if not valid(lockedTarget) then
            lockedTarget = getClosest()
        end

        if lockedTarget and valid(lockedTarget) then
            local part = lockedTarget.Character[Settings.AimPart]
            local pos = part.Position

            if Settings.Prediction then
                local hrp = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pos = pos + hrp.Velocity * Settings.PredictionFactor
                end
            end

            local screen = Camera:WorldToViewportPoint(pos)
            local moveX = (screen.X - mousePos.X) / Settings.Smoothness
            local moveY = (screen.Y - mousePos.Y) / Settings.Smoothness
            mousemoverel(moveX, moveY)
        end
    else
        lockedTarget = nil
    end
end)
