local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Core = {}
local HUB_VERSION = "v1.0"
local CONFIG_FILE = "RVXHub_Config.json"

local DEFAULT_CONFIG = {
    Theme = "Violet",
    AutoReconnect = false,
    Language = "TH",
    Transparency = 0,
    QuickCloseKey = "K",
}

local LANG = {
    TH = {
        home = "หน้าแรก",
        profileSection = "โปรไฟล์ผู้เล่น",
        version = "เวอร์ชั่น ",
        discord = "เข้าร่วม Discord",
        discordCopied = "คัดลอกลิงก์แล้ว",
        discordDesc = "วางในเบราว์เซอร์เพื่อเข้าร่วม Discord",
        settings = "การตั้งค่า",
        general = "การตั้งค่าทั่วไป",
        generalDesc = "ปรับแต่งการทำงานของ Hub",
        theme = "ธีม",
        connection = "การเชื่อมต่อ",
        connectionDesc = "จัดการการหลุดเซิร์ฟเวอร์",
        autoreconnect = "Auto Reconnect",
        autoreconnectDesc = "เข้าเกมใหม่อัตโนมัติถ้าหลุดเซิร์ฟเวอร์",
        language = "ภาษา",
        languageDesc = "มีผลกับหน้าแรกและการตั้งค่า (ต้องเข้าเกมใหม่ถึงจะเห็นผลเต็มที่)",
        appearance = "รูปลักษณ์",
        appearanceDesc = "ปรับความโปร่งใสของหน้าต่าง Hub",
        transparency = "ความโปร่งใส",
        keybindSection = "ปุ่มลัด",
        keybindDesc = "เลือกปุ่มสำหรับปิด Hub อย่างเร็ว",
        quickCloseKey = "ปุ่มปิดด่วน",
        stats = "แสดงสถิติ",
        statsDesc = "โชว์กรอบ FPS/Ping มุมจอ",
        showStats = "แสดง FPS/Ping",
        configSection = "การตั้งค่าที่บันทึกไว้",
        configDesc = "บันทึก/รีเซ็ตการตั้งค่าทั้งหมด",
        saveConfig = "บันทึกการตั้งค่า",
        savedMsg = "บันทึกการตั้งค่าแล้ว",
        resetConfig = "รีเซ็ตการตั้งค่าทั้งหมด",
        resetMsg = "รีเซ็ตเรียบร้อยแล้ว เข้าเกมใหม่เพื่อให้มีผลเต็มที่",
        closehub = "ปิด Hub",
        transparencyUnsupported = "WindUI เวอร์ชันนี้ยังไม่รองรับการปรับความโปร่งใส",
    },
    EN = {
        home = "Home",
        profileSection = "Player Profile",
        version = "Version ",
        discord = "Join Discord",
        discordCopied = "Link copied",
        discordDesc = "Paste it in your browser to join Discord",
        settings = "Settings",
        general = "General Settings",
        generalDesc = "Customize how the Hub works",
        theme = "Theme",
        connection = "Connection",
        connectionDesc = "Manage server disconnects",
        autoreconnect = "Auto Reconnect",
        autoreconnectDesc = "Auto rejoin if you get disconnected",
        language = "Language",
        languageDesc = "Affects Home and Settings tabs (rejoin for full effect)",
        appearance = "Appearance",
        appearanceDesc = "Adjust the Hub window transparency",
        transparency = "Transparency",
        keybindSection = "Keybind",
        keybindDesc = "Choose a key to quickly close the Hub",
        quickCloseKey = "Quick close key",
        stats = "Show Stats",
        statsDesc = "Show an FPS/Ping overlay on screen",
        showStats = "Show FPS/Ping",
        configSection = "Saved Settings",
        configDesc = "Save/reset all settings",
        saveConfig = "Save Settings",
        savedMsg = "Settings saved",
        resetConfig = "Reset All Settings",
        resetMsg = "Reset done. Rejoin for full effect.",
        closehub = "Close Hub",
        transparencyUnsupported = "This WindUI version does not support transparency yet",
    },
}

local function LoadConfig()
    local cfg = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        cfg[k] = v
    end

    if isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and data then
            for k, v in pairs(data) do
                cfg[k] = v
            end
        end
    end

    return cfg
