local Settings   = getgenv().HubSettings
local Utils      = getgenv().HubUtils
local DrawingLib = getgenv().HubDrawing

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TeamService    = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Floor       = math.floor
local V2New       = Vector2.new

local Tortoiseshell = getupvalue(require(ReplicatedStorage.TS), 1)
local Characters    = getupvalue(Tortoiseshell.Characters.GetCharacter, 1)

local function GetCharacter(Player)
    local Char = Characters[Player]
    if not Char or Char.Parent == nil then return end
    return Char, Char.PrimaryPart
end

local function GetHealth(Character)
    local H = Character.Health
    return H.Value, H.MaxHealth.Value, H.Value > 0
end

local function GetPlayerTeam(Player)
    for _, Team in pairs(TeamService:GetChildren()) do
        if Team.Players:FindFirstChild(Player.Name) then
            return Team.Name
        end
    end
end

local function IsEnemy(Player)
    local t1 = GetPlayerTeam(Player)
    local t2 = GetPlayerTeam(LocalPlayer)
    return t2 ~= t1 or t1 == "FFA"
end

-- management

local ESPObjects = {}

local function AddESP(Player)
    if ESPObjects[Player] then return end
    ESPObjects[Player] = { Player = Player, Drawing = DrawingLib.CreateESP() }
end

local function RemoveESP(Player)
    local esp = ESPObjects[Player]
    if not esp then return end
    DrawingLib.Clear(esp.Drawing)
    ESPObjects[Player] = nil
end

local function UpdateESP(esp)
    local Player  = esp.Player
    local D       = esp.Drawing
    local S       = Settings

    local function HideAll()
        D.Box.Visible              = false
        D.BoxOutline.Visible       = false
        D.HealthBar.Main.Visible   = false
        D.HealthBar.Outline.Visible = false
    end

    local Char, Root = GetCharacter(Player)
    if not Char or not Root then HideAll() return end

    local ScreenPos, OnScreen = Utils.WorldToScreen(Root.Position)
    local Distance            = Utils.GetDistance(Root.Position)
    local Health, MaxHealth, Alive = GetHealth(Char)
    local Enemy               = IsEnemy(Player)
    local TeamCheck           = (not S.TeamCheck) or Enemy

    if not (OnScreen and Alive and TeamCheck) then HideAll() return end

    local BoxSize  = Utils.CalculateBoxSize(Char, Distance)
    local hw, hh   = BoxSize.X / 2, BoxSize.Y / 2
    local sx, sy   = ScreenPos.X, ScreenPos.Y
    local YOffset  = hh * 0.5
    local TopLeft  = V2New(Floor(sx - hw), Floor(sy - hh + YOffset))
    local Color    = Enemy and S.EnemyColor or S.AllyColor
    local Thick    = S.BoxThickness

    D.Box.Visible   = true
    D.Box.Color     = Color
    D.Box.Thickness = Thick
    D.Box.Position  = TopLeft
    D.Box.Size      = BoxSize

    D.BoxOutline.Visible   = S.Outline
    D.BoxOutline.Thickness = Thick + 2
    D.BoxOutline.Position  = TopLeft
    D.BoxOutline.Size      = BoxSize

    local TooSmall = BoxSize.Y < 18
    D.HealthBar.Main.Visible    = S.HealthBar and not TooSmall
    D.HealthBar.Outline.Visible = D.HealthBar.Main.Visible and S.Outline

    if D.HealthBar.Main.Visible then
        local Pct       = Health / MaxHealth
        local BarW      = Thick + 2
        local OutPos    = V2New(Floor(sx - hw) - BarW - 3, Floor(sy - hh + YOffset))
        local OutSize   = V2New(BarW, BoxSize.Y)
        local BarH      = Floor(Pct * (OutSize.Y - 2))

        D.HealthBar.Outline.Position = OutPos
        D.HealthBar.Outline.Size     = OutSize

        D.HealthBar.Main.Color    = DrawingLib.EvalHealth(Pct)
        D.HealthBar.Main.Position = V2New(OutPos.X + 1, OutPos.Y + OutSize.Y - 1 - BarH)
        D.HealthBar.Main.Size     = V2New(OutSize.X - 2, BarH)
    end
end

-- init

for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then AddESP(Player) end
end

Players.PlayerAdded:Connect(AddESP)
Players.PlayerRemoving:Connect(RemoveESP)

RunService.RenderStepped:Connect(function()
    for _, esp in pairs(ESPObjects) do UpdateESP(esp) end
end)

-- Integrated Aimbot (from core/Aimbot.lua) - Simple silent-ish aimbot → head only, using mousemoverel()
-- WARNING: extremely detectable in 2026 Bad Business (Byfron + Hyperion are aggressive)

local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
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

-- Main aimbot loop (integrated into existing RenderStepped)
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
