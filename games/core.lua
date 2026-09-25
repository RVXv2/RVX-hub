local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Core = {}
local HUB_VERSION = "v1.0"
local CONFIG_FILE = "RVXHub_Config.json"

local SCRIPTS_MODULE_URL = "https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/RVXHub_Scripts.lua"

local GlobalStore = (type(getgenv) == "function" and getgenv()) or _G

local function RVXHub_Cleanup()
    local prev = GlobalStore.__RVXHub_Instance
    if not prev then return end

    pcall(function()
        if prev.InputConnection then
            prev.InputConnection:Disconnect()
        end
    end)

    pcall(function()
        if prev.StatsConnection then
            prev.StatsConnection:Disconnect()
        end
    end)

    pcall(function()
        if prev.AntiAFKConnection then
            prev.AntiAFKConnection:Disconnect()
        end
    end)

    pcall(function()
        if prev.StatsGui then
            prev.StatsGui:Destroy()
        end
    end)

    pcall(function()
        if prev.Window then
            prev.Window:Destroy()
        end
    end)

    GlobalStore.__RVXHub_Instance = nil
end

RVXHub_Cleanup()
GlobalStore.__RVXHub_Instance = {}

local DEFAULT_CONFIG = {
    Theme = "Violet",
    AutoReconnect = false,
    AntiAFK = true,
    Language = "TH",
    Transparent = true,
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
        antiafk = "Anti-AFK",
        antiafkDesc = "ขยับตัวเล็กน้อยเป็นระยะเพื่อไม่ให้สถานะ AFK ค้าง",
        language = "ภาษา",
        languageDesc = "เปลี่ยนแล้วมีผลทันที ไม่ต้องรันสคริปต์ใหม่",
        appearance = "รูปลักษณ์",
        appearanceDesc = "ปรับความโปร่งใสของหน้าต่าง Hub (มีผลหลังรันสคริปต์ใหม่)",
        transparency = "หน้าต่างโปร่งใส",
        transparencySaved = "บันทึกแล้ว รันสคริปต์ใหม่เพื่อให้มีผล",
        languageSaved = "เปลี่ยนภาษาเรียบร้อยแล้ว",
        keybindSection = "ปุ่มลัด",
        keybindDesc = "เลือกปุ่มสำหรับปิด Hub อย่างเร็ว",
        quickCloseKey = "ปุ่มปิดด่วน",
        stats = "แสดงสถิติ",
        statsDesc = "โชว์กรอบ FPS/Ping มุมจอ",
        showStats = "แสดง FPS/Ping",
        savedSettings = "บันทึกการตั้งค่า",
        savedSettingsDesc = "บันทึก/รีเซ็ตการตั้งค่าทั้งหมด ใช้ได้ทุกแมพ",
        configSection = "การตั้งค่าที่บันทึกไว้",
        configDesc = "บันทึก/รีเซ็ตการตั้งค่าทั้งหมด",
        saveConfig = "บันทึกการตั้งค่า",
        savedMsg = "บันทึกการตั้งค่าแล้ว",
        resetConfig = "รีเซ็ตการตั้งค่าทั้งหมด",
        resetMsg = "รีเซ็ตเรียบร้อยแล้ว (มีผลทันที)",
        closehub = "ปิด Hub",
        transparencyUnsupported = "WindUI เวอร์ชันนี้ยังไม่รองรับการปรับความโปร่งใส",
        scripts = "สคริปต์",
        scriptsSection = "สคริปต์ภายนอก",
        scriptsSectionDesc = "กดปุ่มเพื่อรันสคริปต์แต่ละตัว",
        scriptsEmptyTitle = "ยังไม่มีสคริปต์",
        scriptsEmptyDesc = "เพิ่มรายการได้ในไฟล์ RVXHub_Scripts.lua",
        scriptsLoadFailTitle = "โหลดแท็บ Scripts ไม่สำเร็จ",
        scriptsLoadFailDesc = "ตรวจสอบ SCRIPTS_MODULE_URL หรือการเชื่อมต่ออินเทอร์เน็ต",
        scriptRan = "รันสคริปต์แล้ว",
        scriptError = "รันไม่สำเร็จ: ",
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
        antiafk = "Anti-AFK",
        antiafkDesc = "Makes a small periodic movement to keep the character active",
        language = "Language",
        languageDesc = "Applies instantly, no need to rerun the script",
        appearance = "Appearance",
        appearanceDesc = "Adjust the Hub window transparency (applies after you rerun the script)",
        transparency = "Transparent window",
        transparencySaved = "Saved. Rerun the script for it to take effect.",
        languageSaved = "Language changed successfully",
        keybindSection = "Keybind",
        keybindDesc = "Choose a key to quickly close the Hub",
        quickCloseKey = "Quick close key",
        stats = "Show Stats",
        statsDesc = "Show an FPS/Ping overlay on screen",
        showStats = "Show FPS/Ping",
        savedSettings = "Saved Settings",
        savedSettingsDesc = "Save/reset all settings, works on every map",
        configSection = "Saved Settings",
        configDesc = "Save/reset all settings",
        saveConfig = "Save Settings",
        savedMsg = "Settings saved",
        resetConfig = "Reset All Settings",
        resetMsg = "Reset done (applies instantly)",
        closehub = "Close Hub",
        transparencyUnsupported = "This WindUI version does not support transparency yet",
        scripts = "Scripts",
        scriptsSection = "External Scripts",
        scriptsSectionDesc = "Tap a button to run that script",
        scriptsEmptyTitle = "No scripts yet",
        scriptsEmptyDesc = "Add entries in RVXHub_Scripts.lua",
        scriptsLoadFailTitle = "Failed to load Scripts tab",
        scriptsLoadFailDesc = "Check SCRIPTS_MODULE_URL or your internet connection",
        scriptRan = "Script executed",
        scriptError = "Failed to run: ",
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
Core.MapName = nil

-- ===== ระบบเปลี่ยนภาษาแบบมีผลทันที (ไม่ทำลาย/สร้างหน้าต่างใหม่) =====
-- แทนที่จะ Destroy+CreateWindow ใหม่ (วิธีเดิมที่เคยลองแล้วพังบ่อย เพราะ yield
-- ข้าม callback boundary) เราเก็บ "ฟังก์ชัน refresh" ของแต่ละ element ไว้แทน
-- พอเปลี่ยนภาษา จะไล่เรียกทุกฟังก์ชันเพื่ออัปเดตข้อความ Title/Desc ของ element
-- นั้นๆ ตรงๆ ผ่าน :SetTitle()/:SetDesc() ถ้า WindUI เวอร์ชันที่ใช้ไม่รองรับ
-- method พวกนี้ จะแค่ข้ามไปเงียบๆ (ครอบ pcall ไว้) ไม่ทำให้ทั้งหน้าพัง
Core.LanguageRefreshers = {}

-- โมดูลแมพอื่น (เช่น rideapet.lua) เรียกอันนี้เพื่อลงทะเบียนขอรับการอัปเดต
-- ภาษาแบบเรียลไทม์ได้เหมือนกัน ไม่ต้องจำกัดแค่ core.lua เอง
function Core.RegisterLanguageRefresh(fn)
    table.insert(Core.LanguageRefreshers, fn)
end

local function RefreshAllLanguage()
    local T = LANG[Core.Config.Language] or LANG.TH
    for _, fn in ipairs(Core.LanguageRefreshers) do
        pcall(fn, T, Core.Config.Language)
    end
end

function Core.Init(mapName)
    Core.MapName = mapName
    local T = LANG[Core.Config.Language] or LANG.TH

    local Window = WindUI:CreateWindow({
        Title = "RVX hub X " .. mapName,
        Icon = "rbxassetid://95844711546407",
        IconSize = 32,
        Theme = Core.Config.Theme,
        Transparent = Core.Config.Transparent,
        OpenButton = {
            Title = "RVX Hub",
            CornerRadius = UDim.new(0, 12),
            Color = ColorSequence.new(
                Color3.fromHex("#6D28D9"),
                Color3.fromHex("#3B82F6")
            ),
        },
    })

    GlobalStore.__RVXHub_Instance = GlobalStore.__RVXHub_Instance or {}
    GlobalStore.__RVXHub_Instance.Window = Window

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local HomeTab = Window:Tab({ Title = T.home, Icon = "house" })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() HomeTab:SetTitle(T2.home) end)
    end)

    local profileSection = HomeTab:Section({ Title = T.profileSection, Desc = mapName })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() profileSection:SetTitle(T2.profileSection) end)
    end)

    local thumbOk, thumbContent = pcall(function()
        return Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)

    HomeTab:Paragraph({
        Title = LocalPlayer.DisplayName,
        Desc = "@" .. LocalPlayer.Name .. "  |  UserId: " .. LocalPlayer.UserId,
        Thumbnail = thumbOk and thumbContent or "rbxassetid://0",
        ThumbnailSize = 60,
    })

    local versionBtn = HomeTab:Button({
        Title = T.version .. HUB_VERSION,
        Icon = "star",
        Callback = function()
            local curT = LANG[Core.Config.Language] or LANG.TH
            WindUI:Notify({
                Title = "RVX Hub",
                Content = curT.version .. HUB_VERSION,
                Duration = 3,
            })
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() versionBtn:SetTitle(T2.version .. HUB_VERSION) end)
    end)

    local discordBtn = HomeTab:Button({
        Title = T.discord,
        Icon = "message-circle",
        Callback = function()
            local curT = LANG[Core.Config.Language] or LANG.TH
            if setclipboard then
                setclipboard("https://discord.gg/WQePykh3yJ")
            end
            WindUI:Notify({
                Title = curT.discordCopied,
                Content = curT.discordDesc,
                Duration = 3,
            })
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() discordBtn:SetTitle(T2.discord) end)
    end)

    local UserInputService = game:GetService("UserInputService")
    local inputConnection
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyEnum = Enum.KeyCode[Core.Config.QuickCloseKey]
            if keyEnum and input.KeyCode == keyEnum then
                local toggled = false
                pcall(function()
                    Window:Toggle()
                    toggled = true
                end)
                if not toggled then
                    pcall(function()
                        if Window.Visible then
                            Window:Close()
                        else
                            Window:Open()
                        end
                    end)
                end
            end
        end
    end)

    GlobalStore.__RVXHub_Instance.InputConnection = inputConnection

    return Window, WindUI
