local RAW = "https://raw.githubusercontent.com/aud1tproof/auditproof/main/"

local function Load(path)
    return loadstring(game:HttpGet(RAW .. path))()
end

-- Core modules
local Settings = Load("core/Settings.lua")
local Utils     = Load("core/Utils.lua")
local Drawing   = Load("core/Drawing.lua")

-- Game detection → load the right module
local GameModules = {
    ["[🎃] Bad Business | FPS"] = "games/BadBusiness.lua",
}

local GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

local GameModule = GameModules[GameName]
if GameModule then
    Load(GameModule)
else
    setclipboard("[Hub] Unsupported game: " .. tostring(GameName)) -- cant print otherwise bb will rape us
end
