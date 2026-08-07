local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Core = {}

function Core.Init(mapName)
    local Window = WindUI:CreateWindow({
        Title = "RVX hub X " .. mapName,
        Icon = "rocket",
        Theme = "Emerald",
    })

    -- ===== หน้าแรก =====
    local HomeTab = Window:Tab({ Title = "หน้าแรก", Icon = "home" })

    HomeTab:Section({ Title = "ยินดีต้อนรับ", Desc = "RVX hub — " .. mapName })

    HomeTab:Paragraph({
        Title = "เกี่ยวกับ",
        Desc = "RVX hub รองรับหลายแมพ อัปเดตอัตโนมัติทุกครั้งที่เปิด",
    })

    -- ===== การตั้งค่า =====
    local SettingsTab = Window:Tab({ Title = "การตั้งค่า", Icon = "settings" })

    SettingsTab:Section({ Title = "การตั้งค่าทั่วไป", Desc = "ปรับแต่งการทำงานของ Hub" })

    SettingsTab:Dropdown({
        Title = "ธีม",
        Values = { "Dark", "Light", "Emerald", "Plant", "Midnight", "Violet", "Rose", "MonokaiPro" },
        Callback = function(selected)
            WindUI:SetTheme(selected)
        end,
    })

    SettingsTab:Button({
        Title = "ปิด Hub",
        Icon = "x",
        Callback = function()
            Window:Destroy()
        end,
    })

    return Window, WindUI
end

return Core
