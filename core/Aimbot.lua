-- // services & variables
local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()
local Camera         = workspace.CurrentCamera

-- // config
local AIMBOT = {
    Enabled          = true,
    Key              = Enum.KeyCode.Q,
    TeamCheck        = true,
    VisibleCheck     = true,
    FOV              = 250,                     -- circle radius in pixels
    Smoothness       = 0.55,                    -- 0.1 = very smooth/slow, 1 = instant/snappy
    TargetPart       = "Head",                  -- "Head", "HumanoidRootPart", "UpperTorso" etc
    MouseMoveMethod  = "mousemoverel",          -- only one implemented here
}

-- // globals / state
local fovCircle      = nil
local connections    = {}
local aiming         = false
local currentTarget  = nil

-- // create fov circle (if Drawing lib exists - most good exploits have it)
local function createFOV()
    if Drawing and not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 2
        fovCircle.NumSides = 64
        fovCircle.Radius = AIMBOT.FOV
        fovCircle.Filled = false
        fovCircle.Color = Color3.fromRGB(255, 50, 50)
        fovCircle.Transparency = 0.8
        fovCircle.Visible = false
    end
end

-- // get closest enemy in FOV
local function getClosest()
    local closest, dist = nil, AIMBOT.FOV

    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        if AIMBOT.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then continue end

        local part = char:FindFirstChild(AIMBOT.TargetPart) or char:FindFirstChild("Head")
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        -- visible check (raycast from camera → part)
        if AIMBOT.VisibleCheck then
            local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 5000)
            local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character or {}})
            if hit and hit:IsDescendantOf(char) == false then continue end
        end

        local mag = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
        if mag < dist then
            dist = mag
            closest = {Player = player, Part = part, ScreenPos = screenPos}
        end
    end

    return closest
end

-- // mouse movement logic
local function moveMouse(targetScreenPos)
    if AIMBOT.MouseMoveMethod ~= "mousemoverel" then return end

    local current = Vector2.new(Mouse.X, Mouse.Y)
    local delta   = (targetScreenPos - current) * AIMBOT.Smoothness

    mousemoverel(delta.X, delta.Y)
end

-- // main loop
local function aimLoop()
    if not AIMBOT.Enabled then
        currentTarget = nil
        return
    end

    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then   -- hold RMB to aim
        aiming = true
    else
        aiming = false
        currentTarget = nil
        return
    end

    if not aiming then return end

    currentTarget = getClosest()

    if currentTarget and currentTarget.ScreenPos then
        moveMouse(Vector2.new(currentTarget.ScreenPos.X, currentTarget.ScreenPos.Y))
    end
end

-- // toggle
local function onInputBegan(input, gpe)
    if gpe then return end
    if input.KeyCode == AIMBOT.Key then
        AIMBOT.Enabled = not AIMBOT.Enabled
        if fovCircle then
            fovCircle.Visible = AIMBOT.Enabled
        end
        print("[Aimbot] " .. (AIMBOT.Enabled and "ON" or "OFF"))
    end
end

-- // init
local function init()
    createFOV()

    -- update fov circle position
    table.insert(connections, RunService.RenderStepped:Connect(function()
        if fovCircle and fovCircle.Visible then
            fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
        end
    end))

    table.insert(connections, RunService.RenderStepped:Connect(aimLoop))
    table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))

    print("[Aimbot] Loaded - press " .. AIMBOT.Key.Name .. " to toggle")
end

-- // cleanup (optional - call when unloading feature)
local function unload()
    for _, conn in connections do conn:Disconnect() end
    connections = {}
    if fovCircle then fovCircle:Remove() end
end

-- // start
init()

-- // example: expose toggle if your hub has UI
-- getgenv().AimbotToggle = function() AIMBOT.Enabled = not AIMBOT.Enabled end
