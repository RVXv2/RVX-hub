local PlaceId = game.PlaceId

local ScriptMap = {
    [4924922222] = "https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/brookhaven.lua",
}

local url = ScriptMap[PlaceId]

if url then
    loadstring(game:HttpGet(url))()
else
    warn("RVX Hub ยังไม่รองรับแมพนี้ | PlaceId: " .. tostring(PlaceId))
end