end

function Core.Settings(Window, WindUI)
    local T = LANG[Core.Config.Language] or LANG.TH
    local Players = game:GetService("Players")

    local SettingsTab = Window:Tab({ Title = T.settings, Icon = "settings" })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() SettingsTab:SetTitle(T2.settings) end)
    end)

    -- ===== ทั่วไป =====
    local generalSection = SettingsTab:Section({ Title = T.general, Desc = T.generalDesc })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            generalSection:SetTitle(T2.general)
            generalSection:SetDesc(T2.generalDesc)
        end)
    end)

    local themeDropdown = SettingsTab:Dropdown({
        Title = T.theme,
        Values = { "Dark", "Light", "Emerald", "Plant", "Midnight", "Violet", "Rose", "MonokaiPro" },
        Value = Core.Config.Theme,
        Callback = function(selected)
            Core.Config.Theme = selected
            WindUI:SetTheme(selected)
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() themeDropdown:SetTitle(T2.theme) end)
    end)

    -- ===== การเชื่อมต่อ =====
    local connectionSection = SettingsTab:Section({ Title = T.connection, Desc = T.connectionDesc })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            connectionSection:SetTitle(T2.connection)
            connectionSection:SetDesc(T2.connectionDesc)
        end)
    end)

    local TeleportService = game:GetService("TeleportService")

    local reconnecting = false
    local function TryAutoReconnect(reason)
        if not Core.Config.AutoReconnect or reconnecting then return end
        reconnecting = true

        local curT = LANG[Core.Config.Language] or LANG.TH
        pcall(function()
            WindUI:Notify({
                Title = curT.settings,
                Content = curT.autoreconnect .. " — " .. tostring(reason or "กำลังเชื่อมต่อใหม่"),
                Duration = 3,
            })
        end)

        task.delay(1, function()
            pcall(function()
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end)
            task.delay(8, function()
                reconnecting = false
            end)
        end)
    end

    local autoReconnectToggle = SettingsTab:Toggle({
        Title = T.autoreconnect,
        Desc = T.autoreconnectDesc,
        Value = Core.Config.AutoReconnect,
        Callback = function(state)
            Core.Config.AutoReconnect = state
            SaveConfigToFile(Core.Config)
            local curT = LANG[Core.Config.Language] or LANG.TH
            WindUI:Notify({
                Title = curT.settings,
                Content = curT.autoreconnect .. ": " .. (state and "ON" or "OFF"),
                Duration = 2,
            })
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            autoReconnectToggle:SetTitle(T2.autoreconnect)
            autoReconnectToggle:SetDesc(T2.autoreconnectDesc)
        end)
    end)

    -- ตรวจจับการเริ่ม Teleport ที่ล้มเหลว แล้วลองเข้าใหม่อีกครั้งเมื่อเปิด Auto Reconnect
    pcall(function()
        TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
            if player == Players.LocalPlayer then
                TryAutoReconnect("Teleport ล้มเหลว: " .. tostring(errorMessage or teleportResult))
            end
        end)
    end)

    -- เก็บ fallback เดิมไว้สำหรับกรณีที่เกมกำลังปิด
    pcall(function()
        game:BindToClose(function()
            if Core.Config.AutoReconnect then
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end)
            end
        end)
    end)

    -- ===== Anti-AFK =====
    local RunService = game:GetService("RunService")
    local antiAFKConnection = nil

    local function StartAntiAFK()
        if antiAFKConnection then return end

        local elapsed = 0
        antiAFKConnection = RunService.Heartbeat:Connect(function(dt)
            if not Core.Config.AntiAFK then return end
            elapsed = elapsed + dt
            if elapsed < 45 then return end
            elapsed = 0

            local character = Players.LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return end

            -- ขยับซ้าย/ขวาสั้น ๆ แล้วหยุด ไม่วาปและไม่ยุ่งกับตำแหน่งแปลง
            task.spawn(function()
                pcall(function()
                    humanoid:Move(Vector3.new(1, 0, 0), false)
                    task.wait(0.35)
                    humanoid:Move(Vector3.new(-1, 0, 0), false)
                    task.wait(0.35)
                    humanoid:Move(Vector3.zero, false)
                end)
            end)
        end)

        GlobalStore.__RVXHub_Instance = GlobalStore.__RVXHub_Instance or {}
        GlobalStore.__RVXHub_Instance.AntiAFKConnection = antiAFKConnection
    end

    local function StopAntiAFK()
        if antiAFKConnection then
            antiAFKConnection:Disconnect()
            antiAFKConnection = nil
        end
        if GlobalStore.__RVXHub_Instance then
            GlobalStore.__RVXHub_Instance.AntiAFKConnection = nil
        end
    end

    local antiAFKToggle = SettingsTab:Toggle({
        Title = T.antiafk,
        Desc = T.antiafkDesc,
        Value = Core.Config.AntiAFK,
        Callback = function(state)
            Core.Config.AntiAFK = state
            if state then
                StartAntiAFK()
            else
                StopAntiAFK()
            end
        end,
    })

    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            antiAFKToggle:SetTitle(T2.antiafk)
            antiAFKToggle:SetDesc(T2.antiafkDesc)
        end)
    end)

    if Core.Config.AntiAFK then
        StartAntiAFK()
    end

    -- ===== ภาษา (เปลี่ยนแล้วมีผลทันที) =====
    local languageSection = SettingsTab:Section({ Title = T.language, Desc = T.languageDesc })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            languageSection:SetTitle(T2.language)
            languageSection:SetDesc(T2.languageDesc)
        end)
    end)

    local languageDropdown = SettingsTab:Dropdown({
        Title = T.language,
        Values = { "TH", "EN" },
        Value = Core.Config.Language,
        Callback = function(selected)
            if selected == Core.Config.Language then return end
            Core.Config.Language = selected
            SaveConfigToFile(Core.Config)
            RefreshAllLanguage() -- อัปเดตข้อความทุกจุดทันที ไม่ต้องรันสคริปต์ใหม่
            local curT = LANG[Core.Config.Language] or LANG.TH
            WindUI:Notify({ Title = curT.settings, Content = curT.languageSaved, Duration = 3 })
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() languageDropdown:SetTitle(T2.language) end)
    end)

    -- ===== รูปลักษณ์ (ความโปร่งใส) =====
    local appearanceSection = SettingsTab:Section({ Title = T.appearance, Desc = T.appearanceDesc })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            appearanceSection:SetTitle(T2.appearance)
            appearanceSection:SetDesc(T2.appearanceDesc)
        end)
    end)

    local transparencyToggle = SettingsTab:Toggle({
        Title = T.transparency,
        Value = Core.Config.Transparent,
        Callback = function(state)
            Core.Config.Transparent = state
            SaveConfigToFile(Core.Config)
            local curT = LANG[Core.Config.Language] or LANG.TH
            WindUI:Notify({ Title = curT.settings, Content = curT.transparencySaved, Duration = 4 })
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() transparencyToggle:SetTitle(T2.transparency) end)
    end)

    -- ===== ปุ่มลัด =====
    local keybindSection = SettingsTab:Section({ Title = T.keybindSection, Desc = T.keybindDesc })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            keybindSection:SetTitle(T2.keybindSection)
            keybindSection:SetDesc(T2.keybindDesc)
        end)
    end)

    local keybindDropdown = SettingsTab:Dropdown({
        Title = T.quickCloseKey,
        Values = { "K", "L", "J", "Insert", "End", "RightShift", "F4" },
        Value = Core.Config.QuickCloseKey,
        Callback = function(selected)
            Core.Config.QuickCloseKey = selected
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() keybindDropdown:SetTitle(T2.quickCloseKey) end)
    end)

    -- ===== สถิติ FPS/Ping =====
    local statsSection = SettingsTab:Section({ Title = T.stats, Desc = T.statsDesc })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            statsSection:SetTitle(T2.stats)
            statsSection:SetDesc(T2.statsDesc)
        end)
    end)

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

        GlobalStore.__RVXHub_Instance = GlobalStore.__RVXHub_Instance or {}
        GlobalStore.__RVXHub_Instance.StatsGui = StatsGui
        GlobalStore.__RVXHub_Instance.StatsConnection = StatsConnection
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
        if GlobalStore.__RVXHub_Instance then
            GlobalStore.__RVXHub_Instance.StatsGui = nil
            GlobalStore.__RVXHub_Instance.StatsConnection = nil
        end
    end

    local statsToggle = SettingsTab:Toggle({
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
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() statsToggle:SetTitle(T2.showStats) end)
    end)

    -- หมายเหตุ: ปุ่มบันทึก/รีเซ็ต/ปิด Hub ย้ายไปแท็บ "บันทึกการตั้งค่า" แยกต่างหากแล้ว
    -- (ดูฟังก์ชัน Core.SavedSettingsTab ด้านล่าง) ไม่ได้อยู่ในแท็บนี้อีกต่อไป
