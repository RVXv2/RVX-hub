local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Core = {}

-- เรียกตอนเริ่มต้น สร้าง Window + หน้าแรก (จะอยู่บนสุดเสมอ)
function Core.Init(mapName)
    local Window = WindUI:CreateWindow({
        Title = "RVX hub X " .. mapName,
        Icon = "rocket",
        Theme = "Emerald",
    })

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local HomeTab = Window:Tab({ Title = "หน้าแรก", Icon = "home" })

    HomeTab:Section({ Title = "โปรไฟล์ผู้เล่น", Desc = mapName })

    HomeTab:Paragraph({
        Title = LocalPlayer.DisplayName,
        Desc = "@" .. LocalPlayer.Name .. "  |  UserId: " .. LocalPlayer.UserId,
    })

    HomeTab:Button({
        Title = "เข้าร่วม Discord",
        Icon = "message-circle",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/YOUR-INVITE-CODE")
            end
            WindUI:Notify({
                Title = "คัดลอกลิงก์แล้ว",
                Content = "วางในเบราว์เซอร์เพื่อเข้าร่วม Discord",
                Duration = 3,
            })
        end,
    })

    return Window, WindUI
end

-- เรียกตอนท้ายสุดของทุกไฟล์แมพ สร้างแท็บตั้งค่า (จะอยู่ล่างสุดเสมอ)
function Core.Settings(Window, WindUI)
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
end

return Core
