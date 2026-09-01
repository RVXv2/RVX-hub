local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Core = {}
local HUB_VERSION = "v1.0"
local CONFIG_FILE = "RVXHub_Config.json"

-- ลิงก์ raw ของไฟล์ RVXHub_Scripts.lua (ต้องอัปโหลดไฟล์นั้นขึ้น host เอง
-- เช่น GitHub raw) แล้วแก้ URL ด้านล่างให้ตรงกับที่อัปไว้จริง
local SCRIPTS_MODULE_URL = "https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/RVXHub_Scripts.lua"

-- ===== ข้อความ Changelog (แก้ตรงนี้ที่เดียว ไม่ต้องไปหาในโค้ด) =====
-- Notes แต่ละบรรทัดจะถูกต่อกันด้วยขึ้นบรรทัดใหม่ในหน้าแรก
local CHANGELOG = {
    Version = "1.0",
    Notes = {
        "- เปิดตัว RVX Hub เวอร์ชันแรก",
        "- เพิ่มแท็บ Scripts สำหรับรันสคริปต์ภายนอก",
        "- ปรับการเปลี่ยนภาษา/ความโปร่งใสให้บันทึกค่าแล้วแจ้งให้รันสคริปต์ใหม่",
    },
}

-- ===== ป้องกันการสร้าง Hub ซ้อนกันหลายอันเวลารันสคริปต์ซ้ำ =====
-- ใช้ getgenv()/_G เก็บ reference ของ instance ก่อนหน้าไว้ (persist ข้ามการรันสคริปต์
-- ในเซสชันเดียวกัน ต่างจากตัวแปร local ที่จะหายไปทุกครั้งที่รันสคริปต์ใหม่)
-- ทุกครั้งที่โหลดสคริปต์นี้ จะเช็คแล้วทำลาย instance เดิมทิ้งก่อนเสมอ
-- เพื่อให้เหลือ Hub อยู่แค่ 1 อันตลอด ไม่ว่าจะกด/รันกี่ครั้งก็ตาม
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

-- ทำลาย Hub จากการรันครั้งก่อน (ถ้ามี) ก่อนเริ่มสร้างของใหม่
RVXHub_Cleanup()
GlobalStore.__RVXHub_Instance = {}

