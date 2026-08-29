local PlaceId = game.PlaceId

local ScriptMap = {
    [4924922222] = "https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/brookhaven.lua",
}

local UniversalURL = "https://raw.githubusercontent.com/RVXv2/RVX-hub/main/universal.lua"

local url = ScriptMap[PlaceId] or UniversalURL

local Intro = loadstring(game:HttpGet("https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/intro.lua"))()

Intro.Show(function()
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if not success then
        warn("RVX Hub โหลดสคริปต์ไม่สำเร็จ | PlaceId: " .. tostring(PlaceId))
        warn(result)
    end
end)
