-- RVX Hub | Build A Boat For Treasure module
-- Ported from the supplied PBR HUB BABFT script.
-- UI is adapted to the RVX Hub Window/WindUI interface.

local Module = {}

function Module.Init(Window, WindUI)
    if not Window or type(Window.Tab) ~= "function" then
        warn("[RVX Hub] BABFT: RVX Window/Tab API unavailable")
        return false
    end

    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local CoreGui = game:GetService("CoreGui")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local LP = Players.LocalPlayer
    if not LP then
        return false
    end

    local Config = getgenv().BABFT_Config or {
        AutoFarm = false,
        BypassWater = false,
        AutoGodMode = false,
        AutoClaim = true,
    }
    getgenv().BABFT_Config = Config

    local alive = true
    local connections = {}

    local function notify(title, content, duration)
        pcall(function()
            WindUI:Notify({
                Title = tostring(title or "BABFT"),
                Content = tostring(content or ""),
                Duration = duration or 2,
            })
        end)
    end

    -- Invisible support platform used by the original farm logic.
    local Platform = Instance.new("Part")
    Platform.Name = "RVX_BABFT_FarmPlatform"
    Platform.Size = Vector3.new(10, 1, 10)
    Platform.Anchored = true
    Platform.CanCollide = true
    Platform.Transparency = 1
    Platform.Parent = Workspace

    local function GetRoot()
        local char = LP.Character or LP.CharacterAdded:Wait()
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function GetHumanoid()
        local char = LP.Character or LP.CharacterAdded:Wait()
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    local function MovePlatformTo(targetCFrame)
        if Platform and Platform.Parent then
            Platform.CFrame = targetCFrame - Vector3.new(0, 3, 0)
        end
    end

    -- Farm statistics state
    local StatsGui
    local StatsFrame
    local StatsRuntime
    local StatsRate
    local StatsStatus
    local StatsClose
    local StatsStartTime = 0
    local StatsStartGold = nil
    local StatsLastGold = nil
    local StatsGoldPerHour = 0

    local function cleanup()
        if not alive then return end
        alive = false
        Config.AutoFarm = false
        Config.AutoClaim = false

        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)

        if Platform then
            pcall(function() Platform:Destroy() end)
        end
        if StatsGui then
            pcall(function() StatsGui:Destroy() end)
            StatsGui = nil
        end
    end

    -- Floating iPhone-style farm statistics panel.
    -- It is shown only while Auto Farm is enabled and does not replace the RVX UI.
    local GOLD_NAMES = {
        gold = true,
        coins = true,
        coin = true,
        money = true,
        cash = true,
        treasure = true,
    }

    local function findGoldValue()
        -- BABFT normally exposes currency in player-side values/leaderstats.
        -- Search the whole LocalPlayer tree so nested value folders are also detected.
        local preferred = {
            LP:FindFirstChild("leaderstats"),
            LP:FindFirstChild("Data"),
            LP:FindFirstChild("Stats"),
            LP:FindFirstChild("PlayerData"),
        }

        for _, container in ipairs(preferred) do
            if container then
                local direct = container:FindFirstChild("Gold")
                if direct and (direct:IsA("IntValue") or direct:IsA("NumberValue")) then
                    return direct
                end
                for _, obj in ipairs(container:GetDescendants()) do
                    if (obj:IsA("IntValue") or obj:IsA("NumberValue")) and GOLD_NAMES[string.lower(obj.Name)] then
                        return obj
                    end
                end
            end
        end

        for _, obj in ipairs(LP:GetDescendants()) do
            if (obj:IsA("IntValue") or obj:IsA("NumberValue")) and GOLD_NAMES[string.lower(obj.Name)] then
                return obj
            end
        end

        return nil
    end

    local function formatNumber(n)
        n = tonumber(n) or 0
        local sign = n < 0 and "-" or ""
        n = math.abs(n)
        if n >= 1e9 then return sign .. string.format("%.2fB", n / 1e9) end
        if n >= 1e6 then return sign .. string.format("%.2fM", n / 1e6) end
        if n >= 1e3 then return sign .. string.format("%.1fK", n / 1e3) end
        return sign .. tostring(math.floor(n + 0.5))
    end

    local function formatTime(seconds)
        seconds = math.max(0, math.floor(seconds or 0))
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local sec = seconds % 60
        return string.format("%02d:%02d:%02d", h, m, sec)
    end

    local function createStatsWindow()
        if StatsGui and StatsGui.Parent then return end

        StatsGui = Instance.new("ScreenGui")
        StatsGui.Name = "RVX_BABFT_FarmStats"
        StatsGui.ResetOnSpawn = false
        StatsGui.IgnoreGuiInset = true
        StatsGui.DisplayOrder = 999
        local parentGui
        pcall(function()
            if typeof(gethui) == "function" then
                parentGui = gethui()
            end
        end)
        parentGui = parentGui or CoreGui
        pcall(function() StatsGui.Parent = parentGui end)
        if not StatsGui.Parent then
            StatsGui.Parent = LP:WaitForChild("PlayerGui")
        end

        StatsFrame = Instance.new("Frame")
        StatsFrame.Name = "StatsCard"
        StatsFrame.Size = UDim2.fromOffset(255, 132)
        StatsFrame.Position = UDim2.new(1, -275, 0, 82)
        StatsFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        StatsFrame.BackgroundTransparency = 0.08
        StatsFrame.BorderSizePixel = 0
        StatsFrame.Parent = StatsGui
        Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 18)

        local stroke = Instance.new("UIStroke", StatsFrame)
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.82
        stroke.Thickness = 1

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(14, 9)
        title.Size = UDim2.new(1, -54, 0, 22)
        title.Font = Enum.Font.GothamSemibold
        title.Text = "Farm Statistics"
        title.TextColor3 = Color3.fromRGB(245, 245, 245)
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = StatsFrame

        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(7, 7)
        dot.Position = UDim2.new(1, -30, 0, 17)
        dot.BackgroundColor3 = Color3.fromRGB(95, 220, 135)
        dot.BorderSizePixel = 0
        dot.Parent = StatsFrame
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        StatsClose = Instance.new("TextButton")
        StatsClose.BackgroundTransparency = 1
        StatsClose.Size = UDim2.fromOffset(28, 28)
        StatsClose.Position = UDim2.new(1, -33, 0, 4)
        StatsClose.Text = "×"
        StatsClose.Font = Enum.Font.GothamMedium
        StatsClose.TextColor3 = Color3.fromRGB(170, 170, 175)
        StatsClose.TextSize = 20
        StatsClose.Parent = StatsFrame
        StatsClose.Activated:Connect(function()
            if StatsGui then StatsGui.Enabled = false end
        end)

        local function makeLabel(y, default)
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.fromOffset(14, y)
            label.Size = UDim2.new(1, -28, 0, 22)
            label.Font = Enum.Font.GothamMedium
            label.Text = default
            label.TextColor3 = Color3.fromRGB(205, 205, 212)
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = StatsFrame
            return label
        end

        StatsRate = makeLabel(39, "Gold / Hour     --")
        StatsRuntime = makeLabel(66, "Runtime             00:00:00")
        StatsStatus = makeLabel(93, "Status               Waiting...")
        StatsStatus.TextColor3 = Color3.fromRGB(155, 155, 165)
    end

    local function resetStats()
        local value = findGoldValue()
        StatsStartTime = os.clock()
        StatsStartGold = value and tonumber(value.Value) or nil
        StatsLastGold = StatsStartGold
        StatsGoldPerHour = 0

        if StatsRate then
            StatsRate.Text = StatsStartGold and "Gold / Hour     0" or "Gold / Hour     detecting..."
        end
        if StatsRuntime then
            StatsRuntime.Text = "Runtime             00:00:00"
        end
        if StatsStatus then
            StatsStatus.Text = StatsStartGold and "Status               Farming..." or "Status               Finding Gold..."
        end
    end

    local function showStats()
        createStatsWindow()
        resetStats()
        if StatsGui then StatsGui.Enabled = true end
    end

    local function hideStats()
        if StatsGui then StatsGui.Enabled = false end
    end

    task.spawn(function()
        while alive do
            task.wait(1)
            if not alive or not StatsGui or not StatsFrame or not Config.AutoFarm then
                continue
            end

            pcall(function()
                local now = os.clock()
                local elapsed = math.max(1, now - StatsStartTime)
                local value = findGoldValue()
                local currentGold = value and tonumber(value.Value) or nil

                -- If Gold was not available when the farm started, keep trying until it appears.
                if not StatsStartGold and currentGold then
                    StatsStartGold = currentGold
                    StatsLastGold = currentGold
                    StatsStartTime = now
                    elapsed = 1
                end

                if currentGold and StatsStartGold then
                    local gained = math.max(0, currentGold - StatsStartGold)
                    StatsGoldPerHour = gained * 3600 / elapsed
                    StatsLastGold = currentGold
                    StatsRate.Text = "Gold / Hour     " .. formatNumber(StatsGoldPerHour)
                    StatsStatus.Text = "Status               Farming..."
                else
                    StatsRate.Text = "Gold / Hour     detecting..."
                    StatsStatus.Text = "Status               Gold not found"
                end

                StatsRuntime.Text = "Runtime             " .. formatTime(elapsed)
            end)
        end
    end)

    -- Layout: ใช้แท็บเดียวของแมพ ส่วน Settings ใช้ของ RVX Hub เพียงอันเดียว
    local BuildTab = Window:Tab({ Title = "Build A Boat", Icon = "ship" })

    BuildTab:Section({ Title = "Farm" })

    BuildTab:Toggle({
        Title = "Auto Farm Gold",
        Icon = "coins",
        Desc = "ฟาร์มทองผ่าน CaveStage 1-10 อัตโนมัติ",
        Value = Config.AutoFarm == true,
        Callback = function(value)
            Config.AutoFarm = value == true
            if Config.AutoFarm then
                showStats()
                notify("Auto Farm Gold", "เปิดใช้งานแล้ว")
            else
                hideStats()
                notify("Auto Farm Gold", "ปิดใช้งานแล้ว")
            end
        end,
    })

    BuildTab:Toggle({
        Title = "Auto Claim",
        Icon = "hand-coins",
        Desc = "กด Claim อัตโนมัติเมื่อปุ่มปรากฏ",
        Value = Config.AutoClaim ~= false,
        Callback = function(value)
            Config.AutoClaim = value == true
            notify("Auto Claim", Config.AutoClaim and "เปิดใช้งานแล้ว" or "ปิดใช้งานแล้ว")
        end,
    })

    BuildTab:Section({ Title = "Tools" })

    BuildTab:Button({
        Title = "Rejoin Server",
        Icon = "refresh-cw",
        Desc = "เข้าเซิร์ฟเวอร์ใหม่",
        Callback = function()
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LP)
            end)
        end,
    })

    BuildTab:Button({
        Title = "Reset Farm Platform",
        Icon = "rotate-ccw",
        Desc = "รีเซ็ตแท่นช่วยฟาร์ม",
        Callback = function()
            if Platform and Platform.Parent then
                Platform.Position = Vector3.new(0, 0, 0)
                notify("Farm Platform", "รีเซ็ตตำแหน่งแล้ว")
            end
        end,
    })

    -- Auto Claim Button
    task.spawn(function()
        while alive do
            task.wait(0.3)
            if Config.AutoClaim or Config.AutoFarm then
                pcall(function()
                    local playerGui = LP:FindFirstChild("PlayerGui")
                    if not playerGui then return end

                    for _, v in ipairs(playerGui:GetDescendants()) do
                        if not (v:IsA("TextButton") or v:IsA("ImageButton")) then
                            continue
                        end

                        local text = ""
                        pcall(function() text = tostring(v.Text or "") end)
                        local lower = string.lower(text)

                        if string.find(text, "เรียกร้อง") or string.find(lower, "claim") then
                            if typeof(getconnections) == "function" then
                                pcall(function()
                                    for _, connection in ipairs(getconnections(v.MouseButton1Click)) do
                                        pcall(function() connection:Fire() end)
                                    end
                                end)
                                pcall(function()
                                    for _, connection in ipairs(getconnections(v.MouseButton1Down)) do
                                        pcall(function() connection:Fire() end)
                                    end
                                end)
                                pcall(function()
                                    for _, connection in ipairs(getconnections(v.Activated)) do
                                        pcall(function() connection:Fire() end)
                                    end
                                end)
                            else
                                pcall(function() v:Activate() end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Prevent character body parts from interfering with the farm route.
    table.insert(connections, RunService.Stepped:Connect(function()
        if not alive or not Config.AutoFarm then return end

        pcall(function()
            local char = LP.Character
            if not char then return end

            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = false
                end
            end
        end)
    end))

    -- Main gold farm loop.
    task.spawn(function()
        while alive do
            task.wait(0.5)
            if not Config.AutoFarm then
                continue
            end

            pcall(function()
                local hrp = GetRoot()
                local hum = GetHumanoid()
                if not hrp or not hum or hum.Health <= 0 then
                    return
                end

                local boatStages = Workspace:FindFirstChild("BoatStages")
                local stages = boatStages and boatStages:FindFirstChild("NormalStages")
                if not stages then
                    return
                end

                -- Stage 1-10 in order.
                for i = 1, 10 do
                    if not alive or not Config.AutoFarm then
                        break
                    end

                    local stageFolder = stages:FindFirstChild("CaveStage" .. i)
                    if stageFolder then
                        local darkPart = stageFolder:FindFirstChild("DarknessPart")
                        if darkPart then
                            local targetCFrame = darkPart.CFrame + Vector3.new(0, 3, 0)

                            hrp.Velocity = Vector3.zero
                            hrp.RotVelocity = Vector3.zero

                            MovePlatformTo(targetCFrame)
                            hrp.CFrame = targetCFrame

                            task.wait(2.3)
                        end
                    end
                end

                -- Final treasure position from the supplied script.
                if alive and Config.AutoFarm then
                    local treasureCFrame = CFrame.new(254, -9, 1370)

                    hrp.Velocity = Vector3.zero
                    hrp.RotVelocity = Vector3.zero

                    MovePlatformTo(treasureCFrame)
                    hrp.CFrame = treasureCFrame

                    task.wait(2)

                    if Platform and Platform.Parent then
                        Platform.Position = Vector3.new(0, -1000, 0)
                    end
                    hrp.CFrame = CFrame.new(hrp.Position.X, -500, hrp.Position.Z)

                    -- Wait for respawn, but don't block cleanup forever.
                    local character = LP.Character
                    local respawned = false
                    local conn
                    conn = LP.CharacterAdded:Connect(function()
                        respawned = true
                        pcall(function() conn:Disconnect() end)
                    end)
                    table.insert(connections, conn)

                    local timeout = 0
                    while alive and Config.AutoFarm and not respawned and timeout < 15 do
                        task.wait(0.25)
                        timeout += 0.25
                    end

                    task.wait(1.5)
                end
            end)
        end
    end)

    -- Cleanup if the player's character is removed permanently or the module is unloaded.
    task.spawn(function()
        while alive do
            task.wait(2)
            if not LP.Parent then
                cleanup()
                break
            end
        end
    end)

    notify("RVX Hub", "Build A Boat For Treasure พร้อมใช้งาน", 3)
    return true
end

return Module