end

local function SaveConfigToFile(cfg)
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(cfg))
        end)
    end
end

Core.Config = LoadConfig()

function Core.Init(mapName)
    local T = LANG[Core.Config.Language] or LANG.TH

    local Window = WindUI:CreateWindow({
        Title = "RVX hub X " .. mapName,
        Icon = "rbxassetid://125616092701976",
        Theme = Core.Config.Theme,
    })

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local HomeTab = Window:Tab({ Title = T.home, Icon = "house" })

    local ProfileSection = HomeTab:Section({ Title = T.profileSection, Desc = mapName })

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
        Title = T.version .. HUB_VERSION,
        Icon = "star",
        Callback = function()
            WindUI:Notify({
                Title = "RVX Hub",
                Content = T.version .. HUB_VERSION,
                Duration = 3,
            })
        end,
    })

    HomeTab:Button({
        Title = T.discord,
        Icon = "message-circle",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/WQePykh3yJ")
            end
            WindUI:Notify({
                Title = T.discordCopied,
                Content = T.discordDesc,
                Duration = 3,
            })
        end,
    })

    -- ===== ปุ่มลัดปิด Hub =====
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyEnum = Enum.KeyCode[Core.Config.QuickCloseKey]
            if keyEnum and input.KeyCode == keyEnum then
                pcall(function()
                    Window:Destroy()
                end)
            end
        end
    end)

    return Window, WindUI
end

