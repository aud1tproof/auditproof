local RAW = "https://raw.githubusercontent.com/aud1tproof/auditproof/main/"

local function Load(path)
    return loadstring(game:HttpGet(RAW .. path))()
end

-- Core modules
local Settings = Load("core/Settings.lua")
local Utils     = Load("core/Utils.lua")
local Drawing   = Load("core/Drawing.lua")
local Aimbot   = Load("core/Aimbot.lua")

-- Game detection
local GameModules = {
    ["[🎃] Bad Business | FPS "] = "games/BadBusiness.lua", -- why in the flying fuck is there a space at the end of the game's name
}

local GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

local GameModule = GameModules[GameName]
if GameModule then
    Load(GameModule)
else
    setclipboard("[Hub] Unsupported game: " .. tostring(GameName)) -- cant print otherwise bb will rape us
end
