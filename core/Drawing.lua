local DrawingLib = {}

local BlackColor = Color3.new(0, 0, 0)
local Settings   = getgenv().HubSettings

local CS = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.new(1, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 0)),
    ColorSequenceKeypoint.new(1,   Color3.new(0, 1, 0)),
})

function DrawingLib.EvalHealth(Percent)
    if Percent <= 0 then return CS.Keypoints[1].Value end
    if Percent >= 1 then return CS.Keypoints[#CS.Keypoints].Value end
    for i = 1, #CS.Keypoints - 1 do
        local k, n = CS.Keypoints[i], CS.Keypoints[i + 1] -- seems right to me (im sorry noah)
        if Percent >= k.Time and Percent < n.Time then
            return k.Value:Lerp(n.Value, (Percent - k.Time) / (n.Time - k.Time))
        end
    end
end

function DrawingLib.New(Type, Properties)
    local obj = Drawing.new(Type)
    if Properties then
        for k, v in pairs(Properties) do obj[k] = v end
    end
    return obj
end

function DrawingLib.Clear(Table)
    for _, v in pairs(Table) do
        if type(v) == "table" then DrawingLib.Clear(v)
        else pcall(function() v:Destroy() end) end
    end
end

function DrawingLib.CreateESP()
    local S = Settings
    return {
        BoxOutline = DrawingLib.New("Square", {
            Visible = false, Filled = false, ZIndex = 0,
            Color = BlackColor, Thickness = S.BoxThickness + 2,
        }),
        Box = DrawingLib.New("Square", {
            Visible = false, Filled = false, ZIndex = 1,
            Thickness = S.BoxThickness,
        }),
        HealthBar = {
            Outline = DrawingLib.New("Square", { Visible = false, ZIndex = 0, Filled = true, Color = BlackColor }),
            Main    = DrawingLib.New("Square", { Visible = false, ZIndex = 1, Filled = true }),
        },
    }
end

getgenv().HubDrawing = DrawingLib
return DrawingLib
