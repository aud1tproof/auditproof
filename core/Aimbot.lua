-- // auditproof/games/BadBusiness.lua  (or wherever you want to inject it)
-- Simple silent-ish aimbot → head only, using mousemoverel()
-- WARNING: extremely detectable in 2026 Bad Business (Byfron + Hyperion are aggressive)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Config
local AIMBOT_ENABLED = true               -- toggle with key or UI later
local AIM_KEY = Enum.KeyCode.LeftAlt      -- hold to aim
local AIM_PART = "Head"                   -- or "HumanoidRootPart" if you want torso
local SMOOTHNESS = 0.55                   -- 0.1 = instant snap, 1 = very slow
local FOV_RADIUS = 150                    -- pixels, larger = easier to acquire
local TEAM_CHECK = true
local WALL_CHECK = true                   -- basic raycast visibility

-- Globals
local CurrentTarget = nil

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if not player.Character or not player.Character:FindFirstChild(AIM_PART) then return false end
    if player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then return false end
    
    if TEAM_CHECK and player.Team == LocalPlayer.Team then return false end
    
    if WALL_CHECK then
        local headPos = player.Character[AIM_PART].Position
        local ray = Ray.new(Camera.CFrame.Position, (headPos - Camera.CFrame.Position).Unit * 500)
        local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
        if hit and hit:IsDescendantOf(player.Character) then
            -- visible
        else
            return false
        end
    end
    
    -- FOV check (screen-space)
    local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character[AIM_PART].Position)
    if not onScreen then return false end
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
    if dist > FOV_RADIUS then return false end
    
    return true, dist, screenPos
end

local function findClosestTarget()
    local closest = nil
    local closestDist = FOV_RADIUS + 1
    
    for _, player in ipairs(Players:GetPlayers()) do
        local valid, dist = isValidTarget(player)
        if valid and dist < closestDist then
            closest = player
            closestDist = dist
        end
    end
    
    return closest
end

-- Main loop
RunService.RenderStepped:Connect(function(delta)
    if not AIMBOT_ENABLED then 
        CurrentTarget = nil
        return 
    end
    
    if UserInputService:IsKeyDown(AIM_KEY) then
        if not CurrentTarget or not isValidTarget(CurrentTarget) then
            CurrentTarget = findClosestTarget()
        end
        
        if CurrentTarget then
            local head = CurrentTarget.Character and CurrentTarget.Character:FindFirstChild(AIM_PART)
            if head then
                local targetPos = head.Position
                -- Very basic prediction (you can improve with velocity + ping)
                local dist = (targetPos - Camera.CFrame.Position).Magnitude
                local predOffset = head.Velocity * (dist / 200) * 0.033  -- rough guess
                targetPos += predOffset
                
                local screenPos = Camera:WorldToViewportPoint(targetPos)
                local mousePos = Vector2.new(Mouse.X, Mouse.Y + 36) -- gui inset hack
                
                local deltaX = (screenPos.X - mousePos.X)
                local deltaY = (screenPos.Y - mousePos.Y)
                
                -- Apply smoothing
                deltaX = deltaX * SMOOTHNESS
                deltaY = deltaY * SMOOTHNESS
                
                mousemoverel(deltaX, deltaY)
            end
        end
    else
        CurrentTarget = nil
    end
end)

-- Optional: toggle with insert key or whatever
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        AIMBOT_ENABLED = not AIMBOT_ENABLED
        print("Aimbot " .. (AIMBOT_ENABLED and "ON" or "OFF"))
    end
end)

print("[auditproof] Head Aimbot loaded (mousemoverel) - hold LeftAlt / toggle with Insert")