local DEFAULT_CONFIG = {
    Theme = "Violet",
    AutoReconnect = false,
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
        language = "ภาษา",
        languageDesc = "มีผลกับหน้าแรกและการตั้งค่าหลังรันสคริปต์ใหม่",
        appearance = "รูปลักษณ์",
        appearanceDesc = "ปรับความโปร่งใสของหน้าต่าง Hub (มีผลหลังรันสคริปต์ใหม่)",
        transparency = "หน้าต่างโปร่งใส",
        transparencySaved = "บันทึกแล้ว รันสคริปต์ใหม่เพื่อให้มีผล",
        languageSaved = "บันทึกภาษาแล้ว รันสคริปต์ใหม่เพื่อให้มีผล",
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
        scripts = "สคริปต์",
        scriptsSection = "สคริปต์ภายนอก",
        scriptsSectionDesc = "กดปุ่มเพื่อรันสคริปต์แต่ละตัว",
        scriptsEmptyTitle = "ยังไม่มีสคริปต์",
        scriptsEmptyDesc = "เพิ่มรายการได้ในไฟล์ RVXHub_Scripts.lua",
        scriptsLoadFailTitle = "โหลดแท็บ Scripts ไม่สำเร็จ",
        scriptsLoadFailDesc = "ตรวจสอบ SCRIPTS_MODULE_URL หรือการเชื่อมต่ออินเทอร์เน็ต",
        scriptRan = "รันสคริปต์แล้ว",
        scriptError = "รันไม่สำเร็จ: ",
        changelogSection = "ประกาศอัปเดต",
        changelogSectionDesc = "สิ่งที่เปลี่ยนแปลงล่าสุดใน Hub",
        changelogTitlePrefix = "อัปเดตเวอร์ชัน ",
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
        languageDesc = "Affects Home and Settings tabs after you rerun the script",
        appearance = "Appearance",
        appearanceDesc = "Adjust the Hub window transparency (applies after you rerun the script)",
        transparency = "Transparent window",
        transparencySaved = "Saved. Rerun the script for it to take effect.",
        languageSaved = "Language saved. Rerun the script for it to take effect.",
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
        scripts = "Scripts",
        scriptsSection = "External Scripts",
        scriptsSectionDesc = "Tap a button to run that script",
        scriptsEmptyTitle = "No scripts yet",
        scriptsEmptyDesc = "Add entries in RVXHub_Scripts.lua",
        scriptsLoadFailTitle = "Failed to load Scripts tab",
        scriptsLoadFailDesc = "Check SCRIPTS_MODULE_URL or your internet connection",
        scriptRan = "Script executed",
        scriptError = "Failed to run: ",
        changelogSection = "What's New",
        changelogSectionDesc = "Latest changes in this Hub",
        changelogTitlePrefix = "Version ",
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

function Core.Init(mapName)
    Core.MapName = mapName
    local T = LANG[Core.Config.Language] or LANG.TH

    local Window = WindUI:CreateWindow({
        Title = "RVX hub X " .. mapName,
        Icon = "rbxassetid://95844711546407",
        IconSize = 32, -- ค่า default เล็กมองไม่ค่อยชัด ปรับให้ใหญ่ขึ้น (ลอง 40-44 ได้ถ้ายังเล็กไป)
        Theme = Core.Config.Theme,
        Transparent = Core.Config.Transparent,
        -- ปุ่มลอย (โผล่ตอนซ่อน Hub ไว้) กดแล้วเปิด Hub กลับมา
        -- ปรับข้อความ/สีตรงนี้ได้เลย ไม่กระทบส่วนอื่น
        OpenButton = {
            Title = "RVX Hub",
            CornerRadius = UDim.new(0, 12), -- มนพอดี ไม่กลมจนเป็นแคปซูล (ปรับตัวเลขได้ ยิ่งมากยิ่งมน)
            Color = ColorSequence.new(
                Color3.fromHex("#6D28D9"), -- ม่วง
                Color3.fromHex("#3B82F6")  -- น้ำเงิน
            ),
        },
    })

    GlobalStore.__RVXHub_Instance = GlobalStore.__RVXHub_Instance or {}
    GlobalStore.__RVXHub_Instance.Window = Window

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local HomeTab = Window:Tab({ Title = T.home, Icon = "house" })

    HomeTab:Section({ Title = T.profileSection, Desc = mapName })

    -- หมายเหตุ: WindUI ไม่มี method "Section:Image()" จริง (เช็คจาก docs แล้ว
    -- ไม่มี element ชื่อ Image เลย) เดิมเรียก ProfileSection:Image({...}) จึงไม่ทำ
    -- อะไรเลย รูปโปรไฟล์เลยไม่ขึ้น วิธีที่ถูกต้องคือใช้ Paragraph ที่มี field
    -- Thumbnail/ThumbnailSize ในตัว (ดู docs: footagesus.github.io/WindUI-Docs/docs/paragraph)
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

    -- ===== ประกาศอัปเดต (Changelog) =====
    -- แก้ข้อความได้ที่ CHANGELOG ตัวแปรเดียว ด้านบนไฟล์ ไม่ต้องมาแก้ตรงนี้อีก
    HomeTab:Section({ Title = T.changelogSection, Desc = T.changelogSectionDesc })

    HomeTab:Paragraph({
        Title = T.changelogTitlePrefix .. CHANGELOG.Version,
        Desc = table.concat(CHANGELOG.Notes, "\n"),
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

    -- ===== ปุ่มลัดซ่อน/เปิด Hub =====
    -- เดิมใช้ Window:Destroy() ซึ่ง "ทำลาย" หน้าต่างถาวร กดแล้วเรียกกลับมาไม่ได้
    -- เปลี่ยนเป็น Toggle เพื่อให้กดปุ่มเดิมซ้ำแล้วเปิด Hub กลับมาได้เอง
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
                    -- เผื่อ WindUI เวอร์ชันที่ใช้ไม่มี :Toggle() ให้ลอง Open/Close แยก
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
    -- หมายเหตุ: ตัด Core.Rebuild ออกแล้ว (เดิมพัง/หายบ่อยเพราะ yield ข้าม
    -- callback boundary ตอน Destroy+CreateWindow ใหม่ทันที) ตอนนี้แค่บันทึกค่า
    -- ลงไฟล์แล้วแจ้งเตือนให้รันสคริปต์ใหม่เพื่อให้มีผล เหมือนปุ่ม "รีเซ็ต"
    SettingsTab:Section({ Title = T.language, Desc = T.languageDesc })

    SettingsTab:Dropdown({
        Title = T.language,
        Values = { "TH", "EN" },
        Value = Core.Config.Language,
        Callback = function(selected)
            if selected == Core.Config.Language then return end
            Core.Config.Language = selected
            SaveConfigToFile(Core.Config)
            WindUI:Notify({ Title = T.settings, Content = T.languageSaved, Duration = 4 })
        end,
    })

    -- ===== รูปลักษณ์ (ความโปร่งใส) =====
    -- หมายเหตุ: WindUI ไม่มีฟังก์ชันปรับความโปร่งใสระหว่างใช้งานจริง (ไม่มี
    -- Window:SetTransparency() ให้เรียก) ค่า Transparent เป็นได้แค่ true/false
    -- และตั้งได้เฉพาะตอนสร้างหน้าต่างผ่าน WindUI:CreateWindow เท่านั้น จึงแค่
    -- บันทึกค่าไว้แล้วแจ้งให้รันสคริปต์ใหม่เพื่อให้มีผล ไม่มีการ Destroy+สร้างใหม่
    -- อัตโนมัติอีกต่อไป
    SettingsTab:Section({ Title = T.appearance, Desc = T.appearanceDesc })

    SettingsTab:Toggle({
        Title = T.transparency,
        Value = Core.Config.Transparent,
        Callback = function(state)
            Core.Config.Transparent = state
            SaveConfigToFile(Core.Config)
            WindUI:Notify({ Title = T.settings, Content = T.transparencySaved, Duration = 4 })
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
            RVXHub_Cleanup()
        end,
    })
end

-- ===== แท็บ Scripts (โหลดจากไฟล์แยก RVXHub_Scripts.lua) =====
-- แยกไฟล์ออกมาเพื่อให้แก้/เพิ่มรายการสคริปต์ได้โดยไม่ต้องยุ่งกับ Core หลัก
-- โหลดผ่าน HttpGet + loadstring เหมือนกับที่ไฟล์นี้โหลด WindUI ตอนต้น
-- ครอบ pcall ไว้ทั้งขั้นตอนโหลดไฟล์และตอนเรียก Init เพื่อไม่ให้ error ตรงนี้
-- ทำให้แท็บอื่นๆ ที่สร้างไปแล้ว (Home/Settings) หายไปด้วย
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
