local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Core = {}
local HUB_VERSION = "v1.0"

function Core.Init(mapName)
    local Window = WindUI:CreateWindow({
        Title = "RVX hub X " .. mapName,
        Icon = "rbxassetid://125616092701976",
        Theme = "Violet",
    })

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local HomeTab = Window:Tab({ Title = "หน้าแรก", Icon = "house" })

    local ProfileSection = HomeTab:Section({ Title = "โปรไฟล์ผู้เล่น", Desc = mapName })

    local content = Players:GetUserThumbnailAsync(
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
        Title = "เวอร์ชั่น " .. HUB_VERSION,
        Icon = "star",
        Callback = function()
            WindUI:Notify({
                Title = "RVX Hub",
                Content = "เวอร์ชั่นปัจจุบัน: " .. HUB_VERSION,
                Duration = 3,
            })
        end,
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
        Value = "Violet",
        Callback = function(selected)
            WindUI:SetTheme(selected)
        end,
    })

    -- ===== Auto Reconnect =====
    SettingsTab:Section({ Title = "การเชื่อมต่อ", Desc = "จัดการการหลุดเซิร์ฟเวอร์" })

    local AutoReconnect = false
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")

    SettingsTab:Toggle({
        Title = "Auto Reconnect",
        Desc = "เข้าเกมใหม่อัตโนมัติถ้าหลุดเซิร์ฟเวอร์",
        Value = false,
        Callback = function(state)
            AutoReconnect = state
            WindUI:Notify({
                Title = "การตั้งค่า",
                Content = "Auto Reconnect: " .. (state and "เปิด" or "ปิด"),
                Duration = 2,
            })
        end,
    })

    game:BindToClose(function()
        if AutoReconnect then
            pcall(function()
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end)
        end
    end)

    SettingsTab:Button({
        Title = "ปิด Hub",
        Icon = "x",
        Callback = function()
            Window:Destroy()
        end,
    })
end

return Core