end

-- ===== แท็บ "บันทึกการตั้งค่า" แยกต่างหาก (โชว์ทุกแมพเหมือน Settings) =====
-- ก่อนหน้านี้ปุ่มพวกนี้อยู่ท้ายแท็บ Settings รวมกับอย่างอื่น ย้ายมาไว้ที่นี่
-- ให้เป็นแท็บของตัวเอง หาง่ายขึ้น และเรียกจาก universal.lua แบบเดียวกับ
-- Core.Settings(Window, WindUI) คือเรียกนอก if hideUniversalTabs เพื่อให้ขึ้น
-- ทุกแมพเสมอ
function Core.SavedSettingsTab(Window, WindUI)
    local T = LANG[Core.Config.Language] or LANG.TH

    local SavedTab = Window:Tab({ Title = T.savedSettings, Icon = "save" })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() SavedTab:SetTitle(T2.savedSettings) end)
    end)

    local savedSection = SavedTab:Section({ Title = T.configSection, Desc = T.savedSettingsDesc })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function()
            savedSection:SetTitle(T2.configSection)
            savedSection:SetDesc(T2.savedSettingsDesc)
        end)
    end)

    local saveBtn = SavedTab:Button({
        Title = T.saveConfig,
        Icon = "save",
        Callback = function()
            SaveConfigToFile(Core.Config)
            local curT = LANG[Core.Config.Language] or LANG.TH
            WindUI:Notify({ Title = curT.settings, Content = curT.savedMsg, Duration = 2 })
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() saveBtn:SetTitle(T2.saveConfig) end)
    end)

    local resetBtn = SavedTab:Button({
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
            RefreshAllLanguage() -- รีเซ็ตภาษากลับ TH แล้วให้มีผลทันทีด้วยเหมือนกัน
            local curT = LANG[Core.Config.Language] or LANG.TH
            WindUI:Notify({ Title = curT.settings, Content = curT.resetMsg, Duration = 4 })
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() resetBtn:SetTitle(T2.resetConfig) end)
    end)

    local closeBtn = SavedTab:Button({
        Title = T.closehub,
        Icon = "x",
        Callback = function()
            local GlobalStoreRef = (type(getgenv) == "function" and getgenv()) or _G
            pcall(function()
                if GlobalStoreRef.__RVXHub_Instance and GlobalStoreRef.__RVXHub_Instance.StatsConnection then
                    GlobalStoreRef.__RVXHub_Instance.StatsConnection:Disconnect()
                end
                if GlobalStoreRef.__RVXHub_Instance and GlobalStoreRef.__RVXHub_Instance.StatsGui then
                    GlobalStoreRef.__RVXHub_Instance.StatsGui:Destroy()
                end
            end)
            RVXHub_Cleanup()
        end,
    })
    Core.RegisterLanguageRefresh(function(T2)
        pcall(function() closeBtn:SetTitle(T2.closehub) end)
    end)
end

function Core.Scripts(Window, WindUI)
    local T = LANG[Core.Config.Language] or LANG.TH

    local loadOk, ScriptsModuleOrErr = pcall(function()
        local chunk = game:HttpGet(SCRIPTS_MODULE_URL)
        local fn, err = loadstring(chunk)
        if not fn then
            error(err or "loadstring failed")
        end
        return fn()
    end)

    if not loadOk or type(ScriptsModuleOrErr) ~= "table" or type(ScriptsModuleOrErr.Init) ~= "function" then
        warn("[RVX Hub] Failed to load Scripts module: " .. tostring(ScriptsModuleOrErr))
        WindUI:Notify({
            Title = T.scriptsLoadFailTitle,
            Content = T.scriptsLoadFailDesc,
            Duration = 5,
        })
        return
    end

    local initOk, initErr = pcall(function()
        ScriptsModuleOrErr.Init(Window, WindUI, T)
    end)

    if not initOk then
        warn("[RVX Hub] Scripts module Init error: " .. tostring(initErr))
        WindUI:Notify({
            Title = T.scriptsLoadFailTitle,
            Content = tostring(initErr),
            Duration = 5,
        })
    end
end

return Core