function Core.Settings(Window, WindUI)
    local T = LANG[Core.Config.Language] or LANG.TH
    local Players = game:GetService("Players")

    local SettingsTab = Window:Tab({ Title = T.settings, Icon = "settings" })

    -- ===== ทั่วไป =====
    SettingsTab:Section({ Title = T.general, Desc = T.generalDesc })

    SettingsTab:Dropdown({
        Title = T.theme,
        Values = { "Dark", "Light", "Emerald", "Plant", "Midnight", "Violet", "Rose", "MonokaiPro" },
        Value = Core.Config.Theme,
        Callback = function(selected)
            Core.Config.Theme = selected
            WindUI:SetTheme(selected)
        end,
    })

    -- ===== การเชื่อมต่อ =====
    SettingsTab:Section({ Title = T.connection, Desc = T.connectionDesc })

    local TeleportService = game:GetService("TeleportService")

    SettingsTab:Toggle({
        Title = T.autoreconnect,
        Desc = T.autoreconnectDesc,
        Value = Core.Config.AutoReconnect,
        Callback = function(state)
            Core.Config.AutoReconnect = state
            WindUI:Notify({
                Title = T.settings,
                Content = T.autoreconnect .. ": " .. (state and "ON" or "OFF"),
                Duration = 2,
            })
        end,
    })

    -- BindToClose ทำงานไม่ได้ในบาง executor และจะ error จนโค้ดที่เหลือ
    -- (ภาษา / ความโปร่งใส / ปุ่มลัด / สถิติ / บันทึก-รีเซ็ต) ไม่ถูกสร้างเลย
    -- ครอบ pcall กันไว้ไม่ให้ error ตรงนี้ทำให้ UI ส่วนที่เหลือหายไป
    pcall(function()
        game:BindToClose(function()
            if Core.Config.AutoReconnect then
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end)
            end
        end)
    end)

    -- ===== ภาษา =====
    SettingsTab:Section({ Title = T.language, Desc = T.languageDesc })

    SettingsTab:Dropdown({
        Title = T.language,
        Values = { "TH", "EN" },
        Value = Core.Config.Language,
        Callback = function(selected)
            Core.Config.Language = selected
        end,
    })

    -- ===== รูปลักษณ์ (ความโปร่งใส) =====
    SettingsTab:Section({ Title = T.appearance, Desc = T.appearanceDesc })

    SettingsTab:Slider({
        Title = T.transparency,
        Value = { Min = 0, Max = 80, Default = Core.Config.Transparency },
        Callback = function(value)
            Core.Config.Transparency = value
            local applied = false

            pcall(function()
                Window:SetTransparency(value / 100)
                applied = true
            end)

            if not applied then
                pcall(function()
                    Window.Transparency = value / 100
                    applied = true
                end)
            end

            if not applied then
                WindUI:Notify({
                    Title = T.appearance,
                    Content = T.transparencyUnsupported,
                    Duration = 3,
                })
            end
        end,
    })

    -- ===== ปุ่มลัด =====
    SettingsTab:Section({ Title = T.keybindSection, Desc = T.keybindDesc })

    SettingsTab:Dropdown({
        Title = T.quickCloseKey,
        Values = { "K", "L", "J", "Insert", "End", "RightShift", "F4" },
        Value = Core.Config.QuickCloseKey,
        Callback = function(selected)
            Core.Config.QuickCloseKey = selected
        end,
    })

    -- ===== สถิติ FPS/Ping =====
    SettingsTab:Section({ Title = T.stats, Desc = T.statsDesc })

    local StatsGui = nil
    local StatsConnection = nil

    local function CreateStatsOverlay()
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

        StatsGui = Instance.new("ScreenGui")
        StatsGui.Name = "RVXStatsOverlay"
        StatsGui.ResetOnSpawn = false
        StatsGui.Parent = playerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 110, 0, 50)
        frame.Position = UDim2.new(0, 10, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
        frame.BackgroundTransparency = 0.3
        frame.Parent = StatsGui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

        local fpsLabel = Instance.new("TextLabel")
        fpsLabel.Size = UDim2.new(1, 0, 0.5, 0)
        fpsLabel.BackgroundTransparency = 1
        fpsLabel.Text = "FPS: --"
        fpsLabel.TextColor3 = Color3.new(1, 1, 1)
        fpsLabel.Font = Enum.Font.GothamBold
        fpsLabel.TextSize = 14
        fpsLabel.Parent = frame

        local pingLabel = Instance.new("TextLabel")
        pingLabel.Size = UDim2.new(1, 0, 0.5, 0)
        pingLabel.Position = UDim2.new(0, 0, 0.5, 0)
        pingLabel.BackgroundTransparency = 1
        pingLabel.Text = "Ping: --"
        pingLabel.TextColor3 = Color3.new(1, 1, 1)
        pingLabel.Font = Enum.Font.GothamBold
        pingLabel.TextSize = 14
        pingLabel.Parent = frame

        local RunService = game:GetService("RunService")
        local frameCount = 0
        local lastTime = tick()

        StatsConnection = RunService.Heartbeat:Connect(function()
            frameCount = frameCount + 1
            local now = tick()
            if now - lastTime >= 1 then
                fpsLabel.Text = "FPS: " .. frameCount
                frameCount = 0
                lastTime = now

                pcall(function()
                    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                    pingLabel.Text = "Ping: " .. math.floor(ping) .. " ms"
                end)
            end
        end)
    end

    local function DestroyStatsOverlay()
        if StatsConnection then
            StatsConnection:Disconnect()
            StatsConnection = nil
        end
        if StatsGui then
            StatsGui:Destroy()
            StatsGui = nil
        end
    end

    SettingsTab:Toggle({
        Title = T.showStats,
        Value = false,
        Callback = function(state)
            if state then
                CreateStatsOverlay()
            else
                DestroyStatsOverlay()
            end
        end,
    })

    -- ===== บันทึก/รีเซ็ต =====
    SettingsTab:Section({ Title = T.configSection, Desc = T.configDesc })

    SettingsTab:Button({
        Title = T.saveConfig,
        Icon = "save",
        Callback = function()
            SaveConfigToFile(Core.Config)
            WindUI:Notify({ Title = T.settings, Content = T.savedMsg, Duration = 2 })
        end,
    })

    SettingsTab:Button({
        Title = T.resetConfig,
        Icon = "rotate-ccw",
        Callback = function()
            local fresh = {}
            for k, v in pairs(DEFAULT_CONFIG) do
                fresh[k] = v
            end
            Core.Config = fresh
            SaveConfigToFile(Core.Config)
            WindUI:SetTheme(Core.Config.Theme)
            WindUI:Notify({ Title = T.settings, Content = T.resetMsg, Duration = 4 })
        end,
    })

    SettingsTab:Button({
        Title = T.closehub,
        Icon = "x",
        Callback = function()
            DestroyStatsOverlay()
            Window:Destroy()
        end,
    })
end

return Core
