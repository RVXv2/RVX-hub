local Core = loadstring(game:HttpGet("https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/core.lua"))()
local Window, WindUI = Core.Init("Brookhaven-RP")

local MainTab = Window:Tab({ Title = "Main", Icon = "star" })

MainTab:Section({ Title = "Interactive Elements", Desc = "Demonstration of new UI components" })

MainTab:Toggle({
    Title = "Autism",
    Value = true,
    Callback = function(state)
        print("Autism:", state)
    end,
})

MainTab:Slider({
    Title = "Brightness Control",
    Value = { Min = 0, Max = 100, Default = 60 },
    Callback = function(value)
        print("Brightness:", value)
    end,
})

MainTab:Slider({
    Title = "Volume Settings",
    Value = { Min = 0, Max = 100, Default = 70 },
    Callback = function(value)
        print("Volume:", value)
    end,
})
