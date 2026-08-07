local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Core = {}

function Core.Init(mapName)
    local Window = WindUI:CreateWindow({
        Title = "RVX hub X " .. mapName,
        Icon = "rocket",
        Theme = "Emerald",
    })

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local HomeTab = Window:Tab({ Title = "หน้าแรก", Icon = "house" })

    local ProfileSection = HomeTab:Section({ Title = "โปรไฟล์ผู้เล่น", Desc = mapName })

    -- ดึงรูปโปรไฟล์ตัวละคร (แบบ 3D headshot)
    local content, isReady = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size420x420
    )

    ProfileSection:Image({
        Image = content,
        AspectRatio = "1:1",
        Radius = 12,
    })

    ProfileSection:Space()

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
