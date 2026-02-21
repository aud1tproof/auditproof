local Settings   = getgenv().HubSettings
local Utils      = getgenv().HubUtils

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TeamService       = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

local AimbotSettings = {
    Key         = Enum.KeyCode.Q,   -- hold to activate
    Smoothing   = 0.15,             -- higher = stronger
    FOV         = 200,       
    TeamCheck   = true,

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
    
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible   = false
FOVCircle.Radius    = AimbotSettings.FOV
FOVCircle.Color     = Color3.new(1, 1, 1)
FOVCircle.Thickness = 1
FOVCircle.Filled    = false
FOVCircle.NumSides  = 64

local function GetScreenCenter()
    return Camera.ViewportSize / 2
end

local function GetBestTarget()
    local Center     = GetScreenCenter()
    local BestPlayer = nil
    local BestDist   = AimbotSettings.FOV

    for _, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end

        local Enemy = IsEnemy(Player)
        if AimbotSettings.TeamCheck and Settings.TeamCheck and not Enemy then continue end

        local Char, Root = GetCharacter(Player)
        if not Char or not Root then continue end

        local _, _, Alive = GetHealth(Char)
        if not Alive then continue end

        local ScreenPos, OnScreen = Utils.WorldToScreen(Root.Position)
        if not OnScreen then continue end

        local Dist = (ScreenPos - Center).Magnitude
        if Dist < BestDist then
            BestDist   = Dist
            BestPlayer = Player
        end
    end

    return BestPlayer
end

RunService.RenderStepped:Connect(function()
    local Center = GetScreenCenter()

    FOVCircle.Position = Center
    FOVCircle.Radius   = AimbotSettings.FOV

    local Holding = UserInputService:IsKeyDown(AimbotSettings.Key)
    FOVCircle.Visible = true 

    if not Holding then return end

    local Target = GetBestTarget()
    if not Target then return end

    local Char, Root = GetCharacter(Target)
    if not Char or not Root then return end

    local ScreenPos, OnScreen = Utils.WorldToScreen(Root.Position)
    if not OnScreen then return end

    local Delta = ScreenPos - Center
    mousemoverel(Delta.X * AimbotSettings.Smoothing, Delta.Y * AimbotSettings.Smoothing)
end)

game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    FOVCircle.Visible = false
end)

getgenv().HubAimbot = AimbotSettings
