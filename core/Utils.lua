local Utils = {}

local Camera    = workspace.CurrentCamera
local V2New     = Vector2.new
local Floor     = math.floor
local Tan       = math.tan
local Rad       = math.rad

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

function Utils.WorldToScreen(WorldPos)
    local Screen, OnScreen = Camera:WorldToViewportPoint(WorldPos)
    return V2New(Screen.X, Screen.Y), OnScreen
end

function Utils.GetDistance(Position)
    return (Position - Camera.CFrame.Position).Magnitude
end

function Utils.CalculateBoxSize(Model, Distance)
    local Size        = Model:GetExtentsSize()
    local FrustumH    = Tan(Rad(Camera.FieldOfView / 2)) * 2 * Distance
    local Scale       = Camera.ViewportSize.Y / FrustumH
    return V2New(Floor(Size.X * Scale), Floor(Size.Y * Scale))
end

function Utils.GetCamera()
    return Camera
end

getgenv().HubUtils = Utils
return Utils
