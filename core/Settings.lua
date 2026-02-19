local ColorNew = Color3.new -- why did i do this?

local Settings = {
    EnemyColor   = ColorNew(1, 0.66, 1),
    AllyColor    = ColorNew(0.33, 0.66, 1),
    TeamCheck    = true,
    BoxThickness = 1,
    HealthBar    = true,
    Outline      = true,
}

getgenv().HubSettings = Settings
return Settings
