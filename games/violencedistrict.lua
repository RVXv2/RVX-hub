--[[
    RVX Hub - Violence District
    Map module pattern: return table with Init(Window, WindUI)

    Features are adapted from the supplied ViolenceDistrict.lua source.
    The module does NOT create its own WindUI window; it uses the RVX HUB core window.
]]

local ViolenceDistrict = {}

function ViolenceDistrict.Init(Window, WindUI)
    -- ══════════════════════════════════════════════════════════════════
    --  [2]  MOBILE / PLATFORM DETECTION
    -- ══════════════════════════════════════════════════════════════════

    local function detectMobilePlatform()
        local UIS            = game:GetService("UserInputService")
        local hasTouchScreen = UIS.TouchEnabled
        local viewportSize   = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
                              or Vector2.new(0, 0)
        local isSmallScreen  = viewportSize.X <= 1024 or viewportSize.Y <= 768
        local hasGyroscope   = UIS.GyroscopeEnabled or UIS.AccelerometerEnabled
        local noKeyboard     = not UIS.KeyboardEnabled

        local executorName      = identifyexecutor and identifyexecutor() or "Unknown"
        local executorLower     = executorName:lower()
        local isMobileExecutor  = executorLower:find("delta")  or
                                  executorLower:find("arceus") or
                                  executorLower:find("fluxus") or
                                  executorLower:find("krnl")

        local isMobile = hasTouchScreen and (noKeyboard or isSmallScreen or hasGyroscope or isMobileExecutor)
        if hasTouchScreen and isMobileExecutor then isMobile = true end

        return isMobile
    end

    local isMobile     = detectMobilePlatform()
    local executorName = identifyexecutor and identifyexecutor() or "Unknown"


    -- ══════════════════════════════════════════════════════════════════
    --  [3]  SERVICES
    -- ══════════════════════════════════════════════════════════════════

    local Players           = game:GetService("Players")
    local Workspace         = game:GetService("Workspace")
    local RunService        = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService  = game:GetService("UserInputService")
    local LocalPlayer       = Players.LocalPlayer


    -- ══════════════════════════════════════════════════════════════════
    --  [4]  CONFIG TABLE
    -- ══════════════════════════════════════════════════════════════════

    local Config = {

        -- ── ESP ────────────────────────────────────────────────────
        ESP = {
            Killer             = false,
            Survivor           = false,
            Generator          = false,
            Gate               = false,
            Hook               = false,
            Pallet             = false,
            Window             = false,
            Pumpkin            = false,
            ClosestHook        = false,
            ShowOnlyClosestHook = false,
            ShowDistance       = true,
            MaxDistance        = 500,
        },

        -- ── AUTO FEATURES ──────────────────────────────────────────
        AutoFeatures = {
            AutoGenerator      = false,
            GeneratorMode      = "great",
            AutoLeaveGenerator = false,
            LeaveDistance      = 15,
            LeaveKeybind       = Enum.KeyCode.Q,
            AutoAttack         = false,
            AttackRange        = 10,
        },

        -- ── TELEPORTATION ──────────────────────────────────────────
        Teleportation = {
            TeleportOffset = 3,
            SafeTeleport   = true,
            TeleportDelay  = 0.1,
        },

        -- ── PERFORMANCE ────────────────────────────────────────────
        Performance = {
            UpdateRate           = 0.5,
            UseDistanceCulling   = true,
            MaxESPObjects        = isMobile and 50 or 100,
            DisableParticles     = false,
            LowerGraphics        = false,
            DisableShadows       = false,
            ReduceRenderDistance = false,
        },

        -- ── MOBILE ─────────────────────────────────────────────────
        Mobile = {
            TouchControlsEnabled   = isMobile,
            ButtonSize             = 80,
            ButtonTransparency     = 0.3,
            AutoOptimize           = true,
            AggressiveOptimization = false,
        },
    }


    -- ══════════════════════════════════════════════════════════════════
    --  [5]  INTERNAL STATE / STORAGE
    -- ══════════════════════════════════════════════════════════════════

    local Highlights    = {}
    local BillboardGuis = {}
    local LastUpdate    = 0

    local UpdateConnection        = nil
    local LeaveGeneratorConnection = nil
    local AutoAttackConnection    = nil
    local MobileUI                = nil
    local FPSCounterEnabled       = false
    local FPSCounterUI            = nil


    -- [6] RVX HUB WINDOW
    -- Uses the Window and WindUI supplied by the RVX HUB core.
    local RVXWindow = Window

    -- RVX HUB tabs for Violence District
    local MainTab = RVXWindow:Tab({ Title = "info", Icon = "info" })
    local ESPTab = RVXWindow:Tab({ Title = "ESP", Icon = "eye" })
    RVXWindow:Divider()
    local SurviveTab = RVXWindow:Tab({ Title = "Survive", Icon = "user-check" })
    local KillerTab = RVXWindow:Tab({ Title = "Killer", Icon = "skull" })
    local PlayerTab = RVXWindow:Tab({ Title = "Player", Icon = "user" })
    RVXWindow:Divider()
    local TeleportTab = RVXWindow:Tab({ Title = "Teleport", Icon = "send" })
    local SettingsTab = RVXWindow:Tab({ Title = "Settings", Icon = "settings" })

    -- ══════════════════════════════════════════════════════════════════
    --  [7]  HELPER / UTILITY FUNCTIONS
    -- ══════════════════════════════════════════════════════════════════

    local function notify(title, content, duration)
        WindUI:Notify({
            Title    = title,
            Content  = content,
            Duration = duration or 3,
            Icon     = "solar:bell-bold",
        })
    end

    local function safeCall(func, ...)
        local ok, result = pcall(func, ...)
        return ok and result or nil
    end

    local function validateInstance(instance)
        return instance and typeof(instance) == "Instance" and instance.Parent ~= nil
    end

    local function isKiller()
        return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
    end

    local function isSurvivor()
        return LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors"
    end


    -- ══════════════════════════════════════════════════════════════════
    --  [8]  PERFORMANCE OPTIMIZATION
    -- ══════════════════════════════════════════════════════════════════

    local function applyMobileOptimizations()
        if not isMobile then return end
        local lighting = game:GetService("Lighting")
        safeCall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            lighting.GlobalShadows = false
            lighting.FogEnd        = 100
            lighting.Brightness    = 2

            for _, effect in ipairs(lighting:GetChildren()) do
                if effect:IsA("PostEffect") then effect.Enabled = false end
            end

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
                or obj:IsA("Fire")           or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                end
            end

            Workspace.StreamingEnabled      = true
            Workspace.StreamingMinRadius    = 32
            Workspace.StreamingTargetRadius = 64

            if Workspace:FindFirstChild("Terrain") then
                Workspace.Terrain.Decoration = false
            end
        end)
    end

    local function applyAggressiveMobileOptimizations()
        if not isMobile then return end
        applyMobileOptimizations()
        safeCall(function()
            settings().Rendering.QualityLevel      = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Rendering.EnableFRM          = false

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Texture") or obj:IsA("Decal") then
                    obj.Transparency = 1
                elseif obj:IsA("SurfaceAppearance") then
                    obj.Parent = nil
                end
            end

            for _, sound in ipairs(Workspace:GetDescendants()) do
                if sound:IsA("Sound") and sound.Name ~= "Music" then
                    sound.Volume = 0
                end
            end

            Config.Performance.UpdateRate    = 1.0
            Config.Performance.MaxESPObjects = 25
        end)
    end

    local function applyPerformanceSettings()
        local lighting = game:GetService("Lighting")

        if Config.Performance.DisableParticles then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Enabled = false
                end
            end
        end

        if Config.Performance.LowerGraphics then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end

        if Config.Performance.DisableShadows then
            lighting.GlobalShadows = false
            lighting.FogEnd        = 100
        end

        if Config.Performance.ReduceRenderDistance then
            Workspace.StreamingEnabled      = true
            Workspace.StreamingMinRadius    = 32
            Workspace.StreamingTargetRadius = 64
        end
    end

    local function resetPerformanceSettings()
        local lighting = game:GetService("Lighting")
        safeCall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Enabled = true
                end
            end

            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            lighting.GlobalShadows            = true
            lighting.FogEnd                   = 100000

            for _, effect in ipairs(lighting:GetChildren()) do
                if effect:IsA("PostEffect") then effect.Enabled = true end
            end

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Texture") or obj:IsA("Decal") then
                    obj.Transparency = 0
                end
            end
        end)
    end


    -- ══════════════════════════════════════════════════════════════════
    --  [9]  TELEPORTATION UTILITIES
    -- ══════════════════════════════════════════════════════════════════

    local function getCharacterRootPart()
        return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end

    function safeTeleport(targetCFrame, offset)
        local hrp = getCharacterRootPart()
        if not hrp then
            notify("Error", "Character not found", 3)
            return false
        end

        offset = offset or Vector3.new(0, Config.Teleportation.TeleportOffset, 0)

        if Config.Teleportation.SafeTeleport then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end

        hrp.CFrame = targetCFrame + offset

        if Config.Teleportation.SafeTeleport then
            task.delay(0.5, function()
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end)
        end

        return true
    end

    local function getAllGenerators()
        local generators = {}
        local map        = Workspace:FindFirstChild("Map")
        if not map then return generators end

        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Generator" then
                local genPart = obj:FindFirstChildWhichIsA("BasePart")
                if genPart then
                    table.insert(generators, {
                        model    = obj,
                        part     = genPart,
                        position = genPart.Position,
                    })
                end
            end
        end

        return generators
    end

    function getGeneratorsByDistance()
        local hrp = getCharacterRootPart()
        if not hrp then return {} end

        local generators = getAllGenerators()
        for _, gen in ipairs(generators) do
            gen.distance = (gen.position - hrp.Position).Magnitude
        end

        table.sort(generators, function(a, b) return a.distance < b.distance end)
        return generators
    end

    local function isNearGenerator()
        local hrp = getCharacterRootPart()
        if not hrp then return false, nil end

        local generators = getGeneratorsByDistance()
        if #generators > 0 and generators[1].distance <= Config.AutoFeatures.LeaveDistance then
            return true, generators[1].model, generators[1].distance
        end

        return false, nil, nil
    end

    function leaveGenerator()
        local hrp = getCharacterRootPart()
        if not hrp then return false end

        local isNear, nearestGen, distance = isNearGenerator()
        if not isNear then
            notify("Not Near", "You're not near any generator", 2)
            return false
        end

        local genPart = nearestGen:FindFirstChildWhichIsA("BasePart")
        if genPart then
            local direction       = (hrp.Position - genPart.Position).Unit
            local escapeDistance  = Config.AutoFeatures.LeaveDistance + 15
            local escapePosition  = hrp.Position + (direction * escapeDistance)
            local escapeCFrame    = CFrame.new(escapePosition, escapePosition + hrp.CFrame.LookVector)

            if safeTeleport(escapeCFrame, Vector3.new(0, 2, 0)) then
                notify("Escaped!", string.format("Moved %.0f studs away", escapeDistance), 2)
                return true
            end
        end

        return false
    end


    -- ══════════════════════════════════════════════════════════════════
    --  [10]  ESP — HIGHLIGHT & LABEL CORE
    -- ══════════════════════════════════════════════════════════════════

    -- ══════════════════════════════════════════════════════════════════
    --  [10]  ESP — HIGHLIGHT CORE (Highlight Only)
    -- ══════════════════════════════════════════════════════════════════

    local function createHighlight(obj, color)
        if not validateInstance(obj) or obj:FindFirstChild("H") then return end
        safeCall(function()
            local h               = Instance.new("Highlight")
            h.Name                = "H"
            h.Adornee             = obj
            h.FillColor           = color
            h.OutlineColor        = color
            h.FillTransparency    = 0.5
            h.OutlineTransparency = 0
            h.Parent              = obj
            Highlights[obj]       = h
        end)
    end

    local function removeHighlight(obj)
        if Highlights[obj] then
            if validateInstance(Highlights[obj]) then Highlights[obj]:Destroy() end
            Highlights[obj] = nil
        end
        local existingH = obj:FindFirstChild("H")
        if existingH then existingH:Destroy() end
    end

    local function clearAllESP()
        for obj in pairs(Highlights) do removeHighlight(obj) end
        Highlights = {}
    end
    -- ต่อจาก clearAllESP()
    local function removeLabel(obj)
        if BillboardGuis[obj] then
            if validateInstance(BillboardGuis[obj]) then
                BillboardGuis[obj]:Destroy()
            end
            BillboardGuis[obj] = nil
        end
    end
    -- ══════════════════════════════════════════════════════════════════
    --  [11]  ESP — PER-OBJECT UPDATE FUNCTIONS
    -- ══════════════════════════════════════════════════════════════════

    local function updatePlayerESP()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Team then
                local teamName = player.Team.Name

                if teamName == "Killer" and Config.ESP.Killer then
                    createHighlight(player.Character, Color3.fromRGB(255, 0, 0))

                elseif teamName == "Survivors" and Config.ESP.Survivor then
                    createHighlight(player.Character, Color3.fromRGB(0, 255, 0))

                else
                    removeHighlight(player.Character)
                end
            end
        end
    end

    local function updateGeneratorESP()
        if not Config.ESP.Generator then return end
        local map = Workspace:FindFirstChild("Map")
        if not map then return end

        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Generator" then
                createHighlight(obj, Color3.fromRGB(203, 132, 66))
            end
        end
    end

    local function updateGateESP()
        if not Config.ESP.Gate then return end
        local map = Workspace:FindFirstChild("Map")
        if not map then return end

        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Gate" then
                createHighlight(obj, Color3.fromRGB(255, 255, 255))
            end
        end
    end

    local function updateHookESP()
        if not Config.ESP.Hook then return end
        local map = Workspace:FindFirstChild("Map")
        if not map then return end

        if Config.ESP.ShowOnlyClosestHook then
            -- ── หา Hook ที่ใกล้ที่สุด ──────────────────────────
            local hrp = getCharacterRootPart()
            if not hrp then return end

            local closestHook, closestDist = nil, math.huge
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    local hookPart = obj:FindFirstChildWhichIsA("BasePart")
                    if hookPart then
                        local dist = (hookPart.Position - hrp.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestHook = obj
                        end
                    end
                end
            end

            -- ล้าง Hook เก่าทั้งหมด
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    removeHighlight(obj)
                end
            end

            -- แสดงเฉพาะ Hook ที่ใกล้ที่สุด
            if closestHook then
                if closestHook:FindFirstChild("Model") then
                    for _, part in ipairs(closestHook.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then
                            createHighlight(part, Color3.fromRGB(255, 255, 0))
                        end
                    end
                end
            end

        else
            -- ── แสดง Hook ทั้งหมด ─────────────────────────────
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    if obj:FindFirstChild("Model") then
                        for _, part in ipairs(obj.Model:GetDescendants()) do
                            if part:IsA("MeshPart") then
                                createHighlight(part, Color3.fromRGB(255, 0, 0))
                            end
                        end
                    end
                end
            end
        end
    end

    local function updatePalletESP()
        if not Config.ESP.Pallet then return end
        local map = Workspace:FindFirstChild("Map")
        if not map then return end

        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Palletwrong" then
                createHighlight(obj, Color3.fromRGB(255, 255, 0))
            end
        end
    end

    local function updateWindowESP()
        if not Config.ESP.Window then return end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Window" then
                createHighlight(obj, Color3.fromRGB(173, 216, 230))
            end
        end
    end

    local function updatePumpkinESP()
        if not Config.ESP.Pumpkin then return end
        local map = Workspace:FindFirstChild("Map")
        if not map then return end

        local pumpkins = map:FindFirstChild("Pumpkins")
        if not pumpkins then return end

        for _, obj in ipairs(pumpkins:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Pumpkin") then
                createHighlight(obj, Color3.fromRGB(255, 140, 0))
            end
        end
    end


    -- ══════════════════════════════════════════════════════════════════
    --  [12]  ESP — MASTER UPDATE LOOP
    -- ══════════════════════════════════════════════════════════════════

    local function updateAllESP()
        local currentTime = tick()
        if currentTime - LastUpdate < Config.Performance.UpdateRate then return end
        LastUpdate = currentTime

        -- ── ทำความสะอาด instance ที่ถูกลบไปแล้ว ─────────────
        local espCount = 0
        for obj, h in pairs(Highlights) do
            if not validateInstance(obj) or not validateInstance(h) then
                Highlights[obj] = nil
            else
                espCount = espCount + 1
            end
        end

        if espCount >= Config.Performance.MaxESPObjects then return end

        -- ── อัปเดตทุกประเภท ───────────────────────────────────
        updatePlayerESP()
        updateGeneratorESP()
        updateGateESP()
        updateHookESP()
        updatePalletESP()
        updateWindowESP()
        updatePumpkinESP()
    end

    local function startESP()
        if UpdateConnection then return end
        UpdateConnection = RunService.Heartbeat:Connect(updateAllESP)
        notify("ESP Started", "All ESP features activated", 2)
    end

    local function stopESP()
        if UpdateConnection then
            UpdateConnection:Disconnect()
            UpdateConnection = nil
        end
        clearAllESP()
        notify("ESP Stopped", "All ESP disabled", 2)
    end
    -- ══════════════════════════════════════════════════════════════════
    --  [13]  MOBILE TOUCH CONTROLS
    -- ══════════════════════════════════════════════════════════════════

    local function createMobileControls()
        if not isMobile then return end

        local screenGui               = Instance.new("ScreenGui")
        screenGui.Name                = "MobileControls"
        screenGui.ResetOnSpawn        = false
        screenGui.ZIndexBehavior      = Enum.ZIndexBehavior.Sibling

        -- ── LEAVE GENERATOR BUTTON ────────────────────────────
        local leaveButton             = Instance.new("TextButton")
        leaveButton.Name              = "LeaveGenerator"
        leaveButton.Size              = UDim2.new(0, Config.Mobile.ButtonSize, 0, Config.Mobile.ButtonSize)
        leaveButton.Position          = UDim2.new(1, -100, 0.5, -40)
        leaveButton.BackgroundColor3  = Color3.fromRGB(255, 100, 100)
        leaveButton.BackgroundTransparency = Config.Mobile.ButtonTransparency
        leaveButton.Text              = "LEAVE"
        leaveButton.TextColor3        = Color3.new(1, 1, 1)
        leaveButton.TextScaled        = true
        leaveButton.Font              = Enum.Font.GothamBold
        leaveButton.Parent            = screenGui

        local leaveCorner             = Instance.new("UICorner")
        leaveCorner.CornerRadius      = UDim.new(0, 10)
        leaveCorner.Parent            = leaveButton

        leaveButton.MouseButton1Click:Connect(leaveGenerator)

        -- ── TELEPORT TO GENERATOR BUTTON ──────────────────────
        local tpButton                = Instance.new("TextButton")
        tpButton.Name                 = "TeleportGen"
        tpButton.Size                 = UDim2.new(0, Config.Mobile.ButtonSize, 0, Config.Mobile.ButtonSize)
        tpButton.Position             = UDim2.new(1, -100, 0.5, 60)
        tpButton.BackgroundColor3     = Color3.fromRGB(100, 150, 255)
        tpButton.BackgroundTransparency = Config.Mobile.ButtonTransparency
        tpButton.Text                 = "TP GEN"
        tpButton.TextColor3           = Color3.new(1, 1, 1)
        tpButton.TextScaled           = true
        tpButton.Font                 = Enum.Font.GothamBold
        tpButton.Parent               = screenGui

        local tpCorner                = Instance.new("UICorner")
        tpCorner.CornerRadius         = UDim.new(0, 10)
        tpCorner.Parent               = tpButton

        tpButton.MouseButton1Click:Connect(function()
            local generators = getGeneratorsByDistance()
            if #generators > 0 then
                safeTeleport(generators[1].part.CFrame)
                notify("Teleported!", "Moved to closest generator", 2)
            end
        end)

        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        MobileUI         = screenGui
        notify("Mobile Controls", "Touch controls enabled!", 3)
    end


    -- ══════════════════════════════════════════════════════════════════
    --  [14]  UI TABS — ESP TAB
    -- ══════════════════════════════════════════════════════════════════
    -- ── Player ESP ─────────────────────────────────────────────────
    MainTab:Section({ Title = "info", Icon = "info" })
    MainTab:Paragraph({
        Title     = "128B!t Hub X | Discord",
        Desc      = "discord support | ดิสคอร์ดสำหรับแจ้งปัญหา",
        Image     = "rbxassetid://115578801000914",
        ImageSize = 50,
        Buttons = {
            {
                Icon     = "copy",
                Title    = "Copy",
                Callback = function()
                    setclipboard("https://discord.gg/E6ft5s7Ddu")
                end
            }
        }
    })
    MainTab:Divider()
    ESPTab:Section({ Title = "Player ESP", Icon = "eye" })

    ESPTab:Toggle({
        Title = "Killer ESP",
        Desc  = "มองฆาตกร",
        Value = false,
        Callback = function(Value)
            Config.ESP.Killer = Value
            if Value then
                startESP()
            else
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character
                    and player.Team and player.Team.Name == "Killer" then
                        removeHighlight(player.Character)
                        removeLabel(player.Character)
                    end
                end
            end
        end,
    })

    ESPTab:Toggle({
        Title = "Survivor ESP",
        Desc  = "มองผู้รอดชีวิต",
        Value = false,
        Callback = function(Value)
            Config.ESP.Survivor = Value
            if Value then
                startESP()
            else
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character
                    and player.Team and player.Team.Name == "Survivors" then
                        removeHighlight(player.Character)
                        removeLabel(player.Character)
                    end
                end
            end
        end,
    })
    ESPTab:Divider()
    ESPTab:Section({ Title = "Object ESP", Icon = "eye" })

    ESPTab:Toggle({
        Title = "Generator ESP",
        Desc  = "มองเครื่องปั่นไฟ",
        Value = false,
        Callback = function(Value)
            Config.ESP.Generator = Value
            if Value then
                startESP()
            else
                local map = Workspace:FindFirstChild("Map")
                if map then
                    for _, obj in ipairs(map:GetDescendants()) do
                        if obj:IsA("Model") and obj.Name == "Generator" then
                            removeHighlight(obj)
                            removeLabel(obj)
                        end
                    end
                end
            end
        end,
    })

    ESPTab:Toggle({
        Title = "Gate ESP",
        Desc  = "มองประตูหนี",
        Value = false,
        Callback = function(Value)
            Config.ESP.Gate = Value
            if Value then
                startESP()
            else
                local map = Workspace:FindFirstChild("Map")
                if map then
                    for _, obj in ipairs(map:GetDescendants()) do
                        if obj:IsA("Model") and obj.Name == "Gate" then
                            removeHighlight(obj)
                            removeLabel(obj)
                        end
                    end
                end
            end
        end,
    })

    ESPTab:Toggle({
        Title = "Hook ESP",
        Desc = "มองแท่งเสียบลูกชิ้น",
        Value = false,
        Callback = function(Value)
            Config.ESP.Hook = Value
            if Value then
                startESP()
            else
                local map = Workspace:FindFirstChild("Map")
                if map then
                    for _, obj in ipairs(map:GetDescendants()) do
                        if obj:IsA("Model") and obj.Name == "Hook" then
                            removeHighlight(obj)
                            removeLabel(obj)
                        end
                    end
                end
            end
        end,
    })

    ESPTab:Toggle({
        Title = "Window ESP",
        Desc  = "มองหน้าต่าง",
        Value = false,
        Callback = function(Value)
            Config.ESP.Window = Value
            if Value then
                startESP()
            else
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == "Window" then
                        removeHighlight(obj)
                        removeLabel(obj)
                    end
                end
            end
        end,
    })


    -- ══════════════════════════════════════════════════════════════════
    --  [15]  UI TABS — GAMEPLAY TAB
    -- ══════════════════════════════════════════════════════════════════
    -- ── Auto Features ─────────────────────────────────────────────────
    SurviveTab:Section({ Title = "Auto Generator", Icon = "rocket" })

    SurviveTab:Toggle({
        Title = "Auto Complete Generators",
        Desc  = "ออโต้เครื่องปั่นไฟ",
        Value = false,
        Callback = function(Value)
            Config.AutoFeatures.AutoGenerator = Value
        end,
    })

    SurviveTab:Dropdown({
        Title  = "Generator Mode",
        Desc   = "เลือกโหมด",
        Values = { "Great (Fast)", "Normal (Slow)" },
        Value  = "Great (Fast)",
        Callback = function(Option)
            Config.AutoFeatures.GeneratorMode = Option == "Great (Fast)" and "great" or "normal"
        end,
    })
    SurviveTab:Divider()
    local AvoidEnabled    = false
    local AvoidRadius     = 20
    local AvoidCooldown   = 5
    local lastAvoidTime   = 0
    local AvoidConnection = nil

    -- หาตัว Killer
    local function getKillerRoot()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer
            and player.Team and player.Team.Name == "Killer"
            and player.Character then
                return player.Character:FindFirstChild("HumanoidRootPart")
            end
        end
        return nil
    end

    -- หา Generator ที่ไกลจาก Killer มากที่สุด = ปลอดภัยสุด
    local function getSafeGenerator(killerPos)
        local map = Workspace:FindFirstChild("Map")
        if not map then return nil end

        local bestPart, bestDist = nil, 0
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Generator" then
                local genPart = obj:FindFirstChildWhichIsA("BasePart")
                if genPart then
                    local d = (genPart.Position - killerPos).Magnitude
                    if d > bestDist then
                        bestDist = d
                        bestPart = genPart
                    end
                end
            end
        end

        return bestPart
    end

    SurviveTab:Section({ Title = "Avoid Killer", Icon = "user"})

    SurviveTab:Toggle({
        Title = "Auto Avoid Killer",
        Desc  = "วาร์ปหนี Killer อัตโนมัติ",
        Value = false,
        Callback = function(v)
            AvoidEnabled = v

            if v then
                AvoidConnection = RunService.Heartbeat:Connect(function()
                    if not AvoidEnabled then return end

                    -- เช็ค cooldown
                    local now = tick()
                    if now - lastAvoidTime < AvoidCooldown then return end

                    local hrp        = getCharacterRootPart()
                    local killerRoot = getKillerRoot()
                    if not hrp or not killerRoot then return end

                    local dist = (killerRoot.Position - hrp.Position).Magnitude

                    if dist <= AvoidRadius then
                        local safeGen = getSafeGenerator(killerRoot.Position)
                        if safeGen then
                            lastAvoidTime = now
                            safeTeleport(safeGen.CFrame)
                        end
                    end
                end)
            else
                if AvoidConnection then
                    AvoidConnection:Disconnect()
                    AvoidConnection = nil
                end
            end
        end,
    })

    SurviveTab:Slider({
        Title = "Detection Radius (studs)",
        Desc  = "ระยะที่ Killer จะทริกการวาร์ป",
        Step  = 1,
        Value = { Min = 10, Max = 80, Default = 20 },
        Callback = function(v)
            AvoidRadius = v
        end,
    })

    getgenv().AimlockPart    = "HumanoidRootPart"
    getgenv().AimlockEnabled = false

    local aimlockConn = nil

    SurviveTab:Divider()
    SurviveTab:Section({ Title = "Gun Aimlock", Icon = "crosshair" })

    SurviveTab:Dropdown({
        Title  = "Aimlock Target Part",
        Desc   = "เลือกจุดที่จะล็อค",
        Values = { "HumanoidRootPart", "Head", "UpperTorso", "RightArm", "LeftArm" },
        Multi  = false,
        Value  = "HumanoidRootPart",
        Callback = function(v)
            getgenv().AimlockPart = v
        end
    })

    SurviveTab:Toggle({
        Title = "Aimlock Killer",
        Desc  = "ล็อคเป้าไปที่ Killer",
        Value = false,
        Callback = function(v)
            getgenv().AimlockEnabled = v

            if v then
                aimlockConn = RunService.RenderStepped:Connect(function()
                    if not getgenv().AimlockEnabled then return end

                    -- หา Killer
                    local targetPlayer = nil
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer
                        and p.Team and p.Team.Name == "Killer"
                        and p.Character then
                            targetPlayer = p
                            break
                        end
                    end

                    if not targetPlayer or not targetPlayer.Character then return end

                    local targetPart = targetPlayer.Character:FindFirstChild(getgenv().AimlockPart)
                        or targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not targetPart then return end

                    local currentCF = workspace.CurrentCamera.CFrame
                    local targetCF  = CFrame.new(currentCF.Position, targetPart.Position)
                    workspace.CurrentCamera.CFrame = currentCF:Lerp(targetCF, 1)
                end)
            else
                if aimlockConn then
                    aimlockConn:Disconnect()
                    aimlockConn = nil
                end
            end
        end
    })
    -- ── Killer Powers ─────────────────────────────────────────────────
    KillerTab:Section({ Title = "Killer Powers", Icon = "skull" })

    KillerTab:Toggle({
        Title = "Auto Attack Nearby Survivors",
        Desc = "ออโต้โจมตี",
        Value = false,
        Callback = function(Value)
            Config.AutoFeatures.AutoAttack = Value

            if Value then
                if not isKiller() then
                    notify("Error", "You must be the Killer!", 3)
                    return
                end

                AutoAttackConnection = RunService.Heartbeat:Connect(function()
                    if not Config.AutoFeatures.AutoAttack then return end

                    local hrp    = getCharacterRootPart()
                    local target = nil
                    local dist   = math.huge

                    if hrp then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Team
                            and p.Team.Name == "Survivors" and p.Character then
                                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                                if tHRP then
                                    local d = (tHRP.Position - hrp.Position).Magnitude
                                    if d < dist and d <= Config.AutoFeatures.AttackRange then
                                        dist   = d
                                        target = p
                                    end
                                end
                            end
                        end
                    end

                    if target then
                        local remotes    = ReplicatedStorage:FindFirstChild("Remotes")
                        local attacks    = remotes and remotes:FindFirstChild("Attacks")
                        local basicAttack = attacks and attacks:FindFirstChild("BasicAttack")
                        if basicAttack then basicAttack:FireServer(false) end
                    end
                end)

            else
                if AutoAttackConnection then
                    AutoAttackConnection:Disconnect()
                    AutoAttackConnection = nil
                end
            end
        end,
    })

    KillerTab:Slider({
        Title = "Auto Attack Range (studs)",
        Desc = "ปรับระยะโจมตี",
        Value = { Min = 5, Max = 20, Default = 10 },
        Callback = function(Value)
            Config.AutoFeatures.AttackRange = Value
        end,
    })

    -- ══════════════════════════════════════════════════════════════════
    --  PLAYER TAB — MOVEMENT
    -- ══════════════════════════════════════════════════════════════════

    local SpeedEnabled    = false
    local SpeedValue      = 16
    local SpeedConnection = nil   -- loop ที่คอย force WalkSpeed

    -- ✅ define ฟังก์ชันที่ขาดหายไป
    local function getHumanoid(player)
        local char = player and player.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    PlayerTab:Section({ Title = "Movement" })

    PlayerTab:Toggle({
        Title = "Speed Boost",
        Desc  = "วิ่งเร็ว",
        Callback = function(v)
            SpeedEnabled = v

            if v then
                -- ✅ ใช้ Heartbeat loop บังคับ WalkSpeed ทุก frame
                -- ป้องกันเกม reset กลับ
                SpeedConnection = RunService.Heartbeat:Connect(function()
                    local h = getHumanoid(LocalPlayer)
                    if h then h.WalkSpeed = SpeedValue end
                end)
            else
                -- ปิด loop + คืนความเร็วปกติ
                if SpeedConnection then
                    SpeedConnection:Disconnect()
                    SpeedConnection = nil
                end
                local h = getHumanoid(LocalPlayer)
                if h then h.WalkSpeed = 16 end
            end
        end
    })

    PlayerTab:Slider({
        Title = "Speed Value",
        Desc  = "ปรับความเร็ว",
        Step  = 1,
        Value = { Min = 16, Max = 500, Default = 16 },
        Callback = function(v)
            SpeedValue = v
            -- Loop จะ pick up ค่าใหม่เองอัตโนมัติ ไม่ต้องทำอะไรเพิ่ม
        end
    })

    -- รีตัวแล้วให้ speed กลับมาทันที
    LocalPlayer.CharacterAdded:Connect(function(char)
        if SpeedEnabled then
            local hum = char:WaitForChild("Humanoid")
            task.wait(0.5)   -- รอ server load ก่อนเล็กน้อย
            hum.WalkSpeed = SpeedValue
        end
    end)
    PlayerTab:Divider()

    -- ── NoClip ───────────────────────────────────────────────────────
    local NoClipEnabled    = false
    local NoClipConnection = nil

    PlayerTab:Toggle({
        Title = "NoClip",
        Desc  = "ทะลุกำแพง",
        Value = false,
        Callback = function(v)
            NoClipEnabled = v

            if v then
                -- ✅ Stepped บังคับ CanCollide = false ทุก frame
                -- ใช้ Stepped แทน Heartbeat เพราะรันก่อน physics
                NoClipConnection = RunService.Stepped:Connect(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end)
            else
                if NoClipConnection then
                    NoClipConnection:Disconnect()
                    NoClipConnection = nil
                end
                -- คืน collision ให้ปกติ
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end,
    })

    -- รีตัวแล้วเปิด NoClip กลับอัตโนมัติ
    LocalPlayer.CharacterAdded:Connect(function(char)
        if NoClipEnabled then
            NoClipConnection = RunService.Stepped:Connect(function()
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end
    end)

    -- ── NoFall ────────────────────────────────────────────────────────
    local NoFallEnabled    = false
    local NoFallConnection = nil
    local lastHealth       = 100

    local function applyNoFall(char)
        local hum = char:WaitForChild("Humanoid")

        -- ปิด state ที่ทำให้ล้ม/โดน fall damage
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,   false)

        lastHealth = hum.Health

        -- ถ้า HP หายจาก fall → คืนทันที
        NoFallConnection = hum.HealthChanged:Connect(function(newHp)
            if not NoFallEnabled then return end

            -- HP ลดลงขณะ FreeFall หรือ Landed = fall damage → คืน
            local state = hum:GetState()
            if newHp < lastHealth and (
                state == Enum.HumanoidStateType.Freefall or
                state == Enum.HumanoidStateType.Landed
            ) then
                hum.Health = lastHealth
            else
                lastHealth = newHp
            end
        end)
    end

    PlayerTab:Toggle({
        Title = "No Fall Damage",
        Desc  = "ตกไม่เจ็บ",
        Value = false,
        Callback = function(v)
            NoFallEnabled = v

            if v then
                local char = LocalPlayer.Character
                if char then applyNoFall(char) end

                -- รีตัวแล้วให้ apply ใหม่
                LocalPlayer.CharacterAdded:Connect(function(newChar)
                    if NoFallEnabled then
                        applyNoFall(newChar)
                    end
                end)
            else
                if NoFallConnection then
                    NoFallConnection:Disconnect()
                    NoFallConnection = nil
                end
                -- คืน state ปกติ
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,   true)
                    end
                end
            end
        end,
    })
    -- ══════════════════════════════════════════════════════════════════
    --  [16]  UI TABS — TELEPORT TAB
    -- ══════════════════════════════════════════════════════════════════
    TeleportTab:Section({ Title = "Generator Teleportation" })

    TeleportTab:Button({
        Title = "Teleport to Closest Generator",
        Desc = "วาร์ปหาเครื่องปั่นไฟที่ใกล้ที่สุด",
        Callback = function()
            local generators = getGeneratorsByDistance()
            if #generators == 0 then notify("Not Found", "No generators found", 3); return end

            if safeTeleport(generators[1].part.CFrame) then
                notify("Teleported!", string.format("Moved to closest generator (%.0fm)", generators[1].distance), 3)
            end
        end,
    })

    TeleportTab:Button({
        Title = "Teleport to Farthest Generator",
        Desc = "วาร์ปหาเครื่องปั่นไฟทีไกลที่สุด",
        Callback = function()
            local generators = getGeneratorsByDistance()
            if #generators == 0 then notify("Not Found", "No generators found", 3); return end

            if safeTeleport(generators[#generators].part.CFrame) then
                notify("Teleported!", string.format("Moved to farthest generator (%.0fm)", generators[#generators].distance), 3)
            end
        end,
    })
    TeleportTab:Divider()

    -- ── Other Teleports ───────────────────────────────────────────────
    TeleportTab:Section({ Title = "Other Teleports" })
    local TPSelectedPlayer = nil

    local function GetPlayerList()
        local tbl = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                table.insert(tbl, plr.Name)
            end
        end
        return tbl
    end

    local PlayerTPDropdown = TeleportTab:Dropdown({
        Title    = "Select Player",
        Desc     = "เลือกผู้เล่น",
        Values   = GetPlayerList(),
        Multi    = false,
        Callback = function(v)
            TPSelectedPlayer = v
        end
    })

    Players.PlayerAdded:Connect(function()
        task.wait(1)
        PlayerTPDropdown:Refresh(GetPlayerList())
    end)

    Players.PlayerRemoving:Connect(function()
        task.wait()
        PlayerTPDropdown:Refresh(GetPlayerList())
    end)

    TeleportTab:Button({
        Title = "TP To Player",
        Desc  = "วาร์ปไปหาผู้เล่น",
        Callback = function()
            local target = Players:FindFirstChild(TPSelectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character:PivotTo(
                    target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                )
            end
        end
    })

    TeleportTab:Button({
        Title = "TP to Nearest Gate",
        Desc = "วาร์ปเข้าประตูหนี",
        Callback = function()
            local hrp = getCharacterRootPart()
            local map = Workspace:FindFirstChild("Map")
            if not hrp or not map then notify("Error", "Character or Map not found", 3); return end

            local nearestGate, nearestDist = nil, math.huge
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Gate" then
                    local gatePart = obj:FindFirstChildWhichIsA("BasePart")
                    if gatePart then
                        local dist = (gatePart.Position - hrp.Position).Magnitude
                        if dist < nearestDist then
                            nearestGate = gatePart
                            nearestDist = dist
                        end
                    end
                end
            end

            if nearestGate then
                safeTeleport(nearestGate.CFrame)
                notify("Teleported", string.format("Teleported to gate (%.0fm)", nearestDist), 3)
            else
                notify("Not Found", "No gates found", 3)
            end
        end,
    })


    -- ══════════════════════════════════════════════════════════════════
    --  [17]  UI TABS — SETTINGS TAB
    -- ══════════════════════════════════════════════════════════════════
    -- ── Performance Options ───────────────────────────────────────────

    local Lighting = game:GetService("Lighting")

    -- เก็บค่าเดิมไว้คืนตอนปิด
    local originalBrightness    = Lighting.Brightness
    local originalClockTime     = Lighting.ClockTime
    local originalAmbient       = Lighting.Ambient
    local originalFogEnd        = Lighting.FogEnd
    local originalFogStart      = Lighting.FogStart
    local originalFogColor      = Lighting.FogColor
    local originalGlobalShadows = Lighting.GlobalShadows

    SettingsTab:Section({ Title = "Visual" })

    SettingsTab:Toggle({
        Title = "Fullbright",
        Desc  = "สว่างทั้งแมพ",
        Value = false,
        Callback = function(v)
            if v then
                Lighting.Brightness    = 10
                Lighting.ClockTime     = 14
                Lighting.Ambient       = Color3.fromRGB(178, 178, 178)
                Lighting.GlobalShadows = false
                -- ปิด PostEffect ทั้งหมดที่ทำให้มืด
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect")
                    or effect:IsA("ColorCorrectionEffect")
                    or effect:IsA("SunRaysEffect") then
                        effect.Enabled = false
                    end
                end
            else
                Lighting.Brightness    = originalBrightness
                Lighting.ClockTime     = originalClockTime
                Lighting.Ambient       = originalAmbient
                Lighting.GlobalShadows = originalGlobalShadows
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect")
                    or effect:IsA("ColorCorrectionEffect")
                    or effect:IsA("SunRaysEffect") then
                        effect.Enabled = true
                    end
                end
            end
        end,
    })

    SettingsTab:Toggle({
        Title = "No Fog",
        Desc  = "เอาหมอกออก",
        Value = false,
        Callback = function(v)
            if v then
                Lighting.FogEnd   = 100000
                Lighting.FogStart = 100000
                Lighting.FogColor = Color3.fromRGB(0, 0, 0)
            else
                Lighting.FogEnd   = originalFogEnd
                Lighting.FogStart = originalFogStart
                Lighting.FogColor = originalFogColor
            end
        end,
    })
    SettingsTab:Section({ Title = "Performance Options" })
    SettingsTab:Toggle({
        Title = "Disable Particles & Effects",
        Desc = "ปิดเอฟเฟค",
        Value = false,
        Callback = function(Value)
            Config.Performance.DisableParticles = Value
            applyPerformanceSettings()
        end,
    })

    SettingsTab:Toggle({
        Title = "Lower Graphics Quality",
        Desc = "คุณภาพดินน้ำมัน",
        Value = false,
        Callback = function(Value)
            Config.Performance.LowerGraphics = Value
            applyPerformanceSettings()
        end,
    })

    SettingsTab:Toggle({
        Title = "Disable Shadows",
        Desc = "ปิดแสงเงา",
        Value = false,
        Callback = function(Value)
            Config.Performance.DisableShadows = Value
            applyPerformanceSettings()
        end,
    })

    SettingsTab:Toggle({
        Title = "Reduce Render Distance",
        Desc = "อะไรไม่รู้",
        Value = false,
        Callback = function(Value)
            Config.Performance.ReduceRenderDistance = Value
            applyPerformanceSettings()
        end,
    })

    SettingsTab:Button({
        Title = "Apply All Performance Boosts",
        Desc = "เปิดทั้งหมด",
        Callback = function()
            Config.Performance.DisableParticles     = true
            Config.Performance.LowerGraphics        = true
            Config.Performance.DisableShadows       = true
            Config.Performance.ReduceRenderDistance = true
            Config.Performance.UseDistanceCulling   = true
            applyPerformanceSettings()
            notify("Performance", "All performance boosts applied!", 3)
        end,
    })

    SettingsTab:Button({
        Title = "Reset Performance Settings",
        Desc = "ล้างทั้งหมด",
        Callback = function()
            Config.Performance.DisableParticles     = false
            Config.Performance.LowerGraphics        = false
            Config.Performance.DisableShadows       = false
            Config.Performance.ReduceRenderDistance = false
            resetPerformanceSettings()
            notify("Performance", "Settings reset to default", 2)
        end,
    })

    -- ══════════════════════════════════════════════════════════════════
    --  [18]  BACKGROUND LOOP — AUTO GENERATOR
    -- ══════════════════════════════════════════════════════════════════

    local AUTO_GEN_RANGE = 10
    local activeGenObj   = nil
    local activeGenPoint = nil

    -- ── Loop 1 : RepairEvent (true/false ตามระยะ) ────────────────────
    task.spawn(function()
        while task.wait(0.2) do
            if Config.AutoFeatures.AutoGenerator then
                safeCall(function()
                    local hrp = getCharacterRootPart()
                    if not hrp then return end

                    local remotes         = ReplicatedStorage:FindFirstChild("Remotes")
                    local genRemotes      = remotes    and remotes:FindFirstChild("Generator")
                    local repairEvent     = genRemotes and genRemotes:FindFirstChild("RepairEvent")
                    if not repairEvent then return end

                    local map = Workspace:FindFirstChild("Map")
                    if not map then return end

                    -- หา Generator ที่ใกล้ที่สุดในรัศมี
                    local nearestObj, nearestDist = nil, math.huge
                    for _, obj in ipairs(map:GetDescendants()) do
                        if obj:IsA("Model") and obj.Name == "Generator" then
                            local genPart = obj:FindFirstChildWhichIsA("BasePart")
                            if genPart then
                                local dist = (genPart.Position - hrp.Position).Magnitude
                                if dist <= AUTO_GEN_RANGE and dist < nearestDist then
                                    nearestDist = dist
                                    nearestObj  = obj
                                end
                            end
                        end
                    end

                    -- เดินออกหรือเปลี่ยน Gen → ส่ง false ทันที
                    if activeGenObj and activeGenObj ~= nearestObj then
                        pcall(function()
                            repairEvent:FireServer(activeGenPoint, false)
                        end)
                        activeGenObj   = nil
                        activeGenPoint = nil
                    end

                    -- อยู่ใกล้ Gen → ส่ง true + จำไว้
                    if nearestObj then
                        for _, point in ipairs(nearestObj:GetChildren()) do
                            if point.Name:find("GeneratorPoint") then
                                pcall(function()
                                    repairEvent:FireServer(point, true)
                                    activeGenPoint = point
                                    activeGenObj   = nearestObj
                                end)
                            end
                        end
                    end
                end)

            else
                -- ปิด Toggle → ส่ง false ปิดให้เรียบร้อย
                if activeGenPoint then
                    pcall(function()
                        local remotes     = ReplicatedStorage:FindFirstChild("Remotes")
                        local genRemotes  = remotes   and remotes:FindFirstChild("Generator")
                        local repairEvent = genRemotes and genRemotes:FindFirstChild("RepairEvent")
                        if repairEvent then
                            repairEvent:FireServer(activeGenPoint, false)
                        end
                    end)
                    activeGenObj   = nil
                    activeGenPoint = nil
                end
            end
        end
    end)

    -- ── Loop 2 : SkillCheckEvent (เร็วมาก = perfect ทุกครั้ง) ────────
    task.spawn(function()
        while task.wait(0.05) do
            if Config.AutoFeatures.AutoGenerator and activeGenObj and activeGenPoint then
                safeCall(function()
                    local remotes         = ReplicatedStorage:FindFirstChild("Remotes")
                    local genRemotes      = remotes    and remotes:FindFirstChild("Generator")
                    local skillCheckEvent = genRemotes and genRemotes:FindFirstChild("SkillCheckResultEvent")
                    if not skillCheckEvent then return end

                    local result = Config.AutoFeatures.GeneratorMode == "great" and "success" or "neutral"
                    local value  = Config.AutoFeatures.GeneratorMode == "great" and 1 or 0
                    skillCheckEvent:FireServer(result, value, activeGenObj, activeGenPoint)
                end)
            end
        end
    end)
    -- ══════════════════════════════════════════════════════════════════
    --  [19]  INITIALIZE
    -- ══════════════════════════════════════════════════════════════════

    if isMobile and Config.Mobile.AutoOptimize then
        applyMobileOptimizations()
    end
end

return ViolenceDistrict
